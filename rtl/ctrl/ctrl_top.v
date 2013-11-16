/********************************************/
/* ctrl_top.v                               */
/* Control top module                       */
/* external tristate drivers needed!        */
/*                                          */
/* 2012, rok.krajnc@gmail.com               */
/********************************************/

/*
DESCRIPTION
This is minimig-de1's control sub-module. It contains a PLL for clock generation, a reset generator,
OR1200 CPU, SRAM & FLASH controllers, and a register slave, which contains reset controls,
timer, UART serial transmitter and a SPI master.
The control submodule requires external 50MHz clock for proper functioning.

BUS
     --------    --------
     | ICPU |    | DCPU |
     --------    --------
        |             |
     -------      -------
     | DEC |      | DEC |
     -------      -------
       | |         | | |
   ----- -------   | | |
   |           |   | | |
   |   --------|---- | |
   |   |       |     | |
   |   |       |  ---- -----------------
   |   |       |  |          |         |
  -------     -------        |         |
  | ARB |     | ARB |        |         |
  -------     -------        |         |
     |           |           |         |
  -------     -------     -------   --------
  | ROM |     | RAM |     | REG |   | DRAM |
  -------     -------     -------   --------

ICPU - CPU instruction bus
DCPU - CPU data bus
DEC  - slave decoder
ARB  - master arbiter
ROM  - FLASH
RAM  - SRAM
REG  - registers
DRAM - SDRAM

Bus is multilayered - accesses from different masters to different slaves can be started independently.
Masters: There are two masters, CPU inctruction bus and CPU data bus.
Slaves:  There are three slaves, FLASH, SRAM and REGS.

Bus type is QMEM, which is a bus modeled after zero wait state memory, with added back pressure flow control.
bus signals:
  CS    (chip select)       - signals a valid master access
  ADR   (address)           - master address
  SEL   (byte select)       - selects valid bytes
  WE    (write enable)      - signals write (1) or read (0) access
  DAT_W (write data)        - master data output
  DAT_R (read data)         - master data input
  ACK   (data acknowledge)  - slave data acknowledge

Acknowledge for writes is asserted in the same cycle as write data.
Acknowledge for reads is asserted one cycle ahead of read data - reads are pipelined.
Master can assert new cycle on the bus after receiving an ack.
Master can't change the active cycle without receiving an ack.

MEMORY ORGANIZATION
0 - (0x000000 - 0x3fffff) adr[23:22] == 2'b00 - ROM
1 - (0x400000 - 0x7fffff) adr[23:22] == 2'b01 - RAM
2 - (0x800000 - 0xbfffff) adr[23:22] == 2'b10 - REGS
3 - (0xc00000 - 0xffffff) adr[23:22] == 2'b11 - DRAM

Only 24 bits of address space is used. This space is divided into four 4Mbyte blocks.

Both masters see the same address space, but only data bus can access the REGS slave.
Address space is minimally decoded - that means that the all slaves are seen aliased at many different addresses.
Don't write to undefined addresses, or bad things could happen!

REGISTERS
reset control      = 0x800000 (bit 0 = ctrl reset, bit1 = minimig reset)
ctrl cfg & status  = 0x800004 (bits [3:0] = cfg input, bits [18:15] = status output)
UART TxD           = 0x800008
timer              = 0x80000c
SPI clock divider  = 0x800010
SPI CS             = 0x800014
SPI_DAT            = 0x800018
SPI_BLOCK          = 0x80001c

The CPU boots from address 0x000004 (ROM). The startup code is written in such a way, that it copies itself into RAM,
and then jumps to RAM and continues executing.

The boot_sel signal can be used to change ROM bootcode location (offset).
The signal is XORed with the last address bit (adr[21]):
bootsel = 0 : master sees flash addresses linearly
bootsel = 1 : master sees top 2MB at location offset 0, and lower 2MB at location offset 2097152 (2MB).

*/

//`define MINIMIG_DE1_FLASH_ROM


