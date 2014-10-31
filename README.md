# SPF-tools

Simple tools for keeping the SPF TXT records tidy.


## despf.sh

`despf.sh` is a tool that resolves all `ip4` and `ip6` blocks
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


## mkblocks.sh

`mkblocks.sh` tool is meant to parse a list of blocks produced by
despf.sh and prepare content of TXT records that all fit into one
UDP packet, splitting into more TXT records if needed.

One TXT record per line of standard output.

    ./despf.sh spf-orig.apiary.io | ./mkblocks.sh apiary.io _spf

You can change the defaults and then just run

    ./despf.sh | ./mkblocks.sh


## compare.sh

Current SPF records can be verified by running `compare.sh`.
If the TXT records need an update, it will automatically run
the other tools to print out or copy into pastebuffer the
new TXT records in reverse order.

Best practice is to put those lines into DNS starting with the
last one. That's why `xsel.sh` reverses the input gathered from
`mkblocks.sh` by using `tac`.

The last record to update is root domain's record which just
contains an include. It should be always updated as the last one
and the prefix alternated between `spf` and `_spf` prefixes when
changing records, so the records are all consistent until the
root one is changed.


## xsel.sh

In order to semi-automate the task of updating the records,
pipe the output of `mkblocks.sh` to `xsel.sh`.

## simplify.sh

This script takes out individual IPv4 addresses which are already
contained in CIDR ranges.

## Example

    ./despf.sh | ./mkblocks.sh | ./simplify.sh | ./xsel.sh


## Links

 * https://dmarcian.com/spf-survey/apiary.io
 * https://dmarcian.com/spf-survey/spf-orig.apiary.io
 * http://www.kitterman.com/spf/validate.html
 * http://serverfault.com/questions/584708
 * http://www.openspf.org/SPF_Record_Syntax
 * http://tools.ietf.org/html/rfc7208#section-5.5
 * http://tools.ietf.org/html/rfc7208#section-14.1
