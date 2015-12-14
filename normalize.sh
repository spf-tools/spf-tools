#!/bin/sh
#
# Usage: ./despf.sh domain | ./normalize.sh
#  E.g.: ./despf.sh microsoft.com | ./normalize.sh

test "$1" = "-i" && ignore=1

ip2int() {
  local a b c d
  echo $1 | while IFS="." read a b c d ; do
    echo $(((((((a << 8) | b) << 8) | c) << 8) | d))
  done
}

int2ip() {
  local ui32=$1; shift
  local ip n
  for n in 1 2 3 4; do
    ip=$((ui32 & 0xff))${ip:+.}$ip
    ui32=$((ui32 >> 8))
  done
  echo $ip
}

network() {
  local ia netmask
  echo $1 | while  IFS="/" read ia netmask; do
    local addr=$(ip2int $ia);
    local mask=$((0xffffffff << (32 -$netmask)));
    echo $(int2ip $((addr & mask)))/$netmask
  done
}

while
  read i
do
  cidr=$(echo $i | cut -d: -f2-)
  ipver=$(echo $i | cut -d: -f1)
  if [ $ipver = "ip4" ] ; then
    # check if is a CIDR
    nm=$(echo $i | cut -s -d/ -f2)
    if [ "x$nm" = "x32" ] ; then
      echo $i
    elif [ "x$nm" = "x" ] ; then
      echo $i
    else
      result="ip4:$(network $cidr)"
      test -n "$ignore" || { echo $result; continue; }
      test "$result" = "$i" && echo $i || true
    fi
  else
    echo $i
  fi
done
