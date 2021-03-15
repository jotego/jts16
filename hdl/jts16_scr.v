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
    Date: 11-3-2021 */

module jts16_scr(
    input              rst,
    input              clk,
    input              pxl2_cen,  // pixel clock enable (2x)
    input              pxl_cen,   // pixel clock enable

    // MMR
    input      [15:0]  pages,
    input      [15:0]  hscr,
    input      [15:0]  vscr,

    // SDRAM interface
    input              map_ok,
    output reg [13:0]  map_addr, // 3 pages + 11 addr = 14 (32 kB)
    input      [15:0]  map_data,

    input              scr_ok,
    output     [16:0]  scr_addr, // 1 bank + 12 addr + 3 vertical = 15 bits
    input      [31:0]  scr_data,

    // Video signal
    input      [ 8:0]  vdump,
    input      [ 8:0]  hdump,
    output     [10:0]  pxl        // 1 priority + 7 palette + 3 colour = 11
);

parameter PXL_DLY=0;

reg  [10:0] scan_addr;
wire [ 1:0] we;
reg  [12:0] code;

// Map reader
reg  [8:0] hpos;
reg  [7:0] vpos;
reg  [2:0] page;
reg        hov, vov; // overflow bits

assign scr_addr = { code, vpos[2:0], 1'b0 };

always @(*) begin
    {hov, hpos } = {1'b0, hdump } + 10'h100 - {1'd0, hscr[8:0]} + PXL_DLY;
    {vov, vpos } = vdump + {1'b0, vscr[7:0]};
    scan_addr = { vpos[7:3], hpos[8:3] };
    case( {vov, ~hov} )
        2'b11: page = pages[14:12];
        2'b10: page = pages[10: 8];
        2'b01: page = pages[ 6: 4];
        2'b00: page = pages[ 2: 0];
    endcase
end

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        map_addr <= 14'd0;
    end else if( pxl_cen ) begin
        if( hpos[2:0]==3'd0 )
            map_addr <= { page, scan_addr^11'h020 };
    end
end


// SDRAM runs at pxl_cen x 8, so new data from SDRAM takes about a
// pxl_cen time to arrive. Data has information for four pixels

reg [23:0] pxl_data;
reg [ 7:0] attr, attr0;

wire bank = map_data[13];

assign pxl = { attr, pxl_data[23], pxl_data[15], pxl_data[7] };

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        code     <= 0;
        attr     <= 0;
        attr0    <= 0;
        pxl_data <= 0;
    end else begin
        if( pxl_cen ) begin
            if( hpos[2:0]==3'd0 ) begin
                code     <= { bank, map_data[11:0] };
                pxl_data <= scr_data[23:0];
                attr0    <= map_data[12:5];
                attr     <= attr0;
            end else begin
                pxl_data[23:16] <= pxl_data[23:16]<<1;
                pxl_data[15: 8] <= pxl_data[15: 8]<<1;
                pxl_data[ 7: 0] <= pxl_data[ 7: 0]<<1;
            end
        end
    end
end

endmodule