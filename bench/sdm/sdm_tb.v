/* sigma-delta modulator bench */

`timescale 1ns/10ps

`define CLK_HPER 17.8571


module sdm_tb();

// variables
reg clk;
real lsum=0, rsum=0;
real lmean=0, rmean=0;
reg [14:0] ldata_in;
reg [14:0] rdata_in;
wire ldata_out;
wire rdata_out;

// constants
real ifactor = 128;
integer steps = 4096;

// integrator function
function integrate;
  input real mean;
  input real in;
begin
  integrate = mean - mean/ifactor + in/ifactor;
end
endfunction

// sdm_convert task
task sdm_convert;
  input signed [14:0] val;
begin
  $display("Testing %d", val);
  ldata_in = val;
  rdata_in = val;
  lsum = 0;
  rsum = 0;
  repeat(steps) @ (posedge clk) begin
    lsum = lsum + ldata_out-0.5;
    rsum = rsum + rdata_out-0.5;
    lmean = lmean - lmean/ifactor + (ldata_out-0.5)/ifactor;
    rmean = rmean - rmean/ifactor + (rdata_out-0.5)/ifactor;
  end
  $display("Average lout (0) = %f", lsum/steps);
  $display("Average rout (0) = %f", rsum/steps);
end
endtask


////////////////////////////////////////

// clock
initial begin
  clk = 1'b0;
  forever #`CLK_HPER clk = ~clk;
end

// testbench
initial begin
  $display("SDM bench starting ...");

  // 0
  sdm_convert(0);

  // 1
  sdm_convert({1'b0, {14{1'b1}}});

  // -1
  sdm_convert({1'b1, {14{1'b0}}});

  // 1
  sdm_convert({1'b0, {14{1'b1}}});

  // -0.5
  sdm_convert(15'h6000);

  // 0.5
  sdm_convert(15'h1fff);
  // 0
  sdm_convert(0);

  $display("SDM bench stopping ...");
  $finish;
end

// dut
sdm sdm (
  .clk      (clk),
  .ldatasum (ldata_in),
  .rdatasum (rdata_in),
  .left     (ldata_out),
  .right    (rdata_out)
);


endmodule

