/********************************************/
/* minimig_de1_top.v                        */
/* Altera DE1 FPGA Top File                 */
/*                                          */
/* 2012, rok.krajnc@gmail.com               */
/********************************************/


`define MINIMIG_DE1
//`define SOC_SIM


module minimig_de1_top (
  // clock inputs
  input  wire [ 2-1:0]  CLOCK_24,   //  24 MHz
  input  wire [ 2-1:0]  CLOCK_27,   //  27 MHz
  input  wire           CLOCK_50,   //  50 MHz
  input  wire           EXT_CLOCK,  //  External Clock
  // USB JTAG Link
  input  wire           TDI,        // CPLD -> FPGA (data in)
  input  wire           TCK,        // CPLD -> FPGA (clk)
  input  wire           TCS,        // CPLD -> FPGA (CS)
  output wire           TDO,        // FPGA -> CPLD (data out)
  // GPIO
//  inout  wire [36-1:0]  GPIO_0,     //  GPIO Connection 0
//  inout  wire [36-1:0]  GPIO_1,     //  GPIO Connection 1
  // push button inputs
  input  wire [ 4-1:0]  KEY,        //  Pushbutton[3:0]
  // switch inputs
  input  wire [10-1:0]  SW,         //  Toggle Switch[9:0]
  // 7-seg display outputs
  output wire [ 7-1:0]  HEX0,      //  Seven Segment Digit 0
  output wire [ 7-1:0]  HEX1,      //  Seven Segment Digit 1
  output wire [ 7-1:0]  HEX2,      //  Seven Segment Digit 2
  output wire [ 7-1:0]  HEX3,      //  Seven Segment Digit 3
  // LED outputs
  output wire [ 8-1:0]  LEDG,      //  LED Green[7:0]
  output wire [10-1:0]  LEDR,      //  LED Red[9:0]
  // UART
  output wire           UART_TXD,   //  UART Transmitter
  input  wire           UART_RXD,   //  UART Receiver
  // I2C
  inout  wire           I2C_SDAT,   //  I2C Data
  output wire           I2C_SCLK,   //  I2C Clock
  // PS2
  inout  wire           PS2_DAT,    //  PS2 Keyboard Data
  inout  wire           PS2_CLK,    //  PS2 Keyboard Clock
  inout  wire           PS2_MDAT,   //  PS2 Mouse Data
  inout  wire           PS2_MCLK,   //  PS2 Mouse Clock
 // VGA
  output wire           VGA_HS,     //  VGA H_SYNC
  output wire           VGA_VS,     //  VGA V_SYNC
  output wire [ 4-1:0]  VGA_R,      //  VGA Red[3:0]
  output wire [ 4-1:0]  VGA_G,      //  VGA Green[3:0]
  output wire [ 4-1:0]  VGA_B,      //  VGA Blue[3:0]
  // Audio CODEC
  inout  wire           AUD_ADCLRCK,//  Audio CODEC ADC LR Clock
  input  wire           AUD_ADCDAT, //  Audio CODEC ADC Data
  inout  wire           AUD_DACLRCK,//  Audio CODEC DAC LR Clock
  output wire           AUD_DACDAT, //  Audio CODEC DAC Data
  inout  wire           AUD_BCLK,   //  Audio CODEC Bit-Stream Clock
  output wire           AUD_XCK,    //  Audio CODEC Chip Clock
  // SD Card
  input  wire           SD_DAT,     //  SD Card Data            - spi MISO
  output wire           SD_DAT3,    //  SD Card Data 3          - spi CS
  output wire           SD_CMD,     //  SD Card Command Signal  - spi MOSI
  output wire           SD_CLK,     //  SD Card Clock           - spi CLK
  // SRAM
  inout  wire [16-1:0]  SRAM_DQ,    //  SRAM Data bus 16 Bits
  output wire [18-1:0]  SRAM_ADDR,  //  SRAM Address bus 18 Bits
  output wire           SRAM_UB_N,  //  SRAM High-byte Data Mask
  output wire           SRAM_LB_N,  //  SRAM Low-byte Data Mask
  output wire           SRAM_WE_N,  //  SRAM Write Enable
  output wire           SRAM_CE_N,  //  SRAM Chip Enable
  output wire           SRAM_OE_N,  //  SRAM Output Enable
  // SDRAM
  inout  wire [16-1:0]  DRAM_DQ,    //  SDRAM Data bus 16 Bits
  output wire [12-1:0]  DRAM_ADDR,  //  SDRAM Address bus 12 Bits
  output wire           DRAM_LDQM,  //  SDRAM Low-byte Data Mask
  output wire           DRAM_UDQM,  //  SDRAM High-byte Data Mask
  output wire           DRAM_WE_N,  //  SDRAM Write Enable
  output wire           DRAM_CAS_N, //  SDRAM Column Address Strobe
  output wire           DRAM_RAS_N, //  SDRAM Row Address Strobe
  output wire           DRAM_CS_N,  //  SDRAM Chip Select
  output wire           DRAM_BA_0,  //  SDRAM Bank Address 0
  output wire           DRAM_BA_1,  //  SDRAM Bank Address 1
  output wire           DRAM_CLK,   //  SDRAM Clock
  output wire           DRAM_CKE,   //  SDRAM Clock Enable
  // FLASH
  inout  wire [ 8-1:0]  FL_DQ,      //  FLASH Data bus 8 Bits
  output wire [22-1:0]  FL_ADDR,    //  FLASH Address bus 22 Bits
  output wire           FL_WE_N,    //  FLASH Write Enable
  output wire           FL_RST_N,   //  FLASH Reset
  output wire           FL_OE_N,    //  FLASH Output Enable
  output wire           FL_CE_N,    //  FLASH Chip Enable
  // MINIMIG specific
  input  wire [ 6-1:0]  Joya,      // joystick port A
  input  wire [ 6-1:0]  Joyb       // joystick port B
);



