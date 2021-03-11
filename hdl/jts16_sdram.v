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
    Date: 10-3-2021 */

module jts16_sdram(
    input           rst,
    input           clk,
    input           LVBL,

    // Char interface
    output          char_ok,
    input   [12:0]  char_addr, // 9 addr + 3 vertical + 2 horizontal = 14 bits
    output  [31:0]  char_data,

    // Scroll 1 interface
    output             map1_ok,
    input      [13:0]  map1_addr, // 3 pages + 11 addr = 14 (32 kB)
    output     [15:0]  map1_data,

    output             scr1_ok,
    input      [15:0]  scr1_addr, // 1 bank + 12 addr + 3 vertical = 15 bits
    output     [31:0]  scr1_data,

    // Bank 0: allows R/W
    output   [22:0] ba0_addr,
    output          ba0_rd,
    output          ba0_wr,
    output   [15:0] ba0_din,
    output   [ 1:0] ba0_din_m,  // write mask
    input           ba0_rdy,
    input           ba0_ack,

    // Bank 1: Read only
    output   [21:0] ba1_addr,
    output          ba1_rd,
    input           ba1_rdy,
    input           ba1_ack,

    input    [31:0] data_read,
    output          refresh_en
);

localparam [21:0] ZERO_OFFSET=0,
                  VRAM_OFFSET=22'h10_0000;

assign refresh_en = LVBL;

jtframe_ram_4slots #(
    // VRAM
    .SLOT0_DW(16),
    .SLOT0_AW(14),  // 32 kB

    // Game ROM
    .SLOT1_DW(16),
    .SLOT1_AW(19),  // 1MB temptative value

    // VRAM access by SCR1
    .SLOT2_DW(16),
    .SLOT2_AW(14),

    // VRAM access by SCR2
    .SLOT3_DW(16),
    .SLOT3_AW(14)
) u_bank0(
    .rst        ( rst       ),
    .clk        ( clk       ),

    .offset0    ( ZERO_OFFSET ),
    .offset1    ( VRAM_OFFSET ),
    .offset2    ( VRAM_OFFSET ),
    .offset3    ( VRAM_OFFSET ),

    //.slot0_addr ( vram_addr ),
    //.slot1_addr ( main_addr  ),
    .slot2_addr ( map1_addr ),
    //.slot3_addr ( map2_addr ),

    //  output data
    //.slot0_dout ( main_dout ),
    //.slot1_dout ( vram_dout ),
    .slot2_dout ( map1_data ),
    //.slot3_dout ( map2_dout ),

    .slot0_cs   ( 1'b0      ),
    .slot1_cs   ( 1'b0      ),
    .slot2_cs   ( LVBL      ),
    .slot3_cs   ( LVBL      ),

    .slot0_wen  ( 1'b0      ),
    .slot0_din  ( 16'd0     ),
    .slot0_wrmask( 2'b11    ),

    .slot1_clr  ( 1'b0      ),
    .slot2_clr  ( 1'b0      ),
    .slot3_clr  ( 1'b0      ),

    //.slot0_ok   ( main_ok   ),
    //.slot1_ok   ( vram_ok   ),
    .slot2_ok   ( map1_ok   ),
    //.slot3_ok   ( map2_ok   ),

    // SDRAM controller interface
    .sdram_ack   ( ba0_ack   ),
    .sdram_rd    ( ba0_rd    ),
    .sdram_wr    ( ba0_wr    ),
    .sdram_addr  ( ba0_addr  ),
    .data_rdy    ( ba0_rdy   ),
    .data_write  ( ba0_din   ),
    .sdram_wrmask( ba0_din_m ),
    .data_read   ( data_read )
);

jtframe_rom_2slots #(
    .SLOT0_DW(32),
    .SLOT0_AW(13),

    .SLOT1_DW(32),
    .SLOT1_AW(16)

) u_bank1(
    .rst        ( rst       ),
    .clk        ( clk       ),

    .slot0_addr ( char_addr ),
    .slot1_addr ( scr1_addr ),

    //  output data
    .slot0_dout ( char_data ),
    .slot1_dout ( scr1_data ),

    .slot0_cs   ( LVBL      ),
    .slot1_cs   ( LVBL      ),

    .slot0_ok   ( char_ok   ),
    .slot1_ok   ( scr1_ok   ),
    // SDRAM controller interface
    .sdram_ack  ( ba1_ack   ),
    .sdram_req  ( ba1_rd    ),
    .sdram_addr ( ba1_addr  ),
    .data_rdy   ( ba1_rdy   ),
    .data_read  ( data_read )
);

endmodule