#!/bin/sh

DOMAIN=${1:-'spf-orig.apiary.io'}

a="/$0"; a=${a%/*}; a=${a#/}; a=${a:-.}; BINDIR=`cd $a; pwd`
PATH=$BINDIR:$PATH

despf.sh | simplify.sh | mkblocks.sh | mkzoneent.sh
