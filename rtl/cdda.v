module cdda
(
	input      CLK,
	input      nRESET,
	input      READ,
	input      WRITE,
	input      [15:0] DIN,
	output     WRITE_READY,
	output reg [15:0] AUDIO_L,
	output reg [15:0] AUDIO_R

);

localparam SECTOR_SIZE = 2352*8/32;
localparam BUFFER_AMOUNT = 2 * SECTOR_SIZE;

reg OLD_WRITE, OLD_READ, LRCK, WR_REQ;

reg [15:0] DATA;
reg [12:0] FILLED_COUNT;

reg [12:0] READ_ADDR, WRITE_ADDR;

wire EMPTY = ~|FILLED_COUNT;
wire FULL = (FILLED_COUNT == BUFFER_AMOUNT);
wire WRITE_CE = ~OLD_WRITE & WRITE;
wire READ_CE = ~OLD_READ & READ;
wire READ_REQ = READ_CE & ~EMPTY;

assign WRITE_READY = (FILLED_COUNT <= (BUFFER_AMOUNT - SECTOR_SIZE)); // Ready to receive sector

always @(posedge CLK) begin
	if (~nRESET) begin
		OLD_WRITE <= 0;
		OLD_READ <= 0;
		LRCK      <= 0;
		READ_ADDR <= 0;
		WRITE_ADDR <= 0;
		FILLED_COUNT <= 0;
	end else begin
		OLD_WRITE <= WRITE;
		OLD_READ <= READ;

		WR_REQ <= 0;
		if (WRITE_CE) begin
			LRCK <= ~LRCK;
			if (~LRCK) begin
				DATA <= DIN;
			end else if(~FULL) begin
				WR_REQ <= 1;
			end
		end

		if (WR_REQ) begin
			if (WRITE_ADDR == BUFFER_AMOUNT-1) begin
				WRITE_ADDR <= 0;
			end else begin
				WRITE_ADDR <= WRITE_ADDR + 1'b1;
			end
		end

		if (READ_REQ) begin
			if (READ_ADDR == BUFFER_AMOUNT-1) begin
				READ_ADDR <= 0;
			end else begin
				READ_ADDR <= READ_ADDR + 1'b1;
			end
			AUDIO_L <= BUFFER_Q[15:0];
			AUDIO_R <= BUFFER_Q[31:16];
		end

		if (READ_CE & EMPTY) begin
			AUDIO_L <= 0;
			AUDIO_R <= 0;
		end

		FILLED_COUNT <= FILLED_COUNT + WR_REQ - READ_REQ;
	end
end

reg [31:0] BUFFER[BUFFER_AMOUNT];
reg [31:0] BUFFER_Q;
always @(posedge CLK) begin
	BUFFER_Q <= BUFFER[READ_ADDR];
	if (WR_REQ) begin
		BUFFER[WRITE_ADDR] <= { DIN, DATA };
	end
end

endmodule
