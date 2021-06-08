; use "cheatzip" script to assemble and send to MiSTer

; The LED will blink if the cheat bits 7:0 are enabled
; CPSx work RAM offset = 30'0000h

; Register use
; SB = LED

    ; enable interrupt
    load sb,0

    ; unlock
    load s0,30
    output s0,30
    load s0,41
    output s0,31
    load s0,ab
    output s0,32
    load s0,0
    output s0,33

    input s0,STATUS
    test s0,1
    jump z, UNLOCKED   ; unlocked, do nothing

    outputk 3,b ; enable display
    call CLS

constant WATCHDOG, 0x40
constant STATUS, 0x80

BEGIN:
    output s0,WATCHDOG

    ; Detect blanking
    input s0,0x80
    and   s0,0x20;   test for blanking
    jump z,inblank
    jump notblank
inblank:
    fetch s1,0
    test s1,0x20
    jump z,notblank
    store s0,0  ; stores last LVBL
    call ISR ; do blank procedure
    jump BEGIN
notblank:
    store s0,0
    jump BEGIN

ISR:
    input s0,2c     ; frame counter
    compare s0,0
    jump nz,SCREEN
    ; invert LED signal
    add sb,1

SCREEN:

    outputk 3,9
    load s4,msg0'upper
    load s3,msg0'lower
    call write_string
    outputk 4,9
    load s4,msg1'upper
    load s3,msg1'lower
    call write_string
    outputk 5,9
    load s4,msg2'upper
    load s3,msg2'lower
    call write_string
    outputk 6,9
    load s4,msg3'upper
    load s3,msg3'lower
    call write_string
    outputk 8,9
    load s4,msg4'upper
    load s3,msg4'lower
    call write_string
    outputk 9,9
    load s4,msg5'upper
    load s3,msg5'lower
    call write_string

CLOSE_FRAME:
    output sb,6     ; LED
    return

write_string:
    load s0,0
.loop:
    call@ (s4,s3)
    sub s2,20
    output s0,8
    output s2,A
    add s0,1
    compare s0,20
    return z
    add s3,1
    addcy s4,0
    jump .loop

    ; s0 screen row address
    ; s1 number to write
    ; modifies s2
    ; s0 updated to point to the next column
WRITE_HEX:
    output s0,8
    load s2,s1
    sr0 s2
    sr0 s2
    sr0 s2
    sr0 s2
    call WRITE_HEX4
    add s0,1
    output s0,8
    load s2,s1
    call WRITE_HEX4
    add s0,1    ; leave the cursor at the next column
    return

    ; s2 number to write
    ; modifies s2
WRITE_HEX4:
    and s2,f
    compare s2,a
    jump nc,.over10
    jump z,.over10
    add s2,16'd
    jump .write
.over10:
    add s2,23'd
.write:
    output s2,a
    return

    ; clear screen
    ; modifies s0,s1,s2
CLS:
    load s0,31
    load s1,31
    load s2,0
.loop_row:
    load s1,31
    output s0,8
.loop_col:
    output s1,9
    output s2,a
    sub s1,1
    jump nc,.loop_col
    sub s0,1
    jump nc,.loop_row
    return


    ; SDRAM address in s2-s0
    ; SDRAM data out in s4-s3
    ; SDRAM data mask in s5
    ; Modifies sf
WRITE_SDRAM:
    output s5, 5
    output s4, 4
    output s3, 3
    output s2, 2
    output s1, 1
    output s0, 0
    output s1, 0xC0   ; s1 value doesn't matter
.loop:
    input  sf, 0x80
    compare sf, 0xC0
    return z
    jump .loop

    ; Modifies sf
    ; Read data in s7,s6
READ_SDRAM:
    output s2, 2
    output s1, 1
    output s0, 0
    output s1, 0x80   ; s1 value doesn't matter
.loop:
    input  sf, 0x80
    compare sf, 0xC0
    jump nz,.loop
    input s6,6
    input s7,7
    return

UNLOCKED:
    outputk 0,b
    output s0,WATCHDOG
    jump UNLOCKED

; strings
string beta0$,  "  (c) Jose Tejada 2021          "
string beta1$,  "  This core is in beta phase    "
string beta2$,  "  Join the beta test team at    "
string beta3$,  "  https://patreon.com/topapate  "
string beta4$,  "  Place the file beta.zip       "
string beta5$,  "  in the folder games/mame      "
string expired$,"  This beta RBF has expired     "
msg0:
    load&return s2, beta0$
msg1:
    load&return s2, beta1$
msg2:
    load&return s2, beta2$
msg3:
    load&return s2, beta3$
msg4:
    load&return s2, beta4$
msg5:
    load&return s2, beta5$
expired:
    load&return s2, expired$

default_jump fatal_error
fatal_error:
    jump fatal_error

    address 3FF    ; interrupt vector
    jump ISR
