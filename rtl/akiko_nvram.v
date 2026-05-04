
module akiko_nvram
#(
	parameter INIT_FILE = "rtl/init/nvram_init.hex"
)
(
	input  wire        clk,
	input  wire        reset,

	input  wire        scl_in,
	input  wire        sda_in,

	output wire        sda_drive,

	input  wire [9:0]  host_addr,
	input  wire [7:0]  host_din,
	input  wire        host_we,
	output reg  [7:0]  host_dout,
	input  wire        host_clear_dirty,
	output reg         nvram_dirty
);

localparam ADDR_W = 10;
(* ramstyle = "M10K, no_rw_check" *) reg [7:0] memory_a [0:1023];
(* ramstyle = "M10K, no_rw_check" *) reg [7:0] memory_b [0:1023];
reg [7:0]        mem_dout;
reg              mem_we;
reg [ADDR_W-1:0] mem_waddr;

initial $readmemh(INIT_FILE, memory_a);
initial $readmemh(INIT_FILE, memory_b);

localparam ST_IDLE    = 3'd0;
localparam ST_RX_DATA = 3'd1;
localparam ST_RX_ACK  = 3'd2;
localparam ST_TX_DATA = 3'd3;
localparam ST_TX_ACK  = 3'd4;

localparam BYTE_DEVADDR  = 2'd0;
localparam BYTE_WORDADDR = 2'd1;
localparam BYTE_DATA     = 2'd2;

reg [2:0] state;
reg [1:0] byte_phase;
reg [3:0] bit_count;
reg [7:0] shift_reg;
reg [ADDR_W-1:0] eeprom_addr;
reg       is_read;
reg       dev_match;
reg       sda_oe;

reg prev_scl, prev_sda;
wire scl_rise = ~prev_scl &  scl_in;
wire scl_fall =  prev_scl & ~scl_in;
wire sda_rise = ~prev_sda &  sda_in;
wire sda_fall =  prev_sda & ~sda_in;

wire start_cond = scl_in & sda_fall;
wire stop_cond  = scl_in & sda_rise;

wire [ADDR_W-1:0] mem_waddr_mux = host_we ? host_addr : mem_waddr;
wire        [7:0] mem_din_mux   = host_we ? host_din  : shift_reg;
wire              mem_we_mux    = host_we | mem_we;

always @(posedge clk) begin
	if (mem_we_mux) begin
		memory_a[mem_waddr_mux] <= mem_din_mux;
		memory_b[mem_waddr_mux] <= mem_din_mux;
	end
	mem_dout  <= memory_a[eeprom_addr];
	host_dout <= memory_b[host_addr];
end

always @(posedge clk) begin
	if (reset)                  nvram_dirty <= 1'b0;
	else if (mem_we)            nvram_dirty <= 1'b1;
	else if (host_clear_dirty)  nvram_dirty <= 1'b0;
end

always @(posedge clk) begin
	prev_scl <= scl_in;
	prev_sda <= sda_in;
	mem_we   <= 1'b0;

	if (reset) begin
		state       <= ST_IDLE;
		byte_phase  <= BYTE_DEVADDR;
		bit_count   <= 4'd0;
		shift_reg   <= 8'h0;
		eeprom_addr <= {ADDR_W{1'b0}};
		is_read     <= 1'b0;
		dev_match   <= 1'b0;
		sda_oe      <= 1'b0;
	end
	else if (stop_cond) begin
		state      <= ST_IDLE;
		byte_phase <= BYTE_DEVADDR;
		bit_count  <= 4'd0;
		sda_oe     <= 1'b0;
	end
	else if (start_cond) begin
		state      <= ST_RX_DATA;
		byte_phase <= BYTE_DEVADDR;
		bit_count  <= 4'd0;
		shift_reg  <= 8'h0;
		sda_oe     <= 1'b0;
	end
	else begin
		case (state)

		ST_IDLE: ;

		ST_RX_DATA: begin
			if (scl_rise) begin
				shift_reg <= {shift_reg[6:0], sda_in};
				if (bit_count == 4'd7) begin
					state     <= ST_RX_ACK;
					bit_count <= 4'd0;
				end else begin
					bit_count <= bit_count + 4'd1;
				end
			end
		end

		ST_RX_ACK: begin
			if (scl_fall && bit_count == 4'd0) begin
				bit_count <= 4'd1;
				case (byte_phase)
				BYTE_DEVADDR: begin
					if (shift_reg[7:4] == 4'b1010) begin
						dev_match            <= 1'b1;
						is_read              <= shift_reg[0];
						eeprom_addr[ADDR_W-1:8] <= shift_reg[2:1];
						sda_oe               <= 1'b1;
					end else begin
						dev_match <= 1'b0;
						sda_oe    <= 1'b0;
					end
				end
				BYTE_WORDADDR: begin
					eeprom_addr[7:0] <= shift_reg;
					sda_oe           <= 1'b1;
				end
				BYTE_DATA: begin
					mem_we              <= 1'b1;
					mem_waddr           <= eeprom_addr;
					eeprom_addr         <= eeprom_addr + 10'd1;
					sda_oe              <= 1'b1;
				end
				endcase
			end
			else if (scl_fall && bit_count == 4'd1) begin
				sda_oe    <= 1'b0;
				bit_count <= 4'd0;
				if (!dev_match) begin
					state <= ST_IDLE;
				end
				else case (byte_phase)
				BYTE_DEVADDR: begin
					if (is_read) begin
						state       <= ST_TX_DATA;
						sda_oe      <= ~mem_dout[7];
						shift_reg   <= {mem_dout[6:0], 1'b0};
						eeprom_addr <= eeprom_addr + 10'd1;
						bit_count   <= 4'd1;
						byte_phase  <= BYTE_DATA;
					end else begin
						state      <= ST_RX_DATA;
						byte_phase <= BYTE_WORDADDR;
					end
				end
				BYTE_WORDADDR: begin
					state      <= ST_RX_DATA;
					byte_phase <= BYTE_DATA;
				end
				BYTE_DATA: begin
					state <= ST_RX_DATA;
				end
				endcase
			end
		end

		ST_TX_DATA: begin
			if (scl_fall) begin
				if (bit_count <= 4'd7) begin
					sda_oe    <= ~shift_reg[7];
					shift_reg <= {shift_reg[6:0], 1'b0};
					bit_count <= bit_count + 4'd1;
				end
				else begin
					sda_oe    <= 1'b0;
					bit_count <= 4'd0;
					state     <= ST_TX_ACK;
				end
			end
		end

		ST_TX_ACK: begin
			if (scl_rise) begin
				dev_match <= ~sda_in;
			end
			else if (scl_fall) begin
				if (dev_match) begin
					state       <= ST_TX_DATA;
					sda_oe      <= ~mem_dout[7];
					shift_reg   <= {mem_dout[6:0], 1'b0};
					eeprom_addr <= eeprom_addr + 10'd1;
					bit_count   <= 4'd1;
				end else begin
					state <= ST_IDLE;
				end
			end
		end

		default: state <= ST_IDLE;
		endcase
	end
end

assign sda_drive = sda_oe;

endmodule
