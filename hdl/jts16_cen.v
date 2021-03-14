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

module jts16_cen(
    input              rst,
    input              clk,       //
    output             pxl2_cen,  // pixel clock enable (2x)
    output             pxl_cen,   // pixel clock enable
    output             cpu_cen,
    output             cpu_cenb,
    output             snd_cen,
    output             fm_cen
);

wire nc, ncb;

jtframe_frac_cen #(2) u_pxlcen(
    .clk    ( clk       ),
    .n      ( 10'd1     ),
    .m      ( 10'd4     ),
    .cen    ( {pxl_cen, pxl2_cen }   ),
    .cenb   (           )
);

jtframe_frac_cen u_cpucen(
    .clk    ( clk       ),
    .n      ( 10'd29    ),
    .m      ( 10'd146   ),
    .cen    ( { nc,  cpu_cen  } ),
    .cenb   ( { ncb, cpu_cenb } )
);

jtframe_frac_cen u_sndcen(
    .clk    ( clk       ),
    .n      ( 10'd109   ),
    .m      ( 10'd686   ),
    .cen    ( { fm_cen, snd_cen } ),
    .cenb   (           )
);

endmodule