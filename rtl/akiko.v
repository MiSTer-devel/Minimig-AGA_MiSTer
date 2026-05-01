// Copyright 2021 Alexey Melnikov
// Copyright 2026 (CD32 native-mode register/IRQ extensions)
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
//----------------------------------------------------------------------------------
//
//
//
//
//
//
//----------------------------------------------------------------------------------

module akiko #(parameter NATIVE_CD32 = 0)
(
	input             clk,
	input             reset,
	input             cs,
	input             rd,
	input             wr,
	input             lds,
	input             uds,
	input       [5:1] addr,
	input      [15:0] din,
	output reg [15:0] dout,
	output            akiko_irq
);

localparam [31:0] INTENA_MASK     = 32'hff000000;
localparam [31:0] CONFIG_MASK     = 32'hff800000;
localparam [31:0] ADDRDATA_MASK   = 32'h00fff000;
localparam [31:0] ADDRMISC_MASK   = 32'h00fffc00;

localparam [31:0] CDINT_SUBCODE   = 32'h80000000;
localparam [31:0] CDINT_DRIVEXMIT = 32'h40000000;
localparam [31:0] CDINT_DRIVERECV = 32'h20000000;
localparam [31:0] CDINT_RXDMADONE = 32'h10000000;
localparam [31:0] CDINT_TXDMADONE = 32'h08000000;
localparam [31:0] CDINT_PBX       = 32'h04000000;
localparam [31:0] CDINT_OVERFLOW  = 32'h02000000;

localparam        CDFLAG_PBX_BIT    = 27;
localparam        CDFLAG_ENABLE_BIT = 26;

