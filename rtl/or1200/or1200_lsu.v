//////////////////////////////////////////////////////////////////////
////                                                              ////
////  OR1200's Load/Store unit                                    ////
////                                                              ////
////  This file is part of the OpenRISC 1200 project              ////
////  http://www.opencores.org/cores/or1k/                        ////
////                                                              ////
////  Description                                                 ////
////  Interface between CPU and DC.                               ////
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

module or1200_lsu(

	// Internal i/f
	addrbase, addrofs, lsu_op, lsu_datain, lsu_dataout, lsu_stall, lsu_unstall,
        du_stall, except_align, except_dtlbmiss, except_dmmufault, except_dbuserr,

	// External i/f to DC
	dcpu_adr_o, dcpu_cycstb_o, dcpu_we_o, dcpu_sel_o, dcpu_tag_o, dcpu_dat_o,
	dcpu_dat_i, dcpu_ack_i, dcpu_rty_i, dcpu_err_i, dcpu_tag_i
);

parameter dw = `OR1200_OPERAND_WIDTH;
parameter aw = `OR1200_REGFILE_ADDR_WIDTH;

//
// I/O
//

//
// Internal i/f
//
input	[31:0]			addrbase;
input	[31:0]			addrofs;
input	[`OR1200_LSUOP_WIDTH-1:0]	lsu_op;
input	[dw-1:0]		lsu_datain;
output	[dw-1:0]		lsu_dataout;
output				lsu_stall;
output				lsu_unstall;
input                           du_stall;
output				except_align;
output				except_dtlbmiss;
output				except_dmmufault;
output				except_dbuserr;

//
// External i/f to DC
//
output	[31:0]			dcpu_adr_o;
output				dcpu_cycstb_o;
output				dcpu_we_o;
output	[3:0]			dcpu_sel_o;
output	[3:0]			dcpu_tag_o;
output	[31:0]			dcpu_dat_o;
input	[31:0]			dcpu_dat_i;
input				dcpu_ack_i;
input				dcpu_rty_i;
input				dcpu_err_i;
input	[3:0]			dcpu_tag_i;

//
// Internal wires/regs
//
reg	[3:0]			dcpu_sel_o;

//
// Internal I/F assignments
//
assign lsu_stall = dcpu_rty_i & dcpu_cycstb_o;
assign lsu_unstall = dcpu_ack_i;
assign except_align = ((lsu_op == `OR1200_LSUOP_SH) | (lsu_op == `OR1200_LSUOP_LHZ) | (lsu_op == `OR1200_LSUOP_LHS)) & dcpu_adr_o[0]
		|  ((lsu_op == `OR1200_LSUOP_SW) | (lsu_op == `OR1200_LSUOP_LWZ) | (lsu_op == `OR1200_LSUOP_LWS)) & |dcpu_adr_o[1:0];
assign except_dtlbmiss = dcpu_err_i & (dcpu_tag_i == `OR1200_DTAG_TE);
assign except_dmmufault = dcpu_err_i & (dcpu_tag_i == `OR1200_DTAG_PE);
assign except_dbuserr = dcpu_err_i & (dcpu_tag_i == `OR1200_DTAG_BE);

//
// External I/F assignments
//
assign dcpu_adr_o = addrbase + addrofs;
assign dcpu_cycstb_o = du_stall | lsu_unstall | except_align ? 1'b0 : |lsu_op;
assign dcpu_we_o = lsu_op[3];
assign dcpu_tag_o = dcpu_cycstb_o ? `OR1200_DTAG_ND : `OR1200_DTAG_IDLE;
always @(lsu_op or dcpu_adr_o)
	casex({lsu_op, dcpu_adr_o[1:0]})
		{`OR1200_LSUOP_SB, 2'b00} : dcpu_sel_o = 4'b1000;
		{`OR1200_LSUOP_SB, 2'b01} : dcpu_sel_o = 4'b0100;
		{`OR1200_LSUOP_SB, 2'b10} : dcpu_sel_o = 4'b0010;
		{`OR1200_LSUOP_SB, 2'b11} : dcpu_sel_o = 4'b0001;
		{`OR1200_LSUOP_SH, 2'b00} : dcpu_sel_o = 4'b1100;
		{`OR1200_LSUOP_SH, 2'b10} : dcpu_sel_o = 4'b0011;
		{`OR1200_LSUOP_SW, 2'b00} : dcpu_sel_o = 4'b1111;
		{`OR1200_LSUOP_LBZ, 2'b00}, {`OR1200_LSUOP_LBS, 2'b00} : dcpu_sel_o = 4'b1000;
		{`OR1200_LSUOP_LBZ, 2'b01}, {`OR1200_LSUOP_LBS, 2'b01} : dcpu_sel_o = 4'b0100;
		{`OR1200_LSUOP_LBZ, 2'b10}, {`OR1200_LSUOP_LBS, 2'b10} : dcpu_sel_o = 4'b0010;
		{`OR1200_LSUOP_LBZ, 2'b11}, {`OR1200_LSUOP_LBS, 2'b11} : dcpu_sel_o = 4'b0001;
		{`OR1200_LSUOP_LHZ, 2'b00}, {`OR1200_LSUOP_LHS, 2'b00} : dcpu_sel_o = 4'b1100;
		{`OR1200_LSUOP_LHZ, 2'b10}, {`OR1200_LSUOP_LHS, 2'b10} : dcpu_sel_o = 4'b0011;
		{`OR1200_LSUOP_LWZ, 2'b00}, {`OR1200_LSUOP_LWS, 2'b00} : dcpu_sel_o = 4'b1111;
		default : dcpu_sel_o = 4'b0000;
	endcase

//
// Instantiation of Memory-to-regfile aligner
//
or1200_mem2reg or1200_mem2reg(
	.addr(dcpu_adr_o[1:0]),
	.lsu_op(lsu_op),
	.memdata(dcpu_dat_i),
	.regdata(lsu_dataout)
);

//
// Instantiation of Regfile-to-memory aligner
//
or1200_reg2mem or1200_reg2mem(
        .addr(dcpu_adr_o[1:0]),
        .lsu_op(lsu_op),
        .regdata(lsu_datain),
        .memdata(dcpu_dat_o)
);

endmodule
