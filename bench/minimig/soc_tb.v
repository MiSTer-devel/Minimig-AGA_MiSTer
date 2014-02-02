/********************************************/
/* soc_tb.v                                 */
/* DE1 skeleton testbench                   */
/*                                          */
/*                                          */
/* 2012, rok.krajnc@gmail.com               */
/********************************************/

//`default_nettype none
`timescale 1ns/1ps


module soc_tb();

////////////////////////////////////////
// defines                            //
////////////////////////////////////////
`define SOC_SIM

`define HP_24  20.833
`define HP_27  18.519
`define HP_50  10.000
`define HP_EXT  5.000

`define VGA_MON_CLK   CLOCK_50
`define VGA_MON_OA    1'b0
`define VGA_MON_F_CNT 'd0
`define VGA_MON_F_STA 1'b0



////////////////////////////////////////
// internal signals                   //
////////////////////////////////////////

//// system ////
reg            RST;
reg            ERR;
reg  [ 32-1:0] datr;


//// soc ////
// clock inputs
reg  [ 2-1:0]  CLOCK_24;    // 24 MHz
reg  [ 2-1:0]  CLOCK_27;    // 27 MHz
reg            CLOCK_50;    // 50 MHz
reg            CLOCK_EXT;   // External Clock
// USB JTAG Link
reg            TDI;         // CPLD -> FPGA (data in)
reg            TCK;         // CPLD -> FPGA (clk)
reg            TCS;         // CPLD -> FPGA (CS)
wire           TDO;         // FPGA -> CPLD (data out)
// GPIO
tri  [36-1:0]  GPIO_0;      // GPIO Connection 0
tri  [36-1:0]  GPIO_1;      // GPIO Connection 1
// push button inputs
wire [ 4-1:0]  BTN;         // Pushbutton[3:0]
// switch inputs
wire [10-1:0]  SW;          // Toggle Switch[9:0]
// 7-seg display outputs
wire [ 7-1:0]  HEX_0;       // Seven Segment Digit 0
wire [ 7-1:0]  HEX_1;       // Seven Segment Digit 1
wire [ 7-1:0]  HEX_2;       // Seven Segment Digit 2
wire [ 7-1:0]  HEX_3;       // Seven Segment Digit 3
// LED outputs
wire [ 8-1:0]  LED_G;       // LED Green[7:0]
wire [10-1:0]  LED_R;       // LED Red[9:0]
// UART
wire           UART_TXD;    // UART Transmitter
reg            UART_RXD;    // UART Receiver
// I2C
tri            I2C_SDAT;    // I2C Data
wire           I2C_SCLK;    // I2C Clock
// PS2
tri            PS2_DAT;     // PS2 Data
tri            PS2_CLK;     // PS2 Clock
// VGA
wire           VGA_HS;      // VGA H_SYNC
wire           VGA_VS;      // VGA V_SYNC
wire [ 4-1:0]  VGA_R;       // VGA Red[3:0]
wire [ 4-1:0]  VGA_G;       // VGA Green[3:0]
wire [ 4-1:0]  VGA_B;       // VGA Blue[3:0]
// Audio CODEC
tri            AUD_ADCLRCK; // Audio CODEC ADC LR Clock
reg            AUD_ADCDAT;  // Audio CODEC ADC Data
tri            AUD_DACLRCK; // Audio CODEC DAC LR Clock
wire           AUD_DACDAT;  // Audio CODEC DAC Data
tri            AUD_BCLK;    // Audio CODEC Bit-Stream Clock
wire           AUD_XCK;     // Audio CODEC Chip Clock
// SD Card
wire           SD_DAT;      // SD Card Data
wire           SD_DAT3;     // SD Card Data 3
wire           SD_CMD;      // SD Card Command Signal
wire           SD_CLK;      // SD Card Clock
// SRAM
tri  [16-1:0]  SRAM_DQ;     // SRAM Data bus 16 Bits
wire [18-1:0]  SRAM_ADDR;   // SRAM Address bus 18 Bits
wire           SRAM_UB_N;   // SRAM High-byte Data Mask
wire           SRAM_LB_N;   // SRAM Low-byte Data Mask
wire           SRAM_WE_N;   // SRAM Write Enable
wire           SRAM_CE_N;   // SRAM Chip Enable
wire           SRAM_OE_N;   // SRAM Output Enable
// SDRAM
tri  [16-1:0]  DRAM_DQ;     // SDRAM Data bus 16 Bits
wire [12-1:0]  DRAM_ADDR;   // SDRAM Address bus 12 Bits
wire           DRAM_LDQM;   // SDRAM Low-byte Data Mask
wire           DRAM_UDQM;   // SDRAM High-byte Data Mask
wire           DRAM_WE_N;   // SDRAM Write Enable
wire           DRAM_CAS_N;  // SDRAM Column Address Strobe
wire           DRAM_RAS_N;  // SDRAM Row Address Strobe
wire           DRAM_CS_N;   // SDRAM Chip Select
wire           DRAM_BA_0;   // SDRAM Bank Address 0
wire           DRAM_BA_1;   // SDRAM Bank Address 1
wire           DRAM_CLK;    // SDRAM Clock
wire           DRAM_CKE;    // SDRAM Clock Enable
// FLASH
tri  [ 8-1:0]  FL_DQ;       // FLASH Data bus 8 Bits
wire [22-1:0]  FL_ADDR;     // FLASH Address bus 22 Bits
wire           FL_WE_N;     // FLASH Write Enable
wire           FL_RST_N;    // FLASH Reset
wire           FL_OE_N;     // FLASH Output Enable
wire           FL_CE_N;     // FLASH Chip Enable



