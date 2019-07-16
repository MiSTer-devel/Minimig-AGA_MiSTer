//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
//                                                                          //
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
	input         sysclk,
	input         reset_in,
	input         cache_rst,
	input         cache_inhibit,
	input   [3:0] cpu_cache_ctrl,
	output        reset_out,

	// DDR3
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,

	// cpu
	input  [27:1] cpuAddr,
	input         cpuCS,
	input   [1:0] cpustate,
	input         cpuL,
	input         cpuU,
	input  [15:0] cpuWR,
	output [15:0] cpuRD,
	output        cpuena
);

assign DDRAM_CLK = sysclk;

////////////////////////////////////////
// reset
////////////////////////////////////////

reg reset;
always @(posedge sysclk) begin
	reg [7:0] reset_cnt;

	if(!reset_in) begin
		reset_cnt     <= 0;
		reset         <= 0;
	end else begin
		if(reset_cnt == 170) reset <= 1;
		else reset_cnt <= reset_cnt + 8'd1;
	end
end

assign reset_out = reset;

////////////////////////////////////////
// cpu cache
////////////////////////////////////////

wire ccachehit;
wire cache_req;
reg  readcache_fill;

cpu_cache_new cpu_cache
(
	.clk              (sysclk),                // clock
	.rst              (!reset || !cache_rst),  // cache reset
	.cache_en         (1),                     // cache enable
	.cpu_cache_ctrl   (cpu_cache_ctrl),        // CPU cache control
	.cache_inhibit    (cache_inhibit),         // cache inhibit
	.cpu_cs           (cpuCS),                 // cpu activity
	.cpu_adr          (cpuAddr),               // cpu address
	.cpu_bs           (~{cpuU, cpuL}),         // cpu byte selects
	.cpu_we           (cpustate == 3),         // cpu write
	.cpu_ir           (cpustate == 0),         // cpu instruction read
	.cpu_dr           (cpustate == 2),         // cpu data read
	.cpu_dat_w        (cpuWR),                 // cpu write data
	.cpu_dat_r        (cpuRD),                 // cpu read data
	.cpu_ack          (ccachehit),             // cpu acknowledge
	.wb_en            (writebuffer_cache_ack), // writebuffer enable
	.sdr_dat_r        (ddr_data),              // sdram read data
	.sdr_read_req     (cache_req),             // sdram read request from cache
	.sdr_read_ack     (readcache_fill)         // sdram read acknowledge to cache
);

//// writebuffer ////
// write buffer, enables CPU to continue while a write is in progress
reg        writebuffer_req;
reg        writebuffer_ena;
reg  [1:0] writebufferBS;
reg [27:1] writebufferAddr;
reg [15:0] writebufferWR;
wire       writebuffer_cache_ack;
reg        writebuffer_hold;

always @ (posedge sysclk) begin
	reg writebuffer_state = 0;

	if(!reset) begin
		writebuffer_req   <= 0;
		writebuffer_ena   <= 0;
		writebuffer_state <= 0;
	end else begin
		if(!writebuffer_state) begin
			// CPU write cycle, no cycle already pending
			if(cpuCS && cpustate == 3) begin
				writebufferAddr <= cpuAddr;
				writebufferWR   <= cpuWR;
				writebufferBS   <= ~{cpuU, cpuL};
				if(writebuffer_cache_ack) begin
					writebuffer_req   <= 1;
					writebuffer_ena   <= 1;
					writebuffer_state <= 1;
				end
			end
		end
		else begin
			if(writebuffer_hold) begin
				// The SDRAM controller has picked up the request
				writebuffer_req   <= 0;
				writebuffer_state <= 0;
			end
		end

		if(~cpuCS) begin
			// the CPU has unpaused, so clear the ack signal
			writebuffer_ena <= 0;
		end
	end
end

assign cpuena = ccachehit || writebuffer_ena;

reg  [27:1] ddr_addr;
wire [63:0] ddr_dout;
reg  [15:0] ddr_din;
reg   [1:0] ddr_bs;
reg         ddr_we;
reg         ddr_req = 0;
wire        ddr_ack;

