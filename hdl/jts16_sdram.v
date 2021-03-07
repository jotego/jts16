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

module jts16_sdram #( parameter
    M68W    = 17,
    Z80_AW  = 15,
    PCM_AW  = 15,
    TILEW   = 17,
    OBJW    = 18
) (
    input           rst,
    input           clk,
    input           LVBL,

    input           downloading,
    output          dwnld_busy,
    output          cfg_we,

    // ROM LOAD
    input   [24:0]  ioctl_addr,
    input   [ 7:0]  ioctl_data,
    output  [ 7:0]  ioctl_data2sd,
    input           ioctl_wr,
    input           ioctl_ram,
    output  [21:0]  prog_addr,
    output  [15:0]  prog_data,
    output  [ 1:0]  prog_mask,
    output  [ 1:0]  prog_ba,
    output          prog_we,
    output          prog_rd,
    input           prog_rdy,

    // Kabuki decoder
//    output          kabuki_we,

    // Main CPU
    input           main_rom_cs,
    output          main_rom_ok,
    input    [20:0] main_rom_addr,
    output   [15:0] main_rom_data,

    // VRAM
    input           vram_clr,
    input           vram_cs,
    input           main_ram_cs,
    input           main_vram_cs,
    input           vram_rfsh_en,

    input    [ 1:0] dsn,
    input    [15:0] main_dout,
    input           main_rnw,

    output          main_ram_ok,
    output          vram_ok,

    input    [16:0] main_ram_addr,
    input    [14:0] vram_addr,

    output   [15:0] main_ram_data,
    output   [15:0] vram_data,

    // Sound CPU and PCM
    input           snd_cs,
    input           pcm_cs,

    output          snd_ok,
    output          pcm_ok,

    input [Z80_AW-1:0] snd_addr,
    input [PCM_AW-1:0] pcm_addr,

    output     [7:0] snd_data,
    output     [7:0] pcm_data,

    // Graphics
    input           tiles_cs,
    input           obj_cs,

    output          tiles_ok,
    output          obj_ok,

    input [TILEW-1:0] tiles_addr,
    input [ OBJW-1:0] obj_addr,

    input           tiles_half,
    input           obj_half,

    output   [15:0] tiles_data,
    output   [15:0] obj_data,

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
    output    reg   refresh_en
);

localparam [21:0] ZERO_OFFSET  = 22'h0,
                  RAM_OFFSET   = 22'h1000;
                  PCM_OFFSET   = ZERO_OFFSET,
                  SND_OFFSET   = 22'h10_0000,
                  CPU_OFFSET   = 22'h10_0000;

wire [21:0] main_offset;
wire        ram_vram_cs;

assign ram_vram_cs = main_ram_cs | main_vram_cs;
assign main_offset = main_rom_cs ? CPU_OFFSET : (main_ram_cs ? RAM_OFFSET : ZERO_OFFSET);
assign prog_rd     = 0;

always @(posedge clk) begin
    refresh_en <= ~LVBL & vram_rfsh_en;
end

jts16_prom_we #(
    .CPU_OFFSET ( CPU_OFFSET    ),
    .PCM_OFFSET ( PCM_OFFSET    ),
    .SND_OFFSET ( SND_OFFSET    )
) u_prom_we(
    .clk            ( clk           ),
    .downloading    ( downloading   ),
    .ioctl_addr     ( ioctl_addr    ),
    .ioctl_data     ( ioctl_data    ),
    .ioctl_data2sd  ( ioctl_data2sd ),
    .ioctl_wr       ( ioctl_wr      ),
    .ioctl_ram      ( ioctl_ram     ),
    .prog_addr      ( prog_addr     ),
    .prog_data      ( prog_data     ),
    .prog_mask      ( prog_mask     ),
    .prog_ba        ( prog_ba       ),
    .prog_we        ( prog_we       ),
    .prog_rdy       ( prog_rdy      ),
    .cfg_we         ( cfg_we        ),
    .dwnld_busy     ( dwnld_busy    ),
    // Kabuki keys
    // .kabuki_we      ( kabuki_we     )
);

