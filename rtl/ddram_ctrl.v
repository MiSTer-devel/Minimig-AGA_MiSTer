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
	output     [28:0] DDRAM_ADDR,
	input      [63:0] DDRAM_DOUT,
	input             DDRAM_DOUT_READY,
	output            DDRAM_RD,
	output     [63:0] DDRAM_DIN,
	output      [7:0] DDRAM_BE,
	output            DDRAM_WE,

	// Second memory port, shared onto the same DDR3 interface. Used by the
	// A2065 Ethernet card, which touches DDR3 rarely; the CPU's fast RAM has
	// priority over it and is never made to wait.
	input      [28:0] mem2_address,
	input       [7:0] mem2_burstcount,
	input             mem2_read,
	output     [63:0] mem2_readdata,
	output            mem2_readdatavalid,
	input      [63:0] mem2_writedata,
	input       [7:0] mem2_byteenable,
	input             mem2_write,
	output            mem2_waitrequest,

	// cpu    
	input      [28:1] cpuAddr,
	input             cpuCS,
	input       [1:0] cpustate,
	input             cpuL,
	input             cpuU,
	input      [15:0] cpuWR,
	output     [15:0] cpuRD,
	input             ramshared,
	output            ramready
);

wire ramsel = cpuCS & (~&cpustate | ~cpuU | ~cpuL);

wire cache_hit;
wire cache_req;
reg  cache_fill;
wire cache_ack;

cpu_cache_new cpu_cache
(
	.clk              (sysclk),                 // clock
	.rst              (~reset_n | ~cache_rst),  // cache reset
	.cpu_cache_ctrl   (cpu_cache_ctrl),         // CPU cache control
	.cache_inhibit    (cache_inhibit | ramshared), // cache inhibit
	.cpu_cs           (ramsel),                 // cpu activity
	.cpu_adr          (cpuAddr),                // cpu address
	.cpu_bs           (~{cpuU, cpuL}),          // cpu byte selects
	.cpu_we           (cpustate == 3),          // cpu write
	.cpu_ir           (cpustate == 0),          // cpu instruction read
	.cpu_dr           (cpustate == 2),          // cpu data read
	.cpu_dat_w        (cpuWR),                  // cpu write data
	.cpu_dat_r        (cpuRD),                  // cpu read data
	.cpu_ack          (cache_hit),              // cpu acknowledge
	.wb_en            (cache_ack),              // write enable
	.sdr_dat_r        (ddr_swap ? {ddr_data[7:0], ddr_data[15:8]} : ddr_data), // sdram read data
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
				if(ramsel && cpustate == 3) begin
					writeAddr <= cpuAddr;
					writeDat  <= ramshared ? {cpuWR[7:0],cpuWR[15:8]} : cpuWR;
					writeBE   <= ramshared ? ~{cpuL, cpuU} : ~{cpuU, cpuL};
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
		if(~ramsel) write_ena <= 0;
	end
end

assign ramready = cache_hit || write_ena;

assign DDRAM_CLK = sysclk;

// Fast RAM's own view of DDR3. It goes through the arbiter below rather than
// straight to the pins, so that the second port can share the interface.
reg  [28:0] ram_addr;
reg  [63:0] ram_din;
reg   [7:0] ram_be;
reg         ram_rd, ram_we;
wire        ram_busy;
wire [63:0] ram_dout       = DDRAM_DOUT;
wire        ram_dout_ready;

a2065_ddram_arbiter arbiter
(
	.clk             (sysclk),
	.rst             (~reset_n),

	.m0_address      (ram_addr),
	.m0_burstcount   (8'd1),
	.m0_read         (ram_rd),
	.m0_readdata     (),
	.m0_readdatavalid(ram_dout_ready),
	.m0_writedata    (ram_din),
	.m0_byteenable   (ram_be),
	.m0_write        (ram_we),
	.m0_waitrequest  (ram_busy),

	.m1_address      (mem2_address),
	.m1_burstcount   (mem2_burstcount),
	.m1_read         (mem2_read),
	.m1_readdata     (),
	.m1_readdatavalid(mem2_readdatavalid),
	.m1_writedata    (mem2_writedata),
	.m1_byteenable   (mem2_byteenable),
	.m1_write        (mem2_write),
	.m1_waitrequest  (mem2_waitrequest),

	.s_address       (DDRAM_ADDR),
	.s_burstcount    (DDRAM_BURSTCNT),
	.s_read          (DDRAM_RD),
	.s_readdata      (DDRAM_DOUT),
	.s_readdatavalid (DDRAM_DOUT_READY),
	.s_writedata     (DDRAM_DIN),
	.s_byteenable    (DDRAM_BE),
	.s_write         (DDRAM_WE),
	.s_waitrequest   (DDRAM_BUSY)
);

assign mem2_readdata = DDRAM_DOUT;

reg        ddr_swap;
reg [15:0] ddr_data;

always @ (posedge sysclk) begin
	reg  [2:0] state = 0;
	reg  [1:0] ba;
	reg [63:0] dout;

	cache_fill <= 0;
	ddr_data <= dout[{ba, 4'b0000} +:16];

	if(~ram_busy) begin
		ram_we  <= 0;
		ram_rd  <= 0;
	end

	if(~reset_n) begin
		state     <= 0;
		write_ack <= 0;
	end
	else begin
		case(state)
			0: if(~ram_busy) begin
					if(~write_ack & write_req) begin
						ram_addr <= {3'b001, writeAddr[28:3]};
						ram_be   <= {6'b000000,writeBE}<<{writeAddr[2:1],1'b0};
						ram_din  <= {writeDat,writeDat,writeDat,writeDat};
						ram_we   <= 1;
						write_ack  <= 1;
					end
					else if(cache_req) begin
						ram_addr <= {3'b001, cpuAddr[28:3]};
						ram_be   <= 8'hFF;
						ram_rd   <= 1;
						ba         <= cpuAddr[2:1];
						state      <= 1;
						ddr_swap   <= ramshared;
					end
				end
			1: if(~ram_busy & ram_dout_ready) begin
					ddr_data      <= ram_dout[{ba, 4'b0000} +:16];
					dout          <= ram_dout;
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
