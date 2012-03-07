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
//////////////////////////////// ALTMULT_ADD for Formal Verification /////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////
// MODEL BEGIN
`define W_FRACTION_ROUND 15
`define W_SIGN 2
`define W_MSB 17
`define ADD 1'b1

module altmult_add (
// INTERFACE BEGIN
	dataa,datab,                 // multiplicand,multiplier
	scanina,scaninb,             // scan in
	sourcea,sourceb,             // source
	clock3,clock2,clock1,clock0, // clock inputs clk[3:0]
	aclr3,aclr2,aclr1,aclr0,     // async clear inputs aclr[3:0]
	ena3,ena2,ena1,ena0,         // clock enable inputs ena[3:0]
	signa,signb,                 // sign bits
	addnsub1,addnsub3,           // add or subtract
   mult01_round, mult23_round,  // round enable
   mult01_saturation, mult23_saturation,  // saturation enable
   addnsub1_round, addnsub3_round, // round enable
accum_sload,
chainin,
chainout_round,
chainout_saturate,
output_round,
output_saturate,
rotate,
shift_right,
zero_chainout,
zero_loopback,
	scanouta,scanoutb,           // scan out
	result,                       // product
	mult0_is_saturated,	     // saturated output flag
	mult1_is_saturated,
	mult2_is_saturated,
	mult3_is_saturated,
	chainout_sat_overflow,
	overflow

);
`include "altera_mf_macros.i"

// INTERFACE END
//// top level parameters ////

parameter width_a               = 1;              // Width of the dataa[] operand of each multiplier.
parameter width_b               = 1;              // Width of the datab[] operand of each multiplier.
parameter width_result          = 1;              // Width of the result[] of each multiplier.
parameter number_of_multipliers = 1;              // Number of multipliers used
parameter lpm_type              = "altmult_add";  // lpm type

//// A port related parameters ////

// Input registers for A

parameter input_register_a0 = "CLOCK0";
parameter input_aclr_a0     = "ACLR3";
parameter input_source_a0   = "DATAA";

parameter input_register_a1 = "CLOCK0";
parameter input_aclr_a1     = "ACLR3";
parameter input_source_a1   = "DATAA";

parameter input_register_a2 = "CLOCK0";
parameter input_aclr_a2     = "ACLR3";
parameter input_source_a2   = "DATAA";

parameter input_register_a3 = "CLOCK0";
parameter input_aclr_a3     = "ACLR3";
parameter input_source_a3   = "DATAA";

// Sign representation for A
parameter representation_a           = "UNSIGNED";

// signa port registers/pipeline

parameter signed_register_a          = "CLOCK0";
parameter signed_aclr_a              = "ACLR3";
parameter signed_pipeline_register_a = "CLOCK0";
parameter signed_pipeline_aclr_a     = "ACLR3";

// Input registers for B 

parameter input_register_b0 = "CLOCK0";
parameter input_aclr_b0     = "ACLR3";
parameter input_source_b0   = "DATAB";

parameter input_register_b1 = "CLOCK0";
parameter input_aclr_b1     = "ACLR3";
parameter input_source_b1   = "DATAB";

parameter input_register_b2 = "CLOCK0";
parameter input_aclr_b2     = "ACLR3";
parameter input_source_b2   = "DATAB";

parameter input_register_b3 = "CLOCK0";
parameter input_aclr_b3     = "ACLR3";
parameter input_source_b3   = "DATAB";

// Multiplier registers 

parameter multiplier_register0 = "CLOCK0";
parameter multiplier_aclr0     = "ACLR3";
parameter multiplier_register1 = "CLOCK0";
parameter multiplier_aclr1     = "ACLR3";
parameter multiplier_register2 = "CLOCK0";
parameter multiplier_aclr2     = "ACLR3";
parameter multiplier_register3 = "CLOCK0";
parameter multiplier_aclr3     = "ACLR3";

// Addnsub for 1st level adders

parameter multiplier1_direction = "ADD";
parameter multiplier3_direction = "ADD";

// Addnsub port registers/pipeline for 1st level adders

parameter addnsub_multiplier_register1          = "CLOCK0";
parameter addnsub_multiplier_aclr1              = "ACLR3";
parameter addnsub_multiplier_pipeline_register1 = "CLOCK0";
parameter addnsub_multiplier_pipeline_aclr1     = "ACLR3";

parameter addnsub_multiplier_register3          = "CLOCK0";
parameter addnsub_multiplier_aclr3              = "ACLR3";
parameter addnsub_multiplier_pipeline_register3 = "CLOCK0";
parameter addnsub_multiplier_pipeline_aclr3     = "ACLR3";

// Sign representation for B
parameter representation_b           = "UNSIGNED";

// signb port registers/pipeline
parameter signed_register_b          = "CLOCK0";
parameter signed_aclr_b              = "ACLR3";
parameter signed_pipeline_register_b = "CLOCK0";
parameter signed_pipeline_aclr_b     = "ACLR3";

// Output Register

parameter output_register = "CLOCK0";
parameter output_aclr     = "ACLR3";

// Misc parameters

parameter extra_latency                  = 0;
parameter dedicated_multiplier_circuitry = "AUTO";
parameter dsp_block_balancing            = "Auto";
parameter intended_device_family         = "UNUSED";

parameter width_a_ = number_of_multipliers * width_a;
parameter width_b_ = number_of_multipliers * width_b;

// Rounding and Saturation
parameter multiplier01_rounding = "NO";
parameter multiplier01_saturation = "NO";
parameter multiplier23_rounding = "NO";
parameter multiplier23_saturation = "NO";

parameter adder1_rounding = "NO";
parameter adder3_rounding = "NO";

parameter port_mult0_is_saturated = "UNUSED";
parameter port_mult1_is_saturated = "UNUSED";
parameter port_mult2_is_saturated = "UNUSED";
parameter port_mult3_is_saturated = "UNUSED";

parameter mult01_round_register = "CLOCK0";
parameter mult01_round_aclr = "ACLR3";
parameter mult23_round_register = "CLOCK0";
parameter mult23_round_aclr = "ACLR3";

parameter mult01_saturation_register = "CLOCK0";
parameter mult01_saturation_aclr = "ACLR2";
parameter mult23_saturation_register = "CLOCK0";
parameter mult23_saturation_aclr = "ACLR3";
 
parameter addnsub1_round_register = "CLOCK0";
parameter addnsub1_round_aclr = "ACLR3";
parameter addnsub1_round_pipeline_register = "CLOCK0";
parameter addnsub1_round_pipeline_aclr = "ACLR3";

parameter addnsub3_round_register = "CLOCK0";
parameter addnsub3_round_aclr = "ACLR3";
parameter addnsub3_round_pipeline_register = "CLOCK0";
parameter addnsub3_round_pipeline_aclr = "ACLR3";

parameter port_addnsub1 = "PORT_CONNECTIVITY";
parameter port_addnsub3 = "PORT_CONNECTIVITY";
parameter port_signa = "PORT_CONNECTIVITY";
parameter port_signb = "PORT_CONNECTIVITY";

parameter lpm_hint = "UNUSED";

parameter accum_direction = "ADD";
parameter accum_sload_aclr = "ACLR3";
parameter accum_sload_pipeline_aclr = "ACLR3";
parameter accum_sload_pipeline_register = "CLOCK0";
parameter accum_sload_register = "CLOCK0";
parameter accumulator = "NO";
parameter chainout_aclr = "ACLR3";
parameter chainout_adder = "NO";
parameter chainout_register = "CLOCK0";
parameter chainout_round_aclr = "ACLR3";
parameter chainout_round_output_aclr = "ACLR3";
parameter chainout_round_output_register = "CLOCK0";
parameter chainout_round_pipeline_aclr = "ACLR3";
parameter chainout_round_pipeline_register = "CLOCK0";
parameter chainout_round_register = "CLOCK0";
parameter chainout_rounding = "NO";
parameter chainout_saturate_aclr = "ACLR3";
parameter chainout_saturate_output_aclr = "ACLR3";
parameter chainout_saturate_output_register = "CLOCK0";
parameter chainout_saturate_pipeline_aclr = "ACLR3";
parameter chainout_saturate_pipeline_register = "CLOCK0";
parameter chainout_saturate_register = "CLOCK0";
parameter chainout_saturation = "NO";
parameter output_round_aclr = "ACLR3";
parameter output_round_pipeline_aclr = "ACLR3";
parameter output_round_pipeline_register = "CLOCK0";
parameter output_round_register = "CLOCK0";
parameter output_round_type = "NEAREST_INTEGER";
parameter output_rounding = "NO";
parameter output_saturate_aclr = "ACLR3";
parameter output_saturate_pipeline_aclr = "ACLR3";
parameter output_saturate_pipeline_register = "CLOCK0";
parameter output_saturate_register = "CLOCK0";
parameter output_saturate_type = "ASYMMETRIC";
parameter output_saturation = "NO";
parameter port_chainout_sat_is_overflow = "PORT_UNUSED";
parameter port_output_is_overflow = "PORT_UNUSED";
parameter rotate_aclr = "ACLR3";
parameter rotate_output_aclr = "ACLR3";
parameter rotate_output_register = "CLOCK0";
parameter rotate_pipeline_aclr = "ACLR3";
parameter rotate_pipeline_register = "CLOCK0";
parameter rotate_register = "CLOCK0";
parameter width_msb = 17;
parameter width_saturate_sign = 1;
parameter scanouta_aclr = "ACLR3";
parameter scanouta_register = "UNREGISTERED";
parameter shift_mode = "NO";
parameter shift_right_aclr = "ACLR3";
parameter shift_right_output_aclr = "ACLR3";
parameter shift_right_output_register = "CLOCK0";
parameter shift_right_pipeline_aclr = "ACLR3";
parameter shift_right_pipeline_register = "CLOCK0";
parameter shift_right_register = "CLOCK0";
parameter width_chainin = 1;
parameter zero_chainout_output_aclr = "ACLR3";
parameter zero_chainout_output_register = "CLOCK0";
parameter zero_loopback_aclr = "ACLR3";
parameter zero_loopback_output_aclr = "ACLR3";
parameter zero_loopback_output_register = "CLOCK0";
parameter zero_loopback_pipeline_aclr = "ACLR3";
parameter zero_loopback_pipeline_register = "CLOCK0";
parameter zero_loopback_register = "CLOCK0";

// Local parameters
parameter mult01_rs_enabled = (
                multiplier01_rounding !="NO" ||
                multiplier01_saturation !="NO");

parameter mult23_rs_enabled = (
                multiplier23_rounding !="NO" ||
                multiplier23_saturation !="NO");

localparam sign_extend_one_input = ( FEATURE_FAMILY_STRATIXIII (intended_device_family) )? (
		( (number_of_multipliers==2) && (accumulator=="NO") && (chainout_adder=="NO") && 
			(width_result > width_a+width_b) && (width_a+width_b < 36) )? "YES" : "NO"
	) : "NO";
	
localparam sign_extend_a = ((sign_extend_one_input=="YES") && ( width_a < 18 ))? "YES" : "NO";
localparam sign_extend_b = ( (sign_extend_one_input=="YES") && ( width_a == 18 ) && (width_b < 18) )? "YES" : "NO";

localparam width_a_adjusted = ( sign_extend_a == "YES" )?  width_a+1 : width_a;
localparam width_b_adjusted = ( sign_extend_b == "YES" )?  width_b+1 : width_b;

parameter max_width = ( width_a_adjusted >= width_b_adjusted ) ? width_a_adjusted : width_b_adjusted;

`ifdef MULT_NORMALIZE_SIZE
parameter normalized_width = ( dedicated_multiplier_circuitry != "NO" ) ?
	( ( max_width <= 9  && ! FEATURE_FAMILY_STRATIXIII (intended_device_family) ) ? 9 : 
	( ( max_width <= 18 ) ? 18 : max_width ) ) : 1;
`else
parameter normalized_width = 1;
`endif

localparam width_l1addrin = width_a_adjusted+width_b_adjusted;
localparam width_l1addrout = width_a_adjusted + width_b_adjusted + 1;

localparam width_l2addrin = width_l1addrout;
localparam width_l2addrout = width_l1addrout + 1;

localparam width_accumout =  
			(accumulator == "YES") ? 
				(
					(width_result > width_a_adjusted + width_b_adjusted + 8)? 
						width_result : width_a_adjusted + width_b_adjusted + 8
				) : (output_saturation !="NO" && width_result > width_l2addrout)? 
						width_result : width_l2addrout;

localparam width_extra_output_sign = (width_accumout > width_result)?  
				(width_accumout - width_result) : 0;

localparam width_chainout = (chainout_adder=="YES")? 
		width_result : width_accumout;

localparam shift_type = ( representation_a == "SIGNED" && representation_b == "SIGNED")? "ARITHMETIC" : (
								( representation_a == "UNSIGNED" && representation_b == "UNSIGNED")? "LOGICAL" : (
								( representation_a == "UNUSED" && representation_b == "UNUSED")? "DYNAMIC" : "DYNAMIC" ));


localparam dataa_signed_param = 
			(port_signa == "PORT_UNUSED")?
				((representation_a != "UNUSED") ? 
					(representation_a == "SIGNED" ? "true" : "false") :"false" 
            ) : (
		   (port_signa == "PORT_USED")? "use_port" : (
		    	((representation_a != "UNUSED") ?
					(representation_a == "SIGNED" ? "true" : "false") : "use_port")
				)
			);

localparam datab_signed_param = 
			(port_signb == "PORT_UNUSED")?
				((representation_b != "UNUSED") ? 
					(representation_b == "SIGNED" ? "true" : "false") : "false"
			) : (
		   (port_signb == "PORT_USED")? "use_port" : (
				((representation_b != "UNUSED") ?
					(representation_b == "SIGNED" ? "true" : "false") : "use_port")
				)
		   );

localparam addsub1_adder_mode = 
			(port_addnsub1 == "PORT_UNUSED")?
				(( multiplier1_direction != "UNUSED") ? 
					(multiplier1_direction == "ADD" ? "add": "sub") : "add" ) : (
         (port_addnsub1 == "PORT_USED")? "use_port" : (
           	((multiplier1_direction != "UNUSED") ? 
              	(multiplier1_direction == "ADD" ? "add" : "sub") : "use_port") 
				)
			);

localparam addsub3_adder_mode = 
			(port_addnsub3 == "PORT_UNUSED")?
				((multiplier3_direction != "UNUSED")? 
					(multiplier3_direction == "ADD" ? "add": "sub") : "add" ) : (
         (port_addnsub3 == "PORT_USED")? "use_port" : (
            ((multiplier3_direction != "UNUSED") ?
               (multiplier3_direction == "ADD" ? "add" : "sub") : "use_port")
            )
         );
localparam acc_dir_param = (accum_direction=="SUB")? "sub" : "add";

//// port declarations ////

// data input ports
input [(number_of_multipliers * width_a_adjusted) -1 : 0] dataa;
input [(number_of_multipliers * width_b_adjusted) -1 : 0] datab;

// clock ports
input clock3;
input clock2;
input clock1;
input clock0;

// asynch clear ports
input aclr3;
input aclr2;
input aclr1;
input aclr0;

// clock enable ports
input ena3;
input ena2;
input ena1;
input ena0;

// control signals
input signa;            // sign of dataa
input signb;            // sign of datab
input addnsub1;         // addnsub for 1st 1-level adder
input addnsub3;         // addnsub for 2nd 1-level adder

input [width_a-1 : 0] scanina; 
input [width_b-1 : 0] scaninb;
input [number_of_multipliers-1 : 0] sourcea; 
input [number_of_multipliers-1 : 0] sourceb;

input mult01_round, mult23_round;
input mult01_saturation, mult23_saturation;
input addnsub1_round;
input addnsub3_round;

input accum_sload;
input [width_chainin-1:0] chainin;
input chainout_round;
input chainout_saturate;
input output_round;
input output_saturate;
input rotate;
input shift_right;
input zero_chainout;
input zero_loopback;

// output ports
output [width_result -1 : 0] result;
output [width_a -1 : 0] scanouta;
output [width_b -1 : 0] scanoutb;
output mult0_is_saturated;
output mult1_is_saturated;
output mult2_is_saturated;
output mult3_is_saturated;
output chainout_sat_overflow;
output overflow;

//// constants ////
//// variables ////

integer i;

//// nets/registers ////

// Data inputs

wire [(4 * width_a_adjusted) -1 : 0] dataa_wide;
wire [(4 * width_b_adjusted) -1 : 0] datab_wide;

// data/scanin input
wire [ (4 * width_a) -1 : 0 ] dataa_in;
wire [ (4 * width_b) -1 : 0 ] datab_in;

wire [width_b -1 : 0 ] loopbackout;

// Clocks
wire input_reg_a0_clk,input_reg_a1_clk,input_reg_a2_clk,input_reg_a3_clk; // input A reg clocks
wire input_reg_b0_clk,input_reg_b1_clk,input_reg_b2_clk,input_reg_b3_clk; // input B reg clocks
wire addsub1_reg_clk,addsub1_pipe_clk;                                    // addnsub1 reg/pipe clocks
wire addsub3_reg_clk,addsub3_pipe_clk;                                    // addnsub3 reg/pipe clocks
wire sign_reg_a_clk,sign_pipe_a_clk;                                      // signa reg/pipe clocks
wire sign_reg_b_clk,sign_pipe_b_clk;                                      // signb reg/pipe clocks
wire multiplier_reg0_clk,multiplier_reg1_clk,multiplier_reg2_clk,multiplier_reg3_clk;
                                                                          // multiplier reg clocks
