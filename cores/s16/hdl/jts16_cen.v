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
    input              clk,       // main CPU & video
    input              clk24,     // sound subsystem (25.1748 MHz)
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

// Sound subsystem uses clk24 = 25.1748 MHz

jtframe_frac_cen u_fmcen(   // 4MHz
    .clk    ( clk24     ),
    .n      ( 10'd143   ),
    .m      ( 10'd900   ),
    .cen    ( { fm2_cen, fm_cen } ),
    .cenb   (           )
);

jtframe_frac_cen #(.WC(14)) u_sndcen( // 5 MHz
    .clk    ( clk24     ),
    .n      ( 14'd1373  ),
    .m      ( 14'd6913  ),
    .cen    ( { nc3, snd_cen } ),
    .cenb   (           )
);

`ifndef S16B
    jtframe_frac_cen #(.WC(14)) u_pcmcen(  // 6 MHz
        .clk    ( clk24     ),
        .n      ( 14'd1619  ),
        .m      ( 14'd6793  ),
        .cen    ( { nc2, pcm_cen  } ),
        .cenb   ( { ncb2, pcm_cenb} )
    );
`else
    // 640 kHz
    jtframe_frac_cen  #(.WC(16)) u_pcmcen(
        .clk    ( clk24     ),
        .n      ( 16'd873   ),
        .m      ( 16'd34340 ),
        .cen    ( { nc2, pcm_cen  } ),
        .cenb   ( { ncb2, pcm_cenb} )
    );
`endif

endmodule