// Copyright 2026 (CDTV native-mode bridge)
//
// This file is part of Minimig
//
// Minimig is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 3 of the License, or
// (at your option) any later version.
//
// Minimig is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

module cdtv_nvram
#(
	parameter ADDR_W = 14
)
(
	input             clk,
	input             reset,

	input             sel,
	input      [23:1] addr,
	input      [15:0] din,
	output     [15:0] dout,
	input             rd,
	input             hwr,
	input             lwr,

	input  [ADDR_W-1:0] hps_load_addr,
	input         [7:0] hps_load_din,
	input               hps_load_we,

	input  [ADDR_W-1:0] hps_save_addr,
	output        [7:0] hps_save_dout,

	output reg        dirty = 1'b0,
	input             clear_dirty
);

localparam WORD_W = ADDR_W - 1;
localparam WORDS  = 1 << WORD_W;

wire [WORD_W-1:0] cpu_addr    = addr[ADDR_W-1:1];
wire        [1:0] cpu_byteena = {sel & hwr, sel & lwr};
wire              cpu_we      = sel & (hwr | lwr);

wire              hps_byte    = hps_load_addr[0];
wire [WORD_W-1:0] hps_addr    = hps_load_we ? hps_load_addr[ADDR_W-1:1] : hps_save_addr[ADDR_W-1:1];
wire       [15:0] hps_data    = {hps_load_din, hps_load_din};
wire        [1:0] hps_byteena = {~hps_byte, hps_byte};

wire [15:0] save_q;

altsyncram nvram_inst (
	.address_a      (cpu_addr),
	.clock0         (clk),
	.data_a         (din),
	.byteena_a      (cpu_byteena),
	.wren_a         (cpu_we),
	.q_a            (dout),
	.address_b      (hps_addr),
	.data_b         (hps_data),
	.byteena_b      (hps_byteena),
	.wren_b         (hps_load_we),
	.q_b            (save_q),
	.aclr0          (1'b0),
	.aclr1          (1'b0),
	.addressstall_a (1'b0),
	.addressstall_b (1'b0),
	.clock1         (1'b1),
	.clocken0       (1'b1),
	.clocken1       (1'b1),
	.clocken2       (1'b1),
	.clocken3       (1'b1),
	.eccstatus      (),
	.rden_a         (1'b1),
	.rden_b         (1'b1)
);
defparam
	nvram_inst.address_reg_b                      = "CLOCK0",
	nvram_inst.byteena_reg_b                      = "CLOCK0",
	nvram_inst.indata_reg_b                       = "CLOCK0",
	nvram_inst.wrcontrol_wraddress_reg_b          = "CLOCK0",
	nvram_inst.clock_enable_input_a               = "BYPASS",
	nvram_inst.clock_enable_input_b               = "BYPASS",
	nvram_inst.clock_enable_output_a              = "BYPASS",
	nvram_inst.clock_enable_output_b              = "BYPASS",
	nvram_inst.intended_device_family             = "Cyclone V",
	nvram_inst.lpm_type                           = "altsyncram",
	nvram_inst.numwords_a                         = WORDS,
	nvram_inst.numwords_b                         = WORDS,
	nvram_inst.operation_mode                     = "BIDIR_DUAL_PORT",
	nvram_inst.outdata_aclr_a                     = "NONE",
	nvram_inst.outdata_aclr_b                     = "NONE",
	nvram_inst.outdata_reg_a                      = "UNREGISTERED",
	nvram_inst.outdata_reg_b                      = "UNREGISTERED",
	nvram_inst.power_up_uninitialized             = "FALSE",
	nvram_inst.ram_block_type                     = "M10K",
	nvram_inst.read_during_write_mode_mixed_ports = "OLD_DATA",
	nvram_inst.read_during_write_mode_port_a      = "NEW_DATA_NO_NBE_READ",
	nvram_inst.read_during_write_mode_port_b      = "NEW_DATA_NO_NBE_READ",
	nvram_inst.widthad_a                          = WORD_W,
	nvram_inst.widthad_b                          = WORD_W,
	nvram_inst.width_a                            = 16,
	nvram_inst.width_b                            = 16,
	nvram_inst.width_byteena_a                    = 2,
	nvram_inst.width_byteena_b                    = 2;

assign hps_save_dout = hps_save_addr[0] ? save_q[7:0] : save_q[15:8];

always @(posedge clk) begin
	if (sel & (hwr | lwr)) dirty <= 1'b1;
	else if (clear_dirty)  dirty <= 1'b0;
end

endmodule
