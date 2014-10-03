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
// This is Denise
// This module	is a complete implementation of the Amiga OCS Denise chip
// It supports all OCS modes including HAM, EHB and interlaced video
//
// 11-05-2005	-started coding
// 15-05-2005	-added local beamcounter
//				-added bitplanes module
//				-added color registers
//				-first experimental version
// 22-05-2005	-added diwstrt/diwstop
// 12-06-2005	-started integrating sprites module
// 21-06-2005	-done more work on integrating sprites module
// 22-06-2005	-done more work on completing denise
// 27-06-2005	-added main priority logic (sprites vs playfields)
// 28-06-2005	-added hold and modify mode
//				-added delay register and video multiplexers
//				-added video output register
// 29-06-2005	-added collision detection, Denise is now complete! (but untested)
//				-(later this day) Denise works! (hires,interlaced,playfield,sprites)
// 07-08-2005	-added deniseid register
// 02-10-2005	-fixed bit 15 of CLXDAT high
// 19-10-2005	-code now uses sol signal to synchronize local beam counter
// 11-01-2006	-added blanking circuit
// 22-01-2006	-added vertical window clipping
// ----------
// JB:
// 2008-07-08	- added hires output (for scandoubler)
//				- changed Denise ID (sometimes Show Config detected wrong chip type)
// 2008-11-23	- playfield collision detection fix
//				- changed horizontal counter counting range (fixes problems with overscan: Stardust, Forgoten Worlds)
//				- added strhor signal to synchronize local horizontal counter
// 2009-01-09	- added sprena signal (disables display of sprites until BPL1DAT is written)
// 2009-03-08	- removed sof and sol inputs as they are no longer used
// 2009-05-24	- clean-up & renaming
// 2009-10-04	- implemented DIWHIGH register, pixel pipeline moved to clk28m domain, implemented super hires, changed ID to ECS
// 2009-12-16	- added ECS enable input (only chip id is affected)
// 2009-12-20	- DIWHIGH is written only in ECS mode
// 2010-04-22	- ECS border blank implemented
//
// SB:
// 2012-03-23 - fixed sprite enable signal (coppermaster demo)
// 2013-10-19 - fixed self-made sprite collision bug. Now YQ100818 code is working again!
//
// Herzi
// 2014-03-08	- fixed detect collisions
//
// SB:
// 2014-04-12	- implemented sprite collision detection fix, developed by Yaqube. thanks a lot!
//		- games Archon1, Rotor and Spaceport finally works normal


module Denise
(
	input 	clk,					// 35ns pixel clock
  input   clk7_en,
	input 	c1 ,					// 35ns clock enable signals (for synchronization with clk)
	input 	c3,
	input 	cck,					// colour clock enable
	input 	reset,					// reset
	input	strhor,					// horizontal strobe
	input 	[8:1] reg_address_in,	// register adress inputs
	input 	[15:0] data_in,			// bus data in
	output 	[15:0] data_out,		// bus data out
	input	blank,					// blanking input
	output 	[3:0] red, 				// red componenent video out
	output 	[3:0] green,  			// green component video out
	output 	[3:0] blue,				// blue component video out
	input	ecs,					// enables ECS chipset features
  input a1k,          // control EHB chipset feature
	output	reg hires				// hires
);


//register names and adresses		
parameter DIWSTRT  = 9'h08E;
parameter DIWSTOP  = 9'h090;
parameter DIWHIGH  = 9'h1E4;
parameter BPLCON0  = 9'h100;  		
parameter BPLCON2  = 9'h104; 
parameter BPLCON3  = 9'h106; 
parameter DENISEID = 9'h07C;
parameter BPL1DAT  = 9'h110;

//local signals
reg		[8:0] hpos;				// horizontal beamcounter
reg		shres;					// super high resolution select
reg		homod;					// HAM mode select
reg		dblpf;					// double playfield select
reg		[3:0] bpu;				// bitplane enable
reg		[3:0] l_bpu;			// latched bitplane enable
reg		enaecs;					// enable ECS features like border blank (bplcon0.0)
reg		[15:0] bplcon2;			// bplcon2 (playfield video priority) register
reg		[15:0] bplcon3;			// bplcon3 register (border blank)
wire 	brdrblnk;				// border blank enable

reg		[8:0] hdiwstrt;			// horizontal display window start position
reg		[8:0] hdiwstop;			// horizontal display window stop position

