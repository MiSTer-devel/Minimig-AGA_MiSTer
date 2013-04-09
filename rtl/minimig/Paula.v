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
// This is paula
//
// 06-03-2005	-started coding
// 19-03-2005	-added interupt controller and uart
// 04-09-2005	-added blitter finished interrupt
// 19-10-2005	-removed cck (color clock enable) input
//				-removed intb signal
//				-added sof signal
// 23-10-2005	-added dmal signal
//				-added paula part of DMACON
// 21-11-2005	-added floppy controller
// 				-added ADKCON/ADCONR registers
//				-added local horbeam counter
// 27-11-2005	-den is now active low (_den)
//				-some typo's fixed
// 11-12-2005	-disable syncword interrupt
// 13-12-2005	-enable syncword interrupt
// 27-12-2005	-cleaned up code
// 28-12-2005	-added audio module
// 03-01-2006	-added dmas to avoid interference with copper cycles
// 07-01-2006	-added dmas for disk controller
// 06-02-2006	-added user disk control input
// 03-07-2007	-moved interrupt controller and uart to this file to reduce number of sourcefiles
// JB:
// 2008-09-24	- code clean-up
//				- added support for floppy _sel[3:1] signals
// 2008-09-30	- removed user disk control input
// 2008-10-12	- source clean-up
// 2009-01-08	- added audio_dmal, audio_dmas
// 2009-03-08	- removed horbeam counter and sol
//				- added strhor
// 2009-04-05	- code clean-up
// 2009-05-24	- clean-up & renaming
// 2009-07-10	- implementation of intreq[14] (Unreal needs it)
// 2009-11-14 - added 28 MHz clock input for sigma-delta modulator
// RK:
// 2013-03-21 - translated & added a new more compatible uart core written by madeho@minimig.net


module Paula
(
	// system bus interface
	input 	clk,		    		//bus clock
  input clk28m,         // 28 MHz system clock
	input 	cck,		    		//colour clock enable
	input 	reset,			   		//reset 
	input 	[8:1] reg_address_in,	//register address inputs
	input	[15:0] data_in,			//bus data in
	output	[15:0] data_out,		//bus data out
	//serial (uart) 
	output 	txd,					//serial port transmitted data
	input 	rxd,			  		//serial port received data
	//interrupts and dma
  input ntsc,         // PAL/NTSC mode
  input sof,          // start of vertical frame
	input	strhor,					//start of video line (latches audio DMA requests)
  input vblint,         // vertical blanking interrupt trigger
	input	int2,					//level 2 interrupt
	input	int3,					//level 3 interrupt
	input	int6,					//level 6 interrupt
	output	[2:0] _ipl,				//m68k interrupt request
	output	[3:0] audio_dmal,		//audio dma data transfer request (to Agnus)
	output	[3:0] audio_dmas,		//audio dma location pointer restart (to Agnus)
	output	disk_dmal,				//disk dma data transfer request (to Agnus)
	output	disk_dmas,				//disk dma special request (to Agnus)
	//disk control signals from cia and user
	input	_step,					//step heads of disk
	input	direc,					//step heads direction
	input	[3:0] _sel,				//disk select 	
	input	side,					//upper/lower disk head
	input	_motor,					//disk motor control
	output	_track0,				//track zero detect
	output	_change,				//disk has been removed from drive
	output	_ready,					//disk is ready
	output	_wprot,					//disk is write-protected
  output  index,          // disk index pulse
	output	disk_led,				//disk activity LED
	//flash drive host controller interface	(SPI)
	input	_scs,					//async. serial data enable
	input	sdi,					//async. serial data input
	output	sdo,					//async. serial data output
	input	sck,					//async. serial data clock
	//audio outputs
	output	left,					//audio bitstream left
	output	right,					//audio bitstream right
	output	[14:0]ldata,			//left DAC data
	output	[14:0]rdata, 			//right DAC data
  // system configuration
	input	[1:0] floppy_drives,	//number of extra floppy drives
  // direct sector read from SD card
	input	direct_scs,				//spi select line for direct transfers from SD card
	input	direct_sdi,				//spi data line for direct transfers from SD card
  // emulated Hard Disk Drive signals
	input	hdd_cmd_req,      // command request
	input	hdd_dat_req,     // data request
	output	[2:0] hdd_addr,     // task file register address
	output	[15:0] hdd_data_out,  // data bus output
	input	[15:0] hdd_data_in,   // data bus input
	output	hdd_wr,         // task file write enable
	output	hdd_status_wr,      // drive status write enable
	output	hdd_data_wr,      // data port write enable
	output	hdd_data_rd,        // data port read enable
  // fifo / track display
	output  [7:0]trackdisp,
	output  [13:0]secdisp,
  output  floppy_fwr,
  output  floppy_frd
);
//--------------------------------------------------------------------------------------

