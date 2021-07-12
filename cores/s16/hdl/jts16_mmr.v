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

module jts16_mmr(
    input              rst,
    input              clk,

    input              flip,
    // CPU interface
    input              char_cs,
    input      [11:1]  cpu_addr,
    input      [15:0]  cpu_dout,
    input      [ 1:0]  dsn,

    // Video registers
    output reg [15:0]  scr1_pages,
    output reg [15:0]  scr2_pages,

    output     [15:0]  scr1_hpos,
    output     [15:0]  scr1_vpos,

    output     [15:0]  scr2_hpos,
    output     [15:0]  scr2_vpos,

    // Outputs for System 16B
    inout              rowscr1_en,
    inout              rowscr2_en,

    // status dump
    input      [ 7:0]  st_addr,
    output reg [ 7:0]  st_dout
);

parameter MODEL=0;  // 0 = S16A, 1 = S16B

reg [15:0]  scr1_pages_flip, scr2_pages_flip,
            scr1_pages_nofl, scr2_pages_nofl,
            scr1_hpos_flip, scr1_hpos_nofl,
            scr1_vpos_flip, scr1_vpos_nofl,
            scr2_hpos_flip, scr2_hpos_nofl,
            scr2_vpos_flip, scr2_vpos_nofl;

function [15:0] bytemux( input [15:0] old );
    bytemux = { dsn[1] ? old[15:8] : cpu_dout[15:8], dsn[0] ? old[7:0] : cpu_dout[7:0] };
endfunction

always @(posedge clk) begin
    scr1_pages <= flip ? scr1_pages_flip : scr1_pages_nofl;
    scr2_pages <= flip ? scr2_pages_flip : scr2_pages_nofl;
end

assign scr1_hpos = (flip && MODEL==1) ? scr1_hpos_flip  : scr1_hpos_nofl;
assign scr1_vpos = (flip && MODEL==1) ? scr1_vpos_flip  : scr1_vpos_nofl;
assign scr2_hpos = (flip && MODEL==1) ? scr2_hpos_flip  : scr2_hpos_nofl;
assign scr2_vpos = (flip && MODEL==1) ? scr2_vpos_flip  : scr2_vpos_nofl;

generate
    if( MODEL==1 ) begin
        assign rowscr1_en = scr1_hpos[15];
        assign rowscr2_en = scr2_hpos[15];
    end
endgenerate

`ifdef SIMULATION
    reg [15:0] sim_cfg[0:511];

    initial begin
        $readmemh( "mmr.hex", sim_cfg );

        scr1_pages_flip = sim_cfg[9'h08e];
        scr1_pages_nofl = sim_cfg[9'h09e];
        scr2_pages_flip = sim_cfg[9'h08c];
        scr2_pages_nofl = sim_cfg[9'h09c];
        scr1_vpos       = sim_cfg[9'h124];
        scr2_vpos       = sim_cfg[9'h126];
        scr1_hpos       = sim_cfg[9'h1f8];
        scr2_hpos       = sim_cfg[9'h1fa];
    end
`endif

localparam [8:0] SCR1_PGFL = MODEL ? 9'h080 : 9'h08e,
                 SCR1_PGNF = MODEL ? 9'h084 : 9'h09e,
                 SCR2_PGFL = MODEL ? 9'h082 : 9'h08c,
                 SCR2_PGNF = MODEL ? 9'h086 : 9'h09c,

                 SCR1_VPOS = MODEL ? 9'h090 : 9'h124,
                 SCR2_VPOS = MODEL ? 9'h092 : 9'h126,
                 SCR1_VPFL = MODEL ? 9'h094 : 9'h124,
                 SCR2_VPFL = MODEL ? 9'h096 : 9'h126,

                 SCR1_HPOS = MODEL ? 9'h098 : 9'h1f8,
                 SCR1_HPFL = MODEL ? 9'h09C : 9'h1f8,
                 SCR2_HPOS = MODEL ? 9'h09A : 9'h1fa,
                 SCR2_HPFL = MODEL ? 9'h09E : 9'h1fa;

always @(posedge clk) begin
    if( char_cs && cpu_addr[11:9]==3'b111 && dsn!=2'b11) begin
        case( {cpu_addr[8:1], 1'b0} )
            SCR1_PGFL: scr1_pages_flip <= bytemux( scr1_pages_flip );
            SCR1_PGNF: scr1_pages_nofl <= bytemux( scr1_pages_nofl );
            SCR2_PGFL: scr2_pages_flip <= bytemux( scr2_pages_flip );
            SCR2_PGNF: scr2_pages_nofl <= bytemux( scr2_pages_nofl );
            SCR1_VPOS: scr1_vpos_nofl  <= bytemux( scr1_vpos_nofl  );
            SCR2_VPOS: scr2_vpos_nofl  <= bytemux( scr2_vpos_nofl  );
            SCR1_HPOS: scr1_hpos_nofl  <= bytemux( scr1_hpos_nofl  );
            SCR2_HPOS: scr2_hpos_nofl  <= bytemux( scr2_hpos_nofl  );

            SCR1_VPFL: scr1_vpos_flip  <= bytemux( scr1_vpos_flip  );
            SCR2_VPFL: scr2_vpos_flip  <= bytemux( scr2_vpos_flip  );
            SCR1_HPFL: scr1_hpos_flip  <= bytemux( scr1_hpos_flip  );
            SCR2_HPFL: scr2_hpos_flip  <= bytemux( scr2_hpos_flip  );
            default:;
        endcase
    end
end

`ifdef JTFRAME_CHEAT
always @(posedge clk) begin
    case( st_addr )
        0:  st_dout <= scr1_pages_nofl[ 7:0];
        1:  st_dout <= scr1_pages_nofl[15:8];
        2:  st_dout <= scr2_pages_nofl[ 7:0];
        3:  st_dout <= scr2_pages_nofl[15:8];
        4:  st_dout <= scr1_vpos[ 7:0];
        5:  st_dout <= scr1_vpos[15:8];
        6:  st_dout <= scr2_vpos[ 7:0];
        7:  st_dout <= scr2_vpos[15:8];
        8:  st_dout <= scr1_hpos[ 7:0];
        9:  st_dout <= scr1_hpos[15:8];
        10: st_dout <= scr2_hpos[ 7:0];
        11: st_dout <= scr2_hpos[15:8];
        default: st_dout <= 0;
    endcase
end
`endif

endmodule