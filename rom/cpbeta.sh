#!/bin/bash

rm -rf beta
mkdir beta

while read LINE; do
    if [ -z "$LINE" ]; then continue; fi
    if [ ${LINE:0:1} = \# ]; then continue; fi
    MATCH=$(find mra -name "*.mra" -print0 | xargs -0 grep -l \>$LINE\< )
    MATCH=${MATCH#mra/}
    if [ ! -e mra/"$MATCH" ]; then
        echo Cannot find mra/"$MATCH"
        exit 1
    fi
    if [ -z "$MATCH" ]; then
        continue
    fi
    DIR=$(dirname "$MATCH")
    mkdir -p beta/"$DIR"
    cp mra/"$MATCH" beta/"$DIR"
done < beta.txt
