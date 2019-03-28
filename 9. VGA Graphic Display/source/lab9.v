`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Dept. of Computer Science, National Chiao Tung University
// Engineer: Chun-Jen Tsai 
// 
// Create Date: 2018/12/11 16:04:41
// Design Name: 
// Module Name: lab9
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: A circuit that show the animation of a fish swimming in a seabed
//              scene on a screen through the VGA interface of the Arty I/O card.
// 
// Dependencies: vga_sync, clk_divider, sram 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module lab9(
    input  clk,
    input  reset_n,
    input  [3:0] usr_btn,
    input  [3:0] usr_sw,
    output [3:0] usr_led,
    
    // VGA specific I/O ports
    output VGA_HSYNC,
    output VGA_VSYNC,
    output [3:0] VGA_RED,
    output [3:0] VGA_GREEN,
    output [3:0] VGA_BLUE
    );

// Declare system variables
reg  [32:0] fish_clock [3:0];
wire [9:0]  pos [3:0];
wire        fish_region [3:0];

// declare SRAM control signals
wire [16:0] sram_addr [3:0];
wire [11:0] data_in;
wire [11:0] data_out  [3:0];
wire        sram_we, sram_en;

// General VGA control signals
wire vga_clk;         // 50MHz clock for VGA control
wire video_on;        // when video_on is 0, the VGA controller is sending
                      // synchronization signals to the display device.
  
wire pixel_tick;      // when pixel tick is 1, we must update the RGB value
                      // based for the new coordinate (pixel_x, pixel_y)
  
wire [9:0] pixel_x;   // x coordinate of the next pixel (between 0 ~ 639) 
wire [9:0] pixel_y;   // y coordinate of the next pixel (between 0 ~ 479)
  
reg  [11:0] rgb_reg;  // RGB value for the current pixel
reg  [11:0] rgb_next; // RGB value for the next pixel
  
// Application-specific VGA signals
reg  [17:0] pixel_addr [3:0];

// Declare the video buffer size
localparam VBUF_W = 320; // video buffer width
localparam VBUF_H = 240; // video buffer height

// Set parameters for the fish images
localparam FISH1_VPOS   = 20; // Vertical location of the fish in the sea image.
localparam FISH2_VPOS   = 90;
localparam FISH3_VPOS   = 180;
localparam FISH_control_VPOS = 0;
//reg[31:0] FISH_control_VPOS;
localparam FISH_W      = 64; // Width of the fish.
localparam FISH_H      = 32; // Height of the fish.
localparam FISH_MOVE     = 15; 
reg [17:0] fish1_addr[0:7];   // Address array for up to 8 fish images.
reg [17:0] fish2_addr[0:7];
reg [17:0] fish3_addr[0:7];
reg [17:0] fish_control_addr[0:7];
// Initializes the fish images starting addresses.
// Note: System Verilog has an easier way to initialize an array,
//       but we are using Verilog 2001 :(
reg [32:0] speed;
reg [31:0] y;
reg [31:0] swing;
reg [9:0] prev_pos;

wire [3:0] btn_pressed;
wire [3:0] btn_level;
reg [3:0] prev_btn_level;

integer i;
initial begin
  for(i = 0 ; i<8 ; i=i+1) begin
    fish1_addr[i] = FISH_W*FISH_H*i;
    fish2_addr[i] = FISH_W*FISH_H*i;
    fish3_addr[i] = FISH_W*FISH_H*i;
    fish_control_addr[i] = FISH_W*FISH_H*i;
  end
end

// Instiantiate the VGA sync signal generator
vga_sync vs0(
  .clk(vga_clk), .reset(~reset_n), .oHS(VGA_HSYNC), .oVS(VGA_VSYNC),
  .visible(video_on), .p_tick(pixel_tick),
  .pixel_x(pixel_x), .pixel_y(pixel_y)
);

clk_divider#(2) clk_divider0(
  .clk(clk),
  .reset(~reset_n),
  .clk_out(vga_clk)
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
debounce btn_db2(
  .clk(clk),
  .btn_input(usr_btn[2]),
  .btn_output(btn_level[2])
);

always @(posedge clk) begin
  if (~reset_n)
    prev_btn_level <= 1;
  else
    prev_btn_level <= btn_level;
end

assign btn_pressed[0] = (btn_level[0] == 1 && prev_btn_level[0] == 0);
assign btn_pressed[1] = (btn_level[1] == 1 && prev_btn_level[1] == 0);
assign btn_pressed[2] = (btn_level[2] == 1 && prev_btn_level[2] == 0);

// ------------------------------------------------------------------------
// The following code describes an initialized SRAM memory block that
// stores a 320x240 12-bit seabed image, plus two 64x32 fish images.
sram_bg #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(VBUF_W*VBUF_H))
  ram_bg (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr[0]), .data_i(data_in), .data_o(data_out[0]));
          
sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(FISH_W*FISH_H*8))
  ram_fish_1 (.clk(clk), .we(sram_we), .en(sram_en),
        .addr(sram_addr[1]), .data_i(data_in), .data_o(data_out[1]));
sram_ctrl #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(FISH_W*FISH_H*8))        
  ram_fish_control (.clk(clk), .we(sram_we), .en(sram_en),
        .addr(sram_addr[2]), .data_i(data_in), .data_o(data_out[2]));
        
assign sram_we = usr_btn[3]; // In this demo, we do not write the SRAM. However, if
                             // you set 'sram_we' to 0, Vivado fails to synthesize
                             // ram0 as a BRAM -- this is a bug in Vivado.
assign sram_en = 1;          // Here, we always enable the SRAM block.
assign sram_addr[0] = pixel_addr[0];
assign sram_addr[1] = pixel_addr[1];
assign sram_addr[2] = pixel_addr[2];
assign data_in = 12'h000; // SRAM is read-only so we tie inputs to zeros.
// End of the SRAM memory block.
// ------------------------------------------------------------------------

// VGA color pixel generator
assign {VGA_RED, VGA_GREEN, VGA_BLUE} = rgb_reg;

// ------------------------------------------------------------------------
// An animation clock for the motion of the fish, upper bits of the
// fish clock is the x position of the fish on the VGA screen.
// Note that the fish will move one screen pixel every 2^20 clock cycles,
// or 10.49 msec
// median
assign pos[0] = fish_clock[0][31:20]; // the x position of the right edge of the fish image
                                // in the 640x480 VGA screen
// fast
assign pos[1] = fish_clock[1][30:19];
// slow
assign pos[2] = fish_clock[2][32:21];
// user define
assign pos[3] = fish_clock[3][32:21];

always @(posedge clk) begin
    if(~reset_n) speed = 1;
    else if(btn_pressed[0]) speed = (speed < 15)? speed + 1 : speed;
    else if(btn_pressed[1]) speed = (speed > 0)? speed - 1 : 0;
    else if(btn_pressed[2]) y <= (FISH_control_VPOS + y + FISH_MOVE < VBUF_H)? y + FISH_MOVE : 0;
end

always @(posedge clk) begin
    if(fish_clock[2][32:21] == 0) prev_pos <= 0;
    if(~reset_n) swing <= 0;
    else if(fish_clock[2][32:21] == prev_pos+5 && fish_clock[2][32:21] != 0) begin
        swing <= (fish_clock[2][26] == 1)? swing-1 : swing+1;
        prev_pos <= fish_clock[2][32:21];
    end
end


always @(posedge clk) begin
  if (~reset_n) begin
    fish_clock[0] <= 0;
    fish_clock[1] <= 0;
    fish_clock[2] <= 0;
    fish_clock[3] <= 0;
  end
  if(fish_clock[0][31:21] > VBUF_W + FISH_W) fish_clock[0] <= 0;
  else fish_clock[0] <= fish_clock[0] + 1;
  
  if(fish_clock[1][30:20] < 0) fish_clock[1] <= VBUF_W + FISH_W;
  else fish_clock[1] <= fish_clock[1] - 1;
  
  if(fish_clock[2][32:22] > VBUF_W + FISH_W) fish_clock[2] <= 0;
  else fish_clock[2] <= fish_clock[2] + 1;
  
  if(fish_clock[3][32:22] > VBUF_W + FISH_W) fish_clock[3] <= 0;
  else fish_clock[3] <= fish_clock[3] + speed;
  
end
// End of the animation clock code.
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// Video frame buffer address generation unit (AGU) with scaling control
// Note that the width x height of the fish image is 64x32, when scaled-up
// on the screen, it becomes 128x64. 'pos' specifies the right edge of the
// fish image.
assign fish_region[0] =
           pixel_y >= (FISH1_VPOS<<1) && pixel_y < (FISH1_VPOS+FISH_H)<<1 &&
           (pixel_x + 127) >= pos[0] && pixel_x < (pos[0] + 1);
assign fish_region[1] = 
           pixel_y >= (FISH2_VPOS<<1) && pixel_y < (FISH2_VPOS+FISH_H)<<1 &&
           (pixel_x + 127) >= pos[1] && pixel_x < (pos[1]+ 1);
assign fish_region[2] = 
          pixel_y >= ((FISH3_VPOS+swing)<<1) && pixel_y < (FISH3_VPOS+swing+FISH_H)<<1 &&
          (pixel_x + 127) >= pos[2] && pixel_x < (pos[2]+ 1);
assign fish_region[3] = 
          pixel_y >= ((FISH_control_VPOS+y)<<1) && pixel_y < (FISH_control_VPOS+y+FISH_H)<<1 &&
          (pixel_x + 127) >= pos[3] && pixel_x < (pos[3]+ 1);

always @ (posedge clk) begin
  if (~reset_n) begin
    pixel_addr[0] <= 0;
    pixel_addr[1] <= 0;
    pixel_addr[2] <= 0;
  end
  else if (fish_region[3]) begin
       pixel_addr[0] <= (pixel_y >> 1) * VBUF_W + (pixel_x >> 1);
       pixel_addr[2] <= fish_control_addr[fish_clock[3][26:24]] +
                          ((pixel_y>>1)-(FISH_control_VPOS+y))*FISH_W +
                          ((pixel_x +(FISH_W*2-1)-pos[3])>>1);
       if (FISH_control_VPOS+y <= FISH1_VPOS+FISH_H && FISH_control_VPOS+y >= 0) begin
            pixel_addr[1] <= fish1_addr[fish_clock[0][25:23]] +
                                   ((pixel_y>>1)-FISH1_VPOS)*FISH_W +
                                   ((pixel_x +(FISH_W*2-1)-pos[0])>>1);
       end
       else if (FISH_control_VPOS+y <= FISH2_VPOS+FISH_H && FISH_control_VPOS+y >= FISH2_VPOS-FISH_H) begin
           pixel_addr[1] <= fish2_addr[fish_clock[1][24:22]] +
                                  ((pixel_y>>1)-FISH2_VPOS)*FISH_W +
                                  (pos[1]-(pixel_x +(FISH_W*2-1))>>1);
       end
       else if (FISH_control_VPOS+y <= FISH3_VPOS+FISH_H && FISH_control_VPOS+y >= FISH3_VPOS-FISH_H) begin
          pixel_addr[1] <= fish3_addr[fish_clock[2][26:24]] +
                                 ((pixel_y>>1)-(FISH3_VPOS+swing))*FISH_W +
                                 ((pixel_x +(FISH_W*2-1)-pos[2])>>1);
       end
  end
  else if(fish_region[0]) begin
      pixel_addr[0] <= (pixel_y >> 1) * VBUF_W + (pixel_x >> 1);
      pixel_addr[1] <= fish1_addr[fish_clock[0][25:23]] +
                        ((pixel_y>>1)-FISH1_VPOS)*FISH_W +
                        ((pixel_x +(FISH_W*2-1)-pos[0])>>1);
      pixel_addr[2] <= fish_control_addr[fish_clock[3][26:24]] +
                      ((pixel_y>>1)-(FISH_control_VPOS+y))*FISH_W +
                      ((pixel_x +(FISH_W*2-1)-pos[3])>>1);
  end
  else if(fish_region[1]) begin
    pixel_addr[0] <= (pixel_y >> 1) * VBUF_W + (pixel_x >> 1);
    pixel_addr[1] <= fish2_addr[fish_clock[1][24:22]] +
                      ((pixel_y>>1)-FISH2_VPOS)*FISH_W +
                      (pos[1]-(pixel_x +(FISH_W*2-1))>>1);
    pixel_addr[2] <= fish_control_addr[fish_clock[3][26:24]] +
                        ((pixel_y>>1)-(FISH_control_VPOS+y))*FISH_W +
                        ((pixel_x +(FISH_W*2-1)-pos[3])>>1);     
  end
  else if (fish_region[2]) begin
    pixel_addr[0] <= (pixel_y >> 1) * VBUF_W + (pixel_x >> 1);
    pixel_addr[1] <= fish3_addr[fish_clock[2][26:24]] +
                    ((pixel_y>>1)-(FISH3_VPOS+swing))*FISH_W +
                    ((pixel_x +(FISH_W*2-1)-pos[2])>>1);
    pixel_addr[2] <= fish_control_addr[fish_clock[3][26:24]] +
                      ((pixel_y>>1)-(FISH_control_VPOS+y))*FISH_W +
                      ((pixel_x +(FISH_W*2-1)-pos[3])>>1);
  end
 
  else pixel_addr[0] <= (pixel_y >> 1) * VBUF_W + (pixel_x >> 1);
  
  
    // Scale up a 320x240 image for the 640x480 display.
    // (pixel_x, pixel_y) ranges from (0,0) to (639, 479)
   
end
// End of the AGU code.
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// Send the video data in the sram to the VGA controller
always @(posedge clk) begin
  if (pixel_tick) rgb_reg <= rgb_next;
end

always @(*) begin
  if (~video_on)
    rgb_next = 12'h000; // Synchronization period, must set RGB values to zero.
  else if(!fish_region[3] && (fish_region[0] || fish_region[1] || fish_region[2])) begin
    rgb_next = (data_out[1] != 12'h0f0)? data_out[1] : data_out[0];
  end
  else if(fish_region[3] && (fish_region[0] || fish_region[1] || fish_region[2])) begin
    rgb_next = (data_out[2] != 12'h0f0)? data_out[2] : (data_out[1] != 12'h0f0)? data_out[1] : data_out[0];
  end
  else if(fish_region[3] && !(fish_region[0] || fish_region[1] || fish_region[2])) begin
    rgb_next = (data_out[2] != 12'h0f0)? data_out[2] : data_out[0];
  end
  else rgb_next = data_out[0]; // RGB value at (pixel_x, pixel_y)
end
// End of the video data display code.
// ------------------------------------------------------------------------

endmodule
