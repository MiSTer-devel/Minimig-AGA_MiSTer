// Copyright 2008, 2009 by Jakub Bednarski
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
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
//
//
// -- JB --
//
// 2008-10-06	- initial version
// 2008-10-08	- interrupt controller implemented, kickstart boots
// 2008-10-09	- working identify device command implemented (hdtoolbox detects our drive)
//				- read command reads data from hardfile (fixed size and name, only one sector read size supported, workbench sees hardfile partition)
// 2008-10-10	- multiple sector transfer supported: works ok, sequential transfers with direct spi read and 28MHz CPU from 400 to 520 KB/s
//				- arm firmare seekfile function very slow: seeking from start to 20MB takes 144 ms (some software improvements required)
// 2008-10-30	- write support added
// 2008-12-31	- added hdd enable
// 2009-05-24	- clean-up & renaming
// 2009-08-11	- hdd_ena enables Master & Slave drives
// 2009-11-18	- changed sector buffer size
// 2010-04-13	- changed sector buffer size
// 2010-08-10	- improved BSY signal handling

module gayle
(
	input	        clk,
	input         clk7_en,
	input	        reset,
	input	 [23:1] address_in,
	input	 [15:0] data_in,
	output [15:0] data_out,
	input         rd,
	input         hwr,
	input         lwr,
	input         sel_ide,			// $DAxxxx
	input         sel_gayle,		// $DExxxx
	output        irq,
	output        nrdy,				// fifo is not ready for reading 

	output  [5:0] ide_req,
	input   [4:0] ide_address,
	input         ide_write,
	input  [15:0] ide_writedata,
	input         ide_read,
	output [15:0] ide_readdata,
	
	output        led
);

//0xda2000 Data
//0xda2004 Error | Feature
//0xda2008 SectorCount
//0xda200c SectorNumber
//0xda2010 CylinderLow
//0xda2014 CylinderHigh
//0xda2018 Device/Head
//0xda201c Status | Command
//0xda3018 Control

/*
memory map:

$DA0000 - $DA0FFFF : CS1 16-bit speed
$DA1000 - $DA1FFFF : CS2 16-bit speed
$DA2000 - $DA2FFFF : CS1 8-bit speed
$DA3000 - $DA3FFFF : CS2 8-bit speed
$DA4000 - $DA7FFFF : reserved
$DA8000 - $DA8FFFF : IDE INTREQ state status register (not implemented as scsi.device doesn't use it)
$DA9000 - $DA9FFFF : IDE INTREQ change status register (writing zeros resets selected bits, writing ones doesn't change anything) 
$DAA000 - $DAAFFFF : IDE INTENA register (r/w, only MSB matters)
 

command class:
PI (PIO In)
PO (PIO Out)
ND (No Data)

Status:
#6 - DRDY	- Drive Ready
#7 - BSY	- Busy
#3 - DRQ	- Data Request
#0 - ERR	- Error
INTRQ	- Interrupt Request

*/
 
