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

for cmd in awk grep sed cut
do
  type $cmd >/dev/null || exit 1
done

sed '1!G;h;$!d' | while read line
do
  subdomain="$(echo $line | cut -d^ -f1 | awk '{print $1}')."
  output=$(echo $line | cut -d^ -f2)
  echo $subdomain 1800 IN TXT $output
done
