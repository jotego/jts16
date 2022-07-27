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
    Date: 13-7-2022 */

// Video board, schematic sheet 5 of 7

module jtoutrun_colmix(
    input              rst,
    input              clk,
    input              pxl2_cen,  // pixel clock enable (2x)
    input              pxl_cen,   // pixel clock enable

    input              video_en,

    input              preLHBL,
    input              preLVBL,

    // CPU interface
    input              pal_cs,
    input      [13:1]  cpu_addr,
    input      [15:0]  cpu_dout,
    input      [ 1:0]  dswn,
    output     [15:0]  cpu_din,

    // From tile map generator
    input      [10:0]  tmap_addr,
    input      [11:0]  obj_pxl,
    input      [ 7:0]  rd_pxl,
    input      [ 4:3]  rc,
    input              shadow,
    input              sa,
    input              sb,
    input              fix,

    output     [ 4:0]  red,
    output     [ 4:0]  green,
    output     [ 4:0]  blue,
    output             LVBL,
    output             LHBL,
    input      [ 7:0]  debug_bus
);

wire [ 1:0] we;
wire [15:0] pal;
wire [14:0] rgb;
reg  [10:0] rd_mux, pal_addr;
reg         muxsel;

assign we = ~dswn & {2{pal_cs}};
assign { red, green, blue } = rgb;

wire [4:0] rpal, gpal, bpal;

`ifndef GRAY
assign rpal  = { pal[ 3:0], pal[12] };
assign gpal  = { pal[ 7:4], pal[13] };
assign bpal  = { pal[11:8], pal[14] };
`else
assign rpal  = { pal_addr[3:0], pal_addr[3] };
assign gpal  = { pal_addr[3:0], pal_addr[3] };
assign bpal  = { pal_addr[3:0], pal_addr[3] };
`endif

jtframe_dual_ram16 #(
    .aw        (13          ),
    .simfile_lo("pal_lo.bin"),
    .simfile_hi("pal_hi.bin")
) u_ram(
    .clk0   ( clk       ),
    .clk1   ( clk       ),

    // CPU writes
    .addr0  ( cpu_addr  ),
    .data0  ( cpu_dout  ),
    .we0    ( we        ),
    .q0     ( cpu_din   ),

    // Video reads
    .addr1  ( { 2'd0, pal_addr }  ),
    .data1  (           ),
    .we1    ( 2'b0      ),
    .q1     ( pal       )
);

function [4:0] dim;
    input [4:0] a;
    dim = a - (a>>2);
endfunction

reg [14:0] gated;

// Super Hang On Equations 315-5251
// muxel ==0 selects tile mapper output, ==1 selects road
// muxsel = obj0 & obj1 & obj2 & obj3 & FIX & !rc3q #
//       obj0 & obj1 & obj2 & obj3 & sa_n & sb_n & FIX #
//       !obj0 & obj1 & !obj2 & obj3 & obj10 & !obj11 & FIX;

always @(*) begin
    rd_mux[3:0] = rd_pxl[3:0];
    case( rc[4:3] )
        0,1: rd_mux[5:4] = 2'b11;
        2: rd_mux[5:4] = {1'b0, rd_pxl[4]};
        3: rd_mux[5:4] = rd_pxl[5:4];
    endcase
    rd_mux[10:6] = {5{rc[4]}};

    muxsel = (obj_pxl[3:0]==4'hf && !fix && (!rc[3] || (!sa && !sb) )) ||
             (obj_pxl[11:10]==2'b01 && obj_pxl[3:0]==4'b1010 && !fix );
    if( debug_bus[1:0]==3 ) muxsel=1;
    `ifdef FORCE_ROAD
    muxsel=1;
    `endif
    pal_addr = muxsel ? rd_mux : tmap_addr;

    gated = (shadow & ~pal[15]) ? { dim(rpal), dim(gpal), dim(bpal) } :
                                  {     rpal,      gpal,      bpal  };
    if( !video_en ) gated = 0;
end

jtframe_blank #(.DLY(2),.DW(15)) u_blank(
    .clk        ( clk       ),
    .pxl_cen    ( pxl_cen   ),
    .preLHBL    ( preLHBL   ),
    .preLVBL    ( preLVBL   ),
    .LHBL       ( LHBL      ),
    .LVBL       ( LVBL      ),
    .preLBL     (           ),
    .rgb_in     ( gated     ),
    .rgb_out    ( rgb[14:0] )
);

endmodule