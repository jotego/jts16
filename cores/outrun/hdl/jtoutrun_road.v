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
    input        [7:0] v,
    // CPU interface
    input       [11:1] cpu_addr,
    input       [15:0] cpu_dout,
    output      [15:0] cpu_din,
    input       [ 1:0] cpu_dswn,
    input              road_cs,
    input              io_cs
);

wire [10:0] rd_addr;
wire [15:0] rd0_gfx, rd1_gfx;
wire [ 1:0] rd0_we, rd1_we;
reg         rdsel, toggle;
reg         rdhon;
reg  [ 1:0] ctrl;

assign rd_addr = 0;
assign rd0_we  = {2{road_cs & ~rdsel }} & ~cpu_dswn;
assign rd1_we  = {2{road_cs &  rdsel }} & ~cpu_dswn;
assign cpu_din = rdsel ? rd1_dout : rd0_dout;

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        rdsel  <= 0;
        toggle <= 0;
        ctrl   <= 0;
    end else begin
        if( io_cs & ~cpu_dswn[0] )  ctrl <= cpu_dout[1:0];
        if( v==475 && toggle ) rdsel  <= ~rdsel;
        if( v==476 )
            toggle <= 0;
        else if( io_cs && cpu_dswn==2'b11 )
            toggle <= 1;
    end
end

jtframe_dual_ram16 #(.aw(11)) u_vram0(
    // CPU
    .clk0 ( clk      ),
    .data0( cpu_dout ),
    .addr0( cpu_addr ),
    .we0  ( rd0_we   ),
    .q0   ( rd0_dout ),
    // Road engine
    .clk1 ( clk      ),
    .data1(          ),
    .addr1( rd_addr  ),
    .we1  ( 2'd0     ),
    .q1   ( rd0_gfx  )
);

jtframe_dual_ram16 #(.aw(11)) u_vram1(
    // CPU
    .clk0 ( clk      ),
    .data0( cpu_dout ),
    .addr0( cpu_addr ),
    .we0  ( rd1_we   ),
    .q0   ( rd1_dout ),
    // Road engine
    .clk1 ( clk      ),
    .data1(          ),
    .addr1( rd_addr  ),
    .we1  ( 2'd0     ),
    .q1   ( rd1_gfx  )
);


endmodule