////////////////////////////////////////////////////////////////////////////////
//                                                                            //
// Copyright 2013, 2014 Rok Krajnc                                            //
//                                                                            //
// This file is part of Minimig                                               //
//                                                                            //
// Minimig is free software; you can redistribute it and/or modify            //
// it under the terms of the GNU General Public License as published by       //
// the Free Software Foundation; either version 3 of the License, or          //
// (at your option) any later version.                                        //
//                                                                            //
// Minimig is distributed in the hope that it will be useful,                 //
// but WITHOUT ANY WARRANTY; without even the implied warranty of             //
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              //
// GNU General Public License for more details.                               //
//                                                                            //
// You should have received a copy of the GNU General Public License          //
// along with this program.  If not, see <http://www.gnu.org/licenses/>.      //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
// This is Cart module with support for HRTmon monitor.                       //
// This module is based on existing ActionReplay.v module by Jakub Bednarski  //
// and code from WinUAE ar.cpp file. The module requires the ctrl firmware    //
// to load the special hrtmon.rom file to address 0xa10000. The module        //
// requires one 512KB RAM bank. The start address (entry point) is 0xa1000c.  //
// TODO : custom registers and CIA registers shadow implemented as in WinUAE. //
//                                                                            //
//                                                                            //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
// Changelog                                                                  //
// RK:                                                                        //
// 2013-11-27  - initial version                                              //
// 2014-09-27  - cleanup, clock enable added                                  //
// 2015-05-03  - added custom registers mirror                                //
// AP:                                                                        //
// 2026-10-27  - the Action Replay (AR5, DeMoN v2 layout) as an alternative   //
//               to HRTmon, ported from the Maximig core                      //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

module cart
(
	input         clk,
	input         clk7_en,
	input         clk7n_en,
	input         cpu_rst,
	input  [23:1] cpu_address_in,
	input         _cpu_as,
	input         cpu_rd,
	input         cpu_hwr,
	input         cpu_lwr,
	input  [15:0] cpu_data,          // the CPU's write data
	input  [31:0] nmi_addr,
	input   [8:1] reg_address_in,
	input  [15:0] reg_data_in,
	input         dbr,
	input         ovl,
	input         freeze, 
	input         cpuhlt,
	input         ar_en,             // the cartridge is the Action Replay, not HRTmon
	input         ar_fetch,          // the CPU took an instruction fetch outside $A80000-$AFFFFF (cpu_wrapper)
	output [15:0] cart_data_out,
	output [15:0] cart_data_mask,    // ANDed onto the memory's read data
	output reg    int7 = 1'b0,
	output        sel_cart,
	output        ovr,
	output        ar_vsel,           // the NMI vector fetch reads the Action Replay ROM's vector ...
	output [23:1] ar_vadr            // ... at this address
);

// The Action Replay (AR5's DeMoN v2 build, ar_en): ROM at $A80000-$ABFFFF,
// RAM at $AC0000-$AFFFFF, uploaded by the HPS with the CPU halted (to the
// same addresses in the SDRAM).  As WinUAE's AR2/AR3 and AR5 expect, it is
// hidden until it freezes the machine:
// * the freeze key; with mode bit 1 a read of CIA-A PRA ($BFE001), with
//   mode bit 0 a write of CIA-B PRB ($BFD100) -- only while hidden;
// * after a reset, the CPU's first word written to chip RAM (cause 3).
// A freeze shows the cartridge and raises level 7; the NMI vector fetch
// reads the ROM's own vector ($A8007C).  The ROM's first long word is the
// control register: a write of the byte at +1 sets the mode and clears the
// cause, and the cartridge hides at the first instruction fetched from
// outside it; a read of the byte at +1 or +3 has the cause in D1-D0 (0 the
// key, 1 PRA read, 2 PRB write, 3 reset).  The custom registers as they were
// at the freeze are at $ACF000-$ACF1FF (a snapshot, read and written as
// RAM).  Other ROM writes are ignored.

