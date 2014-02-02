// tpram_inf_128x32.v
// 2013, rok.krajnc@gmail.com
// inferrable two-port memory

module tpram_inf_128x32 (
  input  wire           clock,
  input  wire [  7-1:0] wraddress,
  input  wire           wren,
  input  wire [ 32-1:0] data,
  input  wire [  7-1:0] rdaddress,
  output reg  [ 32-1:0] q
);

// memory
reg [32-1:0] mem [0:128-1];

// read / write
always @ (posedge clock) begin
  if (wren) mem[wraddress] <= #1 data;
  q <= #1 mem[rdaddress];
end

endmodule