////////////////////////////////////////
// bench                              //
////////////////////////////////////////

//// clocks & async reset ////
initial begin
  CLOCK_24  = 1'b1;
  #2;
  forever #`HP_24 CLOCK_24 = ~CLOCK_24;
end

initial begin
  CLOCK_27  = 1'b1;
  #3;
  forever #`HP_27 CLOCK_27 = ~CLOCK_27;
end

initial begin
  CLOCK_50  = 1'b1;
  #5;
  forever #`HP_50 CLOCK_50 = ~CLOCK_50;
end

initial begin
  CLOCK_EXT = 1'b1;
  #7;
  forever #`HP_EXT CLOCK_EXT = ~CLOCK_EXT;
end

initial begin
  RST = 1'b1;
  #101;
  RST = 1'b0;
end

initial begin
  ERR = 1'b0;
end

//// set all inputs at initial time ////
initial begin
  TDI         = 0;
  TCK         = 0;
  TCS         = 0;
  UART_RXD    = 0;
  AUD_ADCDAT  = 0;
//  SD_DAT      = 0;
end


//// bench ////
initial begin
  $display("BENCH : %t : soc test starting ...", $time);

  // wait for reset
  #5;
  wait(!RST);
  repeat (10) @ (posedge CLOCK_50);
  #1;

  // disable ctrl CPU
  force soc_top.ctrl_top.ctrl_cpu.dcpu_cs  = 1'b0;
  force soc_top.ctrl_top.ctrl_cpu.icpu_cs  = 1'b0;
  force soc_top.ctrl_top.ctrl_cpu.dcpu_ack = 1'b0;
  force soc_top.ctrl_top.ctrl_cpu.icpu_ack = 1'b0;
  // force reset TG68
  force soc_top.tg68_rst = 1'b0;

  // wait for reset
  //while (!soc_top.ctrl_top.rst) @ (posedge soc_top.ctrl_top.clk); #1;
  wait (!soc_top.ctrl_top.ctrl_regs.rst);

  // force unreset minimig
  force soc_top.minimig.reset = 1'b0;

  force soc_top.tg68_rst = 1'b1;
  repeat(10) @ (posedge soc_top.clk_7);
  force soc_top.tg68_rst = 1'b0;
  repeat(10) @ (posedge soc_top.clk_7);

  // try qmem bridge
  ctrl_bridge_cycle(32'h00180000, 1'b1, 4'hf, 32'h01234567);
  ctrl_bridge_cycle(32'h00180000, 1'b1, 4'hf, 32'hdeadbeef);
  repeat(10) @ (posedge soc_top.ctrl_top.clk);

  // write to OSD SPI slave
  // enable OSD (SPI chip select)
  ctrl_regs_cycle(32'h00800020, 1'b1, 4'hf, 32'h00000044);
  // send write command
  ctrl_regs_cycle(32'h00800024, 1'b1, 4'hf, 32'h0000001c);
  // send address
  ctrl_regs_cycle(32'h00800024, 1'b1, 4'hf, 32'h00000000);
  ctrl_regs_cycle(32'h00800024, 1'b1, 4'hf, 32'h00000000);
  ctrl_regs_cycle(32'h00800024, 1'b1, 4'hf, 32'h00000000);
  ctrl_regs_cycle(32'h00800024, 1'b1, 4'hf, 32'h00000000);
  // send data
  ctrl_regs_cycle(32'h00800024, 1'b1, 4'hf, 32'h000000aa);
  ctrl_regs_cycle(32'h00800024, 1'b1, 4'hf, 32'h000000bb);
  ctrl_regs_cycle(32'h00800024, 1'b1, 4'hf, 32'h000000cc);
  ctrl_regs_cycle(32'h00800024, 1'b1, 4'hf, 32'h000000dd);
  ctrl_regs_cycle(32'h00800024, 1'b1, 4'hf, 32'h000000ee);
  ctrl_regs_cycle(32'h00800024, 1'b1, 4'hf, 32'h000000ff);
  ctrl_regs_cycle(32'h00800024, 1'b1, 4'hf, 32'h00000001);
  ctrl_regs_cycle(32'h00800024, 1'b1, 4'hf, 32'h00000023);
  ctrl_regs_cycle(32'h00800024, 1'b1, 4'hf, 32'h00000045);
  ctrl_regs_cycle(32'h00800024, 1'b1, 4'hf, 32'h00000067);
  ctrl_regs_cycle(32'h00800024, 1'b1, 4'hf, 32'h00000089);
  ctrl_regs_cycle(32'h00800024, 1'b1, 4'hf, 32'h000000ab);
  ctrl_regs_cycle(32'h00800024, 1'b1, 4'hf, 32'h000000cd);
  ctrl_regs_cycle(32'h00800024, 1'b1, 4'hf, 32'h000000ef);
  repeat (10) @ (posedge soc_top.ctrl_top.clk);

  // disable OSD (SPI chip select)
  ctrl_regs_cycle(32'h00800020, 1'b1, 4'hf, 32'h00000040);
  repeat (10) @ (posedge soc_top.ctrl_top.clk);

  // write to OSD SPI slave
  // enable OSD (SPI chip select)
  ctrl_regs_cycle(32'h00800020, 1'b1, 4'hf, 32'h00000044);
  // send write command
  ctrl_regs_cycle(32'h00800024, 1'b1, 4'hf, 32'h0000001c);
  // send address
  ctrl_regs_cycle(32'h00800024, 1'b1, 4'hf, 32'h00000080);
  ctrl_regs_cycle(32'h00800024, 1'b1, 4'hf, 32'h000000f0);
  ctrl_regs_cycle(32'h00800024, 1'b1, 4'hf, 32'h000000df);
  ctrl_regs_cycle(32'h00800024, 1'b1, 4'hf, 32'h00000000);
  // send data
  ctrl_regs_cycle(32'h00800024, 1'b1, 4'hf, 32'h000000aa);
  ctrl_regs_cycle(32'h00800024, 1'b1, 4'hf, 32'h000000bb);
  ctrl_regs_cycle(32'h00800024, 1'b1, 4'hf, 32'h000000cc);
  ctrl_regs_cycle(32'h00800024, 1'b1, 4'hf, 32'h000000dd);
  ctrl_regs_cycle(32'h00800024, 1'b1, 4'hf, 32'h000000ee);
  ctrl_regs_cycle(32'h00800024, 1'b1, 4'hf, 32'h000000ff);
  ctrl_regs_cycle(32'h00800024, 1'b1, 4'hf, 32'h00000001);
  ctrl_regs_cycle(32'h00800024, 1'b1, 4'hf, 32'h00000023);
  ctrl_regs_cycle(32'h00800024, 1'b1, 4'hf, 32'h00000045);
  ctrl_regs_cycle(32'h00800024, 1'b1, 4'hf, 32'h00000067);
  ctrl_regs_cycle(32'h00800024, 1'b1, 4'hf, 32'h00000089);
  ctrl_regs_cycle(32'h00800024, 1'b1, 4'hf, 32'h000000ab);
  ctrl_regs_cycle(32'h00800024, 1'b1, 4'hf, 32'h000000cd);
  ctrl_regs_cycle(32'h00800024, 1'b1, 4'hf, 32'h000000ef);
  repeat (10) @ (posedge soc_top.ctrl_top.clk);


  // readback
  ctrl_bridge_cycle(32'h00180000, 1'b0, 4'hf, 32'h00000000, datr);
  repeat (100) @ (posedge soc_top.clk_7);


