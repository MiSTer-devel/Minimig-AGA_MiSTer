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


module bitplanes
(
	input 	clk,					//bus clock
	input 	[8:1] reg_address_in, 	//register address
	input 	[15:0] data_in,	 		//bus data in
	input 	hires,		   			//high resolution mode select
	input	[8:0] hpos,				//horizontal position (70ns resolution)
	output 	[6:1] bpldata			//bitplane data out
);
//register names and adresses
parameter DDFSTRT = 9'h092;		
parameter BPLCON1 = 9'h102;  		
parameter BPL1DAT = 9'h110;
parameter BPL2DAT = 9'h112;
parameter BPL3DAT = 9'h114;
parameter BPL4DAT = 9'h116;
parameter BPL5DAT = 9'h118;
parameter BPL6DAT = 9'h11a;

//local signals
reg 	[7:0] bplcon1;		//bplcon1 register
wire	hclk;				//high res double pumped clock
reg		hclkl1;				//helper latch for generating hclk;
reg		hclkl2;	   			//helper latch for generating hclk;
reg		[15:0] bpl2dat;		//buffer register for bit plane 2
reg		[15:0] bpl3dat;		//buffer register for bit plane 3
reg		[15:0] bpl4dat;		//buffer register for bit plane 4
reg		[15:0] bpl5dat;		//buffer register for bit plane 5
reg		[15:0] bpl6dat;		//buffer register for bit plane 6
wire	load;				//parallel load signal

reg		[3:0] extra_delay;	//extra delay when not alligned ddfstart
reg		[3:0] pf1h;			//playfield 1 horizontal scroll
reg		[3:0] pf2h;			//playfield 2 horizontal scroll
reg		pfxh_load;

//--------------------------------------------------------------------------------------

//generate hclk hclk is in sync with clk but driven by logic instead of general clock
always @(posedge clk)
	hclkl1 <= ~hclkl1;
	
always @(negedge clk)
	hclkl2 <= hclkl1;
	
assign hclk = hclkl1 ^ hclkl2;

//--------------------------------------------------------------------------------------

//horizontal scroll depends on horizontal position when BPL0DAT in written
always @(hpos)
	case (hpos[3:2])
		2'b00 : extra_delay = 4'b0000;
		2'b01 : extra_delay = 4'b1100;
		2'b10 : extra_delay = 4'b1000;
		2'b11 : extra_delay = 4'b0100;
	endcase

//delay
always @(posedge clk)
	pfxh_load  <=  load;
	
//playfield 1 effective horizontal scroll
always @(posedge clk)
	if (pfxh_load)
		pf1h  <=  bplcon1[3:0] + extra_delay;

//playfield 2 effective horizontal scroll
always @(posedge clk)
	if (pfxh_load)
		pf2h  <=  bplcon1[7:4] + extra_delay;

//writing bplcon1 register : horizontal scroll codes for even and odd bitplanes
always @(posedge clk)
	if (reg_address_in[8:1]==BPLCON1[8:1])
		bplcon1 <= data_in[7:0];

//--------------------------------------------------------------------------------------

//bitplane buffer register for plane 2
always @(posedge clk)
	if (load)
		bpl2dat <= 16'b0000000000000000;	
	else if (reg_address_in[8:1]==BPL2DAT[8:1])
		bpl2dat <= data_in[15:0];

//bitplane buffer register for plane 3
always @(posedge clk)
	if (load)
		bpl3dat <= 16'b0000000000000000;	
	else if (reg_address_in[8:1]==BPL3DAT[8:1])
		bpl3dat <= data_in[15:0];

//bitplane buffer register for plane 4
always @(posedge clk)
	if (load)
		bpl4dat <= 16'b0000000000000000;	
	else if (reg_address_in[8:1]==BPL4DAT[8:1])
		bpl4dat <= data_in[15:0];

//bitplane buffer register for plane 5
always @(posedge clk)
	if (load)
		bpl5dat <= 16'b0000000000000000;	
	else if (reg_address_in[8:1]==BPL5DAT[8:1])
		bpl5dat <= data_in[15:0];