////////////////////////////////////////
// internal signals                   //
////////////////////////////////////////

// clock
wire           pll_in_clk;
`ifdef SOC_SIM
reg            clk_114;
reg            clk_28;
reg            clk_sdram;
reg            pll_locked;
`else
wire           clk_114;
wire           clk_28;
wire           clk_sdram;
wire           pll_locked;
`endif
wire           clk_7;
wire           clk_14;

// reset
wire           pll_rst;
wire           n_rst;
wire           sdctl_rst;

// sram
wire [ 13-1:0] fifoinptr;
wire [ 16-1:0] fifodwr;
wire           fifowr;
wire [ 13-1:0] fifooutptr;
wire [  8-1:0] track;
wire [ 14-1:0] dsklen;
wire [ 16-1:0] sram_fifodrd;

// tg68
wire           tg68_clkena;
wire           tg68_rst;
wire [ 16-1:0] tg68_dat_in;
wire [ 16-1:0] tg68_dat_out;
wire [ 32-1:0] tg68_adr;
wire [  3-1:0] tg68_IPL;
wire           tg68_dtack;
wire           tg68_as;
wire           tg68_uds;
wire           tg68_lds;
wire           tg68_rw;
wire           tg68_enaRD;
wire           tg68_enaWR;

// minimig
wire [ 16-1:0] ram_data;      // sram data bus
wire [ 16-1:0] ramdata_in;    // sram data bus in
wire [ 22-1:1] ram_address;   // sram address bus
//wire [  4-1:0] _ram_ce;       // sram chip enable
wire           _ram_bhe;      // sram upper byte select
wire           _ram_ble;      // sram lower byte select
wire           _ram_we;       // sram write enable
wire           _ram_oe;       // sram output enable
wire           _15khz;        // scandoubler disable
wire           joy_emu_en;    // joystick emulation enable
wire           sdo;           // SPI data output
wire [ 15-1:0] ldata;         // left DAC data
wire [ 15-1:0] rdata;         // right DAC data
wire           floppy_fwr;
wire           floppy_frd;
wire           hd_fwr;
wire           hd_frd;

// cfide
wire [  8-1:0] sd_cs;
wire           sd_do;
wire           sd_clk;
wire           cfide_memce;

// tg68_fast
wire           tg68_fast_clkena;
wire [ 16-1:0] tg68_fast_dat_in;
wire [ 16-1:0] tg68_fast_dat_out;
wire [ 32-1:0] tg68_fast_adr;
wire [  2-1:0] tg68_fast_state;
wire           tg68_fast_rw;
wire           tg68_fast_uds;
wire           tg68_fast_lds;
wire           tg68_fast_enaRD;
wire           tg68_fast_enaWR;

// sdram
wire           reset_out;
wire           pulse;
wire           zena_o;
wire           enaRDreg;
wire           enaWRreg;
wire [  4-1:0] sdram_cs;
wire [  2-1:0] sdram_dqm;
wire [  2-1:0] sdram_ba;
wire [ 16-1:0] zdataout;

// audio
wire           exchan;



////////////////////////////////////////
// toplevel logic                     //
////////////////////////////////////////

// assign unused outputs
assign TDO          = 1'b1;
assign FL_ADDR      = 22'h3fffff;
assign FL_WE_N      = 1'b1;
assign FL_RST_N     = 1'b1;
assign FL_OE_N      = 1'b1;
assign FL_CE_N      = 1'b0;

// input synchronizers
wire   sw_7, sw_8, sw_9;
wire   key_3, key_2;

i_sync #(.DW(3)) i_sync_sw (
  .clk  (clk_7),
  .i    ({SW[7], SW[8], SW[9]}),
  .o    ({sw_7,  sw_8,  sw_9})
);

i_sync #(.DW(2)) i_sync_key (
  .clk  (clk_7),
  .i    ({KEY[3], KEY[2]}),
  .o    ({key_3,  key_2})
);

// clock
assign pll_in_clk   = CLOCK_27[0];

// reset
assign pll_rst      = !SW[0];
assign n_rst        = reset_out  & SW[1];
assign sdctl_rst    = pll_locked & SW[0];

// tg68
assign tg68_clkena  = 1'b1;

// minimig
assign _15khz       = sw_8;
assign joy_emu_en   = sw_9;

// audio
assign exchan       = sw_7;

// SD card
assign SD_DAT3      = sd_cs[1];
assign SD_CMD       = sd_do;
assign SD_CLK       = sd_clk;

// SDRAM
assign DRAM_CKE     = 1'b1;
assign DRAM_CLK     = clk_sdram;
assign DRAM_CS_N    = sdram_cs[0];
assign DRAM_LDQM    = sdram_dqm[0];
assign DRAM_UDQM    = sdram_dqm[1];
assign DRAM_BA_0    = sdram_ba[0];
assign DRAM_BA_1    = sdram_ba[1];



////////////////////////////////////////
// modules                            //
////////////////////////////////////////

/* clock */
`ifdef SOC_SIM
// generated clocks
initial begin
  pll_locked  = 1'b0;
  #50;
  pll_locked  = 1'b1;