wire	[6:1] bpldata_out;		// bitplane serial data out from shifters
wire	[6:1] bpldata;			// raw bitplane serial video data
wire	[3:0] sprdata;			// sprite serial video data
wire	[5:0] plfdata;			// playfield serial video data
wire	[2:1] nplayfield;		// playfield 1,2 valid data signals
wire	[7:0] nsprite;			// sprite 0-7 valid data signals 
wire	sprsel;					// sprite select

wire	[11:0] ham_rgb;			// hold and modify mode RGB video data
reg		[5:0] clut_data;		// colour table colour select in
wire	[11:0] clut_rgb;		// colour table rgb data out
wire	[11:0] out_rgb;			// final multiplexer rgb output data
reg		window;					// window enable signal

wire	[15:0] deniseid_out; 	// deniseid data_out
wire	[15:0] col_out;			// colision detection data_out

reg		display_ena;					// in OCS sprites are visible between first write to BPL1DAT and end of scanline

//--------------------------------------------------------------------------------------

// data out mulitplexer
assign data_out = col_out | deniseid_out;

//--------------------------------------------------------------------------------------

// Denise horizontal counter counting range: $01-$E3 CCKs (2-455 lores pixels)
always @(posedge clk)
  if (clk7_en) begin
  	if (strhor)
  		hpos <= 9'd2;
  	else
  		hpos <= hpos + 9'd1;
  end

//--------------------------------------------------------------------------------------

// sprite display enable signal - sprites are visible after the first write to the BPL1DAT register in a scanline
always @(posedge clk)
  if (clk7_en) begin
    if (reset || hpos[8:0]==8)
      display_ena <= 0;
    else if (reg_address_in[8:1]==BPL1DAT[8:1])
      display_ena <= 1;
  end

// bpu is updated when bpl1dat register is written
always @(posedge clk)
  if (clk7_en) begin
  	if (reg_address_in[8:1]==BPL1DAT[8:1])
  		l_bpu <= bpu;
  end

// BPLCON0 register
always @(posedge clk)
  if (clk7_en) begin
  	if (reset)
  	begin
  		hires <= 0;
  		shres <= 0;
  		homod <= 0;
  		dblpf <= 0;
  		bpu <= 0;
  		enaecs <= 0;
  	end
  	else if (reg_address_in[8:1]==BPLCON0[8:1])
  	begin
  		hires <= data_in[15];
  		shres <= data_in[6];
  		homod <= data_in[11];
  		dblpf <= data_in[10];
  		bpu <= {data_in[4],data_in[14:12]};
  		enaecs <= data_in[0];
  	end	
  end

// BPLCON2 register
always @(posedge clk)
  if (clk7_en) begin
  	if (reset)
  		bplcon2 <= 16'h00_00;
  	else if (reg_address_in[8:1]==BPLCON2[8:1])
  		bplcon2[15:0] <= data_in[15:0];
  end

// BPLCON3 register
always @(posedge clk)
  if (clk7_en) begin
  	if (reset)
  		bplcon3 <= 16'h00_00;
  	else if (reg_address_in[8:1]==BPLCON3[8:1])
  		bplcon3[15:0] <= data_in[15:0];
  end

assign brdrblnk = bplcon3[5];
		
// DIWSTART and DIWSTOP registers (vertical and horizontal limits of display window)
	
// HDIWSTRT
always @(posedge clk)
  if (clk7_en) begin
  	if (reg_address_in[8:1]==DIWSTRT[8:1])
  		hdiwstrt[7:0] <= data_in[7:0];
  end

always @(posedge clk)
  if (clk7_en) begin
  	if (reg_address_in[8:1]==DIWSTRT[8:1])
  		hdiwstrt[8] <= 1'b0; // diwstop H9 = 0
  	else if (reg_address_in[8:1]==DIWHIGH[8:1] && ecs)
  		hdiwstrt[8] <= data_in[5];
  end

// HDIWSTOP
always @(posedge clk)
  if (clk7_en) begin
  	if (reg_address_in[8:1]==DIWSTOP[8:1])
  		hdiwstop[7:0] <= data_in[7:0];
  end

always @(posedge clk)
  if (clk7_en) begin
  	if (reg_address_in[8:1]==DIWSTOP[8:1])
  		hdiwstop[8] <= 1'b1; // diwstop H8 = 1
  	else if (reg_address_in[8:1]==DIWHIGH[8:1] && ecs)
  		hdiwstop[8] <= data_in[13];		
  end

