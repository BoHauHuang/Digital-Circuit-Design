`timescale 1ns / 1ps

module bcd(
    input clk,
    input reset_n,
    input enable,
    input [63:0] init_start,
    input [63:0] number_now,
    output reg [63:0] ascii_out,
    output valid
    );
    
reg [63:0] init_num;
reg [63:0] now_value;
reg [63:0] ascii;
reg done_all;
assign valid = done_all;

always@(posedge clk) begin
    if(~reset_n | !enable) begin
        done_all = 0;
        now_value = number_now;
    end
    else if(enable) begin
        ascii[7:0] = (now_value[7:0] == "9")? "0" : now_value[7:0] + 1;
        ascii[15:8] = (now_value[7:0] == "9")? ((now_value[15:8] == "9")? "0" : now_value[15:8]+1) 
                                                : now_value[15:8];
        ascii[23:16] = (now_value[15:0] == "99")? ((now_value[23:16] == "9")? "0" : now_value[23:16]+1) 
                                                : now_value[23:16];
        ascii[31:24] = (now_value[23:0] == "999")? ((now_value[31:24] == "9")? "0" : now_value[31:24]+1) 
                                                : now_value[31:24];
        ascii[39:32] = (now_value[31:0] == "9999")? ((now_value[39:32] == "9")? "0" : now_value[39:32]+1) 
                                                : now_value[39:32];
        ascii[47:40] = (now_value[39:0] == "99999")? ((now_value[47:40] == "9")? "0" : now_value[47:40]+1) 
                                                : now_value[47:40];
        ascii[55:48] = (now_value[47:0] == "999999")? ((now_value[55:48] == "9")? "0" : now_value[55:48]+1) 
                                                : now_value[55:48];
        ascii[63:56] = (now_value[55:0] == "9999999")? ((now_value[63:56] == "9")? "0" : now_value[63:56]+1) 
                                                : now_value[63:56];
                                                
        ascii_out <= ascii;
        now_value <= ascii;
        done_all = 1;
    end
end
endmodule
