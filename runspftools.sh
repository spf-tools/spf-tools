#!/bin/sh

a="/$0"; a=${a%/*}; a=${a#/}; a=${a:-.}; BINDIR=$(cd $a; pwd)
. $BINDIR/include/global.inc.sh

# Read DOMAIN and ORIG_SPF from spf-toolsrc
test -r $SPFTRC && . $SPFTRC

test -n "$DOMAIN" || { echo "DOMAIN not set! Exiting."; exit 1; }
test -n "$ORIG_SPF" || { echo "ORIG_SPF not set! Exiting."; exit 1; }

bash -se <<EOF
PATH=$BINDIR:$PATH
cd $BINDIR
exec > $HOME/runspftools.log 2>&1
date
git pull
compare.sh $DOMAIN $ORIG_SPF || despf.sh $ORIG_SPF \
  | normalize.sh | simplify.sh | mkblocks.sh $DOMAIN \
  | mkzoneent.sh | cloudflare.sh $DOMAIN
sleep 300
exec $0
EOF
