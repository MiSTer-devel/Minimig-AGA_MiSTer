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
// along with this program.  If not, see <http:// www.gnu.org/licenses/>.
//
//
//
// These are the cia's
// Note that these are simplified implementation of both CIA's, just enough
// to get Minimig going
// NOT implemented is:
// serial data register for CIA B(but keyboard input for CIA A is supported)
// port B for CIA A
// counter inputs for timer A and B other then 'E' clock
// toggling of PB6/PB7 by timer A/B
//
// 30-03-2005  -started coding
//         -intterupt description finished
// 03-04-2005  -added timers A,B and D
// 05-04-2005  -simplified state machine of timerab
//         -improved timing of timer-reload of timerab
//         -cleaned up timer d
//         -moved intterupt part to seperate module
//         -created nice central address decoder
// 06-04-2005  -added I/O ports
//         -fixed small bug in timerab state machine
// 10-04-2005  -added clock synchronisation latch on input ports
//         -added rd (read) input to detect valid bus states
// 11-04-2005  -removed rd again due to change in address decoder
//         -better reset behaviour for timer D
// 17-04-2005  -even better reset behaviour for timer D and timers A and B
// 17-07-2005  -added pull-up simulation on I/O ports
// 21-12-2005  -added rd input
// 21-11-2006  -splitted in seperate ciaa and ciab
//         -added ps2 keyboard module to ciaa
// 22-11-2006  -added keyboard reset
// 05-12-2006  -added keyboard acknowledge
// 11-12-2006  -ciaa cleanup
// 27-12-2006  -ciab cleanup
// 01-01-2007  -osd_ctrl[] is now 4 bits/keys


// JB:
// 2008-03-25  - osd_ctrl[] is 6 bits/keys (Ctrl+Break and PrtScr keys added)
//         - verilog 2001 style declaration
// 2008-04-02  - separate Timer A and Timer B descriptions (they differ a little)
//         - one-shot mode of Timer A/B sets START bit in control register
//         - implemented Timer B counting mode of Timer A underflows
// 2008-04-25  - added transmit interrupt for serial port
// 2008-07-28  - scroll lock led as disk activity led
// 2008-12-29  - more sophisticated implementation of serial port transmit interrupt (fixes problem with keyboard in Citadel)
//         - fixed reloading of Timer A/B when writing THI in stop mode
// 2009-02-01  - osd_ctrl[] is 8 bit wide
// 2009-05-24  - clean-up & renaming
// 2009-06-12  - sdr returns written value
// 2009-06-17  - timer A&B reset to 0xFFFF
// 2009-07-09  - reading of port B of CIA A ($BFE101) returns all ones ($FF)
// 2009-12-28  - added serial port register to CIA B
// 2010-08-15  - added joystick emulation
//
// SB:
// 2011-04-02 - added ciaa port b (parallel) register to let Unreal game work and some trainer store data
// 2011-04-24 - fixed TOD read
//----------------------------------------------------------------------------------
//----------------------------------------------------------------------------------

/*cia a*/
module ciaa
(
  input   clk,          // clock
  input clk7_en,
  input clk7n_en,
  input   aen,          // adress enable
  input  rd,          // read enable
  input  wr,          // write enable
  input   reset,         // reset
  input   [3:0] rs,         // register select (address)
  input   [7:0] data_in,    // bus data in
  output   [7:0] data_out,    // bus data out
  input   tick,        // tick (counter input for TOD timer)
  input   eclk,          // eclk (counter input for timer A/B)
  output   irq,           // interrupt request out
  input  [7:2] porta_in,   // porta in
  output   [3:0] porta_out,  // porta out
  output  kbdrst,        // keyboard reset out
  inout  kbddat,        // ps2 keyboard data
  inout  kbdclk,        // ps2 keyboard clock
  input  keyboard_disabled,  // disable keystrokes
  input kbd_mouse_strobe,
  input kms_level,
  input [1:0] kbd_mouse_type,
  input [7:0] kbd_mouse_data,
  output  [7:0] osd_ctrl,    // osd control
  output  _lmb,
  output  _rmb,
  output  [5:0] _joy2,
  output  aflock,       // auto fire lock
  output  freeze,        // Action Replay freeze key
  input  disk_led,      // floppy disk activity LED
  output [5:0] mou_emu,
  output [5:0] joy_emu,
  input hrtmon_en
);

// local signals
wire   [7:0] icr_out;
wire  [7:0] tmra_out;
wire  [7:0] tmrb_out;
wire  [7:0] tmrd_out;
wire  [7:0] sdr_out;
reg    [7:0] pa_out;
reg    [7:0] pb_out;
wire  [7:0] portb_out;
wire  alrm;        // TOD interrupt
wire  ta;          // TIMER A interrupt
wire  tb;          // TIMER B interrupt
wire  tmra_ovf;      // TIMER A underflow (for Timer B)

