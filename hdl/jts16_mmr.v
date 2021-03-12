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

module jts16_mmr(
    input              rst,
    input              clk,

    // CPU interface
    input              char_cs,
    input      [11:1]  cpu_addr,
    input      [15:0]  cpu_dout,
    input      [ 1:0]  dsn,
    output     [15:0]  cpu_din,

    // Video registers
    output reg [15:0]  scr1_pages,
    output reg [15:0]  scr2_pages,

    output reg [15:0]  scr1_hpos,
    output reg [15:0]  scr1_vpos,

    output reg [15:0]  scr2_hpos,
    output reg [15:0]  scr2_vpos
);

                                      // SCR1  SCR2
//localparam [2:0] PAGE     = 4'b0_011, // E9E - E9C 1110'1001'1110
//                 PAGE_ALT = 4'b0_001, // E8E - E8C
//                 VSCR     = 4'b0_100, // F24 - F26
//                 HSCR     = 4'b0_110; // FF8 - FFA

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        scr1_pages <= 16'h3300;
        scr2_pages <= 16'h7744;
        scr1_hpos  <= 0;
        scr2_hpos  <= 0;
        scr1_vpos  <= 0;
        scr2_vpos  <= 0;
    end else begin
    end
end

endmodule