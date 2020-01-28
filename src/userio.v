////////////////////////////////////////////////////////////////////////////////
//                                                                            //
// Copyright 2006, 2007 Dennis van Weeren                                     //
//                                                                            //
// This file is part of Minimig                                               //
//                                                                            //
// Minimig is free software; you can redistribute it and/or modify            //
// it under the terms of the GNU General Public License as published by       //
// the Free Software Foundation; either version 3 of the License, or          //
// (at your option) any later version.                                        //
//                                                                            //
// Minimig is distributed in the hope that it will be useful,                 //
// but WITHOUT ANY WARRANTY; without even the implied warranty of             //
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              //
// GNU General Public License for more details.                               //
//                                                                            //
// You should have received a copy of the GNU General Public License          //
// along with this program.  If not, see <http://www.gnu.org/licenses/>.      //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
// This is the user IO module                                                 //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////



module userio
(
	input             clk,        // bus clock
	input             reset,      // reset
	input             clk7_en,

	input       [8:1] reg_address_in, // register adress inputs
	input      [15:0] data_in,    // bus data in
	output reg [15:0] data_out,   // bus data out
	output            _fire0,     // joystick 0 fire output (to CIA)
	output            _fire1,     // joystick 1 fire output (to CIA)
	input             _fire0_dat,
	input             _fire1_dat,
	input      [15:0] _joy1,      // joystick 1 in (default mouse port)
	input      [15:0] _joy2,      // joystick 2 in (default joystick port)
	input       [2:0] mouse_btn,
	input             kms_level,
	input       [1:0] kbd_mouse_type,
	input       [7:0] kbd_mouse_data,
	output reg  [1:0] aud_mix,
	input             IO_ENA,
	input             IO_STROBE,
	output reg        IO_WAIT,
	input      [15:0] IO_DIN,
	output reg  [7:0] memory_config,
	output reg  [4:0] chipset_config,
	output reg  [3:0] floppy_config,
	output reg  [2:0] scanline,
	output reg  [1:0] ar,
	output reg  [1:0] blver,
	output reg  [4:0] ide_config,
	output reg  [1:0] cpu_config,
	output reg  [2:0] cache_config,
	output reg        bootrom =0, // do the A1000 bootrom magic in gary.v
	output reg        usrrst,     // user reset from osd module
	output reg        cpurst,
	output reg        cpuhlt,
	// host
	output reg        host_cs,
	output reg [23:0] host_adr,
	output reg        host_we,
	output      [1:0] host_bs,
	output reg [15:0] host_wdat,
	input      [15:0] host_rdat,
	input             host_ack
);


// register names and adresses
parameter JOY0DAT     = 9'h00a;
parameter JOY1DAT     = 9'h00c;
parameter SCRDAT      = 9'h1f0;
parameter POTINP      = 9'h016;
parameter POTGO       = 9'h034;
parameter JOYTEST     = 9'h036;
parameter KEY_MENU    = 8'h69;
parameter KEY_ESC     = 8'h45;
parameter KEY_ENTER   = 8'h44;
parameter KEY_UP      = 8'h4C;
parameter KEY_DOWN    = 8'h4D;
parameter KEY_LEFT    = 8'h4F;
parameter KEY_RIGHT   = 8'h4E;
parameter KEY_PGUP    = 8'h6c;
parameter KEY_PGDOWN  = 8'h6d;


// local signals
reg   [15:0] _sjoy1;        // synchronized joystick 1 signals
reg   [15:0] _djoy1;        // synchronized joystick 1 signals
reg   [15:0] _sjoy2;        // synchronized joystick 2 signals
reg   [15:0] _djoy2;        // synchronized joystick 2 signals
reg   [15:0] potreg;        // POTGO write
wire  [15:0] mouse0dat;     // mouse counters
wire   [7:0] mouse0scr = 0; // mouse scroller
reg   [15:0] dmouse0dat;    // docking mouse counters
reg   [15:0] dmouse1dat;    // docking mouse counters
wire         _mleft;        // left mouse button
wire         _mthird;       // middle mouse button
wire         _mright;       // right mouse buttons
reg           joy1enable;   // joystick 1 enable (mouse/joy switch)
wire         test_load;     // load test value to mouse counter
wire  [15:0] test_data;     // mouse counter test value
reg          cd32pad;
reg          joy_swap;

