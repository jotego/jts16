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
    Date: 6-3-2021 */

module `GAMETOP(
    input           rst,
    input           clk,
    input           rst24,
    input           clk24,
    output          pxl2_cen,   // 12   MHz
    output          pxl_cen,    //  6   MHz
    output   [4:0]  red,
    output   [4:0]  green,
    output   [4:0]  blue,
    output          LHBL_dly,
    output          LVBL_dly,
    output          HS,
    output          VS,
    // cabinet I/O
    input   [ 3:0]  start_button,
    input   [ 3:0]  coin_input,
    input   [ 7:0]  joystick1,
    input   [ 7:0]  joystick2,
    input   [ 7:0]  joystick3,
    input   [ 7:0]  joystick4,
    input   [15:0]  joyana1,
    input   [15:0]  joyana2,
    input   [15:0]  joyana3,
    input   [15:0]  joyana4,

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
    output  [ 7:0]  ioctl_din,
    input           ioctl_ram, // 0 - ROM, 1 - RAM(EEPROM)
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
    input           dip_flip,
    input           dip_test,
    input   [ 1:0]  dip_fxlevel, // Not a DIP on the original PCB
    // Sound output
    output  signed [15:0] snd,
    output          sample,
    output          game_led,
    input           enable_psg,
    input           enable_fm,
    // Debug
    input   [3:0]   gfx_en,
    input   [7:0]   debug_bus,
    // status dump
    input   [ 7:0]  st_addr,
    output reg [ 7:0]  st_dout
);

`ifndef S16B
    localparam SNDW=15;
    wire [7:0] sndmap_dout=0;
`else
    localparam SNDW=19;

    wire [7:0] sndmap_din, sndmap_dout;
    wire       sndmap_rd, sndmap_wr, sndmap_obf;
`endif

// clock enable signals
wire    cpu_cen, cpu_cenb,
        cen_fm,  cen_fm2, cen_snd,
        cen_pcm, cen_pcmb;

// video signals
wire        HB, VB, LVBL;
wire [ 8:0] vrender;
wire        hstart, vint;
wire        colscr_en, rowscr_en;
wire [ 5:0] tile_bank;

// SDRAM interface
wire        main_cs, vram_cs, ram_cs;
wire [18:1] main_addr;
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
wire [12:1] cpu_addr;
wire [15:0] main_dout, char_dout, pal_dout, obj_dout;
wire [ 1:0] dsn;
wire        UDSWn, LDSWn, main_rnw;
wire        char_cs, scr1_cs, pal_cs, objram_cs;

// Sound CPU
wire [SNDW-1:0] snd_addr;
wire [ 7:0] snd_data;
wire        snd_cs, snd_ok;
wire        mc8123_we; // only for S16B2 core

// PCM
wire [16:0] pcm_addr;
wire        pcm_cs;
wire [ 7:0] pcm_data;
wire        pcm_ok;
wire        n7751_prom;

// Protection
wire        key_we, fd1089_we;
wire        dec_en, dec_type;
wire        mcu_en, mcu_we, mcu_cen;

wire [ 7:0] snd_latch;
wire        snd_irqn, snd_ack;

wire        flip, video_en, sound_en;

// Cabinet inputs
wire [ 7:0] dipsw_a, dipsw_b;
wire [ 7:0] game_id;

// Status report
wire [7:0] st_video, st_main;

assign { dipsw_b, dipsw_a } = dipsw[15:0];
assign dsn = { UDSWn, LDSWn };

jts16_cen u_cen(
    .rst        ( rst       ),

    .clk        ( clk       ),
    .pxl2_cen   ( pxl2_cen  ),
    .pxl_cen    ( pxl_cen   ),
    .cpu_cen    (           ),
    .cpu_cenb   (           ),

    .clk24      ( clk24     ),
    .mcu_cen    ( mcu_cen   ),
    .fm2_cen    ( cen_fm2   ),
    .fm_cen     ( cen_fm    ),
    .snd_cen    ( cen_snd   ),
    .pcm_cen    ( cen_pcm   ),
    .pcm_cenb   ( cen_pcmb  )
);

