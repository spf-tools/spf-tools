set | grep VERSION >&2 || true
for test in `find . -type d -mindepth 1 -maxdepth 1`
do
  echo .. Testing $test
  eval `cat $test/cmd` < $test/in >/tmp/test
  diff $test/out /tmp/test
  echo .. OK
done
