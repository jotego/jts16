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

module jtoutrun_sdram(
    input            rst,
    input            clk,

    input            LVBL,
    input      [8:0] vrender,
    output reg [1:0] game_id,

    // Encryption
    output           fd1089_we,
    output           key_we,
    input     [12:0] key_addr,
    input     [12:0] key_mcaddr,
    output    [ 7:0] key_data,

    // Main CPU
    input            main_cs,
    input            vram_cs,
    input            ram_cs,
    input     [18:1] main_addr,
    output    [15:0] main_data,
    output    [15:0] ram_data,
    output           main_ok,
    output           ram_ok,
    input     [ 1:0] main_dsn,
    input     [15:0] main_dout,
    input            main_rnw,

    // Sub CPU
    input            srom_cs,
    input            sram_cs,
    input     [18:1] sub_addr,
    output    [15:0] srom_data,
    output    [15:0] sram_data,
    output           srom_ok,
    output           sram_ok,
    input     [ 1:0] sub_dsn,
    input     [15:0] sub_dout,
    input            sub_rnw,

    // Sound CPU
    // input            snd_cs,
    // output           snd_ok,
    // input [SNDW-1:0] snd_addr,
    // output     [7:0] snd_data,


    // ADPCM ROM
    output  reg      dec_en,
    output  reg      fd1089_en,
    output  reg      fd1094_en,
    output  reg      dec_type,
    // input     [16:0] pcm_addr,
    // input            pcm_cs,
    // output    [ 7:0] pcm_data,
    // output           pcm_ok,

    // Char
    // output           char_ok,
    // input    [12:0]  char_addr, // 9 addr + 3 vertical + 2 horizontal = 14 bits
    // output   [31:0]  char_data,

    // Scroll 1
    // output           map1_ok,
    // input    [14:0]  map1_addr, // 3(+1) pages + 11 addr = 14/15 (32/64 kB)
    // output   [15:0]  map1_data,

    // output           scr1_ok,
    // input    [16:0]  scr1_addr, // 1 bank + 12 addr + 3 vertical = 15 bits
    // output   [31:0]  scr1_data,

    // Obj
    // output           obj_ok,
    // input            obj_cs,
    // input    [19:0]  obj_addr,
    // output   [15:0]  obj_data,

    // Bank 0: allows R/W
    output    [21:0] ba0_addr,
    output    [21:0] ba1_addr,
    output    [21:0] ba2_addr,
    output    [21:0] ba3_addr,
    output    [ 3:0] ba_rd,
    output           ba_wr,
    output    [15:0] ba0_din,
    output    [ 1:0] ba0_din_m,  // write mask
    input     [ 3:0] ba_ack,
    input     [ 3:0] ba_dst,
    input     [ 3:0] ba_dok,
    input     [ 3:0] ba_rdy,

    input     [15:0] data_read,

    // ROM LOAD
    input            downloading,
    output           dwnld_busy,

    input    [24:0]  ioctl_addr,
    input    [ 7:0]  ioctl_dout,
    input            ioctl_wr,
    output   [21:0]  prog_addr,
    output   [15:0]  prog_data,
    output   [ 1:0]  prog_mask,
    output   [ 1:0]  prog_ba,
    output           prog_we,
    output           prog_rd,
    input            prog_ack,
    input            prog_rdy
    //, input    [ 7:0]  debug_bus
);

/* verilator lint_off WIDTH */
localparam [24:0] BA1_START  = `BA1_START,
                  BA2_START  = `BA2_START,
                  BA3_START  = `BA3_START,
                  ROAD_START = `ROAD_START,
                  KEY_PROM   = `KEY_START,
                  FD_PROM    = `FD1089_START;
/* verilator lint_on WIDTH */
localparam [21:0] ZERO_OFFSET= 22'd0,
                  VRAM_OFFSET= 22'h08_0000,
                  SROM_OFFSET= 22'h10_0000,
                  SRAM_OFFSET= 22'h18_0000;


reg  [16:1] xram_addr;
wire        xram_cs;
wire        prom_we, header;

//  wire        gfx_cs = LVBL || vrender==0 || vrender[8];

