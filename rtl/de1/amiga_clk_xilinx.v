/* amiga_clk_xilinx.v */
/* 2012, rok.krajnc@gmail.com */


module amiga_clk_xilinx (
  input  wire areset,
  input  wire inclk0,
  output wire c0,
  output wire c1,
  output wire c2,
  output wire locked
);


// internal wires
wire pll_114;
wire dll_114;
wire dll_28;
reg [1:0] clk_7 = 0;


// pll
DCM #(
  .CLKDV_DIVIDE(2.0), // Divide by: 1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0,6.5,7.0,7.5,8.0,9.0,10.0,11.0,12.0,13.0,14.0,15.0 or 16.0
  .CLKFX_DIVIDE(17),   // Can be any integer from 1 to 32
  .CLKFX_MULTIPLY(29), // Can be any integer from 2 to 32
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
  .CLKFX(pll_114)   // DCM CLK synthesis out (M/D) (113.611765 MHz)
);

// dll
DCM #(
  .CLKDV_DIVIDE(4.0), // Divide by: 1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0,6.5,7.0,7.5,8.0,9.0,10.0,11.0,12.0,13.0,14.0,15.0 or 16.0
  .CLKFX_DIVIDE(1),   // Can be any integer from 1 to 32
  .CLKFX_MULTIPLY(4), // Can be any integer from 2 to 32
  .CLKIN_DIVIDE_BY_2("FALSE"), // TRUE/FALSE to enable CLKIN divide by two feature
  .CLKIN_PERIOD(8.802),  // Specify period of input clock
  .CLKOUT_PHASE_SHIFT("FIXED"), // Specify phase shift of NONE, FIXED or VARIABLE
  .CLK_FEEDBACK("1X"),  // Specify clock feedback of NONE, 1X or 2X
  .DESKEW_ADJUST("SYSTEM_SYNCHRONOUS"), // SOURCE_SYNCHRONOUS, SYSTEM_SYNCHRONOUS or an integer from 0 to 15
  .DFS_FREQUENCY_MODE("LOW"),  // HIGH or LOW frequency mode for frequency synthesis
  .DLL_FREQUENCY_MODE("LOW"),  // HIGH or LOW frequency mode for DLL
  .DUTY_CYCLE_CORRECTION("TRUE"), // Duty cycle correction, TRUE or FALSE
  .FACTORY_JF(16'h8080),   // FACTORY JF values
  .PHASE_SHIFT(104),     // Amount of fixed phase shift from -255 to 255
  .STARTUP_WAIT("TRUE")   // Delay configuration DONE until DCM LOCK, TRUE/FALSE
) dll (
  .RST(areset),
  .CLKIN(pll_114),   // Clock input (from IBUFG, BUFG or DCM)
  .CLK0(dll_114),
  .CLKDV(dll_28),
  .CLKFB(c0),
  .LOCKED(locked)
);

// 7MHz clock
always @ (posedge c1) begin
  clk_7 <= #1 clk_7 + 2'd1;
end

// global clock buffers
BUFG  BUFG_SDR (.I(pll_114),  .O(c2));
BUFG  BUFG_114 (.I(dll_114),  .O(c0));
BUFG  BUFG_28  (.I(dll_28),   .O(c1));
//BUFG  BUFG_7   (.I(clk_7[1]), .O(c3));


endmodule

