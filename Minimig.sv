/********************************************/
/* minimig.sv                               */
/* MiSTer version                           */
/*                                          */
/* 2017,2018 Sorgelig                       */
/********************************************/


module emu
(
   //Master input clock
   input         CLK_50M,
	
	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

   //Used as clock for IO_* signals in top module
   output        CLK_SYS,
	input         CLK_100,
	
   //Base video clock. Usually equals to CLK_SYS.
   output        CLK_VIDEO,

   //Multiple resolutions are supported using different CE_PIXEL rates.
   //Must be based on CLK_VIDEO
   output        CE_PIXEL,

	output  [1:0] SCANLINE,

   //Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
   output  [7:0] VIDEO_ARX,
   output  [7:0] VIDEO_ARY,

   output  [7:0] VGA_R,
   output  [7:0] VGA_G,
   output  [7:0] VGA_B,
   output        VGA_HS,
   output        VGA_VS,
   output        VGA_CS,
	output        VGA_F1,
	
	//NOTE: Scaler measures the frame width by first line.
	//So, make sure DE is stable during the first active line!
   output        VGA_DE,    // = ~(VBlank | HBlank)

   output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status ORed with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	input         BTN_USER,

   output [15:0] AUDIO_L,
   output [15:0] AUDIO_R,
   output        AUDIO_S, // 1 - signed audio samples, 0 - unsigned
   input         TAPE_IN,

   input         IO_UIO,
   input         IO_FPGA,
   input         IO_OSD,
   input         IO_STROBE,
   output        IO_WAIT,
   input  [15:0] IO_DIN,
   output [15:0] IO_DOUT,

	//High latency DDR3 RAM interface
	//Use for non-critical time purposes
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,

	//SDRAM interface with lower latency
   output        SDRAM_CLK,
   output        SDRAM_CKE,
   output [12:0] SDRAM_A,
   output  [1:0] SDRAM_BA,
   inout  [15:0] SDRAM_DQ,
   output        SDRAM_DQML,
   output        SDRAM_DQMH,
   output        SDRAM_nCS,
   output        SDRAM_nCAS,
   output        SDRAM_nRAS,
   output        SDRAM_nWE
);

assign {DDRAM_CLK, DDRAM_BURSTCNT, DDRAM_ADDR, DDRAM_DIN, DDRAM_BE, DDRAM_RD, DDRAM_WE} = 0;


////////////////////////////////////////
// internal signals                   //
////////////////////////////////////////

// clock
wire           clk_114;
wire           clk_28;
wire           pll_locked;
wire           clk_7;
wire           clk7_en;
wire           clk7n_en;
wire           c1;
wire           c3;
wire           cck;
wire [ 10-1:0] eclk;

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
wire [ 16-1:0] ram_data;      // sram data bus
wire [ 16-1:0] ramdata_in;    // sram data bus in
wire [ 48-1:0] chip48;        // big chip read
wire [ 22-1:1] ram_address;   // sram address bus
wire           _ram_bhe;      // sram upper byte select
wire           _ram_ble;      // sram lower byte select
wire           _ram_we;       // sram write enable
wire           _ram_oe;       // sram output enable
wire [ 15-1:0] ldata;         // left DAC data
wire [ 15-1:0] rdata;         // right DAC data
wire           vs;
wire           hs;
wire     [1:0] ar;

// mist
wire [   15:0] joya;
wire [   15:0] joyb;
wire [  8-1:0] kbd_mouse_data;
wire           kbd_mouse_strobe;
wire           kms_level;
wire [  2-1:0] kbd_mouse_type;
wire [  3-1:0] mouse_buttons;
wire [  4-1:0] core_config;
wire [   63:0] rtc;


////////////////////////////////////////
// toplevel assignments               //
////////////////////////////////////////

// SDRAM
assign SDRAM_CKE    = 1;