//bitplane buffer register for plane 6
always @(posedge clk)
	if (load)
		bpl6dat <= 16'b0000000000000000;	
	else if (reg_address_in[8:1]==BPL6DAT[8:1])
		bpl6dat <= data_in[15:0];

//generate load signal when plane 1 is written
assign load = reg_address_in[8:1]==BPL1DAT[8:1] ? 1 : 0;

//--------------------------------------------------------------------------------------

//instantiate bitplane 1 parallel to serial converters, this plane is loaded directly from bus
bplshift bpls1 
(
	.clk(clk),
	.hclk(hclk),
	.load(load),
	.hires(hires),
	.data(data_in),
	.delay(pf1h),
	.out(bpldata[1])	
);

//instantiate bitplane 2 to 6 parallel to serial converters, (loaded from buffer registers)
bplshift bpls2 
(	
	.clk(clk),
	.hclk(hclk),
	.load(load),
	.hires(hires),
	.data(bpl2dat),
	.delay(pf2h),
	.out(bpldata[2])	
);

bplshift bpls3 
(	
	.clk(clk),
	.hclk(hclk),
	.load(load),
	.hires(hires),
	.data(bpl3dat),
	.delay(pf1h),
	.out(bpldata[3])	
);

bplshift bpls4 
(	
	.clk(clk),
	.hclk(hclk),
	.load(load),
	.hires(hires),
	.data(bpl4dat),
	.delay(pf2h),
	.out(bpldata[4])	
);

bplshift bpls5 
(	
	.clk(clk),
	.hclk(hclk),
	.load(load),
	.hires(hires),
	.data(bpl5dat),
	.delay(pf1h),
	.out(bpldata[5])	
);

bplshift bpls6 
(	
	.clk(clk),
	.hclk(hclk),
	.load(load),
	.hires(hires),
	.data(bpl6dat),
	.delay(pf2h),
	.out(bpldata[6])	
);

//--------------------------------------------------------------------------------------

endmodule

//--------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------

//This is the playfield engine.
//It takes the raw bitplane data and generates a
//single or dual playfield
//it also generated the nplayfield valid data signals which are needed
//by the main video priority logic in Denise

module playfields
(
	input 	[6:1] bpldata,	   		//raw bitplane data in
	input 	dblpf,		   			//double playfield select
	input	[6:0] bplcon2,			//bplcon2 (playfields priority)
	output	reg [2:1] nplayfield,	//playfield 1,2 valid data
	output	reg [5:0] plfdata		//playfield data out
);

//local signals
wire pf2pri;						//playfield 2 priority over playfield 1
wire [2:0] pf2p;					//playfield 2 priority code

assign pf2pri = bplcon2[6];
assign pf2p = bplcon2[5:3];

