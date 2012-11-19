/* or1200_top_wrapper.b */

// only removes all un-needed signals

module or1200_top_wrapper #(
  parameter AW = 24
)(
  // system
  input wire            clk,
  input wire            rst,
  // data bus
  output wire           dcpu_cs,
  output wire           dcpu_we,
  output wire [  4-1:0] dcpu_sel,
  output wire [ AW-1:0] dcpu_adr,
  output wire [ 32-1:0] dcpu_dat_w,
  input  wire [ 32-1:0] dcpu_dat_r,
  input  wire           dcpu_ack,
  // instruction bus
  output wire           icpu_cs,
  output wire           icpu_we,
  output wire [  4-1:0] icpu_sel,
  output wire [ AW-1:0] icpu_adr,
  output wire [ 32-1:0] icpu_dat_w,
  input  wire [ 32-1:0] icpu_dat_r,
  input  wire           icpu_ack
);

// icpu_we is always 0
assign icpu_we = 1'b0;

// icpu_sel is always all-ones
assign icpu_sel = 4'b1111;

// icpu_dat_w is don't care
assign icpu_dat_w = 32'hxxxxxxxx;

// cut address to desired width
wire [ 32-1:0] iadr;
wire [ 32-1:0] dadr;
assign dcpu_adr = dadr[AW-1:0];
assign icpu_adr = iadr[AW-1:0];

// OR1200 cpu
or1200_top or1200 (
  // system
  .clk_i                  (clk),
  .rst_i                  (rst),
  .clmode_i               (2'b00),
  .pic_ints_i             (4'b0000),
  // Instruction wishbone
  .iwb_clk_i              (1'b0),
  .iwb_rst_i              (1'b1),
  .iwb_ack_i              (1'b0),
  .iwb_err_i              (1'b0),
  .iwb_rty_i              (1'b0),
  .iwb_dat_i              (32'h00000000),
  .iwb_cyc_o              (),
  .iwb_adr_o              (),
  .iwb_stb_o              (),
  .iwb_we_o               (),
  .iwb_sel_o              (),
  .iwb_dat_o              (),
//  .iwb_cab_o              (),
//  .iwb_cti_o              (),
//  .iwb_bte_o              (),
  // Data wishbone
  .dwb_clk_i              (1'b0),
  .dwb_rst_i              (1'b1),
  .dwb_ack_i              (1'b0),
  .dwb_err_i              (1'b0),
  .dwb_rty_i              (1'b0),
  .dwb_dat_i              (32'h00000000),
  .dwb_cyc_o              (),
  .dwb_adr_o              (),
  .dwb_stb_o              (),
  .dwb_we_o               (),
  .dwb_sel_o              (),
  .dwb_dat_o              (),
//  .dwb_cab_o              (),
//  .dwb_cti_o              (),
//  .dwb_bte_o              (),
  // Debug interface
  .dbg_stall_i            (1'b0),
  .dbg_ewt_i              (1'b0),
  .dbg_lss_o              (),
  .dbg_is_o               (),
  .dbg_wp_o               (),
  .dbg_bp_o               (),
  .dbg_stb_i              (1'b0),
  .dbg_we_i               (1'b0),
  .dbg_adr_i              (32'h00000000),
  .dbg_dat_i              (32'h00000000),
  .dbg_dat_o              (),
  .dbg_ack_o              (),
  // QMEM interface
  .dqmem_ce_o             (dcpu_cs),
  .dqmem_we_o             (dcpu_we),
  .dqmem_sel_o            (dcpu_sel),
  .dqmem_addr_o           (dadr),
  .dqmem_do_o             (dcpu_dat_w),
  .dqmem_di_i             (dcpu_dat_r),
  .dqmem_ack_i            (dcpu_ack && dcpu_cs),
  .iqmem_ce_o             (icpu_cs),
  .iqmem_sel_o            (),
  .iqmem_addr_o           (iadr),
  .iqmem_di_i             (icpu_dat_r),
  .iqmem_ack_i            (icpu_ack && icpu_cs),
  // Power management
  .pm_cpustall_i          (1'b0),
  .pm_clksd_o             (),
  .pm_dc_gate_o           (),
  .pm_ic_gate_o           (),
  .pm_dmmu_gate_o         (),
  .pm_immu_gate_o         (),
  .pm_tt_gate_o           (),
  .pm_cpu_gate_o          (),
  .pm_wakeup_o            (),
  .pm_lvolt_o             ()
);

endmodule