//register names and addresses
parameter DMACON  = 9'h096;	
parameter ADKCON  = 9'h09e;
parameter ADKCONR = 9'h010;	

//local signals
reg		[4:0] dmacon;			//dmacon paula bits 
reg		dmaen;					//master dma enable
reg		[14:0] adkcon;			//audio and disk control register
wire	[15:0] uartdata_out; 	//UART data out
wire	[15:0] intdata_out;  	//interrupt controller data out
wire	[15:0] diskdata_out;		//disk controller data out
wire	[15:0] adkconr;			//ADKCONR register data out
wire	rbfmirror; 				//rbf mirror (from uart to interrupt controller)
wire	rxint;  				//uart rx interrupt request
wire	txint;					//uart tx interrupt request
wire	blckint;				//disk block finished interrupt
wire	syncint;				//disk syncword match interrupt
wire	[3:0] audint;			//audio channels 0,1,2,3 interrupt request
wire	[3:0] audpen;			//audio channels 0,1,2,3 interrupt pending
wire	[3:0] auden;			//audio channels 0,1,2,3 dma enable
wire	dsken; 					//disk dma enable


//--------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------

//data_out multiplexer
assign data_out = uartdata_out | intdata_out | diskdata_out | adkconr;

//--------------------------------------------------------------------------------------

//DMACON register write
//NOTE: this register is also present in the Agnus module,
//there DMACONR (read) is implemented
always @(posedge clk)
	if (reset) begin
    dmaen <= 0;
		dmacon <= 5'd0;
	end else if (reg_address_in[8:1]==DMACON[8:1]) begin
		if (data_in[15])
			{dmaen,dmacon[4:0]} <= {dmaen,dmacon[4:0]} | {data_in[9],data_in[4:0]};
		else
			{dmaen,dmacon[4:0]} <= {dmaen,dmacon[4:0]} & (~{data_in[9],data_in[4:0]});	
	end

//assign disk and audio dma enable bits
assign	dsken = dmacon[4] & dmaen;
assign	auden[3] = dmacon[3] & dmaen;
assign	auden[2] = dmacon[2] & dmaen;
assign	auden[1] = dmacon[1] & dmaen;
assign	auden[0] = dmacon[0] & dmaen;

//--------------------------------------------------------------------------------------

//ADKCON register write
always @(posedge clk)
	if (reset)
		adkcon <= 15'd0;
	else if (reg_address_in[8:1]==ADKCON[8:1])
	begin
		if (data_in[15])
			adkcon[14:0] <= adkcon[14:0] | data_in[14:0];
		else
			adkcon[14:0] <= adkcon[14:0] & (~data_in[14:0]);	
	end

