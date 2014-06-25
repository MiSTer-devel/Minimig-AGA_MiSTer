/********************************************/
/* ctrl_tb.v                                */
/*                                          */
/* 2012, rok.krajnc@gmail.com               */
/********************************************/


//`default_nettype none
`timescale 1ns/1ps


module ctrl_tb();



////////////////////////////////////////
// defines                            //
////////////////////////////////////////
`define SOC_SIM



////////////////////////////////////////
// internal signals                   //
////////////////////////////////////////

// system
reg            CLK;
reg            RST;
reg            ERR;
reg [ 32-1:0]  MEM [0:4096-1];
// SD Card
wire           SD_DAT;      // SD Card Data
wire           SD_DAT3;     // SD Card Data 3
wire           SD_CMD;      // SD Card Command Signal
wire           SD_CLK;      // SD Card Clock
// SRAM
tri  [16-1:0]  SRAM_DQ;     // SRAM Data bus 16 Bits
wire [18-1:0]  SRAM_ADDR;   // SRAM Address bus 18 Bits
wire           SRAM_UB_N;   // SRAM High-byte Data Mask 
wire           SRAM_LB_N;   // SRAM Low-byte Data Mask 
wire           SRAM_WE_N;   // SRAM Write Enable
wire           SRAM_CE_N;   // SRAM Chip Enable
wire           SRAM_OE_N;   // SRAM Output Enable
// FLASH
tri  [ 8-1:0]  FL_DQ;       // FLASH Data bus 8 Bits
wire [22-1:0]  FL_ADDR;     // FLASH Address bus 22 Bits
wire           FL_WE_N;     // FLASH Write Enable
wire           FL_RST_N;    // FLASH Reset
wire           FL_OE_N;     // FLASH Output Enable
wire           FL_CE_N;     // FLASH Chip Enable
// UART
wire           UART_TXD;    // UART Transmitter
wire           UART_RXD;    // UART Receiver
reg            BOOT_SEL;    // boot location select
reg  [ 4-1:0]  CTRL_CFG;    // control block config input
wire [ 4-1:0]  CTRL_STATUS; // control block status output

reg  [32-1:0]  dat;


////////////////////////////////////////
// bench                              //
////////////////////////////////////////

// clocks & async reset
initial begin
  CLK  = 1'b1;
  forever #10 CLK = ~CLK;
end


// bench
initial begin
  $display("BENCH : %t : ctrl test starting ...", $time);

  // initial states
  RST = 1;
  ERR = 0;
  BOOT_SEL = 0;

  // load RAM
  $display("BENCH : %t : loading memory ...", $time);
  //$readmemh("../../../../fw/ctrl/boot_old/bin/ctrl_boot.hex", MEM);
  //ram_write;

  repeat(2) @ (posedge CLK);
  #1;

  RST = 0;

  // disable ctrl CPU
  force ctrl_top.ctrl_cpu.dcpu_cs  = 1'b0;
  force ctrl_top.ctrl_cpu.icpu_cs  = 1'b0;
  force ctrl_top.ctrl_cpu.dcpu_ack = 1'b0;
  force ctrl_top.ctrl_cpu.icpu_ack = 1'b0;

  // wait for reset
  wait (!ctrl_top.ctrl_regs.rst);
  @ (posedge ctrl_top.clk);

  // write a char to UART TX
  ctrl_regs_cycle(32'h0080000c, 1'b1, 4'hf, 32'h000000ab);
  repeat(5000) @ (posedge CLK);
  ctrl_regs_cycle(32'h00800014, 1'b0, 4'hf, 32'hxxxxxxxx, dat);
  $display("UART_STAT = 0x%02x", dat, dat);
  repeat(5000) @ (posedge CLK);
  ctrl_regs_cycle(32'h00800010, 1'b0, 4'hf, 32'hxxxxxxxx, dat);
  $display("UART_RX = %c (0x%02x)", dat, dat);
  repeat(5000) @ (posedge CLK);
  ctrl_regs_cycle(32'h00800014, 1'b0, 4'hf, 32'hxxxxxxxx, dat);
  $display("UART_STAT = 0x%02x", dat, dat);
  repeat(5000) @ (posedge CLK);
  ctrl_regs_cycle(32'h0080000c, 1'b1, 4'hf, 32'h000000ab);
  ctrl_regs_cycle(32'h0080000c, 1'b1, 4'hf, 32'h000000ba);
  repeat(5000) @ (posedge CLK);
  ctrl_regs_cycle(32'h00800014, 1'b0, 4'hf, 32'hxxxxxxxx, dat);
  $display("UART_STAT = 0x%02x", dat, dat);
  repeat(5000) @ (posedge CLK);
  ctrl_regs_cycle(32'h00800010, 1'b0, 4'hf, 32'hxxxxxxxx, dat);
  $display("UART_RX = %c (0x%02x)", dat, dat);
  repeat(5000) @ (posedge CLK);
  ctrl_regs_cycle(32'h00800014, 1'b0, 4'hf, 32'hxxxxxxxx, dat);
  $display("UART_STAT = 0x%02x", dat, dat);

  // wait
  repeat(10000) @ (posedge CLK);

  // display result
  if (ERR) $display("BENCH : %t : ctrl test FAILED - there were errors!", $time);
  else     $display("BENCH : %t : ctrl test PASSED - no errors!", $time);

  $display("BENCH : done.");
  $finish;
end



////////////////////////////////////////
// tasks                              //
////////////////////////////////////////

// ram_write
task ram_write;
  integer i;
  reg [32-1:0] dat;
