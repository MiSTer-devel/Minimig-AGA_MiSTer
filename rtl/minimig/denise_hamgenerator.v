// this module handles the hold and modify mode (HAM)
// the module has its own colour pallete bank, this is to let 
// the sprites run simultanously with a HAM playfield


module denise_hamgenerator
(
	input	clk,					// 35ns pixel clock
  input clk7_en,
	input 	[8:1] reg_address_in,	// register adress inputs
	input 	[11:0] data_in,			// bus data in
	input	[5:0] bpldata,			// bitplane data input
	output	reg [11:0] rgb			// RGB output
);

//register names and adresses		
parameter COLORBASE = 9'h180;  		// colour table base address

//local signals
reg 	[11:0] colortable [15:0];	// colour table
wire	[11:0] selcolor;			// selected colour output from colour table

//--------------------------------------------------------------------------------------

//writing of HAM colour table from bus (implemented using dual port distributed ram)
/*always @(posedge clk28m)*/
always @(posedge clk)
  if (clk7_en) begin
  	if (reg_address_in[8:5]==COLORBASE[8:5])
  		colortable[reg_address_in[4:1]] <= data_in[11:0];
  end

//reading of colour table
assign selcolor = colortable[bpldata[3:0]];   

//--------------------------------------------------------------------------------------

//HAM instruction decoder/processor
always @(posedge clk)
begin
	case (bpldata[5:4])
		2'b00://load rgb output with colour from table	
			rgb <= selcolor;
		2'b01://hold green and red, modify blue
			rgb  <= {rgb[11:4],bpldata[3:0]};	
		2'b10://hold green and blue, modify red
			rgb <= {bpldata[3:0],rgb[7:0]};
		2'b11://hold blue and red, modify green
			rgb <= {rgb[11:8],bpldata[3:0],rgb[3:0]};
	endcase
end

endmodule