// AUDIO
assign AUDIO_L      = {ldata, 1'b0};
assign AUDIO_R      = {rdata, 1'b0};
assign AUDIO_S      = 1;

assign LED_POWER[1] = 1;
assign LED_DISK[1]  = 1;

assign VGA_HS       = ~hs;
assign VGA_VS       = ~vs;
assign VIDEO_ARX    = ar[0] ? 8'd16 : 8'd4;
assign VIDEO_ARY    = ar[0] ? 8'd9  : 8'd3;
assign CLK_VIDEO    = clk_28;
assign CE_PIXEL     = 1;

wire   IO_WAIT_UIO;
wire   IO_WAIT_MM;
assign IO_WAIT      = IO_WAIT_UIO | IO_WAIT_MM;

assign CLK_SYS      = clk_28;

//// amiga clocks ////
amiga_clk amiga_clk (
  .rst          (0                ), // async reset input
  .clk_in       (CLK_50M          ), // input clock     ( 50.000000MHz)
  .clk_114      (clk_114          ), // output clock c0 (114.750000MHz)
  .clk_sdram    (SDRAM_CLK        ), // output clock c2 (114.750000MHz, -146.25 deg)
  .clk_28       (clk_28           ), // output clock c1 ( 28.687500MHz)
  .clk_7        (clk_7            ), // output clock 7  (  7.171875MHz) DO NOT USE IT AS A CLOCK!
  .clk7_en      (clk7_en          ), // output clock 7 enable (on 28MHz clock domain)
  .clk7n_en     (clk7n_en         ), // 7MHz negedge output clock enable (on 28MHz clock domain)
  .c1           (c1               ), // clk28m clock domain signal synchronous with clk signal
  .c3           (c3               ), // clk28m clock domain signal synchronous with clk signal delayed by 90 degrees
  .cck          (cck              ), // colour clock output (3.54 MHz)
  .eclk         (eclk             ), // 0.709379 MHz clock enable output (clk domain pulse)
  .locked       (pll_locked       )  // pll locked output
);


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
  .eth_en       (1'b1             ), // TODO
  .sel_eth      (                 ),
  .frometh      (16'd0            ),
  .ethready     (1'b0             ),
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

sdram_ctrl sdram (
  .cache_rst    (tg68_rst         ),
  .cache_inhibit(cache_inhibit    ),
  .cpu_cache_ctrl (tg68_CACR_out  ),
  .sdata        (SDRAM_DQ         ),
  .sdaddr       (SDRAM_A[12:0]    ),
  .dqm          ({SDRAM_DQMH, SDRAM_DQML}),
  .sd_cs        (SDRAM_nCS        ),
  .ba           (SDRAM_BA         ),
  .sd_we        (SDRAM_nWE        ),
  .sd_ras       (SDRAM_nRAS       ),
  .sd_cas       (SDRAM_nCAS       ),
  .sysclk       (clk_114          ),
  .reset_in     (pll_locked       ),
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
  .reset_out    (                 ),
  .enaRDreg     (                 ),
  .enaWRreg     (tg68_enaWR       ),
  .ena7RDreg    (tg68_ena7RD      ),
  .ena7WRreg    (tg68_ena7WR      )
);

assign IO_DOUT = IO_UIO ? uio_dout : fpga_dout;

wire [15:0] uio_dout;
wire [15:0] fpga_dout;
wire        ce_pix;

//// user io has an extra spi channel outside minimig core ////
user_io user_io
(
	.clk(clk_28),

	.IO_ENA(IO_UIO),
	.IO_STROBE(IO_STROBE),
	.IO_WAIT(IO_WAIT_UIO),
	.IO_DIN(IO_DIN),
	.IO_DOUT(uio_dout),

	.JOY0(joya),
	.JOY1(joyb),
	.MOUSE_BUTTONS(mouse_buttons),
	.KBD_MOUSE_DATA(kbd_mouse_data),
	.KBD_MOUSE_TYPE(kbd_mouse_type),
	.KBD_MOUSE_STROBE(kbd_mouse_strobe),
	.KMS_LEVEL(kms_level),
	.RTC(rtc),

	.clk_100(CLK_100),
	.clk_vid(CLK_VIDEO),
	.ce_pix(ce_pix),
	.de(VGA_DE),
	.hs(~hs),
	.vs(~vs),
	.f1(VGA_F1)
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
  .rst_ext      (BTN_USER         ), // reset from ctrl block
  .rst_out      (                 ), // minimig reset status
  .clk          (clk_28           ), // output clock c1 ( 28.687500MHz)
  .clk7_en      (clk7_en          ), // 7MHz clock enable
  .clk7n_en     (clk7n_en         ), // 7MHz negedge clock enable
  .c1           (c1               ), // clk28m clock domain signal synchronous with clk signal
  .c3           (c3               ), // clk28m clock domain signal synchronous with clk signal delayed by 90 degrees
  .cck          (cck              ), // colour clock output (3.54 MHz)
  .eclk         (eclk             ), // 0.709379 MHz clock enable output (clk domain pulse)
  //rs232 pins
  .rxd          (0                ), // RS232 receive
  .txd          (                 ), // RS232 send
  .cts          (1'b0             ), // RS232 clear to send
  .rts          (                 ), // RS232 request to send
  //I/O
  ._joy1        (~joya            ), // joystick 1 [fire4,fire3,fire2,fire,up,down,left,right] (default mouse port)
  ._joy2        (~joyb            ), // joystick 2 [fire4,fire3,fire2,fire,up,down,left,right] (default joystick port)
  .mouse_btn1   (1'b1             ), // mouse button 1
  .mouse_btn2   (1'b1             ), // mouse button 2
  .mouse_btn    (mouse_buttons    ), // mouse buttons
  .kbd_mouse_data (kbd_mouse_data ), // mouse direction data, keycodes
  .kbd_mouse_type (kbd_mouse_type ), // type of data
  .kbd_mouse_strobe (kbd_mouse_strobe), // kbd/mouse data strobe
  .kms_level    (kms_level        ),
  .pwr_led      (LED_POWER[0]     ), // power led
  .fdd_led      (LED_USER         ),
  .hdd_led      (LED_DISK[0]      ),
  .msdat        (                 ), // PS2 mouse data
  .msclk        (                 ), // PS2 mouse clk
  .kbddat       (                 ), // PS2 keyboard data
  .kbdclk       (                 ), // PS2 keyboard clk
  .rtc          (rtc              ),
  //host controller interface (SPI)
  .IO_OSD       (IO_OSD           ),
  .IO_FPGA      (IO_FPGA          ),
  .IO_STROBE    (IO_STROBE        ),
  .IO_WAIT      (IO_WAIT_MM       ),
  .IO_DIN       (IO_DIN           ),
  .IO_DOUT      (fpga_dout        ),
  //video
  ._hsync       (hs               ), // horizontal sync
  ._vsync       (vs               ), // vertical sync
  ._csync       (VGA_CS           ),
  .field1       (VGA_F1           ),
  .red          (VGA_R            ), // red
  .green        (VGA_G            ), // green
  .blue         (VGA_B            ), // blue
  .de           (VGA_DE           ),
  .ar           (ar               ),
  .scanline     (SCANLINE         ),
  .ce_pix       (ce_pix           ),
  //audio
  .left         (                 ), // audio bitstream left
  .right        (                 ), // audio bitstream right
  .ldata        (ldata            ), // left DAC data
  .rdata        (rdata            ), // right DAC data
  //user i/o
  .cpu_config   (cpu_config       ), // CPU config
  .memcfg       (memcfg           ), // memory config
  .turbochipram (turbochipram     ), // turbo chipRAM
  .turbokick    (turbokick        ), // turbo kickstart
  .init_b       (                 ), // vertical sync for MCU (sync OSD update)

  .trackdisp    (                 ), // floppy track number
  .secdisp      (                 ), // sector
  .floppy_fwr   (                 ), // floppy fifo writing
  .floppy_frd   (                 ), // floppy fifo reading
  .hd_fwr       (                 ), // hd fifo writing
  .hd_frd       (                 )  // hd fifo  ading
);


endmodule
