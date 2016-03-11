#!/bin/sh
##############################################################################
#
# Copyright 2015 spf-tools team (see AUTHORS)
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
# Script to update pre-existing TXT SPF records for
# a domain according to the input in DNS zone format.
#
# Requires jq(1) from http://stedolan.github.io/jq/
#
# Usage: ./despf.sh | ./simplify.sh | mkblocks.sh | \
#          mkzoneent.sh | ./cloudflare.sh <domain>
# E.g.: ... | ./cloudflare.sh spf-tools.ml

for cmd in jq awk sed grep
do
  type $cmd >/dev/null || exit 1
done

a="/$0"; a=${a%/*}; a=${a#/}; a=${a:-.}; BINDIR=$(cd $a; pwd)
. $BINDIR/include/global.inc.sh

test -n "$TOKEN" || { echo "TOKEN not set! Exiting."; exit 1; }
test -n "$EMAIL" || { echo "EMAIL not set! Exiting."; exit 1; }

DOMAIN=${1:-'spf-tools.ml'}
TTL=1 # 1 = auto
APIURL="https://www.cloudflare.com/api_json.html"
idsfile=$(mktemp /tmp/cloudflare-ids-XXXXXX)
zonefile=$(mktemp /tmp/cloudflare-zone-XXXX)
cat > $zonefile
trap "rm $idsfile $zonefile" EXIT

# Read TOKEN and EMAIL
test -r $SPFTRC && . $SPFTRC

apicmd() {
  CMD=${1:-'stats'}
  shift
  curl $APIURL \
    -s \
    -d "a=$CMD" \
    -d "tkn=$TOKEN" \
    -d "email=$EMAIL" \
    -d "z=$DOMAIN" \
    "$@"
}

apicmd rec_load_all | \
  jq '.response.recs.objs[] | .name + " " + .type + " "
    + .rec_id + " " + .content' | \
  tr -d "\"" | sort > $idsfile

while read domain ttl proto type content
do
  name=$domain
  domain=$(echo $domain | sed 's/\.$//')
  id_to_change=$(grep -x "^$domain TXT [0-9]\+ .v=spf1.*" $idsfile | \
    awk '{print $3}')

  echo -n "Changing $domain with id $id_to_change... "
  apicmd rec_edit \
    -o /dev/null \
    -d 'type=TXT' \
    -d "name=$name" \
    -d "ttl=$TTL" \
    -d "id=$id_to_change" \
    -d "content=$content" && echo "OK"
done < $zonefile
