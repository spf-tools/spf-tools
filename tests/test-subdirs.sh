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

a="/$0"; a=${a%/*}; a=${a:-.}; a=${a#/}/; BINDIR=$(cd $a; pwd)
export PATH=$BINDIR/..:$PATH
cd $BINDIR

RUNSHELL=${1:-"/bin/sh"}
out=$(mktemp 2>/dev/null || mktemp -t 'spftools-test-subdir.XXXXXX')
set | grep 'SH_VERSION=' >&2 || true
for test in $(find . -mindepth 1 -maxdepth 1 -type d)
do
  echo Testing $test
  $RUNSHELL $ADD $test/cmd <$test/in >$out
  grep -v '^+' $out | diff -u $test/out -
  echo .. $test OK
  rm $out
done
