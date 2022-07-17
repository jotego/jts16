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

module jtoutrun_main(
    input              rst,
    input              clk,
    input              clk_rom,
    input              pxl_cen,
    output             cpu_cen,
    output             cpu_cenb,
    input       [ 1:0] game_id,
    output             snd_rstb,

    // Video
    input              vint,
    input              line_intn,
    input              LHBL,

    // Video circuitry
    output reg         char_cs,
    output reg         pal_cs,
    output reg         objram_cs,
    input       [15:0] char_dout,
    input       [15:0] pal_dout,
    input       [15:0] obj_dout,
    output             flip,
    output             video_en,
    output      [ 1:0] obj_cfg, // SG bus on page 6/7
    output reg         obj_toggle,

    // RAM access
    output reg         ram_cs,
    output reg         vram_cs,
    input       [15:0] ram_data,   // coming from VRAM or RAM
    input              ram_ok,
    // CPU bus
    output      [15:0] cpu_dout,
    output             RnW,
    output reg         sub_cs,
    input              sub_ok,
    input       [15:0] sub_din,
    output      [ 1:0] dsn,

    // cabinet I/O
    input       [ 7:0] joystick1,
    input       [ 7:0] joystick2,
    input       [15:0] joyana1,
    input       [15:0] joyana1b,
    input       [ 1:0] start_button,
    input       [ 1:0] coin_input,
    input              service,
    output      [19:1] addr,
    // ROM access
    output reg         rom_cs,
    input       [15:0] rom_data,
    input              rom_ok,

    // Decoder configuration
    input              dec_en,
    input              fd1089_en,
    input              fd1094_en,
    input              dec_type,
    input       [12:0] prog_addr,
    input              key_we,
    input              fd1089_we,
    input       [ 7:0] prog_data,
    output      [12:0] key_addr,
    input       [ 7:0] key_data,

    // DIP switches
    input              dip_test,
    input       [ 7:0] dipsw_a,
    input       [ 7:0] dipsw_b,

    // Sound - Mapper interface
    input              sndmap_rd,
    input              sndmap_wr,
    input       [ 7:0] sndmap_din,
    output      [ 7:0] sndmap_dout,
    output             sndmap_pbf, // pbf signal == buffer full ?

    // status dump
    input       [ 7:0] debug_bus,
    input       [ 7:0] st_addr,
    output      [ 7:0] st_dout
);

//  Mapper regions, CSS signals in schematics
localparam [2:0] REG_MEM  = 0,
                 REG_SCR  = 1,
                 REG_PAL  = 2,
                 REG_OBJ  = 3,
                 REG_IO   = 4,
                 REG_SUB  = 5;

wire [23:1] A,cpu_A;
wire        BERRn;
wire [ 2:0] FC;

`ifdef SIMULATION
wire [23:0] A_full = {A,1'b0};
`endif

wire        BRn, BGACKn, BGn;
wire        ASn, UDSn, LDSn, BUSn, LDSWn;
wire [15:0] rom_dec, cpu_dout_raw;

reg         io_cs, ppi_cs;
wire        cpu_RnW, dec_ok;

reg  [ 7:0] cab_dout;
wire [ 7:0] active, sys_inputs,
            ppi_dout, ppia_dout, ppib_dout, ppic_dout;
wire [ 2:0] cpu_ipln, mix_ipln;
wire        DTACKn, cpu_vpan;

wire bus_cs    = pal_cs | char_cs | vram_cs | ram_cs | rom_cs | objram_cs | io_cs | sub_cs;
wire bus_busy  = |{ rom_cs & ~dec_ok, (ram_cs | vram_cs) & ~ram_ok, sub_cs & ~sub_ok };
wire cpu_rst, cpu_haltn, cpu_asn;
wire [ 1:0] cpu_dsn;
reg  [15:0] cpu_din;
wire [15:0] mapper_dout;
wire        none_cs;
wire [ 2:0] adc_ch;

