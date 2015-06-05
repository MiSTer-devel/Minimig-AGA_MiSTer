// cpu / cache / sdram testbench
// 2013, rok.krajnc@gmail.com


`default_nettype none
`timescale 1ns/1ps

`define SOC_SIM

// use real TG68 or sim
`define USE_TG68


//// module ////
module cpu_cache_sdram_tb();


//// internal signals ////

// data reg
reg  [16-1:0] dat;

// DE1 clocks
wire          CLOCK24;
wire          CLOCK27;
wire          CLOCK50;
wire          CLOCKEXT;
wire          RST;

// amiga_clk
wire          clk_114;
wire          clk_sdram;
wire          clk_28;
wire          clk_7;
wire          clk7_en;
wire          c1;
wire          c3;
wire          cck;
wire [10-1:0] eclk;
wire          pll_locked;

// SDRAM
wire [ 16-1:0] DRAM_DQ;
wire [ 12-1:0] DRAM_ADDR;
wire           DRAM_LDQM;
wire           DRAM_UDQM;
wire           DRAM_WE_N;
wire           DRAM_CAS_N;
wire           DRAM_RAS_N;
wire           DRAM_CS_N;
wire           DRAM_BA_0;
wire           DRAM_BA_1;
wire           DRAM_CLK;
wire           DRAM_CKE;

// SDRAM controller
wire          sdctl_rst;
wire          reset_out;
wire [ 3-1:0] cctrl;
wire [ 4-1:0] sdram_cs;
wire [ 2-1:0] sdram_ba;
wire [ 2-1:0] sdram_dqm;
wire [22-1:0] bridge_adr;
wire          bridge_cs;
wire          bridge_we;
wire [ 2-1:0] bridge_sel;
wire [16-1:0] bridge_dat_w;
wire [16-1:0] bridge_dat_r;
wire          bridge_ack;
wire          bridge_err;
wire [16-1:0] ram_data;
wire [22-1:1] ram_address;
wire          _ram_bhe;
wire          _ram_ble;
wire          _ram_we;
wire          _ram_oe;
wire [16-1:0] ramdata_in;

// TG68
`ifdef USE_TG68
wire [32-1:0] tg68_cad;
wire [ 6-1:0] tg68_cpustate;
wire          tg68_clds;
wire          tg68_cuds;
wire          tg68_cdma;
wire [16-1:0] tg68_cout;
wire          tg68_enaWR;
wire          tg68_ena7RD;
wire          tg68_ena7WR;
wire          tg68_cpuena;
wire          tg68_rst;
wire [ 3-1:0] tg68_IPL;
wire          tg68_dtack;
wire [32-1:0] tg68_adr;
wire [16-1:0] tg68_dat_in;
wire [16-1:0] tg68_dat_out;
wire          tg68_as;
wire          tg68_uds;
wire          tg68_lds;
wire          tg68_rw;
wire [ 2-1:0] cpu_config;
wire          turbochipram;
wire [ 6-1:0] memcfg;
wire          tg68_ovr;
wire [32-1:0] tg68_VBRout;
`else
reg  [32-1:0] tg68_cad=0;
reg  [ 6-1:0] tg68_cpustate=6'b000001;
reg           tg68_clds=1;
reg           tg68_cuds=1;
reg           tg68_cdma=0;
wire [16-1:0] tg68_cout;
wire          tg68_enaWR;
wire          tg68_ena7RD;
wire          tg68_ena7WR;
wire          tg68_cpuena;
wire          tg68_rst;
wire [ 3-1:0] tg68_IPL;
reg           tg68_dtack=0;
reg  [32-1:0] tg68_adr=0;
reg  [16-1:0] tg68_dat_in=0;
reg  [16-1:0] tg68_dat_out=0;
reg           tg68_as=0;
reg           tg68_uds=0;
reg           tg68_lds=0;
reg           tg68_rw=0;
wire [ 2-1:0] cpu_config;
wire          turbochipram;
wire [ 6-1:0] memcfg;
reg  [32-1:0] tg68_VBRout=0;
`endif


//// toplevel logic ////
assign sdctl_rst = pll_locked;
assign cctrl = 3'b111;

assign bridge_cs = 1'b0;
assign bridge_adr = 22'd0;
assign bridge_we = 1'b0;
assign bridge_sel = 2'd0;
assign bridge_dat_w = 16'd0;

assign ram_address = 21'd0;
assign ram_data = 16'd0;
assign _ram_bhe = 1'b1;
assign _ram_ble = 1'b1;
assign _ram_we = 1'b1;
assign _ram_oe = 1'b1;

assign tg68_rst = ~RST; // TODO
assign tg68_IPL = 3'b111;

assign cpu_config = 2'b11;
assign turbochipram = 1'b1;
assign memcfg = 6'b110000;
assign tg68_ovr = 1'b0;

assign DRAM_CKE  = 1'b1;
assign DRAM_CLK  = clk_sdram;
assign DRAM_CS_N = sdram_cs[0];
assign DRAM_LDQM = sdram_dqm[0];
assign DRAM_UDQM = sdram_dqm[1];
assign DRAM_BA_0 = sdram_ba[0];
assign DRAM_BA_1 = sdram_ba[1];


//// testbench ////
initial begin
  $display ("* BENCH : starting ...");
  #1;

`ifdef USE_TG68
  tg68_ram.load("../../../../bench/cpu_cache_sdram/fw/test.hex");
  $display ("* BENCH : RAM loaded ...");
