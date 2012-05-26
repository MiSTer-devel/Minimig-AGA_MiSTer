/* lcd_tb.v */


`timescale 1ns/1ps


module lcd_tb();


reg            clk;
reg            rst;

wire           sof;
wire [  4-1:0] r;
wire [  4-1:0] g;
wire [  4-1:0] b;
wire [ 16-1:0] lcd_dat;
wire           lcd_cs;
wire           lcd_rs;
wire           lcd_wr;
wire           lcd_rd;
wire           lcd_res;


//// clock ////
`define CLK_HP 17.857
initial begin
  clk = 0;
  forever #`CLK_HP clk = ~clk;
end


//// reset ////
initial begin
  rst = 1;
  repeat (10) @ (posedge clk); #1;
  rst = 0;
end


//// stop ////
initial begin
  $display("LCD bench starting ...");
  repeat(1000) @ (posedge clk);
  $display("LCD bench stopping ...");
  $finish;
end

initial begin
  wait(lcd.init_cnt == 'd162);
  repeat(10) @ (posedge clk); #1;
  force sof = 1;
  @ (posedge clk); #1;
  release sof;
end


//// DUT ////
lcd lcd(
  .clk          (clk        ),
  .rst          (rst        ),
  .sof          (sof        ),
  .r            (r          ),
  .g            (g          ),
  .b            (b          ),
  .lcd_dat      (lcd_dat    ),
  .lcd_cs       (lcd_cs     ),
  .lcd_rs       (lcd_rs     ),
  .lcd_wr       (lcd_wr     ),
  .lcd_rd       (lcd_rd     ),
  .lcd_res      (lcd_res    )
);


endmodule

