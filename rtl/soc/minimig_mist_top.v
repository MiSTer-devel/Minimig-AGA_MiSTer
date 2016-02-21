/********************************************/
/* minimig_mist_top.v                       */
/* MiST Board Top File                      */
/*                                          */
/* 2012-2015, rok.krajnc@gmail.com          */
/********************************************/


// board type define
`define MINIMIG_MIST

// new cpu define
//`define MINIMIG_MIST_NEWCPU

// simulation define
//`define SOC_SIM

`include "minimig_defines.vh"


module minimig_mist_top (
  // clock inputs
  input  wire [  2-1:0] CLOCK_32,   // 32 MHz
  input  wire [  2-1:0] CLOCK_27,   // 27 MHz
  input  wire [  2-1:0] CLOCK_50,   // 50 MHz
  // LED outputs
  output wire           LED,        // LED Yellow
  // UART
  output wire           UART_TX,    // UART Transmitter
  input wire            UART_RX,    // UART Receiver
  // VGA
  output wire           VGA_HS,     // VGA H_SYNC
  output wire           VGA_VS,     // VGA V_SYNC
  output wire [  6-1:0] VGA_R,      // VGA Red[5:0]
  output wire [  6-1:0] VGA_G,      // VGA Green[5:0]
  output wire [  6-1:0] VGA_B,      // VGA Blue[5:0]
  // SDRAM
  inout  wire [ 16-1:0] SDRAM_DQ,   // SDRAM Data bus 16 Bits
  output wire [ 13-1:0] SDRAM_A,    // SDRAM Address bus 13 Bits
  output wire           SDRAM_DQML, // SDRAM Low-byte Data Mask
  output wire           SDRAM_DQMH, // SDRAM High-byte Data Mask
  output wire           SDRAM_nWE,  // SDRAM Write Enable
  output wire           SDRAM_nCAS, // SDRAM Column Address Strobe
  output wire           SDRAM_nRAS, // SDRAM Row Address Strobe
  output wire           SDRAM_nCS,  // SDRAM Chip Select
  output wire [  2-1:0] SDRAM_BA,   // SDRAM Bank Address
  output wire           SDRAM_CLK,  // SDRAM Clock
  output wire           SDRAM_CKE,  // SDRAM Clock Enable
  // MINIMIG specific
  output wire           AUDIO_L,    // sigma-delta DAC output left
  output wire           AUDIO_R,    // sigma-delta DAC output right
  // SPI
  inout wire            SPI_DO,     // inout
  input wire            SPI_DI,
  input wire            SPI_SCK,
  input wire            SPI_SS2,    // fpga
  input wire            SPI_SS3,    // OSD
  input wire            SPI_SS4,    // "sniff" mode
  input wire            CONF_DATA0  // SPI_SS for user_io
);


////////////////////////////////////////
// internal signals                   //
////////////////////////////////////////

// clock
wire           pll_in_clk;
wire           clk_114;
wire           clk_28;
wire           clk_sdram;
wire           pll_locked;
wire           clk_7;
wire           clk7_en;
wire           clk7n_en;
wire           c1;
wire           c3;
wire           cck;
wire [ 10-1:0] eclk;

// reset
wire           pll_rst;
wire           sdctl_rst;
wire           rst_50;
wire           rst_minimig;

// ctrl
wire           rom_status;
wire           ram_status;
wire           reg_status;

// tg68
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
wire [  4-1:0] cpu_config;
wire [  6-1:0] memcfg;
wire           turbochipram;
wire           turbokick;
wire           cache_inhibit;
wire [ 32-1:0] tg68_cad;
wire [  6-1:0] tg68_cpustate;
wire           tg68_nrst_out;
wire           tg68_cdma;
wire           tg68_clds;
wire           tg68_cuds;
wire [  4-1:0] tg68_CACR_out;
wire [ 32-1:0] tg68_VBR_out;
wire           tg68_ovr;

// minimig
wire           led;
wire [ 16-1:0] ram_data;      // sram data bus
wire [ 16-1:0] ramdata_in;    // sram data bus in
wire [ 48-1:0] chip48;        // big chip read
wire [ 22-1:1] ram_address;   // sram address bus
wire           _ram_bhe;      // sram upper byte select
wire           _ram_ble;      // sram lower byte select
wire           _ram_we;       // sram write enable
wire           _ram_oe;       // sram output enable
wire           _15khz;        // scandoubler disable
wire           joy_emu_en;    // joystick emulation enable
wire           sdo;           // SPI data output
wire [ 15-1:0] ldata;         // left DAC data
wire [ 15-1:0] rdata;         // right DAC data
wire           audio_left;
wire           audio_right;
wire           vs;
wire           hs;
wire [  8-1:0] red;
wire [  8-1:0] green;
wire [  8-1:0] blue;
reg            vs_reg;
reg            hs_reg;
reg  [  6-1:0] red_reg;
reg  [  6-1:0] green_reg;
reg  [  6-1:0] blue_reg;

// sdram
wire           reset_out;
wire [  4-1:0] sdram_cs;
wire [  2-1:0] sdram_dqm;
wire [  2-1:0] sdram_ba;

// mist
wire           user_io_sdo;
wire           minimig_sdo;
wire [  8-1:0] JOYA;
wire [  8-1:0] JOYB;
reg  [  8-1:0] JOYA_0;
reg  [  8-1:0] JOYB_0;
reg  [  8-1:0] JOYA_1;
reg  [  8-1:0] JOYB_1;
wire [  8-1:0] joya;
wire [  8-1:0] joyb;
wire [  8-1:0] kbd_mouse_data;
wire           kbd_mouse_strobe;
wire           kms_level;
wire [  2-1:0] kbd_mouse_type;
wire [  3-1:0] MOUSE_BUTTONS;
reg  [  3-1:0] MOUSE_BUTTONS_0;
reg  [  3-1:0] MOUSE_BUTTONS_1;
wire [  3-1:0] mouse_buttons;
wire [  4-1:0] CORE_CONFIG;
reg  [  4-1:0] CORE_CONFIG_0;
reg  [  4-1:0] CORE_CONFIG_1;
wire [  4-1:0] core_config;



////////////////////////////////////////
// toplevel assignments               //
////////////////////////////////////////

// SDRAM
assign SDRAM_CKE        = 1'b1;
assign SDRAM_CLK        = clk_sdram;
assign SDRAM_nCS        = sdram_cs[0];
assign SDRAM_DQML       = sdram_dqm[0];
assign SDRAM_DQMH       = sdram_dqm[1];
assign SDRAM_BA         = sdram_ba;

// clock
assign pll_in_clk       = CLOCK_27[0];

// reset
assign pll_rst          = 1'b0;
assign sdctl_rst        = pll_locked;

// mist
always @ (posedge clk_28) begin
  CORE_CONFIG_0   <= #1 CORE_CONFIG;
  CORE_CONFIG_1   <= #1 CORE_CONFIG_0;
  JOYA_0          <= #1 JOYA;
  JOYB_0          <= #1 JOYB;
  JOYA_1          <= #1 JOYA_0;
  JOYB_1          <= #1 JOYB_0;
  MOUSE_BUTTONS_0 <= #1 MOUSE_BUTTONS;
  MOUSE_BUTTONS_1 <= #1 MOUSE_BUTTONS_0;
end

assign core_config      = CORE_CONFIG_1;
assign joya             = JOYA_1;
assign joyb             = JOYB_1;
assign mouse_buttons    = MOUSE_BUTTONS_1;

// minimig
assign _15khz           = ~core_config[0];
assign joy_emu_en       = 1'b1;

assign LED              = ~led;

// VGA data
always @ (posedge clk_28) begin
  vs_reg    <= #1 vs;
  hs_reg    <= #1 hs;
  red_reg   <= #1 red[7:2];
  green_reg <= #1 green[7:2];
  blue_reg  <= #1 blue[7:2];
end

assign VGA_VS           = vs_reg;
assign VGA_HS           = hs_reg;
assign VGA_R[5:0]       = red_reg[5:0];
assign VGA_G[5:0]       = green_reg[5:0];
assign VGA_B[5:0]       = blue_reg[5:0];


//// amiga clocks ////
amiga_clk amiga_clk (
  .rst          (pll_rst          ), // async reset input
  .clk_in       (pll_in_clk       ), // input clock     ( 27.000000MHz)
  .clk_114      (clk_114          ), // output clock c0 (114.750000MHz)
  .clk_sdram    (clk_sdram        ), // output clock c2 (114.750000MHz, -146.25 deg)
  .clk_28       (clk_28           ), // output clock c1 ( 28.687500MHz)
  .clk_7        (clk_7            ), // output clock 7  (  7.171875MHz)
  .clk7_en      (clk7_en          ), // output clock 7 enable (on 28MHz clock domain)
  .clk7n_en     (clk7n_en         ), // 7MHz negedge output clock enable (on 28MHz clock domain)
  .c1           (c1               ), // clk28m clock domain signal synchronous with clk signal
  .c3           (c3               ), // clk28m clock domain signal synchronous with clk signal delayed by 90 degrees
  .cck          (cck              ), // colour clock output (3.54 MHz)
  .eclk         (eclk             ), // 0.709379 MHz clock enable output (clk domain pulse)
  .locked       (pll_locked       )  // pll locked output
);


//// TG68K main CPU ////
`ifdef MINIMIG_MIST_NEWCPU
TG68K_SplitClock tg68k (
  .clk          (clk_114          ),
  .clk28        (clk_28           ),
  .reset        (tg68_rst         ),
  .IPL          (tg68_IPL         ),
  .dtack        (tg68_dtack       ),
//  .vpa          (1'b1             ),
//  .ein          (1'b1             ),
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
  .toram      (tg68_cin        ),
  .ramready     (tg68_cpuena      ),
  .cache_valid(cache_valid),
  .cacheable(tg68_cacheable),
  .cpu          (cpu_config[1:0]  ),
  .turbochipram (memcfg[5]&memcfg[4]&turbochipram/*1'b0*//*turbochipram*/     ),
  .fastramcfg   ({memcfg[5]&memcfg[4],memcfg[5:4]}),
  .ramaddr      (tg68_cad         ),
  .cpustate     (tg68_cpustate    ),
  .nResetOut    (tg68_nrst_out    ),
  .skipFetch    (                 ),
  .ramlds       (tg68_clds        ),
  .ramuds       (tg68_cuds        ),
  .VBR_out      (tg68_VBR_out     )
);

