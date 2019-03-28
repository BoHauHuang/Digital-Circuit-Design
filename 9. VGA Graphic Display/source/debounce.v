`timescale 1ns / 1ps
module debounce(
    input clk,
    input btn_input,
    output btn_output
    );
    
    parameter bouncing_time = 10000000;
    reg [0 : 24] bouncing_rec;
    assign btn_output = (bouncing_rec == bouncing_time);
    always@(posedge clk)begin
        if(~btn_input)begin
            bouncing_rec <= 0;
        end
        else begin
            bouncing_rec <= bouncing_rec + (bouncing_rec < bouncing_time); 
        end
    end
    
endmodule