jtframe_ram_3slots #(
    .SLOT0_AW    ( 14            ), // Main CPU VRAM (tiles, 32kB)
    .SLOT0_DW    ( 16            ),

    .SLOT1_AW    ( 14            ), // VRAM - read only access
    .SLOT1_DW    ( 16            ),

    .SLOT2_AW    ( M68W          ), // Main CPU ROM
    .SLOT2_DW    ( 16            )
) u_bank0 (
    .rst         ( rst           ),
    .clk         ( clk           ),

    .offset0     ( main_offset   ),
    .offset1     ( ZERO_OFFSET   ),
    .offset2     ( CPU_OFFSET    ),

    .slot0_cs    ( ram_vram_cs   ),
    .slot0_wen   ( !main_rnw     ),

    .slot1_cs    ( vram_cs       ),
    .slot1_clr   ( vram_clr      ),

    .slot2_cs    ( main_rom_cs   ),
    .slot2_clr   ( 1'b0          ),

    .slot0_ok    ( main_ram_ok   ),
    .slot1_ok    ( vram_ok       ),
    .slot2_ok    ( main_rom_ok   ),

    .slot0_din   ( main_dout     ),
    .slot0_wrmask( dsn           ),

    .slot0_addr  ( main_addr_x   ),
    .slot1_addr  ( vram_addr     ),
    .slot2_addr  ( main_rom_addr ),

    .slot0_dout  ( main_ram_data ),
    .slot1_dout  ( vram_data     ),
    .slot2_dout  ( main_rom_data ),

    // SDRAM interface
    .sdram_addr  ( ba0_addr      ),
    .sdram_rd    ( ba0_rd        ),
    .sdram_wr    ( ba0_wr        ),
    .sdram_ack   ( ba0_ack       ),
    .data_rdy    ( ba0_rdy       ),
    .data_write  ( ba0_din       ),
    .sdram_wrmask( ba0_din_m     ),
    .data_read   ( data_read     )
);

jtframe_rom_2slotS #(
    .SLOT0_AW    ( PCM_AW        ), // PCM
    .SLOT0_DW    (  8            ),
    .SLOT0_OFFSET( ZERO_OFFSET   ),
    .SLOT0_REPACK( 1             ),

    .SLOT1_AW    ( Z80_AW        ), // z80
    .SLOT1_DW    (  8            ),
    .SLOT1_OFFSET( SND_OFFSET    ),
    .SLOT1_REPACK( 1             )
) u_bank1 (
    .rst         ( rst           ),
    .clk         ( clk           ),

    .slot0_cs    ( pcm_cs        ),
    .slot0_ok    ( pcm_ok        ),
    .slot0_addr  ( pcm_addr      ),
    .slot0_dout  ( pcm_data      ),

    .slot0_cs    ( snd_cs        ),
    .slot0_ok    ( snd_ok        ),
    .slot0_addr  ( snd_addr      ),
    .slot0_dout  ( snd_data      ),

    .sdram_addr  ( ba1_addr      ),
    .sdram_req   ( ba1_rd        ),
    .sdram_ack   ( ba1_ack       ),
    .data_rdy    ( ba1_rdy       ),
    .data_read   ( data_read     )
);


jtframe_rom_1slot #(
    // Slot 0: Obj
    .SLOT0_AW    ( 23            ),
    .SLOT0_DW    ( 32            ),
    .LATCH0      ( 1             )
    //.SLOT0_REPACK( 1             ),
) u_bank2 (
    .rst         ( rst           ),
    .clk         ( clk           ), // do not use clk

    .slot0_cs    ( obj_cs        ),
    .slot0_ok    ( obj_cs        ),
    .slot0_addr  ( obj_addr      ),
    .slot0_dout  ( obj_dout      ),

    .sdram_addr  ( ba2_addr      ),
    .sdram_req   ( ba2_rd        ),
    .sdram_ack   ( ba2_ack       ),
    .data_rdy    ( ba2_rdy       ),
    .data_read   ( data_read     )
);

// Bank 3 unused
assign ba3_rd   = 0;
assign ba3_addr = 22'd0;

endmodule