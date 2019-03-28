`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Dept. of Computer Science, National Chiao Tung University
// Engineer: Chun-Jen Tsai
// 
// Create Date: 2018/11/01 11:16:50
// Design Name: 
// Module Name: lab6
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: This is a sample circuit to show you how to initialize an SRAM
//              with a pre-defined data file. Hit BTN0/BTN1 let you browse
//              through the data.
// 
// Dependencies: LCD_module, debounce
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module lab6(
  // General system I/O ports
  input  clk,
  input  reset_n,
  input  [3:0] usr_btn,
  input uart_rx,
  output [3:0] usr_led,

  // 1602 LCD Module Interface
  output LCD_RS,
  output LCD_RW,
  output LCD_E,
  output [3:0] LCD_D,
  // uart
  output uart_tx
);

localparam [2:0] S_MAIN_ADDR = 3'b000, S_MAIN_READ = 3'b001,
                 S_MAIN_SHOW = 3'b010, S_MAIN_WAIT = 3'b011,
                 S_MAIN_STORE = 3'b100;

// declare system variables
wire [1:0]  btn_level, btn_pressed;
reg  [1:0]  prev_btn_level;
reg  [2:0]  P, P_next;
reg  [11:0] user_addr;
reg  [7:0]  user_data;

reg  [127:0] row_A, row_B;

// declare SRAM control signals
wire [10:0] sram_addr;
wire [7:0]  data_in;
wire [7:0]  data_out;
wire        sram_we, sram_en;
wire print_enable, print_done;
reg [7:0] Amat[0:15];
reg [7:0] Bmat[0:15];

wire [0:16*18-1] Ans;
reg [0:17] Result [0:15];
reg [11:0] mat_addr;
integer mat_idx;

// declare UART signals
wire transmit;
wire received;
wire [7:0] rx_byte;
reg  [7:0] rx_temp;  // if recevied is true, rx_temp latches rx_byte for ONLY ONE CLOCK CYCLE!
wire [7:0] tx_byte;
wire is_num_key;
wire is_receiving;
wire is_transmitting;
wire recv_error;

// UART operations
localparam [2:0] S_MAIN_INIT = 0, S_MAIN_READ_MAT = 2, S_MAIN_PRINT = 3, S_MAIN_ADD = 4, S_MAIN_DONE = 5, S_MAIN_MUL = 6;

localparam [1:0] S_UART_IDLE = 0, S_UART_WAIT = 1,
                 S_UART_SEND = 2, S_UART_INCR = 3;
                 
                 
localparam INIT_DELAY = 100_000; // 1 msec @ 100 MHz
localparam PROMPT_STR = 0;  // starting index of the prompt message
localparam PROMPT_LEN = 167;

localparam MEM_SIZE   = PROMPT_LEN;

reg [2:0] P_uart, P_uart_next;
reg [1:0] Q, Q_next;
reg [$clog2(MEM_SIZE):0] send_counter;
reg [$clog2(INIT_DELAY):0] init_counter;
reg [7:0] data[0:MEM_SIZE-1];
reg  [0:PROMPT_LEN*8-1] msg1 = {"The matrix multiplication result is:\015\012[ 00000, 00000, 00000, 00000 ]\015\012[ 00000, 00000, 00000, 00000 ]\015\012[ 00000, 00000, 00000, 00000 ]\015\012[ 00000, 00000, 00000, 00000 ]\015\012", 8'h00 };
reg  B_done;
reg [5:0]data_count;

assign usr_led = 4'h00;
assign print_done = (tx_byte == 8'h00);
assign print_enable = (P_uart == S_MAIN_PRINT);

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
  .btn_input(usr_btn[0]),
  .btn_output(btn_level[0])
);

debounce btn_db1(
  .clk(clk),
  .btn_input(usr_btn[1]),
  .btn_output(btn_level[1])
);

uart uart(
  .clk(clk),
  .rst(~reset_n),
  .rx(uart_rx),
  .tx(uart_tx),
  .transmit(transmit),
  .tx_byte(tx_byte),
  .received(received),
  .rx_byte(rx_byte),
  .is_receiving(is_receiving),
  .is_transmitting(is_transmitting),
  .recv_error(recv_error)
);


//
// Enable one cycle of btn_pressed per each button hit
//
always @(posedge clk) begin
  if (~reset_n)
    prev_btn_level <= 2'b00;
  else
    prev_btn_level <= btn_level;
end

assign btn_pressed = (btn_level & ~prev_btn_level);

// ------------------------------------------------------------------------
// The following code creates an initialized SRAM memory block that
// stores an 1024x8-bit unsigned numbers.
sram ram0(
    .clk(clk), 
    .we(sram_we), 
    .en(sram_en),
    .addr(sram_addr), 
    .data_i(data_in), 
    .data_o(data_out)
);


assign sram_we = usr_btn[3]; // In this demo, we do not write the SRAM. However,
                             // if you set 'we' to 0, Vivado fails to synthesize
                             // ram0 as a BRAM -- this is a bug in Vivado.
assign sram_en = (P == S_MAIN_ADDR || P == S_MAIN_READ); // Enable the SRAM block. 
assign sram_addr = user_addr[11:0]; // : user_addr[11:0]
assign data_in = 8'b0; // SRAM is read-only so we tie inputs to zeros.
// End of the SRAM memory block.
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// FSM of the main controller
always @(posedge clk) begin
  if (~reset_n) begin
    P <= S_MAIN_ADDR; // read samples at 000 first
  end
  else begin
    P <= P_next;
  end
end

always @(posedge clk) begin
  if (~reset_n) user_data <= 8'b0;
  else if (sram_en && !sram_we) user_data <= data_out;
end

always @(*) begin // FSM next-state logic
  case (P)
    S_MAIN_ADDR: // send an address to the SRAM 
      P_next = S_MAIN_READ;
    S_MAIN_READ:
      P_next = S_MAIN_STORE;
      //else P_next = S_MAIN_READ;
    S_MAIN_STORE:
      P_next = S_MAIN_WAIT;
    S_MAIN_WAIT: // wait for a button click
      if(data_count < 32) P_next = S_MAIN_ADDR;
      else P_next = S_MAIN_WAIT;
  endcase
end

// FSM ouput logic: Fetch the data bus of sram[] for display
always @(posedge clk) begin
  if (~reset_n) begin 
    data_count <= 0;
    B_done <= 0;
  end
  else if (P == S_MAIN_STORE) begin 
    if(user_addr <= 15) begin 
        Amat[user_addr] <= user_data;
    end
    else if (user_addr >= 16) begin
        Bmat[user_addr-16] <= user_data;
    end
    if(user_addr == 32) begin
        B_done <= 1;
    end
  end
end

// End of the main controller
// ------------------------------------------------------------------------
/*
// ------------------------------------------------------------------------
// The following code updates the 1602 LCD text messages.
always @(posedge clk) begin
  if (~reset_n) begin
    row_A <= "Data at [0x---] ";
  end
  else if (P == S_MAIN_SHOW) begin
    row_A[39:32] <= ((user_addr[11:08] > 9)? "7" : "0") + user_addr[11:08];
    row_A[31:24] <= ((user_addr[07:04] > 9)? "7" : "0") + user_addr[07:04];
    row_A[23:16] <= ((user_addr[03:00] > 9)? "7" : "0") + user_addr[03:00];
  end
end
*/
/*
always @(posedge clk) begin
  if (~reset_n) begin
    row_B <= "is equal to 0x--";
  end
  else if (P == S_MAIN_SHOW) begin
    //row_A[15:08] <= ((Amat[0][7:4] > 9)? "7" : "0") + Amat[0][7:4];
    //row_A[07: 0] <= ((Amat[0][3:0] > 9)? "7" : "0") + Amat[0][3:0];
    row_B[15:08] <= ((Bmat[15][7:4] > 9)? "7" : "0") + Bmat[15][7:4];
    row_B[07: 0] <= ((Bmat[15][3:0] > 9)? "7" : "0") + Bmat[15][3:0];
    
  end
end
*/
// End of the 1602 LCD text-updating code.
// ------------------------------------------------------------------------


// ------------------------------------------------------------------------
// The circuit block that processes the user's button event.
always @(posedge clk) begin
  if (~reset_n)
    user_addr <= 12'h000;
  else if(P_next == S_MAIN_ADDR) begin
    user_addr <= (user_addr < 32)? user_addr + 1 : user_addr;
  end
end
// End of the user's button control.
// ------------------------------------------------------------------------


integer idx;

always @(posedge clk) begin
  if (~reset_n) begin
    for (idx = 0; idx < PROMPT_LEN; idx = idx + 1) data[idx] = msg1[idx*8 +: 8];
  end
  else if (P_uart == S_MAIN_PRINT) begin
   //row_A <= {Result[0][0]+"0",Result[0][1]+"0",Result[0][2]+"0",Result[0][3]+"0",Result[0][4]+"0",Result[0][5]+"0",Result[0][6]+"0",Result[0][7]+"0",Result[0][8]+"0",Result[0][9]+"0",Result[0][10]+"0",Result[0][11]+"0",Result[0][12]+"0",Result[0][13]+"0",Result[0][14]+"0",Result[0][15]+"0"};
   
   //row_B <= {"0123456789012345"};
   for(idx = 0 ; idx < 4 ; idx = idx + 1) begin
    data[38+2+idx*7] <= Result[idx][0:1]+"0";
    data[38+3+idx*7] <= ((Result[idx][2:5] > 9)? "7" : "0") + Result[idx][2:5];
    data[38+4+idx*7] <= ((Result[idx][6:9] > 9)? "7" : "0") + Result[idx][6:9];
    data[38+5+idx*7] <= ((Result[idx][10:13] > 9)? "7" : "0") + Result[idx][10:13];
    data[38+6+idx*7] <= ((Result[idx][14:17] > 9)? "7" : "0") + Result[idx][14:17];
   end
   for(idx = 4 ; idx < 8 ; idx = idx + 1) begin
     data[70+2+(idx-4)*7] <= Result[idx][0:1]+"0";
     data[70+3+(idx-4)*7] <= ((Result[idx][2:5] > 9)? "7" : "0") + Result[idx][2:5];
     data[70+4+(idx-4)*7] <= ((Result[idx][6:9] > 9)? "7" : "0") + Result[idx][6:9];
     data[70+5+(idx-4)*7] <= ((Result[idx][10:13] > 9)? "7" : "0") + Result[idx][10:13];
     data[70+6+(idx-4)*7] <= ((Result[idx][14:17] > 9)? "7" : "0") + Result[idx][14:17];
   end
   for(idx = 8 ; idx < 12 ; idx = idx + 1) begin
     data[102+2+(idx-8)*7] <= Result[idx][0:1]+"0";
     data[102+3+(idx-8)*7] <= ((Result[idx][2:5] > 9)? "7" : "0") + Result[idx][2:5];
     data[102+4+(idx-8)*7] <= ((Result[idx][6:9] > 9)? "7" : "0") + Result[idx][6:9];
     data[102+5+(idx-8)*7] <= ((Result[idx][10:13] > 9)? "7" : "0") + Result[idx][10:13];
     data[102+6+(idx-8)*7] <= ((Result[idx][14:17] > 9)? "7" : "0") + Result[idx][14:17];
   end
   for(idx = 12 ; idx < 16 ; idx = idx + 1) begin
     data[134+2+(idx-12)*7] <= Result[idx][0:1]+"0";
     data[134+3+(idx-12)*7] <= ((Result[idx][2:5] > 9)? "7" : "0") + Result[idx][2:5];
     data[134+4+(idx-12)*7] <= ((Result[idx][6:9] > 9)? "7" : "0") + Result[idx][6:9];
     data[134+5+(idx-12)*7] <= ((Result[idx][10:13] > 9)? "7" : "0") + Result[idx][10:13];
     data[134+6+(idx-12)*7] <= ((Result[idx][14:17] > 9)? "7" : "0") + Result[idx][14:17];
   end
  end
end

wire enable_mult;
reg [0:16*8-1] Ain;
reg [0:16*8-1] Bin;
wire mult_valid ;
reg result_valid;

always @(posedge clk) begin
  if (~reset_n) begin
    P_uart <= S_MAIN_INIT;
  end
  else P_uart <= P_uart_next;
end

assign enable_mult = (P_uart == S_MAIN_MUL);
// Initialization counter.
always @(posedge clk) begin
  if (P_uart == S_MAIN_INIT) init_counter <= init_counter + 1;
  else init_counter <= 0;
end


always @(*) begin
  case(P_uart)
    S_MAIN_INIT: // Wait for initial of the circuit.
        if (init_counter > INIT_DELAY) begin 
            mat_addr <= 0;
            P_uart_next = S_MAIN_READ_MAT;
        end
        else P_uart_next = S_MAIN_INIT;

    S_MAIN_READ_MAT:
        if(B_done) begin 
            Ain <= {Amat[0],Amat[4],Amat[8],Amat[12], Amat[1],Amat[5],Amat[9],Amat[13], Amat[2],Amat[6],Amat[10],Amat[14], Amat[3],Amat[7],Amat[11],Amat[15]};
            Bin <= {Bmat[0],Bmat[4],Bmat[8],Bmat[12], Bmat[1],Bmat[5],Bmat[9],Bmat[13], Bmat[2],Bmat[6],Bmat[10],Bmat[14], Bmat[3],Bmat[7],Bmat[11],Bmat[15]};
            P_uart_next = S_MAIN_ADD;
        end
        else P_uart_next = S_MAIN_READ_MAT;
    S_MAIN_ADD:
        if(btn_pressed[1]) P_uart_next = S_MAIN_MUL;
        else P_uart_next = S_MAIN_ADD;
    S_MAIN_MUL:
        if(result_valid) P_uart_next = S_MAIN_PRINT;
        else P_uart_next = S_MAIN_MUL;
    S_MAIN_PRINT:
        if(print_done) P_uart_next = S_MAIN_INIT;
        else P_uart_next = S_MAIN_PRINT;
    endcase
end

// FSM of the controller that sends a string to the UART.
always @(posedge clk) begin
  if (~reset_n) Q <= S_UART_IDLE;
  else Q <= Q_next;
end

always @(*) begin // FSM next-state logic
  case (Q)
    S_UART_IDLE: // wait for the print_string flag
      if (print_enable) Q_next = S_UART_WAIT;
      else Q_next = S_UART_IDLE;
    S_UART_WAIT: // wait for the transmission of current data byte begins
      if (is_transmitting == 1) Q_next = S_UART_SEND;
      else Q_next = S_UART_WAIT;
    S_UART_SEND: // wait for the transmission of current data byte finishes
      if (is_transmitting == 0) Q_next = S_UART_INCR; // transmit next character
      else Q_next = S_UART_SEND;
    S_UART_INCR:
      if (print_done) Q_next = S_UART_IDLE; // string transmission ends
      else Q_next = S_UART_WAIT;
  endcase
end

// FSM output logics: UART transmission control signals
assign transmit = (Q_next == S_UART_WAIT || print_enable);
assign tx_byte  =  data[send_counter];
// UART send_counter control circuit
always @(posedge clk) begin
  case (P_uart)
    S_MAIN_MUL: 
        if(P_uart_next == S_MAIN_PRINT) send_counter <= PROMPT_STR;
    default: send_counter <= send_counter + (Q_next == S_UART_INCR);
  endcase
end


mmult mmult(
    .clk(clk),
    .reset_n(reset_n),
    .enable(enable_mult),
    .A_mat(Ain),
    .B_mat(Bin),
    .valid(mult_valid),
    .result(Ans)
);

always @(posedge clk) begin
  if (mult_valid) begin
    //row_A <= {Ain[0]+"0",Ain[1]+"0",Ain[2]+"0",Ain[3]+"0",Ain[4]+"0",Ain[5]+"0",Ain[6]+"0",Ain[7]+"0",Ain[8]+"0",Ain[9]+"0",Ain[10]+"0"};
    //row_B <= {Amat[2][0]+"0",Amat[2][1]+"0",Amat[2][2]+"0",Amat[2][3]+"0",Amat[2][4]+"0",Amat[2][5]+"0",Amat[2][6]+"0",Amat[2][7]+"0"};
    //row_A <= {Ans[0]+"0",Ans[1]+"0",Ans[2]+"0",Ans[3]+"0",Ans[4]+"0",Ans[5]+"0",Ans[6]+"0",Ans[7]+"0",Ans[8]+"0",Ans[9]+"0",Ans[10]+"0",Ans[11]+"0",Ans[12]+"0",Ans[13]+"0",Ans[14]+"0",Ans[15]+"0"};
    Result[0] <= {Ans[0],Ans[1],Ans[2],Ans[3],Ans[4],Ans[5],Ans[6],Ans[7],Ans[8],Ans[9],Ans[10],Ans[11],Ans[12],Ans[13],Ans[14],Ans[15],Ans[16],Ans[17]};
    Result[1] <= {Ans[18],Ans[19],Ans[20],Ans[21],Ans[22],Ans[23],Ans[24],Ans[25],Ans[26],Ans[27],Ans[28],Ans[29],Ans[30],Ans[31],Ans[32],Ans[33],Ans[34],Ans[35]};
    Result[2] <= {Ans[36],Ans[37],Ans[38],Ans[39],Ans[40],Ans[41],Ans[42],Ans[43],Ans[44],Ans[45],Ans[46],Ans[47],Ans[48],Ans[49],Ans[50],Ans[51],Ans[52],Ans[53]};
    Result[3] <= {Ans[54],Ans[55],Ans[56],Ans[57],Ans[58],Ans[59],Ans[60],Ans[61],Ans[62],Ans[63],Ans[64],Ans[65],Ans[66],Ans[67],Ans[68],Ans[69],Ans[70],Ans[71]};
    Result[4] <= {Ans[72],Ans[73],Ans[74],Ans[75],Ans[76],Ans[77],Ans[78],Ans[79],Ans[80],Ans[81],Ans[82],Ans[83],Ans[84],Ans[85],Ans[86],Ans[87],Ans[88],Ans[89]};
    Result[5] <= {Ans[90],Ans[91],Ans[92],Ans[93],Ans[94],Ans[95],Ans[96],Ans[97],Ans[98],Ans[99],Ans[100],Ans[101],Ans[102],Ans[103],Ans[104],Ans[105],Ans[106],Ans[107]};
    Result[6] <= {Ans[108],Ans[109],Ans[110],Ans[111],Ans[112],Ans[113],Ans[114],Ans[115],Ans[116],Ans[117],Ans[118],Ans[119],Ans[120],Ans[121],Ans[122],Ans[123],Ans[124],Ans[125]};
    Result[7] <= {Ans[126],Ans[127],Ans[128],Ans[129],Ans[130],Ans[131],Ans[132],Ans[133],Ans[134],Ans[135],Ans[136],Ans[137],Ans[138],Ans[139],Ans[140],Ans[141],Ans[142],Ans[143]};
    Result[8] <= {Ans[144],Ans[145],Ans[146],Ans[147],Ans[148],Ans[149],Ans[150],Ans[151],Ans[152],Ans[153],Ans[154],Ans[155],Ans[156],Ans[157],Ans[158],Ans[159],Ans[160],Ans[161]};
    Result[9] <= {Ans[162],Ans[163],Ans[164],Ans[165],Ans[166],Ans[167],Ans[168],Ans[169],Ans[170],Ans[171],Ans[172],Ans[173],Ans[174],Ans[175],Ans[176],Ans[177],Ans[178],Ans[179]};
    Result[10] <= {Ans[180],Ans[181],Ans[182],Ans[183],Ans[184],Ans[185],Ans[186],Ans[187],Ans[188],Ans[189],Ans[190],Ans[191],Ans[192],Ans[193],Ans[194],Ans[195],Ans[196],Ans[197]};
    Result[11] <= {Ans[198],Ans[199],Ans[200],Ans[201],Ans[202],Ans[203],Ans[204],Ans[205],Ans[206],Ans[207],Ans[208],Ans[209],Ans[210],Ans[211],Ans[212],Ans[213],Ans[214],Ans[215]};
    Result[12] <= {Ans[216],Ans[217],Ans[218],Ans[219],Ans[220],Ans[221],Ans[222],Ans[223],Ans[224],Ans[225],Ans[226],Ans[227],Ans[228],Ans[229],Ans[230],Ans[231],Ans[232],Ans[233]};
    Result[13] <= {Ans[234],Ans[235],Ans[236],Ans[237],Ans[238],Ans[239],Ans[240],Ans[241],Ans[242],Ans[243],Ans[244],Ans[245],Ans[246],Ans[247],Ans[248],Ans[249],Ans[250],Ans[251]};
    Result[14] <= {Ans[252],Ans[253],Ans[254],Ans[255],Ans[256],Ans[257],Ans[258],Ans[259],Ans[260],Ans[261],Ans[262],Ans[263],Ans[264],Ans[265],Ans[266],Ans[267],Ans[268],Ans[269]};
    Result[15] <= {Ans[270],Ans[271],Ans[272],Ans[273],Ans[274],Ans[275],Ans[276],Ans[277],Ans[278],Ans[279],Ans[280],Ans[281],Ans[282],Ans[283],Ans[284],Ans[285],Ans[286],Ans[287]};
    result_valid <= 1;
  end
  else result_valid <= 0;
end


endmodule
