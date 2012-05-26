/********************************************/
/* qmem_bus.v                               */
/* QMEM interconnect                        */
/*                                          */
/* 2012, rok.krajnc@gmail.com               */
/********************************************/


//// slave address map ////
// 0 - (0x000000 - 0x3fffff) adr[23:22] == 2'b00 - RAM
// 1 - (0x400000 - 0x7fffff) adr[23:22] == 2'b01 - ROM
// 2 - (0x800000 - 0xbfffff) adr[23:22] == 2'b10 - REGS
// 3 - (0xc00000 - 0xffffff) adr[23:22] == 2'b11 - N.A.


module qmem_bus #(
  parameter MAW = 24,             // master address width
  parameter SAW = 22,             // slave address width
  parameter QDW = 32,             // data width
  parameter QSW = QDW/8           // select width
)(
  // system
  input  wire           clk,
  input  wire           rst,

  // master 0 (dcpu)
  input  wire [MAW-1:0] m0_adr,
  input  wire           m0_cs,
  input  wire           m0_we,
  input  wire [QSW-1:0] m0_sel,
  input  wire [QDW-1:0] m0_dat_w,
  output wire [QDW-1:0] m0_dat_r,
  output wire           m0_ack,
  output wire           m0_err,
  // master 1 (icpu)
  input  wire [MAW-1:0] m1_adr,
  input  wire           m1_cs,
  input  wire           m1_we,
  input  wire [QSW-1:0] m1_sel,
  input  wire [QDW-1:0] m1_dat_w,
  output wire [QDW-1:0] m1_dat_r,
  output wire           m1_ack,
  output wire           m1_err,

  // slave 0 (ram)
  output wire [SAW-1:0] s0_adr,
  output wire           s0_cs,
  output wire           s0_we,
  output wire [QSW-1:0] s0_sel,
  output wire [QDW-1:0] s0_dat_w,
  input  wire [QDW-1:0] s0_dat_r,
  input  wire           s0_ack,
  input  wire           s0_err,
  // slave 1 (rom)
  output wire [SAW-1:0] s1_adr,
  output wire           s1_cs,
  output wire           s1_we,
  output wire [QSW-1:0] s1_sel,
  output wire [QDW-1:0] s1_dat_w,
  input  wire [QDW-1:0] s1_dat_r,
  input  wire           s1_ack,
  input  wire           s1_err,
  // slave 2 (regs)
  output wire [SAW-1:0] s2_adr,
  output wire           s2_cs,
  output wire           s2_we,
  output wire [QSW-1:0] s2_sel,
  output wire [QDW-1:0] s2_dat_w,
  input  wire [QDW-1:0] s2_dat_r,
  input  wire           s2_ack,
  input  wire           s2_err
);


// no. of masters
localparam MN = 2;

// no. of slaves
localparam SN = 3;



//// MASTERS ////

////////////////////////////////////////
// Master 0 (dcpu)                    //
// connects to: s0 (ram)              //
//              s1 (rom)              //
//              s2 (regs)             // 
////////////////////////////////////////
wire [MAW-1:0] m0_s0_adr   , m0_s1_adr   , m0_s2_adr  ;
wire           m0_s0_cs    , m0_s1_cs    , m0_s2_cs   ;
wire           m0_s0_we    , m0_s1_we    , m0_s2_we   ;
wire [QSW-1:0] m0_s0_sel   , m0_s1_sel   , m0_s2_sel  ;
wire [QDW-1:0] m0_s0_dat_w , m0_s1_dat_w , m0_s2_dat_w;
wire [QDW-1:0] m0_s0_dat_r , m0_s1_dat_r , m0_s2_dat_r;
wire           m0_s0_ack   , m0_s1_ack   , m0_s2_ack  ;
wire           m0_s0_err   , m0_s1_err   , m0_s2_err  ;

localparam M0_SN = 3;
wire [M0_SN-1:0] m0_ss;
wire m0_s0_select, m0_s1_select, m0_s2_select;