//--------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------

// POTGO register
always @ (posedge clk) begin
	if (reset) potreg <= 0;
	else if (reg_address_in[8:1]==POTGO[8:1]) potreg[15:0] <= data_in[15:0];
end

wire joy2_pin5 = ~(potreg[13] & ~potreg[12]);
wire joy1_pin5 = ~(potreg[9]  & ~potreg[8]);

// potcap reg
reg  [4-1:0] potcap;
always @ (posedge clk) begin
	if (reset)
		potcap <= 0;
	else if (clk7_en) begin
		if (cd32pad & ~joy2_pin5) begin
			potcap[3] <= cd32pad2_reg[7];
		end else begin
			potcap[3] <= _djoy2[5] & ~(potreg[15] & ~potreg[14]);
		end
		potcap[2] <= joy2_pin5;

		if(joy1enable & cd32pad & ~joy1_pin5) begin
			potcap[1] <= cd32pad1_reg[7];
		end else begin
			potcap[1] <= _mright & _djoy1[5] & ~(potreg[11] & ~potreg[10]);
		end
		potcap[0] <= _mthird & joy1_pin5;
	end
end

// cd32pad1 reg
reg fire1_d;
always @ (posedge clk) begin
	if (reset) fire1_d <= 1;
	else fire1_d <= _fire0_dat;
end

