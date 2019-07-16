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
	input             reset_in,
	input             cache_rst,
	input             cache_inhibit,
	input       [3:0] cpu_cache_ctrl,
	output            reset_out,
	// sdram
	output reg [12:0] sdaddr,
	output reg  [1:0] ba,
	output reg        sd_cs,
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
	input      [25:1] cpuAddr,
	input       [5:0] cpustate,
	input             cpuL,
	input             cpuU,
	input      [15:0] cpuWR,
	output     [15:0] cpuRD,
	output reg        enaWRreg,
	output reg        ena7RDreg,
	output reg        ena7WRreg,
	output            cpuena
);

assign dqm = sdaddr[12:11];

//// parameters ////
localparam [1:0]
	WAITING = 0,
	WRITE1 = 1,
	WRITE2 = 2,
	WRITE3 = 3;

localparam [2:0]
	REFRESH = 0,
	CHIP = 1,
	CPU_READCACHE = 2,
	CPU_WRITECACHE = 3,
	IDLE = 4;

localparam [3:0]
	ph0 = 0,
	ph1 = 1,
	ph2 = 2,
	ph3 = 3,
	ph4 = 4,
	ph5 = 5,
	ph6 = 6,
	ph7 = 7,
	ph8 = 8,
	ph9 = 9,
	ph10 = 10,
	ph11 = 11;


////////////////////////////////////////
// reset
////////////////////////////////////////

reg reset;
reg reset_sdstate;
always @(posedge sysclk) begin
	reg [7:0] reset_cnt;

	if(!reset_in) begin
		reset_cnt     <= 0;
		reset         <= 0;
		reset_sdstate <= 0;
	end else begin
		if(reset_cnt == 42) reset_sdstate <= 1;
		if(reset_cnt == 170) begin
			if(sdram_state == ph11) reset <= 1;
		end
		else begin
			reset_cnt <= reset_cnt + 8'd1;
		end
	end
end

assign reset_out = init_done;

////////////////////////////////////////
// cpu cache
////////////////////////////////////////

wire ccachehit;
wire cache_req;
wire snoop_act = ((sdram_state==ph2)&&(!chipRW));
wire readcache_fill = (cache_fill_1 && slot1_type == CPU_READCACHE) || (cache_fill_2 && slot2_type == CPU_READCACHE);