assign m0_s0_select = (m0_adr[23:22] == 2'b00); // ~(|m0_adr[32:22])
assign m0_s1_select = (m0_adr[23:22] == 2'b01); // m0_adr[22]
assign m0_s2_select = (m0_adr[23:22] == 2'b10); // m0_adr[23]
assign m0_ss = {m0_s2_select, m0_s1_select, m0_s0_select};

// m0 decoder
qmem_decoder #(
  .QAW    (MAW),
  .QDW    (QDW),
  .QSW    (QSW),
  .SN     (M0_SN)
) m0_decoder (
  // system
  .clk      (clk),
  .rst      (rst),
  // slave port for requests from masters
  .qm_cs    (m0_cs),
  .qm_we    (m0_we),
  .qm_sel   (m0_sel),
  .qm_adr   (m0_adr),
  .qm_dat_w (m0_dat_w),
  .qm_dat_r (m0_dat_r),
  .qm_ack   (m0_ack),
  .qm_err   (m0_err),
  // master port for requests to a slave
  .qs_cs    ({m0_s2_cs   , m0_s1_cs   , m0_s0_cs   }),
  .qs_we    ({m0_s2_we   , m0_s1_we   , m0_s0_we   }),
  .qs_sel   ({m0_s2_sel  , m0_s1_sel  , m0_s0_sel  }),
  .qs_adr   ({m0_s2_adr  , m0_s1_adr  , m0_s0_adr  }),
  .qs_dat_w ({m0_s2_dat_w, m0_s1_dat_w, m0_s0_dat_w}),
  .qs_dat_r ({m0_s2_dat_r, m0_s1_dat_r, m0_s0_dat_r}),
  .qs_ack   ({m0_s2_ack  , m0_s1_ack  , m0_s0_ack  }),
  .qs_err   ({m0_s2_err  , m0_s1_err  , m0_s0_err  }),
  // one hot slave select signal
  .ss       (m0_ss)
);

 
////////////////////////////////////////
// Master 1 (icpu)                    //
// connects to: s0 (ram)              //
////////////////////////////////////////
wire [MAW-1:0] m1_s0_adr   ;
wire           m1_s0_cs    ;
wire           m1_s0_we    ;
wire [QSW-1:0] m1_s0_sel   ;
wire [QDW-1:0] m1_s0_dat_w ;
wire [QDW-1:0] m1_s0_dat_r ;
wire           m1_s0_ack   ;
wire           m1_s0_err   ;

assign m1_s0_adr    = m1_adr;
assign m1_s0_cs     = m1_cs;
assign m1_s0_we     = m1_we;
assign m1_s0_sel    = m1_sel;
assign m1_s0_dat_w  = m1_dat_w;
assign m1_dat_r     = m1_s0_dat_r;
assign m1_ack       = m1_s0_ack;
assign m1_err       = m1_s0_err;



//// SLAVES ////

////////////////////////////////////////
// Slave 0 (ram)                      //
// masters:     m0 (dcpu)             //
//              m1 (icpu)             //
////////////////////////////////////////

localparam S0_MN = 2;
wire [S0_MN-1:0] s0_ms;

// s0 arbiter
qmem_arbiter #(
  .QAW    (SAW),
  .QDW    (QDW),
  .QSW    (QSW),
  .MN     (S0_MN)
) s0_arbiter (
  // system
  .clk      (clk),
  .rst      (rst),
  // slave port for requests from masters
  .qm_cs    ({m1_s0_cs   , m0_s0_cs   }),
  .qm_we    ({m1_s0_we   , m0_s0_we   }),
  .qm_sel   ({m1_s0_sel  , m0_s0_sel  }),
  .qm_adr   ({m1_s0_adr[SAW-1:0]  , m0_s0_adr[SAW-1:0]  }),
  .qm_dat_w ({m1_s0_dat_w, m0_s0_dat_w}),
  .qm_dat_r ({m1_s0_dat_r, m0_s0_dat_r}),
  .qm_ack   ({m1_s0_ack  , m0_s0_ack  }),
  .qm_err   ({m1_s0_err  , m0_s0_err  }),
  // master port for requests to a slave
  .qs_cs    (s0_cs),
  .qs_we    (s0_we),
  .qs_sel   (s0_sel),
  .qs_adr   (s0_adr),
  .qs_dat_w (s0_dat_w),
  .qs_dat_r (s0_dat_r),
  .qs_ack   (s0_ack),
  .qs_err   (s0_err),
  // one hot master (bit MN is always 1'b0)
  .ms       (s0_ms)
);


////////////////////////////////////////
// Slave 1 (rom)                      //
// masters:     m0 (dcpu)             //
////////////////////////////////////////

assign s1_adr   = m0_s1_adr[SAW-1:0]  ;
assign s1_cs    = m0_s1_cs   ;
assign s1_we    = m0_s1_we   ;
assign s1_sel   = m0_s1_sel  ;
assign s1_dat_w = m0_s1_dat_w;
assign m0_s1_dat_r = s1_dat_r;
assign m0_s1_ack   = s1_ack  ;
assign m0_s1_err   = s1_err  ;


////////////////////////////////////////
// Slave 2 (regs)                     //
// masters:     m0 (dcpu)             //
////////////////////////////////////////

assign s2_adr   = m0_s2_adr[SAW-1:0]  ;
assign s2_cs    = m0_s2_cs   ;
assign s2_we    = m0_s2_we   ;
assign s2_sel   = m0_s2_sel  ;
assign s2_dat_w = m0_s2_dat_w;
assign m0_s2_dat_r = s2_dat_r;
assign m0_s2_ack   = s2_ack  ;
assign m0_s2_err   = s2_err  ;



endmodule

