#!/bin/sh
#
# Usage: ./mkblocks.sh <domain> <prefix>
#  E.g.: ./mkblocks.sh microsoft.com _spf

domain=${1:-'apiary.io'}
test -n "$2" || {
  alternate=`host -t txt $domain | grep "v=spf1" | grep -o "include:."`
  alternate=`echo $alternate | cut -d: -f2 | sed 's/_//;s/s/_/'`
  alternate="${alternate}spf"
}
prefix=${2:-"$alternate"}

header="v=spf1"
incldomain="${prefix}X.$domain"
footer="include:$incldomain -all"
let counter=1

myout() {
  local mycounter=$2
  echo -n "${1/X/$((mycounter-1))} (length: `echo $3 | wc -c`):^"
  echo $3
}

{
myout $domain $counter "$header ${footer/X/1}"
let counter++

blocks=""
while
  read block
do
  blocksprev=$blocks
  test -n "$blocks" && blocks="${blocks} ${block}" || blocks=$block
  if
    compare="$header $blocks ${footer/X/$counter}"
    test `echo $compare | wc -c` -ge 255
  then
    myout $incldomain $counter "$header ${blocksprev} ${footer/X/$counter}"
    blocks=$block
    let counter++
  fi
done

if
  test -n "$blocks"
then
  myout $incldomain $counter "$header $blocks -all"
fi
} | tac | tr "^" "\n"
