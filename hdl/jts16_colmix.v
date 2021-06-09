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

    input              video_en,
    input      [ 3:0]  gfx_en,

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
    input      [10:0]  scr2_pxl,
    input      [11:0]   obj_pxl,

    output     [ 4:0]  red,
    output     [ 4:0]  green,
    output     [ 4:0]  blue,
    output             LVBL_dly,
    output             LHBL_dly
);

wire [ 1:0] we;
reg  [10:0] pal_addr;
reg  [11:0] lyr0, lyr1, lyr2;
wire [15:0] pal;
wire [14:0] rgb;
wire [ 1:0] obj_prio;
reg         shadow;

assign we = ~dsn & {2{pal_cs}};

assign red   = { rgb[ 3:0], rgb[12] };
assign green = { rgb[ 7:4], rgb[13] };
assign blue  = { rgb[11:8], rgb[14] };

assign obj_prio = obj_pxl[11:10];

// bit 11 = shadow bit
// bit 10 = 0/tile 1/obj
//    9:0 = palette and colour index
function [11:0] tile_or_obj( input [9:0] obj, input [9:0] tile, input tile_prio, input obj_prio );
    tile_or_obj = obj[3:0]==0 || !obj_prio || tile_prio ?
                        { 2'b0, tile } :
                   ( &obj[9:4] ? { 2'b10, tile } : { 1'b1, obj  } ); // shadow or object
endfunction

// Layer gating
reg  [ 6:0] char_g;
reg  [10:0] scr1_g, scr2_g;
reg  [11:0] obj_g;

always @(*) begin
    char_g = char_pxl;
    scr1_g = scr1_pxl;
    scr2_g = scr2_pxl;
    obj_g  = obj_pxl;
    if( !gfx_en[0] ) char_g[3:0]=0;
    if( !gfx_en[1] ) scr1_g[3:0]=0;
    if( !gfx_en[2] ) scr2_g[3:0]=0;
    if( !gfx_en[3] )  obj_g[3:0]=0;
end

always @(posedge clk) if( pxl_cen ) begin
    lyr0 <= tile_or_obj( obj_g[9:0], {4'd0, char_g[5:0] }, char_g[ 6], obj_prio==2'd3 );
    lyr1 <= tile_or_obj( obj_g[9:0],        scr1_g[9:0]  , scr1_g[10], obj_prio>=2'd2 );
    lyr2 <= tile_or_obj( obj_g[9:0],        scr2_g[9:0]  , scr2_g[10], obj_prio>=2'd1 );
end

always @(*) begin
    { shadow, pal_addr } =
               (lyr0[10] ? lyr0[3:0]!=0 : lyr0[2:0]!=0) ? lyr0 : (
               (lyr1[10] ? lyr1[3:0]!=0 : lyr1[2:0]!=0) ? lyr1 : (
                lyr2 ));
end

jtframe_dual_ram16 #(
    .aw        (11          ),
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
    .addr1  ( pal_addr  ),
    .data1  (           ),
    .we1    ( 2'b0      ),
    .q1     ( pal       )
);

function [14:0] apply_shadow;
    input shadow;
    input [15:0] pal;
    apply_shadow = (shadow & pal[15]) ?
        { pal[14:10]>>1, pal[9:5]>>1, pal[4:0]>>1 } : pal[14:0];
endfunction

wire [14:0] gated = video_en ? apply_shadow( shadow, pal ) : 15'd0;

jtframe_blank #(.DLY(2),.DW(15)) u_blank(
    .clk        ( clk       ),
    .pxl_cen    ( pxl_cen   ),
    .LHBL       ( LHBL      ),
    .LVBL       ( LVBL      ),
    .LHBL_dly   ( LHBL_dly  ),
    .LVBL_dly   ( LVBL_dly  ),
    .preLBL     (           ),
    .rgb_in     ( gated     ),
    .rgb_out    ( rgb[14:0] )
);

endmodule