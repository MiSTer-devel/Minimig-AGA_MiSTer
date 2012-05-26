//////////////////////////////////////////////////////////////////////
////                                                              ////
////  OR1200's instruction fetch                                  ////
////                                                              ////
////  This file is part of the OpenRISC 1200 project              ////
////  http://www.opencores.org/cores/or1k/                        ////
////                                                              ////
////  Description                                                 ////
////  PC, instruction fetch, interface to IC.                     ////
////                                                              ////
////  To Do:                                                      ////
////   - make it smaller and faster                               ////
////                                                              ////
////  Author(s):                                                  ////
////      - Damjan Lampret, lampret@opencores.org                 ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000 Authors and OPENCORES.ORG                 ////
////                                                              ////
//// This source file may be used and distributed without         ////
//// restriction provided that this copyright statement is not    ////
//// removed from the file and that any derivative work contains  ////
//// the original copyright notice and the associated disclaimer. ////
////                                                              ////
//// This source file is free software; you can redistribute it   ////
//// and/or modify it under the terms of the GNU Lesser General   ////
//// Public License as published by the Free Software Foundation; ////
//// either version 2.1 of the License, or (at your option) any   ////
//// later version.                                               ////
////                                                              ////
//// This source is distributed in the hope that it will be       ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied   ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ////
//// PURPOSE.  See the GNU Lesser General Public License for more ////
//// details.                                                     ////
////                                                              ////
//// You should have received a copy of the GNU Lesser General    ////
//// Public License along with this source; if not, download it   ////
//// from http://www.opencores.org/lgpl.shtml                     ////
////                                                              ////
//////////////////////////////////////////////////////////////////////

// synopsys translate_off
`include "timescale.v"
// synopsys translate_on
`include "or1200_defines.v"

module or1200_if(
	// Clock and reset
	clk, rst,

	// External i/f to IC
	icpu_dat_i, icpu_ack_i, icpu_err_i, icpu_adr_i, icpu_tag_i,

	// Internal i/f
	if_freeze, if_insn, if_pc, flushpipe,
	if_stall, no_more_dslot, genpc_refetch, rfe,
	except_itlbmiss, except_immufault, except_ibuserr
);

//
// I/O
//

//
// Clock and reset
//
input				clk;
input				rst;

//
// External i/f to IC
//
input	[31:0]			icpu_dat_i;
input				icpu_ack_i;
input				icpu_err_i;
input	[31:0]			icpu_adr_i;
input	[3:0]			icpu_tag_i;

//
// Internal i/f
//
input				if_freeze;
output	[31:0]			if_insn;
output	[31:0]			if_pc;
input				flushpipe;
output				if_stall;
input				no_more_dslot;
output				genpc_refetch;
input				rfe;
output				except_itlbmiss;
output				except_immufault;
output				except_ibuserr;

//
// Internal wires and regs
//
reg	[31:0]			insn_saved;
reg	[31:0]			addr_saved;
reg				saved;

//
// IF stage insn
//
assign if_insn = icpu_err_i | no_more_dslot | rfe ? {`OR1200_OR32_NOP, 26'h041_0000} : saved ? insn_saved : icpu_ack_i ? icpu_dat_i : {`OR1200_OR32_NOP, 26'h061_0000};
assign if_pc = saved ? addr_saved : icpu_adr_i;
// assign if_stall = !icpu_err_i & !icpu_ack_i & !saved & !no_more_dslot;
assign if_stall = !icpu_err_i & !icpu_ack_i & !saved;
assign genpc_refetch = saved & icpu_ack_i;
assign except_itlbmiss = icpu_err_i & (icpu_tag_i == `OR1200_ITAG_TE) & !no_more_dslot;
assign except_immufault = icpu_err_i & (icpu_tag_i == `OR1200_ITAG_PE) & !no_more_dslot;
assign except_ibuserr = icpu_err_i & (icpu_tag_i == `OR1200_ITAG_BE) & !no_more_dslot;

//
// Flag for saved insn/address
//
always @(posedge clk or posedge rst)
	if (rst)
		saved <= #1 1'b0;
	else if (flushpipe)
		saved <= #1 1'b0;
	else if (icpu_ack_i & if_freeze & !saved)
		saved <= #1 1'b1;
	else if (!if_freeze)
		saved <= #1 1'b0;

//
// Store fetched instruction
//
always @(posedge clk or posedge rst)
	if (rst)
		insn_saved <= #1 {`OR1200_OR32_NOP, 26'h041_0000};
	else if (flushpipe)
		insn_saved <= #1 {`OR1200_OR32_NOP, 26'h041_0000};
	else if (icpu_ack_i & if_freeze & !saved)
		insn_saved <= #1 icpu_dat_i;
	else if (!if_freeze)
		insn_saved <= #1 {`OR1200_OR32_NOP, 26'h041_0000};

//
// Store fetched instruction's address
//
always @(posedge clk or posedge rst)
	if (rst)
		addr_saved <= #1 32'h00000000;
	else if (flushpipe)
		addr_saved <= #1 32'h00000000;
	else if (icpu_ack_i & if_freeze & !saved)
		addr_saved <= #1 icpu_adr_i;
	else if (!if_freeze)
		addr_saved <= #1 icpu_adr_i;

endmodule
