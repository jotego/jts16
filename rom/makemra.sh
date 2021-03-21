#!/bin/bash

OUTDIR=mra

mkdir -p $OUTDIR
mkdir -p $OUTDIR/_alt

function s16a_mra {
    NAME=$1
    FOLDER=$2
    BUTTONS="$3"
    ALTFOLDER="_alt/_$FOLDER"
    mkdir -p "$OUTDIR/$ALTFOLDER"
    mame2dip $NAME.xml -rbf jts16 -outdir $OUTDIR -altfolder "$ALTFOLDER" \
        -nobootlegs \
        -header 32 0xFF \
        -setword maincpu 16 reverse \
        -setword sprites 16 reverse \
        -len maincpu   0x40000 \
        -ghost n7751 0x400 \
        -start gfx1    0x68000 \
        -start sprites 0xa8000 \
        -start fd1089  0x1AA000 \
        -len sprites 0x80000 \
        -fill sprites \
        -frac 1 gfx1 4 \
        -order maincpu soundcpu n7751data gfx1 sprites n7751 \
        -header-offset-bits 8 -header-offset 0 soundcpu n7751data gfx1 sprites n7751 \
        -corebuttons 4 -buttons "$BUTTONS"

}

s16a_mra shinobi   "Shinobi" "Shuriken,Jump,Magic"
s16a_mra alexkidd  "Alex Kidd" "Jump,Shot,Other"
s16a_mra sdi       "SDI" "Fire"
s16a_mra sjryuko   "Sukeban" "None"
s16a_mra mjleague  "Major League" "None"
s16a_mra quartet2a "Quartet" "Jump,Shot,Other"
s16a_mra afighter  "Action Fighter" "Shot,Button 2,Button 3"
s16a_mra fantzone  "Fantasy Zone" "Shot,Bomb,Button 3"
s16a_mra wb3       "Wonder Boy 3" "Shot,Jump,Button 3"
s16a_mra tetris    "Tetris" "Turn,Turn,Turn"
s16a_mra aliensyn  "Alien Syndrome" "Shot,Button 2,Button 3"
s16a_mra bodyslam  "Body Slam" "Button 1,Button 2,Button 3"
s16a_mra aceattac  "Ace Attack" "None"
s16a_mra passsht   "Passing Shot" "Button 1,Button 2,Button 3, Button 4"
s16a_mra timescan  "Time Scanner" "Button 1,Button 2,Button 3"

exit 0
