
// OKK 09-12-2020

module iir_1pole_filter
(
	clk,
	clk_en,
	rst,
	left_in,
	right_in,
	left_out,
	right_out
);

	// IO Ports
	input clk;
	input clk_en;
	input rst;

	input  [15:0] left_in,  right_in;
	output [15:0] left_out, right_out;

	// Parameters
	wire [26:0] input_fraction	= 27'd29360128; // (1.0 / 32768.0)
	wire [26:0] output_scale	= 27'd37224448; // 32768.0

	// MIST minimig runs at 28.687500MHz

	// Config
	//wire [26:0] filter_gain		= 27'h1D0A041; // (use inverse gain here = 1.0 / GAIN)
	//wire [26:0] filter_coeff	= 27'h1FBFDAF; // 4420Hz cutoff at 24.576MHz stream

	wire [26:0] filter_gain	= 27'd31195225; // (use inverse gain here = 1.0 / GAIN)
	wire [26:0] filter_coeff	= 27'd33288190; // 4429Hz cutoff at 3.5MHz stream

	// Wires
	wire [26:0] left_fp, right_fp;
	wire [26:0] left_smp, right_smp;
	wire [26:0] left_flt_in, right_flt_in;
	wire [26:0] left_flt_add0_out, right_flt_add0_out;
	wire [26:0] left_flt_mul0_out, right_flt_mul0_out;
	wire [26:0] left_flt_out, right_flt_out;
	wire [26:0] left_smp_out, right_smp_out;

	wire [15:0] left_int_out, right_int_out;

	// Registers
	reg  [26:0] left_flt_x, right_flt_x;
	reg  [26:0] left_flt_y, right_flt_y;
	reg  [15:0] left_out_int_reg, right_out_int_reg;

	assign left_out = left_out_int_reg;
	assign right_out = right_out_int_reg;

	// Left float operations
	f27_int2float left_input_conv 	(.A (left_in), .Q (left_fp) );
	f27_mul left_input_scaler  	(.A (left_fp),  .B (input_fraction), .Q (left_smp));
	f27_mul left_filter_gain   	(.A (left_smp),  .B (filter_gain), .Q (left_flt_in));
	f27_add left_filter_add0    	(.A (left_flt_x),  .B (left_flt_in),  .Q (left_flt_add0_out));
	f27_mul left_filter_mul0    	(.A (left_flt_y),  .B (filter_coeff), .Q (left_flt_mul0_out));
	f27_add left_filter_output    	(.A (left_flt_add0_out),  .B (left_flt_mul0_out),  .Q (left_flt_out));
	f27_mul left_output_scaler  	(.A (left_flt_y),  .B (output_scale), .Q (left_smp_out));
	f27_float2int left_output_conv	(.A (left_smp_out), .Q (left_int_out));

	// Right float operations
	f27_int2float right_input_conv	(.A (right_in), .Q (right_fp) );
	f27_mul right_input_scaler 	(.A (right_fp), .B (input_fraction), .Q (right_smp));
	f27_mul right_filter_gain  	(.A (right_smp), .B (filter_gain), .Q (right_flt_in));
	f27_add right_filter_add0   	(.A (right_flt_x), .B (right_flt_in), .Q (right_flt_add0_out));
	f27_mul right_filter_mul0   	(.A (right_flt_y), .B (filter_coeff), .Q (right_flt_mul0_out));
	f27_add right_filter_output   	(.A (right_flt_add0_out), .B (right_flt_mul0_out), .Q (right_flt_out));
	f27_mul right_output_scaler 	(.A (right_flt_y), .B (output_scale), .Q (right_smp_out));
	f27_float2int right_output_conv	(.A (right_smp_out), .Q (right_int_out));

	// Sequencial logic
	always @(posedge clk) begin
		if (rst) begin
			left_flt_x <= 27'd0; right_flt_x <= 27'd0;
			left_flt_y <= 27'd0; right_flt_y <= 27'd0;

			left_out_int_reg  <= 16'h0000;
			right_out_int_reg <= 16'h0000;
		end

		else if (clk_en) begin
			left_out_int_reg <= left_int_out;
			right_out_int_reg <= right_int_out;

			left_flt_x <= left_flt_in; right_flt_x <= right_flt_in;
			left_flt_y <= left_flt_out; right_flt_y <= right_flt_out;
		end
	end

endmodule
