#/bin/bash
bonus.py > sim_inputs.hex
sim.sh -nosnd -d JTFRAME_J68 -video 1760 -d SHINOBI_BONUS -w -d DUMP_START=1560 -inputs
