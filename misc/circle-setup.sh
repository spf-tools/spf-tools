#!/bin/sh -e

a="/$0"; a=${a%/*}; a=${a#/}; a=${a:-.}; BINDIR=`cd $a; pwd`

export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/usr/local/musl/bin

which bc || {
#  sudo apt-get update
#  sudo apt-get install mksh dash build-essential bc
#  sudo apt-get autoremove
  sudo apt-get install mksh bc
}

sudo ln -nsf `which busybox` /bin/ash

git clone git://git.musl-libc.org/musl || true
cd musl
test -x musl/tools/musl-gcc || {
  ./configure
  make
}
sudo make install
cd ..

git clone https://github.com/dimkr/loksh.git || true
cd loksh
test -x loksh/ksh || {
  export CC=musl-gcc
  make
}
sudo make install
cd ..
