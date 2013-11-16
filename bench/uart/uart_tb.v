// uart_tb.v
// 2013, rok.krajnc@gmail.com


`timescale 1ns/10ps

`define CLK_HPER 20

module uart_tb();

reg clk;
reg rst;

localparam REG_SERDAT  = 9'h030;
localparam REG_SERDATR = 9'h018;
localparam REG_SERPER  = 9'h032;

reg  [  8-1:0] v_adr;
reg  [ 16-1:0] v_dat_w;
wire [ 16-1:0] v_dat_r;
reg            v_uartbrk;
reg            v_rbfmirror;
wire           v_txint;
wire           v_rxint;
wire           v_txd;
wire           v_rxd;

reg  [  8-1:0] vv_adr;
reg  [ 16-1:0] vv_dat_w;
wire [ 16-1:0] vv_dat_r;
reg            vv_uartbrk;
reg            vv_rbfmirror;
wire           vv_txint;
wire           vv_rxint;
wire           vv_txd;
wire           vv_rxd;

reg  [  9-1:1] o_adr;
reg  [ 16-1:0] o_dat_w;
wire [ 16-1:0] o_dat_r;
reg            o_rbfmirror;
wire           o_txint;
wire           o_rxint;
wire           o_txd;
wire           o_rxd;

reg  [  8-1:0] vhd_adr;
reg  [ 16-1:0] vhd_dat_w;
wire [ 16-1:0] vhd_dat_r;
reg            vhd_uartbrk;
reg            vhd_rbfmirror;
wire           vhd_txint;
wire           vhd_rxint;
wire           vhd_txd;
wire           vhd_rxd;

reg  [  8-1:0] vh_adr;
reg  [ 16-1:0] vh_dat_w;
wire [ 16-1:0] vh_dat_r;
reg            vh_uartbrk;
reg            vh_rbfmirror;
wire           vh_txint;
wire           vh_rxint;
wire           vh_txd;
wire           vh_rxd;

reg  [  8-1:0] adr;
reg  [ 16-1:0] dat_w;

//// clock & reset ////
initial begin
  clk = 1'b1;
  forever #`CLK_HPER clk = ~clk;
end

initial begin
  rst = 1'b1;
  repeat(10) @ (posedge clk); #1;
  rst = 1'b0;
end


//// testbench ////
initial begin
  // initial conditions
  v_adr         = 0;
  v_dat_w       = 0;
  v_uartbrk     = 0;
  v_rbfmirror   = 0;
  vv_adr        = 0;
  vv_dat_w      = 0;
  vv_uartbrk    = 0;
  vv_rbfmirror  = 0;
  o_adr         = 0;
  o_dat_w       = 0;
  o_rbfmirror   = 0;
  vhd_adr       = 0;
  vhd_dat_w     = 0;
  vhd_uartbrk   = 0;
  vhd_rbfmirror = 0;
  vh_adr        = 0;
  vh_dat_w      = 0;
  vh_uartbrk    = 0;
  vh_rbfmirror  = 0;

  // wait for rst
  wait(!rst);
  @ (posedge clk); #1;

  // write period register
  @ (posedge clk); #1;
  adr     = REG_SERPER[8:1];
  dat_w   = 16'h0010;
  @ (posedge clk); #1;
  adr     = 'd0;
  dat_w   = 'd0;

  // read serdatr register
  @ (posedge clk); #1;
  adr     = REG_SERDATR[8:1];
  dat_w   = 16'hxxxx;
  @ (posedge clk); #1;
  adr     = 'd0;
  dat_w   = 'd0;

  // write serdat register
  @ (posedge clk); #1;
  adr     = REG_SERDAT[8:1];
  dat_w   = 16'h01aa;
  @ (posedge clk); #1;
  @ (posedge clk); #1;
  adr     = 'd0;
  dat_w   = 'd0;

  // wait for rxint
  //wait(v_rxint);
  repeat (500) @ (posedge clk); #1;

  // read serdatr register
  @ (posedge clk); #1;
  adr     = REG_SERDATR[8:1];
  dat_w   = 16'hxxxx;
  @ (posedge clk); #1;
  adr     = 'd0;
  dat_w   = 'd0;

  // write period register - set long bit
  @ (posedge clk); #1;
  adr     = REG_SERPER[8:1];
  dat_w   = 16'h8010;
  @ (posedge clk); #1;
  adr     = 'd0;
  dat_w   = 'd0;

  // read serdatr register
  @ (posedge clk); #1;
  adr     = REG_SERDATR[8:1];
  dat_w   = 16'hxxxx;
  @ (posedge clk); #1;
  adr     = 'd0;
  dat_w   = 'd0;

  // write serdat register
  @ (posedge clk); #1;
  adr     = REG_SERDAT[8:1];
  dat_w   = 16'h03aa;
  @ (posedge clk); #1;
  @ (posedge clk); #1;
  adr     = 'd0;
  dat_w   = 'd0;

  // wait for rxint
  //wait(v_rxint);
  repeat (500) @ (posedge clk); #1;

  // read serdatr register
  @ (posedge clk); #1;
  adr     = REG_SERDATR[8:1];
  dat_w   = 16'hxxxx;
  @ (posedge clk); #1;
  adr     = 'd0;
  dat_w   = 'd0;

  repeat (100) @ (posedge clk); #1;
  $finish;
