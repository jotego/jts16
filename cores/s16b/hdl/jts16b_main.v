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
    Date: 5-7-2021 */

module jts16b_main(
    input              rst,
    input              clk,
    input              clk_rom,
    output             cpu_cen,
    output             cpu_cenb,
    input  [7:0]       game_id,
    // Video
    input  [8:0]       vdump,
    input              hstart,
    // Video circuitry
    output reg         char_cs,
    output reg         pal_cs,
    output reg         objram_cs,
    input       [15:0] char_dout,
    input       [15:0] pal_dout,
    input       [15:0] obj_dout,
    output reg         flip,
    output             video_en,
    output             colscr_en,
    output             rowscr_en,
    // RAM access
    output             ram_cs,
    output             vram_cs,
    input       [15:0] ram_data,   // coming from VRAM or RAM
    input              ram_ok,
    // CPU bus
    output      [15:0] cpu_dout,
    output             UDSWn,
    output             LDSWn,
    output             RnW,
    output      [12:1] cpu_addr,
    // Sound control
    output      [ 7:0] snd_latch,
    output             snd_irqn,
    output             sound_en,
    input              snd_ack,
    // cabinet I/O
    input       [ 7:0] joystick1,
    input       [ 7:0] joystick2,
    input       [ 7:0] joystick3,
    input       [ 7:0] joystick4,
    input       [15:0] joyana1,
    input       [15:0] joyana2,
    input       [ 3:0] start_button,
    input       [ 1:0] coin_input,
    input              service,
    // ROM access
    output reg         rom_cs,
    output      [17:1] rom_addr,
    input       [15:0] rom_data,
    input              rom_ok,

    // Decoder configuration
    input             dec_en,
    input             dec_type,
    input      [12:0] prog_addr,
    input             key_we,
    input      [ 7:0] prog_data,

    // DIP switches
    input              dip_pause,
    input              dip_test,
    input    [7:0]     dipsw_a,
    input    [7:0]     dipsw_b,

    // NVRAM - debug
    input       [15:0] ioctl_addr,
    output      [ 7:0] ioctl_din
);

localparam [7:0] GAME_SDI=1, GAME_PASSSHT=2;

//  Region 0 - Program ROM
//  Region 3 - 68000 work RAM
//  Region 4 - Text/tile RAM
//  Region 5 - Object RAM
//  Region 6 - Color RAM
//  Region 7 - I/O area
localparam [2:0] REG_RAM  = 3,
                 REG_VRAM = 4,
                 REG_ORAM = 5,
                 REG_PAL  = 6,
                 REG_IO   = 7;

wire [23:1] A;
wire        BERRn;
wire [ 2:0] FC;

`ifdef SIMULATION
wire [23:0] A_full = {A,1'b0};
`endif

wire        BRn, BGACKn, BGn;
wire        ASn, UDSn, LDSn, BUSn;
wire        ok_dly;
wire [15:0] rom_dec;

reg         io_cs, wdog_cs;

assign UDSWn = RnW | UDSn;
assign LDSWn = RnW | LDSn;
assign BUSn  = ASn | (LDSn & UDSn);

// No peripheral bus access for now
assign BRn   = 1;
assign BGACKn= 1;
assign cpu_addr = A[12:1];
assign rom_addr = A[18:1]; //  18:0 = 512kB
assign BERRn = !(!ASn && BGACKn && !rom_cs && !char_cs && !objram_cs  && !pal_cs
                              && !io_cs  && !wdog_cs && vram_cs && ram_cs);

wire [7:0] active;

jts16b_mem_map u_memmap(
    .rst        ( rst            ),
    .clk        ( clk            ),
    .addr       ( A              ),
    .cpu_dout   ( cpu_dout       ),
    .dswn       ( {UDSWn, LDSWn} ),
    .active     ( active         )
);

// System 16B memory map
always @(posedge clk, posedge rst) begin
    if( rst ) begin
            rom_cs    <= 0;
            char_cs   <= 0; // 4 kB
            objram_cs <= 0; // 2 kB
            pal_cs    <= 0; // 4 kB
            io_cs     <= 0;
            wdog_cs   <= 0;

            vram_cs   <= 0; // 32kB
            ram_cs    <= 0;
    end else begin
        if( !ASn && BGACKn ) begin
            rom_cs    <= |active[2:0];
            char_cs   <= active[REG_VRAM] && addr[16];

            objram_cs <= active[REG_ORAM];
            pal_cs    <= active[REG_PAL];
            io_cs     <= active[REG_IO];

            // jtframe_ramrq requires cs to toggle to
            // process a new request. BUSn will toggle for
            // read-modify-writes
            vram_cs <= !BUSn && active[REG_VRAM] && !addr[16];
            ram_cs  <= !BUSn && active[REG_RAM];
        end else begin
            rom_cs    <= 0;
            char_cs   <= 0;
            objram_cs <= 0;
            pal_cs    <= 0;
            io_cs     <= 0;
            wdog_cs   <= 0;
            vram_cs <= 0;
            ram_cs  <= 0;
        end
    end
end

// cabinet input
reg [ 7:0] cab_dout, sort1, sort2;
reg        last_iocs;

wire       op_n; // low for CPU OP requests

assign op_n        = FC[1:0]!=2'b10;
assign snd_irqn    = ppic_dout[7];
assign colscr_en   = ~ppic_dout[2];
assign rowscr_en   = ~ppic_dout[1];

