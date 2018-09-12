#!/bin/sh
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
#
# Usage: isincidrange6.sh <ip6> <ip6> <mask>
# E.g.: isincidrange6.sh 2400:aa00:1:1::19c1 2400:aa00:1:1::5 64

test -n "$DEBUG" && set -x

ip2int() {
  local a b c d e f g h
  echo $1 | while IFS=":" read a b c d e f g h; do
    perl -e "print (((((((((((((($a << 16) | $b) << 16) | $c) << 16) | $d) << 16) | $e) << 16) | $f) << 16) | $g) << 16) | $h)" | bc
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

a=${1:-"2400:aa00:1:1::19c1"}
b=$2:-"2400:aa00:1:1::5"}
c=$3:-64}

nm=$c
if [ "x$nm" = "x32" ] ; then
  test "$a" = "$b"
else
  resulta="$(network $a/$nm)"
  resultb="$(network $b/$nm)"
  test "$resulta" = "$resultb"
fi
