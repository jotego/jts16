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
    Date: 10-3-2021 */

module jts16_colmix(
    input              rst,
    input              clk,
    input              pxl2_cen,  // pixel clock enable (2x)
    input              pxl_cen,   // pixel clock enable

    input              LHBL,
    input              LVBL,

    input  [6:0]       char_pxl,

    output [4:0]       red,
    output [4:0]       green,
    output [4:0]       blue,
    output             LVBL_dly,
    output             LHBL_dly
);

assign LVBL_dly = LVBL;
assign LHBL_dly = LHBL;

assign red   = {1'b0, char_pxl[2:0],1'b0 };
assign green = {1'b0, char_pxl[2:0],1'b0 };
assign blue  = {1'b0, char_pxl[2:0],1'b0 };

endmodule