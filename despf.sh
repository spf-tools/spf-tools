#!/bin/sh
#
# Usage: ./despf <domain_with_SPF_TXT_record>

domain=${1:-'spf-orig.apiary.io'}

despf() {
  myspf=`host -t txt $1 | grep 'v=spf1' | sed 's/" "//'`
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
  echo $myspf | grep -o 'ip[46]:\S\+' || true
}

despf $domain | sort -u | sort -n -t: -k1.3,2
