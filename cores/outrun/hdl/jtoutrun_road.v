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
    Date: 9-7-2022 */

module jtoutrun_road(
    input              rst,
    input              clk,
);

jtframe_dual_ram16 u_vram0(
    // CPU
    .clk0 ( clk      ),
    .data0( cpu_dout ),
    .addr0( cpu_addr ),
    .we0  ( rd0_we   ),
    .q0   ( rd0_dout ),
    // Road engine
    .clk1 ( clk      ),
    .data1(          ),
    .addr1( addr1    ),
    .we1  ( 2'd0     ),
    .q1   ( q1       )
);


endmodule