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

// Master clock generator for minimig
// This module generates all necessary clocks from the 4.433619 PAL clock
// JB:
// 2008-03-01	- added ddl for generating in phase system clock with 28MHz clock
// 2008-09-23	- added c1 and c3 clock enable outputs
// 2008-10-15	- adapted e clock enable to be in sync with cck
// 2009-05-23	- eclk modification
// 2010-08-18	- clean-up

module clock_generator
(
	input	mclk,		// 4.433619 MHz master clock input
	output	clk28m,	 	// 28.37516 MHz clock output
	output	reg c1,		// clk28m clock domain signal synchronous with clk signal
	output	reg c3,		// clk28m clock domain signal synchronous with clk signal delayed by 90 degrees
	output	cck,		// colour clock output (3.54 MHz)
	output 	clk, 		// 7.09379  MHz clock output
	output	cpu_clk,
	input	turbo,
	output 	[9:0] eclk	// 0.709379 MHz clock enable output (clk domain pulse)
);

//            __    __    __    __    __
// clk28m  __/  \__/  \__/  \__/  \__/  
//            ___________             __
// clk     __/           \___________/  
//            ___________             __
// c1      __/           \___________/   <- clk28m domain
//                  ___________
// c3      ________/           \________ <- clk28m domain
//

	wire	pll_mclk;
	wire	pll_c28m;
	wire	dll_c28m;
	wire	dll_c7m;
	wire	pll_cpuclk;
   
	IBUFG mclk_buf ( .I(mclk), .O(pll_mclk) );	
	
	DCM #
	(
		.CLKDV_DIVIDE(2.0), // Divide by: 1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0,6.5,7.0,7.5,8.0,9.0,10.0,11.0,12.0,13.0,14.0,15.0 or 16.0
		.CLKFX_DIVIDE(5),   // Can be any integer from 1 to 32
		.CLKFX_MULTIPLY(32), // Can be any integer from 2 to 32
		.CLKIN_DIVIDE_BY_2("FALSE"), // TRUE/FALSE to enable CLKIN divide by two feature
		.CLKIN_PERIOD(225.0),  // Specify period of input clock
		.CLKOUT_PHASE_SHIFT("NONE"), // Specify phase shift of NONE, FIXED or VARIABLE
		.CLK_FEEDBACK("NONE"),  // Specify clock feedback of NONE, 1X or 2X
		.DESKEW_ADJUST("SYSTEM_SYNCHRONOUS"), // SOURCE_SYNCHRONOUS, SYSTEM_SYNCHRONOUS or an integer from 0 to 15
		.DFS_FREQUENCY_MODE("LOW"),  // HIGH or LOW frequency mode for frequency synthesis
		.DLL_FREQUENCY_MODE("LOW"),  // HIGH or LOW frequency mode for DLL
		.DUTY_CYCLE_CORRECTION("TRUE"), // Duty cycle correction, TRUE or FALSE
		.FACTORY_JF(16'hC080),   // FACTORY JF values
		.PHASE_SHIFT(0),     // Amount of fixed phase shift from -255 to 255
		.STARTUP_WAIT("TRUE")   // Delay configuration DONE until DCM LOCK, TRUE/FALSE
	)
	pll
	(
		.CLKFX(pll_c28m),   // DCM CLK synthesis out (M/D)
		.CLKIN(pll_mclk)   // Clock input (from IBUFG, BUFG or DCM)
	);

	DCM #
	(
		.CLKDV_DIVIDE(4.0), // Divide by: 1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0,6.5,7.0,7.5,8.0,9.0,10.0,11.0,12.0,13.0,14.0,15.0 or 16.0
		.CLKFX_DIVIDE(4),   // Can be any integer from 1 to 32
		.CLKFX_MULTIPLY(4), // Can be any integer from 2 to 32
		.CLKIN_DIVIDE_BY_2("FALSE"), // TRUE/FALSE to enable CLKIN divide by two feature
		.CLKIN_PERIOD(35.0),  // Specify period of input clock
		.CLKOUT_PHASE_SHIFT("NONE"), // Specify phase shift of NONE, FIXED or VARIABLE
		.CLK_FEEDBACK("1X"),  // Specify clock feedback of NONE, 1X or 2X
		.DESKEW_ADJUST("SYSTEM_SYNCHRONOUS"), // SOURCE_SYNCHRONOUS, SYSTEM_SYNCHRONOUS or an integer from 0 to 15
		.DFS_FREQUENCY_MODE("LOW"),  // HIGH or LOW frequency mode for frequency synthesis
		.DLL_FREQUENCY_MODE("LOW"),  // HIGH or LOW frequency mode for DLL
		.DUTY_CYCLE_CORRECTION("TRUE"), // Duty cycle correction, TRUE or FALSE
		.FACTORY_JF(16'hC080),   // FACTORY JF values
		.PHASE_SHIFT(0),     // Amount of fixed phase shift from -255 to 255
		.STARTUP_WAIT("TRUE")   // Delay configuration DONE until DCM LOCK, TRUE/FALSE
	)
	dll
	(
		.CLKIN(pll_c28m),	// Clock input (from IBUFG, BUFG or DCM)
		.CLK0(dll_c28m),	// 0 degree DCM CLK output
		.CLKDV(dll_c7m),	// Divided DCM CLK out (CLKDV_DIVIDE)
		.CLKFB(clk28m)		// DCM clock feedback
	);
	
	//global clock buffers
	BUFG clk28m_buf ( .I(dll_c28m), .O(clk28m) );
	BUFG clk_buf ( .I(dll_c7m), .O(clk) );

	DCM #
	(
		.CLKDV_DIVIDE(2.0), // Divide by: 1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0,6.5,7.0,7.5,8.0,9.0,10.0,11.0,12.0,13.0,14.0,15.0 or 16.0
		.CLKFX_DIVIDE(2),   // Can be any integer from 1 to 32
		.CLKFX_MULTIPLY(14), // Can be any integer from 2 to 32
		.CLKIN_DIVIDE_BY_2("FALSE"), // TRUE/FALSE to enable CLKIN divide by two feature
		.CLKIN_PERIOD(140.0),  // Specify period of input clock
		.CLKOUT_PHASE_SHIFT("NONE"), // Specify phase shift of NONE, FIXED or VARIABLE
		.CLK_FEEDBACK("NONE"),  // Specify clock feedback of NONE, 1X or 2X
		.DESKEW_ADJUST("SYSTEM_SYNCHRONOUS"), // SOURCE_SYNCHRONOUS, SYSTEM_SYNCHRONOUS or an integer from 0 to 15
		.DFS_FREQUENCY_MODE("LOW"),  // HIGH or LOW frequency mode for frequency synthesis
		.DLL_FREQUENCY_MODE("LOW"),  // HIGH or LOW frequency mode for DLL
		.DUTY_CYCLE_CORRECTION("TRUE"), // Duty cycle correction, TRUE or FALSE
		.FACTORY_JF(16'hC080),   // FACTORY JF values
		.PHASE_SHIFT(0),     // Amount of fixed phase shift from -255 to 255
		.STARTUP_WAIT("TRUE")   // Delay configuration DONE until DCM LOCK, TRUE/FALSE
	)
	cpu_pll
	(
		.CLKFX(pll_cpuclk),   // DCM CLK synthesis out (M/D)
		.CLKIN(dll_c7m)   // Clock input (from IBUFG, BUFG or DCM)
	);
	
	BUFGMUX cpu_clk_buf 
	(
		.O(cpu_clk),	// Clock MUX output
		.I0(~clk),		// Clock0 input
		.I1(~pll_cpuclk),	// Clock1 input
		.S(turbo)		// Clock select input
	);

reg		[3:0] e_cnt;	//used to generate e clock enable

// E clock counter
always @(posedge clk)
	if (e_cnt[3] && e_cnt[0])
		e_cnt[3:0] <= 0;
	else
		e_cnt[3:0] <= e_cnt[3:0] + 1;

// CCK clock output
assign cck = ~e_cnt[0];
		
assign eclk[0] = ~e_cnt[3] & ~e_cnt[2] & ~e_cnt[1] & ~e_cnt[0]; // e_cnt == 0
assign eclk[1] = ~e_cnt[3] & ~e_cnt[2] & ~e_cnt[1] &  e_cnt[0]; // e_cnt == 1
assign eclk[2] = ~e_cnt[3] & ~e_cnt[2] &  e_cnt[1] & ~e_cnt[0]; // e_cnt == 2
assign eclk[3] = ~e_cnt[3] & ~e_cnt[2] &  e_cnt[1] &  e_cnt[0]; // e_cnt == 3
assign eclk[4] = ~e_cnt[3] &  e_cnt[2] & ~e_cnt[1] & ~e_cnt[0]; // e_cnt == 4
assign eclk[5] = ~e_cnt[3] &  e_cnt[2] & ~e_cnt[1] &  e_cnt[0]; // e_cnt == 5
assign eclk[6] = ~e_cnt[3] &  e_cnt[2] &  e_cnt[1] & ~e_cnt[0]; // e_cnt == 6
assign eclk[7] = ~e_cnt[3] &  e_cnt[2] &  e_cnt[1] &  e_cnt[0]; // e_cnt == 7
assign eclk[8] =  e_cnt[3] & ~e_cnt[2] & ~e_cnt[1] & ~e_cnt[0]; // e_cnt == 8
assign eclk[9] =  e_cnt[3] & ~e_cnt[2] & ~e_cnt[1] &  e_cnt[0]; // e_cnt == 9
		
always @(posedge clk28m)
	c3 <= clk;
	
always @(posedge clk28m)
	c1 <= ~c3;
	
endmodule
