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

testexpect 0 "findns orig.spf-tools.ml | sort" <<EOF
chris.ns.cloudflare.com.
dawn.ns.cloudflare.com.
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

testexpect 0 demx mx.spf-tools.ml <<EOF
ip4:5.6.7.8
ip6:56:78::1
EOF

testexpect 0 parsepf spf-tools.ml <<EOF
v=spf1 include:spf1.spf-tools.ml ~all
EOF

testexpect -n 1 parsepf mail.spf-tools.ml
