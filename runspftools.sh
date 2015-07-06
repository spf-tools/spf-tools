#!/bin/sh

a="/$0"; a=${a%/*}; a=${a#/}; a=${a:-.}; BINDIR=`cd $a; pwd`

# Read DOMAIN and ORIG_SPF
. $HOME/.spf-toolsrc

test -n "$DOMAIN" || exit 1
test -n "$ORIG_SPF" || exit 1

bash -se <<EOF
PATH=$BINDIR:$PATH
cd $BINDIR
exec > $HOME/runspftools.log 2>&1
date
git pull
compare.sh $DOMAIN $ORIG_SPF || despf.sh $ORIG_SPF \
  | simplify.sh | mkblocks.sh $DOMAIN \
  | mkzoneent.sh | cloudflare.sh $DOMAIN
sleep 300
exec $0
EOF