end
initial begin
  clk_114     = 1'b1;
  forever #4.357  clk_114   = ~clk_114;
end
initial begin
  clk_28      = 1'b1;
  forever #17.428 clk_28    = ~clk_28;
end
initial begin
  clk_sdram   = 1'b1;
  forever #4.357  clk_sdram = ~clk_sdram;
end
`else
// use pll
amigaclk amigaclk (
  .areset       (pll_rst          ), // async reset input
  .inclk0       (pll_in_clk       ), // input clock (27MHz)
  .c0           (clk_114          ), // output clock c0 (114.750000MHz)
  .c1           (clk_28           ), // output clock c1 (28.687500MHz)
  .c2           (clk_sdram        ), // output clock c2 (114.750000MHz, -146.25 deg)
  .locked       (pll_locked       )  // pll locked output
);
`endif


/* indicators */
indicators indicators(
  .clk          (clk_7            ),
  .rst          (~pll_locked      ),
  .track        (track            ),
  .f_wr         (floppy_fwr       ),
  .f_rd         (floppy_frd       ),
  .h_wr         (hd_fwr           ),
  .h_rd         (hd_frd           ),
  .hex_0        (HEX0             ),
  .hex_1        (HEX1             ),
  .hex_2        (HEX2             ),
  .hex_3        (HEX3             ),
  .led_g        (LEDG             ),
  .led_r        (LEDR             )
);


/* sram controller */
sram_ctl sram_ctl(
  .clk          (clk_114          ),
  .rst          (!n_rst           ),
  .adr          (tg68_fast_adr    ),
  .rw           (tg68_fast_rw     ),
  .lds          (tg68_fast_uds    ),
  .uds          (tg68_fast_lds    ), 
  .dat_w        (tg68_fast_dat_out),
  .dat_r        (/*zdataout*/         ),
  .ce           (SRAM_CE_N        ),
  .oe           (SRAM_OE_N        ),
  .wr           (SRAM_WE_N        ),
  .bs           ({SRAM_UB_N, SRAM_LB_N}),
  .addr         (SRAM_ADDR        ),
  .data         (SRAM_DQ          )
);


