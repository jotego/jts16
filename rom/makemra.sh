#!/bin/bash

OUTDIR=mra

mkdir -p $OUTDIR
mkdir -p $OUTDIR/_alt

function s16a_mra {
    NAME=$1
    BUTTONS="$2"
    mame2dip $NAME.xml -rbf jts16 -outdir $OUTDIR -altfolder _alt \
        -header 32 0xFF \
        -setword maincpu 16 reverse \
        -setword sprites 16 reverse \
        -len maincpu   0x40000 \
        -len n7751data 0x20000 \
        -len gfx1      0x40000 \
        -len sprites   0x80000 \
        -frac 1 gfx1 4 \
        -order maincpu soundcpu n7751data gfx1 sprites n7751 \
        -header-offset-bits 8 -header-offset 0 soundcpu n7751data gfx1 sprites n7751 \
        -corebuttons 4 -buttons "$BUTTONS"

}

s16a_mra shinobi   "Shuriken,Jump,Magic"
s16a_mra alexkidd  "Jump,Shot,Other"
s16a_mra sdi       "Fire"
s16a_mra sjryuko   "None"
s16a_mra mjleague  "None"
s16a_mra quartet2a "Jump,Shot,Other"

exit 0
