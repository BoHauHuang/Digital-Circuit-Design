`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/10/23 13:24:39
// Design Name: 
// Module Name: div
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


module div(
    input [15:0] Anum_reg,
    input [15:0] Bnum_reg,
    output [15:0] Q_reg,
    output Q_valid
    );
integer Q_valid;
parameter N = 16;
reg [N-1:0] Ain;
reg [N-1:0] Bin;
reg [N-1:0] R = 16'b0;
reg [N-1:0] Q_reg = 16'b0;
integer i;

always @(Anum_reg or Bnum_reg) begin
    Q_valid = 0;
    Ain = Anum_reg;
    Bin = Bnum_reg;
    Q_reg = 0;
    R = 0;
    
    for( i = N-1 ; i >= 0 ; i = i-1) begin
        R = R<<1;
        R[0]=Ain[i];
        
        if(R>=Bin) begin
        R = R-Bin;
        Q_reg[i] = 1;
        end
    end
    Q_valid = 1;
end
    
endmodule
