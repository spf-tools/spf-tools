#!/bin/sh

first="yes"

while read line
do
  if
    test -n "$first"
  then
    echo $line
    unset first
  else
    echo $line | cut -d^ -f2 | xsel -b
    echo '  Coppied into seconday paste-buffer. Use CTRL+V to paste it.'
    echo '  Press ENTER to continue...'
    read enter </dev/tty
    first="yes"
  fi
done
