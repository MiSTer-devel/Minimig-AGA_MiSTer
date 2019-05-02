////////////////////////////////////////////////////////////////////////////////
//                                                                            //
// Copyright 2013, 2014 Rok Krajnc                                            //
//                                                                            //
// This file is part of Minimig                                               //
//                                                                            //
// Minimig is free software; you can redistribute it and/or modify            //
// it under the terms of the GNU General Public License as published by       //
// the Free Software Foundation; either version 3 of the License, or          //
// (at your option) any later version.                                        //
//                                                                            //
// Minimig is distributed in the hope that it will be useful,                 //
// but WITHOUT ANY WARRANTY; without even the implied warranty of             //
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              //
// GNU General Public License for more details.                               //
//                                                                            //
// You should have received a copy of the GNU General Public License          //
// along with this program.  If not, see <http://www.gnu.org/licenses/>.      //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
// This is Cart module with support for HRTmon monitor.                       //
// This module is based on existing ActionReplay.v module by Jakub Bednarski  //
// and code from WinUAE ar.cpp file. The module requires the ctrl firmware    //
// to load the special hrtmon.rom file to address 0xa10000. The module        //
// requires one 512KB RAM bank. The start address (entry point) is 0xa1000c.  //
// TODO : custom registers and CIA registers shadow implemented as in WinUAE. //
//                                                                            //
//                                                                            //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
// Changelog                                                                  //
// RK:                                                                        //
// 2013-11-27  - initial version                                              //
// 2014-09-27  - cleanup, clock enable added                                  //
// 2015-05-03  - added custom registers mirror                                //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////


module cart
(
  input wire 		clk,
  input wire 		clk7_en,
  input wire 		clk7n_en,
  input wire 		cpu_rst,
  input wire [ 24-1:1] 	cpu_address,
  input wire [ 24-1:1] 	cpu_address_in,
  input wire 		_cpu_as,
  input wire 		cpu_rd,
  input wire 		cpu_hwr,
  input wire 		cpu_lwr,
  input wire [ 32-1:0] 	cpu_vbr,
  input wire [ 9-1:1] 	reg_address_in,
  input wire [ 16-1:0] 	reg_data_in,
  input wire 		dbr,
  input wire 		ovl,
  input wire 		freeze, 
  input wire 		cpuhlt,
  output wire [ 16-1:0] cart_data_out,
  output reg 		int7 = 1'b0,
  output wire 		sel_cart,
  output wire 		ovr
 
//  output reg            aron = 1'b1
//  output wire 		aron //not needed -- remove!
 );


//// internal signals ////
reg  [32-1:0] nmi_vec_adr=0;
reg           freeze_d=0;
reg 	      stealth; //hide till first freeze request   
wire          freeze_req;
wire          int7_req;
wire          int7_ack;
reg           l_int7_req=0;
reg           l_int7_ack=0;
reg           l_int7=0;
reg           active=0;
wire          sel_custom_mirror;
wire [16-1:0] nmi_adr_out;
reg  [16-1:0] custom_mirror_q;
wire [16-1:0] custom_mirror_out;
reg  [16-1:0] custom_mirror [0:256-1];


//// code ////

// currently cart is activated by the first freeze request of the cia.    
// OLD: cart is activated by writing to its area during bootloading
/*
`define ARON_HACK
`ifndef ARON_HACK
always @ (posedge clk) begin
  if (clk7_en) begin
    if (cpu_rst && (cpu_address_in[23:19]==5'b1010_0) && cpu_lwr && !aron)
      aron <= 1'b1;
  end
end
`else
// TODO enable cart from firmware when uploading
assign aron = 1'b1;
`endif
*/
 
//  cart selected, is in stealth mode until first freeze, has to be available during halt to allow userio 
   assign sel_cart = ~dbr && (cpu_address_in[23:19]==5'b1010_0) && (stealth | cpuhlt); // $A00000
   

// latch VBR + NMI vector offset
always @ (posedge clk) begin
  if (clk7_en) begin
    nmi_vec_adr <= #1 cpu_vbr + 32'h0000007c; // $7C = NMI vector offset
  end
end

// override decoding of NMI
//assign ovr = active && ~dbr && ~ovl && cpu_rd && (cpu_address_in[23:2]==22'b0000_0000_0000_0000_0111_11);
assign ovr = active && ~dbr && ~ovl && cpu_rd && (cpu_address_in[23:2] == nmi_vec_adr[23:2]);

// custom NMI vector address output $a1000c
assign nmi_adr_out = ovr ? (!cpu_address_in[1] ? 16'h00a1 : 16'h000c) : 16'h0000; 

// freeze button
always @ (posedge clk) begin
  if (clk7_en) begin
    freeze_d <= freeze;
  end
end

assign freeze_req = freeze && ~freeze_d;

// int7 request
assign int7_req = /*aron &&*/ freeze_req;

// level7 interrupt ack cycle, on Amiga interrupt vector number is read from kickstart rom
// A[23:4] all high, A[3:1] vector number
assign int7_ack = &cpu_address_in && ~_cpu_as;

// level 7 interrupt request logic
// interrupt request lines are sampled during S4->S5 transition (falling cpu clock edge)
always @ (posedge clk) begin
  if (clk7_en) begin
    if (cpu_rst)
      int7 <= 1'b0;
    else if (int7_req)
      int7 <= 1'b1;
    else if (int7_ack)
      int7 <= 1'b0;
  end
end

// latches
always @ (posedge clk) begin
  if (clk7_en) begin
    l_int7_req <= int7_req;
    l_int7_ack <= int7_ack;
  end
end

always @ (posedge clk) begin
  if (clk7_en) begin
    if (cpu_rst)
      l_int7 <= 1'b0;
    else if (l_int7_req)
      l_int7 <= 1'b1;
    else if (l_int7_ack && cpu_rd)
      l_int7 <= 1'b0;
  end
end

// overlay active
always @ (posedge clk) begin
  if (clk7_en) begin
    if (cpu_rst)
      begin
	 active <= #1 1'b0;
	 stealth <= #1 1'b0;
      end
    else if (/*aron &&*/ l_int7 && l_int7_ack && cpu_rd)
      begin
	 active <= #1 1'b1;
	 stealth <= #1 1'b1;
      end
    else if (sel_cart && cpu_rd)
      active <= #1 1'b0;
  end
end

// custom registers mirror memory
assign sel_custom_mirror = ~dbr && cpu_rd && (cpu_address_in[23:12]==12'b1010_1001_1111) &&stealth; // $A9F000
always @ (posedge clk) begin
  if (clk7_en) begin
    custom_mirror[reg_address_in] <= #1 reg_data_in;
  end
  custom_mirror_q <= #1 custom_mirror[cpu_address_in[8:1]];
end

assign custom_mirror_out = sel_custom_mirror ? custom_mirror_q : 16'h0000;

// cart data output
assign cart_data_out = custom_mirror_out | nmi_adr_out;


endmodule

