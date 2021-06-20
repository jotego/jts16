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
    Date: 16-6-2021 */

module jts16_fd1094(
    input             rst,
    input             clk,

    // Configuration
    input      [12:0] prog_addr,
    input             fd1094_we,
    input      [ 7:0] prog_data,

    // Operation
    input             dec_en,
    input             vrq,      // vector request
    input      [ 7:0] st,       // state

    input             op_n,     // OP (0) or data (1)
    input      [23:1] addr,
    input      [15:0] enc,
    output     [15:0] dec,

    input             rom_ok,
    output            ok_dly
);

`define BITSWAP( v, b15, b14, b13, b12, b11, b10, b9, b8, b7, b6, b5, b4, b3, b2, b1, b0 ) { \
    v[b15], v[b14], v[b13], v[b12], v[b11], v[b10], v[b9], v[b8], \
    v[b7],  v[b6],  v[b5],  v[b4],  v[b3],  v[b2],  v[b1], v[b0] }

reg [7:0] gkey1, gkey2, gkey3;
reg [7:0] gkey1_st, gkey2_st, gkey3_st;

wire [ 7:0] xor_mask1, xor_mask2, xor_mask3, mainkey;
reg  [12:0] key_addr;
reg         key_F;
reg  [15:0] val;

assign dec = op_n ? enc : val;

assign xor_mask1 = { st[2], st[4], st[3], st[6],
                     st[5], st[0], st[4], st[1]};

assign xor_mask2 = { st[0], st[2], st[6], st[1],
                     st[4], st[6], st[3], st[7]};

assign xor_mask3 = { st[0], st[7], st[3], st[5],
                     st[5], st[2], st[7], st[1]};

wire global_xor0         = ~gkey1_st[5];
wire global_xor1         = ~gkey1_st[2];
wire global_swap2        = ~gkey1_st[0];

wire global_swap0a       = ~gkey2_st[5];
wire global_swap0b       = ~gkey2_st[2];

wire global_swap3        = ~gkey3_st[6];
wire global_swap1        = ~gkey3_st[4];
wire global_swap4        = ~gkey3_st[2];

wire key_0a = mainkey[0] ^ gkey3_st[1];
wire key_0b = mainkey[0] ^ gkey1_st[7];
wire key_0c = mainkey[0] ^ gkey1_st[1];

wire key_1a = mainkey[1] ^ gkey2_st[7];
wire key_1b = mainkey[1] ^ gkey1_st[3];

wire key_2a = mainkey[2] ^ gkey3_st[7];
wire key_2b = mainkey[2] ^ gkey1_st[4];

wire key_3a = mainkey[3] ^ gkey2_st[0];
wire key_3b = mainkey[3] ^ gkey3_st[3];

wire key_4a = mainkey[4] ^ gkey2_st[3];
wire key_4b = mainkey[4] ^ gkey3_st[0];

wire key_5a = mainkey[5] ^ gkey3_st[5];
wire key_5b = mainkey[5] ^ gkey1_st[6];

wire key_6a = mainkey[6] ^ gkey2_st[1];
wire key_6b = mainkey[6] ^ gkey2_st[6];

wire key_7a = mainkey[7] ^ gkey2_st[4];

always @(posedge clk) begin
    if( fd1094_we && prog_addr<4 ) begin
        case( prog_addr[1:0] )
            1: gkey1 <= prog_data;
            2: gkey2 <= prog_data;
            3: gkey3 <= prog_data;
        endcase
        `ifdef SIMULATION
        $display("global key %d = %X",prog_addr, prog_data);
        `endif
    end
end

always @(*) begin
    key_addr = addr[13:1];
    if ((addr[16:1] & 16'h0ffc) == 0 && addr >= 4)
        key_addr[12] = 1;
    key_F = addr[13] ? mainkey[7] : mainkey[6];

    gkey1_st = gkey1 ^ xor_mask1;
    gkey2_st = gkey2 ^ xor_mask2;
    gkey3_st = gkey3 ^ xor_mask3;

    if( vrq ) begin
        if( addr <= 3 ) gkey3_st = 0;
        if( addr <= 2 ) gkey2_st = 0;
        if( addr <= 1 ) gkey1_st = 0;
        if( addr <= 1 ) key_F = 0;
    end
end

`ifdef SIMULATION
always @(mainkey) begin
    $display("mainkey = %X",mainkey);
