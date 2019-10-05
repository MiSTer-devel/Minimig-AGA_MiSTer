//
// hps_io for Minimig
//
// Copyright (c) 2017-2019 Alexey Melnikov
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
	output            KBD_MOUSE_STROBE,
	output            KMS_LEVEL,
	output      [1:0] KBD_MOUSE_TYPE,
	output      [7:0] KBD_MOUSE_DATA,

	output      [1:0] BUTTONS,
	input             new_vmode,

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

	output reg [63:0] RTC
);

assign FPGA_ENA  = HPS_BUS[35];
assign UIO_ENA   = HPS_BUS[34];
assign IO_STROBE = HPS_BUS[33];
assign IO_DIN    = HPS_BUS[31:16];

assign HPS_BUS[37]   = io_wait | FPGA_WAIT;
assign HPS_BUS[36]   = clk_sys;
assign HPS_BUS[32]   = 0;
assign HPS_BUS[15:0] = UIO_ENA ? io_dout : FPGA_DOUT;

///////////////// calc video parameters //////////////////

wire clk_100 = HPS_BUS[43];
wire clk_vid = clk_sys;
wire de      = HPS_BUS[40];
wire hs      = HPS_BUS[39];
wire vs      = HPS_BUS[38];
wire vs_hdmi = HPS_BUS[44];
wire f1      = HPS_BUS[45];

reg [31:0] vid_hcnt = 0;
reg [31:0] vid_vcnt = 0;
reg  [7:0] vid_nres = 0;
reg  [1:0] vid_int  = 0;
integer hcnt;

always @(posedge clk_vid) begin
	integer vcnt;
	reg old_vs= 0, old_de = 0, old_vmode = 0;
	reg [3:0] resto = 0;
	reg calch = 0;

	if(ce_pix) begin
		old_vs <= vs;
		old_de <= de;

		if(~vs & ~old_de & de) vcnt <= vcnt + 1;
		if(calch & de) hcnt <= hcnt + 1;
		if(old_de & ~de) calch <= 0;

		if(old_vs & ~vs) begin
			vid_int <= {vid_int[0],f1};
			if(~f1) begin
				if(hcnt && vcnt) begin
					old_vmode <= new_vmode;

					//report new resolution after timeout
					if(resto) resto <= resto + 1'd1;
					if(vid_hcnt != hcnt || vid_vcnt != vcnt || old_vmode != new_vmode) resto <= 1;
					if(&resto) vid_nres <= vid_nres + 1'd1;
					vid_hcnt <= hcnt;
					vid_vcnt <= vcnt;
				end
				vcnt <= 0;
				hcnt <= 0;
				calch <= 1;
			end
		end
	end
end

reg [31:0] vid_htime = 0;
reg [31:0] vid_vtime = 0;
reg [31:0] vid_pix = 0;

always @(posedge clk_100) begin
	integer vtime, htime, hcnt;
	reg old_vs, old_hs, old_vs2, old_hs2, old_de, old_de2;
	reg calch = 0;

	old_vs <= vs;
	old_hs <= hs;

	old_vs2 <= old_vs;
	old_hs2 <= old_hs;

	vtime <= vtime + 1'd1;
	htime <= htime + 1'd1;

	if(~old_vs2 & old_vs) begin
		vid_pix <= hcnt;
		vid_vtime <= vtime;
		vtime <= 0;
		hcnt <= 0;
	end

	if(old_vs2 & ~old_vs) calch <= 1;

	if(~old_hs2 & old_hs) begin
		vid_htime <= htime;
		htime <= 0;
	end

	old_de   <= de;
	old_de2  <= old_de;

	if(calch & old_de) hcnt <= hcnt + 1;
	if(old_de2 & ~old_de) calch <= 0;
end

reg [31:0] vid_vtime_hdmi;
always @(posedge clk_100) begin
	integer vtime;
	reg old_vs, old_vs2;

	old_vs <= vs_hdmi;
	old_vs2 <= old_vs;

	vtime <= vtime + 1'd1;

	if(~old_vs2 & old_vs) begin
		vid_vtime_hdmi <= vtime;
		vtime <= 0;
	end
end

//////////////////////////////////////////////////////////

reg [15:0] joystick0;
reg [15:0] joystick1;
reg [15:0] joystick2;
reg [15:0] joystick3;
reg [7:0] but_sw;

reg       kbd_mouse_strobe;
reg       kbd_mouse_strobe_level;
reg [1:0] kbd_mouse_type;
reg [7:0] kbd_mouse_data;
reg [2:0] mouse_buttons;

assign JOY0 = joystick0;
assign JOY1 = joystick1;
assign JOY2 = joystick2;
assign JOY3 = joystick3;

