`timescale 1ns / 1ps

module lab8(
    input clk,
    input reset_n,
    input [3:0] usr_btn,
    output [2:0] usr_led,
    output LCD_RS,
    output LCD_RW,
    output LCD_E,
    output [3:0] LCD_D
    );

reg [127:0] passwd_hash = 128'hef775988943825d2871e1cfa75473ec0;//6f7b6fc969e90609fe52d789b471cc22;//ced165163e51e06e01dc44c35fea3eaf;//E8CD0953ABDFDE433DFEC7FAA70DF7F6;//
wire [127:0] passwd;
reg [63:0] result;

// Timing 
reg [35:0] timer_origin;
reg [35:0] timer_ms;
reg [27:0] timer;
wire [27:0] time_bcd;
wire time_valid;
reg time_ok;

// BCD
reg [63:0] pattern [24:0];
wire [24:0] bcd_valid;
wire bcd_enable; 
wire [63:0] bcd_out [24:0];

// MD5
wire md5_enable;
wire [24:0] valid;
wire [24:0] get_answer;
wire [63:0] ans [24:0];
reg got;
reg  [127:0] row_A = "Press btn3      ";
reg  [127:0] row_B = "to start...     ";

reg btn_pressed;

assign passwd = passwd_hash;
assign md5_enable = btn_pressed & (~got);
assign bcd_enable = (| valid) & (~got);

always@(posedge clk) begin
    if(~reset_n || ~btn_pressed) begin
        timer_ms <= 0;
        timer_origin <= 0;
    end
    else if(btn_pressed && md5_enable) begin 
        if(timer_origin  == 99999) begin 
            timer_ms <= timer_ms + 1;
            timer_origin <= 0;
        end
        else timer_origin <= timer_origin + 1;
    end
end

always@(posedge clk) begin
    if(~reset_n | ~btn_pressed) begin 
        row_A <= "Press btn3      ";
        row_B <= "to start...     ";
        time_ok = 0;
        btn_pressed = 0;
        got = 0;
        result = 0;
        pattern[0] <= "00000000";
        pattern[1] <= "04000000";
        pattern[2] <= "08000000";
        pattern[3] <= "12000000";
        pattern[4] <= "16000000";
        pattern[5] <= "20000000";
        pattern[6] <= "24000000";
        pattern[7] <= "28000000";
        pattern[8] <= "32000000";
        pattern[9] <= "36000000";
        pattern[10] <= "40000000";
        pattern[11] <= "44000000";
        pattern[12] <= "48000000";
        pattern[13] <= "52000000";
        pattern[14] <= "56000000";
        pattern[15] <= "60000000";
        pattern[16] <= "64000000";
        pattern[17] <= "68000000";
        pattern[18] <= "72000000";
        pattern[19] <= "76000000";
        pattern[20] <= "80000000";
        pattern[21] <= "84000000";
        pattern[22] <= "88000000";
        pattern[23] <= "92000000";
        pattern[24] <= "96000000";
    end
    if(usr_btn[3] && ~btn_pressed) begin
        result = 0;
        got = 0;
        time_ok = 0;
        btn_pressed = 1;
    end
    if(| bcd_valid) begin
        pattern[0] <= bcd_out[0];
        pattern[1] <= bcd_out[1];
        pattern[2] <= bcd_out[2];
        pattern[3] <= bcd_out[3];
        pattern[4] <= bcd_out[4];
        pattern[5] <= bcd_out[5];
        pattern[6] <= bcd_out[6];
        pattern[7] <= bcd_out[7];
        pattern[8] <= bcd_out[8];
        pattern[9] <= bcd_out[9];
        pattern[10] <= bcd_out[10];
        pattern[11] <= bcd_out[11];
        pattern[12] <= bcd_out[12];
        pattern[13] <= bcd_out[13];
        pattern[14] <= bcd_out[14];
        pattern[15] <= bcd_out[15];
        pattern[16] <= bcd_out[16];
        pattern[17] <= bcd_out[17];
        pattern[18] <= bcd_out[18];
        pattern[19] <= bcd_out[19];
        pattern[20] <= bcd_out[20];
        pattern[21] <= bcd_out[21];
        pattern[22] <= bcd_out[22];
        pattern[23] <= bcd_out[23];
        pattern[24] <= bcd_out[24];
    end
    
    if(| get_answer) got = 1;
    if(get_answer[0]) result = ans[0];
    if(get_answer[1]) result = ans[1];
    if(get_answer[2]) result = ans[2];
    if(get_answer[3]) result = ans[3];
    if(get_answer[4]) result = ans[4];
    if(get_answer[5]) result = ans[5];
    if(get_answer[6]) result = ans[6];
    if(get_answer[7]) result = ans[7];
    if(get_answer[8]) result = ans[8];
    if(get_answer[9]) result = ans[9];
    if(get_answer[10]) result = ans[10];
    if(get_answer[11]) result = ans[11];
    if(get_answer[12]) result = ans[12];
    if(get_answer[13]) result = ans[13];
    if(get_answer[14]) result = ans[14];
    if(get_answer[15]) result = ans[15];
    if(get_answer[16]) result = ans[16];
    if(get_answer[17]) result = ans[17];
    if(get_answer[18]) result = ans[18];
    if(get_answer[19]) result = ans[19];
    if(get_answer[20]) result = ans[20];
    if(get_answer[21]) result = ans[21];
    if(get_answer[22]) result = ans[22];
    if(get_answer[23]) result = ans[23];
    if(get_answer[24]) result = ans[24];
    
    if(time_valid) begin
        timer = time_bcd;
        time_ok = 1; 
    end
    if(~time_ok && btn_pressed) begin
        if(btn_pressed) begin
            row_A <= "Cracking...     ";
            row_B <= "................";
        end
        else if(~btn_pressed) begin
            row_A <= "Press btn3      ";
            row_B <= "to start...     ";
        end
    end
    if(time_ok && got) begin
        row_A <= {"Passwd: ", result};
        row_B <= {"Time: ", 
                         timer[27:24]+"0",
                         timer[23:20]+"0",
                         timer[19:16]+"0",
                         timer[15:12]+"0",
                         timer[11:8]+"0",
                         timer[7:4]+"0",
                         timer[3:0]+"0",
                         " ms"};
    end
end
LCD_module lcd(.clk(clk), .reset(~reset_n), .row_A(row_A), .row_B(row_B),
                .LCD_E(LCD_E), .LCD_RS(LCD_RS), .LCD_RW(LCD_RW), .LCD_D(LCD_D));
   
binary_2_bcd b2b(.clk(clk), .reset_n(reset_n), .enable(~md5_enable && btn_pressed), .binary(timer_ms),.valid(time_valid),.bcd(time_bcd));

bcd bcd_module_0(.clk(clk), .reset_n(reset_n),.enable(bcd_enable),.init_start("00000000"),.number_now(pattern[0]),
                .ascii_out(bcd_out[0]),.valid(bcd_valid[0]));

bcd bcd_module_1(.clk(clk), .reset_n(reset_n),.enable(bcd_enable),.init_start("04000000"),.number_now(pattern[1]),
                .ascii_out(bcd_out[1]),.valid(bcd_valid[1]));
                
bcd bcd_module_2(.clk(clk), .reset_n(reset_n),.enable(bcd_enable),.init_start("08000000"),.number_now(pattern[2]),
                .ascii_out(bcd_out[2]),.valid(bcd_valid[2]));

bcd bcd_module_3(.clk(clk), .reset_n(reset_n),.enable(bcd_enable),.init_start("12000000"),.number_now(pattern[3]),
                .ascii_out(bcd_out[3]),.valid(bcd_valid[3]));
                                
bcd bcd_module_4(.clk(clk), .reset_n(reset_n),.enable(bcd_enable),.init_start("16000000"),.number_now(pattern[4]),
                .ascii_out(bcd_out[4]),.valid(bcd_valid[4]));
                
bcd bcd_module_5(.clk(clk), .reset_n(reset_n),.enable(bcd_enable),.init_start("20000000"),.number_now(pattern[5]),
                .ascii_out(bcd_out[5]),.valid(bcd_valid[5]));

bcd bcd_module_6(.clk(clk), .reset_n(reset_n),.enable(bcd_enable),.init_start("24000000"),.number_now(pattern[6]),
                .ascii_out(bcd_out[6]),.valid(bcd_valid[6]));
                
bcd bcd_module_7(.clk(clk), .reset_n(reset_n),.enable(bcd_enable),.init_start("28000000"),.number_now(pattern[7]),
                .ascii_out(bcd_out[7]),.valid(bcd_valid[7]));

bcd bcd_module_8(.clk(clk), .reset_n(reset_n),.enable(bcd_enable),.init_start("32000000"),.number_now(pattern[8]),
                .ascii_out(bcd_out[8]),.valid(bcd_valid[8]));
                                
bcd bcd_module_9(.clk(clk), .reset_n(reset_n),.enable(bcd_enable),.init_start("36000000"),.number_now(pattern[9]),
                .ascii_out(bcd_out[9]),.valid(bcd_valid[9]));
                
bcd bcd_module_10(.clk(clk), .reset_n(reset_n),.enable(bcd_enable),.init_start("40000000"),.number_now(pattern[10]),
                .ascii_out(bcd_out[10]),.valid(bcd_valid[10]));

bcd bcd_module_11(.clk(clk), .reset_n(reset_n),.enable(bcd_enable),.init_start("44000000"),.number_now(pattern[11]),
                .ascii_out(bcd_out[11]),.valid(bcd_valid[11]));
                
bcd bcd_module_12(.clk(clk), .reset_n(reset_n),.enable(bcd_enable),.init_start("48000000"),.number_now(pattern[12]),
                .ascii_out(bcd_out[12]),.valid(bcd_valid[12]));

bcd bcd_module_13(.clk(clk), .reset_n(reset_n),.enable(bcd_enable),.init_start("52000000"),.number_now(pattern[13]),
                .ascii_out(bcd_out[13]),.valid(bcd_valid[13]));
                                
bcd bcd_module_14(.clk(clk), .reset_n(reset_n),.enable(bcd_enable),.init_start("56000000"),.number_now(pattern[14]),
                .ascii_out(bcd_out[14]),.valid(bcd_valid[14]));
                
bcd bcd_module_15(.clk(clk), .reset_n(reset_n),.enable(bcd_enable),.init_start("60000000"),.number_now(pattern[15]),
                .ascii_out(bcd_out[15]),.valid(bcd_valid[15]));

bcd bcd_module_16(.clk(clk), .reset_n(reset_n),.enable(bcd_enable),.init_start("64000000"),.number_now(pattern[16]),
                .ascii_out(bcd_out[16]),.valid(bcd_valid[16]));
                
bcd bcd_module_17(.clk(clk), .reset_n(reset_n),.enable(bcd_enable),.init_start("68000000"),.number_now(pattern[17]),
                .ascii_out(bcd_out[17]),.valid(bcd_valid[17]));

bcd bcd_module_18(.clk(clk), .reset_n(reset_n),.enable(bcd_enable),.init_start("72000000"),.number_now(pattern[18]),
                .ascii_out(bcd_out[18]),.valid(bcd_valid[18]));
                                
bcd bcd_module_19(.clk(clk), .reset_n(reset_n),.enable(bcd_enable),.init_start("76000000"),.number_now(pattern[19]),
                .ascii_out(bcd_out[19]),.valid(bcd_valid[19]));

bcd bcd_module_20(.clk(clk), .reset_n(reset_n),.enable(bcd_enable),.init_start("80000000"),.number_now(pattern[20]),
                .ascii_out(bcd_out[20]),.valid(bcd_valid[20]));

bcd bcd_module_21(.clk(clk), .reset_n(reset_n),.enable(bcd_enable),.init_start("84000000"),.number_now(pattern[21]),
                .ascii_out(bcd_out[21]),.valid(bcd_valid[21]));
                
bcd bcd_module_22(.clk(clk), .reset_n(reset_n),.enable(bcd_enable),.init_start("88000000"),.number_now(pattern[22]),
                .ascii_out(bcd_out[22]),.valid(bcd_valid[22]));

bcd bcd_module_23(.clk(clk), .reset_n(reset_n),.enable(bcd_enable),.init_start("92000000"),.number_now(pattern[23]),
                .ascii_out(bcd_out[23]),.valid(bcd_valid[23]));
                                
bcd bcd_module_24(.clk(clk), .reset_n(reset_n),.enable(bcd_enable),.init_start("96000000"),.number_now(pattern[24]),
                .ascii_out(bcd_out[24]),.valid(bcd_valid[24]));



md5 md5_module_0(.clk(clk), .reset_n(reset_n), .enable(md5_enable),.passwd_hash(passwd),.pattern(pattern[0]),
                .valid(valid[0]), .get_answer(get_answer[0]), .answer(ans[0]));
                
md5 md5_module_1(.clk(clk), .reset_n(reset_n), .enable(md5_enable),.passwd_hash(passwd),.pattern(pattern[1]),
                .valid(valid[1]), .get_answer(get_answer[1]), .answer(ans[1]));
                
md5 md5_module_2(.clk(clk), .reset_n(reset_n), .enable(md5_enable),.passwd_hash(passwd),.pattern(pattern[2]),
                .valid(valid[2]), .get_answer(get_answer[2]), .answer(ans[2]));
                
md5 md5_module_3(.clk(clk), .reset_n(reset_n), .enable(md5_enable),.passwd_hash(passwd),.pattern(pattern[3]),
                .valid(valid[3]), .get_answer(get_answer[3]), .answer(ans[3]));                    
                            
md5 md5_module_4(.clk(clk), .reset_n(reset_n), .enable(md5_enable),.passwd_hash(passwd),.pattern(pattern[4]),
                .valid(valid[4]), .get_answer(get_answer[4]), .answer(ans[4]));

md5 md5_module_5(.clk(clk), .reset_n(reset_n), .enable(md5_enable),.passwd_hash(passwd),.pattern(pattern[5]),
                .valid(valid[5]), .get_answer(get_answer[5]), .answer(ans[5]));
                
md5 md5_module_6(.clk(clk), .reset_n(reset_n), .enable(md5_enable),.passwd_hash(passwd),.pattern(pattern[6]),
                .valid(valid[6]), .get_answer(get_answer[6]), .answer(ans[6]));
                
md5 md5_module_7(.clk(clk), .reset_n(reset_n), .enable(md5_enable),.passwd_hash(passwd),.pattern(pattern[7]),
                .valid(valid[7]), .get_answer(get_answer[7]), .answer(ans[7]));
                
md5 md5_module_8(.clk(clk), .reset_n(reset_n), .enable(md5_enable),.passwd_hash(passwd),.pattern(pattern[8]),
                .valid(valid[8]), .get_answer(get_answer[8]), .answer(ans[8]));                    
                            
md5 md5_module_9(.clk(clk), .reset_n(reset_n), .enable(md5_enable),.passwd_hash(passwd),.pattern(pattern[9]),
                .valid(valid[9]), .get_answer(get_answer[9]), .answer(ans[9]));
                
md5 md5_module_10(.clk(clk), .reset_n(reset_n), .enable(md5_enable),.passwd_hash(passwd),.pattern(pattern[10]),
            .valid(valid[10]), .get_answer(get_answer[10]), .answer(ans[10]));
            
md5 md5_module_11(.clk(clk), .reset_n(reset_n), .enable(md5_enable),.passwd_hash(passwd),.pattern(pattern[11]),
            .valid(valid[11]), .get_answer(get_answer[11]), .answer(ans[11]));
            
md5 md5_module_12(.clk(clk), .reset_n(reset_n), .enable(md5_enable),.passwd_hash(passwd),.pattern(pattern[12]),
            .valid(valid[12]), .get_answer(get_answer[12]), .answer(ans[12]));
            
md5 md5_module_13(.clk(clk), .reset_n(reset_n), .enable(md5_enable),.passwd_hash(passwd),.pattern(pattern[13]),
            .valid(valid[13]), .get_answer(get_answer[13]), .answer(ans[13]));                    
                        
md5 md5_module_14(.clk(clk), .reset_n(reset_n), .enable(md5_enable),.passwd_hash(passwd),.pattern(pattern[14]),
            .valid(valid[14]), .get_answer(get_answer[14]), .answer(ans[14]));

md5 md5_module_15(.clk(clk), .reset_n(reset_n), .enable(md5_enable),.passwd_hash(passwd),.pattern(pattern[15]),
            .valid(valid[15]), .get_answer(get_answer[15]), .answer(ans[15]));
            
md5 md5_module_16(.clk(clk), .reset_n(reset_n), .enable(md5_enable),.passwd_hash(passwd),.pattern(pattern[16]),
            .valid(valid[16]), .get_answer(get_answer[16]), .answer(ans[16]));
            
md5 md5_module_17(.clk(clk), .reset_n(reset_n), .enable(md5_enable),.passwd_hash(passwd),.pattern(pattern[17]),
            .valid(valid[17]), .get_answer(get_answer[17]), .answer(ans[17]));
            
md5 md5_module_18(.clk(clk), .reset_n(reset_n), .enable(md5_enable),.passwd_hash(passwd),.pattern(pattern[18]),
            .valid(valid[18]), .get_answer(get_answer[18]), .answer(ans[18]));                    
                        
md5 md5_module_19(.clk(clk), .reset_n(reset_n), .enable(md5_enable),.passwd_hash(passwd),.pattern(pattern[19]),
            .valid(valid[19]), .get_answer(get_answer[19]), .answer(ans[19]));
            
md5 md5_module_20(.clk(clk), .reset_n(reset_n), .enable(md5_enable),.passwd_hash(passwd),.pattern(pattern[20]),
            .valid(valid[20]), .get_answer(get_answer[20]), .answer(ans[20]));
            
md5 md5_module_21(.clk(clk), .reset_n(reset_n), .enable(md5_enable),.passwd_hash(passwd),.pattern(pattern[21]),
            .valid(valid[21]), .get_answer(get_answer[21]), .answer(ans[21]));
            
md5 md5_module_22(.clk(clk), .reset_n(reset_n), .enable(md5_enable),.passwd_hash(passwd),.pattern(pattern[22]),
            .valid(valid[22]), .get_answer(get_answer[22]), .answer(ans[22]));
            
md5 md5_module_23(.clk(clk), .reset_n(reset_n), .enable(md5_enable),.passwd_hash(passwd),.pattern(pattern[23]),
            .valid(valid[23]), .get_answer(get_answer[23]), .answer(ans[23]));                    
                        
md5 md5_module_24(.clk(clk), .reset_n(reset_n), .enable(md5_enable),.passwd_hash(passwd),.pattern(pattern[24]),
            .valid(valid[24]), .get_answer(get_answer[24]), .answer(ans[24]));
endmodule
