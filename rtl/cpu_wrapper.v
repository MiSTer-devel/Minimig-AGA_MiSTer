//--------------------------------------------------------------------------//
//--------------------------------------------------------------------------//
//                                                                          //
// Copyright (c) 2009-2011 Tobias Gubener                                   //
// Copyright (c) 2017-2019 Alexey Melnikov                                  //
// Subdesign fAMpIGA by TobiFlex                                            //
//                                                                          //
// This is the cpu wrapper to generate 68K Bus signals                      //
// and configure Zorro cards                                                //
//                                                                          //
// This source file is free software: you can redistribute it and/or modify //
// it under the terms of the GNU General Public License as published        //
// by the Free Software Foundation, either version 3 of the License, or     //
// (at your option) any later version.                                      //
//                                                                          //
// This source file is distributed in the hope that it will be useful,      //
// but WITHOUT ANY WARRANTY; without even the implied warranty of           //
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            //
// GNU General Public License for more details.                             //
//                                                                          //
// You should have received a copy of the GNU General Public License        //
// along with this program.  If not, see <http://www.gnu.org/licenses/>.    //
//                                                                          //
//--------------------------------------------------------------------------//
//--------------------------------------------------------------------------//

module cpu_wrapper
(
	input             reset,
	output reg        reset_out,

	input             clk,
	input             ph1,
	input             ph2,

	input       [1:0] cpucfg,
	input       [2:0] fastramcfg,
	input       [3:0] cachecfg,
	input             bootrom,

	output reg [23:1] chip_addr,
	input      [15:0] chip_dout,
	output reg [15:0] chip_din,
	output reg        chip_as,
	output reg        chip_uds,
	output reg        chip_lds,
	output reg        chip_rw,
	input             chip_dtack,
	input       [2:0] chip_ipl,
	
	input      [15:0] fastchip_dout,
	output reg        fastchip_sel,
	output            fastchip_lds,
	output            fastchip_uds,
	output            fastchip_rnw,
	output reg        fastchip_lw,
	input             fastchip_selack,
	input             fastchip_ready,

	output            ramsel,
	output     [28:1] ramaddr,
	output     [15:0] ramdin,
	input      [15:0] ramdout,
	input             ramready,
	output            ramlds,
	output            ramuds,
	output            ramshared,

	output            toccata_ena,
	output reg  [7:0] toccata_base,

	input             cdtv_mode,

	input      [15:0] cdtv_din,
	input             cdtv_selack,

	input       [5:0] cdtv_ac_rom_addr,
	output      [7:0] cdtv_ac_rom_byte,

	output reg  [1:0] cpustate,
	output reg  [3:0] cacr,
	output reg [31:0] nmi_addr,

	output            z2ram_ena_out,
	output      [4:0] z3ram_base0_out,
	output            z3ram_ena0_out,
	output      [3:0] z3ram_base1_out,
	output            z3ram_ena1_out,

	output            dcache_sw_en,

	input             z2_trace_cs,
	input             z2_trace_rd,
	output      [7:0] z2_trace_dout
);

wire dcache_sw_en_p;
assign dcache_sw_en = cpucfg[1] ? dcache_sw_en_p : 1'b1;

assign z2ram_ena_out   = z2ram_ena;
assign z3ram_base0_out = z3ram_base0;
assign z3ram_ena0_out  = z3ram_ena0;
assign z3ram_base1_out = z3ram_base1;
assign z3ram_ena1_out  = z3ram_ena1;

assign ramsel       = cpu_req & ~sel_nmi_vector & (sel_zram | sel_chipram | sel_kickram | sel_dd | sel_rtg);
assign ramshared    = sel_dd;

// NMI
always @(posedge clk) nmi_addr <= vbr + 32'h7c;

wire sel_chipram;
wire sel_kickram;
wire sel_kicklower;
wire sel_z2ram;
wire sel_z3ram0;
wire sel_z3ram1;
wire sel_zram;
wire sel_dd;
wire sel_rtg;

memory_router u_memory_router
(
	.cpu_addr      (cpu_addr      ),
	.cchip         (cchip         ),
	.ckick         (ckick         ),
	.wr            (wr            ),
	.bootrom       (bootrom       ),
	.z2ram_ena     (z2ram_ena     ),
	.z3ram_base0   (z3ram_base0   ),
	.z3ram_ena0    (z3ram_ena0    ),
	.z3ram_base1   (z3ram_base1   ),
	.z3ram_ena1    (z3ram_ena1    ),
	.sel_chipram   (sel_chipram   ),
	.sel_kickram   (sel_kickram   ),
	.sel_kicklower (sel_kicklower ),
	.sel_z2ram     (sel_z2ram     ),
	.sel_z3ram0    (sel_z3ram0    ),
	.sel_z3ram1    (sel_z3ram1    ),
	.sel_zram      (sel_zram      ),
	.sel_dd        (sel_dd        ),
	.sel_rtg       (sel_rtg       ),
	.ramaddr       (ramaddr       ),
	.zram_sel      (              )
);

