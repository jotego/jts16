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
    input   [13:0]  char_addr, // 9 addr + 3 vertical + 2 horizontal = 14 bits
    output  [15:0]  char_data,


    // Bank 1: Read only
    output   [21:0] ba1_addr,
    output          ba1_rd,
    input           ba1_rdy,
    input           ba1_ack,

    input    [31:0] data_read,
    output          refresh_en
);

assign refresh_en = LVBL;

jtframe_rom_1slot #(
    .SLOT0_DW(16),
    .SLOT0_AW(14)
) u_bank1(
    .rst        ( rst       ),
    .clk        ( clk       ),

    .slot0_addr ( char_addr ),

    //  output data
    .slot0_dout ( char_data ),

    .slot0_cs   ( LVBL      ),
    .slot0_ok   ( char_ok   ),
    // SDRAM controller interface
    .sdram_ack  ( ba1_ack   ),
    .sdram_req  ( ba1_rd    ),
    .sdram_addr ( ba1_addr  ),
    .data_rdy   ( ba1_rdy   ),
    .data_read  ( data_read )
);

endmodule