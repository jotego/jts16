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

module jts16_sdram(
    input           rst,
    input           clk,

    input           LVBL,
    input    [ 8:0] vrender,

    // Main CPU
    input           main_cs,
    input           vram_cs,
    input           ram_cs,
    input    [17:1] main_addr,
    output   [15:0] main_data,
    output   [15:0] ram_data,
    output          main_ok,
    output          ram_ok,
    input    [ 1:0] dsn,
    input    [15:0] main_dout,
    input           main_rnw,

    // Sound CPU
    input           snd_cs,
    output          snd_ok,
    input   [14:0]  snd_addr,
    output  [ 7:0]  snd_data,

    // Char
    output          char_ok,
    input   [12:0]  char_addr, // 9 addr + 3 vertical + 2 horizontal = 14 bits
    output  [31:0]  char_data,

    // Scroll 1
    output          map1_ok,
    input   [13:0]  map1_addr, // 3 pages + 11 addr = 14 (32 kB)
    output  [15:0]  map1_data,

    output          scr1_ok,
    input   [16:0]  scr1_addr, // 1 bank + 12 addr + 3 vertical = 15 bits
    output  [31:0]  scr1_data,

    // Scroll 1
    output          map2_ok,
    input   [13:0]  map2_addr, // 3 pages + 11 addr = 14 (32 kB)
    output  [15:0]  map2_data,

    output          scr2_ok,
    input   [16:0]  scr2_addr, // 1 bank + 12 addr + 3 vertical = 15 bits
    output  [31:0]  scr2_data,

    // Obj
    output          obj_ok,
    input           obj_cs,
    input   [17:0]  obj_addr,
    output  [15:0]  obj_data,

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

    input    [31:0] data_read,
    output          refresh_en,

    // ROM LOAD
    input           downloading,
    output          dwnld_busy,

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
    input           prog_rdy
);

localparam [21:0] ZERO_OFFSET=0,
                  VRAM_OFFSET=22'h10_0000;

wire [14:0] xram_addr;  // 32 kB VRAM + 16kB RAM
wire        xram_cs;

wire        gfx_cs = LVBL || vrender==0 || vrender[8];

