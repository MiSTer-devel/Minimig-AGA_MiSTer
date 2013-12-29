`define QMEM_MASTER_DEBUG

module qmem_master #(
  parameter QAW = 32,   // address width
  parameter QDW = 32,   // data width
  parameter QSW = QDW/8, // select width
  parameter AD = 10    // allowed delay for ack
)(
  // system signals
  input wire clk, rst,
  // qmem interface
  output reg            cs,
  output reg            we,
  output reg  [QSW-1:0] sel,
  output reg  [QAW-1:0] adr,
  output reg  [QDW-1:0] dat_o,
  input  wire [QDW-1:0] dat_i,
  input  wire           ack,
  input  wire           err,
  // error
  output reg            error
);


// initial settings
initial begin
  cs    = 1'b0;
  we    = 1'bx;
  sel   = {QSW{1'bx}};
  adr   = {QAW{1'bx}};
  dat_o = {QDW{1'bx}};

  error = 1'b0;
end


// tasks

//wait ack task
task wait_ack;
  integer cnt;
begin
  cnt = 0;
  while (!(ack | err)) begin
    if (cnt == AD) begin
      $display("ERROR : QMEM_MASTER : acknowledge delay longer than %01d (instance \"%m\", at time %t) !!!", AD, $time);
      error = 1;
      $finish(1);
    end
    cnt = cnt + 1;
    @(posedge clk);
  end
end
endtask

// write task
task write (
  input  [QAW-1:0] madr,
  input  [QSW-1:0] msel,
  input  [QDW-1:0] mdat
);
begin
  @(posedge clk);
  #1;
  cs    = 1'b1;
  we    = 1'b1;
  adr   = madr;
  sel   = msel;
  dat_o = mdat;
  @(posedge clk);
  // wait for answer
  wait_ack;
  #1;
  cs    = 1'b0;
  we    = 1'b0;
  sel   = {QSW{1'bx}};
  adr   = {QAW{1'bx}};
  dat_o = {QDW{1'bx}};
end
endtask

// read task
task read;
  input  [QAW-1:0] madr;
  input  [QSW-1:0] msel;
  output [QDW-1:0] mdat;
begin
  @(posedge clk);
  #1;
  cs    = 1'b1;
  we    = 1'b0;
  adr   = madr;
  sel   = msel;
  @(posedge clk);
  // wait for answer
  wait_ack;
  #1;
  cs    = 1'b0;
  we    = 1'b0;
  sel   = {QSW{1'bx}};
  adr   = {QAW{1'bx}};
  @(posedge clk);
  #1;
  mdat  = dat_i;
end
endtask

// write mulitple task
task write_multiple;
  parameter IW = 2;
  input  [IW*QAW-1:0] madr;
  input  [IW*QSW-1:0] msel;
  input  [IW*QDW-1:0] mdat;
  integer            i;
begin
  @(posedge clk);
  #1;
  for(i = 0; i < IW; i = i + 1) begin
    cs    = 1'b1;
    we    = 1'b1;
    sel   = msel[QSW*i +:QSW];
    adr   = madr[QAW*i +:QAW];
    dat_o = mdat[QDW*i +:QDW];
    @(posedge clk);
    // wait for answer
    wait_ack;
    #1;
  end
  cs    = 1'b0;
  we    = 1'b0;
  sel   = {QSW{1'bx}};
  adr   = {QAW{1'bx}};
  dat_o = {QDW{1'bx}};
end
endtask     

// read multiple task
task read_multiple;
  parameter IW = 2;
  input  [IW*QAW-1:0] madr;
  input  [IW*QSW-1:0] msel;
  output [IW*QDW-1:0] mdat;
  integer            i;
begin
  @(posedge clk);
  #1;
  for (i = 0; i < IW; i = i + 1) begin
    cs    = 1'b1;
    we    = 1'b0;
    adr   = madr[QAW*i +:QAW];
    sel   = msel[QSW*i +:QSW];
    @(posedge clk);
    // wait for answer
    wait_ack;
    #1;
    cs    = 1'b0;  // TODO : this should be fixed for real concurrent read accesses, next address should be appplied immidiately after ack, in the read cycle!
    we    = 1'b0;
    @(posedge clk);
    #1;
    mdat[QDW*i +:QDW] = dat_i;
  end
  cs    = 1'b0;
  we    = 1'b0;
  sel   = {QSW{1'bx}};
  adr   = {QAW{1'bx}};
end
endtask

// cycle task
// input (70 bit) :
// name: | cs    | we    | address  | sel     | data     |
// bits: | 69:69 | 68:68 | 67:36    | 35:32   | 31:0     |
// size: | 1     | 1     | 32 (QAW) | 4 (QSW) | 32 (QDW) |
task cycle;
  input [(1 + 1 + QAW + QSW + QDW - 1):0] mdat;
  input last_cycle;
begin
  //@(posedge clk); // bus should be ready here!
  #1;
  cs    = mdat[QDW+QSW+QAW+1:QDW+QSW+QAW+1];
  we    = mdat[QDW+QSW+QAW:QDW+QSW+QAW];
  adr   = mdat[QDW+QSW+QAW-1:QDW+QSW];
  sel   = mdat[QDW+QSW-1:QDW];
  if (mdat[QDW+QSW+QAW:QDW+QSW+QAW] == 1'b1)
    dat_o = mdat[QDW-1:0];
  else
    dat_o = {QDW{1'bx}};
  @(posedge clk);
  if (mdat[QDW+QSW+QAW+1:QDW+QSW+QAW+1] == 1'b1) begin // only wait for ack if cs is HIGH
    wait_ack;
  end
  // leave bus in x state if last cycle
  if (last_cycle == 1) begin
    #1;
    cs    = 0;
    we    = 0;
    adr   = {QAW{1'bx}};
    sel   = {QSW{1'bx}};
    dat_o = {QDW{1'bx}};
  end
end
endtask



endmodule

