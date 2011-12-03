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
// This is the Blitter (part of the Agnus chip)
//
// 14-08-2005		-started coding
// 16-08-2005		-done more coding
// 19-08-2005		-added C source channel
//				-added minterm function generator
// 21-08-2005		-added proper masking for A channel
//				-added fill logic and D destination channel
//				-added normal/line mode control logic
//				-added address generator but it needs more work to reduce slices
// 23-08-2005		-done more work
//				-added blitsize counter
// 24-08-2005		-done some cleanup
// 28-08-2005		-redesigned address generator module
//				-started coding of main state machine
// 29-08-2005		-added blitter zero detect
//				-added logic for special line mode to channel D 
// 31-08-2005		-blitsize is now decremented automatically during channel D cycle
//				-added delayed version for lwt called lwtd (needed for pipelining)
// 04-09-2005		-added state machine for normal blitter mode	
//				-added data output gate in channel D (needed for integration into Agnus)
// 05-09-2005		-fixed bug in bltaddress module
//				-modified state machine start of blit handling
// 06-09-2005		-restored state machine, we should now have a working blitter (normal mode)
//				-fixed bug, channel B preload didn't work
// 14-09-2005		-fixed bug in channel A masking logic when doing 1 word wide blits
//				 (and subsequently found another error in the Hardware Reference Manual)
// 18-09-2005		-added sign bit handling for line mode
//				-redesigned address pointer ALU
//				-adapted state machine to use new style ALU codes
//				-added experimental line mode for octant 0,3,4,7
// 19-09-2005		-fixed bugs in line mode state machine and it begins to start working..
// 20-09-2005		-testing
// 25-09-2005		-complete redesign of controller logic
//				-added new linemode logic for all octants
// 27-09-2005		-fixed problem in linemode with dma/channel D modulo: it seems like the real blitter
//				 uses only C modulo for channel C and D during linemode, same for USEC/USED
//				-sign is taken from bit 15 of pointer A, NOT bit 20! -->fixed
//				-line drawing in octant 0,3,4,7 now works!
// 28-09-2005		-line drawing in octant 1,2,5,6 now works too!
// 02-10-2005		-special line draw mode added (single bit per horizontal line)
//				 this completes the blitter (but some bugs may still remain...)
// 17-10-2005		-fixed typo in sensitivity list of always block
// 22-01-2006		-fixed bug in special line draw mode
// 25-01-2006		-added bblck signal	
// 14-02-2006		-improved bblck table
// 07-07-2006		-added some comments

// 25-12-07 Redskulldc : Start adding ECS components 

module blitter(clk,reset,reqdma,ackdma,bzero,bbusy,bblck,horbeam,wr,datain,dataout,regaddressin,addressout);
input 	clk;	 				//bus clock
input 	reset;	 			//reset
output	reqdma;				//blitter requests dma cycle
input	ackdma;				//agnus dma priority logic grants dma cycle
output	bzero;				//blitter zero status
output	bbusy;				//blitter busy status
output	bblck;				//blitter is blocking cpu, cpu may not access chip bus
input	horbeam;				//least significant bit of horbeam[]
output	wr;					//write (blitter writes to memory)
input 	[15:0] datain;	    		//bus data in
output	[15:0] dataout;		//bus data out
input 	[8:1] regaddressin;		//register address inputs
output 	[20:1] addressout; 		//chip address outputs

//register names and adresses		
parameter BLTCON0=9'h040;
parameter BLTCON1=9'h042;
parameter BLTAFWM=9'h044;
parameter BLTALWM=9'h046;
parameter BLTADAT=9'h074;
parameter BLTBDAT=9'h072;
parameter BLTCDAT=9'h070;
parameter BLTSIZE=9'h058;
parameter BLTSIZV=9'h05C;		//ECS   new  Blitter V size (for 15 bit vertical start)
parameter BLTSIZH=9'h05E;		//ECS   new  Blitter H size and start (for 11 bit H size)

//channel select codes
parameter CHA=2'b00;			//channel A
parameter CHB=2'b01;			//channel B
parameter CHC=2'b10;			//channel C
parameter CHD=2'b11;		    	//channel D

//local signals
reg		bzero;				//see above
reg 		bblck;				//see above

reg		[15:0]bltcon0;			//blitter control register 0
reg		[15:0]bltcon1;			//blitter control register 1
reg		[15:0]bltafwm;			//blitter first word mask for source A
reg		[15:0]bltalwm;			//blitter last word mask for source A
reg		[15:0]bltadat;			//blitter source A preload data register
reg		[15:0]bltbdat;			//blitter source B preload data register
reg		[15:0]bltaold;			//blitter source A 'old' data
reg		[15:0]bltbold;			//blitter source B 'old' data
reg		[15:0]ahold;			//A holding register
reg		[15:0]bhold;			//B holding register
reg		[15:0]chold;			//C holding register
reg		[15:0]dhold;			//D holding register
//reg		[5:0]bltwidth;			//blitsize number of words (width)		--OCS
//reg		[9:0]bltheight;			//blitsize number of lines (height)		--OCS
reg		[10:0]bltwidth;			//blitsize number of words (width = 11)
reg		[14:0]bltheight;		//blitsize number of lines (height = 15)

reg		[4:0]bltstate;			//blitter state
reg		[4:0]bltnext;			//blitter next state

