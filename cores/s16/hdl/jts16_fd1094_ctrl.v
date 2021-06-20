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
    Date: 20-6-2021 */

module jts16_fd1094_ctrl(
    input             rst,
    input             clk,

    // Operation
    input             inta_n,      // interrupt acknowledgement
    input             op_n,

    input      [23:1] addr,
    input      [15:0] dec,    
    input      [ 7:0] gkey0,

    input             ok_dly,
    output     [ 7:0] st
);

reg [7:0] state;
reg       irqmode, stchange, staddr;

assign st = irqmode ? gkey0 : state;

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        state <= 0;
        stchange <= 0;
        staddr   <= 0;
        irqmode  <= 0;
    end else begin
        if( !op_n ) begin
            // cmp.l #data
            if( dec[15:12]==4'b1011 && dec[5:0]==6'b111_100 ) begin
                stchange <= 1;
                staddr   <= ~addr[2];
            end
            // rte
            if( dec == 16'h4e73 ) irqmode <= 0;
        end
        if( !inta_n ) irqmode <= 1;
        if( addr[2]==staddr && stchange ) begin
            stchange <= 0;
            case( dec[13:12])
                0: state <= dec[11:8];
                1: begin
                    state   <= 0; // reset
                    irqmode <= 0;
                end
                2: irqmode <= 1; // enter interruption
                3: irqmode <= 0; // leave interruption
            endcase
        end
    end
end

endmodule