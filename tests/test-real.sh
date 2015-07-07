set | grep 'SH_VERSION=' >&2 || true
for test in $(find . -type d -mindepth 1 -maxdepth 1)
do
  echo Testing $test
  $0 $test/cmd <$test/in >/tmp/test 2>&1
  diff $test/out /tmp/test
  echo .. $test OK
done
