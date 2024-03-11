/********************************************/
/* minimig.sv                               */
/* MiSTer glue logic                        */
/* 2017-2020 Alexey Melnikov                */
/********************************************/

module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [48:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	//if VIDEO_ARX[12] or VIDEO_ARY[12] is set then [11:0] contains scaled size instead of aspect ratio.
	output [12:0] VIDEO_ARX,
	output [12:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,
	output        VGA_SCALER, // Force VGA scaler
	output        VGA_DISABLE, // analog out is off

	input  [11:0] HDMI_WIDTH,
	input  [11:0] HDMI_HEIGHT,
	output        HDMI_FREEZE,

`ifdef MISTER_FB
	// Use framebuffer in DDRAM
	// FB_FORMAT:
	//    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
	//    [3]   : 0=16bits 565 1=16bits 1555
	//    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
	//
	// FB_STRIDE either 0 (rounded to 256 bytes) or multiple of pixel size (in bytes)
	output        FB_EN,
	output  [4:0] FB_FORMAT,
	output [11:0] FB_WIDTH,
	output [11:0] FB_HEIGHT,
	output [31:0] FB_BASE,
	output [13:0] FB_STRIDE,
	input         FB_VBL,
	input         FB_LL,
	output        FB_FORCE_BLANK,

`ifdef MISTER_FB_PALETTE
	// Palette control for 8bit modes.
	// Ignored for other video modes.
	output        FB_PAL_CLK,
	output  [7:0] FB_PAL_ADDR,
	output [23:0] FB_PAL_DOUT,
	input  [23:0] FB_PAL_DIN,
	output        FB_PAL_WR,
`endif
`endif

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	// I/O board button press simulation (active high)
	// b[1]: user button
	// b[0]: osd button
	output  [1:0] BUTTONS,

	input         CLK_AUDIO, // 24.576 MHz
	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned
	output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

	//ADC
	inout   [3:0] ADC_BUS,

	//SD-SPI
	output        SD_SCK,
	output        SD_MOSI,
	input         SD_MISO,
	output        SD_CS,
	input         SD_CD,

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
	output        SDRAM_nWE,

`ifdef MISTER_DUAL_SDRAM
	//Secondary SDRAM
	//Set all output SDRAM_* signals to Z ASAP if SDRAM2_EN is 0
	input         SDRAM2_EN,
	output        SDRAM2_CLK,
	output [12:0] SDRAM2_A,
	output  [1:0] SDRAM2_BA,
	inout  [15:0] SDRAM2_DQ,
	output        SDRAM2_nCS,
	output        SDRAM2_nCAS,
	output        SDRAM2_nRAS,
	output        SDRAM2_nWE,
`endif

	input         UART_CTS,
	output        UART_RTS,
	input         UART_RXD,
	output        UART_TXD,
	output        UART_DTR,
	input         UART_DSR,

	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..6 - USR2..USR6
	// Set USER_OUT to 1 to read from USER_IN.
	input   [6:0] USER_IN,
	output  [6:0] USER_OUT,

	input         OSD_STATUS
);

assign ADC_BUS  = 'Z;
assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;
assign BUTTONS = 0;
assign VGA_DISABLE = 0;
assign HDMI_FREEZE = 0;

`include "build_id.v" 
localparam CONF_STR = {
	"Minimig;UART115200,MIDI;",
	"J,Red(Fire),Blue,Yellow,Green,RT,LT,Pause;",
	"jn,A,B,X,Y,R,L,Start;",
	"jp,B,A,X,Y,R,L,Start;",
	"-   ;",
	"I,",
	"MT32-pi: SoundFont #0,",
	"MT32-pi: SoundFont #1,",
	"MT32-pi: SoundFont #2,",
	"MT32-pi: SoundFont #3,",
	"MT32-pi: SoundFont #4,",
	"MT32-pi: SoundFont #5,",
	"MT32-pi: SoundFont #6,",
	"MT32-pi: SoundFont #7,",
	"MT32-pi: MT-32 v1,",
	"MT32-pi: MT-32 v2,",
	"MT32-pi: CM-32L,",
	"MT32-pi: Unknown mode;",
	"V,v",`BUILD_DATE
};

wire [15:0] JOY0;
wire [15:0] JOY1;
wire [15:0] JOY2;
wire [15:0] JOY3;
wire [15:0] JOYA0;
wire [15:0] JOYA1;
wire  [7:0] kbd_mouse_data;
wire        kbd_mouse_level;
wire  [1:0] kbd_mouse_type;
wire  [2:0] mouse_buttons;
wire [64:0] RTC;

wire        ce_pix;
wire  [1:0] buttons;
wire [63:0] status;
wire        forced_scandoubler;

wire        io_strobe;
wire        io_wait;
wire        io_fpga;
wire        io_uio;
wire [15:0] io_din;
wire [15:0] fpga_dout;

wire [21:0] gamma_bus;

wire  [7:0] uart_mode;

