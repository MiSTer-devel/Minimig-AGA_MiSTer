/* audio_shifter.v */


module audio_shifter(
  input  wire           clk,    //32MHz
  input  wire           nreset,
  input  wire           mix,
  input  wire [ 15-1:0] rdata,
  input  wire [ 15-1:0] ldata,
  input  wire           exchan,
  output wire           aud_bclk,
  output wire           aud_daclrck,
  output wire           aud_dacdat,
  output wire           aud_xck
);


//// L-R mixer ////

wire [ 16-1:0] rdata_mix;
wire [ 16-1:0] ldata_mix;

assign rdata_mix = {rdata[14], rdata} + {{2{ldata[14]}}, ldata[14:1]};
assign ldata_mix = {ldata[14], ldata} + {{2{rdata[14]}}, rdata[14:1]};

// data mux
reg [16-1:0] rdata_mux;
reg [16-1:0] ldata_mux;

always @ (posedge clk) begin
  rdata_mux <= #1 (mix) ? rdata_mix : {rdata, rdata[13]};
  ldata_mux <= #1 (mix) ? ldata_mix : {ldata, ldata[13]};
end


//// audio output shifter ////

reg  [  9-1:0] shiftcnt;
reg  [ 16-1:0] shift;

always @(posedge clk, negedge nreset) begin
  if(~nreset)
    shiftcnt <= 9'd0;
  else
    shiftcnt <= shiftcnt - 9'd1;
end

always @ (posedge clk) begin
  if(~|shiftcnt[2:0]) begin
    if (~|shiftcnt[6:3])
      shift <= #1 (exchan ^ shiftcnt[7]) ? ldata_mux : rdata_mux;
    else
      shift <= #1 {shift[14:0], 1'b0};
  end
end


//// output ////
assign aud_daclrck = shiftcnt[7];
assign aud_bclk    = ~shiftcnt[2];
assign aud_xck     = shiftcnt[0];
assign aud_dacdat  = shift[15];


endmodule

