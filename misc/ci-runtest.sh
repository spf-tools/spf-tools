#!/bin/sh

export PATH=$HOME/bin:/bin:/sbin:/usr/bin:/usr/sbin

pwd

# Check for required tools
for cmd in host awk grep sed cut
do
  type $cmd >/dev/null
done

which host
host jasan.tk

echo "COVERAGE is $COVERAGE"
if [ "x1" = "x$COVERAGE" ] ; then
	$GEM_HOME/wrappers/bashcov -- tests/test-shell.sh
else
	tests/test-shell.sh || DEBUG=1 tests/test-shell.sh
fi
