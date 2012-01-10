/********************************************/
/* minimig_de1_top.v                        */
/* Altera DE1 FPGA Top File                 */
/*                                          */
/* 2012, rok.krajnc@gmail.com               */
/********************************************/


`define MINIMIG_DE1


module minimig_de1_top (
  // clock inputs
  input  wire [ 2-1:0]  CLOCK_24,   //  24 MHz
  input  wire [ 2-1:0]  CLOCK_27,   //  27 MHz
  input  wire           CLOCK_50,   //  50 MHz
  input  wire           CLOCK_EXT,  //  External Clock
  // USB JTAG Link
  input  wire           TDI,        // CPLD -> FPGA (data in)
  input  wire           TCK,        // CPLD -> FPGA (clk)
  input  wire           TCS,        // CPLD -> FPGA (CS)
  output wire           TDO,        // FPGA -> CPLD (data out)
  // GPIO
  inout  wire [36-1:0]  GPIO_0,     //  GPIO Connection 0
  inout  wire [36-1:0]  GPIO_1,     //  GPIO Connection 1
  // push button inputs
  input  wire [ 4-1:0]  BTN,        //  Pushbutton[3:0]
  // switch inputs
  input  wire [10-1:0]  SW,         //  Toggle Switch[9:0]
  // 7-seg display outputs
  output wire [ 7-1:0]  HEX_0,      //  Seven Segment Digit 0
  output wire [ 7-1:0]  HEX_1,      //  Seven Segment Digit 1
  output wire [ 7-1:0]  HEX_2,      //  Seven Segment Digit 2
  output wire [ 7-1:0]  HEX_3,      //  Seven Segment Digit 3
  // LED outputs
  output wire [ 8-1:0]  LED_G,      //  LED Green[7:0]
  output wire [10-1:0]  LED_R,      //  LED Red[9:0]
  // UART
  output wire           UART_TXD,   //  UART Transmitter
  input  wire           UART_RXD,   //  UART Receiver
  // I2C
  inout  wire           I2C_SDAT,   //  I2C Data
  output wire           I2C_SCLK,   //  I2C Clock
  // PS2
  input  wire           PS2_DAT,    //  PS2 Data
  input  wire           PS2_CLK,    //  PS2 Clock
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
  output wire           FL_CE_N     //  FLASH Chip Enable
);



////////////////////////////////////////
// internal signals                   //
////////////////////////////////////////

// clock
wire           areset;
wire           inclk0;
wire           c0;
wire           c1;
wire           c2;
wire           locked;



////////////////////////////////////////
// toplevel logic                     //
////////////////////////////////////////

// clock
assign areset = !(SW[0]);
assign inclk0 = CLOCK_27[0];





////////////////////////////////////////
// modules                            //
////////////////////////////////////////

/* clock */
amigaclk amigaclk (
  .areset       (areset      ), // async reset input
  .inclk0       (inclk0      ), // input clock (27MHz)
  .c0           (c0          ), // output clock c0 (114.750000MHz)
  .c1           (c1          ), // output clock c1 (28.687500MHz)
  .c2           (c2          ), // output clock c2 (114.750000MHz, -146.25 deg)
  .locked       (locked      )  // pll locked output
);


/* sram controller */
wire clk;
wire pulse;
wire [ 13-1:0] fifoinptr;
wire [ 16-1:0] fifodwr;
wire           fifowr;
wire [ 13-1:0] fifooutptr;
wire [  8-1:0] track;
wire [ 14-1:0] dsklen;
wire [ 18-1:0] addr;
wire [ 16-1:0] data;
wire           oe;
wire           wr;
wire [ 16-1:0] fifodrd;
wire [  7-1:0] hex1;
wire [  7-1:0] hex10;
wire [  7-1:0] hex100;
wire [ 10-1:0] led;

SRAM sram (
  .clk          (clk         ),
  .pulse        (pulse       ),
  .fifoinptr    (fifoinptr   ),
  .fifodwr      (fifodwr     ),
  .fifowr       (fifowr      ),
  .fifooutptr   (fifooutptr  ),
  .track        (track       ),
  .dsklen       (dsklen      ),
  .addr         (addr        ),
  .data         (data        ),
  .oe           (oe          ),
  .wr           (wr          ),
  .fifodrd      (fifodrd     ),
  .hex1         (hex1        ),
  .hex10        (hex10       ),
  .hex100       (hex100      ),
  .led          (led         )
);


/* tg68 main cpu */
wire           clk;
wire           reset;
wire           clkena_in;
wire [ 16-1:0] data_in;
wire [  3-1:0] IPL;
wire           dtack;
wire [ 32-1:0] addr;
wire [ 16-1:0] data_out;
wire           as;
wire           uds;
wire           lds;
wire           rw;
wire           drive_data;
wire           enaRDreg;
wire           enaWRreg;

TG68 tg68 (
  .clk          (clk         ),
  .reset        (reset       ),
  .clkena_in    (clkena_in   ),
  .data_in      (data_in     ),
  .IPL          (IPL         ),
  .dtack        (dtack       ),
  .addr         (addr        ),
  .data_out     (data_out    ),
  .as           (as          ),
  .uds          (uds         ),
  .lds          (lds         ),
  .rw           (rw          ),
  .drive_data   (drive_data  ),
  .enaRDreg     (enaRDreg    ),
  .enaWRreg     (enaWRreg    )
);


/* minimig top */
wire [ 16-1:0] cpu_data;      //m68k data bus
wire [ 24-1:1] cpu_address;   //m68k address bus
wire [ 16-1:0] cpudata_in;    //m68k data in
wire [  3-1:0] _cpu_ipl;      //m68k interrupt request
wire           _cpu_as;       //m68k address strobe
wire           _cpu_uds;      //m68k upper data strobe
wire           _cpu_lds;      //m68k lower data strobe
wire           cpu_r_w;       //m68k read / write
wire           _cpu_dtack;    //m68k data acknowledge
wire           _cpu_reset;    //m68k reset
wire           cpu_clk;       //m68k clock
wire [ 16-1:0] ram_data;      //sram data bus
wire [ 22-1:1] ram_address;   //sram address bus
wire [  4-1:0] _ram_ce;       //sram chip enable
wire           _ram_bhe;      //sram upper byte select
wire           _ram_ble;      //sram lower byte select
wire           _ram_we;       //sram write enable
wire           _ram_oe;       //sram output enable
wire           clk;           //system clock (7.09379 MHz)
wire           clk28m;        //28.37516 MHz clock
wire           rxd;           //rs232 receive
wire           txd;           //rs232 send
wire           cts;           //rs232 clear to send
wire           rts;           //rs232 request to send
wire [  6-1:0] _joy1;         //joystick 1 [fire2,fire,up,down,left,right] (default mouse port)
wire [  6-1:0] _joy2;         //joystick 2 [fire2,fire,up,down,left,right] (default joystick port)
wire           _15khz;        //scandoubler disable
wire           pwrled;        //power led
wire           msdat;         //PS2 mouse data
wire           msclk;         //PS2 mouse clk
wire           kbddat;        //PS2 keyboard data
wire           kbdclk;        //PS2 keyboard clk
wire [  3-1:0] _scs;          //SPI chip select
wire           direct_sdi;    //SD Card direct in
wire           sdi;           //SPI data input
wire           sdo;           //SPI data output
wire           sck;           //SPI clock
wire           _hsync;        //horizontal sync
wire           _vsync;        //vertical sync
wire [  4-1:0] red;           //red
wire [  4-1:0] green;         //green
wire [  4-1:0] blue;          //blue
wire           left;          //audio bitstream left
wire           right;         //audio bitstream right
wire [ 15-1:0] ldata;         //left DAC data
wire [ 15-1:0] rdata;         //right DAC data
wire           gpio;
wire [ 16-1:0] ramdata_in;    //sram data bus in
wire [ 13-1:0] fifoinptr;
wire [ 16-1:0] fifodwr;
wire           fifowr;
wire [ 13-1:0] fifooutptr;
wire [ 16-1:0] fifodrd;
wire [  8-1:0] trackdisp;
wire [ 14-1:0] secdisp;

Minimig1 minimig (
  //m68k pins
  .cpu_data     (cpu_data    ), // M68K data bus
  .cpu_address  (cpu_address ), // M68K address bus
  .cpudata_in   (cpudata_in  ), // M68K data in
  ._cpu_ipl     (_cpu_ipl    ), // M68K interrupt request
  ._cpu_as      (_cpu_as     ), // M68K address strobe
  ._cpu_uds     (_cpu_uds    ), // M68K upper data strobe
  ._cpu_lds     (_cpu_lds    ), // M68K lower data strobe
  .cpu_r_w      (cpu_r_w     ), // M68K read / write
  ._cpu_dtack   (_cpu_dtack  ), // M68K data acknowledge
  ._cpu_reset   (_cpu_reset  ), // M68K reset
  .cpu_clk      (cpu_clk     ), // M68K clock
  //sram pins
  .ram_data     (ram_data    ), // SRAM data bus
  .ram_address  (ram_address ), // SRAM address bus
  ._ram_ce      (_ram_ce     ), // SRAM chip enable
  ._ram_bhe     (_ram_bhe    ), // SRAM upper byte select
  ._ram_ble     (_ram_ble    ), // SRAM lower byte select
  ._ram_we      (_ram_we     ), // SRAM write enable
  ._ram_oe      (_ram_oe     ), // SRAM output enable
  //system  pins
  .clk          (clk         ), // system clock (7.09379 MHz)
  .clk28m       (clk28m      ), // 28.37516 MHz clock
  //rs232 pins
  .rxd          (rxd         ), // RS232 receive
  .txd          (txd         ), // RS232 send
  .cts          (cts         ), // RS232 clear to send
  .rts          (rts         ), // RS232 request to send
  //I/O
  ._joy1        (_joy1       ), // joystick 1 [fire2,fire,up,down,left,right] (default mouse port)
  ._joy2        (_joy2       ), // joystick 2 [fire2,fire,up,down,left,right] (default joystick port)
  ._15khz       (_15khz      ), // scandoubler disable
  .pwrled       (pwrled      ), // power led
  .msdat        (msdat       ), // PS2 mouse data
  .msclk        (msclk       ), // PS2 mouse clk
  .kbddat       (kbddat      ), // PS2 keyboard data
  .kbdclk       (kbdclk      ), // PS2 keyboard clk
  //host controller interface (SPI)
  ._scs         (_scs        ), // SPI chip select
  .direct_sdi   (direct_sdi  ), // SD Card direct in
  .sdi          (sdi         ), // SPI data input
  .sdo          (sdo         ), // SPI data output
  .sck          (sck         ), // SPI clock
  //video
  ._hsync       (_hsync      ), // horizontal sync
  ._vsync       (_vsync      ), // vertical sync
  .red          (red         ), // red
  .green        (green       ), // green
  .blue         (blue        ), // blue
  //audio
  .left         (left        ), // audio bitstream left
  .right        (right       ), // audio bitstream right
  .ldata        (ldata       ), // left DAC data
  .rdata        (rdata       ), // right DAC data
  //user i/o
  .gpio         (gpio        ), // spare GPIO
  // sram data in
  .ramdata_in   (ramdata_in  ), // SRAM data bus in
  // DE1 Ext. SRAM for FIFO
  .fifoinptr    (fifoinptr   ),
  .fifodwr      (fifodwr     ),
  .fifowr       (fifowr      ),
  .fifooutptr   (fifooutptr  ),
  .fifodrd      (fifodrd     ),
  .trackdisp    (trackdisp   ),
  .secdisp      (secdisp     )
);


/* cfide */
wire [ 16-1:0] idedata_in;
wire           sysclk;
wire           n_reset;
wire           cpuena_in;
wire [ 16-1:0] memdata_in;
wire [ 24-1:0] addr;
wire [ 16-1:0] cpudata_in;
wire [  2-1:0] state;
wire           lds;
wire           uds;
wire           sd_di;
wire [ 16-1:0] idedata;
wire [  3-1:0] idea;
wire           ide_wr;
wire           ide_rd;
wire           ide_csp0;
wire           ide_css0;
wire           ide_csp1;
wire           memce;
wire [ 16-1:0] cpudata;
wire           cpuena;
wire           TxD;
wire [  8-1:0] sd_cs;
wire           sd_clk;
wire           sd_do;
wire [ 24-1:0] A_addr;
wire [ 16-1:0] A_cpudata_in;
wire           A_rw;
wire           A_selide;
wire [ 16-1:0] A_cpudata;
wire           A_iderdy;
wire           ideirq;
wire           support_run;
wire           sd_dimm;
wire           enaWRreg;

cfide cfide (
  .idedata_in   (idedata_in  ),
  .sysclk       (sysclk      ),
  .n_reset      (n_reset     ),
  .cpuena_in    (cpuena_in   ),
  .memdata_in   (memdata_in  ),
  .addr         (addr        ),
  .cpudata_in   (cpudata_in  ),
  .state        (state       ),
  .lds          (lds         ),
  .uds          (uds         ),
  .sd_di        (sd_di       ),
  .idedata      (idedata     ),
  .idea         (idea        ),
  .ide_wr       (ide_wr      ),
  .ide_rd       (ide_rd      ),
  .ide_csp0     (ide_csp0    ),
  .ide_css0     (ide_css0    ),
  .ide_csp1     (ide_csp1    ),
  .memce        (memce       ),
  .cpudata      (cpudata     ),
  .cpuena       (cpuena      ),
  .TxD          (TxD         ),
  .sd_cs        (sd_cs       ),
  .sd_clk       (sd_clk      ),
  .sd_do        (sd_do       ),
  .A_addr       (A_addr      ),
  .A_cpudata_in (A_cpudata_in),
  .A_rw         (A_rw        ),
  .A_selide     (A_selide    ),
  .A_cpudata    (A_cpudata   ),
  .A_iderdy     (A_iderdy    ),
  .ideirq       (ideirq      ),
  .support_run  (support_run ),
  .sd_dimm      (sd_dimm     ),
  .enaWRreg     (enaWRreg    )
);


/* tg68_fast control cpu */
wire           clk;
wire           reset;
wire           clkena_in;
wire [ 16-1:0] data_in;
wire [  3-1:0] IPL;
wire           test_IPL;
wire [ 32-1:0] address;
wire [ 16-1:0] data_write;
wire [  2-1:0] state_out;
wire           LDS;
wire           UDS;
wire           decodeOPC;
wire           wr;
wire           enaRDreg;
wire           enaWRreg;

TG68_fast TG68_fast (
  .clk          (clk         ),
  .reset        (reset       ),
  .clkena_in    (clkena_in   ),
  .data_in      (data_in     ),
  .IPL          (IPL         ),
  .test_IPL     (test_IPL    ),
  .address      (address     ),
  .data_write   (data_write  ),
  .state_out    (state_out   ),
  .LDS          (LDS         ),
  .UDS          (UDS         ),
  .decodeOPC    (decodeOPC   ),
  .wr           (wr          ),
  .enaRDreg     (enaRDreg    ),
  .enaWRreg     (enaWRreg    )
);


/* sdram */
wire [ 16-1:0] sdata;
wire [ 12-1:0] sdaddr;
wire           sd_we;
wire           sd_ras;
wire           sd_cas;
wire [  4-1:0] sd_cs;
wire [  2-1:0] dqm;
wire [  2-1:0] ba;
wire           sysclk;
wire           reset;
wire [ 16-1:0] zdatawr;
wire [ 24-1:0] zAddr;
wire [  3-1:0] zstate;
wire [ 16-1:0] datawr;
wire [ 24-1:0] rAddr;
wire           rwr;
wire           dwrL;
wire           dwrU;
wire           ZwrL;
wire           ZwrU;
wire           dma;
wire           cpu_dma;
wire           c_28min;
wire [ 16-1:0] dataout;
wire [ 16-1:0] zdataout;
wire           c_14m;
wire           zena_o;
wire           c_28m;
wire           c_7m;
wire           reset_out;
wire           pulse;
wire           enaRDreg;
wire           enaWRreg;
wire           ena7RDreg;
wire           ena7WRreg;

sdram sdram (
  .sdata        (sdata       ),
  .sdaddr       (sdaddr      ),
  .sd_we        (sd_we       ),
  .sd_ras       (sd_ras      ),
  .sd_cas       (sd_cas      ),
  .sd_cs        (sd_cs       ),
  .dqm          (dqm         ),
  .ba           (ba          ),
  .sysclk       (sysclk      ),
  .reset        (reset       ),
  .zdatawr      (zdatawr     ),
  .zAddr        (zAddr       ),
  .zstate       (zstate      ),
  .datawr       (datawr      ),
  .rAddr        (rAddr       ),
  .rwr          (rwr         ),
  .dwrL         (dwrL        ),
  .dwrU         (dwrU        ),
  .ZwrL         (ZwrL        ),
  .ZwrU         (ZwrU        ),
  .dma          (dma         ),
  .cpu_dma      (cpu_dma     ),
  .c_28min      (c_28min     ),
  .dataout      (dataout     ),
  .zdataout     (zdataout    ),
  .c_14m        (c_14m       ),
  .zena_o       (zena_o      ),
  .c_28m        (c_28m       ),
  .c_7m         (c_7m        ),
  .reset_out    (reset_out   ),
  .pulse        (pulse       ),
  .enaRDreg     (enaRDreg    ),
  .enaWRreg     (enaWRreg    ),
  .ena7RDreg    (ena7RDreg   ),
  .ena7WRreg    (ena7WRreg   )
);


/* audio shifter */
wire           clk;
wire           nreset;
wire [ 16-1:0] rechts;
wire [ 16-1:0] links;
wire           exchan;
wire           aud_bclk;
wire           aud_daclrck;
wire           aud_dacdat;
wire           aud_xck;

Audio_shifter audio_shifter (
  .clk          (clk         ),
  .nreset       (nreset      ),
  .rechts       (rechts      ),
  .links        (links       ),
  .exchan       (exchan      ),
  .aud_bclk     (aud_bclk    ),
  .aud_daclrck  (aud_daclrck ),
  .aud_dacdat   (aud_dacdat  ),
  .aud_xck      (aud_xck     )
);


/* i2c audio config */
wire iCLK;
wire iRST_N;
wire oI2C_SCLK;
wire oI2C_SDAT;

I2C_AV_Config audio_config (
  // host side
  .iCLK         (iCLK        ),
  .iRST_N       (iRST_N      ),
  // i2c side
  .oI2C_SCLK    (oI2C_SCLK   ),
  .oI2C_SDAT    (oI2C_SDAT   )
);



endmodule

