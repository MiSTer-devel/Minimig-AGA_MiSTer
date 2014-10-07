// >>> Audio DMA Engine <<<
//
// 2 dma cycle types are defined:
// - restart pointer (go back to the beginning of the sample): dmas active
// - advance pointer to the next word of the sample: dmas inactive
//
// dma slot allocation:
// channel #0 : $0E
// channel #1 : $10
// channel #2 : $12
// channel #3 : $14

module agnus_audiodma
(
	input 	clk,		    			//bus clock
  input clk7_en,
	output	dma,						//true if audio dma engine uses it's cycle
	input	[3:0] audio_dmal,			//audio dma data transfer request (from Paula)
	input	[3:0] audio_dmas,			//audio dma location pointer restart (from Paula)
	input	[8:0] hpos,					//horizontal beam counter
	input 	[8:1] reg_address_in,		//register address inputs
	output 	reg [8:1] reg_address_out,	//register address outputs
	input	[15:0] data_in,				//bus data in
	output	[20:1] address_out			//chip address out
);

//register names and adresses
parameter AUD0DAT = 9'h0AA;
parameter AUD1DAT = 9'h0BA;
parameter AUD2DAT = 9'h0CA;
parameter AUD3DAT = 9'h0DA;

//local signals
wire	audlcena;				//audio dma location pointer register address enable
wire	[1:0] audlcsel;			//audio dma location pointer select
reg		[20:16] audlch [3:0];	//audio dma location pointer bank (high word)
reg		[15:1] audlcl [3:0];	//audio dma location pointer bank (low word)
wire	[20:1] audlcout;		//audio dma location pointer bank output
reg		[20:1] audpt [3:0];		//audio dma pointer bank
wire	[20:1] audptout;		//audio dma pointer bank output
reg		[1:0]  channel;			//audio dma channel select
reg		dmal;
reg		dmas;

//--------------------------------------------------------------------------------------
// location registers address enable
// active when any of the location registers is addressed
// $A0-$A3, $B0-$B3, $C0-$C3, $D0-$D3,
assign audlcena = ~reg_address_in[8] & reg_address_in[7] & (reg_address_in[6]^reg_address_in[5]) & ~reg_address_in[3] & ~reg_address_in[2];

//location register channel select
assign audlcsel = {~reg_address_in[5],reg_address_in[4]};

//audio location register bank
always @(posedge clk)
  if (clk7_en) begin
  	if (audlcena & ~reg_address_in[1]) // AUDxLCH
  		audlch[audlcsel] <= data_in[4:0];
  end

always @(posedge clk)
  if (clk7_en) begin
  	if (audlcena & reg_address_in[1]) // AUDxLCL
  		audlcl[audlcsel] <= data_in[15:1];
  end

//get audio location pointer
assign audlcout = {audlch[channel],audlcl[channel]};

//--------------------------------------------------------------------------------------
//dma cycle allocation
always @(*)
	case (hpos)
		9'b0001_0010_1 : dmal = audio_dmal[0]; //$0E
		9'b0001_0100_1 : dmal = audio_dmal[1]; //$10
		9'b0001_0110_1 : dmal = audio_dmal[2]; //$12
		9'b0001_1000_1 : dmal = audio_dmal[3]; //$14
		default        : dmal = 0;
	endcase

//dma cycle request
assign dma = dmal;

//channel dmas encoding
always @(*)
	case (hpos)
		9'b0001_0010_1 : dmas = audio_dmas[0]; //$0E
		9'b0001_0100_1 : dmas = audio_dmas[1]; //$10
		9'b0001_0110_1 : dmas = audio_dmas[2]; //$12
		9'b0001_1000_1 : dmas = audio_dmas[3]; //$14
		default        : dmas = 0;
	endcase

//dma channel select
always @(*)
	case (hpos[3:2])
		2'b01 : channel = 0; //$0E
		2'b10 : channel = 1; //$10
		2'b11 : channel = 2; //$12
		2'b00 : channel = 3; //$14
	endcase

// memory address output
assign address_out[20:1] = audptout[20:1];

// audio pointers register bank (implemented using distributed ram) and ALU
always @(posedge clk)
  if (clk7_en) begin
  	if (dmal)
  		audpt[channel] <= dmas ? audlcout[20:1] : audptout[20:1] + 1'b1;
  end

// audio pointer output
assign audptout[20:1] = audpt[channel];

//register address output multiplexer
always @(*)
	case (channel)
		0 : reg_address_out[8:1] = AUD0DAT[8:1];
		1 : reg_address_out[8:1] = AUD1DAT[8:1];
		2 : reg_address_out[8:1] = AUD2DAT[8:1];
		3 : reg_address_out[8:1] = AUD3DAT[8:1];
	endcase

//--------------------------------------------------------------------------------------


endmodule

