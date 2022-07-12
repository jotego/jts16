RAM     EQU $60000
SIO     EQU $90000

    ORG 0
    DC.L RAM+$8000
    DC.L RESET
    ORG $100

RESET:  
    ; Set the mapper values
    LEA.L $FFFFFF20,A0
    LEA.L MAPPER_LUT,A1
    MOVE.L #$F,D0
MAPPER_CFG:
    MOVE.W (A1)+,(A0)+
    DBRA D0,MAPPER_CFG

    ; copy the ROM
    MOVE.L #0,A0
    MOVE.L #RAM,A1
    MOVE.L #$8000>>2-1,D0
COPY_ROM:
    MOVE.L (A0)+,(A1)+
    DBF D0,COPY_ROM

    ; test the RAM vs ROM
    MOVE.L #0,A0
    MOVE.L #RAM,A1
    MOVE.L #$8000>>2-1,D0
    MOVE.L #1,D7
CMP_ROM:
    MOVE.L (A0)+,D1
    CMP.L (A1)+,D1
    BNE BAD

GOOD:
    MOVE.W #$BABE,D0
    MOVE.L #RAM,A0
    MOVE.W D0,(A0)
    BRA GOOD

BAD:
    MOVE.W #$BAD,D0
    MOVE.L #RAM,A0
    MOVE.W D0,(A0)+
    MOVE.W D7,(A0)
    BRA BAD

MAPPER_LUT:
    ;DS.W $0200, $0000, $0D00, $1000, $0000, $1200, $0C00, $1300
    ;DS.W $0800, $1400, $0F00, $2000, $0000, $0000, $0000, $0000

    DC.W $0002, $0000, $000D, $0010, $0000, $0012, $000C, $0013
    DC.W $0008, $0014, $000F, $0020, $0000, $0000, $0000, $0000
    DC.W $4A79, $0014, $0060, $4E4C, $4FF9, $0006, $7F00, $6100
    DC.W $0702, $6100, $0AC0, $6100, $5602, $4FF9, $0006, $7F00


;    ORG $0
;    DS.L SIO
;    DS.L RESET

    END