// address decoding
wire sel_gayleid= (sel_gayle && address_in[15:12]==4'b0001);  // GAYLEID, $DE1xxx
wire sel_tfr    = (sel_ide   && address_in[15:14]==2'b00);    // $DA0xxx, $DA1xxx, $DA2xxx, $DA3xxx
wire sel_cs     = (sel_ide   && address_in[15:12]==4'b1000);  // GAYLE_CS_1200,  $DA8xxx
wire sel_intreq = (sel_ide   && address_in[15:12]==4'b1001);  // GAYLE_IRQ_1200, $DA9xxx
wire sel_intena = (sel_ide   && address_in[15:12]==4'b1010);  // GAYLE_INT_1200, $DAAxxx
wire sel_cfg    = (sel_ide   && address_in[15:12]==4'b1011);  // GAYLE_CFG_1200, $DABxxx

wire port_num   = address_in[12];

//===============================================================================================//

reg old_reset = 0;
wire reset_stb = ~old_reset & reset;
always @(posedge clk) old_reset <= reset;

reg [1:0] cs;
reg [5:0] cs_mask;

// gayle cs
always @ (posedge clk) if (clk7_en) begin
	if (reset) begin
		cs_mask <= 0;
		cs      <= 0;
	end else if (hwr && sel_cs) begin
		cs_mask <= data_in[15:10];
		cs      <= data_in[9:8];
	end
end

// gayle cfg
reg [3:0] cfg;
always @ (posedge clk) if (clk7_en) begin
	if (reset) cfg <= 0;
	if (hwr && sel_cfg) cfg <= data_in[15:12];
end

// gayle id register: reads 1->1->0->1 on MSB
reg  [1:0] gayleid_cnt;	// sequence counter
wire       gayleid;		// output data (one bit wide)
always @(posedge clk) if (clk7_en) begin
	if (sel_gayleid) begin
		if (hwr) gayleid_cnt <= 2'd0; // a write resets sequence counter
		else if (rd) gayleid_cnt <= gayleid_cnt + 2'd1;
	end
end

// IDE interrupt enable register
reg intena;
always @(posedge clk) if (clk7_en) begin
	if (reset) intena <= 0;
	else if (sel_intena && hwr) intena <= data_in[15];
end

//===============================================================================================//

assign      ide_readdata = ide_address[4] ? ide1_readdata : ide0_readdata;
assign      led = ide0_drq | ide1_drq;

wire [15:0] ide0_data, ide0_readdata;
wire        ide0_intreq, ide0_drq, ide0_nodata;

reg wr;
always @(posedge clk) begin
	reg old_hwr;
	old_hwr <= hwr;
	wr <= ~old_hwr & hwr;
end

ide ide0
(
	.clk(clk),
	.rst_n(~reset_stb),
	.irq(ide0_intreq),

	.io_address(address_in[4:2]),
	.io_read(rd & sel_tfr & ~port_num),
	.io_write(wr & sel_tfr & ~port_num),
	.io_readdata({ide0_data[7:0], ide0_data[15:8]}),
	.io_writedata({data_in[7:0],data_in[15:8]}),
	.io_32(0),

	.request(ide_req[2:0]),
	.drq(ide0_drq),
	
	.use_fast(1),
	.no_data(ide0_nodata),

	.mgmt_address(ide_address[3:0]),
	.mgmt_write(ide_write & ~ide_address[4]),
	.mgmt_writedata(ide_writedata),
	.mgmt_read(ide_read & ~ide_address[4]),
	.mgmt_readdata(ide0_readdata)
);

wire [15:0] ide1_data, ide1_readdata;
wire        ide1_intreq, ide1_drq, ide1_nodata;

ide ide1
(
	.clk(clk),
	.rst_n(~reset_stb),
	.irq(ide1_intreq),

	.io_address(address_in[4:2]),
	.io_read(rd & sel_tfr & port_num),
	.io_write(wr & sel_tfr & port_num),
	.io_readdata({ide1_data[7:0], ide1_data[15:8]}),
	.io_writedata({data_in[7:0],data_in[15:8]}),
	.io_32(0),

	.request(ide_req[5:3]),
	.drq(ide1_drq),

	.use_fast(1),
	.no_data(ide1_nodata),

	.mgmt_address(ide_address[3:0]),
	.mgmt_write(ide_write & ide_address[4]),
	.mgmt_writedata(ide_writedata),
	.mgmt_read(ide_read & ide_address[4]),
	.mgmt_readdata(ide1_readdata)
);


wire   intreq  = ide0_intreq | ide1_intreq;
assign irq     = intreq & intena; // interrupt request line (INT2)
assign gayleid = ~gayleid_cnt[1] | gayleid_cnt[0]; // Gayle ID output data
assign nrdy    = sel_tfr & !address_in[4:2] & (port_num ? ide1_nodata : ide0_nodata);

//data_out multiplexer
assign data_out = (sel_tfr     & rd ? (port_num ? ide1_data : ide0_data)               : 16'h0000)
                | (sel_cs      & rd ? {(cs_mask[5] || intreq), cs_mask[4:0], cs, 8'h0} : 16'h0000)
                | (sel_intreq  & rd ? {intreq, 15'b000_0000_0000_0000}                 : 16'h0000)
                | (sel_intena  & rd ? {intena, 15'b000_0000_0000_0000}                 : 16'h0000)
                | (sel_gayleid & rd ? {gayleid,15'b000_0000_0000_0000}                 : 16'h0000)
                | (sel_cfg     & rd ? {cfg,        12'b0000_0000_0000}                 : 16'h0000);


endmodule

