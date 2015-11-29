#!/bin/sh
#
# Usage: ./despf.sh domain | ./normalize.sh
#  E.g.: ./despf.sh microsoft.com | ./normalize.sh


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
  local ip netmask
  echo $1 | while  IFS="/" read ip netmask; do
    local addr=$(ip2int $ip);
    local mask=$((0xffffffff << (32 -$netmask)));
    echo $(int2ip $((addr & mask)))/$netmask
  done
}

while
  read ip
do
  array=(${ip/:/ });
  if [ "x${array[0]}" = "xip4" ] ; then
    # check if is a CIDR
    if [[ ${array[1]} == *"/"32 ]] ; then
      echo $ip
    elif [[ ${array[1]} == *"/"* ]] ; then
      echo "ip4:$(network ${array[1]})"
    else
      echo "ip4:${array[1]}"
    fi
  else
    echo $ip
  fi
done
