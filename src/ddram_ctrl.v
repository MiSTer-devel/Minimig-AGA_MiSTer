//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
//                                                                          //
// DDR3 memory interface                                                    // 
// Copyright (c)2019 Alexey Melnikov                                        //
// Based on SDRAM controller by Tobias Gubener                              //
//                                                                          //
// This source file is free software: you can redistribute it and/or modify //
// it under the terms of the GNU General Public License as published        //
// by the Free Software Foundation, either version 3 of the License, or     //
// (at your option) any later version.                                      //
//                                                                          //
// This source file is distributed in the hope that it will be useful,      //
// but WITHOUT ANY WARRANTY; without even the implied warranty of           //
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            //
// GNU General Public License for more details.                             //
//                                                                          //
// You should have received a copy of the GNU General Public License        //
// along with this program.  If not, see <http://www.gnu.org/licenses/>.    //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////


module ddram_ctrl
(
	// system
	input             sysclk,
	input             reset_n,
	input             cache_rst,
	input             cache_inhibit,
	input       [3:0] cpu_cache_ctrl,

	// DDR3    
	output            DDRAM_CLK,
	input             DDRAM_BUSY,
	output      [7:0] DDRAM_BURSTCNT,
	output reg [28:0] DDRAM_ADDR,
	input      [63:0] DDRAM_DOUT,
	input             DDRAM_DOUT_READY,
	output reg        DDRAM_RD,
	output reg [63:0] DDRAM_DIN,
	output reg  [7:0] DDRAM_BE,
	output reg        DDRAM_WE,

	// cpu    
	input      [28:1] cpuAddr,
	input             cpuCS,
	input       [1:0] cpustate,
	input             cpuL,
	input             cpuU,
	input      [15:0] cpuWR,
	output     [15:0] cpuRD,
	output            ramready
);

wire cache_hit;
wire cache_req;
reg  cache_fill;
wire cache_ack;

cpu_cache_new cpu_cache
(
	.clk              (sysclk),                 // clock
	.rst              (~reset_n | ~cache_rst), // cache reset
	.cache_en         (1),                      // cache enable
	.cpu_cache_ctrl   (cpu_cache_ctrl),         // CPU cache control
	.cache_inhibit    (cache_inhibit),          // cache inhibit
	.cpu_cs           (cpuCS),                  // cpu activity
	.cpu_adr          (cpuAddr),                // cpu address
	.cpu_bs           (~{cpuU, cpuL}),          // cpu byte selects
	.cpu_we           (cpustate == 3),          // cpu write
	.cpu_ir           (cpustate == 0),          // cpu instruction read
	.cpu_dr           (cpustate == 2),          // cpu data read
	.cpu_dat_w        (cpuWR),                  // cpu write data
	.cpu_dat_r        (cpuRD),                  // cpu read data
	.cpu_ack          (cache_hit),              // cpu acknowledge
	.wb_en            (cache_ack),              // write enable
	.sdr_dat_r        (ddr_data),               // sdram read data
	.sdr_read_req     (cache_req),              // sdram read request from cache
	.sdr_read_ack     (cache_fill)              // sdram read acknowledge to cache
);

// write buffer, enables CPU to continue while a write is in progress
reg        write_ena;
reg        write_req;
reg        write_ack;
reg  [1:0] writeBE;
reg [28:1] writeAddr;
reg [15:0] writeDat;

always @ (posedge sysclk) begin
	reg  [1:0] write_state;

	if(~reset_n) begin
		write_req   <= 0;
		write_ena   <= 0;
		write_state <= 0;
	end else begin
		case(write_state)
			default:
				if(cpuCS && cpustate == 3) begin
					writeAddr <= cpuAddr;
					writeDat  <= cpuWR;
					writeBE   <= ~{cpuU, cpuL};
					write_req <= 1;
					if(cache_ack) begin
						write_ena   <= 1;
						write_state <= 1;
					end
				end

			1: if(write_ack) begin
					// The SDRAM controller has picked up the request
					write_req   <= 0;
					write_state <= 2;
				end

			2: if(!write_ack) write_state <= 0;
		endcase
		if(~cpuCS) write_ena <= 0;
	end
end

assign ramready = cache_hit || write_ena;

assign DDRAM_CLK = sysclk;
assign DDRAM_BURSTCNT = 1;

reg [15:0] ddr_data;

always @ (posedge sysclk) begin
	reg  [2:0] state = 0;
	reg  [1:0] ba;
	reg [63:0] dout;

	cache_fill <= 0;
	ddr_data <= dout[{ba, 4'b0000} +:16];

	if(~DDRAM_BUSY) begin
		DDRAM_WE  <= 0;
		DDRAM_RD  <= 0;
	end

	if(~reset_n) begin
		state     <= 0;
		write_ack <= 0;
	end
	else begin
		case(state)
			0: if(~DDRAM_BUSY) begin
					if(~write_ack & write_req) begin
						DDRAM_ADDR <= {3'b001, writeAddr[28:3]};
						DDRAM_BE   <= {6'b000000,writeBE}<<{writeAddr[2:1],1'b0};
						DDRAM_DIN  <= {writeDat,writeDat,writeDat,writeDat};
						DDRAM_WE   <= 1;
						write_ack  <= 1;
					end
					else if(cache_req) begin
						DDRAM_ADDR <= {3'b001, cpuAddr[28:3]};
						DDRAM_BE   <= 8'hFF;
						DDRAM_RD   <= 1;
						ba         <= cpuAddr[2:1];
						state      <= 1;
					end
				end
			1: if(~DDRAM_BUSY & DDRAM_DOUT_READY) begin
					ddr_data      <= DDRAM_DOUT[{ba, 4'b0000} +:16];
					dout          <= DDRAM_DOUT;
					cache_fill    <= 1;
					ba            <= ba + 1'd1;
					state         <= state + 1'd1;
				end
			2,3: begin
					cache_fill    <= 1;
					ba            <= ba + 1'd1;
					state         <= state + 1'd1;
				end
			4: begin
					cache_fill    <= 1;
					state         <= 0;
				end
		endcase

		if(~write_req) write_ack <= 0;
	end
end

endmodule
