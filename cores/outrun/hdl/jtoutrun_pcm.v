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
    Date: 16-7-2022 */

// This module represents the 315-5218

module jtoutrun_pcm(
    input              rst,
    input              clk,
    input              cen,

    // CPU interface
    input        [7:0] cpu_addr,
    input        [7:0] cpu_dout,
    output       [7:0] cpu_din,
    input              cpu_rnw,
    input              cpu_cs,

    // ROM interface
    output      [18:0] rom_addr,
    input       [ 7:0] rom_data,
    input              rom_ok,
    output             rom_cs
);

wire we = cpu_cs & ~cpu_rnw;

assign rom_addr = 0;
assign rom_cs = 0;

jtframe_dual_ram #(.aw(8)) u_ram(
    // Port 0: CPU
    .clk0   ( clk       ),
    .data0  ( cpu_dout  ),
    .addr0  ( cpu_addr  ),
    .we0    ( we        ),
    .q0     ( cpu_din   ),
    // Port 1
    .clk1   ( clk       ),
    .data1  (           ),
    .addr1  (           ),
    .we1    ( 1'b0      ),
    .q1     (           )
);

endmodule