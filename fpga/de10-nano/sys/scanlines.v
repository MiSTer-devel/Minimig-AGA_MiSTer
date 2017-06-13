module scanlines
(
	input         clk,

	input   [1:0] scanlines,
	input  [23:0] din,
	output reg [23:0] dout,
	input         hs,vs
);

reg scanline = 0;
always @(posedge clk) begin
	reg old_hs, old_vs;

	old_hs <= hs;
	old_vs <= vs;
	
	if(old_hs && ~hs) scanline <= ~scanline;
	if(old_vs && ~vs) scanline <= 0;
end

wire [7:0] r,g,b;
assign {r,g,b} = din;

always @(*) begin
	case(scanlines & {scanline, scanline})
		1: // reduce 25% = 1/2 + 1/4
			dout = {{1'b0, r[7:1]} + {2'b00, r[7:2]},
					  {1'b0, g[7:1]} + {2'b00, g[7:2]},
					  {1'b0, b[7:1]} + {2'b00, b[7:2]}};

		2: // reduce 50% = 1/2
			dout = {{1'b0, r[7:1]},
					  {1'b0, g[7:1]},
					  {1'b0, b[7:1]}};

		3: // reduce 75% = 1/4
			dout = {{2'b00, r[7:2]},
					  {2'b00, g[7:2]},
					  {2'b00, b[7:2]}};

		default: dout = {r,g,b};
	endcase
end

endmodule
