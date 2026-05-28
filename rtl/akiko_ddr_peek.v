
module akiko_ddr_peek #(parameter CAPTURE_ENABLE = 1)(
	input             clk,
	input             reset,

	input             dma_cs,
	input             dma_we,
	input      [28:1] dma_addr,
	input             dma_l,
	input             dma_u,
	input      [15:0] dma_wr,

	input             uio_cs_peek,
	input             uio_rd,
	output reg  [7:0] uio_dout
);

reg [47:0] ring [0:63];
reg  [5:0] wr_ptr;
reg  [5:0] rd_ptr;
wire       empty = (wr_ptr == rd_ptr);

reg  dma_event_d;
wire dma_event = dma_cs & dma_we;

always @(posedge clk) begin
	dma_event_d <= dma_event;

	if (CAPTURE_ENABLE && (dma_event & ~dma_event_d)) begin
		ring[wr_ptr] <= {2'b00, dma_u, dma_l, dma_addr, dma_wr};
		wr_ptr       <= wr_ptr + 1'b1;
	end

	if (reset) begin
		wr_ptr      <= 6'd0;
		dma_event_d <= 1'b0;
	end
end

reg [2:0] byte_idx;
wire [47:0] cur = ring[rd_ptr];

always @(*) begin
	if (empty) begin
		uio_dout = 8'h00;
	end else begin
		case (byte_idx)
			3'd0: uio_dout = {cur[22:16], 1'b0};
			3'd1: uio_dout = cur[30:23];
			3'd2: uio_dout = cur[38:31];
			3'd3: uio_dout = {cur[45], cur[44], 1'b0, cur[43:39]};
			3'd4: uio_dout = cur[ 7: 0];
			3'd5: uio_dout = cur[15: 8];
			3'd6: uio_dout = 8'hA5;
			3'd7: uio_dout = 8'hFF;
		endcase
	end
end

always @(posedge clk) begin
	if (reset) begin
		byte_idx <= 3'd0;
		rd_ptr   <= 6'd0;
	end
	else if (uio_cs_peek && uio_rd) begin
		if (!empty) begin
			if (byte_idx == 3'd7) begin
				rd_ptr   <= rd_ptr + 1'b1;
				byte_idx <= 3'd0;
			end else begin
				byte_idx <= byte_idx + 1'b1;
			end
		end
	end
	else if (!uio_cs_peek) begin
		byte_idx <= 3'd0;
	end
end

endmodule
