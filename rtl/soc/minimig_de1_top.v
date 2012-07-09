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
wire           clk_50;

// reset
wire           pll_rst;
wire           sdctl_rst;
wire           rst_50;
wire           rst_minimig;

// ctrl
wire           rom_status;
wire           ram_status;
wire           reg_status;

// sram
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
wire           tg68_ena7RD;
wire           tg68_ena7WR;
wire           tg68_enaWR;
wire [ 16-1:0] tg68_cout;
wire           tg68_cpuena;
wire [  2-1:0] cpu_config;
wire [  6-1:0] memcfg;
wire [ 32-1:0] tg68_cad;
wire [  6-1:0] tg68_cpustate;
wire           tg68_cdma;
wire           tg68_clds;
wire           tg68_cuds;

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

// input synchronizers
wire   sw_4, sw_5, sw_6, sw_7, sw_8, sw_9;
wire   key_3, key_2, key_1, key_0;

i_sync #(.DW(3)) i_sync_sw_7 (
  .clk  (clk_7),
  .i    ({SW[7], SW[8], SW[9]}),
  .o    ({sw_7,  sw_8,  sw_9})
);

i_sync #(.DW(1)) i_sync_sw_50 (
  .clk  (clk_50),
  .i    ({SW[6]}),
  .o    ({sw_6})
);

i_sync #(.DW(1)) i_sync_sw_28 (
  .clk  (clk_28),
  .i    (SW[5]),
  .o    (sw_5)
);

i_sync #(.DW(2)) i_sync_key (
  .clk  (clk_7),
  .i    ({KEY[3], KEY[2], KEY[1], KEY[0]}),
  .o    ({key_3,  key_2, key_1, key_0})
);

// clock
assign pll_in_clk   = CLOCK_27[0];

// reset
assign pll_rst      = !SW[0];
assign sdctl_rst    = pll_locked & SW[0];

// tg68
assign tg68_clkena  = 1'b1;

// minimig
assign _15khz       = sw_8;
assign joy_emu_en   = sw_9;

// audio
assign exchan       = sw_7;

// SD card

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

//// control block ////
wire [ 16-1:0]  SRAM_DAT_W;
wire [ 16-1:0]  SRAM_DAT_R;
wire [  8-1:0]  FL_DAT_W;
wire [  8-1:0]  FL_DAT_R;
wire [  4-1:0]  SPI_CS_N;
wire            SPI_DI;

assign SD_DAT3      = SPI_CS_N[0];

assign SRAM_DQ    = SRAM_OE_N ? SRAM_DAT_W : 16'bzzzzzzzzzzzzzzzz;
assign SRAM_DAT_R = SRAM_DQ;
assign FL_DQ      = FL_OE_N   ? FL_DAT_W   : 8'bzzzzzzzz;
assign FL_DAT_R   = FL_DQ;
assign SPI_DI     = !SPI_CS_N[0] ? SD_DAT : sdo;


//// ctrl block ////
ctrl_top ctrl_top (
  // system
  .clk_in       (CLOCK_50   ),
  .rst_ext      (!KEY[0]    ),
  .clk_out      (clk_50     ),
  .rst_out      (rst_50     ),
  .rst_minimig  (rst_minimig),
  // config
  .boot_sel     (sw_6       ),
  // status
  .rom_status   (rom_status ),
  .ram_status   (ram_status ),
  .reg_status   (reg_status ),
  // SRAM interface
  .sram_adr     (SRAM_ADDR  ),
  .sram_ce_n    (SRAM_CE_N  ),
  .sram_we_n    (SRAM_WE_N  ),
  .sram_ub_n    (SRAM_UB_N  ),
  .sram_lb_n    (SRAM_LB_N  ),
  .sram_oe_n    (SRAM_OE_N  ),
  .sram_dat_w   (SRAM_DAT_W ),
  .sram_dat_r   (SRAM_DAT_R ),
  // FLASH interface
  .fl_adr       (FL_ADDR    ),
  .fl_ce_n      (FL_CE_N    ),
  .fl_we_n      (FL_WE_N    ),
  .fl_oe_n      (FL_OE_N    ),
  .fl_rst_n     (FL_RST_N   ),
  .fl_dat_w     (FL_DAT_W   ),
  .fl_dat_r     (FL_DAT_R   ),
  // UART
  .uart_txd     (UART_TXD   ),
  .spi_cs_n     (SPI_CS_N   ),
  .spi_clk      (SD_CLK     ),
  .spi_do       (SD_CMD     ),
  .spi_di       (SPI_DI     )
);


