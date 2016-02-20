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



module userio (
  input  wire           clk,                // bus clock
  input  wire           reset,              // reset
  input  wire           clk7_en,
  input  wire           clk7n_en,
  input  wire           c1,
  input  wire           c3,
  input  wire           sol,                // start of video line
  input  wire           sof,                // start of video frame
  input  wire           varbeamen,
  input  wire [  9-1:1] reg_address_in,     // register adress inputs
  input  wire [ 16-1:0] data_in,            // bus data in
  output reg  [ 16-1:0] data_out,           // bus data out
  inout  wire           ps2mdat,            // mouse PS/2 data
  inout  wire           ps2mclk,            // mouse PS/2 clk
  output wire           _fire0,             // joystick 0 fire output (to CIA)
  output wire           _fire1,             // joystick 1 fire output (to CIA)
  input  wire           _fire0_dat,
  input  wire           _fire1_dat,
  input  wire [  8-1:0] _joy1,              // joystick 1 in (default mouse port)
  input  wire [  8-1:0] _joy2,              // joystick 2 in (default joystick port)
  input  wire           aflock,             // auto fire lock
  input  wire [  3-1:0] mouse_btn,
  input  wire           _lmb,
  input  wire           _rmb,
  input  wire [  6-1:0] mou_emu,
  input  wire           kbd_mouse_strobe,
  input  wire           kms_level,
  input  wire [  2-1:0] kbd_mouse_type,
  input  wire [  8-1:0] kbd_mouse_data,
  input  wire [  8-1:0] osd_ctrl,           // OSD control (minimig->host, [menu,select,down,up])
  output reg            keyboard_disabled,  // disables Amiga keyboard while OSD is active
  input  wire           _scs,               // SPI enable
  input  wire           sdi,                // SPI data in
  output wire           sdo,                // SPI data out
  input  wire           sck,                // SPI clock
  output wire           osd_blank,          // osd overlay, normal video blank output
  output wire           osd_pixel,          // osd video pixel
  output wire [  2-1:0] lr_filter,
  output wire [  2-1:0] hr_filter,
  output wire [  7-1:0] memory_config,
  output wire [  5-1:0] chipset_config,
  output wire [  4-1:0] floppy_config,
  output wire [  2-1:0] scanline,
  output wire [  2-1:0] dither,
  output wire [  3-1:0] ide_config,
  output wire [  4-1:0] cpu_config,
  output                usrrst,             // user reset from osd module
  output                cpurst,
  output                cpuhlt,
  output wire           fifo_full,
  // host
  output wire           host_cs,
  output wire [ 24-1:0] host_adr,
  output wire           host_we,
  output wire [  2-1:0] host_bs,
  output wire [ 16-1:0] host_wdat,
  input  wire [ 16-1:0] host_rdat,
  input  wire           host_ack
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
reg   [7:0] _sjoy1;       // synchronized joystick 1 signals
reg   [7:0] _djoy1;       // synchronized joystick 1 signals
reg   [5:0] _xjoy2;       // synchronized joystick 2 signals
reg   [7:0] _tjoy2;       // synchronized joystick 2 signals
reg   [7:0] _djoy2;       // synchronized joystick 2 signals
wire  [5:0] _sjoy2;       // synchronized joystick 2 signals
reg   [15:0] potreg;      // POTGO write
wire  [15:0] mouse0dat;      //mouse counters
wire  [7:0]  mouse0scr;   // mouse scroller
reg   [15:0] dmouse0dat;      // docking mouse counters
reg   [15:0] dmouse1dat;      // docking mouse counters
wire  _mleft;            //left mouse button
wire  _mthird;          //middle mouse button
wire  _mright;          //right mouse buttons
reg    joy1enable;          //joystick 1 enable (mouse/joy switch)
reg    joy2enable;          //joystick 2 enable when no osd
wire  osd_enable;          // OSD display enable
wire  key_disable;        // Amiga keyboard disable
reg    [7:0] t_osd_ctrl;      //JB: osd control lines
wire  test_load;          //load test value to mouse counter
wire  [15:0] test_data;      //mouse counter test value
wire  [1:0] autofire_config;
reg   [1:0] autofire_cnt;
wire  cd32pad;
reg   autofire;
reg   sel_autofire;     // select autofire and permanent fire


//--------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------

// POTGO register
always @ (posedge clk) begin
  if (clk7_en) begin
    if (reset)
      potreg <= #1 0;
    else if (reg_address_in[8:1]==POTGO[8:1])
      potreg[15:0] <= #1 data_in[15:0];
  end
end

// potcap reg
reg  [4-1:0] potcap;
always @ (posedge clk) begin
  if (clk7_en) begin
    if (reset)
      potcap <= #1 4'h0;
    else begin
      if (cd32pad && (potreg[15] && !potreg[14])) begin
        potcap[3] <= #1 cd32pad2_reg[7];
      end else begin
        if (!_sjoy2[5]) potcap[3] <= #1 1'b0;
        else if (potreg[15] & potreg[14]) potcap[3] <= #1 1'b1;
      end
      if (potreg[13]) potcap[2] <= #1 potreg[12];
      if (cd32pad && (potreg[11] && !potreg[10])) begin
        potcap[1] <= #1 cd32pad1_reg[7];
      end else begin
        if (!(_mright&_djoy1[5]&_rmb)) potcap[1] <= #1 1'b0;
        else if (potreg[11] & potreg[10]) potcap[1] <= #1 1'b1;
      end
      if (!_mthird) potcap[0] <= #1 1'b0;
      else if (potreg[ 9] & potreg[ 8]) potcap[0] <= #1 1'b1;
    end
  end
end

// cd32pad1 reg
reg fire1_d;
always @ (posedge clk) begin
  if (clk7_en) begin
    if (reset)
      fire1_d <= #1 1'b1;
    else
      fire1_d <= #1 _fire0_dat;
  end
end
wire cd32pad1_reg_load  = !(potreg[9] && !potreg[8]);
wire cd32pad1_reg_shift = _fire0_dat && !fire1_d;
reg [8-1:0] cd32pad1_reg;
always @ (posedge clk) begin
  if (clk7_en) begin
    if (reset)
      cd32pad1_reg <= #1 8'hff;
    else if (cd32pad1_reg_load)
      cd32pad1_reg <= #1 {_djoy1[5], _djoy1[4], _djoy1[6], _djoy1[7], 3'b111, 1'b1};
    else if (cd32pad1_reg_shift)
      cd32pad1_reg <= #1 {cd32pad1_reg[6:0], 1'b0};
  end
end

// cd32pad2 reg
reg fire2_d;
always @ (posedge clk) begin
  if (clk7_en) begin
    if (reset)
      fire2_d <= #1 1'b1;
    else
      fire2_d <= #1 _fire1_dat;
  end
end
wire cd32pad2_reg_load  = !(potreg[13] && !potreg[12]);
wire cd32pad2_reg_shift = _fire1_dat && !fire2_d;
reg [8-1:0] cd32pad2_reg;
always @ (posedge clk) begin
  if (clk7_en) begin
    if (reset)
      cd32pad2_reg <= #1 8'hff;
    else if (cd32pad2_reg_load)
      cd32pad2_reg <= #1 {_djoy2[5], _djoy2[4], _djoy2[6], _djoy2[7], 3'b111, 1'b1};
    else if (cd32pad2_reg_shift)
      cd32pad2_reg <= #1 {cd32pad2_reg[6:0], 1'b0};
  end
end

// autofire pulses generation
always @ (posedge clk) begin
  if (clk7_en) begin
    if (sof)
      if (autofire_cnt == 1)
        autofire_cnt <= #1 autofire_config;
      else
        autofire_cnt <= #1 autofire_cnt - 2'd1;
  end
end

// autofire
always @ (posedge clk) begin
  if (clk7_en) begin
    if (sof)
      if (autofire_config == 2'd0)
        autofire <= #1 1'b0;
      else if (autofire_cnt == 2'd1)
        autofire <= #1 ~autofire;
  end
end

// auto fire function toggle via capslock status
always @ (posedge clk) begin
  if (clk7_en) begin
    sel_autofire <= #1 (~aflock ^ _xjoy2[4]) ? autofire : 1'b0;
  end
end

// disable keyboard when OSD is displayed
always @ (*) keyboard_disabled = key_disable;

// input synchronization of external signals
always @ (posedge clk) begin
  if (clk7_en) begin
    _sjoy1[7:0] <= #1 _joy1[7:0];
    _djoy1[7:0] <= #1 _sjoy1[7:0];
    _tjoy2[7:0] <= #1 _joy2[7:0];
    _djoy2[7:0] <= #1 _tjoy2[7:0];
    if (sof)
      _xjoy2[5:0] <= #1 _joy2[5:0];
  end
end

// port 2 joystick disable in osd
always @ (posedge clk) begin
  if (clk7_en) begin
    if (key_disable)
      joy2enable <= #1 0;
    else if (_xjoy2[5:0] == 6'b11_1111)
      joy2enable <= #1 1;
  end
end

// autofire is permanent active if enabled, can be overwritten any time by normal fire button
assign _sjoy2[5:0] = joy2enable ? {_xjoy2[5], sel_autofire ^ _xjoy2[4], _xjoy2[3:0]} : 6'b11_1111;

always @ (*) begin
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
//    if (~_xjoy2[3] && ~_xjoy2[2])
//      t_osd_ctrl = KEY_MENU;
//    else
      t_osd_ctrl = osd_ctrl;
end

// port 1 automatic mouse/joystick switch
always @ (posedge clk) begin
  if (clk7_en) begin
    if (!_mleft || reset)//when left mouse button pushed, switch to mouse (default)
      joy1enable = 0;
    else if (!_sjoy1[4])//when joystick 1 fire pushed, switch to joystick
      joy1enable = 1;
  end
end

// Port 1
always @ (posedge clk) begin
  if (clk7_en) begin
    if (test_load)
      dmouse0dat[7:0] <= #1 8'h00;
    else if ((!_djoy1[0] && _sjoy1[0] && _sjoy1[2]) || (_djoy1[0] && !_sjoy1[0] && !_sjoy1[2]) || (!_djoy1[2] && _sjoy1[2] && !_sjoy1[0]) || (_djoy1[2] && !_sjoy1[2] && _sjoy1[0]))
      dmouse0dat[7:0] <= #1 dmouse0dat[7:0] + 1;
    else if ((!_djoy1[0] && _sjoy1[0] && !_sjoy1[2]) || (_djoy1[0] && !_sjoy1[0] && _sjoy1[2]) || (!_djoy1[2] && _sjoy1[2] && _sjoy1[0]) || (_djoy1[2] && !_sjoy1[2] && !_sjoy1[0]))
      dmouse0dat[7:0] <= #1 dmouse0dat[7:0] - 1;
    else
      dmouse0dat[1:0] <= #1 {!_djoy1[0], _djoy1[0] ^ _djoy1[2]};
  end
end

always @ (posedge clk) begin
  if (clk7_en) begin
    if (test_load)
      dmouse0dat[15:8] <= #1 8'h00;
    else if ((!_djoy1[1] && _sjoy1[1] && _sjoy1[3]) || (_djoy1[1] && !_sjoy1[1] && !_sjoy1[3]) || (!_djoy1[3] && _sjoy1[3] && !_sjoy1[1]) || (_djoy1[3] && !_sjoy1[3] && _sjoy1[1]))
      dmouse0dat[15:8] <= #1 dmouse0dat[15:8] + 1;
    else if ((!_djoy1[1] && _sjoy1[1] && !_sjoy1[3]) || (_djoy1[1] && !_sjoy1[1] && _sjoy1[3]) || (!_djoy1[3] && _sjoy1[3] && _sjoy1[1]) || (_djoy1[3] && !_sjoy1[3] && !_sjoy1[1]))
      dmouse0dat[15:8] <= #1 dmouse0dat[15:8] - 1;
    else
      dmouse0dat[9:8] <= #1 {!_djoy1[1], _djoy1[1] ^ _djoy1[3]};
  end
end

// Port 2
always @ (posedge clk) begin
  if (clk7_en) begin
    if (test_load)
      dmouse1dat[7:2] <= #1 test_data[7:2];
    else if ((!_djoy2[0] && _tjoy2[0] && _tjoy2[2]) || (_djoy2[0] && !_tjoy2[0] && !_tjoy2[2]) || (!_djoy2[2] && _tjoy2[2] && !_tjoy2[0]) || (_djoy2[2] && !_tjoy2[2] && _tjoy2[0]))
      dmouse1dat[7:0] <= #1 dmouse1dat[7:0] + 1;
    else if ((!_djoy2[0] && _tjoy2[0] && !_tjoy2[2]) || (_djoy2[0] && !_tjoy2[0] && _tjoy2[2]) || (!_djoy2[2] && _tjoy2[2] && _tjoy2[0]) || (_djoy2[2] && !_tjoy2[2] && !_tjoy2[0]))
      dmouse1dat[7:0] <= #1 dmouse1dat[7:0] - 1;
    else
      dmouse1dat[1:0] <= #1 {!_djoy2[0], _djoy2[0] ^ _djoy2[2]};
  end
end

always @ (posedge clk) begin
  if (clk7_en) begin
    if (test_load)
      dmouse1dat[15:10] <= #1 test_data[15:10];
    else if ((!_djoy2[1] && _tjoy2[1] && _tjoy2[3]) || (_djoy2[1] && !_tjoy2[1] && !_tjoy2[3]) || (!_djoy2[3] && _tjoy2[3] && !_tjoy2[1]) || (_djoy2[3] && !_tjoy2[3] && _tjoy2[1]))
      dmouse1dat[15:8] <= #1 dmouse1dat[15:8] + 1;
    else if ((!_djoy2[1] && _tjoy2[1] && !_tjoy2[3]) || (_djoy2[1] && !_tjoy2[1] && _tjoy2[3]) || (!_djoy2[3] && _tjoy2[3] && _tjoy2[1]) || (_djoy2[3] && !_tjoy2[3] && !_tjoy2[1]))
      dmouse1dat[15:8] <= #1 dmouse1dat[15:8] - 1;
    else
      dmouse1dat[9:8] <= #1 {!_djoy2[1], _djoy2[1] ^ _djoy2[3]};
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
assign _fire0 = cd32pad && !cd32pad1_reg_load ? fire1_d : _sjoy1[4] & _mleft & _lmb;
assign _fire1 = cd32pad && !cd32pad2_reg_load ? fire2_d : _sjoy2[4];

//JB: some trainers writes to JOYTEST register to reset current mouse counter
assign test_load = reg_address_in[8:1]==JOYTEST[8:1] ? 1'b1 : 1'b0;
assign test_data = data_in[15:0];


//--------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------


`ifdef MINIMIG_PS2_MOUSE

//instantiate mouse controller
userio_ps2mouse pm1
(
  .clk        (clk),
  .clk7_en    (clk7_en),
  .reset      (reset),
  .ps2mdat    (ps2mdat),
  .ps2mclk    (ps2mclk),
  .mou_emu    (mou_emu),
  .sof        (sof),
  .zcount     (mouse0scr),
  .ycount     (mouse0dat[15:8]),
  .xcount     (mouse0dat[7:0]),
  ._mleft     (_mleft),
  ._mthird    (_mthird),
  ._mright    (_mright),
  .test_load  (test_load),
  .test_data  (test_data)
);

`else

//// MiST mouse ////
reg  [ 2:0] kms_level_sync;
wire        kms;
reg  [ 7:0] kmd_sync[0:1];
reg  [ 1:0] kmt_sync[0:1];
reg  [ 7:0] xcount;
reg  [ 7:0] ycount;

// sync kms_level to clk28
always @ (posedge clk) begin
  kms_level_sync <= #1 {kms_level_sync[1:0], kms_level};
end

//recreate kbd_mouse strobe in clk28 domain
assign kms = kms_level_sync[2] ^ kms_level_sync[1];

// sync kbd_mouse_data to clk28
always @ (posedge clk) begin
  kmd_sync[0] <= #1 kbd_mouse_data;
  kmd_sync[1] <= #1 kmd_sync[0];
  kmt_sync[0] <= #1 kbd_mouse_type;
  kmt_sync[1] <= #1 kmt_sync[0];
end

// mouse counters
always @(posedge clk) begin
  if(reset) begin
      xcount <= #1 8'd0;
      ycount <= #1 8'd0;
  end else if (test_load && clk7_en) begin
    ycount[7:2] <= #1 test_data[15:10];
    xcount[7:2] <= #1 test_data[7:2];
  end else if (kms) begin
    if(kmt_sync[1] == 0)
      xcount[7:0] <= #1 xcount[7:0] + kmd_sync[1];
    else if(kmt_sync[1] == 1)
      ycount[7:0] <= #1 ycount[7:0] + kmd_sync[1];
  end
end

// output
assign mouse0dat = {ycount, xcount};

// mouse buttons
assign _mleft  = ~mouse_btn[0];
assign _mright = ~mouse_btn[1];
assign _mthird = ~mouse_btn[2];

`endif


//--------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------


//instantiate osd controller
userio_osd osd1
(
  .clk              (clk),
  .clk7_en          (clk7_en),
  .clk7n_en         (clk7n_en),
  .reset            (reset),
  .c1               (c1),
  .c3               (c3),
  .sol              (sol),
  .sof              (sof),
  .varbeamen        (varbeamen),
  .osd_ctrl         (t_osd_ctrl),
  ._scs             (_scs),
  .sdi              (sdi),
  .sdo              (sdo),
  .sck              (sck),
  .osd_blank        (osd_blank),
  .osd_pixel        (osd_pixel),
  .osd_enable       (osd_enable),
  .key_disable      (key_disable),
  .lr_filter        (lr_filter),
  .hr_filter        (hr_filter),
  .memory_config    (memory_config),
  .chipset_config   (chipset_config),
  .floppy_config    (floppy_config),
  .scanline         (scanline),
  .dither           (dither),
  .ide_config       (ide_config),
  .cpu_config       (cpu_config),
  .autofire_config  (autofire_config),
  .cd32pad          (cd32pad),
  .usrrst           (usrrst),
  .cpurst           (cpurst),
  .cpuhlt           (cpuhlt),
  .fifo_full        (fifo_full),
  .host_cs          (host_cs),
  .host_adr         (host_adr),
  .host_we          (host_we),
  .host_bs          (host_bs),
  .host_wdat        (host_wdat),
  .host_rdat        (host_rdat),
  .host_ack         (host_ack)
);


endmodule