`else

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
  .cpu          (cpu_config[1:0]  ),
  .turbochipram (turbochipram     ),
  .turbokick    (turbokick        ),
  .cache_inhibit(cache_inhibit    ),
  .fastramcfg   ({&memcfg[5:4],memcfg[5:4]}),
  .eth_en       (1'b1), // TODO
  .sel_eth      (),
  .frometh      (16'd0),
  .ethready     (1'b0),
  .ovr          (tg68_ovr         ),
  .ramaddr      (tg68_cad         ),
  .cpustate     (tg68_cpustate    ),
  .nResetOut    (tg68_nrst_out    ),
  .skipFetch    (                 ),
  .cpuDMA       (tg68_cdma        ),
  .ramlds       (tg68_clds        ),
  .ramuds       (tg68_cuds        ),
  .CACR_out     (tg68_CACR_out    ),
  .VBR_out      (tg68_VBR_out     )
);

`endif

/*
//// TG68 main CPU ////
TG68 tg68 (
  .clk          (clk_114          ),
  .reset        (tg68_rst         ),
  .clkena_in    (1'b1             ),
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
*/


//// sdram ////
/*
sdram_ctrl sdram (
  // sys
  .sysclk       (clk_114          ),
  .c_7m         (clk_7            ),
  .reset_in     (sdctl_rst        ),
  .cache_rst    (tg68_rst         ),
  .reset_out    (reset_out        ),
  .cache_ena    (cpu_config[2]    ),
  // sdram
  .sdaddr       (SDRAM_A[12:0]    ),
  .sd_cs        (sdram_cs         ),
  .ba           (sdram_ba         ),
  .sd_we        (SDRAM_nWE        ),
  .sd_ras       (SDRAM_nRAS       ),
  .sd_cas       (SDRAM_nCAS       ),
  .dqm          (sdram_dqm        ),
  .sdata        (SDRAM_DQ         ),
  // host
  .host_cs      (1'b0             ),
  .host_adr     (22'hxxxxxx       ),
  .host_we      (1'b0             ),
  .host_bs      (2'bxx            ),
  .host_wdat    (16'hxxxx         ),
  .host_rdat    (                 ),
  .host_ack     (                 ),
  // chip
  .chipAddr     ({2'b00, ram_address[21:1]}),
  .chipL        (_ram_ble         ),
  .chipU        (_ram_bhe         ),
  .chipRW       (_ram_we          ),
  .chip_dma     (_ram_oe          ),
  .chipWR       (ram_data         ),
  .chipRD       (ramdata_in       ),
  .chip48       (chip48           ),
  // cpu
  .cpuAddr      (tg68_cad[24:1]   ),
  .cpustate     (tg68_cpustate    ),
  .cpuL         (tg68_clds        ),
  .cpuU         (tg68_cuds        ),
  .cpu_dma      (tg68_cdma        ),
  .cpuWR        (tg68_dat_out     ),
  .cpuRD        (tg68_cout        ),
  .enaWRreg     (tg68_enaWR       ),
  .ena7RDreg    (tg68_ena7RD      ),
  .ena7WRreg    (tg68_ena7WR      ),
  .cpuena       (tg68_cpuena      )
);
*/