/*
  // try a TG68 cycle
  force soc_top.tg68_adr = 24'h123456;
  force soc_top.tg68_dat_out = 16'hbeef;
  force soc_top.tg68_as = 1'b0;
  force soc_top.tg68_uds = 1'b0;
  force soc_top.tg68_lds = 1'b0;
  force soc_top.tg68_rw = 1'b0;
  @ (posedge soc_top.clk_7);
  while (soc_top.tg68_dtack) @ (posedge soc_top.clk_7); #1;
  @ (posedge soc_top.clk_7);
  force soc_top.tg68_as = 1'b1;
  @ (posedge soc_top.clk_7);
  @ (posedge soc_top.clk_7);
  force soc_top.tg68_adr = 24'h123456;
  force soc_top.tg68_dat_out = 16'hdead;
  force soc_top.tg68_as = 1'b0;
  force soc_top.tg68_uds = 1'b1;
  force soc_top.tg68_lds = 1'b1;
  force soc_top.tg68_rw = 1'b1;
  @ (posedge soc_top.clk_7);
  while (soc_top.tg68_dtack) @ (posedge soc_top.clk_7); #1;
  @ (posedge soc_top.clk_7);
  force soc_top.tg68_as = 1'b1;
  @ (posedge soc_top.clk_7);
  @ (posedge soc_top.clk_7);
  release soc_top.tg68_adr;
  release soc_top.tg68_dat_out;
  release soc_top.tg68_as;
  release soc_top.tg68_uds;
  release soc_top.tg68_lds;
  release soc_top.tg68_rw;
  repeat (10) @ (posedge soc_top.clk_7);
*/

  // start monitor
  $display("BENCH : %t : starting vga monitor ...", $time);
  //vga_monitor.start;

  // set pattern mode 2
  //               SW9   SW8   SW7   SW6-2     SW1   SW0
  //switches.toggle({1'b0, 1'b0, 1'b0, 5'b00000, 1'b1, 1'b0});

  // set dither
  //               SW9   SW8   SW7   SW6-2     SW1   SW0
  //switches.toggle({1'b1, 1'b1, 1'b1, 5'b00000, 1'b0, 1'b0});

  // wait for three frames
  //$display("BENCH : %t : waiting for frames ...", $time);
  //wait (`VGA_MON_F_CNT == 7'd3);
  #100;

  // display result
  if (ERR) $display("BENCH : %t : vga_dma test FAILED - there were errors!", $time);
  else     $display("BENCH : %t : vga_dma test PASSED - no errors!", $time);

  $display("BENCH : done.");
  $finish;
