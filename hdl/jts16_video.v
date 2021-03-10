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
    Date: 7-3-2021 */

module jts16_video(
    input              rst,
    input              clk,       //
    input              pxl2_cen,  // pixel clock enable (2x)
    input              pxl_cen,   // pixel clock enable

    // Video signal
    output             HS,
    output             VS,
    output             HB,
    output             VB,
    output             LHBL_dly,
    output             LVBL_dly,
    output     [ 4:0]  red,
    output     [ 4:0]  green,
    output     [ 4:0]  blue
);

wire [8:0] V, H, vrender;
wire LHBL, LVBL;

// Frame rate and blanking as the original
// Sync pulses slightly adjusted
jtframe_vtimer #(
    .HB_START  ( 9'h1FC ),
    .HB_END    ( 9'h0BC ),
    .HCNT_START( 9'h70  ),
    .HCNT_END  ( 9'h1FF ),
    .VB_START  ( 9'h0E0 ),
    .VB_END    ( 9'h104 ),
    .VCNT_END  ( 9'h104 ),
    //.VS_START ( 9'h0   ),
    .VS_START ( 9'hF0   ),
    //.VS_END   ( 9'h8   ),
    .HS_START ( 9'h090 )
) u_timer(
    .clk       ( clk      ),
    .pxl_cen   ( pxl_cen  ),
    .vdump     ( V        ),
    .H         ( H        ),
    .Hinit     (          ),
    .LHBL      ( LHBL     ),
    .LVBL      ( LVBL     ),
    .HS        ( HS       ),
    .VS        ( VS       ),
    .Vinit     (          ),
    // unused
    .vrender   ( vrender  ),
    .vrender1  (          )
);


endmodule