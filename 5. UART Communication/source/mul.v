`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/10/23 13:24:39
// Design Name: 
// Module Name: mul
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


module mul(
    input [0:15] Anum_reg,
    input [0:15] Bnum_reg,
    output [0:15] Q_reg,
    output Q_valid
    );
integer Q_valid = 0;
parameter N = 16;
reg [0:N-1] Ain;
reg [0:N-1] Bin;
reg [0:N-1] R = 16'b0;
reg [0:N-1] Q = 16'b0;
integer i;

always @(Anum_reg or Bnum_reg) begin
    Ain = Anum_reg;
    Bin = Bnum_reg;
    
    for( i = N-1 ; i >= 0 ; i = i-1) begin
        R = R<<1;
        R[0]=Ain[i];
        
        if(R>=Bin) begin
        R = R-Bin;
        Q[i] = 1;
        end
    end
    Q_valid = 1;
end
    
endmodule
