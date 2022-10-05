#!/bin/bash
set -eux

rewrite() {
    echo -e "% $1\n% $2\n\n$(cat $1)\n\n% --->\n% $(../run $1)" >$1
}

rewrite a.lgt 'A graph with an nullary atom `A`.'
rewrite err1.lgt 'Parser error (unmatched parentheses).'
rewrite dlist.lgt 'Pop the last element of a difference list (length 1).'
rewrite dlist2.lgt 'Append two difference lists.'
rewrite dlist3.lgt 'Rotate a difference list (push an element to front from back).'
rewrite dlist4.lgt 'Pop the last element of a difference list (length 2).'
rewrite fusion.lgt 'Fuse a local links `_Z1` and `_Z2`.'
rewrite let1.lgt 'Testing let binding.'
rewrite let2.lgt 'Testing let binding.'
rewrite letrec1.lgt 'Pop all the elements from back of a difference list.'
rewrite lltree.lgt 'A leaf linked tree.'
rewrite lltree1.lgt 'Map leaves of an leaf-linked tree.'
rewrite lltree2.lgt 'Failure: map leaves of an leaf-linked tree but unsuccessful.'
