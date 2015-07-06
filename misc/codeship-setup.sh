#!/bin/sh

export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/usr/local/musl/bin:$HOME/bin
ORIG_PWD=$PWD
CD_CACHE=$HOME/.m2/repository
mkdir -p $CD_CACHE/bin
ln -nsf $CD_CACHE/bin $HOME/bin
ln -nsf `which busybox` $HOME/bin/ash
cd $CD_CACHE
git clone git://git.musl-libc.org/musl || true
cd musl
test -x musl/tools/musl-gcc || { ./configure --prefix=$HOME; make; }
make install
cd ..
git clone https://github.com/dimkr/loksh.git || true
cd loksh
test -x loksh/ksh || { export CC=musl-gcc LDFLAGS=-static; make; }
make PREFIX=$HOME install
cd ..
cd $ORIG_PWD
