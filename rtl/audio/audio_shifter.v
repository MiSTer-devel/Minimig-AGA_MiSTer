/* audio_shifter.v */


module audio_shifter(
  input  wire           clk,    //32MHz
  input  wire           nreset,
  input  wire [ 16-1:0] rechts,
  input  wire [ 16-1:0] links,
  input  wire           exchan,
  output reg            aud_bclk,
  output reg            aud_daclrck,
  output reg            aud_dacdat,
  output reg            aud_xck
);


reg  [  9-1:0] shiftcnt;
reg  [ 16-1:0] shift;
reg  [ 15-1:0] test;


always @(*) begin
  aud_bclk    <= ~shiftcnt[2] ;
  aud_daclrck <= shiftcnt[7] ;
  aud_dacdat  <= shift[15] ;
  aud_xck     <= shiftcnt[0] ;
end


always @(posedge clk, negedge nreset) begin
  if(~nreset) begin
    shiftcnt <= {9{1'b0}};
  end else begin
    test <= test - 15'd1;
    shiftcnt <= shiftcnt - 9'd1;
    if(shiftcnt[6:3]  <= 4'd15 && shiftcnt[2:0] == 3'b000) begin
      if(shiftcnt[6:3]  == 4'd0) begin
        if(((exchan ^ shiftcnt[7] )) == 1'b1) begin
          shift <= links;
        end
        else begin
          shift <= rechts;
        end
      end
      else begin
        shift[15:1]  <= shift[14:0];
      end
    end
  end
end


endmodule

