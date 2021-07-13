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

module jts16_char(
    input              rst,
    input              clk,
    input              pxl2_cen,  // pixel clock enable (2x)
    input              pxl_cen,   // pixel clock enable

    // CPU interface
    input              char_cs,
    input      [11:1]  cpu_addr,
    input      [15:0]  cpu_dout,
    input      [ 1:0]  dsn,
    output     [15:0]  cpu_din,

    // SDRAM interface
    input              char_ok,
    output     [12:0]  char_addr, // 9 addr + 3 vertical = 12 bits
    input      [31:0]  char_data,

    // In-RAM data
    output             scr_start,
    output reg [ 8:0]  rowscr1,
    output reg [ 8:0]  rowscr2,

    // Video signal
    input              flip,
    input      [ 8:0]  vdump,
    input      [ 8:0]  hdump,
    output     [ 6:0]  pxl,       // 1 priority + 3 palette + 3 colour = 7
    input      [ 7:0]  debug_bus
);

parameter MODEL=0;  // 0 = S16A, 1 = S16B

wire [15:0] scan;
reg  [10:0] scan_addr;
wire [ 1:0] we;
reg  [ 8:0] code, vf, hf;

assign we = ~dsn & {2{char_cs}};

jtframe_dual_ram16 #(
    .aw(11),
    .simfile_lo("char_lo.bin"),
    .simfile_hi("char_hi.bin")
) u_ram(
    .clk0   ( clk       ),
    .clk1   ( clk       ),

    // CPU writes
    .addr0  ( cpu_addr  ),
    .data0  ( cpu_dout  ),
    .we0    ( we        ),
    .q0     ( cpu_din   ),

    // Video reads
    .addr1  ( scan_addr ),
    .data1  (           ),
    .we1    ( 2'b0      ),
    .q1     ( scan      )
);

localparam [4:0] ROWREAD=8;
localparam [8:0] FLIPOFFSET = 9'ha3;

assign char_addr = { code, vf[2:0], 1'b0 };
assign scr_start = hdump[8:4]==ROWREAD+1;

// Flip
always @(posedge clk) begin
    vf <= flip ? 9'd223-vdump : vdump;
    hf <= flip ? FLIPOFFSET-hdump : hdump;
end

// Row scroll
always @(*) begin
    scan_addr = { vf[7:3], hf[8:3]+6'd2 };
    // Reads column scroll during blanking
    // if( hdump[2:0]==0 ) begin
    //     scan_addr = { 5'h1f, vf[7:3], hdump[4] };
    // end
    // Reads row scroll during blanking
    if ( hdump[8:4] == ROWREAD ) begin
        scan_addr = { 5'h1f, vf[7:3], hdump[3] };
    end
end

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        rowscr1 <= 0;
        rowscr2 <= 0;
    end else begin
        if ( hdump[8:4] == ROWREAD ) begin
            if( !hdump[3] )
                rowscr1 <= scan[8:0];
            else
                rowscr2 <= scan[8:0];
        end
    end
end

// SDRAM runs at pxl_cen x 8, so new data from SDRAM takes about a
// pxl_cen time to arrive. Data has information for four pixels

reg [23:0] pxl_data;
reg [ 3:0] attr, attr0;

assign pxl = { attr,
    pxl_data[flip ? 16: 23],
    pxl_data[flip ?  8: 15],
    pxl_data[flip ?  0:  7] };

function [7:0] shift;
    input [7:0] din;
    input flip;
    shift = flip ? din>>1 : din << 1;
endfunction

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        code     <= 9'd0;
        attr     <= 4'd0;
        attr0    <= 4'd0;
        pxl_data <= 24'd0;
    end else begin
        if( pxl_cen ) begin
            if( hdump[2:0]==7 ) begin
                code     <= MODEL ? scan[8:0] : {1'b0,scan[7:0]};
                pxl_data <= char_data[23:0];
                attr0    <= MODEL ? {scan[15],scan[11:9]} : scan[11:8];
                attr     <= attr0;
            end else begin
                pxl_data[23:16] <= shift( pxl_data[23:16], flip );
                pxl_data[15: 8] <= shift( pxl_data[15: 8], flip );
                pxl_data[ 7: 0] <= shift( pxl_data[ 7: 0], flip );
            end
        end
    end
end

endmodule