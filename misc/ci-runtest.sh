#!/bin/sh

export PATH=$HOME/bin:/usr/bin:/usr/sbin:/bin:/sbin

pwd

# Check for required tools
for cmd in host awk grep sed cut
do
  type $cmd >/dev/null
done

which host
host spf-tools.eu.org

echo "COVERAGE is $COVERAGE"
if [ "x1" = "x$COVERAGE" ] ; then
	bashcov -- tests/test-shell.sh
else
	tests/test-shell.sh || DEBUG=1 tests/test-shell.sh
fi
