mydig() {
  dig +time=1 +short "$@" || { echo "DNS lookup error!" >&2; cleanup; false; }
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
  while read line
  do
    if echo $line | grep -q ':'; then ver=6
    elif echo $line | grep -q '\.'; then ver=4
    else EXIT=1; break 1
    fi
    echo "ip${ver}:$line"
  done
  return $EXIT
}

# dea <hostname>
# dea both.spf-tools.ml
# 1.2.3.4
# fec0::1
dea() {
  for TYPE in A AAAA; do mydig -t $TYPE $1 | printip; done
  true
}

# demx <domain>
# Get MX record for a domain
demx() {
  mymx=$(mydig -t MX $1 | awk '{print $2}' | grep -m1 .)
  for name in $mymx; do dea $name; done
}

# parsepf <host>
parsepf() {
  host=$1
  myns=$(findns $host)
  mydig -t TXT $host @$myns | sed 's/^"//;s/"$//;s/" "//' \
    | grep '^v=spf1' | grep .
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
  echo $myspf | grep -qw a && dea $host
  echo $myspf | grep -qw mx && demx $host
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
