/********************************************/
/* minimig.sv                               */
/* MiSTer glue logic                        */
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
   output  [1:0] VGA_SL,
   input         HDMI_VS,

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
   output        SDRAM_nWE,

   input         UART_CTS,
   output        UART_RTS,
   input         UART_RXD,
   output        UART_TXD,
	output        UART_DTR,
	input	        UART_DSR
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
amiga_clk amiga_clk
(
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


TG68K tg68k
(
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
	.ovr          (tg68_ovr         ),
	.ramaddr      (tg68_cad         ),
	.nResetOut    (tg68_nrst_out    ),
	.cpuDMA       (tg68_cdma        ),
	.ramlds       (tg68_clds        ),
	.ramuds       (tg68_cuds        ),

	//custom CPU signals
	.cpustate     (tg68_cpustate    ),
	.CACR_out     (tg68_CACR_out    ),
	.VBR_out      (tg68_VBR_out     )
);

sdram_ctrl sdram
(
	.sysclk       (clk_114          ),
	.reset_in     (pll_locked       ),
	.c_7m         (clk_7            ),
	.reset_out    (                 ),

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

	.cpuWR        (tg68_dat_out     ),
	.cpuAddr      (tg68_cad[24:1]   ),
	.cpuU         (tg68_cuds        ),
	.cpuL         (tg68_clds        ),
	.cpustate     (tg68_cpustate    ),
	.cpu_dma      (tg68_cdma        ),
	.cpuRD        (tg68_cout        ),
	.cpuena       (tg68_cpuena      ),
	.enaWRreg     (tg68_enaWR       ),
	.ena7RDreg    (tg68_ena7RD      ),
	.ena7WRreg    (tg68_ena7WR      ),

	.chipWR       (ram_data         ),
	.chipAddr     ({2'b00, ram_address[21:1]}),
	.chipU        (_ram_bhe         ),
	.chipL        (_ram_ble         ),
	.chipRW       (_ram_we          ),
	.chip_dma     (_ram_oe          ),
	.chipRD       (ramdata_in       ),
	.chip48       (chip48           )
);

assign IO_DOUT = IO_UIO ? uio_dout : fpga_dout;

wire [15:0] uio_dout;
wire [15:0] fpga_dout;
wire        ce_pix;

hps_io hps_io
(
	.*,

	.clk(clk_28),

	.IO_ENA(IO_UIO),
	.IO_STROBE(IO_STROBE),
	.IO_WAIT(IO_WAIT_UIO),
	.IO_DIN(IO_DIN),
	.IO_DOUT(uio_dout),
	
	.BUTTONS(),
	.CONF(),

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
	.vs_hdmi(HDMI_VS),
	.f1(VGA_F1)
);

//// minimig top ////
minimig minimig
(
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
	.rxd          (UART_RXD         ), // RS232 receive
	.txd          (UART_TXD         ), // RS232 send
	.cts          (UART_CTS         ), // RS232 clear to send
	.rts          (UART_RTS         ), // RS232 request to send
	.dtr          (UART_DTR         ), // RS232 Data Terminal Ready
	.dsr          (UART_DSR         ), // RS232 Data Set Ready
	.cd           (UART_DSR         ), // RS232 Carrier Detect
	.ri           (1                ), // RS232 Ring Indicator

	//I/O
	._joy1        (~joya            ), // joystick 1 [fire4,fire3,fire2,fire,up,down,left,right] (default mouse port)
	._joy2        (~joyb            ), // joystick 2 [fire4,fire3,fire2,fire,up,down,left,right] (default joystick port)
	.mouse_btn    (mouse_buttons    ), // mouse buttons
	.kbd_mouse_data (kbd_mouse_data ), // mouse direction data, keycodes
	.kbd_mouse_type (kbd_mouse_type ), // type of data
	.kbd_mouse_strobe (kbd_mouse_strobe), // kbd/mouse data strobe
	.kms_level    (kms_level        ),
	.pwr_led      (LED_POWER[0]     ), // power led
	.fdd_led      (LED_USER         ),
	.hdd_led      (LED_DISK[0]      ),
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
	.hblank       (hblank           ),
	.vblank       (vblank           ),
	.ar           (ar               ),
	.scanline     (VGA_SL           ),
	.ce_pix       (ce_pix           ),
	.res          (res              ),

	//audio
	.ldata        (ldata            ), // left DAC data
	.rdata        (rdata            ), // right DAC data

	//user i/o
	.cpu_config   (cpu_config       ), // CPU config
	.memcfg       (memcfg           ), // memory config
	.turbochipram (turbochipram     ), // turbo chipRAM
	.turbokick    (turbokick        ), // turbo kickstart

	.trackdisp    (                 ), // floppy track number
	.secdisp      (                 ), // sector
	.floppy_fwr   (                 ), // floppy fifo writing
	.floppy_frd   (                 ), // floppy fifo reading
	.hd_fwr       (                 ), // hd fifo writing
	.hd_frd       (                 )  // hd fifo reading
);

assign VGA_DE = hde & vde;

reg  hde;
wire vde = ~(fvbl | svbl);

wire [7:0] red, green, blue, r,g,b;
wire hblank, vblank;
reg  fhbl, fvbl, shbl, svbl;
wire hbl = fhbl | shbl;

wire [1:0] res;

wire sset;
wire [11:0] shbl_l, shbl_r;
wire [11:0] svbl_t, svbl_b;

reg [11:0] hbl_l=0, hbl_r=0;
reg [11:0] hsta, hend, hmax, hcnt;
reg [11:0] hsize;
always @(posedge clk_28) begin
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
	
	if(~old_hblank & hblank & ~VGA_F1 & (vcnt == vsta+1'd1)) hsize <= hcnt - hend;
end

reg [11:0] vbl_t=0, vbl_b=0;
reg [11:0] vsta, vend, vmax, f1_vend, f1_vsize, vcnt;
reg [11:0] vsize;
always @(posedge clk_28) begin
	reg old_vs;
	reg old_vblank, old_hs, old_hbl;

	old_vs <= vs;
	old_hs <= hs;
	old_vblank <= vblank;
	
	if(old_hs & ~hs) vcnt <= vcnt + 1'd1;
	if(~vs) vcnt <= 0;

	if(~VGA_F1) begin
		if(old_vblank & ~vblank) vend <= vcnt;
		if(~old_vblank & vblank) vsta <= vcnt;
		if(old_vs & ~vs)         vmax <= vcnt;
		
		if(~old_vblank & vblank) begin
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
	if(old_hbl & ~hbl) begin
		if(vcnt == vend+vbl_t-1'd1) svbl <= 0;
		if(vcnt == vsta+vbl_b-1'd1) svbl <= 1;

		//force vblank
		if(vcnt == 1)         fvbl <= 0;
		if(vcnt == vmax-4'd3) fvbl <= 1;
	end
	
	hde <= ~hbl;
end

wire adj_stb = kbd_mouse_strobe && (kbd_mouse_type==3);

always @(posedge clk_28) begin
	reg old_stb;
	reg alt = 0;

	old_stb <= adj_stb;
	if(~old_stb & adj_stb) begin
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

always @(posedge clk_28) begin
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

endmodule
