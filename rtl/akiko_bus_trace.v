
module akiko_bus_trace
(
	input             clk,
	input             reset,

	input             sel,
	input             rd,
	input             wr,
	input       [6:0] addr,
	input      [15:0] din,
	input      [15:0] dout,

	input             rd_filter_en,
	input             rd_arm,

	input             uio_cs_trace,
	input             uio_rd,
	output reg  [7:0] uio_dout
);

reg [31:0] ring [0:127];
reg  [6:0] wr_ptr;
reg  [6:0] rd_ptr;
wire       empty = (wr_ptr == rd_ptr);

reg sel_d, rd_d, wr_d;
reg [6:0] addr_d;
reg [15:0] din_d, dout_d;

wire rd_addr_interesting =
       (addr_d[6:2] == 5'b00001)
    || (addr_d[6:2] == 5'b00010)
    || (addr_d[6:3] == 4'b0010 )
    || (addr_d[6:1] == 6'b010000)
    || (addr_d[6:1] == 6'b010001)
    || (addr_d[6:1] == 6'b010010)
    || (addr_d[6:1] == 6'b010011);

always @(posedge clk) begin
	sel_d  <= sel;
	rd_d   <= rd;
	wr_d   <= wr;
	addr_d <= addr;
	din_d  <= din;
	if (sel) dout_d <= dout;

	if (sel_d && wr_d) begin
		ring[wr_ptr] <= {8'hFF, din_d, 1'b1, addr_d};
		wr_ptr       <= wr_ptr + 1'b1;
	end else if (sel_d && rd_d && rd_filter_en && rd_arm
	             && rd_addr_interesting) begin
		ring[wr_ptr] <= {8'hFF, dout_d, 1'b0, addr_d};
		wr_ptr       <= wr_ptr + 1'b1;
	end

	if (reset) begin
		wr_ptr <= 0;
	end
end

reg [1:0] byte_idx;

always @(*) begin
	if (empty) begin
		uio_dout = 8'h00;
	end else begin
		case (byte_idx)
			2'd0: uio_dout = ring[rd_ptr][7:0];
			2'd1: uio_dout = ring[rd_ptr][15:8];
			2'd2: uio_dout = ring[rd_ptr][23:16];
			2'd3: uio_dout = ring[rd_ptr][31:24];
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
			if (byte_idx == 2'd3) begin
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
