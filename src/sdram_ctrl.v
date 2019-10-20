//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
//                                                                          //
// Copyright (c) 2009/2011 Tobias Gubener                                   //
// Subdesign fAMpIGA by TobiFlex                                            //
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
//////////////////////////////////////////////////////////////////////////////
//
// Code re-work:
// - Shrink 16 to 12 cycles to work at quarter lower frequency with the same performance.
// - Support for 64MB SDRAM
//
// (C)2019 Alexey Melnikov
//


module sdram_ctrl
(
	// system
	input             sysclk,
	input             c_7m,
	input             reset_n,
	input             cache_rst,
	input             cache_inhibit,
	input       [3:0] cpu_cache_ctrl,
	// sdram
	output reg [12:0] sdaddr,
	output      [1:0] ba,
	output            sd_cs,
	output reg        sd_we,
	output reg        sd_ras,
	output reg        sd_cas,
	output      [1:0] dqm,
	inout  reg [15:0] sdata,
	// chip
	input      [22:1] chipAddr, //we only use the first 8M block of the RAM for non-fastram
	input             chipL,
	input             chipU,
	input             chipRW,
	input             chip_dma,
	input      [15:0] chipWR,
	output reg [15:0] chipRD,
	output     [47:0] chip48,
	// cpu
	input      [22:1] cpuAddr,
	input             cpuCS,
	input       [1:0] cpustate,
	input             cpuL,
	input             cpuU,
	input      [15:0] cpuWR,
	output     [15:0] cpuRD,
	output            ramready
);

assign dqm   = sdaddr[12:11];
assign ba    = 0;
assign sd_cs = 0;

//// parameters ////
localparam [1:0]
	WAITING = 0,
	WRITE1 = 1,
	WRITE2 = 2;

localparam [2:0]
	IDLE = 0,
	CHIP = 1,
	CPU_READCACHE = 2,
	CPU_WRITECACHE = 3;


////////////////////////////////////////
// reset
////////////////////////////////////////

reg reset;
always @(posedge sysclk) begin
	reg [7:0] reset_cnt;

	if(!reset_n) begin
		reset_cnt     <= 0;
		reset         <= 0;
	end else begin
		if(reset_cnt == 170) begin
			if(sdram_state == 15) reset <= 1;
		end
		else begin
			reset_cnt <= reset_cnt + 8'd1;
		end
	end
end