assign refresh_en = LVBL;
assign xram_addr  = { 1'b0 , main_addr[14:1] }; // RAM is mapped up
assign xram_cs    = vram_cs;

assign dwnld_busy = downloading;

jtframe_dwnld #(
    .HEADER    ( 32         ),
    .BA1_START ( 25'h4_0000 ), // sound
    .BA2_START ( 25'h5_0000 ), // tiles
    .BA3_START ( 25'h9_0000 ), // obj
    .SWAB      ( 1          )
) u_dwnld(
    .clk          ( clk            ),
    .downloading  ( downloading    ),
    .ioctl_addr   ( ioctl_addr     ),
    .ioctl_data   ( ioctl_data     ),
    .ioctl_wr     ( ioctl_wr       ),
    .prog_addr    ( prog_addr      ),
    .prog_data    ( prog_data      ),
    .prog_mask    ( prog_mask      ), // active low
    .prog_we      ( prog_we        ),
    .prog_rd      ( prog_rd        ),
    .prog_ba      ( prog_ba        ),
    .prom_we      (                ),
    .sdram_ack    ( prog_ack       )
);

jtframe_ram_4slots #(
    // VRAM/RAM
    .SLOT0_DW(16),
    .SLOT0_AW(15),  // 32 kB + 16kB

    // Game ROM
    .SLOT1_DW(16),
    .SLOT1_AW(17),  // 256kB temptative value

    // VRAM access by SCR1
    .SLOT2_DW(16),
    .SLOT2_AW(14),

    // VRAM access by SCR2
    .SLOT3_DW(16),
    .SLOT3_AW(14)
) u_bank0(
    .rst        ( rst       ),
    .clk        ( clk       ),

    .offset0    (VRAM_OFFSET),
    .offset1    (ZERO_OFFSET),
    .offset2    (VRAM_OFFSET),
    .offset3    (VRAM_OFFSET),

    .slot0_addr ( xram_addr ),
    .slot1_addr ( main_addr ),
    .slot2_addr ( map1_addr ),
    .slot3_addr ( map2_addr ),

    //  output data
    .slot0_dout ( ram_data  ),
    .slot1_dout ( main_data ),
    .slot2_dout ( map1_data ),
    .slot3_dout ( map2_data ),

    .slot0_cs   ( xram_cs   ),
    .slot1_cs   ( main_cs   ),
    .slot2_cs   ( gfx_cs    ),
    .slot3_cs   ( gfx_cs    ),

    .slot0_wen  ( ~main_rnw ),
    .slot0_din  ( main_dout ),
    .slot0_wrmask( dsn      ),

    .slot1_clr  ( 1'b0      ),
    .slot2_clr  ( 1'b0      ),
    .slot3_clr  ( 1'b0      ),

    .slot0_ok   ( ram_ok    ),
    .slot1_ok   ( main_ok   ),
    .slot2_ok   ( map1_ok   ),
    .slot3_ok   ( map2_ok   ),

    // SDRAM controller interface
    .sdram_ack   ( ba0_ack   ),
    .sdram_rd    ( ba0_rd    ),
    .sdram_wr    ( ba0_wr    ),
    .sdram_addr  ( ba0_addr  ),
    .data_rdy    ( ba0_rdy   ),
    .data_write  ( ba0_din   ),
    .sdram_wrmask( ba0_din_m ),
    .data_read   ( data_read )
);

jtframe_rom_3slots #(
    .SLOT0_DW(32),
    .SLOT0_AW(13),

    .SLOT1_DW(32),
    .SLOT1_AW(17),

    .SLOT2_DW(32),
    .SLOT2_AW(17)
) u_bank2(
    .rst        ( rst       ),
    .clk        ( clk       ),

    .slot0_addr ( char_addr ),
    .slot1_addr ( scr1_addr ),
    .slot2_addr ( scr2_addr ),

    //  output data
    .slot0_dout ( char_data ),
    .slot1_dout ( scr1_data ),
    .slot2_dout ( scr2_data ),

    .slot0_cs   ( gfx_cs    ),
    .slot1_cs   ( gfx_cs    ),
    .slot2_cs   ( gfx_cs    ),

    .slot0_ok   ( char_ok   ),
    .slot1_ok   ( scr1_ok   ),
    .slot2_ok   ( scr2_ok   ),

    // SDRAM controller interface
    .sdram_ack  ( ba2_ack   ),
    .sdram_req  ( ba2_rd    ),
    .sdram_addr ( ba2_addr  ),
    .data_rdy   ( ba2_rdy   ),
    .data_read  ( data_read )
);

// OBJ
jtframe_rom_1slot #(
    .SLOT0_DW(16),
    .SLOT0_AW(18)
) u_bank3(
    .rst        ( rst       ),
    .clk        ( clk       ),

    .slot0_addr ( obj_addr  ),
    .slot0_dout ( obj_data  ),
    .slot0_cs   ( obj_cs    ),
    .slot0_ok   ( obj_ok    ),

    // SDRAM controller interface
    .sdram_ack  ( ba3_ack   ),
    .sdram_req  ( ba3_rd    ),
    .sdram_addr ( ba3_addr  ),
    .data_rdy   ( ba3_rdy   ),
    .data_read  ( data_read )
);

// Sound
jtframe_rom_1slot #(
    .SLOT0_DW( 8),
    .SLOT0_AW(15)
) u_bank1(
    .rst        ( rst       ),
    .clk        ( clk       ),

    .slot0_addr ( snd_addr  ),
    .slot0_dout ( snd_data  ),
    .slot0_cs   ( snd_cs    ),
    .slot0_ok   ( snd_ok    ),

    // SDRAM controller interface
    .sdram_ack  ( ba1_ack   ),
    .sdram_req  ( ba1_rd    ),
    .sdram_addr ( ba1_addr  ),
    .data_rdy   ( ba1_rdy   ),
    .data_read  ( data_read )
);

endmodule