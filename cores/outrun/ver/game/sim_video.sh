#!/bin/bash
# MAME:
# save rdram.bin,80000,1000,1
# the ,1 is for the sub cpu
# Use special MAME compilation for sprite dumps

sim.sh -d NOMAIN -d NOSUB -nosnd -video 2 -d GRAY -verilator $*