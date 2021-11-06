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
    Date: 17-3-2021 */

module jts16_main(
    input              rst,
    input              clk,
    input              clk_rom,
    output             cpu_cen,
    output             cpu_cenb,
    input              rst24,       // MCU
    input              clk24,
    input              mcu_cen,
    input  [7:0]       game_id,
    // Video
    input              vint,
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
    input       [15:0] joyana1b,
    input       [15:0] joyana2,
    input       [15:0] joyana2b,
    input       [15:0] joyana3,
    input       [15:0] joyana4,
    input       [ 3:0] start_button,
    input       [ 1:0] coin_input,
    input              service,
    // ROM access
    output reg         rom_cs,
    output      [18:1] rom_addr,
    input       [15:0] rom_data,
    input              rom_ok,

    // Decoder configuration
    input             dec_en,
    input             dec_type,
    input      [12:0] prog_addr,
    input             key_we,
    input             fd1089_we,
    input      [ 7:0] prog_data,

    // DIP switches
    input              dip_pause,
    input              dip_test,
    input    [7:0]     dipsw_a,
    input    [7:0]     dipsw_b,

    // MCU enable and ROM programming
    input              mcu_en,
    input              mcu_prog_we,

    // NVRAM - debug
    input       [15:0] ioctl_addr,
    output      [ 7:0] ioctl_din,

    // status dump - debug
    input       [ 7:0] debug_bus,
    input       [ 7:0] st_addr,
    output reg  [ 7:0] st_dout
);

