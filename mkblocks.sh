#!/bin/bash
#
# Usage: ./mkblocks.sh <domain> <prefix>
#  E.g.: ./mkblocks.sh microsoft.com _spf

for cmd in dig awk grep sed cut
do
  type $cmd >/dev/null || exit 1
done

header="v=spf1"
policy="~all"
delim="^"
packet=257

domain=${1:-'spf-tools.ml'}
prefix=${2:-"spf"}
incldomain="${prefix}X.$domain"
footer="include:$incldomain $policy"
let counter=1

myout() {
  local mycounter=$2
  echo "${1/X/$((mycounter-1))}${delim}\"$3\""
}

myout $domain $counter "$header ${footer/X/1}"
let counter++

while
  read block
do
  blocksprev=$blocks
  test -n "$blocks" && blocks="${blocks} ${block}" || blocks=$block
  compare="$header $blocks ${footer/X/$counter}"
  test `echo $compare | wc -c` -ge $packet && {
    myout $incldomain $counter "$header ${blocksprev} ${footer/X/$counter}"
    blocks=$block
    let counter++
    test $counter -gt 10 && { echo "Too many DNS lookups!"; exit 1; }
  }
done

test -n "$blocks" && myout $incldomain $counter "$header $blocks $policy"
