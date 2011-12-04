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

module Denise
(
	input 	clk,		   			//bus clock / lores pixel clock
	input 	reset,					//reset
	input	strhor,					//horizontal strobe
	input 	[8:1] reg_address_in,	//register adress inputs
	input 	[15:0] data_in,			//bus data in
	output 	[15:0] data_out,		//bus data out
	input	blank,					//blanking input
	output 	[3:0] red, 				//red componenent video out
	output 	[3:0] green,  			//green component video out
	output 	[3:0] blue,				//blue component video out
	output	reg hires				//hires
);

//register names and adresses		
parameter DIWSTRT  = 9'h08E;
parameter DIWSTOP  = 9'h090;
parameter BPLCON0  = 9'h100;  		
parameter BPLCON2  = 9'h104; 
parameter DENISEID = 9'h07C;
parameter BPL1DAT  = 9'h110;

//local signals
reg		[8:0] hpos;				//horizontal beamcounter
reg		homod;					//HAM mode select
reg		dblpf;					//double playfield select
reg		[6:0] bplcon2;			//bplcon2 (playfield video priority) register

wire	dclk;					//ddr register select clock

reg		[7:0] diwstrt;			//horizontal display window start position
reg		[7:0] diwstop;			//horizontal display window stop position

wire	[6:1] bpldata;			//raw bitplane serial video data
wire	[3:0] sprdata;			//sprite serial video data
wire	[5:0] plfdata;			//playfield serial video data
wire	[2:1] nplayfield;		//playfield 1,2 valid data signals
wire	[7:0] nsprite;			//sprite 0-7 valid data signals 
wire	sprsel;					//sprite select

wire	[11:0] hamrgb;			//hold and modify mode RGB video data
wire	[5:0] plfdata_d;		//plfdata delayed by one low res pixel
wire	sprsel_d;				//sprsel delayed by one low res pixel
reg		[3:0] sprdata_d;		//sprdata delayed by one low res pixel

reg		[5:0] tabledata;		//color table color select in
wire	[11:0] tablergb;		//color table rgb data out
reg		[11:0] outrgb;			//final multiplexer rgb output data
reg		window;					//window enable signal

wire	[15:0] deniseid_out; 	//deniseid data_out
wire	[15:0] col_out;			//colision detection data_out

reg		sprena;					//in OCS sprites are visible between first write to BPL1DAT and end of scanline

//--------------------------------------------------------------------------------------

//data out mulitplexer
assign data_out = col_out | deniseid_out;

//--------------------------------------------------------------------------------------

//generate dclk dclk is in sync with clk but driven by logic instead of general clock
//dclk is used to drive the multiplexers of the double data rate (hires) registers
reg dclkl1;
reg dclkl2;

always @(posedge clk)
	dclkl1 <= ~dclkl1;
	
always @(negedge clk)
	dclkl2 <= dclkl1;
	
assign dclk = dclkl1 ^ dclkl2;

//--------------------------------------------------------------------------------------

//Denise local horizontal beamcounter
// Denise's horizontal counter counting range: $01-$E3 CCKs (2-455 lores pixels)
always @(posedge clk)
	if (strhor)
		hpos <= 2;
	else
		hpos <= hpos + 1;

//--------------------------------------------------------------------------------------

//sprite enable signal
//sprites are visible after the first write to the BPL1DAT register in a scanline
always @(posedge clk)
	if (reset || strhor)
		sprena <= 0;
	else if (reg_address_in[8:1]==BPL1DAT[8:1])
		sprena <= 1;

//bplcon0 register
always @(posedge clk)
	if (reset)
	begin
		hires <= 0;
		homod <= 0;
		dblpf <= 0;
	end
	else if (reg_address_in[8:1]==BPLCON0[8:1])
	begin
		hires <= data_in[15];
		homod <= data_in[11];
		dblpf <= data_in[10];
	end	

//bplcon2 register
always @(posedge clk)
	if (reset)
		bplcon2 <= 0;
	else if (reg_address_in[8:1]==BPLCON2[8:1])
		bplcon2[6:0] <= data_in[6:0];
		
//diwstart and diwstop registers (vertical and horizontal limits of display window)
always @(posedge clk)
	if (reg_address_in[8:1]==DIWSTRT[8:1])
		diwstrt[7:0] <= data_in[7:0];
		
always @(posedge clk)
	if (reg_address_in[8:1]==DIWSTOP[8:1])
		diwstop[7:0] <= data_in[7:0];

assign deniseid_out = reg_address_in[8:1]==DENISEID[8:1] ? 16'hFF_FF : 16'h00_00;