z2_trace u_z2_trace
(
	.clk           (clk           ),
	.reset         (~reset        ),
	.ramsel        (ramsel        ),
	.ramready      (ramready      ),
	.cpu_addr      (cpu_addr      ),
	.ramaddr       (ramaddr       ),
	.ramdat        (ramdat        ),
	.wr            (wr            ),
	.uds_in        (uds_in        ),
	.lds_in        (lds_in        ),
	.cpustate      (cpustate      ),
	.cchip         (cchip         ),
	.ckick         (ckick         ),
	.sel_z2ram     (sel_z2ram     ),
	.sel_z3ram0    (sel_z3ram0    ),
	.sel_z3ram1    (sel_z3ram1    ),
	.sel_kickram   (sel_kickram   ),
	.sel_kicklower (sel_kicklower ),
	.sel_chipram   (sel_chipram   ),
	.sel_dd        (sel_dd        ),
	.sel_rtg       (sel_rtg       ),
	.z2ram_ena     (z2ram_ena     ),
	.uio_cs_trace  (z2_trace_cs   ),
	.uio_rd        (z2_trace_rd   ),
	.uio_dout      (z2_trace_dout )
);

// we route everything hrtmon related through cart.v (needs a couple of signals to
// decide what to do, would not be good style to replicate that here).
wire sel_nmi_vector = (cpu_addr[31:2] == nmi_addr[31:2]) && (cpustate == 2);

wire [15:0] ramdat;

assign ramlds = sel_rtg ? uds_in : lds_in;
assign ramuds = sel_rtg ? lds_in : uds_in;
assign ramdin = sel_rtg ? {cpu_dout[7:0],cpu_dout[15:8]} : cpu_dout;
assign ramdat = sel_rtg ? {ramdout[7:0], ramdout[15:8]}  : ramdout;

assign fastchip_lds = lds_in;
assign fastchip_uds = uds_in;
assign fastchip_rnw = wr;

reg  [31:0] cpu_addr;
reg  [15:0] cpu_dout;
wire [15:0] cpu_din = ramsel ? ramdat :
                      fastchip_selack ? fastchip_dout :
                      cdtv_selack ? cdtv_din :
                      {sel_autoconfig ? autocfg_data : chip_data[15:12], chip_data[11:0]};
reg         wr;
reg         uds_in;
reg         lds_in;
reg  [15:0] chip_data;
reg  [31:0] vbr;

always @* begin
	if(cpucfg[1:0]) begin
		cpu_dout     = cpu_dout_p;
		cpu_addr     = cpu_addr_p;
		cpustate     = cpustate_p;
		cacr         = cacr_p;
		vbr          = vbr_p;
		wr           = wr_p;
		uds_in       = uds_p;
		lds_in       = lds_p;
		reset_out    = reset_out_p;
		chip_as      = c_as;
		chip_rw      = c_rw;
		chip_uds     = c_uds;
		chip_lds     = c_lds;
		chip_addr    = cpu_addr_p[23:1];
		chip_din     = cpu_dout_p;
		chip_data    = chipdout_i;
		fastchip_sel = cpu_req & !cpu_addr_p[31:24];
		fastchip_lw  = longword;
	end
	else begin
		cpu_dout     = cpu_dout_o;
		cpu_addr     = {cpu_addr_o,1'b0};
		cpustate     = as_o ? 2'b01 : ~{wr_o,wr_o};
		cacr         = 1;
		vbr          = 0;
		wr           = wr_o;
		uds_in       = uds_o;
		lds_in       = lds_o;
		reset_out    = reset_out_o;
		chip_as      = ramsel | as_o;
		chip_rw      = wr_o;
		chip_uds     = uds_o;
		chip_lds     = lds_o;
		chip_addr    = cpu_addr_o[23:1];
		chip_din     = cpu_dout_o;
		chip_data    = chip_dout;
		fastchip_sel = 0;
		fastchip_lw  = 0;
	end
end

wire [15:0] cpu_dout_p;
wire [31:0] cpu_addr_p;
wire  [1:0] cpustate_p;
wire  [3:0] cacr_p;
wire [31:0] vbr_p;
wire        wr_p;
wire        uds_p;
wire        lds_p;
wire        reset_out_p;
wire        longword;

TG68KdotC_Kernel
#(
	.sr_read(2),        // 0=>user,   1=>privileged,    2=>switchable with CPU(0)
	.vbr_stackframe(2), // 0=>no,     1=>yes/extended,  2=>switchable with CPU(0)
	.extaddr_mode(2),   // 0=>no,     1=>yes,           2=>switchable with CPU(1)
	.mul_mode(2),       // 0=>16Bit,  1=>32Bit,         2=>switchable with CPU(1),  3=>no MUL,
	.div_mode(2),       // 0=>16Bit,  1=>32Bit,         2=>switchable with CPU(1),  3=>no DIV,
	.bitfield(2)        // 0=>no,     1=>yes,           2=>switchable with CPU(1)
)
cpu_inst_p
(
  .clk(clk),
  .nreset(reset),
  .clkena_in(clkena_p_throttled),
  .data_in(cpu_din),
  .ipl(cpu_ipl),
  .ipl_autovector(1),
  .regin_out(),
  .addr_out(cpu_addr_p),
  .data_write(cpu_dout_p),
  .nwr(wr_p),
  .nuds(uds_p),
  .nlds(lds_p),
  .nresetout(reset_out_p),
  .longword(longword),
  
  .cpu(cpucfg),
  .busstate(cpustate_p),		// 0: fetch code, 1: no memaccess, 2: read data, 3: write data
  .cacr_out(cacr_p),
  .d_cache_out(dcache_sw_en_p),
  .vbr_out(vbr_p)
);