reg		ife;					//enable inclusive fill mode
reg		efe;					//enable exclusive fill mode
reg		desc;				//descending mode
reg		bpa;					//bypass preload register for channel A
reg		bpb;					//bypass preload register for channel B
reg		tmb;					//channel B is in texturing mode
reg		sing;				//single bit per horizontal line (special line mode)
reg		enable;				//blit cycle enable signal

reg		[1:0]chs;				//channel select(A,B,C,D)
wire		ame;					//instruct address generator to add or subtract modulo	(enable)
reg		ams;					//instruct address generator to subtract modulo
wire		ape;					//instruct address generator increment or decrement pointer (enable)
reg		apd;	  				//instruct address generator to decrement pointer
wire		amb;					//instruct address generator to only use modulo B and C
wire		sbz;					//set blitter zero bit
wire		incash;				//increment ASH (line mode)
wire		decash;				//decrement ASH (line mode)
wire		rlb;					//rotate B holding register to the left (line mode)
reg		fpl;					//first pixel on horizontal line signal used for special line draw mode (SING) 	

reg		start;				//blitter is started by write to BLTSIZE or BLTSIZH (ECS)
wire		fwt;					//first word time
wire		lwt;					//last word time
reg		bbusyd;				//bbusy delayed for channel D modulo handling
reg		lwtd;				//last word time delayed for channel D modulo handling
wire		nml;					//no more lines to blit (blit is done), only valid during first word time
wire		signout;				//new accumulator sign calculated by address generator (line mode)
reg		sign;				//current sign of accumulator (line mode)
reg		plr;					//move pointer left or right due to shifter roll over (line mode)
        
//--------------------------------------------------------------------------------------

