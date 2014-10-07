// bit plane dma engine


module agnus_bitplanedma
(
	input 	clk,		    			// bus clock
  input clk7_en,
	input	reset,						// reset
	input	ecs,						// ddfstrt/ddfstop ECS bits enable
  input a1k,              // DIP Agnus feature
  input sof,              // start of frame
	input	dmaena,						// enable dma input
	input	[10:0] vpos,				// vertical position counter
	input	[8:0] hpos,					// agnus internal horizontal position counter (advanced by 4 CCK)
	output	dma,						// true if bitplane dma engine uses it's cycle
	input 	[8:1] reg_address_in,		// register address inputs
	output 	reg [8:1] reg_address_out,	// register address outputs
	input	[15:0] data_in,				// bus data in
	output	[20:1] address_out			// chip address out
);

localparam GND = 1'b0;
localparam VCC = 1'b1;

// register names and adresses
localparam DIWSTRT   = 9'h08E;
localparam DIWSTOP   = 9'h090;
localparam DIWHIGH   = 9'h1E4;
localparam BPLPTBASE = 9'h0E0;		// bitplane pointers base address
localparam DDFSTRT   = 9'h092;
localparam DDFSTOP   = 9'h094;
localparam BPL1MOD   = 9'h108;
localparam BPL2MOD   = 9'h10a;
localparam BPLCON0   = 9'h100;

// local signals
reg		[8:2] ddfstrt;				// display data fetch start
reg 	[8:2] ddfstop; 				// display data fetch stop
reg		[15:1] bpl1mod;				// modulo for odd bitplanes
reg		[15:1] bpl2mod;				// modulo for even bitplanes
reg		[5:0] bplcon0;				// bitplane control (SHRES, HIRES and BPU bits)
reg		[5:0] bplcon0_delayed;		// delayed bplcon0 (compatibility)
reg		[5:0] bplcon0_delay [1:0];

wire 	hires;						// bplcon0 - high resolution display mode
wire	shres;						// bplcon0 - super high resolution display mode
wire	[3:0] bpu;					// bplcon0 - selected number of bitplanes

reg		[20:1] newpt;				// new pointer
reg 	[20:16] bplpth [7:0];		// upper 5 bits bitplane pointers
reg 	[15:1] bplptl [7:0];		// lower 16 bits bitplane pointers
reg		[2:0] plane;				// plane pointer select
wire	[2:0] planes;				// selected number of planes

wire	mod;						// end of data fetch, add modulo

reg		hardena;					// hardware display data fetch enable ($18-$D8)
reg 	softena;					// software display data fetch enable
reg 	ddfena;						// combined display data fetch
reg   ddfena_0;

reg 	[2:0] ddfseq;				// bitplane DMA fetch cycle sequencer
reg 	ddfrun;						// set when display dma fetches data
reg		ddfend;						// indicates the last display data fetch sequence

reg		[1:0] dmaena_delayed;		// delayed bitplane dma enable signal (compatibility)

reg		[10:0] vdiwstrt;			// vertical display window start position
reg		[10:0] vdiwstop;			// vertical display window stop position
reg		vdiwena;					// vertical display window enable

//--------------------------------------------------------------------------------------

// display data fetches can take place during blanking (when vdiwstrt is set to 0 the display is distorted)
// diw vstop/vstart conditiotions are continuously checked
// first visible line $1A
// vstop forced by vbl
// last visible line is displayed in colour 0
// vdiwstop = N (M>N)
// wait vpos N-1 hpos $d7, move vdiwstop M : effective
// wait vpos N-1 hpos $d9, move vdiwstop M : non effective

// display not active:
// wait vpos N hpos $dd, move vdiwstrt N : display starts
// wait vpos N hpos $df, move vdiwstrt N : display doesn't start

// if vdiwstrt==vdiwstop : no display
// if vdiwstrt>vdiwstop : display from vdiwstrt till screen bottom

// display dma can be started in the middle of a scanline by setting vdiwstrt to the current line number (ECS only)
// OCS: the display starts when ddfstrt condition is true
// display dma can be stopped in the middle of a scanline by setting vdiwstop to the current line number
// if display starts all enabled planes are fetched
// if hstop is set 4 CCKs after hstart to the same line no display occurs
// if hstop is set 8 CCKs after hstart one 16 pixel chunk is displayed (lowres)

