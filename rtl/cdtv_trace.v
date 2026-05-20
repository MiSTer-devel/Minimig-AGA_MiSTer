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

module cdtv_trace
(
	input             clk,
	input             reset,

	input             trace_we,
	input      [63:0] trace_data,

	input             uio_cs,
	input             uio_rd,
	output reg  [7:0] uio_dout
);

reg [63:0] ring [0:1023];
reg  [9:0] wr_ptr;
reg  [9:0] rd_ptr;
wire       empty = (wr_ptr == rd_ptr);

reg [31:0] ts;

reg        trace_we_d;
reg [63:0] trace_data_d;

always @(posedge clk) begin
	ts <= ts + 32'd1;
	trace_we_d   <= trace_we;
	trace_data_d <= {ts, trace_data[31:0]};
	if (trace_we_d) begin
		ring[wr_ptr] <= trace_data_d;
		wr_ptr       <= wr_ptr + 10'd1;
	end
	if (reset) begin
		wr_ptr <= 10'd0;
		ts     <= 32'd0;
	end
end

reg [3:0] byte_idx;

always @* begin
	uio_dout = 8'h00;
	if (!empty) begin
		case (byte_idx)
			4'd0: uio_dout = ring[rd_ptr][7:0];
			4'd1: uio_dout = ring[rd_ptr][15:8];
			4'd2: uio_dout = ring[rd_ptr][23:16];
			4'd3: uio_dout = ring[rd_ptr][31:24];
			4'd4: uio_dout = ring[rd_ptr][39:32];
			4'd5: uio_dout = ring[rd_ptr][47:40];
			4'd6: uio_dout = ring[rd_ptr][55:48];
			4'd7: uio_dout = ring[rd_ptr][63:56];
			default: uio_dout = 8'hFF;
		endcase
	end
end

always @(posedge clk) begin
	if (reset) begin
		rd_ptr   <= 10'd0;
		byte_idx <= 4'd0;
	end else if (uio_cs && uio_rd) begin
		if (!empty) begin
			if (byte_idx == 4'd8) begin
				rd_ptr   <= rd_ptr + 10'd1;
				byte_idx <= 4'd0;
			end else begin
				byte_idx <= byte_idx + 4'd1;
			end
		end
	end else if (!uio_cs) begin
		byte_idx <= 4'd0;
	end
end

endmodule
