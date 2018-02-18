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
// This is the Minimig PS/2 keyboard handler
//
// 19-11-2006	-started coding
// 20-11-2006	-more coding
// 21-11-2006	-finished PS/2 state machine, added keymap
// 29-11-2006	-keymap is now blockram, saves almost 80 slices!
// 04-12-2006	-added keyack signal
// 05-12-2006	-more work; cleaning up, optimizing
//			-added on-screen-display control
// 01-01-2007	-added extra key for on-screen-display control
// 11-02-2007	-reset is now ctrl-alt-alt (as in Amiga OS4) instead of ctrl-lgui-rgui 

// this is the ps2 keyboard module itself
// every time a new key is decoded, keystrobe is asserted.
// keydat is only valid when keystrobe is asserted
// after keystrobe, keyboard controller waits for keyack or timeout
// kbdrst is asserted when the control, left gui and right gui keys are hold down together
// leda and ledb control the numlock and scrolllock leds


// JB:
// added support for prtscr and ctrlbrk keys
// verilog 2001 style module declaration
// osd_ctrl is 8-bit wide
//
// 2009-05-24	- clean-up & renaming
// 2010-08-18	- joystick emulation

// SB:
// 2011-04-09 - added autofire lock function using capslock
// 2011-07-21 - changed '#' key scan code, thanks Chris

module ciaa_ps2keyboard
(
	input 	clk,		   		//bus clock
  input clk7_en,
	input 	reset,			   	//reset (system reset in)
	inout	ps2kdat,			//keyboard PS/2 data
	inout	ps2kclk,			//keyboard PS/2 clk
	input	leda,				//keyboard led a in
	input	ledb,				//keyboard led b in
  output  aflock,   // auto fire toggle
	output	kbdrst,				//keyboard reset out
	output	[7:0] keydat,		//keyboard data out
	output	reg keystrobe,		//keyboard data out strobe
	input	keyack,				//keyboard data out acknowledge
	output	[7:0] osd_ctrl,		//on-screen-display controll
	output	_lmb,				//emulated left mouse button
	output	_rmb,				//emulated right mouse button
	output	[5:0] _joy2,		//joystick emulation
	output	freeze,				//Action Replay freeze button
  output [5:0] mou_emu,
  output [5:0] joy_emu
);

//local signals
reg		pclkout; 				//ps2 clk out
wire	pdatout;				//ps2 data out
wire	pclkneg;				//negative edge of ps2 clock strobe
reg		pdatb,pclkb,pclkc;		//input synchronization	

reg		[11:0] preceive;		//ps2 receive register
reg		[11:0] psend;			//ps2 send register
reg		[19:0] ptimer;			//ps2 timer
reg		[2:0] kstate;			//keyboard controller current state
reg		[2:0] knext;			//keyboard controller next state
reg		capslock;				//capslock status
wire	numlock;

reg		prreset;				//ps2 receive reset
wire	prbusy;					//ps2 receive busy
reg		ptreset;				//ps2 reset timer
wire	pto1;					//ps2 timer timeout 1 
wire	pto2;					//ps2 timer timeout 2
reg		psled1;					//ps2 send led code 1
reg		psled2;					//ps2 send led code 2
wire	psready;				//ps2 send ready
wire	valid;					//valid amiga key code at keymap output

//bidirectional open collector IO buffers
assign ps2kclk = pclkout ? 1'bz : 1'b0;
assign ps2kdat = pdatout ? 1'bz : 1'b0;

//input synchronization of external signals
always @(posedge clk) begin
  if (clk7_en) begin
  	pdatb <= ps2kdat;
  	pclkb <= ps2kclk;
  	pclkc <= pclkb;
  end
end						

//detect ps2 clock negative edge
assign pclkneg = pclkc & ~pclkb;

//PS2 input shifter
wire prready;