`ifndef NOMAIN
`JTS16_MAIN u_main(
    .rst        ( rst       ),
    .clk        ( clk       ),
    .clk_rom    ( clk       ),  // same clock - at least for now
    .cpu_cen    ( cpu_cen   ),
    .cpu_cenb   ( cpu_cenb  ),
    .game_id    ( game_id   ),
    // Video
    .vint       ( vint      ),
    .video_en   ( video_en  ),
    // Video circuitry
    .vram_cs    ( vram_cs   ),
    .char_cs    ( char_cs   ),
    .pal_cs     ( pal_cs    ),
    .objram_cs  ( objram_cs ),
    .char_dout  ( char_dout ),
    .pal_dout   ( pal_dout  ),
    .obj_dout   ( obj_dout  ),

    .flip       ( flip      ),
    .colscr_en  ( colscr_en ),
    .rowscr_en  ( rowscr_en ),
    // RAM access
    .ram_cs     ( ram_cs    ),
    .ram_data   ( ram_data  ),
    .ram_ok     ( ram_ok    ),
    // CPU bus
    .cpu_dout   ( main_dout ),
    .UDSWn      ( UDSWn     ),
    .LDSWn      ( LDSWn     ),
    .RnW        ( main_rnw  ),
    .cpu_addr   ( cpu_addr  ),
    // cabinet I/O
    .joystick1   ( joystick1  ),
    .joystick2   ( joystick2  ),
    .joystick3   ( joystick3  ),
    .joystick4   ( joystick4  ),
    .joyana1     ( joyana1    ),
    .joyana2     ( joyana2    ),
    .joyana3     ( joyana3    ),
    .joyana4     ( joyana4    ),
    .start_button(start_button),
    .coin_input  ( coin_input ),
    .service     ( service    ),
    // ROM access
    .rom_cs      ( main_cs    ),
    .rom_addr    ( main_addr  ),
    .rom_data    ( main_data  ),
    .rom_ok      ( main_ok    ),
    // Decoder configuration
    .dec_en      ( dec_en     ),
    .key_we      ( key_we     ),
    .fd1089_we   ( fd1089_we  ),
    .dec_type    ( dec_type   ),
`ifndef S16B
    // Sound communication
    .snd_latch   ( snd_latch  ),
    .snd_irqn    ( snd_irqn   ),
    .snd_ack     ( snd_ack    ),
    .sound_en    ( sound_en   ),
`else
    .rst24       ( rst24      ),
    .clk24       ( clk24      ),  // To ease MCU compilation
    .mcu_cen     ( mcu_cen    ),
    .mcu_en      ( mcu_en     ),
    .mcu_prog_we ( mcu_we     ),
    .sndmap_rd   ( sndmap_rd  ),
    .sndmap_wr   ( sndmap_wr  ),
    .sndmap_din  ( sndmap_din ),
    .sndmap_dout (sndmap_dout ),
    .sndmap_obf  ( sndmap_obf ),
    .tile_bank   ( tile_bank  ),
`endif
    .prog_addr   ( prog_addr[12:0] ),
    .prog_data   ( prog_data[ 7:0] ),
    // DIP switches
    .dip_pause   ( dip_pause  ),
    .dip_test    ( dip_test   ),
    .dipsw_a     ( dipsw_a    ),
    .dipsw_b     ( dipsw_b    ),
    // Status report
    .debug_bus   ( debug_bus  ),
    .st_addr     ( st_addr    ),
    .st_dout     ( st_main    ),
    // NVRAM dump
    .ioctl_din   ( ioctl_din  ),
    .ioctl_addr  ( ioctl_addr[16:0] )
);
`else
    assign flip      = 0;
    assign main_cs   = 0;
    assign ram_cs    = 0;
    assign vram_cs   = 0;
    assign UDSWn     = 1;
    assign LDSWn     = 1;
    assign main_rnw  = 1;
    assign main_dout = 0;
    assign video_en  = 1;
    assign sound_en  = 0; // active low (?)
    `ifdef S16B
        reg aux_obf = 0;
        reg [7:0] aux_dout=0;
        assign sndmap_dout = aux_dout;
        assign sndmap_obf  = aux_obf;
        integer framecnt=0, last_fcnt=0;

        always @(negedge LVBL) begin
            framecnt <= framecnt+1;
        end
        always @(negedge LHBL_dly) begin
            last_fcnt <= framecnt;
            aux_obf <= last_fcnt != framecnt && (framecnt==10
                || framecnt==12
                // || framecnt==32
                // || framecnt==72
                // || framecnt==112
            );
            if( framecnt == 11 ) aux_dout <= 8'h4b; //8'h48 Ok; 4c
            //if( framecnt == 31 ) aux_dout <= 8'h42;
            //if( framecnt == 71 ) aux_dout <= 8'h41;
            //if( framecnt ==111 ) aux_dout <= 8'h40;
        end
    `endif
`endif

`ifndef NOSOUND
`JTS16_SND u_sound(
    .rst        ( rst24     ),
    .clk        ( clk24     ),

    .cen_fm     ( cen_fm    ),   // 4MHz or 5MHz
    .cen_fm2    ( cen_fm2   ),   // 2MHz
    .cen_pcm    ( cen_pcm   ),   // 6MHz or 640kHz

    .fxlevel    (dip_fxlevel),
    .enable_fm  ( enable_fm ),
    .enable_psg ( enable_psg),

`ifdef S16B
    // System 16B
    .cen_snd    ( cen_snd   ),  // 5MHz
    .mapper_rd  ( sndmap_rd ),
    .mapper_wr  ( sndmap_wr ),
    .mapper_din ( sndmap_din),
    .mapper_dout(sndmap_dout),
    .mapper_obf ( sndmap_obf),
    .game_id    ( game_id   ),
    // MC8123 encoding
    .mc8123_we  ( mc8123_we ),
    .prog_addr  (prog_addr[12:0]),
    .prog_data  ( prog_data ),
`else
    // System 16A
    .cen_pcmb   ( cen_pcmb  ),   // 6MHz
    .sound_en   ( sound_en  ),

    .latch      ( snd_latch ),
    .irqn       ( snd_irqn  ),
    .ack        ( snd_ack   ),
    // MCU PROM
    .prom_we    ( n7751_prom     ),
    .prog_addr  ( prog_addr[9:0] ),
    .prog_data  ( prog_data[7:0] ),

    // ADPCM ROM
    .pcm_addr   ( pcm_addr  ),
    .pcm_cs     ( pcm_cs    ),
    .pcm_data   ( pcm_data  ),
    .pcm_ok     ( pcm_ok    ),
`endif
    // ROM
    .rom_addr   ( snd_addr  ),
    .rom_cs     ( snd_cs    ),
    .rom_data   ( snd_data  ),
    .rom_ok     ( snd_ok    ),

    // Sound output
    .snd        ( snd       ),
    .sample     ( sample    ),
    .peak       ( game_led  )
);
`else
    assign snd_cs=0;
    assign snd_addr=0;
    //assign pcm_cs=0;
    //assign pcm_addr=0;
    `ifdef SIMULATION
        reg [7:0] sim_def[0:1];

        initial begin
            $readmemh("tilebank.hex",sim_def);
            $display("Tile bank set to %X",sim_def[0]);
        end
        assign tile_bank = sim_def[0][5:0];
    `endif
`endif

