/********************************************/
/* sync_fifo.v                              */
/* simple single-clock fifo                 */
/*                                          */
/* 2011, rok.krajnc@gmail.com               */
/********************************************/


module sync_fifo #(
  parameter FD    = 16,               // fifo depth
  parameter DW    = 32                // data width
)(
  // system
  input  wire           clk,          // clock
  input  wire           clk7_en,      // 7MHz clock enable
  input  wire           rst,          // reset
  // fifo input / output
  input  wire [ DW-1:0] fifo_in,      // write data
  output wire [ DW-1:0] fifo_out,     // read data
  // fifo control
  input  wire           fifo_wr_en,   // fifo write enable
  input  wire           fifo_rd_en,   // fifo read enable
  // fifo status
  output wire           fifo_full,    // fifo full
  output wire           fifo_empty    // fifo empty
);



////////////////////////////////////////
// log function                       //
////////////////////////////////////////

function integer CLogB2;
  input [31:0] d;
  integer i;
begin
  i = d;
  for(CLogB2 = 0; i > 0; CLogB2 = CLogB2 + 1) i = i >> 1;
end
endfunction



////////////////////////////////////////
// local parameters                   //
////////////////////////////////////////

localparam FCW = CLogB2(FD-1) + 1;
localparam FPW = CLogB2(FD-1);



////////////////////////////////////////
// local signals                      //
////////////////////////////////////////

// fifo counter
reg  [FCW-1:0] fifo_cnt;

// fifo write & read pointers
reg  [FPW-1:0] fifo_wp, fifo_rp;

// fifo memory
reg  [ DW-1:0] fifo_mem [0:FD-1];



////////////////////////////////////////
// logic                              //
////////////////////////////////////////

// FIFO write pointer
always @ (posedge clk or posedge rst) begin
  if (rst)
    fifo_wp <= #1 1'b0;
  else if (clk7_en) begin
    if (fifo_wr_en && !fifo_full)
      fifo_wp <= #1 fifo_wp + 1'b1;
  end
end


// FIFO write
always @ (posedge clk) begin
  if (clk7_en) begin
    if (fifo_wr_en && !fifo_full) fifo_mem[fifo_wp] <= #1 fifo_in;
  end
end


// FIFO counter
always @ (posedge clk or posedge rst) begin
  if (rst)
    fifo_cnt <= #1 'd0;
  // read & no write
  else if (clk7_en) begin
    if (fifo_rd_en && !fifo_wr_en && (fifo_cnt != 'd0))
      fifo_cnt <= #1 fifo_cnt - 'd1;
    // write & no read
    else if (fifo_wr_en && !fifo_rd_en && (fifo_cnt != FD))
      fifo_cnt <= #1 fifo_cnt + 'd1;
  end
end


// FIFO full & empty
assign fifo_full  = (fifo_cnt == (FD));
assign fifo_empty = (fifo_cnt == 'd0);


// FIFO read pointer
always @ (posedge clk or posedge rst) begin
  if (rst)
    fifo_rp <= #1 1'b0;
  else if (clk7_en) begin
    if (fifo_rd_en && !fifo_empty)
      fifo_rp <= #1 fifo_rp + 1'b1;
  end
end


// FIFO read
assign fifo_out = fifo_mem[fifo_rp];


endmodule

