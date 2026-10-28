// Simulation model of bram.vhd's dpram (altsyncram BIDIR_DUAL_PORT, one
// clock, both ports' addresses and writes registered under their clock
// enables, outputs unregistered, the new data on a same-port read during a
// write, all ones while CS is low).  Only for Verilator; Quartus builds
// bram.vhd.

module dpram
#(
	parameter addr_width    = 8,
	parameter data_width    = 8,
	parameter mem_init_file = " "
)
(
	input                       clock,

	input      [addr_width-1:0] address_a,
	input      [data_width-1:0] data_a = '0,
	input                       enable_a = 1'b1,
	input                       wren_a = 1'b0,
	output     [data_width-1:0] q_a,
	input                       cs_a = 1'b1,

	input      [addr_width-1:0] address_b = '0,
	input      [data_width-1:0] data_b = '0,
	input                       enable_b = 1'b1,
	input                       wren_b = 1'b0,
	output     [data_width-1:0] q_b,
	input                       cs_b = 1'b1
);

reg [data_width-1:0] mem [0:(1<<addr_width)-1];
reg [addr_width-1:0] ra, rb;

initial begin : init
	integer i;
	for (i = 0; i < (1<<addr_width); i = i + 1) mem[i] = '0;
end

always @(posedge clock) begin
	if (enable_a) begin
		ra <= address_a;
		if (wren_a & cs_a) mem[address_a] <= data_a;
	end
	if (enable_b) begin
		rb <= address_b;
		if (wren_b & cs_b) mem[address_b] <= data_b;
	end
end

assign q_a = cs_a ? mem[ra] : '1;
assign q_b = cs_b ? mem[rb] : '1;

endmodule
