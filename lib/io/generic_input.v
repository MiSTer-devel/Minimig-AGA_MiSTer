/********************************************/
/* generic_input.v                          */
/* A generic implementation of inputs       */
/* (buttons, switches)                      */
/*                                          */
/* 2012, rok.krajnc@gmail.com               */
/********************************************/


module generic_input #(
  parameter IW  = 1,    // input width
  parameter PD  = 10,   // push delay
  parameter DS  = 1'b0, // default (off) state
  parameter DBG = 0     // debug output
)(
  output wire [ IW-1:0] o
);



////////////////////////////////////////
// logic                              //
////////////////////////////////////////

reg  [ IW-1:0] state = {IW{DS}};
assign o = state;



////////////////////////////////////////
// tasks                              //
////////////////////////////////////////

//// on ////
task on;
input [ IW-1:0] i;
begin
  if (DBG) $display ("BENCH : %M : %t : changing state from [%b] to [%b].", $time, state, (DS ? i & state : i | state));
  state <= #1 DS ? i & state : i | state;
end
endtask


//// off ////
task off;
input [ IW-1:0] i;
begin
  if (DBG) $display ("BENCH : %M : %t : changing state from [%b] to [%b].", $time, state, (DS ? i | state : i & state));
  state <= #1 DS ? i | state : i & state;
end
endtask


//// push ////
task push;
input [ IW-1:0] i;
begin
  if (DBG) $display ("BENCH : %M : %t : changing state from [%b] to [%b].", $time, state, (i ^ state));
  state = #1 i ^ state;
  #PD;
  if (DBG) $display ("BENCH : %M : %t : changing state from [%b] to [%b].", $time, state, (i ^ state));
  state = #1 i ^ state;
end
endtask


//// toggle ////
task toggle;
input [ IW-1:0] i;
begin
  if (DBG) $display ("BENCH : %M : %t : changing state from [%b] to [%b].", $time, state, (i ^ state));
  state = #1 i ^ state;
end
endtask



endmodule

