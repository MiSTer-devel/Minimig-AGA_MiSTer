/* amiga_clk.v */
/* 2012, rok.krajnc@gmail.com */

module amiga_clk (
  input        rst,        // asynhronous reset input
  input        clk_in,     // input clock        ( 27.000000MHz)
  output       clk_114,    // SDRAM ctrl   clock (114.750000MHz)
  output       clk_sdram,  // SDRAM output clock (114.750000MHz, -146.25 deg)
  output       clk_28,     // 28MHz output clock ( 28.375160MHz)
  output       clk_7,      // 7MHz  output clock (  7.171875MHz) DO NOT USE IT AS A CLOCK!
  output       clk7_en,    // 7MHz output clock enable (on 28MHz clock domain)
  output       clk7n_en,   // 7MHz negedge output clock enable (on 28MHz clock domain)
  output reg   c1,         // clk28m clock domain signal synchronous with clk signal
  output reg   c3,         // clk28m clock domain signal synchronous with clk signal delayed by 90 degrees
  output       cck,        // colour clock output (3.54 MHz)
  output [9:0] eclk,       // 0.709379 MHz clock enable output (clk domain pulse)
  output       locked      // PLL locked output
);

//// hardware clocks ////
// device-specific PLL/DCM

pll pll
(
	.refclk(clk_in),
	.rst(rst),
	.outclk_0(clk_114),
	.outclk_1(clk_sdram),
	.outclk_2(clk_28),
	.locked(locked)
);

//// generated clocks ////

// 7MHz
reg [1:0] clk7_cnt = 2'b10;
reg       clk7_en_reg = 1'b1;
reg       clk7n_en_reg = 1'b1;
always @ (posedge clk_28, negedge locked) begin
  if (!locked) begin
    clk7_cnt     <= 2'b10;
    clk7_en_reg  <= 1'b1;
    clk7n_en_reg <= 1'b1;
  end else begin
    clk7_cnt     <= clk7_cnt + 2'b01;
    clk7_en_reg  <= (clk7_cnt == 2'b00);
    clk7n_en_reg <= (clk7_cnt == 2'b10);
	 if(clk7_cnt == 2'b01) begin
		if (e_cnt == 9) e_cnt <= 0;
			else e_cnt <= e_cnt + 1'd1;
	 end
  end
end

assign clk_7 = clk7_cnt[1];
assign clk7_en = clk7_en_reg;
assign clk7n_en = clk7n_en_reg;

// amiga clocks & clock enables
//            __    __    __    __    __
// clk_28  __/  \__/  \__/  \__/  \__/  
//            ___________             __
// clk_7   __/           \___________/  
//            ___________             __
// c1      __/           \___________/   <- clk28m domain
//                  ___________
// c3      ________/           \________ <- clk28m domain
//

// clk_28 clock domain signal synchronous with clk signal delayed by 90 degrees
always @(posedge clk_28) c3 <= clk_7;

// clk28m clock domain signal synchronous with clk signal
always @(posedge clk_28) c1 <= ~c3;

// counter used to generate e clock enable
reg [3:0] e_cnt = 4'b0000;

// CCK clock output
assign cck = ~e_cnt[0];

// 0.709379 MHz clock enable output (clk domain pulse)
assign eclk[0] = ~e_cnt[3] & ~e_cnt[2] & ~e_cnt[1] & ~e_cnt[0]; // e_cnt == 0
assign eclk[1] = ~e_cnt[3] & ~e_cnt[2] & ~e_cnt[1] &  e_cnt[0]; // e_cnt == 1
assign eclk[2] = ~e_cnt[3] & ~e_cnt[2] &  e_cnt[1] & ~e_cnt[0]; // e_cnt == 2
assign eclk[3] = ~e_cnt[3] & ~e_cnt[2] &  e_cnt[1] &  e_cnt[0]; // e_cnt == 3
assign eclk[4] = ~e_cnt[3] &  e_cnt[2] & ~e_cnt[1] & ~e_cnt[0]; // e_cnt == 4
assign eclk[5] = ~e_cnt[3] &  e_cnt[2] & ~e_cnt[1] &  e_cnt[0]; // e_cnt == 5
assign eclk[6] = ~e_cnt[3] &  e_cnt[2] &  e_cnt[1] & ~e_cnt[0]; // e_cnt == 6
assign eclk[7] = ~e_cnt[3] &  e_cnt[2] &  e_cnt[1] &  e_cnt[0]; // e_cnt == 7
assign eclk[8] =  e_cnt[3] & ~e_cnt[2] & ~e_cnt[1] & ~e_cnt[0]; // e_cnt == 8
assign eclk[9] =  e_cnt[3] & ~e_cnt[2] & ~e_cnt[1] &  e_cnt[0]; // e_cnt == 9


endmodule