function [7:0] sort_joy( input [7:0] joy_in );
    sort_joy = { joy_in[1:0], joy_in[3:2], joy_in[7], joy_in[5:4], joy_in[6] };
endfunction

assign sound_en = 1;
assign video_en = 1;

always @(*) begin
    sort1 = sort_joy( joystick1 );
    sort2 = sort_joy( joystick2 );
end

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        cab_dout  <= 8'hff;
        flip      <= 0;
    end else  begin
        last_iocs <= io_cs;
        cab_dout <= 8'hff;
        if(io_cs) case( A[13:12] )
            0: if( !LDSWn ) begin
                flip    <= cpu_dout[6];
                //video_en <= cpu_dout[5];
            end
            1:
                case( A[2:1] )
                    0: begin
                        if( !last_iocs ) port_cnt <= 0;
                        cab_dout <= { 2'b11, start_button[1:0], service, dip_test, coin_input };
                    end
                    1: begin
                        cab_dout <= sort1;
                    end
                    3: begin
                        cab_dout <= sort2;
                    end
                endcase
            2:
                cab_dout <= { A[1] ? dipsw_b : dipsw_a };
        endcase
    end
end

// Data bus input
reg  [15:0] cpu_din;

always @(posedge clk) begin
    if(rst) begin
        cpu_din <= 16'hffff;
    end else begin
        cpu_din <= (ram_cs | vram_cs ) ? ram_data  : (
                    rom_cs             ? rom_dec   : (
                    char_cs            ? char_dout : (
                    pal_cs             ? pal_dout  : (
                    objram_cs          ? obj_dout  : (
                    io_cs              ? { 8'hff, cab_dout } :
                                       16'hFFFF )))));
    end
end

// interrupt generation
reg        irqn; // VBLANK
wire       inta_n = ~&{ FC[2], FC[1], FC[0], ~ASn }; // interrupt ack.
reg        last_hstart;

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        irqn <= 1;
    end else begin
        last_hstart <= hstart;

        if( !inta_n ) begin
            irqn <= 1;
        end else if( hstart && !last_hstart && vdump==223 ) begin
            irqn <= 0;
        end
    end
end

wire DTACKn;
wire bus_cs    = pal_cs | char_cs | vram_cs | ram_cs | rom_cs | objram_cs | io_cs;
wire bus_busy  = |{ rom_cs & ~ok_dly, (ram_cs | vram_cs) & ~ram_ok };
wire bus_legit = 0;

jtframe_68kdtack #(.W(8)) u_dtack(
    .rst        ( rst       ),
    .clk        ( clk       ),
    .cpu_cen    ( cpu_cen   ),
    .cpu_cenb   ( cpu_cenb  ),
    .bus_cs     ( bus_cs    ),
    .bus_busy   ( bus_busy  ),
    .bus_legit  ( bus_legit ),
    .BUSn       ( BUSn      ),   // BUSn = ASn | (LDSn & UDSn)
    .num        ( 8'd29     ),  // numerator
    .den        ( 8'd146    ),  // denominator
    .DTACKn     ( DTACKn    )
);

jts16_fd1094 u_dec(
    .rst        ( rst       ),
    .clk        ( clk       ),

    // Configuration
    .prog_addr  ( prog_addr ),
    .fd1094_we  ( key_we    ),
    .prog_data  ( prog_data ),

    // Operation
    .dec_en     ( dec_en    ),
    .FC         ( FC        ),
    .ASn        ( ASn       ),

    .addr       ( A         ),
    .enc        ( rom_data  ),
    .dec        ( rom_dec   ),

    .dtackn     ( DTACKn    ),
    .rom_ok     ( rom_ok    ),
    .ok_dly     ( ok_dly    )
);

jtframe_m68k u_cpu(
    .clk        ( clk         ),
    .rst        ( rst         ),
    .cpu_cen    ( cpu_cen     ),
    .cpu_cenb   ( cpu_cenb    ),

    // Buses
    .eab        ( A           ),
    .iEdb       ( cpu_din     ),
    .oEdb       ( cpu_dout    ),


    .eRWn       ( RnW         ),
    .LDSn       ( LDSn        ),
    .UDSn       ( UDSn        ),
    .ASn        ( ASn         ),
    .VPAn       ( inta_n      ),
    .FC         ( FC          ),

    .BERRn      ( BERRn       ),
    // Bus arbitrion
    .HALTn      ( dip_pause   ),
    .BRn        ( BRn         ),
    .BGACKn     ( BGACKn      ),
    .BGn        ( BGn         ),

    .DTACKn     ( DTACKn      ),
    .IPLn       ( { irqn, 2'b11 } ) // VBLANK
);

// Debug
`ifdef MISTER
`ifndef JTFRAME_RELEASE
`ifndef BETA
jts16_shadow u_shadow(
    .clk        ( clk       ),
    .clk_rom    ( clk_rom   ),

    // Capture SDRAM bank 0 inputs
    .addr       ( A[14:1]   ),
    .char_cs    ( char_cs   ),    //  4k
    .vram_cs    ( vram_cs   ),    // 32k
    .pal_cs     ( pal_cs    ),     //  4k
    .objram_cs  ( objram_cs ),  //  2k
    .din        ( cpu_dout  ),
    .dswn       ( {UDSWn, LDSWn} ),  // write mask -active low

    // Let data be dumped via NVRAM interface
    .ioctl_addr ( ioctl_addr),
    .ioctl_din  ( ioctl_din )
);
`endif
`endif
`endif

endmodule