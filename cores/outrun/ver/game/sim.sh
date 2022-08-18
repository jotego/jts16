#!/bin/bash

SYSNAME=outrun
GAME=jtoutrun
SIMULATOR=-verilator

eval `jtcfgstr -target=mist -output=bash -core outrun`

if which ncverilog >/dev/null; then
    # Options for non-verilator simulation
    SIMULATOR=
    HEXDUMP=
fi

# Fast load
# rm -f sdram_bank*
# dd if=rom.bin of=sdram_bank0.bin ibs=16 skip=1 conv=swab
$JTFRAME/bin/rom2sdram.sh -header 16 -swab || exit $?

jtsim -mist -sysname $SYSNAME $SIMULATOR \
	-d JTFRAME_DWNLD_PROM_ONLY -d JTFRAME_SIM_DIPS=$(printf "%d" 0xfeff) \
    -d JTFRAME_SIM_ROMRQ_NOCHECK $* || exit $?
