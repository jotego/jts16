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
    Date: 10-10-2022 */

module jtoutrun_obj_scan(
    input              rst,
    input              clk,

    // Obj table
    output     [10:1]  tbl_addr,
    input      [15:0]  tbl_dout,
    output     [15:0]  tbl_din,
    output reg         tbl_we,

    // Draw commands
    output reg         dr_start,
    input              dr_busy,
    output reg [ 8:0]  dr_xpos,
    output reg [15:0]  dr_offset,  // MSB is also used as the flip bit
    output reg [ 2:0]  dr_bank,
    output reg [ 1:0]  dr_prio,
    output reg [ 6:0]  dr_pal,
    output reg [ 9:0]  dr_hzoom,
    output reg         dr_hflipb,

    // Video signal
    input              flip,
    input              hstart,
    input      [ 8:0]  vrender
);

parameter [8:0] PXL_DLY=8;

localparam LAST_IDX = 5; // last LUT position set by the CPU
localparam STW = 4;

reg  [6:0] cur_obj;  // current object
reg  [2:0] idx;
reg  [STW-1:0] st;
reg [15:0] zoom;
reg        first, stop, visible;

// Object data
reg        [ 8:0] bottom, top;
wire       [ 8:0] endline;
reg        [ 8:0] xpos;
reg signed [15:0] pitch;
reg        [15:0] offset;
reg        [ 2:0] bank;
reg        [ 1:0] prio;
reg        [ 6:0] pal;
reg               zoom_sel, hflipb, vflip, shadow;
wire       [15:0] next_offset;
wire       [10:0] next_zoom;
reg        [ 9:0] vzoom, hzoom;

assign tbl_addr    = { cur_obj, idx };
assign tbl_din     = offset; //zoom_sel ? {1'b0, zoom[14:0] } : offset;
assign next_offset = first ? offset : tbl_dout + pitch;
assign endline     = vflip ? top - {1'd0,tbl_dout[15:8]} : top + {1'd0,tbl_dout[15:8]};

// wire       inzone = { 1'd0, vrender[7:0] } >=top && bottom>vrender[7:0];

initial zoom = 0;

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        cur_obj   <= 0;
        st        <= 0;
        tbl_we    <= 0;
        stop      <= 0;

        dr_start  <= 0;
        dr_xpos   <= 0;
        dr_offset <= 0;
        dr_bank   <= 0;
        dr_prio   <= 0;
        dr_pal    <= 0;
    end else begin
        idx <= idx>=LAST_IDX ? 3'd7 : (idx + 3'd1); // 7 is the scratch location
        if( !stop ) begin
            st <= st+1'd1;
        end
        stop     <= 0;
        dr_start <= 0;
        tbl_we   <= 0;
        case( st )
            default: begin
                cur_obj  <= 0;
                stop     <= 0;
                dr_start <= 0;
                if( !hstart || vrender>223 ) begin // holds the state
                    st  <= 0;
                    idx <= 0;
                end
            end
            1: if( !stop ) begin
                top     <= tbl_dout[ 8:0] ^ 9'h100;
                visible <= !tbl_dout[14] && !tbl_dout[12];
                bank <= tbl_dout[11:9];
                if( tbl_dout[15] ) begin
                    st <= 0; // Done
                end else begin // draw this one
                    first <= top == vrender[8:0]; // first line
                end
            end
            2: begin
                offset <= tbl_dout;
            end
            3: begin
                pitch <= { {9{tbl_dout[15]}}, tbl_dout[15:9]};
                xpos  <= tbl_dout[8:0];
            end
            4: begin
                shadow <= tbl_dout[14];
                prio   <= tbl_dout[13:12];
                vzoom  <= tbl_dout[9:0];
            end
            5: begin
                vflip  <= tbl_dout[15];
                hflipb <= tbl_dout[14];
                //  <= tbl_dout[13]; // flip what?
                hzoom  <= tbl_dout[9:0];
            end
            6: begin
                if( vflip ) begin
                    top    <= endline;
                    bottom <= top;
                end else begin
                    bottom <= endline;
                end
                pal    <= tbl_dout[6:0];
            end
            7: begin
                if( !visible || top > vrender || bottom < vrender ) begin // skip this sprite
                    cur_obj <= cur_obj + 1'd1;
                    idx     <= 0;
                    st      <= 1;
                    stop    <= 1;
                    if( &cur_obj )
                        st <= 0; // we're done
                end
            //     zoom <= next_zoom;
            end
            8: begin
                offset   <= next_offset;
                tbl_we   <= 1;
                zoom_sel <= 0;
            end
            // 9: begin
            //     tbl_we  <= 1;
            //     zoom_sel<= 1;
            //     idx     <= 5;
            // end
            10: begin
                if( !dr_busy ) begin
                    dr_xpos   <= xpos; //+PXL_DLY;
                    dr_offset <= offset;
                    dr_pal    <= pal;
                    dr_prio   <= prio;
                    dr_start  <= 1;
                    dr_hflipb <= hflipb;
                    dr_hzoom  <= hzoom;
                    dr_bank   <= bank;
                    // next
                    if( &cur_obj )
                        st <= 0; // Done
                    else begin
                        cur_obj <= cur_obj + 1'd1;
                        idx     <= 0;
                        st      <= 1;
                        stop    <= 1;
                    end
                end else begin
                    if(!hstart) st <= st;
                end
            end
        endcase
    end
end

endmodule