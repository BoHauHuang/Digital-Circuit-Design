`timescale 1ns / 1ps

module mmult(
    input  clk,
    input  reset_n,
    input  enable,
      
    input [0 : 9*8-1] A_mat,
    input [0 : 9*8-1] B_mat,
      
    output valid,
    output reg [0 : 9*17-1] C_mat
);

reg [0 : 8-1] A[0 : 9-1];
reg [0 : 8-1] B[0 : 9-1];

integer i, col, j;
integer done;

always @(posedge clk) begin
    if (!reset_n || !enable) begin
        C_mat <= 17*9'd0;
        i <= 0;
        j <= 0;
        col <= 0;
        done <= 0;
    end
    else if (enable) begin
    
        for(i = 0 ; i < 72 ; i = i+8) begin
            A[i/8] = A_mat[i +: 8];
            B[i/8] = B_mat[i +: 8];
        end
        
        for(col = 0 ; col <= 102 ; col = col + 51) begin
            j = col/17;
            C_mat[col +: 17] <= A[j]*B[0]+A[j+1]*B[3]+A[j+2]*B[6];
            C_mat[col+17 +: 17] <= A[j]*B[1]+A[j+1]*B[4]+A[j+2]*B[7];
            C_mat[col+34 +: 17] <= A[j]*B[2]+A[j+1]*B[5]+A[j+2]*B[8];
        end
        
        done = 1;
    end
end

assign valid =  (done)? 1:0;
endmodule
