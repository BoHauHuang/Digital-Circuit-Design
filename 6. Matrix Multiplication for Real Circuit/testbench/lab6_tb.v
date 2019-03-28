`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/11/12 19:49:33
// Design Name: 
// Module Name: test_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module lab6_tb;
    
    reg clk = 1;
    reg reset_n = 0;
    reg [3:0] usr_btn = 4'b0;
    always #5 clk = ~clk;
    
    initial begin
        #50 reset_n = 1;
    end
    lab6 uut(
      // General system I/O ports
      .clk(clk),
      .reset_n(reset_n),
      .usr_btn(usr_btn)
    );
    
endmodule