//--------------------------------------------------------------------------------------

//generate window enable signal
//true when beamcounter satisfies horizontal diwstrt/diwstop limits
always @(posedge clk)
	if (hpos[8:0]=={1'b0,diwstrt[7:0]})
		window <= 1;
	else if (hpos[8:0]=={1'b1,diwstop[7:0]})
		window <= 0;
		

//--------------------------------------------------------------------------------------

//instantiate bitplane module
bitplanes bplm0 
(
	.clk(clk),
	.reg_address_in(reg_address_in),
	.data_in(data_in),
	.hires(hires),
	.hpos(hpos),
	.bpldata(bpldata)	
);

//instantiate playfield module
playfields plfm0
(
	.bpldata(bpldata),
	.dblpf(dblpf),
	.bplcon2(bplcon2[6:0]),
	.nplayfield(nplayfield),
	.plfdata(plfdata)	
);

//instantiate sprite module
sprites sprm0
(
	.clk(clk),
	.reset(reset),
	.reg_address_in(reg_address_in),
	.hpos(hpos),
	.data_in(data_in),
	.sprena(sprena),
	.nsprite(nsprite),
	.sprdata(sprdata)	
);

//instantiate video priority logic module
sprpriority spm0
(
	.bplcon2(bplcon2[5:0]),
	.nplayfield(nplayfield),
	.nsprite(nsprite),
	.sprsel(sprsel)	
);

//instantiate color table
colortable ctbm0
(
	.clk(clk),
	.reg_address_in(reg_address_in),
	.data_in(data_in[11:0]),
	.select(tabledata),
	.rgb(tablergb)		
);

//instantiate HAM (hold and modify) module
hamgenerator ham0
(
	.clk(clk),
	.reg_address_in(reg_address_in),
	.data_in(data_in[11:0]),
	.bpldata(bpldata),
	.rgb(hamrgb)		
);

//instantiate collision detection module
collision col0
(
	.clk(clk),
	.reset(reset),
	.reg_address_in(reg_address_in),
	.data_in(data_in),
	.data_out(col_out),
	.bpldata(bpldata),
	.nsprite(nsprite)	
);

//--------------------------------------------------------------------------------------

//sprsel and plfdata latch (ddr)
//delay those signals by one low res pixel 
reg [6:0] plfdatal1;
reg [6:0] plfdatal2;

always @(negedge clk)
	plfdatal1 <= {sprsel,plfdata[5:0]};
	
always @(posedge clk)
	plfdatal2 <= {sprsel,plfdata[5:0]};
	
assign {sprsel_d,plfdata_d[5:0]} = dclk ? plfdatal1 : plfdatal2;

//--------------------------------------------------------------------------------------

//sprdata latch (sdr)
//delay sprdata by one low res pixel 
always @(posedge clk)
	sprdata_d <= sprdata;

//--------------------------------------------------------------------------------------

//sprdata_d / plfdata_d / border multiplexer
always @(homod or sprsel_d or window or sprdata_d or plfdata_d)
begin
	if (!window)//we are outside the visible window region, display border color
		tabledata = 6'b000000;
	else if (homod || sprsel_d)//if HAM mode or sprsel, select sprites
		tabledata = {2'b01,sprdata_d[3:0]};
	else//else select playfield data
		tabledata = plfdata_d;
end

//hamrgb / tablergb multiplexer
always @(homod or sprsel_d or window or tablergb or hamrgb)
begin
	if (!homod)//if no HAM mode, always select normal (table selected) rgb data
		outrgb = tablergb;
	else if (!window || sprsel_d)//else if outside window or sprite priority
		outrgb = tablergb;
	else//else select ham generated rgb value
		outrgb = hamrgb;
end

//--------------------------------------------------------------------------------------

//video output register (ddr) and blanking circuit
reg [11:0] outrgbl1;
reg [11:0] outrgbl2;

always @(negedge clk)
	if (blank)
		outrgbl1 <= 12'h000;
	else
		outrgbl1 <= outrgb;
		
always @(posedge clk)
	if (blank)
		outrgbl2 <= 12'h000;
	else
		outrgbl2 <= outrgb;
		
//output ddr mulitplexer
assign {red[3:0],green[3:0],blue[3:0]} = dclk ? outrgbl1 : outrgbl2;

endmodule

//--------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------

//this is the 32 color color table
//because this module also supports EHB (extra half brite) mode,
//it actually has a 6bit color select input
//the 6th bit selects EHB color while the lower 5 bit select the actual color register

module colortable
(
	input 	clk,		   			//bus clock / lores pixel clock
	input 	[8:1] reg_address_in,		//register adress inputs
	input 	[11:0] data_in,			//bus data in
	input	[5:0] select,			//color select input
	output	reg [11:0] rgb			//RGB output
);

//register names and adresses		
parameter COLORBASE = 9'h180;  		//color table base address

//local signals
reg 	[11:0] colortable [31:0];	//color table
wire	[11:0] selcolor; 			//selected color register output

//writing of color table from bus (implemented using dual port distributed ram)
always @(posedge clk)
	if (reg_address_in[8:6]==COLORBASE[8:6])
		colortable[reg_address_in[5:1]] <= data_in[11:0];

//reading of color table
assign selcolor = colortable[select[4:0]];   

//extra half brite mode shifter
always @(selcolor or select[5])
	if (select[5])//half bright, shift every component 1 position to the right
		rgb = {1'b0,selcolor[11:9],1'b0,selcolor[7:5],1'b0,selcolor[3:1]};
	else//normal color select
		rgb = selcolor;

endmodule

//--------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------

//sprite priority logic module
//this module checks the playfields and sprites video status and
//determines if playfield or sprite data must be sent to the video output
//sprite/playfield priority is configurable through the bplcon2 bits				
module sprpriority
(
	input 	[5:0] bplcon2,		   	//playfields vs sprites priority setting
	input	[2:1] nplayfield,		//playfields video status
	input	[7:0] nsprite,			//sprites video status
	output	reg sprsel				//sprites select signal output
);

// local signals
reg		[2:0] sprcode;			//sprite code
wire	[3:0] sprgroup;			//grouped sprites
wire	pf1front;				//playfield 1 is on front of sprites
wire	pf2front;				//playfield 2 is on front of sprites

//group sprites together
assign	sprgroup[0] = (nsprite[1:0]==0) ? 0 : 1;
assign	sprgroup[1] = (nsprite[3:2]==0) ? 0 : 1;
assign	sprgroup[2] = (nsprite[5:4]==0) ? 0 : 1;
assign	sprgroup[3] = (nsprite[7:6]==0) ? 0 : 1;

//sprites priority encoder
always @(sprgroup)
	if (sprgroup[0])
		sprcode = 1;
	else if (sprgroup[1])
		sprcode = 2;
	else if (sprgroup[2])
		sprcode = 3;
	else if (sprgroup[3])
		sprcode = 4;
	else
		sprcode = 7;

//check if playfields are in front of sprites
assign pf1front = sprcode[2:0]>bplcon2[2:0] ? 1 : 0;
assign pf2front = sprcode[2:0]>bplcon2[5:3] ? 1 : 0;

//generate final playfield/sprite select signal
always @(sprcode or pf1front or pf2front or nplayfield)
begin
	if (sprcode[2:0]==7) //if no valid sprite data, always select playfields
		sprsel = 0;
	else if (pf1front && nplayfield[1]) //else if pf1 in front and valid data, select playfields
		sprsel = 0;
	else if (pf2front && nplayfield[2]) //else if pf2 in front and valid data, select playfields
		sprsel = 0;	 
	else //else select sprites
		sprsel = 1;
end

endmodule

//--------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------

//this module handles the hold and modify mode (HAM)
//the module has its own color pallete bank, this is to let 
//the sprites run simultanously with a HAM playfield
module hamgenerator
(
	input 	clk,		   			//bus clock / lores pixel clock
	input 	[8:1] reg_address_in,		//register adress inputs
	input 	[11:0] data_in,			//bus data in
	input	[5:0] bpldata,			//bitplane data input
	output	reg [11:0] rgb			//RGB output
);

//register names and adresses		
parameter COLORBASE = 9'h180;  		//color table base address

//local signals
reg 	[11:0] colortable [15:0];	//color table
wire	[11:0] selcolor;			//selected color output from color table

//--------------------------------------------------------------------------------------

//writing of HAM color table from bus (implemented using dual port distributed ram)
always @(posedge clk)
	if (reg_address_in[8:5]==COLORBASE[8:5])
		colortable[reg_address_in[4:1]] <= data_in[11:0];

//reading of color table
assign selcolor = colortable[bpldata[3:0]];   

//--------------------------------------------------------------------------------------

//HAM instruction decoder/processor
always @(posedge clk)
begin
	case (bpldata[5:4])
		2'b00://load rgb output with color from table	
			rgb <= selcolor;
		2'b01://hold green and red, modify blue
			rgb  <= {rgb[11:4],bpldata[3:0]};	
		2'b10://hold green and blue, modify red
			rgb <= {bpldata[3:0],rgb[7:0]};
		2'b11://hold blue and red, modify green
			rgb <= {rgb[11:8],bpldata[3:0],rgb[3:0]};
	endcase
end

endmodule

//--------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------

//this is the collision detection module
module collision
(
	input 	clk,					//bus clock / lores pixel clock
	input	reset,					//reset
	input 	[8:1] reg_address_in,	//register adress inputs
	input 	[15:0] data_in,			//bus data in
	output	[15:0] data_out,		//bus data out
	input	[5:0] bpldata,			//bitplane serial video data in
	input	[7:0] nsprite	
);

//register names and adresses		
parameter CLXCON = 9'h098;
parameter CLXDAT = 9'h00E;

//local signals
reg		[15:0] clxcon;			//collision detection control register
reg		[14:0] clxdat;			//collision detection data register
wire	[3:0] sprmatch;			//sprite group matches clxcon settings
wire	oddmatch;				//odd bitplane data matches clxcon settings
wire	evenmatch;				//even bitplane data matches clxcon settings

//--------------------------------------------------------------------------------------

//CLXCON register
always @(posedge clk)
	if (reset) //reset to safe value
		clxcon <= 16'h0fff;
	else if (reg_address_in[8:1]==CLXCON[8:1])
		clxcon <= data_in;

//--------------------------------------------------------------------------------------

//generate bitplane match signal
wire [5:0] bm;
assign bm = (bpldata[5:0] ^ ~clxcon[5:0]) | (~clxcon[11:6]); // JB: playfield collision detection fix

assign oddmatch = bm[4] & bm[2] & bm[0];
assign evenmatch = bm[5] & bm[3] & bm[1];

//generate sprite group match signal
assign sprmatch[0] = nsprite[0] | (nsprite[1] & clxcon[12]);
assign sprmatch[1] = nsprite[2] | (nsprite[3] & clxcon[13]);
assign sprmatch[2] = nsprite[4] | (nsprite[5] & clxcon[14]);
assign sprmatch[3] = nsprite[6] | (nsprite[7] & clxcon[15]);

//--------------------------------------------------------------------------------------

//detect collisions
wire [14:0] cl;

assign cl[0]  = evenmatch   & oddmatch;		//odd to even bitplanes
assign cl[1]  = oddmatch    & sprmatch[0];	//odd bitplanes to sprite 0(or 1)
assign cl[2]  = oddmatch    & sprmatch[1];	//odd bitplanes to sprite 2(or 3)
assign cl[3]  = oddmatch    & sprmatch[2];	//odd bitplanes to sprite 4(or 5)
assign cl[4]  = oddmatch    & sprmatch[3];	//odd bitplanes to sprite 6(or 7)
assign cl[5]  = evenmatch   & sprmatch[0];	//even bitplanes to sprite 0(or 1)
assign cl[6]  = evenmatch   & sprmatch[1];	//even bitplanes to sprite 2(or 3)
assign cl[7]  = evenmatch   & sprmatch[2];	//even bitplanes to sprite 4(or 5)
assign cl[8]  = evenmatch   & sprmatch[3];	//even bitplanes to sprite 6(or 7)
assign cl[9]  = sprmatch[0] & sprmatch[1];	//sprite 0(or 1) to sprite 2(or 3)
assign cl[10] = sprmatch[0] & sprmatch[2];	//sprite 0(or 1) to sprite 4(or 5)
assign cl[11] = sprmatch[0] & sprmatch[3];	//sprite 0(or 1) to sprite 6(or 7)
assign cl[12] = sprmatch[1] & sprmatch[2];	//sprite 2(or 3) to sprite 4(or 5)
assign cl[13] = sprmatch[1] & sprmatch[3];	//sprite 2(or 3) to sprite 6(or 7)
assign cl[14] = sprmatch[2] & sprmatch[3];	//sprite 4(or 5) to sprite 6(or 7)

//register detected collisions
always @(posedge clk)
	if (reg_address_in[8:1]==CLXDAT[8:1]) //if clxdat is read, clxdat is cleared to all zero's
		clxdat <= 0;
	else //else register collisions
		clxdat <= clxdat[14:0] | cl[14:0];

//--------------------------------------------------------------------------------------

//reading of clxdat register
assign data_out = reg_address_in[8:1]==CLXDAT[8:1] ? {1'b1,clxdat[14:0]} : 0;

endmodule