//sdram sdram (
sdram_ctrl sdram (
  .cache_rst    (tg68_rst         ),
  .cache_inhibit(cache_inhibit    ),
  .cpu_cache_ctrl (tg68_CACR_out    ),
  .sdata        (SDRAM_DQ         ),
  .sdaddr       (SDRAM_A[12:0]    ),
  .dqm          (sdram_dqm        ),
  .sd_cs        (sdram_cs         ),
  .ba           (sdram_ba         ),
  .sd_we        (SDRAM_nWE        ),
  .sd_ras       (SDRAM_nRAS       ),
  .sd_cas       (SDRAM_nCAS       ),
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
  .chip48       (chip48           ),
  .reset_out    (reset_out        ),
  .enaRDreg     (                 ),
  .enaWRreg     (tg68_enaWR       ),
  .ena7RDreg    (tg68_ena7RD      ),
  .ena7WRreg    (tg68_ena7WR      )
);


// multiplex spi_do, drive it from user_io if that's selected, drive
// it from minimig if it's selected and leave it open else (also
// to be able to monitor sd card data directly)
assign SPI_DO = (CONF_DATA0 == 1'b0)?user_io_sdo:
    (((SPI_SS2 == 1'b0)|| (SPI_SS3 == 1'b0))?minimig_sdo:1'bZ);


//// user io has an extra spi channel outside minimig core ////
user_io user_io(
     .SPI_CLK(SPI_SCK),
     .SPI_SS_IO(CONF_DATA0),
     .SPI_MISO(user_io_sdo),
     .SPI_MOSI(SPI_DI),
     .JOY0(JOYA),
     .JOY1(JOYB),
     .MOUSE_BUTTONS(MOUSE_BUTTONS),
     .KBD_MOUSE_DATA(kbd_mouse_data),
     .KBD_MOUSE_TYPE(kbd_mouse_type),
     .KBD_MOUSE_STROBE(kbd_mouse_strobe),
     .KMS_LEVEL(kms_level),
     .CORE_TYPE(8'ha5),    // minimig core id (a1 - old minimig id, a5 - new aga minimig id)
     .CONF(CORE_CONFIG)
  );


//// minimig top ////
minimig minimig (
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
  ._cpu_reset_in(tg68_nrst_out    ), // M68K reset out
  .cpu_vbr      (tg68_VBR_out     ), // M68K VBR
  .ovr          (tg68_ovr         ), // NMI override address decoding
  //sram pins
  .ram_data     (ram_data         ), // SRAM data bus
  .ramdata_in   (ramdata_in       ), // SRAM data bus in
  .ram_address  (ram_address[21:1]), // SRAM address bus
  ._ram_bhe     (_ram_bhe         ), // SRAM upper byte select
  ._ram_ble     (_ram_ble         ), // SRAM lower byte select
  ._ram_we      (_ram_we          ), // SRAM write enable
  ._ram_oe      (_ram_oe          ), // SRAM output enable
  .chip48       (chip48           ), // big chipram read
  //system  pins
  .rst_ext      (rst_minimig      ), // reset from ctrl block
  .rst_out      (                 ), // minimig reset status
  .clk          (clk_28           ), // output clock c1 ( 28.687500MHz)
  .clk7_en      (clk7_en          ), // 7MHz clock enable
  .clk7n_en     (clk7n_en         ), // 7MHz negedge clock enable
  .c1           (c1               ), // clk28m clock domain signal synchronous with clk signal
  .c3           (c3               ), // clk28m clock domain signal synchronous with clk signal delayed by 90 degrees
  .cck          (cck              ), // colour clock output (3.54 MHz)
  .eclk         (eclk             ), // 0.709379 MHz clock enable output (clk domain pulse)
  //rs232 pins
  .rxd          (UART_RX          ),  // RS232 receive
  .txd          (UART_TX          ),  // RS232 send
  .cts          (1'b0             ),  // RS232 clear to send
  .rts          (                 ),  // RS232 request to send
  //I/O
  ._joy1        (~joya            ),  // joystick 1 [fire4,fire3,fire2,fire,up,down,left,right] (default mouse port)
  ._joy2        (~joyb            ),  // joystick 2 [fire4,fire3,fire2,fire,up,down,left,right] (default joystick port)
  .mouse_btn1   (1'b1             ), // mouse button 1
  .mouse_btn2   (1'b1             ), // mouse button 2
  .mouse_btn    (mouse_buttons    ),  // mouse buttons
  .kbd_mouse_data (kbd_mouse_data ),  // mouse direction data, keycodes
  .kbd_mouse_type (kbd_mouse_type ),  // type of data
  .kbd_mouse_strobe (kbd_mouse_strobe), // kbd/mouse data strobe
  .kms_level    (kms_level        ),
  ._15khz       (_15khz           ),  // scandoubler disable
  .pwrled       (led              ),  // power led
  .msdat        (                 ),  // PS2 mouse data
  .msclk        (                 ),  // PS2 mouse clk
  .kbddat       (                 ),  // PS2 keyboard data
  .kbdclk       (                 ),  // PS2 keyboard clk
  //host controller interface (SPI)
  ._scs         ( {SPI_SS4,SPI_SS3,SPI_SS2}  ),  // SPI chip select
  .direct_sdi   (SPI_DO           ),  // SD Card direct in  SPI_SDO
  .sdi          (SPI_DI           ),  // SPI data input
  .sdo          (minimig_sdo      ),  // SPI data output
  .sck          (SPI_SCK          ),  // SPI clock
  //video
  ._hsync       (hs               ),  // horizontal sync
  ._vsync       (vs               ),  // vertical sync
  .red          (red              ),  // red
  .green        (green            ),  // green
  .blue         (blue             ),  // blue
  //audio
  .left         (AUDIO_L          ),  // audio bitstream left
  .right        (AUDIO_R          ),  // audio bitstream right
  .ldata        (                 ),  // left DAC data
  .rdata        (                 ),  // right DAC data
  //user i/o
  .cpu_config   (cpu_config       ), // CPU config
  .memcfg       (memcfg           ), // memory config
  .turbochipram (turbochipram     ), // turbo chipRAM
  .turbokick    (turbokick        ), // turbo kickstart
  .init_b       (                 ), // vertical sync for MCU (sync OSD update)
  .fifo_full    (                 ),
  // fifo / track display
  .trackdisp    (                 ),  // floppy track number
  .secdisp      (                 ),  // sector
  .floppy_fwr   (                 ),  // floppy fifo writing
  .floppy_frd   (                 ),  // floppy fifo reading
  .hd_fwr       (                 ),  // hd fifo writing
  .hd_frd       (                 )   // hd fifo  ading
);


endmodule