end



////////////////////////////////////////
// tasks                              //
////////////////////////////////////////

// force ctrl regs bus
task ctrl_regs_cycle;
input  [32-1:0] adr;
input           we;
input  [ 4-1:0] sel;
input  [32-1:0] dat_w;
output [32-1:0] dat_r;
begin
  @ (posedge soc_top.ctrl_top.clk); #1;
  force soc_top.ctrl_top.ctrl_regs.adr   = adr;
  force soc_top.ctrl_top.ctrl_regs.cs    = 1'b1;
  force soc_top.ctrl_top.ctrl_regs.we    = we;
  force soc_top.ctrl_top.ctrl_regs.sel   = sel;
  force soc_top.ctrl_top.ctrl_regs.dat_w = dat_w;
  @ (posedge soc_top.ctrl_top.clk); #1;
  while (!soc_top.ctrl_top.ctrl_regs.ack) @ (posedge soc_top.ctrl_top.clk); #1;
  release soc_top.ctrl_top.ctrl_regs.adr;
  release soc_top.ctrl_top.ctrl_regs.cs;
  release soc_top.ctrl_top.ctrl_regs.we;
  release soc_top.ctrl_top.ctrl_regs.sel;
  release soc_top.ctrl_top.ctrl_regs.dat_w;
  @ (posedge soc_top.ctrl_top.clk); #1;
  dat_r = soc_top.ctrl_top.ctrl_regs.dat_r;
