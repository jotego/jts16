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

`ifndef NOSOUND

module jts16b_snd(
    input                rst,
    input                clk,

    input                cen_fm,    // 4MHz
    input                cen_fm2,   // 2MHz
    input                cen_pcm,   // 6MHz
    input                cen_pcmb,

    input                sound_en,
    // options
    input         [ 1:0] fxlevel,
    input                enable_fm,
    input                enable_psg,

    input         [ 7:0] latch,
    input                irqn,
    output               ack,
    // ROM
    output        [14:0] rom_addr,
    output    reg        rom_cs,
    input         [ 7:0] rom_data,
    input                rom_ok,

    // PROM
    input         [ 9:0] prog_addr,
    input                prom_we,
    input         [ 7:0] prog_data,

    // ADPCM ROM
    output        [16:0] pcm_addr,
    output               pcm_cs,
    input         [ 7:0] pcm_data,
    input                pcm_ok,

    // Sound output
    output signed [15:0] snd,
    output               sample,
    output               peak
);

localparam [7:0] FMGAIN=8'h10;

wire [15:0] A;
reg         fm_cs, latch_cs, ram_cs;
wire        mreq_n, iorq_n, int_n, nmi_n;
wire        WRn;
reg  [ 7:0] din, pcm_cmd, pcmgain;
reg         rom_ok2;
wire        rom_good, cmd_cs;
wire [ 7:0] dout, fm_dout, ram_dout;
wire        pcm_irqn, pcm_rstn,
            wr_n, rd_n;

wire signed [15:0] fm_left, fm_right, mixed;
wire signed [ 8:0] pcm_raw, pcm_snd;
wire [7:0] fmgain;

assign snd = sound_en ? mixed : 16'd0;

assign rom_good = rom_ok2 & rom_ok;
assign rom_addr = A[14:0];
assign ack      = latch_cs;
assign cmd_cs   = !iorq_n && A[7:6]==2 && !wr_n; // 80
assign fmgain   = enable_fm ? FMGAIN : 0;

// PCM volume
always @(posedge clk ) begin
    case( fxlevel )
        2'd0: pcmgain <= 8'h04;
        2'd1: pcmgain <= 8'h06;
        2'd2: pcmgain <= 8'h08;
        2'd3: pcmgain <= 8'h0C;
    endcase
    if( !enable_psg ) pcmgain <= 0;
end

always @(*) begin
    if( !iorq_n ) begin
        case( A[7:6] )
            0: fm_cs        = 1;
            1: upd_ctrl_cs  = 1;
            2: upd_st_cs    = 1;
            3: latch_cs     = 1;
        endcase
    end else begin
        latch_cs = (!mreq_n &&  A[15:12]==4'he && A[11]) // e800
    end
    end
end

always @(posedge clk) begin
    ram_cs   <=  !mreq_n && &A[15:11];
    rom_cs   <=  !mreq_n && !A[15];
    rom_ok2  <= rom_ok;
    if( cmd_cs ) pcm_cmd <= dout;

    din      <= rom_cs   ? rom_data : (
                ram_cs   ? ram_dout : (
                fm_cs    ? fm_dout  : (
                latch_cs ? latch    : (
                    8'hff ))));
end

jtframe_mixer #(.W2(9)) u_mixer(
    .rst    ( rst       ),
    .clk    ( clk       ),
    .cen    ( 1'b1      ),
    // input signals
    .ch0    ( fm_left   ),
    .ch1    ( fm_right  ),
    .ch2    ( pcm_snd   ),
    .ch3    ( 16'd0     ),
    // gain for each channel in 4.4 fixed point format
    .gain0  ( fmgain    ),
    .gain1  ( fmgain    ),
    .gain2  ( pcmgain   ),
    .gain3  ( 8'h00     ),
    .mixed  ( mixed     ),
    .peak   ( peak      )
);

jtframe_ff u_ff(
    .rst    ( rst       ),
    .clk    ( clk       ),
    .cen    ( 1'b1      ),
    .din    ( 1'b1      ),
    .q      (           ),
    .qn     ( nmi_n     ),
    .set    ( 1'b0      ),    // active high
    .clr    ( latch_cs  ),    // active high
    .sigedge( ~irqn     ) // signal whose edge will trigger the FF
);

jtframe_sysz80 #(.RAM_AW(11)) u_cpu(
    .rst_n      ( ~rst        ),
    .clk        ( clk         ),
    .cen        ( cen_fm      ),
    .cpu_cen    (             ),
    .int_n      ( int_n       ),
    .nmi_n      ( nmi_n       ),
    .busrq_n    ( 1'b1        ),
    .m1_n       (             ),
    .mreq_n     ( mreq_n      ),
    .iorq_n     ( iorq_n      ),
    .rd_n       ( rd_n        ),
    .wr_n       ( wr_n        ),
    .rfsh_n     (             ),
    .halt_n     (             ),
    .busak_n    (             ),
    .A          ( A           ),
    .cpu_din    ( din         ),
    .cpu_dout   ( dout        ),
    .ram_dout   ( ram_dout    ),
    // manage access to ROM data from SDRAM
    .ram_cs     ( ram_cs      ),
    .rom_cs     ( rom_cs      ),
    .rom_ok     ( rom_good    )
);

//
//  YM2151 output port
//
//  D1 = /RESET line on 7751
//  D0 = /IRQ line on 7751
//

jt51 u_jt51(
    .rst        ( rst       ), // reset
    .clk        ( clk       ), // main clock
    .cen        ( cen_fm    ),
    .cen_p1     ( cen_fm2   ),
    .cs_n       ( !fm_cs    ), // chip select
    .wr_n       ( wr_n      ), // write
    .a0         ( A[0]      ),
    .din        ( dout      ), // data in
    .dout       ( fm_dout   ), // data out
    .ct1        ( pcm_rstn  ),
    .ct2        ( pcm_irqn  ),
    .irq_n      ( int_n     ),  // I do not synchronize this signal
    // Low resolution output (same as real chip)
    .sample     ( sample    ), // marks new output sample
    .left       (           ),
    .right      (           ),
    // Full resolution output
    .xleft      ( fm_left   ),
    .xright     ( fm_right  ),
    // unsigned outputs for sigma delta converters, full resolution
    .dacleft    (           ),
    .dacright   (           )
);

jt7759 u_pcm(
    .rst        ( rst       ), // reset
    .clk        ( clk       ), // main clock
    input                  cen,  // 640kHz
    input                  stn,  // STart (active low)
    input                  cs,
    input                  mdn,  // MODE: 1 for stand alone mode, 0 for slave mode
    output                 busyn,
    // CPU interface
    input                  wrn,  // for slave mode only
    input         [ 7:0]   din,
    // ROM interface
    output                 rom_cs,      // equivalent to DRQn in original chip
    output        [16:0]   rom_addr,
    input         [ 7:0]   rom_data,
    input                  rom_ok,
    // Sound output
    .sound      ( pcm_raw   )
);

// where a = exp(-wc/T ), a<1
// wc = radian frequency

wire [3:0] pole_a = 4'd10; // pole at 4kHz

jtframe_pole #(.WS(9)) u_pole(
    .rst        ( rst       ),
    .clk        ( clk       ),
    .sample     ( sample    ),      // uses the YM2151 as sampling signal
    .a          ( pole_a    ),
    .sin        ( pcm_raw   ),
    .sout       ( pcm_snd   )
);

endmodule

`endif