assign deniseid_out = reg_address_in[8:1]==DENISEID[8:1] ? ecs ? 16'hFF_FC : 16'hFF_FF : 16'h00_00;

//--------------------------------------------------------------------------------------

// generate window enable signal
// true when beamcounter satisfies horizontal diwstrt/diwstop limits
always @(posedge clk)
  if (clk7_en) begin
  	if (hpos[8:0]==hdiwstrt[8:0])
  		window <= 1;
  	else if (hpos[8:0]==hdiwstop[8:0])
  		window <= 0;
  end

reg window_ena;		
always @(posedge clk)
  if (clk7_en) begin
  	window_ena <= window;
	end

//--------------------------------------------------------------------------------------

// instantiate bitplane module
denise_bitplanes bplm0 
(
	.clk(clk),
  .clk7_en(clk7_en),
	.c1(c1),
	.c3(c3),
	.reg_address_in(reg_address_in),
	.data_in(data_in),
	.hires(hires),
	.shres(shres & ecs),
	.hpos(hpos),
	.bpldata(bpldata_out)	
);

assign bpldata[1] = l_bpu > 0 ? bpldata_out[1] : 1'b0;
assign bpldata[2] = l_bpu > 1 ? bpldata_out[2] : 1'b0;
assign bpldata[3] = l_bpu > 2 ? bpldata_out[3] : 1'b0;
assign bpldata[4] = l_bpu > 3 ? bpldata_out[4] : 1'b0;
assign bpldata[5] = l_bpu > 4 ? bpldata_out[5] : 1'b0;
assign bpldata[6] = l_bpu > 5 ? bpldata_out[6] : 1'b0;

// instantiate playfield module
denise_playfields plfm0
(
	.bpldata(bpldata),
	.dblpf(dblpf),
	.bplcon2(bplcon2[6:0]),
	.nplayfield(nplayfield),
	.plfdata(plfdata)	
);

// instantiate sprite module
denise_sprites sprm0
(
	.clk(clk),
  .clk7_en(clk7_en),
	.reset(reset),
	.reg_address_in(reg_address_in),
	.hpos(hpos),
	.data_in(data_in),
	.sprena(display_ena),
	.nsprite(nsprite),
	.sprdata(sprdata)	
);

// instantiate video priority logic module
denise_spritepriority spm0
(
	.bplcon2(bplcon2[5:0]),
	.nplayfield(nplayfield),
	.nsprite(nsprite),
	.sprsel(sprsel)	
);

// instantiate colour look up table
denise_colortable clut0
(
	.clk(clk),
	.clk7_en(clk7_en),
	.reg_address_in(reg_address_in),
	.data_in(data_in[11:0]),
	.select(clut_data),
  .a1k(a1k),
	.rgb(clut_rgb) // rgb data is delayed by one clk28m clock cycle
);

// instantiate HAM (hold and modify) module
denise_hamgenerator ham0
(
	.clk(clk),
	.clk7_en(clk7_en),
	.reg_address_in(reg_address_in),
	.data_in(data_in[11:0]),
	.bpldata(bpldata),
	.rgb(ham_rgb)		
);

// instantiate collision detection module
denise_collision col0
(
	.clk(clk),
  .clk7_en(clk7_en),
	.reset(reset),
	.reg_address_in(reg_address_in),
	.data_in(data_in),
	.data_out(col_out),
	.dblpf(dblpf),
	.bpldata(bpldata),
	.nsprite(nsprite)	
);


always @(*)
begin
	if (!window_ena) // we are outside of the visible window region, display border colour
		clut_data = 6'b000000;
	else if (sprsel) // select sprites
		clut_data = {2'b01,sprdata[3:0]};
	else // select playfield
		clut_data = plfdata;
end

reg window_del;
reg sprsel_del;

always @(posedge clk)
begin
	window_del <= window_ena;
	sprsel_del <= sprsel;
end

// ham_rgb / clut_rgb multiplexer
assign out_rgb = homod && window_del && !sprsel_del ? ham_rgb : clut_rgb; //if no HAM mode, always select normal (table selected) rgb data

//--------------------------------------------------------------------------------------

wire t_blank;

assign t_blank = blank | ecs & enaecs & brdrblnk & (~window_del | ~display_ena);

// RGB video output
assign {red[3:0],green[3:0],blue[3:0]} = t_blank ? 12'h000 : out_rgb;


endmodule

