// This module interfaces Minimig's synchronous bus to the 68SEC000 CPU
//
// cycle exact CIA interface:
// ECLK low for 6 cycles and high for 4
// data latched with falling edge of ECLK
// VPA sampled 3 CLKs before rising edge of ECLK
// VMA asserted one clock later if VPA recognized
// DTACK sampled one clock before ECLK falling edge
//
//             ___     ___     ___     ___     ___     ___     ___     ___     ___     ___     ___
// CLK     ___/   \___/   \___/   \___/   \___/   \___/   \___/   \___/   \___/   \___/   \___/   \___
//         ___     ___     ___     ___     ___     ___     ___     ___     ___     ___     ___     ___
// CPU_CLK    \___/   \___/   \___/   \___/   \___/   \___/   \___/   \___/   \___/   \___/   \___/
//         ___ _______ _______ _______ _______ _______ _______ _______ _______ _______ _______ _______
//         ___X___0___X___1___X___2___X___3___X___4___X___5___X___6___X___7___X___8___X___9___X___0___
//         ___                                                 _______________________________
// ECLK       \_______________________________________________/                               \_______
//                                    |       |_VMA_asserted                          
//                                    |_VPA_sampled                   _______________           ______
//                                                                            \\\\\\\\_________/       DTACK asserted (7MHz)
//                                                                                    |__DTACK_sampled (7MHz) 
//                                                                    _____________________     ______
//                                                                                         \___/       DTACK asserted (28MHz)
//                                                                                          |__DTACK_sampled (28MHz)
//
// NOTE: in 28MHz mode this timing model is not (yet?) supported, CPU talks to CIAs with no waitstates
//


module minimig_m68k_bridge
(
	input	clk,					// 28 MHz system clock
  input clk7_en,
  input clk7n_en,
  input blk,
	input	c1,						// clock enable signal
	input	c3,						// clock enable signal
	input	[9:0] eclk,				// ECLK enable signal
	input	vpa,					// valid peripheral address (CIAs)
	input	dbr, 					// data bus request, Gary keeps CPU off the bus (custom chips transfer data)
	input	dbs,					// data bus slowdown (access to chip ram or custom registers)
	input	xbs,					// cross bridge access (active dbr holds off CPU access)
  input nrdy,         // target device is not ready
	output	bls,					// blitter slowdown, tells the blitter that CPU wants the bus
	input	cck,					// colour clock enable, active when dma can access the memory bus
	input	cpu_speed,				// CPU speed select request
  input [3:0] memory_config,  // system memory config
	output	reg turbo,				// indicates current CPU speed mode
	input	_as,					// m68k adress strobe
	input	_lds,					// m68k lower data strobe d0-d7
	input	_uds,					// m68k upper data strobe d8-d15
	input	r_w,					// m68k read / write
	output	 _dtack,				// m68k data acknowledge to cpu
	output	rd,						// bus read 
	output	hwr,					// bus high write
	output	lwr,					// bus low write
	input	[23:1] address,			// external cpu address bus
//	output	reg [23:1] address_out,	// internal cpu address bus output
	output	[23:1] address_out,	// internal cpu address bus output
  output  [15:0] data,      // external cpu data bus
  input [15:0] cpudatain,
//  output  reg [15:0] data_out,  // internal data bus output
  output  [15:0] data_out,  // internal data bus output
  input [15:0] data_in,      // internal data bus input
  // UserIO interface
  input _cpu_reset,
  input cpu_halt,
  input host_cs,
  input [23:1] host_adr,
  input host_we,
  input [1:0] host_bs,
  input [15:0] host_wdat,
  output [15:0] host_rdat,
  output host_ack
);



localparam VCC = 1'b1;
localparam GND = 1'b0;

/*
68000 bus timing diagram

          .....   .   .   .   .   .   .   .....   .   .   .   .   .   .   .....
        7 . 0 . 1 . 2 . 3 . 4 . 5 . 6 . 7 . 0 . 1 . 2 . 3 . 4 . 5 . 6 . 7 . 0 . 1
          .....   .   .   .   .   .   .   .....   .   .   .   .   .   .   .....
           ___     ___     ___     ___     ___     ___     ___     ___     ___
CLK    ___/   \___/   \___/   \___/   \___/   \___/   \___/   \___/   \___/   \___
          .....   .   .   .   .   .   .   .....   .   .   .   .   .   .   .....
       _____________________________________________                         _____		  
R/W                 \_ _ _ _ _ _ _ _ _ _ _ _/       \_______________________/     
          .....   .   .   .   .   .   .   .....   .   .   .   .   .   .   .....
       _________ _______________________________ _______________________________ _		  
ADDR   _________X_______________________________X_______________________________X_
          .....   .   .   .   .   .   .   .....   .   .   .   .   .   .   .....
       _____________                     ___________                     _________
/AS                 \___________________/           \___________________/         
          .....   .   .   .       .   .   .....   .   .   .   .       .   .....
       _____________        READ         ___________________    WRITE    _________
/DS                 \___________________/                   \___________/         
          .....   .   .   .   .   .   .   .....   .   .   .   .   .   .   .....
       _____________________     ___________________________     _________________
/DTACK                      \___/                           \___/                 
          .....   .   .   .   .   .   .   .....   .   .   .   .   .   .   .....
                                     ___
DIN    -----------------------------<___>-----------------------------------------
          .....   .   .   .   .   .   .   .....   .   .   .   .   .   .   .....
                                                         ___________________
DOUT   -------------------------------------------------<___________________>-----
          .....   .   .   .   .   .   .   .....   .   .   .   .   .   .   .....
*/

