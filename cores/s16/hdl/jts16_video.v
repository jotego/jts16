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

    input              video_en,

    // CPU interface
    input              char_cs,
    input              pal_cs,
    input              objram_cs,
    input      [12:1]  cpu_addr,
    input      [15:0]  cpu_dout,
    input      [ 1:0]  dsn,

    output     [15:0]  char_dout,
    output     [15:0]  pal_dout,
    output     [15:0]  obj_dout,
    output             vint,

    // Other configuration
    input              flip,
    input              ext_flip,
    input              colscr_en,
    input              rowscr_en,

    // SDRAM interface
    input              char_ok,
    output     [12:0]  char_addr, // 9 addr + 3 vertical + 2 horizontal = 14 bits
    input      [31:0]  char_data,

    input              map1_ok,
    output     [14:0]  map1_addr, // 3 pages + 11 addr = 14 (32 kB)
    input      [15:0]  map1_data,

    input              scr1_ok,
    output     [16:0]  scr1_addr, // 1 bank + 12 addr + 3 vertical = 15 bits
    input      [31:0]  scr1_data,

    input              map2_ok,
    output     [14:0]  map2_addr, // 3 pages + 11 addr = 14 (32 kB)
    input      [15:0]  map2_data,

    input              scr2_ok,
    output     [16:0]  scr2_addr, // 1 bank + 12 addr + 3 vertical = 15 bits
    input      [31:0]  scr2_data,

    input              obj_ok,
    output             obj_cs,
    output     [17:0]  obj_addr,
    input      [15:0]  obj_data,

    // Video signal
    output             HS,
    output             VS,
    output             HB,
    output             VB,
    output             LVBL,
    output             LHBL_dly,
    output             LVBL_dly,
    output             hstart,
    output     [ 8:0]  vdump,
    output     [ 8:0]  vrender,
    output     [ 4:0]  red,
    output     [ 4:0]  green,
    output     [ 4:0]  blue,

    // Debug
    input      [ 3:0]  gfx_en,
    input      [ 7:0]  debug_bus,
    // status dump
    input      [ 7:0]  st_addr,
    output     [ 7:0]  st_dout
);

localparam [9:0] SCR_DLY=17; // 15

localparam MODEL = `ifdef S16B 1; `else 0; `endif

wire [ 8:0] hdump, vrender1;
wire        LHBL;
wire        rowscr1_en, rowscr2_en;

// Scroll
wire [ 8:0] rowscr1, rowscr2;
wire        scr_start;

// video layers
wire [ 6:0] char_pxl;
wire [10:0] scr1_pxl, scr2_pxl;
wire [11:0] obj_pxl;

// MMR
wire [15:0] scr1_pages,      scr2_pages,
            scr1_hpos,       scr1_vpos,
            scr2_hpos,       scr2_vpos;

`ifdef JTFRAME_OSD_FLIP
    wire flipx = ext_flip ^ flip;
`else
    wire flipx = flip;
`endif
// Frame rate and horizontal frequency as the original
// "The sprite X position defines the starting location of the sprite. The
//  leftmost pixel of the screen is $00B6, and the rightmost is $1F5."

parameter [8:0] HB_END = 9'h0bf;

assign vint = vdump==223;

`ifndef S16B
    assign rowscr1_en = rowscr_en;
    assign rowscr2_en = rowscr_en;
`endif

