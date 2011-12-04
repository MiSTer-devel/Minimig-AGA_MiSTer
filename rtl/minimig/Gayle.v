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

module gayle
(
	input	clk,
	input	reset,
	input	[23:1] address_in,
	input	[15:0] data_in,
	output	[15:0] data_out,
	input	rd,
	input	hwr,
	input	lwr,
	input	sel_ide,	//$DAxxxx
	input	sel_gayle,	//$DExxxx
	output	irq,
	input	[1:0] hdd_ena, //enables Master & Slave drives

	output	hdd_cmd_req,
	output	hdd_dat_req,
	input	[2:0] hdd_addr,
	input	[15:0] hdd_data_out,
	output	[15:0] hdd_data_in,
	input	hdd_wr,
	input	hdd_status_wr,
	input	hdd_data_wr,
	input	hdd_data_rd
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

wire 	sel_gayleid;
wire 	sel_tfr;
wire 	sel_fifo;
wire 	sel_status;
wire 	sel_command;
wire 	sel_intreq;
wire 	sel_intena;

reg		intena;
reg		intreq;
reg		busy;
reg		pio_in;
reg		pio_out;
reg		error;

reg		dev;	// drive 0/1 select

wire 	bsy;
wire 	drdy;
wire 	drq;
wire 	err;
wire 	[7:0] status;

wire	fifo_reset;
wire	[15:0] fifo_data_in;
wire	[15:0] fifo_data_out;
wire 	fifo_rd;
wire 	fifo_wr;
wire 	fifo_full;
wire 	fifo_empty;

// gayle id reg
reg		[1:0] gayleid_cnt;
wire	gayleid;

assign status = {bsy,drdy,2'b00,drq,2'b00,err};

assign bsy = busy & ~drq;
assign drdy = ~(bsy|drq);
assign err = error;

assign sel_gayleid = sel_gayle && address_in[15:12]==4'b0001 ? 1 : 0;	//$DE1xxx
assign sel_tfr = sel_ide && address_in[15:14]==2'b00 && !address_in[12] ? 1 : 0;
assign sel_status = rd && sel_tfr && address_in[4:2]==3'b111 ? 1 : 0;
assign sel_command = hwr && sel_tfr && address_in[4:2]==3'b111 ? 1 : 0;
assign sel_fifo = sel_tfr && address_in[4:2]==3'b000 ? 1 : 0;
assign sel_intreq = sel_ide && address_in[15:12]==4'b1001 ? 1 : 0;	//INTREQ
assign sel_intena = sel_ide && address_in[15:12]==4'b1010 ? 1 : 0;	//INTENA

//===============================================================================================//

// task file registers
reg		[7:0] tfr[7:0];
wire	[2:0] tfr_sel;
wire	[7:0] tfr_in;
wire	[7:0] tfr_out;
wire	tfr_we;

assign tfr_we = busy ? hdd_wr : sel_tfr & hwr;
assign tfr_sel = busy ? hdd_addr : address_in[4:2];
assign tfr_in = busy ? hdd_data_out[7:0] : data_in[15:8];

assign hdd_data_in = tfr_sel==0 ? fifo_data_out : {8'h00,tfr_out};

always @(posedge clk)
	if (tfr_we)
		tfr[tfr_sel] <= tfr_in;
		
assign tfr_out = tfr[tfr_sel];

always @(posedge clk)
	if (reset)
		dev <= 0;
	else if (sel_tfr && address_in[4:2]==6 && hwr)
		dev <= data_in[12];
		
// IDE interrupt enable register
always @(posedge clk)
	if (reset)
		intena <= 0;
	else if (sel_intena && hwr)
		intena <= data_in[15];
			
// gayle id register: reads 1->1->0->1 on MSB
always @(posedge clk)
	if (sel_gayleid)
		if (hwr)
			gayleid_cnt <= 0;
		else if (rd)
			gayleid_cnt <= gayleid_cnt + 1;

assign gayleid = gayleid_cnt[1:0] == 2'b10 ? 1'b0 : 1'b1;

// status register (write only from SPI host)
// 7 - busy status (write zero to finish command processing: allow host access to task file registers)
// 6
// 5
// 4 - intreq
// 3 - drq enable for pio in (PI) command type
// 2 - drq enable for pio out (PO) command type
// 1
// 0 - error flag (remember about setting error task file register)

// command busy status
always @(posedge clk)
	if (reset)
		busy <= 0;
	else if (busy && hdd_status_wr && hdd_data_out[7])	//reset by writing a zero to BSY status bit by SPI host
		busy <= 0;
	else if (sel_command)	//set after writing command register
		busy <= 1;

//IDE interrupt enable register
always @(posedge clk)
	if (reset)
		intreq <= 0;
	else if (busy && hdd_status_wr && hdd_data_out[4] && intena)	//set by SPI host
		intreq <= 1;
	else if (sel_intreq && hwr && !data_in[15])
		intreq <= 0;

assign irq = intreq;

// drq enable bit
always @(posedge clk)
	if (reset)
		pio_in <= 0;
	else if (drdy) //reset when drive finished command processing
		pio_in <= 0;
	else if (busy && hdd_status_wr && hdd_data_out[3])	//set by writing a one to DRQ status bit by SPI host
		pio_in <= 1;		

// drq enable bit
always @(posedge clk)
	if (reset)
		pio_out <= 0;
	else if (busy && hdd_status_wr && hdd_data_out[7]) 	//reset when processing of the current command ends
		pio_out <= 0;
	else if (busy && hdd_status_wr && hdd_data_out[2])	//set by writing a one by SPI host
		pio_out <= 1;	
		
assign drq = (~fifo_empty & pio_in) | (fifo_empty & pio_out);

// error status
always @(posedge clk)
	if (reset)
		error <= 0;
	else if (sel_command)	//reset by writing a new command
		error <= 0;
	else if (busy && hdd_status_wr && hdd_data_out[0])
		error <= 1;	
		
assign hdd_cmd_req = bsy;
assign hdd_dat_req = (~fifo_empty & pio_out);

assign fifo_reset = reset | sel_command;
assign fifo_data_in = pio_in ? hdd_data_out : data_in;
assign fifo_rd = pio_out ? hdd_data_rd : sel_fifo & rd;
assign fifo_wr = pio_in ? hdd_data_wr : sel_fifo & hwr & lwr;

//sector data buffer
fifo256x16 sb1
(
	.clk(clk),
	.reset(fifo_reset),
	.data_in(fifo_data_in),
	.data_out(fifo_data_out),
	.rd(fifo_rd),
	.wr(fifo_wr),
	.full(fifo_full),
	.empty(fifo_empty)
);


//data_out multiplexer //dev ? 16'h00_00 :
assign data_out = (sel_fifo && rd ? fifo_data_out : sel_status ? (!dev && hdd_ena[0]) || (dev && hdd_ena[1]) ? {status,8'h00} : 16'h00_00 : sel_tfr && rd ? {tfr_out,8'h00} : 16'h00_00)
			   | (sel_intreq && rd ? {intreq,15'b000_0000_0000_0000} : 16'h00_00)				
			   | (sel_intena && rd ? {intena,15'b000_0000_0000_0000} : 16'h00_00)				
			   | (sel_gayleid && rd ? {gayleid,15'b000_0000_0000_0000} : 16'h00_00);
 
//===============================================================================================//

//===============================================================================================//

endmodule


//256 words deep, 16 bits wide, fifo
//data is written into the fifo when wr=1
//when rd=1, the next data word is selected 
module fifo256x16
(
	input 	clk,		    		// bus clock
	input 	reset,			   		// reset 
	input	[15:0] data_in,			// data in
	output	reg [15:0] data_out,	// data out
	input	rd,						// read from fifo
	input	wr,						// write to fifo
	output	full,					// fifo is full
	output	reg empty				// fifo is empty
);

//local signals and registers
reg 	[15:0] mem [255:0];		// 256 words by 16 bit wide fifo memory
reg		[8:0] inptr;			// fifo input pointer
reg		[8:0] outptr;			// fifo output pointer
wire	equal;					// lower 8 bits of inptr and outptr are equal

//main fifo memory (implemented using synchronous block ram)
always @(posedge clk)
	if (wr && !full)
		mem[inptr[7:0]] <= data_in;
		
always @(posedge clk)
	data_out <= mem[outptr[7:0]];

//fifo write pointer control
always @(posedge clk)
	if (reset)
		inptr <= 0;
	else if (wr && !full)
		inptr <= inptr + 1;

//fifo read pointer control
always @(posedge clk)
	if(reset)
		outptr <= 0;
	else if(rd && !empty)
		outptr <= outptr + 1;

//check lower 13 bits of pointer to generate equal signal
assign equal = inptr==outptr ? 1 : 0;

//assign output flags, empty is delayed by one clock to handle ram delay
always @(posedge clk)
	if (inptr[8]==outptr[8])
		empty <= 1;
	else
		empty <= 0;
		
assign full = inptr[8]!=outptr[8] ? 1 : 0;	

endmodule