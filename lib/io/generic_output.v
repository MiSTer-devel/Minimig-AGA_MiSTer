/********************************************/
/* generic_output.v                         */
/* A generic implementation of outputs      */
/* (LEDs, ...)                              */
/*                                          */
/* 2012, rok.krajnc@gmail.com               */
/********************************************/


module generic_output #(
  parameter OW  = 1,    // output width
  parameter DS  = 1'b0, // default (off) state
  parameter DBG = 0     // debug output
)(
  output wire [ OW-1:0] i
);



////////////////////////////////////////
// logic                              //
////////////////////////////////////////

reg  [ OW-1:0] state_old = {OW{DS}};

always @ (i) begin
  if (i != state_old) begin
  if (DBG) $display ("BENCH : %M : %t : changing state from [%b] to [%b].", $time, state_old, i);
  state_old = #1 i;
  end
end



////////////////////////////////////////
// tasks                              //
////////////////////////////////////////

//// read ////
task read;
output [ OW-1:0] data;
begin
  data = state_old;
end
endtask



endmodule