/* tg68 main cpu */
TG68 tg68 (
  .clk          (clk_114          ),
  .reset        (tg68_rst         ),
  .clkena_in    (tg68_clkena      ),
  .data_in      (tg68_dat_in      ),
  .data_out     (tg68_dat_out     ),
  .IPL          (tg68_IPL         ),
  .dtack        (tg68_dtack       ),
  .addr         (tg68_adr         ),
  .as           (tg68_as          ),
  .uds          (tg68_uds         ),
  .lds          (tg68_lds         ),
  .rw           (tg68_rw          ),
  .drive_data   (                 ),
  .enaRDreg     (tg68_enaRD       ),
  .enaWRreg     (tg68_enaWR       )
);


/* minimig top */
Minimig1 minimig (
  //m68k pins
  .cpu_address  (tg68_adr[23:1]   ), // M68K address bus
  .cpu_data     (tg68_dat_in      ), // M68K data bus
  .cpudata_in   (tg68_dat_out     ), // M68K data in
  ._cpu_ipl     (tg68_IPL         ), // M68K interrupt request
  ._cpu_as      (tg68_as          ), // M68K address strobe
  ._cpu_uds     (tg68_uds         ), // M68K upper data strobe
  ._cpu_lds     (tg68_lds         ), // M68K lower data strobe
  .cpu_r_w      (tg68_rw          ), // M68K read / write
  ._cpu_dtack   (tg68_dtack       ), // M68K data acknowledge
  ._cpu_reset   (tg68_rst         ), // M68K reset
  .cpu_clk      (clk_7            ), // M68K clock
  //sram pins
  .ram_data     (ram_data         ), // SRAM data bus
  .ramdata_in   (ramdata_in       ), // SRAM data bus in
  .ram_address  (ram_address[21:1]), // SRAM address bus
  ._ram_ce      (                 ), // SRAM chip enable
  ._ram_bhe     (_ram_bhe         ), // SRAM upper byte select
  ._ram_ble     (_ram_ble         ), // SRAM lower byte select
  ._ram_we      (_ram_we          ), // SRAM write enable
  ._ram_oe      (_ram_oe          ), // SRAM output enable
  //system  pins
  .clk          (clk_7            ), // system clock (7.09379 MHz)
  .clk28m       (clk_28           ), // 28.37516 MHz clock
  //rs232 pins
  .rxd          (1'b0             ), // RS232 receive
  .txd          (                 ), // RS232 send
  .cts          (1'b0             ), // RS232 clear to send
  .rts          (                 ), // RS232 request to send
  //I/O
  ._joy1        (Joya             ), // joystick 1 [fire2,fire,up,down,left,right] (default mouse port)
  ._joy2        (Joyb             ), // joystick 2 [fire2,fire,up,down,left,right] (default joystick port)
  .mouse_btn1   (key_3            ), // mouse button 1
  .mouse_btn2   (key_2            ), // mouse button 2
  .joy_emu_en   (joy_emu_en       ), // enable keyboard joystick emulation
  ._15khz       (_15khz           ), // scandoubler disable
  .pwrled       (                 ), // power led
  .msdat        (PS2_MDAT         ), // PS2 mouse data
  .msclk        (PS2_MCLK         ), // PS2 mouse clk
  .kbddat       (PS2_DAT          ), // PS2 keyboard data
  .kbdclk       (PS2_CLK          ), // PS2 keyboard clk
  //host controller interface (SPI)
  ._scs         (sd_cs[6:4]       ), // SPI chip select
  .direct_sdi   (SD_DAT           ), // SD Card direct in
  .sdi          (sd_do            ), // SPI data input
  .sdo          (sdo              ), // SPI data output
  .sck          (sd_clk           ), // SPI clock
  //video
  ._hsync       (VGA_HS           ), // horizontal sync
  ._vsync       (VGA_VS           ), // vertical sync
  .red          (VGA_R            ), // red
  .green        (VGA_G            ), // green
  .blue         (VGA_B            ), // blue
  //audio
  .left         (                 ), // audio bitstream left
  .right        (                 ), // audio bitstream right
  .ldata        (ldata            ), // left DAC data
  .rdata        (rdata            ), // right DAC data
  //user i/o
  .gpio         (                 ), // spare GPIO
  // DE1 Ext. SRAM for FIFO
  .fifoinptr    (fifoinptr        ),
  .fifodwr      (fifodwr          ),
  .fifowr       (fifowr           ),
  .fifooutptr   (fifooutptr       ),
  .fifodrd      (sram_fifodrd     ),
  .trackdisp    (track            ),
  .secdisp      (dsklen           ),
  .floppy_fwr   (floppy_fwr       ),
  .floppy_frd   (floppy_frd       ),
  .hd_fwr       (hd_fwr           ),
  .hd_frd       (hd_frd           )
);


/* cfide */
cfide cfide (
  .sysclk       (clk_114          ),
  .n_reset      (n_rst            ),
  .cpuena_in    (zena_o           ),
  .memdata_in   (zdataout         ),
  .addr         (tg68_fast_adr[23:0]),
  .cpudata      (tg68_fast_dat_in ),
  .cpudata_in   (tg68_fast_dat_out),
  .state        (tg68_fast_state  ),
  .lds          (tg68_fast_lds    ),
  .uds          (tg68_fast_uds    ),
  .sd_di        (SD_DAT           ),
  .memce        (cfide_memce      ),
  .cpuena       (tg68_fast_clkena ),
  .TxD          (UART_TXD         ),
  .sd_cs        (sd_cs            ),
  .sd_clk       (sd_clk           ),
  .sd_do        (sd_do            ),
  .sd_dimm      (sdo              ),
  .enaWRreg     (tg68_fast_enaWR  )
);


/* tg68_fast control cpu */
TG68_fast tg68_fast (
  .clk          (clk_114          ),
  .reset        (n_rst            ),
  .clkena_in    (tg68_fast_clkena ),
  .data_in      (tg68_fast_dat_in ),
  .data_write   (tg68_fast_dat_out),
  .IPL          (3'b111           ),
  .test_IPL     (1'b1             ),
  .address      (tg68_fast_adr    ),
  .state_out    (tg68_fast_state  ),
  .LDS          (tg68_fast_lds    ),
  .UDS          (tg68_fast_uds    ),
  .decodeOPC    (                 ),
  .wr           (tg68_fast_rw     ),
  .enaRDreg     (tg68_fast_enaRD  ),
  .enaWRreg     (tg68_fast_enaWR  )
);


/* sdram */
sdram sdram (
  .sysclk       (clk_114          ),
  .reset        (sdctl_rst        ),
  .sdata        (DRAM_DQ          ),
  .sdaddr       (DRAM_ADDR        ),
  .sd_we        (DRAM_WE_N        ),
  .sd_ras       (DRAM_RAS_N       ),
  .sd_cas       (DRAM_CAS_N       ),
  .sd_cs        (sdram_cs         ),
  .dqm          (sdram_dqm        ),
  .ba           (sdram_ba         ),
  .zdatawr      (tg68_fast_dat_out),
  .zAddr        (tg68_fast_adr[23:0]),
  .zstate       ({cfide_memce, tg68_fast_state}),
  .datawr       (ram_data         ),
  .rAddr        ({2'b01, ram_address[21:1], 1'b0}),
  .rwr          (_ram_we          ),
  .dwrL         (_ram_ble         ),
  .dwrU         (_ram_bhe         ),
  .ZwrL         (tg68_fast_lds    ),
  .ZwrU         (tg68_fast_uds    ),
  .dma          (_ram_we          ),
  .cpu_dma      (_ram_oe          ),
  .c_28min      (clk_28           ),
  .dataout      (ramdata_in       ),
  .zdataout     (zdataout         ),
  .c_14m        (clk_14           ),
  .zena_o       (zena_o           ),
  .c_28m        (                 ),
  .c_7m         (clk_7            ),
  .reset_out    (reset_out        ),
  .pulse        (pulse            ),
  .enaRDreg     (tg68_fast_enaRD  ),
  .enaWRreg     (tg68_fast_enaWR  ),
  .ena7RDreg    (tg68_enaWR       ),
  .ena7WRreg    (tg68_enaRD       )
);


// don't include these two modules for sim, as they have some probems in simulation
`ifndef SOC_SIM
/* audio shifter */
audio_shifter audio_shifter (
  .clk          (clk_28           ),
  .nreset       (reset_out        ),
  .rechts       ({rdata, 1'b0}    ),
  .links        ({ldata, 1'b0}    ),
  .exchan       (exchan           ),
  .aud_bclk     (AUD_BCLK         ),
  .aud_daclrck  (AUD_DACLRCK      ),
  .aud_dacdat   (AUD_DACDAT       ),
  .aud_xck      (AUD_XCK          )
);


/* i2c audio config */
I2C_AV_Config audio_config (
  // host side
  .iCLK         (clk_28           ),
  .iRST_N       (reset_out        ),
  // i2c side
  .oI2C_SCLK    (I2C_SCLK         ),
  .oI2C_SDAT    (I2C_SDAT         )
);
`endif


endmodule

