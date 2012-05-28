/* ctrl_top.v */


module ctrl_top (
  // system
  input  wire           clk_in,
  input  wire           rst_ext,
  output wire           clk_out,
  output wire           rst_out,
  // SRAM interface
  output wire [ 18-1:0] sram_adr,
  output wire           sram_ce_n,
  output wire           sram_we_n,
  output wire           sram_ub_n,
  output wire           sram_lb_n,
  output wire           sram_oe_n,
  output wire [ 16-1:0] sram_dat_w,
  input  wire [ 16-1:0] sram_dat_r,
  // FLASH interface
  output wire [ 22-1:0] fl_adr,
  output wire           fl_ce_n,
  output wire           fl_we_n,
  output wire           fl_oe_n,
  output wire           fl_rst_n,
  output wire [  8-1:0] fl_dat_w,
  input  wire [  8-1:0] fl_dat_r,
  // UART
  output wire           uart_txd
);



////////////////////////////////////////
// PLL clock generation               //
////////////////////////////////////////

`ifdef SOC_SIM
reg            clk_100;
initial begin
  clk_100 = 1;
  forever #5 clk_100 = ~clk_100; 
end
reg            clk_50;
initial begin
  clk_50 = 1;
  forever #10 clk_50 = ~clk_50; 
end
reg            clk_25;
initial begin
  clk_25 = 1;
  forever #20 clk_25 = ~clk_25; 
end
reg            pll_locked;
initial begin
  pll_locked = 1;
end
`else
wire           clk_100;
wire           clk_50;
wire           clk_25;
wire           pll_locked;

// ctrl_clk
ctrl_clk ctrl_clk(
  .inclk0     (clk_in     ),  // 50MHz input clock
  .c0         (clk_100    ),  // 100MHz output clock
  .c1         (clk_50     ),  // 50MHz output clock
  .c2         (clk_25     ),  // 25MHz output clock
  .locked     (pll_locked )   // pll locked output, active high
);
`endif



////////////////////////////////////////
// reset generation                   //
////////////////////////////////////////

wire           clk;
wire           rst;

// ctrl_rst
`ifdef SOC_SIM
`define RST_CNT 16'h00ff      // reset counter length used in simulations
`else
`define RST_CNT 16'hffff      // reset counter length
`endif
ctrl_rst ctrl_rst (
  .clk        (clk_50     ),  // system clock
  .pll_lock   (pll_locked ),  // pll locked input, active high
  .rst_ext    (rst_ext    ),  // external reset (button) input, active high
  .rst_reg    (1'b0       ),  // register reset input, active high
  .rst        (rst        )   // reset signal output, active high
);

assign clk = clk_50;
assign clk_out = clk_50;
assign rst_out = rst;



////////////////////////////////////////
// qmem interconnect                  //
////////////////////////////////////////

localparam MAW = 24;
localparam SAW = 22;
localparam QDW = 32;
localparam QSW = 4;

wire [MAW-1:0] dcpu_adr;
wire           dcpu_cs;
wire           dcpu_we;
wire [QSW-1:0] dcpu_sel;
wire [QDW-1:0] dcpu_dat_w;
wire [QDW-1:0] dcpu_dat_r;
wire           dcpu_ack;
wire           dcpu_err;
wire [MAW-1:0] icpu_adr;
wire           icpu_cs;
wire           icpu_we;
wire [QSW-1:0] icpu_sel;
wire [QDW-1:0] icpu_dat_w;
wire [QDW-1:0] icpu_dat_r;
wire           icpu_ack;
wire           icpu_err;
wire [SAW-1:0] ram_adr;
wire           ram_cs;
wire           ram_we;
wire [QSW-1:0] ram_sel;
wire [QDW-1:0] ram_dat_w;
wire [QDW-1:0] ram_dat_r;
wire           ram_ack;
wire           ram_err;
wire [SAW-1:0] rom_adr;
wire           rom_cs;
wire           rom_we;
wire [QSW-1:0] rom_sel;
wire [QDW-1:0] rom_dat_w;
wire [QDW-1:0] rom_dat_r;
wire           rom_ack;
wire           rom_err;
wire [SAW-1:0] regs_adr;
wire           regs_cs;
wire           regs_we;
wire [QSW-1:0] regs_sel;
wire [QDW-1:0] regs_dat_w;
wire [QDW-1:0] regs_dat_r;
wire           regs_ack;
wire           regs_err;

// ctrl_bus
qmem_bus #(
  .MAW        (MAW),          // master address width
  .SAW        (SAW),          // slave address width
  .QDW        (QDW),          // data width
  .QSW        (QSW)           // select width
) ctrl_bus (
  // system
  .clk        (clk        ),
  .rst        (rst        ),
  // master 0 (dcpu)
  .m0_adr     (dcpu_adr   ),
  .m0_cs      (dcpu_cs    ),
  .m0_we      (dcpu_we    ),
  .m0_sel     (dcpu_sel   ),
  .m0_dat_w   (dcpu_dat_w ),
  .m0_dat_r   (dcpu_dat_r ),
  .m0_ack     (dcpu_ack   ),
  .m0_err     (dcpu_err   ),
  // master 1 (icpu)
  .m1_adr     (icpu_adr   ),
  .m1_cs      (icpu_cs    ),
  .m1_we      (icpu_we    ),
  .m1_sel     (icpu_sel   ),
  .m1_dat_w   (icpu_dat_w ),
  .m1_dat_r   (icpu_dat_r ),
  .m1_ack     (icpu_ack   ),
  .m1_err     (icpu_err   ),
  // slave 0 (ram)
  .s0_adr     (ram_adr    ),
  .s0_cs      (ram_cs     ),
  .s0_we      (ram_we     ),
  .s0_sel     (ram_sel    ),
  .s0_dat_w   (ram_dat_w  ),
  .s0_dat_r   (ram_dat_r  ),
  .s0_ack     (ram_ack    ),
  .s0_err     (ram_err    ),
  // slave 1 (rom)
  .s1_adr     (rom_adr    ),
  .s1_cs      (rom_cs     ),
  .s1_we      (rom_we     ),
  .s1_sel     (rom_sel    ),
  .s1_dat_w   (rom_dat_w  ),
  .s1_dat_r   (rom_dat_r  ),
  .s1_ack     (rom_ack    ),
  .s1_err     (rom_err    ),
  // slave 2 (regs)
  .s2_adr     (regs_adr   ),
  .s2_cs      (regs_cs    ),
  .s2_we      (regs_we    ),
  .s2_sel     (regs_sel   ),
  .s2_dat_w   (regs_dat_w ),
  .s2_dat_r   (regs_dat_r ),
  .s2_ack     (regs_ack   ),
  .s2_err     (regs_err   )
);



