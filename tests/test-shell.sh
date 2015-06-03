#!/bin/sh -e

a="/$0"; a=${a%/*}; a=${a#/}; a=${a:-.}; BINDIR=`cd $a; pwd`
PATH=$BINDIR/..:$PATH
cd $BINDIR

for MYSH in sh pdksh bash dash ash mksh
do
  MYSH=`which $MYSH 2>/dev/null` || continue

  echo Using $MYSH
  $MYSH -se < test-real.sh
done
