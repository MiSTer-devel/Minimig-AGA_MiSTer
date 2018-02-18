module gayle_fifo
(
	input 	clk,		    		// bus clock
  input clk7_en,
	input 	reset,			   		// reset 
	input	[15:0] data_in,			// data in
	output	reg [15:0] data_out,	// data out
	input	rd,						// read from fifo
	input	wr,						// write to fifo
	output	full,					// fifo is full
	output	empty,					// fifo is empty
	output	last					// the last word of a sector is being read
);

// local signals and registers
reg 	[15:0] mem [4095:0];		// 16 bit wide fifo memory
reg		[12:0] inptr;				// fifo input pointer
reg		[12:0] outptr;				// fifo output pointer
wire	empty_rd;					// fifo empty flag (set immediately after reading the last word)
reg		empty_wr;					// fifo empty flag (set one clock after writting the empty fifo)

// main fifo memory (implemented using synchronous block ram)
always @(posedge clk)
  if (clk7_en) begin
  	if (wr)
  		mem[inptr[11:0]] <= data_in;
  end
		
always @(posedge clk)
  if (clk7_en) begin
  	data_out <= mem[outptr[11:0]];
  end

// fifo write pointer control
always @(posedge clk)
  if (clk7_en) begin
  	if (reset)
  		inptr <= 12'd0;
  	else if (wr)
  		inptr <= inptr + 12'd1;
  end

// fifo read pointer control
always @(posedge clk)
  if (clk7_en) begin
  	if (reset)
  		outptr <= 0;
  	else if (rd)
  		outptr <= outptr + 13'd1;
  end

// the empty flag is set immediately after reading the last word from the fifo
assign empty_rd = inptr==outptr ? 1'b1 : 1'b0;

// after writting empty fifo the empty flag is delayed by one clock to handle ram write delay
always @(posedge clk)
  if (clk7_en) begin
  	empty_wr <= empty_rd;
  end

assign empty = empty_rd | empty_wr;

// at least 512 bytes are in FIFO 
// this signal is activated when 512th byte is written to the empty fifo
// then it's deactivated when 512th byte is read from the fifo (hysteresis)		
assign full = inptr[12:8]!=outptr[12:8] ? 1'b1 : 1'b0;	

assign last = outptr[7:0] == 8'hFF ? 1'b1 : 1'b0;	


endmodule