assign BUSn  = LDSn & UDSn;
assign dsn   = { UDSn, LDSn };
// assign UDSWn = RnW | UDSn;
assign LDSWn = RnW | LDSn;
// assign BERRn = !(!ASn && BGACKn && !rom_cs && !char_cs && !objram_cs  && !pal_cs
//                               && !io_cs  && !wdog_cs && vram_cs && ram_cs);
assign obj_cfg  = ppic_dout[7:6]; // obj_cfg[1] -> object engine, obj_cfg[0] -> colmix
assign video_en = ppic_dout[5];
assign adc_ch   = ppic_dout[4:2];
assign snd_rstb = ppic_dout[0];
assign flip     = 0;
assign addr     = A[19:1];
assign mix_ipln = { cpu_ipln[2], line_intn, 1'b1 };

jts16b_mapper u_mapper(
    .rst        ( rst            ),
    .clk        ( clk            ),
    .pxl_cen    ( pxl_cen        ),
    .cpu_cen    ( cpu_cen        ),
    .cpu_cenb   ( cpu_cenb       ),
    .vint       ( vint           ),

    .addr       ( cpu_A          ),
    .cpu_dout   ( cpu_dout_raw   ),
    .cpu_dsn    ( cpu_dsn        ),
    .bus_dsn    ( {UDSn,  LDSn}  ),
    .bus_cs     ( bus_cs         ),
    .bus_busy   ( bus_busy       ),
    // effective bus signals
    .addr_out   ( A              ),

    .none       ( none_cs        ),
    .mapper_dout( mapper_dout    ),

    // Bus sharing
    .bus_dout   ( cpu_din        ),
    .bus_din    ( cpu_dout       ),
    .cpu_rnw    ( cpu_RnW        ),
    .bus_rnw    ( RnW            ),
    .bus_asn    ( ASn            ),

    // M68000 control
    .cpu_berrn  ( BERRn          ),
    .cpu_brn    ( BRn            ),
    .cpu_bgn    ( BGn            ),
    .cpu_bgackn ( BGACKn         ),
    .cpu_dtackn ( DTACKn         ),
    .cpu_asn    ( cpu_asn        ),
    .cpu_fc     ( FC             ),
    .cpu_ipln   ( cpu_ipln       ),
    .cpu_vpan   ( cpu_vpan       ),
    .cpu_haltn  ( cpu_haltn      ),
    .cpu_rst    ( cpu_rst        ),

    // Sound CPU
    .sndmap_rd  ( sndmap_rd      ),
    .sndmap_wr  ( sndmap_wr      ),
    .sndmap_din ( sndmap_din     ),
    .sndmap_dout( sndmap_dout    ),
    .sndmap_pbf ( sndmap_pbf     ),

    // MCU side
    .mcu_en     ( 1'b0           ),
    .mcu_dout   ( 8'd0           ),
    .mcu_din    (                ),
    .mcu_intn   (                ),
    .mcu_addr   ( 16'd0          ),
    .mcu_wr     ( 1'b0           ),
    .mcu_acc    ( 1'b0           ),

    .active     ( active         ),
    .debug_bus  ( debug_bus      ),
    //.debug_bus  ( 8'd0           ),
    .st_addr    ( st_addr        ),
    .st_dout    ( st_dout        )
);

// System 16B memory map
always @(posedge clk, posedge rst) begin
    if( rst ) begin
            rom_cs    <= 0;
            ram_cs    <= 0;
            char_cs   <= 0;
            vram_cs   <= 0; // 32kB
            objram_cs <= 0; // 2 kB
            pal_cs    <= 0; // 4 kB
            io_cs     <= 0;
            sub_cs    <= 0;
    end else begin
        if( !BUSn || (!ASn && RnW) ) begin
            rom_cs    <= active[REG_MEM] && A[18:17]!=2'b11;
            ram_cs    <= active[REG_MEM] && A[18:17]==2'b11 && !BUSn; // $60000
            sub_cs    <= active[REG_SUB];

            char_cs   <= active[REG_SCR] &&  A[16];
            vram_cs   <= active[REG_SCR] && !A[16] && !BUSn;
            objram_cs <= active[REG_OBJ];
            pal_cs    <= active[REG_PAL];
            io_cs     <= active[REG_IO];
        end else begin
            rom_cs    <= 0;
            ram_cs    <= 0;
            sub_cs    <= 0;
            char_cs   <= 0;
            vram_cs   <= 0;
            objram_cs <= 0;
            pal_cs    <= 0;
            io_cs     <= 0;
        end
    end
end

always @(*) begin
    ppi_cs     = 0;
    cab_dout   = 8'hff;
    obj_toggle = 0;
    if( io_cs ) begin
        case( A[6:4] )
            0: begin
                ppi_cs   = 1;
                cab_dout = ppi_dout;
            end
            1: case( A[2:1] )
                0: cab_dout = { coin_input, ~joystick1[4], joystick1[4], start_button[0], service, dip_test, 1'b1 };
                1: cab_dout = 8'hff;
                2: cab_dout = dipsw_a;
                3: cab_dout = dipsw_b;
                default:;
            endcase
            3: case( adc_ch ) // ADC reads
                0: cab_dout = !joystick1[0] ? 8'hd0 :
                              !joystick1[1] ? 8'h20 :
                               joyana1[7:0]^8'h80; // steering wheel
                1: cab_dout = !joystick1[3] ? 8'hf0 :
                               joyana1b[15] ? ~{joyana1b[14:8], joyana1b[14]} : 8'd0; // gas pedal
                2: cab_dout = !joystick1[2] ? 8'hf0 :
                               joyana1b[15] ? 8'd0 : {joyana1b[14:8], joyana1b[14]};  // break pedal
                default:;
            endcase
            // 6: watchdog
            7: obj_toggle = 1;
            default:;
        endcase // A[6:4]
    end
end

jt8255 u_8255(
    .rst       ( rst        ),
    .clk       ( clk        ),

    // CPU interface
    .addr      ( A[2:1]     ),
    .din       ( cpu_dout[7:0] ),
    .dout      ( ppi_dout   ),
    .rdn       ( ~RnW       ),
    .wrn       ( LDSWn      ),
    .csn       ( ~ppi_cs    ),

    // External pins to peripherals
    .porta_din ( 8'hFF      ),  // Port A: read from motor
    .portb_din ( 8'hFF      ),  // Port B: write to motor
    .portc_din ( 8'hFF      ),

    .porta_dout( ppia_dout  ),
    .portb_dout( ppib_dout  ),
    .portc_dout( ppic_dout  )
);

// Data bus input
always @(posedge clk) begin
    if(rst) begin
        cpu_din <= 0;
    end else begin
        cpu_din <= (ram_cs | vram_cs ) ? ram_data  :
                    rom_cs             ? rom_dec   :
                    char_cs            ? char_dout :
                    pal_cs             ? pal_dout  :
                    objram_cs          ? obj_dout  :
                    sub_cs             ? sub_din   :
                    io_cs              ? { 8'hff, cab_dout } :
                    none_cs            ? mapper_dout :
                                         16'hffff;
    end
end

// Shared by FD1094 and FD1089
wire [12:0] key_1094, key_1089;
wire [15:0] dec_1094, dec_1089;
wire        ok_1094, ok_1089;

assign key_addr= fd1094_en ? key_1094 : key_1089;
assign rom_dec = fd1094_en ? dec_1094 : dec_1089;
assign dec_ok  = fd1094_en ? ok_1094  : ok_1089;

`ifndef NODEC
jts16_fd1094 u_dec1094(
    .rst        ( rst       ),
    .clk        ( clk       ),

    // Configuration
    .prog_addr  ( prog_addr ),
    .fd1094_we  ( key_we    ),
    .prog_data  ( prog_data ),

    // Key access
    .key_addr   ( key_1094  ),
    .key_data   ( key_data  ),

    // Operation
    .dec_en     ( dec_en    ),
    .FC         ( FC        ),
    .ASn        ( ASn       ),

    .addr       ( A         ),
    .enc        ( rom_data  ),
    .dec        ( dec_1094  ),

    .dtackn     ( DTACKn    ),
    .rom_ok     ( rom_ok    ),
    .ok_dly     ( ok_1094   )
);

wire op_n = FC[1:0]!=2'b10; // low for CPU OP requests

jts16_fd1089 u_dec1089(
    .rst        ( rst       ),
    .clk        ( clk       ),

    // Configuration
    .prog_addr  ( prog_addr ),
    .fd1089_we  ( fd1089_we ),
    .prog_data  ( prog_data ),

    // Key access
    .key_addr   ( key_1089  ),
    .key_data   ( key_data  ),

    // Operation
    .dec_type   ( dec_type  ), // 0=a, 1=b
    .dec_en     ( dec_en    ),
    .rom_ok     ( rom_ok    ),
    .ok_dly     ( ok_1089   ),

    .op_n       ( op_n      ), // OP (0) or data (1)
    .addr       ( A         ),
    .enc        ( rom_data  ),
    .dec        ( dec_1089  )
);
`else
    assign dec_1089 = rom_data;
    assign dec_1094 = rom_data;
    assign ok_1089  = rom_ok;
    assign ok_1094  = rom_ok;
`endif

jtframe_m68k u_cpu(
    .clk        ( clk         ),
    .rst        ( cpu_rst     ),
    .cpu_cen    ( cpu_cen     ),
    .cpu_cenb   ( cpu_cenb    ),

    // Buses
    .eab        ( cpu_A       ),
    .iEdb       ( cpu_din     ),
    .oEdb       ( cpu_dout_raw),


    .eRWn       ( cpu_RnW     ),
    .LDSn       ( cpu_dsn[0]  ),
    .UDSn       ( cpu_dsn[1]  ),
    .ASn        ( cpu_asn     ),
    .VPAn       ( cpu_vpan    ),
    .FC         ( FC          ),

    .BERRn      ( BERRn       ),
    // Bus arbitrion
    .HALTn      ( cpu_haltn   ),
    .BRn        ( BRn         ),
    .BGACKn     ( BGACKn      ),
    .BGn        ( BGn         ),

    .DTACKn     ( DTACKn      ),
    .IPLn       ( mix_ipln    ) // VBLANK
);
/*
`ifdef SIMULATION
always @(negedge  DTACKn ) if(sub_cs) begin
    $display("Sub access: %X <> %X", cpu_A, cpu_din );
end
`endif
*/
endmodule