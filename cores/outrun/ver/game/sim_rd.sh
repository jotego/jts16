#!/bin/bash

cat rdram.bin | drop1 > rdram_lo.bin
cat rdram.bin | drop1 -l > rdram_hi.bin

sim.sh -d NOMAIN -d NOSUB -nosnd -video 4 -d GRAY -w