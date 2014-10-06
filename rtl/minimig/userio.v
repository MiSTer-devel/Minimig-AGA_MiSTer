//Copyright 2006, 2007 Dennis van Weeren
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
// This is the user IO module
// joystick signals are _joy[5:0]=[fire2,fire,up,down,left,right];
//
// 16-10-2005	-started coding
// 17-10-2005	-added proper reset for mouse buttons/counters
//				-improved mouse startup timing
// 22-11-2005	-added joystick 1
// 05-02-2006	-unused buttons of joystick port 2 are now high
// 06-02-2006	-cleaned up code
//				-added user output
// 27-12-2006	-added joystick port 1 and automatic joystick/mouse switch
//				-started coding osd display
// 28-12-2006	-more osd display work done
// 29-12-2006	-fixed some bugs in osd module
// 30-12-2006	-cleaned up osd module, added osd_ctrl input
//-----------------------------------------------------------------------------
// JB:
// 2008-06-17	- added osd control by joy2
//				- spi8 rewritten to use spi clock
//				- added highlight (inversion) of selected osd line
//				- added user reset and reset to bootloader
//				- added memory and interpolation filters configuration
// 2008-07-28	- added JOYTEST register to make it compatible with ALPHA1/SIRIAX flashtro/trainer
// 2008-09-30	- removed user output
// 2008-10-12	- added floppy_config and chipset_config outputs
// 2008-12-12	- added scanline outputs
// 2008-12-27	- added hdd_ena output
// 2009-02-10	- sampling of joystick signals using sof (acting as simple debouncing filter)
// 2009-03-21	- disable keyboard until all keys are released
// 2009-05-08	- fixed problem with activation of OSD menu using UP+DOWN joystick signals
// 2009-05-24	- clean-up & renaming
// 2009-07-18	- change of memory_config takes effect after reset
// 2009-08-11	- hdd_ena replaced with ide_config
// 2009-08-17	- OSD position moved right
// 2009-12-18 - clean-up
// 2010-08-16 - joystick emulation
// 2010-08-16 - autofire
//        - lmb & rmb emulation
//
// SB:
//  06-03-2011  - added autofire without key press & permanent fire at KP0
// 11-04-2011 - autofire function toggle able via capslock / led status
// 17-01-2013  - added POTGO write register handling (required by Asterix game)
//                         
// RK:
// 2013-03-21 - more compatible right mouse & second joystick button handling; TODO tests
// 2014-06-21 - added PS/2 mouse intellimouse support
// 2014-06-22 - added real mouse support from Chameleon minimig port


module userio
(
	input 	clk,		    		//bus clock
	input 	reset,			   		//reset
  input clk7_en,
  input clk7n_en,
	input	c1,
	input	c3,
	input	sol,					//start of video line
	input	sof,					//start of video frame 
	input 	[8:1] reg_address_in,	//register adress inputs
	input	[15:0] data_in,			//bus data in
	output	reg [15:0] data_out,	//bus data out
	inout	ps2mdat,				//mouse PS/2 data
	inout	ps2mclk,				//mouse PS/2 clk
	output	_fire0,					//joystick 0 fire output (to CIA)
	output	_fire1,					//joystick 1 fire output (to CIA)
	input	[5:0] _joy1,			//joystick 1 in (default mouse port)
	input	[5:0] _joy2,			//joystick 2 in (default joystick port)
  input aflock,         // auto fire lock
  input [2:0] mouse_btn,
  input _lmb,
  input _rmb,
  input [5:0] mou_emu,
  input kbd_mouse_strobe,
  input [1:0] kbd_mouse_type,
  input [7:0] kbd_mouse_data,
	input	[7:0] osd_ctrl,			//OSD control (minimig->host, [menu,select,down,up])
  output  reg keyboard_disabled,  // disables Amiga keyboard while OSD is active
	input	_scs,					//SPI enable
	input	sdi,		  			//SPI data in
	output	sdo,	 				//SPI data out
	input	sck,	  				//SPI clock
	output	osd_blank,				//osd overlay, normal video blank output
	output	osd_pixel,				//osd video pixel
	output	[1:0] lr_filter,
	output	[1:0] hr_filter,
	output	[5:0] memory_config,
	output	[3:0] chipset_config,
	output	[3:0] floppy_config,
	output	[1:0] scanline,
	output	[2:0] ide_config,
  output  [3:0] cpu_config,
	output	usrrst,					//user reset from osd module
  output cpurst,
  output cpuhlt,
  output wire fifo_full,
  // host
  output wire           host_cs,
  output wire [ 24-1:0] host_adr,
  output wire           host_we,
  output wire [  2-1:0] host_bs,
  output wire [ 16-1:0] host_wdat,
  input  wire [ 16-1:0] host_rdat,
  input  wire           host_ack
);

