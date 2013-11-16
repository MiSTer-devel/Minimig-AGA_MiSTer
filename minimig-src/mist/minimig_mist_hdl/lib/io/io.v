/********************************************/
/* io.v                                     */
/* A generic implementation of IOs          */
/* (buttons, switches, LEDs, ...)           */
/*                                          */
/* 2012, rok.krajnc@gmail.com               */
/********************************************/


module io #(
  parameter SW  = 1,    // signal width
  parameter OE  = 1'b0, // output enable (direction), 0 = input, 1 = output
  parameter DS  = 1'b0, // default (off) state
  parameter PD  = 10,   // push delay
  parameter DBG = 0     // debug output
)(
  inout  wire [ SW-1:0] io
);



////////////////////////////////////////
// logic                              //
////////////////////////////////////////

reg  [ SW-1:0] i  = {SW{DS}};
reg  [ SW-1:0] o  = {SW{DS}};
reg  [ SW-1:0] oe = {SW{OE}};

assign io = oe ? o : {SW{1'bz}};



////////////////////////////////////////
// input change detect                //
////////////////////////////////////////
always @ (io) begin
  if ((io & (~oe)) != (i & (~oe))) begin
  if (DBG) $display ("BENCH : %M : %t : input changed from [%b] to [%b].", $time, i, ((i & ( oe | io)) | (~oe & io)));
  i = i & ( oe | io);
  i = i | (~oe & io);
  end
end



////////////////////////////////////////
// tasks                              //
////////////////////////////////////////

//// dir ////
task dir;
input [ SW-1:0] dir;
begin
  if (DBG) $display ("BENCH : %M : %t : output enable changed from [%b] to [%b].", $time, oe, dir);
  oe = dir;
end
endtask


//// read ////
task read(data);
output [ SW-1:0] data;
begin
  data = i;
end
endtask


//// on ////
task on;
input [ SW-1:0] in;
begin
  if (DBG) $display ("BENCH : %M : %t : output changed from [%b] to [%b].", $time, o, (DS ? in & o : in | o));
  o <= #1 DS ? in & o : in | o;
end
endtask


//// off ////
task off;
input [ SW-1:0] in;
begin
  if (DBG) $display ("BENCH : %M : %t : changing state from [%b] to [%b].", $time, o, (DS ? in | o : in & o));
  o <= #1 DS ? in | o : in & o;
end
endtask


//// push ////
task push;
input [ SW-1:0] in;
begin
  if (DBG) $display ("BENCH : %M : %t : changing state from [%b] to [%b].", $time, o, (in ^ o));
  o = #1 in ^ o;
  #PD;
  if (DBG) $display ("BENCH : %M : %t : changing state from [%b] to [%b].", $time, o, (in ^ o));
  o = #1 in ^ o;
end
endtask


//// toggle ////
task toggle;
input [ SW-1:0] in;
begin
  if (DBG) $display ("BENCH : %M : %t : changing state from [%b] to [%b].", $time, o, (in ^ o));
  o = #1 in ^ o;
end
endtask



endmodule

