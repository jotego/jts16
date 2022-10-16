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
    Date: 15-10-2022 */

module jtoutrun_obj_draw(
    input              rst,
    input              clk,
    input              hstart,
    // From scan
    input              start,
    output reg         busy,
    input      [ 8:0]  xpos,
    input      [15:0]  offset,  // MSB is also used as the flip bit
    input      [ 2:0]  bank,
    input      [ 1:0]  prio,
    input              shadow,
    input      [ 6:0]  pal,
    input      [ 4:0]  hzoom,
    input              hflip,
    input              backwd,

    // SDRAM interface
    input              obj_ok,
    output reg         obj_cs,
    output     [19:2]  obj_addr, // All games have 1MB max ROM for objects
    input      [31:0]  obj_data,

    // Buffer
    output     [13:0]  bf_data,
    output reg         bf_we,
    output reg [ 8:0]  bf_addr,
    input      [ 7:0]  debug_bus
);

reg  [31:0] pxl_data;
reg  [15:0] cur;
reg  [ 3:0] cnt;
reg         draw, halted, last_data;
wire [ 3:0] cur_pxl, nxt_pxl;
reg  [ 5:0] hzacc;
wire [ 6:0] hzsum;
wire        hzov;

assign cur_pxl  = hflip ? pxl_data[3:0] : pxl_data[31-:4];
assign nxt_pxl  = hflip ? pxl_data[7:4] : pxl_data[(31-4)-:4];
assign obj_addr = { bank[1:0], cur };
assign bf_data  = { pal, shadow, prio, cur_pxl }; // 14 bits,

// Sprite scaling
assign hzsum = {1'b0, hzacc} + {2'd0, hzoom};
assign hzov  = hzsum[6];

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        busy   <= 0;
        draw   <= 0;
        obj_cs <= 0;
        bf_we  <= 0;
        cur    <= 0;
    end else begin
        if( hstart ) begin
            busy <= 0;
            draw <= 0;
        end else
        if( start ) begin
            cur      <= offset;
            obj_cs   <= 1;
            busy     <= 1;
            draw     <= 0;
            bf_we    <= 0;
            halted   <= 1;
            bf_addr  <= xpos;
            hzacc    <= { hzoom[3:0], 2'd0 };
        end else begin
            bf_we <= 0;
            if(obj_ok) halted <= 0;
            if( busy ) begin
                if( draw ) begin
                    if( !obj_cs ) begin // request the next 8 pixels from the SDRAM
                        cur    <= cur + (hflip ? -16'd1 : 16'd1);
                        obj_cs <= 1;
                        halted <= 1;
                    end
                    cnt <= cnt + 1'b1;
                    hzacc <= hzsum[5:0];
                    if( cnt==7 ) last_data <= &cur_pxl;
                    if(cnt[3]) begin
                        draw  <= 0;
                        bf_we <= 0;
                        if( last_data )
                            busy <= 0;  // done
                    end else begin
                        bf_we    <= ~hzov & ~&nxt_pxl;
                    end
                    pxl_data <= hflip ? pxl_data>>4 : pxl_data<<4;
                    if( !hzov ) bf_addr <= bf_addr + { {8{backwd}}, 1'd1 }; // if backwd, then -1; else +1
                end else if(!halted) begin
                    if( obj_cs && obj_ok ) begin
                        // Get new data
                        pxl_data <= obj_data;
                        bf_we    <= ~&(hflip ? obj_data[3:0] : obj_data[31-:4]); // $F must not be drawn
                        cnt      <= 1;
                        draw     <= 1;
                        obj_cs   <= 0;
                    end
                end
            end
        end
    end
end

endmodule