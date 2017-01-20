#!/bin/sh
#
# This script uses iprange from https://github.com/firehol/iprange
# in order to optimize resulting list. E.g. if the original SPF records
# would result (after calling despf.sh) in
#   ip4:13.111.0.0/24
#   ip4:13.111.1.0/24
#   ip4:13.111.2.0/24
#   ip4:13.111.3.0/24
#
# then if such result is piped into this script it will print just
#   ip4:13.111.0.0/22
#
# Thanks to @bakerjalexander for suggestion!
#
# Usage: despf.sh <domain> | iprange.sh

TMP=/tmp/iprange

cat > $TMP
grep -v ^ip4: $TMP > $TMP-rest
grep ^ip4: $TMP | cut -d: -f2- | iprange | while read l; do echo "ip4:$l"; done
cat $TMP-rest
