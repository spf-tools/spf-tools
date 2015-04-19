#!/bin/sh

bash -se <<EOF
PATH=$PWD:$PATH
git pull
compare.sh || despf.sh \
  | simplify.sh | mkblocks.sh \
  | mkzoneent.sh | cloudflare.sh
sleep 300
exec $0
EOF
