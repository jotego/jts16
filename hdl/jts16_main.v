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
    input              cpu_cen,
    input              cpu_cenb,

    // Video
    input  [8:0]       vdump,
    input              hstart,
    // Video circuitry
    output reg         vram_cs,
    output reg         char_cs,
    output reg         pal_cs,
    output reg         objram_cs,
    input       [15:0] char_dout,
    input       [15:0] pal_dout,
    input       [15:0] obj_dout,
    // RAM access
    output reg         ram_cs,
    input       [15:0] ram_data,   // coming from VRAM or RAM
    input              ram_ok,
    // CPU bus
    output      [15:0] cpu_dout,
    output             UDSWn,
    output             LDSWn,
    output             RnW,
    // cabinet I/O
    input       [ 6:0] joystick1,
    input       [ 6:0] joystick2,
    input       [ 1:0] start_button,
    input       [ 1:0] coin_input,
    input              service,
    // ROM access
    output reg         rom_cs,
    output reg  [17:1] rom_addr,
    input       [15:0] rom_data,
    input              rom_ok,
    // DIP switches
    input              dip_pause,
    input              dip_test,
    input    [7:0]     dipsw_a,
    input    [7:0]     dipsw_b
);

wire [23:1] A;
wire        BERRn = 1'b1;

`ifdef SIMULATION
wire [23:0] A_full = {A,1'b0};
`endif

wire        BRn, BGACKn, BGn;
wire        ASn;
wire        UDSn, LDSn;

reg         io_cs, wdog_cs;

assign UDSWn = RnW | UDSn;
assign LDSWn = RnW | LDSn;

// No peripheral bus access for now
assign BRn   = 1;
assign BGACKn= 1;

// System 16A memory map
always @(posedge clk, posedge rst) begin
    if( rst ) begin
            rom_cs    <= 0;
            vram_cs   <= 0;
            char_cs   <= 0;
            objram_cs <= 0;
            pal_cs    <= 0;
            io_cs     <= 0;
            wdog_cs   <= 0;
            ram_cs    <= 0;
            rom_addr  <= 0;
    end else begin
        if( !ASn && BGACKn ) begin
            if( A[23:22]==0 ) rom_addr <= A[17:1];
            rom_cs    <= A[23:22]==0;                   // 00-03
            vram_cs   <= A[23:22]==1 && A[18:16]==0;    // 40
            char_cs   <= A[23:22]==1 && A[18:16]==1;    // 41
            objram_cs <= A[23:22]==1 && A[18:16]==4;    // 44
            pal_cs    <= A[23:22]==2 && A[18:16]==4;    // 84
            io_cs     <= A[23:22]==3 && A[18:16]==4;    // c4
            wdog_cs   <= A[23:22]==3 && A[18:16]==6;    // c6
            ram_cs    <= A[23:22]==3 && A[18:16]==7;    // c7
        end else begin
            rom_cs    <= 0;
            vram_cs   <= 0;
            char_cs   <= 0;
            objram_cs <= 0;
            pal_cs    <= 0;
            io_cs     <= 0;
            wdog_cs   <= 0;
            ram_cs    <= 0;
        end
    end
end

// Data bus input
reg  [15:0] cpu_din;

always @(posedge clk) begin
    if(rst) begin
        cpu_din <= 16'hffff;
    end else begin
        cpu_din <= (ram_cs | vram_cs ) ? ram_data  : (
                    rom_cs             ? rom_data  : (
                    char_cs            ? char_dout : (
                    pal_cs             ? pal_dout  : (
                    objram_cs          ? obj_dout  : (
                                       16'hFFFF )))));
    end
end

// interrupt generation
reg        irqn; // VBLANK
wire [2:0] FC;
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
wire bus_cs   = pal_cs | char_cs | vram_cs | ram_cs | rom_cs;
wire bus_busy = |{ rom_cs & ~rom_ok, (ram_cs | vram_cs) & ~ram_ok };

jts16_dtack u_dtack(
    .rst        ( rst       ),
    .clk        ( clk       ),
    .cpu_cen    ( cpu_cen   ),
    .cpu_cenb   ( cpu_cenb  ),

    .ASn        ( ASn       ),
    .bus_cs     ( bus_cs    ),
    .bus_busy   ( bus_busy  ),
    .rom_ok     ( rom_ok    ),
    .ram_ok     ( ram_ok    ),

    .DTACKn     ( DTACKn    )
);

fx68k u_cpu(
    .clk        ( clk         ),
    .extReset   ( rst         ),
    .pwrUp      ( rst         ),
    .enPhi1     ( cpu_cen     ),
    .enPhi2     ( cpu_cenb    ),

    // Buses
    .eab        ( A           ),
    .iEdb       ( cpu_din     ),
    .oEdb       ( cpu_dout    ),


    .eRWn       ( RnW         ),
    .LDSn       ( LDSn        ),
    .UDSn       ( UDSn        ),
    .ASn        ( ASn         ),
    .VPAn       ( inta_n      ),
    .FC0        ( FC[0]       ),
    .FC1        ( FC[1]       ),
    .FC2        ( FC[2]       ),

    .BERRn      ( BERRn       ),
    // Bus arbitrion
    .HALTn      ( dip_pause   ),
    .BRn        ( BRn         ),
    .BGACKn     ( BGACKn      ),
    .BGn        ( BGn         ),

    .DTACKn     ( DTACKn      ),
    .IPL0n      ( 1'b1        ),
    .IPL1n      ( 1'b1        ),
    .IPL2n      ( irqn        ), // VBLANK

    // Unused
    .oRESETn    (             ),
    .oHALTEDn   (             ),
    .VMAn       (             ),
    .E          (             )
);

endmodule