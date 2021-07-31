/*  This file is part of JTS16.
    JTS16 program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    JTS16 program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with JTS16.  If not, see <http://www.gnu.org/licenses/>.

    Author: Jose Tejada Gomez. Twitter: @topapate
    Version: 1.0
    Date: 5-7-2021 */

// This module represents the SEGA 315-5195
//
//  Region 0 - Program ROM
//  Region 3 - 68000 work RAM
//  Region 4 - Text/tile RAM
//  Region 5 - Object RAM
//  Region 6 - Color RAM
//  Region 7 - I/O area

// Quick count from die photo by Furrtek
// 11 x 4-bit counters -> what for?
// 36 x 4-bit latches

// base address = 8x2 x 4-bit = 16 x 4-bit
// control      =                8 x 4-bit

// write address = 3x8 = 6 x 4 -> 5 x 4 ?
// read  address = 3x8 = 6 x 4 -> 5 x 4 ?

// DTACK cycles
// Programmed with bits [3:2] of size registers
// D[3:2] | DTACK (# cycles)
// -------|--------
//  11    | use EDACK pin
//  10    | 3
//  01    | 2
//  00    | 1


module jts16b_mapper(
    input             rst,
    input             clk,
    input             cpu_cen,
    input             vint,

    // M68000 interface
    input      [23:1] addr,
    input      [15:0] cpu_dout,
    input      [ 1:0] cpu_dswn,
    output     [ 2:0] cpu_ipln,
    output            cpu_haltn,
    output            cpu_rstn,
    output            cpu_vpan,
    output reg [ 1:0] dtack_cyc,    // number of DTACK cycles

    // Bus sharing
    output            cpu_berrn,
    output            cpu_brn,
    input             cpu_bgn,
    output            cpu_bgackn,
    input             cpu_dtackn,
    input             cpu_asn,
    input      [ 2:0] cpu_fc,

    // Z80 interface
    input             sndmap_rd,
    input             sndmap_wr,
    input      [ 7:0] sndmap_din,
    output     [ 7:0] sndmap_dout,
    output reg        sndmap_obf, // pbf signal == buffer full ?

    // MCU side
    input      [ 7:0] mcu_dout,
    output     [ 7:0] mcu_din,
    input      [15:0] mcu_addr,
    input             mcu_wr,
    output     [ 1:0] mcu_intn,

    // Bus interface
    output     [23:1] addr_out,
    input      [15:0] bus_dout,
    output     [15:0] bus_din,
    output reg [ 7:0] active
);

reg [7:0] mmr[0:31];
wire      none = active==0;
wire      bus_rq = 0;
wire      mcu_cen;
reg       cpu_sel;
reg       irqn; // VBLANK

