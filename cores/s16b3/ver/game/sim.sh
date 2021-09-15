#!/bin/bash

SYSNAME=s16b3
GAME=tturfu
#GAME=goldnaxe
SCENE=
OTHER=
HEXDUMP=-nohex
SIMULATOR=-verilator
SDRAM_SNAP=

AUXTMP=/tmp/$RANDOM$RANDOM
jtcfgstr -target=mist -output=bash -parse ../../hdl/jts16b3.def |grep _START > $AUXTMP
source $AUXTMP

while [ $# -gt 0 ]; do
    case $1 in
        -g)
            shift
            GAME=$1
            if [ ! -e $ROM/$GAME.rom ]; then
                echo "Cannot find ROM file $ROM/$GAME.rom"
                exit 1
            fi
            ;;
    	-s|-scene)
            shift
    		SCENE=$1;;
    	*)
            OTHER="$OTHER $1";;
    esac
    shift
done

ln -sf $ROM/$GAME.rom rom.bin

if [ ! -z "$SCENE" ]; then
	echo Use the main jts16b simulation setup for scenes
    exit 0
else
    export YM2151=1
    export Z80=1
    export I8051=1
    rm -f char_*.bin pal_*.bin obj_*.bin scr.bin
fi

if which ncverilog >/dev/null; then
    # Options for non-verilator simulation
    SIMULATOR=
    HEXDUMP=
fi

rm -f sdram_bank?.*
jtsim_sdram $HEXDUMP -header 32 \
    -banks $BA1_START $BA2_START $BA3_START \
    -stop $MCU_START \
    -dumpbin fd1094.bin $MAINKEY_START 0x2000 \
    $SDRAM_SNAP || exit $?


jtsim -mist -sysname $SYSNAME $SIMULATOR \
	-videow 320 -videoh 224 -d JTFRAME_DWNLD_PROM_ONLY \
    -d JTFRAME_SIM_ROMRQ_NOCHECK $OTHER || exit $?
