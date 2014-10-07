#!/bin/sh

case `uname -s` in
  Darwin)
    cap="pbcopy"
    ;;
  *)
    test -n "$DISPLAY" && type xsel && cap="xsel -b"
    ;;
esac

tac | while read line
do
  echo -- $line | cut -d^ -f1
  output=`echo $line | cut -d^ -f2`
  test -n "$cap" && echo $output | tr -d '\n' | eval $cap || echo $output
  echo '  Press ENTER to continue...'
  read enter </dev/tty
done
