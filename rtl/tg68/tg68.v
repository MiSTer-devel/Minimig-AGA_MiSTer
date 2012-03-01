//----------------------------------------------------------------------------
//----------------------------------------------------------------------------
//                                                                          --
// This is the TOP-Level for TG68_fast to generate 68K Bus signals          --
//                                                                          --
// Copyright (c) 2007-2008 Tobias Gubener <tobiflex@opencores.org>          -- 
//                                                                          --
// This source file is free software: you can redistribute it and/or modify --
// it under the terms of the GNU Lesser General Public License as published --
// by the Free Software Foundation, either version 3 of the License, or     --
// (at your option) any later version.                                      --
//                                                                          --
// This source file is distributed in the hope that it will be useful,      --
// but WITHOUT ANY WARRANTY; without even the implied warranty of           --
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            --
// GNU General Public License for more details.                             --
//                                                                          --
// You should have received a copy of the GNU General Public License        --
// along with this program.  If not, see <http://www.gnu.org/licenses/>.    --
//                                                                          --
//----------------------------------------------------------------------------
//----------------------------------------------------------------------------
//
// Revision 1.02 2008/01/23
// bugfix Timing
//
// Revision 1.01 2007/11/28
// add MOVEP
// Bugfix Interrupt in MOVEQ
//
// Revision 1.0 2007/11/05
// Clean up code and first release
//
// known bugs/todo:
// Add CHK INSTRUCTION
// full decode ILLEGAL INSTRUCTIONS
// Add FDC Output
// add odd Address test
// add TRACE
// Movem with regmask==x0000
// no timescale needed

module TG68(
  input  wire           clk,
  input  wire           reset,
  input  wire           clkena_in,
  input  wire [ 16-1:0] data_in,
  input  wire [  3-1:0] IPL,
  input  wire           dtack,
  output wire [ 32-1:0] addr,
  output wire [ 16-1:0] data_out,
  output reg            as,
  output reg            uds,
  output reg            lds,
  output reg            rw,
  output reg            drive_data, //enable for data_out driver
  input  wire           enaRDreg,
  input  wire           enaWRreg
);



reg            as_s;
reg            as_e;
reg            uds_s;
reg            uds_e;
reg            lds_s;
reg            lds_e;
reg            rw_s;
reg            rw_e;
reg            waitm;
reg            clkena_e;
reg  [  2-1:0] S_state;
wire           decode;
wire           wr;
wire           uds_in;
wire           lds_in;
wire [  2-1:0] state;
reg            clkena;  
wire           n_clk;
reg  [  3-1:0] cpuIPL;



assign n_clk = ~clk;


TG68_fast TG68_fast_inst(
  // originally n_clk was used
  //.clk        (n_clk),
  .clk        (clk),
  .reset      (reset),
  .clkena_in  (clkena),
  .data_in    (data_in),
  // originally cpuIPL was used
  //.IPL        (cpuIPL),
  .IPL        (IPL),
  .test_IPL   (1'b0),
  .address    (addr),
  .data_write (data_out),
  .state_out  (state),
  .decodeOPC  (decode),
  .wr         (wr),
  .UDS        (uds_in),
  .LDS        (lds_in),
  .enaRDreg   (enaWRreg),
  .enaWRreg   (enaRDreg)
);


always @(posedge clk) begin
  // TODO new version is not edge sensitive (convert this to always_comb ?)
  if((clkena_in == 1'b1) && ((clkena_e == 1'b1) || (state == 2'b01))) begin
    clkena <= 1'b1;
  end else begin
    clkena <= 1'b0;
  end
end


always @(*) begin
  if(state == 2'b01) begin
    as  = 1'b1;
    rw  = 1'b1;
    uds = 1'b1;
    lds = 1'b1;
  end else begin
    as  = as_s & as_e;
    rw  = rw_s & rw_e;
    uds = uds_s & uds_e;
    lds = lds_s & lds_e;
  end
end


always @(posedge clk or negedge reset) begin
  if(reset == 1'b0) begin
    S_state <= 2'b11;
    as_s    <= 1'b1;
    rw_s    <= 1'b1;
    uds_s   <= 1'b1;
    lds_s   <= 1'b1;
  end else begin
    if((clkena_in == 1'b1) && (enaWRreg == 1'b1)) begin // enaWRreg added
      as_s  <= 1'b1;
      rw_s  <= 1'b1;
      uds_s <= 1'b1;
      lds_s <= 1'b1;
      if((state != 2'b01) || (decode == 1'b1)) begin
        case(S_state)
          2'b00 : begin
            as_s <= 1'b0;
            rw_s <= wr;
            if(wr == 1'b1) begin
              uds_s <= uds_in;
              lds_s <= lds_in;
            end
            S_state <= 2'b01;
          end
          2'b01 : begin
            as_s    <= 1'b0;
            rw_s    <= wr;
            uds_s   <= uds_in;
            lds_s   <= lds_in;
            S_state <= 2'b10;
          end
          2'b10 : begin
            rw_s <= wr;
            if(waitm == 1'b0) begin
              S_state <= 2'b11;
            end
          end
          2'b11 : begin
            S_state <= 2'b00;
          end
          default : begin
          end
        endcase
      end
    end
  end
end


// originally it was falling edge clock sensitive
always @(posedge clk or negedge reset) begin
  if(reset == 1'b0) begin
    as_e       <= 1'b1;
    rw_e       <= 1'b1;
    uds_e      <= 1'b1;
    lds_e      <= 1'b1;
    clkena_e   <= 1'b0;
    cpuIPL     <= 3'b111;
    drive_data <= 1'b0;
  end else begin
    if(clkena_in == 1'b1 && enaRDreg == 1'b1) begin // enaRDreg added
      as_e       <= 1'b1;
      rw_e       <= 1'b1;
      uds_e      <= 1'b1;
      lds_e      <= 1'b1;
      clkena_e   <= 1'b0;
      drive_data <= 1'b0;
      case(S_state)
        2'b00 : begin
        end
        2'b01 : begin
          drive_data <= ~wr;
        end
        2'b10 : begin
          as_e       <= 1'b0;
          uds_e      <= uds_in;
          lds_e      <= lds_in;
          cpuIPL     <= IPL;
          drive_data <= ~wr;
          if(state == 2'b01) begin
            clkena_e <= 1'b1;
            waitm <= 1'b0;
          end
          else begin
            clkena_e <= ~dtack;
            waitm <= dtack;
          end
        end
        default : begin
        end
      endcase
    end
  end
end



endmodule

