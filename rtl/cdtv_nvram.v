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

	input      [13:0] hps_load_addr,
	input       [7:0] hps_load_din,
	input             hps_load_we,

	input      [13:0] hps_save_addr,
	output      [7:0] hps_save_dout,

	output reg        dirty = 1'b0,
	input             clear_dirty
);

wire [12:0] cpu_waddr = addr[13:1];
wire [12:0] hps_waddr = hps_load_addr[13:1];
wire        hps_byte  = hps_load_addr[0];

wire [12:0] write_addr    = hps_load_we ? hps_waddr : cpu_waddr;
wire [15:0] write_data    = hps_load_we ? {hps_load_din, hps_load_din} : din;
wire [1:0]  write_byteena = hps_load_we ? {~hps_byte, hps_byte}
                                        : {sel & hwr, sel & lwr};
wire        write_we      = hps_load_we | (sel & (hwr | lwr));

altsyncram nvram_inst (
	.address_a      (write_addr),
	.clock0         (clk),
	.data_a         (write_data),
	.byteena_a      (write_byteena),
	.wren_a         (write_we),
	.address_b      (cpu_waddr),
	.q_b            (dout),
	.aclr0          (1'b0),
	.aclr1          (1'b0),
	.addressstall_a (1'b0),
	.addressstall_b (1'b0),
	.byteena_b      (1'b1),
	.clock1         (1'b1),
	.clocken0       (1'b1),
	.clocken1       (1'b1),
	.clocken2       (1'b1),
	.clocken3       (1'b1),
	.data_b         (16'h0000),
	.eccstatus      (),
	.q_a            (),
	.rden_a         (1'b1),
	.rden_b         (1'b1),
	.wren_b         (1'b0)
);
defparam
	nvram_inst.address_aclr_b                  = "NONE",
	nvram_inst.address_reg_b                   = "CLOCK0",
	nvram_inst.clock_enable_input_a            = "BYPASS",
	nvram_inst.clock_enable_input_b            = "BYPASS",
	nvram_inst.clock_enable_output_b           = "BYPASS",
	nvram_inst.intended_device_family          = "Cyclone V",
	nvram_inst.lpm_type                        = "altsyncram",
	nvram_inst.numwords_a                      = 8192,
	nvram_inst.numwords_b                      = 8192,
	nvram_inst.operation_mode                  = "DUAL_PORT",
	nvram_inst.outdata_aclr_b                  = "NONE",
	nvram_inst.outdata_reg_b                   = "UNREGISTERED",
	nvram_inst.power_up_uninitialized          = "FALSE",
	nvram_inst.ram_block_type                  = "M10K",
	nvram_inst.read_during_write_mode_mixed_ports = "OLD_DATA",
	nvram_inst.widthad_a                       = 13,
	nvram_inst.widthad_b                       = 13,
	nvram_inst.width_a                         = 16,
	nvram_inst.width_b                         = 16,
	nvram_inst.width_byteena_a                 = 2;

assign hps_save_dout = 8'h00;

always @(posedge clk) begin
	if (sel & (hwr | lwr)) dirty <= 1'b1;
	else if (clear_dirty)  dirty <= 1'b0;
end

endmodule
