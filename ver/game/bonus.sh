#/bin/bash
bonus.py > sim_inputs.hex
# Use -d JTFRAME_J68 for J68_cpu
# compare frame 1604 (FX) with 1599 (J68)
sim.sh -nosnd $* -video 1760 -d SHINOBI_BONUS -w -d DUMP_START=1560 -inputs