//generate playfield 1,2 data valid signals
always @(dblpf or bpldata)
begin
	if (dblpf) //dual playfield
	begin
		if (bpldata[5] || bpldata[3] || bpldata[1]) //detect data valid for playfield 1
			nplayfield[1] = 1;
		else
			nplayfield[1] = 0;	
		if (bpldata[6] || bpldata[4] || bpldata[2]) //detect data valid for playfield 2
			nplayfield[2] = 1;
		else
			nplayfield[2] = 0;	
	end
	else //single playfield is always playfield 2
	begin
		nplayfield[1] = 0;
		if (bpldata[6:1]!=6'b000000)
			nplayfield[2] = 1;
		else
			nplayfield[2] = 0;	
	end
end

//--------------------------------------------------------------------------------------

//playfield 1 and 2 priority logic
always @(nplayfield or dblpf or pf2pri or bpldata or pf2p)
begin
	if (dblpf) //dual playfield
	begin
		if (pf2pri) //playfield 2 (2,4,6) has priority
		begin
			if (nplayfield[2])
				plfdata[5:0] = {3'b001,bpldata[6],bpldata[4],bpldata[2]};
			else if (nplayfield[1])
				plfdata[5:0] = {3'b000,bpldata[5],bpldata[3],bpldata[1]};
			else //both planes transparant, select background color
				plfdata[5:0] = 6'b000000;
		end
		else //playfield 1 (1,3,5) has priority
		begin
			if (nplayfield[1])
				plfdata[5:0] = {3'b000,bpldata[5],bpldata[3],bpldata[1]};
			else if (nplayfield[2])
				plfdata[5:0] = {3'b001,bpldata[6],bpldata[4],bpldata[2]};
			else //both planes transparant, select background color
				plfdata[5:0] = 6'b000000;
		end
	end
	else //normal single playfield (playfield 2 only)
	//OCS/ECS undocumented feature when bpu=5 and pf2pri>5 (Swiv score display)
		if (pf2p>5 && bpldata[5])
			plfdata[5:0] = {6'b010000};
		else
			plfdata[5:0] = bpldata[6:1];
end

//--------------------------------------------------------------------------------------

endmodule

//--------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------

//this is the bitplane parallel to serial converter
//it can operate in normal mode or hires mode
//clk is 7.09379 MHz (low resolution pixel clock)
//hclk is also 7.09379 MHz (high resolution double rate pixel clock) but driven by logic
//hires is double pumped (data on rising AND falling edge of clk)

module bplshift
(
	input 	clk,		   		//lores pixel clock
	input	hclk,				//hires clock that can drive logic	(double pumped)
	input	load,				//load shift register
	input	hires,				//high resolution / double pump select
	input	[15:0] data,		//parallel load data input
	input	[3:0] delay,		//delay select (for scrolling)
	output	out					//shift register out
);

//local signals
reg		[7:0] mshifteven;		//main shifter for even bits (0,2..)
reg		[7:0] mshiftodd;		//main shifter for odd bits (1,3..)
reg		[15:0] dshifteven;		//delayed scrolling shifter for even bits (0,2..)
reg		[15:0] dshiftodd;		//delayed scrolling shifter for odd bits (1,3..)

reg		enable;					//enable (toggles at clk/2)
reg		senable;				//shifters enable
reg		oddselect;				//odd shifter select
reg	 	[4:0] select;			//delayed pixel select

//--------------------------------------------------------------------------------------

//generate enable signal
always @(posedge clk)
	if (load) //upon load synchronize toggling enable signal
		enable <= 1;
	else
		enable <= ~enable;

//--------------------------------------------------------------------------------------

//main shifter
always @(posedge clk)
	if (load) //load new parallel data into shifter
		begin
			mshifteven[7:0] <= {data[14],data[12],data[10],data[8],data[6],data[4],data[2],data[0]};
			mshiftodd[7:0] <= {data[15],data[13],data[11],data[9],data[7],data[5],data[3],data[1]};
		end
	else if (senable) //shift when enabled
		begin
			mshifteven[7:0] <= {mshifteven[6:0],1'b0};
			mshiftodd[7:0] <= {mshiftodd[6:0],1'b0};
		end

//delayed shifter
always @(posedge clk)
	if (senable)
		begin
			dshifteven[15:0] <= {dshifteven[14:0],mshifteven[7]};
			dshiftodd[15:0] <= {dshiftodd[14:0],mshiftodd[7]};
		end		 

//--------------------------------------------------------------------------------------

wire	oddpixel;			//odd shift register delayed output
wire	evenpixel;			//even shift register delayed output
wire 	sout;				//final shift register delay output
reg		dout;				//1 clk delayed version of sout

//select even and odd pixel
assign oddpixel = dshiftodd[select[3:0]];//select odd pixel
assign evenpixel = dshifteven[select[3:0]];//select even pixel

//select final shifter output
assign sout = oddselect ? oddpixel : evenpixel;

//delay sout by 1 clock for pixel resolution scrolling in lores mode
always @(posedge clk)
	dout <= sout;

//assign output data
assign out = select[4] ? dout : sout;

//--------------------------------------------------------------------------------------

//main hires/lores shifter and scroll control
always @(hires or enable or hclk or delay)
	if (hires) //hires mode
	begin
		senable = 1;//shifter always enabled in this mode (2 pixels per clock)
		oddselect = hclk;
		select[4:0] = {2'b00,delay[2:0]};//only delay in 2 pixel steps
	end
	else
	begin
		senable = enable;//shifter enable once every 2 clocks
		oddselect = ~enable;
		select[4:0] = {delay[0],1'b0,delay[3:1]};//scroll in 1 pixel steps
	end
			
endmodule		