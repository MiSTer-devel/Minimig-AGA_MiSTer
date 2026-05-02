// SPDX-License-Identifier: GPL-3.0-or-later

module chipdma_arb
(
	input             clk,
	input             reset,

	input      [24:1] chip_in_addr,
	input             chip_in_l,
	input             chip_in_u,
	input             chip_in_rw,
	input             chip_in_dma,
	input      [15:0] chip_in_wr,

	input             akiko_dma_req,
	input             akiko_dma_we,
	input      [23:0] akiko_dma_baddr,
	input       [7:0] akiko_dma_wbyte,
	output      [7:0] akiko_dma_rbyte,
	output            akiko_dma_ack,

	output     [24:1] chip_out_addr,
	output            chip_out_l,
	output            chip_out_u,
	output            chip_out_rw,
	output            chip_out_dma,
	output     [15:0] chip_out_wr,
	input      [15:0] chip_in_rd
);

assign chip_out_addr = chip_in_addr;
assign chip_out_l    = chip_in_l;
assign chip_out_u    = chip_in_u;
assign chip_out_rw   = chip_in_rw;
assign chip_out_dma  = chip_in_dma;
assign chip_out_wr   = chip_in_wr;

assign akiko_dma_rbyte = 8'h00;
assign akiko_dma_ack   = 1'b0;

endmodule
