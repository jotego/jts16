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
    Date: 20-3-2021 */

module jts16_fd1089(
    input               rst,
    input               clk,

    // NVRAM
    input         [12:0] prog_addr,
    input                prom_we,
    input                fd1089_we,
    input         [ 7:0] prog_data,

    input               op_n,     // OP (0) or data (1)
    input      [23:0]   addr,
    input      [15:0]   enc,
    output reg [15:0]   dec
);

reg  [ 7:0] encbyte, decbyte, last_dout, last_in, val_a;
reg  [ 3:0] family;
reg  [12:0] lut_a;
wire [ 7:0] shkey, preval;
reg  [ 7:0] key, lut2_addr;
wire [ 7:0] second[0:15];
wire [ 7:0] last[0:15];

`define SWAPBYTES( v, b7, b6, b5, b4, b3, b2, b1, b0 ) {v[b7], v[b6], v[b5], v[b4], v[b3], v[b2], v[b1], v[b0] };

// Common to 1089A and 1089B
assign second[ 0] = 8'h23 ^ `SWAPBYTES( encbyte, 6,4,5,7,3,0,1,2 );
assign second[ 1] = 8'h92 ^ `SWAPBYTES( encbyte, 2,5,3,6,7,1,0,4 );
assign second[ 2] = 8'hb8 ^ `SWAPBYTES( encbyte, 6,7,4,2,0,5,1,3 );
assign second[ 3] = 8'h74 ^ `SWAPBYTES( encbyte, 5,3,7,1,4,6,0,2 );
assign second[ 4] = 8'hcf ^ `SWAPBYTES( encbyte, 7,4,1,0,6,2,3,5 );
assign second[ 5] = 8'hc4 ^ `SWAPBYTES( encbyte, 3,1,6,4,5,0,2,7 );
assign second[ 6] = 8'h51 ^ `SWAPBYTES( encbyte, 5,7,2,4,3,1,6,0 );
assign second[ 7] = 8'h14 ^ `SWAPBYTES( encbyte, 7,2,0,6,1,3,4,5 );
assign second[ 8] = 8'h7f ^ `SWAPBYTES( encbyte, 3,5,6,0,2,1,7,4 );
assign second[ 9] = 8'h03 ^ `SWAPBYTES( encbyte, 2,3,4,0,6,7,5,1 );
assign second[10] = 8'h96 ^ `SWAPBYTES( encbyte, 3,1,7,5,2,4,6,0 );
assign second[11] = 8'h30 ^ `SWAPBYTES( encbyte, 7,6,2,3,0,4,5,1 );
assign second[12] = 8'he2 ^ `SWAPBYTES( encbyte, 1,0,3,7,4,5,2,6 );
assign second[13] = 8'h72 ^ `SWAPBYTES( encbyte, 1,6,0,5,7,2,4,3 );
assign second[14] = 8'hf5 ^ `SWAPBYTES( encbyte, 0,4,1,2,6,5,7,3 );
assign second[15] = 8'h5b ^ `SWAPBYTES( encbyte, 0,7,5,3,1,4,2,6 );

assign last[ 0] = 8'h55 ^ `SWAPBYTES( last_in, 6,5,1,0,7,4,2,3 );
assign last[ 1] = 8'h94 ^ `SWAPBYTES( last_in, 7,6,4,2,0,5,1,3 );
assign last[ 2] = 8'h8d ^ `SWAPBYTES( last_in, 1,4,2,3,0,6,7,5 );
assign last[ 3] = 8'h9a ^ `SWAPBYTES( last_in, 4,3,5,6,0,2,1,7 );
assign last[ 4] = 8'h72 ^ `SWAPBYTES( last_in, 4,3,7,0,5,6,1,2 );
assign last[ 5] = 8'hff ^ `SWAPBYTES( last_in, 1,7,2,3,6,4,5,0 );
assign last[ 6] = 8'h06 ^ `SWAPBYTES( last_in, 6,5,3,2,4,1,0,7 );
assign last[ 7] = 8'hc5 ^ `SWAPBYTES( last_in, 3,5,1,4,2,7,0,6 );
assign last[ 8] = 8'hec ^ `SWAPBYTES( last_in, 4,7,5,1,6,0,2,3 );
assign last[ 9] = 8'h89 ^ `SWAPBYTES( last_in, 3,5,0,6,1,2,7,4 );
assign last[10] = 8'h5c ^ `SWAPBYTES( last_in, 1,3,0,7,5,2,4,6 );
assign last[11] = 8'h3f ^ `SWAPBYTES( last_in, 7,3,0,2,4,6,1,5 );
assign last[12] = 8'h57 ^ `SWAPBYTES( last_in, 6,4,7,2,1,5,3,0 );
assign last[13] = 8'hf7 ^ `SWAPBYTES( last_in, 6,3,7,0,5,4,2,1 );
assign last[14] = 8'h3a ^ `SWAPBYTES( last_in, 6,1,3,2,7,4,5,0 );
assign last[15] = 8'hac ^ `SWAPBYTES( last_in, 1,6,3,5,0,7,4,2 );

