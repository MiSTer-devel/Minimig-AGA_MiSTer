/* ctrl_clk_xilinx.v */
/* 2012, rok.krajnc@gmail.com */


module ctrl_clk_xilinx (
  input  wire inclk0,
  output wire c0,
  output wire c1,
  output wire c2,
  output wire locked
);


// internal wires
wire pll_50;
wire dll_50;
wire dll_100;
reg  clk_25 = 0;


// pll
DCM #(
  .CLKDV_DIVIDE(2.0), // Divide by: 1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0,6.5,7.0,7.5,8.0,9.0,10.0,11.0,12.0,13.0,14.0,15.0 or 16.0
  .CLKFX_DIVIDE(32),   // Can be any integer from 1 to 32
  .CLKFX_MULTIPLY(24), // Can be any integer from 2 to 32
  .CLKIN_DIVIDE_BY_2("FALSE"), // TRUE/FALSE to enable CLKIN divide by two feature
  .CLKIN_PERIOD(15.015),  // Specify period of input clock
  .CLKOUT_PHASE_SHIFT("NONE"), // Specify phase shift of NONE, FIXED or VARIABLE
  .CLK_FEEDBACK("NONE"),  // Specify clock feedback of NONE, 1X or 2X
  .DESKEW_ADJUST("SYSTEM_SYNCHRONOUS"), // SOURCE_SYNCHRONOUS, SYSTEM_SYNCHRONOUS or an integer from 0 to 15
  .DFS_FREQUENCY_MODE("LOW"),  // HIGH or LOW frequency mode for frequency synthesis
  .DLL_FREQUENCY_MODE("LOW"),  // HIGH or LOW frequency mode for DLL
  .DUTY_CYCLE_CORRECTION("TRUE"), // Duty cycle correction, TRUE or FALSE
  .FACTORY_JF(16'h8080),   // FACTORY JF values
  .PHASE_SHIFT(0),     // Amount of fixed phase shift from -255 to 255
  .STARTUP_WAIT("TRUE")   // Delay configuration DONE until DCM LOCK, TRUE/FALSE
) pll (
  .CLKIN(inclk0),   // Clock input (from IBUFG, BUFG or DCM)
  .CLKFX(pll_50)   // DCM CLK synthesis out (M/D) (49.950 MHz)
);

// dll
DCM #(
  .CLKDV_DIVIDE(2.0), // Divide by: 1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0,6.5,7.0,7.5,8.0,9.0,10.0,11.0,12.0,13.0,14.0,15.0 or 16.0
  .CLKFX_DIVIDE(1),   // Can be any integer from 1 to 32
  .CLKFX_MULTIPLY(4), // Can be any integer from 2 to 32
  .CLKIN_DIVIDE_BY_2("FALSE"), // TRUE/FALSE to enable CLKIN divide by two feature
  .CLKIN_PERIOD(20.020),  // Specify period of input clock
  .CLKOUT_PHASE_SHIFT("NONE"), // Specify phase shift of NONE, FIXED or VARIABLE
  .CLK_FEEDBACK("1X"),  // Specify clock feedback of NONE, 1X or 2X
  .DESKEW_ADJUST("SYSTEM_SYNCHRONOUS"), // SOURCE_SYNCHRONOUS, SYSTEM_SYNCHRONOUS or an integer from 0 to 15
  .DFS_FREQUENCY_MODE("LOW"),  // HIGH or LOW frequency mode for frequency synthesis
  .DLL_FREQUENCY_MODE("LOW"),  // HIGH or LOW frequency mode for DLL
  .DUTY_CYCLE_CORRECTION("TRUE"), // Duty cycle correction, TRUE or FALSE
  .FACTORY_JF(16'h8080),   // FACTORY JF values
  .PHASE_SHIFT(0),     // Amount of fixed phase shift from -255 to 255
  .STARTUP_WAIT("TRUE")   // Delay configuration DONE until DCM LOCK, TRUE/FALSE
) dll (
  .CLKIN(pll_50),   // Clock input (from IBUFG, BUFG or DCM)
  .CLK0(dll_50),
  .CLK2X(dll_100),
  .CLKFB(c1),
  .LOCKED(locked)
);

// 25MHz clock
always @ (posedge c0) begin
  clk_25 <= #1 ~clk_25;
end

// global clock buffers
BUFG  BUFG_100 (.I(dll_100), .O(c0));
BUFG  BUFG_50  (.I(dll_50),  .O(c1));
BUFG  BUFG_25  (.I(clk_25),  .O(c2));


endmodule