`endif

  wait(pll_locked);
  $display ("* BENCH : PLL started ...");
  wait(reset_out);
  $display("* BENCH : SDRAM ready ...");

`ifdef USE_TG68

  // TODO
  repeat (4000) @ (posedge clk_28);

`else

  // single writes / reads
  tg68_write(32'h00000000, 2'b11, 16'h0123);
  tg68_read (32'h00000000, dat);
  tg68_write(32'h00000002, 2'b11, 16'h4567);
  tg68_read (32'h00000002, dat);
  tg68_write(32'h00000004, 2'b11, 16'h0123);
  tg68_read (32'h00000004, dat);
  tg68_write(32'h00000006, 2'b11, 16'h4567);
  tg68_read (32'h00000006, dat);
  tg68_write(32'h00000008, 2'b11, 16'h0123);
  tg68_read (32'h00000008, dat);
  tg68_write(32'h0000000a, 2'b11, 16'h4567);
  tg68_read (32'h0000000a, dat);
  tg68_write(32'h0000000c, 2'b11, 16'h0123);
  tg68_read (32'h0000000c, dat);
  tg68_write(32'h0000000e, 2'b11, 16'h4567);
  tg68_read (32'h0000000e, dat);

`endif

  // end bench
  repeat (20) @ (posedge clk_28);
  $display("* BENCH : done.");
  $finish();
end


//// tasks ////
`ifndef USE_TG68
// tg68_write
task tg68_write;
  input  [31:0] adr;
  input  [ 1:0] bs;
  input  [15:0] dat;
begin
  @ (posedge clk_114); #1;
  tg68_cpustate = 2'b11;
  tg68_cuds = ~bs[1];
  tg68_clds = ~bs[0];
  tg68_cad  = adr;
  tg68_dat_out = dat;
  repeat(1) @ (posedge clk_114); #1;
  while(!tg68_cpuena) begin
    @ (posedge clk_114); #1;
  end
  tg68_cpustate = 2'b01;
  tg68_cuds = 1'b1;
  tg68_clds = 1'b1;
  tg68_cad = 32'hxxxxxxxx;
  tg68_dat_out = 16'hxxxx;
  repeat(24) @ (posedge clk_114); #1;
end
endtask

// tg68_read
task tg68_read;
  input  [31:0] adr;
  output [15:0] dat;
begin
  @ (posedge clk_114); #1;
  tg68_cpustate = 2'b00;
  tg68_cuds = 1'b0;
  tg68_clds = 1'b0;
  tg68_cad  = adr;
  repeat(1) @ (posedge clk_114); #1;
  while(!tg68_cpuena) begin
    @ (posedge clk_114); #1;
  end
  tg68_cpustate = 2'b01;
  tg68_cuds = 1'b1;
  tg68_clds = 1'b1;
  tg68_cad = 32'hxxxxxxxx;
  dat = tg68_cout;
  repeat(24) @ (posedge clk_114); #1;
end
endtask
`endif


//// modules ////

// DE1 clocks
de1_clk_rst clk_rst (
  .CLOCK24  (CLOCK24  ),
  .CLOCK27  (CLOCK27  ),
  .CLOCK50  (CLOCK50  ),
  .CLOCKEXT (CLOCKEXT ),
  .RST      (RST      )
);

