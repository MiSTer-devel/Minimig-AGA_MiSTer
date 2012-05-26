/* sram_ctl.v */

module sram_ctl (
  // system
  input  wire           clk,
  input  wire           rst,
  // cpu if
  output reg            cpu_clken,
  input  wire [ 24-1:0] adr,
  input  wire           rw,
  input  wire           lds,
  input  wire           uds, 
  input  wire [ 16-1:0] dat_w,
  output wire [ 16-1:0] dat_r,
  // sram if
  output wire           ce,
  output wire           oe,
  output wire           wr,
  output wire [  2-1:0] bs,
  output wire [ 18-1:0] addr,
  inout  wire [ 16-1:0] data
);

always @ (posedge clk, posedge rst) begin
  if (rst)
    cpu_clken <= #1 1'b0;
  else if (cpu_clken == 1'b1)
    cpu_clken <= #1 1'b0;
  else if ((adr != 24'hffffff) && (!lds | !uds))
    cpu_clken <= #1 1'b1;
end

assign ce    = 1'b0;
assign oe    = ~rw;
assign wr    = rw;
assign bs    = {uds, lds};
assign addr  = adr[18:1];
assign data  = oe ? dat_w : 16'bzzzzzzzzzzzzzzzz;
assign dat_r = data;

endmodule

