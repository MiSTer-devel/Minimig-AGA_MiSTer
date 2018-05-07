
module gayle_fifo
(
	input             clk,		   // bus clock
	input             clk7_en,
	input             reset,		// reset 
	input	     [15:0] data_in,		// data in
	output reg [15:0] data_out,	// data out
	input             rd,			// read from fifo
	input             fast_rd,
	input             wr,			// write to fifo
	input             fast_wr,
	output            full,			// fifo is full
	output            empty,		// fifo is empty
	output reg        last			// the last word of a sector is being read
);

// local signals and registers
reg  [15:0] mem [4095:0];	// 16 bit wide fifo memory
reg  [12:0] inptr;			// fifo input pointer
reg  [12:0] outptr;			// fifo output pointer
wire        empty_rd;		// fifo empty flag (set immediately after reading the last word)
reg         empty_wr;		// fifo empty flag (set one clock after writting the empty fifo)

// main fifo memory (implemented using synchronous block ram)
always @(posedge clk) if ((clk7_en & wr) | fast_wr) mem[inptr[11:0]] <= data_in;
always @(posedge clk) data_out <= mem[outptr[11:0]];

// fifo write pointer control
always @(posedge clk) begin
	if (reset) inptr <= 0;
	else if ((clk7_en & wr) | fast_wr) inptr <= inptr + 1'd1;
end

// fifo read pointer control
always @(posedge clk) begin
	last <= 0;
	if (reset) outptr <= 0;
	else if ((clk7_en & rd) | fast_rd) begin
		outptr <= outptr + 1'd1;
		last <= (outptr[7:0] == 8'hFF);
	end
end

// the empty flag is set immediately after reading the last word from the fifo
assign empty_rd = (inptr==outptr);

// after writting empty fifo the empty flag is delayed by one clock to handle ram write delay
always @(posedge clk) if (clk7_en) empty_wr <= empty_rd;

assign empty = empty_rd | empty_wr;

// at least 512 bytes are in FIFO 
// this signal is activated when 512th byte is written to the empty fifo
// then it's deactivated when 512th byte is read from the fifo (hysteresis)
assign full = (inptr[12:8]!=outptr[12:8]);

endmodule