end
`endif

// decoding, pretty much copy-paste from MAME's fd1094.cpp
// I trust the synthesizer to simplify the equations
always @(*) begin
    val=enc;
    if (val[15] ) begin
        val = `BITSWAP(val, 15, 9,10,13, 3,12, 0,14, 6, 5, 2,11, 8, 1, 4, 7);

        if (!global_xor1)   if (~val[11] /*& 16'h0800*/)  val ^= 16'h3002;                                      // 1,12,13
                            if (~val[ 5] /*& 16'h0020*/)  val ^= 16'h0044;                                      // 2,6
        if (!key_1b)        if (~val[10] /*& 16'h0400*/)  val ^= 16'h0890;                                      // 4,7,11
        if (!global_swap2)  if (!key_0c)        val ^= 16'h0308;                                      // 3,8,9
                                                val ^= 16'h6561;

        if (!key_2b)        val = `BITSWAP(val,15,10,13,12,11,14,9,8,7,6,0,4,3,2,1,5);             // 0-5, 10-14
    end
    $display("Check point 0: %X (%d,%d,%d,%d)",val, global_xor1, key_1b, global_swap2, key_2b);
    if (val[14] ) begin
        val = `BITSWAP(val, 13,14, 7, 0, 8, 6, 4, 2, 1,15, 3,11,12,10, 5, 9);

        if (!global_xor0)   if (val[4] /*& 16'h0010*/)   val ^= 16'h0468;                                      // 3,5,6,10
        if (!key_3a)        if (val[8] /*& 16'h0100*/)   val ^= 16'h0081;                                      // 0,7
        if (!key_6a)        if (val[2] /*& 16'h0004*/)   val ^= 16'h0100;                                      // 8
        if (!key_5b)        if (!key_0b)        val ^= 16'h3012;                                      // 1,4,12,13
                                                val ^= 16'h3523;

        if (!global_swap0b) val = `BITSWAP(val, 2,14,13,12, 9,10,11, 8, 7, 6, 5, 4, 3,15, 1, 0);   // 2-15, 9-11
    end

    if (val[13] ) begin     // block invariant: val & 16'h2000 != 0
        val = `BITSWAP(val, 10, 2,13, 7, 8, 0, 3,14, 6,15, 1,11, 9, 4, 5,12);

        if (!key_4a)        if (val[11] /*& 16'h0800*/)   val ^= 16'h010c;                                      // 2,3,8
        if (!key_1a)        if (val[ 7] /*& 16'h0080*/)   val ^= 16'h1000;                                      // 12
        if (!key_7a)        if (val[10] /*& 16'h0400*/)   val ^= 16'h0a21;                                      // 0,5,9,11
        if (!key_4b)        if (!key_0a)        val ^= 16'h0080;                                      // 7
        if (!global_swap0a) if (!key_6b)        val ^= 16'hc000;                                      // 14,15
                                                val ^= 16'h99a5;

        if (!key_5b)        val = `BITSWAP(val,15,14,13,12,11, 1, 9, 8, 7,10, 5, 6, 3, 2, 4, 0);   // 1,4,6,10
    end

    if (val[15:13]!=0 ) begin
        val = `BITSWAP(val,15,13,14, 5, 6, 0, 9,10, 4,11, 1, 2,12, 3, 7, 8);

        val ^= 16'h17ff;

        if (!global_swap4)  val = `BITSWAP(val, 15,14,13, 6,11,10, 9, 5, 7,12, 8, 4, 3, 2, 1, 0);  // 5-8, 6-12
        if (!global_swap3)  val = `BITSWAP(val, 13,15,14,12,11,10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0);  // 15-14-13
        if (!global_swap2)  val = `BITSWAP(val, 15,14,13,12,11, 2, 9, 8,10, 6, 5, 4, 3, 0, 1, 7);  // 10-2-0-7
        if (!key_3b)        val = `BITSWAP(val, 15,14,13,12,11,10, 4, 8, 7, 6, 5, 9, 1, 2, 3, 0);  // 9-4, 3-1
        if (!key_2a)        val = `BITSWAP(val, 13,14,15,12,11,10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0);  // 13-15

        if (!global_swap1)  val = `BITSWAP(val, 15,14,13,12, 9, 8,11,10, 7, 6, 5, 4, 3, 2, 1, 0);  // 11...8
        if (!key_5a)        val = `BITSWAP(val, 15,14,13,12,11,10, 9, 8, 4, 5, 7, 6, 3, 2, 1, 0);  // 7...4
        if (!global_swap0a) val = `BITSWAP(val, 15,14,13,12,11,10, 9, 8, 7, 6, 5, 4, 0, 3, 2, 1);  // 3...0
    end

    val = `BITSWAP(val, 12,15,14,13,11,10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0);

    if ((val & 16'hb080) == 16'h8000) val ^= 16'h4000;
    if ((val & 16'hf000) == 16'hc000) val ^= 16'h0080;
    if ((val & 16'hb100) == 16'h0000) val ^= 16'h4000;
end

jtframe_prom #(.aw(13),.simfile("fd1094.bin")) u_lut(
    .clk    ( clk            ),
    .cen    ( 1'b1           ),
    .data   ( prog_data      ),
    .rd_addr( key_addr       ),
    .wr_addr( prog_addr      ),
    .we     ( fd1094_we      ),
    .q      ( mainkey        )
);

`undef BITSWAP

endmodule