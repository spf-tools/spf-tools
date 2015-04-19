#!/bin/sh
#
# Usage: ./mkblocks.sh <domain> <prefix>
#  E.g.: ./mkblocks.sh microsoft.com _spf

for cmd in dig awk grep sed cut
do
  type $cmd >/dev/null || exit 1
done

domain=${1:-'apiary.io'}
test -n "$2" || {
  nameserver=`dig +short -t NS $domain | sed 1q`
  alternate=`dig +short -t TXT $domain @$nameserver | \
    grep "v=spf1" | grep -o "include:."`
  alternate=`echo $alternate | cut -d: -f2 | sed 's/_//;s/s/_/'`
  alternate="${alternate}spf"
}
prefix=${2:-"$alternate"}
incldomain="${prefix}X.$domain"

header="v=spf1"
policy="~all"
footer="include:$incldomain $policy"
let counter=1

myout() {
  local mycounter=$2
  echo "${1/X/$((mycounter-1))}^\"$3\""
}

myout $domain $counter "$header ${footer/X/1}"
let counter++

while
  read block
do
  blocksprev=$blocks
  test -n "$blocks" && blocks="${blocks} ${block}" || blocks=$block
  compare="$header $blocks ${footer/X/$counter}"
  test `echo $compare | wc -c` -ge 257 && {
    myout $incldomain $counter "$header ${blocksprev} ${footer/X/$counter}"
    blocks=$block
    let counter++
  }
done

test -n "$blocks" && myout $incldomain $counter "$header $blocks $policy"
