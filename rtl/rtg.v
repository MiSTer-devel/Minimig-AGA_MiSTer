// Copyright 2020
//
// This file is part of Minimig
//
// Minimig is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 3 of the License, or
// (at your option) any later version.
//
// Minimig is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http:// www.gnu.org/licenses/>.
//
//
//----------------------------------------------------------------------------------
//----------------------------------------------------------------------------------  
// REGISTER MAP
// B80100:B80101 :  8:0 : ADDR[24:16]
// B80102:B80103 : 15:0 : ADDR[15:0]
// B80104:B80105 : 5:0  : FORMAT[5:0]
// B80106:B80107 :    0 : ENABLE
// B80108:B80109 : 11:0 : HSIZE
// B8010A:B8010B : 11:0 : VSIZE
// B8010C:B8010D : 13:0 : STRIDE
// B8010E:B8010F :  7:0 : ID = 50 / VERSION = 01

// B80400..B807FF CLUT : 256 * 32bits 00 / RR / GG / BB

module rtg
(
	input         clk,           // clock
	input         clk7_en,
	input         aen,           // adress enable
	input         rd,            // read enable
	input         wr,            // write enable
	input         reset,         // reset
	input  [11:0] rs,            // register select (address)

	input  [15:0] data_in,       // bus data in
	output reg [15:0] data_out,      // bus data out

	output reg        rtg_ena,
	output reg [11:0] rtg_hsize,
	output reg [11:0] rtg_vsize,
	output reg [5:0]  rtg_format,
	output reg [31:0] rtg_base,
	output reg [13:0] rtg_stride,
	output        rtg_pal_clk,
	output [23:0] rtg_pal_dw,
	input  [23:0] rtg_pal_dr,
	output [7:0]  rtg_pal_a,
	output        rtg_pal_wr
);

wire enable = aen & (rd | wr);
reg [23:0] rpal;

// decoder
wire r_ahi = enable && (rs[3:1]==3'h0) && (rs[10]==0);
wire r_alo = enable && (rs[3:1]==3'h1) && (rs[10]==0);
wire r_fmt = enable && (rs[3:1]==3'h2) && (rs[10]==0);
wire r_ena = enable && (rs[3:1]==3'h3) && (rs[10]==0);
wire r_hs  = enable && (rs[3:1]==3'h4) && (rs[10]==0);
wire r_vs  = enable && (rs[3:1]==3'h5) && (rs[10]==0);
wire r_str = enable && (rs[3:1]==3'h6) && (rs[10]==0);
wire r_id  = enable && (rs[3:1]==3'h7) && (rs[10]==0);

wire r_pal = enable && (rs[10]==1);
   
// writing of output port
always @(posedge clk)
  if (clk7_en) begin
    if (reset)
      rtg_ena<=0;
    else if (wr) begin
       if (r_ahi) rtg_base[31:16]<=data_in;
       if (r_alo) rtg_base[15:0] <=data_in;
       if (r_fmt) rtg_format<=data_in[5:0];
       if (r_ena) rtg_ena<=data_in[0];
       if (r_hs ) rtg_hsize <=data_in[11:0];
       if (r_vs ) rtg_vsize <=data_in[11:0];
       if (r_str) rtg_stride<=data_in[13:0];

       if (r_pal) begin
          if (!rs[1] & wr) rpal[23:16]<=data_in[7:0];
                       else rpal[15:0]<=data_in;
       end
    end
  end

always @(*) begin
   data_out<=16'b0;
   if (r_ahi) data_out<=rtg_base[31:16];
   if (r_alo) data_out<=rtg_base[15:0];
   if (r_fmt) data_out[5:0]<=rtg_format;
   if (r_ena) data_out[0]<=rtg_ena;
   if (r_hs)  data_out[11:0]<=rtg_hsize;
   if (r_vs)  data_out[11:0]<=rtg_vsize;
   if (r_str) data_out[13:0]<=rtg_stride;
   if (r_id)  data_out<=16'h5001;
   if (r_pal && !rs[1]) data_out<={8'b0,rtg_pal_dr[23:16]};
   if (r_pal &&  rs[1]) data_out<=rtg_pal_dr[15:0];
end

assign rtg_pal_a  = rs[9:2];
assign rtg_pal_wr = wr & r_pal & clk7_en;
assign rtg_pal_dw = (rs[1])?{rpal[23:16],data_in}:{data_in[7:0],rpal[15:0]};
assign rtg_pal_clk= clk;

endmodule
