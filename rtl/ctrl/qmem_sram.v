/********************************************/
/* qmem_sram.v                              */
/* A QMEM (32bit) to SRAM (16bit) interface */
/* Compatible with Altera DE1 board         */
/*                                          */
/* 2010, rok.krajnc@gmail.com               */
/********************************************/


// uncomment this for non-regstered sram interface
//`define QMEM_SRAM_ASYNC
//`define QMEM_SRAM_SLOW


module qmem_sram #(
  parameter AW = 32,
  parameter DW = 32,
  parameter SW = DW/8
)(
  // system signals
  input  wire           clk50,
  input  wire           clk100,
  input  wire           rst,
  // qmem bus
  input  wire [AW-1:0]  adr,
  input  wire           cs,
  input  wire           we,
  input  wire [SW-1:0]  sel,
  input  wire [DW-1:0]  dat_w,
  output reg  [DW-1:0]  dat_r,
  output wire           ack,
  output wire           err,
  // SRAM interface
  output wire [18-1:0]  sram_adr,
  output wire           sram_ce_n,
  output wire           sram_we_n,
  output wire           sram_ub_n,
  output wire           sram_lb_n,
  output wire           sram_oe_n,
  output wire [16-1:0]  sram_dat_w,
  input  wire [16-1:0]  sram_dat_r
);



`ifndef QMEM_SRAM_ASYNC
`ifdef QMEM_SRAM_SLOW
////////////////////////////////////////
// registered outputs variant - slow  //
////////////////////////////////////////

/* state */
localparam S_ID  = 3'b000; // idle
localparam S_HI1 = 3'b011; // first access,  write upper 16 bits
localparam S_HI2 = 3'b111;
localparam S_LO1 = 3'b010; // second access, write lower 16 bits, latch upper 16 bits
localparam S_LO2 = 3'b110;
localparam S_FH  = 3'b001; // last read,                          latch lower 16 bits

reg [2:0] state, next_state;

always @ (*)
begin
  case (state)
    S_ID    : begin if (cs) next_state = S_HI1; else next_state = S_ID; end
    S_HI1   : begin if (cs) next_state = S_HI2; else next_state = S_ID; end
    S_HI2   : begin if (cs) next_state = S_LO1; else next_state = S_ID; end
    S_LO1   : begin if (cs) next_state = S_LO2; else next_state = S_ID; end
    S_LO2   : begin if (cs) next_state = S_FH;  else next_state = S_ID; end
    S_FH    : begin                                  next_state = S_ID; end
    default : begin                                  next_state = S_ID; end
  endcase
end

always @ (posedge clk100 or posedge rst)
begin
  if (rst)
    state <= #1 S_ID;
  else
    state <= #1 next_state;
end


/* output registers */

// address
reg [17:0] s_adr;
always @ (posedge clk100)
begin
  if (next_state == S_HI1)
    s_adr <= #1 {adr[18:2], 1'b0};
  else if (next_state == S_LO1)
    s_adr <= #1 {adr[18:2], 1'b1};
end

// ce_n
reg s_ce_n;
always @ (posedge clk100 or posedge rst)
begin
  if (rst)
    s_ce_n <= #1 1'b1;
  else if ((next_state == S_HI1) || (next_state == S_HI2) || (next_state == S_LO1) || (next_state == S_LO2))
    s_ce_n <= #1 1'b0;
  else
    s_ce_n <= #1 1'b1;
end

// we_n
reg s_we_n;
always @ (posedge clk100)
begin
  if ((next_state == S_HI1) || (next_state == S_HI2) || (next_state == S_LO1) || (next_state == S_LO2))
    s_we_n <= #1 !we;
end

// ub_n & lb_n
reg s_ub_n, s_lb_n;
always @ (posedge clk100)
begin
  if (next_state == S_HI1)
    {s_ub_n, s_lb_n} <= #1 {!sel[3], !sel[2]};
  else if (next_state == S_LO1)
    {s_ub_n, s_lb_n} <= #1 {!sel[1], !sel[0]};
end

// oe_n
reg s_oe_n;
always @ (posedge clk100)
begin
  if ((next_state == S_HI1) || (next_state == S_HI2) || (next_state == S_LO1) || (next_state == S_LO2))
    s_oe_n <= #1 we;
  else
    s_oe_n <= #1 1'b0;
end

// dat_w
reg [15:0] s_dat_w;
always @ (posedge clk100)
begin
  if (next_state == S_HI1)
    s_dat_w <= #1 dat_w[31:16];
  else if (next_state == S_LO1)
    s_dat_w <= #1 dat_w[15:0];
end


/* inputs */

// dat_r
reg [31:0] s_dat_r;
always @ (posedge clk100)
begin
  if ((next_state == S_LO1) && !we)
    dat_r[31:16] <= #1 sram_dat_r;
  else if ((next_state == S_FH) && !we)
    dat_r[15: 0] <= #1 sram_dat_r;
end

// ack
reg s_ack;
always @ (posedge clk100 or posedge rst)
begin
  if (rst)
    s_ack <= #1 1'b0;
  else if ((state == S_LO2) || (state == S_FH))
    s_ack <= #1 1'b1;
  else
    s_ack <= #1 1'b0;
end


/* output assignments */
assign sram_adr   = s_adr;
assign sram_ce_n  = s_ce_n;
assign sram_we_n  = s_we_n;
assign sram_ub_n  = s_ub_n;
assign sram_lb_n  = s_lb_n;
assign sram_oe_n  = s_oe_n;
assign sram_dat_w = s_dat_w;
assign ack        = s_ack;
assign err        = 1'b0;


