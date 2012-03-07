// Copyright (C) 1991-2011 Altera Corporation
// Your use of Altera Corporation's design tools, logic functions 
// and other software and tools, and its AMPP partner logic 
// functions, and any output files from any of the foregoing 
// (including device programming or simulation files), and any 
// associated documentation or information are expressly subject 
// to the terms and conditions of the Altera Program License 
// Subscription Agreement, Altera MegaCore Function License 
// Agreement, or other applicable license agreement, including, 
// without limitation, that your use is for the sole purpose of 
// programming logic devices manufactured by Altera and sold by 
// Altera or its authorized distributors.  Please refer to the 
// applicable agreement for further details.
//////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////// LPM_MULT for Formal Verification ////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////
// MODEL BEGIN
module lpm_mult (
// INTERFACE BEGIN
        dataa, datab,     // multiplicand,multiplier
        sum,              // partial sum 
	clock,            // pipeline clock
        clken,            // clock enable
	aclr,             // asynch clear
        result            // product
);
// INTERFACE END
//// default parameters ////

parameter lpm_type = "lpm_mult";
parameter lpm_widtha = 1;
parameter lpm_widthb = 1;
parameter lpm_widths = 1;
parameter lpm_widthp = 1;
parameter lpm_representation  = "UNSIGNED";
parameter lpm_pipeline  = 0;
parameter lpm_hint = "UNUSED";
parameter intended_device_family = "UNUSED";

// Local parameters
parameter max_width = ( lpm_widtha >= lpm_widthb ) ? lpm_widtha : lpm_widthb;

`ifdef MULT_NORMALIZE_SIZE
parameter normalized_width = ( max_width <= 9 ) ? 9 :
	( ( max_width <= 18 ) ? 18 : max_width );
`else
parameter normalized_width = 1;
`endif


parameter  adder_width = (lpm_widths > lpm_widtha + lpm_widthb) ? lpm_widths : lpm_widtha + lpm_widthb,
           lpm_in_pipeline  = (lpm_pipeline > 0)                ? 1          : 0,


	   lpm_out_pipeline = lpm_pipeline - lpm_in_pipeline; 

//// port declarations ////

input  clock;
input  clken;
input  aclr;
input  [lpm_widtha-1:0] dataa;
input  [lpm_widthb-1:0] datab;
input  [lpm_widths-1:0] sum;
output [lpm_widthp-1:0] result;

//// constants ////
//// variables ////

integer i;

//// nets/registers ////

wire sign_a,sign_b,sign_sum;
wire [lpm_widtha + lpm_widthb - 1:0] product;
wire signed [adder_width - 1 : 0] augend;
wire signed [adder_width : 0]     add_out;
 
wire [lpm_widtha-1:0] dataa_piped;
wire [lpm_widthb-1:0] datab_piped;
wire [lpm_widths - 1:0] sum_reg;
wire [adder_width - 1:0] sum_piped;
wire [adder_width - 1:0] multout_piped;

// IMPLEMENTATION BEGIN
//////////////////////////// asynchronous logic ////////////////////////////////////////


assign sign_a   = (lpm_representation == "SIGNED");
assign sign_b   = (lpm_representation == "SIGNED");
assign sign_sum = (lpm_representation == "SIGNED");

// ************** Multiplier logic  *************** //

mult_block #(
	.width_a(lpm_widtha),
	.width_b(lpm_widthb),
	.normalized_width(normalized_width)
) multiply (
        .dataa(dataa_piped) ,.datab(datab_piped),
        .signa(sign_a),.signb(sign_b),
        .product(product)
);

// ************** Adder logic  ******************* //

assign augend = (product[lpm_widtha + lpm_widthb - 1] & (sign_a | sign_b)) 
		? {{(adder_width - lpm_widtha - lpm_widthb){1'b1}},product} 
                : {{(adder_width - lpm_widtha - lpm_widthb){1'b0}},product};

assign sum_piped = (sum_reg[lpm_widths - 1] & sign_sum) 
                ? {{(adder_width - lpm_widths){1'b1}},sum_reg} 
                : {{(adder_width - lpm_widths){1'b0}},sum_reg};

addsub_block #(adder_width, adder_width) add (
        .dataa(multout_piped),.datab(sum_piped), 
        .signa(sign_a | sign_b) ,.signb(sign_sum), 
        .addsub(1'b1),
        .sum(add_out)
);

// ************** Pipeline logic ************ //
// When lpm_width is larger than adder_width, sign extend the 
// result to the larger lpm_width

generate 
if (lpm_widthp < adder_width)
assign result = add_out[adder_width - 1:adder_width - lpm_widthp];
else
assign result = 
        (add_out[adder_width] && (sign_a | sign_b |sign_sum)) ?
          {{(lpm_widthp - adder_width){1'b1}},add_out} : 
	  {{(lpm_widthp - adder_width){1'b0}},add_out};

endgenerate

//////////////////////////// synchronous logic  ////////////////////////////////////////

pipeline_internal_fv #(lpm_widtha,lpm_in_pipeline) inda_latency (
                .clk(clock),
                .ena(clken) ,
                .clr(aclr),
                .d(dataa),
                .piped(dataa_piped)
                );

pipeline_internal_fv #(lpm_widthb,lpm_in_pipeline) indb_latency (
                .clk(clock),
                .ena(clken) ,
                .clr(aclr),
                .d(datab),
                .piped(datab_piped)
                );

pipeline_internal_fv #(lpm_widths,lpm_pipeline) sum_latency (
                .clk(clock),
                .ena(clken) ,
                .clr(aclr),
                .d(sum),
                .piped(sum_reg)
                );

pipeline_internal_fv #(adder_width,lpm_out_pipeline) mult_latency (
                .clk(clock),
                .ena(clken) ,
                .clr(aclr),
                .d(augend),
                .piped(multout_piped)
                );

// IMPLEMENTATION END
endmodule
// MODEL END
