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

module jts16b_mem_map(
    input             rst,
    input             clk,
    input             cpu_cen,
    input             vint,

    // M68000 interface
    input      [23:1] addr,
    input      [15:0] cpu_dout,
    input      [ 1:0] dswn,
    input      [ 2:0] fc,
    output            cpu_haltn,
    output            cpu_rstn,

    // Bus sharing
    output            cpu_berrn,
    output            cpu_brn,
    input             cpu_bgn,
    output            cpu_bgackn,
    input             cpu_dtackn,
    input             cpu_asn,

    // Z80 interface
    input             sndmap_rd,
    input             sndmap_wr,
    input      [ 7:0] sndmap_din,
    output     [ 7:0] sndmap_dout,
    output            sndmap_obf, // pbf signal == buffer full ?

    // MCU side
    input      [ 7:0] mcu_dout,
    output     [ 7:0] mcu_din,
    output            mcu_intn,
    input      [15:0] mcu_addr,
    input             mcu_wr,
    output reg [ 1:0] mcu_intn,

    // Bus interface
    output reg [23:1] addr_out,
    input      [15:0] bus_dout,
    output     [15:0] bus_din,
    output reg [ 7:0] active
);

reg [7:0] mmr[0:31];
wire      none = active==0;
reg       bus_rq;
wire      mcu_cen;

assign cpu_berrn = 1;

integer aux;

always @(*) begin
    for( aux=0; aux<8; aux=aux+1 ) begin
        case( size[aux] )
            0: active[aux] = addr[23:16] == mmr[ {1'b1, aux[2:0], 1'b0 } ];      //   64 kB
            1: active[aux] = addr[23:17] == mmr[ {1'b1, aux[2:0], 1'b0 } ][7:1]; //  128 kB
            2: active[aux] = addr[23:19] == mmr[ {1'b1, aux[2:0], 1'b0 } ][7:3]; //  512 kB
            3: active[aux] = addr[23:21] == mmr[ {1'b1, aux[2:0], 1'b0 } ][7:5]; // 2048 kB
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
end

integer aux2;

always @(posedge clk, posedge rst ) begin
    if( rst ) begin
        for( aux2=0; aux2<32; aux2=aux2+1 )
            mmr[aux2] <= 0;
    end else begin
        if( none ) begin
            if( !dswn[0] )
                mmr[ addr[5:1] ] <= cpu_dout[7:0];
        end
        if( mcu_wr ) begin
            mmr[ mcu_addr[4:0] ] <= mcu_dout;
        end
    end
end

// interrupt generation
reg        irqn; // VBLANK
wire       inta_n = ~&{ FC[2], FC[1], FC[0], ~ASn }; // interrupt ack.
reg        last_vint;

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