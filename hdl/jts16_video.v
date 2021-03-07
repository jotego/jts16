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
    input              clk,
    input              pxl2_cen,        // pixel clock enable
    input              pxl_cen,        // pixel clock enable

    output     [ 8:0]  vdump,
    output     [ 8:0]  vrender,
    output     [ 8:0]  hdump,
    input      [ 3:0]  gfx_en,

    // CPU interface
    input              ppu1_cs,
    input              ppu2_cs,
    input   [13:1]     addr,
    input   [ 1:0]     dsn,      // data select, active low
    input   [15:0]     cpu_dout,

    // Video RAM interface
    output     [17:1]  vram_addr,
    input      [15:0]  vram_data,
    input              vram_ok,
    output             vram_cs,
    output             vram_clr,
    output             vram_rfsh_en,

    // Video signal
    output             HS,
    output             VS,
    output             HB,
    output             VB,
    output             LHBL_dly,
    output             LVBL_dly,
    output     [ 7:0]  red,
    output     [ 7:0]  green,
    output     [ 7:0]  blue,

    // GFX ROM interface
    output     [19:0]  obj_addr,
    output             obj_half,    // selects which half to read
    input      [31:0]  obj_data,
    output             obj_cs,
    input              obj_ok,

    output     [19:0]  tile_addr,
    output     [ 1:0]  tile_bank,
    output             tile_half,    // selects which half to read
    input      [31:0]  tile_data,
    output             tile_cs,
    input              tile_ok,

    input              watch_vram_cs,
    output             watch

    `ifdef CPS1
    // EEPROM
    ,output            sclk,
    output             sdi,
    output             scs,
    input              sdo
    `endif
);

// Frame rate and blanking as the original
// Sync pulses slightly adjusted
jtframe_vtimer #(
    .HB_START ( 9'h1C7 ),
    .HB_END   ( 9'h047 ),
    //.HB_END   ( 9'h04F ),
    .HCNT_END ( 9'h1FF ),
    .VB_START ( 9'hF0  ),
    .VB_END   ( 9'h10  ),
    .VCNT_END ( 9'hFF  ),
    //.VS_START ( 9'h0   ),
    .VS_START ( 9'hF8   ),
    //.VS_END   ( 9'h8   ),
    .HS_START ( 9'h1F8 ),
    .HS_END   ( 9'h020 ),
    .H_VB     ( 9'h7   ),
    .H_VS     ( 9'h1FF ),
    .H_VNEXT  ( 9'h1FF ),
    .HINIT    ( 9'h20 )
) u_timer(
    .clk       ( clk      ),
    .pxl_cen   ( pxl_cen  ),
    .vdump     ( V        ),
    .H         ( H        ),
    .Hinit     ( HINIT    ),
    .LHBL      ( LHBL     ),
    .LVBL      ( LVBL     ),
    .HS        ( HS       ),
    .VS        ( VS       ),
    .Vinit     (          ),
    // unused
    .vrender   (          ),
    .vrender1  (          )
);

`ifndef NOSCROLL
jts16_scroll u_scroll(
    .rst        ( rst           ),
    .clk        ( clk           ),
    .pxl_cen    ( pxl_cen       ),
    .gfx_en     ( gfx_en        ),
    .flip       ( flip          ),

    .vrender    ( vrender       ),
    .vdump      ( vdump         ),
    .hdump      ( hdump         ),
    .preVB      ( preVB         ),
    .VB         ( VB            ),
    .HB         ( HB            ),

    .hpos1      ( hpos1         ),
    .vpos1      ( vpos1         ),

    .hpos2      ( row_scr       ),
    .vpos2      ( vpos2         ),

    // ROM banks
    .game       ( game          ),
    .bank_offset( bank_offset   ),
    .bank_mask  ( bank_mask     ),

    .start      ( line_start    ),

    .tile_addr  ( tile_addr     ),
    .tile_data  ( tile_data     ),

    .rom_addr   ( obj_addr     ),
    .rom_data   ( obj_data     ),
    .rom_cs     ( obj_cs       ),
    .rom_ok     ( obj_ok       ),
    .rom_half   ( obj_half     ),

    .scr1_pxl   ( scr1_pxl      ),
    .scr2_pxl   ( scr2_pxl      ),
    .scr3_pxl   ( scr3_pxl      ),

    .star0_pxl  ( star0_pxl     ),
    .star1_pxl  ( star1_pxl     )
);
`else
assign obj_cs    = 1'b0;
assign obj_addr  = 20'd0;
assign scr1_pxl   = 11'h1ff;
assign scr2_pxl   = 11'h1ff;
assign scr3_pxl   = 11'h1ff;
`endif

// Objects
`ifndef NOOBJ
jts16_obj u_obj(
    .rst        ( rst           ),
    .clk        ( clk           ),
    .pxl_cen    ( pxl_cen       ),
    .flip       ( flip          ),

    // Cache access
    .frame_addr ( obj_cache_addr),
    .frame_data ( objtable_data ),

    .start      ( line_start    ),
    .vrender    ( vrender       ),
    .vdump      ( vdump         ),
    .hdump      ( hdump         ),

    // ROM banks
    .game       ( game          ),
    .bank_offset( bank_offset   ),
    .bank_mask  ( bank_mask     ),

    // ROM data
    .rom_addr   ( tile_addr     ),
    .rom_data   ( tile_data     ),
    .rom_cs     ( tile_cs       ),
    .rom_ok     ( tile_ok       ),
    .rom_half   ( tile_half     ),

    .pxl        ( obj_pxl       )
);
`endif

`ifndef NOCOLMIX
jts16_colmix u_colmix(
    .rst        ( rst           ),
    .clk        ( clk           ),
    .pxl_cen    ( pxl_cen       ),

    .gfx_en     ( gfx_en        ),

    // Pixel layers data
    .char_pxl   ( char_pxl      ),
    .scr1_pxl   ( scr1_pxl      ),
    .scr2_pxl   ( scr2_pxl      ),
    .obj_pxl    ( obj_pxl       ),

    .pxl        ( mix_pxl       )
);

jts16_pal #(.BLNK_DLY(BLNK_DLY)) u_pal(
    .rst        ( rst           ),
    .clk        ( clk           ),
    .pxl_cen    ( pxl_cen       ),

    .vb         ( VB            ),
    .hb         ( HB            ),
    .LHBL_dly   ( LHBL_dly      ),
    .LVBL_dly   ( LVBL_dly      ),

    // Palette RAM
    .pxl_in     ( mix_pxl       ),
    .pal_addr   ( pal_addr      ),
    .pal_raw    ( pal_raw       ),

    // Video
    .red        ( red           ),
    .green      ( green         ),
    .blue       ( blue          )
);

`else
assign LVBL_dly  = ~VB;
assign LHBL_dly  = ~HB;
`endif

endmodule