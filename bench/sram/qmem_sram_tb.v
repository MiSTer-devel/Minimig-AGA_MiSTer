// qmem_sram_tb.v
// 2013, rok.krajnc@gmail.com


`timescale 1ns/10ps


module qmem_sram_tb();

//// parameters ////
parameter QAW = 32;     // qmem adr width
parameter QDW = 32;     // qmem dat width
parameter QSW = QDW/8;  // qmem sel width
parameter AD  = 10;     // allowed delay for qmem slave


//// internal signals ////
reg             clk50;
reg             clk100;
reg             rst;

wire            mcs;
wire            mwe;
wire [QSW-1:0]  msel;
wire [QAW-1:0]  madr;
wire [QDW-1:0]  mdat_r;
wire [QDW-1:0]  mdat_w;
wire            mack;
wire            merr;
wire            error;

wire [ 18-1:0]  SRAM_ADDR;
wire            SRAM_CE_N;
wire            SRAM_WE_N;
wire            SRAM_UB_N;
wire            SRAM_LB_N;
wire            SRAM_OE_N;
wire [ 16-1:0]  SRAM_DAT_W;
wire [ 16-1:0]  SRAM_DAT_R;
wire [ 16-1:0]  SRAM_DQ;

reg  [QDW-1:0]  q_dat;
reg  [QAW-1:0]  q_adr;
reg  [QSW-1:0]  q_sel;


//// bench ////

// clock & reset
initial begin
  clk50   = 1;
  forever #10 clk50  = ~clk50;
end

initial begin
  clk100  = 1;
  forever #5  clk100 = ~clk100;
end

initial begin
  rst = 1;
  #101;
  rst = 0;
end


// bench
initial begin
  $display("* BENCH : Starting ...");

  #1;
  wait(rst);
  repeat (10) @ (posedge clk100);
  #1;

  // qmem master cycles
  qmem_master.write(32'h00000000, 4'b1111, 32'h00000000);
  qmem_master.read (32'h00000000, 4'b1111, q_dat);

  qmem_master.write(32'h00000010, 4'b1111, 32'h00010001);
  qmem_master.write(32'h00000014, 4'b1111, 32'h00010002);
  qmem_master.write(32'h00000018, 4'b1111, 32'h00010003);
  qmem_master.write(32'h0000001c, 4'b1111, 32'h00010004);
  qmem_master.read (32'h00000010, 4'b1111, q_dat);
  qmem_master.read (32'h00000014, 4'b1111, q_dat);
  qmem_master.read (32'h00000018, 4'b1111, q_dat);
  qmem_master.read (32'h0000001c, 4'b1111, q_dat);

  qmem_master.read (32'h00000010, 4'b1111, q_dat);
  qmem_master.write(32'h00000010, 4'b1111, 32'h00010001);


  // read, write 0xdeadbeef to 0x0
  q_dat = 32'hdeadbeef;
  q_adr = 32'h00000000;
  q_sel = 4'b1111;
  qmem_master.write(q_adr, q_sel, q_dat);
  q_dat = 32'h00000000;
  qmem_master.read(q_adr, q_sel, q_dat);
  if (q_dat != 32'hdeadbeef) begin
    $display ("* BENCH : Error reading / writing 0x%08x to address 0x%08x !!!", q_dat, q_adr);
    #100;
    $finish(0);
  end

  // read, write 0x12345678 to 0x4
  q_dat = 32'h12345678;
  q_adr = 32'h00000004;
  q_sel = 4'b0011;
  qmem_master.write(q_adr, q_sel, q_dat);
  q_dat = 32'h00000000;
  qmem_master.read(q_adr, q_sel, q_dat);
  if (q_dat != 32'h12zz5678) begin
    $display ("* BENCH : Error reading / writing 0x%08x to address 0x%08x !!!", q_dat, q_adr);
    #100;
    $finish(0);
  end

  repeat (10) @ (posedge clk50);

  $display("* BENCH : Done.");
  $finish;

end


//// modules ////

// QMEM master
qmem_master #(
  .QAW  (QAW),
  .QDW  (QDW),
  .QSW  (QSW),
  .AD   (AD)
) qmem_master (
  .clk        (clk50      ),
  .rst        (rst        ),
  .cs         (mcs        ),
  .we         (mwe        ),
  .sel        (msel       ),
  .adr        (madr       ),
  .dat_o      (mdat_w     ),
  .dat_i      (mdat_r     ),
  .ack        (mack       ),
  .err        (merr       ),
  .error      (error      )
);

// QMEM SRAM bridge
qmem_sram #(
  .AW (32),
  .DW (32),
  .SW (4)
) bridge (
  // system signals
  .clk50      (clk50      ),
  .clk100     (clk100     ),
  .rst        (rst        ),
  // qmem bus
  .adr        (madr       ),
  .cs         (mcs        ),
  .we         (mwe        ),
  .sel        (msel       ),
  .dat_w      (mdat_w     ),
  .dat_r      (mdat_r     ),
  .ack        (mack       ),
  .err        (merr       ),
  // SRAM interface
  .sram_adr   (SRAM_ADDR  ),
  .sram_ce_n  (SRAM_CE_N  ),
  .sram_we_n  (SRAM_WE_N  ),
  .sram_ub_n  (SRAM_UB_N  ),
  .sram_lb_n  (SRAM_LB_N  ),
  .sram_oe_n  (SRAM_OE_N  ),
  .sram_dat_w (SRAM_DAT_W ),
  .sram_dat_r (SRAM_DAT_R )
);

// SRAM data tristate drivers
assign SRAM_DQ = SRAM_OE_N ? SRAM_DAT_W : 16'bzzzzzzzzzzzzzzzz;
assign SRAM_DAT_R = SRAM_DQ;

// SRAM model
IS61LV6416L #(
  .memdepth (262144),
  .addbits  (18)
) ram (
  .A          (SRAM_ADDR  ),
  .IO         (SRAM_DQ    ),
  .CE_        (SRAM_CE_N  ),
  .OE_        (SRAM_OE_N  ),
  .WE_        (SRAM_WE_N  ),
  .LB_        (SRAM_LB_N  ),
  .UB_        (SRAM_UB_N  )
);


endmodule

