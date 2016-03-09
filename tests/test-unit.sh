##############################################################################
#
# Copyright 2015 spf-tools team (see AUTHORS)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
#     Unless required by applicable law or agreed to in writing, software
#     distributed under the License is distributed on an "AS IS" BASIS,
#     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#     See the License for the specific language governing permissions and
#     limitations under the License.
#
##############################################################################

a="/$0"; a=${a%/*}; a=${a#/}; a=${a:-.}; BINDIR=$(cd $a; pwd)
tmp=$(mktemp /tmp/spf-test-unit-XXXXXXXXX)
trap "rm $tmp*" EXIT
. $BINDIR/../include/despf.inc.sh
export LC_ALL=C
export LANG=C

testexpect() {
  IN=0
  test $1 = "-n" && shift || cat > $tmp-out
  EXPRET=$1
  shift

  echo .. Testing $* ...
  set +e
  eval "$@" > $tmp-real 2>&1
  RETURN=$?
  set -e
  test -s $tmp-out && { diff $tmp-out $tmp-real; rm $tmp-out; }
  test $EXPRET -eq $RETURN
  echo .... OK
}

testexpect 0 mydig -t TXT spf-tools.ml <<EOF
"v=spf1 include:spf1.spf-tools.ml ~all"
EOF

testexpect 0 "mydig -t NS spf-tools.ml | sort" <<EOF
chris.ns.cloudflare.com.
dawn.ns.cloudflare.com.
EOF

testexpect 0 "mydig_notshort -t A cname.spf-tools.ml @dawn.ns.cloudflare.com." <<EOF
cname.spf-tools.ml.	300	IN	CNAME	both.spf-tools.ml.
both.spf-tools.ml.	300	IN	A	1.2.3.4
EOF

testexpect 0 findns one.spf-tools.ml <<EOF
ns1.he.net.
EOF

testexpect -n 1 findns orig.non-existent.nonnon

cat > $tmp <<EOF
1.2.3.4
fec0::1
EOF
testexpect 0 "cat $tmp | printip" <<EOF
ip4:1.2.3.4
ip6:fec0::1
EOF

cat > $tmp <<EOF
1.2.3.4
test
fec0::1
EOF
testexpect 1 "cat $tmp | printip" <<EOF
ip4:1.2.3.4
EOF

testexpect 0 dea both.spf-tools.ml <<EOF
ip4:1.2.3.4
ip6:fec0::1
EOF

testexpect 0 dea cname.spf-tools.ml <<EOF
ip4:1.2.3.4
ip6:fec0::1
EOF

testexpect 0 demx mx.spf-tools.ml <<EOF
ip4:5.6.7.8
ip6:56:78::1
EOF

testexpect 0 parsepf spf-tools.ml <<EOF
v=spf1 include:spf1.spf-tools.ml ~all
EOF

# This tests the correct process of iteration
# between different NS servers if one is not
# responding
testexpect 0 parsepf morens.spf-tools.ml <<EOF
v=spf1 include:spf1.spf-tools.ml ~all
EOF

testexpect -n 1 parsepf mail.spf-tools.ml

testexpect -n 1 isincidrange.sh 74.86.241.250 199.122.123.192 32

testexpect -n 0 isincidrange.sh 192.168.5.1 192.168.0.0 16
