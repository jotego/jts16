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

    output reg [17:0]  rom_addr,
    output reg         rom_cs,
    input              rom_ok,
    input      [15:0]  rom_data,

    output reg         ram_cs,
    input              ram_ok,
    input      [15:0]  ram_data,
);

wire [23:1] A, Abus, cpu_A;
wire        BERRn;
wire [ 2:0] FC, IPLn;
wire        BRn, BGACKn, BGn;
wire        ASn, UDSn, LDSn, BUSn, VPAn;

`ifdef SIMULATION
wire [23:0] A_full = {A,1'b0};
`endif

assign IPLn = { irqn, 2'b11 };

reg road_cs, sio_cs;

// memory map
always @(posedge clk, posedge rst) begin
    if( rst ) begin
        rom_cs  <= 0;
        sio_cs  <= 0;
        ram_cs  <= 0;
        road_cs <= 0;
    end else begin
        if( !BGACKn || !ASn ) begin
            case( Abus[19:17] )
                0,1,2: rom_cs = 1;  // <6'0000
                3: ram_cs = 1;      //  6'0000
                4: begin            //  8'0000
                    road_cs = !Abus[16]; // 8'0000 road RAM
                    sio_cs  =  Abus[16]; // 9'0000 road other
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
    .bus_legit  ( bus_legit ),
    .ASn        ( ASn       ),
    .DSn        ({UDSn,LDSn}),
    .num        ( 7'd29     ),  // numerator
    .den        ( 8'd146    ),  // denominator
    .DTACKn     ( DTACKn    ),
    // Frequency report
    .fave       ( fave      ),
    .fworst     ( fworst    ),
    .frst       ( rst       )
);

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