wire [15:0] cpu_dout_o;
wire [23:1] cpu_addr_o;
wire  [2:0] fc_o;
wire        wr_o;
wire        as_o;
wire        uds_o;
wire        lds_o;
wire        reset_out_o;

fx68k cpu_inst_o
(
	.clk(clk),
	.enPhi1(ph1),
	.enPhi2(ph2),

	.extReset(~reset),
	.pwrUp(~reset),
	.oRESETn(reset_out_o),
	.HALTn(1),

	.eRWn(wr_o),
	.ASn(as_o),
	.LDSn(lds_o),
	.UDSn(uds_o),
	.DTACKn(ramsel ? ~ramready : chip_dtack),

	.FC0(fc_o[0]),
	.FC1(fc_o[1]),
	.FC2(fc_o[2]), 

	.VPAn(~&fc_o),
	.BERRn(1),
	.BRn(1),
	.BGACKn(1),
	.IPL0n(chip_ipl[0]),
	.IPL1n(chip_ipl[1]),
	.IPL2n(chip_ipl[2]),
	.iEdb(cpu_din),
	.oEdb(cpu_dout_o),
	.eab(cpu_addr_o)
);

wire cpu_req = (cpustate != 1);

wire cchip = turbochip_d & (!cpustate | dcache_d);
wire ckick = turbokick_d & (!cpustate | dcache_d);

reg turbochip_d;
reg turbokick_d;
reg dcache_d;
always @(posedge clk) begin
	if (~reset | ~reset_out) begin
		turbochip_d <= 0;
		turbokick_d <= 0;
		dcache_d    <= 0;
	end
	else if (~cpu_req) begin	// No mem access, so safe to switch chipram access mode
		turbochip_d <= cachecfg[0] & cpucfg[1];
		turbokick_d <= cachecfg[1] & cpucfg[1];
		dcache_d    <= cachecfg[2];
	end
end

wire stock_speed   = cachecfg[3];
wire clkena_p_base = ~cpu_req | chipready | ramready | fastchip_ready | cdtv_selack;

