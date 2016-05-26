#!/bin/sh

ODIR=$PWD/mybin
export PATH=$ODIR:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/usr/local/musl/bin:$HOME/bin

pwd
which drill
drill
tests/test-shell.sh || DEBUG=1 tests/test-shell.sh
