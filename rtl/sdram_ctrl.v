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
	input             dcache_sw_en,
	input             sdram_big,
	// sdram
	output reg [12:0] sd_addr,
	output reg  [1:0] sd_ba,
	output reg        sd_cs,
	output reg        sd_we,
	output reg        sd_ras,
	output reg        sd_cas,
	output      [1:0] sd_dqm,
	inout      [15:0] sd_data,
	output reg        sd_clk,
	output            sd_cke,
	// chip
	input      [24:1] chipAddr,
	input             chipL,
	input             chipU,
	input             chipRW,
	input             chipDMA,
	input      [15:0] chipWR,
	output reg [15:0] chipRD,
	output     [47:0] chip48,
	input             chip32,
	input      [15:0] chipWR2,
	output reg [15:0] chipRD2,
	// cpu
	input      [24:1] cpuAddr,
	input             cpuCS,
	input       [1:0] cpustate,
	input             cpuL,
	input             cpuU,
	input      [15:0] cpuWR,
	output     [15:0] cpuRD,
	output            ramready,
	input             fast_req,
	input             fast_we,
	input      [26:1] fast_addr,
	input       [1:0] fast_dqm,
	input      [15:0] fast_wdat,
	input             fast_w2,
	input       [1:0] fast_dqm2,
	input      [15:0] fast_wdat2,
	output reg        fast_ack,
	output reg        fast_rvalid,
	output     [15:0] fast_rdat
);

assign sd_cke = 1;
assign sd_dqm = sd_addr[12:11];

reg [15:0] sd_dout;
reg        sd_oe = 0;
assign sd_data = sd_oe ? sd_dout : 16'hZZZZ;

//// parameters ////
localparam [2:0]
	IDLE = 0,
	CHIP = 1,
	CPU_READCACHE = 2,
	CPU_WRITECACHE = 3,
	REFRESH = 4;


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

wire ramsel = cpuCS & (~&cpustate | ~cpuU | ~cpuL);

reg        a_wr2 = 0;
reg        a_rd2 = 0;
reg [15:0] datawr2;
reg        chipWE2 = 0;
reg        snoop2 = 0;

