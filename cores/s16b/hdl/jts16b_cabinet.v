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
    Date: 30-10-2021 */

module jts16b_cabinet(
    input             rst,
    input             clk,
    input             LHBL,
    input      [ 7:0] game_id,

    // CPU
    input      [23:1] A,
    input      [15:0] cpu_dout,
    input             LDSWn,
    input             UDSWn,
    input             io_cs,

    // DIP switches
    input             dip_test,
    input      [ 7:0] dipsw_a,
    input      [ 7:0] dipsw_b,

    // cabinet I/O
    input      [ 7:0] joystick1,
    input      [ 7:0] joystick2,
    input      [ 7:0] joystick3,
    input      [ 7:0] joystick4,
    input      [15:0] joyana1,
    input      [15:0] joyana2,
    input      [15:0] joyana3,
    input      [15:0] joyana4,
    input      [ 3:0] start_button,
    input      [ 3:0] coin_input,
    input             service,

    output     [ 7:0] sys_inputs,
    output reg [ 7:0] cab_dout,
    output reg        flip,
    output reg        video_en
);

localparam [7:0] GAME_SDI=1,
                 GAME_PASSSHT=2,
                 GAME_BULLET=8'h11,
                 GAME_PASSSHT2='h13,
                 GAME_DUNKSHOT='h14,
                 GAME_PASSSHT3='h18;

reg  game_passsht, game_dunkshot, game_bullet;

// Game ID registers
always @(posedge clk) begin
    game_passsht  <= game_id==GAME_PASSSHT2 || game_id==GAME_PASSSHT3 || game_id==GAME_PASSSHT;
    game_dunkshot <= game_id==GAME_DUNKSHOT;
    game_bullet   <= game_id==GAME_BULLET;
end

reg [ 7:0] sort1, sort2, sort3;
reg        last_iocs;

wire [7:0] sort1_bullet, sort2_bullet, sort3_bullet,
           sort_dunkshot;

assign sort1_bullet = { sort1[3:0], sort1[7:4] };
assign sort2_bullet = { sort2[3:0], sort2[7:4] };
assign sort3_bullet = { sort3[3:0], sort3[7:4] };
assign sort_dunkshot= { joystick4[5:4], joystick3[5:4], joystick2[5:4], joystick1[5:4] };

function [7:0] sort_joy( input [7:0] joy_in );
    sort_joy = { joy_in[1:0], joy_in[3:2], joy_in[7], joy_in[5:4], joy_in[6] };
endfunction

always @(*) begin
    sort1 = sort_joy( joystick1 );
    sort2 = sort_joy( joystick2 );
    sort3 = sort_joy( joystick3 );
end

