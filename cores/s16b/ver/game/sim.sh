#!/bin/bash

SYSNAME=s16b
GAME=altbest5
SCENE=
OTHER=
HEXDUMP=-nohex
SIMULATOR=-verilator
SDRAM_SNAP=

AUXTMP=/tmp/$RANDOM$RANDOM
jtcfgstr -target=mist -output=bash -parse ../../hdl/jts16b.def |grep _START > $AUXTMP
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
	echo "Simulating scene $SCENE"

	if [ ! -e $GAME/char$SCENE.bin ]; then
	    echo Cannot open scene files
	    exit 1
	fi

	drop1    < $GAME/char${SCENE}.bin > char_hi.bin
	drop1 -l < $GAME/char${SCENE}.bin > char_lo.bin

	drop1    < $GAME/pal${SCENE}.bin > pal_hi.bin
	drop1 -l < $GAME/pal${SCENE}.bin > pal_lo.bin

	drop1    < $GAME/obj${SCENE}.bin > obj_hi.bin
	drop1 -l < $GAME/obj${SCENE}.bin > obj_lo.bin

    hexdump -v -e '/2 "%04X\n"' -s 0xe00 $GAME/char${SCENE}.bin > mmr.hex
    hexdump -v -e '/1 "%02X"' $GAME/tilebank${SCENE}.bin > tilebank.hex
    # File must end with \n so it gets read correctly
    echo -e "\n" >> tilebank.hex

	cp $GAME/scr${SCENE}.bin scr.bin
    OTHER="$OTHER -d NOMAIN -video -nosnd"
    if [[ ! "$*" =~ -time ]]; then
        OTHER="$OTHER -time 16"
    fi
    # VRAM snap goes to 20'0000h (bytes) = 10'0000h (words)
    SDRAM_SNAP="-snap scr.bin 0 0x200000"
else
    export Z80=1
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

if [[ ! -z "$SCENE" && -e frame_1.jpg ]]; then
	eom frame_1.jpg 2> /dev/null
fi