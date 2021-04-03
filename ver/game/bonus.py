#!/usr/bin/python

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
        inp |= ((i&4)!=0) << 8;
    # Move left
    if( i>300 and i<330 ):
        inp |= 1<<5
    # Move Right
    if( i>606 and i<652 ):
        inp |= 1<<4
    # Move back left
    if( i>700 and i<746 ):
        inp |= 1<<5

    # 2 ninjas
    # Move Right
    if( i>1006 and i<1052 ):
        inp |= 1<<4
    # Move back left
    if( i>1200 and i<1246 ):
        inp |= 1<<5
    # print input
    print "%X" % inp

