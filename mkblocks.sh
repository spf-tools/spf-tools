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
# Usage: ./mkblocks.sh <domain> <prefix> <policy>
#  E.g.: ./mkblocks.sh microsoft.com _spf

for cmd in awk grep sed cut
do
  type $cmd >/dev/null || exit 1
done

# Default values
domain=${DOMAIN:-"jasan.tk"}
prefix="spf"
policy="~all"
delim="^"
header="v=spf1"
length=257

usage() {
    cat <<-EOF
	Usage: mkblocks.sh [OPTION]... [DOMAIN]
	Make blocks out of decomposed SPF records.

	Available options:
	  -h HEADER                  set SPF header
	  -l LENGTH                  set desired packet length
	  -p PREFIX                  set SPF prefix
	  -o POLICY                  set default SPF policy
	  -d DELIM                   set delimiter of output

	Default values:
	  HEADER = $header
	  LENGTH = $length
	  PREFIX = $prefix
	  POLICY = $policy
	  DELIM  = $delim
	EOF
    exit 1
}

while getopts "h:l:p:o:d:-" opt; do
  case $opt in
    h) test -n "$OPTARG" && header=$OPTARG;;
    l) test -n "$OPTARG" && length=$OPTARG;;
    p) test -n "$OPTARG" && prefix=$OPTARG;;
    o) test -n "$OPTARG" && policy=$OPTARG;;
    d) test -n "$OPTARG" && delim=$OPTARG;;
    *) usage;;
  esac
done
shift $((OPTIND-1))

# For backward compatibility the options are also positional
domain=${1:-"$domain"}
prefix=${2:-"$prefix"}
policy=${3:-"$policy"}

# One-char placeholder substitued for number later
MYX=#

incldomain="${prefix}${MYX}.$domain"
footer="include:$incldomain $policy"
counter=$((1))

mysed() {
  sed "s/$MYX/$1/"
}

myout() {
  local mycounter=${3:-'1'}
  rrlabel=$1
  if [ $mycounter -eq 1 ]; then
      #first resource label of chain is bare domain
      rrlabel="$domain"
  fi
  mystart=$(echo $rrlabel | mysed $((mycounter-1)))
  myrest=$(echo $2 | mysed $((mycounter)))
  echo ${mystart}${delim}\"$header $myrest\"
}


while
  read block
do
  blocksprev=$blocks
  test -n "$blocks" && blocks="${blocks} ${block}" || blocks=$block
  compare="$header $blocks $footer"
  test $(echo $compare | wc -c) -ge $length && {
    myout $incldomain "${blocksprev} ${footer}" $counter
    blocks=$block
    counter=$((counter+1))
    test $counter -gt 10 && { echo "Too many DNS look-ups!" 1>&2; exit 1; }
  }
done

# Corner case for last entry not containing any include
test -n "$blocks" && myout $incldomain "$blocks $policy" $counter