// internal clocks
amiga_clk amiga_clk (
  .rst          (1'b0             ), // async reset input
  .clk_in       (CLOCK27          ), // input clock     ( 27.000000MHz)
  .clk_114      (clk_114          ), // output clock c0 (114.750000MHz)
  .clk_sdram    (clk_sdram        ), // output clock c2 (114.750000MHz, -146.25 deg)
  .clk_28       (clk_28           ), // output clock c1 ( 28.687500MHz)
  .clk_7        (clk_7            ), // output clock 7  (  7.171875MHz)
  .clk7_en      (clk7_en          ), // output clock 7 enable (on 28MHz clock domain)
  .c1           (c1               ), // clk28m clock domain signal synchronous with clk signal
  .c3           (c3               ), // clk28m clock domain signal synchronous with clk signal delayed by 90 degrees
  .cck          (cck              ), // colour clock output (3.54 MHz)
  .eclk         (eclk             ), // 0.709379 MHz clock enable output (clk domain pulse)
  .locked       (pll_locked       )  // pll locked output
);

`ifdef USE_TG68
// tg68k
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
  .turbochipram (turbochipram     ),
  .fastramcfg   ({&memcfg[5:4],memcfg[5:4]}),
  .ovr          (tg68_ovr         ),
  .ramaddr      (tg68_cad         ),
  .cpustate     (tg68_cpustate    ),
  .nResetOut    (                 ),
  .skipFetch    (                 ),
  .cpuDMA       (tg68_cdma        ),
  .ramlds       (tg68_clds        ),
  .ramuds       (tg68_cuds        ),
  .VBR_out      (tg68_VBRout      )
);

// generic memory
tg68_ram tg68_ram (
  .clk          (clk_114          ),
  .tg68_dtack   (tg68_dtack       ), 
  .tg68_adr     (tg68_adr         ),
  .tg68_dat_in  (tg68_dat_in      ),
  .tg68_dat_out (tg68_dat_out     ), 
  .tg68_as      (tg68_as          ),
  .tg68_uds     (tg68_uds         ),
  .tg68_lds     (tg68_lds         ),
  .tg68_rw      (tg68_rw          )
);
`endif

// SDRAM controller
sdram_ctrl sdram_ctrl (
  // sys
  .sysclk       (clk_114          ),
  .c_7m         (clk_7            ),
  .reset_in     (sdctl_rst        ),
  .cache_rst    (tg68_rst         ),
  .reset_out    (reset_out        ),
  // sdram
  .sdaddr       (DRAM_ADDR        ),
  .sd_cs        (sdram_cs         ),
  .ba           (sdram_ba         ),
  .sd_we        (DRAM_WE_N        ),
  .sd_ras       (DRAM_RAS_N       ),
  .sd_cas       (DRAM_CAS_N       ),
  .dqm          (sdram_dqm        ),
  .sdata        (DRAM_DQ          ),
  // host
  .hostWR       (bridge_dat_w     ),
  .hostAddr     ({2'b00, bridge_adr}),
  .hostState    ({1'b0, 2'b01}    ),
  .hostL        (!bridge_sel[0]   ),
  .hostU        (!bridge_sel[1]   ),
  .hostRD       (bridge_dat_r     ),
  .hostena      (bridge_ack       ),
  // chip
  .chipAddr     ({2'b00, ram_address[21:1]}),
  .chipL        (_ram_ble         ),
  .chipU        (_ram_bhe         ),
  .chipRW       (_ram_we          ),
  .chip_dma     (_ram_oe          ),
  .chipWR       (ram_data         ),
  .chipRD       (ramdata_in       ),
  .chip48       (                 ),
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

// SDRAM
mt48lc16m16a2 #(
  .tAC  (5.4),
  .tHZ  (5.4),
  .tOH  (2.5),
  .tMRD (2.0),    // 2 Clk Cycles
  .tRAS (40.0),
  .tRC  (58.0),
  .tRCD (18.0),
  .tRFC (60.0),
  .tRP  (18.0),
  .tRRD (12.0),
  .tWRa (7.0),     // A2 Version - Auto precharge mode (1 Clk + 7 ns)
  .tWRm (14.0)    // A2 Version - Manual precharge mode (14 ns)
) sdram (
  .Dq         (DRAM_DQ),
  .Addr       (DRAM_ADDR),
  .Ba         ({DRAM_BA_1, DRAM_BA_0}),
  .Clk        (DRAM_CLK),
  .Cke        (DRAM_CKE),
  .Cs_n       (DRAM_CS_N),
  .Ras_n      (DRAM_RAS_N),
  .Cas_n      (DRAM_CAS_N),
  .We_n       (DRAM_WE_N),
  .Dqm        ({DRAM_UDQM, DRAM_LDQM})
);


endmodule

