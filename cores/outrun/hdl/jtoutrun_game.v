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
    Date: 10-7-2022 */

module jtoutrun_game(
    input           rst,
    input           clk,
    input           rst24,
    input           clk24,
    output          pxl2_cen,   // 12   MHz
    output          pxl_cen,    //  6   MHz
    output   [4:0]  red,
    output   [4:0]  green,
    output   [4:0]  blue,
    output          LHBL,
    output          LVBL,
    output          HS,
    output          VS,
    // cabinet I/O
    input   [ 1:0]  start_button,
    input   [ 1:0]  coin_input,
    input   [ 7:0]  joystick1,
    input   [ 7:0]  joystick2,
    input   [15:0]  joyana_l1,
    input   [15:0]  joyana_l2,
    input   [15:0]  joyana_r1,
    input   [15:0]  joyana_r2,

    // SDRAM interface
    input           downloading,
    output          dwnld_busy,

    // Bank 0: allows R/W
    output   [21:0] ba0_addr,
    output   [21:0] ba1_addr,
    output   [21:0] ba2_addr,
    output   [21:0] ba3_addr,
    output   [ 3:0] ba_rd,
    output          ba_wr,
    output   [15:0] ba0_din,
    output   [ 1:0] ba0_din_m,  // write mask
    input    [ 3:0] ba_ack,
    input    [ 3:0] ba_dst,
    input    [ 3:0] ba_dok,
    input    [ 3:0] ba_rdy,

    input    [15:0] data_read,

    // RAM/ROM LOAD
    input   [24:0]  ioctl_addr,
    input   [ 7:0]  ioctl_dout,
    input           ioctl_wr,
    // output  [ 7:0]  ioctl_din,
    // input           ioctl_ram, // 0 - ROM, 1 - RAM(EEPROM)
    output  [21:0]  prog_addr,
    output  [15:0]  prog_data,
    output  [ 1:0]  prog_mask,
    output  [ 1:0]  prog_ba,
    output          prog_we,
    output          prog_rd,
    input           prog_ack,
    input           prog_dok,
    input           prog_dst,
    input           prog_rdy,
    // DIP switches
    input   [31:0]  status,
    input   [31:0]  dipsw,
    input           service,
    input           dip_pause,
    inout           dip_flip,
    input           dip_test,
    input   [ 1:0]  dip_fxlevel, // Not a DIP on the original PCB
    // Sound output
    output  signed [15:0] snd_left,
    output  signed [15:0] snd_right,
    output          sample,
    output          game_led,
    input           enable_psg,
    input           enable_fm,
    // Debug
    input   [3:0]   gfx_en,
    input   [7:0]   debug_bus,
    output  [7:0]   debug_view,
    // status dump
    input   [ 7:0]  st_addr,
    output reg [ 7:0]  st_dout
);

// clock enable signals
wire    cpu_cen, cpu_cenb,
        cen_fm,  cen_fm2, cen_snd,
        cen_pcm, cen_pcmb;

// video signals
wire [ 8:0] vrender;
wire        hstart, vint;
wire        colscr_en, rowscr_en;
wire [ 5:0] tile_bank;
wire        scr_bad;

// SDRAM interface
wire        main_cs, vram_cs, ram_cs;
wire [19:1] main_addr;
wire [15:0] main_data, ram_data;
wire        main_ok, ram_ok;

wire        char_ok;
wire [12:0] char_addr;
wire [31:0] char_data;

wire        map1_ok, map2_ok;
wire [14:0] map1_addr, map2_addr; // 3(+1 S16B) pages + 11 addr = 14 (32 kB)
wire [15:0] map1_data, map2_data;

wire        scr1_ok, scr2_ok;
wire [16:0] scr1_addr, scr2_addr; // 1 bank + 12 addr + 3 vertical + 1 (32-bit) = 15 bits
wire [31:0] scr1_data, scr2_data;

wire        obj_ok, obj_cs;
wire [19:0] obj_addr;
wire [15:0] obj_data;

