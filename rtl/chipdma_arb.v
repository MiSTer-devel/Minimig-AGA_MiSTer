// SPDX-License-Identifier: GPL-3.0-or-later

module chipdma_arb
(
	input             clk,
	input             reset,
	input             c_7m,

	input      [24:1] chip_in_addr,
	input             chip_in_l,
	input             chip_in_u,
	input             chip_in_rw,
	input             chip_in_dma,
	input      [15:0] chip_in_wr,

	input             akiko_dma_req,
	input             akiko_dma_we,
	input      [23:0] akiko_dma_baddr,
	input       [7:0] akiko_dma_wbyte,
	output      [7:0] akiko_dma_rbyte,
	output            akiko_dma_ack,

	input             cdtv_dma_req,
	input             cdtv_dma_we,
	input      [23:0] cdtv_dma_baddr,
	input       [7:0] cdtv_dma_wbyte,
	output      [7:0] cdtv_dma_rbyte,
	output            cdtv_dma_ack,

	output     [24:1] chip_out_addr,
	output            chip_out_l,
	output            chip_out_u,
	output            chip_out_rw,
	output            chip_out_dma,
	output     [15:0] chip_out_wr,
	input      [15:0] chip_in_rd
);

reg c_7m_d;
always @(posedge clk) c_7m_d <= c_7m;
wire c_7m_rise = c_7m & ~c_7m_d;

reg akiko_dma_req_q;
reg cdtv_dma_req_q;
always @(posedge clk) begin
	if (reset) begin
		akiko_dma_req_q <= 1'b0;
		cdtv_dma_req_q  <= 1'b0;
	end else begin
		akiko_dma_req_q <= akiko_dma_req;
		cdtv_dma_req_q  <= cdtv_dma_req;
	end
end

reg [2:0] slot_cnt;

reg [24:1] ak_addr;
reg        ak_l;
reg        ak_u;
reg        ak_rw;
reg [15:0] ak_wr_data;
reg        ak_we;
reg        ak_baddr0;

localparam [1:0]
	S_IDLE     = 2'd0,
	S_DRIVE    = 2'd1,
	S_ACK      = 2'd2,
	S_COOLDOWN = 2'd3;

reg [1:0] state;

reg [7:0] ak_rbyte_r;
reg       ak_ack_r;
reg       cdtv_ack_r;

reg active_is_cdtv;

assign akiko_dma_rbyte = ak_rbyte_r;
assign akiko_dma_ack   = ak_ack_r;
assign cdtv_dma_rbyte  = 8'h00;
assign cdtv_dma_ack    = cdtv_ack_r;

wire minimig_idle = chip_in_dma & chip_in_rw;
wire minimig_busy = ~minimig_idle;

wire any_req       = akiko_dma_req_q | cdtv_dma_req_q;
wire arming_is_cdtv = ~akiko_dma_req_q & cdtv_dma_req_q;

wire        live_we     = arming_is_cdtv ? cdtv_dma_we    : akiko_dma_we;
wire [23:0] live_baddr  = arming_is_cdtv ? cdtv_dma_baddr : akiko_dma_baddr;
wire  [7:0] live_wbyte  = arming_is_cdtv ? cdtv_dma_wbyte : akiko_dma_wbyte;

wire arm_now = (state == S_IDLE) & c_7m_rise & minimig_idle & any_req;

wire arb_request = arm_now | (state == S_DRIVE);

wire arb_drive = arb_request & minimig_idle;

wire [24:1] ak_addr_w    = arm_now ? {1'b0, live_baddr[23:1]}            : ak_addr;
wire        ak_l_w       = arm_now ? ~live_baddr[0]                       : ak_l;
wire        ak_u_w       = arm_now ?  live_baddr[0]                       : ak_u;
wire        ak_rw_w      = arm_now ? ~live_we                             : ak_rw;
wire [15:0] ak_wr_data_w = arm_now ? {live_wbyte, live_wbyte}             : ak_wr_data;

assign chip_out_addr = arb_drive ? ak_addr_w    : chip_in_addr;
assign chip_out_l    = arb_drive ? ak_l_w       : chip_in_l;
assign chip_out_u    = arb_drive ? ak_u_w       : chip_in_u;
assign chip_out_rw   = arb_drive ? ak_rw_w      : chip_in_rw;
assign chip_out_dma  = arb_drive ? 1'b0         : chip_in_dma;
assign chip_out_wr   = arb_drive ? ak_wr_data_w : chip_in_wr;

always @(posedge clk) begin
	if (reset) begin
		state          <= S_IDLE;
		slot_cnt       <= 3'd0;
		ak_ack_r       <= 1'b0;
		cdtv_ack_r     <= 1'b0;
		ak_rbyte_r     <= 8'h00;
		active_is_cdtv <= 1'b0;
	end else begin
		ak_ack_r   <= 1'b0;
		cdtv_ack_r <= 1'b0;

		case (state)
		S_IDLE: begin
			if (arm_now) begin
				ak_addr        <= {1'b0, live_baddr[23:1]};
				ak_u           <= live_baddr[0];
				ak_l           <= ~live_baddr[0];
				ak_rw          <= ~live_we;
				ak_wr_data     <= {live_wbyte, live_wbyte};
				ak_we          <= live_we;
				ak_baddr0      <= live_baddr[0];
				slot_cnt       <= 3'd0;
				active_is_cdtv <= arming_is_cdtv;
				state          <= S_DRIVE;
			end
		end

		S_DRIVE: begin
			slot_cnt <= slot_cnt + 3'd1;
			if (slot_cnt == 3'd3) begin
				if (!ak_we) begin
					ak_rbyte_r <= ak_baddr0 ? chip_in_rd[7:0]
					                        : chip_in_rd[15:8];
				end
				state <= S_ACK;
			end
		end

		S_ACK: begin
			if (active_is_cdtv) cdtv_ack_r <= 1'b1;
			else                ak_ack_r   <= 1'b1;
			state <= S_COOLDOWN;
		end

		S_COOLDOWN: begin
			state <= S_IDLE;
		end
		endcase
	end
end

endmodule
