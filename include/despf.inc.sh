mydig() {
  dig +time=1 +short "$@" || { echo "DNS lookup error!" >&2; cleanup; false; }
}

mydig_notshort() {
  dig +time=1 +noall +answer "$@" || { echo "DNS lookup error!" >&2; cleanup; false; }
}

# findns <domain>
# Find an authoritative NS server for domain
findns() {
  dd="$1"; ns=""; dig=${2:-mydig}
  while test -z "$ns"
  do
    ns=$($dig -t NS $dd) && echo $dd | grep -q '\.' && dd="${dd#*.}" || {
      unset ns
      break 1
    }
  done
  echo "$ns" | grep .
}

# printip <<EOF
# 1.2.3.4
# fec0::1
# EOF
# ip4:1.2.3.4
# ip6:fec0::1
printip() {
  if [ "x" != "x$1" ] ; then 
    prefix="/$1";
  fi
  while read line
  do
    if echo $line | grep -q ':'; then ver=6
    elif echo $line | grep -q '\.'; then ver=4
    else EXIT=1; break 1
    fi
    echo "ip${ver}:${line}${prefix}"
  done
  return $EXIT
}

# dea <hostname>
# dea both.spf-tools.ml
# 1.2.3.4
# fec0::1
dea() {
  for TYPE in A AAAA; do mydig_notshort -t $TYPE $1 | grep -v CNAME | awk '{print $5}' | printip $2; done
  true
}

# demx <domain>
# Get MX record for a domain
demx() {
  mymx=$(mydig -t MX $1 | awk '{print $2}' | grep -m1 .)
  for name in $mymx; do dea $name $2; done
}

# parsepf <host>
parsepf() {
  host=$1
  myns=$(findns $host)
  mydig -t TXT $host @$myns | sed 's/^"//;s/"$//;s/" "//' \
    | grep -E '^v=spf1\s+' | grep .
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

# getamx <a:modifiers>
# e.g. a="a a:gnu.org a:google.com/24"
getamx() {
  host=$1
  local myloop=$2
  shift
  shift
  for record in $* ; do 
    local ahost=$(echo $record | cut -s -d: -f2-)
    if [ "x" = "x$ahost" ] ; then
      lookuphost="$host";
      cidr="32";
      mech="$record"
    else
      mech=$(echo $record | cut -s -d: -f1)
      cidr=$(echo $ahost | cut -s -d\/ -f2-)
      if [ "x" = "x$cidr" ] ; then
        lookuphost=$ahost
        cidr="32";
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
  myspf=$(parsepf $host)
  getem $myloop $(echo $myspf | grep -Eo 'include:\S+')
  getamx $host $myloop $(echo $myspf | grep -Eo -w '(mx|a)(:\S+)?')
  echo $myspf | grep -Eo 'ip[46]:\S+' || true
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
