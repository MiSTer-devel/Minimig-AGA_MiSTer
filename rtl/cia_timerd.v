// CIA Timer D - Time of Day (TOD) Clock Module
// 24-bit BCD counter for real-time clock functionality
// Counts external pulses (typically 50/60 Hz from power line frequency)
// Includes alarm functionality for time-based interrupts
module cia_timerd
(
  input   clk,            // System clock
  input clk7_en,          // 7MHz clock enable for synchronization
  input  wr,              // Write enable signal
  input   reset,          // Synchronous reset

  // Register select signals from address decoder
  input   tlo,            // TOD low byte select (1/10 seconds) ($x8)
  input   tme,            // TOD middle byte select (seconds) ($x9)
  input  thi,             // TOD high byte select (minutes) ($xA)
  input  tcr,             // Timer control register B select ($xF)

  input   [7:0] data_in,  // CPU data bus input
  output   reg [7:0] data_out, // CPU data bus output
  input  count,           // Count enable (typically 50/60 Hz tick)
  output  irq             // Alarm interrupt request
);

  // Internal registers
  reg    latch_ena;       // TOD output latch control
  reg   count_ena;        // TOD counting enable
  reg    crb7;            // CRB bit 7: TOD/ALARM register select
  reg    [23:0] tod;      // 24-bit TOD counter (BCD format)
  reg    [23:0] alarm;    // 24-bit alarm register (BCD format)
  reg    [23:0] tod_latch; // Latched TOD value for stable reading
  reg    count_del;       // Delayed count signal for edge detection
  reg    count_del2;      // delayed count signal for interrupt requesting

// TOD Counter Format (BCD - Binary Coded Decimal):
// Bits 23:16 - Minutes (00-59 BCD)
// Bits 15:8  - Seconds (00-59 BCD)
// Bits 7:0   - 1/10 seconds (00-99 BCD)

// TOD Read Latching Mechanism:
// Reading TOD registers must be done in specific order to ensure consistency
// - Reading high byte (minutes) latches entire TOD value
// - Subsequent reads of middle/low bytes return latched values
// - Reading low byte releases the latch for next update
always @(posedge clk)
  if (clk7_en) begin
    if (reset)
      latch_ena <= 1'd1;  // Latch enabled after reset
    else if (!wr)
    begin
      if (thi && !crb7)   // Reading minutes with TOD selected
        latch_ena <= 1'd0; // Freeze latch to ensure consistent read
      else if (tlo)       // Reading 1/10 seconds
        latch_ena <= 1'd1; // Release latch for updates
    end
  end

// Update TOD latch when enabled
always @(posedge clk)
  if (clk7_en) begin
    if (latch_ena)
      tod_latch[23:0] <= tod[23:0];
  end

// CPU Read Data Multiplexer
// CRB bit 7 = 0: Read TOD registers
// CRB bit 7 = 1: Read ALARM registers (write-only, reads as TOD)
always @(*)
  if (!wr)
  begin
    if (thi)      // High byte - minutes
      data_out[7:0] = tod_latch[23:16];
    else if (tme) // Middle byte - seconds
      data_out[7:0] = tod_latch[15:8];
    else if (tlo) // Low byte - 1/10 seconds
      data_out[7:0] = tod_latch[7:0];
    else if (tcr) // Control register B bit 7 only
      data_out[7:0] = {crb7,7'b000_0000};
    else
      data_out[7:0] = 8'd0;
  end
  else
    data_out[7:0] = 8'd0;

// TOD Write Control:
// Writing to high/middle byte stops TOD counting
// Writing to low byte starts TOD counting again
// This ensures consistent time setting
always @(posedge clk)
  if (clk7_en) begin
    if (reset)
      count_ena <= 1'd1;  // Counting enabled after reset
    else if (wr && !crb7) // Writing to TOD (not ALARM)
    begin
      if (thi/* || tme*/) // Writing minutes (or seconds)
        count_ena <= 1'd0; // Stop counting during update
      else if (tlo)       // Writing 1/10 seconds
        count_ena <= 1'd1; // Resume counting
    end
  end

// TOD Counter
// Note: Simplified implementation - counts binary, not true BCD
// Real hardware would implement proper BCD counting with digit carries
// AMR - emulate buggy TOD behaviour in Mid counter.Add commentMore actions
reg todcarry;
always @(posedge clk)
  if (clk7_en) begin
    if (reset)
    begin
      tod[23:0] <= 24'd0;  // Start at 00:00:00.0
    end
    else if (wr && !crb7)  // CRB7=0 enables writing to TOD
    begin
      if (tlo)
        tod[7:0] <= data_in[7:0];    // Set 1/10 seconds
      if (tme)
        tod[15:8] <= data_in[7:0];   // Set seconds
      if (thi)
        tod[23:16] <= data_in[7:0];  // Set minutes
    end
    else if (count_ena && count) begin
		todcarry <= &tod[11:0];
      tod[11:0] <= tod[11:0] + 12'd1;
    end
	 else if (count_ena && count_del)
	   tod[23:12] <= tod[23:12] + todcarry;

  end

// ALARM Register Write
// Written when CRB bit 7 = 1
always @(posedge clk)
  if (clk7_en) begin
    if (reset)
    begin
      // Set alarm to maximum value (never match by default)
      alarm[7:0] <= 8'b1111_1111;
      alarm[15:8] <= 8'b1111_1111;
      alarm[23:16] <= 8'b1111_1111;
    end
    else if (wr && crb7)  // CRB7=1 enables writing to ALARM
    begin
      if (tlo)
        alarm[7:0] <= data_in[7:0];    // Set alarm 1/10 seconds
      if (tme)
        alarm[15:8] <= data_in[7:0];   // Set alarm seconds
      if (thi)
        alarm[23:16] <= data_in[7:0];  // Set alarm minutes
    end
  end

// Control Register B bit 7
// Selects between TOD and ALARM for read/write operations
always @(posedge clk)
  if (clk7_en) begin
    if (reset)
      crb7 <= 1'd0;  // Default to TOD access
    else if (wr && tcr)
      crb7 <= data_in[7];
  end

// Edge detection for count input
// Used to ensure alarm triggers only once when TOD matches
always @(posedge clk)
  if (clk7_en) begin
    count_del <= count & count_ena;
    count_del2 <= count_del & count_ena;
  end

// Alarm interrupt generation
// Triggers when TOD exactly matches ALARM value
// count_del ensures single interrupt pulse
assign irq = (tod[23:0]==alarm[23:0] && (count_del || count_del2)) ? 1'b1 : 1'b0;


endmodule