end
endtask

// force ctrl bridge cycle
task ctrl_bridge_cycle;
input  [32-1:0] adr;
input           we;
input  [ 4-1:0] sel;
input  [32-1:0] dat_w;
output [32-1:0] dat_r;
begin
  @ (posedge soc_top.ctrl_top.clk); #1;
  force soc_top.ctrl_top.dram_adr   = adr;
  force soc_top.ctrl_top.dram_cs    = 1'b1;
  force soc_top.ctrl_top.dram_we    = we;
  force soc_top.ctrl_top.dram_sel   = sel;
  force soc_top.ctrl_top.dram_dat_w = dat_w;
  @ (posedge soc_top.ctrl_top.clk); #1;
  while (!soc_top.ctrl_top.dram_ack) @ (posedge soc_top.ctrl_top.clk); #1;
  release soc_top.ctrl_top.dram_adr;
  release soc_top.ctrl_top.dram_cs;
  release soc_top.ctrl_top.dram_we;
  release soc_top.ctrl_top.dram_sel;
  release soc_top.ctrl_top.dram_dat_w;
  @ (posedge soc_top.ctrl_top.clk); #1;
  dat_r = soc_top.ctrl_top.dram_dat_r;
end
endtask



////////////////////////////////////////
// soc top module                     //
////////////////////////////////////////
minimig_de1_top soc_top (
  .CLOCK_24     (CLOCK_24   ),  // 24 MHz
  .CLOCK_27     (CLOCK_27   ),  // 27 MHz
  .CLOCK_50     (CLOCK_50   ),  // 50 MHz
  .EXT_CLOCK    (CLOCK_EXT  ),  // External Clock
  .TDI          (TDI        ),  // CPLD -> FPGA (data in)
  .TCK          (TCK        ),  // CPLD -> FPGA (clk)
  .TCS          (TCS        ),  // CPLD -> FPGA (CS)
  .TDO          (TDO        ),  // FPGA -> CPLD (data out)
  //.GPIO_0       (GPIO_0     ),  // GPIO Connection 0
  //.GPIO_1       (GPIO_1     ),  // GPIO Connection 1
  .KEY          (BTN        ),  // Pushbutton[3:0]
  .SW           (SW         ),  // Toggle Switch[9:0]
  .HEX0         (HEX_0      ),  // Seven Segment Digit 0
  .HEX1         (HEX_1      ),  // Seven Segment Digit 1
  .HEX2         (HEX_2      ),  // Seven Segment Digit 2
  .HEX3         (HEX_3      ),  // Seven Segment Digit 3
  .LEDG         (LED_G      ),  // LED Green[7:0]
  .LEDR         (LED_R      ),  // LED Red[9:0]
  .UART_TXD     (UART_TXD   ),  // UART Transmitter
  .UART_RXD     (UART_RXD   ),  // UART Receiver
  .I2C_SDAT     (I2C_SDAT   ),  // I2C Data
  .I2C_SCLK     (I2C_SCLK   ),  // I2C Clock
  .PS2_DAT      (PS2_DAT    ),  // PS2 Data
  .PS2_CLK      (PS2_CLK    ),  // PS2 Clock
  .VGA_HS       (VGA_HS     ),  // VGA H_SYNC
  .VGA_VS       (VGA_VS     ),  // VGA V_SYNC
  .VGA_R        (VGA_R      ),  // VGA Red[3:0]
  .VGA_G        (VGA_G      ),  // VGA Green[3:0]
  .VGA_B        (VGA_B      ),  // VGA Blue[3:0]
  .AUD_ADCLRCK  (AUD_ADCLRCK),  // Audio CODEC ADC LR Clock
  .AUD_ADCDAT   (AUD_ADCDAT ),  // Audio CODEC ADC Data
  .AUD_DACLRCK  (AUD_DACLRCK),  // Audio CODEC DAC LR Clock
  .AUD_DACDAT   (AUD_DACDAT ),  // Audio CODEC DAC Data
  .AUD_BCLK     (AUD_BCLK   ),  // Audio CODEC Bit-Stream Clock
  .AUD_XCK      (AUD_XCK    ),  // Audio CODEC Chip Clock
  .SD_DAT       (SD_DAT     ),  // SD Card Data            - spi MISO
  .SD_DAT3      (SD_DAT3    ),  // SD Card Data 3          - spi CS
  .SD_CMD       (SD_CMD     ),  // SD Card Command Signal  - spi MOSI
  .SD_CLK       (SD_CLK     ),  // SD Card Clock           - spi CLK
  .SRAM_DQ      (SRAM_DQ    ),  // SRAM Data bus 16 Bits
  .SRAM_ADDR    (SRAM_ADDR  ),  // SRAM Address bus 18 Bits
  .SRAM_UB_N    (SRAM_UB_N  ),  // SRAM High-byte Data Mask
  .SRAM_LB_N    (SRAM_LB_N  ),  // SRAM Low-byte Data Mask
  .SRAM_WE_N    (SRAM_WE_N  ),  // SRAM Write Enable
  .SRAM_CE_N    (SRAM_CE_N  ),  // SRAM Chip Enable
  .SRAM_OE_N    (SRAM_OE_N  ),  // SRAM Output Enable
  .DRAM_DQ      (DRAM_DQ    ),  // SDRAM Data bus 16 Bits
  .DRAM_ADDR    (DRAM_ADDR  ),  // SDRAM Address bus 12 Bits
  .DRAM_LDQM    (DRAM_LDQM  ),  // SDRAM Low-byte Data Mask
  .DRAM_UDQM    (DRAM_UDQM  ),  // SDRAM High-byte Data Mask
  .DRAM_WE_N    (DRAM_WE_N  ),  // SDRAM Write Enable
  .DRAM_CAS_N   (DRAM_CAS_N ),  // SDRAM Column Address Strobe
  .DRAM_RAS_N   (DRAM_RAS_N ),  // SDRAM Row Address Strobe
  .DRAM_CS_N    (DRAM_CS_N  ),  // SDRAM Chip Select
  .DRAM_BA_0    (DRAM_BA_0  ),  // SDRAM Bank Address 0
  .DRAM_BA_1    (DRAM_BA_1  ),  // SDRAM Bank Address 1
  .DRAM_CLK     (DRAM_CLK   ),  // SDRAM Clock
  .DRAM_CKE     (DRAM_CKE   ),  // SDRAM Clock Enable
  .FL_DQ        (FL_DQ      ),  // FLASH Data bus 8 Bits
  .FL_ADDR      (FL_ADDR    ),  // FLASH Address bus 22 Bits
  .FL_WE_N      (FL_WE_N    ),  // FLASH Write Enable
  .FL_RST_N     (FL_RST_N   ),  // FLASH Reset
  .FL_OE_N      (FL_OE_N    ),  // FLASH Output Enable
  .FL_CE_N      (FL_CE_N    )   // FLASH Chip Enable
);



