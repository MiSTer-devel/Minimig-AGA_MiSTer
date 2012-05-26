/* lcd.v */


module lcd(
  input  wire           clk,
  input  wire           rst,
  input  wire           sof,
  input  wire [  4-1:0] r,
  input  wire [  4-1:0] g,
  input  wire [  4-1:0] b,
  output reg  [ 16-1:0] lcd_dat,
  output reg            lcd_cs,
  output reg            lcd_rs,
  output reg            lcd_wr,
  output reg            lcd_rd,
  output reg            lcd_res
);


//// start of frame marker ////
reg  [  4-1:0] sofm;
always @ (posedge clk, posedge rst) begin
  if (rst)
    sofm <= #1 4'h0;
  else if (sof)
    sofm <= #1 4'h1;
  else if (|sofm)
    sofm <= #1 sofm + 4'h1;
end


//// lcd init counter ////
reg  [  8-1:0] init_cnt;

always @ (posedge clk, posedge rst) begin
  if (rst)
    init_cnt <= #1 'd0;
  else if (init_cnt < 'd162)
    init_cnt <= #1 init_cnt + 'd1;
end


//// lcd init sm ////
reg  [ 16-1:0] dat;
reg            cs;
reg            rs;
reg            wr;
reg            rd;

always @ (*) begin
  case (init_cnt)
    'd000 : begin dat = 16'h0000; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    // Oscillator enable
    'd001 : begin dat = 16'h0000; cs = 1'b0; rs = 1'b0; wr = 1'b0; rd = 1'b1; end
    'd002 : begin dat = 16'h0000; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    'd003 : begin dat = 16'h0001; cs = 1'b0; rs = 1'b1; wr = 1'b0; rd = 1'b1; end
    'd004 : begin dat = 16'h0001; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    // Power control 1
    'd005 : begin dat = 16'h0003; cs = 1'b0; rs = 1'b0; wr = 1'b0; rd = 1'b1; end
    'd006 : begin dat = 16'h0003; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    'd007 : begin dat = 16'ha8a4; cs = 1'b0; rs = 1'b1; wr = 1'b0; rd = 1'b1; end
    'd008 : begin dat = 16'ha8a4; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    // Power control 2
    'd009 : begin dat = 16'h000c; cs = 1'b0; rs = 1'b0; wr = 1'b0; rd = 1'b1; end
    'd010 : begin dat = 16'h000c; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    'd011 : begin dat = 16'h0000; cs = 1'b0; rs = 1'b1; wr = 1'b0; rd = 1'b1; end
    'd012 : begin dat = 16'h0000; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    // Power control 3
    'd013 : begin dat = 16'h000d; cs = 1'b0; rs = 1'b0; wr = 1'b0; rd = 1'b1; end
    'd014 : begin dat = 16'h000d; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    'd015 : begin dat = 16'h080c; cs = 1'b0; rs = 1'b1; wr = 1'b0; rd = 1'b1; end
    'd016 : begin dat = 16'h080c; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    // Power control 4
    'd017 : begin dat = 16'h000e; cs = 1'b0; rs = 1'b0; wr = 1'b0; rd = 1'b1; end
    'd018 : begin dat = 16'h000e; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    'd019 : begin dat = 16'h2b00; cs = 1'b0; rs = 1'b1; wr = 1'b0; rd = 1'b1; end
    'd020 : begin dat = 16'h2b00; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    // Power control 5
    'd021 : begin dat = 16'h001e; cs = 1'b0; rs = 1'b0; wr = 1'b0; rd = 1'b1; end
    'd022 : begin dat = 16'h001e; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    'd023 : begin dat = 16'h00b0; cs = 1'b0; rs = 1'b1; wr = 1'b0; rd = 1'b1; end
    'd024 : begin dat = 16'h00b0; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    // Driver output control
    'd021 : begin dat = 16'h0001; cs = 1'b0; rs = 1'b0; wr = 1'b0; rd = 1'b1; end
    'd022 : begin dat = 16'h0001; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    'd023 : begin dat = 16'h2b3f; cs = 1'b0; rs = 1'b1; wr = 1'b0; rd = 1'b1; end
    'd024 : begin dat = 16'h2b3f; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    // LCD-Driving Waveform Control
    'd025 : begin dat = 16'h0002; cs = 1'b0; rs = 1'b0; wr = 1'b0; rd = 1'b1; end
    'd026 : begin dat = 16'h0002; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    'd027 : begin dat = 16'h0600; cs = 1'b0; rs = 1'b1; wr = 1'b0; rd = 1'b1; end
    'd028 : begin dat = 16'h0600; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    // Sleep mode
    'd029 : begin dat = 16'h0010; cs = 1'b0; rs = 1'b0; wr = 1'b0; rd = 1'b1; end
    'd030 : begin dat = 16'h0010; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    'd031 : begin dat = 16'h0000; cs = 1'b0; rs = 1'b1; wr = 1'b0; rd = 1'b1; end
    'd032 : begin dat = 16'h0000; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    // Entry Mode
    'd033 : begin dat = 16'h0011; cs = 1'b0; rs = 1'b0; wr = 1'b0; rd = 1'b1; end
    'd034 : begin dat = 16'h0011; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    'd035 : begin dat = 16'h6078; cs = 1'b0; rs = 1'b1; wr = 1'b0; rd = 1'b1; end
    'd036 : begin dat = 16'h6078; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    // Compare Register
    'd037 : begin dat = 16'h0005; cs = 1'b0; rs = 1'b0; wr = 1'b0; rd = 1'b1; end
    'd038 : begin dat = 16'h0005; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    'd039 : begin dat = 16'h0000; cs = 1'b0; rs = 1'b1; wr = 1'b0; rd = 1'b1; end
    'd040 : begin dat = 16'h0000; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    // Compare Register
    'd041 : begin dat = 16'h0006; cs = 1'b0; rs = 1'b0; wr = 1'b0; rd = 1'b1; end
    'd042 : begin dat = 16'h0006; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    'd043 : begin dat = 16'h0000; cs = 1'b0; rs = 1'b1; wr = 1'b0; rd = 1'b1; end
    'd044 : begin dat = 16'h0000; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    // Horizontal Porch
    'd045 : begin dat = 16'h0016; cs = 1'b0; rs = 1'b0; wr = 1'b0; rd = 1'b1; end
    'd046 : begin dat = 16'h0016; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    'd047 : begin dat = 16'hef1c; cs = 1'b0; rs = 1'b1; wr = 1'b0; rd = 1'b1; end
    'd048 : begin dat = 16'hef1c; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    // Vertical Porch
    'd049 : begin dat = 16'h0017; cs = 1'b0; rs = 1'b0; wr = 1'b0; rd = 1'b1; end
    'd050 : begin dat = 16'h0017; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    'd051 : begin dat = 16'h0003; cs = 1'b0; rs = 1'b1; wr = 1'b0; rd = 1'b1; end
    'd052 : begin dat = 16'h0003; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    // Display Control
    'd053 : begin dat = 16'h0007; cs = 1'b0; rs = 1'b0; wr = 1'b0; rd = 1'b1; end
    'd054 : begin dat = 16'h0007; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    'd055 : begin dat = 16'h0233; cs = 1'b0; rs = 1'b1; wr = 1'b0; rd = 1'b1; end
    'd056 : begin dat = 16'h0233; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    // Frame Cycle Control
    'd057 : begin dat = 16'h000b; cs = 1'b0; rs = 1'b0; wr = 1'b0; rd = 1'b1; end
    'd058 : begin dat = 16'h000b; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    'd059 : begin dat = 16'h0000; cs = 1'b0; rs = 1'b1; wr = 1'b0; rd = 1'b1; end
    'd060 : begin dat = 16'h0000; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    // Gate Scan Position
    'd061 : begin dat = 16'h000f; cs = 1'b0; rs = 1'b0; wr = 1'b0; rd = 1'b1; end
    'd062 : begin dat = 16'h000f; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    'd063 : begin dat = 16'h0000; cs = 1'b0; rs = 1'b1; wr = 1'b0; rd = 1'b1; end
    'd064 : begin dat = 16'h0000; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    // Vertical Scan Control
    'd065 : begin dat = 16'h0041; cs = 1'b0; rs = 1'b0; wr = 1'b0; rd = 1'b1; end
    'd066 : begin dat = 16'h0041; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    'd067 : begin dat = 16'h0000; cs = 1'b0; rs = 1'b1; wr = 1'b0; rd = 1'b1; end
    'd068 : begin dat = 16'h0000; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    // Vertical Scan Control
    'd069 : begin dat = 16'h0042; cs = 1'b0; rs = 1'b0; wr = 1'b0; rd = 1'b1; end
    'd070 : begin dat = 16'h0042; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    'd071 : begin dat = 16'h0000; cs = 1'b0; rs = 1'b1; wr = 1'b0; rd = 1'b1; end
    'd072 : begin dat = 16'h0000; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    // 1st Screen Driving Position
    'd073 : begin dat = 16'h0048; cs = 1'b0; rs = 1'b0; wr = 1'b0; rd = 1'b1; end
    'd074 : begin dat = 16'h0048; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    'd075 : begin dat = 16'h0000; cs = 1'b0; rs = 1'b1; wr = 1'b0; rd = 1'b1; end
    'd076 : begin dat = 16'h0000; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    // 1st Screen Driving Position
    'd077 : begin dat = 16'h0049; cs = 1'b0; rs = 1'b0; wr = 1'b0; rd = 1'b1; end
    'd078 : begin dat = 16'h0049; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    'd079 : begin dat = 16'h013f; cs = 1'b0; rs = 1'b1; wr = 1'b0; rd = 1'b1; end
    'd080 : begin dat = 16'h013f; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    // 2nd Screen Driving Position
    'd081 : begin dat = 16'h004a; cs = 1'b0; rs = 1'b0; wr = 1'b0; rd = 1'b1; end
    'd082 : begin dat = 16'h004a; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    'd083 : begin dat = 16'h0000; cs = 1'b0; rs = 1'b1; wr = 1'b0; rd = 1'b1; end
    'd084 : begin dat = 16'h0000; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    // 2nd Screen Driving Position
    'd085 : begin dat = 16'h004b; cs = 1'b0; rs = 1'b0; wr = 1'b0; rd = 1'b1; end
    'd086 : begin dat = 16'h004b; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    'd087 : begin dat = 16'h0000; cs = 1'b0; rs = 1'b1; wr = 1'b0; rd = 1'b1; end
    'd088 : begin dat = 16'h0000; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    // Horizontal RAM address position
    'd089 : begin dat = 16'h0044; cs = 1'b0; rs = 1'b0; wr = 1'b0; rd = 1'b1; end
    'd090 : begin dat = 16'h0044; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    'd091 : begin dat = 16'hef00; cs = 1'b0; rs = 1'b1; wr = 1'b0; rd = 1'b1; end
    'd092 : begin dat = 16'hef00; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    // Vertical RAM address position
    'd093 : begin dat = 16'h0045; cs = 1'b0; rs = 1'b0; wr = 1'b0; rd = 1'b1; end
    'd094 : begin dat = 16'h0045; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    'd095 : begin dat = 16'h0000; cs = 1'b0; rs = 1'b1; wr = 1'b0; rd = 1'b1; end
    'd096 : begin dat = 16'h0000; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    // Vertical RAM address position
    'd097 : begin dat = 16'h0046; cs = 1'b0; rs = 1'b0; wr = 1'b0; rd = 1'b1; end
    'd098 : begin dat = 16'h0046; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    'd099 : begin dat = 16'h013f; cs = 1'b0; rs = 1'b1; wr = 1'b0; rd = 1'b1; end
    'd100 : begin dat = 16'h013f; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    // Gamma Control
    'd101 : begin dat = 16'h0030; cs = 1'b0; rs = 1'b0; wr = 1'b0; rd = 1'b1; end
    'd102 : begin dat = 16'h0030; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    'd103 : begin dat = 16'h0707; cs = 1'b0; rs = 1'b1; wr = 1'b0; rd = 1'b1; end
    'd104 : begin dat = 16'h0707; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    // Gamma Control
    'd105 : begin dat = 16'h0031; cs = 1'b0; rs = 1'b0; wr = 1'b0; rd = 1'b1; end
    'd106 : begin dat = 16'h0031; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    'd107 : begin dat = 16'h0204; cs = 1'b0; rs = 1'b1; wr = 1'b0; rd = 1'b1; end
    'd108 : begin dat = 16'h0204; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    // Gamma Control
    'd109 : begin dat = 16'h0032; cs = 1'b0; rs = 1'b0; wr = 1'b0; rd = 1'b1; end
    'd110 : begin dat = 16'h0032; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    'd111 : begin dat = 16'h0204; cs = 1'b0; rs = 1'b1; wr = 1'b0; rd = 1'b1; end
    'd112 : begin dat = 16'h0204; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    // Gamma Control
    'd113 : begin dat = 16'h0033; cs = 1'b0; rs = 1'b0; wr = 1'b0; rd = 1'b1; end
    'd114 : begin dat = 16'h0033; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    'd115 : begin dat = 16'h0502; cs = 1'b0; rs = 1'b1; wr = 1'b0; rd = 1'b1; end
    'd116 : begin dat = 16'h0502; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    // Gamma Control
    'd117 : begin dat = 16'h0034; cs = 1'b0; rs = 1'b0; wr = 1'b0; rd = 1'b1; end
    'd118 : begin dat = 16'h0034; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    'd119 : begin dat = 16'h0507; cs = 1'b0; rs = 1'b1; wr = 1'b0; rd = 1'b1; end
    'd120 : begin dat = 16'h0507; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    // Gamma Control
    'd121 : begin dat = 16'h0035; cs = 1'b0; rs = 1'b0; wr = 1'b0; rd = 1'b1; end
    'd122 : begin dat = 16'h0035; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    'd123 : begin dat = 16'h0204; cs = 1'b0; rs = 1'b1; wr = 1'b0; rd = 1'b1; end
    'd124 : begin dat = 16'h0204; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    // Gamma Control
    'd125 : begin dat = 16'h0036; cs = 1'b0; rs = 1'b0; wr = 1'b0; rd = 1'b1; end
    'd126 : begin dat = 16'h0036; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    'd127 : begin dat = 16'h0204; cs = 1'b0; rs = 1'b1; wr = 1'b0; rd = 1'b1; end
    'd128 : begin dat = 16'h0204; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    // Gamma Control
    'd129 : begin dat = 16'h0037; cs = 1'b0; rs = 1'b0; wr = 1'b0; rd = 1'b1; end
    'd130 : begin dat = 16'h0037; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    'd131 : begin dat = 16'h0502; cs = 1'b0; rs = 1'b1; wr = 1'b0; rd = 1'b1; end
    'd132 : begin dat = 16'h0502; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    // Gamma Control
    'd133 : begin dat = 16'h003a; cs = 1'b0; rs = 1'b0; wr = 1'b0; rd = 1'b1; end
    'd134 : begin dat = 16'h003a; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    'd135 : begin dat = 16'h0302; cs = 1'b0; rs = 1'b1; wr = 1'b0; rd = 1'b1; end
    'd136 : begin dat = 16'h0302; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    // Gamma Control
    'd137 : begin dat = 16'h003b; cs = 1'b0; rs = 1'b0; wr = 1'b0; rd = 1'b1; end
    'd138 : begin dat = 16'h003b; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    'd139 : begin dat = 16'h0302; cs = 1'b0; rs = 1'b1; wr = 1'b0; rd = 1'b1; end
    'd140 : begin dat = 16'h0302; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    // RAM write data mask
    'd141 : begin dat = 16'h0023; cs = 1'b0; rs = 1'b0; wr = 1'b0; rd = 1'b1; end
    'd142 : begin dat = 16'h0023; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    'd143 : begin dat = 16'h0000; cs = 1'b0; rs = 1'b1; wr = 1'b0; rd = 1'b1; end
    'd144 : begin dat = 16'h0000; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    // RAM write data mask
    'd145 : begin dat = 16'h0024; cs = 1'b0; rs = 1'b0; wr = 1'b0; rd = 1'b1; end
    'd146 : begin dat = 16'h0024; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    'd147 : begin dat = 16'h0000; cs = 1'b0; rs = 1'b1; wr = 1'b0; rd = 1'b1; end
    'd148 : begin dat = 16'h0000; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    // Frame frequency control
    'd149 : begin dat = 16'h0025; cs = 1'b0; rs = 1'b0; wr = 1'b0; rd = 1'b1; end
    'd150 : begin dat = 16'h0025; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    'd151 : begin dat = 16'h8000; cs = 1'b0; rs = 1'b1; wr = 1'b0; rd = 1'b1; end
    'd152 : begin dat = 16'h8000; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    // RAM address set
    'd153 : begin dat = 16'h004f; cs = 1'b0; rs = 1'b0; wr = 1'b0; rd = 1'b1; end
    'd154 : begin dat = 16'h004f; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    'd155 : begin dat = 16'h0000; cs = 1'b0; rs = 1'b1; wr = 1'b0; rd = 1'b1; end
    'd156 : begin dat = 16'h0000; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    // RAM address set
    'd157 : begin dat = 16'h004e; cs = 1'b0; rs = 1'b0; wr = 1'b0; rd = 1'b1; end
    'd158 : begin dat = 16'h004e; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    'd159 : begin dat = 16'h0000; cs = 1'b0; rs = 1'b1; wr = 1'b0; rd = 1'b1; end
    'd160 : begin dat = 16'h0000; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
    // default is control from frame start & data
    default: begin
      // start of frame (reset position to 0,0 & send write command)
      case (sofm)
        'd01 : begin dat = 16'h004f; cs = 1'b0; rs = 1'b0; wr = 1'b0; rd = 1'b1; end
        'd02 : begin dat = 16'h004f; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
        'd03 : begin dat = 16'h0000; cs = 1'b0; rs = 1'b1; wr = 1'b0; rd = 1'b1; end
        'd04 : begin dat = 16'h0000; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
        'd05 : begin dat = 16'h004e; cs = 1'b0; rs = 1'b0; wr = 1'b0; rd = 1'b1; end
        'd06 : begin dat = 16'h004e; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
        'd07 : begin dat = 16'h0000; cs = 1'b0; rs = 1'b1; wr = 1'b0; rd = 1'b1; end
        'd08 : begin dat = 16'h0000; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
        'd09 : begin dat = 16'h0022; cs = 1'b0; rs = 1'b0; wr = 1'b0; rd = 1'b1; end
        'd10 : begin dat = 16'h0022; cs = 1'b1; rs = 1'b1; wr = 1'b1; rd = 1'b1; end
        default : begin

        end
      endcase
    end
  endcase
end


//// register outputs ////
always @ (posedge clk, posedge rst) begin
  if (rst)
    lcd_res <= #1 1'b0;
  else
    lcd_res <= #1 1'b1;
end

always @ (posedge clk) begin
  lcd_dat <= #1 dat;
  lcd_cs  <= #1 cs;
  lcd_rs  <= #1 rs;
  lcd_wr  <= #1 wr;
  lcd_rd  <= #1 rd;
end


endmodule

