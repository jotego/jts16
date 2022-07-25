#!/bin/bash
# MAME:
# save rdram.bin,80000,1000

cat rdram.bin | drop1 > rdram_lo.bin
cat rdram.bin | drop1 -l > rdram_hi.bin

sim.sh -d NOMAIN -d NOSUB -nosnd -video 2 -d GRAY $*