// cpu cache
wire cache_rd_ack;
wire cache_wr_ack;
wire cache_req;
cpu_cache_new cpu_cache
(
	.clk              (sysclk),                // clock
	.rst              (!reset || !cache_rst),  // cache reset
	.cpu_cache_ctrl   (cpu_cache_ctrl),        // CPU cache control
	.dcache_sw_en     (dcache_sw_en),
	.cache_inhibit    (cache_inhibit),         // cache inhibit
	.cpu_cs           (ramsel),                // cpu activity
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
	.snoop_act        (chipWE | chipWE2),      // snoop act (write only - just update existing data in cache)
	.snoop_adr        (snoop2 ? {chipAddr[24:2], 1'b1} : chipAddr), // snoop address
	.snoop_dat_w      (snoop2 ? chipWR2 : chipWR), // snoop write data
	.snoop_bs         (snoop2 ? 2'b11 : {!chipU, !chipL}) // snoop byte selects
	,
	.buf_ok           (1'b0),
	.buf_dat          (64'd0),
	.buf_take         ()
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
reg [24:1] writeAddr;
reg [15:0] writeDat;
reg        fwd_en = 1'b0;
reg  [1:0] fwd_pos;
reg [15:0] fwd_dat;
reg  [1:0] fwd_dqm;

always @ (posedge sysclk) begin
	reg  [1:0] write_state;

	if(~reset_n) begin
		write_req   <= 0;
		write_ena   <= 0;
		write_state <= 0;
	end else begin
		case(write_state)
			default:
				if(~write_ena && ramsel && cpustate == 3) begin
					writeAddr <= cpuAddr;
					writeDat  <= cpuWR;
					write_dqm <= {cpuU, cpuL};
					write_req <= 1;
					if(cache_wr_ack) begin
						write_ena   <= 1;
						write_state <= 1;
					end
				end

			1: if(write_ack) begin
					write_req   <= 0;
					write_state <= 2;
				end

			2: if(!write_ack) begin
					write_state <= 0;
				end
		endcase

		if(~ramsel) write_ena <= 0;
	end
end

assign ramready = cache_rd_ack || write_ena;

//// chip line read ////
reg [15:0] chip48_1, chip48_2, chip48_3;

always @ (posedge sysclk) begin
	reg [15:0] sdata_chip;
	reg [15:0] m;

	sdata_chip <= sdata_reg;
	m = sdata_chip;
	if(fwd_en) begin
		if(!fwd_dqm[1]) m[15:8] = fwd_dat[15:8];
		if(!fwd_dqm[0]) m[7:0]  = fwd_dat[7:0];
	end
	if(slot_type == CHIP) begin
		case(sdram_state)
			 9: chipRD   <= (fwd_en && fwd_pos==2'd0) ? m : sdata_chip;
			11: begin
					chip48_1 <= (fwd_en && fwd_pos==2'd1) ? m : sdata_chip;
					if(a_rd2) chipRD2 <= (fwd_en && fwd_pos==2'd1) ? m : sdata_chip;
				end
			13: chip48_2 <= (fwd_en && fwd_pos==2'd2) ? m : sdata_chip;
			15: chip48_3 <= (fwd_en && fwd_pos==2'd3) ? m : sdata_chip;
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
reg       sdram_st0 = 1;
reg       sdram_st2 = 0;
reg       old_7m;
wire      resync   = ~old_7m & c_7m;
wire      resync_x = resync & (sdram_state != 4'd15);
always @ (posedge sysclk) begin
	sdram_state <= sdram_state + 1'd1;
	sdram_st0   <= (sdram_state == 15);
	sdram_st2   <= (sdram_state == 1);

	old_7m <= c_7m;
	if(resync) begin
		sdram_state <= 0;
		sdram_st0   <= 1;
		sdram_st2   <= 0;
	end
end

wire        fast_cs  = fast_addr[26];
wire  [1:0] fast_ba  = fast_cs ? fast_addr[25:24] : ((sdram_big ? fast_addr[25:24] : fast_addr[24:23]) + 2'd1);
wire [12:0] fast_row = (fast_cs | sdram_big) ? fast_addr[23:11] : fast_addr[22:10];
wire  [9:0] fast_col = (fast_cs | sdram_big) ? fast_addr[10:1]  : {1'b0, fast_addr[9:1]};

//// sdram control ////

reg  [2:0] slot_type = IDLE;
reg [15:0] sdata_reg;
reg        chipWE;

reg [15:0] b_buf;
reg        b_tail;
reg        b_rvalid;
reg [15:0] fast_rdat_r;
assign fast_rdat = fast_rdat_r;

wire chip_req = ~chipDMA | ~chipRW;

reg [12:0] p_addr;
reg  [1:0] p_ba;
reg        p_cs  = 0;
reg        p_ras = 1;
reg        p_cas = 1;
reg        p_we  = 1;
reg        p_oe  = 0;
reg [15:0] p_dout;
reg        st0_go  = 0;
reg        st0_cpu = 0;

wire        act_chip = st0_go & chip_req;
wire        act_cpu  = st0_cpu & (write_req | cache_req);
wire [14:0] row_cpu  = write_req ? writeAddr[24:10] : cpuAddr[24:10];
wire [14:0] row_new  = act_chip ? chipAddr[24:10] : act_cpu ? row_cpu : {p_ba, p_addr};
wire        ras_new  = ~(act_chip | act_cpu) & p_ras;

always @ (posedge sysclk) begin : ctrl
	reg        cas_sd_cas;
	reg        cas_sd_we;
	reg  [1:0] cas_dqm;
	reg [15:0] datawr;
	reg  [9:0] casaddr;
	reg  [5:0] ref_div;
	reg  [3:0] ref_pend;
	reg  [3:0] ref_pend_n;
	reg        ref_go;
	reg        ref_now;
	reg  [3:0] ref1_pend;
	reg        ref1_go;
	reg        ref1_now;
	reg        a_act;
	reg        init_n;
	reg        b_go;
	reg        b_wr;
	reg        b_half;
	reg        b_cs;
	reg  [1:0] b_ba;
	reg [12:0] b_row;
	reg  [9:0] b_col;
	reg  [1:0] b_dqm;
	reg [15:0] b_dat;
	reg        b_rd;
	reg        b_rd_half;
	reg        b_rd_cs;
	reg        b_rd_odd;
	reg        b_dp;
	reg        b_dp4;
	reg        b_dp_odd;
	reg        b_dp_tail;
	reg        b_cont;
	reg        b_w2;
	reg  [1:0] b_dqm2;
	reg [15:0] b_dat2;
	reg        b_wcont;

	sd_clk <= sdram_state[0];
	fast_ack <= 0;
	b_rvalid <= 0;
	b_tail <= 0;

	{sd_ba, sd_addr}      <= row_new;
	sd_ras                <= ras_new;
	sd_cs                 <= p_cs;
	sd_cas                <= p_cas;
	sd_we                 <= p_we;
	sd_oe                 <= p_oe;
	sd_dout               <= p_dout;

	{p_ba, p_addr}        <= row_new;
	p_ras                 <= ras_new;
	if(sdram_state[0] | resync_x) begin
		p_ras              <= 1;
		p_cas              <= 1;
		p_we               <= 1;
		p_oe               <= 0;
	end
	if(resync_x) begin
		p_cs               <= 0;
		p_addr[12:11]      <= {2{~init_done}};
	end

	if(~sdram_state[0]) chipWE <= 0;

	if(sdram_state == 4) begin
		chipWE2 <= a_wr2;
		snoop2  <= a_wr2;
	end
	if(sdram_state == 6) chipWE2 <= 0;
	if(sdram_state == 8) snoop2  <= 0;

	if(sdram_state[0]) sdata_reg <= sd_data;

	init_n = reset & (init_done | ((sdram_state == 15) & &initstate));
	if(~resync_x && sdram_state == 15) begin
		p_cs               <= 0;
		p_addr[12:11]      <= 2'b00;
		if(!init_n) begin
			p_addr[12:11]   <= 2'b11;
			case(initstate)
				3,4 : begin // PRECHARGE
					p_cs        <= ~initstate[0];
					p_addr[10]  <= 1; // all banks
					p_ras       <= 0;
					p_we        <= 0;
				end
				7,8,9,10 : begin // AUTOREFRESH
					p_cs        <= ~initstate[0];
					p_ras       <= 0;
					p_cas       <= 0;
				end
				12 : begin // LOAD MODE REGISTER
					p_ras       <= 0;
					p_cas       <= 0;
					p_we        <= 0;
					p_addr      <= 13'b0001000100010; // CL=2, BURST=4
				end
				13 : begin // LOAD MODE REGISTER
					p_cs        <= 1;
					p_ras       <= 0;
					p_cas       <= 0;
					p_we        <= 0;
					p_addr      <= 13'b0001000100001; // CL=2, BURST=2
				end
			endcase
		end
	end

	ref_pend_n = 4'd0;
	if(!init_done) begin
		slot_type             <= IDLE;
		casaddr               <= 0;
		ref_div               <= 0;
		ref_pend              <= 0;
		ref_now               <= 0;
		ref1_pend             <= 0;
		ref1_now              <= 0;
		b_go                  <= 0;
		b_rd                  <= 0;
		b_dp                  <= 0;
		b_dp4                 <= 0;
		b_dp_odd              <= 0;
		b_dp_tail             <= 0;
		b_cont                <= 0;
		b_w2                  <= 0;
		b_wcont               <= 0;
		p_ba                  <= 0;
		a_wr2                 <= 0;
		a_rd2                 <= 0;
	end else begin
		ref_pend_n = ref_pend;

		// RAS
		if(sdram_st0) begin
			cas_sd_cas      <= 1;
			cas_sd_we       <= 1;
			cas_dqm         <= 0;
			slot_type       <= IDLE;
			fwd_en          <= 0;
			a_wr2           <= 0;
			a_rd2           <= 0;

			ref_go  = ~chip_req & (|ref_pend[3:2] | (~write_req & ~cache_req & |ref_pend));
			a_act   = chip_req | (~ref_go & (write_req | cache_req));
			ref1_go = |ref1_pend & ~ref_go & ~(b_rd & ~b_rd_half & b_rd_cs) & ~(chip_req & chip32 & ~chipRW);
			ref_now   <= ref_go;
			ref1_now  <= ref1_go;
			ref_div   <= (ref_div == 47) ? 6'd0 : ref_div + 1'd1;
			ref_pend_n = ref_pend  + {3'd0, (ref_div == 47) & ~&ref_pend}  - {3'd0, ref_go};
			ref_pend  <= ref_pend_n;
			ref1_pend <= ref1_pend + {3'd0, (ref_div == 47) & ~&ref1_pend} - {3'd0, ref1_go};

			b_dp      <= b_rd;
			b_dp4     <= b_rd & ~b_rd_half & ~a_act & ~b_rd_cs;
			b_dp_odd  <= b_rd & ~b_rd_half & b_rd_cs & b_rd_odd;
			b_dp_tail <= b_rd &  b_rd_half & b_rd_cs & b_rd_odd;
			b_cont    <= b_rd & ~b_rd_half & (a_act | b_rd_cs);
			b_rd      <= 0;

			// we give the chipset first priority
			// (this includes anything on the "motherboard" - chip RAM, slow RAM and Kickstart, turbo modes notwithstanding)
			if(chip_req) begin
				slot_type    <= CHIP;
				casaddr      <= {1'b0, chipAddr[9:1]};
				cas_dqm      <= {chipU,chipL};
				cas_sd_cas   <= 0;
				cas_sd_we    <= chipRW;
				datawr       <= chipWR;
				chipWE       <= !chipRW;
				a_wr2        <= chip32 & !chipRW;
				a_rd2        <= chip32 &  chipRW;
				datawr2      <= chipWR2;
				if(chipRW & write_req & (writeAddr[24:3] == chipAddr[24:3])) begin
					fwd_en  <= 1'b1;
					fwd_pos <= writeAddr[2:1] - chipAddr[2:1];
					fwd_dat <= writeDat;
					fwd_dqm <= write_dqm;
				end
			end
			else if(ref_go) begin
				// REFRESH
				slot_type    <= REFRESH;
			end
			else if(write_req) begin
				slot_type    <= CPU_WRITECACHE;
				casaddr      <= {1'b0, writeAddr[9:1]};
				cas_dqm      <= write_dqm;
				cas_sd_we    <= 0;
				cas_sd_cas   <= 0;
				write_ack    <= 1; // let the write buffer know we're about to write
				datawr       <= writeDat;
			end
			// request from read cache
			else if(cache_req) begin
				slot_type    <= CPU_READCACHE;
				casaddr      <= {1'b0, cpuAddr[9:1]};
				cas_sd_cas   <= 0;
			end
		end

		if(sdram_st2) write_ack <= 0; // indicate to write that it's safe to accept the next write

		if(~resync_x) case(sdram_state)
			// CAS
			1: if(cas_sd_we) begin
					p_addr       <= {2'b00, 1'b1, casaddr}; // AUTO PRECHARGE
					p_cas        <= cas_sd_cas;
				end
				else p_addr[12:11] <= 2'b11;

			5: if(!cas_sd_we) begin
					p_addr       <= {cas_dqm, ~a_wr2, casaddr}; // AUTO PRECHARGE
					p_cas        <= 0;
					p_we         <= 0;
					p_dout       <= datawr;
					p_oe         <= 1;
				end

			7: if(ref_now | ref1_now) begin
					p_cs         <= ref1_now;
					p_ras        <= 0;
					p_cas        <= 0;
				end
				else if(a_wr2) begin
					p_cs         <= 0;
					p_addr       <= {2'b00, 1'b1, casaddr[9:1], 1'b1}; // AUTO PRECHARGE
					p_cas        <= 0;
					p_we         <= 0;
					p_dout       <= datawr2;
					p_oe         <= 1;
				end

			9: begin
					b_go  <= 0;
					p_cs  <= 0;
					if(b_cont) begin
						b_go         <= 1;
						b_wr         <= 0;
						b_half       <= 1;
						b_col[1:0]   <= b_col[1:0] + 2'd2;
						p_cs         <= b_cs;
						p_ba         <= b_ba;
						p_addr       <= b_row;
						p_ras        <= 0;
					end
					else if(b_wcont) begin
						if(~(b_cs ? ref1_now : ref_now)) begin
							b_go         <= 1;
							b_wr         <= 1;
							b_half       <= 0;
							b_w2         <= 0;
							b_wcont      <= 0;
							b_col[0]     <= 1'b1;
							b_dqm        <= b_dqm2;
							b_dat        <= b_dat2;
							p_cs         <= b_cs;
							p_ba         <= b_ba;
							p_addr       <= b_row;
							p_ras        <= 0;
						end
					end
					else if(fast_req & ~(fast_cs ? ref1_now : ref_now)) begin
						b_go         <= 1;
						b_wr         <= fast_we;
						b_w2         <= fast_we & fast_w2;
						b_dqm2       <= fast_dqm2;
						b_dat2       <= fast_wdat2;
						b_half       <= 0;
						b_cs         <= fast_cs;
						b_ba         <= fast_ba;
						b_row        <= fast_row;
						b_col        <= fast_col;
						b_dqm        <= fast_dqm;
						b_dat        <= fast_wdat;
						p_cs         <= fast_cs;
						p_ba         <= fast_ba;
						p_addr       <= fast_row;
						p_ras        <= 0;
						fast_ack     <= 1;
					end
				end

			11: if(b_go & ~b_wr) begin
					p_cs         <= b_cs;
					p_ba         <= b_ba;
					p_addr       <= {2'b00, 1'b1, b_col[9:1], b_col[0] & ~b_cs}; // AUTO PRECHARGE
					p_cas        <= 0;
				end
				else if(b_go & b_wr & b_w2 & ~(~cas_sd_cas & cas_sd_we)) begin
					p_cs         <= b_cs;
					p_ba         <= b_ba;
					p_addr       <= {b_dqm, 1'b0, b_col};
					p_cas        <= 0;
					p_we         <= 0;
					p_dout       <= b_dat;
					p_oe         <= 1;
				end

			13: if(b_go & b_wr) begin
					p_cs         <= b_cs;
					p_ba         <= b_ba;
					p_addr       <= {b_dqm, 1'b1, b_col}; // AUTO PRECHARGE
					p_cas        <= 0;
					p_we         <= 0;
					p_dout       <= b_dat;
					p_oe         <= 1;
					if(b_w2) begin
						if(~(~cas_sd_cas & cas_sd_we)) begin
							p_addr       <= {b_dqm2, 1'b1, b_col[9:1], 1'b1}; // AUTO PRECHARGE
							p_dout       <= b_dat2;
						end
						else b_wcont <= 1;
					end
				end
		endcase

		if(sdram_state == 12 && b_go && !b_wr) begin
			b_rd         <= 1;
			b_rd_half    <= b_half;
			b_rd_cs      <= b_cs;
			b_rd_odd     <= b_col[0];
		end

		case(sdram_state)
			1: b_rvalid <= b_dp & ~b_dp_odd;
			2: if(b_dp_odd) b_buf <= sdata_reg;
			3: b_rvalid <= b_dp;
			5: begin
					b_rvalid     <= b_dp4 | b_dp_tail;
					b_tail       <= b_dp_tail;
				end
			7: b_rvalid <= b_dp4;
		endcase
	end

	fast_rvalid <= b_rvalid;
	fast_rdat_r <= b_tail ? b_buf : sdata_reg;

	st0_go  <= ((sdram_state == 15) | resync) & init_n;
	st0_cpu <= ((sdram_state == 15) | resync) & init_n & ~|ref_pend_n[3:2];
end

always @(posedge sysclk) if(reset === 1'b1) begin
	if(st0_go !== (sdram_st0 & init_done) || st0_cpu !== (sdram_st0 & init_done & ~|ctrl.ref_pend[3:2])) begin
		$display("SDRAM_CTRL %0t: st0_go %b st0_cpu %b, sdram_st0 %b init_done %b ref_pend %h",
			$realtime, st0_go, st0_cpu, sdram_st0, init_done, ctrl.ref_pend);
		$finish;
	end
end

endmodule
