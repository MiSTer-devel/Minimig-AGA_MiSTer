// The full-system simulation of Minimig: the core's emu (Minimig.sv) as
// Quartus builds it, with an SDRAM chip and the DDR3 port modelled.  The
// bench (sim_main.cpp) drives the clocks (pll_sim.sv), the HPS bus as Main
// does (hps_io and hps_ext take it), and watches the CPU's chip bus writes
// for the test programs' mailbox at $F00000.

module tb_top
(
	input         clk_50,
	input         reset,

	// the HPS side of hps_io (Main): HPS_BUS[35:33] {fpga, uio, strobe},
	// HPS_BUS[31:16] the word
	input         hps_fpga,
	input         hps_uio,
	input         hps_strobe,
	input  [15:0] hps_din,
	output [15:0] hps_dout,

	// the CPU's chip bus writes, one pulse each at the end of the cycle
	output reg        mon_wr = 1'b0,
	output reg [23:1] mon_addr,
	output reg [15:0] mon_data,
	output reg  [1:0] mon_ds,           // {UDS, LDS} asserted
	output reg        mon_rd = 1'b0,    // a read cycle: its data (and the second word of a 32-bit one)
	output reg [15:0] mon_rdata,
	output reg [15:0] mon_rdata2,
	output reg        mon_long,

	output        led_power,

	// observation
	output        dbg_cpu_rst,
	output        dbg_chip_as,
	output [23:1] dbg_chip_addr,
	output  [1:0] dbg_cpu_state,
	output        dbg_reset_d,
	output        dbg_cpuhlt,
	output  [1:0] dbg_turbo,
	output  [2:0] dbg_cachecfg
);
assign dbg_turbo     = {emu.cpu_wrapper.turbokick_d, emu.cpu_wrapper.turbochip_d};
assign dbg_cachecfg  = emu.cachecfg;
assign dbg_cpu_rst   = emu.cpu_rst;
assign dbg_chip_as   = emu.chip_as;
assign dbg_chip_addr = emu.chip_addr;
assign dbg_cpu_state = emu.cpu_state;
assign dbg_reset_d   = emu.reset_d;
assign dbg_cpuhlt    = emu.minimig.cpuhlt;

wire [45:0] HPS_BUS;
assign HPS_BUS[45:38] = 8'd0;
assign HPS_BUS[35:33] = {hps_fpga, hps_uio, hps_strobe};
assign HPS_BUS[31:16] = hps_din;
assign hps_dout = HPS_BUS[15:0];

wire        sd_clk, sd_cke, sd_dqml, sd_dqmh, sd_cs_n, sd_cas_n, sd_ras_n, sd_we_n;
wire [12:0] sd_a;
wire  [1:0] sd_ba;
wire [15:0] sd_dq;

wire        dd_clk, dd_busy, dd_rd, dd_we, dd_dout_ready;
wire  [7:0] dd_burstcnt, dd_be;
wire [28:0] dd_addr;
wire [63:0] dd_dout, dd_din;
wire  [1:0] led_pwr;
assign led_power = led_pwr[0];

