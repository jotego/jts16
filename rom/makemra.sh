#!/bin/bash

cd $JTUTIL/src
make || exit $?
cd -
echo "------------"


OUTDIR=mra

mkdir -p $OUTDIR
mkdir -p $OUTDIR/_alt

AUXTMP=/tmp/$RANDOM$RANDOM
DEF=$CORES/s16/hdl/jts16.def
jtcfgstr -target=mist -output=bash -def $DEF|grep _START > $AUXTMP
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
    mame2mra -def $DEF -toml s16a.toml -xml $NAME.xml \
        -outdir $OUTDIR -altdir "$ALTFOLDER" \
        -info platform="$PLATFORM" \
        -info category="$CATEGORY" \
        -info catver="$CATVER" \
        -buttons "$BUTTONS"
}

s16a_mra wb3       "Wonder Boy 3" "Shot,Jump" "ff,fd" "Platformer" "Platform/Shooter Scrolling" "Sega S16A"
s16a_mra shinobi   "Shinobi" "Shuriken,Jump,Magic" "ff,fc" "Hack & Slash" "Platform/Fighter Scrolling" "Sega S16A"
s16a_mra alexkidd  "Alex Kidd" "Jump/Swim,Shot" "ff,ec" "Platformer" "Platform/Run, Jump & Scrolling" "Sega S16A"
s16a_mra sdi       "SDI" "Shot" "ff,ff" "Shoot'em Up" "Shooter/Command" "Sega S16A"
s16a_mra sjryuko   "Sukeban" "None" "ff,ff" "Puzzle" "Tabletop/Mahjong * Mature *" "Sega S16A"
s16a_mra mjleague  "Major League" "Open Stance,Curb/Shoot/Fork,Close Stance,Pinch Hitter/Sliding/Runner" "ff,ff" "Sports" "Sports/Baseball" "Sega S16A"
s16a_mra quartet   "Quartet" "Jump,Shot" "ff,ff" "Run & Gun" "Maze/Shooter Large" "Sega S16A"
s16a_mra afighter  "Action Fighter" "Shot,Special Weapon,-" "ff,fc" "Shoot'em Up" "Shooter/Misc. Vertical" "Sega S16A"
s16a_mra fantzone  "Fantasy Zone" "Shot,Bomb" "ff,fc" "Shoot'em Up" "Shooter/Flying Horizontal" "Sega S16A"
s16a_mra tetris    "Tetris" "Rotate,Rotate,Rotate" "ff,fd" "Puzzle" "Puzzle/Drop" "Sega S16A"
s16a_mra aliensyn  "Alien Syndrome" "Shot" "ff,ff" "Run & Gun" "Maze/Shooter Large" "Sega S16A"
s16a_mra bodyslam  "Body Slam" "Punch/Throw,Kick/Pin,Get Up/Tag" "ff,fd" "Sports" "Sports/Wrestling" "Sega S16A"
s16a_mra aceattac  "Ace Attacker" "None" "ff,ff" "Sports" "Sports/Volleyball" "Sega S16A"
s16a_mra passsht   "Passing Shot" "Flat,Slice,Lob,Top Spin" "ff,ff" "Sports" "Sports/Tennis" "Sega S16A"
s16a_mra timescan  "Time Scanner" "L. Flipper/Ball Start,R. Flipper/Lane Shift,-" "ff,ff" "Pinball" "Arcade/Pinball" "Sega S16A"

# echo "Enter MiSTer's root password"
# scp -r mra/* root@MiSTer.home:/media/fat/_S16
