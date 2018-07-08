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

test -n "$DEBUG" && set -x

a="/$0"; a=${a%/*}; a=${a:-.}; a=${a#/}/; BINDIR=$(cd $a; pwd)
. $BINDIR/include/global.inc.sh

# Read DOMAIN and ORIG_SPF from spf-toolsrc
test -r $SPFTRC && . $SPFTRC

test -n "$DOMAIN" || { echo "DOMAIN not set! Exiting."; exit 1; }
test -n "$ORIG_SPF" || { echo "ORIG_SPF not set! Exiting."; exit 1; }

bash -se <<EOF
PATH=$BINDIR:$PATH
cd $BINDIR
exec > $HOME/runspftools.log 2>&1
date
git pull
compare.sh $DOMAIN $ORIG_SPF || despf.sh $ORIG_SPF \
  | normalize.sh | simplify.sh | mkblocks.sh $DOMAIN \
  | mkzoneent.sh | cloudflare.sh $DOMAIN
sleep 300
exec $0
EOF
