`timescale 1ns / 1ps

module md5( 
    input clk,
    input reset_n,
    input enable,
    input [127:0] passwd_hash,
    
    input [63:0] pattern,
    //output [6:0] counter_out,
    output valid,
    output get_answer,
    output reg [63:0] answer
);
localparam [3:0] S_IDLE = 0, S_INIT = 1, S_ASSIGN_W = 2, S_MAIN_LOOP_A = 3, S_MAIN_LOOP_C = 4, S_ADD_C = 5, S_ADD_HASH = 6, S_MAIN_DONE = 7, S_IS_ANS = 8, S_MAIN_LOOP_B = 9, S_MAIN_LOOP_B_2 = 10;
localparam [63:0] bits_len = 64;
localparam pad_len = 56;
reg [3:0] P, P_next;
reg [31:0] r[0:63];
reg [31:0] k[0:63];
reg [31:0] sr[0:63];
reg [7:0] msg [0:127];

reg [31:0] h0, h1, h2, h3;
reg [31:0] a,b,c,d,f,g,f1,f2, c5, c3, c7;
reg [31:0] w [0:15];
reg [127:0] cmp_hash;
reg [6:0] counter;
reg done_prepare, done_add;
integer i;
//assign counter_out = counter;
always@(posedge clk) begin
    if(P == S_IDLE) begin
       {r[ 0], r[ 1], r[ 2], r[ 3], r[ 4], r[ 5], r[ 6], r[ 7], 
        r[ 8], r[ 9], r[10], r[11], r[12], r[13], r[14], r[15], 
        r[16], r[17], r[18], r[19], r[20], r[21], r[22], r[23], 
        r[24], r[25], r[26], r[27], r[28], r[29], r[30], r[31], 
        r[32], r[33], r[34], r[35], r[36], r[37], r[38], r[39], 
        r[40], r[41], r[42], r[43], r[44], r[45], r[46], r[47], 
        r[48], r[49], r[50], r[51], r[52], r[53], r[54], r[55], 
        r[56], r[57], r[58], r[59], r[60], r[61], r[62], r[63]} <= {32'd7, 32'd12, 32'd17, 32'd22, 
                                                                    32'd7, 32'd12, 32'd17, 32'd22, 
                                                                    32'd7, 32'd12, 32'd17, 32'd22, 
                                                                    32'd7, 32'd12, 32'd17, 32'd22,
                                                                    
                                                                    32'd5, 32'd9, 32'd14, 32'd20, 
                                                                    32'd5, 32'd9, 32'd14, 32'd20, 
                                                                    32'd5, 32'd9, 32'd14, 32'd20, 
                                                                    32'd5, 32'd9, 32'd14, 32'd20,
                                                                    
                                                                    32'd4, 32'd11, 32'd16, 32'd23, 
                                                                    32'd4, 32'd11, 32'd16, 32'd23, 
                                                                    32'd4, 32'd11, 32'd16, 32'd23, 
                                                                    32'd4, 32'd11, 32'd16, 32'd23,
                                                                    
                                                                    32'd6, 32'd10, 32'd15, 32'd21, 
                                                                    32'd6, 32'd10, 32'd15, 32'd21, 
                                                                    32'd6, 32'd10, 32'd15, 32'd21, 
                                                                    32'd6, 32'd10, 32'd15, 32'd21};
        {sr[ 0], sr[ 1], sr[ 2], sr[ 3], sr[ 4], sr[ 5], sr[ 6], sr[ 7], 
        sr[ 8], sr[ 9], sr[10], sr[11], sr[12], sr[13], sr[14], sr[15], 
        sr[16], sr[17], sr[18], sr[19], sr[20], sr[21], sr[22], sr[23], 
        sr[24], sr[25], sr[26], sr[27], sr[28], sr[29], sr[30], sr[31], 
        sr[32], sr[33], sr[34], sr[35], sr[36], sr[37], sr[38], sr[39], 
        sr[40], sr[41], sr[42], sr[43], sr[44], sr[45], sr[46], sr[47], 
        sr[48], sr[49], sr[50], sr[51], sr[52], sr[53], sr[54], sr[55], 
        sr[56], sr[57], sr[58], sr[59], sr[60], sr[61], sr[62], sr[63]} <= {32'd25, 32'd20, 32'd15, 32'd10, 
                                                                            32'd25, 32'd20, 32'd15, 32'd10, 
                                                                            32'd25, 32'd20, 32'd15, 32'd10, 
                                                                            32'd25, 32'd20, 32'd15, 32'd10,
                                                                            
                                                                            32'd27, 32'd23, 32'd18, 32'd12, 
                                                                            32'd27, 32'd23, 32'd18, 32'd12, 
                                                                            32'd27, 32'd23, 32'd18, 32'd12, 
                                                                            32'd27, 32'd23, 32'd18, 32'd12,
                                                                            
                                                                            32'd28, 32'd21, 32'd16, 32'd9, 
                                                                            32'd28, 32'd21, 32'd16, 32'd9, 
                                                                            32'd28, 32'd21, 32'd16, 32'd9, 
                                                                            32'd28, 32'd21, 32'd16, 32'd9,
                                                                            
                                                                            32'd26, 32'd22, 32'd17, 32'd11, 
                                                                            32'd26, 32'd22, 32'd17, 32'd11, 
                                                                            32'd26, 32'd22, 32'd17, 32'd11, 
                                                                            32'd26, 32'd22, 32'd17, 32'd11};
        {k[ 0], k[ 1], k[ 2], k[ 3], k[ 4], k[ 5], k[ 6], k[ 7], 
         k[ 8], k[ 9], k[10], k[11], k[12], k[13], k[14], k[15], 
         k[16], k[17], k[18], k[19], k[20], k[21], k[22], k[23], 
         k[24], k[25], k[26], k[27], k[28], k[29], k[30], k[31], 
         k[32], k[33], k[34], k[35], k[36], k[37], k[38], k[39], 
         k[40], k[41], k[42], k[43], k[44], k[45], k[46], k[47], 
         k[48], k[49], k[50], k[51], k[52], k[53], k[54], k[55], 
         k[56], k[57], k[58], k[59], k[60], k[61], k[62], k[63]} <= {32'hd76aa478, 32'he8c7b756, 32'h242070db, 32'hc1bdceee,
                                                                     32'hf57c0faf, 32'h4787c62a, 32'ha8304613, 32'hfd469501,
                                                                     32'h698098d8, 32'h8b44f7af, 32'hffff5bb1, 32'h895cd7be,
                                                                     32'h6b901122, 32'hfd987193, 32'ha679438e, 32'h49b40821,
                                                                     32'hf61e2562, 32'hc040b340, 32'h265e5a51, 32'he9b6c7aa,
                                                                     32'hd62f105d, 32'h02441453, 32'hd8a1e681, 32'he7d3fbc8,
                                                                     32'h21e1cde6, 32'hc33707d6, 32'hf4d50d87, 32'h455a14ed,
                                                                     32'ha9e3e905, 32'hfcefa3f8, 32'h676f02d9, 32'h8d2a4c8a,
                                                                     32'hfffa3942, 32'h8771f681, 32'h6d9d6122, 32'hfde5380c,
                                                                     32'ha4beea44, 32'h4bdecfa9, 32'hf6bb4b60, 32'hbebfbc70,
                                                                     32'h289b7ec6, 32'heaa127fa, 32'hd4ef3085, 32'h04881d05,
                                                                     32'hd9d4d039, 32'he6db99e5, 32'h1fa27cf8, 32'hc4ac5665,
                                                                     32'hf4292244, 32'h432aff97, 32'hab9423a7, 32'hfc93a039,
                                                                     32'h655b59c3, 32'h8f0ccc92, 32'hffeff47d, 32'h85845dd1,
                                                                     32'h6fa87e4f, 32'hfe2ce6e0, 32'ha3014314, 32'h4e0811a1,
                                                                     32'hf7537e82, 32'hbd3af235, 32'h2ad7d2bb, 32'heb86d391};
  end
end

assign get_answer = (cmp_hash == passwd_hash);
assign valid = (P == S_MAIN_DONE);

always@ (posedge clk) begin
    if(~reset_n || !enable) begin 
        P <= S_IDLE;
    end
    else if(enable) P <= P_next;
end

always@(*) begin
    case(P)
        S_IDLE:
            P_next = S_INIT;
        S_INIT:
            P_next = S_ASSIGN_W;
        S_ASSIGN_W:
            P_next = S_MAIN_LOOP_A;
        S_MAIN_LOOP_A:
            P_next = S_MAIN_LOOP_C;
        S_MAIN_LOOP_B:
            P_next = S_MAIN_LOOP_C;
        S_MAIN_LOOP_C:
            if(counter < 63) P_next = S_ADD_C;
            else P_next = S_ADD_HASH;
        S_ADD_C:
            P_next = S_MAIN_LOOP_A;
        S_ADD_HASH:
            P_next = S_MAIN_DONE;
        S_MAIN_DONE:
            if(!get_answer) P_next = S_IDLE;
            else P_next = S_IS_ANS;
        S_IS_ANS:
            P_next = S_IS_ANS;
        default:
            P_next = S_IDLE;
    endcase
end

always@(posedge clk) begin
    if(P == S_INIT) begin
        counter <= 0;
        for(i = 0 ; i < 128 ; i = i + 1) begin
            msg[i] <= 8'b0;
        end
        msg[7] <= pattern[7:0];
        msg[6] <= pattern[15:8];
        msg[5] <= pattern[23:16];
        msg[4] <= pattern[31:24];
        msg[3] <= pattern[39:32];
        msg[2] <= pattern[47:40];
        msg[1] <= pattern[55:48];
        msg[0] <= pattern[63:56];
        msg[8] <= 128;
        
        msg[56] <= bits_len[ 7: 0];
        msg[57] <= bits_len[15: 8];
        msg[58] <= bits_len[23:16];
        msg[59] <= bits_len[31:24];
        msg[60] <= bits_len[39:32];
        msg[61] <= bits_len[47:40];
        msg[62] <= bits_len[55:48];
        msg[63] <= bits_len[63:56];
        
        answer <= pattern;
        
        a <= 32'h67452301;
        b <= 32'hefcdab89;
        c <= 32'h98badcfe;
        d <= 32'h10325476;
    end
    if(P == S_ASSIGN_W) begin
        w[0] <= {msg[3],msg[2],msg[1],msg[0]};
        w[1] <= {msg[7],msg[6],msg[5],msg[4]};
        w[2] <= {msg[11],msg[10],msg[9],msg[8]};
        w[3] <= {msg[15],msg[14],msg[13],msg[12]};
        w[4] <= {msg[19],msg[18],msg[17],msg[16]};
        w[5] <= {msg[23],msg[22],msg[21],msg[20]};
        w[6] <= {msg[27],msg[26],msg[25],msg[24]};
        w[7] <= {msg[31],msg[30],msg[29],msg[28]};
        w[8] <= {msg[35],msg[34],msg[33],msg[32]};
        w[9] <= {msg[39],msg[38],msg[37],msg[36]};
        w[10] <= {msg[43],msg[42],msg[41],msg[40]};
        w[11] <= {msg[47],msg[46],msg[45],msg[44]};
        w[12] <= {msg[51],msg[50],msg[49],msg[48]};
        w[13] <= {msg[55],msg[54],msg[53],msg[52]};
        w[14] <= {msg[59],msg[58],msg[57],msg[56]};
        w[15] <= {msg[63],msg[62],msg[61],msg[60]};
        
    end
    if(P == S_MAIN_LOOP_A) begin
        if(counter < 16) begin
            f = (b & c) | ((~b) & d);
            g = counter;
        end
        else if(counter < 32) begin
            f = (d & b) | ((~d) & c);
            g = (5*counter + 1) & 15;
        end
        else if(counter < 48) begin
            f = b ^ c ^ d;
            g = (3*counter+5) & 15;
        end
        else begin
            f = c ^ (b | (~d));
            g = (7*counter) & 15;
        end
        f1 <= a + f + k [counter] + w[g];
        
    end
    if(P == S_MAIN_LOOP_C) begin
        f2 = (f1 << r[counter] | f1 >> sr[counter]);
        d <= c;
        c <= b;
        b <= b + f2;
        a <= d;
    end
    if(P == S_ADD_C) begin
        counter <= counter + 1;
    end
    if(P == S_ADD_HASH) begin
        h0 = 32'h67452301 + a;
        h1 = 32'hefcdab89 + b;
        h2 = 32'h98badcfe + c;
        h3 = 32'h10325476 + d;
        cmp_hash = {h0[0+:8],h0[8+:8],h0[16+:8],h0[24+:8],
                    h1[0+:8],h1[8+:8],h1[16+:8],h1[24+:8],
                    h2[0+:8],h2[8+:8],h2[16+:8],h2[24+:8],
                    h3[0+:8],h3[8+:8],h3[16+:8],h3[24+:8]};
    end 
end

endmodule