wire output_reg_clk;                                                      // output register clocks

// Asynch Clears
wire input_reg_a0_clr,input_reg_a1_clr,input_reg_a2_clr,input_reg_a3_clr; // input A reg aclr
wire input_reg_b0_clr,input_reg_b1_clr,input_reg_b2_clr,input_reg_b3_clr; // input B reg aclr
wire addsub1_reg_clr,addsub1_pipe_clr;                                    // addnsub1 reg/pipe aclr
wire addsub3_reg_clr,addsub3_pipe_clr;                                    // addnsub3 reg/pipe aclr
wire sign_reg_a_clr,sign_pipe_a_clr;                                      // signa reg/pipe aclr
wire sign_reg_b_clr,sign_pipe_b_clr;                                      // signb reg/pipe aclr
wire multiplier_reg0_clr,multiplier_reg1_clr,multiplier_reg2_clr,multiplier_reg3_clr;
                                                                          // multiplier reg aclr
wire output_reg_clr;                                                      // output register aclr

// Clock enables
wire input_reg_a0_en,input_reg_a1_en,input_reg_a2_en,input_reg_a3_en;     // input A reg enable
wire input_reg_b0_en,input_reg_b1_en,input_reg_b2_en,input_reg_b3_en;     // input B reg enable
wire addsub1_reg_en,addsub1_pipe_en;                                      // addnsub1 reg/pipe enable
wire addsub3_reg_en,addsub3_pipe_en;                                      // addnsub3 reg/pipe enable
wire sign_reg_a_en,sign_pipe_a_en;                                        // signa reg/pipe enable
wire sign_reg_b_en,sign_pipe_b_en;                                        // signb reg/pipe enable
wire multiplier_reg0_en,multiplier_reg1_en,multiplier_reg2_en,multiplier_reg3_en;
                                          // multiplier reg enable
wire output_reg_en;                       // output register enable

// Sign bits
wire signa_rev,signb_rev;

wire signa_in_reg,signa_in_pipe;          // signa reg/pipe
wire signa_reg,signa_pipe;
wire signb_in_reg,signb_in_pipe;          // signb reg/pipe
wire signb_reg,signb_pipe;
wire first_level_adder_sign;
wire second_level_adder_sign_a;
wire second_level_adder_sign_b;

wire addnsub1_rev,addnsub3_rev;

wire addsub1_in_reg,addsub1_in_pipe;      // addsub1 reg/pipe
wire addsub1_reg,addsub1_pipe;
wire addsub3_in_reg,addsub3_in_pipe;      // addsub3 reg/pipe
wire addsub3_reg,addsub3_pipe;

// Multiplier inputs

wire signed [width_a_adjusted - 1 : 0] mult1_a_in,mult2_a_in,mult3_a_in,mult4_a_in;
wire signed [width_b_adjusted - 1 : 0] mult1_b_in,mult2_b_in,mult3_b_in,mult4_b_in;


// Multiplier registered inputs

wire signed [width_a_adjusted - 1 : 0] mult1_a_reg_in,mult2_a_reg_in,mult3_a_reg_in,mult4_a_reg_in;
wire signed [width_a_adjusted - 1 : 0] mult1_a_reg,mult2_a_reg,mult3_a_reg,mult4_a_reg;
wire signed [width_b_adjusted - 1 : 0] mult1_b_reg_in,mult2_b_reg_in,mult3_b_reg_in,mult4_b_reg_in;
wire signed [width_b_adjusted - 1 : 0] mult1_b_reg,mult2_b_reg,mult3_b_reg,mult4_b_reg;

wire signed [(4*width_a_adjusted) - 1 : 0] mult_a_reg_in;
wire signed [(4*width_b_adjusted) - 1 : 0] mult_b_reg_in;

wire [width_a-1 : 0] scanouta_reg;

// rounding and saturation
wire mult01_round_clk, mult01_round_en, mult01_round_clr;
wire mult01_round_in_reg, mult01_round_signal_reg;
wire mult23_round_clk, mult23_round_en, mult23_round_clr;
wire mult23_round_in_reg, mult23_round_signal_reg;

wire mult01_saturation_clk, mult01_saturation_en, mult01_saturation_clr;
wire mult01_saturation_in_reg, mult01_saturation_signal_reg;
wire mult23_saturation_clk, mult23_saturation_en, mult23_saturation_clr;
wire mult23_saturation_in_reg, mult23_saturation_signal_reg;

wire addnsub1_round_clk, addnsub1_round_en, addnsub1_round_clr;
wire addnsub1_round_in_reg, addnsub1_round_signal_reg;
wire addnsub1_round_pipe_clk, addnsub1_round_pipe_en, addnsub1_round_pipe_clr;
wire addnsub1_round_pipe_in_reg, addnsub1_round_pipe_signal_reg;

wire addnsub3_round_clk, addnsub3_round_en, addnsub3_round_clr;
wire addnsub3_round_in_reg, addnsub3_round_signal_reg;
wire addnsub3_round_pipe_clk, addnsub3_round_pipe_en, addnsub3_round_pipe_clr;
wire addnsub3_round_pipe_in_reg, addnsub3_round_pipe_signal_reg;
wire scanouta_clk, scanouta_ena, scouta_clr;

wire zero_lpbk_reg, zero_lpbk_clk, zero_lpbk_ena, zero_lpbk_clr;
wire zero_lpbk_pipe, zero_lpbk_pipe_clk, zero_lpbk_pipe_ena, zero_lpbk_pipe_clr;
wire zero_lpbk_out_reg, zero_lpbk_out_clk, zero_lpbk_out_ena, zero_lpbk_out_clr;

// Multiplier outputs

wire signed [width_a_adjusted + width_b_adjusted - 1 : 0] mult1_out,mult2_out,mult3_out,mult4_out;
wire signed [4*(width_a_adjusted + width_b_adjusted) - 1 : 0] mult_out;

// Multiplier registered outputs

wire signed [width_a_adjusted + width_b_adjusted - 1 : 0] mult1_reg,mult2_reg,mult3_reg,mult4_reg;
wire signed [width_a_adjusted + width_b_adjusted - 1 : 0] mult1_reg_out,mult2_reg_out,mult3_reg_out,mult4_reg_out;

// Multiplier round/saturate 
wire signed [4*(width_a_adjusted + width_b_adjusted) - 1 : 0] mult_rs_out;
wire mult1_sat_overflow, mult2_sat_overflow, mult3_sat_overflow, mult4_sat_overflow;
wire mult1_sat_reg_out, mult2_sat_reg_out, mult3_sat_reg_out, mult4_sat_reg_out;
wire mult1_sat_reg, mult2_sat_reg, mult3_sat_reg, mult4_sat_reg;

// Addsub block outputs

wire signed [width_l1addrout - 1 : 0] addsub1_out,addsub3_out;
wire signed [width_l1addrout - 1 : 0] addsub1_rs_out,addsub3_rs_out;
wire signed [width_l1addrout - 1 : 0] addsub1_addblock_out,addsub3_addblock_out;
wire signed [width_l1addrout - 1 : 0] addsub1_addblock_reg_out,addsub3_addblock_reg_out;

// Accumulator 
wire acc_dir;
wire accum_sload_clk, accum_sload_ena, accum_sload_clr;
wire accum_sload_pipe_clk, accum_sload_pipe_ena, accum_sload_pipe_clr;
wire accum_sload_reg, accum_sload_pipe_reg;
wire accum_overflow;
wire accum_overflow_reg;
wire accum_overflow_reg_late;
wire accum_out_sat;

// Output round/saturate
wire out_round_clk, out_round_ena, out_round_clr;
wire out_round_pipe_clk, out_round_pipe_ena, out_round_pipe_clr;
wire out_sat_clk, out_sat_ena, out_sat_clr;
wire out_sat_pipe_clk, out_sat_pipe_ena, out_sat_pipe_clr;
wire out_round_reg, out_round_pipe;
wire out_sat_reg, out_sat_pipe;


// Output
wire signed [width_l2addrout - 1 : 0] add_out;
wire signed [width_accumout - 1 : 0] add_reg_out;
wire signed [width_accumout - 1 : 0] add_reg_out_late;
wire signed [width_result - 1 : 0] dataout;

wire signed [width_accumout - 1 : 0] accum_out;
wire signed [width_accumout - 1 : 0] accum_out_rs;
wire addr11_sumsign, addr12_sumsign, accum_signout, extend_bit;
wire extend_bit_pre;

// Chainout
wire chainout_clk, chainout_clr, chainout_ena;
wire [width_chainout-1 : 0] chainout_out, chainout_out_rs, chainout_out_reg;
wire chain_round_clk, chain_round_ena, chain_round_clr;
wire chain_round_pipe_clk, chain_round_pipe_ena, chain_round_pipe_clr;
wire chain_round_out_clk, chain_round_out_ena, chain_round_out_clr;
wire chain_sat_clk, chain_sat_ena, chain_sat_clr;
wire chain_sat_pipe_clk, chain_sat_pipe_ena, chain_sat_pipe_clr;
wire chain_sat_out_clk, chain_sat_out_ena, chain_sat_out_clr;

wire chain_round_reg, chain_round_pipe, chain_round_out;
wire chain_sat_reg, chain_sat_pipe, chain_sat_out;

wire zero_chain_clk, zero_chain_ena, zero_chain_clr;
wire zero_chain_reg;
wire chainout_out_sat;

// Rotate and Shift
wire rotate_out, rotate_reg, rotate_pipe;
wire rotate_clk, rotate_ena, rotate_clr;
wire rotate_pipe_clk, rotate_pipe_ena, rotate_pipe_clr;
wire rotate_out_clk, rotate_out_ena, rotate_out_clr;

wire shiftr_out, shiftr_reg, shiftr_pipe;
wire shiftr_clk, shiftr_ena, shiftr_clr;
wire shiftr_pipe_clk, shiftr_pipe_ena, shiftr_pipe_clr;
wire shiftr_out_clk, shiftr_out_ena, shiftr_out_clr;

// IMPLEMENTATION BEGIN
//////////////////////////// asynchronous logic ////////////////////////////////////////

// ************** Multipliers      *************** //

generate 
genvar m;
    for (m = 0; m < number_of_multipliers; m=m+1) begin:mlt
		wire [width_a_adjusted -1 : 0] a_in;
		wire [width_b_adjusted -1 : 0] b_in;

		if (sign_extend_a=="YES") begin
			assign a_in = {{ signa_reg && mult_a_reg_in[(m+1)*width_a - 1] },{ mult_a_reg_in[(m+1)*width_a - 1:m*width_a]}};
		end
		else begin
			assign a_in = mult_a_reg_in[(m+1)*width_a - 1:m*width_a];
		end
		if (sign_extend_b=="YES") begin
			assign b_in = {{ signb_reg && mult_b_reg_in[ (m+1)*width_b - 1] },{ mult_b_reg_in[(m+1)*width_b - 1:m*width_b]}};
		end
		else begin
			assign b_in = mult_b_reg_in[(m+1)*width_b - 1:m*width_b];
		end

	mult_block #(
		.width_a(width_a_adjusted),
		.width_b(width_b_adjusted),
		.normalized_width(normalized_width)
	) mult (
		.dataa(mult_a_reg_in[(m+1)*width_a_adjusted - 1:m*width_a_adjusted]),
		.datab(mult_b_reg_in[(m+1)*width_b_adjusted - 1:m*width_b_adjusted]),
		.signa(signa_reg),.signb(signb_reg),
		.product(mult_out[(m+1)*(width_a_adjusted + width_b_adjusted) - 1 : m*(width_a_adjusted + width_b_adjusted)])
	);
    end
endgenerate

generate
if(mult01_rs_enabled)
    assign mult1_out = mult_rs_out[width_a_adjusted+width_b_adjusted-1 : 0] ;
else
    assign mult1_out = mult_out[width_a_adjusted+width_b_adjusted-1 : 0]; 
endgenerate

generate 
if ((number_of_multipliers > 1) && (mult01_rs_enabled))
    assign mult2_out = mult_rs_out[2*(width_a_adjusted+width_b_adjusted)-1 : width_a_adjusted+width_b_adjusted];
else if(number_of_multipliers > 1)
    assign mult2_out = mult_out[2*(width_a_adjusted+width_b_adjusted)-1 : width_a_adjusted+width_b_adjusted];
else 
    assign mult2_out = 'b0;
endgenerate

generate
if ((number_of_multipliers > 2) && (mult23_rs_enabled))
    assign mult3_out = mult_rs_out[3*(width_a_adjusted+width_b_adjusted)-1 : 2*(width_a_adjusted+width_b_adjusted)];
else if (number_of_multipliers > 2)
    assign mult3_out = mult_out[3*(width_a_adjusted+width_b_adjusted)-1 : 2*(width_a_adjusted+width_b_adjusted)]; 
else 
    assign mult3_out = 'b0;
endgenerate

generate
if ((number_of_multipliers > 3) && (mult23_rs_enabled))
    assign mult4_out = mult_rs_out[4*(width_a_adjusted+width_b_adjusted)-1 : 3*(width_a_adjusted+width_b_adjusted)];
else if (number_of_multipliers > 3)
      assign mult4_out = mult_out[4*(width_a_adjusted+width_b_adjusted)-1 : 3*(width_a_adjusted+width_b_adjusted)];
else
      assign mult4_out = 'b0;
endgenerate

