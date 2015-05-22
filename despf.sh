#!/bin/sh
#
# Usage: ./despf <domain_with_SPF_TXT_record>

for cmd in dig awk grep sed cut
do
  type $cmd >/dev/null || exit 1
done

domain=${1:-'spf-orig.jasan.tk'}

findns() {
  ns=""
  dd="$1"
  while
    test -z "$ns"
  do
    ns="`dig +short -t NS $dd | sed 1q`"
    dd="${dd#*.}"
  done
  unset dd
  echo "@$ns"
}

loopfile=`mktemp /tmp/despf-loop-XXXXXXX`
touch $loopfile
trap "rm $loopfile" EXIT INT

printip() {
  ver=${1:-4}
  while read line
  do
    echo "ip$ver:$line"
  done
}

dea() {
  dig +short -t A $1 | printip
  dig +short -t AAAA $1 | printip 6
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
  myns=`findns $host`

  # Loop detection
  echo $host | grep -qxFf $loopfile && {
    echo "Loop detected with $host!" 1>&2
    return 1
  }
  echo "$host" >> $loopfile

  myspf=`dig +short -t TXT $host $myns |
    sed 's/^"//;s/"$//;s/" "//' | grep '^v=spf1'`
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
  echo $myspf | grep -o 'ip[46]:\S\+' || true
}

despf $domain | sort -u
