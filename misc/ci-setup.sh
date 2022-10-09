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

export PATH=$HOME/bin:/bin:/sbin:/usr/bin:/usr/sbin:$PATH

CD_CACHE=$HOME/.m2/repository
ADIR=$CD_CACHE/bin
test -d $ADIR || mkdir -p $ADIR
ln -nsf $CD_CACHE/bin $HOME/bin
#type busybox && ln -nsf $(which busybox) $HOME/bin/ash

ODIR=$ADIR
test -d $ODIR || mkdir $ODIR

dlit() {
  which $1 || {
    OUT=$ODIR/$1
    wget -O - "$2" | bzcat > $OUT
    chmod a+x $OUT
  }
}

KERNELARCH=$(uname -sm)
if
  test "$KERNELARCH" = "Linux x86_64"
then
  dlit host "http://dl.bintray.com/jsarenik/spf-tools-bin/host.bz2"
  dlit mksh "http://dl.bintray.com/jsarenik/spf-tools-bin/mksh.bz2"
  dlit ksh "http://dl.bintray.com/jsarenik/spf-tools-bin/ksh.bz2"
  dlit dash "http://dl.bintray.com/jsarenik/spf-tools-bin/dash.bz2"
fi

test x"$SEMAPHORE" = x"true" && install-package gawk
true