//local signals	
reg   [5:0] _sjoy1;       // synchronized joystick 1 signals
reg   [5:0] _djoy1;       // synchronized joystick 1 signals
reg   [5:0] _xjoy2;       // synchronized joystick 2 signals
reg   [5:0] _tjoy2;       // synchronized joystick 2 signals
reg   [5:0] _djoy2;       // synchronized joystick 2 signals
wire  [5:0] _sjoy2;       // synchronized joystick 2 signals
reg   [15:0] potreg;      // POTGO write
wire	[15:0] mouse0dat;			//mouse counters
wire  [7:0]  mouse0scr;   // mouse scroller
reg   [15:0] dmouse0dat;      // docking mouse counters
reg   [15:0] dmouse1dat;      // docking mouse counters
wire	_mleft;						//left mouse button
wire	_mthird;					//middle mouse button
wire	_mright;					//right mouse buttons
reg		joy1enable;					//joystick 1 enable (mouse/joy switch)
reg		joy2enable;					//joystick 2 enable when no osd
wire	osd_enable;					// OSD display enable
wire  key_disable;        // Amiga keyboard disable
reg		[7:0] t_osd_ctrl;			//JB: osd control lines
wire	test_load;					//load test value to mouse counter 
wire	[15:0] test_data;			//mouse counter test value
wire  [1:0] autofire_config;
reg   [1:0] autofire_cnt;
reg   autofire;
reg   sel_autofire;     // select autofire and permanent fire

//register names and adresses		
parameter JOY0DAT = 9'h00a;
parameter JOY1DAT = 9'h00c;
parameter SCRDAT  = 9'h1f0;
parameter POTINP  = 9'h016;
parameter POTGO   = 9'h034;
parameter JOYTEST = 9'h036;

parameter KEY_MENU  = 8'h69;
parameter KEY_ESC   = 8'h45;
parameter KEY_ENTER = 8'h44;
parameter KEY_UP    = 8'h4C;
parameter KEY_DOWN  = 8'h4D;
parameter KEY_LEFT  = 8'h4F;
parameter KEY_RIGHT = 8'h4E;
parameter KEY_PGUP   = 8'h6c;
parameter KEY_PGDOWN = 8'h6d;

//--------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------

// POTGO register
always @(posedge clk)
  if (clk7_en) begin
    if (reset)
      potreg <= 0;
  //    potreg <= 16'hffff;
    else if (reg_address_in[8:1]==POTGO[8:1])
      potreg[15:0] <= data_in[15:0];
  end

// potcap reg
reg  [4-1:0] potcap;
always @ (posedge clk) begin
  if (clk7_en) begin
    if (reset)
      potcap <= 4'h0;
    else begin
      if (!_sjoy2[5]) potcap[3] <= 1'b0;
      else if (potreg[15] & potreg[14]) potcap[3] <= 1'b1;
      /*if (!1'b1) potcap[2] <= 1'b0;
      else*/ if (potreg[13]) potcap[2] <= potreg[12];
      if (!(_mright&_djoy1[5]&_rmb)) potcap[1] <= 1'b0;
      else if (potreg[11] & potreg[10]) potcap[1] <= 1'b1;
      if (!_mthird) potcap[0] <= #1 1'b0;
      else if (potreg[ 9] & potreg[ 8]) potcap[0] <= 1'b1;
    end
  end
end

//autofire pulses generation
always @(posedge clk)
  if (clk7_en) begin
    if (sof)
      if (autofire_cnt == 1)
        autofire_cnt <= autofire_config;
      else
        autofire_cnt <= autofire_cnt - 2'd1;
  end

