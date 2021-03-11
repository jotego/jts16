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

    // CPU interface
    input              scr_cs,
    input      [ 4:1]  cpu_addr,
    input      [15:0]  cpu_dout,
    input      [ 1:0]  dsn,
    output     [15:0]  cpu_din,

    // SDRAM interface
    input              map_ok,
    output reg [13:0]  map_addr, // 3 pages + 11 addr = 14 (32 kB)
    input      [15:0]  map_data,

    input              scr_ok,
    output reg [15:0]  scr_addr, // 1 bank + 12 addr + 3 vertical = 15 bits
    input      [31:0]  scr_data,

    // Video signal
    input      [ 8:0]  vdump,
    input      [ 8:0]  hdump,
    output     [10:0]  pxl        // 1 priority + 7 palette + 3 colour = 11
);

parameter ABIT=0;

localparam [2:0] PAGE     = 3'b000,
                 PAGE_ALT = 3'b001,
                 VSCR     = 3'b100,
                 VSCR_ALT = 3'b101,
                 HSCR     = 3'b110,
                 HSCR_ALT = 3'b111;

reg  [10:0] scan_addr;
wire [ 1:0] we;
reg  [ 8:0] code;

// Memory mapped registers
reg  [15:0] pages, hscr, vscr;

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        pages <= 16'd0;
        vscr  <= 16'd0;
        hscr  <= 16'd0;
    end else if(scr_cs && cpu_addr[1]==ABIT) begin
        case( cpu_addr[4:2] )
            PAGE: begin
                if( !dsn[1] ) pages[15:8] <= cpu_din[15:8];
                if( !dsn[0] ) pages[ 7:0] <= cpu_din[ 7:0];
                cpu_dout <= pages;
            end
            VSCR: begin
                if( !dsn[1] ) vscr[15:8] <= cpu_din[15:8];
                if( !dsn[0] ) vscr[ 7:0] <= cpu_din[ 7:0];
                cpu_dout <= vscr;
            end
            HSCR: begin
                if( !dsn[1] ) hscr[15:8] <= cpu_din[15:8];
                if( !dsn[0] ) hscr[ 7:0] <= cpu_din[ 7:0];
                cpu_dout <= hscr;
            end
        endcase
    end
end

// Map reader
reg  [8:0] hpos, vpos;
reg  [2:0] page;

assign scr_addr = { code, vdump[2:0], 1'b0 };

always @(*) begin
    hpos = hdump + hscr[8:0];
    vpos = vdump + vscr[8:0];
    scan_addr = { vpos[7:3], hpos[8:3] };
    page = 3'd5;
end

always @(posedge clk, posedge rst) begin
    if( rst ) begin
    end else if( pxl_cen ) begin
        if( hdump[2:0]==3'd0 )
            map_addr <= { page, scan_addr };
    end
end


// SDRAM runs at pxl_cen x 8, so new data from SDRAM takes about a
// pxl_cen time to arrive. Data has information for four pixels

reg [23:0] pxl_data;
reg [ 7:0] attr, attr0;

assign pxl = { attr, pxl_data[23], pxl_data[15], pxl_data[7] };

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        code     <= 9'd0;
        attr     <= 4'd0;
        attr0    <= 4'd0;
        pxl_data <= 24'd0;
    end else begin
        if( pxl_cen ) begin
            if( hdump[2:0]==3'd4 ) begin
                code     <= { map_data[13], map_data[11:0] };
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