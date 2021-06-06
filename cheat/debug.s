; use "cheatzip" script to assemble and send to MiSTer

; The LED will blink if the cheat bits 7:0 are enabled
; CPSx work RAM offset = 30'0000h

; Register use
; SA = frame counter
; SB = LED

    ; enable interrupt
    load sa,0   ; SA = frame counter, modulo 60
    load sb,0
    load s0,1
    output s0,a ; enable display
    call CLS
BEGIN:
    output s0,0x40

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
    compare sa,0
    jump nz,SCREEN
    ; invert LED signal
    add sb,1

SCREEN:
    ; Show scroll data
    ; Scroll 1 pages
    load  s0,0x44
    load  s3,1
    call  write_st16
    ; Scroll 1 Hpos
    add   s0,2
    load  s3,9
    call  write_st16
    ; Scroll 1 Vpos
    add   s0,2
    load  s3,5
    call  write_st16

    ; Scroll 2 pages
    load  s0,0x54
    load  s3,3
    call  write_st16
    ; Scroll 2 Hpos
    add   s0,2
    load  s3,11
    call  write_st16
    ; Scroll 2 Vpos
    add   s0,2
    load  s3,7
    call  write_st16

CLOSE_FRAME:
    output sb,6     ; LED
    ; Frame counter
    add sa,1
    compare sa,59'd
    jump nz,.else
    load sa,0
.else:
    return

    ; writes 16-bit status data
    ; s3 points to the MSB st_addr, the LSB is meant to be in s3-1
    ; s2 is modified
    ; s0 is updated to point to the next column
write_st16:
    output s3,c
    load s1,d
    call WRITE_HEX
    sub s3,1
    output s3,c
    load s1,d
    call WRITE_HEX
    return


    ; s0 screen address
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
    output s2,9
    return

CLS:
    load s0,0
    load s1,0
.loop:
    output s0,8
    output s1,9
    add s0,1
    jump nc,.loop

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

default_jump fatal_error
fatal_error:
    jump fatal_error

    address 3FF    ; interrupt vector
    jump ISR