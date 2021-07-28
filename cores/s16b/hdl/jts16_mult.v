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
    Date: 28-7-2021 */

module jts16_mult(
    input              rst,
    input              clk,
    input              cs,
    input      [ 1:0]  addr,
    input      [ 1:0]  wdsn,    // write data select
    input      [15:0]  din,
    output     [15:0]  dout
);

reg  [15:0] a, b;
reg  [31:0] product;

always @(posedge clk) begin
    product <= a * b;
    // output
    case( addr )
        0: dout <= a;
        1: dout <= b;
        2: dout <= product[31:16];
        3: dout <= product[15:0];
    endcase
end

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        a    <= 0;
        b    <= 0;
    end else begin
        if( cs && !wdsn[0] && !addr[0] ) a[ 7:0] <= din[ 7:0];
        if( cs && !wdsn[1] && !addr[0] ) a[15:8] <= din[15:8];
        if( cs && !wdsn[0] &&  addr[0] ) b[ 7:0] <= din[ 7:0];
        if( cs && !wdsn[1] &&  addr[0] ) b[15:8] <= din[15:8];
    end
end

endmodule