// CPU interface
wire [15:0] main_dout, char_dout, pal_dout, obj_dout;
wire [ 1:0] main_dsn, main_dswn;
wire        main_rnw, sub_br, irqn,
            char_cs, scr1_cs, pal_cs, objram_cs;

// Sub CPU
wire [18:1] sub_addr;
wire [15:0] sub_din, sub_dout, sram_data, srom_data, road_dout;
wire [ 1:0] sub_dsn, sub_dswn;
wire        sub_rnw, srom_cs, sram_cs, sub_ok,
            srom_ok, sram_ok, road_cs, sio_cs, main_br;
// Sound CPU
wire [15:0] snd_addr;
wire [ 7:0] snd_data;
wire        snd_cs, snd_ok;
wire [ 7:0] sndmap_din, sndmap_dout;
wire        sndmap_rd, sndmap_wr, sndmap_pbf, snd_rstb;
// PCM
wire [18:0] pcm_addr;
wire        pcm_cs;
wire [ 7:0] pcm_data;
wire        pcm_ok;
wire        snd_clip;

// Protection
wire        key_we, fd1089_we;
wire        dec_en, dec_type,
            fd1089_en, fd1094_en, mc8123_en;
wire [ 7:0] key_data;
wire [12:0] key_addr, key_mcaddr;

wire        flip, video_en, sound_en, line_intn;

// Cabinet inputs
wire [ 7:0] dipsw_a, dipsw_b;
wire [ 1:0] game_id;

// Status report
wire [7:0] st_video, st_main;

assign { dipsw_b, dipsw_a } = dipsw[15:0];
assign debug_view           = st_dout;
assign irqn                 = 1;
assign main_dswn            = {2{main_rnw}} | main_dsn;
assign sub_dswn             = {2{sub_rnw }} | sub_dsn;
assign game_led             = snd_clip;

jts16_cen u_cen(
    .rst        ( rst       ),

    .clk        ( clk       ),
    .pxl2_cen   ( pxl2_cen  ),
    .pxl_cen    ( pxl_cen   ),
    .cpu_cen    (           ),
    .cpu_cenb   (           ),

    .clk24      ( clk24     ),
    .mcu_cen    (           ),
    .fm2_cen    ( cen_fm2   ),
    .fm_cen     ( cen_fm    ),
    .snd_cen    ( cen_snd   ),
    .pcm_cen    ( cen_pcm   ),
    .pcm_cenb   ( cen_pcmb  )
);

