// Copyright 2006, 2007 Dennis van Weeren
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
// This is the bitplane part of denise 
// It accepts data from the bus and converts it to serial video data (6 bits).
// It supports all ocs modes and also handles the pf1<->pf2 priority handling in
// a seperate module.
//
// 11-05-2005	-started coding
// 15-05-2005	-first finished version
// 16-05-2005	-fixed hires scrolling, now you can fetch 2 words early
// 22-05-2005	-fixed bug in dual playfield mode when both playfields where transparant
// 22-06-2005	-moved playfield engine / priority logic to seperate module
// ----------
// JB:
// 2008-12-27	- addapted playfield horizontal scrolling
// 2009-02-09	- added hpos for proper horizontal scroll of non-aligned dma fetches
// 2009-05-24	- clean-up & renaming
// 2009-10-07	- pixel pipe line extra delay (alligment of bitplane data and copper colour change)


module denise_bitplanes
(
	input 	clk,		   			// system bus clock
	input 	clk7_en,
	input 	c1,						// 35ns clock enable signals (for synchronization with clk)
	input 	c3,
	input 	[8:1] reg_address_in, 	// register address
	input 	[15:0] data_in,	 		// bus data in
	input 	hires,		   			// high resolution mode select
	input 	shres,		   			// super high resolution mode select
	input	[8:0] hpos,				// horizontal position (70ns resolution)
	output 	[6:1] bpldata			// bitplane data out
);
//register names and adresses
parameter BPLCON1 = 9'h102;  		
parameter BPL1DAT = 9'h110;
parameter BPL2DAT = 9'h112;
parameter BPL3DAT = 9'h114;
parameter BPL4DAT = 9'h116;
parameter BPL5DAT = 9'h118;
parameter BPL6DAT = 9'h11a;

//local signals
reg 	[7:0] bplcon1;		// bplcon1 register
reg		[15:0] bpl1dat;		// buffer register for bit plane 2
reg		[15:0] bpl2dat;		// buffer register for bit plane 2
reg		[15:0] bpl3dat;		// buffer register for bit plane 3
reg		[15:0] bpl4dat;		// buffer register for bit plane 4
reg		[15:0] bpl5dat;		// buffer register for bit plane 5
reg		[15:0] bpl6dat;		// buffer register for bit plane 6
reg		load;				// bpl1dat written => load shif registers

reg		[3:0] extra_delay;	// extra delay when not alligned ddfstart
reg		[3:0] pf1h;			// playfield 1 horizontal scroll
reg		[3:0] pf2h;			// playfield 2 horizontal scroll
reg		[3:0] pf1h_del;		// delayed playfield 1 horizontal scroll
reg		[3:0] pf2h_del;		// delayed playfield 2 horizontal scroll

//--------------------------------------------------------------------------------------

// horizontal scroll depends on horizontal position when BPL0DAT in written
// visible display scroll is updated on fetch boundaries
// increasing scroll value during active display inserts blank pixels

always @(hpos)
	case (hpos[3:2])
		2'b00 : extra_delay = 4'b0000;
		2'b01 : extra_delay = 4'b1100;
		2'b10 : extra_delay = 4'b1000;
		2'b11 : extra_delay = 4'b0100;
	endcase

//playfield 1 effective horizontal scroll
always @(posedge clk)
  if (clk7_en) begin
  	if (load)
  		pf1h <= bplcon1[3:0] + extra_delay;
  end

always @(posedge clk)
  if (clk7_en) begin
  	pf1h_del <= pf1h;
  end
		
//playfield 2 effective horizontal scroll
always @(posedge clk)
  if (clk7_en) begin
  	if (load)
  		pf2h <= bplcon1[7:4] + extra_delay;
  end

always @(posedge clk)
  if (clk7_en) begin
  	pf2h_del <= pf2h;
  end
	
