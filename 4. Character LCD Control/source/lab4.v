`timescale 1ns / 1ps

module lab4(
  input clk,
  input reset_n,
  input [3:0] usr_btn,
  output [3:0] usr_led,
  output LCD_RS,
  output LCD_RW,
  output LCD_E,
  output [3:0] LCD_D
);

// turn off all the LEDs
assign usr_led = 4'b0000;

wire btn_level, btn_pressed;
reg prev_btn_level;
reg [127:0] row_A; // Initialize the text of the first row. 
reg [127:0] row_B; // Initialize the text of the second row.
reg [0 : 27-1] fib_clk;
reg [0 : 27-1] full_fib_clk;
reg [0:7] dataA [0:6];
reg [0:7] dataB [0:6];
reg [0:7] data[0:6];
reg [0:16-1] fib[0:26-1];
reg scroll_up;

reg [3:1] state, state_next;
reg [0:5-1] counter;
reg [0:8-1] idx;

parameter [3:1] IDLE=3'b001, FIBO=3'b010, DISP=3'b100;

LCD_module lcd0(
  .clk(clk),
  .reset(~reset_n),
  .row_A(row_A),
  .row_B(row_B),
  .LCD_E(LCD_E),
  .LCD_RS(LCD_RS),
  .LCD_RW(LCD_RW),
  .LCD_D(LCD_D)
);
    
debounce btn_db0(
  .clk(clk),
  .btn_input(usr_btn[3]),
  .btn_output(btn_level)
);

always @(posedge clk) begin
    if(~reset_n) begin
        fib_clk <= 27'b0;
    end
    else begin
        fib_clk <= (fib_clk == 100000010)? 1 : fib_clk+1;
    end
end
    
always @(posedge clk) begin
  if (~reset_n)
    prev_btn_level <= 1;
  else
    prev_btn_level <= btn_level;
end

assign btn_pressed = (btn_level == 1 && prev_btn_level == 0);

always @(posedge clk) begin
    if (~reset_n) begin
        scroll_up <= 1;
    end
    else if (btn_pressed) begin
        scroll_up <= ~scroll_up;
    end
end

reg [0:16-1] fib_last;
reg [0:16-1] fib_last_last;
integer num;
always @(posedge clk) begin
    if(~reset_n) begin
        counter <= 0;
        num <= 1;
        fib[0] = 16'h0;
        fib[1] = 16'h0;
        fib[2] = 16'h1;
        fib_last = 16'h1;
        fib_last_last = 16'h0;
    end
    if(state == FIBO) begin
        if (num < 26 && counter < 25) begin
            if (num > 2) begin
                fib[num] = fib_last + fib_last_last;
                fib_last_last = fib_last;
                fib_last = fib[num];
            end
            num = num + 1;
            counter = counter + 1;
        end
    end
end

always @(posedge clk) begin
  if (~reset_n) begin
    // Initialize the text when the user hit the reset button
    row_A = "Press BTN3 to   ";
    row_B = "show a message..";
    idx <= 8'h01;
  end
  else if (state == DISP && fib_clk == 100000000) begin
        if (scroll_up == 1) begin
            if (idx == 8'h19) begin 
                idx <= 8'h01;
            end
            idx = idx + 1;
            row_A <= row_B;
            row_B <= {"Fibo #",data[0],data[1]," is ",data[2],data[3],data[4],data[5]};
        end
        else begin
            if (idx == 8'h01) begin 
                idx <= 8'h19;
            end
            idx = idx - 1;
            
            row_A <= {"Fibo #",data[0],data[1]," is ",data[2],data[3],data[4],data[5]};
            row_B <= row_A;
        end        
    end
end

always @(posedge clk) begin
    data[0] <= (idx[0:4-1] >= 10)? idx[0:4-1]+55 : idx[0:4-1]+48;
    data[1] <= (idx[4:8-1] >= 10)? idx[4:8-1]+55 : idx[4:8-1]+48;
    data[2] <= (fib[idx][0:4-1] >= 10)? fib[idx][0:4-1]+55 : fib[idx][0:4-1]+48;
    data[3] <= (fib[idx][4:8-1] >= 10)? fib[idx][4:8-1]+55 : fib[idx][4:8-1]+48;
    data[4] <= (fib[idx][8:12-1] >= 10)? fib[idx][8:12-1]+55 : fib[idx][8:12-1]+48;
    data[5] <= (fib[idx][12:16-1] >= 10)? fib[idx][12:16-1]+55 : fib[idx][12:16-1]+48;
end



always @(posedge clk) begin
    if (~reset_n) begin
        state <= IDLE;
    end
    else state <= state_next;
end
always @(*) begin
    case (state)
        IDLE: state_next = FIBO;
        FIBO: state_next = (counter < 25)? FIBO : DISP;
        DISP: state_next = DISP;
        default: state_next = state_next;
    endcase
end

endmodule