#!/bin/bash

# System 16A
mame2mra -core s16 -year "2021-2022" $*
# System 16B
mame2mra -core s16b -year "2021-2022" $*

# Copy to MiSTer
sshpass -p 1 scp -r mra/* root@MiSTer.home:/media/fat/_S16
