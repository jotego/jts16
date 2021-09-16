; Homebrew replacement for Tough Turf MCU code
; (c) Jose Tejada 2021

    LJMP INIT
    LJMP VBLANK
.ORG 0X13
    RETI

INIT:
    MOV IE,#0x85
    SJMP INIT

READVAL:
    MOV R0,#7
    MOV A,R1
    MOVX @R0,A
    INC R0
    MOV A,R2
    MOVX @R0,A
    INC R0
    MOV A,R3
    MOVX @R0,A
    MOV R0,#5
    MOV A,#2
    MOVX @R0,A  ; Read
    MOV R0,#2
    MOVX A,@R0
RDWAIT:
    ANL A,#40h
    JNZ RDWAIT
    MOV R0,0
    MOVX A,@R0
    MOV R4,A
    INC R0
    MOVX A,@R0
    MOV R5,A
    RET

WRVAL:
    MOV R0,#0xA
    MOV A,R1
    MOVX @R0,A
    INC R0
    MOV A,R2
    MOVX @R0,A
    INC R0
    MOV A,R3
    MOVX @R0,A
    MOV R0,#0
    MOV A,R4
    MOVX @R0,A
    INC R0
    MOV A,R5
    MOVX @R0,A
    ; trigger write
    MOV R0,#5
    MOV A,#1
    MOVX @R0,A  ; Write
    MOV R0,#2
    MOVX A,@R0
WRWAIT:
    ANL A,#40h
    JNZ WRWAIT
    RET

VBLANK:
    MOV IE,#0
    ; Read sound data
    MOV R1,#0
    MOV R2,#0
    MOV R3,#0xE8
    ACALL READVAL
    MOV A,R4
    JZ NOSND
    MOV R0,3
    MOV A,R5
    MOVX @R0,A  ; update sound register
    ; Signal that the command was processed
    MOV R4,#0
    MOV R1,#0
    MOV R2,#0
    MOV R3,#0xE8
    ACALL WRVAL
NOSND:
    ; Read the inputs
    MOV R4,P1       ; System inputs via port 1
    MOV R5,#0xFF
    MOV R1,#0
    MOV R2,#0
    MOV R3,#0xF3
    ACALL WRVAL

    ; Set the vertical interrupt
    MOV R0,#4
    MOV A,#0xB
    MOVX @R0,A
    MOV R1,#4
    MOV IE,#5
    RETI
