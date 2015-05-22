#!/bin/sh

ORIGDOMAIN=${1:-'spf-orig.jasan.tk'}
DOMAIN=${1:-'jasan.tk'}

a="/$0"; a=${a%/*}; a=${a#/}; a=${a:-.}; BINDIR=`cd $a; pwd`
PATH=$BINDIR:$PATH

despf.sh $ORIGDOMAIN | simplify.sh | mkblocks.sh $DOMAIN spf | mkzoneent.sh
