/* qmem_decoder.v */

module qmem_decoder #(
  parameter QAW = 32,     // address width
  parameter QDW = 32,     // data width
  parameter QSW = QDW/8,  // byte select width
  parameter SN  = 2       // number of slaves
)(
  // system
  input  wire              clk,
  input  wire              rst,
  // slave port for requests from masters
  input  wire              qm_cs,
  input  wire              qm_we,
  input  wire    [QAW-1:0] qm_adr,
  input  wire    [QSW-1:0] qm_sel,
  input  wire    [QDW-1:0] qm_dat_w,
  output wire    [QDW-1:0] qm_dat_r,
  output wire              qm_ack,
  output wire              qm_err,
  // master port for requests to a slave
  output wire [SN    -1:0] qs_cs,
  output wire [SN    -1:0] qs_we,
  output wire [SN*QAW-1:0] qs_adr,
  output wire [SN*QSW-1:0] qs_sel,
  output wire [SN*QDW-1:0] qs_dat_w,
  input  wire [SN*QDW-1:0] qs_dat_r,
  input  wire [SN    -1:0] qs_ack,
  input  wire [SN    -1:0] qs_err,
  // one hot slave select signal
  input  wire [SN    -1:0] ss
);


// this code is written for up to 8 slaves
wire [7:0] ss_a;
reg  [7:0] ss_r;

generate if (SN == 1) assign ss_a =                                                         0; endgenerate
generate if (SN == 2) assign ss_a =                                                 ss[1]?1:0; endgenerate
generate if (SN == 3) assign ss_a =                                         ss[2]?2:ss[1]?1:0; endgenerate
generate if (SN == 4) assign ss_a =                                 ss[3]?3:ss[2]?2:ss[1]?1:0; endgenerate
generate if (SN == 5) assign ss_a =                         ss[4]?4:ss[3]?3:ss[2]?2:ss[1]?1:0; endgenerate
generate if (SN == 6) assign ss_a =                 ss[5]?5:ss[4]?4:ss[3]?3:ss[2]?2:ss[1]?1:0; endgenerate
generate if (SN == 7) assign ss_a =         ss[6]?6:ss[5]?5:ss[4]?4:ss[3]?3:ss[2]?2:ss[1]?1:0; endgenerate
generate if (SN == 8) assign ss_a = ss[7]?7:ss[6]?6:ss[5]?5:ss[4]?4:ss[3]?3:ss[2]?2:ss[1]?1:0; endgenerate

always @ (posedge clk)
if (qm_cs & (qm_ack | qm_err) & ~qm_we)  ss_r <= #1 ss_a;

genvar i;

// master port for requests to a slave
generate for (i=0; i<SN; i=i+1) begin : loop_select
  assign qs_cs    [     i                   ] = qm_cs & ss [i];
  assign qs_we    [     i                   ] = qm_we;
  assign qs_adr   [QAW*(i+1)-1:QAW*(i+1)-QAW] = qm_adr;
  assign qs_sel   [QSW*(i+1)-1:QSW*(i+1)-QSW] = qm_sel;
  assign qs_dat_w [QDW*(i+1)-1:QDW*(i+1)-QDW] = qm_dat_w;
end endgenerate

// slave port for requests from masters
assign qm_dat_r = qs_dat_r >> (QDW*ss_r);
assign qm_ack   = qs_ack   >>      ss_a ;
assign qm_err   = qs_err   >>      ss_a ;


endmodule