////////////////////////////////////////
// OR1200 cpu                         //
////////////////////////////////////////

or1200_top_wrapper #(
  .AW       (MAW)             // address bus width
) ctrl_cpu (
  // system
  .clk        (clk        ),
  .rst        (rst        ),
  // data bus
  .dcpu_cs    (dcpu_cs    ),
  .dcpu_we    (dcpu_we    ),
  .dcpu_sel   (dcpu_sel   ),
  .dcpu_adr   (dcpu_adr   ),
  .dcpu_dat_w (dcpu_dat_w ),
  .dcpu_dat_r (dcpu_dat_r ),
  .dcpu_ack   (dcpu_ack   ),
  // instruction bus
  .icpu_cs    (icpu_cs    ),
  .icpu_we    (icpu_we    ),
  .icpu_sel   (icpu_sel   ),
  .icpu_adr   (icpu_adr   ),
  .icpu_dat_w (icpu_dat_w ),
  .icpu_dat_r (icpu_dat_r ),
  .icpu_ack   (icpu_ack   )
);



////////////////////////////////////////
// RAM                                //
////////////////////////////////////////

// TODO check data register!
qmem_sram #(
  .AW         (SAW),          // address bus width
  .DW         (QDW),          // data bus width
  .SW         (QSW)           // select width
) ctrl_ram (
  // system signals
  .clk50      (clk_50     ),
  .clk100     (clk_100    ),
  .rst        (rst        ),
  // qmem bus
  .adr        (ram_adr    ),
  .cs         (ram_cs     ),
  .we         (ram_we     ),
  .sel        (ram_sel    ),
  .dat_w      (ram_dat_w  ),
  .dat_r      (ram_dat_r  ),
  .ack        (ram_ack    ),
  .err        (ram_err    ),
  // SRAM interface
  .sram_adr   (sram_adr   ),
  .sram_ce_n  (sram_ce_n  ),
  .sram_we_n  (sram_we_n  ),
  .sram_ub_n  (sram_ub_n  ),
  .sram_lb_n  (sram_lb_n  ),
  .sram_oe_n  (sram_oe_n  ),
  .sram_dat_w (sram_dat_w ),
  .sram_dat_r (sram_dat_r )
);



////////////////////////////////////////
// ROM                                //
////////////////////////////////////////

ctrl_flash #(
  .FAW      (22 ),            // flash address width
  .FDW      (8  ),            // flash data width
  .QAW      (SAW),            // qmem address width
  .QDW      (QDW),            // qmem data width
  .QSW      (QSW),            // qmem select width
  .DLY      (4  )             // delay - for S29AL032D70 (70ns access part)
) ctrl_rom (
  // system
  .clk        (clk        ),
  .rst        (rst        ),
  // qmem interface
  .adr        (rom_adr    ),
  .cs         (rom_cs     ),
  .we         (rom_we     ),
  .sel        (rom_sel    ),
  .dat_w      (rom_dat_w  ),
  .dat_r      (rom_dat_r  ),
  .ack        (rom_ack    ),
  .err        (rom_err    ),
  // flash interface
  .fl_adr     (fl_adr     ),
  .fl_ce_n    (fl_ce_n    ),
  .fl_we_n    (fl_we_n    ),
  .fl_oe_n    (fl_oe_n    ),
  .fl_rst_n   (fl_rst_n   ),
  .fl_dat_w   (fl_dat_w   ),
  .fl_dat_r   (fl_dat_r   )
);



////////////////////////////////////////
// REGS                               //
////////////////////////////////////////

// TODO


endmodule