assign KBD_MOUSE_DATA = kbd_mouse_data; // 8 bit movement data
assign KBD_MOUSE_TYPE = kbd_mouse_type; // 0=mouse x,1=mouse y, 2=keycode, 3=OSD kbd
assign KMS_LEVEL = kbd_mouse_strobe_level; // level change of kbd_mouse_strobe
assign KBD_MOUSE_STROBE = kbd_mouse_strobe;
assign MOUSE_BUTTONS = mouse_buttons; // state of the two mouse buttons

assign BUTTONS  = but_sw[1:0];

reg [15:0] io_dout;
reg        io_wait;

always@(posedge clk_sys) begin
	reg [7:0] cmd;
	reg [5:0] cnt;
	reg [4:0] timeout;

	if(timeout) timeout <= timeout - 1'd1;
	else begin
		io_wait <= 0;
		kbd_mouse_strobe <= 0;
	end

	sset <= 0;

	if(~UIO_ENA) begin
		cnt <= 0;
		io_wait <= 0;
		timeout <= 0;
		cmd <= 0;
		if(cmd == 'h2D) sset <= 1;
	end
	else if(IO_STROBE) begin
		timeout <= 8;
		io_wait <= 1;
		io_dout <= 0;

		if(~&cnt) cnt <= cnt + 1'd1;

		if(cnt == 0) begin
			cmd <= IO_DIN[7:0];
			if(IO_DIN[7:0] == 4) kbd_mouse_type <= 0;  // first mouse axis
			if(IO_DIN[7:0] == 5) kbd_mouse_type <= 2;  // keyboard
			if(IO_DIN[7:0] == 6) kbd_mouse_type <= 3;  // OSD keyboard	
			if(IO_DIN[7:0] == 'h2B) io_dout <= 1;
			if(IO_DIN[7:0] == 'h2F) io_dout <= 1;
		end

		// first payload byte
		if(cnt == 1) begin
			if(cmd == 1) but_sw <= IO_DIN[7:0];
			if(cmd == 2) joystick0 <= IO_DIN; 
			if(cmd == 3) joystick1 <= IO_DIN; 
			if(cmd == 'h10) joystick2 <= IO_DIN;
			if(cmd == 'h11) joystick3 <= IO_DIN;

			// mouse, keyboard or OSD
			if((cmd == 4)||(cmd == 5)||(cmd == 6)) begin
				kbd_mouse_data <= IO_DIN[7:0];
				kbd_mouse_strobe_level <= ~kbd_mouse_strobe_level;
				kbd_mouse_strobe <= 1;
			end
		end	

		// mouse handling
		if(cmd == 4) begin
			// second byte contains movement data
			if(cnt == 2) begin
				kbd_mouse_data <= IO_DIN[7:0];
				kbd_mouse_type <= 1;
				kbd_mouse_strobe_level <= ~kbd_mouse_strobe_level; 
				kbd_mouse_strobe <= 1;
			end

			// third byte contains the buttons
			if(cnt == 3) begin
				mouse_buttons <= IO_DIN[2:0];
			end
		end
		
		// reading config string, returning a byte from string
		if(cmd == 'h14 && (cnt < STRLEN + 1)) io_dout[7:0] <= conf_str[(STRLEN - cnt)<<3 +:8];

		if(cmd == 'h22 && cnt > 0) RTC[(cnt-6'd1)<<4 +:16] <= IO_DIN;
		
		if(cmd == 'h23) begin
			case(cnt)
				1: io_dout <= {|vid_int, vid_nres};
				2: io_dout <= vid_hcnt[15:0];
				3: io_dout <= vid_hcnt[31:16];
				4: io_dout <= vid_vcnt[15:0];
				5: io_dout <= vid_vcnt[31:16];
				6: io_dout <= vid_htime[15:0];
				7: io_dout <= vid_htime[31:16];
				8: io_dout <= vid_vtime[15:0];
				9: io_dout <= vid_vtime[31:16];
			  10: io_dout <= vid_pix[15:0];
			  11: io_dout <= vid_pix[31:16];
			  12: io_dout <= vid_vtime_hdmi[15:0];
			  13: io_dout <= vid_vtime_hdmi[31:16];
			endcase
		end

		if(cmd == 'h2C) begin
			case(cnt)
				1: io_dout <= {1'b1, scr_flg, 6'd0, scr_res};
				2: io_dout <= scr_hsize;
				3: io_dout <= scr_vsize;
				4: io_dout <= scr_hbl_l;
				5: io_dout <= scr_hbl_r;
			   6: io_dout <= scr_vbl_t;
			   7: io_dout <= scr_vbl_b;
			endcase
		end

		if(cmd == 'h2D) begin
			case(cnt)
				1: shbl_l <= IO_DIN[11:0];
				2: shbl_r <= IO_DIN[11:0];
			   3: svbl_t <= IO_DIN[11:0];
			   4: svbl_b <= IO_DIN[11:0];
			endcase
		end

		//UART flags
		if(cmd == 'h28) io_dout <= 16'b000_11111_000_11111;

		//sdram size set
		if(cmd == 'h31 && cnt == 1) sdram_sz <= IO_DIN;
	end
end

endmodule