`ifdef S16B
assign pcm_cs   = 0;
assign pcm_addr = 0;
`else
assign tile_bank = 0; // unused on S16A
`endif

always @(posedge clk) begin
    st_dout <= 0;
    case( st_addr[7:4] )
        0: st_dout <= st_video;
        1: case( st_addr[3:0] )
                0: st_dout <= sndmap_dout;
                1: st_dout <= {2'd0, tile_bank};
                2: st_dout <= game_id;
            endcase
        2,3: st_dout <= st_main;
    endcase
end

jts16_video u_video(
    .rst        ( rst       ),
    .clk        ( clk       ),
    .pxl2_cen   ( pxl2_cen  ),
    .pxl_cen    ( pxl_cen   ),
    .gfx_en     ( gfx_en    ),

    .video_en   ( video_en  ),
    .game_id    ( game_id   ),
    // CPU interface
    .cpu_addr   ( cpu_addr  ),
    .char_cs    ( char_cs   ),
    .pal_cs     ( pal_cs    ),
    .objram_cs  ( objram_cs ),
    .vint       ( vint      ),

    .cpu_dout   ( main_dout ),
    .dsn        ( dsn       ),
    .char_dout  ( char_dout ),
    .pal_dout   ( pal_dout  ),
    .obj_dout   ( obj_dout  ),

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
    .HB         ( HB        ),
    .VB         ( VB        ),
    .LVBL       ( LVBL      ),
    .LHBL_dly   ( LHBL_dly  ),
    .LVBL_dly   ( LVBL_dly  ),
    .vdump      (           ),
    .vrender    ( vrender   ),
    .hstart     ( hstart    ),
    .red        ( red       ),
    .green      ( green     ),
    .blue       ( blue      ),
    // debug
    .debug_bus  ( debug_bus ),
    .st_addr    ( st_addr   ),
    .st_dout    ( st_video  )
);

jts16_sdram #(.SNDW(SNDW)) u_sdram(
    .rst        ( rst       ),
    .clk        ( clk       ),
    .ioctl_ram  ( ioctl_ram ),

    .vrender    ( vrender   ),
    .LVBL       ( LVBL      ),
    .game_id    ( game_id   ),
    .tile_bank  ( tile_bank ),
    //.tile_bank  ( debug_bus[5:0] ),

    .dec_en     ( dec_en    ),
    .dec_type   ( dec_type  ),
    .key_we     ( key_we    ),
    .fd1089_we  ( fd1089_we ),

    // i8751 MCU
    .mcu_we     ( mcu_we    ),
    .mcu_en     ( mcu_en    ),

    // Main CPU
    .main_cs    ( main_cs   ),
    .vram_cs    ( vram_cs   ),
    .ram_cs     ( ram_cs    ),

    .main_addr  ( main_addr ),
    .main_data  ( main_data ),
    .ram_data   ( ram_data  ),

    .main_ok    ( main_ok   ),
    .ram_ok     ( ram_ok    ),

    .dsn        ( dsn       ),
    .main_dout  ( main_dout ),
    .main_rnw   ( main_rnw  ),

    // Sound CPU
    .snd_addr   ( snd_addr  ),
    .snd_cs     ( snd_cs    ),
    .snd_data   ( snd_data  ),
    .snd_ok     ( snd_ok    ),
    .mc8123_we  ( mc8123_we ),

    // ADPCM ROM
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
    .ba0_addr    ( ba0_addr      ),
    .ba1_addr    ( ba1_addr      ),
    .ba2_addr    ( ba2_addr      ),
    .ba3_addr    ( ba3_addr      ),
    .ba_rd       ( ba_rd         ),
    .ba_wr       ( ba_wr         ),
    .ba_ack      ( ba_ack        ),
    .ba_dst      ( ba_dst        ),
    .ba_dok      ( ba_dok        ),
    .ba_rdy      ( ba_rdy        ),
    .ba0_din     ( ba0_din       ),
    .ba0_din_m   ( ba0_din_m     ),

    .data_read   ( data_read     ),

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
    .n7751_prom ( n7751_prom ),
    .prog_rd    ( prog_rd    ),
    .prog_ack   ( prog_ack   ),
    .prog_rdy   ( prog_rdy   )
);

endmodule
