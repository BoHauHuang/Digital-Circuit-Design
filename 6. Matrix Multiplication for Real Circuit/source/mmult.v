`timescale 1ns / 1ps

module mmult(
    input  clk,
    input  reset_n,
    input  enable,
      
    input [0:16*8-1] A_mat,
    input [0:16*8-1] B_mat,
    
    output valid,
    output reg [0:16*18-1] result
);

reg [0:7] A[0:3][0:3];
reg [0:7] B[0:3][0:3];
reg [0:17] C_mat[0:3][0:3];
reg [0:17] mul_mat [0:64];

integer i, col, j, k, adding, idx;
reg done;

always @(posedge clk) begin
    if (!reset_n || !enable) begin
        i <= 0;
        j <= 0;
        col <= 0;
        k <= 0;
        idx <= 0;
        done <= 0;
    end
    else if (enable) begin
        {A[0][0],A[0][1],A[0][2],A[0][3],A[1][0],A[1][1],A[1][2],A[1][3],A[2][0],A[2][1],A[2][2],A[2][3],A[3][0],A[3][1],A[3][2],A[3][3]} = A_mat;
        {B[0][0],B[0][1],B[0][2],B[0][3],B[1][0],B[1][1],B[1][2],B[1][3],B[2][0],B[2][1],B[2][2],B[2][3],B[3][0],B[3][1],B[3][2],B[3][3]} = B_mat;
        
        for(col = 0 ; col < 4 ; col = col + 1) begin
            for(k = 0 ; k < 4 ; k = k + 1)begin
                mul_mat[i] = A[idx][k]*B[k][col];
                i = i + 1;
            end
        end
        idx = idx + 1;
        if(idx == 4) begin
            idx = 0;
            done = 1;
        end
        
    end
end
reg add_done = 0;

always @(posedge clk) begin
  if (enable && done) begin
    adding = 0;
    {C_mat[0][0],C_mat[0][1],C_mat[0][2],C_mat[0][3],C_mat[1][0],C_mat[1][1],C_mat[1][2],C_mat[1][3],C_mat[2][0],C_mat[2][1],C_mat[2][2],C_mat[2][3],C_mat[3][0],C_mat[3][1],C_mat[3][2],C_mat[3][3]} = 0;
    for(col=0 ; col<4 ; col=col+1) begin
        for(j=0 ; j<4 ; j=j+1) begin
            C_mat[col][j] = mul_mat[adding]+mul_mat[adding+1]+mul_mat[adding+2]+mul_mat[adding+3];
            adding = adding + 4;
        end
    end
    if(adding == 64) begin
        result = {C_mat[0][0],C_mat[0][1],C_mat[0][2],C_mat[0][3],C_mat[1][0],C_mat[1][1],C_mat[1][2],C_mat[1][3],C_mat[2][0],C_mat[2][1],C_mat[2][2],C_mat[2][3],C_mat[3][0],C_mat[3][1],C_mat[3][2],C_mat[3][3]};
        add_done <= 1;
    end
  end
end

assign valid =  (add_done)? 1:0;
endmodule
