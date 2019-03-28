`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/11/09 17:38:19
// Design Name: 
// Module Name: adder
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


module adder(
    input clk,
    input reset_n,
    input enable,
    input [64*18-1 : 0] Ain,
    output reg [16*18-1:0] Sum,
    output valid
    );
    
integer add_done, idx;
reg [18-1 : 0] A_mat [0:63];

always @(posedge clk) begin
    if(!reset_n || !enable) begin
        Sum <= 18'b0;
        add_done <= 0;
    end
    else if (enable) begin
        for(idx = 0 ; idx < 1152 ; idx = idx + 18) begin
            A_mat[idx/18] <= Ain[idx +: 18];
        end
        Sum[0] <= A_mat[0]+A_mat[1]+A_mat[2]+A_mat[3];
        Sum[1] <= A_mat[4]+A_mat[5]+A_mat[6]+A_mat[7];
        Sum[2] <= A_mat[8]+A_mat[9]+A_mat[10]+A_mat[11];
        Sum[3] <= A_mat[12]+A_mat[13]+A_mat[14]+A_mat[15];
        Sum[4] <= A_mat[16]+A_mat[17]+A_mat[18]+A_mat[19];
        Sum[5] <= A_mat[20]+A_mat[21]+A_mat[22]+A_mat[23];
        Sum[6] <= A_mat[24]+A_mat[25]+A_mat[26]+A_mat[27];
        Sum[7] <= A_mat[28]+A_mat[29]+A_mat[30]+A_mat[31];
        Sum[8] <= A_mat[32]+A_mat[33]+A_mat[34]+A_mat[35];
        Sum[9] <= A_mat[36]+A_mat[37]+A_mat[38]+A_mat[39];
        Sum[10] <= A_mat[40]+A_mat[41]+A_mat[42]+A_mat[43];
        Sum[11] <= A_mat[44]+A_mat[45]+A_mat[46]+A_mat[47];
        Sum[12] <= A_mat[48]+A_mat[49]+A_mat[50]+A_mat[51];
        Sum[13] <= A_mat[52]+A_mat[53]+A_mat[54]+A_mat[55];
        Sum[14] <= A_mat[56]+A_mat[57]+A_mat[58]+A_mat[59];
        Sum[15] <= A_mat[60]+A_mat[61]+A_mat[62]+A_mat[63];
        
        add_done = 1;
    end
end

assign valid = (add_done)? 1 : 0;
endmodule
