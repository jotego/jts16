#!/bin/bash

OUTDIR=mra

mkdir -p $OUTDIR
mkdir -p $OUTDIR/_alt

AUXTMP=/tmp/$RANDOM$RANDOM
jtcfgstr -target=mist -output=bash -def ../hdl/jts16.def|grep _START > $AUXTMP
source $AUXTMP

function s16a_mra {
    NAME=$1
    FOLDER=$2
    BUTTONS="$3"
    DIPS="$4"
    CATEGORY="$5"
    CATVER="$6"
    ALTFOLDER="_alt/_$FOLDER"
    mkdir -p "$OUTDIR/$ALTFOLDER"
    mame2dip $NAME.xml -rbf jts16 -outdir $OUTDIR -altfolder "$ALTFOLDER" \
        -skip_desc 16B \
        -skip_desc Taito \
        -skip_desc FD1094 \
        -skip_desc "Fantasy Zone (Time Attack, bootleg)" \
        -skip_desc "Fantasy Zone (Prototype, S16A)" \
        -rmdipsw "Unused" \
        -dipdef "$DIPS" \
        -info category "$CATEGORY" \
        -info catver "$CATVER" \
        -header 32 0x0 \
        -header-dev 0x10 fd1089a=1 fd1089b=2 \
        -setword maincpu 16 reverse \
        -setword sprites 16 reverse \
        -ghost n7751 0x400 \
        -ghost mcu   0x1000 \
        -ghost maincpu:key 0x2000 \
        -start soundcpu    $BA1_START \
        -start gfx1        $BA2_START \
        -start sprites     $BA3_START \
        -start mcu         $MCU_START \
        -start maincpu:key $MAINKEY_START \
        -start n7751       $N7751_START \
        -start fd1089      $FD1089_START \
        -fill sprites \
        -frac 1 gfx1 4 \
        -order maincpu soundcpu n7751data gfx1 sprites mcu maincpu:key n7751 \
        -header-offset-bits 8 \
        -header-offset 0 soundcpu n7751data gfx1 sprites mcu maincpu:key n7751 \
        -corebuttons 4 -buttons "$BUTTONS" -cheat

}

s16a_mra wb3       "Wonder Boy 3" "Shot,Jump,-" "ff,fd" "Platformer" "Platform/Shooter Scrolling"
s16a_mra shinobi   "Shinobi" "Shuriken,Jump,Magic" "ff,fc" "Hack & Slash" "Platform/Fighter Scrolling"
s16a_mra alexkidd  "Alex Kidd" "Jump/Swim,Shot,-" "ff,ec" "Platformer" "Platform/Run, Jump & Scrolling"
#s16a_mra sdi       "SDI" "Shot"
#s16a_mra sjryuko   "Sukeban" "None"
#s16a_mra mjleague  "Major League" "Open Stance,Curb/Shoot/Fork,Close Stance,Pinch Hitter/Sliding/Runner"
#s16a_mra quartet   "Quartet" "Jump,Shot"
s16a_mra afighter  "Action Fighter" "Shot,-,-" "ff,fc" "Shoot'em Up" "Shooter/Misc. Vertical"
s16a_mra fantzone  "Fantasy Zone" "Shot,Bomb,-" "ff,fc" "Shoot'em Up" "Shooter/Flying Horizontal"
#s16a_mra tetris    "Tetris" "Rotate,Rotate,Rotate"
#s16a_mra aliensyn  "Alien Syndrome" "Shot,-,-"
#s16a_mra bodyslam  "Body Slam" "Punch/Throw/Attack,Kick/Tag/Pin,-"
#s16a_mra aceattac  "Ace Attack" "None"
#s16a_mra passsht   "Passing Shot" "Flat,Slice,Lob,Top Spin"
#s16a_mra timescan  "Time Scanner" "L. Flipper/Ball Start,R. Flipper/Lane Shift,-"

echo "Enter MiSTer's root password"
scp -r mra/* root@MiSTer.home:/media/fat/_S16

mv '/mra/* root@MiSTer.home:/media/fat/_S16/mra/_alt/_Wonder Boy 3/Wonder Boy III Monster Lair (Set 5, Japan, S16A) [FD1089A 317-0086].mra' '/mra/* root@MiSTer.home:/media/fat/_S16/mra/Wonder Boy III Monster Lair (Set 5, Japan, S16A) [FD1089A 317-0086].mra'

sed -i 's/quot/amp/g' /mra/* root@MiSTer.home:/media/fat/_S16/mra/*.mra
sed -i 's/quot/amp/g' /mra/* root@MiSTer.home:/media/fat/_S16mra/_alt/"_Shinobi"/*.mra
sed -i 's/quot/apos/g' /mra/* root@MiSTer.home:/media/fat/_S16/mra/_alt/"_Action Fighter"/*.mra
sed -i 's/quot/apos/g' /mra/* root@MiSTer.home:/media/fat/_S16/mra/_alt/"_Fantasy Zone"/*.mra


exit 0

#/mnt/c/jotego/s16/mra/
#/mnt/c/jotego/s16/mra/_alt/