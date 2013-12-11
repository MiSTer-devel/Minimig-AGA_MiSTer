// Copyright 2013 by Rok Krajnc
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
// RK:
// This module is based on existing ActionReplay.v module by Jakub Bednarski and code from WinUAE ar.cpp file.
// The module requires the ctrl firmware to load the special hrtmon.rom file to address 0xa00000.
// The module requires one 512KB RAM bank. The start address (entry point) is 0xa0000c.
// TODO : custom registers and CIA registers shadow implemented as in WinUAE.
// TODO : for better compatibility, load the monitor to $A10000 (requires recompilation!).
//


module Cart
(
  input  wire          clk,
  input  wire          cpu_clk,
  input  wire          cpu_rst,
  input  wire [24-1:1] cpu_address,
  input  wire [24-1:1] cpu_address_in,
  input  wire          _cpu_as,
  input  wire          cpu_rd,
  input  wire          cpu_hwr,
  input  wire          cpu_lwr,
  input  wire [32-1:0] cpu_vbr,
  input  wire          dbr,
  input  wire          ovl,
  input  wire          freeze,
  output wire [16-1:0] cart_data_out,
  output reg           int7 = 1'b0,
  output wire          sel_cart,
  output wire          ovr,
//  output reg           aron = 1'b1
  output wire          aron
);


//// internal signals ////
reg  [32-1:0] nmi_vec_adr;
reg           freeze_d = 1'b0;
wire          freeze_req;
wire          int7_req;
wire          int7_ack;
reg           l_int7_req = 1'b0;
reg           l_int7_ack = 1'b0;
reg           l_int7 = 1'b0;
reg           active = 1'b0;

//// code ////

// cart is activated by writing to its area during bootloading
/*
always @ (posedge clk) begin
  if (cpu_rst && (cpu_address_in[23:19]==5'b1010_0) && cpu_lwr && !aron)
    aron <= 1'b1;
end
*/
// TODO enable cart from firmware when uploading
assign aron = 1'b1;

// cart selected
assign sel_cart = ~dbr && (cpu_address_in[23:19]==5'b1010_0);

// latch VBR + NMI vector offset
always @ (posedge clk) begin
  nmi_vec_adr <= #1 cpu_vbr + 32'h0000007c;
end

// override decoding of NMI
//assign ovr = active && ~dbr && ~ovl && cpu_rd && (cpu_address_in[23:2]==22'b0000_0000_0000_0000_0111_11);
assign ovr = active && ~dbr && ~ovl && cpu_rd && (cpu_address_in[23:2] == nmi_vec_adr[23:2]);

// custom NMI vector address output
assign cart_data_out = ovr ? (!cpu_address_in[1] ? 16'h00a0 : 16'h000c) : 16'h0000;

// freeze button
always @ (posedge clk) begin
  freeze_d <= freeze;
end

assign freeze_req = freeze && ~freeze_d;

// int7 request
assign int7_req = /*aron &&*/ freeze_req;

// level7 interrupt ack cycle, on Amiga interrupt vector number is read from kickstart rom
// A[23:4] all high, A[3:1] vector number
assign int7_ack = &cpu_address && ~_cpu_as;

// level 7 interrupt request logic
// interrupt request lines are sampled during S4->S5 transition (falling cpu clock edge)
always @ (posedge cpu_clk) begin
  if (cpu_rst)
    int7 <= 1'b0;
  else if (int7_req)
    int7 <= 1'b1;
  else if (int7_ack)
    int7 <= 1'b0;
end

always @ (posedge clk) begin
  l_int7_req <= int7_req;
  l_int7_ack <= int7_ack;
end

always @ (posedge clk) begin
  if (cpu_rst)
    l_int7 <= 1'b0;
  else if (l_int7_req)
    l_int7 <= 1'b1;
  else if (l_int7_ack && cpu_rd)
    l_int7 <= 1'b0;
end

// overlay active
always @ (posedge clk) begin
  if (cpu_rst)
    active <= #1 1'b0;
  else if (/*aron &&*/ l_int7 && l_int7_ack && cpu_rd)
    active <= #1 1'b1;
  else if (sel_cart && cpu_rd)
    active <= #1 1'b0;
end


endmodule

