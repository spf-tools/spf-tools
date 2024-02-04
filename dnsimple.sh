#!/bin/sh
##############################################################################
#
# Copyright 2024 spf-tools team (see AUTHORS)
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
# Script to create or update pre-existing TXT SPF records for
# a domain according to the input in mkblocks format.
#
# Requires jq(1) from http://stedolan.github.io/jq/
#
# Requires TOKEN env var to be set to an account token (not a user token).
#
# Usage: ./despf.sh | ./simplify.sh | mkblocks.sh | \
#          ./dnsimple.sh <domain>
# E.g.: ... | ./dnsimple.sh spf-tools.eu.org

test -n "$DEBUG" && set -x

for cmd in jq
do
  type $cmd >&2 || exit 1
done

a="/$0"; a=${a%/*}; a=${a:-.}; a=${a#/}/; BINDIR=$(cd "$a" || exit; pwd)
# shellcheck source=include/global.inc.sh
. "$BINDIR/include/global.inc.sh"

DOMAIN=${1:-'spf-tools.eu.org'}
APIURL="https://api.dnsimple.com/v2/"
TTL=3600

apicmd() {
  CMD=${1:-'GET'}
  test -n "$1" && shift
  REST=${1:-'/zones'}
  test -n "$1" && shift
  curl -X "$CMD" "${APIURL}${REST}" \
    -s \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type:application/json" \
    "$@"
}

# Read TOKEN
# shellcheck source=/dev/null
test -r "$SPFTRC" && . "$SPFTRC"

test -n "$TOKEN" || { echo "TOKEN not set! Exiting." >&2; exit 1; }

test "$1" = "verify" && {
	apicmd GET "/whoami"
	exit
}

PAYLOAD_FILE=$(mktemp /tmp/dnsimple-payload-XXXXXX)
trap 'rm -f "$PAYLOAD_FILE"' EXIT

ACCOUNT_ID=$(apicmd GET /whoami | jq -r '.data.account.id') || exit 1

test "$ACCOUNT_ID" = "null" && {
  echo "TOKEN is not an account token! Exiting." >&2
  exit 1
}

RECORDS=$(apicmd GET "$ACCOUNT_ID/zones/$DOMAIN/records?type=TXT&per_page=100" | jq  '[.data | .[] | select ( .content | contains("v=spf1") )]')
apicmd GET "$ACCOUNT_ID/zones/$DOMAIN/records?type=TXT&per_page=100" > /tmp/bla.json
echo $RECORDS
while read -r line
do
  __name=$(echo "$line" | cut -d^ -f1)
  _name=${__name%$DOMAIN}
  name=${_name%.}
  content=$(echo "$line" | cut -d^ -f2 | tr -d \")

  EXISTING_RECORD=$(echo $RECORDS | jq -r 'first(.[] | select(.name=="'$name'") )' )

  if test -z "$EXISTING_RECORD" 
  then
    echo '{
      "name": "'$name'",
      "type": "TXT",
      "content": "'$content'",
      "ttl": '$TTL'
    }' > $PAYLOAD_FILE
    printf "Creating TXT record %s... " "$name"
    RESULT=$(apicmd POST "$ACCOUNT_ID/zones/$DOMAIN/records" --data @$PAYLOAD_FILE)
  else
    echo '{
      "name": "'$name'",
      "content": "'$content'",
      "ttl": '$TTL'
    }' > $PAYLOAD_FILE
    test "$(echo $EXISTING_RECORD | jq -e -r '.content')" = "\"$content\"" && {
      echo 'TXT record '$name' up to date'
      continue
    }
    EXISTING_ID=$(echo $EXISTING_RECORD | jq -e -r '.id')
    printf "Updating TXT record %s with id %s... " "$name" "$EXISTING_ID"
    RESULT=$(apicmd PATCH "$ACCOUNT_ID/zones/$DOMAIN/records/$EXISTING_ID" --data "@$PAYLOAD_FILE")
  fi
  ID=$(echo $RESULT | jq -e -r '.data.id') || {
    echo "failed: $RESULT"
    exit 1
  }
  echo "success (id $(echo $RESULT | jq -r '.data.id'))"
done
