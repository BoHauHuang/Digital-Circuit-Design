`timescale 1ns / 1ps

module binary_2_bcd(
    input clk,    
    input reset_n,
    input enable,
    input [35:0] binary,
    output valid,
    output reg [27:0] bcd
    );
    
localparam [2:0] S_IDLE = 0, S_INIT = 1, S_LOOP = 2, S_DONE = 3, S_INIT_TIME = 4;
reg [2:0] P, P_next;
reg [63:0] R;
reg [5:0] loop_count;
reg [35:0] binary_tmp;
reg done;
integer i;

assign valid = done;

always@(posedge clk) begin
    if(~reset_n || !enable) P <= S_IDLE;
    else if(enable) P <= P_next;
end

always@(*) begin
    case(P)
        S_IDLE:
            P_next = S_INIT_TIME;
        S_INIT_TIME:
            P_next = S_INIT;
        S_INIT:
            P_next = S_LOOP;
        S_LOOP:
            if(loop_count < 35) P_next = S_LOOP;
            else P_next = S_DONE;
        S_DONE:
            P_next = S_IDLE;
        default:
            P_next = S_IDLE;
    endcase
end

always@ (posedge clk) begin
    if(P == S_INIT_TIME) begin
        binary_tmp = binary;
    end
    if(P == S_INIT) begin
        R[63:36] = 0;
        R[35:0] = binary_tmp[35:0];
        done = 0;
        loop_count = 0;
    end
    if(P == S_LOOP) begin
          R[63:60] = (R[63:60] > 4'd4)? R[63:60]+3 : R[63:60];
          R[59:56] = (R[59:56] > 4'd4)? R[59:56]+3 : R[59:56];
          R[55:52] = (R[55:52] > 4'd4)? R[55:52]+3 : R[55:52];
          R[51:48] = (R[51:48] > 4'd4)? R[51:48]+3 : R[51:48];
          R[47:44] = (R[47:44] > 4'd4)? R[47:44]+3 : R[47:44];
          R[43:40] = (R[43:40] > 4'd4)? R[43:40]+3 : R[43:40];
          R[39:36] = (R[39:36] > 4'd4)? R[39:36]+3 : R[39:36];
          R = R << 1;
          loop_count = loop_count + 1;
    end
    if(P == S_DONE) begin
        bcd <= R[63:36];
        done = 1;
    end
end
endmodule