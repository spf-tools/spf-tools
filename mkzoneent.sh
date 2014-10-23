#!/bin/sh

sed '1!G;h;$!d' | while read line
do
  subdomain="`echo $line | cut -d^ -f1 | awk '{print $1}'`."
  output=`echo $line | cut -d^ -f2`
  echo $subdomain 1800 IN TXT $output
done
