#!/bin/sh
##############################################################################
#
# Copyright 2026 spf-tools team (see AUTHORS)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
#     Unless required by applicable law or agreed to in writing, software
#     distributed under the License is distributed on an "AS IS" BASIS,
#     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#     See the License for the specific language governing permissions and
#     limitations under the License.
#
##############################################################################
#
# Script to create or update TXT SPF records for a domain
# according to the input in mkblocks format using deSEC's API.
#
# All changes are sent in one atomic bulk request, so the published
# SPF chain is never left half-updated. TXT records that do not start
# with "v=spf1" (e.g. site verification tokens) are kept untouched.
# SPF records of the previously published chain which are no longer
# part of the new one are removed.
#
# Requires jq(1) from http://stedolan.github.io/jq/ and curl(1).
#
# Requires DESEC_TOKEN (or TOKEN) to be set to a deSEC API token.
#
# Usage: ./despf.sh | ./normalize.sh | ./simplify.sh | ./iprange.sh | \
#          ./mkblocks.sh <domain> | ./desec.sh [-t TTL] [-n] <domain>
# E.g.: ... | ./desec.sh spf-tools.eu.org

test -n "$DEBUG" && set -x

for cmd in jq curl
do
  type $cmd >/dev/null || exit 1
done

a="/$0"; a=${a%/*}; a=${a:-.}; a=${a#/}/; BINDIR=$(cd "$a" || exit; pwd)
# shellcheck source=include/global.inc.sh
. "$BINDIR/include/global.inc.sh"

APIURL=${DESEC_APIURL:-"https://desec.io/api/v1"}

usage() {
    cat <<-EOF
  Usage: desec.sh [OPTION]... [DOMAIN]
         desec.sh verify [DOMAIN]
  Create or update TXT SPF records of DOMAIN (a zone managed
  by deSEC) according to the input in mkblocks format.

  Available options:
    -t TTL                     set Time To Live for changed records
                               (default: keep existing TTL, or 3600
                               for new records; deSEC minimum is 3600)
    -n                         dry run, print the request and exit
    -h                         display this help and exit
EOF
    exit 1
}

while getopts "t:nh" opt; do
  case $opt in
    t) TTL=$OPTARG;;
    n) DRYRUN=1;;
    *) usage;;
  esac
done
shift $((OPTIND-1))

VERIFY=
test "$1" = "verify" && { VERIFY=1; shift; }

# Read DESEC_TOKEN/TOKEN, DOMAIN and ORIG_SPF
# shellcheck source=/dev/null
test -r "$SPFTRC" && . "$SPFTRC"

DESEC_TOKEN=${DESEC_TOKEN:-"$TOKEN"}
DOMAIN=${1:-"$DOMAIN"}
DOMAIN=$(printf "%s" "${DOMAIN%.}" | tr "[:upper:]" "[:lower:]")

test -n "$DESEC_TOKEN" || { echo "DESEC_TOKEN not set! Exiting." >&2; exit 1; }
test -n "$DOMAIN" || { echo "DOMAIN not set! Exiting." >&2; exit 1; }
test -z "$TTL" || test "$TTL" -gt 0 2>/dev/null \
  || { echo "Invalid TTL: $TTL" >&2; exit 1; }

RESPONSE_FILE=$(mktemp /tmp/desec-response-XXXXXX)
PAYLOAD_FILE=$(mktemp /tmp/desec-payload-XXXXXX)
trap 'rm -f "$RESPONSE_FILE" "$PAYLOAD_FILE" "$PAYLOAD_FILE.tmp"' EXIT

# apicmd METHOD PATH [CURL_ARGS...]
# Writes the response body to $RESPONSE_FILE, fails on non-2xx status.
apicmd() {
  CMD=$1; shift
  REST=$1; shift
  STATUS=$(curl -X "$CMD" "${APIURL}${REST}" \
    -s -o "$RESPONSE_FILE" -w '%{http_code}' \
    -H "Authorization: Token $DESEC_TOKEN" \
    -H "Content-Type: application/json" \
    "$@") || { echo "curl failed for $CMD $REST" >&2; return 1; }
  case $STATUS in
    2??) return 0;;
    *) echo "$CMD $REST failed with HTTP $STATUS:" >&2
       cat "$RESPONSE_FILE" >&2; echo >&2
       return 1;;
  esac
}

test -n "$VERIFY" && {
  apicmd GET "/domains/$DOMAIN/" || exit 1
  jq . "$RESPONSE_FILE"
  exit
}

apicmd GET "/domains/$DOMAIN/rrsets/?type=TXT" || exit 1
EXISTING=$(cat "$RESPONSE_FILE")

# Turn "name^content" lines into deSEC RRsets, merging with existing ones:
# drop old v=spf1 records, keep any other TXT records at the same name,
# and only emit RRsets whose records actually change.
#
# Stale chain records are removed too: starting from the input names, the
# include:/redirect= links of the currently published SPF records are
# followed within the zone. Every SPF record reached this way which is
# neither produced nor referenced by the new input is deleted. ORIG_SPF
# is never deleted.
jq -R -n \
  --arg domain "$DOMAIN" \
  --arg ttl "$TTL" \
  --arg orig "$ORIG_SPF" \
  --argjson existing "$EXISTING" '
  def spf: ltrimstr("\"") | startswith("v=spf1");
  # TXT presentation format to plain text: join "a" "b" strings
  def text: gsub("\" \""; "") | ltrimstr("\"") | rtrimstr("\"");
  # FQDN to subname within $domain, null when outside of it
  def subname: ascii_downcase | rtrimstr(".")
    | if . == $domain then ""
      elif endswith("." + $domain) then .[:-($domain | length + 1)]
      else null end;
  def targets: text | [scan("(?:include:|redirect=)([^ ]+)")[0]
    | subname | select(. != null)];
  ($existing | map({key: .subname, value: .}) | from_entries) as $cur
  | def oldtargets: [($cur[.].records // [])[] | select(spf) | targets[]];
    def closure: . as $set
      | ($set + [$set[] | oldtargets[]] | unique) as $next
      | if $next == $set then $set else $next | closure end;
  [ inputs
      | select(length > 0)
      | index("^") as $i
      | if $i == null then error("malformed input line: \(.)") else . end
      | .[:$i] as $name
      | {sub: ($name | subname), content: .[$i+1:]}
      | if .sub == null then error("\($name) is not within \($domain)") else . end
    ] as $in
  | ($in | map(.sub)) as $insubs
  | ([$in[].content | targets[]] + $insubs
     + [$orig | subname | select(. != null)]) as $keep
  | (($insubs | unique | closure) - $keep) as $stale
  | def rrset($sub; $records; $action):
      ($cur[$sub] // {records: [], ttl: null}) as $old
      | select(($records | sort) != ($old.records | sort))
      | {action: $action, subname: $sub, type: "TXT",
         ttl: (if $ttl != "" then ($ttl | tonumber) else ($old.ttl // 3600) end),
         records: $records};
    def others($sub): ($cur[$sub].records // []) | map(select(spf | not));
  [ ($in[] | rrset(.sub; others(.sub) + [.content]; "Updating")),
    ($stale[] | rrset(.; others(.); "Removing SPF from")) ]
  ' > "$PAYLOAD_FILE" || exit 1

if test "$(jq length "$PAYLOAD_FILE")" -eq 0
then
  echo "TXT records of $DOMAIN up to date"
  exit 0
fi

jq -r '.[] | "\(.action) TXT record " +
  (if .subname == "" then "@" else .subname end) + " (ttl \(.ttl))"' \
  "$PAYLOAD_FILE"

# Strip the informational action field before sending
jq 'map(del(.action))' "$PAYLOAD_FILE" > "$PAYLOAD_FILE.tmp" \
  && mv "$PAYLOAD_FILE.tmp" "$PAYLOAD_FILE" || exit 1

test -n "$DRYRUN" && { jq . "$PAYLOAD_FILE"; exit 0; }

apicmd PATCH "/domains/$DOMAIN/rrsets/" --data "@$PAYLOAD_FILE" || exit 1
echo OK
