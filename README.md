# JTS16

SEGA System 16 compatible verilog core for FPGA by Jose Tejada (jotego).

# Supported Games

As of 2nd of April 2021, only unprotected, System 16A games that don't use the i8751 microcontroller will work. The only game that has been thoroughly tested is Shinobi.

Some of the features needed for the rest of the games are already implemented but I still haven't hooked up all the elements together.

# Known Problems

-If you win the bonus stage the game will halt
-The sprite surface may not be covering the top and bottom screen lines
-Bus timings are only approximated, and may be slower than the original timing
-The refresh rate is based on a single PCB measurement, it may be off because of device ageing

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

80's spaceman                           ARCADEAGES
Adam Davis                              Adam Zorzin
Adrian Labastida Cañizares              Adrian Nabarro
Alan Shurvinton                         Alberta Dave
Alexander Lash                          Alexander Upton
Alfonso Clemente                        Alfredo Henriquez
Alonso J. Núñez                         Anders Rensberg
Andrea Chiavazza                        Andreas Micklei
Andrew Ajello                           Andrew Boudreau
Andrew Francomb                         Andrew Moore
Andy Palmer                             Andyways
Angelo Kanaris                          Anthony Monaco
Anton Gale                              Antonio Villena
Antwon                                  Aquijacks (Flashjacks MSX)
Arcade Express                          Arjan de Lang
Atom                                    Banane
Bear S                                  Ben Toman
Bender                                  Bitmap Bureau
Bliz 452                                Bob Gallardo
Boogermann                              Brandon Smith
Brandon Thomas                          Brent Fraser Weatherall
Brian Peek                              Brian Plummer
Brian Sallee                            C
Cameron Tinker                          Carrboroman
Cesar Sandoval                          Charles
Chi Wai Tran                            Choquer0
Chris Jardine                           Chris Mzhickteno
Chris W Miller                          Chris smith
Christian                               Christian Bailey
Christopher Brown                       Christopher Gelatt
Christopher Harvey                      Christopher Tuckwell
Clinton Cronin                          Cobra Clips Gaming
Coldheat007                             Colt83
Connor Glynn                            Cornelle Janse Van Rensburg
D.J. Estreito                           Dakken
Dan                                     Daniel
Daniel Bauza                            Daniel Casadevall
Daniel Fowler                           Daniel Zetterman
Daniel_papa                             Darren Chell
Darren Wootton                          Dasutin
David Ashby                             David Drury
David Fleetwood                         David Jones
David Mills Jr.                         David Moylan
Diana Carolina                          Don Gafford
DrMnike                                 Ed Balan
Edward Rana                             Epixjava
Eric J Faulkes                          Eric Schlappi
Eric Walklet                            Filip Kindt
Five Year Guy                           Focux
Francis B                               Frank Glaser
Frédéric Mahé                           Gladius
Gluthecat                               Gonzalo López
Goolio                                  Greg
Gregory Val                             Gus Douboulidis
HFSPlay                                 Handheld Obsession
Hard Rich                               Henrik Nordström
Henry                                   Ian Court
Ibrahim                                 ItsBobDudes
JPS (RetroFPGA)                         Jacob Hoffman
Jacob Lawter                            James Dingo
James Kilgore                           James Williams
Jason Nagy                              Javier Rodas
Jeff Despres                            Jeff Roberts
Jeremy Hasse                            Jeremy Kelaher
Jesse Clark                             Jim Knowler
Jo Tomiyori                             Jockel
Joeri van Dooren                        Johan Smolinski
John Casey                              John Fletcher
John Lange                              John Schaeffer
John Wilson                             Jonah Phillips
Jonathan Brochu                         Jonathan Loor
Jonathan Tuttle                         Jootec from Mars
Jorge Slowfret                          Jork Sonkinfield
Josh Emery                              Josiah Wilson
Juan Francisco Roco                     Justin D'Arcangelo
Keith Gordon                            Kem Yos
Kevin Gudgeirsson                       Kitsuake
KnC                                     Krycek7o2
L.Rapter                                Laurent Cooper
Lee Grocott                             Lee Osborne
Leslie Law                              Lionel LENOBLE
Louis Martinez                          Luc JOLY
Magnus Kvevlander                       Manuel Astudillo
Marcelo Carrapatoso                     Marcus Hogue
Mark Baffa                              Mark Davidson
Mark Haborak                            MarthSR
Martin Ansin                            Martin Birkeldh
Matheus                                 Matt Elder
Matt Evans                              Matt Lichtenberg
Matt McCarthy                           Matt ODonnell
Matt Postema                            Matthew Humphrey
Matthew Woodford                        Matthew Young
MechaGG                                 Megan Alnico
MiSTerFPGA.co.uk                        Michael Deshaies
Michael Rea                             Michael Yount
Mick Stone                              Mike Jegenjan
Mike Olson                              Mike Parks
MoonZ                                   Mottzilla
Nailbomb                                Narugawa
Neil St Clair                           Nelson Jr
Nick Delia                              Nico Stamp
Nicolas Hurtado                         NonstopXiaowei
Oliver Jaksch                           Oliver Wndmth
Oriez                                   Oscar Laguna Garcia
Oskar Sigvardsson                       Parker Blackman
Patrick Roman Fabri                     Paul M
PeFClic                                 Per Ole Klemetsrud
Peter Bray                              Philip Lawson
Phillip McMahon                         Pierre-Emmanuel Martin
PsyFX                                   Purple Tinker
Rachael Netz                            RandomRetro
Raph Furendo                            ReTr0~g!GGles
RetroPrez                               Richard Eng
Richard Malcolm-Smith                   Richard Murillo
Richard Simpson                         Rick Ochoa
Robert MacLean                          Robert Mullings
Roman Buser                             Ronald Dean
Ryan                                    Ryan Fig
Ryan O'Malley                           Sam Hall
Samuel Warner                           Sassbasket Silvercloud
Shawn Henderson                         Sofia Rose
Spank Minister                          Spencer Bradley
SteelRush                               Stefan Krueger
Steven Hansen                           Steven Wilson
Steven Yedwab                           Stuart Morton
SuperBabyHix                            Taehyun Kim
Tarnjeet Bhachu                         Thomas Irwin
Tobias Dossin                           Toby Boreham
Torren Beitler                          Travis Brown
Trifle                                  Tym Whitney
Ulf Skutnabba                           Ultrarobotninja
Victor Bly                              Victor Fontanez
Víctor Gomariz Ladrón de Guevara        William Clemens
Xzarian                                 Zach Marquette
Zoltan Kovacs                           alejandro carlos
angel_killah                            asdfgasfhsn
atrac17                                 blackwine
brian burney                            cbab
chauviere benjamin                      cohge
dannahan                                deathwombat
derFunkenstein                          gunmakuma
hyp36rmax                               kccheng
kernelchagi                             natalie
nonamebear                              nullobject
rsn8887                                 scapeghost
yoaarond