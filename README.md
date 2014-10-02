SPF-tools
=========

Simple tools for keeping the SPF TXT records tidy.

despf.sh is a tool that resolves all `ip4` and `ip6` blocks
found in any included SPF subdomain. It prints all these blocks
`sort(1)`ed and `uniq(1)`ed to stdout, one per line.
Other output (`Getting ...`) is on stderr.

Example:

    ./despf.sh google.com
    Getting _spf.google.com...
    Getting _netblocks.google.com...
    Getting _netblocks2.google.com...
    Getting _netblocks3.google.com...
    ip4:173.194.0.0/16
    ip4:74.125.0.0/16
    ...
    ip6:2a00:1450:4000::/36
    ip6:2c0f:fb50:4000::/36

mkblocks.sh tool is meant to parse a list of blocks produced by
despf.sh and prepare content of TXT records that all fit into one
UDP packet, splitting into more TXT records if needed.

One TXT record per line of standard output.

    ./despf.sh spf-orig.apiary.io | ./mkblocks.sh _spf

Both tools have sane defaults, so you can run just

    ./despf.sh | ./mkblocks.sh

You can verify your current SPF records by running compare.sh.
If the TXT records need an update, it will automatically run
the other tools to print out one updated TXT records, one per line.

Best practice is to put those lines into DNS starting with the
last one. The output tries to help with that by reversing the
output and printing also headers that say which record does the
following line belong to.

    -------------------------------------
    spf6.apiary.io:
    v=spf1 ip6:2c0f:fb50:4000::/36 -all
    spf5.apiary.io:
    v=spf1 ip4:74.63.235.0/24ip4:74.63.236.0/24 ip4:74.63.247.0/24 ip4:75.126.200.128/27 ip4:75.126.253.0/24 ip6:2001:4860:4000::/36 ip6:2404:6800:4000::/36 ip6:2607:f8b0:4000::/36 ip6:2800:3f0:4000::/36 ip6:2a00:1450:4000::/36 ip6:2c0f:fb50:4000::/36 include:spf6.apiary.io -all
    ...
    -------------------------------------

You can change the prefix by running mkblocks.sh with an argument
(e.g. `_spf`).

The last record to update is your root domain's record which just
contains an include. It should be always updated as the last one
and you should keep alternating between `spf` and `_spf` prefixes when
changing records, so the records are all consistent until you change
the root one.


In order to semi-automate the task of updating the records, you can
pipe the output of `mkblocks.sh` with `xsel.sh` (requires `xsel`
obviously :)

Links:

 * https://dmarcian.com/spf-survey/apiary.io
 * http://www.kitterman.com/spf/validate.html
 * http://serverfault.com/questions/584708
