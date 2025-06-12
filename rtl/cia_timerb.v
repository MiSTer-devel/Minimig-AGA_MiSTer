// CIA Timer B Module
// 16-bit down counter similar to Timer A but with cascade mode capability
// Can count system clock pulses or Timer A underflows
module cia_timerb
(
  input   clk,            // System clock
  input clk7_en,          // 7MHz clock enable for synchronization
  input  wr,              // Write enable signal
  input   reset,          // Synchronous reset

  // Register select signals from address decoder
  input   tlo,            // Timer low byte select ($x6)
  input  thi,             // Timer high byte select ($x7)
  input  tcr,             // Timer control register select ($xF)

  input   [7:0] data_in,  // CPU data bus input
  output   [7:0] data_out, // CPU data bus output
  input  eclk,            // External clock input (usually E clock)
  input  tmra_ovf,        // Timer A underflow signal for cascade mode
  output  irq             // Timer underflow interrupt request
);

// Internal registers - similar structure to Timer A
reg    [15:0] tmr;        // 16-bit timer counter (counts down)
reg    [7:0] tmlh;        // Timer latch high byte (reload value)
reg    [7:0] tmll;        // Timer latch low byte (reload value)
reg    [6:0] tmcr;        // Timer control register
reg    forceload;         // Force load strobe signal
wire  oneshot;            // One-shot mode flag
wire  start;              // Timer start/stop control
reg    thi_load;          // Load timer when high byte written
wire  reload;             // Reload timer from latch
wire  zero;               // Timer reached zero
wire  underflow;          // Timer underflow condition
wire  count;              // Count enable signal

// Timer B special feature: can count Timer A underflows
// Control register bit 6 selects count source:
// 0 = Count system clock pulses (eclk)
// 1 = Count Timer A underflows (cascade mode)
assign count = tmcr[6] ? tmra_ovf : eclk;

// Timer Control Register (CRB) bit definitions:
// Bit 0: START - Start/stop timer (1=start, 0=stop)
// Bit 1: PBON - PB7 output mode (not implemented in simplified version)
// Bit 2: OUTMODE - PB7 output mode (not implemented)
// Bit 3: RUNMODE - 0=continuous, 1=one-shot
// Bit 4: LOAD - Force load timer from latch (strobe, write-only)
// Bit 5-6: INMODE - Count source:
//          00,01 = System clock
//          10,11 = Timer A underflow (cascade mode)
// Bit 7: ALARM - TOD clock write select (0=TOD, 1=ALARM)

// Write to control register
always @(posedge clk)
  if (clk7_en) begin
    if (reset)
      tmcr[6:0] <= 7'd0;
    else if (tcr && wr)
      // Load control register, bit 4 (LOAD strobe) is not stored
      tmcr[6:0] <= {data_in[6:5],1'b0,data_in[3:0]};
    else if (thi_load && oneshot)
      // In one-shot mode, writing to timer high byte starts the timer
      tmcr[0] <= 1'd1;
    else if (underflow && oneshot)
      // In one-shot mode, timer stops automatically on underflow
      tmcr[0] <= 1'd0;
  end

// Capture force load strobe
always @(posedge clk)
  if (clk7_en) begin
    forceload <= tcr & wr & data_in[4];
  end

// Control register bit aliases
assign oneshot = tmcr[3];    // One-shot mode enable
assign start = tmcr[0];      // Timer start/stop

// Timer latch registers - hold reload value
// Low byte latch
always @(posedge clk)
  if (clk7_en) begin
    if (reset)
      tmll[7:0] <= 8'b1111_1111;  // Default to $FF
    else if (tlo && wr)
      tmll[7:0] <= data_in[7:0];
  end

// High byte latch
always @(posedge clk)
  if (clk7_en) begin
    if (reset)
      tmlh[7:0] <= 8'b1111_1111;  // Default to $FF
    else if (thi && wr)
      tmlh[7:0] <= data_in[7:0];
  end

// Detect write to timer high byte
always @(posedge clk)
  if (clk7_en) begin
    thi_load <= thi & wr & (~start | oneshot);
  end

// Timer reload conditions (same as Timer A)
assign reload = thi_load | forceload | underflow;

// 16-bit down counter
always @(posedge clk)
  if (clk7_en) begin
    if (reset)
      tmr[15:0] <= 16'hFF_FF;  // Reset to maximum value
    else if (reload)
      tmr[15:0] <= {tmlh[7:0],tmll[7:0]};  // Load from latches
    else if (start && count)
      tmr[15:0] <= tmr[15:0] - 16'd1;     // Count down
  end

// Timer state detection
assign zero = ~|tmr;                    // Timer equals zero
assign underflow = zero & start & count; // Underflow when counting through zero

// Output signals
assign irq = underflow;  // Interrupt request on underflow

// CPU read data multiplexer
// Note: Bit 7 of CRB (ALARM bit) is handled by Timer D module
assign data_out[7:0] = ({8{~wr&tlo}} & tmr[7:0])        // Timer low byte
          | ({8{~wr&thi}} & tmr[15:8])                  // Timer high byte
          | ({8{~wr&tcr}} & {1'b0,tmcr[6:0]});         // Control register


endmodule