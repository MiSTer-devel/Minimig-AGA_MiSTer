// DE1 external clocks and resets
// 2013, rok.krajnc@gmail.com


//// timescale ////
`timescale 1ns/1ps


//// clock defines ////
`define HP_24  20.833
`define HP_27  18.519
`define HP_50  10.000
`define HP_EXT  5.000


//// module ////
module de1_clk_rst (
  output reg  CLOCK24,
  output reg  CLOCK27,
  output reg  CLOCK50,
  output reg  CLOCKEXT,
  output reg  RST
);


//// clocks & async reset ////
initial begin
  CLOCK24  = 1'b1;
  #2;
  forever #`HP_24 CLOCK24 = ~CLOCK24;
end

initial begin
  CLOCK27  = 1'b1;
  #3;
  forever #`HP_27 CLOCK27 = ~CLOCK27;
end

initial begin
  CLOCK50  = 1'b1;
  #5;
  forever #`HP_50 CLOCK50 = ~CLOCK50;
end

initial begin
  CLOCKEXT = 1'b1;
  #7;
  forever #`HP_EXT CLOCKEXT = ~CLOCKEXT;
end

initial begin
  RST = 1'b1;
  #101;
  RST = 1'b0;
end


endmodule

