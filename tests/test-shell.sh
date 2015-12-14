#!/bin/sh -e

a="/$0"; a=${a%/*}; a=${a#/}; a=${a:-.}; BINDIR=$(cd $a; pwd)
PATH=$BINDIR/..:$PATH
cd $BINDIR

for MYSH in sh ash pdksh ksh dash mksh bash 
do
  MYSH=$(which $MYSH 2>/dev/null) || continue

  echo =================================
  echo Using $MYSH
  $MYSH -se < test-real.sh

  echo Testing despf functions...
  $MYSH $BINDIR/test-unit.sh

  echo Testing with '-n'
  for script in $BINDIR/../*.sh
  do
    if
      $MYSH -en $script
    then
      echo .. ${script##*/} ... OK
    else
      echo .. ${script##*/} ERROR
      exit 1
    fi
  done
done

! ls /tmp/despf* 2>/dev/null