end


//// rbfmirror ////
always @ (posedge clk, posedge rst) begin
  if (rst) begin
    v_rbfmirror   <= #1 1'b0;
    vv_rbfmirror  <= #1 1'b0;
    vhd_rbfmirror <= #1 1'b0;
  end else begin
    if (v_rxint)   v_rbfmirror   <= #1 1'b1;
    if (vv_rxint)  vv_rbfmirror  <= #1 1'b1;
    if (vhd_rxint) vhd_rbfmirror <= #1 1'b1;
  end
end


//// verilog module ////
uart_verilog uart_verilog (
  .clk        (clk          ),
  .reset      (rst          ),
  .rga_i      (adr          ),
  .data_i     (dat_w        ),
  .data_o     (v_dat_r      ),
  .uartbrk    (v_uartbrk    ),
  .rbfmirror  (v_rbfmirror  ),
  .txint      (v_txint      ),
  .rxint      (v_rxint      ),
  .txd        (v_txd        ),
  .rxd        (v_rxd        )
);


//// verilog module ////
uart_verilog uart_verilog2 (
  .clk        (clk          ),
  .reset      (rst          ),
  .rga_i      (adr          ),
  .data_i     (dat_w        ),
  .data_o     (vv_dat_r     ),
  .uartbrk    (vv_uartbrk   ),
  .rbfmirror  (vv_rbfmirror ),
  .txint      (vv_txint     ),
  .rxint      (vv_rxint     ),
  .txd        (v_rxd        ),
  .rxd        (vh_txd       )
);


//// old uart ////
uart_old uart_old (
  .clk        (clk          ),
  .reset      (rst          ),
  .reg_address_in (adr          ),
  .data_in    (dat_w        ),
  .data_out   (o_dat_r      ),
  .rbfmirror  (o_rbfmirror  ),
  .txint      (o_txint      ),
  .rxint      (o_rxint      ),
  .txd        (o_txd        ),
  .rxd        (vh_txd       )
);


//// VHDL module ////
uart uart_vhdl (
  .clk        (clk          ),
  .reset      (rst          ),
  .rga_i      (adr          ),
  .data_i     (dat_w        ),
  .data_o     (vhd_dat_r    ),
  .uartbrk    (vhd_uartbrk  ),
  .rbfmirror  (vhd_rbfmirror),
  .txint      (vhd_txint    ),
  .rxint      (vhd_rxint    ),
  .txd        (vhd_txd      ),
  .rxd        (vh_txd       )
);


//// VHDL module ////
uart uart_vhdl_master (
  .clk        (clk          ),
  .reset      (rst          ),
  .rga_i      (adr          ),
  .data_i     (dat_w        ),
  .data_o     (vh_dat_r     ),
  .uartbrk    (vh_uartbrk   ),
  .rbfmirror  (vh_rbfmirror ),
  .txint      (vh_txint     ),
  .rxint      (vh_rxint     ),
  .txd        (vh_txd       ),
  .rxd        (vhd_txd      )
);




endmodule

