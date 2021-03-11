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

module jts16_game(
    input           rst,
    input           clk,
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
    input   [ 1:0]  start_button,
    input   [ 1:0]  coin_input,
    input   [ 6:0]  joystick1,
    input   [ 6:0]  joystick2,

    // SDRAM interface
    input           downloading,
    output          dwnld_busy,

    // Bank 0: allows R/W
    output   [21:0] ba0_addr,
    output          ba0_rd,
    output          ba0_wr,
    output   [15:0] ba0_din,
    output   [ 1:0] ba0_din_m,  // write mask
    input           ba0_rdy,
    input           ba0_ack,

    // Bank 1: Read only
    output   [21:0] ba1_addr,
    output          ba1_rd,
    input           ba1_rdy,
    input           ba1_ack,

    // Bank 2: Read only
    output   [21:0] ba2_addr,
    output          ba2_rd,
    input           ba2_rdy,
    input           ba2_ack,

    // Bank 3: Read only
    output   [21:0] ba3_addr,
    output          ba3_rd,
    input           ba3_rdy,
    input           ba3_ack,

    input   [31:0]  data_read,
    output          refresh_en,
    // ROM LOAD
    input   [24:0]  ioctl_addr,
    input   [ 7:0]  ioctl_data,
    input           ioctl_wr,
    output  [21:0]  prog_addr,
    output  [15:0]  prog_data,
    output  [ 1:0]  prog_mask,
    output  [ 1:0]  prog_ba,
    output          prog_we,
    output          prog_rd,
    input           prog_ack,
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
    output  signed [15:0] snd_left,
    output  signed [15:0] snd_right,
    output          sample,
    output          game_led,
    input           enable_psg,
    input           enable_fm,
    // Debug
    input   [3:0]   gfx_en
);

// clock enable signals
wire    cpu_cen, cpu_cenb,
        snd_cen, fm_cen;

// video signals
wire    HB, VB, LVBL;

// SDRAM interface
wire         char_ok;
wire [12:0]  char_addr;
wire [31:0]  char_data;

wire         map1_ok, map2_ok;
wire [13:0]  map1_addr, map2_addr; // 3 pages + 11 addr = 14 (32 kB)
wire [15:0]  map1_data, map2_data;

wire         scr1_ok, scr2_ok;
wire [16:0]  scr1_addr, scr2_addr; // 1 bank + 12 addr + 3 vertical + 1 (32-bit) = 15 bits
wire [31:0]  scr1_data, scr2_data;

// CPU interface
wire [12:1]  cpu_addr;
wire [15:0]  cpu_dout, char_dout, mmr_dout, pal_dout;
wire [ 1:0]  dsn;
wire         char_cs, scr1_cs, pal_cs;

jts16_cen u_cen(
    .rst        ( rst       ),
    .clk        ( clk       ),
    .pxl2_cen   ( pxl2_cen  ),
    .pxl_cen    ( pxl_cen   ),
    .cpu_cen    ( cpu_cen   ),
    .cpu_cenb   ( cpu_cenb  ),
    .snd_cen    ( snd_cen   ),
    .fm_cen     ( fm_cen    )
);

jts16_video u_video(
    .rst        ( rst       ),
    .clk        ( clk       ),
    .pxl2_cen   ( pxl2_cen  ),
    .pxl_cen    ( pxl_cen   ),

    // CPU interface
    .cpu_addr   ( cpu_addr  ),
    .char_cs    ( char_cs   ),
    .scr1_cs    ( scr1_cs   ),
    .pal_cs     ( pal_cs    ),
    .cpu_dout   ( cpu_dout  ),
    .dsn        ( dsn       ),
    .char_dout  ( char_dout ),
    .mmr_dout   ( mmr_dout  ),
    .pal_dout   ( pal_dout  ),

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

    // Video signal
    .HS         ( HS        ),
    .VS         ( VS        ),
    .HB         ( HB        ),
    .VB         ( VB        ),
    .LVBL       ( LVBL      ),
    .LHBL_dly   ( LHBL_dly  ),
    .LVBL_dly   ( LVBL_dly  ),
    .red        ( red       ),
    .green      ( green     ),
    .blue       ( blue      )
);

jts16_sdram u_sdram(
    .rst        ( rst       ),
    .clk        ( clk       ),
    .LVBL       ( LVBL      ),

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

    // Bank 0: allows R/W
    .ba0_addr   ( ba0_addr  ),
    .ba0_rd     ( ba0_rd    ),
    .ba0_wr     ( ba0_wr    ),
    .ba0_ack    ( ba0_ack   ),
    .ba0_rdy    ( ba0_rdy   ),
    .ba0_din    ( ba0_din   ),
    .ba0_din_m  ( ba0_din_m ),

    // Bank 1: Read only
    .ba1_addr   ( ba1_addr  ),
    .ba1_rd     ( ba1_rd    ),
    .ba1_rdy    ( ba1_rdy   ),
    .ba1_ack    ( ba1_ack   ),

    .data_read  ( data_read ),
    .refresh_en ( refresh_en)
);

endmodule