////////////////////////////////////////
// input / output models              //
////////////////////////////////////////

//// buttons ////
generic_input #(
  .IW   (4),                    // input width
  .PD   (10),                   // push delay
  .DS   (1'b1),                 // default state
  .DBG  (1)                     // debug output
) buttons (
  .o            (BTN)
);


//// switches ////
generic_input #(
  .IW   (10),                   // input width
  .PD   (10),                   // push delay
  .DS   (1'b1),                 // default state
  .DBG  (1)                     // debug output
) switches (
  .o            (SW)
);


//// LEDs ////


//// GPIOs ////


/*
//// vga_monitor ////
vga_monitor #(
  .VGA  (1),                    // SVGA or VGA mode
  .IRW  (4),                    // input red width
  .IGW  (4),                    // input green width
  .IBW  (4),                    // input blue width
  .ODW  (8),                    // output width
  .DLY  (2),                    // output delay
  .COR  ("RGB"),                // color order (RGB or BGR)
  .FNW  (32),                   // filename string width
  .FEX  ("hex"),                // filename extension
  .FILE ("../out/hex/frame")    // filename (without extension!)
) vga_monitor (
  // system
  .clk        (`VGA_MON_CLK),   // clock
  // status
  .oa         (`VGA_MON_OA),    // vga output active
  .f_cnt      (`VGA_MON_F_CNT), // frame counter (resets for every second)
  .f_start    (`VGA_MON_F_STA), // frame start
  // vga data
  .r_in       (VGA_R),          // red   data
  .g_in       (VGA_G),          // green data
  .b_in       (VGA_B)           // blue  data
);
*/