emu emu
(
	.CLK_50M          (clk_50),
	.RESET            (reset),
	.HPS_BUS          (HPS_BUS),

	.CLK_VIDEO        (),
	.CE_PIXEL         (),
	.VIDEO_ARX        (),
	.VIDEO_ARY        (),
	.VGA_R            (),
	.VGA_G            (),
	.VGA_B            (),
	.VGA_HS           (),
	.VGA_VS           (),
	.VGA_DE           (),
	.VGA_F1           (),
	.VGA_SL           (),
	.VGA_SCALER       (),
	.VGA_DISABLE      (),
	.HDMI_WIDTH       (12'd1920),
	.HDMI_HEIGHT      (12'd1080),
	.HDMI_FREEZE      (),
	.HDMI_BLACKOUT    (),
	.HDMI_BOB_DEINT   (),

	.FB_EN            (),
	.FB_FORMAT        (),
	.FB_WIDTH         (),
	.FB_HEIGHT        (),
	.FB_BASE          (),
	.FB_STRIDE        (),
	.FB_VBL           (1'b0),
	.FB_LL            (1'b0),
	.FB_FORCE_BLANK   (),
	.FB_PAL_CLK       (),
	.FB_PAL_ADDR      (),
	.FB_PAL_DOUT      (),
	.FB_PAL_DIN       (24'd0),
	.FB_PAL_WR        (),

	.LED_USER         (),
	.LED_POWER        (led_pwr),
	.LED_DISK         (),
	.BUTTONS          (),

	.CLK_AUDIO        (1'b0),
	.AUDIO_L          (),
	.AUDIO_R          (),
	.AUDIO_S          (),
	.AUDIO_MIX        (),

	.ADC_BUS          (),
	.SD_SCK           (),
	.SD_MOSI          (),
	.SD_MISO          (1'b1),
	.SD_CS            (),
	.SD_CD            (1'b1),

	.DDRAM_CLK        (dd_clk),
	.DDRAM_BUSY       (dd_busy),
	.DDRAM_BURSTCNT   (dd_burstcnt),
	.DDRAM_ADDR       (dd_addr),
	.DDRAM_DOUT       (dd_dout),
	.DDRAM_DOUT_READY (dd_dout_ready),
	.DDRAM_RD         (dd_rd),
	.DDRAM_DIN        (dd_din),
	.DDRAM_BE         (dd_be),
	.DDRAM_WE         (dd_we),

	.SDRAM_CLK        (sd_clk),
	.SDRAM_CKE        (sd_cke),
	.SDRAM_A          (sd_a),
	.SDRAM_BA         (sd_ba),
	.SDRAM_DQ         (sd_dq),
	.SDRAM_DQML       (sd_dqml),
	.SDRAM_DQMH       (sd_dqmh),
	.SDRAM_nCS        (sd_cs_n),
	.SDRAM_nCAS       (sd_cas_n),
	.SDRAM_nRAS       (sd_ras_n),
	.SDRAM_nWE        (sd_we_n),

	.UART_CTS         (1'b0),
	.UART_RTS         (),
	.UART_RXD         (1'b1),
	.UART_TXD         (),
	.UART_DTR         (),
	.UART_DSR         (1'b0),

	.USER_IN          (7'h7F),
	.USER_OUT         (),

	.OSD_STATUS       (1'b0)
);

sdram_model sdram
(
	.clk   (sd_clk),
	.a     (sd_a),
	.ba    (sd_ba),
	.dq    (sd_dq),
	.dqml  (sd_dqml),
	.dqmh  (sd_dqmh),
	.cs_n  (sd_cs_n),
	.ras_n (sd_ras_n),
	.cas_n (sd_cas_n),
	.we_n  (sd_we_n)
);

ddr3_model ddr3
(
	.clk        (dd_clk),
	.busy       (dd_busy),
	.burstcnt   (dd_burstcnt),
	.addr       (dd_addr),
	.dout       (dd_dout),
	.dout_ready (dd_dout_ready),
	.rd         (dd_rd),
	.din        (dd_din),
	.be         (dd_be),
	.we         (dd_we)
);

// the CPU's chip bus (cpu_wrapper's outputs): a write cycle, reported when
// AS goes away
reg        as_d = 1'b1;
reg        wcyc = 1'b0;
reg        rcyc = 1'b0;
always @(posedge emu.clk_sys) begin
	mon_wr <= 1'b0;
	mon_rd <= 1'b0;
	if (!emu.chip_as && emu.chip_rw && !emu.chip_dtack) begin
		rcyc       <= 1'b1;
		mon_addr   <= emu.chip_addr;
		mon_rdata  <= emu.chip_dout;
		mon_rdata2 <= emu.chip_rd2;
		mon_long   <= emu.chip_long;
	end
	if (emu.chip_as && !as_d && rcyc) begin
		mon_rd <= 1'b1;
		rcyc   <= 1'b0;
	end
	as_d   <= emu.chip_as;
	if (!emu.chip_as && !emu.chip_rw && (!emu.chip_uds || !emu.chip_lds)) begin
		wcyc     <= 1'b1;
		mon_addr <= emu.chip_addr;
		mon_data <= emu.chip_din;
		mon_ds   <= {!emu.chip_uds, !emu.chip_lds};
	end
	if (emu.chip_as && !as_d && wcyc) begin
		mon_wr <= 1'b1;
		wcyc   <= 1'b0;
	end
end

endmodule
