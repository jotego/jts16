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
    Date: 7-3-2021 */

module jts16_video(
    input              rst,
    input              clk,       //
    input              pxl2_cen,  // pixel clock enable (2x)
    input              pxl_cen,   // pixel clock enable

    // CPU interface
    input              char_cs,
    input              pal_cs,
    input      [12:1]  cpu_addr,
    input      [15:0]  cpu_dout,
    input      [ 1:0]  dsn,
    output     [15:0]  cpu_din,

    // SDRAM interface
    input              char_ok,
    output     [12:0]  char_addr, // 9 addr + 3 vertical + 2 horizontal = 14 bits
    input      [31:0]  char_data,

    input              map1_ok,
    output     [13:0]  map1_addr, // 3 pages + 11 addr = 14 (32 kB)
    input      [15:0]  map1_data,

    input              scr1_ok,
    output reg [15:0]  scr1_addr, // 1 bank + 12 addr + 3 vertical = 15 bits
    input      [31:0]  scr1_data,


    // Video signal
    output             HS,
    output             VS,
    output             HB,
    output             VB,
    output             LVBL,
    output             LHBL_dly,
    output             LVBL_dly,
    output     [ 4:0]  red,
    output     [ 4:0]  green,
    output     [ 4:0]  blue
);

wire [8:0] V, H, vrender;
wire LHBL;

// video layers
wire [ 6:0] char_pxl;
wire [10:0] scr1_pxl;

// Frame rate and horizontal frequency as the original
jtframe_vtimer #(
    .HB_START  ( 9'h1FC ),
    .HB_END    ( 9'h0BC ),
    .HCNT_START( 9'h70  ),
    .HCNT_END  ( 9'h1FF ),
    .VB_START  ( 9'h0E0 ),
    .VB_END    ( 9'h104 ),
    .VCNT_END  ( 9'h104 ),
    //.VS_START ( 9'h0   ),
    .VS_START ( 9'hF0   ),
    //.VS_END   ( 9'h8   ),
    .HS_START ( 9'h090 )
) u_timer(
    .clk       ( clk      ),
    .pxl_cen   ( pxl_cen  ),
    .vdump     ( V        ),
    .H         ( H        ),
    .Hinit     (          ),
    .LHBL      ( LHBL     ),
    .LVBL      ( LVBL     ),
    .HS        ( HS       ),
    .VS        ( VS       ),
    .Vinit     (          ),
    .vrender   ( vrender  ),
    .vrender1  (          )
);

jts16_char u_char(
    .rst       ( rst        ),
    .clk       ( clk        ),
    .pxl2_cen  ( pxl2_cen   ),
    .pxl_cen   ( pxl_cen    ),

    // CPU interface
    .char_cs   ( char_cs        ),
    .cpu_addr  ( cpu_addr[11:1] ),
    .cpu_dout  ( cpu_dout       ),
    .dsn       ( dsn            ),
    .cpu_din   ( cpu_din        ),

    // SDRAM interface
    .char_ok   ( char_ok    ),
    .char_addr ( char_addr  ), // 9 addr + 3 vertical + 2 horizontal = 14 bits
    .char_data ( char_data  ),

    // Video signal
    .vdump     ( V          ),
    .hdump     ( H          ),
    .pxl       ( char_pxl   )
);

jts16_scr u_scr1(
    .rst       ( rst        ),
    .clk       ( clk        ),
    .pxl2_cen  ( pxl2_cen   ),
    .pxl_cen   ( pxl_cen    ),

    // CPU interface
    .scr_cs    ( scr1_cs        ),
    .cpu_addr  ( cpu_addr[4:1]  ),
    .cpu_dout  ( cpu_dout       ),
    .dsn       ( dsn            ),
    .cpu_din   ( cpu_din        ),

    // SDRAM interface
    .map_ok    ( map1_ok        ),
    .map_addr  ( map1_addr      ), // 3 pages + 11 addr = 14 (32 kB)
    .map_data  ( map1_data      ),

    .scr_ok    ( scr1_ok        ),
    .scr_addr  ( scr1_addr      ), // 1 bank + 12 addr + 3 vertical = 15 bits
    .scr_data  ( scr1_data      ),

    // Video signal
    .vdump     ( V          ),
    .hdump     ( H          ),
    .pxl       ( scr1_pxl   )
);

jts16_colmix u_colmix(
    .rst       ( rst        ),
    .clk       ( clk        ),
    .pxl2_cen  ( pxl2_cen   ),
    .pxl_cen   ( pxl_cen    ),

    // CPU interface
    .pal_cs    ( pal_cs         ),
    .cpu_addr  ( cpu_addr[11:1] ),
    .cpu_dout  ( cpu_dout       ),
    .dsn       ( dsn            ),
    .cpu_din   ( cpu_din        ),


    .LHBL      ( LHBL       ),
    .LVBL      ( LVBL       ),

    .char_pxl  ( char_pxl   ),
    .scr1_pxl  ( scr1_pxl   ),

    .red       ( red        ),
    .green     ( green      ),
    .blue      ( blue       ),
    .LVBL_dly  ( LVBL_dly   ),
    .LHBL_dly  ( LHBL_dly   )
);

endmodule