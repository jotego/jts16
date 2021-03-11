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

module jts16_colmix(
    input              rst,
    input              clk,
    input              pxl2_cen,  // pixel clock enable (2x)
    input              pxl_cen,   // pixel clock enable

    input              LHBL,
    input              LVBL,

    // CPU interface
    input              pal_cs,
    input      [11:1]  cpu_addr,
    input      [15:0]  cpu_dout,
    input      [ 1:0]  dsn,
    output     [15:0]  cpu_din,

    input      [ 6:0]  char_pxl,
    input      [10:0]  scr1_pxl,

    output     [ 4:0]  red,
    output     [ 4:0]  green,
    output     [ 4:0]  blue,
    output             LVBL_dly,
    output             LHBL_dly
);

wire [ 1:0] we;
reg  [10:0] pal_addr;
wire [15:0] pal;
wire [14:0] rgb;

assign we = ~dsn & {2{pal_cs}};

assign red   = { rgb[ 3:0], rgb[12] };
assign green = { rgb[ 7:4], rgb[13] };
assign blue  = { rgb[11:8], rgb[14] };

always @(*) begin
    pal_addr = char_pxl[3:0]!=0 ? { 5'd0, char_pxl[5:0] } :
                                  { 1'b0, scr1_pxl[9:0] };
end

jtframe_dual_ram #(.aw(11),.simfile("pal_lo.bin")) u_low(
    // CPU writes
    .clk0   ( clk           ),
    .addr0  ( cpu_addr      ),
    .data0  ( cpu_dout[7:0] ),
    .we0    ( we[0]         ),
    .q0     ( cpu_din[7:0]  ),
    // Video reads
    .clk1   ( clk           ),
    .addr1  ( pal_addr      ),
    .data1  (               ),
    .we1    ( 1'b0          ),
    .q1     ( pal[7:0]      )
);

jtframe_dual_ram #(.aw(11),.simfile("pal_hi.bin")) u_hi(
    // CPU writes
    .clk0   ( clk           ),
    .addr0  ( cpu_addr      ),
    .data0  ( cpu_dout[7:0] ),
    .we0    ( we[0]         ),
    .q0     ( cpu_din[7:0]  ),
    // Video reads
    .clk1   ( clk           ),
    .addr1  ( pal_addr      ),
    .data1  (               ),
    .we1    ( 1'b0          ),
    .q1     ( pal[15:8]     )
);

jtframe_blank #(.DLY(12),.DW(15)) u_blank(
    .clk        ( clk       ),
    .pxl_cen    ( pxl_cen   ),
    .LHBL       ( LHBL      ),
    .LVBL       ( LVBL      ),
    .LHBL_dly   ( LHBL_dly  ),
    .LVBL_dly   ( LVBL_dly  ),
    .preLBL     (           ),
    .rgb_in     ( pal[14:0] ),
    .rgb_out    ( rgb[14:0] )
);

endmodule