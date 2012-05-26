/* qmem_arbiter.v */

module qmem_arbiter #(
  parameter QAW = 32,     // address width
  parameter QDW = 32,     // data width
  parameter QSW = QDW/8,  // byte select width
  parameter MN  = 2       // number of masters
)(
  // system
  input  wire              clk,
  input  wire              rst,
  // slave port for requests from masters
  input  wire [MN    -1:0] qm_cs,
  input  wire [MN    -1:0] qm_we,
  input  wire [MN*QSW-1:0] qm_sel,
  input  wire [MN*QAW-1:0] qm_adr,
  input  wire [MN*QDW-1:0] qm_dat_w,
  output wire [MN*QDW-1:0] qm_dat_r,
  output wire [MN    -1:0] qm_ack,
  output wire [MN    -1:0] qm_err,
  // master port for requests to a slave
  output wire              qs_cs,
  output wire              qs_we,
  output wire    [QSW-1:0] qs_sel,
  output wire    [QAW-1:0] qs_adr,
  output wire    [QDW-1:0] qs_dat_w,
  input  wire    [QDW-1:0] qs_dat_r,
  input  wire              qs_ack,
  input  wire              qs_err,
  // one hot master status (bit MN is always 1'b0)
  output wire     [MN-1:0] ms
);


wire     [3:0] ms_a;
wire  [MN-1:0] ms_tmp;
reg   [MN-1:0] ms_reg;

genvar i;

// masters priority decreases from the LSB to the MSB side
assign ms_tmp[0] = qm_cs[0];
generate for (i=1; i<MN; i=i+1) begin : loop_arbiter
  assign ms_tmp[i] = qm_cs[i] & ~|qm_cs[i-1:0];
end endgenerate

always @(posedge clk, posedge rst) begin
  if (rst)                   ms_reg <= #1 0;
  else if (qs_ack | qs_err)  ms_reg <= #1 0;
  else if (!(|ms_reg))       ms_reg <= #1 ms_tmp;
end

assign ms = |ms_reg ? ms_reg : ms_tmp;

generate if (MN == 1) assign ms_a =                                                         0; endgenerate
generate if (MN == 2) assign ms_a =                                                 ms[1]?1:0; endgenerate
generate if (MN == 3) assign ms_a =                                         ms[2]?2:ms[1]?1:0; endgenerate
generate if (MN == 4) assign ms_a =                                 ms[3]?3:ms[2]?2:ms[1]?1:0; endgenerate
generate if (MN == 5) assign ms_a =                         ms[4]?4:ms[3]?3:ms[2]?2:ms[1]?1:0; endgenerate
generate if (MN == 6) assign ms_a =                 ms[5]?5:ms[4]?4:ms[3]?3:ms[2]?2:ms[1]?1:0; endgenerate
generate if (MN == 7) assign ms_a =         ms[6]?6:ms[5]?5:ms[4]?4:ms[3]?3:ms[2]?2:ms[1]?1:0; endgenerate
generate if (MN == 8) assign ms_a = ms[7]?7:ms[6]?6:ms[5]?5:ms[4]?4:ms[3]?3:ms[2]?2:ms[1]?1:0; endgenerate

// slave port for requests from masters
assign qs_cs    = qm_cs    >>      ms_a ;
assign qs_we    = qm_we    >>      ms_a ;
assign qs_sel   = qm_sel   >> (QSW*ms_a);
assign qs_adr   = qm_adr   >> (QAW*ms_a);
assign qs_dat_w = qm_dat_w >> (QDW*ms_a);

// master ports for requests to a slave
generate for (i=0; i<MN; i=i+1) begin : loop_bus
  assign qm_dat_r [QDW*(i+1)-1:QDW*(i+1)-QDW] = qs_dat_r;
end endgenerate

// one hot is a bit of overkill for register
assign qm_ack = ms & {MN{qs_ack}};
assign qm_err = ms & {MN{qs_err}};


endmodule