//writing bplcon1 register : horizontal scroll codes for even and odd bitplanes
always @(posedge clk)
  if (clk7_en) begin
  	if (reg_address_in[8:1]==BPLCON1[8:1])
  		bplcon1 <= data_in[7:0];
  end

//--------------------------------------------------------------------------------------

//bitplane buffer register for plane 1
always @(posedge clk)
  if (clk7_en) begin
  	if (reg_address_in[8:1]==BPL1DAT[8:1])
  		bpl1dat <= data_in[15:0];
  end
		
//bitplane buffer register for plane 2
always @(posedge clk)
  if (clk7_en) begin
  	if (reg_address_in[8:1]==BPL2DAT[8:1])
  		bpl2dat <= data_in[15:0];
  end

//bitplane buffer register for plane 3
always @(posedge clk)
  if (clk7_en) begin
  	if (reg_address_in[8:1]==BPL3DAT[8:1])
  		bpl3dat <= data_in[15:0];
  end

//bitplane buffer register for plane 4
always @(posedge clk)
  if (clk7_en) begin
  	if (reg_address_in[8:1]==BPL4DAT[8:1])
  		bpl4dat <= data_in[15:0];
  end

//bitplane buffer register for plane 5
always @(posedge clk)
  if (clk7_en) begin
  	if (reg_address_in[8:1]==BPL5DAT[8:1])
  		bpl5dat <= data_in[15:0];
  end

//bitplane buffer register for plane 6
always @(posedge clk)
  if (clk7_en) begin
  	if (reg_address_in[8:1]==BPL6DAT[8:1])
  		bpl6dat <= data_in[15:0];
  end

//generate load signal when plane 1 is written
always @(posedge clk)
  if (clk7_en) begin
  	load <= reg_address_in[8:1]==BPL1DAT[8:1] ? 1'b1 : 1'b0;
  end

//--------------------------------------------------------------------------------------

//instantiate bitplane 1 parallel to serial converters, this plane is loaded directly from bus
denise_bitplane_shifter bplshft1 
(
	.clk(clk),
  .clk7_en(clk7_en),
	.c1(c1),
	.c3(c3),
	.load(load),
	.hires(hires),
	.shres(shres),
	.data_in(bpl1dat),
	.scroll(pf1h_del),
	.out(bpldata[1])	
);

//instantiate bitplane 2 to 6 parallel to serial converters, (loaded from buffer registers)
denise_bitplane_shifter bplshft2 
(	
	.clk(clk),
  .clk7_en(clk7_en),
	.c1(c1),
	.c3(c3),
	.load(load),
	.hires(hires),
	.shres(shres),
	.data_in(bpl2dat),
	.scroll(pf2h_del),
	.out(bpldata[2])	
);

denise_bitplane_shifter bplshft3 
(	
	.clk(clk),
  .clk7_en(clk7_en),
	.c1(c1),
	.c3(c3),
	.load(load),
	.hires(hires),
	.shres(shres),
	.data_in(bpl3dat),
	.scroll(pf1h_del),
	.out(bpldata[3])	
);

denise_bitplane_shifter bplshft4 
(	
	.clk(clk),
  .clk7_en(clk7_en),
	.c1(c1),
	.c3(c3),
	.load(load),
	.hires(hires),
	.shres(shres),
	.data_in(bpl4dat),
	.scroll(pf2h_del),
	.out(bpldata[4])	
);

denise_bitplane_shifter bplshft5 
(	
	.clk(clk),
  .clk7_en(clk7_en),
	.c1(c1),
	.c3(c3),
	.load(load),
	.hires(hires),
	.shres(shres),
	.data_in(bpl5dat),
	.scroll(pf1h_del),
	.out(bpldata[5])	
);

denise_bitplane_shifter bplshft6 
(	
	.clk(clk),
  .clk7_en(clk7_en),
	.c1(c1),
	.c3(c3),
	.load(load),
	.hires(hires),
	.shres(shres),
	.data_in(bpl6dat),
	.scroll(pf2h_del),
	.out(bpldata[6])	
);

endmodule