// ************** Round/Saturate ******************** //
generate
if (mult01_rs_enabled)
begin
rs_block #( `W_SIGN, width_a_adjusted+width_b_adjusted, `W_MSB) mult1_rs (
	.round(multiplier01_rounding == "YES" || (multiplier01_rounding == "VARIABLE" && mult01_round_signal_reg == 1'b1)),
	.saturate(multiplier01_saturation == "YES" || (multiplier01_saturation == "VARIABLE" && mult01_saturation_signal_reg==1'b1)),
	.datain(mult_out[width_a_adjusted + width_b_adjusted - 1:0]),
	.sign(signa_reg|signb_reg),
	.rs_output(mult_rs_out[width_a_adjusted + width_b_adjusted - 1:0]),
	.sat_overflow(mult1_sat_overflow)
	);

end
endgenerate

generate
if (mult01_rs_enabled && number_of_multipliers > 1)
begin
rs_block #(`W_SIGN, width_a_adjusted+width_b_adjusted, `W_MSB) mult2_rs (
	.round(multiplier01_rounding == "YES" || (multiplier01_rounding == "VARIABLE" && mult01_round_signal_reg == 1'b1)),
	.saturate(multiplier01_saturation == "YES" || (multiplier01_saturation == "VARIABLE" && mult01_saturation_signal_reg==1'b1)),
	.datain(mult_out[2*(width_a_adjusted + width_b_adjusted) - 1:width_a_adjusted + width_b_adjusted]),
	.sign(signa_reg|signb_reg),
	.rs_output(mult_rs_out[2*(width_a_adjusted + width_b_adjusted) - 1:width_a_adjusted + width_b_adjusted]),
	.sat_overflow(mult2_sat_overflow)
	);

end
endgenerate

generate
if (mult23_rs_enabled && number_of_multipliers > 2)
begin
rs_block #(`W_SIGN, width_a_adjusted+width_b_adjusted, `W_MSB) mult3_rs (
	.round(multiplier23_rounding == "YES" || (multiplier23_rounding == "VARIABLE" && mult23_round_signal_reg == 1'b1)),
	.saturate(multiplier23_saturation == "YES" || (multiplier23_saturation == "VARIABLE" && mult23_saturation_signal_reg==1'b1)),
	.datain(mult_out[3*(width_a_adjusted+width_b_adjusted)-1 : 2*(width_a_adjusted+width_b_adjusted)]),
	.sign(signa_reg|signb_reg),
	.rs_output(mult_rs_out[3*(width_a_adjusted+width_b_adjusted)-1 : 2*(width_a_adjusted+width_b_adjusted)]),
	.sat_overflow(mult3_sat_overflow)
	);

end
endgenerate

generate
if (mult23_rs_enabled && number_of_multipliers > 3)
begin
rs_block #(`W_SIGN, width_a_adjusted+width_b_adjusted, `W_MSB) mult4_rs (
	.round(multiplier23_rounding == "YES" || (multiplier23_rounding == "VARIABLE" && mult23_round_signal_reg == 1'b1)),
	.saturate(multiplier23_saturation == "YES" || (multiplier23_saturation == "VARIABLE" && mult23_saturation_signal_reg==1'b1)),
	.datain(mult_out[4*(width_a_adjusted+width_b_adjusted)-1 : 3*(width_a_adjusted+width_b_adjusted)]),
	.sign(signa_reg|signb_reg),
	.rs_output(mult_rs_out[4*(width_a_adjusted+width_b_adjusted)-1 : 3*(width_a_adjusted+width_b_adjusted)]),
	.sat_overflow(mult4_sat_overflow)
	);

end
endgenerate

// ************** Addsub block ******************** //
generate if ( FEATURE_FAMILY_STRATIXIII( intended_device_family ) ) 
	assign first_level_adder_sign = signa_reg | signb_reg;
else
	assign first_level_adder_sign = signa_pipe | signb_pipe;
endgenerate

addsub_block #(
	.width_a(width_a_adjusted+width_b_adjusted), 
	.width_b(width_a_adjusted+width_b_adjusted),
	.adder_mode(addsub1_adder_mode),
	.dataa_signed("use_port"),
	.datab_signed("use_port")
) adder11 (
	.dataa(mult1_reg_out),
	.datab(mult2_reg_out),
	.signa(first_level_adder_sign),
	.signb(first_level_adder_sign),
	.addsub(addsub1_pipe),
	.sum(addsub1_addblock_out),
	.sumsign(addr11_sumsign)
	);

// For SIII, the multipier_register is moved to after the first level of adder
generate
if ( ( FEATURE_FAMILY_STRATIXIII( intended_device_family )) && (multiplier_register0 != "UNREGISTERED") )
begin

	dffep mult1_dout_ff[ width_l1addrout - 1 : 0 ] (
		addsub1_addblock_reg_out,
		multiplier_reg0_clk,
		multiplier_reg0_en,
		addsub1_addblock_out,
		1'b0,
		multiplier_reg0_clr 
	);

end

else
	assign addsub1_addblock_reg_out = addsub1_addblock_out;
endgenerate

generate
if (adder1_rounding !="NO")
begin
rs_block #(`W_SIGN+1, width_l1addrout, `W_MSB+1) addr11_rs (
	.round(adder1_rounding=="YES" || (adder1_rounding=="VARIABLE" && addnsub1_round_pipe_signal_reg==1'b1)),
	.saturate(1'b0),
	.datain(addsub1_addblock_reg_out),
	.sign(signa_pipe | signb_pipe),
	.rs_output(addsub1_rs_out),
	.sat_overflow()
	);

	assign addsub1_out = addsub1_rs_out;
end
else
	assign addsub1_out = addsub1_addblock_reg_out;
endgenerate
generate
if (number_of_multipliers > 2)
begin
addsub_block #(
	.width_a(width_a_adjusted+width_b_adjusted), 
	.width_b(width_a_adjusted+width_b_adjusted),
	.adder_mode(addsub3_adder_mode),
	.dataa_signed("use_port"),
	.datab_signed("use_port")
	) adder12 (
	.dataa(mult3_reg_out),
	.datab(mult4_reg_out),
	.signa(first_level_adder_sign),
	.signb(first_level_adder_sign),
	.addsub(addsub3_pipe),
	.sum(addsub3_addblock_out),
	.sumsign(addr12_sumsign)
	);
end 
else
	assign addsub3_addblock_out = {width_l1addrout{1'b0}};
endgenerate

// For SIII, the multipier_register is moved to after the first level of adder
generate
if ( ( FEATURE_FAMILY_STRATIXIII( intended_device_family )) && 
	((accumulator == "YES" || chainout_adder == "YES") || 
		(number_of_multipliers>2)) && (multiplier_register2 != "UNREGISTERED") )
begin

	dffep mult3_dout_ff[ width_l1addrout - 1 : 0 ] (
		addsub3_addblock_reg_out,
		multiplier_reg3_clk,
		multiplier_reg3_en,
		addsub3_addblock_out,
		1'b0,
		multiplier_reg3_clr 
	);

end

else
	assign addsub3_addblock_reg_out = addsub3_addblock_out;
endgenerate

generate
if (adder3_rounding !="NO")
begin
rs_block #(`W_SIGN+1, width_l1addrout, `W_MSB+1) addr12_rs (
	.round(adder3_rounding=="YES" || (adder3_rounding=="VARIABLE" && addnsub3_round_pipe_signal_reg==1'b1)),
	.saturate(1'b0),
	.datain(addsub3_addblock_reg_out),
	.sign(signa_pipe | signb_pipe),
	.rs_output(addsub3_rs_out),
	.sat_overflow()
);

	assign addsub3_out = addsub3_rs_out ;
end
else
	assign addsub3_out = addsub3_addblock_reg_out;
endgenerate

generate if ( IS_FAMILY_CYCLONE ( intended_device_family ) )
	begin
		assign second_level_adder_sign_a = signa_pipe | signb_pipe | addr11_sumsign ;
		assign second_level_adder_sign_b = signa_pipe | signb_pipe | addr12_sumsign ;
	end
else
	begin
		assign second_level_adder_sign_a = signa_pipe | signb_pipe ;
		assign second_level_adder_sign_b = signa_pipe | signb_pipe ;
	end
endgenerate

generate
if (number_of_multipliers > 2)
begin
addsub_block #(
	.width_a(width_l1addrout), 
	.width_b(width_l1addrout),
	.adder_mode("add"),
	.dataa_signed("use_port"),
	.datab_signed("use_port")
) adder2 (
	.dataa(addsub1_out),
	.datab(addsub3_out),    
	.signa( second_level_adder_sign_a ),
	.signb( second_level_adder_sign_b ),       
	.addsub(`ADD), 
	.sum(add_out),
	.sumsign(addr2signout)
);
end
else begin
	assign add_out = addsub1_out;
end
endgenerate

//Accumulator
generate
if (accum_sload_register != "UNREGISTERED")
begin
	dffep accum_sload_ff (
		accum_sload_reg,
		accum_sload_clk,
		accum_sload_ena,
		accum_sload,
		1'b0,
		accum_sload_clr
	);
end
else
	assign accum_sload_reg = accum_sload;
endgenerate

generate
if (accum_sload_pipeline_register != "UNREGISTERED")
begin
	dffep accum_sload_pipe_ff (
		accum_sload_pipe_reg,
		accum_sload_pipe_clk,
		accum_sload_pipe_ena,
		accum_sload_reg,
		1'b0,
		accum_sload_pipe_clr
	);
end
else
	assign accum_sload_pipe_reg = accum_sload_reg;
endgenerate


assign acc_dir = (accum_direction=="SUB")? 1'b0 : 1'b1;

generate
if (accumulator=="YES")
begin
	addsub_block #(
		.width_a(width_accumout), 
		.width_b(width_l2addrout),
		.adder_mode(acc_dir_param),
		.dataa_signed("use_port"),
		.datab_signed("use_port")
	) accum (
		.dataa( add_reg_out & {width_accumout{~accum_sload_pipe_reg}} ),
		.datab( add_out ),
		.signa( signa_pipe | signb_pipe ),
		.signb( signa_pipe | signb_pipe | addr2signout ),
		.addsub( acc_dir ),
		.sum( accum_out ),
		.sumsign( accum_signout )

	);

end
else
	assign accum_out = add_out;
endgenerate

assign accum_overflow = 
	(~(&accum_out[width_accumout-1 : width_accumout-1-width_extra_output_sign] && accum_signout) && 
	(|accum_out[width_accumout-1 : width_accumout-1-width_extra_output_sign] || accum_signout) );

// Output Round/Saturate block (in Stratix III)
generate
if (output_rounding!="NO" || output_saturation!="NO")
begin
	rs_block #(
		.width_sign( width_saturate_sign + width_extra_output_sign ), 
		.width_total( width_accumout ), 
		.width_msb( width_msb ), 
		.round_type( output_round_type ), 
		.saturate_type (output_saturate_type ),
		.family ( intended_device_family )
	) output_rs (
		.round ( output_rounding=="YES" || (output_rounding=="VARIABLE" && out_round_pipe==1'b1) ),
		.saturate ( output_saturation=="YES" || ( output_saturation=="VARIABLE" && out_sat_pipe==1'b1) ),
		.sign( signa_pipe | signb_pipe ),
		.datain( accum_out ),
		.rs_output( accum_out_rs ),
		.sat_overflow( accum_out_sat )
	);
end
else 
begin
	assign accum_out_rs = accum_out;
	assign accum_out_sat = accum_overflow;
end
endgenerate

/////////////////////////// net assignments //////////////////////////


generate 
case (input_register_a0)
	"CLOCK0": assign input_reg_a0_clk = clock0;
	"CLOCK1": assign input_reg_a0_clk = clock1;
	"CLOCK2": assign input_reg_a0_clk = clock2;
	"CLOCK3": assign input_reg_a0_clk = clock3;
	default : assign input_reg_a0_clk = 1'b0;
endcase
endgenerate

generate 
case (input_register_a1)
	"CLOCK0": assign input_reg_a1_clk = clock0;
	"CLOCK1": assign input_reg_a1_clk = clock1;
	"CLOCK2": assign input_reg_a1_clk = clock2;
	"CLOCK3": assign input_reg_a1_clk = clock3;
	default : assign input_reg_a1_clk = 1'b0;
endcase
endgenerate

generate 
case (input_register_a2)
	"CLOCK0": assign input_reg_a2_clk = clock0;
	"CLOCK1": assign input_reg_a2_clk = clock1;
	"CLOCK2": assign input_reg_a2_clk = clock2;
	"CLOCK3": assign input_reg_a2_clk = clock3;
	default : assign input_reg_a2_clk = 1'b0;
endcase
endgenerate

generate 
case (input_register_a3)
	"CLOCK0": assign input_reg_a3_clk = clock0;
	"CLOCK1": assign input_reg_a3_clk = clock1;
	"CLOCK2": assign input_reg_a3_clk = clock2;
	"CLOCK3": assign input_reg_a3_clk = clock3;
	default : assign input_reg_a3_clk = 1'b0;
endcase
endgenerate

generate 
case (input_register_b0)
	"CLOCK0": assign input_reg_b0_clk = clock0;
	"CLOCK1": assign input_reg_b0_clk = clock1;
	"CLOCK2": assign input_reg_b0_clk = clock2;
	"CLOCK3": assign input_reg_b0_clk = clock3;
	default : assign input_reg_b0_clk = 1'b0;
endcase
endgenerate

generate 
case (input_register_b1)
	"CLOCK0": assign input_reg_b1_clk = clock0;
	"CLOCK1": assign input_reg_b1_clk = clock1;
	"CLOCK2": assign input_reg_b1_clk = clock2;
	"CLOCK3": assign input_reg_b1_clk = clock3;
	default : assign input_reg_b1_clk = 1'b0;
endcase
endgenerate

generate 
case (input_register_b2)
	"CLOCK0": assign input_reg_b2_clk = clock0;
	"CLOCK1": assign input_reg_b2_clk = clock1;
	"CLOCK2": assign input_reg_b2_clk = clock2;
	"CLOCK3": assign input_reg_b2_clk = clock3;
	default : assign input_reg_b2_clk = 1'b0;
endcase
endgenerate

generate 
case (input_register_b3)
	"CLOCK0": assign input_reg_b3_clk = clock0;
	"CLOCK1": assign input_reg_b3_clk = clock1;
	"CLOCK2": assign input_reg_b3_clk = clock2;
	"CLOCK3": assign input_reg_b3_clk = clock3;
	default : assign input_reg_b3_clk = 1'b0;
endcase
endgenerate

generate 
case (addnsub_multiplier_register1)
	"CLOCK0": assign addsub1_reg_clk = clock0;
	"CLOCK1": assign addsub1_reg_clk = clock1;
	"CLOCK2": assign addsub1_reg_clk = clock2;
	"CLOCK3": assign addsub1_reg_clk = clock3;
	default : assign addsub1_reg_clk = 1'b0;
endcase
endgenerate

generate 
case (addnsub_multiplier_pipeline_register1)
	"CLOCK0": assign addsub1_pipe_clk = clock0;
	"CLOCK1": assign addsub1_pipe_clk = clock1;
	"CLOCK2": assign addsub1_pipe_clk = clock2;
	"CLOCK3": assign addsub1_pipe_clk = clock3;
	default : assign addsub1_pipe_clk = 1'b0;
endcase
endgenerate

generate 
case (addnsub_multiplier_register3)
	"CLOCK0": assign addsub3_reg_clk = clock0;
	"CLOCK1": assign addsub3_reg_clk = clock1;
	"CLOCK2": assign addsub3_reg_clk = clock2;
	"CLOCK3": assign addsub3_reg_clk = clock3;
	default : assign addsub3_reg_clk = 1'b0;
endcase
endgenerate

generate 
case (addnsub_multiplier_pipeline_register3)
	"CLOCK0": assign addsub3_pipe_clk = clock0;
	"CLOCK1": assign addsub3_pipe_clk = clock1;
	"CLOCK2": assign addsub3_pipe_clk = clock2;
	"CLOCK3": assign addsub3_pipe_clk = clock3;
	default : assign addsub3_pipe_clk = 1'b0;
endcase
endgenerate

generate 
case (signed_register_a)
	"CLOCK0": assign sign_reg_a_clk = clock0;
	"CLOCK1": assign sign_reg_a_clk = clock1;
	"CLOCK2": assign sign_reg_a_clk = clock2;
	"CLOCK3": assign sign_reg_a_clk = clock3;
	default : assign sign_reg_a_clk = 1'b0;
endcase
endgenerate

generate 
case (signed_register_b)
	"CLOCK0": assign sign_reg_b_clk = clock0;
	"CLOCK1": assign sign_reg_b_clk = clock1;
	"CLOCK2": assign sign_reg_b_clk = clock2;
	"CLOCK3": assign sign_reg_b_clk = clock3;
	default : assign sign_reg_b_clk = 1'b0;
endcase
endgenerate

generate 
case (signed_pipeline_register_a)
	"CLOCK0": assign sign_pipe_a_clk = clock0;
	"CLOCK1": assign sign_pipe_a_clk = clock1;
	"CLOCK2": assign sign_pipe_a_clk = clock2;
	"CLOCK3": assign sign_pipe_a_clk = clock3;
	default : assign sign_pipe_a_clk = 1'b0;
endcase
endgenerate

generate 
case (signed_pipeline_register_b)
	"CLOCK0": assign sign_pipe_b_clk = clock0;
	"CLOCK1": assign sign_pipe_b_clk = clock1;
	"CLOCK2": assign sign_pipe_b_clk = clock2;
	"CLOCK3": assign sign_pipe_b_clk = clock3;
	default : assign sign_pipe_b_clk = 1'b0;
endcase
endgenerate

generate 
case (multiplier_register0)
	"CLOCK0": assign multiplier_reg0_clk = clock0;
	"CLOCK1": assign multiplier_reg0_clk = clock1;
	"CLOCK2": assign multiplier_reg0_clk = clock2;
	"CLOCK3": assign multiplier_reg0_clk = clock3;
	default : assign multiplier_reg0_clk = 1'b0;
endcase
endgenerate

generate 
case (multiplier_register1)
	"CLOCK0": assign multiplier_reg1_clk = clock0;
	"CLOCK1": assign multiplier_reg1_clk = clock1;
	"CLOCK2": assign multiplier_reg1_clk = clock2;
	"CLOCK3": assign multiplier_reg1_clk = clock3;
	default : assign multiplier_reg1_clk = 1'b0;
endcase
endgenerate

generate 
case (multiplier_register2)
	"CLOCK0": assign multiplier_reg2_clk = clock0;
	"CLOCK1": assign multiplier_reg2_clk = clock1;
	"CLOCK2": assign multiplier_reg2_clk = clock2;
	"CLOCK3": assign multiplier_reg2_clk = clock3;
	default : assign multiplier_reg2_clk = 1'b0;
endcase
endgenerate

generate 
case (multiplier_register3)
	"CLOCK0": assign multiplier_reg3_clk = clock0;
	"CLOCK1": assign multiplier_reg3_clk = clock1;
	"CLOCK2": assign multiplier_reg3_clk = clock2;
	"CLOCK3": assign multiplier_reg3_clk = clock3;
	default : assign multiplier_reg3_clk = 1'b0;
endcase
endgenerate

generate 
case (output_register)
	"CLOCK0": assign output_reg_clk = clock0;
	"CLOCK1": assign output_reg_clk = clock1;
	"CLOCK2": assign output_reg_clk = clock2;
	"CLOCK3": assign output_reg_clk = clock3;
	default : assign output_reg_clk = 1'b0;
endcase
endgenerate

generate 
case (input_aclr_a0)
	"ACLR0": assign input_reg_a0_clr = aclr0;
	"ACLR1": assign input_reg_a0_clr = aclr1;
	"ACLR2": assign input_reg_a0_clr = aclr2;
	"ACLR3": assign input_reg_a0_clr = aclr3;
	default : assign input_reg_a0_clr = 1'b0;
endcase
endgenerate

generate 
case (input_aclr_a1)
	"ACLR0": assign input_reg_a1_clr = aclr0;
	"ACLR1": assign input_reg_a1_clr = aclr1;
	"ACLR2": assign input_reg_a1_clr = aclr2;
	"ACLR3": assign input_reg_a1_clr = aclr3;
	default : assign input_reg_a1_clr = 1'b0;
endcase
endgenerate

generate 
case (input_aclr_a2)
	"ACLR0": assign input_reg_a2_clr = aclr0;
	"ACLR1": assign input_reg_a2_clr = aclr1;
	"ACLR2": assign input_reg_a2_clr = aclr2;
	"ACLR3": assign input_reg_a2_clr = aclr3;
	default : assign input_reg_a2_clr = 1'b0;
endcase
endgenerate

generate 
case (input_aclr_a3)
	"ACLR0": assign input_reg_a3_clr = aclr0;
	"ACLR1": assign input_reg_a3_clr = aclr1;
	"ACLR2": assign input_reg_a3_clr = aclr2;
	"ACLR3": assign input_reg_a3_clr = aclr3;
	default : assign input_reg_a3_clr = 1'b0;
endcase
endgenerate

generate 
case (input_aclr_b0)
	"ACLR0": assign input_reg_b0_clr = aclr0;
	"ACLR1": assign input_reg_b0_clr = aclr1;
	"ACLR2": assign input_reg_b0_clr = aclr2;
	"ACLR3": assign input_reg_b0_clr = aclr3;
	default : assign input_reg_b0_clr = 1'b0;
endcase
endgenerate

generate 
case (input_aclr_b1)
	"ACLR0": assign input_reg_b1_clr = aclr0;
	"ACLR1": assign input_reg_b1_clr = aclr1;
	"ACLR2": assign input_reg_b1_clr = aclr2;
	"ACLR3": assign input_reg_b1_clr = aclr3;
	default : assign input_reg_b1_clr = 1'b0;
endcase
endgenerate

generate 
case (input_aclr_b2)
	"ACLR0": assign input_reg_b2_clr = aclr0;
	"ACLR1": assign input_reg_b2_clr = aclr1;
	"ACLR2": assign input_reg_b2_clr = aclr2;
	"ACLR3": assign input_reg_b2_clr = aclr3;
	default : assign input_reg_b2_clr = 1'b0;
endcase
endgenerate

generate 
case (input_aclr_b3)
	"ACLR0": assign input_reg_b3_clr = aclr0;
	"ACLR1": assign input_reg_b3_clr = aclr1;
	"ACLR2": assign input_reg_b3_clr = aclr2;
	"ACLR3": assign input_reg_b3_clr = aclr3;
	default : assign input_reg_b3_clr = 1'b0;
endcase
endgenerate

generate 
case (addnsub_multiplier_aclr1)
	"ACLR0": assign addsub1_reg_clr = aclr0;
	"ACLR1": assign addsub1_reg_clr = aclr1;
	"ACLR2": assign addsub1_reg_clr = aclr2;
	"ACLR3": assign addsub1_reg_clr = aclr3;
	default : assign addsub1_reg_clr = 1'b0;
endcase
endgenerate

generate 
case (addnsub_multiplier_pipeline_aclr1)
	"ACLR0": assign addsub1_pipe_clr = aclr0;
	"ACLR1": assign addsub1_pipe_clr = aclr1;
	"ACLR2": assign addsub1_pipe_clr = aclr2;
	"ACLR3": assign addsub1_pipe_clr = aclr3;
	default : assign addsub1_pipe_clr = 1'b0;
endcase
endgenerate

generate 
case (addnsub_multiplier_aclr3)
	"ACLR0": assign addsub3_reg_clr = aclr0;
	"ACLR1": assign addsub3_reg_clr = aclr1;
	"ACLR2": assign addsub3_reg_clr = aclr2;
	"ACLR3": assign addsub3_reg_clr = aclr3;
	default : assign addsub3_reg_clr = 1'b0;
endcase
endgenerate

generate 
case (addnsub_multiplier_pipeline_aclr3)
	"ACLR0": assign addsub3_pipe_clr = aclr0;
	"ACLR1": assign addsub3_pipe_clr = aclr1;
	"ACLR2": assign addsub3_pipe_clr = aclr2;
	"ACLR3": assign addsub3_pipe_clr = aclr3;
	default : assign addsub3_pipe_clr = 1'b0;
endcase
endgenerate

generate 
case (signed_aclr_a)
	"ACLR0": assign sign_reg_a_clr = aclr0;
	"ACLR1": assign sign_reg_a_clr = aclr1;
	"ACLR2": assign sign_reg_a_clr = aclr2;
	"ACLR3": assign sign_reg_a_clr = aclr3;
	default : assign sign_reg_a_clr = 1'b0;
endcase
endgenerate

generate 
case (signed_aclr_b)
	"ACLR0": assign sign_reg_b_clr = aclr0;
	"ACLR1": assign sign_reg_b_clr = aclr1;
	"ACLR2": assign sign_reg_b_clr = aclr2;
	"ACLR3": assign sign_reg_b_clr = aclr3;
	default : assign sign_reg_b_clr = 1'b0;
endcase
endgenerate

generate 
case (signed_pipeline_aclr_a)
	"ACLR0": assign sign_pipe_a_clr = aclr0;
	"ACLR1": assign sign_pipe_a_clr = aclr1;
	"ACLR2": assign sign_pipe_a_clr = aclr2;
	"ACLR3": assign sign_pipe_a_clr = aclr3;
	default : assign sign_pipe_a_clr = 1'b0;
endcase
endgenerate

generate 
case (signed_pipeline_aclr_b)
	"ACLR0": assign sign_pipe_b_clr = aclr0;
	"ACLR1": assign sign_pipe_b_clr = aclr1;
	"ACLR2": assign sign_pipe_b_clr = aclr2;
	"ACLR3": assign sign_pipe_b_clr = aclr3;
	default : assign sign_pipe_b_clr = 1'b0;
endcase
endgenerate

generate 
case (multiplier_aclr0)
	"ACLR0": assign multiplier_reg0_clr = aclr0;
	"ACLR1": assign multiplier_reg0_clr = aclr1;
	"ACLR2": assign multiplier_reg0_clr = aclr2;
	"ACLR3": assign multiplier_reg0_clr = aclr3;
	default : assign multiplier_reg0_clr = 1'b0;
endcase
endgenerate

generate 
case (multiplier_aclr1)
	"ACLR0": assign multiplier_reg1_clr = aclr0;
	"ACLR1": assign multiplier_reg1_clr = aclr1;
	"ACLR2": assign multiplier_reg1_clr = aclr2;
	"ACLR3": assign multiplier_reg1_clr = aclr3;
	default : assign multiplier_reg1_clr = 1'b0;
endcase
endgenerate

generate 
case (multiplier_aclr2)
	"ACLR0": assign multiplier_reg2_clr = aclr0;
	"ACLR1": assign multiplier_reg2_clr = aclr1;
	"ACLR2": assign multiplier_reg2_clr = aclr2;
	"ACLR3": assign multiplier_reg2_clr = aclr3;
	default : assign multiplier_reg2_clr = 1'b0;
endcase
endgenerate

generate 
case (multiplier_aclr3)
	"ACLR0": assign multiplier_reg3_clr = aclr0;
	"ACLR1": assign multiplier_reg3_clr = aclr1;
	"ACLR2": assign multiplier_reg3_clr = aclr2;
	"ACLR3": assign multiplier_reg3_clr = aclr3;
	default : assign multiplier_reg3_clr = 1'b0;
endcase
endgenerate

generate 
case (output_aclr)
	"ACLR0": assign output_reg_clr = aclr0;
	"ACLR1": assign output_reg_clr = aclr1;
	"ACLR2": assign output_reg_clr = aclr2;
	"ACLR3": assign output_reg_clr = aclr3;
	default : assign output_reg_clr = 1'b0;
endcase
endgenerate

generate 
case (input_register_a0)
	"CLOCK0": assign input_reg_a0_en = ena0;
	"CLOCK1": assign input_reg_a0_en = ena1;
	"CLOCK2": assign input_reg_a0_en = ena2;
	"CLOCK3": assign input_reg_a0_en = ena3;
	default : assign input_reg_a0_en = 1'b0;
endcase
endgenerate

generate 
case (input_register_a1)
	"CLOCK0": assign input_reg_a1_en = ena0;
	"CLOCK1": assign input_reg_a1_en = ena1;
	"CLOCK2": assign input_reg_a1_en = ena2;
	"CLOCK3": assign input_reg_a1_en = ena3;
	default : assign input_reg_a1_en = 1'b0;
endcase
endgenerate

generate 
case (input_register_a2)
	"CLOCK0": assign input_reg_a2_en = ena0;
	"CLOCK1": assign input_reg_a2_en = ena1;
	"CLOCK2": assign input_reg_a2_en = ena2;
	"CLOCK3": assign input_reg_a2_en = ena3;
	default : assign input_reg_a2_en = 1'b0;
endcase
endgenerate

generate 
case (input_register_a3)
	"CLOCK0": assign input_reg_a3_en = ena0;
	"CLOCK1": assign input_reg_a3_en = ena1;
	"CLOCK2": assign input_reg_a3_en = ena2;
	"CLOCK3": assign input_reg_a3_en = ena3;
	default : assign input_reg_a3_en = 1'b0;
endcase
endgenerate

generate 
case (input_register_b0)
	"CLOCK0": assign input_reg_b0_en = ena0;
	"CLOCK1": assign input_reg_b0_en = ena1;
	"CLOCK2": assign input_reg_b0_en = ena2;
	"CLOCK3": assign input_reg_b0_en = ena3;
	default : assign input_reg_b0_en = 1'b0;
endcase
endgenerate

generate 
case (input_register_b1)
	"CLOCK0": assign input_reg_b1_en = ena0;
	"CLOCK1": assign input_reg_b1_en = ena1;
	"CLOCK2": assign input_reg_b1_en = ena2;
	"CLOCK3": assign input_reg_b1_en = ena3;
	default : assign input_reg_b1_en = 1'b0;
endcase
endgenerate

generate 
case (input_register_b2)
	"CLOCK0": assign input_reg_b2_en = ena0;
	"CLOCK1": assign input_reg_b2_en = ena1;
	"CLOCK2": assign input_reg_b2_en = ena2;
	"CLOCK3": assign input_reg_b2_en = ena3;
	default : assign input_reg_b2_en = 1'b0;
endcase
endgenerate

generate 
case (input_register_b3)
	"CLOCK0": assign input_reg_b3_en = ena0;
	"CLOCK1": assign input_reg_b3_en = ena1;
	"CLOCK2": assign input_reg_b3_en = ena2;
	"CLOCK3": assign input_reg_b3_en = ena3;
	default : assign input_reg_b3_en = 1'b0;
endcase
endgenerate

generate 
case (addnsub_multiplier_register1)
	"CLOCK0": assign addsub1_reg_en = ena0;
	"CLOCK1": assign addsub1_reg_en = ena1;
	"CLOCK2": assign addsub1_reg_en = ena2;
	"CLOCK3": assign addsub1_reg_en = ena3;
	default : assign addsub1_reg_en = 1'b0;
endcase
endgenerate

generate 
case (addnsub_multiplier_pipeline_register1)
	"CLOCK0": assign addsub1_pipe_en = ena0;
	"CLOCK1": assign addsub1_pipe_en = ena1;
	"CLOCK2": assign addsub1_pipe_en = ena2;
	"CLOCK3": assign addsub1_pipe_en = ena3;
	default : assign addsub1_pipe_en = 1'b0;
endcase
endgenerate

generate 
case (addnsub_multiplier_register3)
	"CLOCK0": assign addsub3_reg_en = ena0;
	"CLOCK1": assign addsub3_reg_en = ena1;
	"CLOCK2": assign addsub3_reg_en = ena2;
	"CLOCK3": assign addsub3_reg_en = ena3;
	default : assign addsub3_reg_en = 1'b0;
endcase
endgenerate

generate 
case (addnsub_multiplier_pipeline_register3)
	"CLOCK0": assign addsub3_pipe_en = ena0;
	"CLOCK1": assign addsub3_pipe_en = ena1;
	"CLOCK2": assign addsub3_pipe_en = ena2;
	"CLOCK3": assign addsub3_pipe_en = ena3;
	default : assign addsub3_pipe_en = 1'b0;
endcase
endgenerate

generate 
case (signed_register_a)
	"CLOCK0": assign sign_reg_a_en = ena0;
	"CLOCK1": assign sign_reg_a_en = ena1;
	"CLOCK2": assign sign_reg_a_en = ena2;
	"CLOCK3": assign sign_reg_a_en = ena3;
	default : assign sign_reg_a_en = 1'b0;
endcase
endgenerate

generate 
case (signed_register_b)
	"CLOCK0": assign sign_reg_b_en = ena0;
	"CLOCK1": assign sign_reg_b_en = ena1;
	"CLOCK2": assign sign_reg_b_en = ena2;
	"CLOCK3": assign sign_reg_b_en = ena3;
	default : assign sign_reg_b_en = 1'b0;
endcase
endgenerate

generate 
case (signed_pipeline_register_a)
	"CLOCK0": assign sign_pipe_a_en = ena0;
	"CLOCK1": assign sign_pipe_a_en = ena1;
	"CLOCK2": assign sign_pipe_a_en = ena2;
	"CLOCK3": assign sign_pipe_a_en = ena3;
	default : assign sign_pipe_a_en = 1'b0;
endcase
endgenerate

generate 
case (signed_pipeline_register_b)
	"CLOCK0": assign sign_pipe_b_en = ena0;
	"CLOCK1": assign sign_pipe_b_en = ena1;
	"CLOCK2": assign sign_pipe_b_en = ena2;
	"CLOCK3": assign sign_pipe_b_en = ena3;
	default : assign sign_pipe_b_en = 1'b0;
endcase
endgenerate

generate 
case (multiplier_register0)
	"CLOCK0": assign multiplier_reg0_en = ena0;
	"CLOCK1": assign multiplier_reg0_en = ena1;
	"CLOCK2": assign multiplier_reg0_en = ena2;
	"CLOCK3": assign multiplier_reg0_en = ena3;
	default : assign multiplier_reg0_en = 1'b0;
endcase
endgenerate

generate 
case (multiplier_register1)
	"CLOCK0": assign multiplier_reg1_en = ena0;
	"CLOCK1": assign multiplier_reg1_en = ena1;
	"CLOCK2": assign multiplier_reg1_en = ena2;
	"CLOCK3": assign multiplier_reg1_en = ena3;
	default : assign multiplier_reg1_en = 1'b0;
endcase
endgenerate

generate 
case (multiplier_register2)
	"CLOCK0": assign multiplier_reg2_en = ena0;
	"CLOCK1": assign multiplier_reg2_en = ena1;
	"CLOCK2": assign multiplier_reg2_en = ena2;
	"CLOCK3": assign multiplier_reg2_en = ena3;
	default : assign multiplier_reg2_en = 1'b0;
endcase
endgenerate

generate 
case (multiplier_register3)
	"CLOCK0": assign multiplier_reg3_en = ena0;
	"CLOCK1": assign multiplier_reg3_en = ena1;
	"CLOCK2": assign multiplier_reg3_en = ena2;
	"CLOCK3": assign multiplier_reg3_en = ena3;
	default : assign multiplier_reg3_en = 1'b0;
endcase
endgenerate

generate 
case (output_register)
	"CLOCK0": assign output_reg_en = ena0;
	"CLOCK1": assign output_reg_en = ena1;
	"CLOCK2": assign output_reg_en = ena2;
	"CLOCK3": assign output_reg_en = ena3;
	default : assign output_reg_en = 1'b0;
endcase
endgenerate

generate 
case (mult01_round_register)
	"CLOCK0": assign mult01_round_clk = clock0;
	"CLOCK1": assign mult01_round_clk = clock1;
	"CLOCK2": assign mult01_round_clk = clock2;
	"CLOCK3": assign mult01_round_clk = clock3;
	default : assign mult01_round_clk = 1'b0;
endcase
endgenerate

generate 
case (mult01_round_register)
	"CLOCK0": assign mult01_round_en = ena0;
	"CLOCK1": assign mult01_round_en = ena1;
	"CLOCK2": assign mult01_round_en = ena2;
	"CLOCK3": assign mult01_round_en = ena3;
	default : assign mult01_round_en = 1'b0;
endcase
endgenerate

generate 
case (mult01_round_aclr)
	"ACLR0": assign mult01_round_clr = aclr0;
	"ACLR1": assign mult01_round_clr = aclr1;
	"ACLR2": assign mult01_round_clr = aclr2;
	"ACLR3": assign mult01_round_clr = aclr3;
	default : assign mult01_round_clr = 1'b0;
endcase
endgenerate

generate 
case (mult23_round_register)
	"CLOCK0": assign mult23_round_clk = clock0;
	"CLOCK1": assign mult23_round_clk = clock1;
	"CLOCK2": assign mult23_round_clk = clock2;
	"CLOCK3": assign mult23_round_clk = clock3;
	default : assign mult23_round_clk = 1'b0;
endcase
endgenerate

generate 
case (mult23_round_register)
	"CLOCK0": assign mult23_round_en = ena0;
	"CLOCK1": assign mult23_round_en = ena1;
	"CLOCK2": assign mult23_round_en = ena2;
	"CLOCK3": assign mult23_round_en = ena3;
	default : assign mult23_round_en = 1'b0;
endcase
endgenerate

generate 
case (mult23_round_aclr)
	"ACLR0": assign mult23_round_clr = aclr0;
	"ACLR1": assign mult23_round_clr = aclr1;
	"ACLR2": assign mult23_round_clr = aclr2;
	"ACLR3": assign mult23_round_clr = aclr3;
	default : assign mult23_round_clr = 1'b0;
endcase
endgenerate

generate 
case (mult01_saturation_register)
	"CLOCK0": assign mult01_saturation_clk = clock0;
	"CLOCK1": assign mult01_saturation_clk = clock1;
	"CLOCK2": assign mult01_saturation_clk = clock2;
	"CLOCK3": assign mult01_saturation_clk = clock3;
	default : assign mult01_saturation_clk = 1'b0;
endcase
endgenerate

generate 
case (mult01_saturation_register)
	"CLOCK0": assign mult01_saturation_en = ena0;
	"CLOCK1": assign mult01_saturation_en = ena1;
	"CLOCK2": assign mult01_saturation_en = ena2;
	"CLOCK3": assign mult01_saturation_en = ena3;
	default : assign mult01_saturation_en = 1'b0;
endcase
endgenerate

generate 
case (mult01_saturation_aclr)
	"ACLR0": assign mult01_saturation_clr = aclr0;
	"ACLR1": assign mult01_saturation_clr = aclr1;
	"ACLR2": assign mult01_saturation_clr = aclr2;
	"ACLR3": assign mult01_saturation_clr = aclr3;
	default : assign mult01_saturation_clr = 1'b0;
endcase
endgenerate

generate 
case (mult23_saturation_register)
	"CLOCK0": assign mult23_saturation_clk = clock0;
	"CLOCK1": assign mult23_saturation_clk = clock1;
	"CLOCK2": assign mult23_saturation_clk = clock2;
	"CLOCK3": assign mult23_saturation_clk = clock3;
	default : assign mult23_saturation_clk = 1'b0;
endcase
endgenerate

generate 
case (mult23_saturation_register)
	"CLOCK0": assign mult23_saturation_en = ena0;
	"CLOCK1": assign mult23_saturation_en = ena1;
	"CLOCK2": assign mult23_saturation_en = ena2;
	"CLOCK3": assign mult23_saturation_en = ena3;
	default : assign mult23_saturation_en = 1'b0;
endcase
endgenerate

generate 
case (mult23_saturation_aclr)
	"ACLR0": assign mult23_saturation_clr = aclr0;
	"ACLR1": assign mult23_saturation_clr = aclr1;
	"ACLR2": assign mult23_saturation_clr = aclr2;
	"ACLR3": assign mult23_saturation_clr = aclr3;
	default : assign mult23_saturation_clr = 1'b0;
endcase
endgenerate

generate 
case (addnsub1_round_register)
	"CLOCK0": assign addnsub1_round_clk = clock0;
	"CLOCK1": assign addnsub1_round_clk = clock1;
	"CLOCK2": assign addnsub1_round_clk = clock2;
	"CLOCK3": assign addnsub1_round_clk = clock3;
	default : assign addnsub1_round_clk = 1'b0;
endcase
endgenerate

generate 
case (addnsub1_round_register)
	"CLOCK0": assign addnsub1_round_en = ena0;
	"CLOCK1": assign addnsub1_round_en = ena1;
	"CLOCK2": assign addnsub1_round_en = ena2;
	"CLOCK3": assign addnsub1_round_en = ena3;
	default : assign addnsub1_round_en = 1'b0;
endcase
endgenerate

generate 
case (addnsub1_round_aclr)
	"ACLR0": assign addnsub1_round_clr = aclr0;
	"ACLR1": assign addnsub1_round_clr = aclr1;
	"ACLR2": assign addnsub1_round_clr = aclr2;
	"ACLR3": assign addnsub1_round_clr = aclr3;
	default : assign addnsub1_round_clr = 1'b0;
endcase
endgenerate

generate 
case (addnsub1_round_pipeline_register)
	"CLOCK0": assign addnsub1_round_pipe_clk = clock0;
	"CLOCK1": assign addnsub1_round_pipe_clk = clock1;
	"CLOCK2": assign addnsub1_round_pipe_clk = clock2;
	"CLOCK3": assign addnsub1_round_pipe_clk = clock3;
	default : assign addnsub1_round_pipe_clk = 1'b0;
endcase
endgenerate

generate 
case (addnsub1_round_pipeline_register)
	"CLOCK0": assign addnsub1_round_pipe_en = ena0;
	"CLOCK1": assign addnsub1_round_pipe_en = ena1;
	"CLOCK2": assign addnsub1_round_pipe_en = ena2;
	"CLOCK3": assign addnsub1_round_pipe_en = ena3;
	default : assign addnsub1_round_pipe_en = 1'b0;
endcase
endgenerate

generate 
case (addnsub1_round_pipeline_aclr)
	"ACLR0": assign addnsub1_round_pipe_clr = aclr0;
	"ACLR1": assign addnsub1_round_pipe_clr = aclr1;
	"ACLR2": assign addnsub1_round_pipe_clr = aclr2;
	"ACLR3": assign addnsub1_round_pipe_clr = aclr3;
	default : assign addnsub1_round_pipe_clr = 1'b0;
endcase
endgenerate

generate 
case(addnsub3_round_register)
	"CLOCK0": 
		begin 
			assign addnsub3_round_clk = clock0; 
			assign addnsub3_round_en = ena0; 
		end
	"CLOCK1": 
		begin 
			assign addnsub3_round_clk = clock1; 
			assign addnsub3_round_en = ena1; 
		end
	"CLOCK2": 
		begin 
			assign addnsub3_round_clk = clock2; 
			assign addnsub3_round_en = ena2; 
		end
	"CLOCK3": 
		begin 
			assign addnsub3_round_clk = clock3; 
			assign addnsub3_round_en = ena3; 
		end
	default : 	
		begin 
			assign addnsub3_round_clk = 1'b0; 
			assign addnsub3_round_en = 1'b0; 
		end
endcase
endgenerate

generate 
case(addnsub3_round_aclr)
	"ACLR0": assign addnsub3_round_clr = aclr0;
	"ACLR1": assign addnsub3_round_clr = aclr1;
	"ACLR2": assign addnsub3_round_clr = aclr2;
	"ACLR3": assign addnsub3_round_clr = aclr3;
	default : assign addnsub3_round_clr = 1'b0; 
endcase
endgenerate

generate 
case(addnsub3_round_pipeline_register)
	"CLOCK0": 
		begin 
			assign addnsub3_round_pipe_clk = clock0; 
			assign addnsub3_round_pipe_en = ena0; 
		end
	"CLOCK1": 
		begin 
			assign addnsub3_round_pipe_clk = clock1; 
			assign addnsub3_round_pipe_en = ena1; 
		end
	"CLOCK2": 
		begin 
			assign addnsub3_round_pipe_clk = clock2; 
			assign addnsub3_round_pipe_en = ena2; 
		end
	"CLOCK3": 
		begin 
			assign addnsub3_round_pipe_clk = clock3; 
			assign addnsub3_round_pipe_en = ena3; 
		end
	default : 	
		begin 
			assign addnsub3_round_pipe_clk = 1'b0; 
			assign addnsub3_round_pipe_en = 1'b0; 
		end
endcase
endgenerate

generate 
case(addnsub3_round_pipeline_aclr)
	"ACLR0": assign addnsub3_round_pipe_clr = aclr0;
	"ACLR1": assign addnsub3_round_pipe_clr = aclr1;
	"ACLR2": assign addnsub3_round_pipe_clr = aclr2;
	"ACLR3": assign addnsub3_round_pipe_clr = aclr3;
	default : assign addnsub3_round_pipe_clr = 1'b0; 
endcase
endgenerate

// Scanout A register for StratixIII
generate 
case(scanouta_register)
	"CLOCK0": begin assign scanouta_clk = clock0; assign scanouta_ena = ena0; end
	"CLOCK1": begin assign scanouta_clk = clock1; assign scanouta_ena = ena1; end
	"CLOCK2": begin assign scanouta_clk = clock2; assign scanouta_ena = ena2; end
	"CLOCK3": begin assign scanouta_clk = clock3; assign scanouta_ena = ena3; end
	default : begin assign scanouta_clk = 1'b0; assign scanouta_ena = 1'b0; end
endcase
endgenerate

generate 
case(scanouta_aclr)
	"ACLR0": assign scouta_clr = aclr0;
	"ACLR1": assign scouta_clr = aclr1;
	"ACLR2": assign scouta_clr = aclr2;
	"ACLR3": assign scouta_clr = aclr3;
	default : assign scouta_clr = 1'b0; 
endcase
endgenerate

generate 
case(zero_loopback_register)
	"CLOCK0": begin assign zero_lpbk_clk = clock0; assign zero_lpbk_ena = ena0; end
	"CLOCK1": begin assign zero_lpbk_clk = clock1; assign zero_lpbk_ena = ena1; end
	"CLOCK2": begin assign zero_lpbk_clk = clock2; assign zero_lpbk_ena = ena2; end
	"CLOCK3": begin assign zero_lpbk_clk = clock3; assign zero_lpbk_ena = ena3; end
	default : begin assign zero_lpbk_clk = 1'b0; assign zero_lpbk_ena = 1'b0; end
endcase
endgenerate

generate 
case(zero_loopback_aclr)
	"ACLR0": assign zero_lpbk_clr = aclr0;
	"ACLR1": assign zero_lpbk_clr = aclr1;
	"ACLR2": assign zero_lpbk_clr = aclr2;
	"ACLR3": assign zero_lpbk_clr = aclr3;
	default : assign zero_lpbk_clr = 1'b0; 
endcase
endgenerate


generate 
case(zero_loopback_pipeline_register)
	"CLOCK0": begin assign zero_lpbk_pipe_clk = clock0; assign zero_lpbk_pipe_ena = ena0; end
	"CLOCK1": begin assign zero_lpbk_pipe_clk = clock1; assign zero_lpbk_pipe_ena = ena1; end
	"CLOCK2": begin assign zero_lpbk_pipe_clk = clock2; assign zero_lpbk_pipe_ena = ena2; end
	"CLOCK3": begin assign zero_lpbk_pipe_clk = clock3; assign zero_lpbk_pipe_ena = ena3; end
	default : begin assign zero_lpbk_pipe_clk = 1'b0; assign zero_lpbk_pipe_ena = 1'b0; end
endcase
endgenerate

generate 
case(zero_loopback_pipeline_aclr)
	"ACLR0": assign zero_lpbk_pipe_clr = aclr0;
	"ACLR1": assign zero_lpbk_pipe_clr = aclr1;
	"ACLR2": assign zero_lpbk_pipe_clr = aclr2;
	"ACLR3": assign zero_lpbk_pipe_clr = aclr3;
	default : assign zero_lpbk_pipe_clr = 1'b0; 
endcase
endgenerate



generate 
case(zero_loopback_output_register)
	"CLOCK0": begin assign zero_lpbk_out_clk = clock0; assign zero_lpbk_out_ena = ena0; end
	"CLOCK1": begin assign zero_lpbk_out_clk = clock1; assign zero_lpbk_out_ena = ena1; end
	"CLOCK2": begin assign zero_lpbk_out_clk = clock2; assign zero_lpbk_out_ena = ena2; end
	"CLOCK3": begin assign zero_lpbk_out_clk = clock3; assign zero_lpbk_out_ena = ena3; end
	default : begin assign zero_lpbk_out_clk = 1'b0; assign zero_lpbk_out_ena = 1'b0; end
endcase
endgenerate

generate 
case(zero_loopback_output_aclr)
	"ACLR0": assign zero_lpbk_out_clr = aclr0;
	"ACLR1": assign zero_lpbk_out_clr = aclr1;
	"ACLR2": assign zero_lpbk_out_clr = aclr2;
	"ACLR3": assign zero_lpbk_out_clr = aclr3;
	default : assign zero_lpbk_out_clr = 1'b0; 
endcase
endgenerate


generate 
case(accum_sload_register)
	"CLOCK0": begin assign accum_sload_clk = clock0; assign accum_sload_ena = ena0; end
	"CLOCK1": begin assign accum_sload_clk = clock1; assign accum_sload_ena = ena1; end
	"CLOCK2": begin assign accum_sload_clk = clock2; assign accum_sload_ena = ena2; end
	"CLOCK3": begin assign accum_sload_clk = clock3; assign accum_sload_ena = ena3; end
	default : begin assign accum_sload_clk = 1'b0; assign accum_sload_ena = 1'b0; end
endcase
endgenerate

generate 
case(accum_sload_aclr)
	"ACLR0": assign accum_sload_clr = aclr0;
	"ACLR1": assign accum_sload_clr = aclr1;
	"ACLR2": assign accum_sload_clr = aclr2;
	"ACLR3": assign accum_sload_clr = aclr3;
	default : assign accum_sload_clr = 1'b0; 
endcase
endgenerate

generate 
case(accum_sload_pipeline_register)
	"CLOCK0": begin assign accum_sload_pipe_clk = clock0; assign accum_sload_pipe_ena = ena0; end
	"CLOCK1": begin assign accum_sload_pipe_clk = clock1; assign accum_sload_pipe_ena = ena1; end
	"CLOCK2": begin assign accum_sload_pipe_clk = clock2; assign accum_sload_pipe_ena = ena2; end
	"CLOCK3": begin assign accum_sload_pipe_clk = clock3; assign accum_sload_pipe_ena = ena3; end
	default : begin assign accum_sload_pipe_clk = 1'b0; assign accum_sload_pipe_ena = 1'b0; end
endcase
endgenerate

generate 
case(accum_sload_pipeline_aclr)
	"ACLR0": assign accum_sload_pipe_clr = aclr0;
	"ACLR1": assign accum_sload_pipe_clr = aclr1;
	"ACLR2": assign accum_sload_pipe_clr = aclr2;
	"ACLR3": assign accum_sload_pipe_clr = aclr3;
	default : assign accum_sload_pipe_clr = 1'b0; 
endcase
endgenerate

generate 
case(output_round_register)
	"CLOCK0": begin assign out_round_clk = clock0; assign out_round_ena = ena0; end
	"CLOCK1": begin assign out_round_clk = clock1; assign out_round_ena = ena1; end
	"CLOCK2": begin assign out_round_clk = clock2; assign out_round_ena = ena2; end
	"CLOCK3": begin assign out_round_clk = clock3; assign out_round_ena = ena3; end
	default : begin assign out_round_clk = 1'b0; assign out_round_ena = 1'b0; end
endcase
endgenerate

generate 
case(output_round_aclr)
	"ACLR0": assign out_round_clr = aclr0;
	"ACLR1": assign out_round_clr = aclr1;
	"ACLR2": assign out_round_clr = aclr2;
	"ACLR3": assign out_round_clr = aclr3;
	default : assign out_round_clr = 1'b0; 
endcase
endgenerate

generate 
case(output_round_pipeline_register)
	"CLOCK0": begin assign out_round_pipe_clk = clock0; assign out_round_pipe_ena = ena0; end
	"CLOCK1": begin assign out_round_pipe_clk = clock1; assign out_round_pipe_ena = ena1; end
	"CLOCK2": begin assign out_round_pipe_clk = clock2; assign out_round_pipe_ena = ena2; end
	"CLOCK3": begin assign out_round_pipe_clk = clock3; assign out_round_pipe_ena = ena3; end
	default : begin assign out_round_pipe_clk = 1'b0; assign out_round_pipe_ena = 1'b0; end
endcase
endgenerate

generate 
case(output_round_pipeline_aclr)
	"ACLR0": assign out_round_pipe_clr = aclr0;
	"ACLR1": assign out_round_pipe_clr = aclr1;
	"ACLR2": assign out_round_pipe_clr = aclr2;
	"ACLR3": assign out_round_pipe_clr = aclr3;
	default : assign out_round_pipe_clr = 1'b0; 
endcase
endgenerate

generate 
case(output_saturate_register)
	"CLOCK0": begin assign out_sat_clk = clock0; assign out_sat_ena = ena0; end
	"CLOCK1": begin assign out_sat_clk = clock1; assign out_sat_ena = ena1; end
	"CLOCK2": begin assign out_sat_clk = clock2; assign out_sat_ena = ena2; end
	"CLOCK3": begin assign out_sat_clk = clock3; assign out_sat_ena = ena3; end
	default : begin assign out_sat_clk = 1'b0; assign out_sat_ena = 1'b0; end
endcase
endgenerate

generate 
case(output_saturate_aclr)
	"ACLR0": assign out_sat_clr = aclr0;
	"ACLR1": assign out_sat_clr = aclr1;
	"ACLR2": assign out_sat_clr = aclr2;
	"ACLR3": assign out_sat_clr = aclr3;
	default : assign out_sat_clr = 1'b0; 
endcase
endgenerate

generate 
case(output_saturate_pipeline_register)
	"CLOCK0": begin assign out_sat_pipe_clk = clock0; assign out_sat_pipe_ena = ena0; end
	"CLOCK1": begin assign out_sat_pipe_clk = clock1; assign out_sat_pipe_ena = ena1; end
	"CLOCK2": begin assign out_sat_pipe_clk = clock2; assign out_sat_pipe_ena = ena2; end
	"CLOCK3": begin assign out_sat_pipe_clk = clock3; assign out_sat_pipe_ena = ena3; end
	default : begin assign out_sat_pipe_clk = 1'b0; assign out_sat_pipe_ena = 1'b0; end
endcase
endgenerate

generate 
case(output_saturate_pipeline_aclr)
	"ACLR0": assign out_sat_pipe_clr = aclr0;
	"ACLR1": assign out_sat_pipe_clr = aclr1;
	"ACLR2": assign out_sat_pipe_clr = aclr2;
	"ACLR3": assign out_sat_pipe_clr = aclr3;
	default : assign out_sat_pipe_clr = 1'b0; 
endcase
endgenerate

generate 
case(chainout_register)
	"CLOCK0": begin assign chainout_clk = clock0; assign chainout_ena = ena0; end
	"CLOCK1": begin assign chainout_clk = clock1; assign chainout_ena = ena1; end
	"CLOCK2": begin assign chainout_clk = clock2; assign chainout_ena = ena2; end
	"CLOCK3": begin assign chainout_clk = clock3; assign chainout_ena = ena3; end
	default : begin assign chainout_clk = 1'b0; assign chainout_ena = 1'b0; end
endcase
endgenerate

generate 
case(chainout_aclr)
	"ACLR0": assign chainout_clr = aclr0;
	"ACLR1": assign chainout_clr = aclr1;
	"ACLR2": assign chainout_clr = aclr2;
	"ACLR3": assign chainout_clr = aclr3;
	default : assign chainout_clr = 1'b0; 
endcase
endgenerate

generate 
case(chainout_round_register)
	"CLOCK0": begin assign chain_round_clk = clock0; assign chain_round_ena = ena0; end
	"CLOCK1": begin assign chain_round_clk = clock1; assign chain_round_ena = ena1; end
	"CLOCK2": begin assign chain_round_clk = clock2; assign chain_round_ena = ena2; end
	"CLOCK3": begin assign chain_round_clk = clock3; assign chain_round_ena = ena3; end
	default : begin assign chain_round_clk = 1'b0; assign chain_round_ena = 1'b0; end
endcase
endgenerate

generate 
case(chainout_round_aclr)
	"ACLR0": assign chain_round_clr = aclr0;
	"ACLR1": assign chain_round_clr = aclr1;
	"ACLR2": assign chain_round_clr = aclr2;
	"ACLR3": assign chain_round_clr = aclr3;
	default : assign chain_round_clr = 1'b0; 
endcase
endgenerate

generate 
case(chainout_round_pipeline_register)
	"CLOCK0": begin assign chain_round_pipe_clk = clock0; assign chain_round_pipe_ena = ena0; end
	"CLOCK1": begin assign chain_round_pipe_clk = clock1; assign chain_round_pipe_ena = ena1; end
	"CLOCK2": begin assign chain_round_pipe_clk = clock2; assign chain_round_pipe_ena = ena2; end
	"CLOCK3": begin assign chain_round_pipe_clk = clock3; assign chain_round_pipe_ena = ena3; end
	default : begin assign chain_round_pipe_clk = 1'b0; assign chain_round_pipe_ena = 1'b0; end
endcase
endgenerate

generate 
case(chainout_round_pipeline_aclr)
	"ACLR0": assign chain_round_pipe_clr = aclr0;
	"ACLR1": assign chain_round_pipe_clr = aclr1;
	"ACLR2": assign chain_round_pipe_clr = aclr2;
	"ACLR3": assign chain_round_pipe_clr = aclr3;
	default : assign chain_round_pipe_clr = 1'b0; 
endcase
endgenerate

generate 
case(chainout_round_output_register)
	"CLOCK0": begin assign chain_round_out_clk = clock0; assign chain_round_out_ena = ena0; end
	"CLOCK1": begin assign chain_round_out_clk = clock1; assign chain_round_out_ena = ena1; end
	"CLOCK2": begin assign chain_round_out_clk = clock2; assign chain_round_out_ena = ena2; end
	"CLOCK3": begin assign chain_round_out_clk = clock3; assign chain_round_out_ena = ena3; end
	default : begin assign chain_round_out_clk = 1'b0; assign chain_round_out_ena = 1'b0; end
endcase
endgenerate

generate 
case(chainout_round_output_aclr)
	"ACLR0": assign chain_round_out_clr = aclr0;
	"ACLR1": assign chain_round_out_clr = aclr1;
	"ACLR2": assign chain_round_out_clr = aclr2;
	"ACLR3": assign chain_round_out_clr = aclr3;
	default : assign chain_round_out_clr = 1'b0; 
endcase
endgenerate

generate 
case(chainout_saturate_register)
	"CLOCK0": begin assign chain_sat_clk = clock0; assign chain_sat_ena = ena0; end
	"CLOCK1": begin assign chain_sat_clk = clock1; assign chain_sat_ena = ena1; end
	"CLOCK2": begin assign chain_sat_clk = clock2; assign chain_sat_ena = ena2; end
	"CLOCK3": begin assign chain_sat_clk = clock3; assign chain_sat_ena = ena3; end
	default : begin assign chain_sat_clk = 1'b0; assign chain_sat_ena = 1'b0; end
endcase
endgenerate

generate 
case(chainout_saturate_aclr)
	"ACLR0": assign chain_sat_clr = aclr0;
	"ACLR1": assign chain_sat_clr = aclr1;
	"ACLR2": assign chain_sat_clr = aclr2;
	"ACLR3": assign chain_sat_clr = aclr3;
	default : assign chain_sat_clr = 1'b0; 
endcase
endgenerate

generate 
case(chainout_saturate_pipeline_register)
	"CLOCK0": begin assign chain_sat_pipe_clk = clock0; assign chain_sat_pipe_ena = ena0; end
	"CLOCK1": begin assign chain_sat_pipe_clk = clock1; assign chain_sat_pipe_ena = ena1; end
	"CLOCK2": begin assign chain_sat_pipe_clk = clock2; assign chain_sat_pipe_ena = ena2; end
	"CLOCK3": begin assign chain_sat_pipe_clk = clock3; assign chain_sat_pipe_ena = ena3; end
	default : begin assign chain_sat_pipe_clk = 1'b0; assign chain_sat_pipe_ena = 1'b0; end
endcase
endgenerate

generate 
case(chainout_saturate_pipeline_aclr)
	"ACLR0": assign chain_sat_pipe_clr = aclr0;
	"ACLR1": assign chain_sat_pipe_clr = aclr1;
	"ACLR2": assign chain_sat_pipe_clr = aclr2;
	"ACLR3": assign chain_sat_pipe_clr = aclr3;
	default : assign chain_sat_pipe_clr = 1'b0; 
endcase
endgenerate

generate 
case(chainout_saturate_output_register)
	"CLOCK0": begin assign chain_sat_out_clk = clock0; assign chain_sat_out_ena = ena0; end
	"CLOCK1": begin assign chain_sat_out_clk = clock1; assign chain_sat_out_ena = ena1; end
	"CLOCK2": begin assign chain_sat_out_clk = clock2; assign chain_sat_out_ena = ena2; end
	"CLOCK3": begin assign chain_sat_out_clk = clock3; assign chain_sat_out_ena = ena3; end
	default : begin assign chain_sat_out_clk = 1'b0; assign chain_sat_out_ena = 1'b0; end
endcase
endgenerate

generate 
case(chainout_saturate_output_aclr)
	"ACLR0": assign chain_sat_out_clr = aclr0;
	"ACLR1": assign chain_sat_out_clr = aclr1;
	"ACLR2": assign chain_sat_out_clr = aclr2;
	"ACLR3": assign chain_sat_out_clr = aclr3;
	default : assign chain_sat_out_clr = 1'b0; 
endcase
endgenerate

generate
case(zero_chainout_output_register)
	"CLOCK0": begin assign zero_chain_clk = clock0; assign zero_chain_ena = ena0; end
	"CLOCK1": begin assign zero_chain_clk = clock1; assign zero_chain_ena = ena1; end
	"CLOCK2": begin assign zero_chain_clk = clock2; assign zero_chain_ena = ena2; end
	"CLOCK3": begin assign zero_chain_clk = clock3; assign zero_chain_ena = ena3; end
	default : begin assign zero_chain_clk = 1'b0; assign zero_chain_ena = 1'b0; end
endcase
endgenerate

generate 
case(zero_chainout_output_aclr)
	"ACLR0": assign zero_chain_clr = aclr0;
	"ACLR1": assign zero_chain_clr = aclr1;
	"ACLR2": assign zero_chain_clr = aclr2;
	"ACLR3": assign zero_chain_clr = aclr3;
	default : assign zero_chain_clr = 1'b0; 
endcase
endgenerate

generate
case(rotate_register)
	"CLOCK0": begin assign rotate_clk = clock0; assign rotate_ena = ena0; end
	"CLOCK1": begin assign rotate_clk = clock1; assign rotate_ena = ena1; end
	"CLOCK2": begin assign rotate_clk = clock2; assign rotate_ena = ena2; end
	"CLOCK3": begin assign rotate_clk = clock3; assign rotate_ena = ena3; end
	default : begin assign rotate_clk = 1'b0; assign rotate_ena = 1'b0; end
endcase
endgenerate

generate 
case(rotate_aclr)
	"ACLR0": assign rotate_clr = aclr0;
	"ACLR1": assign rotate_clr = aclr1;
	"ACLR2": assign rotate_clr = aclr2;
	"ACLR3": assign rotate_clr = aclr3;
	default : assign rotate_clr = 1'b0; 
endcase
endgenerate

generate
case(rotate_pipeline_register)
	"CLOCK0": begin assign rotate_pipe_clk = clock0; assign rotate_pipe_ena = ena0; end
	"CLOCK1": begin assign rotate_pipe_clk = clock1; assign rotate_pipe_ena = ena1; end
	"CLOCK2": begin assign rotate_pipe_clk = clock2; assign rotate_pipe_ena = ena2; end
	"CLOCK3": begin assign rotate_pipe_clk = clock3; assign rotate_pipe_ena = ena3; end
	default : begin assign rotate_pipe_clk = 1'b0; assign rotate_pipe_ena = 1'b0; end
endcase
endgenerate

generate 
case(rotate_pipeline_aclr)
	"ACLR0": assign rotate_pipe_clr = aclr0;
	"ACLR1": assign rotate_pipe_clr = aclr1;
	"ACLR2": assign rotate_pipe_clr = aclr2;
	"ACLR3": assign rotate_pipe_clr = aclr3;
	default : assign rotate_pipe_clr = 1'b0; 
endcase
endgenerate

generate
case(rotate_output_register)
	"CLOCK0": begin assign rotate_out_clk = clock0; assign rotate_out_ena = ena0; end
	"CLOCK1": begin assign rotate_out_clk = clock1; assign rotate_out_ena = ena1; end
	"CLOCK2": begin assign rotate_out_clk = clock2; assign rotate_out_ena = ena2; end
	"CLOCK3": begin assign rotate_out_clk = clock3; assign rotate_out_ena = ena3; end
	default : begin assign rotate_out_clk = 1'b0; assign rotate_out_ena = 1'b0; end
endcase
endgenerate

generate 
case(rotate_output_aclr)
	"ACLR0": assign rotate_out_clr = aclr0;
	"ACLR1": assign rotate_out_clr = aclr1;
	"ACLR2": assign rotate_out_clr = aclr2;
	"ACLR3": assign rotate_out_clr = aclr3;
	default : assign rotate_out_clr = 1'b0; 
endcase
endgenerate

generate
case(shift_right_register)
	"CLOCK0": begin assign shiftr_clk = clock0; assign shiftr_ena = ena0; end
	"CLOCK1": begin assign shiftr_clk = clock1; assign shiftr_ena = ena1; end
	"CLOCK2": begin assign shiftr_clk = clock2; assign shiftr_ena = ena2; end
	"CLOCK3": begin assign shiftr_clk = clock3; assign shiftr_ena = ena3; end
	default : begin assign shiftr_clk = 1'b0; assign shiftr_ena = 1'b0; end
endcase
endgenerate

generate 
case(shift_right_aclr)
	"ACLR0": assign shiftr_clr = aclr0;
	"ACLR1": assign shiftr_clr = aclr1;
	"ACLR2": assign shiftr_clr = aclr2;
	"ACLR3": assign shiftr_clr = aclr3;
	default : assign shiftr_clr = 1'b0; 
endcase
endgenerate

generate
case(shift_right_pipeline_register)
	"CLOCK0": begin assign shiftr_pipe_clk = clock0; assign shiftr_pipe_ena = ena0; end
	"CLOCK1": begin assign shiftr_pipe_clk = clock1; assign shiftr_pipe_ena = ena1; end
	"CLOCK2": begin assign shiftr_pipe_clk = clock2; assign shiftr_pipe_ena = ena2; end
	"CLOCK3": begin assign shiftr_pipe_clk = clock3; assign shiftr_pipe_ena = ena3; end
	default : begin assign shiftr_pipe_clk = 1'b0; assign shiftr_pipe_ena = 1'b0; end
endcase
endgenerate

generate 
case(shift_right_pipeline_aclr)
	"ACLR0": assign shiftr_pipe_clr = aclr0;
	"ACLR1": assign shiftr_pipe_clr = aclr1;
	"ACLR2": assign shiftr_pipe_clr = aclr2;
	"ACLR3": assign shiftr_pipe_clr = aclr3;
	default : assign shiftr_pipe_clr = 1'b0; 
endcase
endgenerate

generate
case(shift_right_output_register)
	"CLOCK0": begin assign shiftr_out_clk = clock0; assign shiftr_out_ena = ena0; end
	"CLOCK1": begin assign shiftr_out_clk = clock1; assign shiftr_out_ena = ena1; end
	"CLOCK2": begin assign shiftr_out_clk = clock2; assign shiftr_out_ena = ena2; end
	"CLOCK3": begin assign shiftr_out_clk = clock3; assign shiftr_out_ena = ena3; end
	default : begin assign shiftr_out_clk = 1'b0; assign shiftr_out_ena = 1'b0; end
endcase
endgenerate

generate 
case(shift_right_output_aclr)
	"ACLR0": assign shiftr_out_clr = aclr0;
	"ACLR1": assign shiftr_out_clr = aclr1;
	"ACLR2": assign shiftr_out_clr = aclr2;
	"ACLR3": assign shiftr_out_clr = aclr3;
	default : assign shiftr_out_clr = 1'b0; 
endcase
endgenerate
// ************** Output block ******************** //
generate
if (chainout_adder == "NO") begin

	if (width_result > width_a+width_b+2)
		assign result = {{(width_result-(width_a+width_b+2)){extend_bit}},dataout};
	else
   	assign result = dataout[width_result -1 : 0];
end
else
	begin
		assign result  = chainout_out_reg & {width_result{~zero_chain_reg}};
	end
endgenerate

generate
if (port_output_is_overflow == "PORT_USED") begin
	assign overflow = accum_overflow_reg_late;
end
endgenerate

generate
if ( (number_of_multipliers == 2) && (input_source_b0 == "LOOPBACK") )
	// Only valid for sum of 2 mode
	assign loopbackout = {width_b{~zero_lpbk_out_reg}} & dataout[2*width_b-1: width_b];
else
	assign loopbackout = {width_b{1'b0}};
endgenerate

// ************** Dynamic Source Selection ********** //
assign dataa_in[width_a-1:0] = (input_source_a0 == "DATAA" || (
	input_source_a0 == "VARIABLE" && sourcea[0] == 1'b0))? 
		dataa[width_a-1:0] : scanina;

generate
if (number_of_multipliers > 1)
begin

assign dataa_in[2*width_a-1:width_a] = (
	(input_source_a1 == "DATAA" || 
	(input_source_a1 == "VARIABLE" && sourcea[1] == 1'b0))? 
		dataa[2*width_a-1:width_a] : mult1_a_reg_in );
end
else
assign dataa_in[2*width_a-1:width_a] = 'b0;
endgenerate

generate
if (number_of_multipliers > 2)
begin
assign dataa_in[3*width_a-1:2*width_a] = (
	(input_source_a2 == "DATAA" || 
	(input_source_a2 == "VARIABLE" && sourcea[2] == 1'b0))? 
		dataa[3*width_a-1:2*width_a] : mult2_a_reg_in );
end
else
assign dataa_in[3*width_a-1:2*width_a] = 'b0;
endgenerate

generate
if (number_of_multipliers > 3)
begin
assign dataa_in[4*width_a-1:3*width_a] = (
	(input_source_a3 == "DATAA" || 
	(input_source_a3 == "VARIABLE" && sourcea[3] == 1'b0))? 
		dataa[4*width_a-1:3*width_a] : mult3_a_reg_in ) ;
end
else
assign dataa_in[4*width_a-1:3*width_a] = 'b0;
endgenerate

assign datab_in[width_b-1:0] = (input_source_b0 == "LOOPBACK")? loopbackout : (
			(input_source_b0 == "DATAB" || 
        (input_source_b0 == "VARIABLE" && sourceb[0] == 1'b0))?
                datab[width_b-1:0] : scaninb );

generate
if (number_of_multipliers > 1)
begin
assign datab_in[2*width_b-1:width_b] =  (
	(input_source_b1 == "DATAB" ||
        (input_source_b1 == "VARIABLE" && sourceb[1] == 1'b0))?
                datab[2*width_b-1:width_b] : mult1_b_reg_in );
end
else
assign datab_in[2*width_b-1:width_b] = 'b0;
endgenerate

generate
if (number_of_multipliers > 2)
begin
assign datab_in[3*width_b-1:2*width_b] = (
	(input_source_b2 == "DATAB" || 
        (input_source_b2 == "VARIABLE" && sourceb[2] == 1'b0))?
                datab[3*width_b-1:2*width_b] : mult2_b_reg_in );
end
else
assign datab_in[3*width_b-1:2*width_b] = 'b0;
endgenerate

generate
if (number_of_multipliers > 3)
begin
assign datab_in[4*width_b-1:3*width_b] = (
	(input_source_b3 == "DATAB" || 
        (input_source_b3 == "VARIABLE" && sourceb[3] == 1'b0))?
                datab[4*width_b-1:3*width_b] : mult3_b_reg_in );
end
else 
assign datab_in[4*width_b-1:3*width_b] = 'b0;
endgenerate

// ************** Multiplier inputs ************ //
assign dataa_wide = {dataa_in};
assign datab_wide = {datab_in};

// for input A
generate if (sign_extend_a == "YES") begin

	assign mult1_a_in = (signa_rev)? {dataa_wide[width_a-1],dataa_wide[width_a-1:0]} : {1'b0,dataa_wide[width_a-1:0]};
	assign mult2_a_in = (signa_rev)? {dataa_wide[(2*width_a)-1],dataa_wide[(2*width_a)-1:width_a]} :
												{1'b0,dataa_wide[(2*width_a)-1:width_a]} ;
	assign mult3_a_in = (signa_rev)? {dataa_wide[(3*width_a)-1],dataa_wide[(3*width_a)-1:(2*width_a)]} :
												{1'b0,dataa_wide[(3*width_a)-1:(2*width_a)]} ;
	assign mult4_a_in = (signa_rev)? {dataa_wide[(4*width_a)-1],dataa_wide[(4*width_a)-1:(3*width_a)]} :
												{1'b0,dataa_wide[(4*width_a)-1:(3*width_a)]} ;

end
else
begin
assign mult1_a_in = dataa_wide[width_a-1:0];
assign mult2_a_in = dataa_wide[(2*width_a)-1:width_a];
assign mult3_a_in = dataa_wide[(3*width_a)-1:(2*width_a)];
assign mult4_a_in = dataa_wide[(4*width_a)-1:(3*width_a)];
end
endgenerate

generate if (sign_extend_b=="YES") begin 

// for input B
	assign mult1_b_in = (signb_rev)? {datab_wide[width_b-1],datab_wide[width_b-1:0]} : {1'b0,datab_wide[width_b-1:0]};
	assign mult2_b_in = (signb_rev)? {datab_wide[(2*width_b)-1],datab_wide[(2*width_b)-1:width_b] } :
												{1'b0,datab_wide[(2*width_b)-1:width_b] };
	assign mult3_b_in = (signb_rev)? {datab_wide[(3*width_b)-1],datab_wide[(3*width_b)-1:(2*width_b)] } :
												{ 1'b0,datab_wide[(3*width_b)-1:(2*width_b)] };
	assign mult4_b_in = (signb_rev)? {datab_wide[(4*width_b)-1],datab_wide[(4*width_b)-1:(3*width_b)] } :
												{ 1'b0,datab_wide[(4*width_b)-1:(3*width_b)] };
end
else
begin
assign mult1_b_in = datab_wide[width_b-1:0];
assign mult2_b_in = datab_wide[(2*width_b)-1:width_b];
assign mult3_b_in = datab_wide[(3*width_b)-1:(2*width_b)];
assign mult4_b_in = datab_wide[(4*width_b)-1:(3*width_b)];
end
endgenerate

assign mult_a_reg_in = {mult4_a_reg_in,mult3_a_reg_in,mult2_a_reg_in,mult1_a_reg_in};
assign mult_b_reg_in = {mult4_b_reg_in,mult3_b_reg_in,mult2_b_reg_in,mult1_b_reg_in};

// ************** Scan outputs ************ //

assign scanouta = scanouta_reg;
assign scanoutb = mult_b_reg_in[(number_of_multipliers * width_b)-1 : ((number_of_multipliers-1) * width_b)];

//////////////////////////// synchronous logic  ////////////////////////////////////////

// ************** Sign A/B logic ************ //

assign signa_rev = (port_signa == "PORT_UNUSED")?
                    ((representation_a != "UNUSED") ? 
                      (representation_a == "SIGNED" ? 1'b1 : 1'b0) : 1'b0
                    ) : (
		   (port_signa == "PORT_USED")? signa : (
		    ((representation_a != "UNUSED") ?
			(representation_a == "SIGNED" ? 1'b1 : 1'b0) : signa)
		    				       )
		    );
// signa reg

generate
if ((signed_register_a != "UNREGISTERED")  && 
	((port_signa!="PORT_UNUSED") || (representation_a=="UNUSED")))
	// don't register a signa_rev if it is permanently set to 1 or 0
begin

	dffep signa_ff (
		signa_in_reg,
		sign_reg_a_clk,
		sign_reg_a_en,
		signa_rev,
		1'b0,
		sign_reg_a_clr
	);

    assign signa_reg = signa_in_reg;
end
else
    assign signa_reg = signa_rev; 
endgenerate


// signa pipe

generate
if ((signed_pipeline_register_a != "UNREGISTERED") &&
	((port_signa!="PORT_UNUSED") || (representation_a=="UNUSED")))
begin

	dffep signa_pipe_ff (
		signa_in_pipe,
		sign_pipe_a_clk,
		sign_pipe_a_en,
		signa_reg,
		1'b0,
		sign_pipe_a_clr
	);
    assign signa_pipe = signa_in_pipe;
end
else
    assign signa_pipe = signa_reg;
endgenerate

assign signb_rev = (port_signb == "PORT_UNUSED")?
                    ((representation_b != "UNUSED") ? 
                      (representation_b == "SIGNED" ? 1'b1 : 1'b0) : 1'b0
                    ) : (
		   (port_signb == "PORT_USED")? signb : (
		    ((representation_b != "UNUSED") ?
			(representation_b == "SIGNED" ? 1'b1 : 1'b0) : signb)
		    				       )
		    );
// signb reg

generate
if ((signed_register_b != "UNREGISTERED") &&
	((port_signb!="PORT_UNUSED") || (representation_b=="UNUSED")))
begin

	dffep signb_ff (
		signb_in_reg,
		sign_reg_b_clk,
		sign_reg_b_en,
		signb_rev,
		1'b0,
		sign_reg_b_clr
	);

    assign signb_reg = signb_in_reg;

end
else
    assign signb_reg = signb_rev;
endgenerate


// signb pipe

generate
if ((signed_pipeline_register_b != "UNREGISTERED") &&
	((port_signb!="PORT_UNUSED") || (representation_b=="UNUSED")))
begin

	dffep signb_pipe_ff (
		signb_in_pipe,
		sign_pipe_b_clk,
		sign_pipe_b_en,
		signb_reg,
		1'b0,
		sign_pipe_b_clr
	);

	assign signb_pipe = signb_in_pipe;
end
else
	assign signb_pipe = signb_reg;
endgenerate


// ************** Addnsub 1/3 logic ************ //

// addsub1
assign addnsub1_rev = (port_addnsub1 == "PORT_UNUSED")?
                       (( multiplier1_direction != "UNUSED") ? 
                         (multiplier1_direction == "ADD" ? 1'b1 : 1'b0) : 
                        1'b1 ) : (
                      (port_addnsub1 == "PORT_USED")? addnsub1 : (
                       ((multiplier1_direction != "UNUSED") ? 
                         (multiplier1_direction == "ADD" ? 1'b1 : 1'b0) :
			addnsub1) 
				)
			);

// addsub1 reg

generate
if ((addnsub_multiplier_register1 != "UNREGISTERED") &&
	((port_addnsub1!="PORT_UNUSED") || (multiplier1_direction=="UNUSED")))
begin

	dffep addsub1_ff (
		addsub1_in_reg,
		addsub1_reg_clk,
		addsub1_reg_en,
		addnsub1_rev,
		1'b0,
		addsub1_reg_clr
	);

	assign addsub1_reg = addsub1_in_reg;
end
else
	assign addsub1_reg = addnsub1_rev;
endgenerate


// addsub1 pipe

generate
if ((addnsub_multiplier_pipeline_register1 != "UNREGISTERED") &&
	((port_addnsub1!="PORT_UNUSED") || (multiplier1_direction=="UNUSED")))
begin

	dffep addsub1_pipe_ff (
		addsub1_in_pipe,
		addsub1_pipe_clk,
		addsub1_pipe_en,
		addsub1_reg,
		1'b0,
		addsub1_pipe_clr
	);

	assign addsub1_pipe = addsub1_in_pipe;
end
else
	assign addsub1_pipe = addsub1_reg;

endgenerate


// addsub3
assign addnsub3_rev = (port_addnsub3 == "PORT_UNUSED")?
                       ((multiplier3_direction != "UNUSED")? 
                        (multiplier3_direction == "ADD" ? 1'b1 : 1'b0) : 1'b1 
                       ) : (
                      (port_addnsub3 == "PORT_USED")? addnsub3 : (
                       ((multiplier3_direction != "UNUSED") ?
                         (multiplier3_direction == "ADD" ? 1'b1 : 1'b0) :
                        addnsub3)
                                )
                       );

// addsub3 reg

generate
if ((number_of_multipliers>3) && 
	(addnsub_multiplier_register3 != "UNREGISTERED") &&
	((port_addnsub3!="PORT_UNUSED") || (multiplier3_direction=="UNUSED")))
begin

	dffep addsub3_ff (
		addsub3_in_reg,
		addsub3_reg_clk,
		addsub3_reg_en,
		addnsub3_rev,
		1'b0,
		addsub3_reg_clr
	);
	assign addsub3_reg = addsub3_in_reg;

end
else
	assign addsub3_reg = addnsub3_rev;
endgenerate


// addsub3 pipe

generate
if ((number_of_multipliers>3) &&
	(addnsub_multiplier_pipeline_register3 != "UNREGISTERED") &&
	((port_addnsub3!="PORT_UNUSED") || (multiplier3_direction=="UNUSED")))
begin

	dffep addsub3_pipe_ff (
		addsub3_in_pipe,
		addsub3_pipe_clk,
		addsub3_pipe_en,
		addsub3_reg,
		1'b0,
		addsub3_pipe_clr
	);

	assign addsub3_pipe = addsub3_in_pipe;

end
else
	assign addsub3_pipe = addsub3_reg;
endgenerate



// ************** Multiplier input ************ //

// for input A

generate
if (input_register_a0 != "UNREGISTERED")
begin

	dffep mult1_dina_ff[ width_a_adjusted - 1 : 0 ] (
		mult1_a_reg,
		input_reg_a0_clk,
		input_reg_a0_en,
		mult1_a_in,
		1'b0,
		input_reg_a0_clr
	);

	assign mult1_a_reg_in = mult1_a_reg;
end
else
	assign mult1_a_reg_in = mult1_a_in;
endgenerate


generate
if ((number_of_multipliers > 1) && (input_register_a1 != "UNREGISTERED"))
begin

	dffep mult2_dina_ff[ width_a_adjusted - 1 : 0 ] (
		mult2_a_reg,
		input_reg_a1_clk, 
		input_reg_a1_en,
		mult2_a_in,
		1'b0,
		input_reg_a1_clr
	);

	assign mult2_a_reg_in = mult2_a_reg;
end
else
	assign mult2_a_reg_in = mult2_a_in;
endgenerate


generate
if ((number_of_multipliers > 2) && (input_register_a2 != "UNREGISTERED"))
begin

	dffep mult3_dina_ff[ width_a_adjusted - 1 : 0 ] (
		mult3_a_reg,
		input_reg_a2_clk,
		input_reg_a2_en,
		mult3_a_in,
		1'b0,
		input_reg_a2_clr
	);

	assign mult3_a_reg_in = mult3_a_reg;

end
else
	assign mult3_a_reg_in = mult3_a_in;
endgenerate



generate
if ((number_of_multipliers > 3) && (input_register_a3 != "UNREGISTERED"))
begin

	dffep mult4_dina_ff[ width_a_adjusted - 1 : 0 ] (
		mult4_a_reg,
		input_reg_a3_clk,
		input_reg_a3_en,
		mult4_a_in,
		1'b0,
		input_reg_a3_clr
	);

	assign mult4_a_reg_in = mult4_a_reg;

end
else
	assign mult4_a_reg_in = mult4_a_in;
endgenerate

generate
if (scanouta_register != "UNREGISTERED")
begin
	dffep scanouta_ff[width_a-1 : 0 ] (
		scanouta_reg,
		scanouta_clk,
		scanouta_ena,
		mult_a_reg_in[(number_of_multipliers * width_a)-1 : ((number_of_multipliers-1) * width_a)],
		1'b0,
		scanouta_clr,
	);
end
else
	assign scanouta_reg = mult_a_reg_in[(number_of_multipliers * width_a)-1 : ((number_of_multipliers-1) * width_a)];
endgenerate

// for input B

generate
if (input_register_b0 != "UNREGISTERED")
begin

	dffep mult1_dinb_ff[ width_b_adjusted - 1 : 0 ] (
		mult1_b_reg,
		input_reg_b0_clk,
		input_reg_b0_en,
		mult1_b_in,
		1'b0,
		input_reg_b0_clr
	);

	assign mult1_b_reg_in = mult1_b_reg;

end
else
	assign mult1_b_reg_in = mult1_b_in;
endgenerate


generate
if ((number_of_multipliers>1) && (input_register_b1 != "UNREGISTERED"))
begin

	dffep mult2_dinb_ff[ width_b_adjusted - 1 : 0 ] (
		mult2_b_reg,
		input_reg_b1_clk,
		input_reg_b1_en,
		mult2_b_in,
		1'b0,
		input_reg_b1_clr
	);

	assign mult2_b_reg_in = mult2_b_reg;

end
else
	assign mult2_b_reg_in = mult2_b_in;
endgenerate


generate
if ((number_of_multipliers>2) && (input_register_b2 != "UNREGISTERED"))
begin

	dffep mult3_dinb_ff[ width_b_adjusted - 1 : 0 ] (
		mult3_b_reg,
		input_reg_b2_clk,
		input_reg_b2_en,
		mult3_b_in,
		1'b0,
		input_reg_b2_clr 
	);

	assign mult3_b_reg_in = mult3_b_reg;

end
else
	assign mult3_b_reg_in = mult3_b_in;
endgenerate



generate
if ((number_of_multipliers>3) && (input_register_b3 != "UNREGISTERED"))
begin

	dffep mult4_dinb_ff[ width_b_adjusted - 1 : 0 ] (
		mult4_b_reg,
		input_reg_b3_clk,
		input_reg_b3_en,
		mult4_b_in,
		1'b0,
		input_reg_b3_clr
	);

	assign mult4_b_reg_in = mult4_b_reg;

end
else
	assign mult4_b_reg_in = mult4_b_in;
endgenerate


// ******************* Loop Back Control ********************* //
generate
if (zero_loopback_register != "UNREGISTERED")
begin
	dffep lpbk_reg_ff (
		zero_lpbk_reg,
		zero_lpbk_clk,
		zero_lpbk_ena,
		zero_loopback,
		1'b0,
		zero_lpbk_clr
	);
end
else
	assign zero_lpbk_reg = zero_loopback;
endgenerate

generate
if (zero_loopback_pipeline_register != "UNREGISTERED")
begin
	dffep lpbk_pipereg_ff (
		zero_lpbk_pipe,
		zero_lpbk_pipe_clk,
		zero_lpbk_pipe_ena,
		zero_lpbk_reg,
		1'b0,
		zero_lpbk_pipe_clr
	);
end
else
	assign zero_lpbk_pipe = zero_lpbk_reg;
endgenerate

generate
if (zero_loopback_output_register != "UNREGISTERED")
begin
	dffep lpbk_outreg_ff (
		zero_lpbk_out_reg,
		zero_lpbk_out_clk,
		zero_lpbk_out_ena,
		zero_lpbk_pipe,
		1'b0,
		zero_lpbk_out_clr
	);
end
else
	assign zero_lpbk_out_reg = zero_lpbk_pipe;
endgenerate

// ************** Rounding and Saturation Control ************ //
generate
if (multiplier01_rounding =="VARIABLE" && 
	mult01_round_register != "UNREGISTERED")
begin

	dffep mult01_round_ff (
		mult01_round_in_reg,
		mult01_round_clk,
		mult01_round_en,
		mult01_round,
		1'b0,
		mult01_round_clr
	);

	assign mult01_round_signal_reg = mult01_round_in_reg;
end
else
	assign mult01_round_signal_reg = mult01_round;
endgenerate

generate
if (multiplier23_rounding=="VARIABLE" && 
	mult23_round_register != "UNREGISTERED")
begin

	dffep mult23_round_ff (
		mult23_round_in_reg,
		mult23_round_clk,
		mult23_round_en,
		mult23_round,
		1'b0,
		mult23_round_clr
	);

	assign mult23_round_signal_reg = mult23_round_in_reg;
end
else
	assign mult23_round_signal_reg = mult23_round; 
endgenerate

generate
if (multiplier01_saturation=="VARIABLE" && 
	mult01_saturation_register != "UNREGISTERED")
begin

	dffep mult01_saturation_ff (
		mult01_saturation_in_reg,
		mult01_saturation_clk,
		mult01_saturation_en,
		mult01_saturation,
		1'b0,
		mult01_saturation_clr
	);

assign mult01_saturation_signal_reg = mult01_saturation_in_reg;
end
else
	assign mult01_saturation_signal_reg = mult01_saturation;
endgenerate

generate
if (multiplier23_saturation=="VARIABLE" &&
	mult23_saturation_register != "UNREGISTERED")
begin

	dffep mult23_saturation_ff (
		mult23_saturation_in_reg,
		mult23_saturation_clk,
		mult23_saturation_en,
		mult23_saturation,
		1'b0,
		mult23_saturation_clr
	);
	assign mult23_saturation_signal_reg = mult23_saturation_in_reg;

end
else
	assign mult23_saturation_signal_reg = mult23_saturation;
endgenerate

generate
if (adder1_rounding=="VARIABLE" && addnsub1_round_register != "UNREGISTERED")
begin

	dffep addnsub1_round_ff (
		addnsub1_round_in_reg,
		addnsub1_round_clk,
		addnsub1_round_en,
		addnsub1_round,
		1'b0,
		addnsub1_round_clr
	);

assign addnsub1_round_signal_reg = addnsub1_round_in_reg;
end
else
assign addnsub1_round_signal_reg = addnsub1_round;
endgenerate

generate
if (adder1_rounding=="VARIABLE" && 
	addnsub1_round_pipeline_register != "UNREGISTERED")
begin

	dffep addnsub1_round_pipe_ff (
		addnsub1_round_pipe_in_reg,
		addnsub1_round_pipe_clk,
		addnsub1_round_pipe_en,
		addnsub1_round_signal_reg,
		1'b0,
		addnsub1_round_pipe_clr
	);
assign addnsub1_round_pipe_signal_reg = addnsub1_round_pipe_in_reg;

end
else
assign addnsub1_round_pipe_signal_reg = addnsub1_round_signal_reg ;
endgenerate


generate
if (adder3_rounding=="VARIABLE" && addnsub3_round_register != "UNREGISTERED")
begin

	dffep addnsub3_round_ff (
		addnsub3_round_in_reg,
		addnsub3_round_clk,
		addnsub3_round_en,
		addnsub3_round,
		1'b0,
		addnsub3_round_clr
	);
assign addnsub3_round_signal_reg = addnsub3_round_in_reg;

end
else
assign addnsub3_round_signal_reg = addnsub3_round;

endgenerate


generate
if (adder3_rounding=="VARIABLE" && 
	addnsub3_round_pipeline_register != "UNREGISTERED")
begin

	dffep addnsub3_round_pipe_ff (
		addnsub3_round_pipe_in_reg,
	   addnsub3_round_pipe_clk,
		addnsub3_round_pipe_en,
		addnsub3_round_signal_reg,
		1'b0,
		addnsub3_round_pipe_clr
	);
assign addnsub3_round_pipe_signal_reg = addnsub3_round_pipe_in_reg;

end
else
assign addnsub3_round_pipe_signal_reg = addnsub3_round_signal_reg;
endgenerate

generate
if (output_rounding=="VARIABLE" && 
	output_round_register != "UNREGISTERED")
begin

	dffep out_round_ff (
		out_round_reg,
	   out_round_clk,
		out_round_ena,
		output_round,
		1'b0,
		out_round_clr
		);

end
else
	assign out_round_reg = output_round;
endgenerate

generate
if (output_rounding=="VARIABLE" && 
	output_round_pipeline_register != "UNREGISTERED")
begin

	dffep out_round_pipe_ff (
		out_round_pipe,
	   out_round_pipe_clk,
		out_round_pipe_ena,
		out_round_reg,
		1'b0,
		out_round_pipe_clr
		);

end
else
	assign out_round_pipe = out_round_reg;
endgenerate

generate
if (output_saturation=="VARIABLE" && 
	output_saturate_register != "UNREGISTERED")
begin

	dffep out_sat_ff (
		out_sat_reg,
	   out_sat_clk,
		out_sat_ena,
		output_saturate,
		1'b0,
		out_sat_clr
		);

end
else
	assign out_sat_reg = output_saturate;
endgenerate

generate
if (output_saturation=="VARIABLE" && 
	output_saturate_pipeline_register != "UNREGISTERED")
begin

	dffep out_sat_pipe_ff (
		out_sat_pipe,
	   out_sat_pipe_clk,
		out_sat_pipe_ena,
		out_sat_reg,
		1'b0,
		out_sat_pipe_clr
		);

end
else
	assign out_sat_pipe = out_sat_reg;
endgenerate

generate
if (zero_chainout_output_register != "UNREGISTERED")
begin

	dffep zero_chain_ff (
		zero_chain_reg,
	   zero_chain_clk,
		zero_chain_ena,
		zero_chainout,
		1'b0,
		zero_chain_clr
		);

end
else
	assign zero_chain_reg = zero_chainout;
endgenerate

// ************** Chainout Block Control  ************ //

generate
if (chainout_rounding == "VARIABLE" &&
	chainout_round_register != "UNREGISTERED")
begin
	dffep chainout_round_ff (
		chain_round_reg,
	   chain_round_clk,
		chain_round_ena,
		chainout_round,
		1'b0,
		chain_round_clr
		);
end
else
	assign chain_round_reg = chainout_round;
endgenerate

generate
if (chainout_rounding == "VARIABLE" &&
	chainout_round_pipeline_register != "UNREGISTERED")
begin
	dffep chainout_round_pipe_ff (
		chain_round_pipe,
	   chain_round_pipe_clk,
		chain_round_pipe_ena,
		chain_round_reg,
		1'b0,
		chain_round_pipe_clr
		);
end
else
	assign chain_round_pipe = chain_round_reg;
endgenerate

generate
if (chainout_rounding == "VARIABLE" &&
	chainout_round_output_register != "UNREGISTERED")
begin
	dffep chainout_round_out_ff (
		chain_round_out,
	   chain_round_out_clk,
		chain_round_out_ena,
		chain_round_pipe,
		1'b0,
		chain_round_out_clr
		);
end
else
	assign chain_round_out = chain_round_pipe;
endgenerate

generate
if (chainout_saturation == "VARIABLE" &&
	chainout_saturate_register != "UNREGISTERED")
begin
	dffep chainout_sat_ff (
		chain_sat_reg,
	   chain_sat_clk,
		chain_sat_ena,
		chainout_saturate,
		1'b0,
		chain_sat_clr
		);
end
else
	assign chain_sat_reg = chainout_saturate;
endgenerate

generate
if (chainout_saturation == "VARIABLE" &&
	chainout_saturate_pipeline_register != "UNREGISTERED")
begin
	dffep chainout_sat_pipe_ff (
		chain_sat_pipe,
	   chain_sat_pipe_clk,
		chain_sat_pipe_ena,
		chain_sat_reg,
		1'b0,
		chain_sat_pipe_clr
		);
end
else
	assign chain_sat_pipe = chain_sat_reg;
endgenerate

generate
if (chainout_saturation == "VARIABLE" &&
	chainout_saturate_output_register != "UNREGISTERED")
begin
	dffep chainout_sat_out_ff (
		chain_sat_out,
	   chain_sat_out_clk,
		chain_sat_out_ena,
		chain_sat_pipe,
		1'b0,
		chain_sat_out_clr
		);
end
else
	assign chain_sat_out = chain_sat_pipe;
endgenerate

// ************** port is saturated outputs ************ //
assign mult0_is_saturated = mult1_sat_reg_out;

assign mult1_is_saturated = mult2_sat_reg_out;

assign mult2_is_saturated = mult3_sat_reg_out;

assign mult3_is_saturated = mult4_sat_reg_out;

generate
if ((port_mult0_is_saturated!="UNUSED") && 
	(output_register != "UNREGISTERED"))
begin

	dffep mult1_sat_ff (
		mult1_sat_reg,
		output_reg_clk,
		output_reg_en,
		mult1_sat_overflow,
		1'b0,
		output_reg_clr
	);
	assign mult1_sat_reg_out = mult1_sat_reg;

end
else if (port_mult0_is_saturated!="UNUSED")
assign mult1_sat_reg_out = mult1_sat_overflow;
else
assign mult1_sat_reg_out = 1'b0;
endgenerate

generate
if ((port_mult1_is_saturated!="UNUSED") &&
	(output_register != "UNREGISTERED"))
begin

	dffep mult2_sat_ff (
		mult2_sat_reg,
		output_reg_clk,
		output_reg_en,
		mult2_sat_overflow,
		1'b0,
		output_reg_clr
	);

assign mult2_sat_reg_out = mult2_sat_reg;
end
else if (port_mult1_is_saturated!="UNUSED")
assign mult2_sat_reg_out = mult2_sat_overflow;
else
assign mult2_sat_reg_out = 1'b0;
endgenerate


generate
if ((port_mult2_is_saturated!="UNUSED") &&
     (output_register != "UNREGISTERED"))
begin

	dffep mult3_sat_ff (
		mult3_sat_reg,
		output_reg_clk,
		output_reg_en,
		mult3_sat_overflow,
		1'b0,
		output_reg_clr
	);

assign mult3_sat_reg_out = mult3_sat_reg;
end
else if (port_mult2_is_saturated!="UNUSED")
assign mult3_sat_reg_out = mult3_sat_overflow;
else
assign mult3_sat_reg_out = 1'b0;
endgenerate

generate
if ((port_mult3_is_saturated!="UNUSED") &&
	(output_register != "UNREGISTERED"))
begin

	dffep mult4_sat_ff (
		mult4_sat_reg,
		output_reg_clk,
		output_reg_en,
		mult4_sat_overflow,
		1'b0,
		output_reg_clr
	);
assign mult4_sat_reg_out = mult4_sat_reg;
end

else if (port_mult3_is_saturated!="UNUSED")
assign mult4_sat_reg_out = mult4_sat_overflow;
else
assign mult4_sat_reg_out = 1'b0;
endgenerate



// ************** Multiplier output ************ //

generate
if ( (! FEATURE_FAMILY_STRATIXIII( intended_device_family )) && (multiplier_register0 != "UNREGISTERED") )
begin

	dffep mult1_dout_ff[ width_a_adjusted + width_b_adjusted - 1 : 0 ] (
		mult1_reg,
		multiplier_reg0_clk,
		multiplier_reg0_en,
		mult1_out,
		1'b0,
		multiplier_reg0_clr 
	);

	assign mult1_reg_out = mult1_reg;
end

else
	assign mult1_reg_out = mult1_out;
endgenerate


generate
if ( (! FEATURE_FAMILY_STRATIXIII( intended_device_family )) && 
	((number_of_multipliers>1) && (multiplier_register1 != "UNREGISTERED")) )
begin

	dffep mult2_dout_ff[ width_a_adjusted + width_b_adjusted - 1 : 0 ] (
		mult2_reg,
		multiplier_reg1_clk,
		multiplier_reg1_en,
		mult2_out,
		1'b0,
		multiplier_reg1_clr
	);

	assign mult2_reg_out = mult2_reg;
end

else
	assign mult2_reg_out = mult2_out;
endgenerate


generate
if ( (! FEATURE_FAMILY_STRATIXIII( intended_device_family )) &&
	((number_of_multipliers>2) && (multiplier_register2 != "UNREGISTERED")) )
begin

	dffep mult3_dout_ff[ width_a_adjusted + width_b_adjusted - 1 : 0 ] (
		mult3_reg,
		multiplier_reg2_clk,
		multiplier_reg2_en,
		mult3_out,
		1'b0,
		multiplier_reg2_clr
	);

	assign mult3_reg_out = mult3_reg;
end

else
	assign mult3_reg_out = mult3_out;
endgenerate


generate
if ( (! FEATURE_FAMILY_STRATIXIII( intended_device_family )) &&
	((number_of_multipliers>3) && (multiplier_register3 != "UNREGISTERED")) )
begin

	dffep mult4_dout_ff[ width_a_adjusted + width_b_adjusted - 1 : 0 ] (
		mult4_reg,
		multiplier_reg3_clk,
		multiplier_reg3_en,
		mult4_out,
		1'b0,
		multiplier_reg3_clr
	);

	assign mult4_reg_out = mult4_reg;
end
else
	assign mult4_reg_out = mult4_out;
endgenerate


// register for output 

generate
	if (output_register != "UNREGISTERED") begin
		dffep add_dout_ff[ width_accumout - 1 : 0 ] (
			add_reg_out, 
			output_reg_clk,
			output_reg_en,
			accum_out_rs,
			1'b0,
			output_reg_clr
		);
		dffep overflow_ff (
			accum_overflow_reg,
			output_reg_clk,
			output_reg_en,
			accum_out_sat,
			1'b0,
			output_reg_clr
		);
	end 
	else begin
		assign add_reg_out = accum_out_rs;
		assign accum_overflow_reg = accum_out_sat ;
	end
endgenerate

generate
	if (output_register != "UNREGISTERED" && extra_latency > 0) begin
	pipeline_internal_fv #(width_accumout, extra_latency) latency_ff (
      .clk(output_reg_clk),
      .ena(output_reg_en) ,
      .clr(output_reg_clr),
      .d(add_reg_out),
      .piped(add_reg_out_late)
	);
	pipeline_internal_fv #(1, extra_latency) of_latency_ff (
      .clk(output_reg_clk),
      .ena(output_reg_en) ,
      .clr(output_reg_clr),
      .d(accum_overflow_reg),
      .piped(accum_overflow_reg_late)
	);
	end
	else begin
		assign add_reg_out_late = add_reg_out;
		assign accum_overflow_reg_late = accum_overflow_reg;
	end
endgenerate

generate
	if (width_result > width_accumout) 
	begin
		if (output_register != "UNREGISTERED") 
			begin 
			dffep sign_extend_ff (
				extend_bit,
				output_reg_clk,
				output_reg_en,
				extend_bit_pre,
				1'b0,
				output_reg_clr
			);
			end
		else 
			begin
				assign extend_bit = extend_bit_pre;
			end

		assign extend_bit_pre = (accum_out_rs[width_accumout-1] == 1)? (
			(signa_pipe | signb_pipe | ((!signa_pipe & !signb_pipe) 
 				& (!addsub1_pipe & !addsub3_pipe)))? accum_out_rs[width_l2addrout - 1] : 
				(( !signa_pipe & !signb_pipe & (!addsub1_pipe ^ !addsub3_pipe))? 
					accum_out_rs[width_accumout - 2] : 1'b0)
				) : 1'b0;
	end

endgenerate

//Chainout block follows the output from output register in Stratix III

generate
	if (chainout_adder != "NO") begin
			addsub_block #(
				.width_a(width_accumout), 
				.width_b(width_chainin),
				.adder_mode("add"),
				.dataa_signed("use_port"),
				.datab_signed("use_port")
			) chainout_adder (
				.dataa( add_reg_out_late ),
				.datab( chainin ),
				.signa( signa_pipe | signb_pipe ),
				.signb( signa_pipe | signb_pipe ),
				.addsub( `ADD ),
				.sum( chainout_out ),
				.sumsign( chainout_signout )
		   );
	end
endgenerate

generate
if (chainout_rounding!="NO" || chainout_saturation!="NO")
begin
	rs_block #(
		.width_sign( width_saturate_sign), 
		.width_total( width_chainout ), 
		.width_msb( width_msb ), 
		.round_type( output_round_type ), 
		.saturate_type (output_saturate_type ),
		.family ( intended_device_family )
	) chainout_rs (
		.round ( chainout_rounding=="YES" || (chainout_rounding=="VARIABLE" && chain_round_out==1'b1) ),
		.saturate ( chainout_saturation=="YES" || ( chainout_saturation=="VARIABLE" && chain_sat_out==1'b1) ),
		.sign( signa_pipe | signb_pipe ),
		.datain( chainout_out ),
		.rs_output( chainout_out_rs ),
		.sat_overflow( chainout_out_sat )
	);
end
else 
begin
	assign chainout_out_rs = chainout_out;
	assign chainout_out_sat = 1'b0;
end
endgenerate

generate
if (chainout_register != "UNREGISTERED")
begin
	dffep chainout_ff [width_chainout-1 : 0] (
		chainout_out_reg,
	   chainout_clk,
		chainout_ena,
		chainout_out_rs,
		1'b0,
		chainout_clr
		);
end
else
	assign chainout_out_reg = chainout_out_rs;
endgenerate

generate
if (port_chainout_sat_is_overflow=="PORT_USED") begin
		assign chainout_sat_overflow = chainout_out_sat;
end
endgenerate

// Shift and Rotate

generate
if (rotate_register != "UNREGISTERED") begin
	dffep rotate_ff (
		rotate_reg,
		rotate_clk,
		rotate_ena,
		shift_right,
		1'b0,
		rotate_clr
	);
end
else
	assign rotate_reg = shift_right;
endgenerate

generate
if (rotate_pipeline_register != "UNREGISTERED") begin
	dffep rotate_pipe_ff (
		rotate_pipe,
		rotate_pipe_clk,
		rotate_pipe_ena,
		rotate_reg,
		1'b0,
		rotate_pipe_clr
	);
end
else
	assign shiftr_pipe = shiftr_reg;
endgenerate

generate
if (rotate_output_register != "UNREGISTERED") begin
	dffep rotate_out_ff (
		rotate_out,
		rotate_out_clk,
		rotate_out_ena,
		rotate_pipe,
		1'b0,
		rotate_out_clr
	);
end
else
	assign rotate_out = shiftr_pipe;
endgenerate

generate
if (shift_right_register != "UNREGISTERED") begin
	dffep shiftr_ff (
		shiftr_reg,
		shiftr_clk,
		shiftr_ena,
		shift_right,
		1'b0,
		shiftr_clr
	);
end
else
	assign shiftr_reg = shift_right;
endgenerate

generate
if (shift_right_pipeline_register != "UNREGISTERED") begin
	dffep shiftr_pipe_ff (
		shiftr_pipe,
		shiftr_pipe_clk,
		shiftr_pipe_ena,
		shiftr_reg,
		1'b0,
		shiftr_pipe_clr
	);
end
else
	assign shiftr_pipe = shiftr_reg;
endgenerate

generate
if (shift_right_output_register != "UNREGISTERED") begin
	dffep shiftr_out_ff (
		shiftr_out,
		shiftr_out_clk,
		shiftr_out_ena,
		shiftr_pipe,
		1'b0,
		shiftr_out_clr
	);
end
else
	assign shiftr_out = shiftr_pipe;
endgenerate


generate 
if (shift_mode != "NO") 
begin
	assign dataout = ( 
		(shift_mode=="LEFT") || 
			(shift_mode=="VARIABLE" && shiftr_out==1'b0 && rotate_out==1'b0) )? add_reg_out_late[ width_a-1 : 0 ] : (
			( (shift_mode=="RIGHT") || (shift_mode=="VARIABLE" && shiftr_out==1'b1 && rotate_out==1'b0) ) ? add_reg_out_late[ 2*width_a-1 : width_a ] : (
			( (shift_mode=="ROTATION") || (shift_mode=="VARIABLE" && shiftr_out==1'b0 && rotate_out==1'b1) ) ? 
			add_reg_out_late[ 2*width_a-1 : width_a] & add_reg_out_late[ width_a-1 : 0 ] : {width_result{1'b0}} ) );
end
else 
	begin
		assign dataout = add_reg_out_late;
	end
endgenerate

// IMPLEMENTATION END
endmodule
// MODEL END