module ctrl_top (
  // system
  input  wire           clk_in,
  input  wire           rst_ext,
  output wire           clk_out,
  output wire           rst_out,
  output wire           rst_minimig,
  output wire           rst_cpu,
  // config
  input  wire           boot_sel,
  input  wire [  4-1:0] ctrl_cfg,
  // status
  output wire           rom_status,
  output wire           ram_status,
  output wire           reg_status,
  output wire           dram_status,
  output wire [  4-1:0] ctrl_status,
  input  wire [  4-1:0] sys_status,
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
  // SDRAM interface
  output wire [ 22-1:0] dram_adr,
  output wire           dram_cs,
  output wire           dram_we,
  output wire [  4-1:0] dram_sel,
  output wire [ 32-1:0] dram_dat_w,
  input  wire [ 32-1:0] dram_dat_r,
  input  wire           dram_ack,
  input  wire           dram_err,
  // UART
  output wire           uart_txd,
  input  wire           uart_rxd,
  // SPI
  output wire [  4-1:0] spi_cs_n,
  output wire           spi_clk,
  output wire           spi_do,
  input  wire           spi_di
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

wire           clk;
assign clk = clk_50;
assign clk_out = clk_50;



////////////////////////////////////////
// reset generation                   //
////////////////////////////////////////

wire           rst;
wire           rst_reg;
assign rst_out = rst;

// ctrl_rst
ctrl_rst ctrl_rst (
  .clk        (clk_50     ),  // system clock
  .pll_lock   (pll_locked ),  // pll locked input, active high
  .rst_ext    (rst_ext    ),  // external reset (button) input, active high
  .rst_reg    (rst_reg    ),  // register reset input, active high
  .rst        (rst        )   // reset signal output, active high
);



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
  // status
  .rom_s      (rom_status ),
  .ram_s      (ram_status ),
  .reg_s      (reg_status ),
  .dram_s     (dram_status),
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
  // slave 0 (rom)
  .s0_adr     (rom_adr    ),
  .s0_cs      (rom_cs     ),
  .s0_we      (rom_we     ),
  .s0_sel     (rom_sel    ),
  .s0_dat_w   (rom_dat_w  ),
  .s0_dat_r   (rom_dat_r  ),
  .s0_ack     (rom_ack    ),
  .s0_err     (rom_err    ),
  // slave 1 (ram)
  .s1_adr     (ram_adr    ),
  .s1_cs      (ram_cs     ),
  .s1_we      (ram_we     ),
  .s1_sel     (ram_sel    ),
  .s1_dat_w   (ram_dat_w  ),
  .s1_dat_r   (ram_dat_r  ),
  .s1_ack     (ram_ack    ),
  .s1_err     (ram_err    ),
  // slave 2 (regs)
  .s2_adr     (regs_adr   ),
  .s2_cs      (regs_cs    ),
  .s2_we      (regs_we    ),
  .s2_sel     (regs_sel   ),
  .s2_dat_w   (regs_dat_w ),
  .s2_dat_r   (regs_dat_r ),
  .s2_ack     (regs_ack   ),
  .s2_err     (regs_err   ),
  // slave 3 (dram)
  .s3_adr     (dram_adr   ),
  .s3_cs      (dram_cs    ),
  .s3_we      (dram_we    ),
  .s3_sel     (dram_sel   ),
  .s3_dat_w   (dram_dat_w ),
  .s3_dat_r   (dram_dat_r ),
  .s3_ack     (dram_ack   ),
  .s3_err     (dram_err   )
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

`ifdef MINIMIG_DE1_FLASH_ROM
ctrl_flash #(
  .FAW      (22 ),            // flash address width
  .FDW      (8  ),            // flash data width
  .QAW      (SAW),            // qmem address width
  .QDW      (QDW),            // qmem data width
  .QSW      (QSW),            // qmem select width
  .DLY      (3  ),            // 80ns delay @ 50MHz clock - for S29AL032D70 (70ns access part)
  .BE       (1  )             // big endianness - 1 = big endian, 0 = little endian
) ctrl_rom (
  // system
  .clk        (clk        ),
  .rst        (rst        ),
  // config
  .boot_sel   (boot_sel   ),
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
`else
assign fl_adr   = 22'b0;
assign fl_ce_n  = 1'b1;
assign fl_we_n  = 1'b1;
assign fl_oe_n  = 1'b1;
assign fl_rst_n = 1'b1;
assign fl_dat_w = 8'b0;
ctrl_boot ctrl_rom (
  .clock      (clk        ),
  .address    (rom_adr[11:2]),
  .q          (rom_dat_r  )
);
assign rom_ack = 1'b1;
assign rom_err = 1'b0;
`endif


////////////////////////////////////////
// REGS                               //
////////////////////////////////////////

ctrl_regs #(
  .QAW      (SAW),            // qmem address width
  .QDW      (QDW),            // qmem data width
  .QSW      (QSW)             // qmem select width
) ctrl_regs (
  // system
  .clk        (clk        ),
  .rst        (rst        ),
  // qmem bus
  .adr        (regs_adr   ),
  .cs         (regs_cs    ),
  .we         (regs_we    ),
  .sel        (regs_sel   ),
  .dat_w      (regs_dat_w ),
  .dat_r      (regs_dat_r ),
  .ack        (regs_ack   ),
  .err        (regs_err   ),
  // registers
  .sys_rst    (rst_reg    ),
  .minimig_rst(rst_minimig),
  .cpu_rst    (rst_cpu    ),
  .ctrl_cfg   (ctrl_cfg   ),
  .ctrl_status (ctrl_status),
  .sys_status (sys_status ),
  .uart_txd   (uart_txd   ),
  .uart_rxd   (uart_rxd   ),
  .spi_cs_n   (spi_cs_n   ),
  .spi_clk    (spi_clk    ),
  .spi_do     (spi_do     ),
  .spi_di     (spi_di     )
);



endmodule

