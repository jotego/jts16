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

//
//  Region 0 - Program ROM
//  Region 3 - 68000 work RAM
//  Region 4 - Text/tile RAM
//  Region 5 - Object RAM
//  Region 6 - Color RAM
//  Region 7 - I/O area

module jts16b_mem_map(
    input             rst,
    input             clk,
    input      [23:1] addr,
    input      [15:0] cpu_dout,
    input      [ 1:0] dswn,
    output reg [ 7:0] active
);

reg [7:0] base[0:7];
reg [1:0] size[0:7];
wire      none = active==0

integer aux;
always @(*) begin
    for( aux=0; aux<8; aux=aux+1 ) begin
        case( size[aux] )
            0: active[aux] = addr[23:16] == base[aux];      //   64 kB
            1: active[aux] = addr[23:17] == base[aux][7:1]; //  128 kB
            2: active[aux] = addr[23:19] == base[aux][7:3]; //  512 kB
            3: active[aux] = addr[23:21] == base[aux][7:5]; // 2048 kB
        endcase
    end
end

always @(posedge clk, posedge rst ) begin
    if( rst ) begin
        base[0] <= 0; base[1] <= 0; base[2] <= 0; // ROM
        base[3] <= 0; // RAM
        base[4] <= 0; // VRAM
        base[5] <= 0; // object RAM
        base[6] <= 0; // palette RAM
        base[7] <= 0; // I/O
        size[0] <= 0; size[1] <= 0; size[2] <= 0; size[3] <= 0;
        size[4] <= 0; size[5] <= 0; size[6] <= 0; size[7] <= 0;
    end else begin
        if( none ) begin
            if(  addr[1] && !dswn[0])
                base[ addr[4:2] ] <= cpu_dout[7:0];
            if( !addr[1] && !dswn[0])
                size[ addr[4:2] ] <= cpu_dout[1:0];
        end
    end
end

endmodule