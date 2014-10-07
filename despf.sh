#!/bin/sh
#
# Usage: ./despf <domain_with_SPF_TXT_record>

domain=${1:-'spf-orig.apiary.io'}

printip4() {
  while read line
  do
    echo "ip4:$line"
  done
}

dea() {
  dig +short -t A $1 | printip4
}

demx() {
  host=$1
  mymx=`dig +short -t mx $host | awk '{print $2}'`
  for name in $mymx
  do
    dea $name
  done
}

despf() {
  host=$1
  myspf=`host -t txt $host | grep 'v=spf1' | sed 's/" "//'`
  if
    includes=`echo $myspf | grep -o 'include:\S\+'`
  then
    echo $includes | tr " " "\n" | sed '/^$/d' | cut -b 9- | while
      read included
    do
      echo Getting $included... 1>&2
      despf $included
    done
  fi
  echo $myspf | grep -qw a && dea $host
  echo $myspf | grep -qw mx && demx $host
  echo $myspf | grep -o 'ptr:\S\+'
  echo $myspf | grep -o 'ip[46]:\S\+' || true
}

despf $domain | sort -u
