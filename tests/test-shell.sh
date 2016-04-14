#!/bin/sh -e
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

a="/$0"; a=${a%/*}; a=${a#/}; a=${a:-.}; BINDIR=$(cd $a; pwd)

export ADD="-e"
test -n "$DEBUG" && export DEBUG=1 ADD="${ADD}x"

for MYSH in sh ash pdksh ksh dash mksh bash 
do
  MYSH=$(which $MYSH 2>/dev/null) || continue

  echo =================================
  echo Using $MYSH
  $BINDIR/test-subdirs.sh $MYSH

  echo Testing despf functions...
  $MYSH $ADD $BINDIR/test-unit.sh

  echo Testing with '-n'
  for script in $BINDIR/../*.sh
  do
    if
      $MYSH -en $ADD $script
    then
      echo .. ${script##*/} ... OK
    else
      echo .. ${script##*/} ERROR
      exit 1
    fi
  done
done

! ls /tmp/despf* 2>/dev/null
