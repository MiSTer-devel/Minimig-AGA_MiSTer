/********************************************/
/* ctrl_flash.v                             */
/* FLASH controller                         */
/*                                          */
/* 2012, rok.krajnc@gmail.com               */
/********************************************/


module ctrl_flash #(
  parameter FAW = 22,             // flash address width
  parameter FDW = 8,              // flash data width
  parameter QAW = 22,             // qmem address width
  parameter QDW = 32,             // qmem data width
  parameter QSW = QDW/8,          // qmem select width
  parameter DLY = 4               // delay - for S29AL032D70 (70ns access part)
)(
  // system
  input  wire           clk,
  input  wire           rst,
  // qmem interface
  input  wire [QAW-1:0] adr,
  input  wire           cs,
  input  wire           we,
  input  wire [QSW-1:0] sel,
  input  wire [QDW-1:0] dat_w,
  output wire [QDW-1:0] dat_r,
  output wire           ack,
  output wire           err,
  // flash interface
  output reg  [FAW-1:0] fl_adr,
  output wire           fl_ce_n,
  output wire           fl_we_n,
  output wire           fl_oe_n,
  output wire           fl_rst_n,
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
    nce  <= #1 1'b1;
    nwe  <= #1 1'b1;
    noe  <= #1 1'b0;
    nrst <= #1 1'b0;
  end else begin
    nce  <= #1 1'b0;
    nwe  <= #1 1'b1;
    noe  <= #1 1'b0;
    nrst <= #1 1'b1;
  end
end



////////////////////////////////////////
// read engine                        //
////////////////////////////////////////

// TODO faster byte / half-word reads

// detect cs posedge
reg            cs_d;
always @ (posedge clk, posedge rst) begin
  if (rst)
    cs_d <= #1 1'b0;
  else
    cs_d <= #1 cs;
end

wire           cs_pos;
assign cs_pos = !cs_d && cs;


// read timer
reg            timer_start;
reg  [  2-1:0] timer;

always @ (posedge clk, posedge rst) begin
  if (rst)
    timer <= #1 2'h0;
  else if (timer_start)
    timer <= #1 DLY-1;
  else if (timer != 2'h0)
    timer <= #1 timer - 2'h1;
end


// state machine
reg  [ QDW-1:0] fl_dat;
reg             fl_ack;

localparam S_ID = 3'h0;
localparam S_R1 = 3'h4;
localparam S_R1 = 3'h5;
localparam S_R1 = 3'h6;
localparam S_R1 = 3'h7;

reg  [   3-1:0] state;

always @ (posedge clk, posedge rst) begin
  if (rst) begin
    state <= #1 S_ID;
    timer_start <= #1 1'b0;
    fl_ack <= #1 1'b0;
  end else begin
    if (timer_start) timer_start <= #1 1'b0;
    case (state)
      S_ID : begin
        fl_ack <= #1 1'b0;
        if (cs_pos) begin
          fl_adr <= #1 {adr[21:2], 2'b00};
          timer_start <= #1 1'b1;
          state <= #1 S_R1;
        end
      end
      S_R1 : begin
        if ((~|timer) && !timer_start) begin
          fl_adr <= #1 {adr[21:2], 2'b01};
          timer_start <= #1 #1 1'b1;
          state <= #1 S_R2;
          fl_dat[31:24] <= #1 fl_dat_r;
        end
      end
      S_R2 : begin
        if ((~|timer) && !timer_start) begin
          fl_adr <= #1 {adr[21:2], 2'b10};
          timer_start <= #1 #1 1'b1;
          state <= #1 S_R3;
          fl_dat[23:16] <= #1 fl_dat_r;
        end
      end
      S_R3 : begin
        if ((~|timer) && !timer_start) begin
          fl_adr <= #1 {adr[21:2], 2'b11};
          timer_start <= #1 #1 1'b1;
          state <= #1 S_R4;
          fl_dat[15:8] <= #1 fl_dat_r;
        end
      end
      S_R4 : begin
        if ((~|timer) && !timer_start) begin
          state <= #1 S_ID;
          fl_dat[7:0] <= #1 fl_dat_r;
          fl_ack <= #1 1'b1;
        end
      end
    endcase
  end
end



////////////////////////////////////////
// outputs                            //
////////////////////////////////////////

assign dat_r       = fl_dat;
assign ack         = fl_ack;
assign err         = 1'b0;

assign fl_dat_w = 8'hxx;
assign fl_ce_n  = nce;
assign fl_we_n  = nwe;
assign fl_oe_n  = noe;
assign fl_rst_n = nrst;



endmodule