jtframe_vtimer #(
    .HB_START  ( 9'h1ff ),
    .HB_END    ( HB_END ),
    .HCNT_START( 9'h70  ),
    .HCNT_END  ( 9'h1FF ),
    .VB_START  ( 9'h0DF ),
    .VB_END    ( 9'h104 ),
    .VCNT_END  ( 9'h104 ),
    //.VS_START ( 9'h0   ),
    .VS_START ( 9'hF0   ),
    //.VS_END   ( 9'h8   ),
    .HS_START ( 9'h080 )
) u_timer(
    .clk       ( clk      ),
    .pxl_cen   ( pxl_cen  ),
    .vdump     ( vdump    ),
    .H         ( hdump    ),
    .Hinit     ( hstart   ),
    .LHBL      ( LHBL     ),
    .LVBL      ( LVBL     ),
    .HS        ( HS       ),
    .VS        ( VS       ),
    .Vinit     (          ),
    .vrender   ( vrender  ),
    .vrender1  ( vrender1 )
);

jts16_mmr #(.MODEL(MODEL)) u_mmr(
    .rst       ( rst            ),
    .clk       ( clk            ),

    .flip      ( flip           ),
    // CPU interface
    .char_cs   ( char_cs        ),
    .cpu_addr  ( cpu_addr[11:1] ),
    .cpu_dout  ( cpu_dout       ),
    .dsn       ( dsn            ),

    // Video registers
    .scr1_pages ( scr1_pages    ),
    .scr2_pages ( scr2_pages    ),
    .scr1_hpos  ( scr1_hpos     ),
    .scr1_vpos  ( scr1_vpos     ),
    .scr2_hpos  ( scr2_hpos     ),
    .scr2_vpos  ( scr2_vpos     ),

    .rowscr1_en ( rowscr1_en    ),
    .rowscr2_en ( rowscr2_en    ),

    .st_addr    ( st_addr       ),
    .st_dout    ( st_dout       )
);

jts16_char #(.MODEL(MODEL)) u_char(
    .rst       ( rst            ),
    .clk       ( clk            ),
    .pxl2_cen  ( pxl2_cen       ),
    .pxl_cen   ( pxl_cen        ),

    // CPU interface
    .char_cs   ( char_cs        ),
    .cpu_addr  ( cpu_addr[11:1] ),
    .cpu_dout  ( cpu_dout       ),
    .dsn       ( dsn            ),
    .cpu_din   ( char_dout      ),

    // SDRAM interface
    .char_ok   ( char_ok        ),
    .char_addr ( char_addr      ), // 9 addr + 3 vertical + 2 horizontal = 14 bits
    .char_data ( char_data      ),

    // In-RAM data
    .scr_start ( scr_start      ),
    .rowscr1   ( rowscr1        ),
    .rowscr2   ( rowscr2        ),

    // Video signal
    .flip      ( flipx          ),
    .vdump     ( vdump          ),
    .hdump     ( hdump          ),
    .pxl       ( char_pxl       ),
    .debug_bus ( debug_bus      )
);

jts16_scr #(.PXL_DLY(SCR_DLY),.HB_END(HB_END),.MODEL(MODEL)) u_scr1(
    .rst       ( rst            ),
    .clk       ( clk            ),
    .pxl2_cen  ( pxl2_cen       ),
    .pxl_cen   ( pxl_cen        ),
    //.LHBL      ( LHBL           ),
    .LHBL      ( ~scr_start     ),

    .pages     ( scr1_pages     ),
    .hscr      ( scr1_hpos      ),
    .vscr      ( scr1_vpos      ),
    .rowscr_en ( rowscr1_en     ),
    .rowscr    ( rowscr1        ),

    // SDRAM interface
    .map_ok    ( map1_ok        ),
    .map_addr  ( map1_addr      ), // 3 pages + 11 addr = 14 (32 kB)
    .map_data  ( map1_data      ),

    .scr_ok    ( scr1_ok        ),
    .scr_addr  ( scr1_addr      ), // 1 bank + 12 addr + 3 vertical = 15 bits
    .scr_data  ( scr1_data      ),

    // Video signal
    .flip      ( flipx          ),
    .vrender   ( vrender        ),
    .hdump     ( hdump          ),
    .pxl       ( scr1_pxl       ),
    .debug_bus ( debug_bus      )
);

jts16_scr #(.PXL_DLY(SCR_DLY[8:0]),.MODEL(MODEL)) u_scr2(
    .rst       ( rst            ),
    .clk       ( clk            ),
    .pxl2_cen  ( pxl2_cen       ),
    .pxl_cen   ( pxl_cen        ),
    //.LHBL      ( LHBL           ),
    .LHBL      ( ~scr_start     ),

    .pages     ( scr2_pages     ),
    .hscr      ( scr2_hpos      ),
    .vscr      ( scr2_vpos      ),
    .rowscr_en ( rowscr2_en     ),
    .rowscr    ( rowscr2        ),

    // SDRAM interface
    .map_ok    ( map2_ok        ),
    .map_addr  ( map2_addr      ), // 3 pages + 11 addr = 14 (32 kB)
    .map_data  ( map2_data      ),

    .scr_ok    ( scr2_ok        ),
    .scr_addr  ( scr2_addr      ), // 1 bank + 12 addr + 3 vertical = 15 bits
    .scr_data  ( scr2_data      ),

    // Video signal
    .flip      ( flipx          ),
    .vrender   ( vrender        ),
    .hdump     ( hdump          ),
    .pxl       ( scr2_pxl       ),
    .debug_bus ( debug_bus      )
);

jts16_obj #(.PXL_DLY(SCR_DLY),.MODEL(MODEL)) u_obj(
    .rst       ( rst            ),
    .clk       ( clk            ),
    .pxl_cen   ( pxl_cen        ),

    // CPU interface
    .cpu_obj_cs( objram_cs      ),
    .cpu_addr  ( cpu_addr[10:1] ),
    .cpu_dout  ( cpu_dout       ),
    .dsn       ( dsn            ),
    .cpu_din   ( obj_dout       ),

    // SDRAM interface
    .obj_ok    ( obj_ok         ),
    .obj_cs    ( obj_cs         ),
    .obj_addr  ( obj_addr       ), // 9 addr + 3 vertical = 12 bits
    .obj_data  ( obj_data       ),

    // Video signal
    .hstart    ( hstart         ),
    .LHBL      ( ~HS            ),
    .flip      ( flipx          ),
    .vrender   ( vdump          ),
    .hdump     ( hdump          ),
    .pxl       ( obj_pxl        ),
    .debug_bus ( debug_bus      )
);

jts16_colmix u_colmix(
    .rst       ( rst            ),
    .clk       ( clk            ),
    .pxl2_cen  ( pxl2_cen       ),
    .pxl_cen   ( pxl_cen        ),
    .gfx_en    ( gfx_en         ),

    .video_en  ( video_en       ),
    // CPU interface
    .pal_cs    ( pal_cs         ),
    .cpu_addr  ( cpu_addr[11:1] ),
    .cpu_dout  ( cpu_dout       ),
    .dsn       ( dsn            ),
    .cpu_din   ( pal_dout       ),


    .LHBL      ( LHBL           ),
    .LVBL      ( LVBL           ),

    .char_pxl  ( char_pxl       ),
    .scr1_pxl  ( scr1_pxl       ),
    //.scr1_pxl  ( 11'd0       ),
    .scr2_pxl  ( scr2_pxl       ),
    .obj_pxl   ( obj_pxl        ),

    .red       ( red            ),
    .green     ( green          ),
    .blue      ( blue           ),
    .LVBL_dly  ( LVBL_dly       ),
    .LHBL_dly  ( LHBL_dly       )
);

endmodule