`ifndef NOMAIN
jtoutrun_main u_main(
    .rst         ( rst        ),
    .clk         ( clk        ),
    .clk_rom     ( clk        ),  // same clock - at least for now
    .cpu_cen     ( cpu_cen    ),
    .cpu_cenb    ( cpu_cenb   ),
    .pxl_cen     ( pxl_cen    ),
    .game_id     ( game_id    ),
    .LHBL        ( LHBL       ),
    .snd_rstb    ( snd_rstb   ),
    // Video
    .vint        ( vint       ),
    .line_intn   ( line_intn  ),
    .video_en    ( video_en   ),
    // Video circuitry
    .vram_cs     ( vram_cs    ),
    .char_cs     ( char_cs    ),
    .pal_cs      ( pal_cs     ),
    .objram_cs   ( objram_cs  ),
    .char_dout   ( char_dout  ),
    .pal_dout    ( pal_dout   ),
    .obj_dout    ( obj_dout   ),

    .flip        ( flip       ),
    // RAM access
    .ram_cs      ( ram_cs     ),
    .ram_data    ( ram_data   ),
    .ram_ok      ( ram_ok     ),
    // CPU bus
    .cpu_dout    ( main_dout  ),
    .dsn         ( main_dsn   ),
    .RnW         ( main_rnw   ),
    .sub_cs      ( sub_br     ),
    .sub_ok      ( sub_ok     ),
    .sub_din     ( sub_din    ),
    // cabinet I/O
    .joystick1   ( joystick1  ),
    .joystick2   ( joystick2  ),
    .joyana1     ( joyana_l1  ),
    .joyana1b    ( joyana_r1  ),
    .joyana2     ( joyana_l2  ),
    .joyana2b    ( joyana_r2  ),
    .start_button(start_button),
    .coin_input  ( coin_input ),
    .service     ( service    ),
    // ROM access
    .addr        ( main_addr  ),
    .rom_cs      ( main_cs    ),
    .rom_data    ( main_data  ),
    .rom_ok      ( main_ok    ),
    // Decoder configuration
    .dec_en      ( dec_en     ),
    .fd1089_en   ( fd1089_en  ),
    .fd1094_en   ( fd1094_en  ),
    .key_we      ( key_we     ),
    .fd1089_we   ( fd1089_we  ),
    .dec_type    ( dec_type   ),
    .key_addr    ( key_addr   ),
    .key_data    ( key_data   ),
    // Sound communication
    .sndmap_rd   ( sndmap_rd  ),
    .sndmap_wr   ( sndmap_wr  ),
    .sndmap_din  ( sndmap_din ),
    .sndmap_dout ( sndmap_dout),
    .sndmap_pbf  ( sndmap_pbf ),
    .prog_addr   ( prog_addr[12:0] ),
    .prog_data   ( prog_data[ 7:0] ),
    // DIP switches
    .dip_test    ( dip_test   ),
    .dipsw_a     ( dipsw_a    ),
    .dipsw_b     ( dipsw_b    ),
    // Status report
    .debug_bus   ( debug_bus  ),
    .st_addr     ( st_addr    ),
    .st_dout     ( st_main    )
);
`else
    assign flip      = 0;
    assign main_cs   = 0;
    assign ram_cs    = 0;
    assign vram_cs   = 0;
    assign main_rnw  = 1;
    assign main_dout = 0;
    assign video_en  = 1;
