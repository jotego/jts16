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

module jts16_obj_draw(
    input              rst,
    input              clk,

    // From scan
    input              start,
    output reg         busy,
    input      [ 8:0]  xpos,
    input      [15:0]  offset,  // MSB is also used as the flip bit
    input      [ 2:0]  bank,
    input      [ 1:0]  prio,
    input      [ 5:0]  pal,

    // SDRAM interface
    input              obj_ok,
    output reg         obj_cs,
    output reg [17:0]  obj_addr, // 3 bank + 15 offset = 18
    input      [15:0]  obj_data,

    // Buffer
    output     [11:0]  bf_data,
    output reg         bf_we,
    output reg [ 8:0]  bf_addr
);

reg [15:0] pxl_data;
reg [ 3:0] cnt;
reg        draw, stop;

assign bf_data = { prio, pal, pxl_data[15:12] };

// ignoring h-flip for now
always @(posedge clk, posedge rst) begin
    if( rst ) begin
        busy   <= 0;
        draw   <= 0;
        obj_cs <= 0;
        bf_we  <= 0;
    end else begin
        if( start ) begin
            obj_addr <= { bank[1:0], bank[2], offset[14:0] };
            obj_cs   <= 1;
            busy     <= 1;
            draw     <= 0;
            bf_we    <= 0;
            stop     <= 1;
            bf_addr  <= xpos;
        end else begin
            bf_we <= 0;
            stop  <= 0;
            if( busy ) begin
                if( draw ) begin
                    cnt <= cnt<<1;
                    if(cnt[3]) begin
                        draw<= 0;
                        if( &pxl_data[15:12] )
                            busy <= 0;  // done
                    end
                    pxl_data <= pxl_data<<4;
                    bf_addr  <= bf_addr+1;
                    bf_we    <= 1;
                end else begin
                    if( obj_cs && obj_ok && !stop ) begin
                        // Draw pixels
                        pxl_data <= obj_data;
                        cnt[0]   <= 1;
                        draw     <= 1;
                        obj_cs   <= 0;
                    end else begin
                        obj_addr[14:0] <= obj_addr[14:0] + 1;   // obey the bank limit
                        obj_cs   <= 1;
                        stop     <= 1;
                    end
                end
            end
        end
    end
end

endmodule