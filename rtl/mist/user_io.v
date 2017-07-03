module user_io
( 
	input        clk,

	input        IO_ENA,
	input        IO_STROBE,
	input [15:0] IO_DIN,
	output reg   IO_WAIT,

	output [15:0] JOY0,
	output [15:0] JOY1,

	output [2:0] MOUSE_BUTTONS,
	output       KBD_MOUSE_STROBE,
	output       KMS_LEVEL,
	output [1:0] KBD_MOUSE_TYPE,
	output [7:0] KBD_MOUSE_DATA,

	output [1:0] BUTTONS,
	output [3:0] CONF
);

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
	end
end

endmodule
