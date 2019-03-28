`timescale 1ns / 1ps

module lab3(
  input  clk,            // System clock at 100 MHz
  input  reset_n,        // System reset signal, in negative logic
  input  [3:0] usr_btn,  // Four user pushbuttons
  output [3:0] usr_led   // Four yellow LEDs
);
integer dutycycle;
wire [3 : 0] btn_on_off, btn_is_pressed;
reg [3 : 0] btn_last_time_on_off;
reg signed [3 : 0] leds_on;
reg [0 : 20] period;
reg [0 : 20] pwm_work[0 : 4];
reg [0 : 20] pwm_clk [0 : 4];

debounce db0(
    .clk(clk),
    .btn_input(usr_btn[0]),
    .btn_on_off(btn_on_off[0])
);
debounce db1(
    .clk(clk),
    .btn_input(usr_btn[1]),
    .btn_on_off(btn_on_off[1])
);
debounce db2(
    .clk(clk),
    .btn_input(usr_btn[2]),
    .btn_on_off(btn_on_off[2])
);
debounce db3(
    .clk(clk),
    .btn_input(usr_btn[3]),
    .btn_on_off(btn_on_off[3])
);


initial begin
    period = 21'd1000000;
    pwm_work[0] <= 21'd50000;
    pwm_work[1] <= 21'd250000;
    pwm_work[2] <= 21'd500000;
    pwm_work[3] <= 21'd750000;
    pwm_work[4] <= 21'd1000000;
end


always@(posedge clk) begin
    if(~reset_n) begin
        btn_last_time_on_off <= 4'b1111;
    end
    else begin
        btn_last_time_on_off <= btn_on_off;
    end
end

assign btn_is_pressed = (~btn_last_time_on_off & btn_on_off);

always@(posedge clk) begin
    if(~reset_n)begin
        leds_on <= 4'b0;
    end
    if(btn_is_pressed[0] && leds_on != 4'b1000)begin
        leds_on <= leds_on-1;
    end
    if(btn_is_pressed[1] && leds_on != 4'b0111)begin
        leds_on <= leds_on+1;
    end
end

always@(posedge clk) begin
    if(~reset_n)begin
        dutycycle = 0;
    end
    if(btn_is_pressed[2] && dutycycle > 0)begin
        dutycycle = dutycycle-1;
    end
    if(btn_is_pressed[3] && dutycycle < 4)begin
        dutycycle = dutycycle+1;
    end
end

always@(posedge clk)begin
    if(~reset_n)begin
        pwm_clk[0] <= 21'b0;
        pwm_clk[1] <= 21'b0;
        pwm_clk[2] <= 21'b0;
        pwm_clk[3] <= 21'b0;
    end
    else begin
        if (pwm_clk[0] < period) begin 
            pwm_clk[0]  <= pwm_clk[0]+1;
        end
        else begin
            pwm_clk[0] <= 21'b0;
        end
        
        
        if (pwm_clk[1] < period) begin 
            pwm_clk[1]  <= pwm_clk[1]+1;
        end
        else begin
            pwm_clk[1] <= 21'b0;
        end
        
        
        if (pwm_clk[2] < period) begin 
            pwm_clk[2]  <= pwm_clk[2]+1;
        end
        else begin
            pwm_clk[2] <= 21'b0;
        end
        
        if (pwm_clk[3] < period) begin 
            pwm_clk[3]  <= pwm_clk[3]+1;
        end
        else begin
            pwm_clk[3] <= 21'b0;
        end
                
            
    end
end

assign usr_led[0]= (pwm_clk[0] < pwm_work[dutycycle]) && leds_on[0];
assign usr_led[1]= (pwm_clk[1] < pwm_work[dutycycle]) && leds_on[1];
assign usr_led[2]= (pwm_clk[2] < pwm_work[dutycycle]) && leds_on[2];
assign usr_led[3]= (pwm_clk[3] < pwm_work[dutycycle]) && leds_on[3];

endmodule