`else // QMEM_SRAM_SLOW
////////////////////////////////////////
// registered outputs variant - fast  //
////////////////////////////////////////

/* state */
localparam S_ID = 2'b00; // idle
localparam S_HI = 2'b11; // first access,  write upper 16 bits
localparam S_LO = 2'b10; // second access, write lower 16 bits, latch upper 16 bits
localparam S_FH = 2'b01; // last read,                          latch lower 16 bits

reg [1:0] state, next_state;

always @ (*)
begin
  case (state)
    S_ID    : begin if (cs) next_state = S_HI; else next_state = S_ID; end
    S_HI    : begin if (cs) next_state = S_LO; else next_state = S_ID; end
    S_LO    : begin if (cs) next_state = S_FH; else next_state = S_ID; end
    S_FH    : begin                                 next_state = S_ID; end
    default : begin                                 next_state = S_ID; end
  endcase
end

always @ (posedge clk100 or posedge rst)
begin
  if (rst)
    state <= #1 S_ID;
  else
    state <= #1 next_state;
end


/* output registers */

// address
reg [17:0] s_adr;
always @ (posedge clk100)
begin
  if (next_state == S_HI)
    s_adr <= #1 {adr[18:2], 1'b0};
  else if (next_state == S_LO)
    s_adr <= #1 {adr[18:2], 1'b1};
end

// ce_n
reg s_ce_n;
always @ (posedge clk100 or posedge rst)
begin
  if (rst)
    s_ce_n <= #1 1'b1;
  else if ((next_state == S_HI) || (next_state == S_LO))
    s_ce_n <= #1 1'b0;
  else
    s_ce_n <= #1 1'b1;
end

// we_n
reg s_we_n;
always @ (posedge clk100)
begin
  if ((next_state == S_HI) || (next_state == S_LO))
    s_we_n <= #1 !we;
end

// ub_n & lb_n
reg s_ub_n, s_lb_n;
always @ (posedge clk100)
begin
  if (next_state == S_HI)
    {s_ub_n, s_lb_n} <= #1 {!sel[3], !sel[2]};
  else if (next_state == S_LO)
    {s_ub_n, s_lb_n} <= #1 {!sel[1], !sel[0]};
end

// oe_n
reg s_oe_n;
always @ (posedge clk100)
begin
  if ((next_state == S_HI) || (next_state == S_LO))
    s_oe_n <= #1 we;
  else
    s_oe_n <= #1 1'b0;
end

// dat_w
reg [15:0] s_dat_w;
always @ (posedge clk100)
begin
  if (next_state == S_HI)
    s_dat_w <= #1 dat_w[31:16];
  else if (next_state == S_LO)
    s_dat_w <= #1 dat_w[15:0];
end


/* inputs */

// dat_r
reg [31:0] s_dat_r;
always @ (posedge clk100)
begin
  if ((state == S_LO) && !we)
    dat_r[31:16] <= #1 sram_dat_r;
  else if ((state == S_FH) && !we)
    dat_r[15: 0] <= #1 sram_dat_r;
end

// ack
reg s_ack;
always @ (posedge clk100 or posedge rst)
begin
  if (rst)
    s_ack <= #1 1'b0;
  else if (state == S_LO)
    s_ack <= #1 1'b1;
  else
    s_ack <= #1 1'b0;
end


/* output assignments */
assign sram_adr   = s_adr;
assign sram_ce_n  = s_ce_n;
assign sram_we_n  = s_we_n;
assign sram_ub_n  = s_ub_n;
assign sram_lb_n  = s_lb_n;
assign sram_oe_n  = s_oe_n;
assign sram_dat_w = s_dat_w;
assign ack        = s_ack;
assign err        = 1'b0;


`endif // QMEM_SRAM_SLOW
`else // QMEM_SRAM_ASYNC
////////////////////////////////////////
// async outputs variant              //
////////////////////////////////////////


/* local signals */
reg  [ AW-1:0] adr_r;
wire           adr_changed;
reg            cnt;
reg  [ 16-1:0] rdat_r;


/* address change */
always @ (posedge clk50) adr_r <= #1 adr;
assign adr_changed = (adr != adr_r);


/* cs counter */
always @ (posedge clk50 or posedge rst)
begin
  if (rst)
    cnt <= #1 1'b0;
  else if (adr_changed)
    cnt <= #1 1'b0;
  else if (cs)
    cnt <= #1 !cnt;
end


/* read data reg */
always @ (posedge clk50) if (cs && !cnt && !we) rdat_r <= #1 sram_dat_r;


/* qmem outputs */
// TODO dat_r - check if a reg is needed! maybe should use address register!
always @ (posedge clk50) if (cs && cnt && !we) dat_r <= #1 {sram_dat_r, rdat_r};
//assign dat_r = {sram_dat_r, rdat_r};
assign ack = cnt;
assign err = 1'b0;


/* SRAM outputs */
assign sram_adr   = (!cnt) ? {adr[18:2], 1'b0} : {adr[18:2], 1'b1};
assign sram_ce_n  = !cs;
assign sram_we_n  = !we;
assign sram_ub_n  = !((!cnt) ? sel[1] : sel[3]);
assign sram_lb_n  = !((!cnt) ? sel[0] : sel[2]);
assign sram_oe_n  = we;
assign sram_dat_w = (!cnt) ?  dat_w[15:0] : dat_w[31:16];


`endif // QMEM_SRAM_ASYNC


endmodule

