// Copyright 2021 Alexey Melnikov
//
// This file is part of Minimig
//
// Minimig is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 3 of the License, or
// (at your option) any later version.
//
// Minimig is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http:// www.gnu.org/licenses/>.
//
//----------------------------------------------------------------------------------  

module fastchip
(
	input         clk,
	input         cyc,
	input         clk_sys,

	input         reset,

	input         sel,
	output        sel_ack, // 1 when fast chip is used instead of legacy chip
	output        ready,

	input  [23:0] addr,
	input  [15:0] din,
	output [15:0] dout,
	input         lds,
	input         uds,
	input         rnw
);

assign sel_ack = sel_akiko;
assign ready   = sel_akiko;
assign dout    = akiko_dout;

wire        sel_akiko = sel && (addr[23:8] == 'hB800);
wire [15:0] akiko_dout;

akiko akiko
(
	.clk(clk_sys),
	.cs(sel_akiko && !addr[7:6]),
	.rd(rnw),
	.wr(~rnw & (lds|uds)),
	.addr(addr[5:1]),
	.din(din),
	.dout(akiko_dout)
);

endmodule