wire cd32pad1_reg_load  = joy1_pin5;
wire cd32pad1_reg_shift = _fire0_dat && !fire1_d;
reg [8-1:0] cd32pad1_reg;
always @ (posedge clk) begin
	if (reset)                   cd32pad1_reg <= 8'hff;
	else if (cd32pad1_reg_load)  cd32pad1_reg <= {_djoy1[5], _djoy1[4], _djoy1[6], _djoy1[7], _djoy1[8], _djoy1[9], _djoy1[10], 1'b1};
	else if (cd32pad1_reg_shift) cd32pad1_reg <= {cd32pad1_reg[6:0], 1'b0};
end

// cd32pad2 reg
reg fire2_d;
always @ (posedge clk) begin
	if (reset) fire2_d <= 1;
	else fire2_d <= _fire1_dat;
end

wire cd32pad2_reg_load  = joy2_pin5;
wire cd32pad2_reg_shift = _fire1_dat && !fire2_d;
reg [8-1:0] cd32pad2_reg;
always @ (posedge clk) begin
	if (reset)                   cd32pad2_reg <= 8'hff;
	else if (cd32pad2_reg_load)  cd32pad2_reg <= {_djoy2[5], _djoy2[4], _djoy2[6], _djoy2[7], _djoy2[8], _djoy2[9], _djoy2[10], 1'b1};
	else if (cd32pad2_reg_shift) cd32pad2_reg <= {cd32pad2_reg[6:0], 1'b0};
end

// input synchronization of external signals
always @ (posedge clk) begin
	_sjoy1 <= joy_swap ? _joy1 : _joy2;
	_djoy1 <= _sjoy1;
	_sjoy2 <= joy_swap ? _joy2 : _joy1;
	_djoy2 <= _sjoy2;
end

// port 1 automatic mouse/joystick switch
always @ (posedge clk) begin
	//when left mouse button pushed, switch to mouse (default)
	if (!_mleft || reset) joy1enable = 0;
	//when joystick 1 fire pushed, switch to joystick
	else if (!_sjoy1[4]) joy1enable = 1;
end

// Port 1
always @ (posedge clk) begin
	if (clk7_en) begin
		if (test_load)
			dmouse0dat[7:0] <= 8'h00;
		else if ((!_djoy1[0] && _sjoy1[0] && _sjoy1[2]) || (_djoy1[0] && !_sjoy1[0] && !_sjoy1[2]) || (!_djoy1[2] && _sjoy1[2] && !_sjoy1[0]) || (_djoy1[2] && !_sjoy1[2] && _sjoy1[0]))
			dmouse0dat[7:0] <= dmouse0dat[7:0] + 1'd1;
		else if ((!_djoy1[0] && _sjoy1[0] && !_sjoy1[2]) || (_djoy1[0] && !_sjoy1[0] && _sjoy1[2]) || (!_djoy1[2] && _sjoy1[2] && _sjoy1[0]) || (_djoy1[2] && !_sjoy1[2] && !_sjoy1[0]))
			dmouse0dat[7:0] <= dmouse0dat[7:0] - 1'd1;
		else
			dmouse0dat[1:0] <= {!_djoy1[0], _djoy1[0] ^ _djoy1[2]};
	end
end

always @ (posedge clk) begin
	if (clk7_en) begin
		if (test_load)
			dmouse0dat[15:8] <= 8'h00;
		else if ((!_djoy1[1] && _sjoy1[1] && _sjoy1[3]) || (_djoy1[1] && !_sjoy1[1] && !_sjoy1[3]) || (!_djoy1[3] && _sjoy1[3] && !_sjoy1[1]) || (_djoy1[3] && !_sjoy1[3] && _sjoy1[1]))
			dmouse0dat[15:8] <= dmouse0dat[15:8] + 1'd1;
		else if ((!_djoy1[1] && _sjoy1[1] && !_sjoy1[3]) || (_djoy1[1] && !_sjoy1[1] && _sjoy1[3]) || (!_djoy1[3] && _sjoy1[3] && _sjoy1[1]) || (_djoy1[3] && !_sjoy1[3] && !_sjoy1[1]))
			dmouse0dat[15:8] <= dmouse0dat[15:8] - 1'd1;
		else
			dmouse0dat[9:8] <= {!_djoy1[1], _djoy1[1] ^ _djoy1[3]};
	end
end

// Port 2
always @ (posedge clk) begin
	if (clk7_en) begin
		if (test_load)
			dmouse1dat[7:2] <= test_data[7:2];
		else if ((!_djoy2[0] && _sjoy2[0] && _sjoy2[2]) || (_djoy2[0] && !_sjoy2[0] && !_sjoy2[2]) || (!_djoy2[2] && _sjoy2[2] && !_sjoy2[0]) || (_djoy2[2] && !_sjoy2[2] && _sjoy2[0]))
			dmouse1dat[7:0] <= dmouse1dat[7:0] + 1'd1;
		else if ((!_djoy2[0] && _sjoy2[0] && !_sjoy2[2]) || (_djoy2[0] && !_sjoy2[0] && _sjoy2[2]) || (!_djoy2[2] && _sjoy2[2] && _sjoy2[0]) || (_djoy2[2] && !_sjoy2[2] && !_sjoy2[0]))
			dmouse1dat[7:0] <= dmouse1dat[7:0] - 1'd1;
		else
			dmouse1dat[1:0] <= {!_djoy2[0], _djoy2[0] ^ _djoy2[2]};
	end
end

always @ (posedge clk) begin
	if (clk7_en) begin
		if (test_load)
			dmouse1dat[15:10] <= test_data[15:10];
		else if ((!_djoy2[1] && _sjoy2[1] && _sjoy2[3]) || (_djoy2[1] && !_sjoy2[1] && !_sjoy2[3]) || (!_djoy2[3] && _sjoy2[3] && !_sjoy2[1]) || (_djoy2[3] && !_sjoy2[3] && _sjoy2[1]))
			dmouse1dat[15:8] <= dmouse1dat[15:8] + 1'd1;
		else if ((!_djoy2[1] && _sjoy2[1] && !_sjoy2[3]) || (_djoy2[1] && !_sjoy2[1] && _sjoy2[3]) || (!_djoy2[3] && _sjoy2[3] && _sjoy2[1]) || (_djoy2[3] && !_sjoy2[3] && !_sjoy2[1]))
			dmouse1dat[15:8] <= dmouse1dat[15:8] - 1'd1;
		else
			dmouse1dat[9:8] <= {!_djoy2[1], _djoy2[1] ^ _djoy2[3]};
	end
end

//--------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------

// data output multiplexer
always @(*) begin
	if ((reg_address_in[8:1]==JOY0DAT[8:1]) && joy1enable)//read port 1 joystick
		data_out[15:0] = {mouse0dat[15:10] + dmouse0dat[15:10],dmouse0dat[9:8],mouse0dat[7:2] + dmouse0dat[7:2],dmouse0dat[1:0]};
	else if (reg_address_in[8:1]==JOY0DAT[8:1])//read port 1 mouse
		data_out[15:0] = {mouse0dat[15:8] + dmouse0dat[15:8],mouse0dat[7:0] + dmouse0dat[7:0]};
	else if (reg_address_in[8:1]==JOY1DAT[8:1])//read port 2 joystick
		data_out[15:0] = dmouse1dat;
	else if (reg_address_in[8:1]==POTINP[8:1])//read mouse and joysticks extra buttons
		data_out[15:0] = {1'b0, potcap[3],
								1'b0, potcap[2],
								1'b0, potcap[1],
								1'b0, potcap[0],
								8'h00};
	else if (reg_address_in[8:1]==SCRDAT[8:1])//read mouse scroll wheel
		data_out[15:0] = {8'h00,mouse0scr};
	else
		data_out[15:0] = 16'h0000;
end

// assign fire outputs to cia A
assign _fire0 = cd32pad && !cd32pad1_reg_load ? fire1_d : _sjoy1[4] & _mleft;
assign _fire1 = cd32pad && !cd32pad2_reg_load ? fire2_d : _sjoy2[4];

//JB: some trainers writes to JOYTEST register to reset current mouse counter
assign test_load = reg_address_in[8:1]==JOYTEST[8:1] ? 1'b1 : 1'b0;
assign test_data = data_in[15:0];


//--------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------


//// mouse ////
reg  [ 7:0] xcount;
reg  [ 7:0] ycount;

// mouse counters
reg old_level;
always @(posedge clk) begin

	old_level <= kms_level;

	if(reset) begin
		xcount <= 0;
		ycount <= 0;
	end else if (test_load && clk7_en) begin
		ycount[7:2] <= test_data[15:10];
		xcount[7:2] <= test_data[7:2];
	end else if (old_level ^ kms_level) begin
		if(kbd_mouse_type == 0) xcount[7:0] <= xcount[7:0] + kbd_mouse_data;
		if(kbd_mouse_type == 1) ycount[7:0] <= ycount[7:0] + kbd_mouse_data;
	end
end

// output
assign mouse0dat = {ycount, xcount};

// mouse buttons
assign _mleft  = ~mouse_btn[0];
assign _mright = ~mouse_btn[1];
assign _mthird = ~mouse_btn[2];


//--------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------

assign host_bs = 2'b11;

reg [7:0] t_memory_config = 8'b0_0_00_01_01;
reg [4:0] t_ide_config = 0;
reg [4:0] t_cpu_config = 0;
reg [4:0] t_chipset_config = 0;

// configuration changes only while reset is active
reg [4:0] ide_cfg = 0;
reg [1:0] cpu_cfg = 0;

always @(posedge clk) begin
	if (reset) begin
		chipset_config <= t_chipset_config;
		ide_cfg <= t_ide_config;
		cpu_cfg <= t_cpu_config[1:0];
		memory_config[5:0] <= t_memory_config[5:0];
		memory_config[7] <= t_memory_config[7];
	end
	
	ide_config <= ide_cfg;
	cpu_config <= cpu_cfg;
end

always @(posedge clk) begin
	cache_config[2:0] <= t_cpu_config[4:2];
	memory_config[6] <= t_memory_config[6];
end

reg [7:0] cmd;

// reg selects
wire mem_write_sel    = (cmd[3:0] == 0); // A_A_A_A B,B,... || write system memory, A - 32 bit memory address, B - variable number of bytes
wire reset_ctrl_sel   = (cmd[3:0] == 1); // XXXXHRBC || reset control   | H - CPU halt, R - reset, B - reset to bootloader, C - reset control block
wire aud_sel          = (cmd[3:0] == 2);
wire chip_cfg_sel     = (cmd[3:0] == 3); // XXXGEANT || chipset config  | G - AGA, E - ECS, A - OCS A1000, N - NTSC, T - turbo
wire cpu_cfg_sel      = (cmd[3:0] == 4); // XXXXKCTT || cpu config      | K - fast kickstart enable, C - CPU cache enable, TT - CPU type (00=68k, 01=68k10, 10=68k20)
wire memory_cfg_sel   = (cmd[3:0] == 5); // XHFFSSCC || memory config   | H - HRTmon, FF - fast, SS - slow, CC - chip
wire video_cfg_sel    = (cmd[3:0] == 6); // DDHHLLSS || video config    | DD - dither, HH - hires interp. filter, LL - lowres interp. filter, SS - scanline mode
wire floppy_cfg_sel   = (cmd[3:0] == 7); // XXXXXFFS || floppy config   | FF - drive number, S - floppy speed
wire harddisk_cfg_sel = (cmd[3:0] == 8); // XXXXXSMC || harddisk config | S - enable slave HDD, M - enable master HDD, C - enable HDD controler
wire joystick_cfg_sel = (cmd[3:0] == 9); // XXXXXCAA || joystick config | C - CD32pad mode, AA - autofire rate

reg       has_cmd;
reg       mrx;
reg       btoggle;
reg       old_ack;
reg [2:0] bcnt;
reg       bootrom_r;

always @(posedge clk) begin
	old_ack <= host_ack;
	if (old_ack & ~host_ack) begin
		IO_WAIT  <= 0;
		host_adr <= host_adr + 24'd2;
	end

	if(~IO_ENA) begin
		IO_WAIT <= 0;
		has_cmd <= 0;
		mrx     <= 0;
		bcnt    <= 0;
      btoggle <= 0;
	end
	else if(IO_STROBE) begin
		has_cmd <= 1;
		if(~has_cmd) cmd <= IO_DIN[7:0];
		else if(&cmd[7:4]) begin
			if(~bcnt[2]) bcnt <= bcnt + 1'd1;

			if(!bcnt) begin
				if (reset_ctrl_sel)   {cpuhlt, cpurst, usrrst} <= IO_DIN[2:0];
				if (chip_cfg_sel)     t_chipset_config <= IO_DIN[4:0];
				if (cpu_cfg_sel)      t_cpu_config <= IO_DIN[4:0];
				if (memory_cfg_sel)   t_memory_config <= IO_DIN[7:0];
				if (video_cfg_sel)    {blver, ar, scanline} <= {IO_DIN[11:8],IO_DIN[2:0]};
				if (floppy_cfg_sel)   floppy_config <= IO_DIN[3:0];
				if (harddisk_cfg_sel) t_ide_config <= IO_DIN[4:0];
				if (joystick_cfg_sel) {joy_swap, cd32pad} <= IO_DIN[3:2];
				if (aud_sel)          aud_mix <= IO_DIN[1:0];
			end
			
			if (mem_write_sel) begin
				case (bcnt)
				  0 : host_adr[ 7: 0] <= IO_DIN[7:0];
				  1 : host_adr[15: 8] <= IO_DIN[7:0];
				  2 : host_adr[23:16] <= IO_DIN[7:0];
				  //3 : mem_page[ 7: 0] <= IO_DIN[7:0];
				endcase

				if(bcnt[2]) begin
				   // If OSD writes to $f80000, it could be a bootrom. When a Kickstart is loaded, $fe0000 is also written.
				   if (host_adr == 24'hF80000) bootrom_r <= 1; 
				   if (host_adr == 24'hFE0000) bootrom_r <= 0;  
					btoggle <= ~btoggle;
					if(btoggle) begin
						host_wdat[7:0] <= IO_DIN[7:0];
						mrx <= 1;
						IO_WAIT <= 1;
					end
					else host_wdat[15:8] <= IO_DIN[7:0];
				end
			end;
		end
	end
	else if(clk7_en) begin
		host_cs <= mrx;
		host_we <= mrx;
		if(host_ack) mrx <= 0;
	end
	
	bootrom <= bootrom_r;
end

endmodule
