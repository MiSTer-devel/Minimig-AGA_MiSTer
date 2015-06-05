// simple ram
// 2014, rok.krajnc@gmail.com


module tg68_ram #(
  parameter MS = 512
)(
  input  wire           clk,
  input  wire           tg68_as,
  input  wire [ 32-1:0] tg68_adr,
  input  wire           tg68_rw,
  input  wire           tg68_lds,
  input  wire           tg68_uds,
  input  wire [ 16-1:0] tg68_dat_out,
  output wire [ 16-1:0] tg68_dat_in,
  output wire           tg68_dtack
);

// memory
reg  [8-1:0] mem0 [0:MS-1];
reg  [8-1:0] mem1 [0:MS-1];

// internal signals
reg  [16-1:0] mem_do = 0;
reg           trn = 1;
reg           ack = 1;

// clear on start
integer i;
initial begin
  for (i=0; i<MS; i=i+1) begin
    mem1[i] = 0;
    mem0[i] = 0;
  end
end

// read
always @ (posedge clk) begin
  if (!tg68_as && tg68_rw) mem_do <= #1 {mem1[tg68_adr[31:1]], mem0[tg68_adr[31:1]]};
end

//write
always @ (posedge clk) begin
  if (!tg68_as && !tg68_rw) begin
    if (!tg68_uds) mem1[tg68_adr[31:1]] <= #1 tg68_dat_out[15:8];
    if (!tg68_lds) mem0[tg68_adr[31:1]] <= #1 tg68_dat_out[7:0];
  end
end

// acknowledge
always @ (posedge clk) begin
  trn <= #1 tg68_as;
  ack <= #1 trn;
end

// outputs
assign tg68_dat_in = mem_do;
assign tg68_dtack = ack || tg68_as; // TODO

// load task
task load;
  input [1024*8-1:0] file;
  reg [16-1:0] memory[0:MS-1];
  reg [16-1:0] dat;
  integer i;
begin
  $readmemh(file, memory);
  for (i=0; i<MS; i=i+1) begin
    dat = memory[i];
    mem1[i] = dat[15:8];
    mem0[i] = dat[7:0];
  end
end
endtask


endmodule

