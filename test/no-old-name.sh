#!/bin/sh
# No tracked file says the product's old name: the repository was renamed, and a word left behind is one nobody
# updates. The pattern is spelled so that it does not match this file.
#
# Run from the repository root: test/no-old-name.sh
set -eu
if git grep -n -I -i 's[o]kar' -- . ; then
    echo "FAULT the tracked files above still say the old name"
    exit 1
fi
echo "OK    no tracked file says the old name"
