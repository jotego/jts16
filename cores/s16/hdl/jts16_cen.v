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
    output             cpu_cen,     // 10
    output             cpu_cenb,
    output             snd_cen,     // 5
    output             fm_cen,      // 4
    output             fm2_cen,     // 2
    output             pcm_cen,
    output             pcm_cenb
);

wire nc, ncb, nc2, ncb2, nc3;

jtframe_frac_cen #(2) u_pxlcen(
    .clk    ( clk       ),
    .n      ( 10'd1     ),
    .m      ( 10'd4     ),
    .cen    ( {pxl_cen, pxl2_cen }   ),
    .cenb   (           )
);

`ifndef FAST_CPU
jtframe_frac_cen u_cpucen(
    .clk    ( clk       ),
    .n      ( 10'd29    ),
    .m      ( 10'd146   ),
    .cen    ( { nc,  cpu_cen  } ),
    .cenb   ( { ncb, cpu_cenb } )
);
`else
reg fastx=0;
always @(posedge clk) begin
    fastx <= ~fastx;
end
assign cpu_cen = fastx;
assign cpu_cenb = ~fastx;
`endif

jtframe_frac_cen u_fmcen(
    .clk    ( clk       ),
    .n      ( 10'd63    ),
    .m      ( 10'd793   ),
    .cen    ( { fm2_cen, fm_cen } ),
    .cenb   (           )
);

jtframe_frac_cen #(.WC(14)) u_sndcen(
    .clk    ( clk       ),
    .n      ( 14'd1373  ),
    .m      ( 14'd13826 ),
    .cen    ( { nc3, snd_cen } ),
    .cenb   (           )
);

`ifndef S16B
    jtframe_frac_cen u_pcmcen(
        .clk    ( clk       ),
        .n      ( 10'd120   ),
        .m      ( 10'd1007  ),
        .cen    ( { nc2, pcm_cen  } ),
        .cenb   ( { ncb2, pcm_cenb} )
    );
`else
    // 640 kHz
    jtframe_frac_cen  #(.WC(16)) u_pcmcen(
        .clk    ( clk       ),
        .n      ( 16'd654   ),
        .m      ( 16'd51451 ),
        .cen    ( { nc2, pcm_cen  } ),
        .cenb   ( { ncb2, pcm_cenb} )
    );
`endif

endmodule