hps_io #(.CONF_STR(CONF_STR), .CONF_STR_BRAM(0)) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS({HPS_BUS[48:42],ce_pix,HPS_BUS[40:0]}),

	.status(status),
	.status_menumask({mt32_cfg,mt32_available}),
	.info_req(mt32_info_req),
	.info(mt32_info_disp),

	.joystick_0(JOY0),
	.joystick_1(JOY1),
	.joystick_2(JOY2),
	.joystick_3(JOY3),
	.joystick_l_analog_0(JOYA0),
	.joystick_l_analog_1(JOYA1),
	
	.ioctl_wait(io_wait),

	.buttons(buttons),
	.forced_scandoubler(forced_scandoubler),

	.uart_mode(uart_mode),

	.RTC(RTC),
	.gamma_bus(gamma_bus),

	.EXT_BUS(EXT_BUS)
);

wire [15:0] ide_din;
wire [15:0] ide_dout;
wire  [4:0] ide_addr;
wire        ide_rd;
wire        ide_wr;
wire  [5:0] ide_req;

wire [35:0] EXT_BUS;
hps_ext hps_ext(.*, .ide_req(ide_fast ? ide_f_req : ide_c_req),  .ide_din(ide_fast ? ide_f_readdata : ide_c_readdata));

assign LED_POWER[1] = 1;
assign LED_DISK     = {1'b0, ide_fast ? ide_f_led : ide_c_led};

assign VGA_SCALER   = FB_EN;

wire clk_57, clk_114;
wire clk_sys;
wire locked;

pll pll
(
	.refclk(CLK_50M),
	.outclk_0(clk_114),
	.outclk_1(clk_sys),
	.locked(locked)
);

wire reset = ~locked | buttons[1] | RESET;

reg reset_d;
always @(posedge clk_sys, posedge reset) begin
	reg [7:0] reset_s;
	reg rs;
	
	if(reset) reset_s <= '1;
	else begin
		reset_s <= reset_s << 1;
		rs <= reset_s[7];
		reset_d <= rs;
	end
end

//// amiga clocks ////
wire       clk7_en;
wire       clk7n_en;
wire       c1;
wire       c3;
wire       cck;
wire [9:0] eclk;

amiga_clk amiga_clk
(
	.clk_28   ( clk_sys    ), // input  clock c1 ( 28.687500MHz)
	.clk7_en  ( clk7_en    ), // output clock 7 enable (on 28MHz clock domain)
	.clk7n_en ( clk7n_en   ), // 7MHz negedge output clock enable (on 28MHz clock domain)
	.c1       ( c1         ), // clk28m clock domain signal synchronous with clk signal
	.c3       ( c3         ), // clk28m clock domain signal synchronous with clk signal delayed by 90 degrees
	.cck      ( cck        ), // colour clock output (3.54 MHz)
	.eclk     ( eclk       ), // 0.709379 MHz clock enable output (clk domain pulse)
	.reset_n  ( ~reset     )
);


wire cpu_type = cpucfg[1];
reg  cpu_ph1;
reg  cpu_ph2;
reg  ram_cs;
reg  cyc;

always @(posedge clk_114) begin
	reg [3:0] div;
	reg       c1d;

	div <= div + 1'd1;
	 
	c1d <= c1;
	if (~c1d & c1) div <= 3;
	
	if (~cpu_rst) begin
		cyc <= 0;
		cpu_ph1 <= 0;
		cpu_ph2 <= 0;
	end
	else begin
		cyc <= !div[1:0];
		if (div[1] & ~div[0]) begin
			cpu_ph1 <= 0;
			cpu_ph2 <= 0;
			case (div[3:2])
				0: cpu_ph2 <= 1;
				2: cpu_ph1 <= 1;
			endcase
		end
	end

	ram_cs <= ~(ram_ready & cyc & cpu_type) & ram_sel;
end

wire  [1:0] cpu_state;
wire        cpu_nrst_out;
wire  [3:0] cpu_cacr;
wire [31:0] cpu_nmi_addr;
wire        cpu_rst;

wire  [2:0] chip_ipl;
wire        chip_dtack;
wire        chip_as;
wire        chip_uds;
wire        chip_lds;
wire        chip_rw;
wire [15:0] chip_dout;
wire [15:0] chip_din;
wire [23:1] chip_addr;

wire [28:1] ram_addr;
wire        ram_sel;
wire        ram_lds;
wire        ram_uds;
wire [15:0] ram_din;
wire [15:0] ram_dout  = zram_sel ? ram_dout2  : ram_dout1;
wire        ram_ready = zram_sel ? ram_ready2 : ram_ready1;
wire        zram_sel  = |ram_addr[28:26];
wire        ramshared;

wire [7:0] toccata_base;
wire toccata_ena;

cpu_wrapper cpu_wrapper
(
	.reset        (cpu_rst         ),
	.reset_out    (cpu_nrst_out    ),

	.clk          (clk_sys         ),
	.ph1          (cpu_ph1         ),
	.ph2          (cpu_ph2         ),

	.chip_addr    (chip_addr       ),
	.chip_dout    (chip_dout       ),
	.chip_din     (chip_din        ),
	.chip_as      (chip_as         ),
	.chip_uds     (chip_uds        ),
	.chip_lds     (chip_lds        ),
	.chip_rw      (chip_rw         ),
	.chip_dtack   (chip_dtack      ),
	.chip_ipl     (chip_ipl        ),

	.fastchip_dout   (fastchip_dout   ),
	.fastchip_sel    (fastchip_sel    ),
	.fastchip_lds    (fastchip_lds    ),
	.fastchip_uds    (fastchip_uds    ),
	.fastchip_rnw    (fastchip_rnw    ),
	.fastchip_selack (fastchip_selack ),
	.fastchip_ready  (fastchip_ready  ),
	.fastchip_lw     (fastchip_lw     ),

	.cpucfg       (cpucfg          ),
	.cachecfg     (cachecfg        ),
	.fastramcfg   (memcfg[6:4]     ),
	.bootrom      (bootrom         ),

	.toccata_ena  (toccata_ena     ),
	.toccata_base (toccata_base    ),
	
	.ramsel       (ram_sel         ),
	.ramaddr      (ram_addr        ),
	.ramlds       (ram_lds         ),
	.ramuds       (ram_uds         ),
	.ramdout      (ram_dout        ),
	.ramdin       (ram_din         ),
	.ramready     (ram_ready       ),
	.ramshared    (ramshared       ),

	//custom CPU signals
	.cpustate     (cpu_state       ),
	.cacr         (cpu_cacr        ),
	.nmi_addr     (cpu_nmi_addr    )
);

wire [15:0] ram_dout1;
wire        ram_ready1;

sdram_ctrl ram1
(
	.sysclk       (clk_114         ),
	.reset_n      (~reset_d        ),
	.c_7m         (c1              ),

	.cache_rst    (cpu_rst         ),
	.cpu_cache_ctrl(cpu_cacr       ),

	.sd_data      (SDRAM_DQ        ),
	.sd_addr      (SDRAM_A         ),
	.sd_dqm       ({SDRAM_DQMH, SDRAM_DQML}),
	.sd_cs        (SDRAM_nCS       ),
	.sd_ba        (SDRAM_BA        ),
	.sd_we        (SDRAM_nWE       ),
	.sd_ras       (SDRAM_nRAS      ),
	.sd_cas       (SDRAM_nCAS      ),
	.sd_cke       (SDRAM_CKE       ),
	.sd_clk       (SDRAM_CLK       ),

	.cpuWR        (ram_din         ),
	.cpuAddr      (ram_addr[22:1]  ),
	.cpuU         (ram_uds         ),
	.cpuL         (ram_lds         ),
	.cpustate     (cpu_state       ),
	.cpuCS        (~zram_sel&ram_cs),
	.cpuRD        (ram_dout1       ),
	.ramready     (ram_ready1      ),

	.chipWR       (ram_data        ),
	.chipAddr     (ram_address     ),
	.chipU        (_ram_bhe        ),
	.chipL        (_ram_ble        ),
	.chipRW       (_ram_we         ),
	.chipDMA      (_ram_oe         ),
	.chipRD       (ramdata_in      ),
	.chip48       (chip48          )
);

wire [15:0] ram_dout2;
wire        ram_ready2;
wire  [7:0] DDRAM_BE_S;
   
ddram_ctrl ram2
(
	.sysclk       (clk_114         ),
	.reset_n      (~reset_d        ),

	.cache_rst    (cpu_rst         ),
	.cpu_cache_ctrl(cpu_cacr       ),

	.DDRAM_CLK    (DDRAM_CLK       ),
	.DDRAM_BUSY   (DDRAM_BUSY      ),
	.DDRAM_BURSTCNT(DDRAM_BURSTCNT ),
	.DDRAM_ADDR   (DDRAM_ADDR      ),
	.DDRAM_DOUT   (DDRAM_DOUT      ),
	.DDRAM_DOUT_READY(DDRAM_DOUT_READY),
	.DDRAM_RD     (DDRAM_RD        ),
	.DDRAM_DIN    (DDRAM_DIN       ),
	.DDRAM_BE     (DDRAM_BE        ),
	.DDRAM_WE     (DDRAM_WE        ),

	.cpuWR        (ram_din         ),
	.cpuAddr      (ram_addr        ),
	.cpuU         (ram_uds         ),
	.cpuL         (ram_lds         ),
	.cpustate     (cpu_state       ),
	.cpuCS        (zram_sel&ram_cs ),
	.cpuRD        (ram_dout2       ),
	.ramshared    (ramshared       ),
	.ramready     (ram_ready2      )
);

wire [15:0] fastchip_dout;
wire        fastchip_sel;
wire        fastchip_lds;
wire        fastchip_uds;
wire        fastchip_rnw;
wire        fastchip_selack;
wire        fastchip_ready;
wire        fastchip_lw;

wire        ide_fast;
wire        ide_f_led;
wire        ide_f_irq;
wire  [5:0] ide_f_req;
wire [15:0] ide_f_readdata;

// fastchip is working on CPU clock.
// Only high performance 68020 devices are inside
fastchip fastchip
(
	.clk          (clk_114           ),
	.cyc          (cyc               ),
	.clk_sys      (clk_sys           ),

	.reset        (~cpu_rst | ~cpu_nrst_out ),
	.sel          (fastchip_sel      ),
	.sel_ack      (fastchip_selack   ),
	.ready        (fastchip_ready    ),

	.addr         ({chip_addr,1'b0}  ),
	.din          (chip_din          ),
	.dout         (fastchip_dout     ),
	.lds          (~fastchip_lds     ),
	.uds          (~fastchip_uds     ),
	.rnw          (fastchip_rnw      ),
	.longword     (fastchip_lw       ),

	//RTG framebuffer control
	.rtg_ena      (FB_EN             ),
	.rtg_hsize    (FB_WIDTH          ),
	.rtg_vsize    (FB_HEIGHT         ),
	.rtg_format   (FB_FORMAT         ),
	.rtg_base     (FB_BASE           ),
	.rtg_stride   (FB_STRIDE         ),
	.rtg_pal_clk  (FB_PAL_CLK        ),
	.rtg_pal_dw   (FB_PAL_DOUT       ),
	.rtg_pal_dr   (FB_PAL_DIN        ),
	.rtg_pal_a    (FB_PAL_ADDR       ),
	.rtg_pal_wr   (FB_PAL_WR         ),

	.ide_ena      (ide_ena & ide_fast),
	.ide_irq      (ide_f_irq         ),
	.ide_req      (ide_f_req         ),
	.ide_address  (ide_addr          ),
	.ide_write    (ide_wr            ),
	.ide_writedata(ide_dout          ),
	.ide_read     (ide_rd            ),
	.ide_readdata (ide_f_readdata    ),
	.ide_led      (ide_f_led         )
);


////////////////////////////  UART  //////////////////////////////////// 

wire uart_cts, uart_dsr, uart_rts, uart_dtr;
wire uart_tx, uart_rx;

wire hps_mpu = (uart_mode >= 3);

assign UART_RTS = ~hps_mpu & uart_rts;
assign UART_DTR = ~hps_mpu & uart_dtr;
assign uart_cts = ~hps_mpu & UART_CTS;
assign uart_dsr = ~hps_mpu & UART_DSR;
assign uart_rx  = uart_mode ? UART_RXD : midi_rx;
assign UART_TXD = (hps_mpu & mt32_use) | uart_tx;

///////////////////////////////////////////////////////////////////////

//// minimig top ////
wire  [1:0] cpucfg;
wire  [2:0] cachecfg;
wire  [6:0] memcfg;
wire        bootrom;   
wire [15:0] ram_data;      // sram data bus
wire [15:0] ramdata_in;    // sram data bus in
wire [47:0] chip48;        // big chip read
wire [23:1] ram_address;   // sram address bus
wire        _ram_bhe;      // sram upper byte select
wire        _ram_ble;      // sram lower byte select
wire        _ram_we;       // sram write enable
wire        _ram_oe;       // sram output enable
wire [14:0] ldata;         // left DAC data
wire [14:0] rdata;         // right DAC data
wire [9:0]  ldata_okk;     // left DAC data  (PWM vol version)
wire [9:0]  rdata_okk;     // right DAC data (PWM vol version)
wire        vs;
wire        hs;
wire  [1:0] ar;

wire  [5:0] ide_c_req;
wire [15:0] ide_c_readdata;
wire        ide_c_led;
wire        ide_ena;

wire [15:0] toccata_aud_left;
wire [15:0] toccata_aud_right;

minimig minimig
(
	//m68k pins
	.cpu_address  (chip_addr        ), // M68K address bus
	.cpu_data     (chip_dout        ), // M68K data bus
	.cpudata_in   (chip_din         ), // M68K data in
	._cpu_ipl     (chip_ipl         ), // M68K interrupt request
	._cpu_as      (chip_as          ), // M68K address strobe
	._cpu_uds     (chip_uds         ), // M68K upper data strobe
	._cpu_lds     (chip_lds         ), // M68K lower data strobe
	.cpu_r_w      (chip_rw          ), // M68K read / write
	._cpu_dtack   (chip_dtack       ), // M68K data acknowledge
	._cpu_reset   (cpu_rst          ), // M68K reset
	._cpu_reset_in(cpu_nrst_out     ), // M68K reset out
	.nmi_addr     (cpu_nmi_addr     ), // M68K NMI address

	//sram pins
	.ram_data     (ram_data         ), // SRAM data bus
	.ramdata_in   (ramdata_in       ), // SRAM data bus in
	.ram_address  (ram_address      ), // SRAM address bus
	._ram_bhe     (_ram_bhe         ), // SRAM upper byte select
	._ram_ble     (_ram_ble         ), // SRAM lower byte select
	._ram_we      (_ram_we          ), // SRAM write enable
	._ram_oe      (_ram_oe          ), // SRAM output enable
	.chip48       (chip48           ), // big chipram read

	//system  pins
	.rst_ext      (reset_d          ), // reset from ctrl block
	.rst_out      (                 ), // minimig reset status
	.clk          (clk_sys          ), // output clock c1 ( 28.687500MHz)
	.clk7_en      (clk7_en          ), // 7MHz clock enable
	.clk7n_en     (clk7n_en         ), // 7MHz negedge clock enable
	.c1           (c1               ), // clk28m clock domain signal synchronous with clk signal
	.c3           (c3               ), // clk28m clock domain signal synchronous with clk signal delayed by 90 degrees
	.cck          (cck              ), // colour clock output (3.54 MHz)
	.eclk         (eclk             ), // 0.709379 MHz clock enable output (clk domain pulse)

	//rs232 pins
	.rxd          (uart_rx          ), // RS232 receive
	.txd          (uart_tx          ), // RS232 send
	.cts          (uart_cts         ), // RS232 clear to send
	.rts          (uart_rts         ), // RS232 request to send
	.dtr          (uart_dtr         ), // RS232 Data Terminal Ready
	.dsr          (uart_dsr         ), // RS232 Data Set Ready
	.cd           (uart_dsr         ), // RS232 Carrier Detect
	.ri           (1                ), // RS232 Ring Indicator

	//I/O
	._joy1        (~JOY0            ), // joystick 1 [fire4,fire3,fire2,fire,up,down,left,right] (default mouse port)
	._joy2        (~JOY1            ), // joystick 2 [fire4,fire3,fire2,fire,up,down,left,right] (default joystick port)
	._joy3        (~JOY2            ), // joystick 1 [fire4,fire3,fire2,fire,up,down,left,right]
	._joy4        (~JOY3            ), // joystick 2 [fire4,fire3,fire2,fire,up,down,left,right]
	.joya1        (JOYA0            ),
	.joya2        (JOYA1            ),
	.mouse_btn    (mouse_buttons    ), // mouse buttons
	.kbd_mouse_data (kbd_mouse_data ), // mouse direction data, keycodes
	.kbd_mouse_type (kbd_mouse_type ), // type of data
	.kms_level    (kbd_mouse_level  ),
	.pwr_led      (pwr_led          ), // power led
	.fdd_led      (LED_USER         ),
	.hdd_led      (ide_c_led        ),
	.rtc          (RTC              ),

	//host controller interface (SPI)
	.IO_UIO       (io_uio           ),
	.IO_FPGA      (io_fpga          ),
	.IO_STROBE    (io_strobe        ),
	.IO_WAIT      (io_wait          ),
	.IO_DIN       (io_din           ),
	.IO_DOUT      (fpga_dout        ),

	//video
	._hsync       (hs               ), // horizontal sync
	._vsync       (vs               ), // vertical sync
	.field1       (field1           ),
	.lace         (lace             ),
	.red          (r                ), // red
	.green        (g                ), // green
	.blue         (b                ), // blue
	.hblank       (hblank           ),
	.vblank       (vbl              ),
	.ar           (ar               ),
	.scanline     (fx               ),
	//.ce_pix     (ce_pix           ),
	.res          (res              ),

	//audio
	.ldata        (ldata            ), // left DAC data
	.rdata        (rdata            ), // right DAC data
	.ldata_okk    (ldata_okk        ), // 9bit
	.rdata_okk    (rdata_okk        ), // 9bit

	.aud_mix      (AUDIO_MIX        ),

	//toccata soundcard
	.toccata_ena  (toccata_ena),
	.toccata_base (toccata_base),
	.toccata_aud_left (toccata_aud_left),
	.toccata_aud_right(toccata_aud_right),
	
	//user i/o
	.cpucfg       (cpucfg           ), // CPU config
	.cachecfg     (cachecfg         ), // Cache config
	.memcfg       (memcfg           ), // memory config
	.bootrom      (bootrom          ), // bootrom mode. Needed here to tell tg68k to also mirror the 256k Kickstart 

	.ide_fast     (ide_fast         ),
	.ide_ext_irq  (ide_f_irq        ),
	.ide_ena      (ide_ena          ),
	.ide_req      (ide_c_req        ),
	.ide_address  (ide_addr         ),
	.ide_write    (ide_wr           ),
	.ide_writedata(ide_dout         ),
	.ide_read     (ide_rd           ),
	.ide_readdata (ide_c_readdata   )
);

// power led control
wire pwr_led;
reg [5:0] led_cnt;
reg led_dim;

always @ (posedge clk_sys) begin
  led_cnt <= led_cnt + 1'd1;
  led_dim <= |led_cnt[5:2];
end

assign LED_POWER[0] = pwr_led | ~led_dim;

assign FB_FORCE_BLANK = 0;

reg ce_out = 0;
always @(posedge CLK_VIDEO) begin
	reg [3:0] div;
	reg [3:0] add;
	reg [1:0] fs_res;
	reg old_vs;
	
	div <= div + add;
	if(~hblank & ~vblank) fs_res <= fs_res | res;

	old_vs <= vs;
	if(old_vs & ~vs) begin
		fs_res <= 0;
		div <= 0;
		add <= 1; // 7MHz
		if(fs_res[0]) add <= 2; // 14MHz
		if(fs_res[1] | (~status[42] & ~scandoubler)) add <= 4; // 28MHz
	end

	ce_out <= div[3] & !div[2:0];
end

assign ce_pix = ce_out;

wire [2:0] fx;
wire       scandoubler = (fx || forced_scandoubler) & ~lace;
wire [7:0] R,G,B;

video_mixer #(.LINE_LENGTH(2000), .HALF_DEPTH(0), .GAMMA(1)) video_mixer
(
	.*,
	.hq2x(fx==1),
	.ce_pix(ce_out),
	.freeze_sync(),

	.R(r),
	.G(g),
	.B(b),
	.HSync(~hs),
	.VSync(~vs),
	.HBlank(~hde),
	.VBlank(~vde),

	.VGA_R(R),
	.VGA_G(G),
	.VGA_B(B)
);

assign CLK_VIDEO = clk_114;
assign VGA_F1    = field1;
assign VGA_R     = mt32_lcd ? {{2{mt32_lcd_pix}},R[7:2]} : R;
assign VGA_G     = mt32_lcd ? {{2{mt32_lcd_pix}},G[7:2]} : G;
assign VGA_B     = mt32_lcd ? {{2{mt32_lcd_pix}},B[7:2]} : B;

wire [12:0] arx,ary;
video_freak video_freak
(
	.*,
	.VGA_DE_IN(VGA_DE),
	.VGA_DE(),
	.ARX((!ar) ? 12'd4 : (ar - 1'd1)),
	.ARY((!ar) ? 12'd3 : 12'd0),
	.VIDEO_ARX(arx),
	.VIDEO_ARY(ary),
	.CROP_SIZE(0),
	.CROP_OFF(0),
	.SCALE(status[45:43])
);

reg [11:0] fb_arx, fb_ary;
always @(posedge CLK_VIDEO) begin
	reg [11:0] x, y, x1, y1;
	reg [1:0] cnt;
	
	cnt <= cnt + 1'd1;
	case(cnt)
		0: begin
				x1 <= FB_WIDTH;
				y1 <= FB_HEIGHT;
				x  <= FB_WIDTH;
				y  <= FB_HEIGHT;
			end

		1: if(x && ((x+x1) <= HDMI_WIDTH) && y && ((y+y1) <= HDMI_HEIGHT)) begin
				x <= x+x1;
				y <= y+y1;
				cnt <= 1;
			end

		2: begin
				fb_arx <= x;
				fb_ary <= y;
			end
	endcase
end

assign VIDEO_ARX = FB_EN ? {status[46], fb_arx} : arx;
assign VIDEO_ARY = FB_EN ? {status[46], fb_ary} : ary;

wire [2:0] sl = fx ? fx - 1'd1 : 3'd0;
assign VGA_SL = sl[1:0];

reg  hde;
wire vde = ~(fvbl | svbl);

wire [7:0] red, green, blue, r,g,b;
wire lace, field1;
wire hblank, vbl;
wire vblank = vbl | ~vs;
reg  fhbl, fvbl, shbl, svbl;
wire hbl = fhbl | shbl | ~hs;

wire  [1:0] res;

wire sset;
wire [11:0] shbl_l, shbl_r;
wire [11:0] svbl_t, svbl_b;

reg  [11:0] hbl_l=0, hbl_r=0;
reg  [11:0] hsta, hend, hmax, hcnt;
reg  [11:0] hsize;
always @(posedge clk_sys) begin
	reg old_hs;
	reg old_hblank;

	old_hs <= hs;
	old_hblank <= hblank;

	hcnt <= hcnt + 1'd1;
	if(~hs) hcnt <= 0;

	if(old_hblank & ~hblank) hend <= hcnt;
	if(~old_hblank & hblank) hsta <= hcnt;
	if(old_hs & ~hs)         hmax <= hcnt;

	if(hcnt == hend+hbl_l-2'd2) shbl <= 0;
	if(hcnt == hsta+hbl_r-2'd2) shbl <= 1;

	//force hblank
	if(hcnt == 8)         fhbl <= 0;
	if(hcnt == hmax-4'd8) fhbl <= 1;
	
	if(~old_hblank & hblank & ~field1 & (vcnt == 1'd1)) hsize <= hcnt - hend;
end

reg [11:0] vbl_t=0, vbl_b=0;
reg [11:0] vend, vmax, f1_vend, f1_vsize, vcnt, vs_end;
reg [11:0] vsize;
always @(posedge clk_sys) begin
	reg old_vs;
	reg old_vblank, old_hs, old_hbl;

	old_vs <= vs;
	old_hs <= hs;
	old_vblank <= vblank;
	
	if(old_hs & ~hs) vcnt <= vcnt + 1'd1;
	if(~old_vblank & vblank) vcnt <= 0;

	if(~lace | ~field1) begin
		if(old_vblank & ~vblank) vend <= vcnt;
		if(~old_vs & vs)         vs_end <= vcnt;
		
		if(~old_vblank & vblank) begin
			vmax <= vcnt;
			vsize <= vcnt - vend + f1_vsize;
			f1_vsize <= 0;
		end
	end
	else begin
		if(old_vblank & ~vblank) f1_vend <= vcnt;
		if(~old_vblank & vblank) begin
			f1_vsize <= vcnt - f1_vend;
		end
	end

	old_hbl <= hbl;
	if((old_hbl & ~hbl) | !vcnt) begin
		if(vcnt == vend+vbl_t) svbl <= 0;
		if(vcnt == (vbl_b[11] ? vmax+vbl_b : vbl_b) ) svbl <= 1;

		//force vblank
		if(vcnt == vmax-1)    fvbl <= 1;
		if(vcnt == vs_end+2)  fvbl <= 0;
	end
	
	hde <= ~hbl;
end

always @(posedge clk_sys) begin
	reg old_level;
	reg alt = 0;

	old_level <= kbd_mouse_level;
	if((old_level ^ kbd_mouse_level) && (kbd_mouse_type==3)) begin
		if(kbd_mouse_data == 'h41) begin //backspace
			vbl_t <= 0; vbl_b <= 0;
			hbl_l <= 0; hbl_r <= 0;
		end
		else if(kbd_mouse_data == 'h4c) begin //up
			if(alt) vbl_b <= vbl_b + 1'd1;
			else    vbl_t <= vbl_t + 1'd1;
		end
		else if(kbd_mouse_data == 'h4d) begin //down
			if(alt) vbl_b <= vbl_b - 1'd1;
			else    vbl_t <= vbl_t - 1'd1;
		end
		else if(kbd_mouse_data == 'h4f) begin //left
			if(alt) hbl_r <= hbl_r + 3'd4;
			else    hbl_l <= hbl_l + 3'd4;
		end
		else if(kbd_mouse_data == 'h4e) begin //right
			if(alt) hbl_r <= hbl_r - 3'd4;
			else    hbl_l <= hbl_l - 3'd4;
		end
		else if(kbd_mouse_data == 'h64 || kbd_mouse_data == 'h65) begin //alt press
			alt <= 1;
		end
		else if(kbd_mouse_data == 'hE4 || kbd_mouse_data == 'hE5) begin //alt release
			alt <= 0;
		end
	end
	
	if(sset) begin
		vbl_t <= svbl_t; vbl_b <= svbl_b;
		hbl_l <= shbl_l; hbl_r <= shbl_r;
	end
end


reg [11:0] scr_hbl_l, scr_hbl_r;
reg [11:0] scr_vbl_t, scr_vbl_b;
reg [11:0] scr_hsize, scr_vsize;
reg  [1:0] scr_res;
reg  [6:0] scr_flg;

always @(posedge clk_sys) begin
	reg old_vblank;

	old_vblank <= vblank;
	if(old_vblank & ~vblank) begin
		scr_hbl_l <= hbl_l;
		scr_hbl_r <= hbl_r;
		scr_vbl_t <= vbl_t;
		scr_vbl_b <= vbl_b;
		scr_hsize <= hsize;
		scr_vsize <= vsize;
		scr_res   <= res;

		if(scr_res != res || scr_vsize != vsize || scr_hsize != hsize) scr_flg <= scr_flg + 1'd1;
	end
end

////////////////////////////  MT32pi  ////////////////////////////////// 

wire        mt32_reset    = status[32] | reset;
wire        mt32_disable  = status[33];
wire        mt32_mode_req = status[34];
wire  [1:0] mt32_rom_req  = status[36:35];
wire  [7:0] mt32_sf_req   = status[39:37];
wire  [1:0] mt32_info     = status[41:40];
wire        midi_tx       = uart_tx;

wire [15:0] mt32_i2s_r, mt32_i2s_l;
wire  [7:0] mt32_mode, mt32_rom, mt32_sf;
wire        mt32_lcd_en, mt32_lcd_pix, mt32_lcd_update;
wire        midi_rx;

wire mt32_newmode;
wire mt32_available;
wire mt32_use  = mt32_available & ~mt32_disable;
wire mt32_mute = mt32_available &  mt32_disable;

mt32pi mt32pi
(
	.*,
	.CE_PIXEL(ce_pix_mt32),
	.reset(mt32_reset),
	.midi_tx(midi_tx | mt32_mute)
);

wire  [4:0] mt32_cfg = (mt32_mode == 'hA2) ? {mt32_sf[2:0],  2'b10} :
                       (mt32_mode == 'hA1) ? {mt32_rom[1:0], 2'b01} : 5'd0;

reg mt32_info_req;
reg [3:0] mt32_info_disp;
always @(posedge clk_sys) begin
	reg old_mode;

	old_mode <= mt32_newmode;
	mt32_info_req <= (old_mode ^ mt32_newmode) && (mt32_info == 1);
	
	mt32_info_disp <= (mt32_mode == 'hA2) ? (4'd1 + mt32_sf[2:0]) :
                     (mt32_mode == 'hA1 && mt32_rom == 0) ?  4'd9 :
                     (mt32_mode == 'hA1 && mt32_rom == 1) ?  4'd10 :
                     (mt32_mode == 'hA1 && mt32_rom == 2) ?  4'd11 : 4'd12;
end

reg mt32_lcd_on;
always @(posedge CLK_VIDEO) begin
	int to;
	reg old_update;

	old_update <= mt32_lcd_update;
	if(to) to <= to - 1;

	if(mt32_info == 2) mt32_lcd_on <= 1;
	else if(mt32_info != 3) mt32_lcd_on <= 0;
	else begin
		if(!to) mt32_lcd_on <= 0;
		if(old_update ^ mt32_lcd_update) begin
			mt32_lcd_on <= 1;
			to <= 114000000 * 2;
		end
	end
end

wire mt32_lcd = mt32_lcd_on & mt32_lcd_en;

reg ce_pix_mt32;
always @(posedge CLK_VIDEO) begin
	reg [3:0] div;
	
	div <= div + 1'd1;
	ce_pix_mt32 <= !div;
end

/* ------------------------------------------------------------------------------ */

wire flt_en    = ~status[48] ? pwr_led : status[47];
wire aud_1200  = status[49];
wire paula_pwm = status[50];

wire [15:0] paula_smp_l = (paula_pwm ? {ldata_okk[8:0], 7'b0} : {ldata[14:0], 1'b0});
wire [15:0] paula_smp_r = (paula_pwm ? {rdata_okk[8:0], 7'b0} : {rdata[14:0], 1'b0});

// LPF 4400Hz, 1st order, 6db/oct
wire [15:0] lpf4400_l, lpf4400_r;
IIR_filter #(0) lpf4400
(
	.clk(clk_sys),
	.reset(reset),

	.ce(clk7_en | clk7n_en),
	.sample_ce(1),

	.cx (40'd4304835800),
	.cx0(1),
	.cy0(-2088941),
	
	.input_l(paula_smp_l),
	.input_r(paula_smp_r),
	.output_l(lpf4400_l),
	.output_r(lpf4400_r)
);

wire [15:0] audm_l = aud_1200 ? paula_smp_l : lpf4400_l;
wire [15:0] audm_r = aud_1200 ? paula_smp_r : lpf4400_r;

// LPF 3000Hz 1st + 3400Hz 1st
wire [15:0] lpf3275_l, lpf3275_r;
IIR_filter #(0) lpf3275
(
	.clk(clk_sys),
	.reset(reset),

	.ce(clk7_en | clk7n_en),
	.sample_ce(1),

	.cx (40'd8536629),
	.cx0(2),
	.cx1(1),
	.cy0(-4182432),
	.cy1(2085297),

	.input_l(audm_l),
	.input_r(audm_r),
	.output_l(lpf3275_l),
	.output_r(lpf3275_r)
);

reg [15:0] aud_l, aud_r;
always @(posedge CLK_AUDIO) begin
	reg [15:0] old_l0, old_l1, old_r0, old_r1;

	old_l0 <= flt_en ? lpf3275_l : audm_l;
	old_l1 <= old_l0;
	if(old_l0 == old_l1) aud_l <= old_l1;

	old_r0 <= flt_en ? lpf3275_r : audm_r;
	old_r1 <= old_r0;
	if(old_r0 == old_r1) aud_r <= old_r1;
end

wire  [15:0] cdda_l;
wire  [15:0] cdda_r;
wire  [15:0] cdda_dout;
wire         cdda_req;
wire         cdda_wr;

cdda #(28375160) cdda
(
	.CLK(clk_sys),
	.nRESET(~reset),
	.WRITE_REQ(cdda_req),
	.WRITE(cdda_wr),
	.DIN(cdda_dout),
	.AUDIO_L(cdda_l),
	.AUDIO_R(cdda_r)
);

reg [15:0] out_l, out_r;
always @(posedge CLK_AUDIO) begin
	reg [16:0] tmp_l, tmp_r;

	tmp_l <= {aud_l[15],aud_l} + {toccata_aud_left[15],toccata_aud_left} + (mt32_mute ? 17'd0 : {mt32_i2s_l[15],mt32_i2s_l}) + {cdda_l[15], cdda_l};
	tmp_r <= {aud_r[15],aud_r} + {toccata_aud_right[15],toccata_aud_right} + (mt32_mute ? 17'd0 : {mt32_i2s_r[15],mt32_i2s_r}) + {cdda_r[15], cdda_r};

	// clamp the output
	out_l <= (^tmp_l[16:15]) ? {tmp_l[16], {15{tmp_l[15]}}} : tmp_l[15:0];
	out_r <= (^tmp_r[16:15]) ? {tmp_r[16], {15{tmp_r[15]}}} : tmp_r[15:0];
end

assign AUDIO_S = 1;
assign AUDIO_L = out_l;
assign AUDIO_R = out_r;

endmodule