//// clock ////
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


//// indicators ////
indicators indicators(
  .clk          (clk_7            ),
  .rst          (~pll_locked      ),
  .track        (track            ),
  .f_wr         (floppy_fwr       ),
  .f_rd         (floppy_frd       ),
  .h_wr         (hd_fwr           ),
  .h_rd         (hd_frd           ),
  .status       ({rom_status, ram_status, reg_status}),
  .hex_0        (HEX0             ),
  .hex_1        (HEX1             ),
  .hex_2        (HEX2             ),
  .hex_3        (HEX3             ),
  .led_g        (LEDG             ),
  .led_r        (LEDR             )
);


//// TG68K main CPU ////
TG68K tg68k (
  .clk          (clk_114          ),
  .reset        (tg68_rst         ),
  .clkena_in    (1'b1             ),
  .IPL          (tg68_IPL         ),
  .dtack        (tg68_dtack       ),
  .vpa          (1'b1             ),
  .ein          (1'b1             ),
  .addr         (tg68_adr         ),
  .data_read    (tg68_dat_in      ),
  .data_write   (tg68_dat_out     ),
  .as           (tg68_as          ),
  .uds          (tg68_uds         ),
  .lds          (tg68_lds         ),
  .rw           (tg68_rw          ),
  .e            (                 ),
  .vma          (                 ),
  .wrd          (                 ),
  .ena7RDreg    (tg68_ena7RD      ),
  .ena7WRreg    (tg68_ena7WR      ),
  .enaWRreg     (tg68_enaWR       ),
  .fromram      (tg68_cout        ),
  .ramready     (tg68_cpuena      ),
  .cpu          (cpu_config       ),
  .memcfg       (memcfg           ),
  .ramaddr      (tg68_cad         ),
  .cpustate     (tg68_cpustate    ),
  .nResetOut    (                 ),
  .skipFetch    (                 ),
  .cpuDMA       (tg68_cdma        ),
  .ramlds       (tg68_clds        ),
  .ramuds       (tg68_cuds        )
);


//// 7MHz clock ////
reg [2-1:0] clk7_cnt;
always @ (posedge clk_28, negedge pll_locked) begin
  if (!pll_locked)
    clk7_cnt <= #1 2'b10;
  else
    clk7_cnt <= #1 clk7_cnt + 2'b01;
end

assign clk_7 = clk7_cnt[1];

//// sdram ////
sdram sdram (
  .sdata        (DRAM_DQ          ),
  .sdaddr       (DRAM_ADDR        ),
  .dqm          (sdram_dqm        ),
  .sd_cs        (sdram_cs         ),
  .ba           (sdram_ba         ),
  .sd_we        (DRAM_WE_N        ),
  .sd_ras       (DRAM_RAS_N       ),
  .sd_cas       (DRAM_CAS_N       ),
  .sysclk       (clk_114          ),
  .reset_in     (sdctl_rst        ),
  .hostWR       (16'h0            ),
  .hostAddr     (24'h0            ),
  .hostState    ({1'b0, 2'b01}    ),
  .hostL        (1'b1             ),
  .hostU        (1'b1             ),
  .cpuWR        (tg68_dat_out     ),
  .cpuAddr      (tg68_cad[24:1]   ),
  .cpuU         (tg68_cuds        ),
  .cpuL         (tg68_clds        ),
  .cpustate     (tg68_cpustate    ),
  .cpu_dma      (tg68_cdma        ),
  .chipWR       (ram_data         ),
  .chipAddr     ({2'b00, ram_address[21:1]}),
  .chipU        (_ram_bhe         ),
  .chipL        (_ram_ble         ),
  .chipRW       (_ram_we          ),
  .chip_dma     (_ram_oe          ),
  .c_7m         (clk_7            ),
  .hostRD       (                 ),
  .hostena      (                 ),
  .cpuRD        (tg68_cout        ),
  .cpuena       (tg68_cpuena      ),
  .chipRD       (ramdata_in       ),
  .reset_out    (reset_out        ),
  .enaRDreg     (                 ),
  .enaWRreg     (tg68_enaWR       ),
  .ena7RDreg    (tg68_ena7RD      ),
  .ena7WRreg    (tg68_ena7WR      )
);


/*
//// TG68 main CPU ////
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
  .enaRDreg     (tg68_ena7RD      ),
  .enaWRreg     (tg68_ena7WR      )
);



//// sdram ////
sdram_ctrl sdram_ctrl (
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
  .zdatawr      (16'b0            ),
  .zAddr        (24'b0            ),
  .zstate       ({1'b0, 2'b01}),
  .datawr       (ram_data         ),
  .rAddr        ({2'b01, ram_address[21:1], 1'b0}),
  .rwr          (_ram_we          ),
  .dwrL         (_ram_ble         ),
  .dwrU         (_ram_bhe         ),
  .ZwrL         (1'b1             ),
  .ZwrU         (1'b1             ),
  .dma          (_ram_we          ),
  .cpu_dma      (_ram_oe          ),
  .c_28min      (clk_28           ),
  .dataout      (ramdata_in       ),
  .zdataout     (                 ),
  .c_14m        (clk_14           ),
  .zena_o       (zena_o           ),
  .c_28m        (                 ),
  .c_7m         (clk_7            ),
  .reset_out    (reset_out        ),
  .pulse        (pulse            ),
  .enaRDreg     (                 ),
  .enaWRreg     (                 ),
  .ena7RDreg    (tg68_ena7WR      ),
  .ena7WRreg    (tg68_ena7RD      )
);
*/

//// audio ////
audio_top audio_top (
  .clk          (clk_28           ),
  .rst_n        (reset_out        ),
  // config
  .mix          (sw_5             ),
  .volup        (key_1            ),
  .voldown      (key_0            ),
  // audio shifter
  .rdata        (rdata            ),
  .ldata        (ldata            ),
  .exchan       (exchan           ),
  .aud_bclk     (AUD_BCLK         ),
  .aud_daclrck  (AUD_DACLRCK      ),
  .aud_dacdat   (AUD_DACDAT       ),
  .aud_xck      (AUD_XCK          ),
  // I2C audio config
  .i2c_sclk     (I2C_SCLK         ),
  .i2c_sdat     (I2C_SDAT         )
);


//// minimig top ////
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
  ._scs         (SPI_CS_N[3:1]    ), // SPI chip select
  .direct_sdi   (SD_DAT           ), // SD Card direct in
  .sdi          (SD_CMD           ), // SPI data input
  .sdo          (sdo              ), // SPI data output
  .sck          (SD_CLK           ), // SPI clock
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
  .cpu_config   (cpu_config       ), // CPU config
  .memcfg       (memcfg           ), // memory config
  .drv_snd      (                 ),
  .init_b       (                 ), // vertical sync for MCU (sync OSD update)
  // fifo / track display
  .trackdisp    (track            ),
  .secdisp      (dsklen           ),
  .floppy_fwr   (floppy_fwr       ),
  .floppy_frd   (floppy_frd       ),
  .hd_fwr       (hd_fwr           ),
  .hd_frd       (hd_frd           )
);



endmodule

