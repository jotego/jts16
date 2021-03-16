# JTS16

SEGA System 16 compatible verilog core for FPGA by Jose Tejada (jotego).

# Clocks

HSync/VSync (OSSC) 15.73kHz, 60.28Hz

Crystal Oscillators (System 16B)

Location | Freq (MHz) | Use
---------|------------|-------
B1       | 20         | M68k
E12      | 8.000      | Sound
G1       | 25.1748    | Video

Pixel clock: 6.2937 MHz

Estimated geometry:
    400 pixels/line
    261 lines/frame

Core clock: 50.3496 MHz

Dividers:

Clock   |  m   |  n
--------|------|-----
25.1748 |   1  |   2
20      |  29  |  73
8       | 109  | 686

# 8255 Connections

Line   |  Destination
-------|--------------
PA     |  Sound latch
PB3-0  |  Coin lock ?
PB4    |  Display enable
PB6-5  |  ?
PB7    |  Flip (pull down)
PC7    |  Port A handshaking signal /OBF -> Sound /NMI
PC6    |  Port A handshaking signal ACK
PC5-3  |  Unconnected
PC2    |  To PAL 315-5107 pin 9 (SCONT1)
PC1    |  To PAL 315-5108 pin 19 (SCONT0)
PC0    |  To MUTE input on MB3733 amplifier (0=sound disabled)

# Memory Size

Item      |  Size (kB)
----------|------------
Main ROM  |  512
Main RAM  |   16
Object    |    2
Palette   |    4
Char      |    4
Scroll    |   32 (?)

# Support

You can show your appreciation through
* Patreon: https://patreon.com/topapate
* Paypal: https://paypal.me/topapate

# Licensing

Contact the author for special licensing needs. Otherwise follow the GPLv3 license attached.

# Patron Acknowledgement

The following patrons supported the development of JTS16