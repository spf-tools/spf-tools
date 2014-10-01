#!/bin/sh

a="/$0"; a=${a%/*}; a=${a#/}; a=${a:-.}; BINDIR=`cd $a; pwd`
PATH=$BINDIR:$PATH

temp=`mktemp`

despf.sh apiary.io > ${temp}-1 2>/dev/null
despf.sh > ${temp}-2 2>/dev/null

trap "rm ${temp}-*" EXIT

if
  cmp ${temp}-*
then
  echo "Everything OK"
else
  echo "Please update TXT records!" 1>&2
  despf.sh | mkblocks.sh
fi
