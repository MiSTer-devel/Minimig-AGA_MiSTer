//PS2 mouse controller.
//This module decodes the standard 3 byte packet of an PS/2 compatible 2 or 3 button mouse, or alternatively, if an intellimouse is detected, a 4-byte packet is supported with scrollwheel support.
//The module also automatically handles power-up initailzation of the mouse.


module userio_ps2mouse
(
	input 	clk,		    	// 28MHz clock
  input clk7_en,
	input 	reset,			   	//reset 
	inout	ps2mdat,			//mouse PS/2 data
	inout	ps2mclk,			//mouse PS/2 clk
  input [5:0] mou_emu,
  input sof,
  output  reg [7:0]zcount,  // mouse Z counter
	output	reg [7:0]ycount,	//mouse Y counter
	output	reg [7:0]xcount,	//mouse X counter
	output	reg _mleft,			//left mouse button output
	output	reg _mthird,		//third(middle) mouse button output
	output	reg _mright,		//right mouse button output
	input	test_load,			//load test value to mouse counter
	input	[15:0] test_data	//mouse counter test value
);

reg           mclkout;
wire          mdatout;
reg  [ 2-1:0] mdatr;
reg  [ 3-1:0] mclkr;

reg  [11-1:0] mreceive;
reg  [12-1:0] msend;
reg  [16-1:0] mtimer;
reg  [ 3-1:0] mstate;
reg  [ 3-1:0] mnext;

wire          mclkneg;
reg           mrreset;
wire          mrready;
reg           msreset;
wire          msready;
reg           mtreset;
wire          mtready;
wire          mthalf;
reg  [ 3-1:0] mpacket;
reg           intellimouse=0;
wire          mcmd_done;
reg  [ 4-1:0] mcmd_cnt=1;
reg           mcmd_inc=0;
reg  [12-1:0] mcmd;


// bidirectional open collector IO buffers
assign ps2mclk = (mclkout) ? 1'bz : 1'b0;
assign ps2mdat = (mdatout) ? 1'bz : 1'b0;

// input synchronization of external signals
always @ (posedge clk) begin
  if (clk7_en) begin
    mdatr[1:0] <= #1 {mdatr[0],   ps2mdat};
    mclkr[2:0] <= #1 {mclkr[1:0], ps2mclk};
  end
end

// detect mouse clock negative edge
assign mclkneg = mclkr[2] & !mclkr[1];

// PS2 mouse input shifter
always @ (posedge clk) begin
  if (clk7_en) begin
    if (mrreset)
      mreceive[10:0] <= #1 11'b11111111111;
    else if (mclkneg)
      mreceive[10:0] <= #1 {mdatr[1],mreceive[10:1]};
  end
end

assign mrready = !mreceive[0];

// PS2 mouse data counter
always @ (posedge clk) begin
  if (clk7_en) begin
    if (reset)
      mcmd_cnt <= #1 4'd0;
    else if (mcmd_inc && !mcmd_done)
      mcmd_cnt <= #1 mcmd_cnt + 4'd1;
  end
end

