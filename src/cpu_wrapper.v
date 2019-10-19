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
   input         reset,
   output        nResetOut,

   input         clk,
   input         ce_7,

   input   [1:0] cpu,
   input   [2:0] fastramcfg,
   input         turbochipram,
   input         turbokick,
   input         bootrom,

   output [31:0] addr,
   input  [15:0] data_read,
   output [15:0] data_write,
   output reg    as,
   output reg    uds,
   output reg    lds,
   output reg    rw,
   input         dtack,
   output  [1:0] cpustate,
   input   [2:0] IPL,

   output [28:1] ramaddr,
   input  [15:0] fromram,
   input         ramready,
   output reg    ramcs,
   output        ramlds,
   output        ramuds,

   output        cache_inhibit,
   output  [3:0] CACR_out,
   output [31:0] VBR_out
);   

// NMI
reg [31:0] NMI_addr;
always @(posedge clk) NMI_addr <= reset ? (VBR_out + 32'h7c) : 32'h7c;

assign addr = cpuaddr;
wire [15:0] cpu_din = (sel_ram & ~sel_nmi_vector) ? fromram : 
				  (sel_autoconfig) ? {autoconfig_data, data[11:0]} : 
				  data;

wire sel_autoconfig = fastramcfg && cpuaddr[23:19] == 5'b11101 && autoconfig_card; 		//$E80000 - $EFFFFF
wire sel_z3ram0 = (cpuaddr[31:27] == z3ram_base0) && z3ram_ena0;
wire sel_z3ram1 = (cpuaddr[31:28] == z3ram_base1) && z3ram_ena1;
wire sel_z2ram  = !cpuaddr[31:24] && ((cpuaddr[23:21] == 3'b001) || (cpuaddr[23:21] == 3'b010) || (cpuaddr[23:21] == 3'b011) || (cpuaddr[23:21] == 3'b100)) && z2ram_ena;

// turbochip is off during boot overlay
wire sel_chipram = !cpuaddr[31:21] && turbochip_d; 		//$000000 - $1FFFFF

// don't sel_kickram when writing (cpustate = "11")
wire sel_kickram   = !cpuaddr[31:24] && (&cpuaddr[23:19] || (cpuaddr[23:19] == 5'b11100)) && turbokick_d && (cpustate != 3);	// $f8xxxx, e0xxxx
wire sel_kicklower = !cpuaddr[31:24] && (cpuaddr[23:18] == 6'b111110);

//  we route everything hrtmon related through cart.v (needs a couple of signals to
//  decide what to do, would not be good style to replicate that here). 
wire sel_nmi_vector = (cpuaddr[31:2] == NMI_addr[31:2]) && (cpustate == 2);

wire sel_ram = cpu_req & ~sel_nmi_vector & (sel_z2ram | sel_z3ram0 | sel_z3ram1 | sel_chipram | sel_kickram);
wire sel_zram = sel_z3ram0 | sel_z3ram1 | sel_z2ram;

assign cache_inhibit = 0;

assign ramlds = lds_in;
assign ramuds = uds_in;

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
assign ramaddr[27]    = sel_zram & (~sel_z3ram1 | cpuaddr[27]);
assign ramaddr[26:23] = (sel_z3ram0 | sel_z3ram1) ? cpuaddr[26:23] : 4'b0000;
assign ramaddr[22:19] = cpuaddr[22:19];
assign ramaddr[18]    = (sel_kicklower & bootrom) | cpuaddr[18];
assign ramaddr[17:1]  = cpuaddr[17:1];

wire wr;
wire uds_in;
wire lds_in;
wire [31:0] cpuaddr;

wire cpu_req = (cpustate != 1);

TG68KdotC_Kernel
#(
	.sr_read(2),        // 0=>user,   1=>privileged,    2=>switchable with CPU(0)
	.vbr_stackframe(2), // 0=>no,     1=>yes/extended,  2=>switchable with CPU(0)
	.extaddr_mode(2),   // 0=>no,     1=>yes,           2=>switchable with CPU(1)
	.mul_mode(2),       // 0=>16Bit,  1=>32Bit,         2=>switchable with CPU(1),  3=>no MUL,
	.div_mode(2),       // 0=>16Bit,  1=>32Bit,         2=>switchable with CPU(1),  3=>no DIV,
	.bitfield(2)        // 0=>no,     1=>yes,           2=>switchable with CPU(1)
)
cpu_inst
(
  .clk(clk),
  .nreset(reset),		//low active
  .clkena_in(cen),
  .data_in(cpu_din),
  .ipl(cpuIPL),
  .ipl_autovector(1),
  .regin_out(),
  .addr_out(cpuaddr),
  .data_write(data_write),
  .nwr(wr),
  .nuds(uds_in),
  .nlds(lds_in),
  .nresetout(nResetOut),
  
  .cpu(cpu),
  .busstate(cpustate),		// 0: fetch code, 1: no memaccess, 2: read data, 3: write data
  .cacr_out(CACR_out),
  .vbr_out(VBR_out)
);

reg turbochip_d;
reg turbokick_d;
always @(posedge clk) begin
	if (~reset | ~nResetOut) begin
		turbochip_d <= 0;
		turbokick_d <= 0;
	end
	else if (~cpu_req) begin	// No mem access, so safe to switch chipram access mode
		turbochip_d <= turbochipram;
		turbokick_d <= turbokick;
	end
end

reg [3:0] autoconfig_data;
always @(*) begin
	autoconfig_data = 4'b1111;
  
	if (autoconfig_card) begin
		if (~fastramcfg[2]) begin
			// Zorro II RAM (Up to 8 meg at 0x200000)
			case (cpuaddr[6:1])
				6'b000000: autoconfig_data = 4'b1110;	// Zorro-II card, add mem, no ROM
				6'b000001:
					case (fastramcfg[1:0])
							   1: autoconfig_data = 4'b0110; // 2MB
							   2: autoconfig_data = 4'b0111; // 4MB
						default: autoconfig_data = 4'b0000; // 8MB
					endcase
				6'b001000: autoconfig_data = 4'b1110;	// Manufacturer ID: 0x139c
				6'b001001: autoconfig_data = 4'b1100;
				6'b001010: autoconfig_data = 4'b0110;
				6'b001011: autoconfig_data = 4'b0011;
				6'b010011: autoconfig_data = 4'b1110; //serial=1
				  default:;
			endcase
		end
		else begin
			// Zorro III RAM 128MB/256MB
			case (cpuaddr[6:1])
				6'b000000: autoconfig_data = 4'b1010;	// Zorro-III card, add mem, no ROM
				6'b000001: autoconfig_data = autoconfig_card[1] ? 4'b0011 : 4'b0100;	// 128MB or 256MB, extended
				6'b000010: autoconfig_data = 4'b1110;	// ProductID=0x10 (only setting upper nibble)
				6'b000100: autoconfig_data = 4'b0000;	// Memory card, not silenceable, Extended size, reserved.
				6'b000101: autoconfig_data = 4'b1111;	// 0000 - logical size matches physical size TODO change this to 0001, so it is autosized by the OS, WHEN it will be 24MB.
				6'b001000: autoconfig_data = 4'b1110;	// Manufacturer ID: 0x139c
				6'b001001: autoconfig_data = 4'b1100;
				6'b001010: autoconfig_data = 4'b0110;
				6'b001011: autoconfig_data = 4'b0011;
				6'b010011: autoconfig_data = {2'b11, ~autoconfig_card};	// serial=1/2
				  default:;
			endcase
		end
	end
end

reg [1:0] autoconfig_card;
reg       z2ram_ena;
reg [4:0] z3ram_base0;
reg [3:0] z3ram_base1;
reg       z3ram_ena0;
reg       z3ram_ena1;

always @(posedge clk) begin
	if (~reset | ~nResetOut) begin
		autoconfig_card <= 1;		//autoconfig on
		z2ram_ena <= 0;
		z3ram_ena0 <= 0;
		z3ram_ena1 <= 0;
		z3ram_base0 <= 1;
		z3ram_base1 <= 1;
	end
	else if (sel_autoconfig && (cpustate == 3) && ~uds_in && cen) begin
		if (~fastramcfg[2]) begin
			if (cpuaddr[6:1] == 6'b100100) begin // Register 0x48 - config, ZII RAM
				z2ram_ena <= 1;
				autoconfig_card <= 0;
			end
		end
		else if (cpuaddr[6:1] == 6'b100010)	begin // Register 0x44, assign base address to ZIII RAM.
			if (autoconfig_card == 1) begin
				z3ram_base1 <= data_write[15:12];
				z3ram_ena1 <= 1;
				autoconfig_card <= {fastramcfg[0], 1'b0};
			end
			else begin
				z3ram_base0 <= data_write[15:11];
				z3ram_ena0 <= 1;
				autoconfig_card <= 0;
			end
		end
	end
end

wire cen = en && (~cpu_req || (ph1 & chipready) || ramready);
always @(posedge clk) ramcs <= ~cen & sel_ram;

reg en;
reg ph1;
reg ph2;

always @(posedge clk) begin
	reg [3:0] div;
	reg       ce_7D;

	div <= div + 1'd1;
	 
	ce_7D <= ce_7;
	if (~ce_7D & ce_7) div <= 0;

	en <= 0;
	ph1 <= 0;
	ph2 <= 0;
	if (reset && !div[1:0]) begin
		en <= 1;
		case (div[3:2])
			1: ph1 <= 1;
			3: ph2 <= 1;
		endcase
	end
end

reg [15:0] data;
reg  [2:0] cpuIPL;
reg        chipready;

/*
68000 bus timing diagram
          .....   .   .   .   .   .   .   .....   .   .   .   .   .   .   .....
        7 . 0 . 1 . 2 . 3 . 4 . 5 . 6 . 7 . 0 . 1 . 2 . 3 . 4 . 5 . 6 . 7 . 0 . 1
          .....   .   .   .   .   .   .   .....   .   .   .   .   .   .   .....
           ___     ___     ___     ___     ___     ___     ___     ___     ___
CLK    ___/   \___/   \___/   \___/   \___/   \___/   \___/   \___/   \___/   \___
          .....   .   .   .   .   .   .   .....   .   .   .   .   .   .   .....
       _____________________________________________                         _____		  
R/W                 \_ _ _ _ _ _ _ _ _ _ _ _/       \_______________________/     
          .....   .   .   .   .   .   .   .....   .   .   .   .   .   .   .....
       _________ _______________________________ _______________________________ _		  
ADDR   _________X_______________________________X_______________________________X_
          .....   .   .   .   .   .   .   .....   .   .   .   .   .   .   .....
       _____________                     ___________                     _________
/AS                 \___________________/           \___________________/         
          .....   .   .   .       .   .   .....   .   .   .   .       .   .....
       _____________        READ         ___________________    WRITE    _________
/DS                 \___________________/                   \___________/         
          .....   .   .   .   .   .   .   .....   .   .   .   .   .   .   .....
       _____________________     ___________________________     _________________
/DTACK                      \___/                           \___/                 
          .....   .   .   .   .   .   .   .....   .   .   .   .   .   .   .....
                                     ___
DIN    -----------------------------<___>-----------------------------------------
          .....   .   .   .   .   .   .   .....   .   .   .   .   .   .   .....
                                                         ___________________
DOUT   -------------------------------------------------<___________________>-----
          .....   .   .   .   .   .   .   .....   .   .   .   .   .   .   .....
*/

always @(posedge clk, negedge reset) begin
	reg [1:0] state;
	reg waitm;

	if(~reset) begin
		state <= 0;
		as <= 1;
		rw <= 1;
		uds <= 1;
		lds <= 1;
		chipready <= 0;
	end
	else begin

		if(cen) chipready <= 0;

		if (ph1|ph2) begin
			case({state,ph2})
				0: cpuIPL <= IPL;
				1: if (cpu_req & ~sel_ram) state <= 1;
				2: begin
						as <= 0;
						rw <= wr;
						if(wr) {uds,lds} <= {uds_in,lds_in};
					end
				3: state <= 2;
				4: begin
						{uds,lds} <= {uds_in,lds_in};
						waitm  <= dtack;
						cpuIPL <= IPL;
					end
				5: if (~waitm) state <= 3;
				6: chipready <= 1;
				7: begin
						data <= data_read;
						as <= 1;
						rw <= 1;
						uds <= 1;
						lds <= 1;
						state <= 0;
					end
			endcase
		end
	end
end

endmodule