wire c2p_sel = (addr[5:2] == 'b1110);

reg [7:0] buff[32];
reg [3:0] rptr = 0, wptr = 0;

always @(posedge clk) begin
	if((wr|rd) & cs & c2p_sel) begin
		if (wr) begin
			rptr <= 0;
			wptr <= wptr + 1'd1;
			{buff[{wptr,1'b0}],buff[{wptr,1'b1}]} <= din;
		end
		else begin
			wptr <= 0;
			rptr <= rptr + 1'd1;
		end
	end
end

reg [15:0] c2p_dout;
always @(*) begin : c2p_read
	reg [4:0] i;
	c2p_dout = 16'h0;
	for (i=0; i<16; i=i+1'd1)
		c2p_dout[i] = buff[{rptr[0],~i[3:0]}][rptr[3:1]];
end

wire [15:0] cd_dout;
wire        cd_irq;

generate
if (NATIVE_CD32) begin : g_cd

	reg [31:0] cdrom_intreq;
	reg [31:0] cdrom_intena;
	reg [31:0] cdrom_addressdata;
	reg [31:0] cdrom_addressmisc;
	reg [31:0] cdrom_flags;
	reg [15:0] cdrom_pbx;
	reg  [7:0] cdrom_subcodeoffset;
	reg  [7:0] cdcomtxinx;
	reg  [7:0] cdcomrxinx;
	reg  [7:0] cdcomtxcmp;
	reg  [7:0] cdcomrxcmp;
	reg  [7:0] pio_byte;
	reg  [7:0] nvram_io;
	reg  [7:0] nvram_dir;

	wire write = wr & cs;

	always @(posedge clk) begin
		if (reset) begin
			cdrom_intreq        <= 32'h0;
			cdrom_intena        <= 32'h0;
			cdrom_addressdata   <= 32'h0;
			cdrom_addressmisc   <= 32'h0;
			cdrom_flags         <= 32'h0;
			cdrom_pbx           <= 16'h0;
			cdrom_subcodeoffset <= 8'h0;
			cdcomtxinx          <= 8'h0;
			cdcomrxinx          <= 8'h0;
			cdcomtxcmp          <= 8'h0;
			cdcomrxcmp          <= 8'h0;
			pio_byte            <= 8'h0;
			nvram_io            <= 8'h0;
			nvram_dir           <= 8'h0;
		end else if (write) begin
			case (addr)
				5'b00100: begin : intena_hi
					reg [31:0] tmp;
					tmp = cdrom_intena;
					if (uds) tmp[31:24] = din[15:8];
					if (lds) tmp[23:16] = din[7:0];
					cdrom_intena <= tmp & INTENA_MASK;
				end
				5'b00101: begin : intena_lo
					reg [31:0] tmp;
					tmp = cdrom_intena;
					if (uds) tmp[15:8] = din[15:8];
					if (lds) tmp[7:0]  = din[7:0];
					cdrom_intena <= tmp & INTENA_MASK;
				end
				5'b01000: begin : addrdata_hi
					reg [31:0] tmp;
					tmp = cdrom_addressdata;
					if (uds) tmp[31:24] = din[15:8];
					if (lds) tmp[23:16] = din[7:0];
					cdrom_addressdata <= tmp & ADDRDATA_MASK;
				end
				5'b01001: begin : addrdata_lo
					reg [31:0] tmp;
					tmp = cdrom_addressdata;
					if (uds) tmp[15:8] = din[15:8];
					if (lds) tmp[7:0]  = din[7:0];
					cdrom_addressdata <= tmp & ADDRDATA_MASK;
				end
				5'b01010: begin : addrmisc_hi
					reg [31:0] tmp;
					tmp = cdrom_addressmisc;
					if (uds) tmp[31:24] = din[15:8];
					if (lds) tmp[23:16] = din[7:0];
					cdrom_addressmisc <= tmp & ADDRMISC_MASK;
				end
				5'b01011: begin : addrmisc_lo
					reg [31:0] tmp;
					tmp = cdrom_addressmisc;
					if (uds) tmp[15:8] = din[15:8];
					if (lds) tmp[7:0]  = din[7:0];
					cdrom_addressmisc <= tmp & ADDRMISC_MASK;
				end
				5'b01100: begin
					if (uds) cdrom_intreq <= cdrom_intreq & ~CDINT_SUBCODE;
				end
				5'b01110: begin
					if (lds) begin
						cdcomtxcmp   <= din[7:0];
						cdrom_intreq <= cdrom_intreq & ~CDINT_TXDMADONE;
					end
				end
				5'b01111: begin
					if (lds) begin
						cdcomrxcmp   <= din[7:0];
						cdrom_intreq <= cdrom_intreq & ~CDINT_RXDMADONE;
					end
				end
				5'b10000: begin : pbx_w
					reg [15:0] tmp;
					tmp = cdrom_pbx;
					if (uds) tmp[15:8] = tmp[15:8] | din[15:8];
					if (lds) tmp[7:0]  = tmp[7:0]  | din[7:0];
					if (!cdrom_flags[CDFLAG_PBX_BIT]) tmp = 16'h0;
					cdrom_pbx    <= tmp;
					cdrom_intreq <= cdrom_intreq & ~CDINT_PBX;
				end
				5'b10010: begin : cfg_high
					reg [31:0] new_flags;
					new_flags = cdrom_flags;
					if (uds) new_flags[31:24] = din[15:8];
					if (lds) new_flags[23:16] = din[7:0];
					new_flags = new_flags & CONFIG_MASK;
					cdrom_flags <= new_flags;
					if (new_flags[CDFLAG_ENABLE_BIT] && !cdrom_flags[CDFLAG_ENABLE_BIT])
						cdrom_intreq <= cdrom_intreq & ~CDINT_OVERFLOW;
					if (!new_flags[CDFLAG_PBX_BIT]) cdrom_pbx <= 16'h0;
				end
				5'b10011: begin : cfg_low
					reg [31:0] new_flags;
					new_flags = cdrom_flags;
					if (uds) new_flags[15:8] = din[15:8];
					if (lds) new_flags[7:0]  = din[7:0];
					new_flags = new_flags & CONFIG_MASK;
					cdrom_flags <= new_flags;
				end
				5'b10100: begin
					if (uds) begin
						pio_byte     <= din[15:8];
						cdrom_intreq <= cdrom_intreq & ~CDINT_DRIVEXMIT;
					end
				end
				5'b11000: begin
					if (uds) nvram_io  <= din[15:8];
					if (lds) ;
				end
				5'b11001: begin
					if (uds) nvram_dir <= din[15:8];
				end
				default: ;
			endcase
		end
	end

	reg [15:0] cd_dout_r;
	always @(*) begin
		cd_dout_r = 16'h0;
		case (addr)
			5'b00010: cd_dout_r = cdrom_intreq[31:16];
			5'b00011: cd_dout_r = cdrom_intreq[15:0];
			5'b00100: cd_dout_r = cdrom_intena[31:16];
			5'b00101: cd_dout_r = cdrom_intena[15:0];
			5'b00110: cd_dout_r = cdrom_intena[31:16];
			5'b00111: cd_dout_r = cdrom_intena[15:0];
			5'b01000, 5'b01010, 5'b01100, 5'b01110:
				cd_dout_r = {cdrom_subcodeoffset, cdcomtxinx};
			5'b01001, 5'b01011, 5'b01101, 5'b01111:
				cd_dout_r = {cdcomrxinx, 8'h0};
			5'b10000: cd_dout_r = cdrom_pbx;
			5'b10010: cd_dout_r = cdrom_flags[31:16];
			5'b10011: cd_dout_r = cdrom_flags[15:0];
			5'b10100: cd_dout_r = {pio_byte, 8'h0};
			5'b11000: cd_dout_r = {nvram_io,  8'h0};
			5'b11001: cd_dout_r = {nvram_dir, 8'h0};
			default:  cd_dout_r = 16'h0;
		endcase
	end

	assign cd_dout = cs ? cd_dout_r : 16'h0;
	assign cd_irq  = |(cdrom_intreq[31:25] & cdrom_intena[31:25]);

end else begin : g_stub
	assign cd_dout = 16'h0;
	assign cd_irq  = 1'b0;
end
endgenerate

always @(*) begin
	dout = 16'h0;
	if (cs) begin
		if (addr == 5'd0) dout = 16'hC0CA;
		if (addr == 5'd1) dout = 16'hCAFE;
		if (c2p_sel)      dout = c2p_dout;
	end
	dout = dout | cd_dout;
end

assign akiko_irq = cd_irq;

endmodule