assign mcmd_done = (mcmd_cnt == 4'd9);

// mouse init commands
always @ (*) begin
  case (mcmd_cnt)
    //                GUARD STOP  PARITY DATA   START
    4'h0    : mcmd = {1'b1, 1'b1, 1'b1,  8'hff, 1'b0}; // reset
    4'h1    : mcmd = {1'b1, 1'b1, 1'b1,  8'hf3, 1'b0}; // set sample rate
    4'h2    : mcmd = {1'b1, 1'b1, 1'b0,  8'hc8, 1'b0}; // sample rate = 200
    4'h3    : mcmd = {1'b1, 1'b1, 1'b1,  8'hf3, 1'b0}; // set sample rate
    4'h4    : mcmd = {1'b1, 1'b1, 1'b0,  8'h64, 1'b0}; // sample rate = 100
    4'h5    : mcmd = {1'b1, 1'b1, 1'b1,  8'hf3, 1'b0}; // set sample rate
    4'h6    : mcmd = {1'b1, 1'b1, 1'b1,  8'h50, 1'b0}; // sample rate = 80
    4'h7    : mcmd = {1'b1, 1'b1, 1'b0,  8'hf2, 1'b0}; // read device type
    4'h8    : mcmd = {1'b1, 1'b1, 1'b0,  8'hf4, 1'b0}; // enable data reporting
    default : mcmd = {1'b1, 1'b1, 1'b0,  8'hf4, 1'b0}; // enable data reporting
  endcase
end

// PS2 mouse send shifter
always @ (posedge clk) begin
  if (clk7_en) begin
    if (msreset)
      msend[11:0] <= #1 mcmd;
    else if (!msready && mclkneg)
      msend[11:0] <= #1 {1'b0,msend[11:1]};
  end
end

assign msready = (msend[11:0]==12'b000000000001);
assign mdatout = msend[0];

// PS2 mouse timer
always @(posedge clk) begin
  if (clk7_en) begin
    if (mtreset)
      mtimer[15:0] <= #1 16'h0000;
    else
      mtimer[15:0] <= #1 mtimer[15:0] + 16'd1;
  end
end

assign mtready = (mtimer[15:0]==16'hffff);
assign mthalf = mtimer[11];

// PS2 mouse packet decoding and handling
always @ (posedge clk) begin
  if (clk7_en) begin
    if (reset) begin
      {_mthird,_mright,_mleft} <= #1 3'b111;
      xcount[7:0] <= #1 8'h00;
      ycount[7:0] <= #1 8'h00;
      zcount[7:0] <= #1 8'h00;
    end else begin
      if (test_load) // test value preload
        {ycount[7:2],xcount[7:2]} <= #1 {test_data[15:10],test_data[7:2]};
      else if (mpacket == 3'd1) // buttons
        {_mthird,_mright,_mleft} <= #1 ~mreceive[3:1];
      else if (mpacket == 3'd2) // delta X movement
        xcount[7:0] <= #1 xcount[7:0] +  mreceive[8:1];
      else if (mpacket == 3'd3) // delta Y movement
        ycount[7:0] <= #1 ycount[7:0] - mreceive[8:1];
      else if (mpacket == 3'd4) // delta Z movement
        zcount[7:0] <= #1 zcount[7:0] + {{4{mreceive[4]}}, mreceive[4:1]};
      else if (sof) begin
        if (mou_emu[3]) ycount <= #1 ycount - 1'b1;
        else if (mou_emu[2]) ycount <= #1 ycount + 1'b1;
        if (mou_emu[1]) xcount <= #1 xcount - 1'b1;
        else if (mou_emu[0]) xcount <= #1 xcount + 1'b1;
      end
    end
  end
end

// PS2 intellimouse flag
always @ (posedge clk) begin
  if (clk7_en) begin
    if (reset)
      intellimouse <= #1 1'b0;
    else if ((mpacket==3'd5) && (mreceive[2:1] == 2'b11))
      intellimouse <= #1 1'b1;
  end
end

// PS2 mouse state machine
always @ (posedge clk) begin
  if (clk7_en) begin
    if (reset || mtready)
      mstate <= #1 0;
    else
      mstate <= #1 mnext;
  end
end

always @ (*) begin
  mclkout  = 1'b1;
  mtreset  = 1'b1;
  mrreset  = 1'b0;
  msreset  = 1'b0;
  mpacket  = 3'd0;
  mcmd_inc = 1'b0;
  case(mstate)

    0 : begin
      // initialize mouse phase 0, start timer
      mtreset=1;
      mnext=1;
    end

    1 : begin
      //initialize mouse phase 1, hold clk low and reset send logic
      mclkout=0;
      mtreset=0;
      msreset=1;
      if (mthalf) begin
        // clk was low long enough, go to next state
        mnext=2;
      end else begin
        mnext=1;
      end
    end

    2 : begin
      // initialize mouse phase 2, send command/data to mouse
      mrreset=1;
      mtreset=0;
      if (msready) begin
        // command sent
        mcmd_inc = 1;
        case (mcmd_cnt)
          0 : mnext = 4;
          1 : mnext = 6;
          2 : mnext = 6;
          3 : mnext = 6;
          4 : mnext = 6;
          5 : mnext = 6;
          6 : mnext = 6;
          7 : mnext = 5;
          8 : mnext = 6;
          default : mnext = 6;
        endcase
      end else begin
        mnext=2;
      end
    end

    3 : begin
      // get first packet byte
      mtreset=1;
      if (mrready) begin
        // we got our first packet byte
        mpacket=1;
        mrreset=1;
        mnext=4;
      end else begin
        // we are still waiting
        mnext=3;
      end
    end

    4 : begin
      // get second packet byte
      mtreset=1;
      if (mrready) begin
        // we got our second packet byte
        mpacket=2;
        mrreset=1;
        mnext=5;
      end else begin
        // we are still waiting
        mnext=4;
      end
    end

    5 : begin
      // get third packet byte 
      mtreset=1;
      if (mrready) begin
        // we got our third packet byte
        mpacket=3;
        mrreset=1;
        mnext = (intellimouse || !mcmd_done) ? 6 : 3;
      end else begin
        // we are still waiting
        mnext=5;
      end
    end

    6 : begin
      // get fourth packet byte
      mtreset=1;
      if (mrready) begin
        // we got our fourth packet byte
        mpacket = (mcmd_cnt == 8) ? 5 : 4;
        mrreset=1;
        mnext = !mcmd_done ? 0 : 3;
      end else begin
        // we are still waiting
        mnext=6;
      end
    end

    default : begin
      //we should never come here
      mclkout=1'bx;
      mrreset=1'bx;
      mtreset=1'bx;
      msreset=1'bx;
      mpacket=3'bxxx;
      mnext=0;
    end

  endcase
end


endmodule