wire ar_area = ~dbr && (cpu_address_in[23:19]==5'b1010_1);                    // $A80000-$AFFFFF
wire ar_snap = ar_area && ar_vis && (cpu_address_in[18:9]==10'b10_0111_1000);  // $ACF000-$ACF1FF
wire ar_ctl  = ar_area && (cpu_address_in[18:2]==17'd0);                      // the control register's long word

//  cart selected, is in stealth mode until first freeze, has to be available during halt to allow userio 
assign sel_cart = ar_en ? ((ar_area && (cpuhlt || (ar_vis && ~ar_snap && (cpu_rd || cpu_address_in[18])))) || ar_vsel) :
                          (~dbr && (cpu_address_in[23:19]==5'b1010_0) && (stealth | cpuhlt)); // $A00000
   

// latch VBR + NMI vector offset
reg [31:0] nmi_vec_adr=0;
reg [23:1] nmi_vec_adr2=0;
always @ (posedge clk) if (clk7_en) nmi_vec_adr <= nmi_addr; // $7C = NMI vector offset
always @ (posedge clk) if (clk7_en) nmi_vec_adr2 <= nmi_addr[23:1] + 1'd1;
wire nmi_vec_hi = (cpu_address_in[23:1] == nmi_vec_adr[23:1]);

// override decoding of NMI
assign ovr = active && ~dbr && ~ovl && cpu_rd && (nmi_vec_hi || (cpu_address_in[23:1] == nmi_vec_adr2));

// custom NMI vector address output $a1000c (HRTmon); the Action Replay's
// vector is read from its ROM
wire [15:0] nmi_adr_out = (ovr && ~ar_en) ? (nmi_vec_hi ? 16'h00a1 : 16'h000c) : 16'h0000;
assign ar_vsel = ar_en && ovr;
assign ar_vadr = nmi_vec_hi ? 23'h54003E : 23'h54003F;   // $A8007C, $A8007E

// freeze button
reg freeze_d=0;
always @ (posedge clk) if (clk7_en) freeze_d <= freeze;

wire freeze_req = freeze && ~freeze_d;

// the Action Replay's freezes: each bus cycle counts once, at the start of
// its strobe (the bridge's strobes drop between two cycles, AS need not: the
// 68020's cycles can follow each other with AS held)
reg ar_vis = 1'b0;      // shown: from the freeze until it hides
reg ar_hide = 1'b0;     // the control register written: hide at the next fetch from outside
reg ar_rst = 1'b0;      // after a reset: freeze at the first word written to chip RAM
reg [1:0] ar_mode = 2'b00;
reg [1:0] ar_cause = 2'b00;
reg ar_str_d = 1'b0;    // a strobe at the 7 MHz enable before
wire ar_str   = cpu_rd | cpu_hwr | cpu_lwr;
wire ar_ev    = clk7_en && ar_str && ~ar_str_d && ~dbr && ~cpuhlt;
wire ar_chw   = ar_ev && cpu_hwr && cpu_lwr && (cpu_address_in[23:21]==3'b000) &&
                ~(ovl && cpu_address_in[23:19]==5'b0000_0);                                   // a word to chip RAM (not the ROM under OVL)
wire ar_pra   = ar_ev && cpu_rd && (cpu_address_in[23:12]==12'hBFE) && (cpu_address_in[11:8]==4'h0); // $BFE001
wire ar_prb   = ar_ev && cpu_hwr && (cpu_address_in[23:12]==12'hBFD) && (cpu_address_in[11:8]==4'h1);// $BFD100
wire ar_set   = ar_ev && ar_vis && ar_ctl && ~cpu_address_in[1] && cpu_lwr;                     // the byte at +1
wire ar_frz   = ar_en && ((ar_rst && ar_chw) ||
                          (~ar_vis && ~ar_rst && ((ar_pra && ar_mode[1]) || (ar_prb && ar_mode[0]) || (clk7_en && freeze_req))));

always @ (posedge clk) begin
	if (clk7_en) ar_str_d <= ar_str;
	if (cpu_rst) begin
		ar_vis  <= 1'b0;
		ar_hide <= 1'b0;
		ar_rst  <= 1'b1;
		ar_mode <= 2'b00;
	end
	else if (~ar_en) ar_rst <= 1'b0;
	else if (ar_frz) begin
		ar_rst   <= 1'b0;
		ar_vis   <= 1'b1;
		ar_cause <= (ar_rst && ar_chw) ? 2'd3 : (ar_pra && ar_mode[1]) ? 2'd1 : (ar_prb && ar_mode[0]) ? 2'd2 : 2'd0;
	end
	else if (ar_set) begin
		ar_mode  <= cpu_data[1:0];
		ar_cause <= 2'd0;
		ar_hide  <= 1'b1;
	end
	else if (ar_hide && ar_fetch) begin
		ar_vis  <= 1'b0;
		ar_hide <= 1'b0;
	end
end

// int7 request
wire int7_req = ar_en ? ar_frz : (clk7_en && freeze_req);

// level7 interrupt ack cycle, on Amiga interrupt vector number is read from kickstart rom
wire int7_ack = &cpu_address_in && ~_cpu_as;

// level 7 interrupt request logic
// interrupt request lines are sampled during S4->S5 transition (falling cpu clock edge)
reg int7_pend = 1'b0;   // (the Action Replay's freeze between two 7 MHz enables)
always @ (posedge clk) begin
	if (cpu_rst) int7_pend <= 0;
	else if (int7_req) int7_pend <= 1;
	else if (clk7_en) int7_pend <= 0;
	if (clk7_en) begin
		     if (cpu_rst)  int7 <= 0;
		else if (int7_req | int7_pend) int7 <= 1;
		else if (int7_ack) int7 <= 0;
	end
end

// latches
reg l_int7_req=0;
reg l_int7_ack=0;
always @ (posedge clk) begin
	if (clk7_en) begin
		l_int7_req <= int7_req | int7_pend;
		l_int7_ack <= int7_ack;
	end
end

reg l_int7=0;
always @ (posedge clk) begin
	if (clk7_en) begin
		     if (cpu_rst)              l_int7 <= 0;
		else if (l_int7_req)           l_int7 <= 1;
		else if (l_int7_ack && cpu_rd) l_int7 <= 0;
	end
end

// overlay active
reg active=0;
reg stealth; //hide till first freeze request   
always @ (posedge clk) begin
	if (clk7_en) begin
		if (cpu_rst) begin
			active <= 0;
			stealth <= 0;
		end
		else if (l_int7 && l_int7_ack && cpu_rd) begin
			active <= 1;
			stealth <= 1;
		end
		else if (sel_cart && cpu_rd && ~ar_vsel) begin
			active <= 0;
		end
	end
end

// custom registers mirror memory
wire sel_custom_mirror = ~dbr && cpu_rd && (cpu_address_in[23:12]==12'b1010_1001_1111) && stealth && ~ar_en; // $A9F000

// the Action Replay's snapshot: at a freeze, the mirror copied to it (an
// entry a clock, its read a clock ahead of its write); then RAM
reg [15:0] custom_mirror_q;
reg [15:0] custom_mirror[256];
reg  [7:0] snap_h[256];
reg  [7:0] snap_l[256];
reg [15:0] snap_q;
reg        cpy_run = 1'b0, cpy_wr = 1'b0;
reg  [7:0] cpy_a = 8'd0, cpy_wa = 8'd0;
wire [7:0] snap_wa = cpy_wr ? cpy_wa : cpu_address_in[8:1];
wire       snap_wh = cpy_wr || (ar_snap && cpu_hwr);
wire       snap_wl = cpy_wr || (ar_snap && cpu_lwr);
wire[15:0] snap_wd = cpy_wr ? custom_mirror_q : cpu_data;
always @ (posedge clk) begin
	if (clk7_en) begin
		custom_mirror[reg_address_in] <= reg_data_in;
	end
	custom_mirror_q <= custom_mirror[cpy_run ? cpy_a : cpu_address_in[8:1]];
	if (ar_frz) begin
		cpy_run <= 1'b1;
		cpy_a   <= 8'd0;
	end
	else if (cpy_run) begin
		cpy_a <= cpy_a + 1'd1;
		if (cpy_a == 8'd255) cpy_run <= 1'b0;
	end
	cpy_wr <= cpy_run;
	cpy_wa <= cpy_a;
	if (snap_wh) snap_h[snap_wa] <= snap_wd[15:8];
	if (snap_wl) snap_l[snap_wa] <= snap_wd[7:0];
	snap_q <= {snap_h[cpu_address_in[8:1]], snap_l[cpu_address_in[8:1]]};
end

wire [15:0] custom_mirror_out = sel_custom_mirror ? custom_mirror_q : 16'h0000;
wire [15:0] snap_out = (ar_snap && cpu_rd) ? snap_q : 16'h0000;

// the control register read: the cause in D1-D0 of the bytes at +1 and +3
wire        ar_crd = ar_en && ar_vis && ar_ctl && cpu_rd;
assign cart_data_mask = ar_crd ? 16'hFFFC : 16'hFFFF;

// cart data output
assign cart_data_out = custom_mirror_out | nmi_adr_out | snap_out | (ar_crd ? {14'd0, ar_cause} : 16'h0000);


endmodule