reg [3:0] cooldown;
always @(posedge clk) begin
	if (~reset)                                cooldown <= 4'd0;
	else if (cooldown != 4'd0)                 cooldown <= cooldown - 4'd1;
	else if (stock_speed & clkena_p_base)      cooldown <= 4'd9;
end
wire clkena_p_throttled = clkena_p_base & (cooldown == 4'd0);

reg       chipreq;
reg [2:0] cpu_ipl;
always @(posedge clk) begin
	chipreq <= cpu_req & ~ramsel & ~fastchip_selack & ~cdtv_selack;
	cpu_ipl <= ipl_i;
end

reg ph1n, ph2n;
always @(posedge clk) begin
	ph1n <= ph1;
	ph2n <= ph2;
end

reg        chipready;
reg [15:0] chipdout_i;
reg  [2:0] ipl_i;
reg        c_as,c_rw,c_uds,c_lds;
always @(negedge clk, negedge reset) begin
	reg [1:0] stage;
	reg waitm;
	reg ready;

	if(~reset) begin
		stage <= 0;
		c_as <= 1;
		c_rw <= 1;
		c_uds <= 1;
		c_lds <= 1;
		ready <= 0;
	end
	else begin
		if (ph2n) begin
			waitm <= chip_dtack;
			if(~stage[0]) ipl_i <= chip_ipl;
		end

		chipready <= 0;
		if (ph1n) begin
			chipready <= ready;
			ready <= 0;
			case (stage)
				0: if (chipreq) begin
						c_as <= 0;
						c_rw <= wr;
						c_uds <= uds_in;
						c_lds <= lds_in;
						stage <= 1;
					end
				1: stage <= 2;
				2: begin
						chipdout_i <= chip_dout;
						if (~waitm) begin
							c_as <= 1;
							c_rw <= 1;
							c_uds <= 1;
							c_lds <= 1;
							ready <= 1;
							stage <= 3;
						end
					end
				3: stage <= 0;
			endcase
		end
	end
end

///////////////////// AUTOCONFIG ////////////////////////////

reg       ac_toccata;
reg       ac_cdtv;
reg [2:0] ac_memcard;
reg [3:0] autocfg_data;
reg [7:0] cdtv_base;

always @(*) begin
	autocfg_data = 4'b1111;

	if (ac_cdtv) begin
		case (chip_addr[6:1])
			6'h00: autocfg_data = 4'b1100;
			6'h01: autocfg_data = 4'b0001;
			6'h03: autocfg_data = 4'b1100;
			6'h04: autocfg_data = 4'b1011;
			6'h09: autocfg_data = 4'b1101;
			6'h0B: autocfg_data = 4'b1101;
			default: autocfg_data = 4'b1111;
		endcase
	end
	// Zorro II RAM (Up to 8 meg at 0x200000). It has a fixed base, so it must be first in the chain.
	else if (~ac_memcard[2] && ac_memcard[1:0]) begin
		case (chip_addr[6:1])
			6'b000000: autocfg_data = 4'b1110;
			6'b000001:
				case (ac_memcard[1:0])
							1: autocfg_data = 4'b0110; // 2MB
							2: autocfg_data = 4'b0111; // 4MB
					default: autocfg_data = 4'b0000; // 8MB
				endcase
			6'b000010: autocfg_data = 4'b1010;
			6'b000011: autocfg_data = 4'b1110;
			6'b001000: autocfg_data = 4'b1111;
			6'b001001: autocfg_data = 4'b1000;
			6'b001010: autocfg_data = 4'b0010;
			6'b001011: autocfg_data = 4'b0100;
			6'b010011: autocfg_data = 4'b1110;
			  default:;
		endcase
	end
	// Zorro II other cards
	else if(ac_toccata) begin
		case (chip_addr[6:1])
			6'h0: autocfg_data = 4'b1100; // Zorro-II card, no link, no ROM
			6'h1: autocfg_data = 4'b0001; // Next board not related, size 'h64k
			// Inverted from here on
			6'h3: autocfg_data = 4'b0011; // Lower byte product number
			//6'h5: autocfg_data = 4'b1101; // logical size 64k -- commented out -> logical size == physical size. Issue with KS1.3?
			6'h8: autocfg_data = 4'b1011; // Manufacturer ID: 0x4754
			6'h9: autocfg_data = 4'b1000;
			6'ha: autocfg_data = 4'b1010;
			6'hb: autocfg_data = 4'b1011;
			default: ;
		endcase
	end
	// Zorro III RAM 128MB/256MB/384MB
	else if(ac_memcard[2]) begin
		case (chip_addr[6:1])
			6'b000000: autocfg_data = 4'b1010;	// Zorro-III card, add mem, no ROM
			6'b000001: autocfg_data = ac_memcard[1] ? 4'b0011 : 4'b0100; // 128MB or 256MB, extended
			6'b000010: autocfg_data = 4'b1110;	// ProductID=0x10 (only setting upper nibble)
			6'b000100: autocfg_data = 4'b0000;	// Memory card, not silenceable, Extended size, reserved.
			6'b000101: autocfg_data = 4'b1111;	// 0000 - logical size matches physical size TODO change this to 0001, so it is autosized by the OS, WHEN it will be 24MB.
			6'b001000: autocfg_data = 4'b1110;	// Manufacturer ID: 0x139c
			6'b001001: autocfg_data = 4'b1100;
			6'b001010: autocfg_data = 4'b0110;
			6'b001011: autocfg_data = 4'b0011;
			6'b010011: autocfg_data = {2'b11, ~ac_memcard[1], ac_memcard[1]};	// serial=1/2
			  default:;
		endcase
	end
end

wire sel_autoconfig = (chip_addr[23:16] == 8'b11101000) && (ac_memcard || ac_toccata || ac_cdtv); //$E80000 - $E8FFFF

reg [7:0] cdtv_ac_rom_byte_r;
always @* begin
	cdtv_ac_rom_byte_r = 8'hFF;
	case (cdtv_ac_rom_addr)
		6'h00: cdtv_ac_rom_byte_r = 8'hC0;
		6'h01: cdtv_ac_rom_byte_r = 8'h10;
		6'h02: cdtv_ac_rom_byte_r = 8'hF0;
		6'h03: cdtv_ac_rom_byte_r = 8'hC0;
		6'h04: cdtv_ac_rom_byte_r = 8'hB0;
		6'h05: cdtv_ac_rom_byte_r = 8'hF0;
		6'h08: cdtv_ac_rom_byte_r = 8'hF0;
		6'h09: cdtv_ac_rom_byte_r = 8'hD0;
		6'h0A: cdtv_ac_rom_byte_r = 8'hF0;
		6'h0B: cdtv_ac_rom_byte_r = 8'hD0;
		6'h0C: cdtv_ac_rom_byte_r = 8'hF0;
		6'h0D: cdtv_ac_rom_byte_r = 8'hF0;
		6'h0E: cdtv_ac_rom_byte_r = 8'hF0;
		6'h0F: cdtv_ac_rom_byte_r = 8'hF0;
		6'h10: cdtv_ac_rom_byte_r = 8'hF0;
		6'h11: cdtv_ac_rom_byte_r = 8'hF0;
		6'h12: cdtv_ac_rom_byte_r = 8'hF0;
		6'h13: cdtv_ac_rom_byte_r = 8'hF0;
		default: cdtv_ac_rom_byte_r = 8'hFF;
	endcase
end
assign cdtv_ac_rom_byte = cdtv_ac_rom_byte_r;

reg       z2ram_ena;
reg [4:0] z3ram_base0;
reg [3:0] z3ram_base1;
reg       z3ram_ena0;
reg       z3ram_ena1;
always @(posedge clk) begin
	reg old_uds;
	old_uds <= chip_uds;

	if (~reset | ~reset_out) begin
		ac_memcard  <= cpucfg[1] ? fastramcfg : fastramcfg[2] ? 3'd3 : {1'b0, fastramcfg[1:0]};
		ac_toccata  <= cdtv_mode ? 1'b0 : 1'b1;
		ac_cdtv     <= cdtv_mode;
		cdtv_base   <= 8'hE9;
		z2ram_ena   <= 0;
		z3ram_ena0  <= 0;
		z3ram_ena1  <= 0;
		z3ram_base0 <= 1;
		z3ram_base1 <= 1;
	end
	else if (sel_autoconfig && ~chip_rw && ~chip_uds && old_uds) begin
		if(ac_cdtv) begin
			if (chip_addr[6:1] == 6'b100100) begin
				cdtv_base <= cpu_dout[15:8];
				ac_cdtv   <= 0;
			end
			else if (chip_addr[6:1] == 6'b100110) begin
				ac_cdtv   <= 0;
			end
		end
		else if(~ac_memcard[2] && ac_memcard[1:0]) begin
			if (chip_addr[6:1] == 6'b100100) begin // Register 0x48 - config, ZII RAM
				z2ram_ena <= 1;
				ac_memcard <= 0;
			end
		end
		else if(ac_toccata) begin
			if (chip_addr[6:1] == 6'b100100) begin // Register 0x48 - config, Toccata card in ZII io space ($E90000)
				toccata_base <= cpu_dout[7:0];
				ac_toccata<=0;
			end
		end
		else if(ac_memcard[2]) begin
			if(chip_addr[6:1] == 6'b100010) begin // Register 0x44, assign base address to ZIII RAM.
				if(~ac_memcard[1]) begin
					z3ram_base1 <= cpu_dout[15:12]; //256MB chunk
					z3ram_ena1 <= 1;
					ac_memcard <= {ac_memcard[0], ac_memcard[0], 1'b0};
				end
				else begin
					z3ram_base0 <= cpu_dout[15:11]; //128MB chunk
					z3ram_ena0 <= 1;
					ac_memcard <= 0;
				end
			end
		end
	end
end

assign toccata_ena = ~ac_toccata & ~cdtv_mode;

endmodule