//bltcon0	ASH part
//In order to move the $8000 value in BLTADAT around during line mode
//the value of ASH can be changed by the main controlling state machine
always @(posedge clk)
	if(reset)
		bltcon0[15:12]<=0;
	else if(enable && incash)//increment (used in line mode)
		bltcon0[15:12]<=bltcon0[15:12]+{decash,decash,decash,1'b1};
	else if(enable && decash)//decrement (used in line mode)
		bltcon0[15:12]<=bltcon0[15:12]+{decash,decash,decash,1'b1};
	else if (regaddressin[8:1]==BLTCON0[8:1])//written from bus (68000 or copper)
		bltcon0[15:12]<=datain[15:12];

//generate plr signal, this is used to detect if we have to increment/decrement channel C/D pointers
//during line mode (sort of shifter carry out/roll over out)
always @(bltcon0 or bltcon1)
	if(bltcon1[4])//octant 0,3,4,7
		plr=(bltcon0[15]&bltcon0[14]&bltcon0[13]&bltcon0[12]&!bltcon1[2]) | (!bltcon0[15]&!bltcon0[14]&!bltcon0[13]&!bltcon0[12]&bltcon1[2]);
	else//octant 1,2,5,6
 		plr=(bltcon0[15]&bltcon0[14]&bltcon0[13]&bltcon0[12]&!bltcon1[3]) | (!bltcon0[15]&!bltcon0[14]&!bltcon0[13]&!bltcon0[12]&bltcon1[3]);

//bltcon0 USE and LF part
always @(posedge clk)
	if(reset)
		bltcon0[11:0]<=0;
	else if (regaddressin[8:1]==BLTCON0[8:1])
		bltcon0[11:0]<=datain[11:0];

//writing of bltcon1 from bus
always @(posedge clk)
	if(reset)
		bltcon1[15:0]<=0;
	else if (regaddressin[8:1]==BLTCON1[8:1])
		bltcon1[15:0]<=datain[15:0];

//--------------------------------------------------------------------------------------

//writing of bltafwm from bus
always @(posedge clk)
	if(reset)
		bltafwm[15:0]<=0;
	else if (regaddressin[8:1]==BLTAFWM[8:1])
		bltafwm[15:0]<=datain[15:0];

//writing of bltalwm from bus
always @(posedge clk)
	if(reset)
		bltalwm[15:0]<=0;
	else if (regaddressin[8:1]==BLTALWM[8:1])
		bltalwm[15:0]<=datain[15:0];

//writing of bltadat from bus	(preload)
always @(posedge clk)
	if(reset)
		bltadat[15:0]<=0;
	else if(regaddressin[8:1]==BLTADAT[8:1])
		bltadat[15:0]<=datain[15:0];

//writing of bltbdat from bus (preload)
always @(posedge clk)
	if(reset)
		bltbdat[15:0]<=0;
	else if(regaddressin[8:1]==BLTBDAT[8:1])
		bltbdat[15:0]<=datain[15:0];

//--------------------------------------------------------------------------------------

//A and B channel processing chain
//these channels share a single barrel shifter to save slices
//The channel B holding register can be directly loaded by writing from the bus
//to BLTBDAT. 

//local signals
reg		[15:0]amux;
reg		[15:0]amask;
reg		[15:0]bmux;
wire		[15:0]newmux;
wire		[15:0]oldmux;
wire		[3:0]shmux;
wire		[15:0]shiftout;

//channel A mask select
always @(bltafwm or bltalwm or fwt or lwt)
	if(fwt && lwt)
		amask[15:0]=bltafwm[15:0]&bltalwm[15:0];
	else if(fwt)
		amask[15:0]=bltafwm[15:0];	
	else if(lwt)
		amask[15:0]=bltalwm[15:0];
	else
		amask[15:0]=16'b1111111111111111;
		
//channel A source select mux
always @(bltadat or datain or amask or bpa)
	if(bpa)
		amux[15:0]=datain[15:0]&amask[15:0];
	else
		amux[15:0]=bltadat[15:0]&amask[15:0];

//channel A 'old' register
always @(posedge clk)
	if(!bbusy)
		bltaold[15:0]<=0;
	else if(enable && (chs[1:0]==CHA[1:0]))
		bltaold[15:0]<=amux[15:0];

//channel A holding register
always @(posedge clk)
	if(enable && (chs[1:0]==CHA[1:0]))
		ahold[15:0]<=shiftout[15:0];

//channel B source select mux
always @(bltbdat or datain or bpb or regaddressin)
	if(bpb || (regaddressin[8:1]==BLTBDAT[8:1]))
		bmux[15:0]=datain[15:0];
	else
		bmux[15:0]=bltbdat[15:0];
		
//channel B 'old' register
always @(posedge clk)
	if(!bbusy)
		bltbold[15:0]<=0;
	else if(enable && (chs[1:0]==CHB[1:0]))
		bltbold[15:0]<=bmux[15:0];

//channel B holding register
always @(posedge clk)
	if(enable && rlb)//rotate register to the left (line mode)
		bhold[15:0]<={bhold[14:0],bhold[15]};
	else if((enable && (chs[1:0]==CHB[1:0])) || (regaddressin[8:1]==BLTBDAT[8:1]))
		bhold[15:0]<=shiftout[15:0];
	

//multiplexed barrel shifter for channel A and channel B
//the multiplexer is controlled by lhs (holding register select)
assign newmux[15:0]=(chs[1:0]==CHA[1:0])?amux[15:0]:bmux[15:0];
assign oldmux[15:0]=(chs[1:0]==CHA[1:0])?bltaold[15:0]:bltbold[15:0];
assign shmux[3:0]=(chs[1:0]==CHA[1:0])?bltcon0[15:12]:bltcon1[15:12];
bltshift blts1 (	.desc(desc),
				.sh(shmux),
				.newm(newmux),
				.old(oldmux),
				.out(shiftout) );

//--------------------------------------------------------------------------------------

//C channel processing chain
//This channel is very simple as it has only a holding register
//the holding register can be preloaded from the bus or loaded by dma

//channel C holding register
always @(posedge clk)
	if((enable && (chs[1:0]==CHC[1:0])) || (regaddressin[8:1]==BLTCDAT[8:1]))
		chold[15:0]<=datain[15:0];

//--------------------------------------------------------------------------------------

//D channel processing chain
//The D channel is the output channel. The data from sources A,B and C are
//combined here by the minterm generator. Then the data is fed through the
//fill logic and loaded into the channel D holding register.

//local signals
reg		[15:0]ain;		//A channel input for minterm generator
reg		[15:0]bin; 		//B channel input for minterm generator
wire		[15:0]mintermout;  	//minterm generator output
wire		[15:0]fillout;		//fill logic output
wire		fci;				//fill carry in
wire		fco;	    			//fill carry out to next word
reg		fcy;	   			//fill carry latch

//minterm A channel input select: special line draw mode or normal blit mode
always @(sing or fpl or ahold)
	if(sing && !fpl)
		ain[15:0]=16'h0000;
	else
		ain[15:0]=ahold[15:0];

//minterm A channel input select: line texturing mode or normal blit mode
always @(tmb or bhold)
	if(tmb)//nomal line draw mode (apply texture)
		bin[15:0]={bhold[0],bhold[0],bhold[0],bhold[0],bhold[0],bhold[0],bhold[0],bhold[0],bhold[0],bhold[0],bhold[0],bhold[0],bhold[0],bhold[0],bhold[0],bhold[0]};
	else//normal blit mode
		bin[15:0]=bhold[15:0];	

//minterm generator instantation
bltminterm bltmt1 (	.lf(bltcon0[7:0]),
				.ain(ain[15:0]),
				.bin(bin[15:0]),
				.cin(chold[15:0]),
				.out(mintermout[15:0])	);
				
//fill logic instantiation
bltfill bltfl1 (	.ife(ife),
				.efe(efe),
				.fci(fci),
				.fco(fco),
				.in(mintermout[15:0]),
				.out(fillout[15:0])		);

//fill carry control
assign fci=(fwt)?bltcon1[2]:fcy;
always @(posedge clk)
	if(enable && (chs[1:0]==CHD[1:0]))
		fcy<=fco;

//channel D holding register
always @(posedge clk)
	if(enable && (chs[1:0]==CHD[1:0]))
		dhold[15:0]<=fillout[15:0];		

//channel D data output gate
assign dataout[15:0]=(ackdma && (chs[1:0]==CHD))?dhold[15:0]:16'h0000;
assign wr=(chs[1:0]==CHD)?1:0;

//channel D blitter zero detect
always @(posedge clk)
	if(reset || sbz)
		bzero<=1;//reset blitter zero detector
	else if(enable && (chs[1:0]==CHD[1:0]) && (dhold[15:0]!=16'h0000))
		bzero<=0;//non-zero output of channel D detected

//--------------------------------------------------------------------------------------

//Blitsize counter and control
//This module keeps track of how many lines and words
//we have to blit.
//The main register bltsize is loaded from the bus and 
//then decremented during a channel D cycle (chs==CHD)
//In line mode, channel D cycle happens twice for every pixel,
//hence bltwidth is always 2 in line mode.
//This module also generates <fwt> (first word time),
//<lwt> (last word time) and <nml> (no more lines to blit)
//Note that <nml> is only valid when <fwt> is true. This is to allow
//heights of 1024 lines, which are written as 10'b0000000000
//by the software. (see amiga hardware reference manual)
//<start> is also controlled here (used to start the blitter state machine)
//<bbusy1d> and <lwtd> are delayed version for channel D (pipeline delay)

//reg		[5:0]bltwcount;		//--OCS
reg		[10:0]bltwcount;

//start control
always @(posedge clk)
	if(reset)
		start<=0;
	else if((regaddressin[8:1]==BLTSIZE[8:1])||(regaddressin[8:1]==BLTSIZH[8:1])) //blitter is started by write to BLTSIZE/BLTSIZH
		start<=1;
	else if(bbusy)//state machine has got the message, we can clear start now
		start<=0;

//bltwidth register (lower 6 bits of BLTSIZE)	//Pad to 11bits for ECS
//or bltwidth register (lower 11 bits of BLTSIZH)		--ECS new
always @(posedge clk)
	if(regaddressin[8:1]==BLTSIZE[8:1])
		bltwidth[10:0]<= {5'b00000,datain[5:0]};
	else if(regaddressin[8:1]==BLTSIZH[8:1])
		bltwidth[10:0]<= datain[10:0];
	
//bltwidth counter			
always @(posedge clk)
	if((regaddressin[8:1]==BLTSIZE[8:1])||(regaddressin[8:1]==BLTSIZH[8:1])) //blitsize or blitsizh written, go to first word time
		bltwcount[10:0]<= 11'b00000000001;
	else if(enable && (chs[1:0]==CHD[1:0]))//decrement blitsize counter
	begin
		if(lwt)//if last word time, go to first word time
			bltwcount[10:0]<= 11'b00000000001;
		else//else go to next word
			bltwcount[10:0]<=bltwcount[10:0]+1'b1;
	end

//bltheight register (upper 10 bits of BLTSIZE, or first 15bits of BLTSIZV) and counter 
always @(posedge clk)
	if(regaddressin[8:1]==BLTSIZE[8:1])//blitheight loaded by write to bltsize
		bltheight[14:0]<= {5'b00000,datain[15:6]};			//pad for ECS
	else if(regaddressin[8:1]==BLTSIZV[8:1])//blitheight loaded by write to bltsizh
		bltheight[14:0]<=datain[14:0];
	else if(enable && lwt && (chs[1:0]==CHD[1:0]))//if last word in this line decrement height counter
		bltheight[14:0]<=bltheight[14:0]-1'b1;

//generate fwt (first word time) signal
assign fwt=(bltwcount[10:0]==11'b00000000001)?1:0;

//generate lwt (last word time) signal
assign lwt=(bltwcount[10:0]==bltwidth[10:0])?1:0;

//generate lwtd (delayed last word time) signal 
//and bbusyd1 (delayed bbusy1) signal
always @(posedge clk)
	if((regaddressin[8:1]==BLTSIZE[8:1])||(regaddressin[8:1]==BLTSIZH[8:1]))//reset signals upon BLTSIZE or BLTSIZH write, just to be sure
	begin
		lwtd<=1'b0;
		bbusyd<=1'b0;
	end
	else if(enable && (chs[1:0]==CHD[1:0]))
	begin
		lwtd<=lwt;
		bbusyd<=bbusy;
	end

//generate nml (no more lines) signal (only valid during first word time)
assign nml=((bltheight[14:0]==15'b000000000000000) && fwt)?1:0;

//--------------------------------------------------------------------------------------

//instantiate address generator
bltaddress bltad1 (	.clk(clk),
				.reset(reset),
				.enable(enable),
				.modb(amb),
				.chs(chs),
				.alu({ame,ams,ape,apd}),
				.signout(signout),
				.datain(datain),
				.regaddressin(regaddressin),
				.addressout(addressout)	);

//--------------------------------------------------------------------------------------

//Blitter main controller logic
//This code controls the blitter A, B, C and D channel
reg	   	[4:0]scn;		//various signals vector used by main state machine
reg		[3:0]acn;	    	//address/alu control vector used by main state machine

//main states
parameter	BLT_DONE=0;
parameter BLT_NB_1=1;
parameter BLT_NB_2=2;
parameter BLT_NB_3=3;
parameter BLT_NB_4=4;
parameter BLT_LP_1=5;
parameter BLT_LP_2=6;
parameter BLT_LB_1=7;
parameter BLT_LB_2=8;
parameter BLT_LB_3=9;
parameter BLT_LB_4=10;
				    
//Normal/line mode settings
always @(bltcon1[0] or bltcon0[11:10] or chs)
begin
	if(bltcon1[0])//line mode
	begin
		bpa=0;//channel A uses preload
		bpb=0;//channel B uses preload
		tmb=1;//channel B is in texturing mode
		efe=0;//fill mode disabled
		ife=0;//fill mode disabled
		desc=0;//ascending mode selected
		sing=bltcon1[1]&bltcon1[4];//special line mode according to bltcon
		if(chs[1:0]==CHA[1:0])//in line mode, channel A is accumulator and modulo's are always added
		begin
			ams=0;
			apd=0;
		end
		else//for all other channels (C and D) it depends on the octant
		begin
			if(bltcon1[4])//octant 0,3,4,7
			begin
				ams=bltcon1[3];//up or down ?
				apd=bltcon1[2];//left or right ?
			end
			else//octant 1,2,5,6
			begin
				ams=bltcon1[2];//up or down ?
				apd=bltcon1[3];//left or right ?
			end
		end
	end
	else//normal mode
	begin
		bpa=bltcon0[11];//if USEA, do not use channel A preload
		bpb=bltcon0[10];//if USEB, do not use channel B preload
		tmb=0;//channel B is in normal mode
		efe=bltcon1[4];//fill mode according to bltcon
		ife=bltcon1[3];//fill mode according to bltcon
		desc=bltcon1[1];//descending mode according to bltcon
		sing=0;//no special line mode
		ams=bltcon1[1];//modulo's are subtracted if descending mode
		apd=bltcon1[1];//pointers are decremented if descending mode
	end
end

//sign bit handling	and fpl bit handling
always @(posedge clk)
	if(!bbusyd)//if blitter not busy, copy sign from bltcon and preset fpl
	begin
		sign<=bltcon1[6];
		fpl<=1;
	end
	//update sign flag and fpl bit (if first D cycle has happened and channel A cycle + dma enabled and line mode)
	else if(enable && bbusyd && bltcon0[11] && bltcon1[0] && (chs[1:0]==CHA[1:0]))
	begin
		sign<=signout;
		fpl<=~sign;
	end

//enable signal control 
//enable controls most of the latches in the blitter
//this is a very important signal
always @(horbeam or bbusy or reqdma or ackdma)
	if(reqdma && ackdma)//dma requested and granted, do external (dma) cycle
		enable=1;
	else	if(!reqdma && bbusy && horbeam)//do internal cycle
		enable=1;
	else//do nothing (blitter not busy)
		enable=0;	
		
//bblck control
//In order to let this blitter run at the same speed as in a real Amiga, it must block the cpu
//in some cases. Apparently (according to winuae sources), cycles that are normally internal
//(channel A/D when USEA/USED=0), DO allocate a bus slot when channel A is enabled in blitter nasty mode.
//This effectively blocks the cpu from the chip bus. Also, when fill mode is enabled but channel C is not (USEC=0)
//we also get some extra idle cycles (cpu is not blocked).
//In line mode, blitter never blocks the cpu.
//the following logic handles the bblck signal
always @(bltcon0 or bltcon1 or bbusy or bbusyd)
begin
	if(bbusy&bbusyd)//blitter busy and not first cycle?
		//{FILL,LINE,USEA,USEC}
		case({bltcon1[3]|bltcon1[4],bltcon1[0],bltcon0[11],bltcon0[9]})
			4'b0000: bblck=0;
			4'b0001: bblck=0;
			4'b0010: bblck=1;
			4'b0011: bblck=1;
			4'b0100: bblck=0;//LINE MODE
			4'b0101: bblck=0;//LINE MODE
			4'b0110: bblck=0;//LINE MODE
			4'b0111: bblck=0;//LINE MODE
			4'b1000: bblck=0;
			4'b1001: bblck=0;
			4'b1010: bblck=0;
			4'b1011: bblck=1;
			4'b1100: bblck=0;//LINE MODE
			4'b1101: bblck=0;//LINE MODE
			4'b1110: bblck=0;//LINE MODE
			4'b1111: bblck=0;//LINE MODE
		endcase						  	
	else//blitter not busy
		bblck=0;
end

//state machine outputs
//we use a couple of vectors here to keep the statemachine readable
//various signals control
assign incash=scn[4];
assign decash=scn[3];
assign rlb=scn[2];
assign sbz=scn[1];
assign bbusy=scn[0];
//address contol
assign reqdma=acn[3]&horbeam;//only request DMA during odd slots
assign amb=acn[2];
assign ame=acn[1];
assign ape=acn[0];

//main state machine
always @(posedge clk)
	if(reset)//master reset
		bltstate<=BLT_DONE;
	else if(enable || (start && !bbusy))//blitter next cycle if (enable) or (start pulse while not yet busy)
		bltstate<=bltnext;
always @(bltstate or bltcon0 or lwt or lwtd or bbusyd or bltcon1 or sign or nml or plr)
begin
	case(bltstate)
		BLT_DONE://blitter is done
			begin
				//-----IDRZB
				scn=5'b00000;
				//-----RBMA
				acn=4'b0x00;
				chs=CHB;
				if(!bltcon1[0])//start normal blit
					bltnext=BLT_NB_1;
				else//start line blit
					bltnext=BLT_LP_1;
			end

		BLT_LP_1://line blit preparation cycle 1 (load channel B 'old' register with texture)
			begin
				acn=4'b0x00;
				scn=5'b00001;
				chs=CHB;
				bltnext=BLT_LP_2;	
 			end

		BLT_LP_2://line blit preparation cycle 2 (load channel B holding register with texture)
			begin
				acn=4'b0x00;
				scn=5'b00001;
				chs=CHB;
				bltnext=BLT_LB_1;	
 			end

		BLT_LB_1://line blit cycle 1 (check accumulator, load channel A and update sign)
			begin
				acn={1'b0,sign,bbusyd,1'b0};//only update accumulator if not first cycle, sign selects modulo A/B	
				scn=5'b00001;
				chs=CHA;
				if(nml && bbusyd)//check if blit is done
					bltnext=BLT_DONE;
				else
					bltnext=BLT_LB_2;	
 			end

		BLT_LB_2://line blit cycle 2 (load channel C)
			begin
				if(bltcon1[4])
					acn={bltcon0[9],1'b0,~sign,plr};
				else
					acn={bltcon0[9],2'b01,~sign&plr};
				scn=5'b00001;
				chs=CHC;
				bltnext=BLT_LB_3;	
 			end

		BLT_LB_3://line blit cycle 3 (load channel D and point to next texture bit)
			begin
				acn=4'b0x00;
				scn=5'b00101;
				chs=CHD;
				bltnext=BLT_LB_4;	
 			end

		BLT_LB_4://line blit cycle 4 (write channel D and update shifter channel A)
			begin
				if(bltcon1[4])
				begin
					acn={bltcon0[9],1'b1,~sign,plr};//modulo C is used for channel D also in line mode
					scn={~bltcon1[2],bltcon1[2],3'b001};
				end
				else
				begin
					acn={bltcon0[9],2'b11,~sign&plr};
					scn={~bltcon1[3]&~sign,bltcon1[3]&~sign,3'b001};
				end
				chs=CHD;
				if(nml)//PANIC! this shouldn't happen but just in case...
					bltnext=BLT_DONE;
				else
					bltnext=BLT_LB_1;	
 			end
 
		BLT_NB_1://normal blit cycle 1
			begin
				if(nml && bbusyd)//blit is done, handle data still in pipeline
				begin
					if(bltcon0[8])//DMA
						acn={2'b10,lwtd,1'b1};
					else//internal
						acn=4'b0x00;
					//-----IDRZB
					scn=5'b00001;	
					chs=CHD;
					bltnext=BLT_DONE;
				end
				else//else handle channel A
				begin
					if(bltcon0[11])//DMA
						acn={2'b10,lwt,1'b1};
					else//internal
						acn=4'b0x00;
					//-----IDRZB
					scn=5'b00001;
					chs=CHA;
					if(bltcon0[10])
						bltnext=BLT_NB_2;
					else if(bltcon0[9])
						bltnext=BLT_NB_3;
					else
						bltnext=BLT_NB_4;	
				end
			end

		BLT_NB_2://normal blitter operation cycle 2 (always dma, skipped otherwise)
			begin
				acn={2'b10,lwt,1'b1};
				scn=5'b00001;
				chs=CHB;
				if(bltcon0[9])
					bltnext=BLT_NB_3;
				else
					bltnext=BLT_NB_4;	
			end

		BLT_NB_3://normal blitter operation cycle 3 (always dma, skipped otherwise)
			begin
				acn={2'b10,lwt,1'b1};
				scn=5'b00001;
				chs=CHC;
				bltnext=BLT_NB_4;	
			end

		BLT_NB_4://normal blitter operation cycle 4
			begin
				if(bltcon0[8] && bbusyd)//DMA (only if not first cycle)
					acn={2'b10,lwtd,1'b1};
				else//internal
					acn=4'b0x00;
				scn={3'b000,~bbusyd,1'b1};//if first (dummy) cycle, set blitter zero flag	
				chs=CHD;
				bltnext=BLT_NB_1;	
			end

		default://unknown state, go back to reset state
			begin
				//-----IDRZB
				scn=5'bxxxx1;
				//-----RBMA
				acn=4'b0xxx;
				chs=2'bxx;
				bltnext=BLT_DONE;
			end
	endcase			
end

//--------------------------------------------------------------------------------------

endmodule

//--------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------

//Blitter barrel shifter
//This module can shift 0-15 positions/bits to the right (normal mode) or to the left
//(descending mode). Inputs are two words, <new> and <old>.
//For example, when shifting <new> to the right,
//the bits to the left are filled with <old>. The bits of <new> that 
//are shifted out are discarded.  
module bltshift(desc,sh,newm,old,out);
input	desc;				//select descending mode (shift to the left)
input	[3:0]sh;				//shift value (0 to 15)
input 	[15:0] newm;	    		//barrel shifter data in
input 	[15:0] old;	    		//barrel shifter data in
output	[15:0] out;			//barrel shifter data out

//local signals
reg		[15:0]out;			//see above
wire		[30:0]bshiftin;		//barrel shifter input
wire		[3:0]bsh;				//barrel shift value

//cross multiplexer feeding barrelshifter
assign bshiftin[30:0]=(desc)?{newm[15:0],old[15:1]}:{old[14:0],newm[15:0]};

//shift value generator for barrel shifter
assign bsh[3:0]=(desc)?(~sh[3:0]):sh[3:0];

//actual barrel shifter
always @(bsh or bshiftin)
	case(bsh[3:0])
		0:	out[15:0]=bshiftin[15:0];
		1:	out[15:0]=bshiftin[16:1];
		2:	out[15:0]=bshiftin[17:2];
		3:	out[15:0]=bshiftin[18:3];
		4:	out[15:0]=bshiftin[19:4];
		5:	out[15:0]=bshiftin[20:5];
		6:	out[15:0]=bshiftin[21:6];
		7:	out[15:0]=bshiftin[22:7];
		8:	out[15:0]=bshiftin[23:8];
		9:	out[15:0]=bshiftin[24:9];
		10:	out[15:0]=bshiftin[25:10];
		11:	out[15:0]=bshiftin[26:11];
		12:	out[15:0]=bshiftin[27:12];
		13:	out[15:0]=bshiftin[28:13];
		14:	out[15:0]=bshiftin[29:14];
		15:	out[15:0]=bshiftin[30:15];
 	endcase

endmodule

//--------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------

//Blitter minterm function generator
//The minterm function generator takes <ain>,<bin> and <cin> 
//and checks every logic combination against the LF control byte.
//If a combination is marked as 1 in the LF byte, the ouput will
//also be 1, else the output is 0.
module bltminterm(lf,ain,bin,cin,out);
input	[7:0]lf;				//LF control byte
input	[15:0]ain;			//A channel in
input	[15:0]bin;			//B channel in
input	[15:0]cin;			//C channel in
output	[15:0]out;			//function generator output

reg		[15:0]mt0;			//minterm 0
reg		[15:0]mt1;			//minterm 1
reg		[15:0]mt2;			//minterm 2
reg		[15:0]mt3;			//minterm 3
reg		[15:0]mt4;			//minterm 4
reg		[15:0]mt5;			//minterm 5
reg		[15:0]mt6;			//minterm 6
reg		[15:0]mt7;			//minterm 7

//Minterm generator for each bit. The code inside the loop 
//describes one bit. The loop is 'unrolled' by the 
//synthesizer to cover all 16 bits in the word.
integer j;
always @(ain or bin or cin or lf)
	for(j=15;j>=0;j=j-1)
	begin
		mt0[j]=(~ain[j])&(~bin[j])&(~cin[j])&lf[0];
		mt1[j]=(~ain[j])&(~bin[j])&( cin[j])&lf[1];
		mt2[j]=(~ain[j])&( bin[j])&(~cin[j])&lf[2];
		mt3[j]=(~ain[j])&( bin[j])&( cin[j])&lf[3];
		mt4[j]=( ain[j])&(~bin[j])&(~cin[j])&lf[4];
		mt5[j]=( ain[j])&(~bin[j])&( cin[j])&lf[5];
		mt6[j]=( ain[j])&( bin[j])&(~cin[j])&lf[6];
		mt7[j]=( ain[j])&( bin[j])&( cin[j])&lf[7];
	end

//Generate function generator output by or-ing all
//minterms together.
assign out=mt0|mt1|mt2|mt3|mt4|mt5|mt6|mt7;

endmodule		

//--------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------

//Blitter fill logic
//The fill logic module has 2 modes, inclusive fill and exclusive fill.
//Both share the same xor operation but in inclusive fill mode,
//the output of the xor-filler is or-ed with the input data.	
module bltfill(ife,efe,fci,fco,in,out);
input	ife;					//inclusive fill enable
input	efe;					//exclusive fill enable
input	fci;					//fill carry input
output	fco;					//fill carry output
input	[15:0]in;				//data in
output	[15:0]out;			//data out

//local signals
reg		[15:0]out;
reg		[15:0]carry;

//generate all fill carry's
integer j;
always @(fci or in[0])//least significant bit
	carry[0]=fci^in[0];		
always @(in or carry)//rest of bits
	for(j=1;j<=15;j=j+1)
		carry[j]=carry[j-1]^in[j];

//fill carry output
assign fco=carry[15];

//fill data output
always @(ife or efe or carry or in)
	if(efe)//exclusive fill
		out[15:0]=carry[15:0];
	else if(ife)//inclusive fill
		out[15:0]=carry[15:0]|in[15:0];
	else//bypass, no filling
		out[15:0]=in[15:0];

endmodule

//--------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------

//Blitter address generator
//This module generates the addresses for blitter DMA
//It has 4 21bit pointer registers, 4 16bit modulo 
//registers and an ALU that can add and subtract
//alu function codes bits [3:2]:
//00 = bypass (no operation)
//01 = bypass (no operation)
//10 = add modulo 
//11 = subtract modulo 
//alu function codes bits [1:0]:
//00 = bypass (no operation)
//01 = bypass (no operation)
//10 = add 2 (next word)
//11 = subtract 2 (previous word)
//
//when modb=1, address pointer selection remains unchanged but modulo selection is as follows:
//chs[1:0]	modb=0	modb=1
//2'b00		A		B
//2'b01		B		B
//2'b10 		C		C
//2'b11 		D		C

module bltaddress(clk,reset,enable,modb,chs,alu,signout,datain,regaddressin,addressout);
input	clk;					//bus clock
input	reset;				//reset
input	enable;				//cycle enable input
input	modb;				//always select modulo B or C (dependening of chs[1])
input	[1:0]chs;				//channel select
input	[3:0]alu;				//ALU function select
output	signout;				//sign output (used for line mode)
input	[15:0]datain;			//bus data in
input	[8:1]regaddressin;		//register address input
output	[20:1]addressout;		//generated address out

//register names and addresses
parameter BLTAMOD=9'h064;
parameter BLTBMOD=9'h062;
parameter BLTCMOD=9'h060;
parameter BLTDMOD=9'h066;
parameter	BLTAPTH=9'h050;
parameter	BLTAPTL=9'h052;
parameter	BLTBPTH=9'h04c;
parameter	BLTBPTL=9'h04e;
parameter	BLTCPTH=9'h048;
parameter	BLTCPTL=9'h04a;
parameter	BLTDPTH=9'h054;
parameter	BLTDPTL=9'h056;

//local signals
reg		[20:1]addressout;		//see above

reg		[15:1]bltamod;			//blitter modulo for source A
reg		[15:1]bltbmod;			//blitter modulo for source B
reg		[15:1]bltcmod;			//blitter modulo for source C
reg		[15:1]bltdmod;			//blitter modulo for destination D
reg		[20:1]bltapt;			//blitter pointer A
reg		[20:1]bltbpt;			//blitter pointer B
reg		[20:1]bltcpt;			//blitter pointer C
reg		[20:1]bltdpt;			//blitter pointer D

reg		[20:1]newpt;			//new pointer				
reg		[15:1]modulo;			//modulo

//--------------------------------------------------------------------------------------

//writing of bltamod from bus
always @(posedge clk)
	if(reset)
		bltamod[15:1]<=0;
	else if (regaddressin[8:1]==BLTAMOD[8:1])
		bltamod[15:1]<=datain[15:1];

//writing of bltbmod from bus
always @(posedge clk)
	if(reset)
		bltbmod[15:1]<=0;
	else if (regaddressin[8:1]==BLTBMOD[8:1])
		bltbmod[15:1]<=datain[15:1];

//writing of bltcmod from bus
always @(posedge clk)
	if(reset)
		bltcmod[15:1]<=0;
	else if (regaddressin[8:1]==BLTCMOD[8:1])
		bltcmod[15:1]<=datain[15:1];

//writing of bltdmod from bus
always @(posedge clk)
	if(reset)
		bltdmod[15:1]<=0;
	else if (regaddressin[8:1]==BLTDMOD[8:1])
		bltdmod[15:1]<=datain[15:1];

//--------------------------------------------------------------------------------------

//pointer bank input multiplexer
wire	[20:1]ptin;
assign ptin[20:1]=(enable)?newpt[20:1]:{datain[4:0],datain[15:1]};

//writing of blitter pointer A
always @(posedge clk)
	if((enable && (chs[1:0]==2'b00)) || (regaddressin[8:1]==BLTAPTH[8:1]))
		bltapt[20:16]<=ptin[20:16];
always @(posedge clk)
	if((enable && (chs[1:0]==2'b00)) || (regaddressin[8:1]==BLTAPTL[8:1]))
		bltapt[15:1]<=ptin[15:1];

//writing of blitter pointer B
always @(posedge clk)
	if((enable && (chs[1:0]==2'b01)) || (regaddressin[8:1]==BLTBPTH[8:1]))
		bltbpt[20:16]<=ptin[20:16];
always @(posedge clk)
	if((enable && (chs[1:0]==2'b01)) || (regaddressin[8:1]==BLTBPTL[8:1]))
		bltbpt[15:1]<=ptin[15:1];

//writing of blitter pointer C
always @(posedge clk)
	if((enable && (chs[1:0]==2'b10)) || (regaddressin[8:1]==BLTCPTH[8:1]))
		bltcpt[20:16]<=ptin[20:16];
always @(posedge clk)
	if((enable && (chs[1:0]==2'b10)) || (regaddressin[8:1]==BLTCPTL[8:1]))
		bltcpt[15:1]<=ptin[15:1];

//writing of blitter pointer D
always @(posedge clk)
	if((enable && (chs[1:0]==2'b11)) || (regaddressin[8:1]==BLTDPTH[8:1]))
		bltdpt[20:16]<=ptin[20:16];
always @(posedge clk)
	if((enable && (chs[1:0]==2'b11)) || (regaddressin[8:1]==BLTDPTL[8:1]))
		bltdpt[15:1]<=ptin[15:1];

//--------------------------------------------------------------------------------------

//address output multiplexer
always @(chs or bltapt or bltbpt or bltcpt or bltdpt)
	case(chs[1:0])
		2'b00://channel A
			addressout[20:1]=bltapt;
		2'b01://channel B
			addressout[20:1]=bltbpt;
		2'b10://channel C
			addressout[20:1]=bltcpt;
		2'b11://channel D
			addressout[20:1]=bltdpt;
	endcase
	    
//--------------------------------------------------------------------------------------

//modulo multiplexer
wire [1:0]msel;
assign msel[1:0]=(modb)?{chs[1],~chs[1]}:chs[1:0];
always @(msel or bltamod or bltbmod or bltcmod or bltdmod)
	case(msel[1:0])
		2'b00://channel A
			modulo[15:1]=bltamod[15:1];
		2'b01://channel B
			modulo[15:1]=bltbmod[15:1];
		2'b10://channel C
			modulo[15:1]=bltcmod[15:1];
		2'b11://channel D
			modulo[15:1]=bltdmod[15:1];
	endcase

//--------------------------------------------------------------------------------------

//ALU
//The ALU calculates a new address pointer based on the value of modulo
//and the selected ALU operation
reg [20:1]npt;

//first adder/subtracter
always @(alu or addressout)
	case(alu[1:0])
		2'b10:	npt[20:1]=addressout[20:1]+20'h1;	// + 1
		2'b11:	npt[20:1]=addressout[20:1]-20'h1;	// - 1 
		default:	npt[20:1]=addressout[20:1];		// bypass 	
	endcase

//second adder/subtracter
always @(alu or npt or modulo)
	case(alu[3:2])
		2'b10:	newpt[20:1]=npt[20:1]+{modulo[15],modulo[15],modulo[15],modulo[15],modulo[15],modulo[15:1]};	// + modulo
		2'b11:	newpt[20:1]=npt[20:1]-{modulo[15],modulo[15],modulo[15],modulo[15],modulo[15],modulo[15:1]};	// - modulo 
		default:	newpt[20:1]=npt[20:1];			// bypass 	
	endcase

//sign output
assign signout=newpt[15];

endmodule	