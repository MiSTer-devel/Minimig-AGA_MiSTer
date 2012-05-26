//////////////////////////////////////////////////////////////////////
////                                                              ////
////  OR1200's Freeze logic                                       ////
////                                                              ////
////  This file is part of the OpenRISC 1200 project              ////
////  http://www.opencores.org/cores/or1k/                        ////
////                                                              ////
////  Description                                                 ////
////  Generates all freezes and stalls inside RISC                ////
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

`define OR1200_NO_FREEZE	3'd0
`define OR1200_FREEZE_BYDC	3'd1
`define OR1200_FREEZE_BYMULTICYCLE	3'd2
`define OR1200_WAIT_LSU_TO_FINISH	3'd3
`define OR1200_WAIT_IC			3'd4

//
// Freeze logic (stalls CPU pipeline, ifetcher etc.)
//
module or1200_freeze(
	// Clock and reset
	clk, rst,

	// Internal i/f
	multicycle, flushpipe, extend_flush, lsu_stall, if_stall,
	lsu_unstall, du_stall, mac_stall, 
	force_dslot_fetch, abort_ex,
	genpc_freeze, if_freeze, id_freeze, ex_freeze, wb_freeze,
	icpu_ack_i, icpu_err_i
);

//
// I/O
//
input				clk;
input				rst;
input	[`OR1200_MULTICYCLE_WIDTH-1:0]	multicycle;
input				flushpipe;
input				extend_flush;
input				lsu_stall;
input				if_stall;
input				lsu_unstall;
input				force_dslot_fetch;
input				abort_ex;
input				du_stall;
input				mac_stall;
output				genpc_freeze;
output				if_freeze;
output				id_freeze;
output				ex_freeze;
output				wb_freeze;
input				icpu_ack_i;
input				icpu_err_i;

//
// Internal wires and regs
//
wire				multicycle_freeze;
reg	[`OR1200_MULTICYCLE_WIDTH-1:0]	multicycle_cnt;
reg				flushpipe_r;

//
// Pipeline freeze
//
// Rules how to create freeze signals:
// 1. Not overwriting pipeline stages:
// Freze signals at the beginning of pipeline (such as if_freeze) can be asserted more
// often than freeze signals at the of pipeline (such as wb_freeze). In other words, wb_freeze must never
// be asserted when ex_freeze is not. ex_freeze must never be asserted when id_freeze is not etc.
//
// 2. Inserting NOPs in the middle of pipeline only if supported:
// At this time, only ex_freeze (and wb_freeze) can be deassrted when id_freeze (and if_freeze) are asserted.
// This way NOP is asserted from stage ID into EX stage.
//
//assign genpc_freeze = du_stall | flushpipe_r | lsu_stall;
assign genpc_freeze = du_stall | flushpipe_r;
assign if_freeze = id_freeze | extend_flush;
//assign id_freeze = (lsu_stall | (~lsu_unstall & if_stall) | multicycle_freeze | force_dslot_fetch) & ~flushpipe | du_stall;
assign id_freeze = (lsu_stall | (~lsu_unstall & if_stall) | multicycle_freeze | force_dslot_fetch) | du_stall | mac_stall;
assign ex_freeze = wb_freeze;
//assign wb_freeze = (lsu_stall | (~lsu_unstall & if_stall) | multicycle_freeze) & ~flushpipe | du_stall | mac_stall;
assign wb_freeze = (lsu_stall | (~lsu_unstall & if_stall) | multicycle_freeze) | du_stall | mac_stall | abort_ex;

//
// registered flushpipe
//
always @(posedge clk or posedge rst)
	if (rst)
		flushpipe_r <= #1 1'b0;
	else if (icpu_ack_i | icpu_err_i)
//	else if (!if_stall)
		flushpipe_r <= #1 flushpipe;
	else if (!flushpipe)
		flushpipe_r <= #1 1'b0;
		
//
// Multicycle freeze
//
assign multicycle_freeze = |multicycle_cnt;

//
// Multicycle counter
//
always @(posedge clk or posedge rst)
	if (rst)
		multicycle_cnt <= #1 2'b00;
	else if (|multicycle_cnt)
		multicycle_cnt <= #1 multicycle_cnt - 2'd1;
	else if (|multicycle & !ex_freeze)
		multicycle_cnt <= #1 multicycle;

endmodule
