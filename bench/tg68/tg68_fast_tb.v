/* tg68_fast_tb.v */


`timescale 1ns/1ps


module tg68_fast_tb();


reg            clk;
reg            rst;

wire           tg68_clk;
wire           tg68_rst;
reg  [  2-1:0] tg68_clk_en;
wire [ 32-1:0] tg68_adr;
wire           tg68_we;
wire           tg68_uds;
wire           tg68_lds;
wire           tg68_r_en;
wire           tg68_w_en;
wire [ 16-1:0] tg68_dat_w;
wire [ 16-1:0] tg68_dat_r;
wire [  3-1:0] tg68_IPL;
wire           tg68_t_IPL;
wire [  2-1:0] tg68_state;
wire           tg68_d_OPC;

wire [ 18-1:0] sram_addr;
wire           sram_ce_n;
wire           sram_oe_n;
wire           sram_we_n;
wire           sram_ub_n;
wire           sram_lb_n;
tri  [ 16-1:0] sram_dq;


//// clock ////
`define CLK_HP 10
initial begin
  clk = 0;
  forever #`CLK_HP clk = ~clk;
end


//// stop ////
initial begin
  $display("TG68_FAST bench starting ...");
  repeat(1000) @ (posedge clk);
  $display("TG68_FAST bench stopping ...");
  $finish;
end


//// ctrl ////
initial begin
  rst = 1;

  $display("TG68_FAST bench : loading firmware ... \n");
  mem_write(18'd00, 16'h0000);
  mem_write(18'd01, 16'h0000);
  mem_write(18'd02, 16'h0000);
  mem_write(18'd03, 16'h0008);

  mem_write(18'd04, 16'h203c);
  mem_write(18'd05, 16'ha0b0);
  mem_write(18'd06, 16'hc0d0);
  mem_write(18'd07, 16'h7600);
  mem_write(18'd08, 16'h7800);
  mem_write(18'd09, 16'h7a00);
  mem_write(18'd10, 16'h7c00);
  mem_write(18'd11, 16'h7e00);

  mem_write(18'd12, 16'h207c);
  mem_write(18'd13, 16'h0000);
  mem_write(18'd14, 16'h0000);
  mem_write(18'd15, 16'h227c);
  mem_write(18'd16, 16'h0000);
  mem_write(18'd17, 16'h0000);
  mem_write(18'd18, 16'h247c);
  mem_write(18'd19, 16'h0000);
  mem_write(18'd20, 16'h0000);
  mem_write(18'd21, 16'h267c);
  mem_write(18'd22, 16'h0000);
  mem_write(18'd23, 16'h0000);
  mem_write(18'd24, 16'h287c);
  mem_write(18'd25, 16'h0000);
  mem_write(18'd26, 16'h0000);
  mem_write(18'd27, 16'h2a7c);
  mem_write(18'd28, 16'h0000);
  mem_write(18'd29, 16'h0000);
  mem_write(18'd30, 16'h2c7c);
  mem_write(18'd31, 16'h0000);
  mem_write(18'd32, 16'h0000);
  mem_write(18'd33, 16'h2e7c);
  mem_write(18'd34, 16'h0000);
  mem_write(18'd35, 16'h0000);

  mem_write(18'd36, 16'hc0bc);
  mem_write(18'd37, 16'h0000);
  mem_write(18'd38, 16'h0000);
  mem_write(18'd39, 16'h5240);
  mem_write(18'd40, 16'h33c0);
  mem_write(18'd41, 16'h00df);
  mem_write(18'd42, 16'hf180);
  mem_write(18'd43, 16'h60f6);
  mem_write(18'd44, 16'h0000);

  repeat(10) @ (posedge clk); #1;
  rst = 0;

end


//// cpu clkena ////
always @ (posedge clk, posedge rst) begin
  if (rst)
    tg68_clk_en <= #1 2'b11;
  else
    tg68_clk_en <= #1 tg68_clk_en - 1;
end


//// mem_write task ////
task mem_write;
  input  [ 18-1:0] adr;
  input  [ 16-1:0] dat;
begin
  @ (posedge clk); #1;
  force tg68_fast_tb.sram_addr = adr;
  force tg68_fast_tb.sram_ce_n = 1'b0;
  force tg68_fast_tb.sram_oe_n = 1'b1;
  force tg68_fast_tb.sram_we_n = 1'b0;
  force tg68_fast_tb.sram_ub_n = 1'b0;
  force tg68_fast_tb.sram_lb_n = 1'b0;
  force tg68_fast_tb.sram_dq   = dat;
  @ (posedge clk); #1;
  release tg68_fast_tb.sram_addr;
  release tg68_fast_tb.sram_ce_n;
  release tg68_fast_tb.sram_oe_n;
  release tg68_fast_tb.sram_we_n;
  release tg68_fast_tb.sram_ub_n;
  release tg68_fast_tb.sram_lb_n;
  release tg68_fast_tb.sram_dq;
end
endtask


//// tg68_fast ////
assign tg68_clk    = clk;
assign tg68_rst    = !rst;
//assign tg68_clk_en = 1'b1;
assign tg68_r_en   = 1'b1;
assign tg68_w_en   = 1'b1;
assign tg68_IPL    = 3'b111;
assign tg68_t_IPL  = 1'b1;
assign tg68_dat_r  = sram_dq;

TG68_fast tg68_fast(
  .clk        (clk),
  .reset      (!rst),
  .clkena_in  (&(~tg68_clk_en)),
  .address    (tg68_adr),
  .wr         (tg68_we),
  .UDS        (tg68_uds),
  .LDS        (tg68_lds),
  .enaRDreg   (tg68_r_en),
  .enaWRreg   (tg68_w_en),
  .data_in    (tg68_dat_r),
  .data_write (tg68_dat_w),
  .IPL        (tg68_IPL),
  .test_IPL   (tg68_t_IPL),
  .state_out  (tg68_state),
  .decodeOPC  (tg68_d_OPC)
);


//// sram ////

assign sram_addr = tg68_adr[18:1];
assign sram_ce_n = 1'b0;
assign sram_oe_n = !tg68_we;
assign sram_we_n = tg68_we;
assign sram_ub_n = tg68_uds;
assign sram_lb_n = tg68_lds;
assign sram_dq   = sram_oe_n ? tg68_dat_w : 16'bzzzzzzzzzzzzzzzz;

IS61LV6416L #(
  .memdepth (262144),
  .addbits  (18)
) sram (
  .A          (sram_addr),
  .IO         (sram_dq),
  .CE_        (sram_ce_n),
  .OE_        (sram_oe_n),
  .WE_        (sram_we_n),
  .LB_        (sram_lb_n),
  .UB_        (sram_ub_n)
);


endmodule

