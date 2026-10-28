// The PLLs of Minimig.sv for Verilator: the bench (sim_main.cpp) drives
// clk_114 and clk_sys through these public registers; locked is high.
// pll_cfg (the NTSC/PAL reconfiguration) answers at once.  Only for the
// simulation; Quartus builds the IP.

module pll
(
	input         refclk,
	output        outclk_0,
	output        outclk_1,
	input  [63:0] reconfig_to_pll,
	output [63:0] reconfig_from_pll,
	output        locked
);

reg c114 /*verilator public_flat_rw*/ = 1'b0;
reg csys /*verilator public_flat_rw*/ = 1'b0;
assign outclk_0 = c114;
assign outclk_1 = csys;
assign reconfig_from_pll = 64'd0;
assign locked = 1'b1;

endmodule

module pll_cfg
(
	input         mgmt_clk,
	input         mgmt_reset,
	output        mgmt_waitrequest,
	input         mgmt_read,
	output [31:0] mgmt_readdata,
	input         mgmt_write,
	input   [5:0] mgmt_address,
	input  [31:0] mgmt_writedata,
	output [63:0] reconfig_to_pll,
	input  [63:0] reconfig_from_pll
);

assign mgmt_waitrequest = 1'b0;
assign mgmt_readdata = 32'd0;
assign reconfig_to_pll = 64'd0;

endmodule
