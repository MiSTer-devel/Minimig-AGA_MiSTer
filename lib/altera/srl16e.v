module SRL16E (Q, A0, A1, A2, A3, CLK, D, CE) ;

parameter INIT = 16'h0000;

 input A0, A1, A2, A3, CLK, D, CE;
 output Q;

 reg [15:0] shift_reg;
 reg Q;

initial shift_reg = INIT;

 always@(posedge CLK)
 begin
 if (CE)
 shift_reg <= {shift_reg[14:0],D};
 end

 always @ (A3 or A2 or A1 or A0 or shift_reg)
 begin

 case ({A3, A2, A1, A0})
 1 : Q = shift_reg[1];

 2 : Q = shift_reg[2];

 3 : Q = shift_reg[3];

 4 : Q = shift_reg[4];

 5 : Q = shift_reg[5];

 6 : Q = shift_reg[6];

 7 : Q = shift_reg[7];

 8 : Q = shift_reg[8];

 9 : Q = shift_reg[9];

 10 : Q = shift_reg[10];

 11 : Q = shift_reg[11];

 12 : Q = shift_reg[12];

 13 : Q = shift_reg[13];

 14 : Q = shift_reg[14];

 15 : Q = shift_reg[15];

 default : Q = shift_reg[0];

 endcase

 end
 endmodule