ddram ddram
(
	.reset(~reset_in),
	.DDRAM_CLK(DDRAM_CLK),

	.DDRAM_BUSY(DDRAM_BUSY),
	.DDRAM_BURSTCNT(DDRAM_BURSTCNT),
	.DDRAM_ADDR(DDRAM_ADDR),
	.DDRAM_DOUT(DDRAM_DOUT),
	.DDRAM_DOUT_READY(DDRAM_DOUT_READY),
	.DDRAM_RD(DDRAM_RD),
	.DDRAM_DIN(DDRAM_DIN),
	.DDRAM_BE(DDRAM_BE),
	.DDRAM_WE(DDRAM_WE),

	.addr(ddr_addr),
	.dout(ddr_dout),
	.din(ddr_din),
	.bs(ddr_bs),
	.we(ddr_we),
	.req(ddr_req),
	.ack(ddr_ack)
);

reg [15:0] ddr_data;

always @ (posedge sysclk) begin
	reg  [2:0] state = 0;
	reg        cas_sd_cas;
	reg        cas_sd_we;
	reg  [1:0] cas_dqm;
	reg [15:0] datawr;
	reg  [9:0] casaddr;

	readcache_fill <= 0;
	writebuffer_hold <= 0;
	ddr_data <= ddr_dout[{ddr_addr[2:1], 4'b0000} +:16];

	if(~reset) state <= 0;
	else begin
		case(state)
			0: if(writebuffer_req) begin
					ddr_addr          <= writebufferAddr;
					ddr_bs            <= writebufferBS;
					ddr_din           <= writebufferWR;
					ddr_we            <= 1;
					writebuffer_hold  <= 1;
					ddr_req           <= ~ddr_ack;
					state             <= 1;
				end
				else if(cache_req) begin
					ddr_addr          <= cpuAddr;
					ddr_we            <= 0;
					ddr_req           <= ~ddr_ack;
					state             <= 2;
				end
			1: begin
					if(ddr_req == ddr_ack) state <= 0;
				end
			2: if(ddr_req == ddr_ack) begin
					readcache_fill <= 1;
					ddr_addr[2:1] <= ddr_addr[2:1] + 1'd1;
					state <= state + 1'd1;
				end
			3,4: begin
					readcache_fill <= 1;
					ddr_addr[2:1] <= ddr_addr[2:1] + 1'd1;
					state <= state + 1'd1;
				end
			5: begin
					readcache_fill <= 1;
					state <= 0;
				end
		endcase
	end
end

endmodule


//
// DDR3 memory interface
// Copyright (c) 2019 Sorgelig
//
//
// This source file is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version. 
//
// This source file is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of 
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the 
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License 
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
// ------------------------------------------
//

module ddram
(
	input             reset,
	input             DDRAM_CLK,

	input             DDRAM_BUSY,
	output      [7:0] DDRAM_BURSTCNT,
	output reg [28:0] DDRAM_ADDR,
	input      [63:0] DDRAM_DOUT,
	input             DDRAM_DOUT_READY,
	output reg        DDRAM_RD,
	output reg [63:0] DDRAM_DIN,
	output reg  [7:0] DDRAM_BE,
	output reg        DDRAM_WE,

	input      [27:1] addr,
	output reg [63:0] dout,
	input      [15:0] din,
	input       [1:0] bs,
	input             we,
	input             req,
	output reg        ack
);

// RAM at 0x30000000
assign DDRAM_BURSTCNT = 1;

always @(posedge DDRAM_CLK) begin
	reg old_reset;
	reg state;

	old_reset <= reset;
	if(old_reset && ~reset) begin
		state     <= 0;
		DDRAM_WE  <= 0;
		DDRAM_RD  <= 0;
		ack       <= req;
	end
	else if(!DDRAM_BUSY) begin
		DDRAM_WE  <= 0;
		DDRAM_RD  <= 0;
		if(state) begin
			if(DDRAM_DOUT_READY) begin
				dout  <= DDRAM_DOUT;
				state <= 0;
				ack   <= req;
			end
		end
		else if (ack ^ req) begin
			DDRAM_ADDR <= {4'b0011, addr[27:3]};
			if(we) begin
				DDRAM_BE   <= {6'b000000,bs}<<{addr[2:1],1'b0};
				DDRAM_DIN  <= {din,din,din,din};
				DDRAM_WE   <= 1;
				ack        <= req;
			end
			else begin
				DDRAM_BE   <= 8'hFF;
				DDRAM_RD   <= 1;
				state      <= 1;
			end
		end
	end
end

endmodule
