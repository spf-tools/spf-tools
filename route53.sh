#!/bin/sh
##############################################################################
#
# Copyright 2017 spf-tools team (see AUTHORS)
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
# Requires AWS CLI from https://aws.amazon.com/cli/
#
# Usage: ./despf.sh | ./simplify.sh | mkblocks.sh | \
#          ./route53.sh <hosted_zone_id>
# E.g.: ... | ./route53.sh ABCXYZEXAMPLE

# The AWS CLI can be configured using ~/.aws/credentials or using
# environment variables: AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY

test -n "$DEBUG" && set -x

for cmd in jq aws awk sed grep
do
  type $cmd >/dev/null || exit 1
done

a="/$0"; a=${a%/*}; a=${a:-.}; a=${a#/}/; BINDIR=$(cd $a; pwd)
. $BINDIR/include/global.inc.sh

# default values
ttl=300
changesfile=$(mktemp /tmp/aws-route53-XXXXXXXXX)
trap "rm $changesfile" EXIT

usage() {
    cat <<-EOF
  Usage: route53.sh [OPTION]... [HOSTED_ZONE_ID]
  Script to update pre-existing TXT SPF records for
  a domain according to the input in DNS zone format.

  Available options:
    -t TTL                     set Time To Live for DNS records

  Default values:
    TTL = $ttl
EOF
    exit 1
}

while getopts "t:-" opt; do
  case $opt in
    t) test -n "$OPTARG" && ttl=$OPTARG;;
    *) usage;;
  esac
done
shift $((OPTIND-1))

# Read HOSTED_ZONE_ID
test -r $SPFTRC && . $SPFTRC

test -n "$1" -o -n "$HOSTED_ZONE_ID" || { echo "HOSTED_ZONE_ID not present! Exiting." >&2; exit 1; }
HOSTED_ZONE_ID=${1:-"$HOSTED_ZONE_ID"}

CHANGES=$(cat | jq -R -s -j --argjson TTL $ttl '.|split("\n")|map(split("^")|select(length>0)|{Action:"UPSERT",ResourceRecordSet:{Type:"TXT",TTL:$TTL,Name:.[0],ResourceRecords:[{Value:.[1]}]}})|{Changes:.}')
echo $CHANGES > $changesfile

aws route53 change-resource-record-sets \
  --hosted-zone-id $HOSTED_ZONE_ID \
  --change-batch "file://${changesfile}"