wire	doe;					// data buffer output enable
reg		[15:0] ldata_in;		// latched data_in
wire	enable;					// enable
reg		lr_w,l_as,l_dtack;  	// synchronised inputs
reg		l_uds,l_lds;

//reg   l_as28m;        // latched address strobe in turbo mode

reg		lvpa;					// latched valid peripheral address (CIAs)
reg		vma;					// valid memory address (synchronised VPA with ECLK)
reg		_ta;					// transfer acknowledge

// halt is enabled when halt request comes in and cpu bus is idle
reg halt=0;
always @ (posedge clk) begin
  if (clk7_en) begin
    //if (!_cpu_reset)
    //  halt <= #1 1'b0;
    /*else*/ if (_as && cpu_halt)
      halt <= #1 1'b1;
    else if (_as && !cpu_halt)
      halt <= #1 1'b0;
  end
end

//CPU speed mode is allowed to change only when there is no bus access
always @(posedge clk)
  if (clk7_en) begin
  	if (_as)
  		turbo <= cpu_speed;
  end

wire  turbo_cpu;
assign turbo_cpu = 1'b0;
	
//latched valid peripheral address
always @(posedge clk)
  if (clk7_en) begin
  	lvpa <= vpa;
  end

//vma output
always @(posedge clk)
  if (clk7_en) begin
  	if (eclk[9])
  		vma <= 0;
  	else if (eclk[3] && lvpa)
  		vma <= 1;
  end

//latched CPU bus control signals
//always @(posedge clk)
////	{lr_w,l_as,l_uds,l_lds,l_dtack} <= {r_w,_as,_uds,_lds,_dtack};
//  {lr_w,l_as,l_dtack} <= ({r_w,_as,_dtack});
always @ (posedge clk) begin
  if (clk7_en) begin
    lr_w <= !halt ? r_w : !host_we;
    l_as <= !halt ? _as : !host_cs;
    l_dtack <= _dtack;
  end

end

always @(posedge clk) begin
  l_uds <= !halt ? _uds : !(host_bs[1]);
  l_lds <= !halt ? _lds : !(host_bs[0]);
end

reg _as28m;
always @(posedge clk)
  _as28m <= !halt ? _as : !host_cs;

reg l_as28m;
always @(posedge clk)
  if (clk7_en) begin
    l_as28m <= _as28m;
  end

wire _as_and_cs;
assign _as_and_cs = !halt ? _as : !host_cs;

// data transfer acknowledge in normal mode
reg _ta_n;
//always @(posedge clk28m or posedge _as)
always @(posedge clk or posedge _as_and_cs)
  if (_as_and_cs)
    _ta_n <= VCC;
  else if (clk7n_en) begin
    if (!l_as && cck && ((!vpa && !(dbr && dbs)) || (vpa && vma && eclk[8])) && !nrdy)
  //  else if (!_as && cck && ((!vpa && !(dbr && dbs)) || (vpa && vma && eclk[8])) && !nrdy)
      _ta_n <= GND; 
  end

assign host_ack = !_ta_n;
    
// actual _dtack generation (from 7MHz synchronous bus access and cache hit access)
//assign _dtack = (_ta_n & _ta_t & ~cache_hit);
assign _dtack = (_ta_n );

// synchronous control signals
assign enable = ((~l_as & ~l_dtack & ~cck & ~turbo) | (~l_as28m & l_dtack & ~(dbr & xbs) & ~nrdy & turbo));
//assign enable = ((~_as & ~_dtack & ~cck & ~turbo) | (~_as28m & _dtack & ~(dbr & xbs) & ~nrdy & turbo));
assign rd = (enable & lr_w);
//assign rd = !halt ? (enable & r_w) : !host_we;
// in turbo mode l_uds and l_lds may be delayed by 35 ns
assign hwr = (enable & ~lr_w & ~l_uds);
assign lwr = (enable & ~lr_w & ~l_lds);
//assign hwr = !halt ? (enable & ~r_w & ~_uds) : host_we && host_bs[1];
//assign lwr = !halt ? (enable & ~r_w & ~_lds) : host_we && host_bs[0];

//blitter slow down signalling, asserted whenever CPU is missing bus access to chip ram, slow ram and custom registers 
assign bls = dbs & ~l_as & l_dtack;
//assign bls = dbs & ~_as & _dtack;

// generate data buffer output enable
assign doe = r_w & ~_as;

// --------------------------------------------------------------------------------------

// data_out multiplexer and latch   
//always @(data)
//  data_out <= wrdata;
assign data_out = !halt ? cpudatain : host_wdat;

//always @(clk or data_in)
//  if (!clk)
//    ldata_in <= data_in;
always @(posedge clk)
  if (!c1 && c3 && enable)
    ldata_in <= data_in;
//assign ldata_in = data_in;

// --------------------------------------------------------------------------------------

// CPU data bus tristate buffers and output data multiplexer
//assign data[15:0] = doe ? cache_hit ? cache_out : ldata_in[15:0] : 16'bz;
assign data[15:0] = ldata_in;
assign host_rdat = ldata_in;

//always @(posedge clk)
//	address_out[23:1] <= address[23:1];
assign 	address_out[23:1] = !halt ? address[23:1] : host_adr[23:1];


endmodule

