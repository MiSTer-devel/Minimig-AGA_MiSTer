// SPDX-License-Identifier: GPL-3.0-or-later

module memory_router
(
	input  [31:0] cpu_addr,

	input         cchip,
	input         ckick,
	input         wr,

	input         bootrom,
	input         cdtv_mode,

	input         z2ram_ena,
	input   [4:0] z3ram_base0,
	input         z3ram_ena0,
	input   [3:0] z3ram_base1,
	input         z3ram_ena1,
	input   [7:0] z3sdr_base0,
	input         z3sdr_ena0,
	input   [7:0] z3sdr_base1,
	input         z3sdr_ena1,
	input   [7:0] z3sdr_base2,
	input         z3sdr_ena2,
	input         sdram_big,

	output        sel_chipram,
	output        sel_kickram,
	output        sel_kicklower,
	output        sel_z2ram,
	output        sel_z3ram0,
	output        sel_z3ram1,
	output        sel_zram,
	output        sel_dd,
	output        sel_rtg,

	output [28:1] ramaddr
);

assign sel_z3ram0   = (cpu_addr[31:27] == z3ram_base0) && z3ram_ena0;
assign sel_z3ram1   = (cpu_addr[31:28] == z3ram_base1) && z3ram_ena1;
assign sel_z2ram    = !cpu_addr[31:24] && (cpu_addr[23] ^ |cpu_addr[22:21]) && z2ram_ena; // addr[23:21] = 1..4
wire   sel_z3sdr0   = z3sdr_ena0 && (sdram_big ? (cpu_addr[31:25] == z3sdr_base0[7:1]) : (cpu_addr[31:24] == z3sdr_base0));
wire   sel_z3sdr1   = z3sdr_ena1 && (cpu_addr[31:26] == z3sdr_base1[7:2]);
wire   sel_z3sdr2   = z3sdr_ena2 && (cpu_addr[31:24] == z3sdr_base2) && !cpu_addr[23];
assign sel_zram     = sel_z3ram0 | sel_z3ram1 | sel_z2ram | sel_z3sdr0 | sel_z3sdr1 | sel_z3sdr2;
assign sel_dd       = (cpu_addr[31:16] == 16'h00DD) && (cpu_addr[15:13] == 3'b010);
assign sel_rtg      = (cpu_addr[31:24] == 8'h02);

// don't sel_kickram when writing
assign sel_kickram   = !cpu_addr[31:24] && (&cpu_addr[23:19] || (!cdtv_mode && cpu_addr[23:19] == 5'b11100) || (cpu_addr[23:19] == 5'b10101) || (cpu_addr[23:19] == 5'b10110)) && ckick && wr;
assign sel_kicklower = !cpu_addr[31:24] && (cpu_addr[23:18] == 6'b111110);
assign sel_chipram   = !cpu_addr[31:21] && cchip;

//       Main  DDx  RTG  8M  128M  256M
//       ----  ---  ---  --  ----  ----
//        SDR  DDR  RTG  Z2  Z3_0  Z3_1
// 28      0    0    0   1    0     1
// 27      0    0    0   1    1     X
// 26      0    1    1   0    X     X
// 25-23   0   111  110  0    X     X
// supported configs: SDR + (Z2, Z3_1, Z3_0+Z3_1)
//
// This is the mapping to the sram

wire [25:1] sdr_off = sel_z3sdr1 ? cpu_addr[25:1] :
                      sel_z3sdr0 ? (sdram_big ? {1'b0, cpu_addr[24:1]} : {2'b00, cpu_addr[23:1]}) :
                      sel_z3sdr2 ? {3'b101, cpu_addr[22:1]} :
                                   (sdram_big ? {3'b100, cpu_addr[22:1]} : {3'b010, cpu_addr[22:1]});
wire        sel_sdr = sel_z3sdr0 | sel_z3sdr1 | sel_z3sdr2;

wire [28:1] ramaddr_m;
assign ramaddr_m[28]    = sel_z2ram | sel_z3ram1;
assign ramaddr_m[27]    = sel_z3ram0 | (sel_z3ram1 & cpu_addr[27]);
assign ramaddr_m[26:23] = (sel_z3ram0 | sel_z3ram1) ? cpu_addr[26:23] : (sel_rtg ? 4'b1110 : {4{sel_dd}});
assign ramaddr_m[22:19] = {4{sel_dd}} | cpu_addr[22:19];
assign ramaddr_m[18]    =    sel_dd   | (sel_kicklower & bootrom) | cpu_addr[18];
assign ramaddr_m[17:16] = {2{sel_dd}} | cpu_addr[17:16];
assign ramaddr_m[15:1]  = cpu_addr[15:1];

assign ramaddr = sel_sdr ? {1'b0, sel_z3sdr1, 1'b1, sdr_off} : ramaddr_m;

endmodule
