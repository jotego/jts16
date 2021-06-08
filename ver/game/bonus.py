#!/usr/bin/python
# Values for J68 CPU

for i in range(1,2000):
    inp=0
    # Coin
    if(i>15 and i<18):
        inp |=1<<0
    # Start
    if(i>20 and i<22):
        inp |=1<<2
    # Fire
    if(i>300 and i<1450):
        #inp |= ((i&4)!=0) << 8;
        if ( (i%10) == 0 ):
            inp |= 0x100
    # Move left
    if( i>300 and i<330 ):
        inp |= 1<<5
    # Move Right
    if( i>606 and i<652 ):
        inp |= 1<<4
    # Move back left
    if( i>700 and i<742 ):
        inp |= 1<<5
    # Move back left
    if( i>918 and i<930 ):
        inp |= 1<<5

    # 2 ninjas
    # Move Right
    if( i>994 and i<1052 ):
        inp |= 1<<4
    # Move back left
    if( i>1200 and i<1246 ):
        inp |= 1<<5
    # print input
    print "%X" % inp

