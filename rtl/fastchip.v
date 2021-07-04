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
	input         rnw,
	input         longword,

	input         ide_ena,
	output        ide_irq,
	output  [5:0] ide_req,
	input   [4:0] ide_address,
	input         ide_write,
	input  [15:0] ide_writedata,
	input         ide_read,
	output [15:0] ide_readdata,

	output        ide_led
);

assign sel_ack = sel_akiko  | sel_ide | sel_gayle;
assign ready   = sel_akiko  | ide_ready;
assign dout    = akiko_dout | ide_dout;

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

wire sel_ide   = ide_ena && sel && addr[23:16] ==  8'b1101_1010;       //IDE registers at $DA0000 - $DAFFFF	
wire sel_gayle = ide_ena && sel && addr[23:12] == 12'b1101_1110_0001;  //GAYLE registers at $DE1000 - $DE1FFF

reg ide_ack;
always @(posedge clk_sys) ide_ack <= (sel_ide | sel_gayle);

wire ide_ready = ide_ack & (sel_ide | sel_gayle) & ~(ide_nrdy & rnw);

wire [15:0] ide_dout;
wire        ide_nrdy;

gayle gayle
(
	.clk(clk_sys),
	.reset(reset),

	.addr(addr[23:1]),
	.data_in(din),
	.data_out(ide_dout),
	.rd(rnw & uds),
	.wr(~rnw & uds),
	.sel_ide(sel_ide),
	.sel_gayle(sel_gayle),
	.irq(ide_irq),
	.nrdy(ide_nrdy),
	.longword(longword),

	.ide_req(ide_req),
	.ide_address(ide_address),
	.ide_write(ide_write),
	.ide_writedata(ide_writedata),
	.ide_read(ide_read),
	.ide_readdata(ide_readdata),
	
	.led(ide_led)
);

endmodule