cpu_cache_new cpu_cache
(
	.clk              (sysclk),                       // clock
	.rst              (!reset || !cache_rst),         // cache reset
	.cache_en         (1'b1),                         // cache enable
	.cpu_cache_ctrl   (cpu_cache_ctrl),               // CPU cache control
	.cache_inhibit    (cache_inhibit),                // cache inhibit
	.cpu_cs           (!cpustate[2]),                 // cpu activity
	.cpu_adr          (cpuAddr),                      // cpu address
	.cpu_bs           ({!cpuU, !cpuL}),               // cpu byte selects
	.cpu_we           (&cpustate[1:0]),               // cpu write
	.cpu_ir           (!cpustate[1:0]),               // cpu instruction read
	.cpu_dr           (cpustate[1] && !cpustate[0]),  // cpu data read
	.cpu_dat_w        (cpuWR),                        // cpu write data
	.cpu_dat_r        (cpuRD),                        // cpu read data
	.cpu_ack          (ccachehit),                    // cpu acknowledge
	.wb_en            (writebuffer_cache_ack),        // writebuffer enable
	.sdr_dat_r        (sdata_reg),                    // sdram read data
	.sdr_read_req     (cache_req),                    // sdram read request from cache
	.sdr_read_ack     (readcache_fill),               // sdram read acknowledge to cache
	.snoop_act        (snoop_act),                    // snoop act (write only - just update existing data in cache)
	.snoop_adr        (chipAddr),                     // snoop address
	.snoop_dat_w      (chipWR),                       // snoop write data
	.snoop_bs         ({!chipU, !chipL})              // snoop byte selects
);

//// writebuffer ////
// write buffer, enables CPU to continue while a write is in progress
reg        writebuffer_req;
reg        writebuffer_ena;
reg  [1:0] writebuffer_dqm;
reg [25:1] writebufferAddr;
reg [15:0] writebufferWR;
wire       writebuffer_cache_ack;
reg        writebuffer_hold;
reg  [1:0] writebuffer_state;

always @ (posedge sysclk) begin
	if(!reset) begin
		writebuffer_req   <= 0;
		writebuffer_ena   <= 0;
		writebuffer_state <= WAITING;
	end else begin
		case(writebuffer_state)
			WAITING : begin
				// CPU write cycle, no cycle already pending
				if(cpustate[2:0] == 3'b011) begin
					writebufferAddr <= cpuAddr;
					writebufferWR   <= cpuWR;
					writebuffer_dqm <= {cpuU, cpuL};
					writebuffer_req <= 1;
					if(writebuffer_cache_ack) begin
						writebuffer_ena   <= 1;
						writebuffer_state <= WRITE2;
					end
				end
			end
			WRITE2 : begin
				if(writebuffer_hold) begin
					// The SDRAM controller has picked up the request
					writebuffer_req   <= 0;
					writebuffer_state <= WRITE3;
				end
			end
			WRITE3 : begin
				if(!writebuffer_hold) begin
					// Wait for write cycle to finish, so it's safe to update the signals
					writebuffer_state <= WAITING;
				end
			end
			default : begin
				writebuffer_state <= WAITING;
			end
		endcase
		if(cpustate[2]) begin
			// the CPU has unpaused, so clear the ack signal
			writebuffer_ena <= 0;
		end
	end
end

assign cpuena = ccachehit || writebuffer_ena;

//// chip line read ////
reg [15:0] chip48_1, chip48_2, chip48_3;

always @ (posedge sysclk) begin
	if(slot1_type == CHIP) begin
		case(sdram_state)
			ph7 : chipRD   <= sdata_reg;
			ph8 : chip48_1 <= sdata_reg;
			ph9 : chip48_2 <= sdata_reg;
			ph10: chip48_3 <= sdata_reg;
		endcase
	end
end

assign chip48 = {chip48_1, chip48_2, chip48_3};


////////////////////////////////////////
// SDRAM control
////////////////////////////////////////


//// write / read control ////
always @ (posedge sysclk) begin
	enaWRreg  <= 0;
	ena7RDreg <= 0;
	ena7WRreg <= 0;
	if(reset_sdstate) begin
		case(sdram_state) // LATENCY=3
			 ph2: enaWRreg  <= 1;
			 ph5: enaWRreg  <= 1;
			 ph8: enaWRreg  <= 1;
			ph11: enaWRreg  <= 1;
		endcase
		case(sdram_state) // LATENCY=3
			 ph5: ena7RDreg <= 1;
			ph11: ena7WRreg <= 1;
		endcase
	end
end


//// init counter ////
reg [3:0] initstate;
reg       init_done;
always @ (posedge sysclk) begin
	if(!reset) begin
		initstate <= 0;
		init_done <= 0;
	end else begin
		if (sdram_state == ph11) begin // LATENCY=3
			if(~&initstate) initstate <= initstate + 4'd1;
			else init_done <= 1;
		end
	end
end


//// sdram state ////
reg [3:0] sdram_state;
always @ (posedge sysclk) begin
	reg old_7m;

	sdram_state <= sdram_state + 1'd1;
	if (sdram_state == ph11) sdram_state <= 0;

	old_7m <= c_7m;
	if(~old_7m & c_7m) sdram_state <= ph2;
end

reg cache_fill_1;
reg cache_fill_2;
always @ (posedge sysclk) begin
	cache_fill_1 <= 0;
	cache_fill_2 <= 0;

	if(init_done) begin
		case(sdram_state)
		   ph0: cache_fill_2 <= 1;
		   ph1: cache_fill_2 <= 1;
		   ph2: cache_fill_2 <= 1;
		   ph3: cache_fill_2 <= 1;
		   ph6: cache_fill_1 <= 1;
		   ph7: cache_fill_1 <= 1;
		   ph8: cache_fill_1 <= 1;
		   ph9: cache_fill_1 <= 1;
		endcase
	end
end


//// sdram control ////
// Address bits will be allocated as follows:
// 24:23: bank
// 22:10: row
// 25,9:1: column

reg  [2:0] slot1_type = IDLE;
reg  [2:0] slot2_type = IDLE;
reg [15:0] sdata_reg;

always @ (posedge sysclk) begin
	reg        cas_sd_cas;
	reg        cas_sd_we;
	reg  [1:0] cas_dqm;
	reg [15:0] datawr;
	reg  [9:0] casaddr;

	sd_cs                         <= 0;
	sd_ras                        <= 1;
	sd_cas                        <= 1;
	sd_we                         <= 1;
	sdata                         <= 16'hZZZZ;
	sdata_reg                     <= sdata;

	if(!init_done) begin
		slot1_type                 <= IDLE;
		slot2_type                 <= IDLE;
		sd_cs                      <= 1;
		if(sdram_state == ph1) begin
			case(initstate)
				2 : begin // PRECHARGE
					sdaddr[10]        <= 1; // all banks
					sd_cs             <= 0;
					sd_ras            <= 0;
					sd_cas            <= 1;
					sd_we             <= 0;
				end
				3,4,5,6,7,8,9,10,11,12 : begin // AUTOREFRESH
					sd_cs             <= 0;
					sd_ras            <= 0;
					sd_cas            <= 0;
					sd_we             <= 1;
				end
				13 : begin // LOAD MODE REGISTER
					sd_cs             <= 0;
					sd_ras            <= 0;
					sd_cas            <= 0;
					sd_we             <= 0;
					sdaddr            <= 13'b0001000100010; // BURST=4 LATENCY=2
				end
			endcase
		end
	end else begin
		case(sdram_state)

			// 25:23 : 000 for ROM, ChipRAM and SlowRAM only
			//       : 100 also slower RAM 

			// Access slot 1, RAS
			ph1 : begin
				cas_sd_cas           <= 1;
				cas_sd_we            <= 1;
				cas_dqm              <= 0;
				slot1_type           <= IDLE;

				// we give the chipset first priority
				// (this includes anything on the "motherboard" - chip RAM, slow RAM and Kickstart, turbo modes notwithstanding)
				if(!chip_dma || !chipRW) begin
					slot1_type        <= CHIP;
					{casaddr[9],ba,sdaddr,casaddr[8:0]} <= {3'b000,chipAddr};
					sd_ras            <= 0;
					cas_dqm           <= {chipU,chipL};
					cas_sd_cas        <= 0;
					cas_sd_we         <= chipRW;
					datawr            <= chipWR;
				end
				// the Amiga CPU gets next bite of the cherry, unless the OSD CPU has been cycle-starved
				// request from write buffer
				else if(writebuffer_req && !writebufferAddr[24:23]) begin
				// We only yield to the OSD CPU if it's both cycle-starved and ready to go.
					slot1_type        <= CPU_WRITECACHE;
					{casaddr[9],ba,sdaddr,casaddr[8:0]} <= writebufferAddr;
					sd_ras            <= 0;
					cas_dqm           <= writebuffer_dqm;
					cas_sd_we         <= 0;
					cas_sd_cas        <= 0;
					writebuffer_hold  <= 1; // let the write buffer know we're about to write
					datawr            <= writebufferWR;
				end
				// request from read cache
				else if(cache_req && !cpuAddr[24:23]) begin
					// we only yield to the OSD CPU if it's both cycle-starved and ready to go
					slot1_type        <= CPU_READCACHE;
					{casaddr[9],ba,sdaddr,casaddr[8:0]} <= cpuAddr;
					sd_ras            <= 0;
					cas_sd_cas        <= 0;
				end
				else begin
					// REFRESH
					slot1_type        <= REFRESH;
					sd_ras            <= 0;
					sd_cas            <= 0;
					cas_dqm           <= 2'b11;
				end
			end

			// Access slot 2, RAS
			ph7 : begin
				cas_sd_cas           <= 1;
				cas_sd_we            <= 1;
				cas_dqm              <= 0;
				slot2_type           <= IDLE;

				if(writebuffer_req && writebufferAddr[24:23]) begin
					slot2_type        <= CPU_WRITECACHE;
					{casaddr[9],ba,sdaddr,casaddr[8:0]} <= writebufferAddr;
					sd_ras            <= 0;
					cas_dqm           <= writebuffer_dqm;
					cas_sd_we         <= 0;
					cas_sd_cas        <= 0;
					writebuffer_hold  <= 1; // let the write buffer know we're about to write
					datawr            <= writebufferWR;
				end
				else if(cache_req && cpuAddr[24:23]) begin
					slot2_type        <= CPU_READCACHE;
					{casaddr[9],ba,sdaddr,casaddr[8:0]} <= cpuAddr;
					sd_ras            <= 0;
					cas_sd_cas        <= 0;
				end
			end

			// CAS
			ph3,ph9 : begin
				sdaddr                <= {1'b1, casaddr}; // AUTO PRECHARGE
				sd_cas                <= cas_sd_cas;
				if(!cas_sd_we) begin
					sdata              <= datawr;
					sdaddr[12:11]      <= cas_dqm;
					sd_we              <= 0;
				end
				writebuffer_hold      <= 0; // indicate to WriteBuffer that it's safe to accept the next write
			end
		endcase
	end
end


//        Slot 1       Slot 2
//        -----------  ----------
// ph0    NOP          READ
// ph1    RAS/REFRESH  READ
// ph2    NOP          READ
// ph3    CAS/WRITE    READ
// ph4    NOP          NOP
// ph5    NOP          NOP
// ph6    READ         NOP
// ph7    READ         RAS
// ph8    READ         NOP
// ph9    READ         CAS/WRITE
// ph10   NOP          NOP
// ph11   NOP          NOP


endmodule