assign xram_cs    = ram_cs | vram_cs;
assign dwnld_busy = downloading | prom_we; // prom_we is really just for sims
assign key_we     = prom_we && prog_addr[21:13]==KEY_PROM   [21:13];
assign fd1089_we  = prom_we && prog_addr[21: 8]==FD_PROM    [21: 8];

always @(*) begin
    xram_addr = { ram_cs, main_addr[15:1] }; // RAM is mapped up
    if( ram_cs ) xram_addr[15] = 0;
end

always @(posedge clk) begin
    if( header && ioctl_wr ) begin
        if( ioctl_addr[3:0]==0 ) begin
            fd1089_en <= ioctl_dout[1];
            dec_type  <= ioctl_dout[0];
            fd1094_en <= ioctl_dout[2];
        end
        if( ioctl_addr[3:0]==1 ) game_id <= ioctl_dout[1:0];
    end
    dec_en <= fd1089_en | fd1094_en;
end

jtframe_prom #(.aw(13),.simfile("317-5021.key")) u_key(
    .clk    ( clk       ),
    .cen    ( 1'b1      ),
    .data   ( prog_data[7:0] ),
    .rd_addr( key_addr  ),
    .wr_addr( prog_addr[12:0] ),
    .we     ( key_we    ),
    .q      ( key_data  )
);

jtframe_dwnld #(
    .HEADER    ( 32        ),
    .BA1_START ( BA1_START ), // sound
    .BA2_START ( BA2_START ), // tiles
    .BA3_START ( BA3_START ), // obj
    .PROM_START( KEY_PROM  ), // PCM MCU
    .SWAB      ( 1         )
) u_dwnld(
    .clk          ( clk            ),
    .downloading  ( downloading    ),
    .ioctl_addr   ( ioctl_addr     ),
    .ioctl_dout   ( ioctl_dout     ),
    .ioctl_wr     ( ioctl_wr       ),
    .prog_addr    ( prog_addr      ),
    .prog_data    ( prog_data      ),
    .prog_mask    ( prog_mask      ), // active low
    .prog_we      ( prog_we        ),
    .prog_rd      ( prog_rd        ),
    .prog_ba      ( prog_ba        ),
    .prom_we      ( prom_we        ),
    .header       ( header         ),
    .sdram_ack    ( prog_ack       )
);

