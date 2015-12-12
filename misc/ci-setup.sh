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

export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/usr/local/musl/bin:$HOME/bin

ORIG_PWD=$PWD
CD_CACHE=$HOME/.m2/repository
mkdir -p $CD_CACHE/cache/bin
ln -nsf $CD_CACHE/cache $HOME/cache
ln -nsf $HOME/cache/bin $HOME/bin
ln -nsf $(which busybox) $HOME/bin/ash

which drill || {
  cd $HOME/bin
  wget "http://dl.bintray.com/jsarenik/spf-tools-bin/drill.bz2"
  bunzip2 drill.bz2
  chmod a+x drill
}

clab() {
  NAME=$1
  REPO=$2
  BIN=${3:-"nonexistent"}
  TMPSH=$(mktemp /tmp/sh.XXXXXXX)

  cat > $TMPSH
  git clone -q $REPO || true
  cd $NAME
  if
    test -x $BIN
  then
    cp $BIN $HOME/bin
  else
    sh $TMPSH
  fi
  rm $TMPSH
  cd ..
}

cd $HOME/cache

clab mksh https://github.com/MirBSD/mksh.git mksh <<EOF
  sh Build.sh
  cp mksh $HOME/bin/mksh
EOF


clab musl git://git.musl-libc.org/musl <<EOF
  test -x tools/musl-gcc || ./configure --prefix=$HOME; make;
  make install
EOF

clab loksh https://github.com/dimkr/loksh.git ksh <<EOF
  export CC=musl-gcc LDFLAGS=-static; make;
  make PREFIX=$HOME install
EOF

cd $ORIG_PWD

ls -l $HOME/bin
which drill
drill