assign mcu_intn = { 1'b1, irqn };
assign mcu_din  = mcu_dout;

`ifdef SIMULATION
wire [7:0] base0 = mmr[ {1'b1, 3'd0, 1'b1 }];
wire [7:0] base1 = mmr[ {1'b1, 3'd1, 1'b1 }];
wire [7:0] base2 = mmr[ {1'b1, 3'd2, 1'b1 }];
wire [7:0] base3 = mmr[ {1'b1, 3'd3, 1'b1 }];
wire [7:0] base4 = mmr[ {1'b1, 3'd4, 1'b1 }];
wire [7:0] base5 = mmr[ {1'b1, 3'd5, 1'b1 }];
wire [7:0] base6 = mmr[ {1'b1, 3'd6, 1'b1 }];
wire [7:0] base7 = mmr[ {1'b1, 3'd7, 1'b1 }];

wire [1:0] size0, dtack0,
           size1, dtack1,
           size2, dtack2,
           size3, dtack3,
           size4, dtack4,
           size5, dtack5,
           size6, dtack6,
           size7, dtack7;

assign {dtack0, size0 } = mmr[ {1'b1, 3'd0, 1'b0 }];
assign {dtack1, size1 } = mmr[ {1'b1, 3'd1, 1'b0 }];
assign {dtack2, size2 } = mmr[ {1'b1, 3'd2, 1'b0 }];
assign {dtack3, size3 } = mmr[ {1'b1, 3'd3, 1'b0 }];
assign {dtack4, size4 } = mmr[ {1'b1, 3'd4, 1'b0 }];
assign {dtack5, size5 } = mmr[ {1'b1, 3'd5, 1'b0 }];
assign {dtack6, size6 } = mmr[ {1'b1, 3'd6, 1'b0 }];
assign {dtack7, size7 } = mmr[ {1'b1, 3'd7, 1'b0 }];
`endif

// unused for now
assign cpu_haltn = 1;
assign cpu_rstn  = 1;
assign addr_out  = 0;
assign bus_din   = 0;

assign cpu_berrn = 1;
assign sndmap_dout = mmr[3];
integer aux;

always @(*) begin
    active = 0;
    for( aux=0; aux<8; aux=aux+1 ) begin
        case( mmr[ {1'b1, aux[2:0], 1'b0 } ][1:0] )
            0: active[aux] = addr[23:16] == mmr[ {1'b1, aux[2:0], 1'b1 } ];      //   64 kB
            1: active[aux] = addr[23:17] == mmr[ {1'b1, aux[2:0], 1'b1 } ][7:1]; //  128 kB
            2: active[aux] = addr[23:19] == mmr[ {1'b1, aux[2:0], 1'b1 } ][7:3]; //  512 kB
            3: active[aux] = addr[23:21] == mmr[ {1'b1, aux[2:0], 1'b1 } ][7:5]; // 2048 kB
        endcase
    end
    // no more than one signal can be set
    if( active[0] ) active[7:1] = 0;
    if( active[1] ) active[7:2] = 0;
    if( active[2] ) active[7:3] = 0;
    if( active[3] ) active[7:4] = 0;
    if( active[4] ) active[7:5] = 0;
    if( active[5] ) active[7:6] = 0;
    if( active[6] ) active[7]   = 0;
    if( &cpu_fc   ) active      = 0; // irq ack.
    case( active )
        8'h01: dtack_cyc = mmr[ {1'b1,3'd0,1'b0}][3:2];
        8'h02: dtack_cyc = mmr[ {1'b1,3'd1,1'b0}][3:2];
        8'h04: dtack_cyc = mmr[ {1'b1,3'd2,1'b0}][3:2];
        8'h08: dtack_cyc = mmr[ {1'b1,3'd3,1'b0}][3:2];
        8'h10: dtack_cyc = mmr[ {1'b1,3'd4,1'b0}][3:2];
        8'h20: dtack_cyc = mmr[ {1'b1,3'd5,1'b0}][3:2];
        8'h40: dtack_cyc = mmr[ {1'b1,3'd6,1'b0}][3:2];
        8'h80: dtack_cyc = mmr[ {1'b1,3'd7,1'b0}][3:2];
        default: dtack_cyc = 0;
    endcase
end

// select between CPU or MCU access to registers
wire [4:0] asel = cpu_sel ? addr[5:1] : mcu_addr[4:0];
wire [7:0] din  = cpu_sel ? cpu_dout[7:0] : mcu_dout;
wire       wren = cpu_sel ? (~cpu_asn & ~cpu_dswn[0] & none) : mcu_wr;

integer aux2;

always @(posedge clk, posedge rst ) begin
    if( rst ) begin
        for( aux2=0; aux2<32; aux2=aux2+1 )
            mmr[aux2] <= 0;
        sndmap_obf <= 0;
        cpu_sel    <= 1;
    end else begin
        if( mcu_wr ) cpu_sel <= 0; // once cleared, it stays like that until reset
        if( wren ) begin
            mmr[ asel ] <= din;
            if( asel == 3 )
                sndmap_obf <= 1;
        end
        if( sndmap_rd )
            sndmap_obf <= 0;
    end
end

// interrupt generation
wire       inta_n = ~&{ cpu_fc, ~cpu_asn }; // interrupt ack.
reg        last_vint;

assign cpu_vpan = inta_n;
assign cpu_ipln = { irqn, 2'b11 };

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        irqn <= 1;
    end else begin
        last_vint <= vint;

        if( !inta_n ) begin
            irqn <= 1;
        end else if( vint && !last_vint ) begin
            irqn <= 0;
        end
    end
end

jtframe_68kdma u_dma(
    .rst        ( rst       ),
    .clk        ( clk       ),
    .cen        ( cpu_cen   ),
    .cpu_BRn    ( cpu_brn   ),
    .cpu_BGACKn ( cpu_bgackn),
    .cpu_BGn    ( cpu_bgn   ),
    .cpu_ASn    ( cpu_asn   ),
    .cpu_DTACKn ( cpu_dtackn),
    .dev_br     ( bus_rq    )      // high to signal a bus request from a device
);

endmodule