wire  spmode;        // TIMER A Serial Port Mode (0-input, 1-output)
wire  ser_tx_irq;      // serial port transmit interrupt request
reg    [3:0] ser_tx_cnt;   // serial port transmit bit counter
reg    ser_tx_run;      // serial port is transmitting

reg    tick_del;      // required for edge detection

//----------------------------------------------------------------------------------
// address decoder
//----------------------------------------------------------------------------------
wire  pra,prb,ddra,ddrb,cra,talo,tahi,crb,tblo,tbhi,tdlo,tdme,tdhi,icrs,sdr;
wire  enable;

assign enable = aen & (rd | wr);

// decoder
assign  pra  = (enable && rs==4'h0) ? 1'b1 : 1'b0;
assign  prb  = (enable && rs==4'h1) ? 1'b1 : 1'b0;
assign  ddra = (enable && rs==4'h2) ? 1'b1 : 1'b0;
assign  ddrb = (enable && rs==4'h3) ? 1'b1 : 1'b0;
assign  talo = (enable && rs==4'h4) ? 1'b1 : 1'b0;
assign  tahi = (enable && rs==4'h5) ? 1'b1 : 1'b0;
assign  tblo = (enable && rs==4'h6) ? 1'b1 : 1'b0;
assign  tbhi = (enable && rs==4'h7) ? 1'b1 : 1'b0;
assign  tdlo = (enable && rs==4'h8) ? 1'b1 : 1'b0;
assign  tdme = (enable && rs==4'h9) ? 1'b1 : 1'b0;
assign  tdhi = (enable && rs==4'hA) ? 1'b1 : 1'b0;
assign  sdr  = (enable && rs==4'hC) ? 1'b1 : 1'b0;
assign  icrs = (enable && rs==4'hD) ? 1'b1 : 1'b0;
assign  cra  = (enable && rs==4'hE) ? 1'b1 : 1'b0;
assign  crb  = (enable && rs==4'hF) ? 1'b1 : 1'b0;

//----------------------------------------------------------------------------------
// data_out multiplexer
//----------------------------------------------------------------------------------
assign data_out = icr_out | tmra_out | tmrb_out | tmrd_out | sdr_out | pb_out | pa_out;

//----------------------------------------------------------------------------------
// instantiate keyboard module
//----------------------------------------------------------------------------------
wire  keystrobe;
wire  keyack;
wire  [7:0] keydat;
reg    [7:0] sdr_latch;


`ifdef MINIMIG_PS2_KEYBOARD

wire freeze_out;

ciaa_ps2keyboard  kbd1
(
  .clk(clk),
  .clk7_en(clk7_en),
  .reset(reset),
  .ps2kdat(kbddat),
  .ps2kclk(kbdclk),
  .leda(~porta_out[1]),  // keyboard joystick LED - num lock
  .ledb(disk_led),    // disk activity LED - scroll lock
  .aflock(aflock),
  .kbdrst(kbdrst),
  .keydat(keydat[7:0]),
  .keystrobe(keystrobe),
  .keyack(keyack),
  .osd_ctrl(osd_ctrl),
  ._lmb(_lmb),
  ._rmb(_rmb),
  ._joy2(_joy2),
  .freeze(freeze_out),
  .mou_emu(mou_emu),
  .joy_emu(joy_emu)
);

assign freeze = hrtmon_en && freeze_out;

// sdr register
// !!! Amiga receives keycode ONE STEP ROTATED TO THE RIGHT AND INVERTED !!!
always @(posedge clk)
  if (clk7_en) begin
    if (reset)
      sdr_latch[7:0] <= 8'h00;
    else if (keystrobe & ~keyboard_disabled)
      sdr_latch[7:0] <= ~{keydat[6:0],keydat[7]};
    else if (wr & sdr)
      sdr_latch[7:0] <= data_in[7:0];
  end

`else

//`define NEW_KEYB
`ifdef NEW_KEYB
// MiST keyboard
reg  [ 2:0] kms_level_sync;
wire        kms;
reg  [ 7:0] kmd_sync[0:1];
wire [ 7:0] kmd;
reg  [ 1:0] kmt_sync[0:1];
wire [ 1:0] kmt;
reg  [ 7:0] osd_ctrl_reg;
reg         freeze_reg=0;

// sync kms_level to clk28
always @ (posedge clk) begin
  if (clk7_en) begin
    kms_level_sync <= #1 {kms_level_sync[1:0], kms_level};
  end
end

//recreate kbd_mouse strobe in clk28 domain
assign kms = kms_level_sync[2] ^ kms_level_sync[1];

// synced data
assign kmt = kmt_sync[1];
assign kmd = kmd_sync[1];

// sync kbd_mouse_data to clk28
always @ (posedge clk) begin
  if (clk7_en) begin
    kmd_sync[0] <= #1 kbd_mouse_data;
    kmd_sync[1] <= #1 kmd_sync[0];
    kmt_sync[0] <= #1 kbd_mouse_type;
    kmt_sync[1] <= #1 kmt_sync[0];
  end
end

// sdr register
// !!! Amiga receives keycode ONE STEP ROTATED TO THE RIGHT AND INVERTED !!!
always @ (posedge clk) begin
  if (clk7_en) begin
    if (reset) begin
      sdr_latch[7:0] <= 8'h00;
      freeze_reg <= #1 1'b0;
    end else if (kms && (kmt == 2) && ~keyboard_disabled) begin
      sdr_latch[7:0] <= ~{kmd[6:0],kmd[7]};
      if (hrtmon_en && (kmd == 8'h5f)) freeze_reg <= #1 1'b1;
      else freeze_reg <= #1 1'b0;
    end else if (wr & sdr) begin
        sdr_latch[7:0] <= data_in[7:0];
    end
  end
end

always @ (posedge clk) begin
  if (clk7_en) begin
    if (reset)
      osd_ctrl_reg[7:0] <= 8'd0;
    else if (kms && ((kmt == 2) || (kmt == 3)))
      osd_ctrl_reg[7:0] <= kbd_mouse_data;
  end
end

assign kbdrst = 1'b0;
assign _lmb = 1'b1;
assign _rmb = 1'b1;
assign _joy2 = 6'b11_1111;
assign joy_emu = 6'b11_1111;
assign mou_emu = 6'b11_1111;
assign freeze = freeze_reg;
assign aflock = 1'b0;
assign keystrobe = kms && ((kmt == 2));
assign osd_ctrl = osd_ctrl_reg;

`else
assign kbdrst = 1'b0;
assign _lmb = 1'b1;
assign _rmb = 1'b1;
assign _joy2 = 6'b11_1111;
assign joy_emu = 6'b11_1111;
assign mou_emu = 6'b11_1111;
reg freeze_reg=0;
assign freeze = freeze_reg;
assign aflock = 1'b0;

reg [7:0] osd_ctrl_reg;

reg keystrobe_reg;
assign keystrobe = keystrobe_reg && ((kbd_mouse_type == 2) || (kbd_mouse_type == 3));

assign osd_ctrl = osd_ctrl_reg;

// generate a keystrobe which is valid exactly one clk cycle
reg kbd_mouse_strobeD, kbd_mouse_strobeD2;
always @(posedge clk)
  if (clk7_en) begin
    kbd_mouse_strobeD <= kbd_mouse_strobe;
  end

always @(posedge clk) begin
  if (clk7n_en) begin
    kbd_mouse_strobeD2 <= kbd_mouse_strobeD;
    keystrobe_reg <= kbd_mouse_strobeD && !kbd_mouse_strobeD2;
  end
end

// sdr register
// !!! Amiga receives keycode ONE STEP ROTATED TO THE RIGHT AND INVERTED !!!
always @(posedge clk) begin
  if (clk7_en) begin
    if (reset) begin
      sdr_latch[7:0] <= 8'h00;
      osd_ctrl_reg[7:0] <= 8'd0;
      freeze_reg <= #1 1'b0;
     end else begin
      if (keystrobe && (kbd_mouse_type == 2) && ~keyboard_disabled) begin
        sdr_latch[7:0] <= ~{kbd_mouse_data[6:0],kbd_mouse_data[7]};
        if (hrtmon_en && (kbd_mouse_data == 8'h5f)) freeze_reg <= #1 1'b1;
        else freeze_reg <= #1 1'b0;
      end else if (wr & sdr)
        sdr_latch[7:0] <= data_in[7:0];

      if(keystrobe && ((kbd_mouse_type == 2) || (kbd_mouse_type == 3)))
        osd_ctrl_reg[7:0] <= kbd_mouse_data;
    end
  end
end

`endif

`endif


// sdr register read
assign sdr_out = (!wr && sdr) ? sdr_latch[7:0] : 8'h00;
// keyboard acknowledge
assign keyack = (!wr && sdr) ? 1'b1 : 1'b0;

// serial port transmision in progress
always @(posedge clk)
  if (clk7_en) begin
    if (reset || !spmode) // reset or not in output mode
      ser_tx_run <= 0;
    else if (sdr && wr) // write to serial port data register when serial port is in output mode
      ser_tx_run <= 1;
    else if (ser_tx_irq) // last bit has been transmitted
      ser_tx_run <= 0;
  end

// serial port transmitted bits counter
always @(posedge clk)
  if (clk7_en) begin
    if (!ser_tx_run)
      ser_tx_cnt <= 4'd0;
    else if (tmra_ovf) // bits are transmitted when tmra overflows
      ser_tx_cnt <= ser_tx_cnt + 4'd1;
  end

assign ser_tx_irq = &ser_tx_cnt & tmra_ovf; // signal irq when ser_tx_cnt overflows

//----------------------------------------------------------------------------------
// porta
//----------------------------------------------------------------------------------
reg [7:2] porta_in2;
reg [3:0] regporta;
reg [7:0] ddrporta;

// synchronizing of input data
always @(posedge clk)
  if (clk7_en) begin
    porta_in2[7:2] <= porta_in[7:2];
  end

// writing of output port
always @(posedge clk)
  if (clk7_en) begin
    if (reset)
      regporta[3:0] <= 4'd0;
    else if (wr && pra)
      regporta[3:0] <= {data_in[7:6], data_in[1:0]};
  end

// writing of ddr register
always @(posedge clk)
  if (clk7_en) begin
    if (reset)
      ddrporta[7:0] <= 8'd0;
    else if (wr && ddra)
       ddrporta[7:0] <= data_in[7:0];
  end

// reading of port/ddr register
always @(*)
begin
  if (!wr && pra)
    pa_out[7:0] = {porta_in2[7:2],porta_out[1:0]};
  else if (!wr && ddra)
    pa_out[7:0] = ddrporta[7:0];
  else
    pa_out[7:0] = 8'h00;
end

// assignment of output port while keeping in mind that the original 8520 uses pull-ups
assign porta_out[3:0] = {(~ddrporta[7:6] | regporta[3:2]), (~ddrporta[1:0] | regporta[1:0])};

//----------------------------------------------------------------------------------
// portb
//----------------------------------------------------------------------------------
reg [7:0] regportb;
reg [7:0] ddrportb;

// writing of output port
always @(posedge clk)
  if (clk7_en) begin
    if (reset)
      regportb[7:0] <= 8'd0;
    else if (wr && prb)
      regportb[7:0] <= (data_in[7:0]);
  end

// writing of ddr register
always @(posedge clk)
  if (clk7_en) begin
    if (reset)
      ddrportb[7:0] <= 8'd0;
    else if (wr && ddrb)
      ddrportb[7:0] <= (data_in[7:0]);
  end

// reading of port/ddr register
always @(*)
begin
  if (!wr && prb)
    pb_out[7:0] = (portb_out[7:0]);
  else if (!wr && ddrb)
    pb_out[7:0] = (ddrportb[7:0]);
  else
    pb_out[7:0] = 8'h00;
end

// assignment of output port while keeping in mind that the original 8520 uses pull-ups
assign portb_out[7:0] = ((~ddrportb[7:0]) | (regportb[7:0]));

// delayed tick signal for edge detection
always @(posedge clk)
  if (clk7_en) begin
    tick_del <= tick;
  end

//----------------------------------------------------------------------------------
// instantiate cia interrupt controller
//----------------------------------------------------------------------------------
cia_int cnt
(
  .clk(clk),
  .clk7_en(clk7_en),
  .wr(wr),
  .reset(reset),
  .icrs(icrs),
  .ta(ta),
  .tb(tb),
  .alrm(alrm),
  .flag(1'b0),
  .ser(keystrobe & ~keyboard_disabled | ser_tx_irq),
  .data_in(data_in),
  .data_out(icr_out),
  .irq(irq)
);

//----------------------------------------------------------------------------------
// instantiate timer A
//----------------------------------------------------------------------------------
cia_timera tmra
(
  .clk(clk),
  .clk7_en(clk7_en),
  .wr(wr),
  .reset(reset),
  .tlo(talo),
  .thi(tahi),
  .tcr(cra),
  .data_in(data_in),
  .data_out(tmra_out),
  .eclk(eclk),
  .spmode(spmode),
  .tmra_ovf(tmra_ovf),
  .irq(ta)
);

//----------------------------------------------------------------------------------
// instantiate timer B
//----------------------------------------------------------------------------------
cia_timerb tmrb
(
  .clk(clk),
  .clk7_en(clk7_en),
  .wr(wr),
  .reset(reset),
  .tlo(tblo),
  .thi(tbhi),
  .tcr(crb),
  .data_in(data_in),
  .data_out(tmrb_out),
  .eclk(eclk),
  .tmra_ovf(tmra_ovf),
  .irq(tb)
);

//----------------------------------------------------------------------------------
// instantiate timer D
//----------------------------------------------------------------------------------
cia_timerd tmrd
(
  .clk(clk),
  .clk7_en(clk7_en),
  .wr(wr),
  .reset(reset),
  .tlo(tdlo),
  .tme(tdme),
  .thi(tdhi),
  .tcr(crb),
  .data_in(data_in),
  .data_out(tmrd_out),
  .count(tick & ~tick_del),
  .irq(alrm)
);


endmodule