wire [8:0] joyana_sum = {joyana1[15], joyana1[15:8]} + {joyana2[15], joyana2[15:8]};
reg  [7:0] ana_in;
assign sys_inputs = { 2'b11, start_button[1:0], service, dip_test, coin_input[1:0] };

function [7:0] pass_joy( input [7:0] joy_in );
    pass_joy = { joy_in[7:4], joy_in[1:0], joy_in[3:2] };
endfunction

function [7:0] dunkshot_joy( input [11:0] tb );
    dunkshot_joy = !A[1] ? tb[7:0] : {4'd0,tb[11:8]};
endfunction

function [11:0] extjoy( input [7:0] ja );
    extjoy = { {8{ja[7]}}, ja[6:3] };
endfunction

reg  [11:0] trackball[0:7];
reg         LHBLl;
reg  [ 5:0] hcnt;

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        hcnt <= 0;
        trackball[0] <= 12'h10a;
        trackball[1] <= 12'h20b;
        trackball[2] <= 12'h30c;
        trackball[3] <= 12'h40d;
        trackball[4] <= 12'h50e;
        trackball[5] <= 12'h60f;
        trackball[6] <= 12'h701;
        trackball[7] <= 12'h802;
    end else begin
        LHBLl <= LHBL;
        if( !LHBL && LHBLl ) begin
            hcnt<=hcnt+1;
            if( hcnt==0 ) begin
                trackball[0] <= trackball[0] - extjoy( joyana1[ 7:0] );
                trackball[1] <= trackball[1] + extjoy( joyana1[15:8] );
                trackball[2] <= trackball[2] - extjoy( joyana2[ 7:0] );
                trackball[3] <= trackball[3] + extjoy( joyana2[15:8] );
                trackball[4] <= trackball[4] - extjoy( joyana3[ 7:0] );
                trackball[5] <= trackball[5] + extjoy( joyana3[15:8] );
                trackball[6] <= trackball[6] - extjoy( joyana4[ 7:0] );
                trackball[7] <= trackball[7] + extjoy( joyana4[15:8] );
            end
        end
    end
end

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        cab_dout  <= 8'hff;
        flip      <= 0;
        video_en  <= 1;
    end else begin
        last_iocs <= io_cs;
        cab_dout  <= 8'hff;
        if(io_cs) case( A[13:12] )
            0: if( !LDSWn ) begin
                flip     <= cpu_dout[6];
                video_en <= cpu_dout[5];
            end
            1:
                case( A[2:1] )
                    0: begin
                        cab_dout <= sys_inputs;
                        if( game_bullet ) begin
                            cab_dout[7] <= coin_input[2];
                            cab_dout[6] <= start_button[2];
                        end
                        if( game_passsht | game_dunkshot )  begin
                            cab_dout[7:6] <= start_button[3:2];
                        end
                    end
                    1: begin
                        cab_dout <= game_bullet ? sort1_bullet :
                            game_dunkshot ? sort_dunkshot :
                            sort1;
                    end
                    2: begin
                        if ( game_bullet ) cab_dout <= sort3_bullet;
                    end
                    3: begin
                        cab_dout <= game_bullet ? sort2_bullet : sort2;
                    end
                endcase
            2: cab_dout <= { A[1] ? dipsw_a : dipsw_b };
            3: begin // custom inputs
                case( game_id )
                    1: begin // Heavy Champion
                        if( A[9:8]==2 ) begin
                            cab_dout <= { 7'd0, ana_in[7] };
                            if (!LDSWn || !UDSWn) begin // load value in shift reg
                                case( A[2:1])
                                    0: ana_in <= 8'h00; //joyana_sum[8:1];
                                    1: ana_in <= 8'h11; //joyana1[15:8];
                                    2: ana_in <= 8'h22; //joyana2[15:8];
                                    3: ana_in <= 8'h33; //8'hff;
                                endcase
                            end else begin
                                if(!last_iocs) begin // read value
                                    ana_in <= ana_in << 1;
                                end
                            end
                        end
                        // A[9:8]==3, bits 7:5 control the lamps, bit 4 is the bell
                    end
                    8'h13: begin // Passing Shot (J)
                        if( A[9:8]== 2'b10 ) begin
                            case( A[2:1] )
                                0: cab_dout <= pass_joy( joystick1 );
                                1: cab_dout <= pass_joy( joystick2 );
                                2: cab_dout <= pass_joy( joystick3 );
                                3: cab_dout <= pass_joy( joystick4 );
                            endcase
                        end
                    end
                    GAME_DUNKSHOT: begin
                        cab_dout <= dunkshot_joy( trackball[A[4:2]] );
                    end
                    8'h12,8'h19: begin // SDI / Defense
                        if( A[9:8]== 2'b10 ) begin
                            case( A[2:1] )
                                // 1P
                                0: cab_dout <= joyana1[15:8];
                                1: cab_dout <= joyana2[15:8];
                                // 2P
                                2: cab_dout <= joyana3[15:8];
                                3: cab_dout <= joyana4[15:8];
                            endcase
                        end
                    end
                endcase
            end
        endcase
    end
end

endmodule