`endif

jtoutrun_sub u_sub(
    .rst        ( rst       ),
    .clk        ( clk       ),

    .irqn       ( irqn      ),    // common with main CPU

    // From main CPU
    .main_A     ( main_addr ),
    .main_dsn   ( main_dsn  ),
    .main_rnw   ( main_rnw  ),
    .sub_br     ( sub_br    ), // bus request
    .sub_din    ( sub_din   ),
    .main_dout  ( main_dout ),
    .sub_ok     ( sub_ok    ),
    .road_dout  ( road_dout ),

    // sub CPU bus
    .cpu_dout   ( sub_dout  ),
    .sub_addr   ( sub_addr  ),

    .rom_cs     ( srom_cs   ),
    .rom_ok     ( srom_ok   ),
    .rom_data   ( srom_data ),

    .ram_cs     ( sram_cs   ),
    .ram_ok     ( sram_ok   ),
    .ram_data   ( sram_data ),

    .road_cs    ( road_cs   ),
    .sio_cs     ( sio_cs    ),
    .dsn        ( sub_dsn   ),
    .RnW        ( sub_rnw   )
);

jtoutrun_snd u_sound(
    .rst        ( rst       ),
    .clk        ( clk       ),
    .snd_rstb   ( snd_rstb  ),

    .cen_fm     ( cen_fm    ),   // 4MHz
    .cen_fm2    ( cen_fm2   ),   // 2MHz

    // options
    .fxlevel    (dip_fxlevel),
    .enable_fm  ( enable_fm ),
    .enable_psg ( enable_psg),

    // Mapper device 315-5195
    .mapper_rd  ( sndmap_rd ),
    .mapper_wr  ( sndmap_wr ),
    .mapper_din ( sndmap_din),
    .mapper_dout(sndmap_dout),
    .mapper_pbf ( sndmap_pbf),

    // ROM
    .rom_addr   ( snd_addr  ),
    .rom_cs     ( snd_cs    ),
    .rom_data   ( snd_data  ),
    .rom_ok     ( snd_ok    ),

    .pcm_addr   ( pcm_addr  ),
    .pcm_cs     ( pcm_cs    ),
    .pcm_data   ( pcm_data  ),
    .pcm_ok     ( pcm_ok    ),

    // Sound output
    .snd_left   ( snd_left  ),
    .snd_right  ( snd_right ),
    .sample     ( sample    ),
    .peak       ( snd_clip  )
);

initial st_dout = 0;
// always @(posedge clk) begin
//     case( st_addr[7:4] )
//         0: st_dout <= st_video;
//         1: case( st_addr[3:0] )
//                 // 0: st_dout <= sndmap_dout;
//                 1: st_dout <= {2'd0, tile_bank};
//                 2: st_dout <= game_id;
//             endcase
//         2,3: st_dout <= st_main;
//     endcase
// end

jtoutrun_video u_video(
    .rst        ( rst       ),
    .clk        ( clk       ),
    .pxl2_cen   ( pxl2_cen  ),
    .pxl_cen    ( pxl_cen   ),
    .gfx_en     ( gfx_en    ),

    .video_en   ( video_en  ),
    .game_id    ( game_id   ),
    // CPU interface
    .cpu_addr   ( main_addr[13:1]),
    .sub_addr   ( sub_addr[11:1] ),
    .road_cs    ( road_cs   ),
    .sub_io_cs  ( sio_cs    ),
    .char_cs    ( char_cs   ),
    .pal_cs     ( pal_cs    ),
    .objram_cs  ( objram_cs ),
    .vint       ( vint      ),
    .line_intn  ( line_intn ),
    .dip_pause  ( dip_pause ),

    .cpu_dout   ( main_dout ),
    .main_dswn  ( main_dswn ),
    .sub_dswn   ( sub_dswn  ),
    .sub_dout   ( sub_dout  ),
    .char_dout  ( char_dout ),
    .pal_dout   ( pal_dout  ),
    .obj_dout   ( obj_dout  ),
    .road_dout  ( road_dout ),

    .flip       ( flip      ),
    .ext_flip   ( dip_flip  ),
    .colscr_en  ( colscr_en ),
    .rowscr_en  ( rowscr_en ),

    // SDRAM interface
    .char_ok    ( char_ok   ),
    .char_addr  ( char_addr ), // 9 addr + 3 vertical + 2 horizontal = 14 bits
    .char_data  ( char_data ),

    .map1_ok    ( map1_ok   ),
    .map1_addr  ( map1_addr ),
    .map1_data  ( map1_data ),

    .scr1_ok    ( scr1_ok   ),
    .scr1_addr  ( scr1_addr ),
    .scr1_data  ( scr1_data ),

    .map2_ok    ( map2_ok   ),
    .map2_addr  ( map2_addr ),
    .map2_data  ( map2_data ),

    .scr2_ok    ( scr2_ok   ),
    .scr2_addr  ( scr2_addr ),
    .scr2_data  ( scr2_data ),

    .obj_ok     ( obj_ok    ),
    .obj_cs     ( obj_cs    ),
    .obj_addr   ( obj_addr  ),
    .obj_data   ( obj_data  ),

    // Video signal
    .HS         ( HS        ),
    .VS         ( VS        ),
    .LHBL       ( LHBL      ),
    .LVBL       ( LVBL      ),
    .vdump      (           ),
    .vrender    ( vrender   ),
    .hstart     ( hstart    ),
    .red        ( red       ),
    .green      ( green     ),
    .blue       ( blue      ),
    // debug
    .debug_bus  ( debug_bus ),
    .st_addr    ( st_addr   ),
    .st_dout    ( st_video  ),
    .scr_bad    ( scr_bad   )
);

jtoutrun_sdram u_sdram(
    .rst        ( rst       ),
    .clk        ( clk       ),

    .vrender    ( vrender   ),
    .LVBL       ( LVBL      ),
    .game_id    ( game_id   ),

    .dec_en     ( dec_en    ),
    .fd1089_en  ( fd1089_en ),
    .fd1094_en  ( fd1094_en ),
    .dec_type   ( dec_type  ),
    .key_we     ( key_we    ),
    .fd1089_we  ( fd1089_we ),
    .key_addr   ( key_addr  ),
    .key_mcaddr ( key_mcaddr),
    .key_data   ( key_data  ),

    // Main CPU
    .main_cs    ( main_cs   ),
    .vram_cs    ( vram_cs   ),
    .ram_cs     ( ram_cs    ),

    .main_addr  ( main_addr[18:1] ),
    .main_data  ( main_data ),
    .ram_data   ( ram_data  ),

    .main_ok    ( main_ok   ),
    .ram_ok     ( ram_ok    ),

    .main_dsn   ( main_dsn  ),
    .main_dout  ( main_dout ),
    .main_rnw   ( main_rnw  ),

    // Sub CPU
    .srom_cs    ( srom_cs   ),
    .sram_cs    ( sram_cs   ),

    .sub_addr   ( sub_addr  ),
    .srom_data  ( srom_data ),
    .sram_data  ( sram_data ),

    .srom_ok    ( srom_ok   ),
    .sram_ok    ( sram_ok   ),

    .sub_dsn    ( sub_dsn   ),
    .sub_dout   ( sub_dout  ),
    .sub_rnw    ( sub_rnw   ),

    // Sound CPU
    .snd_addr   ( snd_addr  ),
    .snd_cs     ( snd_cs    ),
    .snd_data   ( snd_data  ),
    .snd_ok     ( snd_ok    ),

    // PCM ROM
    .pcm_addr   ( pcm_addr  ),
    .pcm_cs     ( pcm_cs    ),
    .pcm_data   ( pcm_data  ),
    .pcm_ok     ( pcm_ok    ),

    // Char interface
    .char_ok    ( char_ok   ),
    .char_addr  ( char_addr ), // 9 addr + 3 vertical + 2 horizontal = 14 bits
    .char_data  ( char_data ),

    // Scroll 1
    .map1_ok    ( map1_ok   ),
    .map1_addr  ( map1_addr ),
    .map1_data  ( map1_data ),

    .scr1_ok    ( scr1_ok   ),
    .scr1_addr  ( scr1_addr ),
    .scr1_data  ( scr1_data ),

    // Scroll 1
    .map2_ok    ( map2_ok   ),
    .map2_addr  ( map2_addr ),
    .map2_data  ( map2_data ),

    .scr2_ok    ( scr2_ok   ),
    .scr2_addr  ( scr2_addr ),
    .scr2_data  ( scr2_data ),

    // Sprite interface
    .obj_ok     ( obj_ok    ),
    .obj_cs     ( obj_cs    ),
    .obj_addr   ( obj_addr  ),
    .obj_data   ( obj_data  ),

    // Bank 0: allows R/W
    .ba0_addr   ( ba0_addr   ),
    .ba1_addr   ( ba1_addr   ),
    .ba2_addr   ( ba2_addr   ),
    .ba3_addr   ( ba3_addr   ),
    .ba_rd      ( ba_rd      ),
    .ba_wr      ( ba_wr      ),
    .ba_ack     ( ba_ack     ),
    .ba_dst     ( ba_dst     ),
    .ba_dok     ( ba_dok     ),
    .ba_rdy     ( ba_rdy     ),
    .ba0_din    ( ba0_din    ),
    .ba0_din_m  ( ba0_din_m  ),

    .data_read  ( data_read  ),

    // ROM load
    .downloading(downloading ),
    .dwnld_busy (dwnld_busy  ),

    .ioctl_addr ( ioctl_addr ),
    .ioctl_dout ( ioctl_dout ),
    .ioctl_wr   ( ioctl_wr   ),
    .prog_addr  ( prog_addr  ),
    .prog_data  ( prog_data  ),
    .prog_mask  ( prog_mask  ),
    .prog_ba    ( prog_ba    ),
    .prog_we    ( prog_we    ),
    .prog_rd    ( prog_rd    ),
    .prog_ack   ( prog_ack   ),
    .prog_rdy   ( prog_rdy   )
);

endmodule
