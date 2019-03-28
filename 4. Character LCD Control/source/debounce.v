`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/10/05 15:23:26
// Design Name: 
// Module Name: debounce
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


module debounce(
    input clk,
    input btn_input,
    output btn_output
    );
    
    parameter bouncing_time = 25000000;
    reg [0 : 24] bouncing_rec;
    assign btn_output = (bouncing_rec == bouncing_time);
    always@(posedge clk)begin
        if(~btn_input)begin
            bouncing_rec <= 0;
        end
        else begin
            bouncing_rec <= bouncing_rec + 1; 
        end
    end
    
endmodule