always @(*) begin
    // LUT Address
    lut_a = {
        op_n,
        addr[23:16],
        addr[9],
        addr[5],
        addr[3],
        addr[0]
    };
    // Encoded byte
    encbyte = {
        enc[15:10],
        enc[6],
        enc[3]
    };
    // Decoded data
    dec        = enc;
    dec[15:10] = decbyte[7:2];
    dec[6]     = decbyte[1];
    dec[3]     = decbyte[0];
end


always @(*) begin
    key = shkey;
    // unshuffle the key
    if( op_n ) begin // not an OP
        key[5:4] = ~key[5:4];

        if(!key[3])
            key[1] = ~key[1];
        key = `SWAPBYTES( key,1,0,6,4,3,5,2,7 );

        if(key[6])
            key = `SWAPBYTES( key,7,6,2,4,5,3,1,0 );
    end else begin // an OP
        key[4:2] = ~key[4:2];

        if( !key[3] )
            key[5] = ~key[5];

        if( key[7] )
            key[6] = ~key[6];

        key = `SWAPBYTES( key,5,7,6,4,2,3,1,0 );

        if(key[6])
            key = `SWAPBYTES( key,7,6,5,3,2,4,1,0 );
    end

    if( key[6] )
        if( key[5] )
            key[4] = ~key[4];
    else
        if( !key[4] )
            key[5] = ~key[5];
    // Second LUT address
    lut2_addr = second[ key[7:4] ];
    if( key[3] ) lut2_addr[0] = ~lut2_addr[0];
    if( key[0] ) lut2_addr = lut2_addr ^ 8'hb1;
    if( !op_n )
        lut2_addr = lut2_addr ^ 8'h34;
    else
        lut2_addr[0] = lut2_addr[0] ^ key[6];
end

// FD1089A variant
always @(*) begin
    family = {1'b0,key[2:0]};
    if( op_n ) begin
        if( !key[6] & key[2] ) family[3] = ~family[3];
        if(  key[4] ) family[3] = ~family[3];
    end else begin
        if( key[6] & key[2] ) family[3] = ~family[3];
        if( key[5] ) family[3] = ~family[3];
    end

    last_in = preval;
    if( key[0] ) begin
        if( last_in[0] ) last_in[7:6] = ~last_in[7:6];
        if(!last_in[6] ^ last_in[4] )
            last_in=`SWAPBYTES(last_in,7,6,5,4,1,0,2,3);
    end else begin
        if( ~last_in[6] ^ last_in[4] )
            last_in=`SWAPBYTES(last_in, 7,6,5,4,0,1,3,2);
    end
    if( !last_in[6] )
        last_in = `SWAPBYTES(last_in, 7,6,5,4,2,3,0,1);
    val_a = last[ family ];
end

jtframe_prom #(.aw(13),.simfile("317-5021.key")) u_key(
    .clk    ( clk       ),
    .cen    ( 1'b1      ),
    .data   ( prog_data ),
    .rd_addr( lut_a     ),
    .wr_addr( prog_addr ),
    .we     ( prom_we   ),
    .q      ( shkey     )
);

jtframe_prom #(.aw(8),.simfile("fd1089.bin")) u_lut(
    .clk    ( clk            ),
    .cen    ( 1'b1           ),
    .data   ( prog_data      ),
    .rd_addr( lut2_addr      ),
    .wr_addr( prog_addr[7:0] ),
    .we     ( fd1089_we      ),
    .q      ( preval         )
);

`undef SWAPBYTES

endmodule

