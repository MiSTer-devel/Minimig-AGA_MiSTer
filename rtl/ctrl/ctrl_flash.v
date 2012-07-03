/********************************************/
/* ctrl_flash.v                             */
/* FLASH controller                         */
/*                                          */
/* 2012, rok.krajnc@gmail.com               */
/********************************************/


// TODO support writes


module ctrl_flash #(
  parameter FAW = 22,             // flash address width
  parameter FDW = 8,              // flash data width
  parameter QAW = 22,             // qmem address width
  parameter QDW = 32,             // qmem data width
  parameter QSW = QDW/8,          // qmem select width
  parameter DLY = 3,              // 80ns delay @ 50MHz clock - for S29AL032D70 (70ns access part) //// if 3 isn't enough, try 4 ////
  parameter BE  = 1               // big endianness - 1 = big endian, 2 = little endian
)(
  // system
  input  wire           clk,
  input  wire           rst,
  // config
  input  wire           boot_sel,
  // qmem interface
  input  wire [QAW-1:0] adr,
  input  wire           cs,
  input  wire           we,
  input  wire [QSW-1:0] sel,
  input  wire [QDW-1:0] dat_w,
  output reg  [QDW-1:0] dat_r,
  output reg            ack,
  output wire           err,
  // flash interface
  output reg  [FAW-1:0] fl_adr,
  output reg            fl_ce_n,
  output reg            fl_we_n,
  output reg            fl_oe_n,
  output reg            fl_rst_n,
  output wire [FDW-1:0] fl_dat_w,
  input  wire [FDW-1:0] fl_dat_r
);



////////////////////////////////////////
// keep flash in read state           //
////////////////////////////////////////

reg            nce;
reg            nwe;
reg            noe;
reg            nrst;

always @ (posedge clk, posedge rst) begin
  if (rst) begin
    fl_ce_n  <= #1 1'b1;
    fl_we_n  <= #1 1'b1;
    fl_oe_n  <= #1 1'b0;
    fl_rst_n <= #1 1'b0;
  end else begin
    fl_ce_n  <= #1 1'b0;
    fl_we_n  <= #1 1'b1; // !we;
    fl_oe_n  <= #1 1'b0; // we;
    fl_rst_n <= #1 1'b1;
  end
end



////////////////////////////////////////
// read engine                        //
////////////////////////////////////////

// TODO faster byte / half-word reads (using byte selects)

// read timer
reg            timer_start;
reg  [  2-1:0] timer;

always @ (posedge clk, posedge rst) begin
  if (rst)
    timer <= #1 2'h0;
  else if (timer_start)
    timer <= #1 DLY-1;
  else if (|timer)
    timer <= #1 timer - 2'h1;
end


// state machine
localparam S_ID = 3'h0;
localparam S_R1 = 3'h4;
localparam S_R2 = 3'h5;
localparam S_R3 = 3'h6;
localparam S_R4 = 3'h7;

reg  [   3-1:0] state;

// this is QMEM compatible - ack is one cycle before data gets read, for WISHBONE compatibility, move ack one clock later
always @ (posedge clk, posedge rst) begin
  if (rst) begin
    state <= #1 S_ID;
    timer_start <= #1 1'b0;
    ack <= #1 1'b0;
  end else begin
    if (timer_start) timer_start <= #1 1'b0;
    case (state)
      S_ID : begin
        if (cs) begin
          fl_adr <= #1 {boot_sel^adr[21], adr[20:2], 2'b00};
          timer_start <= #1 1'b1;
          state <= #1 S_R1;
        end
      end
      S_R1 : begin
        if ((~|timer) && !timer_start) begin
          fl_adr <= #1 {boot_sel^adr[21], adr[20:2], 2'b01};
          timer_start <= #1 1'b1;
          state <= #1 S_R2;
          if (BE == 1)
            dat_r[31:24] <= #1 fl_dat_r;
          else
            dat_r[ 7: 0] <= #1 fl_dat_r;
        end
      end
      S_R2 : begin
        if ((~|timer) && !timer_start) begin
          fl_adr <= #1 {boot_sel^adr[21], adr[20:2], 2'b10};
          timer_start <= #1 1'b1;
          state <= #1 S_R3;
          if (BE == 1)
            dat_r[23:16] <= #1 fl_dat_r;
          else
            dat_r[15: 8] <= #1 fl_dat_r;
        end
      end
      S_R3 : begin
        if ((~|timer) && !timer_start) begin
          fl_adr <= #1 {boot_sel^adr[21], adr[20:2], 2'b11};
          timer_start <= #1 1'b1;
          state <= #1 S_R4;
          if (BE == 1)
            dat_r[15: 8] <= #1 fl_dat_r;
          else
            dat_r[23:16] <= #1 fl_dat_r;
        end
      end
      S_R4 : begin
        if (timer == 2'h1) begin
          ack <= #1 1'b1;
        end
        if ((~|timer) && !timer_start) begin
          state <= #1 S_ID;
          ack <= #1 1'b0;
          if (BE == 1)
            dat_r[ 7: 0] <= #1 fl_dat_r;
          else
            dat_r[31:24] <= #1 fl_dat_r;
        end
      end
    endcase
  end
end



////////////////////////////////////////
// unused outputs                     //
////////////////////////////////////////

assign err      = 1'b0;
assign fl_dat_w = 8'hxx;



endmodule