//// SRAM model ////
IS61LV6416L #(
  .memdepth (262144),
  .addbits  (18)
) sram (
  .A          (SRAM_ADDR),
  .IO         (SRAM_DQ),
  .CE_        (SRAM_CE_N),
  .OE_        (SRAM_OE_N),
  .WE_        (SRAM_WE_N),
  .LB_        (SRAM_LB_N),
  .UB_        (SRAM_UB_N)
);


//// SDRAM model ////
mt48lc16m16a2 #(
  .tAC  (5.4),
  .tHZ  (5.4),
  .tOH  (2.5),
  .tMRD (2.0),    // 2 Clk Cycles
  .tRAS (40.0),
  .tRC  (58.0),
  .tRCD (18.0),
  .tRFC (60.0),
  .tRP  (18.0),
  .tRRD (12.0),
  .tWRa (7.0),     // A2 Version - Auto precharge mode (1 Clk + 7 ns)
  .tWRm (14.0)    // A2 Version - Manual precharge mode (14 ns)
) sdram (
  .Dq         (DRAM_DQ),
  .Addr       (DRAM_ADDR),
  .Ba         ({DRAM_BA_1, DRAM_BA_0}),
  .Clk        (DRAM_CLK),
  .Cke        (DRAM_CKE),
  .Cs_n       (DRAM_CS_N),
  .Ras_n      (DRAM_RAS_N),
  .Cas_n      (DRAM_CAS_N),
  .We_n       (DRAM_WE_N),
  .Dqm        ({DRAM_UDQM, DRAM_LDQM})
);


//// SDCARD model ////
sd_card #(
  .FNAME  ("../../../../sd32MBNP.img")
) sdcard (
  .sck          (SD_CLK     ),
  .ss           (SD_DAT3    ),
  .mosi         (SD_CMD     ),
  .miso         (SD_DAT     )
);


/* flash model */


endmodule

