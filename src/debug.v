// debug.v


module debug (
  input  wire           clk,
  input  wire           clk7_en,
  input  wire [  9-1:1] adr,
  input  wire [ 16-1:0] dat
);


`include "regs.vh"


//// local signals ////
wire [236-1:0] reg_sel;


//// rga decode ////
rga_decode rga_decode (
  .adr      (adr),
  .reg_sel  (reg_sel)
);


//// save required regs ////

// BPLCON0
reg           bplcon0_hires /* synthesis syn_noprune */;
reg  [ 4-1:0] bplcon0_bpu /* synthesis syn_noprune */;
reg           bplcon0_ham /* synthesis syn_noprune */;
reg           bplcon0_dpf /* synthesis syn_noprune */;
reg           bplcon0_uhres /* synthesis syn_noprune */;
reg           bplcon0_shres /* synthesis syn_noprune */;
reg           bplcon0_lace /* synthesis syn_noprune */;
reg           bplcon0_ecsena /* synthesis syn_noprune */;

always @ (posedge clk) begin
  if (clk7_en) begin
    if (reg_sel[BPLCON0_REG]) begin
      bplcon0_hires   <= #1 dat[15];
      bplcon0_bpu     <= #1 {dat[4], dat[14:12]};
      bplcon0_ham     <= #1 dat[11];
      bplcon0_dpf     <= #1 dat[10];
      bplcon0_uhres   <= #1 dat[7];
      bplcon0_shres   <= #1 dat[6];
      bplcon0_lace    <= #1 dat[2];
      bplcon0_ecsena  <= #1 dat[0];
    end
  end
end

// BPLCON1
reg  [ 8-1:0] bplcon1_pf1h /* synthesis syn_noprune */;
reg  [ 8-1:0] bplcon1_pf2h /* synthesis syn_noprune */;

always @ (posedge clk) begin
  if (clk7_en) begin
    if (reg_sel[BPLCON1_REG]) begin
      bplcon1_pf1h    <= #1 {dat[11:10], dat[3:0], dat[9:8]};
      bplcon1_pf2h    <= #1 {dat[15:14], dat[7:4], dat[13:12]};
    end
  end
end

// BPLCON2
reg           bplcon2_killehb /* synthesis syn_noprune */;
reg           bplcon2_rdram /* synthesis syn_noprune */;
reg           bplcon2_pf2pri /* synthesis syn_noprune */;
reg  [ 3-1:0] bplcon2_pf2p /* synthesis syn_noprune */;
reg  [ 3-1:0] bplcon2_pf1p /* synthesis syn_noprune */;

always @ (posedge clk) begin
  if (clk7_en) begin
    if (reg_sel[BPLCON2_REG]) begin
      bplcon2_killehb <= #1 dat[9];
      bplcon2_rdram   <= #1 dat[8];
      bplcon2_pf2pri  <= #1 dat[6];
      bplcon2_pf2p    <= #1 dat[5:3];
      bplcon2_pf1p    <= #1 dat[2:0];
    end
  end
end

// BPLCON3
reg  [ 3-1:0] bplcon3_bank /* synthesis syn_noprune */;
reg  [ 3-1:0] bplcon3_pf2of /* synthesis syn_noprune */;
reg           bplcon3_loct /* synthesis syn_noprune */;
reg  [ 2-1:0] bplcon3_spres /* synthesis syn_noprune */;
reg           bplcon3_brdblnk /* synthesis syn_noprune */;
reg           bplcon3_brdsprt /* synthesis syn_noprune */;

always @ (posedge clk) begin
  if (clk7_en) begin
    if (reg_sel[BPLCON3_REG]) begin
      bplcon3_bank    <= #1 dat[15:13];
      bplcon3_pf2of   <= #1 dat[12:10];
      bplcon3_loct    <= #1 dat[9];
      bplcon3_spres   <= #1 dat[7:6];
      bplcon3_brdblnk <= #1 dat[5];
      bplcon3_brdsprt <= #1 dat[1];
    end
  end
end

// BPLCON4
reg  [ 8-1:0] bplcon4_bplam /* synthesis syn_noprune */;
reg  [ 4-1:0] bplcon4_esprm /* synthesis syn_noprune */;
reg  [ 4-1:0] bplcon4_osprm /* synthesis syn_noprune */;

always @ (posedge clk) begin
  if (clk7_en) begin
    if (reg_sel[BPLCON4_REG]) begin
      bplcon4_bplam   <= #1 dat[15:8];
      bplcon4_esprm   <= #1 dat[7:4];
      bplcon4_osprm   <= #1 dat[3:0];
    end
  end
end






endmodule

