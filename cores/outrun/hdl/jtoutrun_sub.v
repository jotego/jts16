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
    Date: 9-7-2022 */

module jtoutrun_sub(
    input              rst,
    input              clk,

    input              irqn,    // common with main CPU

    // From main CPU
    input      [19:1]  main_A,
    input      [ 1:0]  main_dsn,
    input              main_rnw,
    input              main_br, // bus request
    input      [15:0]  main_dout,
    output     [15:0]  main_din,
    output             main_ok,

    // sub CPU bus
    output     [15:0]  cpu_dout,

    output reg [17:0]  rom_addr,
    output reg         rom_cs,
    input              rom_ok,
    input      [15:0]  rom_data,

    output reg         ram_cs,
    input              ram_ok,
    input      [15:0]  ram_data,

    output reg         road_cs,
    output reg         sio_cs,
    output     [ 1:0]  dswn
);

wire [19:1] A;
wire [23:1] cpu_A;
wire        BERRn;
wire [ 2:0] FC, IPLn;
wire        BRn, BGACKn, BGn, DTACKn;
wire        ASn, UDSn, LDSn, BUSn, VPAn, RnW, BUSn,
            cpu_UDSn, cpu_LDSn, cpu_RnW;
reg  [15:0] cpu_din;
wire [15:0] cpu_dout_raw;
wire        bus_busy, bus_cs;
wire        cpu_cen, cpu_cenb;
wire        inta_n;

`ifdef SIMULATION
wire [19:0] A_full = {A,1'b0};
`endif

assign IPLn     = { irqn, 2'b11 };
assign dswn     = { UDSn, LDSn } | {2{RnW}};
assign main_din = cpu_din;
assign {UDSn, LDSn} = BGACKn ? {cpu_UDSn,cpu_LDSn} : main_dsn;
assign RnW      = BGACKn ? cpu_RnW : main_rnw;
assign cpu_dout = BGACKn ? cpu_dout_raw : main_dout;
assign A        = BGACKn ? cpu_A[19:1] : main_A;
assign bus_cs   = rom_cs | ram_cs;
assign bus_busy = (rom_cs & ~rom_ok) | (ram_cs & ~ram_ok);
assign inta_n   = ~&FC[1:0];
assign VPAn     = ~(~ASn & ~inta_n); // autovector
assign main_ok  = ~BGACKn & ~bus_busy;
assign BUSn     = LDSn & UDSn;

// memory map
always @(posedge clk, posedge rst) begin
    if( rst ) begin
        rom_cs  <= 0;
        sio_cs  <= 0;
        ram_cs  <= 0;
        road_cs <= 0;
    end else begin
        if( !BUSn || !BGACKn || (!ASn && RnW) ) begin
            case( A[19:17] )
                0,1,2: rom_cs = 1;  // <6'0000
                3: ram_cs = ~BUSn;  //  6'0000
                4: begin            //  8'0000
                    road_cs = !A[16]; // 8'0000 road RAM
                    sio_cs  =  A[16]; // 9'0000 road other
                end
            endcase
        end else begin
            rom_cs  <= 0;
            sio_cs  <= 0;
            ram_cs  <= 0;
            road_cs <= 0;
        end
    end
end

jtframe_68kdtack #(.W(8),.MFREQ(50_347)) u_dtack( // 10 MHz
    .rst        ( rst       ),
    .clk        ( clk       ),
    .cpu_cen    ( cpu_cen   ),
    .cpu_cenb   ( cpu_cenb  ),
    .bus_cs     ( bus_cs    ),
    .bus_busy   ( bus_busy  ),
    .bus_legit  ( 1'b0      ),
    .ASn        ( ASn | ~inta_n ), // do not generate DTACK for int ack
    .DSn        ({UDSn,LDSn}),
    .num        ( 7'd29     ),  // numerator
    .den        ( 8'd146    ),  // denominator
    .DTACKn     ( DTACKn    ),
    // Frequency report
    .fave       (           ),
    .fworst     (           ),
    .frst       ( rst       )
);

jtframe_68kdma u_dma(
    .rst        ( rst       ),
    .clk        ( clk       ),
    .cen        ( cpu_cen   ),
    .cpu_BRn    ( BRn       ),
    .cpu_BGACKn ( BGACKn    ),
    .cpu_BGn    ( BGn       ),
    .cpu_ASn    ( ASn       ),
    .cpu_DTACKn ( DTACKn    ),
    .dev_br     ( main_br   )
);

jtframe_m68k u_cpu(
    .clk        ( clk         ),
    .rst        ( rst         ),
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
    .VPAn       ( VPAn        ),
    .FC         ( FC          ),

    .BERRn      ( BERRn       ),
    // Bus arbitrion
    .HALTn      ( 1'b1        ),
    .BRn        ( BRn         ),
    .BGACKn     ( BGACKn      ),
    .BGn        ( BGn         ),

    .DTACKn     ( DTACKn      ),
    .IPLn       ( IPLn        ) // VBLANK
);

endmodule