// SPDX-License-Identifier: GPL-3.0-or-later

module z2_trace #(parameter CAPTURE_ENABLE = 1)(
	input             clk,
	input             reset,

	input             ramsel,
	input             ramready,
	input      [31:0] cpu_addr,
	input      [28:1] ramaddr,
	input      [15:0] ramdat,
	input             wr,
	input             uds_in,
	input             lds_in,
	input       [1:0] cpustate,
	input             cchip,
	input             ckick,

	input             sel_z2ram,
	input             sel_z3ram0,
	input             sel_z3ram1,
	input             sel_kickram,
	input             sel_kicklower,
	input             sel_chipram,
	input             sel_dd,
	input             sel_rtg,

	input             z2ram_ena,

	input             uio_cs_trace,
	input             uio_rd,
	output reg  [7:0] uio_dout
);

reg [127:0] ring [0:255];
reg   [7:0] wr_ptr;
reg   [7:0] rd_ptr;
wire        empty = (wr_ptr == rd_ptr);

reg  [31:0] tstamp;
always @(posedge clk) tstamp <= reset ? 32'b0 : tstamp + 1'b1;

reg ramsel_d;
always @(posedge clk) ramsel_d <= ramsel;
wire ramsel_rise = ramsel & ~ramsel_d;

reg z2ena_d;
always @(posedge clk) z2ena_d <= z2ram_ena;
wire z2ena_rise = z2ram_ena & ~z2ena_d;

reg [8:0] stall_cnt;
always @(posedge clk) begin
	if (reset || !ramsel || ramready) stall_cnt <= 9'b0;
	else if (!stall_cnt[8])           stall_cnt <= stall_cnt + 1'b1;
end
wire stall_hit = (stall_cnt == 9'h100) && ramsel && !ramready;
reg stall_fired;
always @(posedge clk) begin
	if (reset || !ramsel || ramready) stall_fired <= 1'b0;
	else if (stall_hit)               stall_fired <= 1'b1;
end

wire fast_hit = ramsel_rise &
	(sel_z2ram | sel_z3ram0 | sel_z3ram1 | sel_kickram);

wire cap_ev_access   = fast_hit;
wire cap_ev_acdone   = z2ena_rise;
wire cap_ev_stall    = stall_hit & ~stall_fired;
wire cap_en          = CAPTURE_ENABLE & (cap_ev_access | cap_ev_acdone | cap_ev_stall);

wire [1:0] ev_type =
	cap_ev_acdone ? 2'b01 :
	cap_ev_stall  ? 2'b10 :
	                2'b00;

wire [7:0] flags_byte = {wr, ramready, cpustate, cchip, ckick, uds_in, lds_in};
wire [7:0] sels_byte  = {sel_z2ram, sel_z3ram0, sel_z3ram1, sel_kickram,
                         sel_chipram, sel_dd, sel_rtg, z2ram_ena};
wire [31:0] ramaddr_pad = {2'b0, ev_type, ramaddr};
wire [127:0] entry = {
	ramdat,
	ramaddr_pad,
	sels_byte,
	flags_byte,
	cpu_addr,
	tstamp
};

always @(posedge clk) begin
	if (reset) begin
		wr_ptr <= 8'b0;
	end
	else if (cap_en) begin
		ring[wr_ptr] <= entry;
		wr_ptr       <= wr_ptr + 1'b1;
	end
end

reg [3:0] byte_idx;

always @(*) begin
	if (empty) begin
		uio_dout = 8'h00;
	end else begin
		case (byte_idx)
			4'h0: uio_dout = ring[rd_ptr][  7:  0];
			4'h1: uio_dout = ring[rd_ptr][ 15:  8];
			4'h2: uio_dout = ring[rd_ptr][ 23: 16];
			4'h3: uio_dout = ring[rd_ptr][ 31: 24];
			4'h4: uio_dout = ring[rd_ptr][ 39: 32];
			4'h5: uio_dout = ring[rd_ptr][ 47: 40];
			4'h6: uio_dout = ring[rd_ptr][ 55: 48];
			4'h7: uio_dout = ring[rd_ptr][ 63: 56];
			4'h8: uio_dout = ring[rd_ptr][ 71: 64];
			4'h9: uio_dout = ring[rd_ptr][ 79: 72];
			4'hA: uio_dout = ring[rd_ptr][ 87: 80];
			4'hB: uio_dout = ring[rd_ptr][ 95: 88];
			4'hC: uio_dout = ring[rd_ptr][103: 96];
			4'hD: uio_dout = ring[rd_ptr][111:104];
			4'hE: uio_dout = ring[rd_ptr][119:112];
			4'hF: uio_dout = ring[rd_ptr][127:120];
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
			if (byte_idx == 4'hF) begin
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
