module user_io
( 
	input        clk,

	input        IO_ENA,
	input        IO_STROBE,
	input [15:0] IO_DIN,
	output[15:0] IO_DOUT,
	output reg   IO_WAIT,

	output [15:0] JOY0,
	output [15:0] JOY1,

	output [2:0] MOUSE_BUTTONS,
	output       KBD_MOUSE_STROBE,
	output       KMS_LEVEL,
	output [1:0] KBD_MOUSE_TYPE,
	output [7:0] KBD_MOUSE_DATA,

	output [1:0] BUTTONS,
	output [3:0] CONF,

	input        clk_100,
	input        clk_vid,
	input        ce_pix,
	input        de,
	input        hs,
	input        vs,
	input        f1,
	input        vs_hdmi,

	output reg [63:0] RTC
);


///////////////// calc video parameters //////////////////

reg [31:0] vid_hcnt = 0;
reg [31:0] vid_vcnt = 0;
reg  [7:0] vid_nres = 0;
integer hcnt;

always @(posedge clk_vid) begin
	integer vcnt;
	reg old_vs= 0, old_de = 0;
	reg calch = 0;

	if(ce_pix) begin
		old_vs <= vs;
		old_de <= de;

		if(~vs & ~old_de & de) vcnt <= vcnt + 1;
		if(calch & de) hcnt <= hcnt + 1;
		if(old_de & ~de) calch <= 0;

		if(old_vs & ~vs & ~f1) begin
			if(hcnt && vcnt) begin
				if(vid_hcnt != hcnt || vid_vcnt != vcnt) vid_nres <= vid_nres + 1'd1;
				vid_hcnt <= hcnt;
				vid_vcnt <= vcnt;
			end
			vcnt <= 0;
			hcnt <= 0;
			calch <= 1;
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
reg [7:0] but_sw;

reg       kbd_mouse_strobe;
reg       kbd_mouse_strobe_level;
reg [1:0] kbd_mouse_type;
reg [7:0] kbd_mouse_data;
reg [2:0] mouse_buttons;

assign JOY0 = joystick0;
assign JOY1 = joystick1;

assign KBD_MOUSE_DATA = kbd_mouse_data; // 8 bit movement data
assign KBD_MOUSE_TYPE = kbd_mouse_type; // 0=mouse x,1=mouse y, 2=keycode, 3=OSD kbd
assign KMS_LEVEL = kbd_mouse_strobe_level; // level change of kbd_mouse_strobe
assign KBD_MOUSE_STROBE = kbd_mouse_strobe;
assign MOUSE_BUTTONS = mouse_buttons; // state of the two mouse buttons

assign BUTTONS  = but_sw[1:0];
assign CONF     = but_sw[7:4];

reg [15:0] io_dout;
assign IO_DOUT = io_dout;

always@(posedge clk) begin
	reg [7:0] cmd;
	reg [5:0] cnt;
	reg [4:0] timeout;

	if(timeout) timeout <= timeout - 1'd1;
	else begin
		IO_WAIT <= 0;
		kbd_mouse_strobe <= 0;
	end

	if(~IO_ENA) begin
		cnt <= 0;
		IO_WAIT <= 0;
		timeout <= 0;
	end
	else if(IO_STROBE) begin
		timeout <= 8;
		IO_WAIT <= 1;

		if(~&cnt) cnt <= cnt + 1'd1;

		if(cnt == 0) begin
			cmd <= IO_DIN[7:0];
			if(IO_DIN[7:0] == 4) kbd_mouse_type <= 2'b00;  // first mouse axis
			if(IO_DIN[7:0] == 5) kbd_mouse_type <= 2'b10;  // keyboard
			if(IO_DIN[7:0] == 6) kbd_mouse_type <= 2'b11;  // OSD keyboard	
		end

		// first payload byte
		if(cnt == 1) begin
			if(cmd == 1) but_sw <= IO_DIN[7:0];
			if(cmd == 2) joystick0 <= IO_DIN; 
			if(cmd == 3) joystick1 <= IO_DIN; 

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
				kbd_mouse_type <= 2'b01;
				kbd_mouse_strobe_level <= ~kbd_mouse_strobe_level; 
				kbd_mouse_strobe <= 1;
			end

			// third byte contains the buttons
			if(cnt == 3) begin
				mouse_buttons <= IO_DIN[2:0];
			end
		end

		if(cmd == 'h22 && cnt > 0) RTC[(cnt-6'd1)<<4 +:16] <= IO_DIN;
		
		if(cmd == 'h23) begin
			case(cnt)
				1: io_dout <= vid_nres;
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

		//UART flags
		if(cmd == 'h28) io_dout <= 16'b000_11111_000_11111;
	end
end

endmodule
