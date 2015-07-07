#!/bin/sh

ORIGDOMAIN=${1:-'orig.spf-tools.ml'}
DOMAIN=${1:-'spf-tools.ml'}

a="/$0"; a=${a%/*}; a=${a#/}; a=${a:-.}; BINDIR=$(cd $a; pwd)
PATH=$BINDIR:$PATH

despf.sh $ORIGDOMAIN | simplify.sh | mkblocks.sh $DOMAIN spf | mkzoneent.sh
