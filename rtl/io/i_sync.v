/* i_sync.v */
/* input synchronizer */


module i_sync #(
  parameter DW = 1,           // signal width
  parameter RS = 1'b0         // power up state
)(
  // system
  input  wire           clk,
  // input
  input  wire [ DW-1:0] i,
  // output
  output wire [ DW-1:0] o
);


reg [ DW-1:0] sync_0 = {DW{RS}};
reg [ DW-1:0] sync_1 = {DW{RS}};


always @ (posedge clk) begin
  sync_0 <= #1 i;
  sync_1 <= #1 sync_0;
end


assign o = sync_1;


endmodule

