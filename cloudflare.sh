#!/bin/sh
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

DOMAIN=${1:-'spf-tools.ml'}
TTL=1 # 1 = auto
APIURL="https://www.cloudflare.com/api_json.html"
idsfile=$(mktemp /tmp/cloudflare-ids-XXXXXX)
zonefile=$(mktemp /tmp/cloudflare-zone-XXXX)
cat > $zonefile
trap "rm $idsfile $zonefile" EXIT

# Read TOKEN and EMAIL
. $HOME/.spf-toolsrc

test -n "$TOKEN" || { echo "TOKEN not set! Exiting."; exit 1; }
test -n "$EMAIL" || { echo "EMAIL not set! Exiting."; exit 1; }

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
