//
// hps_io for Minimig
// Copyright (c) 2019 Alexey Melnikov
//
// This source file is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This source file is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
///////////////////////////////////////////////////////////////////////


module hps_io_minimig #(parameter STRLEN=0)
( 
	input             clk_sys,
	inout      [45:0] HPS_BUS,
	
	input             ce_pix,

	// parameter STRLEN and the actual length of conf_str have to match
	input [(8*STRLEN)-1:0] conf_str,

	output            IO_STROBE,
	output     [15:0] IO_DIN,
	output            FPGA_ENA,
	output            UIO_ENA,
	input      [15:0] FPGA_DOUT,
	input             FPGA_WAIT,

	output     [15:0] JOY0,
	output     [15:0] JOY1,
	output     [15:0] JOY2,
	output     [15:0] JOY3,

	output      [2:0] MOUSE_BUTTONS,
	output            KMS_LEVEL,
	output      [1:0] KBD_MOUSE_TYPE,
	output      [7:0] KBD_MOUSE_DATA,

	output      [1:0] BUTTONS,
	input             new_vmode,
	output            forced_scandoubler,

	input      [11:0] scr_hbl_l, scr_hbl_r,
	input      [11:0] scr_hsize,
	input      [11:0] scr_vbl_t, scr_vbl_b,
	input      [11:0] scr_vsize,
	input       [6:0] scr_flg,
	input       [1:0] scr_res,

	output reg [11:0] shbl_l, shbl_r,
	output reg [11:0] svbl_t, svbl_b,
	output reg        sset,

	// [15]: 0 - unset, 1 - set. [1:0]: 0 - none, 1 - 32MB, 2 - 64MB, 3 - 128MB
	// [14]: debug mode: [8]: 1 - phase up, 0 - phase down. [7:0]: amount of shift.
	output reg [15:0] sdram_sz,

	output reg [63:0] RTC,

	inout      [21:0] gamma_bus
);

assign FPGA_ENA  = HPS_BUS[35];
assign UIO_ENA   = HPS_BUS[34];
assign IO_STROBE = HPS_BUS[33];
wire [15:0] io_din = HPS_BUS[31:16];

assign IO_DIN = io_din;

assign HPS_BUS[37]   = FPGA_WAIT;
assign HPS_BUS[36]   = clk_sys;
assign HPS_BUS[32]   = 0;
assign HPS_BUS[15:0] = UIO_ENA ? io_dout : FPGA_DOUT;

/////////////////////////////////////////////////////////

wire [15:0] vc_dout;
video_calc video_calc
(
	.clk_100(HPS_BUS[43]),
	.clk_vid(clk_sys),
	.ce_pix(ce_pix),
	.de(HPS_BUS[40]),
	.hs(HPS_BUS[39]),
	.vs(HPS_BUS[38]),
	.vs_hdmi(HPS_BUS[44]),
	.f1(HPS_BUS[45]),
	.new_vmode(new_vmode),

	.par_num(byte_cnt[3:0]),
	.dout(vc_dout)
);

/////////////////////////////////////////////////////////

assign     gamma_bus[20:0] = {clk_sys, gamma_en, gamma_wr, gamma_wr_addr, gamma_value};
reg        gamma_en;
reg        gamma_wr;
reg  [9:0] gamma_wr_addr;
reg  [7:0] gamma_value;

//////////////////////////////////////////////////////////

reg [15:0] joystick_0;
reg [15:0] joystick_1;
reg [15:0] joystick_2;
reg [15:0] joystick_3;

reg [7:0] cfg;

reg       kbd_mouse_level;
reg [1:0] kbd_mouse_type;
reg [7:0] kbd_mouse_data;
reg [2:0] mouse_buttons;

assign JOY0 = joystick_0;
assign JOY1 = joystick_1;
assign JOY2 = joystick_2;
assign JOY3 = joystick_3;

assign KBD_MOUSE_DATA = kbd_mouse_data; // 8 bit movement data
assign KBD_MOUSE_TYPE = kbd_mouse_type; // 0=mouse x,1=mouse y, 2=keycode, 3=OSD kbd
assign KMS_LEVEL = kbd_mouse_level;     // toggle on new data
assign MOUSE_BUTTONS = mouse_buttons;   // state of the two mouse buttons