//ADKCONR register 
assign adkconr[15:0] = (reg_address_in[8:1]==ADKCONR[8:1]) ? {1'b0,adkcon[14:0]} : 16'h0000;

//--------------------------------------------------------------------------------------

//instantiate uart
uart pu1
(
	.clk(clk),
	.reset(reset),
	.rga_i(reg_address_in),
	.data_i(data_in),
	.data_o(uartdata_out),
	.uartbrk(adkcon[11]),
	.rbfmirror(rbfmirror),
	.rxint(rxint),
	.txint(txint),
	.rxd(rxd),
	.txd(txd)
);

//instantiate interrupt controller
intcontroller pi1
(
	.clk(clk),
	.reset(reset),
	.reg_address_in(reg_address_in),
	.data_in(data_in),
	.data_out(intdata_out),
	.rxint(rxint),
	.txint(txint),
  .vblint(vblint),
	.int2(int2),
	.int3(int3),
	.int6(int6),
	.blckint(blckint),
	.syncint(syncint),
	.audint(audint),
	.audpen(audpen),
	.rbfmirror(rbfmirror),
	._ipl(_ipl)
);

//instantiate floppy controller / flashdrive host interface
floppy pf1
(
	.clk(clk),
	.reset(reset),
  .ntsc(ntsc),
  .sof(sof),
	.enable(dsken),
	.reg_address_in(reg_address_in),
	.data_in(data_in),
	.data_out(diskdata_out),
	.dmal(disk_dmal),
	.dmas(disk_dmas),
	._step(_step),
	.direc(direc),
	._sel(_sel),
	.side(side),
	._motor(_motor),
	._track0(_track0),
	._change(_change),
	._ready(_ready),
	._wprot(_wprot),
  .index(index),
	.blckint(blckint),
	.syncint(syncint),
	.wordsync(adkcon[10]),
	._scs(_scs),
	.sdi(sdi),
	.sdo(sdo),
	.sck(sck),
	
	.disk_led(disk_led),
	.floppy_drives(floppy_drives),

	.direct_scs(direct_scs),
	.direct_sdi(direct_sdi),
	.hdd_cmd_req(hdd_cmd_req),
	.hdd_dat_req(hdd_dat_req),
	.hdd_addr(hdd_addr),
	.hdd_data_out(hdd_data_out),
	.hdd_data_in(hdd_data_in),
	.hdd_wr(hdd_wr),
	.hdd_status_wr(hdd_status_wr),
	.hdd_data_wr(hdd_data_wr),
	.hdd_data_rd(hdd_data_rd),
  // fifo / track display
	.trackdisp(trackdisp),
	.secdisp(secdisp),
  .floppy_fwr (floppy_fwr),
  .floppy_frd (floppy_frd)
);

//instantiate audio controller
audio ad1
(
	.clk(clk),
  .clk28m(clk28m),
	.cck(cck),
	.reset(reset),
	.strhor(strhor),
	.reg_address_in(reg_address_in),
	.data_in(data_in),
	.dmaena(auden[3:0]),
	.audint(audint[3:0]),
	.audpen(audpen),
	.dmal(audio_dmal),
	.dmas(audio_dmas),
	.left(left),
	.right(right),	
	.ldata(ldata),
	.rdata(rdata)	
);

//--------------------------------------------------------------------------------------

endmodule

//--------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------

// interrupt controller //
module intcontroller
(
	input 	clk,		    	//bus clock
	input 	reset,			   	//reset 
	input 	[8:1] reg_address_in,	//register address inputs
	input	[15:0] data_in,		//bus data in
	output	[15:0] data_out,		//bus data out
	input	rxint,				//uart receive interrupt
	input	txint,				//uart transmit interrupt
  input vblint,         // start of video frame
	input	int2,				//level 2 interrupt
	input	int3,				//level 3 interrupt
	input	int6,				//level 6 interrupt
	input	blckint,			//disk block finished interrupt
	input	syncint,			//disk syncword match interrupt
	input	[3:0] audint,		//audio channels 0,1,2,3 interrupts
	output	[3:0] audpen,		//mirror of audio interrupts for audio controller
	output	rbfmirror,			//mirror of serial receive interrupt for uart SERDATR register
	output	reg [2:0] _ipl		//m68k interrupt request
);

//register names and addresses		
parameter INTENAR = 9'h01c;
parameter INTREQR = 9'h01e;
parameter INTENA  = 9'h09a;
parameter INTREQ  = 9'h09c;

//local signals
reg		[14:0] intena;			//int enable write register
reg 	[15:0] intenar;			//int enable read register
reg		[14:0] intreq;			//int request register
reg		[15:0] intreqr;			//int request readback

//rbf mirror out
assign rbfmirror = intreq[11];

//audio mirror out
assign audpen[3:0] = intreq[10:7];

//data_out	multiplexer
assign data_out = intenar | intreqr;

//intena register
always @(posedge clk)
	if (reset)
		intena <= 0;
	else if (reg_address_in[8:1]==INTENA[8:1])
	begin
		if (data_in[15])
			intena[14:0] <= intena[14:0] | data_in[14:0];
		else
			intena[14:0] <= intena[14:0] & (~data_in[14:0]);	
	end

//intenar register
always @(reg_address_in or intena)
	if (reg_address_in[8:1]==INTENAR[8:1])
		intenar[15:0] = {1'b0,intena[14:0]};
	else
		intenar = 16'd0;

//intreqr register
always @(reg_address_in or intreq)
	if (reg_address_in[8:1]==INTREQR[8:1])
		intreqr[15:0] = {1'b0,intreq[14:0]};
	else
		intreqr = 16'd0;

// control all interrupts, intterupts are registered at the rising edge of clk
reg [14:0]tmp;

always @(reg_address_in or data_in or intreq)
	//check if we are addressed and some bits must change
	//(generate mask tmp[13:0])
	if (reg_address_in[8:1]==INTREQ[8:1])
	begin
		if (data_in[15])
			tmp[14:0] = intreq[14:0] | data_in[14:0];
		else
			tmp[14:0] = intreq[14:0] & (~data_in[14:0]);	
 	end
	else
		tmp[14:0] = intreq[14:0];
		
always @(posedge clk)
begin
	if (reset)//synchronous reset
		intreq <= 0;
	else 
	begin
		//transmit buffer empty interrupt
		intreq[0] <= tmp[0] | txint;
		//diskblock finished
		intreq[1] <= tmp[1] | blckint;
		//software interrupt
		intreq[2] <= tmp[2];
		//I/O ports and timers
		intreq[3] <= tmp[3] | int2;
		//Copper
		intreq[4] <= tmp[4];
		//start of vertical blank
		intreq[5] <= tmp[5] | vblint;
		//blitter finished
		intreq[6] <= tmp[6] | int3;
		//audio channel 0
		intreq[7] <= tmp[7] | audint[0];
		//audio channel 1
		intreq[8] <= tmp[8] | audint[1];
		//audio channel 2
		intreq[9] <= tmp[9] | audint[2];
		//audio channel 3
		intreq[10] <= tmp[10] | audint[3];
		//serial port receive interrupt
		intreq[11] <= tmp[11] | rxint;
		//disk sync register matches disk data
		intreq[12] <= tmp[12] | syncint;
		//external interrupt
		intreq[13] <= tmp[13] | int6;
		//undocumented interrupt
		intreq[14] <= tmp[14];
	end
end						  

//create m68k interrupt request signals
reg	[14:0]intreqena;
always @(intena or intreq)
begin
	//and int enable and request signals together
	if (intena[14])
		intreqena[14:0] = intreq[14:0] & intena[14:0];
	else
		intreqena[14:0] = 15'b000_0000_0000_0000;	
end

//interrupt priority encoder
always @(posedge clk)
begin
	casez (intreqena[14:0])
		15'b1?????????????? : _ipl <= 1;
		15'b01????????????? : _ipl <= 1;
		15'b001???????????? : _ipl <= 2;
		15'b0001??????????? : _ipl <= 2;
		15'b00001?????????? : _ipl <= 3;
		15'b000001????????? : _ipl <= 3;
		15'b0000001???????? : _ipl <= 3;
		15'b00000001??????? : _ipl <= 3;
		15'b000000001?????? : _ipl <= 4;
		15'b0000000001????? : _ipl <= 4;
		15'b00000000001???? : _ipl <= 4;
		15'b000000000001??? : _ipl <= 5;
		15'b0000000000001?? : _ipl <= 6;
		15'b00000000000001? : _ipl <= 6;
		15'b000000000000001 : _ipl <= 6;
		15'b000000000000000 : _ipl <= 7;
		default:			  _ipl <= 7;
	endcase
end

endmodule

//--------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------

module uart (
  input  wire           clk,
  input  wire           reset,
  input  wire [  8-1:0] rga_i,
  input  wire [ 16-1:0] data_i,
  output wire [ 16-1:0] data_o,
  input  wire           uartbrk,
  input  wire           rbfmirror,
  output wire           txint,
  output wire           rxint,
  output wire           txd,
  input  wire           rxd
);


//// registers ////
localparam REG_SERDAT  = 9'h030;
localparam REG_SERDATR = 9'h018;
localparam REG_SERPER  = 9'h032;


//// bits ////
localparam LONG_BIT  = 15;
localparam OVRUN_BIT = 15-11;
localparam RBF_BIT   = 14-11;
localparam TBE_BIT   = 13-11;
localparam TSRE_BIT  = 12-11;
localparam RXD_BIT   = 11-11;


//// RX input sync ////
reg  [  2-1:0] rxd_sync = 2'b11;
wire           rxds;
always @ (posedge clk) begin
  rxd_sync <= #1 {rxd_sync[0],rxd};
end
assign rxds = rxd_sync[1];


//// write registers ////

// SERPER
reg  [ 16-1:0] serper = 16'h0000;
always @ (posedge clk) begin
  if (rga_i == REG_SERPER[8:1])
    serper <= #1 data_i;
end

// SERDAT
reg  [ 16-1:0] serdat = 16'h0000;
always @ (posedge clk) begin
  if (rga_i == REG_SERDAT[8:1])
    serdat <= #1 data_i;
end


//// TX ////
localparam [  2-1:0] TX_IDLE=2'd0, TX_SHIFT=2'd2;
reg  [  2-1:0] tx_state;
reg  [ 16-1:0] tx_cnt;
reg  [ 16-1:0] tx_shift;
reg            tx_txd;
reg            tx_irq;
reg            tx_tbe;
reg            tx_tsre;

always @ (posedge clk) begin
  if (reset) begin
    tx_state  <= #1 TX_IDLE;
    tx_txd    <= #1 1'b1;
    tx_irq    <= #1 1'b0;
    tx_tbe    <= #1 1'b1;
    tx_tsre   <= #1 1'b1;
  end else begin
    case (tx_state)
      TX_IDLE : begin
        // txd pin inactive in idle state
        tx_txd <= #1 1'b1;
        // check if new data loaded to serdat register
        if (!tx_tbe) begin
          // set interrupt request
          tx_irq <= #1 1'b1;
          // data buffer empty again
          //tx_tbe <= #1 1'b1;
          // generate start bit
          tx_txd <= #1 1'b0;
          // pass data to a shift register
          tx_tsre <= #1 1'b0;
          tx_shift <= #1 serdat;
          // reload period register
          tx_cnt <= #1 {serper[14:0], 1'b1};
          // start bitstream generation
          tx_state <= #1 TX_SHIFT;
        end
      end
      TX_SHIFT: begin
        // clear interrupt request, active by 1 cycle of clk
        tx_irq <= #1 1'b0;
        // count bit period
        if (tx_cnt == 16'd0) begin
          // check if any bit left to send out
          if (tx_shift == 16'd0) begin
            // set TSRE flag when serdat register is empty
            if (tx_tbe) tx_tsre <= #1 1'b1;
            // data sent, go to idle state
            tx_state <= #1 TX_IDLE;
          end else begin
            // reload period counter
            tx_cnt <= #1 {serper[14:0], 1'b1};
            // update shift register and txd pin
            tx_shift <= #1 {1'b0, tx_shift[15:1]};
            tx_txd <= #1 tx_shift[0];
          end
        end else begin
          // decrement period counter
          tx_cnt <= #1 tx_cnt - 16'd1;
        end
      end
      default: begin
        // force idle state
        tx_state <= #1 TX_IDLE;
      end
    endcase
    // force break char when requested
    if (uartbrk) tx_txd <= #1 1'b0;
    // handle tbe bit
    //if (rga_i == REG_SERDAT[8:1]) tx_tbe <= #1 1'b0;
    tx_tbe <= #1 (rga_i == REG_SERDAT[8:1]) ? 1'b0 : ((tx_state == TX_IDLE) ? 1'b1 : tx_tbe);
  end
end


//// RX ////
localparam [  2-1:0] RX_IDLE=2'd0, RX_START=2'd1, RX_SHIFT=2'd2;
reg  [  2-1:0] rx_state;
reg  [ 16-1:0] rx_cnt;
reg  [ 10-1:0] rx_shift;
reg  [ 10-1:0] rx_data;
reg            rx_rbf;
reg            rx_rxd;
reg            rx_irq;
reg            rx_ovrun;

always @ (posedge clk) begin
  if (reset) begin
    rx_state <= #1 RX_IDLE;
    rx_rbf   <= #1 1'b0;
    rx_rxd   <= #1 1'b1;
    rx_irq   <= #1 1'b0;
    rx_ovrun <= #1 1'b0;
  end else begin
    case (rx_state)
      RX_IDLE : begin
        // clear interrupt request
        rx_irq <= #1 1'b0;
        // wait for start condition
        if (rx_rxd && !rxds) begin
          // setup received data format
          rx_shift <= #1 {serper[LONG_BIT], {9{1'b1}}};
          rx_cnt <= #1 {1'b0, serper[14:0]};
          // wait for a sampling point of a start bit
          rx_state <= #1 RX_START;
        end
      end
      RX_START : begin
        // wait for a sampling point
        if (rx_cnt == 16'h0) begin
          // sample rxd signal
          if (!rxds) begin
            // start bit valid, start data shifting
            rx_shift <= #1 {rxds, rx_shift[9:1]};
            // restart period counter
            rx_cnt <= #1 {serper[14:0], 1'b1};
            // start data bits sampling
            rx_state <= #1 RX_SHIFT;
          end else begin
            // start bit invalid, return into idle state
            rx_state <= #1 RX_IDLE;
          end
        end else begin
          rx_cnt <= #1 rx_cnt - 16'd1;
        end
        // check false start condition
        if (!rx_rxd && rxds) begin
          rx_state <= #1 RX_IDLE;
        end
      end
      RX_SHIFT : begin
        // wait for bit period
        if (rx_cnt == 16'h0) begin
          // store received bit
          rx_shift <= #1 {rxds, rx_shift[9:1]};
          // restart period counter
          rx_cnt <= #1 {serper[14:0], 1'b1};
          // check for all bits received
          if (rx_shift[0] == 1'b0) begin
            // set interrupt request flag
            rx_irq <= #1 1'b1;
            // handle OVRUN bit
            //rx_ovrun <= #1 rbfmirror;
            // update receive buffer
            rx_data[9] <= #1 rxds;
            if (serper[LONG_BIT]) begin
              rx_data[8:0] <= #1 rx_shift[9:1];
            end else begin
              rx_data[8:0] <= #1 {rxds, rx_shift[9:2]};
            end
            // go to idle state
            rx_state <= #1 RX_IDLE;
          end
        end else begin
          rx_cnt <= #1 rx_cnt - 16'd1;
        end
      end
      default : begin
        // force idle state
        rx_state <= #1 RX_IDLE;
      end
    endcase
    // register rxds
    rx_rxd <= #1 rxds;
    // handle ovrun bit
    rx_rbf <= #1 rbfmirror;
    //if (!rbfmirror &&  rx_rbf) rx_ovrun <= #1 1'b0;
    rx_ovrun <= #1 (!rbfmirror &&  rx_rbf) ? 1'b0 : (((rx_state == RX_SHIFT) && ~|rx_cnt && !rx_shift[0]) ? rbfmirror : rx_ovrun);
  end
end


//// outputs ////

// SERDATR
wire [  5-1:0] serdatr;
assign serdatr  = {rx_ovrun, rx_rbf, tx_tbe, tx_tsre, rx_rxd};

// interrupts
assign txint = tx_irq;
assign rxint = rx_irq;

// uart output
assign txd   = tx_txd;

// reg bus output
assign data_o = (rga_i == REG_SERDATR[8:1]) ? {serdatr, 1'b0, rx_data} : 16'h0000;


endmodule

