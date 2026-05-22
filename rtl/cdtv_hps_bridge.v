// Copyright 2026 (CDTV native-mode HPS bridge)
//
// This file is part of Minimig
//
// SPDX-License-Identifier: GPL-3.0-or-later

module cdtv_hps_bridge
(
	input             clk,
	input             reset,

	input             uio_cs,
	input             uio_cs_stch,
	input             uio_cs_sec,
	input             uio_wr,
	input             uio_rd,
	input       [7:0] uio_din,
	output     [15:0] uio_dout,

	input             cmd_in_pending,
	input       [7:0] cmd_in_byte,
	output            cmd_in_pop,
	output            cmd_out_push,
	output      [7:0] cmd_out_data,

	output            sec_byte_push,
	output      [7:0] sec_byte_data,

	output            stch_inject,

	output            req
);

assign cmd_in_pop    = uio_rd & uio_cs;
assign cmd_out_push  = uio_wr & uio_cs;
assign cmd_out_data  = uio_din;
assign uio_dout      = {8'h00, cmd_in_byte};
assign sec_byte_push = uio_wr & uio_cs_sec;
assign sec_byte_data = uio_din;
assign stch_inject   = uio_wr & uio_cs_stch;
assign req           = cmd_in_pending;

endmodule