begin
  for (i=0; i<4096; i=i+1) begin
    if (MEM[i] !== 32'hxxxxxxxx) begin
      dat = MEM[i];
      ctrl_tb.ram.bank1[2*i + 0] = dat[31:24];
      ctrl_tb.ram.bank0[2*i + 0] = dat[23:16];
      ctrl_tb.ram.bank1[2*i + 1] = dat[15: 8];
      ctrl_tb.ram.bank0[2*i + 1] = dat[ 7: 0];
    end
  end
end
endtask

// force ctrl regs bus
task ctrl_regs_cycle;
input  [32-1:0] adr;
input           we;
input  [ 4-1:0] sel;
input  [32-1:0] dat_w;
output [32-1:0] dat_r;
begin
  @ (posedge ctrl_top.clk); #1;
  force ctrl_top.ctrl_regs.adr   = adr;
  force ctrl_top.ctrl_regs.cs    = 1'b1;
  force ctrl_top.ctrl_regs.we    = we;
  force ctrl_top.ctrl_regs.sel   = sel;
  force ctrl_top.ctrl_regs.dat_w = dat_w;
  @ (posedge ctrl_top.clk); #1;
  while (!ctrl_top.ctrl_regs.ack) @ (posedge ctrl_top.clk); #1;
  release ctrl_top.ctrl_regs.adr;
  release ctrl_top.ctrl_regs.cs;
  release ctrl_top.ctrl_regs.we;
  release ctrl_top.ctrl_regs.sel;
  release ctrl_top.ctrl_regs.dat_w;
  @ (posedge ctrl_top.clk); #1;
  dat_r = ctrl_top.ctrl_regs.dat_r;
end
endtask




////////////////////////////////////////
// ctrl module                        //
////////////////////////////////////////

wire [ 16-1:0] SRAM_DAT_W;
wire [ 16-1:0] SRAM_DAT_R;
assign SRAM_DQ = SRAM_OE_N ? SRAM_DAT_W : 16'bzzzzzzzzzzzzzzzz;
assign SRAM_DAT_R = SRAM_DQ;

wire [  8-1:0] FL_DAT_W;
wire [  8-1:0] FL_DAT_R;
assign FL_DQ = FL_OE_N ? FL_DAT_W : 8'bzzzzzzzz;
assign FL_DAT_R = FL_DQ;

ctrl_top ctrl_top (
  // system
  .clk_in       (CLK        ),
  .rst_ext      (RST        ),
  .clk_out      (           ),
  .rst_out      (           ),
  .rst_minimig  (           ),
  // config
  .boot_sel     (BOOT_SEL   ),
  .ctrl_cfg     (CTRL_CFG   ),
  // status
  .rom_status   (           ),
  .ram_status   (           ),
  .reg_status   (           ),
  .ctrl_status  (CTRL_STATUS),
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
  .uart_rxd     (UART_TXD   ), // LOOPBACK!
  .spi_cs_n     (SPI_CS_N   ),
  .spi_clk      (SD_CLK     ),
  .spi_do       (SD_CMD     ),
  .spi_di       (SD_DAT     )
);



////////////////////////////////////////
// models                             //
////////////////////////////////////////

// UART model
// TODO


// SRAM model
IS61LV6416L #(
  .memdepth (262144),
  .addbits  (18)
) ram (
  .A            (SRAM_ADDR  ),
  .IO           (SRAM_DQ    ),
  .CE_          (SRAM_CE_N  ),
  .OE_          (SRAM_OE_N  ),
  .WE_          (SRAM_WE_N  ),
  .LB_          (SRAM_LB_N  ),
  .UB_          (SRAM_UB_N  )
);


// FLASH model
s29al032d_00 #(
  .UserPreload (1'b1),
  .mem_file_name("../../../../fw/ctrl_boot/bin/ctrl_boot.hex")
) rom (
  .A21          (FL_ADDR[21]),
  .A20          (FL_ADDR[20]),
  .A19          (FL_ADDR[19]),
  .A18          (FL_ADDR[18]),
  .A17          (FL_ADDR[17]),
  .A16          (FL_ADDR[16]),
  .A15          (FL_ADDR[15]),
  .A14          (FL_ADDR[14]),
  .A13          (FL_ADDR[13]),
  .A12          (FL_ADDR[12]),
  .A11          (FL_ADDR[11]),
  .A10          (FL_ADDR[10]),
  .A9           (FL_ADDR[09]),
  .A8           (FL_ADDR[08]),
  .A7           (FL_ADDR[07]),
  .A6           (FL_ADDR[06]),
  .A5           (FL_ADDR[05]),
  .A4           (FL_ADDR[04]),
  .A3           (FL_ADDR[03]),
  .A2           (FL_ADDR[02]),
  .A1           (FL_ADDR[01]),
  .A0           (FL_ADDR[00]),
  .DQ7          (FL_DQ[7]   ),
  .DQ6          (FL_DQ[6]   ),
  .DQ5          (FL_DQ[5]   ),
  .DQ4          (FL_DQ[4]   ),
  .DQ3          (FL_DQ[3]   ),
  .DQ2          (FL_DQ[2]   ),
  .DQ1          (FL_DQ[1]   ),
  .DQ0          (FL_DQ[0]   ),
  .CENeg        (FL_CE_N    ),
  .OENeg        (FL_OE_N    ),
  .WENeg        (FL_WE_N    ),
  .RESETNeg     (FL_RST_N   ),
  .ACC          (1'b0       ),
  .RY           (           )
);


// SDCARD model
sd_card #(
  .FNAME  ("../../../../sd32MBNP.img")
) sdcard (
  .sck          (SD_CLK     ),
  .ss           (SPI_CS_N   ),
  .mosi         (SD_CMD     ),
  .miso         (SD_DAT     )
);


endmodule

