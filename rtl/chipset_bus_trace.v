
module chipset_bus_trace
(
	input             clk,
	input             reset,

	input             write_strobe,
	input       [7:0] reg_addr,
	input      [15:0] data,
	input       [2:0] src,
	input      [10:0] vpos,
	input       [8:0] hpos,
	input             dbwe,

	input             uio_cs_trace,
	input             uio_rd,
	output reg  [7:0] uio_dout
);

reg [63:0] ring [0:1023];
reg  [9:0] wr_ptr;
reg  [9:0] rd_ptr;
wire       empty = (wr_ptr == rd_ptr);

always @(posedge clk) begin
	if (write_strobe) begin
		ring[wr_ptr] <= {data,
		                 reg_addr,
		                 src,
		                 vpos,
		                 hpos,
		                 dbwe,
		                 16'h0000};
		wr_ptr <= wr_ptr + 1'b1;
	end

	if (reset) begin
		wr_ptr <= 0;
	end
end

reg [2:0] byte_idx;

always @(*) begin
	if (empty) begin
		uio_dout = 8'h00;
	end else begin
		case (byte_idx)
			3'd0: uio_dout = ring[rd_ptr][55:48];
			3'd1: uio_dout = ring[rd_ptr][63:56];
			3'd2: uio_dout = ring[rd_ptr][47:40];
			3'd3: uio_dout = {ring[rd_ptr][16],
			                  ring[rd_ptr][39:37],
			                  1'b0,
			                  ring[rd_ptr][36:34]};
			3'd4: uio_dout = ring[rd_ptr][33:26];
			3'd5: uio_dout = ring[rd_ptr][24:17];
			3'd6: uio_dout = {7'b0, ring[rd_ptr][25]};
			3'd7: uio_dout = 8'hFF;
		endcase
	end
end

always @(posedge clk) begin
	if (reset) begin
		byte_idx <= 0;
		rd_ptr   <= 0;
	end
	else if (uio_cs_trace && uio_rd) begin
		if (!empty) begin
			if (byte_idx == 3'd7) begin
				rd_ptr   <= rd_ptr + 1'b1;
				byte_idx <= 0;
			end else begin
				byte_idx <= byte_idx + 1'b1;
			end
		end
	end
	else if (!uio_cs_trace) begin
		byte_idx <= 0;
	end
end

endmodule