localparam [7:0] GAME_HWCHAMP =`GAME_HWCHAMP ,
                 GAME_PASSSHT =`GAME_PASSSHT ,
                 GAME_SDIBL   =`GAME_SDIBL   ,
                 GAME_PASSSHT2=`GAME_PASSSHT2,
                 GAME_DUNKSHOT=`GAME_DUNKSHOT,
                 GAME_EXCTLEAG=`GAME_EXCTLEAG,
                 GAME_BULLET  =`GAME_BULLET  ,
                 GAME_PASSSHT3=`GAME_PASSSHT3,
                 GAME_SDI     =`GAME_SDI     ;
wire [23:1] A, cpu_A;
wire        BERRn;
wire [ 2:0] FC, IPLn;

`ifdef SIMULATION
wire [23:0] A_full = {A,1'b0};
`endif

wire        BRn, BGACKn, BGn;
wire        ASn, UDSn, LDSn, BUSn;
wire        ok_dly;
wire [15:0] rom_dec, cpu_dout_raw;
reg  [15:0] cpu_din;
wire        cpu_LDSn, cpu_UDSn, cpu_RnW, DTACKn;

reg         io_cs, wdog_cs,
            pre_ram_cs, pre_vram_cs;

reg         cpu_rst;
reg         irqn; // VBLANK

wire [15:0] fave, fworst;

// MCU
wire        mcu_bus;    // the MCU controls the bus
wire [ 7:0] mcu_ctrl, mcu_dout;
wire        mcu_wr, mcu_acc;
wire [15:0] mcu_addr;
reg [23:16] mcu_top;

assign A   = mcu_bus ? { mcu_top, 2'b0, mcu_addr[13:1] } : cpu_A;
assign RnW = mcu_bus ? mcu_wr : cpu_RnW;
assign UDSn= mcu_bus ? mcu_addr[0] : cpu_UDSn;
assign LDSn= mcu_bus ?~mcu_addr[0] : cpu_LDSn;
assign cpu_dout = mcu_bus ? mcu_dout : cpu_dout_raw;

assign UDSWn = RnW | UDSn;
assign LDSWn = RnW | LDSn;
assign BUSn  = (BGACKn & ASn) | (LDSn & UDSn);
assign IPLn  = { irqn, 2'b11 } & ({3{mcu_en}} | mcu_ctrl[2:0]);

// No peripheral bus access for now
assign cpu_addr = A[12:1];
assign rom_addr = {1'b0, A[17:1]}; // only 256kB on System 16A
assign BERRn = !(!ASn && BGACKn && !rom_cs && !char_cs && !objram_cs  && !pal_cs
                              && !io_cs  && !wdog_cs && pre_vram_cs && pre_ram_cs);

always @(negedge clk) begin
    cpu_rst <= rst | (~mcu_ctrl[6] & mcu_en);
end

// System 16A memory map
always @(posedge clk, posedge rst) begin
    if( rst ) begin
            rom_cs    <= 0;
            char_cs   <= 0; // 4 kB
            objram_cs <= 0; // 2 kB
            pal_cs    <= 0; // 4 kB
            io_cs     <= 0;
            wdog_cs   <= 0;

            pre_vram_cs <= 0; // 32kB
            pre_ram_cs  <= 0;
            //rom_addr  <= 0;
    end else begin
        if( BGACKn ? !ASn : mcu_acc ) begin
            rom_cs    <= A[23:22]==0 && !A[18];         // 00-03
            char_cs   <= A[22] && A[18:16]==1;    // 41
            //if( !A[23] ) rom_addr <= A[17:1];
            objram_cs <= A[23:22]==1 && A[18];    // 44
            pal_cs    <= A[23:22]==2 && A[18];    // 84
            io_cs     <= A[23:22]==3 && A[18:17]==2;    // c4
            wdog_cs   <= A[23:22]==3 && A[18:16]==6;    // c6

            // jtframe_ramrq requires cs to toggle to
            // process a new request. BUSn will toggle for
            // read-modify-writes
            pre_vram_cs <= !BUSn && A[22] && A[18:16]==0;        // 40
            pre_ram_cs  <= !BUSn && A[23:22]==3 && A[18:16]==7;  // c7
        end else begin
            rom_cs    <= 0;
            char_cs   <= 0;
            objram_cs <= 0;
            pal_cs    <= 0;
            io_cs     <= 0;
            wdog_cs   <= 0;
            pre_vram_cs <= 0;
            pre_ram_cs  <= 0;
        end
    end
end

assign ram_cs  = pre_ram_cs,
       vram_cs = pre_vram_cs;

// cabinet input
reg [ 7:0] cab_dout, sort1, sort2;
reg [ 7:0] ppi_b;
reg [ 1:0] port_cnt;    // used by Passing Shot
reg        ppi_cs, last_iocs;

wire [7:0] ppi_dout, ppic_din, ppic_dout, ppib_dout;
wire       op_n; // low for CPU OP requests

assign op_n        = FC[1:0]!=2'b10;
assign snd_irqn    = ppic_dout[7];
assign colscr_en   = ~ppic_dout[2];
assign rowscr_en   = ~ppic_dout[1];
assign ppic_din[6] = snd_ack;

function [7:0] sort_joy( input [7:0] joy_in );
    sort_joy = { joy_in[1:0], joy_in[3:2], joy_in[7], joy_in[5:4], joy_in[6] };
endfunction

function [7:0] pass_joy( input [7:0] joy_in );
    pass_joy = { joy_in[7:4], joy_in[1:0], joy_in[3:2] };
endfunction


function [7:0] sdi_joy( input [15:0] joyana );
    sdi_joy = ppib_dout[2] ? ~joyana[15:8] : ~joyana[7:0];
endfunction


assign { flip, sound_en, video_en } = { ppib_dout[7], ~ppib_dout[5], ppib_dout[4] };
//assign flip = ppib_dout[7];
//assign sound_en = 1;
//assign video_en = 1;

always @(*) begin
    sort1 = sort_joy( joystick1 );
    sort2 = sort_joy( joystick2 );
end

reg  game_sdi, game_passsht;
wire [11:0] trackball0, trackball1, trackball2, trackball3;

always @(posedge clk) begin
    game_sdi      <= game_id==GAME_SDI || game_id==GAME_SDIBL;
    game_passsht  <= game_id==GAME_PASSSHT2 || game_id==GAME_PASSSHT3 || game_id==GAME_PASSSHT;
end

jts16_trackball u_trackball(
    .rst        ( rst           ),
    .clk        ( clk           ),
    .LHBL       ( LHBL          ),

    .right_en   ( game_sdi      ),

    .joystick1  ( joystick1     ),
    .joystick2  ( joystick2     ),
    .joystick3  ( joystick3     ),
    .joystick4  ( joystick4     ),
    .joyana1    ( joyana1       ),
    .joyana1b   ( joyana1b      ), // used by Heavy Champ
    .joyana2    ( joyana2       ),
    .joyana2b   ( joyana2b      ), // used by SDI
    .joyana3    ( joyana3       ),
    .joyana4    ( joyana4       ),

    .trackball0 ( trackball0    ),
    .trackball1 ( trackball1    ),
    .trackball2 ( trackball2    ),
    .trackball3 ( trackball3    ),
    .trackball4 (               ),
    .trackball5 (               ),
    .trackball6 (               ),
    .trackball7 (               )
);

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        ppi_b     <= 8'hff;
        cab_dout  <= 8'hff;
        ppi_cs    <= 0;
        port_cnt  <= 0;
    end else  begin
        ppi_cs   <= 0;
        last_iocs <= io_cs;
        cab_dout <= 8'hff;
        if(io_cs) case( A[13:12] )
            2'd0: begin // 8255
                ppi_cs   <= 1;
                cab_dout <= ppi_dout;
            end
            2'd1:
                case( A[2:1] )
                    0: begin
                        if( !last_iocs ) port_cnt <= 0;
                        cab_dout <= { 2'b11, start_button[1:0], service, dip_test, coin_input };
                        case( game_id )
                            GAME_SDI: begin
                                cab_dout[7] <= joystick2[4];
                                cab_dout[6] <= joystick1[4];
                            end
                            GAME_PASSSHT: begin
                                cab_dout[7:6] <= start_button[3:2];
                            end
                        endcase
                    end
                    1: begin
                        case( game_id )
                            GAME_SDI: cab_dout <= sdi_joy( {trackball1[10:3],trackball0[10:3]} );
                            GAME_PASSSHT: begin
                                if( !last_iocs ) port_cnt <= port_cnt + 2'd1;
                                case( port_cnt )
                                    1: cab_dout <= pass_joy( joystick1 );
                                    2: cab_dout <= pass_joy( joystick2 );
                                    3: cab_dout <= pass_joy( joystick3 );
                                    0: cab_dout <= pass_joy( joystick4 );
                                endcase
                            end
                            default: cab_dout <= sort1;
                        endcase
                    end
                    2: begin
                        if( game_id == GAME_SDI ) begin
                            cab_dout <= { sort2[7:4], sort1[7:4] };
                        end
                    end
                    3: begin
                        if( game_id == GAME_SDI ) begin
                            cab_dout <= sdi_joy( {trackball3[10:3],trackball2[10:3]} );
                        end else begin
                            cab_dout <= sort2;
                        end
                    end
                endcase
            2'd2:
                cab_dout <= { A[1] ? dipsw_b : dipsw_a };
        endcase
    end
end


`ifndef NOMCU
    reg [1:0] mcu_aux;
    wire      mcu_br;
    wire      mcu_rst;

    assign mcu_bus = ~BGACKn;
    assign mcu_br  = mcu_en & mcu_acc;
    assign mcu_rst = mcu_aux[1];

    always @(negedge clk24, posedge rst24) begin
        if( rst24 ) begin
            mcu_aux <= 3;
        end else begin
            mcu_aux <= mcu_en ? mcu_aux<<1 : 3;
        end
    end

    // This is done by IC69 (a 82S153 programmable logic chip)
    always @(*) begin
        case(mcu_ctrl[1:0])
            0: mcu_top = mcu_addr[15] ? 8'hc4 : 8'hc7;  // main RAM or IO
            1: mcu_top = 8'h41; // text RAM
            3: mcu_top = 8'h41;
            default: mcu_top = 0;
        endcase
    end

    jtframe_68kdma u_dma(
        .rst        ( rst       ),
        .clk        ( clk       ),
        .cen        ( cpu_cen   ),
        .cpu_BRn    ( BRn       ),
        .cpu_BGACKn ( BGACKn    ),
        .cpu_BGn    ( BGn       ),
        .cpu_ASn    ( ASn       ),
        .cpu_DTACKn ( DTACKn    ),
        .dev_br     ( mcu_br    )      // high to signal a bus request from a device
    );

    jtframe_8751mcu #(
        .DIVCEN     ( 1             ),
        .SYNC_XDATA ( 1             ),
        .SYNC_P1    ( 1             ),
        .SYNC_INT   ( 1             ),
        .ROMBIN     ( "mcu.bin"     )
    ) u_mcu(
        .rst        ( mcu_rst       ),
        .clk        ( clk24         ),
        .cen        ( mcu_cen       ),

        .int0n      ( ~vint         ),
        .int1n      ( 1'b1          ),

        .p0_i       ( cpu_din       ),
        .p1_i       ( 8'hff         ),
        .p2_i       ( 8'hff         ),
        .p3_i       ( 8'hff         ),

        .p0_o       (               ),
        .p1_o       ( mcu_ctrl      ),
        .p2_o       (               ),
        .p3_o       (               ),

        // external memory
        .x_din      ( cpu_din       ),
        .x_dout     ( mcu_dout      ),
        .x_addr     ( mcu_addr      ),
        .x_wr       ( mcu_wr        ),
        .x_acc      ( mcu_acc       ),

        // ROM programming
        .clk_rom    ( clk           ),
        .prog_addr  (prog_addr[11:0]),
        .prom_din   ( prog_data     ),
        .prom_we    ( mcu_prog_we   )
    );
`else
    assign BRn   = 1;
    assign BGACKn= 1;
    assign mcu_wr   = 0;
    assign mcu_acc  = 0;
    assign mcu_dout = 0;
    assign mcu_ctrl = 8'ff;
    assign mcu_addr = 0;
    assign mcu_bus  = 0;
    initial begin
        mcu_top = 0;
    end
`endif

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
    .porta_din ( 8'hFF      ),
    .portb_din ( 8'hFF      ),
    .portc_din ( ppic_din   ),

    .porta_dout( snd_latch  ),
    .portb_dout( ppib_dout  ),
    .portc_dout( ppic_dout  )
);

// Data bus input
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
wire       inta_n = ~&{ FC[2], FC[1], FC[0], ~ASn }; // interrupt ack.
reg        last_vint;

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        irqn <= 1;
    end else begin
        last_vint <= vint;

        if( !inta_n ) begin
            irqn <= 1;
        end else if( vint && !last_vint ) begin
            irqn <= 0;
        end
    end
end

wire bus_cs    = pal_cs | char_cs | pre_vram_cs | pre_ram_cs | rom_cs | objram_cs | io_cs;
wire bus_busy  = |{ rom_cs & ~ok_dly, (pre_ram_cs | pre_vram_cs) & ~ram_ok };
wire bus_legit = 0;

jtframe_68kdtack #(.W(8)) u_dtack(
    .rst        ( rst       ),
    .clk        ( clk       ),
    .cpu_cen    ( cpu_cen   ),
    .cpu_cenb   ( cpu_cenb  ),
    .bus_cs     ( bus_cs    ),
    .bus_busy   ( bus_busy  ),
    .bus_legit  ( bus_legit ),
    .ASn        ( ASn       ),
    .DSn        ({UDSn,LDSn}),
    .num        ( 8'd29     ),  // numerator
    .den        ( 8'd146    ),  // denominator
    .DTACKn     ( DTACKn    ),
    // Frequency report
    .fave       ( fave      ),
    .fworst     ( fworst    ),
    .frst       ( rst       )
);

`ifdef FD1094
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
`else
    jts16_fd1089 u_dec(
        .rst        ( rst       ),
        .clk        ( clk       ),

        // Configuration
        .prog_addr  ( prog_addr ),
        .key_we     ( key_we    ),
        .fd1089_we  ( fd1089_we ),
        .prog_data  ( prog_data ),

        // Operation
        .dec_type   ( dec_type  ), // 0=a, 1=b
        .dec_en     ( dec_en    ),
        .rom_ok     ( rom_ok    ),
        .ok_dly     ( ok_dly    ),

        .op_n       ( op_n      ),     // OP (0) or data (1)
        .addr       ( A         ),
        .enc        ( rom_data  ),
        .dec        ( rom_dec   )
    );
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
    .LDSn       ( cpu_LDSn    ),
    .UDSn       ( cpu_UDSn    ),
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
    .IPLn       ( IPLn        ) // VBLANK
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

always @(posedge clk) begin
    // 10-11, average frequency
    if( st_addr[4] )
        case( st_addr[1:0] )
            0: st_dout <= fave[7:0];
            1: st_dout <= fave[15:8];
            2: st_dout <= fworst[7:0];
            3: st_dout <= fworst[15:8];
        endcase
    else
        st_dout <= 0;
end
`endif
`endif
`endif

endmodule