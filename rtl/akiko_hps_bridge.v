// Copyright 2026 (CD32 native-mode HPS bridge)
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

module akiko_hps_bridge
(
	input             clk,
	input             reset,

	input             uio_cs,
	input             uio_cs_sec,
	input             uio_cs_nvr,
	input             uio_wr,
	input             uio_rd,
	input       [7:0] uio_din,
	output      [7:0] uio_dout,

	input             cmd_pending,
	input       [7:0] cmd_byte,
	output            cmd_pop,
	output            cmd_done,
	output            result_push,
	output      [7:0] result_byte,
	output            result_done,

	input             sec_req,
	input       [7:0] sec_status,
	output            sec_push,
	output      [7:0] sec_byte,
	output            sec_done,

	output      [9:0] nvr_addr,
	input       [7:0] nvr_dout,
	output      [7:0] nvr_din,
	output            nvr_we,
	output            nvr_clear_dirty,
	output            nvr_done,
	input             nvr_dirty,

	input             rx_busy,

	output            req,
	output            sec_req_out,
	output            rx_busy_out,
	output            nvr_dirty_out
);

reg cs_d;
reg cs_sec_d;
reg cs_nvr_d;
reg saw_read;
reg saw_write;

reg [9:0] nvr_addr_cnt;

wire cs_cmd = uio_cs & ~uio_cs_sec & ~uio_cs_nvr;

always @(posedge clk) begin
	if (reset) begin
		cs_d         <= 1'b0;
		cs_sec_d     <= 1'b0;
		cs_nvr_d     <= 1'b0;
		saw_read     <= 1'b0;
		saw_write    <= 1'b0;
		nvr_addr_cnt <= 10'd0;
	end else begin
		cs_d     <= uio_cs;
		cs_sec_d <= uio_cs_sec;
		cs_nvr_d <= uio_cs_nvr;
		if (!uio_cs) begin
			saw_read  <= 1'b0;
			saw_write <= 1'b0;
		end else begin
			if (uio_rd) saw_read  <= 1'b1;
			if (uio_wr) saw_write <= 1'b1;
		end
		if (uio_cs_nvr & ~cs_nvr_d) begin
			nvr_addr_cnt <= 10'd0;
		end else if ((uio_rd | uio_wr) & uio_cs_nvr) begin
			nvr_addr_cnt <= nvr_addr_cnt + 10'd1;
		end
	end
end

wire xfer_end = cs_d & ~uio_cs;

assign cmd_pop         = uio_rd & cs_cmd;
assign result_push     = uio_wr & cs_cmd;
assign result_byte     = uio_din;

assign sec_push        = uio_wr & uio_cs &  uio_cs_sec;
assign sec_byte        = uio_din;

assign nvr_addr        = nvr_addr_cnt;
assign nvr_din         = uio_din;
assign nvr_we          = uio_wr & uio_cs &  uio_cs_nvr;
assign nvr_clear_dirty = xfer_end & saw_read & cs_nvr_d;

assign uio_dout        = uio_cs_nvr ? nvr_dout    :
                         uio_cs_sec ? sec_status  :
                                      cmd_byte;

assign cmd_done        = xfer_end & saw_read  & ~cs_sec_d & ~cs_nvr_d;
assign result_done     = xfer_end & saw_write & ~cs_sec_d & ~cs_nvr_d;
assign sec_done        = xfer_end &              cs_sec_d;
assign nvr_done        = xfer_end &              cs_nvr_d;

assign req             = cmd_pending;
assign sec_req_out     = sec_req;
assign rx_busy_out     = rx_busy;
assign nvr_dirty_out   = nvr_dirty;

endmodule
