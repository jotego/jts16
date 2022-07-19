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
    Date: 9-7-2022 */

module jtoutrun_road(
    input              rst,
    input              clk,
    input              pxl_cen,
    input        [8:0] v,
    input              vint,
    input              hs,

    // CPU interface
    input       [11:1] cpu_addr,
    input       [15:0] cpu_dout,
    output      [15:0] cpu_din,
    input       [ 1:0] cpu_dswn,
    input              road_cs,
    input              io_cs

    // ROM access
    output      [13:0] rom0_addr,
    input       [15:0] rom0_data,
    output             rom0_cs,
    input              rom0_ok,

    output      [13:0] rom1_addr,
    input       [15:0] rom1_data,
    output             rom1_cs,
    input              rom1_ok,
    // Pixel output
    output      [ 7:0] pxl
);

    wire [10:0] rd_addr;
    wire [15:0] rd_gfx;
    wire [ 1:0] rd_we;
    reg         rdsel, toggle;
    reg         rdhon;
    reg  [ 1:0] ctrl;
    reg  [ 2:0] st;

    reg  [11:0] rd0_idx, rd1_idx,
                rd0_scr, rd1_scr, rd_col;

    assign rd_addr = 0;
    assign rd_we   = {2{road_cs}} & ~cpu_dswn;

    always @(posedge clk, posedge rst) begin
        if( rst ) begin
            rdsel  <= 0;
            toggle <= 0;
            ctrl   <= 0;
        end else begin
            if( io_cs & ~cpu_dswn[0] )  ctrl <= cpu_dout[1:0];
            if( vint && toggle ) begin
                rdsel  <= ~rdsel;
                toggle <= 0;
            end else if( io_cs && cpu_dswn==2'b11 )
                toggle <= 1;
        end
    end

    jtframe_dual_ram16 #(.aw(12)) u_vram0(
        // CPU
        .clk0 ( clk      ),
        .data0( cpu_dout ),
        .addr0( {rd_sel, cpu_addr } ),
        .we0  ( rd_we    ),
        .q0   ( cpu_din  ),
        // Road engine
        .clk1 ( clk      ),
        .data1(          ),
        .addr1( rd_addr  ),
        .we1  ( 2'd0     ),
        .q1   ( rd_gfx   )
    );

    always @(posedge clk, posedge rst) begin
        if( rst ) begin
            rd_draw <= 0;
            st      <= 0;
        end else begin
            if( hs ) begin
                st <= st + 3'd1;
                case( st )
                    0: rd0_idx <= rd_gfx[11:0];
                    1: rd1_idx <= rd_gfx[11:0];
                    2: rd0_scr <= rd_gfx[11:0];
                    3: rd1_scr <= rd_gfx[11:0];
                    4: rd_col  <= rd_gfx[11:0];
                endcase
            end else begin
                st <= 0;
            end
        end
    end

    jtoutrun_rdrom u_rom0(
        .rst        ( rst       ),
        .clk        ( clk       ),
        .pxl_csn    ( pxl_cen   ),

        .cfg        ( rd0_idx   ),

        .rom_addr   ( rom0_addr ),
        .rom_data   ( rom0_data ),
        .rom_cs     ( rom0_cs   ),
        .rom_ok     ( rom0_ok   ),
        .pxl        ( rd0_pxl   )
    );

    jtoutrun_rdrom u_rom1(
        .rst        ( rst       ),
        .clk        ( clk       ),
        .pxl_csn    ( pxl_cen   ),

        .cfg        ( rd1_idx   ),

        .rom_addr   ( rom1_addr ),
        .rom_data   ( rom1_data ),
        .rom_cs     ( rom1_cs   ),
        .rom_ok     ( rom1_ok   ),
        .pxl        ( rd1_pxl   )
    );

endmodule

module jtoutrun_rdrom(
    input              rst,
    input              clk,
    input              pxl_cen,
    input              hs,

    input       [11:0] cfg,
    input       [11:0] hscr,

    output      [13:0] rom_addr,
    input       [15:0] rom_data,
    output             rom_cs,
    input              rom_ok,
    output      [ 1:0] pxl
);

    reg  [11:0] hpos;
    reg  [15:0] pxl_data;
    wire        en;

    assign pxl = { pxl_data[15], pxl_data[7] };
    assign rom_addr = { cfg[8:1], hpos[8:3] };
    assign en  = !cfg[11] && hpos[11:9]==3'b011;

    always @(posedge clk, posedge rst) begin
        if( rst ) begin
            rom_cs   <= 0;
            rom_addr <= 0;
            pxl_data <= 0;
        end else begin
            if( hs ) begin
                rom_cs   <= 0;
                rom_addr <= 0;
                hpos     <= hscr;
                pxl_data <= 16'hffff;
            end else if( pxl_cen ) begin
                rom_cs <= en;
                hpos   <= hpos + 11'd1;
                if( hpos[2:0]==0 ) begin
                    pxl_data <= !en ? 16'hffff : rom_data;
                end else begin
                    pxl_data <= pxl_data << 1;
                end
            end
        end
    end

endmodule