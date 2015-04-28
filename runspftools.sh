#!/bin/sh

a="/$0"; a=${a%/*}; a=${a#/}; a=${a:-.}; BINDIR=`cd $a; pwd`

bash -se <<EOF
PATH=$BINDIR:$PATH
cd $BINDIR
exec > $HOME/runspftools.log 2>&1
date
git pull
compare.sh || despf.sh \
  | simplify.sh | mkblocks.sh \
  | mkzoneent.sh | cloudflare.sh
sleep 300
exec $0
EOF
