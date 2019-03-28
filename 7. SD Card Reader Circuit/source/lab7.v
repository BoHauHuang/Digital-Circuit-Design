`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Dept. of Computer Science, National Chiao Tung University
// Engineer: Chun-Jen Tsai
// 
// Create Date: 2017/05/08 15:29:41
// Design Name: 
// Module Name: lab7
// Project Name: 
// Target Devices: 
// Tool Versions:
// Description: The sample top module of lab 7: sd card reader. The behavior of
//              this module is as follows
//              1. When the SD card is initialized, display a message on the LCD.
//                 If the initialization fails, an error message will be shown.
//              2. The user can then press usr_btn[2] to trigger the sd card
//                 controller to read the super block of the sd card (located at
//                 block # 8192) into the SRAM memory.
//              3. During SD card reading time, the four LED lights will be turned on.
//                 They will be turned off when the reading is done.
//              4. The LCD will then display the sector just been read, and the
//                 first byte of the sector.
//              5. Everytime you press usr_btn[2], the next byte will be displayed.
// 
// Dependencies: clk_divider, LCD_module, debounce, sd_card
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module lab7(
  // General system I/O ports
  input  clk,
  input  reset_n,
  input  [3:0] usr_btn,
  output [3:0] usr_led,

  // SD card specific I/O ports
  output spi_ss,
  output spi_sck,
  output spi_mosi,
  input  spi_miso,

  // 1602 LCD Module Interface
  output LCD_RS,
  output LCD_RW,
  output LCD_E,
  output [3:0] LCD_D
  );

localparam [3:0] S_MAIN_INIT = 4'b0000, S_MAIN_IDLE = 4'b0001,
                 S_MAIN_WAIT = 4'b0010, S_MAIN_READ = 4'b0011,
                 S_MAIN_DONE = 4'b0100, S_MAIN_SHOW = 4'b0101,
                 S_MAIN_FIND_TAG = 4'b0110, S_MAIN_ANS = 4'b0111,
                 S_MAIN_CHECK_TEXT = 4'b1000;

// Declare system variables
wire btn_level, btn_pressed;
reg  prev_btn_level;
reg  [5:0] send_counter;
reg  [3:0] P, P_next;
reg  [9:0] sd_counter;
reg  [7:0] data_byte;
reg  [31:0] blk_addr;

reg  [127:0] row_A = "SD card cannot  ";
reg  [127:0] row_B = "be initialized! ";

// Declare SD card interface signals
wire clk_sel;
wire clk_500k;
reg  rd_req;
reg  [31:0] rd_addr;
wire init_finished;
wire [7:0] sd_dout;
wire sd_valid;

// Declare the control/data signals of an SRAM memory block
wire [7:0] data_in;
wire [7:0] data_out;
wire [8:0] sram_addr;
wire       sram_we, sram_en;

// find tag 
reg find_tag;
reg [63:0] cmp_texts;
reg [10:0] compare_text_counter;
reg [15:0] three_letter_word;
wire front_pun;
wire mid_not_pun;
wire back_pun;
wire is_three_letter;
wire DLAB_TAG;
wire DLAB_END;

// check if the compare texts are start of texts or end of texts
assign DLAB_TAG = (cmp_texts == "DLAB_TAG");
assign DLAB_END = (cmp_texts == "DLAB_END"); 

assign clk_sel = (init_finished)? clk : clk_500k; // clock for the SD controller
assign usr_led = 4'h00;

clk_divider#(200) clk_divider0(
  .clk(clk),
  .reset(~reset_n),
  .clk_out(clk_500k)
);

debounce btn_db0(
  .clk(clk),
  .btn_input(usr_btn[2]),
  .btn_output(btn_level)
);

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

sd_card sd_card0(
  .cs(spi_ss),
  .sclk(spi_sck),
  .mosi(spi_mosi),
  .miso(spi_miso),

  .clk(clk_sel),
  .rst(~reset_n),
  .rd_req(rd_req),
  .block_addr(rd_addr),
  .init_finished(init_finished),
  .dout(sd_dout),
  .sd_valid(sd_valid)
);

sram ram0(
  .clk(clk),
  .we(sram_we),
  .en(sram_en),
  .addr(sram_addr),
  .data_i(data_in),
  .data_o(data_out)
);

//
// Enable one cycle of btn_pressed per each button hit
//
always @(posedge clk) begin
  if (~reset_n)
    prev_btn_level <= 0;
  else
    prev_btn_level <= btn_level;
end

assign btn_pressed = (btn_level == 1 && prev_btn_level == 0)? 1 : 0;

// ------------------------------------------------------------------------
// The following code sets the control signals of an SRAM memory block
// that is connected to the data output port of the SD controller.
// Once the read request is made to the SD controller, 512 bytes of data
// will be sequentially read into the SRAM memory block, one byte per
// clock cycle (as long as the sd_valid signal is high).

assign sram_we = sd_valid;          // Write data into SRAM when sd_valid is high.
assign sram_en = 1;                 // Always enable the SRAM block.
assign data_in = sd_dout;           // Input data always comes from the SD controller.
assign sram_addr = (P == S_MAIN_FIND_TAG || P == S_MAIN_CHECK_TEXT)? compare_text_counter[8:0] : sd_counter[8:0]; // Set the driver of the SRAM address signal.

// End of the SRAM memory block
// ------------------------------------------------------------------------

//  Find tag reg setting
always @(posedge clk) begin
    if(~reset_n) find_tag <=0;
    else if(DLAB_TAG) find_tag <= 1;
    else if(P == S_MAIN_INIT || P == S_MAIN_IDLE) find_tag <= 0;
end

// ------------------------------------------------------------------------
// FSM of the SD card reader that reads the super block (512 bytes)
always @(posedge clk) begin
  if (~reset_n) begin
    P <= S_MAIN_INIT;
  end
  else begin
    P <= P_next;
  end
end

always @(*) begin // FSM next-state logic
  case (P)
    S_MAIN_INIT: // wait for SD card initialization
      if (init_finished == 1) P_next = S_MAIN_IDLE;
      else P_next = S_MAIN_INIT;
    S_MAIN_IDLE: // wait for button click
      if (btn_pressed == 1) P_next = S_MAIN_WAIT;
      else P_next = S_MAIN_IDLE;
    S_MAIN_WAIT: // issue a rd_req to the SD controller until it's ready
      P_next = S_MAIN_READ;
    S_MAIN_READ: // wait for the input data to enter the SRAM buffer
      if (sd_counter == 512 && find_tag) P_next = S_MAIN_CHECK_TEXT;
      else if(sd_counter == 512 && !find_tag) P_next = S_MAIN_FIND_TAG;
      else P_next = S_MAIN_READ;
    S_MAIN_FIND_TAG: // find if the tag is in these text
    if(DLAB_TAG) P_next = S_MAIN_CHECK_TEXT;
    else if(compare_text_counter == 20) P_next = S_MAIN_WAIT;
    else P_next = S_MAIN_FIND_TAG;
    
    S_MAIN_CHECK_TEXT: // if get tag, start check if other word is a 3 letter word
        if(compare_text_counter == 512) P_next = S_MAIN_WAIT;
        else if(DLAB_END) P_next = S_MAIN_ANS;
        else P_next = S_MAIN_CHECK_TEXT;
    
    /*S_MAIN_DONE: // read data bytes of the superblock from sram[]
      if (btn_pressed == 1) P_next = S_MAIN_SHOW;
      else P_next = S_MAIN_DONE;*/
    S_MAIN_SHOW:
      if (sd_counter < 512) P_next = S_MAIN_DONE;
      else P_next = S_MAIN_IDLE;
    S_MAIN_ANS:  // print out the answer
    P_next = S_MAIN_ANS;
    default:
      P_next = S_MAIN_IDLE;
  endcase
end

always @(posedge clk) begin
    if(~reset_n) begin
        compare_text_counter <= 0;
    end
    else if(P == S_MAIN_CHECK_TEXT || P == S_MAIN_FIND_TAG) begin
        compare_text_counter <= compare_text_counter + (compare_text_counter < 512);
    end
    else begin
        compare_text_counter <= 0;
    end
end


// Count 3 letter word
always @(posedge clk) begin
    if(~reset_n) three_letter_word <= 0;
    else if(P == S_MAIN_CHECK_TEXT && is_three_letter) begin
        three_letter_word <= three_letter_word + 1;
    end
    else if(P == S_MAIN_INIT || P == S_MAIN_IDLE) three_letter_word <= 0;
end

// Store 5 texts to check if  (pun, 3_letter, pun)
always @(posedge clk)begin
    if(~reset_n) cmp_texts <= 0;
    else if(P == S_MAIN_CHECK_TEXT || P == S_MAIN_FIND_TAG) cmp_texts <= {cmp_texts[55:0], data_out};
    else if(P == S_MAIN_INIT || P == S_MAIN_IDLE) cmp_texts <= 0;
end

// Check front and back punctuation
assign front_pun = (cmp_texts[39:32] == "," || cmp_texts[39:32] == "." || cmp_texts[39:32] == "?" || cmp_texts[39:32] == "!" || cmp_texts[39:32] == " " || cmp_texts[39:32] == ":" || cmp_texts[39:32] == ";" || cmp_texts[39:32] == "-" || cmp_texts[39:32] == 10);

assign mid_not_pun = (~(cmp_texts[31:24] == "," || cmp_texts[31:24] == "." || cmp_texts[31:24] == "?" || cmp_texts[31:24] == "!" || cmp_texts[31:24] == " " || cmp_texts[31:24] == ":" || cmp_texts[31:24] == ";" || cmp_texts[31:24] == "-" || cmp_texts[31:24] == 10) &&
                      ~(cmp_texts[23:16] == "," || cmp_texts[23:16] == "." || cmp_texts[23:16] == "?" || cmp_texts[23:16]  == "!" || cmp_texts[23:16] == " " || cmp_texts[23:16] == ":" || cmp_texts[23:16] == ";" || cmp_texts[23:16] == "-" || cmp_texts[23:16] == 10) &&
                      ~(cmp_texts[15:8] == "," || cmp_texts[15:8] == "." || cmp_texts[15:8] == "?" || cmp_texts[15:8] == "!" || cmp_texts[15:8] == " " || cmp_texts[15:8] == ":" || cmp_texts[15:8] == ";" || cmp_texts[15:8] == "-" || cmp_texts[15:8] == 10));
                      
assign back_pun = (cmp_texts[7:0] == "," || cmp_texts[7:0] == "." || cmp_texts[7:0] == "?" || cmp_texts[7:0] == "!" || cmp_texts[7:0] == " " || cmp_texts[7:0] == ";" || cmp_texts[7:0] == ":" || cmp_texts[7:0] == "-" || cmp_texts[7:0] == 10);
assign is_three_letter = (front_pun && mid_not_pun && back_pun);

// FSM output logic: controls the 'rd_req' and 'rd_addr' signals.
always @(*) begin
  rd_req = (P == S_MAIN_WAIT);
  rd_addr = blk_addr;
end

// Switch searching storage block of SD card
always @(posedge clk) begin
  if (~reset_n) blk_addr <= 32'h2000;
  else if ((P == S_MAIN_FIND_TAG || P == S_MAIN_CHECK_TEXT) && P_next == S_MAIN_WAIT) blk_addr <= blk_addr + 1; // In lab 6, change this line to scan all blocks
end

// FSM output logic: controls the 'sd_counter' signal.
// SD card read address incrementer
always @(posedge clk) begin
  if (~reset_n)
    sd_counter <= 0;
  else if (P == S_MAIN_READ && sd_valid) sd_counter <= sd_counter + 1;
  else if (P == S_MAIN_FIND_TAG || P == S_MAIN_CHECK_TEXT) sd_counter <= 0;
end

// FSM ouput logic: Retrieves the content of sram[] for display
/*always @(posedge clk) begin
  if (~reset_n) data_byte <= 8'b0;
  else if (sram_en && P == S_MAIN_DONE) data_byte <= data_out;
end*/
// End of the FSM of the SD card reader
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// LCD Display function.
always @(posedge clk) begin
  if (~reset_n) begin
    row_A = "SD card cannot  ";
    row_B = "be initialized! ";
  end 
  else if (P == S_MAIN_IDLE) begin
    row_A <= "Hit BTN2 to read";
    row_B <= "the SD card ... ";
  end
  else if(P == S_MAIN_ANS) begin
    row_A <= {"Found ",
              ((three_letter_word[15:12] > 9)? "7" : "0")+three_letter_word[15:12],
              ((three_letter_word[11:8] > 9)? "7" : "0")+three_letter_word[11:8],
              ((three_letter_word[7:4] > 9)? "7" : "0")+three_letter_word[7:4],
              ((three_letter_word[3:0] > 9)? "7" : "0")+three_letter_word[3:0], " words"};
    row_B <= {"In the text file"};
  end
end
// End of the LCD display function
// ------------------------------------------------------------------------

endmodule