// ECS: DDFSTOP = $E2($E3) display data fetch stopped ($00 stops the display as well)
// ECS: DDFSTOP = $E4 display data fetch not stopped

//--------------------------------------------------------------------------------------

// vdiwstart
always @(posedge clk)
  if (clk7_en) begin
  	if (reg_address_in[8:1]==DIWSTRT[8:1])
  		vdiwstrt[7:0] <= data_in[15:8];
  end

always @(posedge clk)
  if (clk7_en) begin
  	if (reg_address_in[8:1]==DIWSTRT[8:1])
  		vdiwstrt[10:8] <= 3'b000; // reset V10-V9 when writing DIWSTRT
  	else if (reg_address_in[8:1]==DIWHIGH[8:1] && ecs) // ECS
  		vdiwstrt[10:8] <= data_in[2:0];
  end

// diwstop
always @(posedge clk)
  if (clk7_en) begin
  	if (reg_address_in[8:1]==DIWSTOP[8:1])
  		vdiwstop[7:0] <= data_in[15:8];
  end

always @(posedge clk)
  if (clk7_en) begin
  	if (reg_address_in[8:1]==DIWSTOP[8:1])
  		vdiwstop[10:8] <= {2'b00,~data_in[15]}; // V8 = ~V7
  	else if (reg_address_in[8:1]==DIWHIGH[8:1] && ecs) // ECS
  		vdiwstop[10:8] <= data_in[10:8];
  end

// vertical display window enable
always @(posedge clk)
  if (clk7_en) begin
  	if (sof && ~a1k || vpos[10:0]==0 && a1k || vpos[10:0]==vdiwstop[10:0]) // DIP Agnus can't start display DMA at scanline 0
  		vdiwena <= GND;
  	else if (vpos[10:0]==vdiwstrt[10:0])
  		vdiwena <= VCC;
  end

//--------------------------------------------------------------------------------------

wire	[2:0] bplptr_sel;	// bitplane pointer select

assign bplptr_sel = dma ? plane : reg_address_in[4:2];

// high word pointer register bank (implemented using distributed ram)
wire [20:16] bplpth_in;

assign bplpth_in = dma ? newpt[20:16] : data_in[4:0];

always @(posedge clk)
  if (clk7_en) begin
  	if (dma || ((reg_address_in[8:5]==BPLPTBASE[8:5]) && !reg_address_in[1])) // if bitplane dma cycle or bus write
  		bplpth[bplptr_sel] <= bplpth_in;
  end

assign address_out[20:16] = bplpth[plane];

// low word pointer register bank (implemented using distributed ram)
wire [15:1] bplptl_in;

assign bplptl_in = dma ? newpt[15:1] : data_in[15:1];

always @(posedge clk)
  if (clk7_en) begin
  	if (dma || ((reg_address_in[8:5]==BPLPTBASE[8:5]) && reg_address_in[1])) // if bitplane dma cycle or bus write
  		bplptl[bplptr_sel] <= bplptl_in;
  end

assign address_out[15:1] = bplptl[plane];

//--------------------------------------------------------------------------------------

wire ddfstrt_sel;

assign ddfstrt_sel = reg_address_in[8:1]==DDFSTRT[8:1] ? VCC : GND;

// write ddfstrt and ddfstop registers
always @(posedge clk)
  if (clk7_en) begin
  	if (ddfstrt_sel)
  		ddfstrt[8:2] <= data_in[7:1];
  end

always @(posedge clk)
  if (clk7_en) begin
  	if (reg_address_in[8:1]==DDFSTOP[8:1])
  		ddfstop[8:2] <= data_in[7:1];
  end

// write modulo registers
always @(posedge clk)
  if (clk7_en) begin
  	if (reg_address_in[8:1]==BPL1MOD[8:1])
  		bpl1mod[15:1] <= data_in[15:1];
  end

always @(posedge clk)
  if (clk7_en) begin
  	if (reg_address_in[8:1]==BPL2MOD[8:1])
  		bpl2mod[15:1] <= data_in[15:1];
  end

// write those parts of bplcon0 register that are relevant to bitplane DMA sequencer
always @(posedge clk)
  if (clk7_en) begin
  	if (reset)
  		bplcon0 <= 6'b00_0000;
  	else if (reg_address_in[8:1]==BPLCON0[8:1])
  		bplcon0 <= {data_in[6],data_in[15],data_in[4],data_in[14:12]}; //SHRES,HIRES,BPU3,BPU2,BPU1,BPU0
  end

////delay by 8 clocks (in real Amiga DMA sequencer is pipelined and features a delay of 3 CCKs)
// delayed BPLCON0 by 3 CCKs
always @(posedge clk) begin
  if (clk7_en) begin
    if (hpos[0]) begin
      bplcon0_delay[0] <= bplcon0;
      bplcon0_delay[1] <= bplcon0_delay[0];
      bplcon0_delayed  <= bplcon0_delay[1];
    end
  end
end

//// delayed BPLCON0 by 3 CCKs
//   SRL16E #(
//      .INIT(16'h0000)
//   ) BPLCON0_DELAY [5:0] (
//      .Q(bplcon0_delayed),
//      .A0(GND),
//      .A1(VCC),
//      .A2(GND),
//      .A3(GND),
//      .CE(hpos[0]),
//      .CLK(clk),
//      .D(bplcon0)
//   );

assign shres = ecs & bplcon0_delayed[5];
assign hires = bplcon0_delayed[4];
assign bpu = bplcon0_delayed[3:0];

// bitplane dma enable bit delayed by 4 CCKs
always @(posedge clk)
  if (clk7_en) begin
  	if (hpos[1:0]==2'b11)
  		dmaena_delayed[1:0] <= {dmaena_delayed[0], dmaena};
  end

//--------------------------------------------------------------------------------------
/*
	Display DMA can start and stop on any (within hardware limits) 2-CCK boundary regardless of a choosen resolution.
	Non-aligned start position causes addition of extra shift value to horizontal scroll.
	This values depends on which horizontal position BPL0DAT register is written.
	One full display DMA sequence lasts 8 CCKs. When sequence restarts finish condition is checked (ddfstop position passed).
	The last DMA sequence adds modulo to bitplane pointers.
	The state of BPLCON0 is delayed by 3 CCKs (real Agnus has pipelining in DMA engine).

	ddf start condition is checked 2 CCKs before actual position, ddf stop is checked 4 CCKs in advance <- that's not true
	ddf start condition is checked 4 CCKs before the first bitplane data fetch
	magic: writing DDFSTRT register when the hpos=ddfstrt doesn't start the bitplane DMA
*/

reg soft_start;
reg soft_stop;
reg hard_start;
reg hard_stop;

always @(posedge clk)
  if (clk7_en) begin
  	if (hpos[0])
  		if (hpos[8:1]=={ddfstrt[8:3], ddfstrt[2] & ecs, 1'b0})
  			soft_start <= VCC;
  		else
  			soft_start <= GND;
  end

always @(posedge clk)
  if (clk7_en) begin
  	if (hpos[0])
  		if (hpos[8:1]=={ddfstop[8:3], ddfstop[2] & ecs, 1'b0})
  			soft_stop <= VCC;
  		else
  			soft_stop <= GND;
  end

always @(posedge clk)
  if (clk7_en) begin
  	if (hpos[0])
  		if (hpos[8:1]==8'h18)
  			hard_start <= VCC;
  		else
  			hard_start <= GND;
  end

always @(posedge clk)
  if (clk7_en) begin
  	if (hpos[0])
  		if (hpos[8:1]==8'hD8)
  			hard_stop <= VCC;
  		else
  			hard_stop <= GND;
  end

// softena : software display data fetch window
always @(posedge clk)
  if (clk7_en) begin
  	if (hpos[0])
  		if (soft_start && (ecs || vdiwena && dmaena) && !ddfstrt_sel) // OCS: display can start only when vdiwena condition is true
  			softena <= VCC;
  		else if (soft_stop || !ecs && hard_stop)
  			softena <= GND;
  end

// hardena : hardware limits of display data fetch
always @(posedge clk)
  if (clk7_en) begin
  	if (hpos[0])
  		if (hard_start)
  			hardena <= VCC;
  		else if (hard_stop)
  			hardena <= GND;
  end

// ddfena signal is set and cleared 2 CCKs before actual transfer should start or stop
//assign ddfena = hardena & softena;

// delayed DDFENA by 2 CCKs
always @(posedge clk) begin
  if (clk7_en) begin
    if (hpos[0])
    begin
      ddfena_0 <= hardena & softena;
      ddfena <= ddfena_0;
    end
  end
end

//SRL16E #(
//      .INIT(16'h0000)
//   ) DDFENA_DELAY (
//      .Q(ddfena),
//      .A0(VCC),
//      .A1(GND),
//      .A2(GND),
//      .A3(GND),
//      .CE(hpos[0]),
//      .CLK(clk),
//      .D(hardena & softena)
//   );

// this signal enables bitplane DMA sequencer
always @(posedge clk)
  if (clk7_en) begin
  	if (hpos[0]) //cycle alligment
  		if (ddfena && vdiwena && !hpos[1] && dmaena_delayed[0]) // bitplane DMA starts at odd timeslot
  			ddfrun <= 1;
  		else if ((ddfend || !vdiwena) && ddfseq==7) // cleared at the end of last bitplane DMA cycle
  			ddfrun <= 0;
  end

// bitplane fetch dma sequence counter (1 bitplane DMA sequence lasts 8 CCK cycles)
always @(posedge clk)
  if (clk7_en) begin
  	if (hpos[0]) // cycle alligment
  		if (ddfrun) // if enabled go to the next state
  			ddfseq <= ddfseq + 1'b1;
  		else
  			ddfseq <= 0;
  end

// the last sequence of the bitplane DMA (time to add modulo)
always @(posedge clk)
  if (clk7_en) begin
  	if (hpos[0] && ddfseq==7)
  		if (ddfend) // cleared if set
  			ddfend <= 0;
  		else if (!ddfena) // set during the last bitplane dma sequence
  			ddfend <= 1;
  end

// signal for adding modulo to the bitplane pointers
assign mod = shres ? ddfend & ddfseq[2] & ddfseq[1] : hires ? ddfend & ddfseq[2] : ddfend;

// plane number encoder
always @(*)
	if (shres) // super high resolution (35ns pixel clock)
		plane = {2'b00,~ddfseq[0]};
	else if (hires) // high resolution (70ns pixel clock)
		plane = {1'b0,~ddfseq[0],~ddfseq[1]};
	else // low resolution (140ns pixel clock)
		plane = {~ddfseq[0],~ddfseq[1],~ddfseq[2]};

// corrected number of selected planes
assign planes = bpu[2:0]==3'b111 ? 3'b100 : bpu[2:0];

// generate dma signal
// for a dma to happen plane must be less than BPU, dma must be enabled and data fetch must be true
assign dma = ddfrun && dmaena_delayed[1] && hpos[0] && (plane[2:0] < bpu[2:0]) ? 1'b1 : 1'b0;

//--------------------------------------------------------------------------------------

// dma pointer arithmetic unit
always @(*)
	if (mod)
	begin
		if (plane[0]) // even plane modulo
			newpt[20:1] = address_out[20:1] + {{5{bpl2mod[15]}},bpl2mod[15:1]} + 1'b1;
		else // odd plane modulo
			newpt[20:1] = address_out[20:1] + {{5{bpl1mod[15]}},bpl1mod[15:1]} + 1'b1;
	end
	else
		newpt[20:1] = address_out[20:1] + 1'b1;

// Denise bitplane shift registers address lookup table
always @(*)
begin
	case (plane)
		3'b000 : reg_address_out[8:1] = 8'h88;
		3'b001 : reg_address_out[8:1] = 8'h89;
		3'b010 : reg_address_out[8:1] = 8'h8A;
		3'b011 : reg_address_out[8:1] = 8'h8B;
		3'b100 : reg_address_out[8:1] = 8'h8C;
		3'b101 : reg_address_out[8:1] = 8'h8D;
		3'b110 : reg_address_out[8:1] = 8'h8E;	// this is required for AGA only
		3'b111 : reg_address_out[8:1] = 8'h8F;	// this is required for AGA only
	endcase
end

//--------------------------------------------------------------------------------------


endmodule

