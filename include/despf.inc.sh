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

myhost() {
  host -W $DNS_TIMEOUT "$@"
}

get_txt() {
  myhost -t TXT "$@" | cut -d\" -f2- | sed -e 's/\" \"//g;s/\"$//'
}

get_mx() {
  myhost -t MX "$@" | awk '/mail is handled/ {print $NF}'
}

get_addr() {
  myhost -t "$@" | awk '/alias/ {print $NF} /address/ {print $NF}'
}

get_ns() {
  myhost -t NS "$@" | awk '/name server/ {print $NF}'
}

# findns <domain>
# Find an authoritative NS server for domain
findns() {
  dd="$1"; ns="";
  while test -z "$ns"
  do
    if
      ns=$(get_ns $dd | grep .)
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
# dea both.jasan.tk
# 1.2.3.4
# fec0::1
dea() {
  for TYPE in A AAAA; do get_addr $TYPE $1 | printip $2; done
  true
}

# demx <domain> <cidr>
# Get MX record for a domain
demx() {
  mymx=$(get_mx $1)
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
    myns=$(sed -n 's/^nameserver \([\.:0-9a-f]*\)/\1/p' /etc/resolv.conf)
  fi
  for ns in $myns
  do
    get_txt $host $ns 2>/dev/null \
      | grep -Eio 'v=spf1 [^"]+' && break
  done
}

# in_list item list
# e.g _spf.google.com  salesforce.com:google.com:outlook.com
in_list() {
  test $# -eq 2 && echo $2 | grep -wq $1
}

# has_macro item
# e.g %{i}.domain.com
has_macro() {
  echo $1 | grep '%{' > /dev/null
}

# getem <includes>
# e.g. includes="include:gnu.org include:google.com"
getem() {
  myloop=$1
  shift
  echo $* | tr " " "\n" | sed '/^$/d' | cut -b 9- | while read included
  do
    if
      in_list "$included" "$DESPF_SKIP_DOMAINS"
    then
      echo "Skipping $included" 1>&2;
      echo "include:$included"
    elif
      has_macro "$included"
    then
      echo "Skipping (has macros) $included" 1>&2;
      echo "include:$included"
    else
      echo Getting $included 1>&2;
      despf $included $myloop
    fi
  done
}

# getamx host mech [mech [...]]
# e.g. host="jasan.tk"
# e.g. mech="a a:gnu.org a:google.com/24 mx:gnu.org mx:jasan.tk/24"
getamx() {
  local cidr ahost
  host=$1
  shift
  for record in $* ; do 
    cidr=$(echo $record | cut -s -d\/ -f2-)
    ahost=$(echo $record | cut -s -d: -f2-)
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
    mech=$(echo $mech | tr '[A-Z]' '[a-z]')
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
  dogetem=$(echo $myspf | grep -Eio 'include:[^[:blank:]]+') \
    && getem $myloop $dogetem
  dogetamx=$(echo $myspf | grep -Eio -w '(mx|a)((\/|:)[^[:blank:]]+)?')  \
    && getamx $host $dogetamx
  echo $myspf | grep -Eio 'ip[46]:[^[:blank:]]+' | cut -d: -f2- | printip
  echo $myspf | grep -Eio '(exists|ptr):[^[:blank:]]+'
  set -e
}

cleanup() {
  myloop=$1
  test -n "$myloop" && rm ${myloop}*
}

despfit() {
  hosts="$1"
  myloop=$2

  # Make sort(1) behave
  export LC_ALL=C
  export LANG=C

  for host in $hosts
  do
    despf $host $myloop
  done | sort -u
}

checkval4() {
  ip=$1
  cidr=${2#/}
  test -n "$cidr" && { numlesseq $cidr 32 || return 1; }

  D=$(echo $ip | grep -Eo '\.' | wc -l)
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
  D=$(echo $1 | grep -Eo ':' | wc -l)
  if
    test $D -eq 7
  then
    echo $1
  elif
    test $D -le 7 && echo $1 | grep -q '::'
  then
    C=$(echo $1 | grep -Eo '::' | wc -l)
    test $C -gt 1 && return 1
    add=""
    for a in $(awk -v MYEND=$((8-$D)) 'BEGIN { for(i=1;i<=MYEND;i++) print i }')
    do
      add=${add}:0
    done
    out=$(echo $1 | sed "s/::/${add}:/;s/^:/0:/;s/:$/:0/")
    echo $out
  else
    return 1
  fi
}
