/* sram_ctl.v */

module sram_ctl (
  // system
  input  wire           clk,
  input  wire           pulse,
  // fifo if
  input  wire [ 13-1:0] fifoinptr,
  input  wire [ 13-1:0] fifooutptr,
  input  wire [ 16-1:0] fifodwr,
  output wire [ 16-1:0] fifodrd,
  // sram if
  output wire           ce,
  output wire           oe,
  output wire           wr,
  output wire [  2-1:0] bs,
  output wire [ 18-1:0] addr,
  inout  wire [ 16-1:0] data
);

assign ce   = 1'b0;
assign oe   = ~clk | pulse;
assign wr   = clk | pulse | ~fifowr;
assign bs   = 2'b00;
assign addr = clk ? {5'b00000, fifooutptr} : {5'b00000, fifoinptr};
assign data = ~clk ? fifodwr : 16'bzzzzzzzzzzzzzzzz;

always @(posedge clk) begin
  fifodrd <= #1 data;
end

endmodule

