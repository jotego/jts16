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
    Date: 12-3-2021 */

module jts16_obj_scan(
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
    output reg [ 3:0]  dr_bank,
    output reg [ 1:0]  dr_prio,
    output reg [ 5:0]  dr_pal,
    output reg [ 9:0]  dr_zoom,
    output reg         dr_hflipb,

    // Video signal
    input              flip,
    input              hstart,
    input      [ 8:0]  vrender
);

parameter [8:0] PXL_DLY=8;
parameter       MODEL=0;  // 0 = S16A, 1 = S16B

localparam LAST_IDX = MODEL ? 5 : 4;
localparam STW = MODEL ? 4 : 3;
localparam ST_SCRATCH = MODEL ? 7 : 6,
           ST_DRAW    = MODEL ? 8 : 7;

reg  [6:0] cur_obj;  // current object
reg  [2:0] idx;
reg  [STW-1:0] st;
reg  [9:0] zoom;
reg        first, stop;

// Object data
//reg        [7:0] bottom, top;
reg        [ 8:0] xpos;
reg signed [15:0] pitch;
reg        [15:0] offset; // MSB is also used as the flip bit
reg        [ 3:0] bank;
reg        [ 1:0] prio;
reg        [ 5:0] pal;
reg               hflipb; // H flip bit for S16B
wire       [15:0] next_offset;
wire       [ 8:0] vrf = flip ? 9'd223-vrender : vrender;

assign tbl_addr    = { cur_obj, idx };
assign next_offset = (first ? offset : tbl_dout) + pitch;
assign tbl_din     = offset;

wire [7:0] top    = tbl_dout[ 7:0],
           bottom = tbl_dout[15:8];
wire       inzone = vrf[7:0]>=top && bottom>vrf[7:0];
wire       badobj = top >= bottom;

`ifndef S16B
    initial zoom = 0;
`endif


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
        if( idx<7 ) idx <= idx==LAST_IDX ? 7 : (idx + 3'd1); // 7 is the scratch location
        if( !stop ) begin
            st <= st+1'd1;
        end
        stop      <= 0;
        dr_start  <= 0;
        case( st )
            0: begin
                cur_obj  <= 0;
                stop     <= 0;
                dr_start <= 0;
                if( !hstart || vrf>223 ) begin // holds it still
                    st  <= 0;
                    idx <= 0;
                end
            end
            1: begin
                if( !stop ) begin
                    if( bottom>=8'hf0 ) begin
                        st <= 0; // Done
                    end else if( !inzone || badobj ) begin
                        // Next object
                        cur_obj <= cur_obj + 1'd1;
                        idx     <= 0;
                        st      <= 1;
                        stop    <= 1;
                    end else begin // draw this one
                        first <= top == vrf[7:0]; // first line
                    end
                end
            end
            2: xpos <= tbl_dout[8:0];
            3: begin
                pitch <= MODEL ? { {8{tbl_dout[7]}}, tbl_dout[7:0]} : tbl_dout;
                hflipb<= tbl_dout[8];
            end
            4: begin
                offset  <= tbl_dout; // flip/offset
            end
            5: begin
                if (MODEL) begin
                    pal  <= tbl_dout[5:0];
                    bank <= tbl_dout[11:8];
                    prio <= tbl_dout[7:6];
                end else begin
                    pal  <= tbl_dout[13:8];
                    bank <= {1'b0, tbl_dout[6:4] };
                    prio <= tbl_dout[1:0];
                end
            end
            `ifdef S16B
            6: begin
                zoom <= tbl_dout[9:0];
            end
            `endif
            ST_SCRATCH: begin
                offset <= next_offset;
                tbl_we <= 1;
            end
            ST_DRAW: begin
                tbl_we  <= 0;
                if( !dr_busy ) begin
                    dr_xpos   <= xpos; //+PXL_DLY;
                    dr_offset <= offset;
                    dr_pal    <= pal;
                    dr_prio   <= prio;
                    dr_bank   <= bank;
                    dr_start  <= 1;
                    dr_hflipb <= hflipb;
                    dr_zoom   <= zoom;
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
                    if(!hstart) st <= ST_DRAW;
                end
            end
        endcase
    end
end

endmodule