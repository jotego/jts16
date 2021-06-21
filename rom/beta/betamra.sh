#!/bin/bash

OUTDIR=betamra

mkdir -p $OUTDIR
mkdir -p $OUTDIR/_alt

AUXTMP=/tmp/$RANDOM$RANDOM
jtcfgstr -target=mist -output=bash -def $CORES/s16/hdl/jts16.def | grep _START > $AUXTMP
source $AUXTMP

function s16a_mra {
    NAME=$1
    FOLDER=$2
    BUTTONS="$3"
    DIPS="$4"
    CATEGORY="$5"
    CATVER="$6"
    PLATFORM="$7"
    ALTFOLDER="_alt/_$FOLDER"
    mkdir -p "$OUTDIR/$ALTFOLDER"
    mame2dip $NAME.xml -rbf jts16 -outdir $OUTDIR -altfolder "$ALTFOLDER" \
        -rbf-dev fd1094 jts16a2 \
        -skip_desc 16B \
        -skip_desc Taito \
        -skip_desc FD1094 \
        -skip_desc Analog \
        -skip_desc "Fantasy Zone (Prototype, S16A) [No Protection]" \
        -skip_desc "Wonder Boy III Monster Lair (Bootleg Ver. 1, Japan, S16A) [No Protection]" \
        -skip_desc "Wonder Boy III Monster Lair (Bootleg Ver. 2, Japan, S16A) [No Protection]" \
        -rmdipsw Unused \
        -rmdipsw Unknown \
        -dipdef "$DIPS" \
        -info platform "$PLATFORM" \
        -info category "$CATEGORY" \
        -info catver "$CATVER" \
        -info mraauthor jotego,atrac17 \
        -header 32 0x0 \
        -header-dev 0x10 fd1089a=1 fd1089b=2 \
        -setword maincpu 16 reverse \
        -setword sprites 16 reverse \
        -ghost n7751 0x400 \
        -ghost mcu   0x1000 \
        -ghost maincpu:key 0x2000 \
        -start soundcpu    0x040000 \
        -start gfx1        0x088000 \
        -start sprites     0x100000 \
        -start mcu         0x180000 \
        -start maincpu:key 0x182000 \
        -start n7751       0x184000 \
        -start fd1089      0x186000 \
        -fill sprites \
        -frac 1 gfx1 4 \
        -order maincpu soundcpu n7751data gfx1 sprites mcu maincpu:key n7751 \
        -header-offset-bits 8 \
        -header-offset 0 soundcpu n7751data gfx1 sprites mcu maincpu:key n7751 \
        -corebuttons 4 -buttons "$BUTTONS" -beta

}

s16a_mra wb3       "Wonder Boy 3" "Shot,Jump,-" "ff,fd" "Platformer" "Platform/Shooter Scrolling" "Sega S16A"
s16a_mra shinobi   "Shinobi" "Shuriken,Jump,Magic" "ff,fc" "Hack & Slash" "Platform/Fighter Scrolling" "Sega S16A"
s16a_mra alexkidd  "Alex Kidd" "Jump/Swim,Shot,-" "ff,ec" "Platformer" "Platform/Run, Jump & Scrolling" "Sega S16A"
#s16a_mra sdi       "SDI" "Shot" "ff,ff" "Shoot'em Up" "Shooter/Command" "Sega S16A"
#s16a_mra sjryuko   "Sukeban" "None" "ff,ff" "Puzzle" "Tabletop/Mahjong * Mature *" "Sega S16A"
#s16a_mra mjleague  "Major League" "Open Stance,Curb/Shoot/Fork,Close Stance,Pinch Hitter/Sliding/Runner" "ff,ff" "Sports" "Sports/Baseball" "Sega S16A"
#s16a_mra quartet   "Quartet" "Jump,Shot" "ff,ff" "Run & Gun" "Maze/Shooter Large" "Sega S16A"
s16a_mra afighter  "Action Fighter" "Shot,Special Weapon,-" "ff,fc" "Shoot'em Up" "Shooter/Misc. Vertical" "Sega S16A"
s16a_mra fantzone  "Fantasy Zone" "Shot,Bomb,-" "ff,fc" "Shoot'em Up" "Shooter/Flying Horizontal" "Sega S16A"
s16a_mra tetris    "Tetris" "Rotate,Rotate,Rotate" "ff,fd" "Puzzle" "Puzzle/Drop" "Sega S16A"
#s16a_mra aliensyn  "Alien Syndrome" "Shot,-,-" "ff,ff" "Run & Gun" "Maze/Shooter Large" "Sega S16A"
s16a_mra bodyslam  "Body Slam" "Punch/Throw,Kick/Pin,Get Up/Tag" "ff,fd" "Sports" "Sports/Wrestling" "Sega S16A"
#s16a_mra aceattac  "Ace Attack" "None" "ff,ff" "Sports" "Sports/Volleyball" "Sega S16A"
#s16a_mra passsht   "Passing Shot" "Flat,Slice,Lob,Top Spin" "ff,ff" "Sports" "Sports/Tennis" "Sega S16A"
#s16a_mra timescan  "Time Scanner" "L. Flipper/Ball Start,R. Flipper/Lane Shift,-" "ff,ff" "Pinball" "Arcade/Pinball" "Sega S16A"

echo "Enter MiSTer's root password"
scp -r mra/* root@MiSTer.home:/media/fat/_S16


					   
							

exit 0
