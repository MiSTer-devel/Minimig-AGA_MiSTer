//this is the bitplane parallel to serial converter


module denise_bitplane_shifter
(
	input 	clk,		   		//35ns pixel clock
  input clk7_en,
	input	c1,
	input	c3,
	input	load,				//load shift register
	input	hires,				//high resolution select
	input	shres,				//super high resolution select (takes priority over hires)
	input	[15:0] data_in,		//parallel load data input
	input	[3:0] scroll,		//scrolling value
	output	out					//shift register out
);


//local signals
reg		[15:0] shifter;			//main shifter
reg		[15:0] scroller;		//scroller shifter
reg		shift;					//shifter enable
reg	 	[3:0] select;			//delayed pixel select
wire	scroller_out;
reg		[3:0] delay;


//main shifter
always @(posedge clk)
	if (load && !c1 && !c3) //load new data into shifter
		shifter[15:0] <= data_in[15:0];
	else if (shift) //shift already loaded data
		shifter[15:0] <= {shifter[14:0],1'b0};

always @(posedge clk)
	if (shift) //shift scroller data
		scroller[15:0] <= {scroller[14:0],shifter[15]};

assign scroller_out = scroller[select[3:0]];//select odd pixel

//--------------------------------------------------------------------------------------

//delay by one low resolution pixel
always @(posedge clk)
	delay[3:0] <= {delay[2:0], scroller_out};
	
// select output pixel
assign out = delay[3];

//--------------------------------------------------------------------------------------

// main shifter and scroller control
always @(*)
	if (shres) // super hires mode
	begin
		shift = 1'b1; // shifter always enabled
		select[3:0] = {scroll[1:0],2'b11}; // scroll in 4 pixel steps
	end
	else if (hires) // hires mode
	begin
		shift = ~c1 ^ c3; // shifter enabled every other clock cycle
		select[3:0] = {scroll[2:0],1'b1}; // scroll in 2 pixel steps
	end
	else // lowres mode
	begin
		shift = ~c1 & ~c3; // shifter enabled once every 4 clock cycles
		select[3:0] = scroll[3:0]; // scroll in 1 pixel steps
	end
			
endmodule

