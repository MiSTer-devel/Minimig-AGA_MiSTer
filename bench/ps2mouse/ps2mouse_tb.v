// ps2mouse_tb.v
// 2014, rok.krajnc@gmail.com


`default_nettype none
`timescale 1ns/1ps


module ps2mouse_tb();

reg CLK7=1;
reg RST=1;

tri1 mclk;
tri1 mdat;


// testbench
initial begin
  #1;
  $display("BENCH : ps2mouse_tb BEGIN");

  repeat (200000) @ (posedge CLK7);

  $display("BENCH : ps2mouse_tb END");
  $finish();
end


// clocks & async reset
initial begin
  CLK7 = 1'b1;
  #1;
  forever #143 CLK7 = ~CLK7;
end

initial begin
  RST = 1'b1;
  #1;
  repeat(10) @ (posedge CLK7);
  RST = 1'b0;
end


// modules
ps2mouse_ctrl ps2mouse_ctrl (
  .clk    (CLK7),
  .reset  (RST),
  .mclk   (mclk),
  .mdat   (mdat)
);

ps2mouse ps2mouse (
  .clk    (CLK7),
  .rst    (RST),
  .mclk   (mclk),
  .mdat   (mdat)
);


endmodule