jtframe_ram2_5slots #(
    // Main CPU RAM/VRAM
    .SLOT0_AW(16),  // 64 (VRAM) + 32 (RAM) kB
    .SLOT0_DW(16),

    // Sub CPU RAM
    .SLOT1_AW(14),  // 32 kB
    .SLOT1_DW(16),

    // Main CPU ROM
    .SLOT2_AW   (18),  // 512kB
    .SLOT2_DW   (16),
    .SLOT2_LATCH( 0),

    // Sub CPU ROM
    .SLOT3_AW   (18),  // 512kB
    .SLOT3_DW   (16),
    .SLOT3_LATCH( 0),

    // VRAM access by SCR
    .SLOT4_AW   (15),
    .SLOT4_DW   (16)
) u_bank0(
    .rst        ( rst       ),
    .clk        ( clk       ),

    .offset0    (VRAM_OFFSET),  // RAM/VRAM main
    .offset1    (SRAM_OFFSET),  // RAM sub
    .offset2    (ZERO_OFFSET),  // Main ROM
    .offset3    (SROM_OFFSET),  // Main RAM
    .offset4    (VRAM_OFFSET),

    .slot0_addr ( xram_addr ),
    .slot1_addr ( sub_addr[14:1] ),
    .slot2_addr ( main_addr ),
    .slot3_addr ( sub_addr  ),
    //.slot4_addr ( map_addr  ),
    .slot4_addr (    ),

    //  output data
    .slot0_dout ( ram_data  ),
    .slot1_dout ( sram_data ),
    .slot2_dout ( main_data ),
    .slot3_dout ( srom_data ),
    //.slot4_dout ( map_data  ),
    .slot4_dout (    ),

    .slot0_cs   ( xram_cs   ),
    .slot1_cs   ( sram_cs   ),
    .slot2_cs   ( main_cs   ),
    .slot3_cs   ( srom_cs   ),
    .slot4_cs   ( 1'b0    ),
    //.slot4_cs   ( map_cs    ),

    .slot0_wen  ( ~main_rnw ),
    .slot0_din  ( main_dout ),
    .slot0_wrmask( main_dsn ),

    .slot1_wen  ( ~sub_rnw  ),
    .slot1_din  ( sub_dout  ),
    .slot1_wrmask( sub_dsn  ),


    .slot2_clr  ( 1'b0      ),
    .slot3_clr  ( 1'b0      ),
    .slot4_clr  ( 1'b0      ),

    .slot0_ok   ( ram_ok    ),
    .slot1_ok   ( sram_ok   ),
    .slot2_ok   ( main_ok   ),
    .slot3_ok   ( srom_ok   ),
    //.slot4_ok   ( map_ok    ),
    .slot4_ok   (     ),

    // SDRAM controller interface
    .sdram_ack   ( ba_ack[0] ),
    .sdram_rd    ( ba_rd[0]  ),
    .sdram_wr    ( ba_wr     ),
    .sdram_addr  ( ba0_addr  ),
    .data_dst    ( ba_dst[0] ),
    .data_rdy    ( ba_rdy[0] ),
    .data_write  ( ba0_din   ),
    .sdram_wrmask( ba0_din_m ),
    .data_read   ( data_read )
);
/*
jtframe_rom_3slots #(
    .SLOT0_DW(32),
    .SLOT0_AW(19),

    .SLOT1_DW(32),
    .SLOT1_AW(19),

    .SLOT2_DW(32),
    .SLOT2_AW(19)
) u_bank2(
    .rst        ( rst       ),
    .clk        ( clk       ),

    .slot0_addr ( char_adj  ),
    .slot1_addr ( scr1_adj  ),
    .slot2_addr ( scr2_adj  ),

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
    .sdram_addr ( ba2_addr  ),
    .sdram_req  ( ba_rd[2]  ),
    .sdram_ack  ( ba_ack[2] ),
    .data_dst   ( ba_dst[2] ),
    .data_rdy   ( ba_rdy[2] ),
    .data_read  ( data_read )
);
*/
assign ba_rd[2]=0;
assign ba2_addr=0;

// OBJ
/*
jtframe_rom_1slot #(
    .SLOT0_DW(16),
    .SLOT0_AW(20)
) u_bank3(
    .rst        ( rst       ),
    .clk        ( clk       ),

    .slot0_addr ( obj_addr_g),
    .slot0_dout ( obj_data  ),
    .slot0_cs   ( obj_cs    ),
    .slot0_ok   ( obj_ok    ),

    // SDRAM controller interface
    .sdram_addr ( ba3_addr  ),
    .sdram_req  ( ba_rd[3]  ),
    .sdram_ack  ( ba_ack[3] ),
    .data_dst   ( ba_dst[3] ),
    .data_rdy   ( ba_rdy[3] ),
    .data_read  ( data_read )
);
*/
assign ba_rd[3]=0;
assign ba3_addr=0;
/*
// Sound
jtframe_rom_2slots #(
    .SLOT0_DW(   8),
    .SLOT0_AW(SNDW),

    .SLOT1_DW(   8),
    .SLOT1_AW(  17),

    .SLOT1_OFFSET( PCM_OFFSET )
) u_bank1(
    .rst        ( rst       ),
    .clk        ( clk       ),

    .slot0_addr ( snd_addr  ),
    .slot0_dout ( snd_data  ),
    .slot0_cs   ( snd_cs    ),
    .slot0_ok   ( snd_ok    ),

    .slot1_addr ( pcm_addr  ),
    .slot1_dout ( pcm_data  ),
    .slot1_cs   ( pcm_cs    ),
    .slot1_ok   ( pcm_ok    ),

    // SDRAM controller interface
    .sdram_addr ( ba1_addr  ),
    .sdram_req  ( ba_rd[1]  ),
    .sdram_ack  ( ba_ack[1] ),
    .data_dst   ( ba_dst[1] ),
    .data_rdy   ( ba_rdy[1] ),
    .data_read  ( data_read )
);
*/
assign ba_rd[1]=0;
assign ba1_addr=0;

endmodule