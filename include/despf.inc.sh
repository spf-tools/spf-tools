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

DNS_TIMEOUT=${DNS_TIMEOUT:-"2"}

mydg() {
  dig +time=$DNS_TIMEOUT "$@" \
      || { echo "DNS lookup error!" >&2; cleanup; false; }
}

mydig() {
  mydg +short "$@"
}

mydig_notshort() {
  mydg +noall +answer "$@"
}

# findns <domain>
# Find an authoritative NS server for domain
findns() {
  dd="$1"; ns=""; dig=${2:-mydig}
  while test -z "$ns"
  do
    if
      ns=$($dig -t NS $dd | grep .)
    then
      break
    else
      echo $dd | grep -q '\.' && { dd="${dd#*.}"; unset ns; } || break
    fi
  done
  echo "$ns" | grep '^[^;]'
}

# printip <<EOF
# 1.2.3.4
# fec0::1
# EOF
# ip4:1.2.3.4
# ip6:fec0::1
printip() {
  while read line
  do
    prefix=/${1:-"${line##*/}"}
    test -n "$1" || echo $line | grep -q '/' || prefix=""
    line=$(echo $line | cut -d/ -f1)
    if echo $line | grep -q ':'; then ver=6
      checkval6 $line $prefix || continue
    elif echo $line | grep -q '\.'; then ver=4
      checkval4 $line $prefix || continue
    else
      continue
    fi
    echo "ip${ver}:${line}${prefix}"
  done
}

# dea <hostname> <cidr>
# dea both.spf-tools.ml
# 1.2.3.4
# fec0::1
dea() {
  for TYPE in A AAAA; do mydig_notshort -t $TYPE $1 | grep -v CNAME | awk '{print $5}' | printip $2; done
  true
}

# demx <domain> <cidr>
# Get MX record for a domain
demx() {
  mymx=$(mydig -t MX $1 | awk '{print $2}')
  for name in $mymx; do dea $name $2; done
}

# parsepf <host>
parsepf() {
  host=$1
  if
    test -n "$USE_UPSTREAM"
  then
    myns=$(findns $host 2>/dev/null)
  else
    myns=$(sed -n 's/nameserver \([\.:0-9a-f]*\)/\1/p' /etc/resolv.conf)
  fi
  for ns in $myns
  do
    mydig -t TXT $host @$ns 2>/dev/null | sed 's/^"//;s/"$//;s/" "//' \
      | grep -E '^v=spf1\s+' && break
  done
}

# getem <includes>
# e.g. includes="include:gnu.org include:google.com"
getem() {
  myloop=$1
  shift
  echo $* | tr " " "\n" | sed '/^$/d' | cut -b 9- | while read included
  do echo Getting $included 1>&2; despf $included $myloop
  done
}

# getamx host mech [mech [...]]
# e.g. host="spf-tools.ml"
# e.g. mech="a a:gnu.org a:google.com/24 mx:gnu.org mx:jasan.tk/24"
getamx() {
  host=$1
  shift
  for record in $* ; do 
    local cidr=$(echo $record | cut -s -d\/ -f2-)
    local ahost=$(echo $record | cut -s -d: -f2-)
    if [ "x" = "x$ahost" ] ; then
      lookuphost="$host";
      mech=$(echo $record | cut -d/ -f1)
    else
      # try to catch "a/24", "a",  "a:host.tld/24" and "a:host.tld"
      mech=$(echo $record | cut -d: -f1 | cut -d/ -f1)
      if [ "x" = "x$cidr" ] ; then
        lookuphost=$ahost
      else
        lookuphost=$(echo $ahost | cut -d\/ -f1)
      fi
    fi
    if [ "$mech" = "a" ]; then
      dea $lookuphost $cidr
    elif [ "$mech" = "mx" ]; then
      demx $lookuphost $cidr
    fi
  done
}

# despf <domain>
despf() {
  host=$1
  myloop=$2

  # Detect loop
  echo $host | grep -qxFf $myloop && {
    #echo "Loop detected with $host!" 1>&2
    return
  }

  echo "$host" >> "${myloop}"
  myspf=$(parsepf $host | sed 's/redirect=/include:/')

  set +e
  dogetem=$(echo $myspf | grep -Eo 'include:\S+') \
    && getem $myloop $dogetem
  dogetamx=$(echo $myspf | grep -Eo -w '(mx|a)((\/|:)\S+)?')  \
    && getamx $host $dogetamx
  echo $myspf | grep -Eo 'ip[46]:\S+' | cut -d: -f2- | printip
  set -e
}

cleanup() {
  myloop=$1
  test -n "$myloop" && rm ${myloop}*
}

despfit() {
  host=$1
  myloop=$2

  # Make sort(1) behave
  export LC_ALL=C
  export LANG=C

  despf $host $myloop > "$myloop-out"
  sort -u $myloop-out
}

checkval4() {
  ip=$1
  cidr=${2#/}
  test -n "$cidr" && { numlesseq $cidr 32 || return 1; }

  D=$(echo $ip | grep -o '\.' | wc -l)
  test $D -eq 3 || return 1
  for i in $(echo $ip | tr '.' ' ')
  do
    numlesseq $i 255 || return 1
  done
}

numlesseq() {
  num=${1:-1}
  less=${2:-255}
  echo "$num" | tr -d '[0-9]' | grep -q '^$' || return 1
  test $num -le $less || return 1
}

checkval6() {
  myip=$(canon6 $1) || return 1
  cidr=${2#/}
  test -n "$cidr" && { numlesseq $cidr 128 || return 1; }

  for i in $(echo $myip | tr ':' ' ')
  do
    C=$(echo $i | wc -c)
    # echo prints a newline --> 5 including \n
    test $C -le 5 || return 1
    echo "$i" | tr -d '[0-9a-f]' | grep -q '^$' || return 1
  done
}

canon6() {
  D=$(echo $1 | grep -o ':' | wc -l)
  if
    test $D -eq 7
  then
    echo $1
  elif
    test $D -le 7 && echo $1 | grep -q '::'
  then
    C=$(echo $1 | grep -o '::' | wc -l)
    test $C -gt 1 && return 1
    add=""
    for a in $(seq $((8-$D)))
    do
      add=${add}:0
    done
    out=$(echo $1 | sed "s/::/${add}:/;s/^:/0:/;s/:$/:0/")
    echo $out
  else
    return 1
  fi
}

shorten6() {
  addr=$1
  addr=$(echo $addr | sed 's/:0:0:/::/')
  while
    echo $addr | grep -q '::0:'
  do
    addr=$(echo $addr | sed 's/::0:/::/')
  done
  echo $addr
}
