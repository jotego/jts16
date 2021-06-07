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

    input              LHBL,

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
    input      [ 8:0]  vrender,
    input      [ 8:0]  hdump,
    output     [10:0]  pxl,       // 1 priority + 7 palette + 3 colour = 11
    input      [ 7:0]  debug_bus
);

parameter [9:0] PXL_DLY=0;
parameter [8:0] HB_END=9'h70, HSCAN0 = HB_END-9'd8;

reg  [10:0] scan_addr;
wire [ 1:0] we;
reg  [12:0] code;

reg  [8:0] hscan, vscan;

// Map reader
reg  [8:0] hpos;
reg  [7:0] vpos;
reg  [2:0] page;
reg        hov, vov; // overflow bits

reg       done, draw;
reg [7:0] busy;
reg       hsel;
reg [9:0] hpage;

assign scr_addr = { code, vpos[2:0], 1'b0 };

always @(*) begin
    {hov, hpos } = {1'b0, hscan } - {1'b0, hscr[8:0] }+PXL_DLY;
    //hpage = {hov,hpos} +{{2{debug_bus[7]}},  debug_bus};
    hpage = {hov,hpos};
    {vov, vpos } = vscan + {1'b0, vscr[7:0]};
    scan_addr = { vpos[7:3], hpage[8:3] };
    //case( debug_bus[1:0] )
    //    0: hsel = ~hov | ~hpos[8];
    //    1: hsel =  hov |  hpos[8];
    //    2: hsel =  hov | ~hpos[8];
    //    3: hsel = ~hov |  hpos[8];
    //endcase
    case( { vov, hov^debug_bus[0] } )
        2'b10: page = pages[14:12]; // upper left
        2'b11: page = pages[10: 8]; // upper right
        2'b00: page = pages[ 6: 4]; // lower left
        2'b01: page = pages[ 2: 0]; // lower right
    endcase
    //page = 5;
end

reg [1:0] map_st;
reg       last_LHBL;

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        map_addr <= 14'd0;
        draw     <= 0;
    end else if(!done) begin
        map_st <= map_st+1'd1;
        draw   <= 0;
        case( map_st )
            0: map_addr <= { page, scan_addr };
            3:
                if( !map_ok || busy!=0 || !scr_ok)
                    map_st <= 3;
                else
                    draw   <= 1;
            default:;
        endcase
    end else begin
        map_st <= 0;
        draw   <= 0;
    end
end


// SDRAM runs at pxl_cen x 8, so new data from SDRAM takes about a
// pxl_cen time to arrive. Data has information for four pixels

reg [23:0] pxl_data;
reg [ 7:0] attr;
reg [ 1:0] scr_good;

wire bank = map_data[13];
wire [10:0] buf_data;

assign buf_data = { attr, pxl_data[23], pxl_data[15], pxl_data[7] };

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        code     <= 0;
        attr     <= 0;
        pxl_data <= 0;

        last_LHBL <= 0;
        done      <= 0;
        busy      <= 0;
        hscan     <= 0;
    end else begin
        last_LHBL <= LHBL;
        scr_good  <= { scr_good[0], scr_ok };
        if( scr_good==2'b01 ) pxl_data <= scr_data[23:0];

        if( !LHBL && last_LHBL ) begin
            vscan <= vrender;
            done  <= 0;
            busy  <= 0;
        end

        if( done ) begin
            hscan <= HSCAN0;
        end

        if( draw && !done ) begin
            code     <= { bank, map_data[11:0] };
            attr     <= map_data[12:5];
            busy     <= ~8'd0;
            scr_good <= 2'd0;
        end else if( busy!=0 && &scr_good && pxl2_cen) begin // This could work
            // without pxl2_cen, but it stresses the SDRAM too much, causing
            // glitches in the char layer.
            pxl_data[23:16] <= pxl_data[23:16]<<1;
            pxl_data[15: 8] <= pxl_data[15: 8]<<1;
            pxl_data[ 7: 0] <= pxl_data[ 7: 0]<<1;
            if( hpos[2:0]==3'd7 )
                busy <= 8'h80;
            else
                busy <= busy<<1;
            hscan <= hscan + 1'd1;
            if( &hscan ) done <= 1;
        end
    end
end

jtframe_linebuf #(.DW(11),.AW(9)) u_linebuf(
    .clk    ( clk      ),
    .LHBL   ( LHBL     ),
    // New data writes
    .wr_addr( hscan    ),
    .wr_data( buf_data ),
    .we     ( busy[7]   ),
    // Old data reads (and erases)
    .rd_addr( hdump    ),
    .rd_data( pxl      ),
    .rd_gated(         )
);

endmodule