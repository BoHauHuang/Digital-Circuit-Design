`timescale 1ns / 1ps

module lab8_tb();
    reg clk = 1;
    reg reset_n = 0;
    reg [3:0] usr_btn = 3'b0;
always #5 clk = ~clk;

initial begin
    #10 reset_n = 1;
    #200 usr_btn[3] = 1;
    #100 usr_btn[3] = 0;
end


lab8 uut(
    .clk(clk),
    .reset_n(reset_n),
    .usr_btn(usr_btn)
);


 
endmodule
