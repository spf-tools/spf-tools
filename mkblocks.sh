#!/bin/sh
#
# Usage: ./mkblocks.sh <domain> <prefix>
#  E.g.: ./mkblocks.sh microsoft.com _spf

for cmd in awk grep sed cut
do
  type $cmd >/dev/null || exit 1
done

header="v=spf1"
policy="~all"
delim="^"
packet=257
domain=${1:-'spf-tools.ml'}
prefix=${2:-"spf"}

# One-char placeholder substitued for number later
MYX=#

incldomain="${prefix}${MYX}.$domain"
footer="include:$incldomain $policy"
counter=$((2))

mysed() {
  sed "s/$MYX/$1/"
}

myout() {
  local mycounter=${3:-'1'}
  mystart=$(echo $1 | mysed $((mycounter-1)))
  myrest=$(echo $2 | mysed $((mycounter)))
  echo ${mystart}${delim}\"$header $myrest\"
}

# Corner case for first entry containing merely include
myout $domain "$footer"

while
  read block
do
  blocksprev=$blocks
  test -n "$blocks" && blocks="${blocks} ${block}" || blocks=$block
  compare="$header $blocks $footer"
  test $(echo $compare | wc -c) -ge $packet && {
    myout $incldomain "${blocksprev} ${footer}" $counter
    blocks=$block
    counter=$((counter+1))
    test $counter -gt 10 && { echo "Too many DNS lookups!" 1>&2; exit 1; }
  }
done

# Corner case for last entry not containing any include
test -n "$blocks" && myout $incldomain "$blocks $policy" $counter
