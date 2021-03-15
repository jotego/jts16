#!/bin/bash

OUTDIR=mra

mkdir -p $OUTDIR
mkdir -p $OUTDIR/_alt

mame2dip shinobi.xml -rbf jts16 -outdir $OUTDIR -altfolder _alt \
    -header 32 0xFF \
    -setword maincpu 16 reverse \
    -setword sprites 16 reverse \
    -frac 1 gfx1 4 \
    -order maincpu soundcpu n7751data gfx1 sprites n7751 \
    -header-offset-bits 8 -header-offset 0 soundcpu n7751data gfx1 sprites n7751 \
    -corebuttons 3 -buttons "Shuriken,Jump,Magic"