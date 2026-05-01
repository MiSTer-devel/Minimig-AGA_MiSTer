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

	output            req,
	output            sec_req_out
);

reg cs_d;
reg cs_sec_d;
reg saw_read;
reg saw_write;

always @(posedge clk) begin
	if (reset) begin
		cs_d      <= 1'b0;
		cs_sec_d  <= 1'b0;
		saw_read  <= 1'b0;
		saw_write <= 1'b0;
	end else begin
		cs_d     <= uio_cs;
		cs_sec_d <= uio_cs_sec;
		if (!uio_cs) begin
			saw_read  <= 1'b0;
			saw_write <= 1'b0;
		end else begin
			if (uio_rd) saw_read  <= 1'b1;
			if (uio_wr) saw_write <= 1'b1;
		end
	end
end

wire xfer_end = cs_d & ~uio_cs;

assign cmd_pop     = uio_rd & uio_cs & ~uio_cs_sec;
assign result_push = uio_wr & uio_cs & ~uio_cs_sec;
assign result_byte = uio_din;

assign sec_push    = uio_wr & uio_cs &  uio_cs_sec;
assign sec_byte    = uio_din;

assign uio_dout    = uio_cs_sec ? sec_status : cmd_byte;

assign cmd_done    = xfer_end & saw_read  & ~cs_sec_d;
assign result_done = xfer_end & saw_write & ~cs_sec_d;
assign sec_done    = xfer_end &              cs_sec_d;

assign req         = cmd_pending;
assign sec_req_out = sec_req;

endmodule
