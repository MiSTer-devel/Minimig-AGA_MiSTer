// The MiSTer DDR3 port (sys/emu DDRAM_*) as an Avalon-MM slave for the
// full-system simulation: 64-bit words, word address = byte address / 8,
// byte enables on writes, bursts.  One command is taken at a time: BUSY
// (waitrequest) is high while a read burst's data is still to come back,
// so the masters see the back-pressure the HPS bridge gives them.  Reads
// return LAT clocks after the command, one beat per clock.  Memory is
// sparse (an associative array of 64-bit words).

module ddr3_model
#(
	parameter int LAT = 16
)
(
	input             clk,
	output            busy,
	input       [7:0] burstcnt,
	input      [28:0] addr,
	output reg [63:0] dout,
	output reg        dout_ready,
	input             rd,
	input      [63:0] din,
	input       [7:0] be,
	input             we
);

logic [63:0] mem [longint unsigned];

reg        rd_busy = 1'b0;
reg  [7:0] rd_left;
reg [28:0] rd_addr;
reg  [7:0] rd_wait;
reg  [7:0] wr_left = 8'd0;
reg [28:0] wr_addr;

assign busy = rd_busy;

function automatic [63:0] rd64(input [28:0] w);
	if (mem.exists(longint'(w))) rd64 = mem[longint'(w)];
	else                         rd64 = 64'd0;
endfunction

always @(posedge clk) begin
	dout_ready <= 1'b0;

	if (rd_busy) begin
		if (rd_wait != 0) rd_wait <= rd_wait - 1'd1;
		else begin
			dout       <= rd64(rd_addr);
			dout_ready <= 1'b1;
			rd_addr    <= rd_addr + 1'd1;
			rd_left    <= rd_left - 1'd1;
			if (rd_left == 8'd1) rd_busy <= 1'b0;
		end
	end
	else if (rd) begin
		rd_busy <= 1'b1;
		rd_left <= burstcnt;
		rd_addr <= addr;
		rd_wait <= 8'(LAT);
	end

	if (we && !rd_busy) begin
		// a write beat: the first of a burst carries the address
		logic [28:0] w;
		logic [63:0] v;
		w = (wr_left != 0) ? wr_addr : addr;
		v = rd64(w);
		for (int i = 0; i < 8; i++) if (be[i]) v[i*8 +: 8] = din[i*8 +: 8];
		mem[longint'(w)] = v;
		if (wr_left != 0) begin
			wr_left <= wr_left - 1'd1;
			wr_addr <= wr_addr + 1'd1;
		end
		else if (burstcnt > 8'd1) begin
			wr_left <= burstcnt - 1'd1;
			wr_addr <= addr + 1'd1;
		end
	end
end

export "DPI-C" function ddr_poke64;
export "DPI-C" function ddr_peek64;
function void ddr_poke64(input int unsigned waddr, input longint unsigned data);
	mem[longint'(waddr)] = data;
endfunction
function longint unsigned ddr_peek64(input int unsigned waddr);
	return rd64(waddr[28:0]);
endfunction

endmodule
