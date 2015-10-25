// This module interfaces the minimig's synchronous bus to the asynchronous sram
// on the Minimig rev1.0 board
//
// JB:
// 2008-09-23	- generation of write strobes moved to clk28m clock domain


module minimig_sram_bridge
(
	//clocks
	input	clk,						// 28 MHz system clock
	input	c1,							// clock enable signal
	input	c3,							// clock enable signal	
	//chipset internal port
	input	[7:0] bank,					// memory bank select (512KB)
	input	[18:1] address_in,			// bus address
	input	[15:0] data_in,				// bus data in
	output	[15:0] data_out,			// bus data out
	input	rd,			   				// bus read
	input	hwr,						// bus high byte write
	input	lwr,						// bus low byte write
	//SRAM external signals
//	output	reg _bhe = 1,				// sram upper byte
//	output	reg _ble = 1,   				// sram lower byte
//	output	reg _we = 1,				// sram write enable
//	output	reg _oe = 1,				// sram output enable
//	output	reg [3:0] _ce = 4'b1111,	// sram chip enable
//	output	reg [19:1] address,			// sram address bus
//	inout	[15:0] data		  			// sram data das
	output	_bhe,				// sram upper byte
	output	_ble,   				// sram lower byte
	output	_we,				// sram write enable
	output	_oe,				// sram output enable
	output	[21:1] address,			// sram address bus
	output	[15:0] data,	  			// sram data das
	input	[15:0] ramdata_in	  		// sram data das in
);	 

/* basic timing diagram

phase          : Q0  : Q1  : Q2  : Q3  : Q0  : Q1  : Q2  : Q3  : Q0  : Q1  :
               :     :     :     :     :     :     :     :     :     :     :
			    ___________             ___________             ___________
clk			___/           \___________/           \___________/           \_____ (7.09 MHz - dedicated clock)

               :     :     :     :     :     :     :     :     :     :     :
			    __    __    __    __    __    __    __    __    __    __    __
clk28m		___/  \__/  \__/  \__/  \__/  \__/  \__/  \__/  \__/  \__/  \__/  \__ (28.36 MHz - dedicated clock)
               :     :     :     :     :     :     :     :     :     :     :
			    ___________             ___________             ___________
c1			___/           \___________/           \___________/           \_____ (7.09 MHz)
               :     :     :     :     :     :     :     :     :     :     :
			          ___________             ___________             ___________
c3			_________/           \___________/           \___________/            (7.09 MHz)
               :     :     :     :     :     :     :     :     :     :     :
			_________                   _____                   _____   
_ce			         \_________________/     \_________________/     \___________ (ram chip enable)
               :     :     :     :     :     :     :     :     :     :     :
			_______________             ___________             ___________   
_we			               \___________/           \___________/           \_____ (ram write strobe)
               :     :     :     :     :     :     :     :     :     :     :
			_________                   _____                   _____
_oe			         \_________________/     \_________________/     \___________ (ram output enable)
               :     :     :     :     :     :     :     :     :     :     :
			          _________________       _________________       ___________
doe			_________/                 \_____/                 \_____/            (data bus output enable)
               :     :     :     :     :     :     :     :     :     :     :
*/

wire	enable;				// indicates memory access cycle
reg		doe;				// data output enable (activates ram data bus buffers during write cycle)

// generate enable signal if any of the banks is selected
//assign enable = |bank[7:0];
assign enable = (bank[7:0]==8'b00000000) ? 1'b0 : 1'b1;

// generate _we
assign _we = (!hwr && !lwr) | !enable;
//always @(posedge clk28m)
//	if (!c1 && !c3) // deassert write strobe in Q0
//		_we <= 1'b1;
//	else if (c1 && c3 && enable && !rd)	//assert write strobe in Q2
//		_we <= 1'b0;

// generate ram output enable _oe
assign _oe = !rd | !enable; 
//assign _oe = !enable;
//always @(posedge clk28m)
//	if (!c1 && !c3) // deassert output enable in Q0
//		_oe <= 1'b1;
//	else if (c1 && !c3 && enable && rd)	//assert output enable in Q1 during read cycle
//		_oe <= 1'b0;

// generate ram upper byte enable _bhe
assign _bhe = !hwr | !enable;
//always @(posedge clk28m)
//	if (!c1 && !c3) // deassert upper byte enable in Q0
//		_bhe <= 1'b1;
//	else if (c1 && !c3 && enable && rd) // assert upper byte enable in Q1 during read cycle
//		_bhe <= 1'b0;
//	else if (c1 && c3 && enable && hwr) // assert upper byte enable in Q2 during write cycle
//		_bhe <= 1'b0;
		
// generate ram lower byte enable _ble
assign _ble = !lwr | !enable;
//always @(posedge clk28m)
//	if (!c1 && !c3) // deassert lower byte enable in Q0
//		_ble <= 1'b1;
//	else if (c1 && !c3 && enable && rd) // assert lower byte enable in Q1 during read cycle
//		_ble <= 1'b0;	
//	else if (c1 && c3 && enable && lwr) // assert lower byte enable in Q2 during write cycle
//		_ble <= 1'b0;
			
//generate data buffer output enable
always @(posedge clk)
	if (!c1 && !c3)  // deassert output enable in Q0
		doe <= 1'b0;
	else if (c1 && !c3 && enable && !rd) // assert output enable in Q1 during write cycle
		doe <= 1'b1;	

// generate sram chip selects (every sram chip is 512K x 16bits)
//assign		_ce[3:0] = {~|bank[7:6],~|bank[5:4],~|bank[3:2],~|bank[1:0]};
//always @(posedge clk28m)
//	if (!c1 && !c3) // deassert chip selects in Q0
//		_ce[3:0] <= 4'b1111;
//	else if (c1 && !c3) // assert chip selects in Q1
//		_ce[3:0] <= {~|bank[7:6],~|bank[5:4],~|bank[3:2],~|bank[1:0]};

// ram address bus
assign		address = {bank[7]|bank[6]|bank[5]|bank[4],  bank[7]|bank[6]|bank[3]|bank[2],  bank[7]|bank[5]|bank[3]|bank[1],  address_in[18:1]};
//assign address = {bank[7]|bank[5]|bank[3]|bank[1],address_in[18:1]};
//always @(posedge clk28m)
//	if (c1 && !c3 && enable)	// set address in Q1		
//		address <= {bank[7]|bank[5]|bank[3]|bank[1],address_in[18:1]};
			
// data_out multiplexer
assign data_out[15:0] = (enable && rd) ? ramdata_in[15:0] : 16'b0000000000000000;

// data bus output buffers
//assign data[15:0] = doe ? data_in[15:0] : 16'bz;
assign data[15:0] = data_in[15:0];


endmodule

