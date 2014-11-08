#!/bin/sh

a="/$0"; a=${a%/*}; a=${a#/}; a=${a:-.}; BINDIR=`cd $a; pwd`
export PATH=$BINDIR:$BINDIR/include:$PATH

tmpfile=`mktemp /tmp/simplify.XXXXXXXXX`
trap "rm ${tmpfile}*" EXIT

cat > $tmpfile.orig

grep '^ip4:' $tmpfile.orig | cut -b5- > $tmpfile
grep -E '/[0-9]+$' $tmpfile > $tmpfile.cidr
grep -E '^[0-9\.]+$' $tmpfile > $tmpfile.addr

while read addr
do
  while read cidr
  do
    mask=${cidr#*/}
    ciaddr=${cidr%%/*}
    isincidrange.sh $addr $ciaddr $mask && echo $addr >> $tmpfile.grep
  done < $tmpfile.cidr
done < $tmpfile.addr

if
  test -f $tmpfile.grep
then
  grep -vFf $tmpfile.grep $tmpfile
else
  cat $tmpfile
fi | sed 's/^/ip4:/'

grep -v "^ip4:" $tmpfile.orig