assign BUTTONS = cfg[1:0];
assign forced_scandoubler = cfg[4];

reg [15:0] io_dout;
reg  [9:0] byte_cnt;

always@(posedge clk_sys) begin
	reg [7:0] cmd;

	sset <= 0;

	if(~UIO_ENA) begin
		byte_cnt <= 0;
		cmd <= 0;
		if(cmd == 'h2D) sset <= 1;
	end
	else if(IO_STROBE) begin
		io_dout <= 0;

		if(~&byte_cnt) byte_cnt <= byte_cnt + 1'd1;

		if(byte_cnt == 0) begin
			cmd <= io_din[7:0];
			case(io_din[7:0])
				'h04: kbd_mouse_type <= 0;  // first mouse axis
				'h05: kbd_mouse_type <= 2;  // keyboard
				'h06: kbd_mouse_type <= 3;  // OSD keyboard	
				'h2B: io_dout <= 1;
				'h2F: io_dout <= 1;
				'h32: io_dout <= gamma_bus[21];
			endcase
		end
		else begin
		
			case(cmd)
				'h01: cfg <= io_din[7:0];
				'h02: if(byte_cnt==1) joystick_0[15:0] <= io_din;
				'h03: if(byte_cnt==1) joystick_1[15:0] <= io_din;
				'h16: if(byte_cnt==1) joystick_2[15:0] <= io_din;
				'h17: if(byte_cnt==1) joystick_3[15:0] <= io_din;
				
				// mouse, keyboard or OSD
				'h05,
				'h06:
					if(byte_cnt == 1) begin
						kbd_mouse_data <= io_din[7:0];
						kbd_mouse_level <= ~kbd_mouse_level;
					end
				
				'h04:
					if(byte_cnt == 1) begin
						kbd_mouse_data <= io_din[7:0];
						kbd_mouse_level <= ~kbd_mouse_level;
					end
					else if(byte_cnt == 2) begin
						// second byte contains movement data
						kbd_mouse_data <= io_din[7:0];
						kbd_mouse_type <= 1;
						kbd_mouse_level <= ~kbd_mouse_level; 
					end
					else if(byte_cnt == 3) begin
						// third byte contains the buttons
						mouse_buttons <= io_din[2:0];
					end
					
				'h14: if(byte_cnt < STRLEN + 1) io_dout[7:0] <= conf_str[(STRLEN - byte_cnt)<<3 +:8];
				'h22: if(byte_cnt > 0) RTC[(byte_cnt-6'd1)<<4 +:16] <= io_din;
				'h23: if(byte_cnt > 0 && !byte_cnt[5:4]) io_dout <= vc_dout;

				'h2C:
					case(byte_cnt)
						1: io_dout <= {1'b1, scr_flg, 6'd0, scr_res};
						2: io_dout <= scr_hsize;
						3: io_dout <= scr_vsize;
						4: io_dout <= scr_hbl_l;
						5: io_dout <= scr_hbl_r;
						6: io_dout <= scr_vbl_t;
						7: io_dout <= scr_vbl_b;
					endcase

				'h2D:
					case(byte_cnt)
						1: shbl_l <= io_din[11:0];
						2: shbl_r <= io_din[11:0];
						3: svbl_t <= io_din[11:0];
						4: svbl_b <= io_din[11:0];
					endcase

				//UART flags
				'h28: io_dout <= 16'b000_11111_000_11111;

				//sdram size set
				'h31: if(byte_cnt == 1) sdram_sz <= io_din;
			
				// Gamma
				'h32: gamma_en <= io_din[0];
				'h33:
					begin
						gamma_wr_addr <= {(byte_cnt[1:0]-1'b1),io_din[15:8]};
						{gamma_wr, gamma_value} <= {1'b1,io_din[7:0]};
						if (byte_cnt[1:0] == 3) byte_cnt <= 1;
					end
			endcase
		end
	end
end

endmodule