always @(posedge clk)
  if (clk7_en) begin
  	if (prreset  ||  prready)
  		preceive[11:0] <= 12'b111111111111;
  	else if (pclkneg)
  		preceive[11:0] <= {1'b0,pdatb,preceive[10:1]};
  end
		
assign prready = ~preceive[0];
assign prbusy = ~preceive[11];

//PS2 timer
always @(posedge clk)
  if (clk7_en) begin
  	if (ptreset)
  		ptimer[19:0] <= 20'd0;
  	else if (!pto2)
  		ptimer[19:0] <= ptimer[19:0] + 20'd1;
  end
		
assign pto1 = ptimer[15];//4.6ms @ 7.09Mhz
assign pto2 = ptimer[19];//74ms @ 7.09Mhz

//PS2 send shifter
always @(posedge clk)
  if (clk7_en) begin
  	if (psled1)
  		psend[11:0] <= 12'b111111011010;//$ED
  	else if (psled2)
  		psend[11:0] <= {2'b11,~(capslock^numlock^ledb),5'b00000,capslock,numlock,ledb,1'b0};//led status
  	else if (!psready && pclkneg)
  		psend[11:0] <= {1'b0,psend[11:1]};
  end

assign psready = (psend[11:0]==12'b000000000001) ? 1'd1 : 1'd0;
assign pdatout = psend[0];

//keyboard state machine
always @(posedge clk)
  if (clk7_en) begin
  	if (reset)//master reset
  		kstate <= 3'd0;
  	else 
  		kstate <= knext;
  end
		
always @(*)
begin
	case(kstate)
		0://reset timer
			begin
				prreset = 1'd1;
				ptreset = 1'd1;
				pclkout = 1'd0;
				psled1 = 1'd0;
				psled2 = 1'd0;
				
				knext = 3'd1;
			end
		1://"request-to-send" for led1 code  
			begin
				prreset = 1'd1;
				ptreset = 1'd0;
				pclkout = 1'd0;
				psled1 = 1'd1;
				psled2 = 1'd0;
				
				if (pto1)
					knext = 3'd2;
				else
					knext = 3'd1;
			end
		2://wait for led1 code to be sent and acknowledge received
			begin
				prreset = ~psready;
				ptreset = 1'd1;
				pclkout = 1'd1;
				psled1 = 1'd0;
				psled2 = 1'd0;
				
				if (prready)
					knext = 3'd3;
				else
					knext = 3'd2;
			end
		3://"request-to-send" for led2 code
			begin
				prreset = 1'd1;
				ptreset = 1'd0;
				pclkout = 1'd0;
				psled1 = 1'd0;
				psled2 = 1'd1;
				
				if (pto1)
					knext = 3'd4;
				else
					knext = 3'd3;
			end
		4://wait for led2 code to be sent
			begin
				prreset = ~psready;
				ptreset = 1'd1;
				pclkout = 1'd1;
				psled1 = 1'd0;
				psled2 = 1'd0;
				
				if (prready)
					knext = 3'd5;
				else
					knext = 3'd4;
			end


		5://wait for valid amiga key code
			begin
				prreset = 1'd0;
				ptreset = keystrobe;
				pclkout = 1'd1;
				psled1 = 1'd0;
				psled2 = 1'd0;
				if (keystrobe)//valid amiga key decoded
					knext = 3'd6;
				else if (!prbusy && pto2)//timeout, update leds
					knext = 3'd0;
				else//stay here
					knext = 3'd5;
 			end

		6://hold of ps2 keyboard and wait for keyack or timeout
			begin
				prreset = 1'd0;
				ptreset = keyack;
				pclkout = 1'd0;
				psled1 = 1'd0;
				psled2 = 1'd0;
				if (keyack  ||  pto2)//keyack or timeout
					knext = 3'd5;
				else//stay here
					knext = 3'd6;
 			end

		default://we should never come here
			begin
				prreset = 1'd0;//ps2 receiver reset
				ptreset = 1'd0;//ps2 timer reset
				pclkout = 1'd1;//ps2 clock override
				psled1 = 1'd0;//ps2 send led code 1
				psled2 = 1'd0;//ps2 send led code 2

				knext = 3'd0;//go to reset state
 			end

	endcase
end

//instantiate keymap to convert ps2 scan codes to amiga raw key codes
wire ctrl,aleft,aright,caps;
ciaa_ps2keyboard_map km1
(
	.clk(clk),
  .clk7_en(clk7_en),
	.reset(reset),
	.enable(prready),
	.ps2key(preceive[8:1]),
	.valid(valid),
	.akey(keydat[7:0]),
	.ctrl(ctrl),
	.aleft(aleft),
	.aright(aright),
	.caps(caps),
	.numlock(numlock),
	.osd_ctrl(osd_ctrl),
	._lmb(_lmb),
	._rmb(_rmb),
	._joy2(_joy2),
	.freeze(freeze),
  .mou_emu(mou_emu),
  .joy_emu(joy_emu)
);

//Duplicate key filter and caps lock handling.
//A ps/2 keyboard has a future called "typematic".
//This means that the last key downstroke event
//is repeated (at approx 2Hz default).
//An Amiga keyboard does not do this so this filter removes
//all duplicate downstroke events:
//When a duplicate downstroke event is detected, keystrobe is not asserted.
//When the event is unique (no duplicate), keystrobe is asserted when valid is asserted.
//
//Capslock on amiga is "remembered" by keyboard. A ps/2 keyboard doesn't do this
//therefore, amiga-like caps lock behaviour is simulated here
wire keyequal;
reg [7:0]keydat2;
assign keyequal = keydat2[6:0]==keydat[6:0] ? 1'd1 : 1'd0; //detect if latched key equals new key

//latch last key downstroke event
always @(posedge clk)
  if (clk7_en) begin
  	if (reset)
  		keydat2[7:0] <= 8'd0;
  	else if (valid && !keydat[7])//latch downstroke event for last key pressed
  		keydat2[7:0] <= keydat[7:0];
  	else if (valid && keydat[7] && keyequal)//upstroke event for latched key received
  		keydat2[7:0] <= keydat[7:0];
  end

//toggle capslock status on capslock downstroke event		
always @(posedge clk)
  if (clk7_en) begin
  	if (reset)
  		capslock <= 1'd0;
  	else if (valid && !keydat[7] && caps && !(keyequal && (keydat[7]==keydat2[7])))
	  	capslock <= ~capslock;
  end

assign aflock = capslock;

//generate keystrobe to indicate valid keycode				
always @(*)
	if (capslock && caps)//filter out capslock downstroke && capslock upstroke events if capslock is set
		keystrobe = 1'd0;
	else if (keyequal && (keydat[7]==keydat2[7]))//filter out duplicate events
		keystrobe = 1'd0;
	else if (valid)//valid amiga keycode, assert strobe
		keystrobe = 1'd1;
	else
		keystrobe = 1'd0;

//Keyboard reset detector. 
//Reset is accomplished by holding down the
//ctrl or caps, left alt and right alt keys all at the same time
reg [2:0]kbdrststatus;
always @(posedge clk) begin
  if (clk7_en) begin
  	//latch status of control key
  	if (reset)
  		kbdrststatus[2] <= 1'd1;
  	else if (valid && (ctrl || caps))
  		kbdrststatus[2] <= keydat[7];
  	//latch status of left alt key
  	if (reset)
  		kbdrststatus[1] <= 1'd1;
  	else if (valid && aleft)
  		kbdrststatus[1] <= keydat[7];
  	//latch status of right alt key
  	if (reset)
  		kbdrststatus[0] <= 1'd1;
  	else if (valid && aright)
  		kbdrststatus[0] <= keydat[7];
  end
end

assign kbdrst = ~(kbdrststatus[2] | kbdrststatus[1] | kbdrststatus[0]);//reset if all 3 keys down


endmodule