// autofire 
always @(posedge clk)
  if (clk7_en) begin
    if (sof)
      if (autofire_config == 2'd0)
        autofire <= 1'b0;
      else if (autofire_cnt == 2'd1)
        autofire <= ~autofire;
  end

// auto fire function toggle via capslock status
always @(posedge clk)
  if (clk7_en) begin
    sel_autofire <= (~aflock ^ _xjoy2[4]) ? autofire : 1'b0;
  end

// disable keyboard when OSD is displayed
always @(key_disable)
  keyboard_disabled <= key_disable;
										   
//input synchronization of external signals
always @(posedge clk)
  if (clk7_en) begin
  	_sjoy1[5:0] <= _joy1[5:0];	
    _djoy1[5:0] <= _sjoy1[5:0]; 
    _tjoy2[5:0] <= _joy2[5:0];  
    _djoy2[5:0] <= _tjoy2[5:0]; 
  	if (sof)
  		_xjoy2[5:0] <= _joy2[5:0];	
  end

//port 2 joystick disable in osd
always @(posedge clk)
  if (clk7_en) begin
  	if (key_disable)
  		joy2enable <= 0;
  	else if (_xjoy2[5:0] == 6'b11_1111)
  		joy2enable <= 1;
  end

//  autofire is permanent active if enabled, can be overwritten any time by normal fire button
assign _sjoy2[5:0] = joy2enable ? {_xjoy2[5], sel_autofire ^ _xjoy2[4], _xjoy2[3:0]} : 6'b11_1111;

always @(joy2enable or _xjoy2 or osd_ctrl)
	if (~joy2enable)
		if (~_xjoy2[5] || (~_xjoy2[3] && ~_xjoy2[2]))
			t_osd_ctrl = KEY_MENU;
		else if (~_xjoy2[4])
			t_osd_ctrl = KEY_ENTER;
		else if (~_xjoy2[3])
			t_osd_ctrl = KEY_UP;
		else if (~_xjoy2[2])
			t_osd_ctrl = KEY_DOWN;
		else if (~_xjoy2[1])
			t_osd_ctrl = KEY_LEFT;
		else if (~_xjoy2[0])
			t_osd_ctrl = KEY_RIGHT;
    else if (~_xjoy2[1] && ~_xjoy2[3])
      t_osd_ctrl = KEY_PGUP;
    else if (~_xjoy2[0] && ~_xjoy2[2])
      t_osd_ctrl = KEY_PGDOWN;
		else
			t_osd_ctrl = osd_ctrl;
	else
		if (~_xjoy2[3] && ~_xjoy2[2])
			t_osd_ctrl = KEY_MENU;
		else
			t_osd_ctrl = osd_ctrl;

//port 1 automatic mouse/joystick switch
always @(posedge clk)
  if (clk7_en) begin
  	if (!_mleft || reset)//when left mouse button pushed, switch to mouse (default)
  		joy1enable = 0;
  	else if (!_sjoy1[4])//when joystick 1 fire pushed, switch to joystick
  		joy1enable = 1;
  end

//Port 1
always @(posedge clk)
  if (clk7_en) begin
    if (test_load)
      dmouse0dat[7:0] <= 8'h00;
    else if ((!_djoy1[0] && _sjoy1[0] && _sjoy1[2]) || (_djoy1[0] && !_sjoy1[0] && !_sjoy1[2]) || (!_djoy1[2] && _sjoy1[2] && !_sjoy1[0]) || (_djoy1[2] && !_sjoy1[2] && _sjoy1[0]))
      dmouse0dat[7:0] <= dmouse0dat[7:0] + 1;
    else if ((!_djoy1[0] && _sjoy1[0] && !_sjoy1[2]) || (_djoy1[0] && !_sjoy1[0] && _sjoy1[2]) || (!_djoy1[2] && _sjoy1[2] && _sjoy1[0]) || (_djoy1[2] && !_sjoy1[2] && !_sjoy1[0]))
      dmouse0dat[7:0] <= dmouse0dat[7:0] - 1;
    else  
      dmouse0dat[1:0] <= {!_djoy1[0], _djoy1[0] ^ _djoy1[2]};
  end
  
always @(posedge clk)
  if (clk7_en) begin
    if (test_load)
      dmouse0dat[15:8] <= 8'h00;
    else if ((!_djoy1[1] && _sjoy1[1] && _sjoy1[3]) || (_djoy1[1] && !_sjoy1[1] && !_sjoy1[3]) || (!_djoy1[3] && _sjoy1[3] && !_sjoy1[1]) || (_djoy1[3] && !_sjoy1[3] && _sjoy1[1]))
      dmouse0dat[15:8] <= dmouse0dat[15:8] + 1;
    else if ((!_djoy1[1] && _sjoy1[1] && !_sjoy1[3]) || (_djoy1[1] && !_sjoy1[1] && _sjoy1[3]) || (!_djoy1[3] && _sjoy1[3] && _sjoy1[1]) || (_djoy1[3] && !_sjoy1[3] && !_sjoy1[1]))
      dmouse0dat[15:8] <= dmouse0dat[15:8] - 1;
    else  
      dmouse0dat[9:8] <= {!_djoy1[1], _djoy1[1] ^ _djoy1[3]};
  end

//Port 2
always @(posedge clk)
  if (clk7_en) begin
    if (test_load)
      dmouse1dat[7:2] <= test_data[7:2];
    else if ((!_djoy2[0] && _tjoy2[0] && _tjoy2[2]) || (_djoy2[0] && !_tjoy2[0] && !_tjoy2[2]) || (!_djoy2[2] && _tjoy2[2] && !_tjoy2[0]) || (_djoy2[2] && !_tjoy2[2] && _tjoy2[0]))
      dmouse1dat[7:0] <= dmouse1dat[7:0] + 1;
    else if ((!_djoy2[0] && _tjoy2[0] && !_tjoy2[2]) || (_djoy2[0] && !_tjoy2[0] && _tjoy2[2]) || (!_djoy2[2] && _tjoy2[2] && _tjoy2[0]) || (_djoy2[2] && !_tjoy2[2] && !_tjoy2[0]))
      dmouse1dat[7:0] <= dmouse1dat[7:0] - 1;
    else  
      dmouse1dat[1:0] <= {!_djoy2[0], _djoy2[0] ^ _djoy2[2]};
  end
  
always @(posedge clk)
  if (clk7_en) begin
    if (test_load)
      dmouse1dat[15:10] <= test_data[15:10];
    else if ((!_djoy2[1] && _tjoy2[1] && _tjoy2[3]) || (_djoy2[1] && !_tjoy2[1] && !_tjoy2[3]) || (!_djoy2[3] && _tjoy2[3] && !_tjoy2[1]) || (_djoy2[3] && !_tjoy2[3] && _tjoy2[1]))
      dmouse1dat[15:8] <= dmouse1dat[15:8] + 1;
    else if ((!_djoy2[1] && _tjoy2[1] && !_tjoy2[3]) || (_djoy2[1] && !_tjoy2[1] && _tjoy2[3]) || (!_djoy2[3] && _tjoy2[3] && _tjoy2[1]) || (_djoy2[3] && !_tjoy2[3] && !_tjoy2[1]))
      dmouse1dat[15:8] <= dmouse1dat[15:8] - 1;
    else  
      dmouse1dat[9:8] <= {!_djoy2[1], _djoy2[1] ^ _djoy2[3]};
  end

//--------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------

//data output multiplexer
always @(*)
	if ((reg_address_in[8:1]==JOY0DAT[8:1]) && joy1enable)//read port 1 joystick
		//data_out[15:0] = {6'b000000,~_sjoy1[1],_sjoy1[3]^_sjoy1[1],6'b000000,~_sjoy1[0],_sjoy1[2]^_sjoy1[0]};
    data_out[15:0] = {mouse0dat[15:10] + dmouse0dat[15:10],dmouse0dat[9:8],mouse0dat[7:2] + dmouse0dat[7:2],dmouse0dat[1:0]};
	else if (reg_address_in[8:1]==JOY0DAT[8:1])//read port 1 mouse
		//data_out[15:0] = mouse0dat[15:0];
    data_out[15:0] = {mouse0dat[15:8] + dmouse0dat[15:8],mouse0dat[7:0] + dmouse0dat[7:0]};
	else if (reg_address_in[8:1]==JOY1DAT[8:1])//read port 2 joystick
		//data_out[15:0] = {6'b000000,~_sjoy2[1],_sjoy2[3]^_sjoy2[1],6'b000000,~_sjoy2[0],_sjoy2[2]^_sjoy2[0]};
    data_out[15:0] = dmouse1dat;
	else if (reg_address_in[8:1]==POTINP[8:1])//read mouse and joysticks extra buttons
//		data_out[15:0] = {1'b0, (1'b1 ? potreg[14]&_sjoy2[5]              : _sjoy2[5]),
//                      1'b0, (1'b1 ? potreg[12]&1'b1                   : 1'b1),
//                      1'b0, (1'b1 ? potreg[10]&_mright&_sjoy1[5]&_rmb : _mright&_sjoy1[5]&_rmb),
//                      1'b0, (1'b1 ? potreg[ 8]&_mthird                : _mthird),
//                      8'h00};
		data_out[15:0] = {1'b0, potcap[3],
                      1'b0, potcap[2],
                      1'b0, potcap[1],
                      1'b0, potcap[0],
                      8'h00};
	else if (reg_address_in[8:1]==SCRDAT[8:1])//read mouse scroll wheel
		data_out[15:0] = {8'h00,mouse0scr};
	else
		data_out[15:0] = 16'h0000;

//assign fire outputs to cia A
assign _fire0 = _sjoy1[4] & _mleft & _lmb;
assign _fire1 = _sjoy2[4];

//JB: some trainers writes to JOYTEST register to reset current mouse counter
assign test_load = reg_address_in[8:1]==JOYTEST[8:1] ? 1'b1 : 1'b0;
assign test_data = data_in[15:0];

//--------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------

`ifdef MINIMIG_PS2_MOUSE

//instantiate mouse controller
userio_ps2mouse pm1
(
  .clk(clk),
  .clk7_en(clk7_en),
  .reset(reset),
  .ps2mdat(ps2mdat),
  .ps2mclk(ps2mclk),
  .mou_emu (mou_emu),
  .sof (sof),
  .zcount(mouse0scr),
  .ycount(mouse0dat[15:8]),
  .xcount(mouse0dat[7:0]),
  ._mleft(_mleft),
  ._mthird(_mthird),
  ._mright(_mright),
  .test_load(test_load),
  .test_data(test_data)
);

`else

reg [7:0] xcount;
reg [7:0] ycount;

assign mouse0dat[7:0] = xcount;
assign mouse0dat[15:8] = ycount;

assign _mleft = ~mouse_btn[0];
assign _mright = ~mouse_btn[1];
assign _mthird = ~mouse_btn[2];

always @(posedge kbd_mouse_strobe) begin
  if(reset) begin
      xcount <= 8'b00000000;
      ycount <= 8'b00000000;
  end else begin
    if(kbd_mouse_type == 0)
      xcount[7:0] <= xcount[7:0] + kbd_mouse_data[7:0];
    else if(kbd_mouse_type == 1)
      ycount[7:0] <= ycount[7:0] + kbd_mouse_data[7:0];
  end   
end

`endif


//--------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------


//instantiate osd controller
userio_osd osd1
(
	.clk(clk),
	.clk7_en(clk7_en),
  .clk7n_en(clk7n_en),
	.reset(reset),
	.c1(c1),
	.c3(c3),
	.sol(sol),
	.sof(sof),
	.osd_ctrl(t_osd_ctrl),
	._scs(_scs),
	.sdi(sdi),
	.sdo(sdo),
	.sck(sck),
	.osd_blank(osd_blank),
	.osd_pixel(osd_pixel),
	.osd_enable(osd_enable),
  .key_disable(key_disable),
	.lr_filter(lr_filter),
	.hr_filter(hr_filter),
	.memory_config(memory_config),
	.chipset_config(chipset_config),
	.floppy_config(floppy_config),
	.scanline(scanline),
	.ide_config(ide_config),
  .cpu_config(cpu_config),
  .autofire_config(autofire_config),
	.usrrst(usrrst),
  .cpurst(cpurst),
  .cpuhlt(cpuhlt),
  .fifo_full(fifo_full),
  .host_cs      (host_cs          ),
  .host_adr     (host_adr         ),
  .host_we      (host_we          ),
  .host_bs      (host_bs          ),
  .host_wdat    (host_wdat        ),
  .host_rdat    (host_rdat        ),
  .host_ack     (host_ack         )
);


endmodule

