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
	input             turbochipram,
	input             turbokick,
	input             dcache,
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

	output            ramsel,
	output     [28:1] ramaddr,
	output     [15:0] ramdin,
	input      [15:0] ramdout,
	input             ramready,
	output            ramlds,
	output            ramuds,

	output reg  [1:0] cpustate,
	output reg  [3:0] cacr,
	output reg [31:0] vbr
);

// Uncomment to use M68K for 68020 mode
// `define M68K20

assign ramsel = cpu_req & ~sel_nmi_vector & (sel_zram | sel_chipram | sel_kickram);

// NMI
reg [31:0] NMI_addr;
always @(posedge clk) NMI_addr <= reset ? (vbr + 32'h7c) : 32'h7c;

wire sel_z3ram0 = (cpu_addr[31:27] == z3ram_base0) && z3ram_ena0;
wire sel_z3ram1 = (cpu_addr[31:28] == z3ram_base1) && z3ram_ena1;
wire sel_z2ram  = !cpu_addr[31:24] && (cpu_addr[23] ^ |cpu_addr[22:21]) && z2ram_ena; // addr[23:21] = 1..4
wire sel_zram   = sel_z3ram0 | sel_z3ram1 | sel_z2ram;


// don't sel_kickram when writing
wire sel_kickram   = !cpu_addr[31:24] && (&cpu_addr[23:19] || (cpu_addr[23:19] == 5'b11100)) && ckick && wr;	// $f8xxxx, e0xxxx
wire sel_kicklower = !cpu_addr[31:24] && (cpu_addr[23:18] == 6'b111110);
wire sel_chipram   = !cpu_addr[31:21] && cchip; 		             //$000000 - $1FFFFF

//  we route everything hrtmon related through cart.v (needs a couple of signals to
//  decide what to do, would not be good style to replicate that here). 
wire sel_nmi_vector = (cpu_addr[31:2] == NMI_addr[31:2]) && (cpustate == 2);

assign ramlds = lds_in;
assign ramuds = uds_in;
assign ramdin = cpu_dout;

//       Main  8M  128M  256M
//       ----  --  ----  ----
//        SDR  Z2  Z3_0  Z3_1
// 28      0    1    0     1
// 27      0    1    1     X
// 26-23   0    0    X     X
// supported configs: SDR + (Z2, Z3_1, Z3_0+Z3_1)

// This is the mapping to the sram
// map 00-1f to 00-1f (chipram), a0-ff to 20-7f. All non-fastram goes into the first
// 8M block(SDRAM). This map should be the same as in minimig_sram_bridge.v 
// All Zorro RAM goes to DDR3
assign ramaddr[28]    = sel_zram & ~sel_z3ram0;
assign ramaddr[27]    = sel_zram & (~sel_z3ram1 | cpu_addr[27]);
assign ramaddr[26:23] = (sel_z3ram0 | sel_z3ram1) ? cpu_addr[26:23] : 4'b0000;
assign ramaddr[22:19] = cpu_addr[22:19];
assign ramaddr[18]    = (sel_kicklower & bootrom) | cpu_addr[18];
assign ramaddr[17:1]  = cpu_addr[17:1];

reg  [31:0] cpu_addr;
reg  [15:0] cpu_dout;
wire [15:0] cpu_din = ramsel ? ramdout : {sel_autoconfig ? autocfg_data : chip_data[15:12], chip_data[11:0]};
reg         wr;
reg         uds_in;
reg         lds_in;
reg  [15:0] chip_data;

always @* begin
	if(cpucfg[1]) begin
		cpu_dout  = cpu_dout_p;
		cpu_addr  = cpu_addr_p;
		cpustate  = cpustate_p;
		cacr      = cacr_p;
		vbr       = vbr_p;
		wr        = wr_p;
		uds_in    = uds_p;
		lds_in    = lds_p;
		reset_out = reset_out_p;
		chip_as   = c_as;
		chip_rw   = c_rw;
		chip_uds  = c_uds;
		chip_lds  = c_lds;
		chip_addr = cpu_addr_p[23:1];
		chip_din  = cpu_dout_p;
		chip_data = chipdout_i;
	end
	else begin
		cpu_dout  = cpu_dout_o;
		cpu_addr  = {cpu_addr_o,1'b0};
		cpustate  = as_o ? 2'b01 : ~{wr_o,wr_o};
		cacr      = 1;
		vbr       = 0;
		wr        = wr_o;
		uds_in    = uds_o;
		lds_in    = lds_o;
		reset_out = reset_out_o;
		chip_as   = ramsel | as_o;
		chip_rw   = wr_o;
		chip_uds  = uds_o;
		chip_lds  = lds_o;
		chip_addr = cpu_addr_o[23:1];
		chip_din  = cpu_dout_o;
		chip_data = chip_dout;
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

`ifdef M68K20

M68K_Core cpu_inst_p
(
	.i_clk(clk),
	.i_ena(~cpu_req | chipready | ramready),

	.i_rst(~reset),        // note active high
	.o_reset_l(reset_out_p),

	.i_cpu_type(cpucfg),

	.i_ipl_l(cpu_ipl),
	.i_ipl_autovector(1),

	.i_data(cpu_din),
	.o_addr(cpu_addr_p),
	.o_data(cpu_dout_p),
	.o_wr_l(wr_p),
	.o_uds_l(uds_p),
	.o_lds_l(lds_p),
	.o_busstate(cpustate_p), // 00-> fetch code 10->read data 11->write data 01->no memaccess

	.o_cacr(cacr_p),
	.o_vbr(vbr_p)
);

`else

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
  .clkena_in(~cpu_req | chipready | ramready),
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
  
  .cpu(cpucfg),
  .busstate(cpustate_p),		// 0: fetch code, 1: no memaccess, 2: read data, 3: write data
  .cacr_out(cacr_p),
  .vbr_out(vbr_p)
);

`endif

wire [15:0] cpu_dout_o;
wire [23:1] cpu_addr_o;
wire  [2:0] fc_o;
wire        wr_o;
wire        as_o;
wire        uds_o;
wire        lds_o;
wire        reset_out_o;

fx68k cpu_inst_fx68k
(
	.clk(clk),
	.enPhi1(ph1),
	.enPhi2(ph2),

	.extReset(~reset),
	.pwrUp(~reset),
	.oRESETn(reset_out_o),

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
		dcache_d <= 0;
	end
	else if (~cpu_req) begin	// No mem access, so safe to switch chipram access mode
		turbochip_d <= turbochipram & cpucfg[1];
		turbokick_d <= turbokick & cpucfg[1];
		dcache_d <= dcache;
	end
end

wire cfg_z3 = fastramcfg[2] & cpucfg[1];

reg [3:0] autocfg_data;
always @(*) begin
	autocfg_data = 4'b1111;
  
	if (autocfg_card) begin
		if (~cfg_z3) begin
			// Zorro II RAM (Up to 8 meg at 0x200000)
			case (chip_addr[6:1])
				6'b000000: autocfg_data = 4'b1110;	// Zorro-II card, add mem, no ROM
				6'b000001:
					case (fastramcfg)
							   1: autocfg_data = 4'b0110; // 2MB
							   2: autocfg_data = 4'b0111; // 4MB
						default: autocfg_data = 4'b0000; // 8MB
					endcase
				6'b001000: autocfg_data = 4'b1110;	// Manufacturer ID: 0x139c
				6'b001001: autocfg_data = 4'b1100;
				6'b001010: autocfg_data = 4'b0110;
				6'b001011: autocfg_data = 4'b0011;
				6'b010011: autocfg_data = 4'b1110; //serial=1
				  default:;
			endcase
		end
		else begin
			// Zorro III RAM 128MB/256MB
			case (chip_addr[6:1])
				6'b000000: autocfg_data = 4'b1010;	// Zorro-III card, add mem, no ROM
				6'b000001: autocfg_data = autocfg_card[1] ? 4'b0011 : 4'b0100;	// 128MB or 256MB, extended
				6'b000010: autocfg_data = 4'b1110;	// ProductID=0x10 (only setting upper nibble)
				6'b000100: autocfg_data = 4'b0000;	// Memory card, not silenceable, Extended size, reserved.
				6'b000101: autocfg_data = 4'b1111;	// 0000 - logical size matches physical size TODO change this to 0001, so it is autosized by the OS, WHEN it will be 24MB.
				6'b001000: autocfg_data = 4'b1110;	// Manufacturer ID: 0x139c
				6'b001001: autocfg_data = 4'b1100;
				6'b001010: autocfg_data = 4'b0110;
				6'b001011: autocfg_data = 4'b0011;
				6'b010011: autocfg_data = {2'b11, ~autocfg_card};	// serial=1/2
				  default:;
			endcase
		end
	end
end

wire sel_autoconfig = fastramcfg && chip_addr[23:19] == 5'b11101 && autocfg_card; //$E80000 - $EFFFFF

reg [1:0] autocfg_card;
reg       z2ram_ena;
reg [4:0] z3ram_base0;
reg [3:0] z3ram_base1;
reg       z3ram_ena0;
reg       z3ram_ena1;
always @(posedge clk) begin
	reg old_uds;
	old_uds <= chip_uds;

	if (~reset | ~reset_out) begin
		autocfg_card <= 1;		//autoconfig on
		z2ram_ena <= 0;
		z3ram_ena0 <= 0;
		z3ram_ena1 <= 0;
		z3ram_base0 <= 1;
		z3ram_base1 <= 1;
	end
	else if (sel_autoconfig && ~chip_rw && ~chip_uds && old_uds) begin
		if (~cfg_z3) begin
			if (chip_addr[6:1] == 6'b100100) begin // Register 0x48 - config, ZII RAM
				z2ram_ena <= 1;
				autocfg_card <= 0;
			end
		end
		else if (chip_addr[6:1] == 6'b100010)	begin // Register 0x44, assign base address to ZIII RAM.
			if (autocfg_card == 1) begin
				z3ram_base1 <= cpu_dout[15:12];
				z3ram_ena1 <= 1;
				autocfg_card <= {fastramcfg[0], 1'b0};
			end
			else begin
				z3ram_base0 <= cpu_dout[15:11];
				z3ram_ena0 <= 1;
				autocfg_card <= 0;
			end
		end
	end
end

reg        chipreq;
reg  [2:0] cpu_ipl;
always @(posedge clk) begin
	chipreq    <= cpu_req & ~ramsel;
	cpu_ipl    <= ipl_i;
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

endmodule