// cpu cache
wire cache_rd_ack;
wire cache_wr_ack;
wire cache_req;
cpu_cache_new cpu_cache
(
	.clk              (sysclk),                // clock
	.rst              (!reset || !cache_rst),  // cache reset
	.cache_en         (1'b1),                  // cache enable
	.cpu_cache_ctrl   (cpu_cache_ctrl),        // CPU cache control
	.cache_inhibit    (cache_inhibit),         // cache inhibit
	.cpu_cs           (cpuCS),                 // cpu activity
	.cpu_adr          (cpuAddr),               // cpu address
	.cpu_bs           ({!cpuU, !cpuL}),        // cpu byte selects
	.cpu_we           (cpustate == 3),         // cpu write
	.cpu_ir           (cpustate == 0),         // cpu instruction read
	.cpu_dr           (cpustate == 2),         // cpu data read
	.cpu_dat_w        (cpuWR),                 // cpu write data
	.cpu_dat_r        (cpuRD),                 // cpu read data
	.cpu_ack          (cache_rd_ack),          // cpu acknowledge
	.wb_en            (cache_wr_ack),          // write enable
	.sdr_dat_r        (sdata_reg),             // sdram read data
	.sdr_read_req     (cache_req),             // sdram read request from cache
	.sdr_read_ack     (cache_fill),            // sdram read acknowledge to cache
	.snoop_act        (chipWE),                // snoop act (write only - just update existing data in cache)
	.snoop_adr        (chipAddr),              // snoop address
	.snoop_dat_w      (chipWR),                // snoop write data
	.snoop_bs         ({!chipU, !chipL})       // snoop byte selects
);

reg cache_fill;
always @ (posedge sysclk) begin
	cache_fill <= 0;

	if(init_done && slot_type == CPU_READCACHE) begin
		case(sdram_state)
		   7, 9, 11, 13: cache_fill <= 1;
		endcase
	end
end

// write buffer, enables CPU to continue while a write is in progress
reg        write_ena;
reg        write_req;
reg        write_ack;
reg  [1:0] write_dqm;
reg [22:1] writeAddr;
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
				if(~write_ena && cpuCS && cpustate == 3) begin
					writeAddr <= cpuAddr;
					writeDat  <= cpuWR;
					write_dqm <= {cpuU, cpuL};
					write_req <= 1;
					if(cache_wr_ack) begin
						write_state <= 1;
					end
				end

			1: if(write_ack) begin
					write_req   <= 0;
					write_state <= 2;
				end

			2: if(!write_ack) begin
					write_ena   <= 1;
					write_state <= 0;
				end
		endcase

		if(~cpuCS) write_ena <= 0;
	end
end

assign ramready = cache_rd_ack || write_ena;

//// chip line read ////
reg [15:0] chip48_1, chip48_2, chip48_3;

always @ (posedge sysclk) begin
	if(slot_type == CHIP) begin
		case(sdram_state)
			 8: chipRD   <= sdata_reg;
			10: chip48_1 <= sdata_reg;
			12: chip48_2 <= sdata_reg;
			14: chip48_3 <= sdata_reg;
		endcase
	end
end

assign chip48 = {chip48_1, chip48_2, chip48_3};


////////////////////////////////////////
// SDRAM control
////////////////////////////////////////


//// init counter ////
reg [3:0] initstate;
reg       init_done;
always @ (posedge sysclk) begin
	if(!reset) begin
		initstate <= 0;
		init_done <= 0;
	end else begin
		if (sdram_state == 15) begin
			if(~&initstate) initstate <= initstate + 1'd1;
			else init_done <= 1;
		end
	end
end


//// sdram state ////
reg [3:0] sdram_state;
always @ (posedge sysclk) begin
	reg old_7m;

	sdram_state <= sdram_state + 1'd1;

	old_7m <= c_7m;
	if(~old_7m & c_7m) sdram_state <= 1;
end

//// sdram control ////

reg  [2:0] slot_type = IDLE;
reg [15:0] sdata_reg;
reg        chipWE;

always @ (posedge sysclk) begin
	reg        cas_sd_cas;
	reg        cas_sd_we;
	reg  [1:0] cas_dqm;
	reg [15:0] datawr;
	reg  [9:0] casaddr;
	reg  [3:0] rcnt;

	if(~sdram_state[0]) begin
		sd_ras                <= 1;
		sd_cas                <= 1;
		sd_we                 <= 1;
		sdata                 <= 16'hZZZZ;
		chipWE                <= 0;
	end

	if(sdram_state[0]) sdata_reg  <= sdata;

	if(!init_done) begin
		slot_type             <= IDLE;
		casaddr               <= 0;
		rcnt                  <= 0;
		if(sdram_state == 0) begin
			case(initstate)
				4 : begin // PRECHARGE
					sdaddr[10]   <= 1; // all banks
					sd_ras       <= 0;
					sd_cas       <= 1;
					sd_we        <= 0;
				end
				8,10 : begin // AUTOREFRESH
					sd_ras       <= 0;
					sd_cas       <= 0;
					sd_we        <= 1;
				end
				13 : begin // LOAD MODE REGISTER
					sd_ras       <= 0;
					sd_cas       <= 0;
					sd_we        <= 0;
					sdaddr       <= 13'b0001000100010; // CL=2, BURST=4
				end
			endcase
		end
	end else begin

		case(sdram_state)

			// RAS
			0 : begin
				cas_sd_cas      <= 1;
				cas_sd_we       <= 1;
				cas_dqm         <= 0;
				slot_type       <= IDLE;

				if(~&rcnt) rcnt <= rcnt + 1'd1;

				// we give the chipset first priority
				// (this includes anything on the "motherboard" - chip RAM, slow RAM and Kickstart, turbo modes notwithstanding)
				if(!chip_dma || !chipRW) begin
					slot_type    <= CHIP;
					{sdaddr,casaddr[8:0]} <= chipAddr;
					sd_ras       <= 0;
					cas_dqm      <= {chipU,chipL};
					cas_sd_cas   <= 0;
					cas_sd_we    <= chipRW;
					datawr       <= chipWR;
					chipWE       <= !chipRW;
				end
				else if(write_req) begin
					slot_type    <= CPU_WRITECACHE;
					{sdaddr,casaddr[8:0]} <= writeAddr;
					sd_ras       <= 0;
					cas_dqm      <= write_dqm;
					cas_sd_we    <= 0;
					cas_sd_cas   <= 0;
					write_ack    <= 1; // let the write buffer know we're about to write
					datawr       <= writeDat;
				end
				// request from read cache
				else if(cache_req) begin
					slot_type    <= CPU_READCACHE;
					{sdaddr,casaddr[8:0]} <= cpuAddr;
					sd_ras       <= 0;
					cas_sd_cas   <= 0;
				end
				else if(&rcnt) begin
					// REFRESH
					sd_ras       <= 0;
					sd_cas       <= 0;
					rcnt         <= 0;
				end
			end

			// CAS
			2 : begin
				sdaddr          <= {1'b1, casaddr}; // AUTO PRECHARGE
				sd_cas          <= cas_sd_cas;
				if(!cas_sd_we) begin
					sdata        <= datawr;
					sdaddr[12:11]<= cas_dqm;
					sd_we        <= 0;
				end
			end

			12: write_ack      <= 0; // indicate to write that it's safe to accept the next write
		endcase
	end
end

endmodule
