#!/bin/sh

case "$1" in
  -m|--mac)
    cap="pbcopy"
    ;;
  -x|--linux|--xsel)
    cap="xsel -b"
    ;;
esac

tac | while read line
do
  echo -- $line | cut -d^ -f1
  output=`echo $line | cut -d^ -f2`
  test -n "$cap" && echo $output | eval $cap || echo $output
  echo '  Press ENTER to continue...'
  read enter </dev/tty
done
