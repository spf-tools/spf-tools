#!/bin/sh

export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/usr/local/musl/bin:$HOME/bin

ORIG_PWD=$PWD
CD_CACHE=$HOME/.m2/repository
mkdir -p $CD_CACHE/cache/bin
ln -nsf $CD_CACHE/cache $HOME/cache
ln -nsf $HOME/cache/bin $HOME/bin
ln -nsf `which busybox` $HOME/bin/ash

clab() {
  NAME=$1
  REPO=$2
  BIN=$3
  TMPSH=`mktemp /tmp/sh.XXXXXXX`

  cat > $TMPSH
  git clone $REPO || true
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

clab mksh https://github.com/MirBSD/mksh.git mksh/mksh <<EOF
  sh Build.sh
  cp mksh $HOME/bin/mksh
EOF


clab musl git://git.musl-libc.org/musl musl/tools/musl-gcc <<EOF
  ./configure --prefix=$HOME; make;
  make install
EOF

clab loksh https://github.com/dimkr/loksh.git loksh/ksh <<EOF
  export CC=musl-gcc LDFLAGS=-static; make;
  make PREFIX=$HOME install
EOF

cd $ORIG_PWD
