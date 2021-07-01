#!/bin/bash
# Use this script to convert NVRAM dumps to simulation input files
# Data order
# VRAM   32kB - part of SDRAM: bank0 at 0x10'0000
# CHAR    4kB - split 16-bit bin dump
# PAL     4kB - split 16-bit bin dump
# OBJRAM  2kB - split 16-bit bin dump

FILE="$1"
SCENE=$2

SCR_START=0
CHAR_START=32
PAL_START=36
OBJRAM_START=40

if [ $(basename `pwd`) = game ]; then
    echo "Call this script from the simulation scene folder"
    exit 1
fi

if [ ! -e "$FILE" ]; then
    echo "Cannot open file $FILE"
    exit 1
fi

if [ -z "$SCENE" ]; then
    echo "You need to specify the simulation scene for the output files"
    exit 1
fi

dd if="$FILE" of=scr$SCENE.bin  skip=$SCR_START  count=32 bs=1024 || exit $?
dd if="$FILE" of=char$SCENE.bin skip=$CHAR_START count=4 bs=1024 || exit $?
dd if="$FILE" of=pal$SCENE.bin skip=$PAL_START count=4 bs=1024 || exit $?
dd if="$FILE" of=obj$SCENE.bin skip=$OBJRAM_START count=2 bs=1024 || exit $?

# rm "$FILE"