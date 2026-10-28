// A behavioural SDR SDRAM for the full-system simulation: 16 bits wide,
// 4 banks of 8192 rows x 512 columns (32 MB, the MiSTer SDRAM module the
// core needs), commands sampled on the rising edge of the controller's
// SDRAM_CLK, the mode register a4k_sdram programs: CAS latency 2, read
// bursts of four (sequential), single-location writes.  DQM masks the bytes
// of a write; A10 with READ/WRITE is auto-precharge (no effect here: the
// model does not need row timing to answer, a4k_sdram's slot keeps it).
//
// Read data: the word of burst beat k is driven after edge 1+k from the
// READ (so the controller samples it at edge 2+k, CL 2) and released after
// the last.
//
// Memory is word addressed {bank, row, column}; the simulation driver loads
// and inspects it through the DPI functions below.

module sdram_model
(
	input         clk,
	input  [12:0] a,
	input   [1:0] ba,
	inout  [15:0] dq,
	input         dqml,
	input         dqmh,
	input         cs_n,
	input         ras_n,
	input         cas_n,
	input         we_n
);

reg [15:0] mem [0:(1<<24)-1];

reg [12:0] row [4];

// the read pipeline: beat k drives at edge 1+k
reg  [3:0] rd_v;          // beats still to drive, a shift
reg [23:0] rd_a;          // the word address of the next beat
reg  [1:0] rd_col;        // the burst's column within its group of four
reg [15:0] dq_o;
reg        dq_oe = 1'b0;

assign dq = dq_oe ? dq_o : 16'hZZZZ;

always @(posedge clk) begin
	// drive the next word of a burst in progress
	if (rd_v[0]) begin
		dq_o  <= mem[{rd_a[23:2], rd_col}];
		dq_oe <= 1'b1;
		rd_col <= rd_col + 1'd1;
	end
	else dq_oe <= 1'b0;
	rd_v <= {1'b0, rd_v[3:1]};

	if (!cs_n) begin
		case ({ras_n, cas_n, we_n})
			3'b011: row[ba] <= a;                                    // ACTIVE
			3'b101: begin                                            // READ
				rd_a   <= {ba, row[ba], a[8:0]};
				rd_col <= a[1:0];
				rd_v   <= 4'b1111;
			end
			3'b100: begin                                            // WRITE (single)
				if (!dqmh) mem[{ba, row[ba], a[8:0]}][15:8] <= dq[15:8];
				if (!dqml) mem[{ba, row[ba], a[8:0]}][7:0]  <= dq[7:0];
			end
			default: ;                                               // PRECHARGE, REFRESH, MODE
		endcase
	end
end

// the simulation driver's access: word address {bank, row, column} as
// a4k_sdram maps its 24-bit word address straight onto it
export "DPI-C" function sdram_poke16;
export "DPI-C" function sdram_peek16;
function void sdram_poke16(input int unsigned waddr, input int unsigned data);
	mem[waddr[23:0]] = data[15:0];
endfunction
function int unsigned sdram_peek16(input int unsigned waddr);
	return {16'd0, mem[waddr[23:0]]};
endfunction

endmodule
