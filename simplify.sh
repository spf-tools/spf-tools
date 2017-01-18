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

for cmd in awk grep sed cut
do
  type $cmd >/dev/null || exit 1
done

a="/$0"; a=${a%/*}; a=${a#/}; a=${a:-.}; BINDIR=$(cd $a; pwd)
export PATH=$BINDIR:$BINDIR/include:$PATH

tmpfile=$(mktemp /tmp/simplify.XXXXXXXXX)
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

grep "^ip6:" $tmpfile.orig
grep -v "^ip[46]:" $tmpfile.orig

if [ $? -eq 1 ]; then
  exit 0
fi
