// Copyright (C) 1991-2011 Altera Corporation
// This simulation model contains highly confidential and
// proprietary information of Altera and is being provided
// in accordance with and subject to the protections of the
// applicable Altera Program License Subscription Agreement
// which governs its use and disclosure. Your use of Altera
// Corporation's design tools, logic functions and other
// software and tools, and its AMPP partner logic functions,
// and any output files any of the foregoing (including device
// programming or simulation files), and any associated
// documentation or information are expressly subject to the
// terms and conditions of the Altera Program License Subscription
// Agreement, Altera MegaCore Function License Agreement, or other
// applicable license agreement, including, without limitation,
// that your use is for the sole purpose of simulating designs for
// use exclusively in logic devices manufactured by Altera and sold
// by Altera or its authorized distributors. Please refer to the
// applicable agreement for further details. Altera products and
// services are protected under numerous U.S. and foreign patents,
// maskwork rights, copyrights and other intellectual property laws.
// Altera assumes no responsibility or liability arising out of the
// application or use of this simulation model.
// Quartus II 11.1 Build 216 11/01/2011
// --------------------------------------------------------------------
// This is auto-generated HSSI Simulation Atom Model Encryption Wrapper
// Module Name : stratixv_atx_pll_wrapper.v
// --------------------------------------------------------------------

`timescale 1 ps/1 ps
module stratixv_atx_pll
#(
  
  parameter enabled_for_reconfig = "false",
  parameter sim_use_fast_model = "true",
  parameter ac_cap = "disable_ac_cap",
  parameter fbclk_sel = "vcoclk",
  parameter lc_cmu_pdb = "false",
  parameter lc_div33_pdb = "false",
  parameter sel_buf14g = "disable_buf14g",
  parameter sel_buf8g = "disable_buf8g",
  parameter vco_over_range_ref = "vco_over_range_off",
  parameter vco_under_range_ref = "vco_under_range_off",
  
	// parameter declaration and default value assignemnt

	parameter avmm_group_channel_index = 0,
	parameter output_clock_frequency = "",
	parameter reference_clock_frequency = "",
	parameter use_default_base_address = "true",
	parameter user_base_address0 = 0,
	parameter user_base_address1 = 0,
	parameter user_base_address2 = 0,
	parameter cp_current_ctrl = 300,
	parameter cp_current_test = "enable_ch_pump_normal",
	parameter cp_hs_levshift_power_supply_setting = 1,
	parameter cp_replica_bias_ctrl = "disable_replica_bias_ctrl",
	parameter cp_rgla_bypass = "false",
	parameter cp_rgla_volt_inc = "boost_30pct",
	parameter l_counter = 1,
	parameter lcpll_atb_select = "atb_disable",
	parameter lcpll_d2a_sel = "volt_1p02v",
	parameter lcpll_hclk_driver_enable = "driver_off",
	parameter lcvco_gear_sel = "high_gear",
	parameter lcvco_sel = "high_freq_14g",
	parameter lpf_ripple_cap_ctrl = "none",
	parameter lpf_rxpll_pfd_bw_ctrl = 2400,
	parameter m_counter = 4,
	parameter ref_clk_div = 1,
	parameter refclk_sel = "refclk",
	parameter vreg1_lcvco_volt_inc = "volt_1p1v",
	parameter vreg1_vccehlow = "normal_operation",
	parameter vreg2_lcpll_volt_sel = "vreg2_volt_1p0v",
	parameter vreg3_lcpll_volt_sel = "vreg3_volt_1p0v"
)
(
  output [1:0] ch0lctestout,
 output [1:0] ch1lctestout,
 output [1:0] ch2lctestout,
//input and output port declaration
	input [ 10:0 ] avmmaddress,
	input [ 1:0 ] avmmbyteen,
	input [ 0:0 ] avmmclk,
	input [ 0:0 ] avmmread,
	input [ 0:0 ] avmmrstn,
	input [ 0:0 ] avmmwrite,
	input [ 15:0 ] avmmwritedata,
	output [ 15:0 ] avmmreaddata,
	output [ 0:0 ] blockselect,
	input [ 31:0 ] ch0rcsrlc,
	input [ 31:0 ] ch1rcsrlc,
	input [ 31:0 ] ch2rcsrlc,
	input [ 0:0 ] cmurstn,
	input [ 0:0 ] cmurstnlpf,
	input [ 0:0 ] extfbclk,
	input [ 0:0 ] iqclklc,
	input [ 0:0 ] pldclklc,
	input [ 0:0 ] pllfbswblc,
	input [ 0:0 ] pllfbswtlc,
	input [ 0:0 ] refclklc,
	output [ 0:0 ] clk010g,
	output [ 0:0 ] clk025g,
	output [ 0:0 ] clk18010g,
	output [ 0:0 ] clk18025g,
	output [ 0:0 ] clk33cmu,
	output [ 0:0 ] clklowcmu,
	output [ 0:0 ] frefcmu,
	output [ 0:0 ] iqclkatt,
	output [ 0:0 ] pfdmodelockcmu,
	output [ 0:0 ] pldclkatt,
	output [ 0:0 ] refclkatt,
	output [ 0:0 ] txpllhclk
); 

	stratixv_atx_pll_encrypted 
	#(
          .enabled_for_reconfig(enabled_for_reconfig),  
          .sim_use_fast_model(sim_use_fast_model),  
	  .ac_cap(ac_cap),
	  .fbclk_sel(fbclk_sel),
	  .lc_cmu_pdb(lc_cmu_pdb),
	  .lc_div33_pdb(lc_div33_pdb),
	  .sel_buf14g(sel_buf14g),
	  .sel_buf8g(sel_buf8g),
	  .vco_over_range_ref(vco_over_range_ref),
	  .vco_under_range_ref(vco_under_range_ref),

		.avmm_group_channel_index(avmm_group_channel_index),
		.output_clock_frequency(output_clock_frequency),
		.reference_clock_frequency(reference_clock_frequency),
		.use_default_base_address(use_default_base_address),
		.user_base_address0(user_base_address0),
		.user_base_address1(user_base_address1),
		.user_base_address2(user_base_address2),
		.cp_current_ctrl(cp_current_ctrl),
		.cp_current_test(cp_current_test),
		.cp_hs_levshift_power_supply_setting(cp_hs_levshift_power_supply_setting),
		.cp_replica_bias_ctrl(cp_replica_bias_ctrl),
		.cp_rgla_bypass(cp_rgla_bypass),
		.cp_rgla_volt_inc(cp_rgla_volt_inc),
		.l_counter(l_counter),
		.lcpll_atb_select(lcpll_atb_select),
		.lcpll_d2a_sel(lcpll_d2a_sel),
		.lcpll_hclk_driver_enable(lcpll_hclk_driver_enable),
		.lcvco_gear_sel(lcvco_gear_sel),
		.lcvco_sel(lcvco_sel),
		.lpf_ripple_cap_ctrl(lpf_ripple_cap_ctrl),
		.lpf_rxpll_pfd_bw_ctrl(lpf_rxpll_pfd_bw_ctrl),
		.m_counter(m_counter),
		.ref_clk_div(ref_clk_div),
		.refclk_sel(refclk_sel),
		.vreg1_lcvco_volt_inc(vreg1_lcvco_volt_inc),
		.vreg1_vccehlow(vreg1_vccehlow),
		.vreg2_lcpll_volt_sel(vreg2_lcpll_volt_sel),
		.vreg3_lcpll_volt_sel(vreg3_lcpll_volt_sel)

	)
	stratixv_atx_pll_encrypted_inst	(
		.avmmaddress(avmmaddress),
		.avmmbyteen(avmmbyteen),
		.avmmclk(avmmclk),
		.avmmread(avmmread),
		.avmmrstn(avmmrstn),
		.avmmwrite(avmmwrite),
		.avmmwritedata(avmmwritedata),
		.avmmreaddata(avmmreaddata),
		.blockselect(blockselect),
		.ch0rcsrlc(ch0rcsrlc),
		.ch1rcsrlc(ch1rcsrlc),
		.ch2rcsrlc(ch2rcsrlc),
		.cmurstn(cmurstn),
		.cmurstnlpf(cmurstnlpf),
		.extfbclk(extfbclk),
		.iqclklc(iqclklc),
		.pldclklc(pldclklc),
		.pllfbswblc(pllfbswblc),
		.pllfbswtlc(pllfbswtlc),
		.refclklc(refclklc),
		.clk010g(clk010g),
		.clk025g(clk025g),
		.clk18010g(clk18010g),
		.clk18025g(clk18025g),
		.clk33cmu(clk33cmu),
		.clklowcmu(clklowcmu),
		.frefcmu(frefcmu),
		.iqclkatt(iqclkatt),
		.pfdmodelockcmu(pfdmodelockcmu),
		.pldclkatt(pldclkatt),
		.refclkatt(refclkatt),
		.txpllhclk(txpllhclk)
	);


endmodule
// --------------------------------------------------------------------
// This is auto-generated HSSI Simulation Atom Model Encryption Wrapper
// Module Name : ./sim_model_wrappers//stratixv_channel_pll_wrapper.v
// --------------------------------------------------------------------

`timescale 1 ps/1 ps
module stratixv_channel_pll
#(      
        parameter enabled_for_reconfig = "false", 
        parameter sim_use_fast_model = "true",
	// parameter declaration and default value assignemnt
	parameter enable_debug_info = "false",	//Valid values: false|true; this is simulation-only parameter, for debug purpose only

	parameter avmm_group_channel_index = 0,	//Valid values: 0..2
	parameter output_clock_frequency = "",	//Valid values: 
	parameter reference_clock_frequency = "",	//Valid values: 
	parameter use_default_base_address = "true",	//Valid values: false|true
	parameter user_base_address = 0,	//Valid values: 0..2047
	parameter bbpd_salatch_offset_ctrl_clk0 = "offset_0mv",	//Valid values: offset_0mv|offset_delta1_left|offset_delta2_left|offset_delta3_left|offset_delta4_left|offset_delta5_left|offset_delta6_left|offset_delta7_left|offset_delta1_right|offset_delta2_right|offset_delta3_right|offset_delta4_right|offset_delta5_right|offset_delta6_right|offset_delta7_right
	parameter bbpd_salatch_offset_ctrl_clk180 = "offset_0mv",	//Valid values: offset_0mv|offset_delta1_left|offset_delta2_left|offset_delta3_left|offset_delta4_left|offset_delta5_left|offset_delta6_left|offset_delta7_left|offset_delta1_right|offset_delta2_right|offset_delta3_right|offset_delta4_right|offset_delta5_right|offset_delta6_right|offset_delta7_right
	parameter bbpd_salatch_offset_ctrl_clk270 = "offset_0mv",	//Valid values: offset_0mv|offset_delta1_left|offset_delta2_left|offset_delta3_left|offset_delta4_left|offset_delta5_left|offset_delta6_left|offset_delta7_left|offset_delta1_right|offset_delta2_right|offset_delta3_right|offset_delta4_right|offset_delta5_right|offset_delta6_right|offset_delta7_right
	parameter bbpd_salatch_offset_ctrl_clk90 = "offset_0mv",	//Valid values: offset_0mv|offset_delta1_left|offset_delta2_left|offset_delta3_left|offset_delta4_left|offset_delta5_left|offset_delta6_left|offset_delta7_left|offset_delta1_right|offset_delta2_right|offset_delta3_right|offset_delta4_right|offset_delta5_right|offset_delta6_right|offset_delta7_right
	parameter bbpd_salatch_sel = "normal",	//Valid values: testmux|normal
	parameter bypass_cp_rgla = "false",	//Valid values: false|true
	parameter cdr_atb_select = "atb_disable",	//Valid values: atb_disable|atb_sel_1|atb_sel_2|atb_sel_3|atb_sel_4|atb_sel_5|atb_sel_6|atb_sel_7|atb_sel_8|atb_sel_9|atb_sel_10|atb_sel_11|atb_sel_12|atb_sel_13|atb_sel_14
	parameter cgb_clk_enable = "false",	//Valid values: false|true
	parameter charge_pump_current_test = "enable_ch_pump_normal",	//Valid values: enable_ch_pump_normal|enable_ch_pump_curr_test_up|enable_ch_pump_curr_test_down|disable_ch_pump_curr_test
	parameter clklow_fref_to_ppm_div_sel = 1,	//Valid values: 1|2
	parameter clock_monitor = "lpbk_data",	//Valid values: lpbk_clk|lpbk_data
	parameter diag_rev_lpbk = "false",	//Valid values: false|true
	parameter eye_monitor_bbpd_data_ctrl = "cdr_data",	//Valid values: eye_mon_data|eye_mon_data_remote|cdr_data
	parameter fast_lock_mode = "false",	//Valid values: false|true
	parameter fb_sel = "vcoclk",	//Valid values: vcoclk|extclk|fbext_ctrla|fbext_ctrla_inv|fbext_ctrlb|fbext_ctrlb_inv
	parameter gpon_lock2ref_ctrl = "lck2ref",	//Valid values: lck2ref|lck2ref_gpon|lck2ref_gpon_neighbor
	parameter hs_levshift_power_supply_setting = 1,	//Valid values: 0|1|2|3
	parameter ignore_phslock = "false",	//Valid values: false|true
	parameter l_counter_pd_clock_disable = "false",	//Valid values: false|true
	parameter m_counter = "<auto>",	//Valid values: 1|4|5|8|10|12|16|20|25|32|40|50
	parameter pcie_freq_control = "pcie_100mhz",	//Valid values: pcie_100mhz|pcie_125mhz
	parameter pd_charge_pump_current_ctrl = 5,	//Valid values: 5|10|20|30|40
	parameter pd_l_counter = 1,	//Valid values: 1|2|4|8
	parameter pfd_charge_pump_current_ctrl = 20,	//Valid values: 5|10|20|30|40|50|60|80|100|120|160|180|200|240|300|320|400
	parameter pfd_l_counter = 1,	//Valid values: 1|2|4|8
	parameter powerdown = "false",	//Valid values: false|true
	parameter ref_clk_div = "<auto>",	//Valid values: 1|2|4|8
	parameter regulator_volt_inc = "0",	//Valid values: 0|5|10|15|20|25|30|not_used
	parameter replica_bias_ctrl = "true",	//Valid values: false|true
	parameter reverse_serial_lpbk = "false",	//Valid values: false|true
	parameter ripple_cap_ctrl = "none",	//Valid values: reserved_11|reserved_10|plus_2pf|none
	parameter rxpll_pd_bw_ctrl = 300,	//Valid values: 600|300|240|170
	parameter rxpll_pfd_bw_ctrl = 3200,	//Valid values: 1600|3200|6400|9600
	parameter txpll_hclk_driver_enable = "false",	//Valid values: false|true
	parameter vco_overange_ref = "off",	//Valid values: off|ref_1|ref_2|ref_3
	parameter vco_range_ctrl_en = "false"	//Valid values: false|true
)
(
//input and output port declaration
	input [ 10:0 ] avmmaddress,
	input [ 1:0 ] avmmbyteen,
	input [ 0:0 ] avmmclk,
	input [ 0:0 ] avmmread,
	input [ 0:0 ] avmmrstn,
	input [ 0:0 ] avmmwrite,
	input [ 15:0 ] avmmwritedata,
	input [ 0:0 ] clk270beyerm,
	input [ 0:0 ] clk270eye,
	input [ 0:0 ] clk90beyerm,
	input [ 0:0 ] clk90eye,
	input [ 0:0 ] clkindeser,
	input [ 0:0 ] crurstb,
	input [ 0:0 ] deeye,
	input [ 0:0 ] deeyerm,
	input [ 0:0 ] doeye,
	input [ 0:0 ] doeyerm,
	input [ 0:0 ] earlyeios,
	input [ 0:0 ] extclk,
	input [ 0:0 ] extfbctrla,
	input [ 0:0 ] extfbctrlb,
	input [ 0:0 ] gpblck2refb,
	input [ 0:0 ] lpbkpreen,
	input [ 0:0 ] ltd,
	input [ 0:0 ] ltr,
	input [ 0:0 ] occalen,
	input [ 0:0 ] pciel,
	input [ 0:0 ] pciem,
	input [ 1:0 ] pciesw,
	input [ 0:0 ] ppmlock,
	input [ 0:0 ] refclk,
	input [ 0:0 ] rstn,
	input [ 0:0 ] rxp,
	input [ 0:0 ] sd,
	output [ 15:0 ] avmmreaddata,
	output [ 0:0 ] blockselect,
	output [ 0:0 ] ck0pd,
	output [ 0:0 ] ck180pd,
	output [ 0:0 ] ck270pd,
	output [ 0:0 ] ck90pd,
	output [ 0:0 ] clk270bcdr,
	output [ 0:0 ] clk270bdes,
	output [ 0:0 ] clk90bcdr,
	output [ 0:0 ] clk90bdes,
	output [ 0:0 ] clkcdr,
	output [ 0:0 ] clklow,
	output [ 0:0 ] decdr,
	output [ 0:0 ] deven,
	output [ 0:0 ] docdr,
	output [ 0:0 ] dodd,
	output [ 0:0 ] fref,
	output [ 3:0 ] pdof,
	output [ 0:0 ] pfdmodelock,
	output [ 0:0 ] rxlpbdp,
	output [ 0:0 ] rxlpbp,
	output [ 0:0 ] rxplllock,
	output [ 0:0 ] txpllhclk,
	output [ 0:0 ] txrlpbk,
	output [ 0:0 ] vctrloverrange
); 

	stratixv_channel_pll_encrypted 
	#(
                .enabled_for_reconfig(enabled_for_reconfig),
		.enable_debug_info(enable_debug_info),
	        .sim_use_fast_model(sim_use_fast_model),

		.avmm_group_channel_index(avmm_group_channel_index),
		.output_clock_frequency(output_clock_frequency),
		.reference_clock_frequency(reference_clock_frequency),
		.use_default_base_address(use_default_base_address),
		.user_base_address(user_base_address),
		.bbpd_salatch_offset_ctrl_clk0(bbpd_salatch_offset_ctrl_clk0),
		.bbpd_salatch_offset_ctrl_clk180(bbpd_salatch_offset_ctrl_clk180),
		.bbpd_salatch_offset_ctrl_clk270(bbpd_salatch_offset_ctrl_clk270),
		.bbpd_salatch_offset_ctrl_clk90(bbpd_salatch_offset_ctrl_clk90),
		.bbpd_salatch_sel(bbpd_salatch_sel),
		.bypass_cp_rgla(bypass_cp_rgla),
		.cdr_atb_select(cdr_atb_select),
		.cgb_clk_enable(cgb_clk_enable),
		.charge_pump_current_test(charge_pump_current_test),
		.clklow_fref_to_ppm_div_sel(clklow_fref_to_ppm_div_sel),
		.clock_monitor(clock_monitor),
		.diag_rev_lpbk(diag_rev_lpbk),
		.eye_monitor_bbpd_data_ctrl(eye_monitor_bbpd_data_ctrl),
		.fast_lock_mode(fast_lock_mode),
		.fb_sel(fb_sel),
		.gpon_lock2ref_ctrl(gpon_lock2ref_ctrl),
		.hs_levshift_power_supply_setting(hs_levshift_power_supply_setting),
		.ignore_phslock(ignore_phslock),
		.l_counter_pd_clock_disable(l_counter_pd_clock_disable),
		.m_counter(m_counter),
		.pcie_freq_control(pcie_freq_control),
		.pd_charge_pump_current_ctrl(pd_charge_pump_current_ctrl),
		.pd_l_counter(pd_l_counter),
		.pfd_charge_pump_current_ctrl(pfd_charge_pump_current_ctrl),
		.pfd_l_counter(pfd_l_counter),
		.powerdown(powerdown),
		.ref_clk_div(ref_clk_div),
		.regulator_volt_inc(regulator_volt_inc),
		.replica_bias_ctrl(replica_bias_ctrl),
		.reverse_serial_lpbk(reverse_serial_lpbk),
		.ripple_cap_ctrl(ripple_cap_ctrl),
		.rxpll_pd_bw_ctrl(rxpll_pd_bw_ctrl),
		.rxpll_pfd_bw_ctrl(rxpll_pfd_bw_ctrl),
		.txpll_hclk_driver_enable(txpll_hclk_driver_enable),
		.vco_overange_ref(vco_overange_ref),
		.vco_range_ctrl_en(vco_range_ctrl_en)

	)
	stratixv_channel_pll_encrypted_inst	(
		.avmmaddress(avmmaddress),
		.avmmbyteen(avmmbyteen),
		.avmmclk(avmmclk),
		.avmmread(avmmread),
		.avmmrstn(avmmrstn),
		.avmmwrite(avmmwrite),
		.avmmwritedata(avmmwritedata),
		.clk270beyerm(clk270beyerm),
		.clk270eye(clk270eye),
		.clk90beyerm(clk90beyerm),
		.clk90eye(clk90eye),
		.clkindeser(clkindeser),
		.crurstb(crurstb),
		.deeye(deeye),
		.deeyerm(deeyerm),
		.doeye(doeye),
		.doeyerm(doeyerm),
		.earlyeios(earlyeios),
		.extclk(extclk),
		.extfbctrla(extfbctrla),
		.extfbctrlb(extfbctrlb),
		.gpblck2refb(gpblck2refb),
		.lpbkpreen(lpbkpreen),
		.ltd(ltd),
		.ltr(ltr),
		.occalen(occalen),
		.pciel(pciel),
		.pciem(pciem),
		.pciesw(pciesw),
		.ppmlock(ppmlock),
		.refclk(refclk),
		.rstn(rstn),
		.rxp(rxp),
		.sd(sd),
		.avmmreaddata(avmmreaddata),
		.blockselect(blockselect),
		.ck0pd(ck0pd),
		.ck180pd(ck180pd),
		.ck270pd(ck270pd),
		.ck90pd(ck90pd),
		.clk270bcdr(clk270bcdr),
		.clk270bdes(clk270bdes),
		.clk90bcdr(clk90bcdr),
		.clk90bdes(clk90bdes),
		.clkcdr(clkcdr),
		.clklow(clklow),
		.decdr(decdr),
		.deven(deven),
		.docdr(docdr),
		.dodd(dodd),
		.fref(fref),
		.pdof(pdof),
		.pfdmodelock(pfdmodelock),
		.rxlpbdp(rxlpbdp),
		.rxlpbp(rxlpbp),
		.rxplllock(rxplllock),
		.txpllhclk(txpllhclk),
		.txrlpbk(txrlpbk),
		.vctrloverrange(vctrloverrange)
	);


endmodule
// --------------------------------------------------------------------
// This is auto-generated HSSI Simulation Atom Model Encryption Wrapper
// Module Name : ./sim_model_wrappers//stratixv_hssi_8g_pcs_aggregate_wrapper.v
// --------------------------------------------------------------------

`timescale 1 ps/1 ps
module stratixv_hssi_8g_pcs_aggregate
#(
	// parameter declaration and default value assignemnt
	parameter enable_debug_info = "false",	//Valid values: false|true; this is simulation-only parameter, for debug purpose only

	parameter xaui_sm_operation = "en_xaui_sm",	//Valid values: dis_xaui_sm|en_xaui_sm|en_xaui_legacy_sm
	parameter dskw_sm_operation = "dskw_xaui_sm",	//Valid values: dskw_xaui_sm|dskw_srio_sm
	parameter data_agg_bonding = "agg_disable",	//Valid values: agg_disable|x4_cmu1|x4_cmu2|x4_cmu3|x4_lc1|x4_lc2|x4_lc3|x2_cmu1|x2_lc1
	parameter prot_mode_tx = "pipe_g1_tx",	//Valid values: pipe_g1_tx|pipe_g2_tx|pipe_g3_tx|cpri_tx|cpri_rx_tx_tx|gige_tx|xaui_tx|srio_2p1_tx|test_tx|basic_tx|disabled_prot_mode_tx
	parameter pcs_dw_datapath = "sw_data_path",	//Valid values: sw_data_path|dw_data_path
	parameter dskw_control = "dskw_write_control",	//Valid values: dskw_write_control|dskw_read_control
	parameter refclkdig_sel = "dis_refclk_dig_sel",	//Valid values: dis_refclk_dig_sel|en_refclk_dig_sel
	parameter agg_pwdn = "dis_agg_pwdn",	//Valid values: dis_agg_pwdn|en_agg_pwdn
	parameter avmm_group_channel_index = 0,	//Valid values: 0..2
	parameter use_default_base_address = "true",	//Valid values: false|true
	parameter user_base_address = 0,	//Valid values: 0..2047
	parameter [ 3:0 ] dskw_mnumber_data = 4'b100	//Valid values: 4
)
(
//input and output port declaration
	input [ 1:0 ] aligndetsyncbotch2,
	input [ 1:0 ] aligndetsyncch0,
	input [ 1:0 ] aligndetsyncch1,
	input [ 1:0 ] aligndetsyncch2,
	input [ 1:0 ] aligndetsynctopch0,
	input [ 1:0 ] aligndetsynctopch1,
	input [ 0:0 ] alignstatussyncbotch2,
	input [ 0:0 ] alignstatussyncch0,
	input [ 0:0 ] alignstatussyncch1,
	input [ 0:0 ] alignstatussyncch2,
	input [ 0:0 ] alignstatussynctopch0,
	input [ 0:0 ] alignstatussynctopch1,
	input [ 1:0 ] cgcomprddinbotch2,
	input [ 1:0 ] cgcomprddinch0,
	input [ 1:0 ] cgcomprddinch1,
	input [ 1:0 ] cgcomprddinch2,
	input [ 1:0 ] cgcomprddintopch0,
	input [ 1:0 ] cgcomprddintopch1,
	input [ 1:0 ] cgcompwrinbotch2,
	input [ 1:0 ] cgcompwrinch0,
	input [ 1:0 ] cgcompwrinch1,
	input [ 1:0 ] cgcompwrinch2,
	input [ 1:0 ] cgcompwrintopch0,
	input [ 1:0 ] cgcompwrintopch1,
	input [ 0:0 ] decctlbotch2,
	input [ 0:0 ] decctlch0,
	input [ 0:0 ] decctlch1,
	input [ 0:0 ] decctlch2,
	input [ 0:0 ] decctltopch0,
	input [ 0:0 ] decctltopch1,
	input [ 7:0 ] decdatabotch2,
	input [ 7:0 ] decdatach0,
	input [ 7:0 ] decdatach1,
	input [ 7:0 ] decdatach2,
	input [ 7:0 ] decdatatopch0,
	input [ 7:0 ] decdatatopch1,
	input [ 0:0 ] decdatavalidbotch2,
	input [ 0:0 ] decdatavalidch0,
	input [ 0:0 ] decdatavalidch1,
	input [ 0:0 ] decdatavalidch2,
	input [ 0:0 ] decdatavalidtopch0,
	input [ 0:0 ] decdatavalidtopch1,
	input [ 0:0 ] dedicatedaggscaninch1,
	input [ 0:0 ] delcondmetinbotch2,
	input [ 0:0 ] delcondmetinch0,
	input [ 0:0 ] delcondmetinch1,
	input [ 0:0 ] delcondmetinch2,
	input [ 0:0 ] delcondmetintopch0,
	input [ 0:0 ] delcondmetintopch1,
	input [ 63:0 ] dprioagg,
	input [ 0:0 ] fifoovrinbotch2,
	input [ 0:0 ] fifoovrinch0,
	input [ 0:0 ] fifoovrinch1,
	input [ 0:0 ] fifoovrinch2,
	input [ 0:0 ] fifoovrintopch0,
	input [ 0:0 ] fifoovrintopch1,
	input [ 0:0 ] fifordinbotch2,
	input [ 0:0 ] fifordinch0,
	input [ 0:0 ] fifordinch1,
	input [ 0:0 ] fifordinch2,
	input [ 0:0 ] fifordintopch0,
	input [ 0:0 ] fifordintopch1,
	input [ 0:0 ] insertincompleteinbotch2,
	input [ 0:0 ] insertincompleteinch0,
	input [ 0:0 ] insertincompleteinch1,
	input [ 0:0 ] insertincompleteinch2,
	input [ 0:0 ] insertincompleteintopch0,
	input [ 0:0 ] insertincompleteintopch1,
	input [ 0:0 ] latencycompinbotch2,
	input [ 0:0 ] latencycompinch0,
	input [ 0:0 ] latencycompinch1,
	input [ 0:0 ] latencycompinch2,
	input [ 0:0 ] latencycompintopch0,
	input [ 0:0 ] latencycompintopch1,
	input [ 0:0 ] rcvdclkch0,
	input [ 0:0 ] rcvdclkch1,
	input [ 1:0 ] rdalignbotch2,
	input [ 1:0 ] rdalignch0,
	input [ 1:0 ] rdalignch1,
	input [ 1:0 ] rdalignch2,
	input [ 1:0 ] rdaligntopch0,
	input [ 1:0 ] rdaligntopch1,
	input [ 0:0 ] rdenablesyncbotch2,
	input [ 0:0 ] rdenablesyncch0,
	input [ 0:0 ] rdenablesyncch1,
	input [ 0:0 ] rdenablesyncch2,
	input [ 0:0 ] rdenablesynctopch0,
	input [ 0:0 ] rdenablesynctopch1,
	input [ 0:0 ] refclkdig,
	input [ 1:0 ] runningdispbotch2,
	input [ 1:0 ] runningdispch0,
	input [ 1:0 ] runningdispch1,
	input [ 1:0 ] runningdispch2,
	input [ 1:0 ] runningdisptopch0,
	input [ 1:0 ] runningdisptopch1,
	input [ 0:0 ] rxpcsrstn,
	input [ 0:0 ] scanmoden,
	input [ 0:0 ] scanshiftn,
	input [ 0:0 ] syncstatusbotch2,
	input [ 0:0 ] syncstatusch0,
	input [ 0:0 ] syncstatusch1,
	input [ 0:0 ] syncstatusch2,
	input [ 0:0 ] syncstatustopch0,
	input [ 0:0 ] syncstatustopch1,
	input [ 0:0 ] txctltcbotch2,
	input [ 0:0 ] txctltcch0,
	input [ 0:0 ] txctltcch1,
	input [ 0:0 ] txctltcch2,
	input [ 0:0 ] txctltctopch0,
	input [ 0:0 ] txctltctopch1,
	input [ 7:0 ] txdatatcbotch2,
	input [ 7:0 ] txdatatcch0,
	input [ 7:0 ] txdatatcch1,
	input [ 7:0 ] txdatatcch2,
	input [ 7:0 ] txdatatctopch0,
	input [ 7:0 ] txdatatctopch1,
	input [ 0:0 ] txpcsrstn,
	input [ 0:0 ] txpmaclk,
	output [ 15:0 ] aggtestbusch0,
	output [ 15:0 ] aggtestbusch1,
	output [ 15:0 ] aggtestbusch2,
	output [ 0:0 ] alignstatusbotch2,
	output [ 0:0 ] alignstatusch0,
	output [ 0:0 ] alignstatusch1,
	output [ 0:0 ] alignstatusch2,
	output [ 0:0 ] alignstatussync0botch2,
	output [ 0:0 ] alignstatussync0ch0,
	output [ 0:0 ] alignstatussync0ch1,
	output [ 0:0 ] alignstatussync0ch2,
	output [ 0:0 ] alignstatussync0topch0,
	output [ 0:0 ] alignstatussync0topch1,
	output [ 0:0 ] alignstatustopch0,
	output [ 0:0 ] alignstatustopch1,
	output [ 0:0 ] cgcomprddallbotch2,
	output [ 0:0 ] cgcomprddallch0,
	output [ 0:0 ] cgcomprddallch1,
	output [ 0:0 ] cgcomprddallch2,
	output [ 0:0 ] cgcomprddalltopch0,
	output [ 0:0 ] cgcomprddalltopch1,
	output [ 0:0 ] cgcompwrallbotch2,
	output [ 0:0 ] cgcompwrallch0,
	output [ 0:0 ] cgcompwrallch1,
	output [ 0:0 ] cgcompwrallch2,
	output [ 0:0 ] cgcompwralltopch0,
	output [ 0:0 ] cgcompwralltopch1,
	output [ 0:0 ] dedicatedaggscanoutch0tieoff,
	output [ 0:0 ] dedicatedaggscanoutch1,
	output [ 0:0 ] dedicatedaggscanoutch2tieoff,
	output [ 0:0 ] delcondmet0botch2,
	output [ 0:0 ] delcondmet0ch0,
	output [ 0:0 ] delcondmet0ch1,
	output [ 0:0 ] delcondmet0ch2,
	output [ 0:0 ] delcondmet0topch0,
	output [ 0:0 ] delcondmet0topch1,
	output [ 0:0 ] endskwqdbotch2,
	output [ 0:0 ] endskwqdch0,
	output [ 0:0 ] endskwqdch1,
	output [ 0:0 ] endskwqdch2,
	output [ 0:0 ] endskwqdtopch0,
	output [ 0:0 ] endskwqdtopch1,
	output [ 0:0 ] endskwrdptrsbotch2,
	output [ 0:0 ] endskwrdptrsch0,
	output [ 0:0 ] endskwrdptrsch1,
	output [ 0:0 ] endskwrdptrsch2,
	output [ 0:0 ] endskwrdptrstopch0,
	output [ 0:0 ] endskwrdptrstopch1,
	output [ 0:0 ] fifoovr0botch2,
	output [ 0:0 ] fifoovr0ch0,
	output [ 0:0 ] fifoovr0ch1,
	output [ 0:0 ] fifoovr0ch2,
	output [ 0:0 ] fifoovr0topch0,
	output [ 0:0 ] fifoovr0topch1,
	output [ 0:0 ] fifordoutcomp0botch2,
	output [ 0:0 ] fifordoutcomp0ch0,
	output [ 0:0 ] fifordoutcomp0ch1,
	output [ 0:0 ] fifordoutcomp0ch2,
	output [ 0:0 ] fifordoutcomp0topch0,
	output [ 0:0 ] fifordoutcomp0topch1,
	output [ 0:0 ] fiforstrdqdbotch2,
	output [ 0:0 ] fiforstrdqdch0,
	output [ 0:0 ] fiforstrdqdch1,
	output [ 0:0 ] fiforstrdqdch2,
	output [ 0:0 ] fiforstrdqdtopch0,
	output [ 0:0 ] fiforstrdqdtopch1,
	output [ 0:0 ] insertincomplete0botch2,
	output [ 0:0 ] insertincomplete0ch0,
	output [ 0:0 ] insertincomplete0ch1,
	output [ 0:0 ] insertincomplete0ch2,
	output [ 0:0 ] insertincomplete0topch0,
	output [ 0:0 ] insertincomplete0topch1,
	output [ 0:0 ] latencycomp0botch2,
	output [ 0:0 ] latencycomp0ch0,
	output [ 0:0 ] latencycomp0ch1,
	output [ 0:0 ] latencycomp0ch2,
	output [ 0:0 ] latencycomp0topch0,
	output [ 0:0 ] latencycomp0topch1,
	output [ 0:0 ] rcvdclkout,
	output [ 0:0 ] rcvdclkoutbot,
	output [ 0:0 ] rcvdclkouttop,
	output [ 0:0 ] rxctlrsbotch2,
	output [ 0:0 ] rxctlrsch0,
	output [ 0:0 ] rxctlrsch1,
	output [ 0:0 ] rxctlrsch2,
	output [ 0:0 ] rxctlrstopch0,
	output [ 0:0 ] rxctlrstopch1,
	output [ 7:0 ] rxdatarsbotch2,
	output [ 7:0 ] rxdatarsch0,
	output [ 7:0 ] rxdatarsch1,
	output [ 7:0 ] rxdatarsch2,
	output [ 7:0 ] rxdatarstopch0,
	output [ 7:0 ] rxdatarstopch1,
	output [ 0:0 ] txctltsbotch2,
	output [ 0:0 ] txctltsch0,
	output [ 0:0 ] txctltsch1,
	output [ 0:0 ] txctltsch2,
	output [ 0:0 ] txctltstopch0,
	output [ 0:0 ] txctltstopch1,
	output [ 7:0 ] txdatatsbotch2,
	output [ 7:0 ] txdatatsch0,
	output [ 7:0 ] txdatatsch1,
	output [ 7:0 ] txdatatsch2,
	output [ 7:0 ] txdatatstopch0,
	output [ 7:0 ] txdatatstopch1
); 

	stratixv_hssi_8g_pcs_aggregate_encrypted 
	#(
		.enable_debug_info(enable_debug_info),

		.xaui_sm_operation(xaui_sm_operation),
		.dskw_sm_operation(dskw_sm_operation),
		.data_agg_bonding(data_agg_bonding),
		.prot_mode_tx(prot_mode_tx),
		.pcs_dw_datapath(pcs_dw_datapath),
		.dskw_control(dskw_control),
		.refclkdig_sel(refclkdig_sel),
		.agg_pwdn(agg_pwdn),
		.avmm_group_channel_index(avmm_group_channel_index),
		.use_default_base_address(use_default_base_address),
		.user_base_address(user_base_address),
		.dskw_mnumber_data(dskw_mnumber_data)

	)
	stratixv_hssi_8g_pcs_aggregate_encrypted_inst	(
		.aligndetsyncbotch2(aligndetsyncbotch2),
		.aligndetsyncch0(aligndetsyncch0),
		.aligndetsyncch1(aligndetsyncch1),
		.aligndetsyncch2(aligndetsyncch2),
		.aligndetsynctopch0(aligndetsynctopch0),
		.aligndetsynctopch1(aligndetsynctopch1),
		.alignstatussyncbotch2(alignstatussyncbotch2),
		.alignstatussyncch0(alignstatussyncch0),
		.alignstatussyncch1(alignstatussyncch1),
		.alignstatussyncch2(alignstatussyncch2),
		.alignstatussynctopch0(alignstatussynctopch0),
		.alignstatussynctopch1(alignstatussynctopch1),
		.cgcomprddinbotch2(cgcomprddinbotch2),
		.cgcomprddinch0(cgcomprddinch0),
		.cgcomprddinch1(cgcomprddinch1),
		.cgcomprddinch2(cgcomprddinch2),
		.cgcomprddintopch0(cgcomprddintopch0),
		.cgcomprddintopch1(cgcomprddintopch1),
		.cgcompwrinbotch2(cgcompwrinbotch2),
		.cgcompwrinch0(cgcompwrinch0),
		.cgcompwrinch1(cgcompwrinch1),
		.cgcompwrinch2(cgcompwrinch2),
		.cgcompwrintopch0(cgcompwrintopch0),
		.cgcompwrintopch1(cgcompwrintopch1),
		.decctlbotch2(decctlbotch2),
		.decctlch0(decctlch0),
		.decctlch1(decctlch1),
		.decctlch2(decctlch2),
		.decctltopch0(decctltopch0),
		.decctltopch1(decctltopch1),
		.decdatabotch2(decdatabotch2),
		.decdatach0(decdatach0),
		.decdatach1(decdatach1),
		.decdatach2(decdatach2),
		.decdatatopch0(decdatatopch0),
		.decdatatopch1(decdatatopch1),
		.decdatavalidbotch2(decdatavalidbotch2),
		.decdatavalidch0(decdatavalidch0),
		.decdatavalidch1(decdatavalidch1),
		.decdatavalidch2(decdatavalidch2),
		.decdatavalidtopch0(decdatavalidtopch0),
		.decdatavalidtopch1(decdatavalidtopch1),
		.dedicatedaggscaninch1(dedicatedaggscaninch1),
		.delcondmetinbotch2(delcondmetinbotch2),
		.delcondmetinch0(delcondmetinch0),
		.delcondmetinch1(delcondmetinch1),
		.delcondmetinch2(delcondmetinch2),
		.delcondmetintopch0(delcondmetintopch0),
		.delcondmetintopch1(delcondmetintopch1),
		.dprioagg(dprioagg),
		.fifoovrinbotch2(fifoovrinbotch2),
		.fifoovrinch0(fifoovrinch0),
		.fifoovrinch1(fifoovrinch1),
		.fifoovrinch2(fifoovrinch2),
		.fifoovrintopch0(fifoovrintopch0),
		.fifoovrintopch1(fifoovrintopch1),
		.fifordinbotch2(fifordinbotch2),
		.fifordinch0(fifordinch0),
		.fifordinch1(fifordinch1),
		.fifordinch2(fifordinch2),
		.fifordintopch0(fifordintopch0),
		.fifordintopch1(fifordintopch1),
		.insertincompleteinbotch2(insertincompleteinbotch2),
		.insertincompleteinch0(insertincompleteinch0),
		.insertincompleteinch1(insertincompleteinch1),
		.insertincompleteinch2(insertincompleteinch2),
		.insertincompleteintopch0(insertincompleteintopch0),
		.insertincompleteintopch1(insertincompleteintopch1),
		.latencycompinbotch2(latencycompinbotch2),
		.latencycompinch0(latencycompinch0),
		.latencycompinch1(latencycompinch1),
		.latencycompinch2(latencycompinch2),
		.latencycompintopch0(latencycompintopch0),
		.latencycompintopch1(latencycompintopch1),
		.rcvdclkch0(rcvdclkch0),
		.rcvdclkch1(rcvdclkch1),
		.rdalignbotch2(rdalignbotch2),
		.rdalignch0(rdalignch0),
		.rdalignch1(rdalignch1),
		.rdalignch2(rdalignch2),
		.rdaligntopch0(rdaligntopch0),
		.rdaligntopch1(rdaligntopch1),
		.rdenablesyncbotch2(rdenablesyncbotch2),
		.rdenablesyncch0(rdenablesyncch0),
		.rdenablesyncch1(rdenablesyncch1),
		.rdenablesyncch2(rdenablesyncch2),
		.rdenablesynctopch0(rdenablesynctopch0),
		.rdenablesynctopch1(rdenablesynctopch1),
		.refclkdig(refclkdig),
		.runningdispbotch2(runningdispbotch2),
		.runningdispch0(runningdispch0),
		.runningdispch1(runningdispch1),
		.runningdispch2(runningdispch2),
		.runningdisptopch0(runningdisptopch0),
		.runningdisptopch1(runningdisptopch1),
		.rxpcsrstn(rxpcsrstn),
		.scanmoden(scanmoden),
		.scanshiftn(scanshiftn),
		.syncstatusbotch2(syncstatusbotch2),
		.syncstatusch0(syncstatusch0),
		.syncstatusch1(syncstatusch1),
		.syncstatusch2(syncstatusch2),
		.syncstatustopch0(syncstatustopch0),
		.syncstatustopch1(syncstatustopch1),
		.txctltcbotch2(txctltcbotch2),
		.txctltcch0(txctltcch0),
		.txctltcch1(txctltcch1),
		.txctltcch2(txctltcch2),
		.txctltctopch0(txctltctopch0),
		.txctltctopch1(txctltctopch1),
		.txdatatcbotch2(txdatatcbotch2),
		.txdatatcch0(txdatatcch0),
		.txdatatcch1(txdatatcch1),
		.txdatatcch2(txdatatcch2),
		.txdatatctopch0(txdatatctopch0),
		.txdatatctopch1(txdatatctopch1),
		.txpcsrstn(txpcsrstn),
		.txpmaclk(txpmaclk),
		.aggtestbusch0(aggtestbusch0),
		.aggtestbusch1(aggtestbusch1),
		.aggtestbusch2(aggtestbusch2),
		.alignstatusbotch2(alignstatusbotch2),
		.alignstatusch0(alignstatusch0),
		.alignstatusch1(alignstatusch1),
		.alignstatusch2(alignstatusch2),
		.alignstatussync0botch2(alignstatussync0botch2),
		.alignstatussync0ch0(alignstatussync0ch0),
		.alignstatussync0ch1(alignstatussync0ch1),
		.alignstatussync0ch2(alignstatussync0ch2),
		.alignstatussync0topch0(alignstatussync0topch0),
		.alignstatussync0topch1(alignstatussync0topch1),
		.alignstatustopch0(alignstatustopch0),
		.alignstatustopch1(alignstatustopch1),
		.cgcomprddallbotch2(cgcomprddallbotch2),
		.cgcomprddallch0(cgcomprddallch0),
		.cgcomprddallch1(cgcomprddallch1),
		.cgcomprddallch2(cgcomprddallch2),
		.cgcomprddalltopch0(cgcomprddalltopch0),
		.cgcomprddalltopch1(cgcomprddalltopch1),
		.cgcompwrallbotch2(cgcompwrallbotch2),
		.cgcompwrallch0(cgcompwrallch0),
		.cgcompwrallch1(cgcompwrallch1),
		.cgcompwrallch2(cgcompwrallch2),
		.cgcompwralltopch0(cgcompwralltopch0),
		.cgcompwralltopch1(cgcompwralltopch1),
		.dedicatedaggscanoutch0tieoff(dedicatedaggscanoutch0tieoff),
		.dedicatedaggscanoutch1(dedicatedaggscanoutch1),
		.dedicatedaggscanoutch2tieoff(dedicatedaggscanoutch2tieoff),
		.delcondmet0botch2(delcondmet0botch2),
		.delcondmet0ch0(delcondmet0ch0),
		.delcondmet0ch1(delcondmet0ch1),
		.delcondmet0ch2(delcondmet0ch2),
		.delcondmet0topch0(delcondmet0topch0),
		.delcondmet0topch1(delcondmet0topch1),
		.endskwqdbotch2(endskwqdbotch2),
		.endskwqdch0(endskwqdch0),
		.endskwqdch1(endskwqdch1),
		.endskwqdch2(endskwqdch2),
		.endskwqdtopch0(endskwqdtopch0),
		.endskwqdtopch1(endskwqdtopch1),
		.endskwrdptrsbotch2(endskwrdptrsbotch2),
		.endskwrdptrsch0(endskwrdptrsch0),
		.endskwrdptrsch1(endskwrdptrsch1),
		.endskwrdptrsch2(endskwrdptrsch2),
		.endskwrdptrstopch0(endskwrdptrstopch0),
		.endskwrdptrstopch1(endskwrdptrstopch1),
		.fifoovr0botch2(fifoovr0botch2),
		.fifoovr0ch0(fifoovr0ch0),
		.fifoovr0ch1(fifoovr0ch1),
		.fifoovr0ch2(fifoovr0ch2),
		.fifoovr0topch0(fifoovr0topch0),
		.fifoovr0topch1(fifoovr0topch1),
		.fifordoutcomp0botch2(fifordoutcomp0botch2),
		.fifordoutcomp0ch0(fifordoutcomp0ch0),
		.fifordoutcomp0ch1(fifordoutcomp0ch1),
		.fifordoutcomp0ch2(fifordoutcomp0ch2),
		.fifordoutcomp0topch0(fifordoutcomp0topch0),
		.fifordoutcomp0topch1(fifordoutcomp0topch1),
		.fiforstrdqdbotch2(fiforstrdqdbotch2),
		.fiforstrdqdch0(fiforstrdqdch0),
		.fiforstrdqdch1(fiforstrdqdch1),
		.fiforstrdqdch2(fiforstrdqdch2),
		.fiforstrdqdtopch0(fiforstrdqdtopch0),
		.fiforstrdqdtopch1(fiforstrdqdtopch1),
		.insertincomplete0botch2(insertincomplete0botch2),
		.insertincomplete0ch0(insertincomplete0ch0),
		.insertincomplete0ch1(insertincomplete0ch1),
		.insertincomplete0ch2(insertincomplete0ch2),
		.insertincomplete0topch0(insertincomplete0topch0),
		.insertincomplete0topch1(insertincomplete0topch1),
		.latencycomp0botch2(latencycomp0botch2),
		.latencycomp0ch0(latencycomp0ch0),
		.latencycomp0ch1(latencycomp0ch1),
		.latencycomp0ch2(latencycomp0ch2),
		.latencycomp0topch0(latencycomp0topch0),
		.latencycomp0topch1(latencycomp0topch1),
		.rcvdclkout(rcvdclkout),
		.rcvdclkoutbot(rcvdclkoutbot),
		.rcvdclkouttop(rcvdclkouttop),
		.rxctlrsbotch2(rxctlrsbotch2),
		.rxctlrsch0(rxctlrsch0),
		.rxctlrsch1(rxctlrsch1),
		.rxctlrsch2(rxctlrsch2),
		.rxctlrstopch0(rxctlrstopch0),
		.rxctlrstopch1(rxctlrstopch1),
		.rxdatarsbotch2(rxdatarsbotch2),
		.rxdatarsch0(rxdatarsch0),
		.rxdatarsch1(rxdatarsch1),
		.rxdatarsch2(rxdatarsch2),
		.rxdatarstopch0(rxdatarstopch0),
		.rxdatarstopch1(rxdatarstopch1),
		.txctltsbotch2(txctltsbotch2),
		.txctltsch0(txctltsch0),
		.txctltsch1(txctltsch1),
		.txctltsch2(txctltsch2),
		.txctltstopch0(txctltstopch0),
		.txctltstopch1(txctltstopch1),
		.txdatatsbotch2(txdatatsbotch2),
		.txdatatsch0(txdatatsch0),
		.txdatatsch1(txdatatsch1),
		.txdatatsch2(txdatatsch2),
		.txdatatstopch0(txdatatstopch0),
		.txdatatstopch1(txdatatstopch1)
	);


endmodule
// --------------------------------------------------------------------
// This is auto-generated HSSI Simulation Atom Model Encryption Wrapper
// Module Name : ./sim_model_wrappers//stratixv_hssi_8g_rx_pcs_wrapper.v
// --------------------------------------------------------------------

`timescale 1 ps/1 ps
module stratixv_hssi_8g_rx_pcs
#(
	// parameter declaration and default value assignemnt
	parameter enable_debug_info = "false",	//Valid values: false|true; this is simulation-only parameter, for debug purpose only

	parameter prot_mode = "basic",	//Valid values: pipe_g1|pipe_g2|pipe_g3|cpri|cpri_rx_tx|gige|xaui|srio_2p1|test|basic|disabled_prot_mode
	parameter tx_rx_parallel_loopback = "dis_plpbk",	//Valid values: dis_plpbk|en_plpbk
	parameter pma_dw = "eight_bit",	//Valid values: eight_bit|ten_bit|sixteen_bit|twenty_bit
	parameter pcs_bypass = "dis_pcs_bypass",	//Valid values: dis_pcs_bypass|en_pcs_bypass
	parameter polarity_inversion = "dis_pol_inv",	//Valid values: dis_pol_inv|en_pol_inv
	parameter wa_pd = "wa_pd_10",	//Valid values: dont_care_wa_pd_0|dont_care_wa_pd_1|wa_pd_7|wa_pd_10|wa_pd_20|wa_pd_40|wa_pd_8_sw|wa_pd_8_dw|wa_pd_16_sw|wa_pd_16_dw|wa_pd_32|wa_pd_fixed_7_k28p5|wa_pd_fixed_10_k28p5|wa_pd_fixed_16_a1a2_sw|wa_pd_fixed_16_a1a2_dw|wa_pd_fixed_32_a1a1a2a2|prbs15_fixed_wa_pd_16_sw|prbs15_fixed_wa_pd_16_dw|prbs15_fixed_wa_pd_20_dw|prbs31_fixed_wa_pd_16_sw|prbs31_fixed_wa_pd_16_dw|prbs31_fixed_wa_pd_10_sw|prbs31_fixed_wa_pd_40_dw|prbs8_fixed_wa|prbs10_fixed_wa|prbs7_fixed_wa_pd_16_sw|prbs7_fixed_wa_pd_16_dw|prbs7_fixed_wa_pd_20_dw|prbs23_fixed_wa_pd_16_sw|prbs23_fixed_wa_pd_32_dw|prbs23_fixed_wa_pd_40_dw
	parameter wa_pd_data = 40'b0,	//Valid values: 40
	parameter wa_boundary_lock_ctrl = "bit_slip",	//Valid values: bit_slip|sync_sm|deterministic_latency|auto_align_pld_ctrl
	parameter wa_pld_controlled = "dis_pld_ctrl",	//Valid values: dis_pld_ctrl|pld_ctrl_sw|rising_edge_sensitive_dw|level_sensitive_dw
	parameter wa_sync_sm_ctrl = "gige_sync_sm",	//Valid values: gige_sync_sm|pipe_sync_sm|xaui_sync_sm|srio1p3_sync_sm|srio2p1_sync_sm|sw_basic_sync_sm|dw_basic_sync_sm|fibre_channel_sync_sm
	parameter wa_rknumber_data = 8'b0,	//Valid values: 8
	parameter wa_renumber_data = 6'b0,	//Valid values: 6
	parameter wa_rgnumber_data = 8'b0,	//Valid values: 8
	parameter wa_rosnumber_data = 2'b0,	//Valid values: 2
	parameter wa_kchar = "dis_kchar",	//Valid values: dis_kchar|en_kchar
	parameter wa_det_latency_sync_status_beh = "assert_sync_status_non_imm",	//Valid values: assert_sync_status_imm|assert_sync_status_non_imm|dont_care_assert_sync
	parameter wa_clk_slip_spacing = "min_clk_slip_spacing",	//Valid values: min_clk_slip_spacing|user_programmable_clk_slip_spacing
	parameter wa_clk_slip_spacing_data = 10'b10000,	//Valid values: 10
	parameter bit_reversal = "dis_bit_reversal",	//Valid values: dis_bit_reversal|en_bit_reversal
	parameter symbol_swap = "dis_symbol_swap",	//Valid values: dis_symbol_swap|en_symbol_swap
	parameter deskew_pattern = 10'b1101101000,	//Valid values: 10
	parameter deskew_prog_pattern_only = "en_deskew_prog_pat_only",	//Valid values: dis_deskew_prog_pat_only|en_deskew_prog_pat_only
	parameter rate_match = "dis_rm",	//Valid values: dis_rm|xaui_rm|gige_rm|pipe_rm|pipe_rm_0ppm|sw_basic_rm|srio_v2p1_rm|srio_v2p1_rm_0ppm|dw_basic_rm
	parameter eightb_tenb_decoder = "dis_8b10b",	//Valid values: dis_8b10b|en_8b10b_ibm|en_8b10b_sgx
	parameter err_flags_sel = "err_flags_wa",	//Valid values: err_flags_wa|err_flags_8b10b
	parameter polinv_8b10b_dec = "dis_polinv_8b10b_dec",	//Valid values: dis_polinv_8b10b_dec|en_polinv_8b10b_dec
	parameter eightbtenb_decoder_output_sel = "data_8b10b_decoder",	//Valid values: data_8b10b_decoder|data_xaui_sm
	parameter invalid_code_flag_only = "dis_invalid_code_only",	//Valid values: dis_invalid_code_only|en_invalid_code_only
	parameter auto_error_replacement = "dis_err_replace",	//Valid values: dis_err_replace|en_err_replace
	parameter pad_or_edb_error_replace = "replace_edb",	//Valid values: replace_edb|replace_pad|replace_edb_dynamic
	parameter byte_deserializer = "dis_bds",	//Valid values: dis_bds|en_bds_by_2|en_bds_by_4|en_bds_by_2_det
	parameter byte_order = "dis_bo",	//Valid values: dis_bo|en_pcs_ctrl_eight_bit_bo|en_pcs_ctrl_nine_bit_bo|en_pcs_ctrl_ten_bit_bo|en_pld_ctrl_eight_bit_bo|en_pld_ctrl_nine_bit_bo|en_pld_ctrl_ten_bit_bo
	parameter re_bo_on_wa = "dis_re_bo_on_wa",	//Valid values: dis_re_bo_on_wa|en_re_bo_on_wa
	parameter bo_pattern = 20'b0,	//Valid values: 20
	parameter bo_pad = 10'b0,	//Valid values: 10
	parameter phase_compensation_fifo = "low_latency",	//Valid values: low_latency|normal_latency|register_fifo|pld_ctrl_low_latency|pld_ctrl_normal_latency
	parameter prbs_ver = "dis_prbs",	//Valid values: dis_prbs|prbs_7_sw|prbs_7_dw|prbs_8|prbs_10|prbs_23_sw|prbs_23_dw|prbs_15|prbs_31|prbs_hf_sw|prbs_hf_dw|prbs_lf_sw|prbs_lf_dw|prbs_mf_sw|prbs_mf_dw
	parameter cid_pattern = "cid_pattern_0",	//Valid values: cid_pattern_0|cid_pattern_1
	parameter cid_pattern_len = 8'b0,	//Valid values: 8
	parameter bist_ver = "dis_bist",	//Valid values: dis_bist|incremental|cjpat|crpat
	parameter cdr_ctrl = "dis_cdr_ctrl",	//Valid values: dis_cdr_ctrl|en_cdr_ctrl|en_cdr_ctrl_w_cid
	parameter cdr_ctrl_rxvalid_mask = "dis_rxvalid_mask",	//Valid values: dis_rxvalid_mask|en_rxvalid_mask
	parameter wait_cnt = 8'b0,	//Valid values: 8
	parameter mask_cnt = 10'h3ff,	//Valid values: 10
	parameter auto_deassert_pc_rst_cnt_data = 5'b0,	//Valid values: 5
	parameter auto_pc_en_cnt_data = 7'b0,	//Valid values: 7
	parameter eidle_entry_sd = "dis_eidle_sd",	//Valid values: dis_eidle_sd|en_eidle_sd
	parameter eidle_entry_eios = "dis_eidle_eios",	//Valid values: dis_eidle_eios|en_eidle_eios
	parameter eidle_entry_iei = "dis_eidle_iei",	//Valid values: dis_eidle_iei|en_eidle_iei
	parameter rx_rcvd_clk = "rcvd_clk_rcvd_clk",	//Valid values: rcvd_clk_rcvd_clk|tx_pma_clock_rcvd_clk
	parameter rx_clk1 = "rcvd_clk_clk1",	//Valid values: rcvd_clk_clk1|tx_pma_clock_clk1|rcvd_clk_agg_clk1|rcvd_clk_agg_top_or_bottom_clk1
	parameter rx_clk2 = "rcvd_clk_clk2",	//Valid values: rcvd_clk_clk2|tx_pma_clock_clk2|refclk_dig2_clk2
	parameter rx_rd_clk = "pld_rx_clk",	//Valid values: pld_rx_clk|rx_clk
	parameter dw_one_or_two_symbol_bo = "donot_care_one_two_bo",	//Valid values: donot_care_one_two_bo|one_symbol_bo|two_symbol_bo_eight_bit|two_symbol_bo_nine_bit|two_symbol_bo_ten_bit
	parameter comp_fifo_rst_pld_ctrl = "dis_comp_fifo_rst_pld_ctrl",	//Valid values: dis_comp_fifo_rst_pld_ctrl|en_comp_fifo_rst_pld_ctrl
	parameter bypass_pipeline_reg = "dis_bypass_pipeline",	//Valid values: dis_bypass_pipeline|en_bypass_pipeline
	parameter agg_block_sel = "same_smrt_pack",	//Valid values: same_smrt_pack|other_smrt_pack
	parameter test_bus_sel = "prbs_bist_testbus",	//Valid values: prbs_bist_testbus|tx_testbus|tx_ctrl_plane_testbus|wa_testbus|deskew_testbus|rm_testbus|rx_ctrl_testbus|pcie_ctrl_testbus|rx_ctrl_plane_testbus|agg_testbus
	parameter wa_rvnumber_data = 13'b0,	//Valid values: 13
	parameter ctrl_plane_bonding_compensation = "dis_compensation",	//Valid values: dis_compensation|en_compensation
	parameter prbs_ver_clr_flag = "dis_prbs_clr_flag",	//Valid values: dis_prbs_clr_flag|en_prbs_clr_flag
	parameter hip_mode = "dis_hip",	//Valid values: dis_hip|en_hip
	parameter ctrl_plane_bonding_distribution = "not_master_chnl_distr",	//Valid values: master_chnl_distr|not_master_chnl_distr
	parameter ctrl_plane_bonding_consumption = "individual",	//Valid values: individual|bundled_master|bundled_slave_below|bundled_slave_above
	parameter pma_done_count = 18'b0,	//Valid values: 18
	parameter test_mode = "prbs",	//Valid values: dont_care_test|prbs|bist
	parameter bist_ver_clr_flag = "dis_bist_clr_flag",	//Valid values: dis_bist_clr_flag|en_bist_clr_flag
	parameter wa_disp_err_flag = "dis_disp_err_flag",	//Valid values: dis_disp_err_flag|en_disp_err_flag
	parameter wait_for_phfifo_cnt_data = 6'b0,	//Valid values: 6
	parameter runlength_check = "en_runlength_sw",	//Valid values: dis_runlength|en_runlength_sw|en_runlength_dw
	parameter runlength_val = 6'b0,	//Valid values: 6
	parameter force_signal_detect = "en_force_signal_detect",	//Valid values: en_force_signal_detect|dis_force_signal_detect
	parameter deskew = "dis_deskew",	//Valid values: dis_deskew|en_srio_v2p1|en_xaui
	parameter rx_wr_clk = "rx_clk2_div_1_2_4",	//Valid values: rx_clk2_div_1_2_4|txfifo_rd_clk
	parameter rx_clk_free_running = "en_rx_clk_free_run",	//Valid values: dis_rx_clk_free_run|en_rx_clk_free_run
	parameter rx_pcs_urst = "en_rx_pcs_urst",	//Valid values: dis_rx_pcs_urst|en_rx_pcs_urst
	parameter pipe_if_enable = "dis_pipe_rx",	//Valid values: dis_pipe_rx|en_pipe_rx|en_pipe3_rx
	parameter pc_fifo_rst_pld_ctrl = "dis_pc_fifo_rst_pld_ctrl",	//Valid values: dis_pc_fifo_rst_pld_ctrl|en_pc_fifo_rst_pld_ctrl
	parameter ibm_invalid_code = "dis_ibm_invalid_code",	//Valid values: dis_ibm_invalid_code|en_ibm_invalid_code
	parameter channel_number = 0,	//Valid values: 0..65
	parameter rx_refclk = "dis_refclk_sel",	//Valid values: dis_refclk_sel|en_refclk_sel
	parameter clock_gate_dw_rm_wr = "dis_dw_rm_wrclk_gating",	//Valid values: dis_dw_rm_wrclk_gating|en_dw_rm_wrclk_gating
	parameter clock_gate_bds_dec_asn = "dis_bds_dec_asn_clk_gating",	//Valid values: dis_bds_dec_asn_clk_gating|en_bds_dec_asn_clk_gating
	parameter fixed_pat_det = "dis_fixed_patdet",	//Valid values: dis_fixed_patdet|en_fixed_patdet
	parameter clock_gate_bist = "dis_bist_clk_gating",	//Valid values: dis_bist_clk_gating|en_bist_clk_gating
	parameter clock_gate_cdr_eidle = "dis_cdr_eidle_clk_gating",	//Valid values: dis_cdr_eidle_clk_gating|en_cdr_eidle_clk_gating
	parameter clkcmp_pattern_p = 20'b0,	//Valid values: 20
	parameter clkcmp_pattern_n = 20'b0,	//Valid values: 20
	parameter clock_gate_prbs = "dis_prbs_clk_gating",	//Valid values: dis_prbs_clk_gating|en_prbs_clk_gating
	parameter clock_gate_pc_rdclk = "dis_pc_rdclk_gating",	//Valid values: dis_pc_rdclk_gating|en_pc_rdclk_gating
	parameter wa_pd_polarity = "dis_pd_both_pol",	//Valid values: dis_pd_both_pol|en_pd_both_pol|dont_care_both_pol
	parameter clock_gate_dskw_rd = "dis_dskw_rdclk_gating",	//Valid values: dis_dskw_rdclk_gating|en_dskw_rdclk_gating
	parameter clock_gate_byteorder = "dis_byteorder_clk_gating",	//Valid values: dis_byteorder_clk_gating|en_byteorder_clk_gating
	parameter clock_gate_dw_pc_wrclk = "dis_dw_pc_wrclk_gating",	//Valid values: dis_dw_pc_wrclk_gating|en_dw_pc_wrclk_gating
	parameter sup_mode = "user_mode",	//Valid values: user_mode|engineering_mode
	parameter clock_gate_sw_wa = "dis_sw_wa_clk_gating",	//Valid values: dis_sw_wa_clk_gating|en_sw_wa_clk_gating
	parameter clock_gate_dw_dskw_wr = "dis_dw_dskw_wrclk_gating",	//Valid values: dis_dw_dskw_wrclk_gating|en_dw_dskw_wrclk_gating
	parameter clock_gate_sw_pc_wrclk = "dis_sw_pc_wrclk_gating",	//Valid values: dis_sw_pc_wrclk_gating|en_sw_pc_wrclk_gating
	parameter clock_gate_sw_rm_rd = "dis_sw_rm_rdclk_gating",	//Valid values: dis_sw_rm_rdclk_gating|en_sw_rm_rdclk_gating
	parameter clock_gate_sw_rm_wr = "dis_sw_rm_wrclk_gating",	//Valid values: dis_sw_rm_wrclk_gating|en_sw_rm_wrclk_gating
	parameter auto_speed_nego = "dis_asn",	//Valid values: dis_asn|en_asn_g2_freq_scal|en_asn_g3
	parameter fixed_pat_num = 4'b1111,	//Valid values: 4
	parameter clock_gate_sw_dskw_wr = "dis_sw_dskw_wrclk_gating",	//Valid values: dis_sw_dskw_wrclk_gating|en_sw_dskw_wrclk_gating
	parameter clock_gate_dw_rm_rd = "dis_dw_rm_rdclk_gating",	//Valid values: dis_dw_rm_rdclk_gating|en_dw_rm_rdclk_gating
	parameter clock_gate_dw_wa = "dis_dw_wa_clk_gating",	//Valid values: dis_dw_wa_clk_gating|en_dw_wa_clk_gating
	parameter avmm_group_channel_index = 0,	//Valid values: 0..2
	parameter use_default_base_address = "true",	//Valid values: false|true
	parameter user_base_address = 0	//Valid values: 0..2047
)
(
//input and output port declaration
	input [ 0:0 ] a1a2size,
	input [ 15:0 ] aggtestbus,
	input [ 0:0 ] alignstatus,
	input [ 0:0 ] alignstatussync0,
	input [ 0:0 ] alignstatussync0toporbot,
	input [ 0:0 ] alignstatustoporbot,
	input [ 10:0 ] avmmaddress,
	input [ 1:0 ] avmmbyteen,
	input [ 0:0 ] avmmclk,
	input [ 0:0 ] avmmread,
	input [ 0:0 ] avmmrstn,
	input [ 0:0 ] avmmwrite,
	input [ 15:0 ] avmmwritedata,
	input [ 0:0 ] bitreversalenable,
	input [ 0:0 ] bitslip,
	input [ 0:0 ] byteorder,
	input [ 0:0 ] bytereversalenable,
	input [ 0:0 ] cgcomprddall,
	input [ 0:0 ] cgcomprddalltoporbot,
	input [ 0:0 ] cgcompwrall,
	input [ 0:0 ] cgcompwralltoporbot,
	input [ 0:0 ] configselinchnldown,
	input [ 0:0 ] configselinchnlup,
	input [ 0:0 ] ctrlfromaggblock,
	input [ 7:0 ] datafrinaggblock,
	input [ 19:0 ] datain,
	input [ 0:0 ] delcondmet0,
	input [ 0:0 ] delcondmet0toporbot,
	input [ 0:0 ] dispcbytegen3,
	input [ 0:0 ] dynclkswitchn,
	input [ 2:0 ] eidleinfersel,
	input [ 0:0 ] enablecommadetect,
	input [ 0:0 ] endskwqd,
	input [ 0:0 ] endskwqdtoporbot,
	input [ 0:0 ] endskwrdptrs,
	input [ 0:0 ] endskwrdptrstoporbot,
	input [ 0:0 ] fifoovr0,
	input [ 0:0 ] fifoovr0toporbot,
	input [ 0:0 ] fifordincomp0toporbot,
	input [ 0:0 ] fiforstrdqd,
	input [ 0:0 ] fiforstrdqdtoporbot,
	input [ 0:0 ] gen2ngen1,
	input [ 0:0 ] hrdrst,
	input [ 0:0 ] insertincomplete0,
	input [ 0:0 ] insertincomplete0toporbot,
	input [ 0:0 ] latencycomp0,
	input [ 0:0 ] latencycomp0toporbot,
	input [ 19:0 ] parallelloopback,
	input [ 0:0 ] pcfifordenable,
	input [ 0:0 ] pcieswitchgen3,
	input [ 0:0 ] phfifouserrst,
	input [ 0:0 ] phystatusinternal,
	input [ 0:0 ] phystatuspcsgen3,
	input [ 0:0 ] pipeloopbk,
	input [ 0:0 ] pldltr,
	input [ 0:0 ] pldrxclk,
	input [ 0:0 ] polinvrx,
	input [ 0:0 ] prbscidenable,
	input [ 0:0 ] pxfifowrdisable,
	input [ 0:0 ] rateswitchcontrol,
	input [ 0:0 ] rcvdclkagg,
	input [ 0:0 ] rcvdclkaggtoporbot,
	input [ 0:0 ] rcvdclkpma,
	input [ 0:0 ] rdenableinchnldown,
	input [ 0:0 ] rdenableinchnlup,
	input [ 0:0 ] refclkdig,
	input [ 0:0 ] refclkdig2,
	input [ 0:0 ] resetpcptrsgen3,
	input [ 0:0 ] resetpcptrsinchnldown,
	input [ 0:0 ] resetpcptrsinchnlup,
	input [ 0:0 ] resetppmcntrsgen3,
	input [ 0:0 ] resetppmcntrsinchnldown,
	input [ 0:0 ] resetppmcntrsinchnlup,
	input [ 0:0 ] rmfifordincomp0,
	input [ 0:0 ] rmfiforeadenable,
	input [ 0:0 ] rmfifouserrst,
	input [ 0:0 ] rmfifowriteenable,
	input [ 3:0 ] rxblkstartpcsgen3,
	input [ 0:0 ] rxcontrolrstoporbot,
	input [ 63:0 ] rxdatapcsgen3,
	input [ 7:0 ] rxdatarstoporbot,
	input [ 3:0 ] rxdatavalidpcsgen3,
	input [ 1:0 ] rxdivsyncinchnldown,
	input [ 1:0 ] rxdivsyncinchnlup,
	input [ 0:0 ] rxpcsrst,
	input [ 2:0 ] rxstatusinternal,
	input [ 2:0 ] rxstatuspcsgen3,
	input [ 1:0 ] rxsynchdrpcsgen3,
	input [ 0:0 ] rxvalidinternal,
	input [ 0:0 ] rxvalidpcsgen3,
	input [ 1:0 ] rxweinchnldown,
	input [ 1:0 ] rxweinchnlup,
	input [ 0:0 ] scanmode,
	input [ 0:0 ] sigdetfrompma,
	input [ 0:0 ] speedchangeinchnldown,
	input [ 0:0 ] speedchangeinchnlup,
	input [ 0:0 ] syncsmen,
	input [ 19:0 ] txctrlplanetestbus,
	input [ 1:0 ] txdivsync,
	input [ 0:0 ] txpmaclk,
	input [ 19:0 ] txtestbus,
	input [ 0:0 ] wrenableinchnldown,
	input [ 0:0 ] wrenableinchnlup,
	output [ 3:0 ] a1a2k1k2flag,
	output [ 0:0 ] aggrxpcsrst,
	output [ 1:0 ] aligndetsync,
	output [ 0:0 ] alignstatuspld,
	output [ 0:0 ] alignstatussync,
	output [ 15:0 ] avmmreaddata,
	output [ 0:0 ] bistdone,
	output [ 0:0 ] bisterr,
	output [ 0:0 ] blockselect,
	output [ 0:0 ] byteordflag,
	output [ 1:0 ] cgcomprddout,
	output [ 1:0 ] cgcompwrout,
	output [ 19:0 ] channeltestbusout,
	output [ 0:0 ] clocktopld,
	output [ 0:0 ] configseloutchnldown,
	output [ 0:0 ] configseloutchnlup,
	output [ 63:0 ] dataout,
	output [ 0:0 ] decoderctrl,
	output [ 7:0 ] decoderdata,
	output [ 0:0 ] decoderdatavalid,
	output [ 0:0 ] delcondmetout,
	output [ 0:0 ] disablepcfifobyteserdes,
	output [ 0:0 ] earlyeios,
	output [ 0:0 ] eidledetected,
	output [ 0:0 ] eidleexit,
	output [ 1:0 ] errctrl,
	output [ 15:0 ] errdata,
	output [ 0:0 ] fifoovrout,
	output [ 0:0 ] fifordoutcomp,
	output [ 0:0 ] insertincompleteout,
	output [ 0:0 ] latencycompout,
	output [ 0:0 ] ltr,
	output [ 0:0 ] observablebyteserdesclock,
	output [ 19:0 ] parallelrevloopback,
	output [ 0:0 ] pcfifoempty,
	output [ 0:0 ] pcfifofull,
	output [ 0:0 ] pcieswitch,
	output [ 0:0 ] phystatus,
	output [ 63:0 ] pipedata,
	output [ 0:0 ] prbsdone,
	output [ 0:0 ] prbserrlt,
	output [ 1:0 ] rdalign,
	output [ 0:0 ] rdenableoutchnldown,
	output [ 0:0 ] rdenableoutchnlup,
	output [ 0:0 ] resetpcptrs,
	output [ 0:0 ] resetpcptrsinchnldownpipe,
	output [ 0:0 ] resetpcptrsinchnluppipe,
	output [ 0:0 ] resetpcptrsoutchnldown,
	output [ 0:0 ] resetpcptrsoutchnlup,
	output [ 0:0 ] resetppmcntrsoutchnldown,
	output [ 0:0 ] resetppmcntrsoutchnlup,
	output [ 0:0 ] resetppmcntrspcspma,
	output [ 0:0 ] rlvlt,
	output [ 0:0 ] rmfifoempty,
	output [ 0:0 ] rmfifofull,
	output [ 0:0 ] rmfifopartialempty,
	output [ 0:0 ] rmfifopartialfull,
	output [ 0:0 ] runlengthviolation,
	output [ 1:0 ] runningdisparity,
	output [ 3:0 ] rxblkstart,
	output [ 0:0 ] rxclkoutgen3,
	output [ 0:0 ] rxclkslip,
	output [ 3:0 ] rxdatavalid,
	output [ 1:0 ] rxdivsyncoutchnldown,
	output [ 1:0 ] rxdivsyncoutchnlup,
	output [ 0:0 ] rxpipeclk,
	output [ 0:0 ] rxpipesoftreset,
	output [ 2:0 ] rxstatus,
	output [ 1:0 ] rxsynchdr,
	output [ 0:0 ] rxvalid,
	output [ 1:0 ] rxweoutchnldown,
	output [ 1:0 ] rxweoutchnlup,
	output [ 0:0 ] selftestdone,
	output [ 0:0 ] selftesterr,
	output [ 0:0 ] signaldetectout,
	output [ 0:0 ] speedchange,
	output [ 0:0 ] speedchangeinchnldownpipe,
	output [ 0:0 ] speedchangeinchnluppipe,
	output [ 0:0 ] speedchangeoutchnldown,
	output [ 0:0 ] speedchangeoutchnlup,
	output [ 0:0 ] syncdatain,
	output [ 0:0 ] syncstatus,
	output [ 4:0 ] wordalignboundary,
	output [ 0:0 ] wrenableoutchnldown,
	output [ 0:0 ] wrenableoutchnlup
); 

	stratixv_hssi_8g_rx_pcs_encrypted 
	#(
		.enable_debug_info(enable_debug_info),

		.prot_mode(prot_mode),
		.tx_rx_parallel_loopback(tx_rx_parallel_loopback),
		.pma_dw(pma_dw),
		.pcs_bypass(pcs_bypass),
		.polarity_inversion(polarity_inversion),
		.wa_pd(wa_pd),
		.wa_pd_data(wa_pd_data),
		.wa_boundary_lock_ctrl(wa_boundary_lock_ctrl),
		.wa_pld_controlled(wa_pld_controlled),
		.wa_sync_sm_ctrl(wa_sync_sm_ctrl),
		.wa_rknumber_data(wa_rknumber_data),
		.wa_renumber_data(wa_renumber_data),
		.wa_rgnumber_data(wa_rgnumber_data),
		.wa_rosnumber_data(wa_rosnumber_data),
		.wa_kchar(wa_kchar),
		.wa_det_latency_sync_status_beh(wa_det_latency_sync_status_beh),
		.wa_clk_slip_spacing(wa_clk_slip_spacing),
		.wa_clk_slip_spacing_data(wa_clk_slip_spacing_data),
		.bit_reversal(bit_reversal),
		.symbol_swap(symbol_swap),
		.deskew_pattern(deskew_pattern),
		.deskew_prog_pattern_only(deskew_prog_pattern_only),
		.rate_match(rate_match),
		.eightb_tenb_decoder(eightb_tenb_decoder),
		.err_flags_sel(err_flags_sel),
		.polinv_8b10b_dec(polinv_8b10b_dec),
		.eightbtenb_decoder_output_sel(eightbtenb_decoder_output_sel),
		.invalid_code_flag_only(invalid_code_flag_only),
		.auto_error_replacement(auto_error_replacement),
		.pad_or_edb_error_replace(pad_or_edb_error_replace),
		.byte_deserializer(byte_deserializer),
		.byte_order(byte_order),
		.re_bo_on_wa(re_bo_on_wa),
		.bo_pattern(bo_pattern),
		.bo_pad(bo_pad),
		.phase_compensation_fifo(phase_compensation_fifo),
		.prbs_ver(prbs_ver),
		.cid_pattern(cid_pattern),
		.cid_pattern_len(cid_pattern_len),
		.bist_ver(bist_ver),
		.cdr_ctrl(cdr_ctrl),
		.cdr_ctrl_rxvalid_mask(cdr_ctrl_rxvalid_mask),
		.wait_cnt(wait_cnt),
		.mask_cnt(mask_cnt),
		.auto_deassert_pc_rst_cnt_data(auto_deassert_pc_rst_cnt_data),
		.auto_pc_en_cnt_data(auto_pc_en_cnt_data),
		.eidle_entry_sd(eidle_entry_sd),
		.eidle_entry_eios(eidle_entry_eios),
		.eidle_entry_iei(eidle_entry_iei),
		.rx_rcvd_clk(rx_rcvd_clk),
		.rx_clk1(rx_clk1),
		.rx_clk2(rx_clk2),
		.rx_rd_clk(rx_rd_clk),
		.dw_one_or_two_symbol_bo(dw_one_or_two_symbol_bo),
		.comp_fifo_rst_pld_ctrl(comp_fifo_rst_pld_ctrl),
		.bypass_pipeline_reg(bypass_pipeline_reg),
		.agg_block_sel(agg_block_sel),
		.test_bus_sel(test_bus_sel),
		.wa_rvnumber_data(wa_rvnumber_data),
		.ctrl_plane_bonding_compensation(ctrl_plane_bonding_compensation),
		.prbs_ver_clr_flag(prbs_ver_clr_flag),
		.hip_mode(hip_mode),
		.ctrl_plane_bonding_distribution(ctrl_plane_bonding_distribution),
		.ctrl_plane_bonding_consumption(ctrl_plane_bonding_consumption),
		.pma_done_count(pma_done_count),
		.test_mode(test_mode),
		.bist_ver_clr_flag(bist_ver_clr_flag),
		.wa_disp_err_flag(wa_disp_err_flag),
		.wait_for_phfifo_cnt_data(wait_for_phfifo_cnt_data),
		.runlength_check(runlength_check),
		.runlength_val(runlength_val),
		.force_signal_detect(force_signal_detect),
		.deskew(deskew),
		.rx_wr_clk(rx_wr_clk),
		.rx_clk_free_running(rx_clk_free_running),
		.rx_pcs_urst(rx_pcs_urst),
		.pipe_if_enable(pipe_if_enable),
		.pc_fifo_rst_pld_ctrl(pc_fifo_rst_pld_ctrl),
		.ibm_invalid_code(ibm_invalid_code),
		.channel_number(channel_number),
		.rx_refclk(rx_refclk),
		.clock_gate_dw_rm_wr(clock_gate_dw_rm_wr),
		.clock_gate_bds_dec_asn(clock_gate_bds_dec_asn),
		.fixed_pat_det(fixed_pat_det),
		.clock_gate_bist(clock_gate_bist),
		.clock_gate_cdr_eidle(clock_gate_cdr_eidle),
		.clkcmp_pattern_p(clkcmp_pattern_p),
		.clkcmp_pattern_n(clkcmp_pattern_n),
		.clock_gate_prbs(clock_gate_prbs),
		.clock_gate_pc_rdclk(clock_gate_pc_rdclk),
		.wa_pd_polarity(wa_pd_polarity),
		.clock_gate_dskw_rd(clock_gate_dskw_rd),
		.clock_gate_byteorder(clock_gate_byteorder),
		.clock_gate_dw_pc_wrclk(clock_gate_dw_pc_wrclk),
		.sup_mode(sup_mode),
		.clock_gate_sw_wa(clock_gate_sw_wa),
		.clock_gate_dw_dskw_wr(clock_gate_dw_dskw_wr),
		.clock_gate_sw_pc_wrclk(clock_gate_sw_pc_wrclk),
		.clock_gate_sw_rm_rd(clock_gate_sw_rm_rd),
		.clock_gate_sw_rm_wr(clock_gate_sw_rm_wr),
		.auto_speed_nego(auto_speed_nego),
		.fixed_pat_num(fixed_pat_num),
		.clock_gate_sw_dskw_wr(clock_gate_sw_dskw_wr),
		.clock_gate_dw_rm_rd(clock_gate_dw_rm_rd),
		.clock_gate_dw_wa(clock_gate_dw_wa),
		.avmm_group_channel_index(avmm_group_channel_index),
		.use_default_base_address(use_default_base_address),
		.user_base_address(user_base_address)

	)
	stratixv_hssi_8g_rx_pcs_encrypted_inst	(
		.a1a2size(a1a2size),
		.aggtestbus(aggtestbus),
		.alignstatus(alignstatus),
		.alignstatussync0(alignstatussync0),
		.alignstatussync0toporbot(alignstatussync0toporbot),
		.alignstatustoporbot(alignstatustoporbot),
		.avmmaddress(avmmaddress),
		.avmmbyteen(avmmbyteen),
		.avmmclk(avmmclk),
		.avmmread(avmmread),
		.avmmrstn(avmmrstn),
		.avmmwrite(avmmwrite),
		.avmmwritedata(avmmwritedata),
		.bitreversalenable(bitreversalenable),
		.bitslip(bitslip),
		.byteorder(byteorder),
		.bytereversalenable(bytereversalenable),
		.cgcomprddall(cgcomprddall),
		.cgcomprddalltoporbot(cgcomprddalltoporbot),
		.cgcompwrall(cgcompwrall),
		.cgcompwralltoporbot(cgcompwralltoporbot),
		.configselinchnldown(configselinchnldown),
		.configselinchnlup(configselinchnlup),
		.ctrlfromaggblock(ctrlfromaggblock),
		.datafrinaggblock(datafrinaggblock),
		.datain(datain),
		.delcondmet0(delcondmet0),
		.delcondmet0toporbot(delcondmet0toporbot),
		.dispcbytegen3(dispcbytegen3),
		.dynclkswitchn(dynclkswitchn),
		.eidleinfersel(eidleinfersel),
		.enablecommadetect(enablecommadetect),
		.endskwqd(endskwqd),
		.endskwqdtoporbot(endskwqdtoporbot),
		.endskwrdptrs(endskwrdptrs),
		.endskwrdptrstoporbot(endskwrdptrstoporbot),
		.fifoovr0(fifoovr0),
		.fifoovr0toporbot(fifoovr0toporbot),
		.fifordincomp0toporbot(fifordincomp0toporbot),
		.fiforstrdqd(fiforstrdqd),
		.fiforstrdqdtoporbot(fiforstrdqdtoporbot),
		.gen2ngen1(gen2ngen1),
		.hrdrst(hrdrst),
		.insertincomplete0(insertincomplete0),
		.insertincomplete0toporbot(insertincomplete0toporbot),
		.latencycomp0(latencycomp0),
		.latencycomp0toporbot(latencycomp0toporbot),
		.parallelloopback(parallelloopback),
		.pcfifordenable(pcfifordenable),
		.pcieswitchgen3(pcieswitchgen3),
		.phfifouserrst(phfifouserrst),
		.phystatusinternal(phystatusinternal),
		.phystatuspcsgen3(phystatuspcsgen3),
		.pipeloopbk(pipeloopbk),
		.pldltr(pldltr),
		.pldrxclk(pldrxclk),
		.polinvrx(polinvrx),
		.prbscidenable(prbscidenable),
		.pxfifowrdisable(pxfifowrdisable),
		.rateswitchcontrol(rateswitchcontrol),
		.rcvdclkagg(rcvdclkagg),
		.rcvdclkaggtoporbot(rcvdclkaggtoporbot),
		.rcvdclkpma(rcvdclkpma),
		.rdenableinchnldown(rdenableinchnldown),
		.rdenableinchnlup(rdenableinchnlup),
		.refclkdig(refclkdig),
		.refclkdig2(refclkdig2),
		.resetpcptrsgen3(resetpcptrsgen3),
		.resetpcptrsinchnldown(resetpcptrsinchnldown),
		.resetpcptrsinchnlup(resetpcptrsinchnlup),
		.resetppmcntrsgen3(resetppmcntrsgen3),
		.resetppmcntrsinchnldown(resetppmcntrsinchnldown),
		.resetppmcntrsinchnlup(resetppmcntrsinchnlup),
		.rmfifordincomp0(rmfifordincomp0),
		.rmfiforeadenable(rmfiforeadenable),
		.rmfifouserrst(rmfifouserrst),
		.rmfifowriteenable(rmfifowriteenable),
		.rxblkstartpcsgen3(rxblkstartpcsgen3),
		.rxcontrolrstoporbot(rxcontrolrstoporbot),
		.rxdatapcsgen3(rxdatapcsgen3),
		.rxdatarstoporbot(rxdatarstoporbot),
		.rxdatavalidpcsgen3(rxdatavalidpcsgen3),
		.rxdivsyncinchnldown(rxdivsyncinchnldown),
		.rxdivsyncinchnlup(rxdivsyncinchnlup),
		.rxpcsrst(rxpcsrst),
		.rxstatusinternal(rxstatusinternal),
		.rxstatuspcsgen3(rxstatuspcsgen3),
		.rxsynchdrpcsgen3(rxsynchdrpcsgen3),
		.rxvalidinternal(rxvalidinternal),
		.rxvalidpcsgen3(rxvalidpcsgen3),
		.rxweinchnldown(rxweinchnldown),
		.rxweinchnlup(rxweinchnlup),
		.scanmode(scanmode),
		.sigdetfrompma(sigdetfrompma),
		.speedchangeinchnldown(speedchangeinchnldown),
		.speedchangeinchnlup(speedchangeinchnlup),
		.syncsmen(syncsmen),
		.txctrlplanetestbus(txctrlplanetestbus),
		.txdivsync(txdivsync),
		.txpmaclk(txpmaclk),
		.txtestbus(txtestbus),
		.wrenableinchnldown(wrenableinchnldown),
		.wrenableinchnlup(wrenableinchnlup),
		.a1a2k1k2flag(a1a2k1k2flag),
		.aggrxpcsrst(aggrxpcsrst),
		.aligndetsync(aligndetsync),
		.alignstatuspld(alignstatuspld),
		.alignstatussync(alignstatussync),
		.avmmreaddata(avmmreaddata),
		.bistdone(bistdone),
		.bisterr(bisterr),
		.blockselect(blockselect),
		.byteordflag(byteordflag),
		.cgcomprddout(cgcomprddout),
		.cgcompwrout(cgcompwrout),
		.channeltestbusout(channeltestbusout),
		.clocktopld(clocktopld),
		.configseloutchnldown(configseloutchnldown),
		.configseloutchnlup(configseloutchnlup),
		.dataout(dataout),
		.decoderctrl(decoderctrl),
		.decoderdata(decoderdata),
		.decoderdatavalid(decoderdatavalid),
		.delcondmetout(delcondmetout),
		.disablepcfifobyteserdes(disablepcfifobyteserdes),
		.earlyeios(earlyeios),
		.eidledetected(eidledetected),
		.eidleexit(eidleexit),
		.errctrl(errctrl),
		.errdata(errdata),
		.fifoovrout(fifoovrout),
		.fifordoutcomp(fifordoutcomp),
		.insertincompleteout(insertincompleteout),
		.latencycompout(latencycompout),
		.ltr(ltr),
		.observablebyteserdesclock(observablebyteserdesclock),
		.parallelrevloopback(parallelrevloopback),
		.pcfifoempty(pcfifoempty),
		.pcfifofull(pcfifofull),
		.pcieswitch(pcieswitch),
		.phystatus(phystatus),
		.pipedata(pipedata),
		.prbsdone(prbsdone),
		.prbserrlt(prbserrlt),
		.rdalign(rdalign),
		.rdenableoutchnldown(rdenableoutchnldown),
		.rdenableoutchnlup(rdenableoutchnlup),
		.resetpcptrs(resetpcptrs),
		.resetpcptrsinchnldownpipe(resetpcptrsinchnldownpipe),
		.resetpcptrsinchnluppipe(resetpcptrsinchnluppipe),
		.resetpcptrsoutchnldown(resetpcptrsoutchnldown),
		.resetpcptrsoutchnlup(resetpcptrsoutchnlup),
		.resetppmcntrsoutchnldown(resetppmcntrsoutchnldown),
		.resetppmcntrsoutchnlup(resetppmcntrsoutchnlup),
		.resetppmcntrspcspma(resetppmcntrspcspma),
		.rlvlt(rlvlt),
		.rmfifoempty(rmfifoempty),
		.rmfifofull(rmfifofull),
		.rmfifopartialempty(rmfifopartialempty),
		.rmfifopartialfull(rmfifopartialfull),
		.runlengthviolation(runlengthviolation),
		.runningdisparity(runningdisparity),
		.rxblkstart(rxblkstart),
		.rxclkoutgen3(rxclkoutgen3),
		.rxclkslip(rxclkslip),
		.rxdatavalid(rxdatavalid),
		.rxdivsyncoutchnldown(rxdivsyncoutchnldown),
		.rxdivsyncoutchnlup(rxdivsyncoutchnlup),
		.rxpipeclk(rxpipeclk),
		.rxpipesoftreset(rxpipesoftreset),
		.rxstatus(rxstatus),
		.rxsynchdr(rxsynchdr),
		.rxvalid(rxvalid),
		.rxweoutchnldown(rxweoutchnldown),
		.rxweoutchnlup(rxweoutchnlup),
		.selftestdone(selftestdone),
		.selftesterr(selftesterr),
		.signaldetectout(signaldetectout),
		.speedchange(speedchange),
		.speedchangeinchnldownpipe(speedchangeinchnldownpipe),
		.speedchangeinchnluppipe(speedchangeinchnluppipe),
		.speedchangeoutchnldown(speedchangeoutchnldown),
		.speedchangeoutchnlup(speedchangeoutchnlup),
		.syncdatain(syncdatain),
		.syncstatus(syncstatus),
		.wordalignboundary(wordalignboundary),
		.wrenableoutchnldown(wrenableoutchnldown),
		.wrenableoutchnlup(wrenableoutchnlup)
	);


endmodule
// --------------------------------------------------------------------
// This is auto-generated HSSI Simulation Atom Model Encryption Wrapper
// Module Name : ./sim_model_wrappers//stratixv_hssi_8g_tx_pcs_wrapper.v
// --------------------------------------------------------------------

`timescale 1 ps/1 ps
module stratixv_hssi_8g_tx_pcs
#(
	// parameter declaration and default value assignemnt
	parameter enable_debug_info = "false",	//Valid values: false|true; this is simulation-only parameter, for debug purpose only

	parameter prot_mode = "basic",	//Valid values: pipe_g1|pipe_g2|pipe_g3|cpri|cpri_rx_tx|gige|xaui|srio_2p1|test|basic|disabled_prot_mode
	parameter hip_mode = "dis_hip",	//Valid values: dis_hip|en_hip
	parameter pma_dw = "eight_bit",	//Valid values: eight_bit|ten_bit|sixteen_bit|twenty_bit
	parameter pcs_bypass = "dis_pcs_bypass",	//Valid values: dis_pcs_bypass|en_pcs_bypass
	parameter phase_compensation_fifo = "low_latency",	//Valid values: low_latency|normal_latency|register_fifo|pld_ctrl_low_latency|pld_ctrl_normal_latency
	parameter tx_compliance_controlled_disparity = "dis_txcompliance",	//Valid values: dis_txcompliance|en_txcompliance_pipe2p0|en_txcompliance_pipe3p0
	parameter force_kchar = "dis_force_kchar",	//Valid values: dis_force_kchar|en_force_kchar
	parameter force_echar = "dis_force_echar",	//Valid values: dis_force_echar|en_force_echar
	parameter byte_serializer = "dis_bs",	//Valid values: dis_bs|en_bs_by_2|en_bs_by_4
	parameter data_selection_8b10b_encoder_input = "normal_data_path",	//Valid values: normal_data_path|xaui_sm|gige_idle_conversion
	parameter eightb_tenb_disp_ctrl = "dis_disp_ctrl",	//Valid values: dis_disp_ctrl|en_disp_ctrl|en_ib_disp_ctrl
	parameter eightb_tenb_encoder = "dis_8b10b",	//Valid values: dis_8b10b|en_8b10b_ibm|en_8b10b_sgx
	parameter prbs_gen = "dis_prbs",	//Valid values: dis_prbs|prbs_7_sw|prbs_7_dw|prbs_8|prbs_10|prbs_23_sw|prbs_23_dw|prbs_15|prbs_31|prbs_hf_sw|prbs_hf_dw|prbs_lf_sw|prbs_lf_dw|prbs_mf_sw|prbs_mf_dw
	parameter cid_pattern = "cid_pattern_0",	//Valid values: cid_pattern_0|cid_pattern_1
	parameter cid_pattern_len = 8'b0,	//Valid values: 8
	parameter bist_gen = "dis_bist",	//Valid values: dis_bist|incremental|cjpat|crpat
	parameter bit_reversal = "dis_bit_reversal",	//Valid values: dis_bit_reversal|en_bit_reversal
	parameter symbol_swap = "dis_symbol_swap",	//Valid values: dis_symbol_swap|en_symbol_swap
	parameter polarity_inversion = "dis_polinv",	//Valid values: dis_polinv|enable_polinv
	parameter tx_bitslip = "dis_tx_bitslip",	//Valid values: dis_tx_bitslip|en_tx_bitslip
	parameter agg_block_sel = "same_smrt_pack",	//Valid values: same_smrt_pack|other_smrt_pack
	parameter revloop_back_rm = "dis_rev_loopback_rx_rm",	//Valid values: dis_rev_loopback_rx_rm|en_rev_loopback_rx_rm
	parameter phfifo_write_clk_sel = "pld_tx_clk",	//Valid values: pld_tx_clk|tx_clk
	parameter ctrl_plane_bonding_consumption = "individual",	//Valid values: individual|bundled_master|bundled_slave_below|bundled_slave_above
	parameter bypass_pipeline_reg = "dis_bypass_pipeline",	//Valid values: dis_bypass_pipeline|en_bypass_pipeline
	parameter ctrl_plane_bonding_distribution = "not_master_chnl_distr",	//Valid values: master_chnl_distr|not_master_chnl_distr
	parameter test_mode = "prbs",	//Valid values: dont_care_test|prbs|bist
	parameter ctrl_plane_bonding_compensation = "dis_compensation",	//Valid values: dis_compensation|en_compensation
	parameter refclk_b_clk_sel = "tx_pma_clock",	//Valid values: tx_pma_clock|refclk_dig
	parameter auto_speed_nego_gen2 = "dis_asn_g2",	//Valid values: dis_asn_g2|en_asn_g2_freq_scal
	parameter channel_number = 0,	//Valid values: 0..65
	parameter txpcs_urst = "en_txpcs_urst",	//Valid values: dis_txpcs_urst|en_txpcs_urst
	parameter clock_gate_dw_fifowr = "dis_dw_fifowr_clk_gating",	//Valid values: dis_dw_fifowr_clk_gating|en_dw_fifowr_clk_gating
	parameter clock_gate_prbs = "dis_prbs_clk_gating",	//Valid values: dis_prbs_clk_gating|en_prbs_clk_gating
	parameter txclk_freerun = "en_freerun_tx",	//Valid values: dis_freerun_tx|en_freerun_tx
	parameter clock_gate_bs_enc = "dis_bs_enc_clk_gating",	//Valid values: dis_bs_enc_clk_gating|en_bs_enc_clk_gating
	parameter clock_gate_bist = "dis_bist_clk_gating",	//Valid values: dis_bist_clk_gating|en_bist_clk_gating
	parameter clock_gate_fiford = "dis_fiford_clk_gating",	//Valid values: dis_fiford_clk_gating|en_fiford_clk_gating
	parameter pcfifo_urst = "dis_pcfifourst",	//Valid values: dis_pcfifourst|en_pcfifourst
	parameter clock_gate_sw_fifowr = "dis_sw_fifowr_clk_gating",	//Valid values: dis_sw_fifowr_clk_gating|en_sw_fifowr_clk_gating
	parameter sup_mode = "user_mode",	//Valid values: user_mode|engineering_mode
	parameter dynamic_clk_switch = "dis_dyn_clk_switch",	//Valid values: dis_dyn_clk_switch|en_dyn_clk_switch
	parameter avmm_group_channel_index = 0,	//Valid values: 0..2
	parameter use_default_base_address = "true",	//Valid values: false|true
	parameter user_base_address = 0	//Valid values: 0..2047
)
(
//input and output port declaration
	input [ 10:0 ] avmmaddress,
	input [ 1:0 ] avmmbyteen,
	input [ 0:0 ] avmmclk,
	input [ 0:0 ] avmmread,
	input [ 0:0 ] avmmrstn,
	input [ 0:0 ] avmmwrite,
	input [ 15:0 ] avmmwritedata,
	input [ 4:0 ] bitslipboundaryselect,
	input [ 0:0 ] clkselgen3,
	input [ 0:0 ] coreclk,
	input [ 43:0 ] datain,
	input [ 0:0 ] detectrxloopin,
	input [ 0:0 ] dispcbyte,
	input [ 2:0 ] elecidleinfersel,
	input [ 0:0 ] enrevparallellpbk,
	input [ 1:0 ] fifoselectinchnldown,
	input [ 1:0 ] fifoselectinchnlup,
	input [ 0:0 ] hrdrst,
	input [ 0:0 ] invpol,
	input [ 0:0 ] phfiforddisable,
	input [ 0:0 ] phfiforeset,
	input [ 0:0 ] phfifowrenable,
	input [ 0:0 ] pipeenrevparallellpbkin,
	input [ 0:0 ] pipetxdeemph,
	input [ 2:0 ] pipetxmargin,
	input [ 0:0 ] pipetxswing,
	input [ 0:0 ] polinvrxin,
	input [ 1:0 ] powerdn,
	input [ 0:0 ] prbscidenable,
	input [ 0:0 ] rateswitch,
	input [ 0:0 ] rdenableinchnldown,
	input [ 0:0 ] rdenableinchnlup,
	input [ 0:0 ] refclkdig,
	input [ 0:0 ] resetpcptrs,
	input [ 0:0 ] resetpcptrsinchnldown,
	input [ 0:0 ] resetpcptrsinchnlup,
	input [ 19:0 ] revparallellpbkdata,
	input [ 0:0 ] rxpolarityin,
	input [ 0:0 ] scanmode,
	input [ 3:0 ] txblkstart,
	input [ 3:0 ] txdatavalid,
	input [ 1:0 ] txdivsyncinchnldown,
	input [ 1:0 ] txdivsyncinchnlup,
	input [ 0:0 ] txpcsreset,
	input [ 0:0 ] txpmalocalclk,
	input [ 1:0 ] txsynchdr,
	input [ 0:0 ] wrenableinchnldown,
	input [ 0:0 ] wrenableinchnlup,
	input [ 0:0 ] xgmctrl,
	input [ 0:0 ] xgmctrltoporbottom,
	input [ 7:0 ] xgmdatain,
	input [ 7:0 ] xgmdataintoporbottom,
	output [ 0:0 ] aggtxpcsrst,
	output [ 15:0 ] avmmreaddata,
	output [ 0:0 ] blockselect,
	output [ 0:0 ] clkout,
	output [ 0:0 ] clkoutgen3,
	output [ 19:0 ] dataout,
	output [ 0:0 ] detectrxloopout,
	output [ 0:0 ] dynclkswitchn,
	output [ 1:0 ] fifoselectoutchnldown,
	output [ 1:0 ] fifoselectoutchnlup,
	output [ 2:0 ] grayelecidleinferselout,
	output [ 0:0 ] observablebyteserdesclock,
	output [ 19:0 ] parallelfdbkout,
	output [ 0:0 ] phfifooverflow,
	output [ 0:0 ] phfifotxdeemph,
	output [ 2:0 ] phfifotxmargin,
	output [ 0:0 ] phfifotxswing,
	output [ 0:0 ] phfifounderflow,
	output [ 0:0 ] pipeenrevparallellpbkout,
	output [ 1:0 ] pipepowerdownout,
	output [ 0:0 ] polinvrxout,
	output [ 0:0 ] rdenableoutchnldown,
	output [ 0:0 ] rdenableoutchnlup,
	output [ 0:0 ] rdenablesync,
	output [ 0:0 ] refclkb,
	output [ 0:0 ] refclkbreset,
	output [ 0:0 ] rxpolarityout,
	output [ 0:0 ] syncdatain,
	output [ 3:0 ] txblkstartout,
	output [ 0:0 ] txcomplianceout,
	output [ 19:0 ] txctrlplanetestbus,
	output [ 3:0 ] txdatakouttogen3,
	output [ 31:0 ] txdataouttogen3,
	output [ 3:0 ] txdatavalidouttogen3,
	output [ 1:0 ] txdivsync,
	output [ 1:0 ] txdivsyncoutchnldown,
	output [ 1:0 ] txdivsyncoutchnlup,
	output [ 0:0 ] txelecidleout,
	output [ 0:0 ] txpipeclk,
	output [ 0:0 ] txpipeelectidle,
	output [ 0:0 ] txpipesoftreset,
	output [ 1:0 ] txsynchdrout,
	output [ 19:0 ] txtestbus,
	output [ 0:0 ] wrenableoutchnldown,
	output [ 0:0 ] wrenableoutchnlup,
	output [ 0:0 ] xgmctrlenable,
	output [ 7:0 ] xgmdataout
); 

	stratixv_hssi_8g_tx_pcs_encrypted 
	#(
		.enable_debug_info(enable_debug_info),

		.prot_mode(prot_mode),
		.hip_mode(hip_mode),
		.pma_dw(pma_dw),
		.pcs_bypass(pcs_bypass),
		.phase_compensation_fifo(phase_compensation_fifo),
		.tx_compliance_controlled_disparity(tx_compliance_controlled_disparity),
		.force_kchar(force_kchar),
		.force_echar(force_echar),
		.byte_serializer(byte_serializer),
		.data_selection_8b10b_encoder_input(data_selection_8b10b_encoder_input),
		.eightb_tenb_disp_ctrl(eightb_tenb_disp_ctrl),
		.eightb_tenb_encoder(eightb_tenb_encoder),
		.prbs_gen(prbs_gen),
		.cid_pattern(cid_pattern),
		.cid_pattern_len(cid_pattern_len),
		.bist_gen(bist_gen),
		.bit_reversal(bit_reversal),
		.symbol_swap(symbol_swap),
		.polarity_inversion(polarity_inversion),
		.tx_bitslip(tx_bitslip),
		.agg_block_sel(agg_block_sel),
		.revloop_back_rm(revloop_back_rm),
		.phfifo_write_clk_sel(phfifo_write_clk_sel),
		.ctrl_plane_bonding_consumption(ctrl_plane_bonding_consumption),
		.bypass_pipeline_reg(bypass_pipeline_reg),
		.ctrl_plane_bonding_distribution(ctrl_plane_bonding_distribution),
		.test_mode(test_mode),
		.ctrl_plane_bonding_compensation(ctrl_plane_bonding_compensation),
		.refclk_b_clk_sel(refclk_b_clk_sel),
		.auto_speed_nego_gen2(auto_speed_nego_gen2),
		.channel_number(channel_number),
		.txpcs_urst(txpcs_urst),
		.clock_gate_dw_fifowr(clock_gate_dw_fifowr),
		.clock_gate_prbs(clock_gate_prbs),
		.txclk_freerun(txclk_freerun),
		.clock_gate_bs_enc(clock_gate_bs_enc),
		.clock_gate_bist(clock_gate_bist),
		.clock_gate_fiford(clock_gate_fiford),
		.pcfifo_urst(pcfifo_urst),
		.clock_gate_sw_fifowr(clock_gate_sw_fifowr),
		.sup_mode(sup_mode),
		.dynamic_clk_switch(dynamic_clk_switch),
		.avmm_group_channel_index(avmm_group_channel_index),
		.use_default_base_address(use_default_base_address),
		.user_base_address(user_base_address)

	)
	stratixv_hssi_8g_tx_pcs_encrypted_inst	(
		.avmmaddress(avmmaddress),
		.avmmbyteen(avmmbyteen),
		.avmmclk(avmmclk),
		.avmmread(avmmread),
		.avmmrstn(avmmrstn),
		.avmmwrite(avmmwrite),
		.avmmwritedata(avmmwritedata),
		.bitslipboundaryselect(bitslipboundaryselect),
		.clkselgen3(clkselgen3),
		.coreclk(coreclk),
		.datain(datain),
		.detectrxloopin(detectrxloopin),
		.dispcbyte(dispcbyte),
		.elecidleinfersel(elecidleinfersel),
		.enrevparallellpbk(enrevparallellpbk),
		.fifoselectinchnldown(fifoselectinchnldown),
		.fifoselectinchnlup(fifoselectinchnlup),
		.hrdrst(hrdrst),
		.invpol(invpol),
		.phfiforddisable(phfiforddisable),
		.phfiforeset(phfiforeset),
		.phfifowrenable(phfifowrenable),
		.pipeenrevparallellpbkin(pipeenrevparallellpbkin),
		.pipetxdeemph(pipetxdeemph),
		.pipetxmargin(pipetxmargin),
		.pipetxswing(pipetxswing),
		.polinvrxin(polinvrxin),
		.powerdn(powerdn),
		.prbscidenable(prbscidenable),
		.rateswitch(rateswitch),
		.rdenableinchnldown(rdenableinchnldown),
		.rdenableinchnlup(rdenableinchnlup),
		.refclkdig(refclkdig),
		.resetpcptrs(resetpcptrs),
		.resetpcptrsinchnldown(resetpcptrsinchnldown),
		.resetpcptrsinchnlup(resetpcptrsinchnlup),
		.revparallellpbkdata(revparallellpbkdata),
		.rxpolarityin(rxpolarityin),
		.scanmode(scanmode),
		.txblkstart(txblkstart),
		.txdatavalid(txdatavalid),
		.txdivsyncinchnldown(txdivsyncinchnldown),
		.txdivsyncinchnlup(txdivsyncinchnlup),
		.txpcsreset(txpcsreset),
		.txpmalocalclk(txpmalocalclk),
		.txsynchdr(txsynchdr),
		.wrenableinchnldown(wrenableinchnldown),
		.wrenableinchnlup(wrenableinchnlup),
		.xgmctrl(xgmctrl),
		.xgmctrltoporbottom(xgmctrltoporbottom),
		.xgmdatain(xgmdatain),
		.xgmdataintoporbottom(xgmdataintoporbottom),
		.aggtxpcsrst(aggtxpcsrst),
		.avmmreaddata(avmmreaddata),
		.blockselect(blockselect),
		.clkout(clkout),
		.clkoutgen3(clkoutgen3),
		.dataout(dataout),
		.detectrxloopout(detectrxloopout),
		.dynclkswitchn(dynclkswitchn),
		.fifoselectoutchnldown(fifoselectoutchnldown),
		.fifoselectoutchnlup(fifoselectoutchnlup),
		.grayelecidleinferselout(grayelecidleinferselout),
		.observablebyteserdesclock(observablebyteserdesclock),
		.parallelfdbkout(parallelfdbkout),
		.phfifooverflow(phfifooverflow),
		.phfifotxdeemph(phfifotxdeemph),
		.phfifotxmargin(phfifotxmargin),
		.phfifotxswing(phfifotxswing),
		.phfifounderflow(phfifounderflow),
		.pipeenrevparallellpbkout(pipeenrevparallellpbkout),
		.pipepowerdownout(pipepowerdownout),
		.polinvrxout(polinvrxout),
		.rdenableoutchnldown(rdenableoutchnldown),
		.rdenableoutchnlup(rdenableoutchnlup),
		.rdenablesync(rdenablesync),
		.refclkb(refclkb),
		.refclkbreset(refclkbreset),
		.rxpolarityout(rxpolarityout),
		.syncdatain(syncdatain),
		.txblkstartout(txblkstartout),
		.txcomplianceout(txcomplianceout),
		.txctrlplanetestbus(txctrlplanetestbus),
		.txdatakouttogen3(txdatakouttogen3),
		.txdataouttogen3(txdataouttogen3),
		.txdatavalidouttogen3(txdatavalidouttogen3),
		.txdivsync(txdivsync),
		.txdivsyncoutchnldown(txdivsyncoutchnldown),
		.txdivsyncoutchnlup(txdivsyncoutchnlup),
		.txelecidleout(txelecidleout),
		.txpipeclk(txpipeclk),
		.txpipeelectidle(txpipeelectidle),
		.txpipesoftreset(txpipesoftreset),
		.txsynchdrout(txsynchdrout),
		.txtestbus(txtestbus),
		.wrenableoutchnldown(wrenableoutchnldown),
		.wrenableoutchnlup(wrenableoutchnlup),
		.xgmctrlenable(xgmctrlenable),
		.xgmdataout(xgmdataout)
	);


endmodule
// --------------------------------------------------------------------
// This is auto-generated HSSI Simulation Atom Model Encryption Wrapper
// Module Name : ./sim_model_wrappers//stratixv_hssi_pipe_gen1_2_wrapper.v
// --------------------------------------------------------------------

`timescale 1 ps/1 ps
module stratixv_hssi_pipe_gen1_2
#(
	// parameter declaration and default value assignemnt
	parameter enable_debug_info = "false",	//Valid values: false|true; this is simulation-only parameter, for debug purpose only

	parameter prot_mode = "pipe_g1",	//Valid values: pipe_g1|pipe_g2|pipe_g3|cpri|cpri_rx_tx|gige|xaui|srio_2p1|test|basic|disabled_prot_mode
	parameter hip_mode = "dis_hip",	//Valid values: dis_hip|en_hip
	parameter tx_pipe_enable = "dis_pipe_tx",	//Valid values: dis_pipe_tx|en_pipe_tx|en_pipe3_tx
	parameter rx_pipe_enable = "dis_pipe_rx",	//Valid values: dis_pipe_rx|en_pipe_rx|en_pipe3_rx
	parameter pipe_byte_de_serializer_en = "dont_care_bds",	//Valid values: dis_bds|en_bds_by_2|dont_care_bds
	parameter txswing = "dis_txswing",	//Valid values: dis_txswing|en_txswing
	parameter rxdetect_bypass = "dis_rxdetect_bypass",	//Valid values: dis_rxdetect_bypass|en_rxdetect_bypass
	parameter error_replace_pad = "replace_edb",	//Valid values: replace_edb|replace_pad
	parameter ind_error_reporting = "dis_ind_error_reporting",	//Valid values: dis_ind_error_reporting|en_ind_error_reporting
	parameter phystatus_rst_toggle = "dis_phystatus_rst_toggle",	//Valid values: dis_phystatus_rst_toggle|en_phystatus_rst_toggle
	parameter elecidle_delay = "elec_idle_delay",	//Valid values: elec_idle_delay
	parameter elec_idle_delay_val = 3'b0,	//Valid values: 3
	parameter phy_status_delay = "phystatus_delay",	//Valid values: phystatus_delay
	parameter phystatus_delay_val = 3'b0,	//Valid values: 3
	parameter rvod_sel_d_val = 6'b0,	//Valid values: 6
	parameter rpre_emph_b_val = 6'b0,	//Valid values: 6
	parameter rvod_sel_c_val = 6'b0,	//Valid values: 6
	parameter rpre_emph_c_val = 6'b0,	//Valid values: 6
	parameter rpre_emph_settings = 6'b0,	//Valid values: 6
	parameter rvod_sel_a_val = 6'b0,	//Valid values: 6
	parameter rpre_emph_d_val = 6'b0,	//Valid values: 6
	parameter rvod_sel_settings = 6'b0,	//Valid values: 6
	parameter rvod_sel_b_val = 6'b0,	//Valid values: 6
	parameter rpre_emph_e_val = 6'b0,	//Valid values: 6
	parameter sup_mode = "user_mode",	//Valid values: user_mode|engineering_mode
	parameter rvod_sel_e_val = 6'b0,	//Valid values: 6
	parameter rpre_emph_a_val = 6'b0,	//Valid values: 6
	parameter ctrl_plane_bonding_consumption = "individual",	//Valid values: individual|bundled_master|bundled_slave_below|bundled_slave_above
	parameter avmm_group_channel_index = 0,	//Valid values: 0..2
	parameter use_default_base_address = "true",	//Valid values: false|true
	parameter user_base_address = 0	//Valid values: 0..2047
)
(
//input and output port declaration
	input [ 10:0 ] avmmaddress,
	input [ 1:0 ] avmmbyteen,
	input [ 0:0 ] avmmclk,
	input [ 0:0 ] avmmread,
	input [ 0:0 ] avmmrstn,
	input [ 0:0 ] avmmwrite,
	input [ 15:0 ] avmmwritedata,
	input [ 0:0 ] pcieswitch,
	input [ 0:0 ] piperxclk,
	input [ 0:0 ] pipetxclk,
	input [ 0:0 ] polinvrx,
	input [ 1:0 ] powerdown,
	input [ 0:0 ] powerstatetransitiondone,
	input [ 0:0 ] powerstatetransitiondoneena,
	input [ 0:0 ] refclkb,
	input [ 0:0 ] refclkbreset,
	input [ 0:0 ] revloopback,
	input [ 0:0 ] revloopbkpcsgen3,
	input [ 63:0 ] rxd,
	input [ 0:0 ] rxdetectvalid,
	input [ 0:0 ] rxelectricalidle,
	input [ 0:0 ] rxelectricalidlepcsgen3,
	input [ 0:0 ] rxfound,
	input [ 0:0 ] rxpipereset,
	input [ 0:0 ] rxpolarity,
	input [ 0:0 ] rxpolaritypcsgen3,
	input [ 0:0 ] sigdetni,
	input [ 0:0 ] speedchange,
	input [ 0:0 ] speedchangechnldown,
	input [ 0:0 ] speedchangechnlup,
	input [ 43:0 ] txdch,
	input [ 0:0 ] txdeemph,
	input [ 0:0 ] txdetectrxloopback,
	input [ 0:0 ] txelecidlecomp,
	input [ 0:0 ] txelecidlein,
	input [ 2:0 ] txmargin,
	input [ 0:0 ] txpipereset,
	input [ 0:0 ] txswingport,
	output [ 15:0 ] avmmreaddata,
	output [ 0:0 ] blockselect,
	output [ 17:0 ] currentcoeff,
	output [ 0:0 ] phystatus,
	output [ 0:0 ] polinvrxint,
	output [ 0:0 ] revloopbk,
	output [ 63:0 ] rxdch,
	output [ 0:0 ] rxelecidle,
	output [ 0:0 ] rxelectricalidleout,
	output [ 2:0 ] rxstatus,
	output [ 0:0 ] rxvalid,
	output [ 0:0 ] speedchangeout,
	output [ 43:0 ] txd,
	output [ 0:0 ] txdetectrx,
	output [ 0:0 ] txelecidleout
); 

	stratixv_hssi_pipe_gen1_2_encrypted 
	#(
		.enable_debug_info(enable_debug_info),

		.prot_mode(prot_mode),
		.hip_mode(hip_mode),
		.tx_pipe_enable(tx_pipe_enable),
		.rx_pipe_enable(rx_pipe_enable),
		.pipe_byte_de_serializer_en(pipe_byte_de_serializer_en),
		.txswing(txswing),
		.rxdetect_bypass(rxdetect_bypass),
		.error_replace_pad(error_replace_pad),
		.ind_error_reporting(ind_error_reporting),
		.phystatus_rst_toggle(phystatus_rst_toggle),
		.elecidle_delay(elecidle_delay),
		.elec_idle_delay_val(elec_idle_delay_val),
		.phy_status_delay(phy_status_delay),
		.phystatus_delay_val(phystatus_delay_val),
		.rvod_sel_d_val(rvod_sel_d_val),
		.rpre_emph_b_val(rpre_emph_b_val),
		.rvod_sel_c_val(rvod_sel_c_val),
		.rpre_emph_c_val(rpre_emph_c_val),
		.rpre_emph_settings(rpre_emph_settings),
		.rvod_sel_a_val(rvod_sel_a_val),
		.rpre_emph_d_val(rpre_emph_d_val),
		.rvod_sel_settings(rvod_sel_settings),
		.rvod_sel_b_val(rvod_sel_b_val),
		.rpre_emph_e_val(rpre_emph_e_val),
		.sup_mode(sup_mode),
		.rvod_sel_e_val(rvod_sel_e_val),
		.rpre_emph_a_val(rpre_emph_a_val),
		.ctrl_plane_bonding_consumption(ctrl_plane_bonding_consumption),
		.avmm_group_channel_index(avmm_group_channel_index),
		.use_default_base_address(use_default_base_address),
		.user_base_address(user_base_address)

	)
	stratixv_hssi_pipe_gen1_2_encrypted_inst	(
		.avmmaddress(avmmaddress),
		.avmmbyteen(avmmbyteen),
		.avmmclk(avmmclk),
		.avmmread(avmmread),
		.avmmrstn(avmmrstn),
		.avmmwrite(avmmwrite),
		.avmmwritedata(avmmwritedata),
		.pcieswitch(pcieswitch),
		.piperxclk(piperxclk),
		.pipetxclk(pipetxclk),
		.polinvrx(polinvrx),
		.powerdown(powerdown),
		.powerstatetransitiondone(powerstatetransitiondone),
		.powerstatetransitiondoneena(powerstatetransitiondoneena),
		.refclkb(refclkb),
		.refclkbreset(refclkbreset),
		.revloopback(revloopback),
		.revloopbkpcsgen3(revloopbkpcsgen3),
		.rxd(rxd),
		.rxdetectvalid(rxdetectvalid),
		.rxelectricalidle(rxelectricalidle),
		.rxelectricalidlepcsgen3(rxelectricalidlepcsgen3),
		.rxfound(rxfound),
		.rxpipereset(rxpipereset),
		.rxpolarity(rxpolarity),
		.rxpolaritypcsgen3(rxpolaritypcsgen3),
		.sigdetni(sigdetni),
		.speedchange(speedchange),
		.speedchangechnldown(speedchangechnldown),
		.speedchangechnlup(speedchangechnlup),
		.txdch(txdch),
		.txdeemph(txdeemph),
		.txdetectrxloopback(txdetectrxloopback),
		.txelecidlecomp(txelecidlecomp),
		.txelecidlein(txelecidlein),
		.txmargin(txmargin),
		.txpipereset(txpipereset),
		.txswingport(txswingport),
		.avmmreaddata(avmmreaddata),
		.blockselect(blockselect),
		.currentcoeff(currentcoeff),
		.phystatus(phystatus),
		.polinvrxint(polinvrxint),
		.revloopbk(revloopbk),
		.rxdch(rxdch),
		.rxelecidle(rxelecidle),
		.rxelectricalidleout(rxelectricalidleout),
		.rxstatus(rxstatus),
		.rxvalid(rxvalid),
		.speedchangeout(speedchangeout),
		.txd(txd),
		.txdetectrx(txdetectrx),
		.txelecidleout(txelecidleout)
	);


endmodule
// --------------------------------------------------------------------
// This is auto-generated HSSI Simulation Atom Model Encryption Wrapper
// Module Name : ./sim_model_wrappers//stratixv_hssi_gen3_rx_pcs_wrapper.v
// --------------------------------------------------------------------

`timescale 1 ps/1 ps
module stratixv_hssi_gen3_rx_pcs
#(
	// parameter declaration and default value assignemnt
	parameter enable_debug_info = "false",	//Valid values: false|true; this is simulation-only parameter, for debug purpose only

	parameter mode = "gen3_func",	//Valid values: gen3_func|par_lpbk|disable_pcs
	parameter sup_mode = "user_mode",	//Valid values: user_mode|engr_mode
	parameter rx_clk_sel = "rcvd_clk",	//Valid values: disable_clk|dig_clk1_8g|rcvd_clk
	parameter tx_clk_sel = "tx_pma_clk",	//Valid values: disable_clk|dig_clk2_8g|tx_pma_clk
	parameter decoder = "enable_decoder",	//Valid values: bypass_decoder|enable_decoder
	parameter descrambler = "enable_descrambler",	//Valid values: bypass_descrambler|enable_descrambler
	parameter block_sync = "enable_block_sync",	//Valid values: bypass_block_sync|enable_block_sync
	parameter block_sync_sm = "enable_blk_sync_sm",	//Valid values: disable_blk_sync_sm|enable_blk_sync_sm
	parameter rate_match_fifo = "enable_rm_fifo",	//Valid values: bypass_rm_fifo|enable_rm_fifo
	parameter rate_match_fifo_latency = "regular_latency",	//Valid values: regular_latency|low_latency
	parameter descrambler_lfsr_check = "lfsr_chk_dis",	//Valid values: lfsr_chk_dis|lfsr_chk_en
	parameter parallel_lpbk = "par_lpbk_dis",	//Valid values: par_lpbk_dis|par_lpbk_en
	parameter lpbk_force = "lpbk_frce_dis",	//Valid values: lpbk_frce_dis|lpbk_frce_en
	parameter reverse_lpbk = "rev_lpbk_en",	//Valid values: rev_lpbk_dis|rev_lpbk_en
	parameter rx_pol_compl = "rx_pol_compl_dis",	//Valid values: rx_pol_compl_dis|rx_pol_compl_en
	parameter rx_lane_num = "lane_0",	//Valid values: lane_0|lane_1|lane_2|lane_3|lane_4|lane_5|lane_6|lane_7|not_used
	parameter rmfifo_pempty_data = 5'b1000,	//Valid values: 5
	parameter rmfifo_pempty = "rmfifo_pempty",	//Valid values: rmfifo_pempty
	parameter rmfifo_pfull_data = 5'b10111,	//Valid values: 5
	parameter rmfifo_pfull = "rmfifo_pfull",	//Valid values: rmfifo_pfull
	parameter rmfifo_empty_data = 5'b1,	//Valid values: 5
	parameter rmfifo_empty = "rmfifo_empty",	//Valid values: rmfifo_empty
	parameter rmfifo_full_data = 5'b11111,	//Valid values: 5
	parameter rmfifo_full = "rmfifo_full",	//Valid values: rmfifo_full
	parameter rx_force_balign = "en_force_balign",	//Valid values: en_force_balign|dis_force_balign
	parameter rx_num_fixed_pat_data = 4'b100,	//Valid values: 4
	parameter rx_num_fixed_pat = "num_fixed_pat",	//Valid values: num_fixed_pat
	parameter rx_test_out_sel = "rx_test_out0",	//Valid values: rx_test_out0|rx_test_out1
	parameter rx_g3_dcbal = "g3_dcbal_en",	//Valid values: g3_dcbal_dis|g3_dcbal_en
	parameter rx_b4gb_par_lpbk = "b4gb_par_lpbk_dis",	//Valid values: b4gb_par_lpbk_dis|b4gb_par_lpbk_en
	parameter avmm_group_channel_index = 0,	//Valid values: 0..2
	parameter use_default_base_address = "true",	//Valid values: false|true
	parameter user_base_address = 0,	//Valid values: 0..2047
	parameter rx_ins_del_one_skip = "ins_del_one_skip_en"	//Valid values: ins_del_one_skip_dis|ins_del_one_skip_en
)
(
//input and output port declaration
	input [ 10:0 ] avmmaddress,
	input [ 1:0 ] avmmbyteen,
	input [ 0:0 ] avmmclk,
	input [ 0:0 ] avmmread,
	input [ 0:0 ] avmmrstn,
	input [ 0:0 ] avmmwrite,
	input [ 15:0 ] avmmwritedata,
	input [ 31:0 ] datain,
	input [ 0:0 ] gen3clksel,
	input [ 0:0 ] hardresetn,
	input [ 0:0 ] inferredrxvalid,
	input [ 0:0 ] lpbken,
	input [ 35:0 ] parlpbkb4gbin,
	input [ 31:0 ] parlpbkin,
	input [ 0:0 ] pcsrst,
	input [ 0:0 ] pldclk28gpcs,
	input [ 0:0 ] rcvdclk,
	input [ 0:0 ] rxpolarity,
	input [ 0:0 ] rxrstn,
	input [ 0:0 ] scanmoden,
	input [ 0:0 ] shutdownclk,
	input [ 0:0 ] syncsmen,
	input [ 3:0 ] txdatakin,
	input [ 0:0 ] txelecidle,
	input [ 0:0 ] txpmaclk,
	input [ 0:0 ] txpth,
	output [ 15:0 ] avmmreaddata,
	output [ 0:0 ] blkalgndint,
	output [ 0:0 ] blklockdint,
	output [ 0:0 ] blkstart,
	output [ 0:0 ] blockselect,
	output [ 0:0 ] clkcompdeleteint,
	output [ 0:0 ] clkcompinsertint,
	output [ 0:0 ] clkcompoverflint,
	output [ 0:0 ] clkcompundflint,
	output [ 31:0 ] dataout,
	output [ 0:0 ] datavalid,
	output [ 0:0 ] eidetint,
	output [ 0:0 ] eipartialdetint,
	output [ 0:0 ] errdecodeint,
	output [ 0:0 ] idetint,
	output [ 0:0 ] lpbkblkstart,
	output [ 33:0 ] lpbkdata,
	output [ 0:0 ] lpbkdatavalid,
	output [ 0:0 ] rcvlfsrchkint,
	output [ 19:0 ] rxtestout,
	output [ 0:0 ] skpdetint,
	output [ 1:0 ] synchdr
); 

	stratixv_hssi_gen3_rx_pcs_encrypted 
	#(
		.enable_debug_info(enable_debug_info),

		.mode(mode),
		.sup_mode(sup_mode),
		.rx_clk_sel(rx_clk_sel),
		.tx_clk_sel(tx_clk_sel),
		.decoder(decoder),
		.descrambler(descrambler),
		.block_sync(block_sync),
		.block_sync_sm(block_sync_sm),
		.rate_match_fifo(rate_match_fifo),
		.rate_match_fifo_latency(rate_match_fifo_latency),
		.descrambler_lfsr_check(descrambler_lfsr_check),
		.parallel_lpbk(parallel_lpbk),
		.lpbk_force(lpbk_force),
		.reverse_lpbk(reverse_lpbk),
		.rx_pol_compl(rx_pol_compl),
		.rx_lane_num(rx_lane_num),
		.rmfifo_pempty_data(rmfifo_pempty_data),
		.rmfifo_pempty(rmfifo_pempty),
		.rmfifo_pfull_data(rmfifo_pfull_data),
		.rmfifo_pfull(rmfifo_pfull),
		.rmfifo_empty_data(rmfifo_empty_data),
		.rmfifo_empty(rmfifo_empty),
		.rmfifo_full_data(rmfifo_full_data),
		.rmfifo_full(rmfifo_full),
		.rx_force_balign(rx_force_balign),
		.rx_num_fixed_pat_data(rx_num_fixed_pat_data),
		.rx_num_fixed_pat(rx_num_fixed_pat),
		.rx_test_out_sel(rx_test_out_sel),
		.rx_g3_dcbal(rx_g3_dcbal),
		.rx_b4gb_par_lpbk(rx_b4gb_par_lpbk),
		.avmm_group_channel_index(avmm_group_channel_index),
		.use_default_base_address(use_default_base_address),
		.user_base_address(user_base_address),
		.rx_ins_del_one_skip(rx_ins_del_one_skip)

	)
	stratixv_hssi_gen3_rx_pcs_encrypted_inst	(
		.avmmaddress(avmmaddress),
		.avmmbyteen(avmmbyteen),
		.avmmclk(avmmclk),
		.avmmread(avmmread),
		.avmmrstn(avmmrstn),
		.avmmwrite(avmmwrite),
		.avmmwritedata(avmmwritedata),
		.datain(datain),
		.gen3clksel(gen3clksel),
		.hardresetn(hardresetn),
		.inferredrxvalid(inferredrxvalid),
		.lpbken(lpbken),
		.parlpbkb4gbin(parlpbkb4gbin),
		.parlpbkin(parlpbkin),
		.pcsrst(pcsrst),
		.pldclk28gpcs(pldclk28gpcs),
		.rcvdclk(rcvdclk),
		.rxpolarity(rxpolarity),
		.rxrstn(rxrstn),
		.scanmoden(scanmoden),
		.shutdownclk(shutdownclk),
		.syncsmen(syncsmen),
		.txdatakin(txdatakin),
		.txelecidle(txelecidle),
		.txpmaclk(txpmaclk),
		.txpth(txpth),
		.avmmreaddata(avmmreaddata),
		.blkalgndint(blkalgndint),
		.blklockdint(blklockdint),
		.blkstart(blkstart),
		.blockselect(blockselect),
		.clkcompdeleteint(clkcompdeleteint),
		.clkcompinsertint(clkcompinsertint),
		.clkcompoverflint(clkcompoverflint),
		.clkcompundflint(clkcompundflint),
		.dataout(dataout),
		.datavalid(datavalid),
		.eidetint(eidetint),
		.eipartialdetint(eipartialdetint),
		.errdecodeint(errdecodeint),
		.idetint(idetint),
		.lpbkblkstart(lpbkblkstart),
		.lpbkdata(lpbkdata),
		.lpbkdatavalid(lpbkdatavalid),
		.rcvlfsrchkint(rcvlfsrchkint),
		.rxtestout(rxtestout),
		.skpdetint(skpdetint),
		.synchdr(synchdr)
	);


endmodule
// --------------------------------------------------------------------
// This is auto-generated HSSI Simulation Atom Model Encryption Wrapper
// Module Name : ./sim_model_wrappers//stratixv_hssi_gen3_tx_pcs_wrapper.v
// --------------------------------------------------------------------

`timescale 1 ps/1 ps
module stratixv_hssi_gen3_tx_pcs
#(
	// parameter declaration and default value assignemnt
	parameter enable_debug_info = "false",	//Valid values: false|true; this is simulation-only parameter, for debug purpose only

	parameter mode = "gen3_func",	//Valid values: gen3_func|prbs|par_lpbk|disable_pcs
	parameter sup_mode = "user_mode",	//Valid values: user_mode|engr_mode
	parameter tx_clk_sel = "tx_pma_clk",	//Valid values: disable_clk|dig_clk1_8g|tx_pma_clk
	parameter encoder = "enable_encoder",	//Valid values: bypass_encoder|enable_encoder
	parameter scrambler = "enable_scrambler",	//Valid values: bypass_scrambler|enable_scrambler
	parameter tx_bitslip_data = 5'b0,	//Valid values: 5
	parameter tx_bitslip = "tx_bitslip_val",	//Valid values: tx_bitslip_val
	parameter reverse_lpbk = "rev_lpbk_en",	//Valid values: rev_lpbk_dis|rev_lpbk_en
	parameter prbs_generator = "prbs_gen_dis",	//Valid values: prbs_gen_dis|prbs_gen_en
	parameter tx_pol_compl = "tx_pol_compl_dis",	//Valid values: tx_pol_compl_dis|tx_pol_compl_en
	parameter tx_lane_num = "lane_0",	//Valid values: lane_0|lane_1|lane_2|lane_3|lane_4|lane_5|lane_6|lane_7|not_used
	parameter tx_g3_dcbal = "tx_g3_dcbal_en",	//Valid values: tx_g3_dcbal_dis|tx_g3_dcbal_en
	parameter tx_gbox_byp = "bypass_gbox",	//Valid values: bypass_gbox|enable_gbox
	parameter avmm_group_channel_index = 0,	//Valid values: 0..2
	parameter use_default_base_address = "true",	//Valid values: false|true
	parameter user_base_address = 0	//Valid values: 0..2047
)
(
//input and output port declaration
	input [ 10:0 ] avmmaddress,
	input [ 1:0 ] avmmbyteen,
	input [ 0:0 ] avmmclk,
	input [ 0:0 ] avmmread,
	input [ 0:0 ] avmmrstn,
	input [ 0:0 ] avmmwrite,
	input [ 15:0 ] avmmwritedata,
	input [ 0:0 ] blkstartin,
	input [ 31:0 ] datain,
	input [ 0:0 ] datavalid,
	input [ 0:0 ] gen3clksel,
	input [ 0:0 ] hardresetn,
	input [ 0:0 ] lpbkblkstart,
	input [ 33:0 ] lpbkdatain,
	input [ 0:0 ] lpbkdatavalid,
	input [ 0:0 ] lpbken,
	input [ 0:0 ] pcsrst,
	input [ 0:0 ] scanmoden,
	input [ 0:0 ] shutdownclk,
	input [ 1:0 ] syncin,
	input [ 0:0 ] txelecidle,
	input [ 0:0 ] txpmaclk,
	input [ 0:0 ] txpth,
	input [ 0:0 ] txrstn,
	output [ 15:0 ] avmmreaddata,
	output [ 0:0 ] blockselect,
	output [ 31:0 ] dataout,
	output [ 0:0 ] errencode,
	output [ 35:0 ] parlpbkb4gbout,
	output [ 31:0 ] parlpbkout,
	output [ 19:0 ] txtestout
); 

	stratixv_hssi_gen3_tx_pcs_encrypted 
	#(
		.enable_debug_info(enable_debug_info),

		.mode(mode),
		.sup_mode(sup_mode),
		.tx_clk_sel(tx_clk_sel),
		.encoder(encoder),
		.scrambler(scrambler),
		.tx_bitslip_data(tx_bitslip_data),
		.tx_bitslip(tx_bitslip),
		.reverse_lpbk(reverse_lpbk),
		.prbs_generator(prbs_generator),
		.tx_pol_compl(tx_pol_compl),
		.tx_lane_num(tx_lane_num),
		.tx_g3_dcbal(tx_g3_dcbal),
		.tx_gbox_byp(tx_gbox_byp),
		.avmm_group_channel_index(avmm_group_channel_index),
		.use_default_base_address(use_default_base_address),
		.user_base_address(user_base_address)

	)
	stratixv_hssi_gen3_tx_pcs_encrypted_inst	(
		.avmmaddress(avmmaddress),
		.avmmbyteen(avmmbyteen),
		.avmmclk(avmmclk),
		.avmmread(avmmread),
		.avmmrstn(avmmrstn),
		.avmmwrite(avmmwrite),
		.avmmwritedata(avmmwritedata),
		.blkstartin(blkstartin),
		.datain(datain),
		.datavalid(datavalid),
		.gen3clksel(gen3clksel),
		.hardresetn(hardresetn),
		.lpbkblkstart(lpbkblkstart),
		.lpbkdatain(lpbkdatain),
		.lpbkdatavalid(lpbkdatavalid),
		.lpbken(lpbken),
		.pcsrst(pcsrst),
		.scanmoden(scanmoden),
		.shutdownclk(shutdownclk),
		.syncin(syncin),
		.txelecidle(txelecidle),
		.txpmaclk(txpmaclk),
		.txpth(txpth),
		.txrstn(txrstn),
		.avmmreaddata(avmmreaddata),
		.blockselect(blockselect),
		.dataout(dataout),
		.errencode(errencode),
		.parlpbkb4gbout(parlpbkb4gbout),
		.parlpbkout(parlpbkout),
		.txtestout(txtestout)
	);


endmodule
// --------------------------------------------------------------------
// This is auto-generated HSSI Simulation Atom Model Encryption Wrapper
// Module Name : ./sim_model_wrappers//stratixv_hssi_pipe_gen3_wrapper.v
// --------------------------------------------------------------------

`timescale 1 ps/1 ps
module stratixv_hssi_pipe_gen3
#(
	// parameter declaration and default value assignemnt
	parameter enable_debug_info = "false",	//Valid values: false|true; this is simulation-only parameter, for debug purpose only

	parameter mode = "pipe_g1",	//Valid values: pipe_g1|pipe_g2|pipe_g3|par_lpbk|disable_pcs
	parameter ctrl_plane_bonding = "individual",	//Valid values: individual|ctrl_master|ctrl_slave_blw|ctrl_slave_abv
	parameter pipe_clk_sel = "func_clk",	//Valid values: disable_clk|dig_clk1_8g|func_clk
	parameter rate_match_pad_insertion = "dis_rm_fifo_pad_ins",	//Valid values: dis_rm_fifo_pad_ins|en_rm_fifo_pad_ins
	parameter ind_error_reporting = "dis_ind_error_reporting",	//Valid values: dis_ind_error_reporting|en_ind_error_reporting
	parameter phystatus_rst_toggle_g3 = "dis_phystatus_rst_toggle_g3",	//Valid values: dis_phystatus_rst_toggle_g3|en_phystatus_rst_toggle_g3
	parameter phystatus_rst_toggle_g12 = "dis_phystatus_rst_toggle",	//Valid values: dis_phystatus_rst_toggle|en_phystatus_rst_toggle
	parameter cdr_control = "en_cdr_ctrl",	//Valid values: dis_cdr_ctrl|en_cdr_ctrl
	parameter cid_enable = "en_cid_mode",	//Valid values: dis_cid_mode|en_cid_mode
	parameter parity_chk_ts1 = "en_ts1_parity_chk",	//Valid values: en_ts1_parity_chk|dis_ts1_parity_chk
	parameter rxvalid_mask = "rxvalid_mask_en",	//Valid values: rxvalid_mask_dis|rxvalid_mask_en
	parameter ph_fifo_reg_mode = "phfifo_reg_mode_dis",	//Valid values: phfifo_reg_mode_dis|phfifo_reg_mode_en
	parameter test_mode_timers = "dis_test_mode_timers",	//Valid values: dis_test_mode_timers|en_test_mode_timers
	parameter inf_ei_enable = "dis_inf_ei",	//Valid values: dis_inf_ei|en_inf_ei
	parameter spd_chnge_g2_sel = "false",	//Valid values: false|true
	parameter cp_up_mstr = "false",	//Valid values: false|true
	parameter cp_dwn_mstr = "false",	//Valid values: false|true
	parameter cp_cons_sel = "cp_cons_default",	//Valid values: cp_cons_master|cp_cons_slave_abv|cp_cons_slave_blw|cp_cons_default
	parameter elecidle_delay_g3_data = 3'b0,	//Valid values: 3
	parameter elecidle_delay_g3 = "elecidle_delay_g3",	//Valid values: elecidle_delay_g3
	parameter phy_status_delay_g12_data = 3'b0,	//Valid values: 3
	parameter phy_status_delay_g12 = "phy_status_delay_g12",	//Valid values: phy_status_delay_g12
	parameter phy_status_delay_g3_data = 3'b0,	//Valid values: 3
	parameter phy_status_delay_g3 = "phy_status_delay_g3",	//Valid values: phy_status_delay_g3
	parameter sigdet_wait_counter_data = 8'b0,	//Valid values: 8
	parameter sigdet_wait_counter = "sigdet_wait_counter",	//Valid values: sigdet_wait_counter
	parameter data_mask_count_val = 10'b0,	//Valid values: 10
	parameter data_mask_count = "data_mask_count",	//Valid values: data_mask_count
	parameter pma_done_counter_data = 18'b0,	//Valid values: 18
	parameter pma_done_counter = "pma_done_count",	//Valid values: pma_done_count
	parameter pc_en_counter_data = 7'b110111,	//Valid values: 7
	parameter pc_en_counter = "pc_en_count",	//Valid values: pc_en_count
	parameter pc_rst_counter_data = 5'b10111,	//Valid values: 5
	parameter pc_rst_counter = "pc_rst_count",	//Valid values: pc_rst_count
	parameter phfifo_flush_wait_data = 6'b0,	//Valid values: 6
	parameter phfifo_flush_wait = "phfifo_flush_wait",	//Valid values: phfifo_flush_wait
	parameter asn_clk_enable = "false",	//Valid values: false|true
	parameter free_run_clk_enable = "true",	//Valid values: false|true
	parameter asn_enable = "dis_asn",	//Valid values: dis_asn|en_asn
	parameter bypass_send_syncp_fbkp = "false",	//Valid values: false|true
	parameter wait_send_syncp_fbkp_data = 11'b11111010,	//Valid values: 11
	parameter wait_clk_on_off_timer_data = 4'b100,	//Valid values: 4
	parameter wait_clk_on_off_timer = "wait_clk_on_off_timer",	//Valid values: wait_clk_on_off_timer
	parameter wait_send_syncp_fbkp = "wait_send_syncp_fbkp",	//Valid values: wait_send_syncp_fbkp
	parameter wait_pipe_synchronizing = "wait_pipe_sync",	//Valid values: wait_pipe_sync
	parameter bypass_pma_sw_done = "false",	//Valid values: false|true
	parameter test_out_sel = "disable",	//Valid values: tx_test_out|rx_test_out|pipe_test_out1|pipe_test_out2|pipe_test_out3|pipe_test_out4|pipe_ctrl_test_out1|pipe_ctrl_test_out2|pipe_ctrl_test_out3|disable
	parameter wait_pipe_synchronizing_data = 5'b10111,	//Valid values: 5
	parameter sup_mode = "user_mode",	//Valid values: user_mode|engr_mode
	parameter avmm_group_channel_index = 0,	//Valid values: 0..2
	parameter use_default_base_address = "true",	//Valid values: false|true
	parameter user_base_address = 0,	//Valid values: 0..2047
	parameter bypass_rx_preset_enable = "false",	//Valid values: false|true
	parameter bypass_tx_coefficent = "tx_coeff_bypass",	//Valid values: tx_coeff_bypass
	parameter bypass_rx_preset_data = 3'b0,	//Valid values: 3
	parameter bypass_tx_coefficent_enable = "false",	//Valid values: false|true
	parameter bypass_tx_coefficent_data = 18'b0,	//Valid values: 18
	parameter bypass_rx_preset = "rx_preset_bypass",	//Valid values: rx_preset_bypass
	parameter bypass_rx_detection_enable = "false"	//Valid values: false|true
)
(
//input and output port declaration
	input [ 10:0 ] avmmaddress,
	input [ 1:0 ] avmmbyteen,
	input [ 0:0 ] avmmclk,
	input [ 0:0 ] avmmread,
	input [ 0:0 ] avmmrstn,
	input [ 0:0 ] avmmwrite,
	input [ 15:0 ] avmmwritedata,
	input [ 0:0 ] blkalgndint,
	input [ 10:0 ] bundlingindown,
	input [ 10:0 ] bundlinginup,
	input [ 0:0 ] clkcompdeleteint,
	input [ 0:0 ] clkcompinsertint,
	input [ 0:0 ] clkcompoverflint,
	input [ 0:0 ] clkcompundflint,
	input [ 17:0 ] currentcoeff,
	input [ 2:0 ] currentrxpreset,
	input [ 0:0 ] eidetint,
	input [ 2:0 ] eidleinfersel,
	input [ 0:0 ] eipartialdetint,
	input [ 0:0 ] errdecodeint,
	input [ 0:0 ] errencodeint,
	input [ 0:0 ] hardresetn,
	input [ 0:0 ] idetint,
	input [ 0:0 ] pldltr,
	input [ 0:0 ] pllfixedclk,
	input [ 1:0 ] pmapcieswdone,
	input [ 0:0 ] pmarxdetectvalid,
	input [ 0:0 ] pmarxfound,
	input [ 0:0 ] pmasignaldet,
	input [ 1:0 ] powerdown,
	input [ 1:0 ] rate,
	input [ 0:0 ] rcvdclk,
	input [ 0:0 ] rcvlfsrchkint,
	input [ 0:0 ] rrxdigclksel,
	input [ 0:0 ] rrxgen3capen,
	input [ 0:0 ] rtxdigclksel,
	input [ 0:0 ] rtxgen3capen,
	input [ 0:0 ] rxblkstartint,
	input [ 63:0 ] rxd8gpcsin,
	input [ 31:0 ] rxdataint,
	input [ 3:0 ] rxdatakint,
	input [ 0:0 ] rxdataskipint,
	input [ 0:0 ] rxelecidle8gpcsin,
	input [ 0:0 ] rxpolarity,
	input [ 0:0 ] rxrstn,
	input [ 1:0 ] rxsynchdrint,
	input [ 19:0 ] rxtestout,
	input [ 0:0 ] rxupdatefc,
	input [ 0:0 ] scanmoden,
	input [ 0:0 ] speedchangeg2,
	input [ 0:0 ] txblkstart,
	input [ 0:0 ] txcompliance,
	input [ 31:0 ] txdata,
	input [ 3:0 ] txdatak,
	input [ 0:0 ] txdataskip,
	input [ 0:0 ] txdeemph,
	input [ 0:0 ] txdetectrxloopback,
	input [ 0:0 ] txelecidle,
	input [ 2:0 ] txmargin,
	input [ 0:0 ] txpmaclk,
	input [ 0:0 ] txpmasyncphip,
	input [ 0:0 ] txrstn,
	input [ 0:0 ] txswing,
	input [ 1:0 ] txsynchdr,
	output [ 15:0 ] avmmreaddata,
	output [ 0:0 ] blockselect,
	output [ 10:0 ] bundlingoutdown,
	output [ 10:0 ] bundlingoutup,
	output [ 0:0 ] dispcbyte,
	output [ 0:0 ] gen3clksel,
	output [ 0:0 ] gen3datasel,
	output [ 0:0 ] inferredrxvalidint,
	output [ 0:0 ] masktxpll,
	output [ 0:0 ] pcsrst,
	output [ 0:0 ] phystatus,
	output [ 17:0 ] pmacurrentcoeff,
	output [ 2:0 ] pmacurrentrxpreset,
	output [ 0:0 ] pmaearlyeios,
	output [ 0:0 ] pmaltr,
	output [ 1:0 ] pmapcieswitch,
	output [ 0:0 ] pmarxdetpd,
	output [ 0:0 ] pmatxdeemph,
	output [ 0:0 ] pmatxdetectrx,
	output [ 0:0 ] pmatxelecidle,
	output [ 2:0 ] pmatxmargin,
	output [ 0:0 ] pmatxswing,
	output [ 0:0 ] ppmcntrst8gpcsout,
	output [ 0:0 ] ppmeidleexit,
	output [ 0:0 ] resetpcprts,
	output [ 0:0 ] revlpbk8gpcsout,
	output [ 0:0 ] revlpbkint,
	output [ 3:0 ] rxblkstart,
	output [ 63:0 ] rxd8gpcsout,
	output [ 3:0 ] rxdataskip,
	output [ 0:0 ] rxelecidle,
	output [ 0:0 ] rxpolarity8gpcsout,
	output [ 0:0 ] rxpolarityint,
	output [ 2:0 ] rxstatus,
	output [ 1:0 ] rxsynchdr,
	output [ 0:0 ] rxvalid,
	output [ 0:0 ] shutdownclk,
	output [ 18:0 ] testinfei,
	output [ 19:0 ] testout,
	output [ 0:0 ] txblkstartint,
	output [ 31:0 ] txdataint,
	output [ 3:0 ] txdatakint,
	output [ 0:0 ] txdataskipint,
	output [ 0:0 ] txpmasyncp,
	output [ 1:0 ] txsynchdrint
); 

	stratixv_hssi_pipe_gen3_encrypted 
	#(
		.enable_debug_info(enable_debug_info),

		.mode(mode),
		.ctrl_plane_bonding(ctrl_plane_bonding),
		.pipe_clk_sel(pipe_clk_sel),
		.rate_match_pad_insertion(rate_match_pad_insertion),
		.ind_error_reporting(ind_error_reporting),
		.phystatus_rst_toggle_g3(phystatus_rst_toggle_g3),
		.phystatus_rst_toggle_g12(phystatus_rst_toggle_g12),
		.cdr_control(cdr_control),
		.cid_enable(cid_enable),
		.parity_chk_ts1(parity_chk_ts1),
		.rxvalid_mask(rxvalid_mask),
		.ph_fifo_reg_mode(ph_fifo_reg_mode),
		.test_mode_timers(test_mode_timers),
		.inf_ei_enable(inf_ei_enable),
		.spd_chnge_g2_sel(spd_chnge_g2_sel),
		.cp_up_mstr(cp_up_mstr),
		.cp_dwn_mstr(cp_dwn_mstr),
		.cp_cons_sel(cp_cons_sel),
		.elecidle_delay_g3_data(elecidle_delay_g3_data),
		.elecidle_delay_g3(elecidle_delay_g3),
		.phy_status_delay_g12_data(phy_status_delay_g12_data),
		.phy_status_delay_g12(phy_status_delay_g12),
		.phy_status_delay_g3_data(phy_status_delay_g3_data),
		.phy_status_delay_g3(phy_status_delay_g3),
		.sigdet_wait_counter_data(sigdet_wait_counter_data),
		.sigdet_wait_counter(sigdet_wait_counter),
		.data_mask_count_val(data_mask_count_val),
		.data_mask_count(data_mask_count),
		.pma_done_counter_data(pma_done_counter_data),
		.pma_done_counter(pma_done_counter),
		.pc_en_counter_data(pc_en_counter_data),
		.pc_en_counter(pc_en_counter),
		.pc_rst_counter_data(pc_rst_counter_data),
		.pc_rst_counter(pc_rst_counter),
		.phfifo_flush_wait_data(phfifo_flush_wait_data),
		.phfifo_flush_wait(phfifo_flush_wait),
		.asn_clk_enable(asn_clk_enable),
		.free_run_clk_enable(free_run_clk_enable),
		.asn_enable(asn_enable),
		.bypass_send_syncp_fbkp(bypass_send_syncp_fbkp),
		.wait_send_syncp_fbkp_data(wait_send_syncp_fbkp_data),
		.wait_clk_on_off_timer_data(wait_clk_on_off_timer_data),
		.wait_clk_on_off_timer(wait_clk_on_off_timer),
		.wait_send_syncp_fbkp(wait_send_syncp_fbkp),
		.wait_pipe_synchronizing(wait_pipe_synchronizing),
		.bypass_pma_sw_done(bypass_pma_sw_done),
		.test_out_sel(test_out_sel),
		.wait_pipe_synchronizing_data(wait_pipe_synchronizing_data),
		.sup_mode(sup_mode),
		.avmm_group_channel_index(avmm_group_channel_index),
		.use_default_base_address(use_default_base_address),
		.user_base_address(user_base_address),
		.bypass_rx_preset_enable(bypass_rx_preset_enable),
		.bypass_tx_coefficent(bypass_tx_coefficent),
		.bypass_rx_preset_data(bypass_rx_preset_data),
		.bypass_tx_coefficent_enable(bypass_tx_coefficent_enable),
		.bypass_tx_coefficent_data(bypass_tx_coefficent_data),
		.bypass_rx_preset(bypass_rx_preset),
		.bypass_rx_detection_enable(bypass_rx_detection_enable)

	)
	stratixv_hssi_pipe_gen3_encrypted_inst	(
		.avmmaddress(avmmaddress),
		.avmmbyteen(avmmbyteen),
		.avmmclk(avmmclk),
		.avmmread(avmmread),
		.avmmrstn(avmmrstn),
		.avmmwrite(avmmwrite),
		.avmmwritedata(avmmwritedata),
		.blkalgndint(blkalgndint),
		.bundlingindown(bundlingindown),
		.bundlinginup(bundlinginup),
		.clkcompdeleteint(clkcompdeleteint),
		.clkcompinsertint(clkcompinsertint),
		.clkcompoverflint(clkcompoverflint),
		.clkcompundflint(clkcompundflint),
		.currentcoeff(currentcoeff),
		.currentrxpreset(currentrxpreset),
		.eidetint(eidetint),
		.eidleinfersel(eidleinfersel),
		.eipartialdetint(eipartialdetint),
		.errdecodeint(errdecodeint),
		.errencodeint(errencodeint),
		.hardresetn(hardresetn),
		.idetint(idetint),
		.pldltr(pldltr),
		.pllfixedclk(pllfixedclk),
		.pmapcieswdone(pmapcieswdone),
		.pmarxdetectvalid(pmarxdetectvalid),
		.pmarxfound(pmarxfound),
		.pmasignaldet(pmasignaldet),
		.powerdown(powerdown),
		.rate(rate),
		.rcvdclk(rcvdclk),
		.rcvlfsrchkint(rcvlfsrchkint),
		.rrxdigclksel(rrxdigclksel),
		.rrxgen3capen(rrxgen3capen),
		.rtxdigclksel(rtxdigclksel),
		.rtxgen3capen(rtxgen3capen),
		.rxblkstartint(rxblkstartint),
		.rxd8gpcsin(rxd8gpcsin),
		.rxdataint(rxdataint),
		.rxdatakint(rxdatakint),
		.rxdataskipint(rxdataskipint),
		.rxelecidle8gpcsin(rxelecidle8gpcsin),
		.rxpolarity(rxpolarity),
		.rxrstn(rxrstn),
		.rxsynchdrint(rxsynchdrint),
		.rxtestout(rxtestout),
		.rxupdatefc(rxupdatefc),
		.scanmoden(scanmoden),
		.speedchangeg2(speedchangeg2),
		.txblkstart(txblkstart),
		.txcompliance(txcompliance),
		.txdata(txdata),
		.txdatak(txdatak),
		.txdataskip(txdataskip),
		.txdeemph(txdeemph),
		.txdetectrxloopback(txdetectrxloopback),
		.txelecidle(txelecidle),
		.txmargin(txmargin),
		.txpmaclk(txpmaclk),
		.txpmasyncphip(txpmasyncphip),
		.txrstn(txrstn),
		.txswing(txswing),
		.txsynchdr(txsynchdr),
		.avmmreaddata(avmmreaddata),
		.blockselect(blockselect),
		.bundlingoutdown(bundlingoutdown),
		.bundlingoutup(bundlingoutup),
		.dispcbyte(dispcbyte),
		.gen3clksel(gen3clksel),
		.gen3datasel(gen3datasel),
		.inferredrxvalidint(inferredrxvalidint),
		.masktxpll(masktxpll),
		.pcsrst(pcsrst),
		.phystatus(phystatus),
		.pmacurrentcoeff(pmacurrentcoeff),
		.pmacurrentrxpreset(pmacurrentrxpreset),
		.pmaearlyeios(pmaearlyeios),
		.pmaltr(pmaltr),
		.pmapcieswitch(pmapcieswitch),
		.pmarxdetpd(pmarxdetpd),
		.pmatxdeemph(pmatxdeemph),
		.pmatxdetectrx(pmatxdetectrx),
		.pmatxelecidle(pmatxelecidle),
		.pmatxmargin(pmatxmargin),
		.pmatxswing(pmatxswing),
		.ppmcntrst8gpcsout(ppmcntrst8gpcsout),
		.ppmeidleexit(ppmeidleexit),
		.resetpcprts(resetpcprts),
		.revlpbk8gpcsout(revlpbk8gpcsout),
		.revlpbkint(revlpbkint),
		.rxblkstart(rxblkstart),
		.rxd8gpcsout(rxd8gpcsout),
		.rxdataskip(rxdataskip),
		.rxelecidle(rxelecidle),
		.rxpolarity8gpcsout(rxpolarity8gpcsout),
		.rxpolarityint(rxpolarityint),
		.rxstatus(rxstatus),
		.rxsynchdr(rxsynchdr),
		.rxvalid(rxvalid),
		.shutdownclk(shutdownclk),
		.testinfei(testinfei),
		.testout(testout),
		.txblkstartint(txblkstartint),
		.txdataint(txdataint),
		.txdatakint(txdatakint),
		.txdataskipint(txdataskipint),
		.txpmasyncp(txpmasyncp),
		.txsynchdrint(txsynchdrint)
	);


endmodule
// --------------------------------------------------------------------
// This is auto-generated HSSI Simulation Atom Model Encryption Wrapper
// Module Name : ./sim_model_wrappers//stratixv_hssi_pma_aux_wrapper.v
// --------------------------------------------------------------------

`timescale 1 ps/1 ps
module stratixv_hssi_pma_aux
#(
	// parameter declaration and default value assignemnt
	parameter enable_debug_info = "false",	//Valid values: false|true; this is simulation-only parameter, for debug purpose only
	parameter continuous_calibration = "false",	//Valid values: false|true
	parameter rx_cal_override_value_enable = "false",	//Valid values: false|true
	parameter rx_cal_override_value = 0,	//Valid values: 0..31
	parameter tx_cal_override_value_enable = "false",	//Valid values: false|true
	parameter tx_cal_override_value = 0,	//Valid values: 0..31
	parameter cal_result_status = "pm_aux_result_status_tx",	//Valid values: pm_aux_result_status_tx|pm_aux_result_status_rx
	parameter rx_imp = "cal_imp_46_ohm",	//Valid values: cal_imp_46_ohm|cal_imp_48_ohm|cal_imp_50_ohm|cal_imp_52_ohm
	parameter tx_imp = "cal_imp_46_ohm",	//Valid values: cal_imp_46_ohm|cal_imp_48_ohm|cal_imp_50_ohm|cal_imp_52_ohm
	parameter test_counter_enable = "false",	//Valid values: false|true
	parameter cal_clk_sel = "pm_aux_iqclk_cal_clk_sel_cal_clk",	//Valid values: pm_aux_iqclk_cal_clk_sel_cal_clk|pm_aux_iqclk_cal_clk_sel_iqclk0|pm_aux_iqclk_cal_clk_sel_iqclk1|pm_aux_iqclk_cal_clk_sel_iqclk2|pm_aux_iqclk_cal_clk_sel_iqclk3|pm_aux_iqclk_cal_clk_sel_iqclk4|pm_aux_iqclk_cal_clk_sel_iqclk5|pm_aux_iqclk_cal_clk_sel_iqclk6|pm_aux_iqclk_cal_clk_sel_iqclk7|pm_aux_iqclk_cal_clk_sel_iqclk8|pm_aux_iqclk_cal_clk_sel_iqclk9|pm_aux_iqclk_cal_clk_sel_iqclk10
	parameter pm_aux_cal_clk_test_sel = 1'b0,	//Valid values: 1
	parameter avmm_group_channel_index = 0,	//Valid values: 0..2
	parameter use_default_base_address = "true",	//Valid values: false|true
	parameter user_base_address = 0	//Valid values: 0..2047
)
(
//input and output port declaration
	input [ 0:0 ] calpdb,
	input [ 0:0 ] calclk,
	input [ 0:0 ] testcntl,
	input [ 10:0 ] refiqclk,
	output [ 0:0 ] nonusertoio,
	output [ 4:0 ] zrxtx50
); 

	stratixv_hssi_pma_aux_encrypted 
	#(
		.enable_debug_info(enable_debug_info),
		.continuous_calibration(continuous_calibration),
		.rx_cal_override_value_enable(rx_cal_override_value_enable),
		.rx_cal_override_value(rx_cal_override_value),
		.tx_cal_override_value_enable(tx_cal_override_value_enable),
		.tx_cal_override_value(tx_cal_override_value),
		.cal_result_status(cal_result_status),
		.rx_imp(rx_imp),
		.tx_imp(tx_imp),
		.test_counter_enable(test_counter_enable),
		.cal_clk_sel(cal_clk_sel),
		.pm_aux_cal_clk_test_sel(pm_aux_cal_clk_test_sel),
		.avmm_group_channel_index(avmm_group_channel_index),
		.use_default_base_address(use_default_base_address),
		.user_base_address(user_base_address)

	)
	stratixv_hssi_pma_aux_encrypted_inst	(
		.calpdb(calpdb),
		.calclk(calclk),
		.testcntl(testcntl),
		.refiqclk(refiqclk),
		.nonusertoio(nonusertoio),
		.zrxtx50(zrxtx50)
	);


endmodule
`timescale 1 ps/1 ps

module    stratixv_hssi_pma_cdr_refclk_select_mux    (
    calclk,
    ffplloutbot,
    ffpllouttop,
    pldclk,
    refiqclk0,
    refiqclk1,
    refiqclk10,
    refiqclk2,
    refiqclk3,
    refiqclk4,
    refiqclk5,
    refiqclk6,
    refiqclk7,
    refiqclk8,
    refiqclk9,
    rxiqclk0,
    rxiqclk1,
    rxiqclk10,
    rxiqclk2,
    rxiqclk3,
    rxiqclk4,
    rxiqclk5,
    rxiqclk6,
    rxiqclk7,
    rxiqclk8,
    rxiqclk9,
    avmmclk,
    avmmrstn,
    avmmwrite,
    avmmread,
    avmmbyteen,
    avmmaddress,
    avmmwritedata,
    avmmreaddata,
    blockselect,
    clkout);

    parameter    lpm_type    =    "stratixv_hssi_pma_cdr_refclk_select_mux";
    parameter    channel_number    =    0;
      // the mux_type parameter is used for dynamic reconfiguration
   // support. It specifies whethter this mux should listen to the
   // DPRIO memory space for the CDR REF CLK mux or for the LC REF CLK
   // mux
parameter mux_type = "cdr_refclk_select_mux"; // cdr_refclk_select_mux|lc_refclk_select_mux

    parameter    refclk_select    =    "ref_iqclk0";
    parameter    reference_clock_frequency    =    "0 ps";
    parameter    avmm_group_channel_index = 0;
    parameter    use_default_base_address = "true";
    parameter    user_base_address = 0;

   parameter inclk0_logical_to_physical_mapping = "";
parameter inclk1_logical_to_physical_mapping = "";
parameter inclk2_logical_to_physical_mapping = "";
parameter inclk3_logical_to_physical_mapping = "";
parameter inclk4_logical_to_physical_mapping = "";
parameter inclk5_logical_to_physical_mapping = "";
parameter inclk6_logical_to_physical_mapping = "";
parameter inclk7_logical_to_physical_mapping = "";
parameter inclk8_logical_to_physical_mapping = "";
parameter inclk9_logical_to_physical_mapping = "";
parameter inclk10_logical_to_physical_mapping = "";
parameter inclk11_logical_to_physical_mapping = "";
parameter inclk12_logical_to_physical_mapping = "";
parameter inclk13_logical_to_physical_mapping = "";
parameter inclk14_logical_to_physical_mapping = "";
parameter inclk15_logical_to_physical_mapping = "";
parameter inclk16_logical_to_physical_mapping = "";
parameter inclk17_logical_to_physical_mapping = "";
parameter inclk18_logical_to_physical_mapping = "";
parameter inclk19_logical_to_physical_mapping = "";
parameter inclk20_logical_to_physical_mapping = "";
parameter inclk21_logical_to_physical_mapping = "";
parameter inclk22_logical_to_physical_mapping = "";
parameter inclk23_logical_to_physical_mapping = "";
parameter inclk24_logical_to_physical_mapping = "";
parameter inclk25_logical_to_physical_mapping = "";
   



    input         calclk;
    input         ffplloutbot;
    input         ffpllouttop;
    input         pldclk;
    input         refiqclk0;
    input         refiqclk1;
    input         refiqclk10;
    input         refiqclk2;
    input         refiqclk3;
    input         refiqclk4;
    input         refiqclk5;
    input         refiqclk6;
    input         refiqclk7;
    input         refiqclk8;
    input         refiqclk9;
    input         rxiqclk0;
    input         rxiqclk1;
    input         rxiqclk10;
    input         rxiqclk2;
    input         rxiqclk3;
    input         rxiqclk4;
    input         rxiqclk5;
    input         rxiqclk6;
    input         rxiqclk7;
    input         rxiqclk8;
    input         rxiqclk9;
    input         avmmclk;
    input         avmmrstn;
    input         avmmwrite;
    input         avmmread;
    input  [ 1:0] avmmbyteen;
    input  [10:0] avmmaddress;
    input  [15:0] avmmwritedata;
    output [15:0] avmmreaddata;
    output        blockselect;
    output        clkout;

    stratixv_hssi_pma_cdr_refclk_select_mux_encrypted inst (
        .calclk(calclk),
        .ffplloutbot(ffplloutbot),
        .ffpllouttop(ffpllouttop),
        .pldclk(pldclk),
        .refiqclk0(refiqclk0),
        .refiqclk1(refiqclk1),
        .refiqclk10(refiqclk10),
        .refiqclk2(refiqclk2),
        .refiqclk3(refiqclk3),
        .refiqclk4(refiqclk4),
        .refiqclk5(refiqclk5),
        .refiqclk6(refiqclk6),
        .refiqclk7(refiqclk7),
        .refiqclk8(refiqclk8),
        .refiqclk9(refiqclk9),
        .rxiqclk0(rxiqclk0),
        .rxiqclk1(rxiqclk1),
        .rxiqclk10(rxiqclk10),
        .rxiqclk2(rxiqclk2),
        .rxiqclk3(rxiqclk3),
        .rxiqclk4(rxiqclk4),
        .rxiqclk5(rxiqclk5),
        .rxiqclk6(rxiqclk6),
        .rxiqclk7(rxiqclk7),
        .rxiqclk8(rxiqclk8),
        .rxiqclk9(rxiqclk9),
	.avmmclk(avmmclk),
	.avmmrstn(avmmrstn),
	.avmmwrite(avmmwrite),
	.avmmread(avmmread),
	.avmmbyteen(avmmbyteen),
	.avmmaddress(avmmaddress),
	.avmmwritedata(avmmwritedata),
	.avmmreaddata(avmmreaddata),
	.blockselect(blockselect),
        .clkout(clkout) );
    defparam inst.lpm_type = lpm_type;
    defparam inst.channel_number = channel_number;
    defparam inst.refclk_select = refclk_select;
    defparam inst.reference_clock_frequency = reference_clock_frequency;
    defparam inst.avmm_group_channel_index = avmm_group_channel_index;
    defparam inst.use_default_base_address = use_default_base_address;
    defparam inst.user_base_address = user_base_address;
   defparam inst.inclk0_logical_to_physical_mapping = inclk0_logical_to_physical_mapping;
      defparam inst.inclk1_logical_to_physical_mapping = inclk1_logical_to_physical_mapping;
      defparam inst.inclk2_logical_to_physical_mapping = inclk2_logical_to_physical_mapping;
      defparam inst.inclk3_logical_to_physical_mapping = inclk3_logical_to_physical_mapping;
      defparam inst.inclk4_logical_to_physical_mapping = inclk4_logical_to_physical_mapping;
      defparam inst.inclk5_logical_to_physical_mapping = inclk5_logical_to_physical_mapping;
      defparam inst.inclk6_logical_to_physical_mapping = inclk6_logical_to_physical_mapping;
      defparam inst.inclk7_logical_to_physical_mapping = inclk7_logical_to_physical_mapping;
      defparam inst.inclk8_logical_to_physical_mapping = inclk8_logical_to_physical_mapping;
      defparam inst.inclk9_logical_to_physical_mapping = inclk9_logical_to_physical_mapping;
      defparam inst.inclk10_logical_to_physical_mapping = inclk10_logical_to_physical_mapping;
      defparam inst.inclk11_logical_to_physical_mapping = inclk11_logical_to_physical_mapping;
      defparam inst.inclk12_logical_to_physical_mapping = inclk12_logical_to_physical_mapping;
      defparam inst.inclk13_logical_to_physical_mapping = inclk13_logical_to_physical_mapping;
   // need to add assignment for the rest of the parameter assignments
   

endmodule //stratixv_hssi_pma_cdr_refclk_select_mux

`timescale 1 ps/1 ps

module stratixv_hssi_pma_hi_pmaif
  #(
    parameter lpm_type = "stratixv_hssi_pma_hi_pmaif",
    parameter tx_pma_direction_sel = "pcs"    // valid values pcs|core
  )    
  (
   input [79:0] datainfromcore,
   input [79:0] datainfrompcs,
   output [79:0] dataouttopma

   // ... avmm and block select ports go here ...

   );

    stratixv_hssi_pma_hi_pmaif_encrypted 
    # (
    .tx_pma_direction_sel("pcs")    // valid values pcs|core
    )
    inst (
   .datainfromcore(datainfromcore),
   .datainfrompcs(datainfrompcs),
   .dataouttopma(dataouttopma)
   );

endmodule // hi_pmaif
`timescale 1 ps/1 ps

module stratixv_hssi_pma_hi_xcvrif
  #(
    parameter lpm_type = "stratixv_hssi_pma_hi_xcvrif",
    parameter rx_pma_direction_sel = "pcs"    // valid values pcs|core
    )
  (
   input  [79:0] datainfrompma,
   input  [79:0] datainfrompcs,
   output [79:0] dataouttopld

   // ... avmm and block select ports go here ...

   );

    stratixv_hssi_pma_hi_xcvrif_encrypted 
    # (
    .rx_pma_direction_sel("pcs")    // valid values pcs|core
    )
    inst (
   .datainfrompma(datainfrompma),
   .datainfrompcs(datainfrompcs),
   .dataouttopld(dataouttopld)
   );

endmodule // hi_pmaif
// --------------------------------------------------------------------
// This is auto-generated HSSI Simulation Atom Model Encryption Wrapper
// Module Name : ./sim_model_wrappers//stratixv_hssi_pma_rx_buf_wrapper.v
// --------------------------------------------------------------------

`timescale 1 ps/1 ps
module stratixv_hssi_pma_rx_buf
#(
	// parameter declaration and default value assignemnt
	parameter enable_debug_info = "false",	//Valid values: false|true; this is simulation-only parameter, for debug purpose only

	parameter channel_number = 0,	//Valid values: 0..65
	parameter eq_bw_sel = "bw_full_12p5",	//Valid values: bw_full_12p5|bw_half_6p5
	parameter input_vcm_sel = "high_vcm",	//Valid values: low_vcm|high_vcm
	parameter pdb_sd = "false",	//Valid values: false|true
	parameter qpi_enable = "false",	//Valid values: false|true
	parameter rx_dc_gain = 0,	//Valid values: 0..4
	parameter rx_sel_bias_source = "bias_vcmdrv",	//Valid values: bias_vcmdrv|bias_int
	parameter sd_off = 0,	//Valid values: 0..29
	parameter sd_on = 0,	//Valid values: 0..16
	parameter sd_threshold = 0,	//Valid values: 0..7
	parameter serial_loopback = "lpbkp_dis",	//Valid values: lpbkp_dis|lpbkp_en_sel_data_slew1|lpbkp_en_sel_data_slew2|lpbkp_en_sel_data_slew3|lpbkp_en_sel_data_slew4|lpbkp_en_sel_refclk|lpbkp_unused
	parameter term_sel = "int_100ohm",	//Valid values: int_150ohm|int_120ohm|int_100ohm|int_85ohm|ext_res
	parameter vccela_supply_voltage = "vccela_1p0v",	//Valid values: vccela_1p0v|vccela_0p85v
	parameter avmm_group_channel_index = 0,	//Valid values: 0..2
	parameter use_default_base_address = "true",	//Valid values: false|true
	parameter user_base_address = 0,	//Valid values: 0..2047
	parameter bypass_eqz_stages_234 = "all_stages_enabled",	//Valid values: all_stages_enabled|byypass_stages_234
	parameter cdrclk_to_cgb = "cdrclk_2cgb_dis",	//Valid values: cdrclk_2cgb_dis|cdrclk_2cgb_en
	parameter diagnostic_loopback = "diag_lpbk_off",	//Valid values: diag_lpbk_on|diag_lpbk_off
	parameter pmos_gain_peak = "eqzp_en_peaking",	//Valid values: eqzp_dis_peaking|eqzp_en_peaking
	parameter vcm_current_add = "vcm_current_default",	//Valid values: vcm_current_default|vcm_current_1|vcm_current_2|vcm_current_3
	parameter vcm_sel = "vtt_0p70v",	//Valid values: vtt_0p80v|vtt_0p75v|vtt_0p70v|vtt_0p65v|vtt_0p60v|vtt_0p55v|vtt_0p50v|vtt_0p35v|vtt_pup_weak|vtt_pdn_weak|tristate1|vtt_pdn_strong|vtt_pup_strong|tristate2|tristate3|tristate4
	parameter cdr_clock_enable = "true",	//Valid values: false|true
	parameter ct_equalizer_setting = 1,	//Valid values: 1..16
	parameter enable_rx_gainctrl_pciemode = "false"	//Valid values: false|true
)
(
//input and output port declaration
        input [ 0:0 ] occlk,
	input [ 0:0 ] voplp,
	input [ 0:0 ] vonlp,
	output [ 0:0 ] dataout,
	input [ 0:0 ] ck0sigdet,
	input [ 0:0 ] lpbkp,
	input [ 0:0 ] rstn,
	input [ 0:0 ] hardoccalen,
	input [ 0:0 ] datain,
	input [ 0:0 ] slpbk,
	input [ 0:0 ] rxqpipulldn,
	output [ 0:0 ] rdlpbkp,
	output [ 0:0 ] sd,
	input [ 0:0 ] nonuserfrompmaux,
	input [ 0:0 ] adaptcapture,
	output [ 0:0 ] adaptdone,
	input [ 0:0 ] adcestandby,
	output [ 0:0 ] hardoccaldone,
	input [ 4:0 ] eyemonitor,
	input [ 0:0 ] lpbkn,
	output [ 0:0 ] rxrefclk,
	output [ 0:0 ] rdlpbkn,
	input [ 0:0 ] avmmrstn,
	input [ 0:0 ] avmmclk,
	input [ 0:0 ] avmmwrite,
	input [ 0:0 ] avmmread,
	input [ 1:0 ] avmmbyteen,
	input [ 10:0 ] avmmaddress,
	input [ 15:0 ] avmmwritedata,
	output [ 15:0 ] avmmreaddata,
	output [ 0:0 ] blockselect
); 

	stratixv_hssi_pma_rx_buf_encrypted 
	#(
		.enable_debug_info(enable_debug_info),

		.channel_number(channel_number),
		.eq_bw_sel(eq_bw_sel),
		.input_vcm_sel(input_vcm_sel),
		.pdb_sd(pdb_sd),
		.qpi_enable(qpi_enable),
		.rx_dc_gain(rx_dc_gain),
		.rx_sel_bias_source(rx_sel_bias_source),
		.sd_off(sd_off),
		.sd_on(sd_on),
		.sd_threshold(sd_threshold),
		.serial_loopback(serial_loopback),
		.term_sel(term_sel),
		.vccela_supply_voltage(vccela_supply_voltage),
		.avmm_group_channel_index(avmm_group_channel_index),
		.use_default_base_address(use_default_base_address),
		.user_base_address(user_base_address),
		.bypass_eqz_stages_234(bypass_eqz_stages_234),
		.cdrclk_to_cgb(cdrclk_to_cgb),
		.diagnostic_loopback(diagnostic_loopback),
		.pmos_gain_peak(pmos_gain_peak),
		.vcm_current_add(vcm_current_add),
		.vcm_sel(vcm_sel),
		.cdr_clock_enable(cdr_clock_enable),
		.ct_equalizer_setting(ct_equalizer_setting),
		.enable_rx_gainctrl_pciemode(enable_rx_gainctrl_pciemode)

	)
	stratixv_hssi_pma_rx_buf_encrypted_inst	(
		.occlk(occlk),				 
		.voplp(voplp),
		.vonlp(vonlp),
		.dataout(dataout),
		.ck0sigdet(ck0sigdet),
		.lpbkp(lpbkp),
		.rstn(rstn),
		.hardoccalen(hardoccalen),
		.datain(datain),
		.slpbk(slpbk),
		.rxqpipulldn(rxqpipulldn),
		.rdlpbkp(rdlpbkp),
		.sd(sd),
		.nonuserfrompmaux(nonuserfrompmaux),
		.adaptcapture(adaptcapture),
		.adaptdone(adaptdone),
		.adcestandby(adcestandby),
		.hardoccaldone(hardoccaldone),
		.eyemonitor(eyemonitor),
		.lpbkn(lpbkn),
		.rxrefclk(rxrefclk),
		.rdlpbkn(rdlpbkn),
		.avmmrstn(avmmrstn),
		.avmmclk(avmmclk),
		.avmmwrite(avmmwrite),
		.avmmread(avmmread),
		.avmmbyteen(avmmbyteen),
		.avmmaddress(avmmaddress),
		.avmmwritedata(avmmwritedata),
		.avmmreaddata(avmmreaddata),
		.blockselect(blockselect)
	);


endmodule
// --------------------------------------------------------------------
// This is auto-generated HSSI Simulation Atom Model Encryption Wrapper
// Module Name : ./sim_model_wrappers//stratixv_hssi_pma_rx_deser_wrapper.v
// --------------------------------------------------------------------

`timescale 1 ps/1 ps
module stratixv_hssi_pma_rx_deser
#(
	// parameter declaration and default value assignemnt
	parameter enable_debug_info = "false",	//Valid values: false|true; this is simulation-only parameter, for debug purpose only

	parameter mode = 8,	//Valid values: 8|10|16|20|32|40|64|80
	parameter auto_negotiation = "false",	//Valid values: false|true
	parameter enable_bit_slip = "false",	//Valid values: false|true
	parameter vco_bypass = "vco_bypass_normal",	//Valid values: vco_bypass_normal|clklow_to_clkdivrx|fref_to_clkdivrx
	parameter sdclk_enable = "true",	//Valid values: false|true
	parameter channel_number = 0,	//Valid values: 0..65
	parameter clk_forward_only_mode = "false",	//Valid values: false|true
	parameter deser_div33_enable = "true",	//Valid values: true|false
	parameter avmm_group_channel_index = 0,	//Valid values: 0..2
	parameter use_default_base_address = "true",	//Valid values: false|true
	parameter user_base_address = 0	//Valid values: 0..2047
)
(
//input and output port declaration
	input [ 0:0 ] bslip,
	input [ 0:0 ] deven,
	input [ 0:0 ] dodd,
	input [ 1:0 ] pciesw,
	input [ 0:0 ] clk90b,
	input [ 0:0 ] clk270b,
	input [ 0:0 ] pfdmodelock,
	input [ 0:0 ] fref,
	input [ 0:0 ] clklow,
	input [ 0:0 ] rstn,
	output [ 0:0 ] clk33pcs,
	output [ 0:0 ] clkdivrx,
	output [ 0:0 ] pciel,
	output [ 0:0 ] pciem,
	output [ 0:0 ] clkdivrxrx,
	output [ 79:0 ] dout,
	input [ 0:0 ] avmmrstn,
	input [ 0:0 ] avmmclk,
	input [ 0:0 ] avmmwrite,
	input [ 0:0 ] avmmread,
	input [ 1:0 ] avmmbyteen,
	input [ 10:0 ] avmmaddress,
	input [ 15:0 ] avmmwritedata,
	output [ 15:0 ] avmmreaddata,
	output [ 0:0 ] blockselect
); 

	stratixv_hssi_pma_rx_deser_encrypted 
	#(
		.enable_debug_info(enable_debug_info),

		.mode(mode),
		.auto_negotiation(auto_negotiation),
		.enable_bit_slip(enable_bit_slip),
		.vco_bypass(vco_bypass),
		.sdclk_enable(sdclk_enable),
		.channel_number(channel_number),
		.clk_forward_only_mode(clk_forward_only_mode),
		.deser_div33_enable(deser_div33_enable),
		.avmm_group_channel_index(avmm_group_channel_index),
		.use_default_base_address(use_default_base_address),
		.user_base_address(user_base_address)

	)
	stratixv_hssi_pma_rx_deser_encrypted_inst	(
		.bslip(bslip),
		.deven(deven),
		.dodd(dodd),
		.pciesw(pciesw),
		.clk90b(clk90b),
		.clk270b(clk270b),
		.pfdmodelock(pfdmodelock),
		.fref(fref),
		.clklow(clklow),
		.rstn(rstn),
		.clk33pcs(clk33pcs),
		.clkdivrx(clkdivrx),
		.pciel(pciel),
		.pciem(pciem),
		.clkdivrxrx(clkdivrxrx),
		.dout(dout),
		.avmmrstn(avmmrstn),
		.avmmclk(avmmclk),
		.avmmwrite(avmmwrite),
		.avmmread(avmmread),
		.avmmbyteen(avmmbyteen),
		.avmmaddress(avmmaddress),
		.avmmwritedata(avmmwritedata),
		.avmmreaddata(avmmreaddata),
		.blockselect(blockselect)
	);


endmodule
// --------------------------------------------------------------------
// This is auto-generated HSSI Simulation Atom Model Encryption Wrapper
// Module Name : ./sim_model_wrappers//stratixv_hssi_pma_tx_buf_wrapper.v
// --------------------------------------------------------------------

`timescale 1 ps/1 ps
module stratixv_hssi_pma_tx_buf
#(
	// parameter declaration and default value assignemnt
	parameter enable_debug_info = "false",	//Valid values: false|true; this is simulation-only parameter, for debug purpose only

	parameter avmm_group_channel_index = 0,	//Valid values: 0..2
	parameter use_default_base_address = "true",	//Valid values: false|true
	parameter user_base_address = 0,	//Valid values: 0..2047
	parameter pre_emp_switching_ctrl_1st_post_tap = 0,	//Valid values: 0..31
	parameter pre_emp_switching_ctrl_2nd_post_tap = 0,	//Valid values: 0..15
	parameter pre_emp_switching_ctrl_pre_tap = 0,	//Valid values: 0..15
	parameter qpi_en = "false",	//Valid values: false|true
	parameter rx_det = 0,	//Valid values: 0..15
	parameter rx_det_pdb = "true",	//Valid values: false|true
	parameter sig_inv_2nd_tap = "false",	//Valid values: false|true
	parameter sig_inv_pre_tap = "false",	//Valid values: false|true
	parameter term_sel = "int_100ohm",	//Valid values: int_150ohm|int_120ohm|int_100ohm|int_85ohm|ext_res
	parameter vod_switching_ctrl_main_tap = 0,	//Valid values: 0..63
	parameter channel_number = 0,	//Valid values: 0..65
	parameter dft_sel = "disabled",	//Valid values: vod_en_lsb|vod_en_msb|po1_en|disabled|pre_en_po2_en
	parameter common_mode_driver_sel = "volt_0p65v",	//Valid values: volt_0p80v|volt_0p75v|volt_0p70v|volt_0p65v|volt_0p60v|volt_0p55v|volt_0p50v|volt_0p35v|pull_up|pull_dn|tristated1|grounded|pull_up_to_vccela|tristated2|tristated3|tristated4
	parameter driver_resolution_ctrl = "disabled",	//Valid values: offset_main|offset_po1|conbination1|disabled|offset_pre|conbination2|conbination3|conbination4|half_resolution|conbination5|conbination6|conbination7|conbination8|conbination9|conbination10|conbination11
	parameter local_ib_ctl = "ib_29ohm",	//Valid values: ib_49ohm|ib_29ohm|ib_42ohm|ib_22ohm
	parameter rx_det_output_sel = "rx_det_pcie_out",	//Valid values: rx_det_qpi_out|rx_det_pcie_out
	parameter slew_rate_ctrl = 1,	//Valid values: 1..5
	parameter swing_boost = "not_boost",	//Valid values: not_boost|boost
	parameter vcm_ctrl_sel = "ram_ctl",	//Valid values: ram_ctl|dynamic_ctl
	parameter vcm_current_addl = "vcm_current_default",	//Valid values: vcm_current_default|vcm_current_1|vcm_current_2|vcm_current_3
	parameter vod_boost = "not_boost",	//Valid values: not_boost|boost
	parameter fir_coeff_ctrl_sel = "ram_ctl",	//Valid values: dynamic_ctl|ram_ctl
	parameter vccela_supply_voltage = "vccela_1p0v"	//Valid values: vccela_1p0v|vccela_0p85	
)
(
//input and output port declaration
	input [ 0:0 ] nonuserfrompmaux,
	input [ 0:0 ] rxdetclk,
	input [ 0:0 ] txdetrx,
	input [ 0:0 ] txelecidl,
	input [ 0:0 ] datain,
	input [ 0:0 ] txqpipullup,
	input [ 0:0 ] txqpipulldn,
	output [ 0:0 ] fixedclkout,
	output [ 0:0 ] rxdetectvalid,
	output [ 0:0 ] rxfound,
	output [ 0:0 ] dataout,
	input [ 0:0 ] vrlpbkn,
	input [ 0:0 ] vrlpbkp,
	input [ 0:0 ] vrlpbkp1t,
	input [ 0:0 ] vrlpbkn1t,
	input [ 17:0 ] icoeff,
	input [ 0:0 ] avmmrstn,
	input [ 0:0 ] avmmclk,
	input [ 0:0 ] avmmwrite,
	input [ 0:0 ] avmmread,
	input [ 1:0 ] avmmbyteen,
	input [ 10:0 ] avmmaddress,
	input [ 15:0 ] avmmwritedata,
	output [ 15:0 ] avmmreaddata,
	output [ 0:0 ] blockselect
); 

	stratixv_hssi_pma_tx_buf_encrypted 
	#(
		.enable_debug_info(enable_debug_info),

		.avmm_group_channel_index(avmm_group_channel_index),
		.use_default_base_address(use_default_base_address),
		.user_base_address(user_base_address),
		.pre_emp_switching_ctrl_1st_post_tap(pre_emp_switching_ctrl_1st_post_tap),
		.pre_emp_switching_ctrl_2nd_post_tap(pre_emp_switching_ctrl_2nd_post_tap),
		.pre_emp_switching_ctrl_pre_tap(pre_emp_switching_ctrl_pre_tap),
		.qpi_en(qpi_en),
		.rx_det(rx_det),
		.rx_det_pdb(rx_det_pdb),
		.sig_inv_2nd_tap(sig_inv_2nd_tap),
		.sig_inv_pre_tap(sig_inv_pre_tap),
		.term_sel(term_sel),
		.vod_switching_ctrl_main_tap(vod_switching_ctrl_main_tap),
		.channel_number(channel_number),
		.dft_sel(dft_sel),
		.common_mode_driver_sel(common_mode_driver_sel),
		.driver_resolution_ctrl(driver_resolution_ctrl),
		.local_ib_ctl(local_ib_ctl),
		.rx_det_output_sel(rx_det_output_sel),
		.slew_rate_ctrl(slew_rate_ctrl),
		.swing_boost(swing_boost),
		.vcm_ctrl_sel(vcm_ctrl_sel),
		.vcm_current_addl(vcm_current_addl),
		.vod_boost(vod_boost),
		.fir_coeff_ctrl_sel(fir_coeff_ctrl_sel),
		.vccela_supply_voltage(vccela_supply_voltage)		
	)
	stratixv_hssi_pma_tx_buf_encrypted_inst	(
		.nonuserfrompmaux(nonuserfrompmaux),
		.rxdetclk(rxdetclk),
		.txdetrx(txdetrx),
		.txelecidl(txelecidl),
		.datain(datain),
		.txqpipullup(txqpipullup),
		.txqpipulldn(txqpipulldn),
		.fixedclkout(fixedclkout),
		.rxdetectvalid(rxdetectvalid),
		.rxfound(rxfound),
		.dataout(dataout),
		.vrlpbkn(vrlpbkn),
		.vrlpbkp(vrlpbkp),
		.vrlpbkp1t(vrlpbkp1t),
		.vrlpbkn1t(vrlpbkn1t),
		.icoeff(icoeff),
		.avmmrstn(avmmrstn),
		.avmmclk(avmmclk),
		.avmmwrite(avmmwrite),
		.avmmread(avmmread),
		.avmmbyteen(avmmbyteen),
		.avmmaddress(avmmaddress),
		.avmmwritedata(avmmwritedata),
		.avmmreaddata(avmmreaddata),
		.blockselect(blockselect)
	);


endmodule
// --------------------------------------------------------------------
// This is auto-generated HSSI Simulation Atom Model Encryption Wrapper
// Module Name : ./sim_model_wrappers//stratixv_hssi_pma_tx_cgb_wrapper.v
// --------------------------------------------------------------------

`timescale 1 ps/1 ps
module stratixv_hssi_pma_tx_cgb
#(
	// parameter declaration and default value assignemnt
	parameter enable_debug_info = "false",	//Valid values: false|true; this is simulation-only parameter, for debug purpose only

	parameter auto_negotiation = "false",	//Valid values: false|true
	parameter mode = 8,	//Valid values: 8|10|16|20|32|40|64|80
	parameter x1_clock_source_sel = "x1_clk_unused",	//Valid values: up_segmented|down_segmented|ffpll|ch1_txpll_t|ch1_txpll_b|same_ch_txpll|hfclk_xn_up|hfclk_ch1_x6_dn|hfclk_xn_dn|hfclk_ch1_x6_up|lcpll_top|lcpll_bottom|up_segmented_g2_ch1_txpll_b_g3|up_segmented_g2_same_ch_txpll_g3|up_segmented_g2_lcpll_top_g3|up_segmented_g2_lcpll_bottom_g3|down_segmented_g2_ch1_txpll_b_g3|down_segmented_g2_same_ch_txpll_g3|down_segmented_g2_lcpll_top_g3|down_segmented_g2_lcpll_bottom_g3|ch1_txpll_t_g2_ch1_txpll_b_g3|ch1_txpll_t_g2_same_ch_txpll_g3|ch1_txpll_t_g2_lcpll_top_g3|ch1_txpll_t_g2_lcpll_bottom_g3|ch1_txpll_b_g2_ch1_txpll_t_g3|ch1_txpll_b_g2_lcpll_top_g3|ch1_txpll_b_g2_lcpll_bottom_g3|hfclk_xn_up_g2_ch1_txpll_t_g3|hfclk_xn_up_g2_lcpll_top_g3|hfclk_xn_up_g2_lcpll_bottom_g3|hfclk_ch1_x6_dn_g2_ch1_txpll_t_g3|hfclk_ch1_x6_dn_g2_lcpll_top_g3|hfclk_ch1_x6_dn_g2_lcpll_bottom_g3|hfclk_xn_dn_g2_ch1_txpll_t_g3|hfclk_xn_dn_g2_lcpll_top_g3|hfclk_xn_dn_g2_lcpll_bottom_g3|hfclk_ch1_x6_up_g2_ch1_txpll_t_g3|hfclk_ch1_x6_up_g2_lcpll_top_g3|hfclk_ch1_x6_up_g2_lcpll_bottom_g3|same_ch_txpll_g2_ch1_txpll_t_g3|same_ch_txpll_g2_lcpll_top_g3|same_ch_txpll_g2_lcpll_bottom_g3|lcpll_top_g2_ch1_txpll_t_g3|lcpll_top_g2_ch1_txpll_b_g3|lcpll_top_g2_same_ch_txpll_g3|lcpll_top_g2_lcpll_bottom_g3|lcpll_bottom_g2_ch1_txpll_t_g3|lcpll_bottom_g2_ch1_txpll_b_g3|lcpll_bottom_g2_same_ch_txpll_g3|lcpll_bottom_g2_lcpll_top_g3|x1_clk_unused
	parameter x1_clock0_logical_to_physical_mapping = "x1_clk_unused",	//Valid values: same_ch_txpll|ch1_txpll_t|ch1_txpll_b|lcpll_top|lcpll_bottom|ffpll|up_segmented|down_segmented|x1_clk_unused
	parameter x1_clock1_logical_to_physical_mapping = "x1_clk_unused",	//Valid values: same_ch_txpll|ch1_txpll_t|ch1_txpll_b|lcpll_top|lcpll_bottom|ffpll|up_segmented|down_segmented|x1_clk_unused
	parameter x1_clock2_logical_to_physical_mapping = "x1_clk_unused",	//Valid values: same_ch_txpll|ch1_txpll_t|ch1_txpll_b|lcpll_top|lcpll_bottom|ffpll|up_segmented|down_segmented|x1_clk_unused
	parameter x1_clock3_logical_to_physical_mapping = "x1_clk_unused",	//Valid values: same_ch_txpll|ch1_txpll_t|ch1_txpll_b|lcpll_top|lcpll_bottom|ffpll|up_segmented|down_segmented|x1_clk_unused
	parameter x1_clock4_logical_to_physical_mapping = "x1_clk_unused",	//Valid values: same_ch_txpll|ch1_txpll_t|ch1_txpll_b|lcpll_top|lcpll_bottom|ffpll|up_segmented|down_segmented|x1_clk_unused
	parameter x1_clock5_logical_to_physical_mapping = "x1_clk_unused",	//Valid values: same_ch_txpll|ch1_txpll_t|ch1_txpll_b|lcpll_top|lcpll_bottom|ffpll|up_segmented|down_segmented|x1_clk_unused
	parameter x1_clock6_logical_to_physical_mapping = "x1_clk_unused",	//Valid values: same_ch_txpll|ch1_txpll_t|ch1_txpll_b|lcpll_top|lcpll_bottom|ffpll|up_segmented|down_segmented|x1_clk_unused
	parameter x1_clock7_logical_to_physical_mapping = "x1_clk_unused",	//Valid values: same_ch_txpll|ch1_txpll_t|ch1_txpll_b|lcpll_top|lcpll_bottom|ffpll|up_segmented|down_segmented|x1_clk_unused
	parameter x1_div_m_sel = 1,	//Valid values: 1|2|4|8
	parameter xn_clock_source_sel = "cgb_xn_unused",	//Valid values: xn_up|ch1_x6_dn|xn_dn|ch1_x6_up|cgb_x1_m_div|cgb_ht|cgb_xn_unused
	parameter channel_number = 0,	//Valid values: 0..255
	parameter data_rate = "",	//Valid values: 
	parameter tx_mux_power_down = "normal",	//Valid values: power_down|normal
	parameter cgb_iqclk_sel = "cgb_x1_n_div",	//Valid values: rx_output|cgb_x1_n_div
	parameter clk_mute = "disable_clockmute",	//Valid values: disable_clockmute|enable_clock_mute|enable_clock_mute_master_channel
	parameter cgb_sync = "normal",	//Valid values: pcs_sync_rst|normal|sync_rst
	parameter reset_scheme = "non_reset_bonding_scheme",	//Valid values: non_reset_bonding_scheme|reset_bonding_scheme
	parameter pll_feedback = "non_pll_feedback",	//Valid values: non_pll_feedback|pll_feedback
	parameter pcie_g3_x8 = "non_pcie_g3_x8",	//Valid values: non_pcie_g3_x8|pcie_g3_x8
	parameter avmm_group_channel_index = 0,	//Valid values: 0..2
	parameter use_default_base_address = "true",	//Valid values: false|true
	parameter user_base_address = 0	//Valid values: 0..2047
)
(
//input and output port declaration
	input [ 1:0 ] pciesw,
	input [ 0:0 ] rxclk,
	output [ 0:0 ] rxiqclk,
	input [ 0:0 ] rstn,
	output [ 1:0 ] pcieswdone,
	input [ 0:0 ] txpmasyncp,
	output [ 0:0 ] pllfbsw,
	output [ 0:0 ] pciesyncp,
	output [ 0:0 ] pciefbclk,
	input [ 0:0 ] clklct,
	input [ 0:0 ] clkblct,
	input [ 0:0 ] clklcb,
	input [ 0:0 ] clkblcb,
	input [ 0:0 ] clkcdrloc,
	input [ 0:0 ] clkbcdrloc,
	input [ 0:0 ] clkffpll,
	input [ 0:0 ] clkbffpll,
	input [ 0:0 ] clkupseg,
	input [ 0:0 ] clkbupseg,
	input [ 0:0 ] clkdnseg,
	input [ 0:0 ] clkbdnseg,
	input [ 0:0 ] clkbcdr1b,
	input [ 0:0 ] clkbcdr1t,
	input [ 0:0 ] clkcdr1b,
	input [ 0:0 ] clkcdr1t,
	output [ 0:0 ] cpulseout,
	output [ 0:0 ] hfclkpout,
	output [ 0:0 ] hfclknout,
	output [ 0:0 ] lfclkpout,
	output [ 0:0 ] lfclknout,
	output [ 2:0 ] pclkout,
	output [ 0:0 ] cpulse,
	output [ 0:0 ] hfclkp,
	output [ 0:0 ] hfclkn,
	output [ 0:0 ] lfclkp,
	output [ 0:0 ] lfclkn,
	output [ 2:0 ] pclk,
	input [ 0:0 ] cpulsex6dn,
	input [ 0:0 ] cpulsex6up,
	input [ 0:0 ] cpulsexndn,
	input [ 0:0 ] cpulsexnup,
	input [ 0:0 ] hfclknx6dn,
	input [ 0:0 ] hfclknx6up,
	input [ 0:0 ] hfclknxndn,
	input [ 0:0 ] hfclknxnup,
	input [ 0:0 ] hfclkpx6dn,
	input [ 0:0 ] hfclkpx6up,
	input [ 0:0 ] hfclkpxndn,
	input [ 0:0 ] hfclkpxnup,
	input [ 0:0 ] lfclknx6dn,
	input [ 0:0 ] lfclknx6up,
	input [ 0:0 ] lfclknxndn,
	input [ 0:0 ] lfclknxnup,
	input [ 0:0 ] lfclkpx6dn,
	input [ 0:0 ] lfclkpx6up,
	input [ 0:0 ] lfclkpxndn,
	input [ 0:0 ] lfclkpxnup,
	input [ 2:0 ] pclkx6dn,
	input [ 2:0 ] pclkx6up,
	input [ 2:0 ] pclkxndn,
	input [ 2:0 ] pclkxnup,
	input [ 0:0 ] avmmrstn,
	input [ 0:0 ] avmmclk,
	input [ 0:0 ] avmmwrite,
	input [ 0:0 ] avmmread,
	input [ 1:0 ] avmmbyteen,
	input [ 10:0 ] avmmaddress,
	input [ 15:0 ] avmmwritedata,
	output [ 15:0 ] avmmreaddata,
	output [ 0:0 ] blockselect
); 

	stratixv_hssi_pma_tx_cgb_encrypted 
	#(
		.enable_debug_info(enable_debug_info),

		.auto_negotiation(auto_negotiation),
		.mode(mode),
		.x1_clock_source_sel(x1_clock_source_sel),
		.x1_clock0_logical_to_physical_mapping(x1_clock0_logical_to_physical_mapping),
		.x1_clock1_logical_to_physical_mapping(x1_clock1_logical_to_physical_mapping),
		.x1_clock2_logical_to_physical_mapping(x1_clock2_logical_to_physical_mapping),
		.x1_clock3_logical_to_physical_mapping(x1_clock3_logical_to_physical_mapping),
		.x1_clock4_logical_to_physical_mapping(x1_clock4_logical_to_physical_mapping),
		.x1_clock5_logical_to_physical_mapping(x1_clock5_logical_to_physical_mapping),
		.x1_clock6_logical_to_physical_mapping(x1_clock6_logical_to_physical_mapping),
		.x1_clock7_logical_to_physical_mapping(x1_clock7_logical_to_physical_mapping),
		.x1_div_m_sel(x1_div_m_sel),
		.xn_clock_source_sel(xn_clock_source_sel),
		.channel_number(channel_number),
		.data_rate(data_rate),
		.tx_mux_power_down(tx_mux_power_down),
		.cgb_iqclk_sel(cgb_iqclk_sel),
		.clk_mute(clk_mute),
		.cgb_sync(cgb_sync),
		.reset_scheme(reset_scheme),
		.pll_feedback(pll_feedback),
		.pcie_g3_x8(pcie_g3_x8),
		.avmm_group_channel_index(avmm_group_channel_index),
		.use_default_base_address(use_default_base_address),
		.user_base_address(user_base_address)

	)
	stratixv_hssi_pma_tx_cgb_encrypted_inst	(
		.pciesw(pciesw),
		.rxclk(rxclk),
		.rxiqclk(rxiqclk),
		.rstn(rstn),
		.pcieswdone(pcieswdone),
		.txpmasyncp(txpmasyncp),
		.pllfbsw(pllfbsw),
		.pciesyncp(pciesyncp),
		.pciefbclk(pciefbclk),
		.clklct(clklct),
		.clkblct(clkblct),
		.clklcb(clklcb),
		.clkblcb(clkblcb),
		.clkcdrloc(clkcdrloc),
		.clkbcdrloc(clkbcdrloc),
		.clkffpll(clkffpll),
		.clkbffpll(clkbffpll),
		.clkupseg(clkupseg),
		.clkbupseg(clkbupseg),
		.clkdnseg(clkdnseg),
		.clkbdnseg(clkbdnseg),
		.clkbcdr1b(clkbcdr1b),
		.clkbcdr1t(clkbcdr1t),
		.clkcdr1b(clkcdr1b),
		.clkcdr1t(clkcdr1t),
		.cpulseout(cpulseout),
		.hfclkpout(hfclkpout),
		.hfclknout(hfclknout),
		.lfclkpout(lfclkpout),
		.lfclknout(lfclknout),
		.pclkout(pclkout),
		.cpulse(cpulse),
		.hfclkp(hfclkp),
		.hfclkn(hfclkn),
		.lfclkp(lfclkp),
		.lfclkn(lfclkn),
		.pclk(pclk),
		.cpulsex6dn(cpulsex6dn),
		.cpulsex6up(cpulsex6up),
		.cpulsexndn(cpulsexndn),
		.cpulsexnup(cpulsexnup),
		.hfclknx6dn(hfclknx6dn),
		.hfclknx6up(hfclknx6up),
		.hfclknxndn(hfclknxndn),
		.hfclknxnup(hfclknxnup),
		.hfclkpx6dn(hfclkpx6dn),
		.hfclkpx6up(hfclkpx6up),
		.hfclkpxndn(hfclkpxndn),
		.hfclkpxnup(hfclkpxnup),
		.lfclknx6dn(lfclknx6dn),
		.lfclknx6up(lfclknx6up),
		.lfclknxndn(lfclknxndn),
		.lfclknxnup(lfclknxnup),
		.lfclkpx6dn(lfclkpx6dn),
		.lfclkpx6up(lfclkpx6up),
		.lfclkpxndn(lfclkpxndn),
		.lfclkpxnup(lfclkpxnup),
		.pclkx6dn(pclkx6dn),
		.pclkx6up(pclkx6up),
		.pclkxndn(pclkxndn),
		.pclkxnup(pclkxnup),
		.avmmrstn(avmmrstn),
		.avmmclk(avmmclk),
		.avmmwrite(avmmwrite),
		.avmmread(avmmread),
		.avmmbyteen(avmmbyteen),
		.avmmaddress(avmmaddress),
		.avmmwritedata(avmmwritedata),
		.avmmreaddata(avmmreaddata),
		.blockselect(blockselect)
	);


endmodule
// --------------------------------------------------------------------
// This is auto-generated HSSI Simulation Atom Model Encryption Wrapper
// Module Name : ./sim_model_wrappers//stratixv_hssi_pma_tx_ser_wrapper.v
// --------------------------------------------------------------------

`timescale 1 ps/1 ps
module stratixv_hssi_pma_tx_ser
#(
	// parameter declaration and default value assignemnt
	parameter enable_debug_info = "false",	//Valid values: false|true; this is simulation-only parameter, for debug purpose only

	parameter ser_loopback = "false",	//Valid values: false|true
	parameter pre_tap_en = "false",	//Valid values: false|true
	parameter post_tap_1_en = "false",	//Valid values: false|true
	parameter post_tap_2_en = "false",	//Valid values: false|true
	parameter auto_negotiation = "false",	//Valid values: false|true
	parameter mode = 8,	//Valid values: 8|10|16|20|32|40|64|80
	parameter clk_divtx_deskew = 0,	//Valid values: 0..15
	parameter channel_number = 0,	//Valid values: 0..65
	parameter clk_forward_only_mode = "false",	//Valid values: false|true
	parameter avmm_group_channel_index = 0,	//Valid values: 0..2
	parameter use_default_base_address = "true",	//Valid values: false|true
	parameter user_base_address = 0	//Valid values: 0..2047
)
(
//input and output port declaration
	output [ 0:0 ] lbvon,
	input [ 79:0 ] datain,
	output [ 0:0 ] preenout,
	input [ 0:0 ] slpbk,
	input [ 0:0 ] pciesyncp,
	input [ 0:0 ] cpulse,
	input [ 0:0 ] hfclkn,
	input [ 0:0 ] hfclk,
	input [ 0:0 ] lfclkn,
	input [ 0:0 ] lfclk,
	input [ 0:0 ] rstn,
	output [ 0:0 ] clkdivtx,
	output [ 0:0 ] lbvop,
	output [ 0:0 ] dataout,
	input [ 1:0 ] pciesw,
	input [ 2:0 ] pclk,
	input [ 0:0 ] avmmrstn,
	input [ 0:0 ] avmmclk,
	input [ 0:0 ] avmmwrite,
	input [ 0:0 ] avmmread,
	input [ 1:0 ] avmmbyteen,
	input [ 10:0 ] avmmaddress,
	input [ 15:0 ] avmmwritedata,
	output [ 15:0 ] avmmreaddata,
	output [ 0:0 ] blockselect
); 

	stratixv_hssi_pma_tx_ser_encrypted 
	#(
		.enable_debug_info(enable_debug_info),

		.ser_loopback(ser_loopback),
		.pre_tap_en(pre_tap_en),
		.post_tap_1_en(post_tap_1_en),
		.post_tap_2_en(post_tap_2_en),
		.auto_negotiation(auto_negotiation),
		.mode(mode),
		.clk_divtx_deskew(clk_divtx_deskew),
		.channel_number(channel_number),
		.clk_forward_only_mode(clk_forward_only_mode),
		.avmm_group_channel_index(avmm_group_channel_index),
		.use_default_base_address(use_default_base_address),
		.user_base_address(user_base_address)

	)
	stratixv_hssi_pma_tx_ser_encrypted_inst	(
		.lbvon(lbvon),
		.datain(datain),
		.preenout(preenout),
		.slpbk(slpbk),
		.pciesyncp(pciesyncp),
		.cpulse(cpulse),
		.hfclkn(hfclkn),
		.hfclk(hfclk),
		.lfclkn(lfclkn),
		.lfclk(lfclk),
		.rstn(rstn),
		.clkdivtx(clkdivtx),
		.lbvop(lbvop),
		.dataout(dataout),
		.pciesw(pciesw),
		.pclk(pclk),
		.avmmrstn(avmmrstn),
		.avmmclk(avmmclk),
		.avmmwrite(avmmwrite),
		.avmmread(avmmread),
		.avmmbyteen(avmmbyteen),
		.avmmaddress(avmmaddress),
		.avmmwritedata(avmmwritedata),
		.avmmreaddata(avmmreaddata),
		.blockselect(blockselect)
	);


endmodule
// --------------------------------------------------------------------
// This is auto-generated HSSI Simulation Atom Model Encryption Wrapper
// Module Name : stratixv_hssi_pma_int_wrapper.v
// --------------------------------------------------------------------

`timescale 1 ps/1 ps
module stratixv_hssi_pma_int
#(
	// parameter declaration and default value assignemnt
	parameter enable_debug_info = "false",	//Valid values: false|true; this is simulation-only parameter, for debug purpose only
	parameter early_eios_sel = "pcs_early_eios",	//Valid values: pcs_early_eios|core_early_eios
	parameter ltr_sel = "pcs_ltr",	//Valid values: pcs_ltr|core_ltr
	parameter pcie_switch_sel = "pcs_pcie_switch_sw",	//Valid values: pcs_pcie_switch_sw|core_pcie_switch_sw
	parameter ppm_lock_sel = "pcs_ppm_lock",	//Valid values: pcs_ppm_lock|core_ppm_lock
	parameter lc_in_sel = "pcs_lc_in",	//Valid values: pcs_lc_in|core_lc_in
	parameter txdetectrx_sel = "pcs_txdetectrx",	//Valid values: pcs_txdetectrx|core_txdetectrx
	parameter tx_elec_idle_sel = "pcs_tx_elec_idle",	//Valid values: pcs_tx_elec_idle|core_tx_elec_idle
	parameter pclk_0_clk_sel = "pclk_0_power_down",	//Valid values: pclk_0_pma_rx_clk|pclk_0_pcs_rx_clk|pclk_0_clkdiv_att|pclk_0_pma_tx_clk|pclk_0_pcs_tx_clk|pclk_0_power_down
	parameter pclk_1_clk_sel = "pclk_1_power_down",	//Valid values: pclk_1_pma_rx_clk|pclk_1_pcs_rx_clk|pclk_1_clkdiv_att|pclk_1_pma_tx_clk|pclk_1_pcs_tx_clk|pclk_1_power_down
	parameter iqtxrxclk_a_sel = "tristage_outa",	//Valid values: iqtxrxclk_a_pma_rx_clk|iqtxrxclk_a_pcs_rx_clk|iqtxrxclk_a_pcie_fb_clk|iqtxrxclk_a_pma_tx_clk|iqtxrxclk_a_pcs_tx_clk|tristage_outa
	parameter iqtxrxclk_b_sel = "tristage_outb",	//Valid values: iqtxrxclk_b_pma_rx_clk|iqtxrxclk_b_pcs_rx_clk|iqtxrxclk_b_pcie_fb_clk|iqtxrxclk_b_pma_tx_clk|iqtxrxclk_b_pcs_tx_clk|tristage_outb
	parameter rx_data_out_sel = "teng_mode",	//Valid values: teng_mode|teng_direct_mode|att_direct_mode
	parameter rx_bbpd_cal_en = "pcs_cal_en",	//Valid values: pcs_cal_en|core_cal_en
	parameter dft_switch = "dft_switch_off",	//Valid values: dft_switch_off|dft_switch_on
	parameter cvp_mode = "cvp_mode_off",	//Valid values: cvp_mode_off|cvp_mode_on
	parameter channel_number = 0,	//Valid values: 0..255
	parameter ffclk_enable = "ffclk_off"	//Valid values: ffclk_off|ffclk_on
)
(
//input and output port declaration
	output [ 0:0 ] fref,
	input [ 0:0 ] frefatti,
	input [ 0:0 ] frefi,
	output [ 0:0 ] hclkpcs,
	input [ 0:0 ] hclkpcsi,
	input [ 17:0 ] icoeff,
	output [ 17:0 ] icoeffo,
	input [ 2:0 ] irxpreset,
	output [ 2:0 ] irxpreseto,
	output [ 0:0 ] iqtxrxclka,
	output [ 0:0 ] iqtxrxclkb,
	input [ 0:0 ] lcin,
	output [ 0:0 ] lcino,
	output [ 1:0 ] lcout,
	input [ 1:0 ] lcouti,
	output [ 0:0 ] ltdo,
	input [ 0:0 ] ltr,
	output [ 0:0 ] ltro,
	output [ 0:0 ] occaldone,
	input [ 0:0 ] occaldoneatti,
	input [ 0:0 ] occaldonei,
	input [ 0:0 ] occalen,
	output [ 0:0 ] occaleno,
	input [ 0:0 ] pciefbclk,
	output [ 1:0 ] pcieswdone,
	input [ 1:0 ] pcieswdonei,
	input [ 1:0 ] pcieswitch,
	output [ 1:0 ] pcieswitcho,
	input [ 0:0 ] pcsrxclkout,
	input [ 0:0 ] pcstxclkout,
	output [ 0:0 ] pfdmodelock,
	input [ 0:0 ] pfdmodelockatti,
	input [ 0:0 ] pfdmodelocki,
	output [ 0:0 ] adaptdone,
	input [ 0:0 ] adaptdonei,
	input [ 0:0 ] adcecapture,
	output [ 0:0 ] adcecaptureo,
	input [ 0:0 ] adcestandby,
	output [ 0:0 ] adcestandbyo,
	input [ 0:0 ] bslip,
	output [ 0:0 ] bslipo,
	input [ 1:0 ] byteen,
	output [ 1:0 ] byteeno,
	input [ 0:0 ] ccrurstb,
	input [ 0:0 ] cearlyeios,
	input [ 0:0 ] clcin,
	output [ 1:0 ] clcout,
	input [ 0:0 ] cltd,
	input [ 0:0 ] cltr,
	output [ 0:0 ] coccaldone,
	input [ 0:0 ] coccalen,
	output [ 1:0 ] cpcieswdone,
	input [ 1:0 ] cpcieswitch,
	output [ 1:0 ] cpclk,
	output [ 0:0 ] cpfdmodelock,
	input [ 0:0 ] cppmlock,
	input [ 0:0 ] crslpbk,
	output [ 0:0 ] crxdetectvalid,
	output [ 0:0 ] crxfound,
	output [ 0:0 ] crxplllock,
	output [ 0:0 ] csd,
	input [ 0:0 ] ctxelecidle,
	input [ 0:0 ] ctxdetectrx,
	input [ 0:0 ] ctxpmarstb,
	output [ 0:0 ] clk33pcs,
	input [ 0:0 ] clk33pcsi,
	input [ 0:0 ] clkdivatti,
	output [ 0:0 ] clkdivrx,
	input [ 0:0 ] clkdivrxatti,
	input [ 0:0 ] clkdivrxi,
	output [ 0:0 ] clkdivtx,
	input [ 0:0 ] clkdivtxatti,
	input [ 0:0 ] clkdivtxi,
	output [ 0:0 ] clklow,
	input [ 0:0 ] clklowatti,
	input [ 0:0 ] clklowi,
	output [ 0:0 ] crurstbo,
	input [ 0:0 ] dprioclk,
	output [ 0:0 ] dprioclko,
	input [ 0:0 ] dpriorstn,
	output [ 0:0 ] dpriorstno,
	input [ 0:0 ] earlyeios,
	output [ 0:0 ] earlyeioso,
	input [ 0:0 ] pldclk,
	output [ 0:0 ] pldclko,
	input [ 0:0 ] ppmlock,
	output [ 0:0 ] ppmlocko,
	output [ 79:0 ] rxdata,
	input [ 63:0 ] rxdataatti,
	input [ 79:0 ] rxdatacorei,
	input [ 39:0 ] rxdatai,
	input [ 0:0 ] rxdetclk,
	output [ 0:0 ] rxdetclko,
	output [ 0:0 ] rxdetectvalid,
	input [ 0:0 ] rxdetectvalidi,
	output [ 0:0 ] rxfound,
	input [ 0:0 ] rxfoundi,
	input [ 0:0 ] rxqpipulldn,
	output [ 0:0 ] rxqpipulldno,
	output [ 0:0 ] rxplllock,
	input [ 0:0 ] rxplllockatti,
	input [ 0:0 ] rxplllocki,
	input [ 0:0 ] rxpmarstb,
	output [ 0:0 ] rxpmarstbo,
	output [ 0:0 ] slpbko,
	output [ 0:0 ] sd,
	input [ 0:0 ] sdi,
	input [ 0:0 ] sershiftload,
	output [ 0:0 ] sershiftloado,
	output [ 0:0 ] signalok,
	output [ 7:0 ] testbus,
	input [ 7:0 ] testbusi,
	input [ 3:0 ] testsel,
	output [ 3:0 ] testselo,
	input [ 79:0 ] txdata,
	output [ 79:0 ] txdatao,
	input [ 0:0 ] txelecidle,
	output [ 0:0 ] txelecidleo,
	input [ 0:0 ] txpmasyncp,
	output [ 0:0 ] txpmasyncpo,
	input [ 0:0 ] txqpipulldn,
	output [ 0:0 ] txqpipulldno,
	input [ 0:0 ] txqpipullup,
	output [ 0:0 ] txqpipullupo,
	input [ 0:0 ] txdetectrx,
	output [ 0:0 ] txdetectrxo,
	output [ 0:0 ] txpmarstbo,
	input [ 0:0 ] avmmrstn,
	input [ 0:0 ] avmmclk,
	input [ 0:0 ] avmmwrite,
	input [ 0:0 ] avmmread,
	input [ 1:0 ] avmmbyteen,
	input [ 10:0 ] avmmaddress,
	input [ 15:0 ] avmmwritedata,
	output [ 15:0 ] avmmreaddata,
	output [ 0:0 ] blockselect
); 

	stratixv_hssi_pma_int_encrypted 
	#(
		.enable_debug_info(enable_debug_info),
		.early_eios_sel(early_eios_sel),
		.ltr_sel(ltr_sel),
		.pcie_switch_sel(pcie_switch_sel),
		.ppm_lock_sel(ppm_lock_sel),
		.lc_in_sel(lc_in_sel),
		.txdetectrx_sel(txdetectrx_sel),
		.tx_elec_idle_sel(tx_elec_idle_sel),
		.pclk_0_clk_sel(pclk_0_clk_sel),
		.pclk_1_clk_sel(pclk_1_clk_sel),
		.iqtxrxclk_a_sel(iqtxrxclk_a_sel),
		.iqtxrxclk_b_sel(iqtxrxclk_b_sel),
		.rx_data_out_sel(rx_data_out_sel),
		.rx_bbpd_cal_en(rx_bbpd_cal_en),
		.dft_switch(dft_switch),
		.cvp_mode(cvp_mode),
		.channel_number(channel_number),
		.ffclk_enable(ffclk_enable)

	)
	stratixv_hssi_pma_int_encrypted_inst	(
		.fref(fref),
		.frefatti(frefatti),
		.frefi(frefi),
		.hclkpcs(hclkpcs),
		.hclkpcsi(hclkpcsi),
		.icoeff(icoeff),
		.icoeffo(icoeffo),
		.irxpreset(irxpreset),
		.irxpreseto(irxpreseto),
		.iqtxrxclka(iqtxrxclka),
		.iqtxrxclkb(iqtxrxclkb),
		.lcin(lcin),
		.lcino(lcino),
		.lcout(lcout),
		.lcouti(lcouti),
		.ltdo(ltdo),
		.ltr(ltr),
		.ltro(ltro),
		.occaldone(occaldone),
		.occaldoneatti(occaldoneatti),
		.occaldonei(occaldonei),
		.occalen(occalen),
		.occaleno(occaleno),
		.pciefbclk(pciefbclk),
		.pcieswdone(pcieswdone),
		.pcieswdonei(pcieswdonei),
		.pcieswitch(pcieswitch),
		.pcieswitcho(pcieswitcho),
		.pcsrxclkout(pcsrxclkout),
		.pcstxclkout(pcstxclkout),
		.pfdmodelock(pfdmodelock),
		.pfdmodelockatti(pfdmodelockatti),
		.pfdmodelocki(pfdmodelocki),
		.adaptdone(adaptdone),
		.adaptdonei(adaptdonei),
		.adcecapture(adcecapture),
		.adcecaptureo(adcecaptureo),
		.adcestandby(adcestandby),
		.adcestandbyo(adcestandbyo),
		.bslip(bslip),
		.bslipo(bslipo),
		.byteen(byteen),
		.byteeno(byteeno),
		.ccrurstb(ccrurstb),
		.cearlyeios(cearlyeios),
		.clcin(clcin),
		.clcout(clcout),
		.cltd(cltd),
		.cltr(cltr),
		.coccaldone(coccaldone),
		.coccalen(coccalen),
		.cpcieswdone(cpcieswdone),
		.cpcieswitch(cpcieswitch),
		.cpclk(cpclk),
		.cpfdmodelock(cpfdmodelock),
		.cppmlock(cppmlock),
		.crslpbk(crslpbk),
		.crxdetectvalid(crxdetectvalid),
		.crxfound(crxfound),
		.crxplllock(crxplllock),
		.csd(csd),
		.ctxelecidle(ctxelecidle),
		.ctxdetectrx(ctxdetectrx),
		.ctxpmarstb(ctxpmarstb),
		.clk33pcs(clk33pcs),
		.clk33pcsi(clk33pcsi),
		.clkdivatti(clkdivatti),
		.clkdivrx(clkdivrx),
		.clkdivrxatti(clkdivrxatti),
		.clkdivrxi(clkdivrxi),
		.clkdivtx(clkdivtx),
		.clkdivtxatti(clkdivtxatti),
		.clkdivtxi(clkdivtxi),
		.clklow(clklow),
		.clklowatti(clklowatti),
		.clklowi(clklowi),
		.crurstbo(crurstbo),
		.dprioclk(dprioclk),
		.dprioclko(dprioclko),
		.dpriorstn(dpriorstn),
		.dpriorstno(dpriorstno),
		.earlyeios(earlyeios),
		.earlyeioso(earlyeioso),
		.pldclk(pldclk),
		.pldclko(pldclko),
		.ppmlock(ppmlock),
		.ppmlocko(ppmlocko),
		.rxdata(rxdata),
		.rxdataatti(rxdataatti),
		.rxdatacorei(rxdatacorei),
		.rxdatai(rxdatai),
		.rxdetclk(rxdetclk),
		.rxdetclko(rxdetclko),
		.rxdetectvalid(rxdetectvalid),
		.rxdetectvalidi(rxdetectvalidi),
		.rxfound(rxfound),
		.rxfoundi(rxfoundi),
		.rxqpipulldn(rxqpipulldn),
		.rxqpipulldno(rxqpipulldno),
		.rxplllock(rxplllock),
		.rxplllockatti(rxplllockatti),
		.rxplllocki(rxplllocki),
		.rxpmarstb(rxpmarstb),
		.rxpmarstbo(rxpmarstbo),
		.slpbko(slpbko),
		.sd(sd),
		.sdi(sdi),
		.sershiftload(sershiftload),
		.sershiftloado(sershiftloado),
		.signalok(signalok),
		.testbus(testbus),
		.testbusi(testbusi),
		.testsel(testsel),
		.testselo(testselo),
		.txdata(txdata),
		.txdatao(txdatao),
		.txelecidle(txelecidle),
		.txelecidleo(txelecidleo),
		.txpmasyncp(txpmasyncp),
		.txpmasyncpo(txpmasyncpo),
		.txqpipulldn(txqpipulldn),
		.txqpipulldno(txqpipulldno),
		.txqpipullup(txqpipullup),
		.txqpipullupo(txqpipullupo),
		.txdetectrx(txdetectrx),
		.txdetectrxo(txdetectrxo),
		.txpmarstbo(txpmarstbo),
		.avmmrstn(avmmrstn),
		.avmmclk(avmmclk),
		.avmmwrite(avmmwrite),
		.avmmread(avmmread),
		.avmmbyteen(avmmbyteen),
		.avmmaddress(avmmaddress),
		.avmmwritedata(avmmwritedata),
		.avmmreaddata(avmmreaddata),
		.blockselect(blockselect)
	);


endmodule
// --------------------------------------------------------------------
// This is auto-generated HSSI Simulation Atom Model Encryption Wrapper
// Module Name : ./sim_model_wrappers//stratixv_hssi_pma_rx_att_wrapper.v
// --------------------------------------------------------------------

`timescale 1 ps/1 ps
module stratixv_hssi_pma_rx_att
#(
	// parameter declaration and default value assignemnt
	parameter enable_debug_info = "false",	//Valid values: false|true; this is simulation-only parameter, for debug purpose only

	parameter rx_pdb = "power_down_rx",	//Valid values: normal_rx_on|power_down_rx
	parameter eq0_dc_gain = "eq0_gain_min",	//Valid values: eq0_gain_min|eq0_gain_set1|eq0_gain_set2|eq0_gain_max
	parameter eq1_dc_gain = "eq1_gain_min",	//Valid values: eq1_gain_min|eq1_gain_set1|eq1_gain_set2|eq1_gain_max
	parameter eq2_dc_gain = "eq2_gain_min",	//Valid values: eq2_gain_min|eq2_gain_set1|eq2_gain_set2|eq2_gain_max
	parameter rx_vcm = "vtt_0p7v",	//Valid values: vtt_0p8v|vtt_0p75v|vtt_0p7v|vtt_0p65v|vtt_0p6v|vtt_0p55v|vtt_0p5v|vtt_0p35v|vtt_vcmoff7|vtt_vcmoff6|vtt_vcmoff5|vtt_vcmoff4|vtt_vcmoff3|vtt_vcmoff2|vtt_vcmoff1|vtt_vcmoff0
	parameter rxterm_ctl = "rxterm_dis",	//Valid values: rxterm_dis|rxterm_en
	parameter rxterm_set = "def_rterm",	//Valid values: max_rterm|rterm_14|rterm_13|rterm_12|rterm_11|rterm_10|rterm_9|def_rterm|rterm_7|rterm_6|rterm_5|rterm_4|rterm_3|rterm_2|rterm_1|min_rterm
	parameter offset_cancellation_ctrl = "volt_0mv",	//Valid values: volt_0mv|minus_delta1|minus_delta2|minus_delta3|minus_delta4|minus_delta5|minus_delta6|minus_delta7|minus_delta8|minus_delta9|minus_delta10|minus_delta11|minus_delta12|minus_delta13|minus_delta14|minus_delta15|plus_delta1|plus_delta2|plus_delta3|plus_delta4|plus_delta5|plus_delta6|plus_delta7|plus_delta8|plus_delta9|plus_delta10|plus_delta11|plus_delta12|plus_delta13|plus_delta14|plus_delta15
	parameter eq_bias_adj = "i_eqbias_def",	//Valid values: i_eqbias_def|i_eqbias_m33|i_eqbias_p33|i_eqbias_m20
	parameter atb_sel = "atb_off",	//Valid values: atb_off|atb_sel0|atb_sel1|atb_sel2|atb_sel3|atb_sel4|atb_sel5|atb_sel6|atb_sel7|atb_sel8|atb_sel9|atb_sel10|atb_sel11|atb_sel12|atb_sel13|atb_sel14|atb_sel15|atb_sel16|atb_sel17|atb_selunused2|atb_selunused3|atb_selunused4|atb_selunused5|atb_selunused6|atb_selunused7|atb_selunused8|atb_selunused9|atb_selunused10|atb_selunused11|atb_selunused12|atb_selunused13|atb_selunused14
	parameter offset_correct = "offcorr_dis",	//Valid values: offcorr_dis|eq_stg1_pd|dig_corr_hold|eq1_pd_dcorr_en|only_acorr_en|dig_ana_corr_en
	parameter var_bulk0 = "eq0_var_bulk0",	//Valid values: eq0_var_bulk0|eq0_var_bulk1|eq0_var_bulk2|eq0_var_bulk3|eq0_var_bulk4|eq0_var_bulk5|eq0_var_bulk6|eq0_var_bulk7|eq0_var_bulk8|eq0_var_bulk9|eq0_var_bulk10|eq0_var_bulk11|eq0_var_bulk12|eq0_var_bulk13|eq0_var_bulk14|eq0_var_bulk15
	parameter var_gate0 = "eq0_var_gate0",	//Valid values: eq0_var_gate0|eq0_var_gate1|eq0_var_gate2|eq0_var_gate3|eq0_var_gate4|eq0_var_gate5|eq0_var_gate6|eq0_var_gate7|eq0_var_gate8|eq0_var_gate9|eq0_var_gate10|eq0_var_gate11|eq0_var_gate12|eq0_var_gate13|eq0_var_gate14|eq0_var_gate15
	parameter var_bulk1 = "eq1_var_bulk0",	//Valid values: eq1_var_bulk0|eq1_var_bulk1|eq1_var_bulk2|eq1_var_bulk3|eq1_var_bulk4|eq1_var_bulk5|eq1_var_bulk6|eq1_var_bulk7|eq1_var_bulk8|eq1_var_bulk9|eq1_var_bulk10|eq1_var_bulk11|eq1_var_bulk12|eq1_var_bulk13|eq1_var_bulk14|eq1_var_bulk15
	parameter var_gate1 = "eq1_var_gate0",	//Valid values: eq1_var_gate0|eq1_var_gate1|eq1_var_gate2|eq1_var_gate3|eq1_var_gate4|eq1_var_gate5|eq1_var_gate6|eq1_var_gate7|eq1_var_gate8|eq1_var_gate9|eq1_var_gate10|eq1_var_gate11|eq1_var_gate12|eq1_var_gate13|eq1_var_gate14|eq1_var_gate15
	parameter var_bulk2 = "eq2_var_bulk0",	//Valid values: eq2_var_bulk0|eq2_var_bulk1|eq2_var_bulk2|eq2_var_bulk3|eq2_var_bulk4|eq2_var_bulk5|eq2_var_bulk6|eq2_var_bulk7|eq2_var_bulk8|eq2_var_bulk9|eq2_var_bulk10|eq2_var_bulk11|eq2_var_bulk12|eq2_var_bulk13|eq2_var_bulk14|eq2_var_bulk15
	parameter var_gate2 = "eq2_var_gate0",	//Valid values: eq2_var_gate0|eq2_var_gate1|eq2_var_gate2|eq2_var_gate3|eq2_var_gate4|eq2_var_gate5|eq2_var_gate6|eq2_var_gate7|eq2_var_gate8|eq2_var_gate9|eq2_var_gate10|eq2_var_gate11|eq2_var_gate12|eq2_var_gate13|eq2_var_gate14|eq2_var_gate15
	parameter off_filter_cap = "off_filt_cap0",	//Valid values: off_filt_cap0|off_filt_cap1
	parameter off_filter_res = "off_filt_res0",	//Valid values: off_filt_res0|off_filt_res1|off_filt_res2|off_filt_res3
	parameter offcomp_cmref = "off_comp_vcm0",	//Valid values: off_comp_vcm0|off_comp_vcm1|off_comp_vcm2|off_comp_vcm3
	parameter offcomp_igain = "off_comp_ig0",	//Valid values: off_comp_ig0|off_comp_ig1|off_comp_ig2|off_comp_ig3
	parameter diag_loopbk_bias = "dlb_bw0",	//Valid values: dlb_bw0|dlb_bw_p33|dlb_bw_m33|dlb_bw3
	parameter rload_shunt = "rld000",	//Valid values: rld000|rld001|rld002|rld003|rld004|rld005|rld006|rld007
	parameter rzero_shunt = "rz0",	//Valid values: rz0|rz1
	parameter eqz3_pd = "eqz3shrt_dis",	//Valid values: eqz3shrt_dis|eqz3shrt_en
	parameter vcm_pup = "msb_lo_vcm_current",	//Valid values: msb_lo_vcm_current|msb_hi_vcm_current
	parameter vcm_pdnb = "lsb_lo_vcm_current",	//Valid values: lsb_lo_vcm_current|lsb_hi_vcm_current
	parameter diag_rev_lpbk = "no_diag_rev_loopback"	//Valid values: no_diag_rev_loopback|diag_rev_loopback
)
(
//input and output port declaration
	input [ 10:0 ] avmmaddress,
	input [ 1:0 ] avmmbyteen,
	input [ 0:0 ] avmmclk,
	input [ 0:0 ] avmmread,
	input [ 0:0 ] avmmrstn,
	input [ 0:0 ] avmmwrite,
	input [ 15:0 ] avmmwritedata,
	input [ 0:0 ] lpbkn,
	input [ 0:0 ] lpbkp,
	input [ 0:0 ] ocden,
	input [ 0:0 ] rxnbidirin,
	input [ 0:0 ] rxpbidirin,
	input [ 0:0 ] slpbk,
	output [ 15:0 ] avmmreaddata,
	output [ 0:0 ] blockselect,
	output [ 0:0 ] outnbidirout,
	output [ 0:0 ] outpbidirout,
	output [ 0:0 ] rdlpbkn,
	output [ 0:0 ] rdlpbkp,
        input          nonuserfrompmaux
); 

	stratixv_hssi_pma_rx_att_encrypted 
	#(
		.enable_debug_info(enable_debug_info),

		.rx_pdb(rx_pdb),
		.eq0_dc_gain(eq0_dc_gain),
		.eq1_dc_gain(eq1_dc_gain),
		.eq2_dc_gain(eq2_dc_gain),
		.rx_vcm(rx_vcm),
		.rxterm_ctl(rxterm_ctl),
		.rxterm_set(rxterm_set),
		.offset_cancellation_ctrl(offset_cancellation_ctrl),
		.eq_bias_adj(eq_bias_adj),
		.atb_sel(atb_sel),
		.offset_correct(offset_correct),
		.var_bulk0(var_bulk0),
		.var_gate0(var_gate0),
		.var_bulk1(var_bulk1),
		.var_gate1(var_gate1),
		.var_bulk2(var_bulk2),
		.var_gate2(var_gate2),
		.off_filter_cap(off_filter_cap),
		.off_filter_res(off_filter_res),
		.offcomp_cmref(offcomp_cmref),
		.offcomp_igain(offcomp_igain),
		.diag_loopbk_bias(diag_loopbk_bias),
		.rload_shunt(rload_shunt),
		.rzero_shunt(rzero_shunt),
		.eqz3_pd(eqz3_pd),
		.vcm_pup(vcm_pup),
		.vcm_pdnb(vcm_pdnb),
		.diag_rev_lpbk(diag_rev_lpbk)

	)
	stratixv_hssi_pma_rx_att_encrypted_inst	(
		.avmmaddress(avmmaddress),
		.avmmbyteen(avmmbyteen),
		.avmmclk(avmmclk),
		.avmmread(avmmread),
		.avmmrstn(avmmrstn),
		.avmmwrite(avmmwrite),
		.avmmwritedata(avmmwritedata),
		.lpbkn(lpbkn),
		.lpbkp(lpbkp),
		.ocden(ocden),
		.rxnbidirin(rxnbidirin),
		.rxpbidirin(rxpbidirin),
		.slpbk(slpbk),
		.avmmreaddata(avmmreaddata),
		.blockselect(blockselect),
		.outnbidirout(outnbidirout),
		.outpbidirout(outpbidirout),
		.rdlpbkn(rdlpbkn),
		.rdlpbkp(rdlpbkp)
	);


endmodule
// --------------------------------------------------------------------
// This is auto-generated HSSI Simulation Atom Model Encryption Wrapper
// Module Name : ./sim_model_wrappers//stratixv_hssi_pma_cdr_att_wrapper.v
// --------------------------------------------------------------------

`timescale 1 ps/1 ps
module stratixv_hssi_pma_cdr_att
#(
	// parameter declaration and default value assignemnt
	parameter enable_debug_info = "false",	//Valid values: false|true; this is simulation-only parameter, for debug purpose only

	parameter reference_clock_frequency = "",	//Valid values: 
	parameter output_clock_frequency = "",	//Valid values: 
	parameter bbpd_salatch_offset_ctrl_clk0 = "offset_0mv",	//Valid values: offset_0mv|offset_delta1_left|offset_delta2_left|offset_delta3_left|offset_delta4_left|offset_delta5_left|offset_delta6_left|offset_delta7_left|offset_delta1_right|offset_delta2_right|offset_delta3_right|offset_delta4_right|offset_delta5_right|offset_delta6_right|offset_delta7_right
	parameter bbpd_salatch_offset_ctrl_clk180 = "offset_0mv",	//Valid values: offset_0mv|offset_delta1_left|offset_delta2_left|offset_delta3_left|offset_delta4_left|offset_delta5_left|offset_delta6_left|offset_delta7_left|offset_delta1_right|offset_delta2_right|offset_delta3_right|offset_delta4_right|offset_delta5_right|offset_delta6_right|offset_delta7_right
	parameter bbpd_salatch_offset_ctrl_clk270 = "offset_0mv",	//Valid values: offset_0mv|offset_delta1_left|offset_delta2_left|offset_delta3_left|offset_delta4_left|offset_delta5_left|offset_delta6_left|offset_delta7_left|offset_delta1_right|offset_delta2_right|offset_delta3_right|offset_delta4_right|offset_delta5_right|offset_delta6_right|offset_delta7_right
	parameter bbpd_salatch_offset_ctrl_clk90 = "offset_0mv",	//Valid values: offset_0mv|offset_delta1_left|offset_delta2_left|offset_delta3_left|offset_delta4_left|offset_delta5_left|offset_delta6_left|offset_delta7_left|offset_delta1_right|offset_delta2_right|offset_delta3_right|offset_delta4_right|offset_delta5_right|offset_delta6_right|offset_delta7_right
	parameter bbpd_salatch_sel = "normal",	//Valid values: sa_sel|normal
	parameter bypass_cp_rgla = "false",	//Valid values: false|true
	parameter cdr_atb_select = "atb_disable",	//Valid values: atb_disable|atb_sel_1|atb_sel_2|atb_sel_3|atb_sel_4|atb_sel_5|atb_sel_6|atb_sel_7|atb_sel_8|atb_sel_9|atb_sel_10|atb_sel_11|atb_sel_12|atb_sel_13|atb_sel_14|atb_sel_15
	parameter charge_pump_current_test = "enable_ch_pump_normal",	//Valid values: enable_ch_pump_normal|enable_ch_pump_curr_test_up|enable_ch_pump_curr_test_down|disable_ch_pump_curr_test
	parameter clklow_fref_to_ppm_div_sel = 4,	//Valid values: 1|2|4
	parameter diag_rev_lpbk = "false",	//Valid values: false|true
	parameter fast_lock_mode = "false",	//Valid values: false|true
	parameter fb_sel = "vcoclk",	//Valid values: vcoclk|extclk
	parameter force_vco_const = "v1p39",	//Valid values: v0p58|v0p64|v0p67|v0p70|v0p75|v0p81|v0p87|v0p93|v0p86|v0p96|v1p00|v1p04|v1p13|v1p22|v1p30|v1p39|v0p00
	parameter hs_levshift_power_supply_setting = 1,	//Valid values: 0|1|2|3
	parameter ignore_phslock = "false",	//Valid values: false|true
	parameter m_counter = "<auto>",	//Valid values: 1|4|5|8|10|12|16|20|25|32|40|50
	parameter pd_charge_pump_current_ctrl = 5,	//Valid values: 5|10|20|30|40
	parameter pd_l_counter = 1,	//Valid values: 1
	parameter pfd_charge_pump_current_ctrl = 20,	//Valid values: 5|10|20|30|40|50|60|80|100|120|160|180|200|240|300|320|400
	parameter pfd_l_counter = 1,	//Valid values: 1|2
	parameter powerdown = 1'b1,	//Valid values: 1
	parameter ref_clk_div = "<auto>",	//Valid values: 1|2|4|8
	parameter regulator_volt_inc = "0",	//Valid values: 0|5|10|15|20|25|30|not_used
	parameter replica_bias_ctrl = "true",	//Valid values: false|true
	parameter reverse_loopback = "reverse_lpbk_cdr",	//Valid values: reverse_lpbk_cdr|reverse_lpbk_rx
	parameter reverse_serial_lpbk = "false",	//Valid values: false|true
	parameter ripple_cap_ctrl = "none",	//Valid values: reserved_11|reserved_10|plus_2pf|none
	parameter rxpll_pd_bw_ctrl = 320,	//Valid values: 320|180|140|100
	parameter rxpll_pfd_bw_ctrl = 3200	//Valid values: 1600|3200|6400|9600
)
(
//input and output port declaration
	input [ 0:0 ] crurstb,
	input [ 0:0 ] ltd,
	input [ 0:0 ] ltr,
	input [ 0:0 ] ppmlock,
	input [ 0:0 ] refclk,
	input [ 0:0 ] rstn,
	input [ 0:0 ] rxp,
	output [ 0:0 ] ck0pd,
	output [ 0:0 ] ck180pd,
	output [ 0:0 ] ck270pd,
	output [ 0:0 ] ck90pd,
	output [ 0:0 ] clk270bout,
	output [ 0:0 ] clk90bout,
	output [ 0:0 ] clklow,
	output [ 0:0 ] devenadiv2p,
	output [ 0:0 ] devenbdiv2p,
	output [ 0:0 ] devenout,
	output [ 0:0 ] div2270,
	output [ 0:0 ] doddadiv2p,
	output [ 0:0 ] doddbdiv2p,
	output [ 0:0 ] doddout,
	output [ 0:0 ] fref,
	output [ 3:0 ] pdof,
	output [ 0:0 ] pfdmodelock,
	output [ 0:0 ] rxplllock,
	output [ 0:0 ] txrlpbk
); 

	stratixv_hssi_pma_cdr_att_encrypted 
	#(
		.enable_debug_info(enable_debug_info),

		.reference_clock_frequency(reference_clock_frequency),
		.output_clock_frequency(output_clock_frequency),
		.bbpd_salatch_offset_ctrl_clk0(bbpd_salatch_offset_ctrl_clk0),
		.bbpd_salatch_offset_ctrl_clk180(bbpd_salatch_offset_ctrl_clk180),
		.bbpd_salatch_offset_ctrl_clk270(bbpd_salatch_offset_ctrl_clk270),
		.bbpd_salatch_offset_ctrl_clk90(bbpd_salatch_offset_ctrl_clk90),
		.bbpd_salatch_sel(bbpd_salatch_sel),
		.bypass_cp_rgla(bypass_cp_rgla),
		.cdr_atb_select(cdr_atb_select),
		.charge_pump_current_test(charge_pump_current_test),
		.clklow_fref_to_ppm_div_sel(clklow_fref_to_ppm_div_sel),
		.diag_rev_lpbk(diag_rev_lpbk),
		.fast_lock_mode(fast_lock_mode),
		.fb_sel(fb_sel),
		.force_vco_const(force_vco_const),
		.hs_levshift_power_supply_setting(hs_levshift_power_supply_setting),
		.ignore_phslock(ignore_phslock),
		.m_counter(m_counter),
		.pd_charge_pump_current_ctrl(pd_charge_pump_current_ctrl),
		.pd_l_counter(pd_l_counter),
		.pfd_charge_pump_current_ctrl(pfd_charge_pump_current_ctrl),
		.pfd_l_counter(pfd_l_counter),
		.powerdown(powerdown),
		.ref_clk_div(ref_clk_div),
		.regulator_volt_inc(regulator_volt_inc),
		.replica_bias_ctrl(replica_bias_ctrl),
		.reverse_loopback(reverse_loopback),
		.reverse_serial_lpbk(reverse_serial_lpbk),
		.ripple_cap_ctrl(ripple_cap_ctrl),
		.rxpll_pd_bw_ctrl(rxpll_pd_bw_ctrl),
		.rxpll_pfd_bw_ctrl(rxpll_pfd_bw_ctrl)

	)
	stratixv_hssi_pma_cdr_att_encrypted_inst	(
		.crurstb(crurstb),
		.ltd(ltd),
		.ltr(ltr),
		.ppmlock(ppmlock),
		.refclk(refclk),
		.rstn(rstn),
		.rxp(rxp),
		.ck0pd(ck0pd),
		.ck180pd(ck180pd),
		.ck270pd(ck270pd),
		.ck90pd(ck90pd),
		.clk270bout(clk270bout),
		.clk90bout(clk90bout),
		.clklow(clklow),
		.devenadiv2p(devenadiv2p),
		.devenbdiv2p(devenbdiv2p),
		.devenout(devenout),
		.div2270(div2270),
		.doddadiv2p(doddadiv2p),
		.doddbdiv2p(doddbdiv2p),
		.doddout(doddout),
		.fref(fref),
		.pdof(pdof),
		.pfdmodelock(pfdmodelock),
		.rxplllock(rxplllock),
		.txrlpbk(txrlpbk)
	);


endmodule
// --------------------------------------------------------------------
// This is auto-generated HSSI Simulation Atom Model Encryption Wrapper
// Module Name : ./sim_model_wrappers//stratixv_hssi_pma_deser_att_wrapper.v
// --------------------------------------------------------------------

`timescale 1 ps/1 ps
module stratixv_hssi_pma_deser_att
#(
	// parameter declaration and default value assignemnt
	parameter enable_debug_info = "false",	//Valid values: false|true; this is simulation-only parameter, for debug purpose only
  parameter vcobypass = "clk_divrx" //Valid values: clk_divrx|clklow|fref

)
(
//input and output port declaration
	input [ 10:0 ] avmmaddress,
	input [ 1:0 ] avmmbyteen,
	input [ 0:0 ] avmmclk,
	input [ 0:0 ] avmmread,
	input [ 0:0 ] avmmrstn,
	input [ 0:0 ] avmmwrite,
	input [ 15:0 ] avmmwritedata,
	input [ 0:0 ] devenadiv2n,
	input [ 0:0 ] devenadiv2p,
	input [ 0:0 ] devenbdiv2n,
	input [ 0:0 ] devenbdiv2p,
	input [ 0:0 ] div2270,
	input [ 0:0 ] div2270n,
	input [ 0:0 ] doddadiv2n,
	input [ 0:0 ] doddadiv2p,
	input [ 0:0 ] doddbdiv2n,
	input [ 0:0 ] doddbdiv2p,
	input [ 0:0 ] rstn,
	output [ 15:0 ] avmmreaddata,
	output [ 0:0 ] blockselect,
	output [ 0:0 ] clkdivrx,
	output [ 127:0 ] dataout,
        output observableintclk,
        output observableasyncdatain
); 

	stratixv_hssi_pma_deser_att_encrypted 
	#(
		.enable_debug_info(enable_debug_info)


	)
	stratixv_hssi_pma_deser_att_encrypted_inst	(
		.avmmaddress(avmmaddress),
		.avmmbyteen(avmmbyteen),
		.avmmclk(avmmclk),
		.avmmread(avmmread),
		.avmmrstn(avmmrstn),
		.avmmwrite(avmmwrite),
		.avmmwritedata(avmmwritedata),
		.devenadiv2n(devenadiv2n),
		.devenadiv2p(devenadiv2p),
		.devenbdiv2n(devenbdiv2n),
		.devenbdiv2p(devenbdiv2p),
		.div2270(div2270),
		.div2270n(div2270n),
		.doddadiv2n(doddadiv2n),
		.doddadiv2p(doddadiv2p),
		.doddbdiv2n(doddbdiv2n),
		.doddbdiv2p(doddbdiv2p),
		.rstn(rstn),
		.avmmreaddata(avmmreaddata),
		.blockselect(blockselect),
		.clkdivrx(clkdivrx),
		.dataout(dataout)
	);


endmodule
// --------------------------------------------------------------------
// This is auto-generated HSSI Simulation Atom Model Encryption Wrapper
// Module Name : ./sim_model_wrappers//stratixv_hssi_pma_tx_att_wrapper.v
// --------------------------------------------------------------------

`timescale 1 ps/1 ps
module stratixv_hssi_pma_tx_att
#(
	// parameter declaration and default value assignemnt
	parameter enable_debug_info = "false",	//Valid values: false|true; this is simulation-only parameter, for debug purpose only

	parameter tx_powerdown = "normal_tx_on",	//Valid values: normal_tx_on|power_down_tx
	parameter vod_ctrl_main_tap_level = "vod_0ma",	//Valid values: vod_0ma|vod_2ma|vod_4ma|vod_6ma|vod_8ma|vod_10ma
	parameter pre_emp_ctrl_post_tap_level = "fir_post_disabled",	//Valid values: fir_post_disabled|fir_post_p2ma|fir_post_p4ma|fir_post_p6ma|fir_post_p8ma|fir_post_1p0ma|fir_post_1p2ma|fir_post_1p4ma|fir_post_1p6ma|fir_post_1p8ma|fir_post_2p0ma|fir_post_2p2ma|fir_post_2p4ma|fir_post_2p6ma|fir_post_2p8ma|fir_post_3p0ma|fir_post_3p2ma|fir_post_3p4ma|fir_post_3p6ma|fir_post_3p8ma|fir_post_4p0ma|fir_post_4p2ma|fir_post_4p4ma|fir_post_4p6ma|fir_post_4p8ma|fir_post_5p0ma|fir_post_5p2ma|fir_post_5p4ma|fir_post_5p6ma|fir_post_5p8ma|fir_post_6p0ma|fir_post_6p2ma
	parameter pre_emp_ctrl_pre_tap_level = "fir_pre_disabled",	//Valid values: fir_pre_disabled|fir_pre_p2ma|fir_pre_p4ma|fir_pre_p6ma|fir_pre_p8ma|fir_pre_1p0ma|fir_pre_1p2ma|fir_pre_1p4ma|fir_pre_1p6ma|fir_pre_1p8ma|fir_pre_2p0ma|fir_pre_2p2ma|fir_pre_2p4ma|fir_pre_2p6ma|fir_pre_2p8ma|fir_pre_3p0ma|fir_pre_3p2ma|fir_pre_3p4ma|fir_pre_3p6ma|fir_pre_3p8ma|fir_pre_4p0ma|fir_pre_4p2ma|fir_pre_4p4ma|fir_pre_4p6ma|fir_pre_4p8ma|fir_pre_5p0ma|fir_pre_5p2ma|fir_pre_5p4ma|fir_pre_5p6ma|fir_pre_5p8ma|fir_pre_6p0ma|fir_pre_6p2ma
	parameter term_sel = "r_setting_7",	//Valid values: r_setting_1|r_setting_2|r_setting_3|r_setting_4|r_setting_5|r_setting_6|r_setting_7|r_setting_8|r_setting_9|r_setting_10|r_setting_11|r_setting_12|r_setting_13|r_setting_14|r_setting_15|r_setting_16
	parameter lst = "atb_disabled",	//Valid values: atb_disabled|atb_1|atb_2|atb_3|atb_4|atb_5|atb_6|atb_7|atb_8|atb_9|atb_10|atb_11|atb_12|atb_13|atb_14|atb_15
	parameter sig_inv_pre_tap = "non_inv_pre_tap",	//Valid values: non_inv_pre_tap|inv_pre_tap
	parameter high_vccehtx = "volt_1p5v",	//Valid values: not_used|volt_1p5v
	parameter vcm_current_addl = "low_current",	//Valid values: low_current|high_current
	parameter clock_monitor = "disable_clk_mon",	//Valid values: disable_clk_mon|enable_clk_mon
	parameter main_tap_lowpass_filter_en_0 = "enable_lp_main_0",	//Valid values: disable_lp_main_0|enable_lp_main_0
	parameter main_tap_lowpass_filter_en_1 = "enable_lp_main_1",	//Valid values: disable_lp_main_1|enable_lp_main_1
	parameter pre_tap_lowpass_filter_en_0 = "enable_lp_pre_0",	//Valid values: disable_lp_pre_0|enable_lp_pre_0
	parameter pre_tap_lowpass_filter_en_1 = "enable_lp_pre_1",	//Valid values: disable_lp_pre_1|enable_lp_pre_1
	parameter post_tap_lowpass_filter_en_0 = "enable_lp_post_0",	//Valid values: disable_lp_post_0|enable_lp_post_0
	parameter post_tap_lowpass_filter_en_1 = "enable_lp_post_1",	//Valid values: disable_lp_post_1|enable_lp_post_1
	parameter main_driver_switch_en_0 = "enable_main_switch_0",	//Valid values: disable_main_switch_0|enable_main_switch_0
	parameter main_driver_switch_en_1 = "enable_main_switch_1",	//Valid values: disable_main_switch_1|enable_main_switch_1
	parameter main_driver_switch_en_2 = "enable_main_switch_2",	//Valid values: disable_main_switch_2|enable_main_switch_2
	parameter main_driver_switch_en_3 = "disable_main_switch_3",	//Valid values: disable_main_switch_3|enable_main_switch_3
	parameter pre_driver_switch_en_0 = "disable_pre_switch_0",	//Valid values: disable_pre_switch_0|enable_pre_switch_0
	parameter pre_driver_switch_en_1 = "disable_pre_switch_1",	//Valid values: disable_pre_switch_1|enable_pre_switch_1
	parameter post_driver_switch_en_0 = "disable_post_switch_0",	//Valid values: disable_post_switch_0|enable_post_switch_0
	parameter post_driver_switch_en_1 = "disable_post_switch_1",	//Valid values: disable_post_switch_1|enable_post_switch_1
	parameter common_mode_driver_sel = "volt_0p65v",	//Valid values: volt_0p80v|volt_0p75v|volt_0p70v|volt_0p65v|volt_0p60v|volt_0p55v|volt_0p50v|volt_0p35v|pull_up|pull_dn|tristated1|grounded|pull_up_to_vccela|tristated2|tristated3|tristated4
	parameter revlb_select = "sel_met_lb",	//Valid values: sel_met_lb|sel_rev_ser_lb
	parameter rev_ser_lb_en = "disable_rev_ser_lb"	//Valid values: disable_rev_ser_lb|enable_rev_ser_lb
)
(
//input and output port declaration
	input [ 10:0 ] avmmaddress,
	input [ 1:0 ] avmmbyteen,
	input [ 0:0 ] avmmclk,
	input [ 0:0 ] avmmread,
	input [ 0:0 ] avmmrstn,
	input [ 0:0 ] avmmwrite,
	input [ 15:0 ] avmmwritedata,
	input [ 0:0 ] clk270bout,
	input [ 0:0 ] clk90bout,
	input [ 0:0 ] devenbout,
	input [ 0:0 ] devenout,
	input [ 0:0 ] doddbout,
	input [ 0:0 ] doddout,
	input [ 0:0 ] oe,
	input [ 0:0 ] oeb,
	input [ 0:0 ] oo,
	input [ 0:0 ] oob,
	input [ 0:0 ] rstn,
	input [ 0:0 ] rtxrlpbk,
	input [ 0:0 ] rxrlpbkn,
	input [ 0:0 ] rxrlpbkp,
	input [ 0:0 ] vonbidirin,
	input [ 0:0 ] vopbidirin,
	output [ 15:0 ] avmmreaddata,
	output [ 0:0 ] blockselect,
	output [ 0:0 ] vonbidirout,
	output [ 0:0 ] vopbidirout,
        input          nonuserfrompmaux
); 

	stratixv_hssi_pma_tx_att_encrypted 
	#(
		.enable_debug_info(enable_debug_info),

		.tx_powerdown(tx_powerdown),
		.vod_ctrl_main_tap_level(vod_ctrl_main_tap_level),
		.pre_emp_ctrl_post_tap_level(pre_emp_ctrl_post_tap_level),
		.pre_emp_ctrl_pre_tap_level(pre_emp_ctrl_pre_tap_level),
		.term_sel(term_sel),
		.lst(lst),
		.sig_inv_pre_tap(sig_inv_pre_tap),
		.high_vccehtx(high_vccehtx),
		.vcm_current_addl(vcm_current_addl),
		.clock_monitor(clock_monitor),
		.main_tap_lowpass_filter_en_0(main_tap_lowpass_filter_en_0),
		.main_tap_lowpass_filter_en_1(main_tap_lowpass_filter_en_1),
		.pre_tap_lowpass_filter_en_0(pre_tap_lowpass_filter_en_0),
		.pre_tap_lowpass_filter_en_1(pre_tap_lowpass_filter_en_1),
		.post_tap_lowpass_filter_en_0(post_tap_lowpass_filter_en_0),
		.post_tap_lowpass_filter_en_1(post_tap_lowpass_filter_en_1),
		.main_driver_switch_en_0(main_driver_switch_en_0),
		.main_driver_switch_en_1(main_driver_switch_en_1),
		.main_driver_switch_en_2(main_driver_switch_en_2),
		.main_driver_switch_en_3(main_driver_switch_en_3),
		.pre_driver_switch_en_0(pre_driver_switch_en_0),
		.pre_driver_switch_en_1(pre_driver_switch_en_1),
		.post_driver_switch_en_0(post_driver_switch_en_0),
		.post_driver_switch_en_1(post_driver_switch_en_1),
		.common_mode_driver_sel(common_mode_driver_sel),
		.revlb_select(revlb_select),
		.rev_ser_lb_en(rev_ser_lb_en)

	)
	stratixv_hssi_pma_tx_att_encrypted_inst	(
		.avmmaddress(avmmaddress),
		.avmmbyteen(avmmbyteen),
		.avmmclk(avmmclk),
		.avmmread(avmmread),
		.avmmrstn(avmmrstn),
		.avmmwrite(avmmwrite),
		.avmmwritedata(avmmwritedata),
		.clk270bout(clk270bout),
		.clk90bout(clk90bout),
		.devenbout(devenbout),
		.devenout(devenout),
		.doddbout(doddbout),
		.doddout(doddout),
		.oe(oe),
		.oeb(oeb),
		.oo(oo),
		.oob(oob),
		.rstn(rstn),
		.rtxrlpbk(rtxrlpbk),
		.rxrlpbkn(rxrlpbkn),
		.rxrlpbkp(rxrlpbkp),
		.vonbidirin(vonbidirin),
		.vopbidirin(vopbidirin),
		.avmmreaddata(avmmreaddata),
		.blockselect(blockselect),
		.vonbidirout(vonbidirout),
		.vopbidirout(vopbidirout)
	);


endmodule
// --------------------------------------------------------------------
// This is auto-generated HSSI Simulation Atom Model Encryption Wrapper
// Module Name : ./sim_model_wrappers//stratixv_hssi_pma_ser_att_wrapper.v
// --------------------------------------------------------------------

`timescale 1 ps/1 ps
module stratixv_hssi_pma_ser_att
#(
	// parameter declaration and default value assignemnt
	parameter enable_debug_info = "false",	//Valid values: false|true; this is simulation-only parameter, for debug purpose only

	parameter ser_pdb = "power_down",	//Valid values: power_down|power_up
	parameter ser_loopback = "loopback_disable"	//Valid values: loopback_enable|loopback_disable
)
(
//input and output port declaration
	input [ 10:0 ] avmmaddress,
	input [ 1:0 ] avmmbyteen,
	input [ 0:0 ] avmmclk,
	input [ 0:0 ] avmmread,
	input [ 0:0 ] avmmrstn,
	input [ 0:0 ] avmmwrite,
	input [ 15:0 ] avmmwritedata,
	input [ 0:0 ] clk0,
	input [ 0:0 ] clk180,
	input [ 127:0 ] datain,
	input [ 0:0 ] rstn,
	input [ 0:0 ] slpbk,
	output [ 15:0 ] avmmreaddata,
	output [ 0:0 ] blockselect,
	output [ 0:0 ] clkdivtxtop,
	output [ 0:0 ] lbvon,
	output [ 0:0 ] lbvop,
	output [ 0:0 ] oe,
	output [ 0:0 ] oeb,
	output [ 0:0 ] oo,
	output [ 0:0 ] oob,
        output observableintclk,
        output observablesyncdatain,
        output observableasyncdatain
); 

	stratixv_hssi_pma_ser_att_encrypted 
	#(
		.enable_debug_info(enable_debug_info),

		.ser_pdb(ser_pdb),
		.ser_loopback(ser_loopback)

	)
	stratixv_hssi_pma_ser_att_encrypted_inst	(
		.avmmaddress(avmmaddress),
		.avmmbyteen(avmmbyteen),
		.avmmclk(avmmclk),
		.avmmread(avmmread),
		.avmmrstn(avmmrstn),
		.avmmwrite(avmmwrite),
		.avmmwritedata(avmmwritedata),
		.clk0(clk0),
		.clk180(clk180),
		.datain(datain),
		.rstn(rstn),
		.slpbk(slpbk),
		.avmmreaddata(avmmreaddata),
		.blockselect(blockselect),
		.clkdivtxtop(clkdivtxtop),
		.lbvon(lbvon),
		.lbvop(lbvop),
		.oe(oe),
		.oeb(oeb),
		.oo(oo),
		.oob(oob)
	);


endmodule
// --------------------------------------------------------------------
// This is auto-generated HSSI Simulation Atom Model Encryption Wrapper
// Module Name : ./sim_model_wrappers//stratixv_hssi_common_pcs_pma_interface_wrapper.v
// --------------------------------------------------------------------

`timescale 1 ps/1 ps
module stratixv_hssi_common_pcs_pma_interface
#(
	// parameter declaration and default value assignemnt
	parameter enable_debug_info = "false",	//Valid values: false|true; this is simulation-only parameter, for debug purpose only

	parameter prot_mode = "disabled_prot_mode",	//Valid values: disabled_prot_mode|pipe_g1|pipe_g2|pipe_g3|other_protocols
	parameter pcie_gen3_cap = "non_pcie_gen3_cap",	//Valid values: pcie_gen3_cap|non_pcie_gen3_cap
	parameter refclk_dig_sel = "refclk_dig_dis",	//Valid values: refclk_dig_dis|refclk_dig_en
	parameter force_freqdet = "force_freqdet_dis",	//Valid values: force_freqdet_dis|force1_freqdet_en|force0_freqdet_en
	parameter ppmsel = "ppmsel_default",	//Valid values: ppmsel_default|ppmsel_1000|ppmsel_500|ppmsel_300|ppmsel_250|ppmsel_200|ppmsel_125|ppmsel_100|ppmsel_62p5|ppm_other
	parameter ppm_cnt_rst = "ppm_cnt_rst_dis",	//Valid values: ppm_cnt_rst_dis|ppm_cnt_rst_en
	parameter auto_speed_ena = "dis_auto_speed_ena",	//Valid values: dis_auto_speed_ena|en_auto_speed_ena
	parameter ppm_gen1_2_cnt = "cnt_32k",	//Valid values: cnt_32k|cnt_64k
	parameter ppm_post_eidle_delay = "cnt_200_cycles",	//Valid values: cnt_200_cycles|cnt_400_cycles
	parameter func_mode = "disable",	//Valid values: disable|pma_direct|hrdrstctrl_cmu|eightg_only_pld|eightg_and_g3|eightg_only_emsip|teng_only|eightgtx_and_tengrx|eightgrx_and_tengtx
	parameter pma_if_dft_val = "dft_0",	//Valid values: dft_0
	parameter sup_mode = "user_mode",	//Valid values: user_mode|engineering_mode|stretch_mode
	parameter selectpcs = "eight_g_pcs",	//Valid values: eight_g_pcs|pcie_gen3
	parameter ppm_deassert_early = "deassert_early_dis",	//Valid values: deassert_early_dis|deassert_early_en
	parameter pipe_if_g3pcs = "pipe_if_8gpcs",	//Valid values: pipe_if_g3pcs|pipe_if_8gpcs
	parameter pma_if_dft_en = "dft_dis",	//Valid values: dft_dis
	parameter avmm_group_channel_index = 0,	//Valid values: 0..2
	parameter use_default_base_address = "true",	//Valid values: false|true
	parameter user_base_address = 0	//Valid values: 0..2047
)
(
//input and output port declaration
	input [ 0:0 ] aggalignstatus,
	input [ 0:0 ] aggalignstatussync0,
	input [ 0:0 ] aggalignstatussync0toporbot,
	input [ 0:0 ] aggalignstatustoporbot,
	input [ 0:0 ] aggcgcomprddall,
	input [ 0:0 ] aggcgcomprddalltoporbot,
	input [ 0:0 ] aggcgcompwrall,
	input [ 0:0 ] aggcgcompwralltoporbot,
	input [ 0:0 ] aggdelcondmet0,
	input [ 0:0 ] aggdelcondmet0toporbot,
	input [ 0:0 ] aggendskwqd,
	input [ 0:0 ] aggendskwqdtoporbot,
	input [ 0:0 ] aggendskwrdptrs,
	input [ 0:0 ] aggendskwrdptrstoporbot,
	input [ 0:0 ] aggfifoovr0,
	input [ 0:0 ] aggfifoovr0toporbot,
	input [ 0:0 ] aggfifordincomp0,
	input [ 0:0 ] aggfifordincomp0toporbot,
	input [ 0:0 ] aggfiforstrdqd,
	input [ 0:0 ] aggfiforstrdqdtoporbot,
	input [ 0:0 ] agginsertincomplete0,
	input [ 0:0 ] agginsertincomplete0toporbot,
	input [ 0:0 ] agglatencycomp0,
	input [ 0:0 ] agglatencycomp0toporbot,
	input [ 0:0 ] aggrcvdclkagg,
	input [ 0:0 ] aggrcvdclkaggtoporbot,
	input [ 0:0 ] aggrxcontrolrs,
	input [ 0:0 ] aggrxcontrolrstoporbot,
	input [ 7:0 ] aggrxdatars,
	input [ 7:0 ] aggrxdatarstoporbot,
	input [ 15:0 ] aggtestbus,
	input [ 0:0 ] aggtestsotopldin,
	input [ 0:0 ] aggtxctlts,
	input [ 0:0 ] aggtxctltstoporbot,
	input [ 7:0 ] aggtxdatats,
	input [ 7:0 ] aggtxdatatstoporbot,
	input [ 10:0 ] avmmaddress,
	input [ 1:0 ] avmmbyteen,
	input [ 0:0 ] avmmclk,
	input [ 0:0 ] avmmread,
	input [ 0:0 ] avmmrstn,
	input [ 0:0 ] avmmwrite,
	input [ 15:0 ] avmmwritedata,
	input [ 0:0 ] clklow,
	input [ 0:0 ] fref,
	input [ 0:0 ] hardreset,
	input [ 0:0 ] pcs8gearlyeios,
	input [ 0:0 ] pcs8geidleexit,
	input [ 0:0 ] pcs8gltrpma,
	input [ 0:0 ] pcs8gpcieswitch,
	input [ 17:0 ] pcs8gpmacurrentcoeff,
	input [ 0:0 ] pcs8gtxdetectrx,
	input [ 0:0 ] pcs8gtxelecidle,
	input [ 1:0 ] pcsaggaligndetsync,
	input [ 0:0 ] pcsaggalignstatussync,
	input [ 1:0 ] pcsaggcgcomprddout,
	input [ 1:0 ] pcsaggcgcompwrout,
	input [ 0:0 ] pcsaggdecctl,
	input [ 7:0 ] pcsaggdecdata,
	input [ 0:0 ] pcsaggdecdatavalid,
	input [ 0:0 ] pcsaggdelcondmetout,
	input [ 0:0 ] pcsaggfifoovrout,
	input [ 0:0 ] pcsaggfifordoutcomp,
	input [ 0:0 ] pcsagginsertincompleteout,
	input [ 0:0 ] pcsagglatencycompout,
	input [ 1:0 ] pcsaggrdalign,
	input [ 0:0 ] pcsaggrdenablesync,
	input [ 0:0 ] pcsaggrefclkdig,
	input [ 1:0 ] pcsaggrunningdisp,
	input [ 0:0 ] pcsaggrxpcsrst,
	input [ 0:0 ] pcsaggscanmoden,
	input [ 0:0 ] pcsaggscanshiftn,
	input [ 0:0 ] pcsaggsyncstatus,
	input [ 0:0 ] pcsaggtxctltc,
	input [ 7:0 ] pcsaggtxdatatc,
	input [ 0:0 ] pcsaggtxpcsrst,
	input [ 0:0 ] pcsgen3gen3datasel,
	input [ 17:0 ] pcsgen3pmacurrentcoeff,
	input [ 2:0 ] pcsgen3pmacurrentrxpreset,
	input [ 0:0 ] pcsgen3pmaearlyeios,
	input [ 0:0 ] pcsgen3pmaltr,
	input [ 1:0 ] pcsgen3pmapcieswitch,
	input [ 0:0 ] pcsgen3pmatxdetectrx,
	input [ 0:0 ] pcsgen3pmatxelecidle,
	input [ 0:0 ] pcsgen3ppmeidleexit,
	input [ 0:0 ] pcsrefclkdig,
	input [ 0:0 ] pcsscanmoden,
	input [ 0:0 ] pcsscanshiftn,
	input [ 0:0 ] pldlccmurstb,
	input [ 0:0 ] pldnfrzdrv,
	input [ 0:0 ] pldpartialreconfig,
	input [ 0:0 ] pldtestsitoaggin,
	input [ 0:0 ] pmahclk,
	input [ 0:0 ] pmaoffcalenin,
	input [ 1:0 ] pmapcieswdone,
	input [ 0:0 ] pmarxdetectvalid,
	input [ 0:0 ] pmarxfound,
	input [ 0:0 ] pmarxpmarstb,
	input [ 0:0 ] resetppmcntrs,
	output [ 1:0 ] aggaligndetsync,
	output [ 0:0 ] aggalignstatussync,
	output [ 1:0 ] aggcgcomprddout,
	output [ 1:0 ] aggcgcompwrout,
	output [ 0:0 ] aggdecctl,
	output [ 7:0 ] aggdecdata,
	output [ 0:0 ] aggdecdatavalid,
	output [ 0:0 ] aggdelcondmetout,
	output [ 0:0 ] aggfifoovrout,
	output [ 0:0 ] aggfifordoutcomp,
	output [ 0:0 ] agginsertincompleteout,
	output [ 0:0 ] agglatencycompout,
	output [ 1:0 ] aggrdalign,
	output [ 0:0 ] aggrdenablesync,
	output [ 0:0 ] aggrefclkdig,
	output [ 1:0 ] aggrunningdisp,
	output [ 0:0 ] aggrxpcsrst,
	output [ 0:0 ] aggscanmoden,
	output [ 0:0 ] aggscanshiftn,
	output [ 0:0 ] aggsyncstatus,
	output [ 0:0 ] aggtestsotopldout,
	output [ 0:0 ] aggtxctltc,
	output [ 7:0 ] aggtxdatatc,
	output [ 0:0 ] aggtxpcsrst,
	output [ 0:0 ] asynchdatain,
	output [ 15:0 ] avmmreaddata,
	output [ 0:0 ] blockselect,
	output [ 0:0 ] freqlock,
	output [ 0:0 ] pcs8ggen2ngen1,
	output [ 0:0 ] pcs8gpmarxfound,
	output [ 0:0 ] pcs8gpowerstatetransitiondone,
	output [ 0:0 ] pcs8grxdetectvalid,
	output [ 0:0 ] pcsaggalignstatus,
	output [ 0:0 ] pcsaggalignstatussync0,
	output [ 0:0 ] pcsaggalignstatussync0toporbot,
	output [ 0:0 ] pcsaggalignstatustoporbot,
	output [ 0:0 ] pcsaggcgcomprddall,
	output [ 0:0 ] pcsaggcgcomprddalltoporbot,
	output [ 0:0 ] pcsaggcgcompwrall,
	output [ 0:0 ] pcsaggcgcompwralltoporbot,
	output [ 0:0 ] pcsaggdelcondmet0,
	output [ 0:0 ] pcsaggdelcondmet0toporbot,
	output [ 0:0 ] pcsaggendskwqd,
	output [ 0:0 ] pcsaggendskwqdtoporbot,
	output [ 0:0 ] pcsaggendskwrdptrs,
	output [ 0:0 ] pcsaggendskwrdptrstoporbot,
	output [ 0:0 ] pcsaggfifoovr0,
	output [ 0:0 ] pcsaggfifoovr0toporbot,
	output [ 0:0 ] pcsaggfifordincomp0,
	output [ 0:0 ] pcsaggfifordincomp0toporbot,
	output [ 0:0 ] pcsaggfiforstrdqd,
	output [ 0:0 ] pcsaggfiforstrdqdtoporbot,
	output [ 0:0 ] pcsagginsertincomplete0,
	output [ 0:0 ] pcsagginsertincomplete0toporbot,
	output [ 0:0 ] pcsagglatencycomp0,
	output [ 0:0 ] pcsagglatencycomp0toporbot,
	output [ 0:0 ] pcsaggrcvdclkagg,
	output [ 0:0 ] pcsaggrcvdclkaggtoporbot,
	output [ 0:0 ] pcsaggrxcontrolrs,
	output [ 0:0 ] pcsaggrxcontrolrstoporbot,
	output [ 7:0 ] pcsaggrxdatars,
	output [ 7:0 ] pcsaggrxdatarstoporbot,
	output [ 15:0 ] pcsaggtestbus,
	output [ 0:0 ] pcsaggtxctlts,
	output [ 0:0 ] pcsaggtxctltstoporbot,
	output [ 7:0 ] pcsaggtxdatats,
	output [ 7:0 ] pcsaggtxdatatstoporbot,
	output [ 0:0 ] pcsgen3pllfixedclk,
	output [ 1:0 ] pcsgen3pmapcieswdone,
	output [ 0:0 ] pcsgen3pmarxdetectvalid,
	output [ 0:0 ] pcsgen3pmarxfound,
	output [ 0:0 ] pldhclkout,
	output [ 0:0 ] pldtestsitoaggout,
	output [ 0:0 ] pmaclklowout,
	output [ 17:0 ] pmacurrentcoeff,
	output [ 2:0 ] pmacurrentrxpreset,
	output [ 0:0 ] pmaearlyeios,
	output [ 0:0 ] pmafrefout,
	output [ 9:0 ] pmaiftestbus,
	output [ 0:0 ] pmalccmurstb,
	output [ 0:0 ] pmaltr,
	output [ 0:0 ] pmanfrzdrv,
	output [ 0:0 ] pmaoffcaldone,
	output [ 0:0 ] pmapartialreconfig,
	output [ 1:0 ] pmapcieswitch,
	output [ 0:0 ] pmatxdetectrx,
	output [ 0:0 ] pmatxelecidle
); 

	stratixv_hssi_common_pcs_pma_interface_encrypted 
	#(
		.enable_debug_info(enable_debug_info),

		.prot_mode(prot_mode),
		.pcie_gen3_cap(pcie_gen3_cap),
		.refclk_dig_sel(refclk_dig_sel),
		.force_freqdet(force_freqdet),
		.ppmsel(ppmsel),
		.ppm_cnt_rst(ppm_cnt_rst),
		.auto_speed_ena(auto_speed_ena),
		.ppm_gen1_2_cnt(ppm_gen1_2_cnt),
		.ppm_post_eidle_delay(ppm_post_eidle_delay),
		.func_mode(func_mode),
		.pma_if_dft_val(pma_if_dft_val),
		.sup_mode(sup_mode),
		.selectpcs(selectpcs),
		.ppm_deassert_early(ppm_deassert_early),
		.pipe_if_g3pcs(pipe_if_g3pcs),
		.pma_if_dft_en(pma_if_dft_en),
		.avmm_group_channel_index(avmm_group_channel_index),
		.use_default_base_address(use_default_base_address),
		.user_base_address(user_base_address)

	)
	stratixv_hssi_common_pcs_pma_interface_encrypted_inst	(
		.aggalignstatus(aggalignstatus),
		.aggalignstatussync0(aggalignstatussync0),
		.aggalignstatussync0toporbot(aggalignstatussync0toporbot),
		.aggalignstatustoporbot(aggalignstatustoporbot),
		.aggcgcomprddall(aggcgcomprddall),
		.aggcgcomprddalltoporbot(aggcgcomprddalltoporbot),
		.aggcgcompwrall(aggcgcompwrall),
		.aggcgcompwralltoporbot(aggcgcompwralltoporbot),
		.aggdelcondmet0(aggdelcondmet0),
		.aggdelcondmet0toporbot(aggdelcondmet0toporbot),
		.aggendskwqd(aggendskwqd),
		.aggendskwqdtoporbot(aggendskwqdtoporbot),
		.aggendskwrdptrs(aggendskwrdptrs),
		.aggendskwrdptrstoporbot(aggendskwrdptrstoporbot),
		.aggfifoovr0(aggfifoovr0),
		.aggfifoovr0toporbot(aggfifoovr0toporbot),
		.aggfifordincomp0(aggfifordincomp0),
		.aggfifordincomp0toporbot(aggfifordincomp0toporbot),
		.aggfiforstrdqd(aggfiforstrdqd),
		.aggfiforstrdqdtoporbot(aggfiforstrdqdtoporbot),
		.agginsertincomplete0(agginsertincomplete0),
		.agginsertincomplete0toporbot(agginsertincomplete0toporbot),
		.agglatencycomp0(agglatencycomp0),
		.agglatencycomp0toporbot(agglatencycomp0toporbot),
		.aggrcvdclkagg(aggrcvdclkagg),
		.aggrcvdclkaggtoporbot(aggrcvdclkaggtoporbot),
		.aggrxcontrolrs(aggrxcontrolrs),
		.aggrxcontrolrstoporbot(aggrxcontrolrstoporbot),
		.aggrxdatars(aggrxdatars),
		.aggrxdatarstoporbot(aggrxdatarstoporbot),
		.aggtestbus(aggtestbus),
		.aggtestsotopldin(aggtestsotopldin),
		.aggtxctlts(aggtxctlts),
		.aggtxctltstoporbot(aggtxctltstoporbot),
		.aggtxdatats(aggtxdatats),
		.aggtxdatatstoporbot(aggtxdatatstoporbot),
		.avmmaddress(avmmaddress),
		.avmmbyteen(avmmbyteen),
		.avmmclk(avmmclk),
		.avmmread(avmmread),
		.avmmrstn(avmmrstn),
		.avmmwrite(avmmwrite),
		.avmmwritedata(avmmwritedata),
		.clklow(clklow),
		.fref(fref),
		.hardreset(hardreset),
		.pcs8gearlyeios(pcs8gearlyeios),
		.pcs8geidleexit(pcs8geidleexit),
		.pcs8gltrpma(pcs8gltrpma),
		.pcs8gpcieswitch(pcs8gpcieswitch),
		.pcs8gpmacurrentcoeff(pcs8gpmacurrentcoeff),
		.pcs8gtxdetectrx(pcs8gtxdetectrx),
		.pcs8gtxelecidle(pcs8gtxelecidle),
		.pcsaggaligndetsync(pcsaggaligndetsync),
		.pcsaggalignstatussync(pcsaggalignstatussync),
		.pcsaggcgcomprddout(pcsaggcgcomprddout),
		.pcsaggcgcompwrout(pcsaggcgcompwrout),
		.pcsaggdecctl(pcsaggdecctl),
		.pcsaggdecdata(pcsaggdecdata),
		.pcsaggdecdatavalid(pcsaggdecdatavalid),
		.pcsaggdelcondmetout(pcsaggdelcondmetout),
		.pcsaggfifoovrout(pcsaggfifoovrout),
		.pcsaggfifordoutcomp(pcsaggfifordoutcomp),
		.pcsagginsertincompleteout(pcsagginsertincompleteout),
		.pcsagglatencycompout(pcsagglatencycompout),
		.pcsaggrdalign(pcsaggrdalign),
		.pcsaggrdenablesync(pcsaggrdenablesync),
		.pcsaggrefclkdig(pcsaggrefclkdig),
		.pcsaggrunningdisp(pcsaggrunningdisp),
		.pcsaggrxpcsrst(pcsaggrxpcsrst),
		.pcsaggscanmoden(pcsaggscanmoden),
		.pcsaggscanshiftn(pcsaggscanshiftn),
		.pcsaggsyncstatus(pcsaggsyncstatus),
		.pcsaggtxctltc(pcsaggtxctltc),
		.pcsaggtxdatatc(pcsaggtxdatatc),
		.pcsaggtxpcsrst(pcsaggtxpcsrst),
		.pcsgen3gen3datasel(pcsgen3gen3datasel),
		.pcsgen3pmacurrentcoeff(pcsgen3pmacurrentcoeff),
		.pcsgen3pmacurrentrxpreset(pcsgen3pmacurrentrxpreset),
		.pcsgen3pmaearlyeios(pcsgen3pmaearlyeios),
		.pcsgen3pmaltr(pcsgen3pmaltr),
		.pcsgen3pmapcieswitch(pcsgen3pmapcieswitch),
		.pcsgen3pmatxdetectrx(pcsgen3pmatxdetectrx),
		.pcsgen3pmatxelecidle(pcsgen3pmatxelecidle),
		.pcsgen3ppmeidleexit(pcsgen3ppmeidleexit),
		.pcsrefclkdig(pcsrefclkdig),
		.pcsscanmoden(pcsscanmoden),
		.pcsscanshiftn(pcsscanshiftn),
		.pldlccmurstb(pldlccmurstb),
		.pldnfrzdrv(pldnfrzdrv),
		.pldpartialreconfig(pldpartialreconfig),
		.pldtestsitoaggin(pldtestsitoaggin),
		.pmahclk(pmahclk),
		.pmaoffcalenin(pmaoffcalenin),
		.pmapcieswdone(pmapcieswdone),
		.pmarxdetectvalid(pmarxdetectvalid),
		.pmarxfound(pmarxfound),
		.pmarxpmarstb(pmarxpmarstb),
		.resetppmcntrs(resetppmcntrs),
		.aggaligndetsync(aggaligndetsync),
		.aggalignstatussync(aggalignstatussync),
		.aggcgcomprddout(aggcgcomprddout),
		.aggcgcompwrout(aggcgcompwrout),
		.aggdecctl(aggdecctl),
		.aggdecdata(aggdecdata),
		.aggdecdatavalid(aggdecdatavalid),
		.aggdelcondmetout(aggdelcondmetout),
		.aggfifoovrout(aggfifoovrout),
		.aggfifordoutcomp(aggfifordoutcomp),
		.agginsertincompleteout(agginsertincompleteout),
		.agglatencycompout(agglatencycompout),
		.aggrdalign(aggrdalign),
		.aggrdenablesync(aggrdenablesync),
		.aggrefclkdig(aggrefclkdig),
		.aggrunningdisp(aggrunningdisp),
		.aggrxpcsrst(aggrxpcsrst),
		.aggscanmoden(aggscanmoden),
		.aggscanshiftn(aggscanshiftn),
		.aggsyncstatus(aggsyncstatus),
		.aggtestsotopldout(aggtestsotopldout),
		.aggtxctltc(aggtxctltc),
		.aggtxdatatc(aggtxdatatc),
		.aggtxpcsrst(aggtxpcsrst),
		.asynchdatain(asynchdatain),
		.avmmreaddata(avmmreaddata),
		.blockselect(blockselect),
		.freqlock(freqlock),
		.pcs8ggen2ngen1(pcs8ggen2ngen1),
		.pcs8gpmarxfound(pcs8gpmarxfound),
		.pcs8gpowerstatetransitiondone(pcs8gpowerstatetransitiondone),
		.pcs8grxdetectvalid(pcs8grxdetectvalid),
		.pcsaggalignstatus(pcsaggalignstatus),
		.pcsaggalignstatussync0(pcsaggalignstatussync0),
		.pcsaggalignstatussync0toporbot(pcsaggalignstatussync0toporbot),
		.pcsaggalignstatustoporbot(pcsaggalignstatustoporbot),
		.pcsaggcgcomprddall(pcsaggcgcomprddall),
		.pcsaggcgcomprddalltoporbot(pcsaggcgcomprddalltoporbot),
		.pcsaggcgcompwrall(pcsaggcgcompwrall),
		.pcsaggcgcompwralltoporbot(pcsaggcgcompwralltoporbot),
		.pcsaggdelcondmet0(pcsaggdelcondmet0),
		.pcsaggdelcondmet0toporbot(pcsaggdelcondmet0toporbot),
		.pcsaggendskwqd(pcsaggendskwqd),
		.pcsaggendskwqdtoporbot(pcsaggendskwqdtoporbot),
		.pcsaggendskwrdptrs(pcsaggendskwrdptrs),
		.pcsaggendskwrdptrstoporbot(pcsaggendskwrdptrstoporbot),
		.pcsaggfifoovr0(pcsaggfifoovr0),
		.pcsaggfifoovr0toporbot(pcsaggfifoovr0toporbot),
		.pcsaggfifordincomp0(pcsaggfifordincomp0),
		.pcsaggfifordincomp0toporbot(pcsaggfifordincomp0toporbot),
		.pcsaggfiforstrdqd(pcsaggfiforstrdqd),
		.pcsaggfiforstrdqdtoporbot(pcsaggfiforstrdqdtoporbot),
		.pcsagginsertincomplete0(pcsagginsertincomplete0),
		.pcsagginsertincomplete0toporbot(pcsagginsertincomplete0toporbot),
		.pcsagglatencycomp0(pcsagglatencycomp0),
		.pcsagglatencycomp0toporbot(pcsagglatencycomp0toporbot),
		.pcsaggrcvdclkagg(pcsaggrcvdclkagg),
		.pcsaggrcvdclkaggtoporbot(pcsaggrcvdclkaggtoporbot),
		.pcsaggrxcontrolrs(pcsaggrxcontrolrs),
		.pcsaggrxcontrolrstoporbot(pcsaggrxcontrolrstoporbot),
		.pcsaggrxdatars(pcsaggrxdatars),
		.pcsaggrxdatarstoporbot(pcsaggrxdatarstoporbot),
		.pcsaggtestbus(pcsaggtestbus),
		.pcsaggtxctlts(pcsaggtxctlts),
		.pcsaggtxctltstoporbot(pcsaggtxctltstoporbot),
		.pcsaggtxdatats(pcsaggtxdatats),
		.pcsaggtxdatatstoporbot(pcsaggtxdatatstoporbot),
		.pcsgen3pllfixedclk(pcsgen3pllfixedclk),
		.pcsgen3pmapcieswdone(pcsgen3pmapcieswdone),
		.pcsgen3pmarxdetectvalid(pcsgen3pmarxdetectvalid),
		.pcsgen3pmarxfound(pcsgen3pmarxfound),
		.pldhclkout(pldhclkout),
		.pldtestsitoaggout(pldtestsitoaggout),
		.pmaclklowout(pmaclklowout),
		.pmacurrentcoeff(pmacurrentcoeff),
		.pmacurrentrxpreset(pmacurrentrxpreset),
		.pmaearlyeios(pmaearlyeios),
		.pmafrefout(pmafrefout),
		.pmaiftestbus(pmaiftestbus),
		.pmalccmurstb(pmalccmurstb),
		.pmaltr(pmaltr),
		.pmanfrzdrv(pmanfrzdrv),
		.pmaoffcaldone(pmaoffcaldone),
		.pmapartialreconfig(pmapartialreconfig),
		.pmapcieswitch(pmapcieswitch),
		.pmatxdetectrx(pmatxdetectrx),
		.pmatxelecidle(pmatxelecidle)
	);


endmodule
// --------------------------------------------------------------------
// This is auto-generated HSSI Simulation Atom Model Encryption Wrapper
// Module Name : ./sim_model_wrappers//stratixv_hssi_common_pld_pcs_interface_wrapper.v
// --------------------------------------------------------------------

`timescale 1 ps/1 ps
module stratixv_hssi_common_pld_pcs_interface
#(
	// parameter declaration and default value assignemnt
	parameter enable_debug_info = "false",	//Valid values: false|true; this is simulation-only parameter, for debug purpose only

	parameter emsip_enable = "emsip_disable",	//Valid values: emsip_enable|emsip_disable
	parameter pld_side_reserved_source0 = "pld_res0",	//Valid values: pld_res0|emsip_res0
	parameter hrdrstctrl_en_cfgusr = "hrst_dis_cfgusr",	//Valid values: hrst_dis_cfgusr|hrst_en_cfgusr
	parameter pld_side_reserved_source10 = "pld_res10",	//Valid values: pld_res10|emsip_res10
	parameter data_source = "pld",	//Valid values: emsip|pld
	parameter pld_side_reserved_source1 = "pld_res1",	//Valid values: pld_res1|emsip_res1
	parameter pld_side_reserved_source2 = "pld_res2",	//Valid values: pld_res2|emsip_res2
	parameter pld_side_reserved_source3 = "pld_res3",	//Valid values: pld_res3|emsip_res3
	parameter pld_side_reserved_source4 = "pld_res4",	//Valid values: pld_res4|emsip_res4
	parameter pld_side_reserved_source5 = "pld_res5",	//Valid values: pld_res5|emsip_res5
	parameter pld_side_reserved_source6 = "pld_res6",	//Valid values: pld_res6|emsip_res6
	parameter pld_side_reserved_source7 = "pld_res7",	//Valid values: pld_res7|emsip_res7
	parameter pld_side_reserved_source8 = "pld_res8",	//Valid values: pld_res8|emsip_res8
	parameter pld_side_reserved_source9 = "pld_res9",	//Valid values: pld_res9|emsip_res9
	parameter hrdrstctrl_en_cfg = "hrst_dis_cfg",	//Valid values: hrst_dis_cfg|hrst_en_cfg
	parameter testbus_sel = "eight_g_pcs",	//Valid values: eight_g_pcs|g3_pcs|ten_g_pcs|pma_if
	parameter usrmode_sel4rst = "usermode",	//Valid values: usermode|last_frz
	parameter pld_side_reserved_source11 = "pld_res11",	//Valid values: pld_res11|emsip_res11
	parameter avmm_group_channel_index = 0,	//Valid values: 0..2
	parameter use_default_base_address = "true",	//Valid values: false|true
	parameter user_base_address = 0	//Valid values: 0..2047
)
(
//input and output port declaration
	input [ 19:0 ] pcs10gtestdata,
	input [ 0:0 ] pcs8gphystatus,
	input [ 0:0 ] pcs8grxelecidle,
	input [ 2:0 ] pcs8grxstatus,
	input [ 0:0 ] pcs8grxvalid,
	input [ 0:0 ] pcsgen3masktxpll,
	input [ 19:0 ] pcsgen3testout,
	input [ 0:0 ] pld10grefclkdig,
	input [ 1:0 ] pld8gpowerdown,
	input [ 0:0 ] pld8gprbsciden,
	input [ 0:0 ] pld8grefclkdig,
	input [ 0:0 ] pld8grxpolarity,
	input [ 0:0 ] pld8gtxdeemph,
	input [ 0:0 ] pld8gtxdetectrxloopback,
	input [ 0:0 ] pld8gtxelecidle,
	input [ 2:0 ] pld8gtxmargin,
	input [ 0:0 ] pld8gtxswing,
	input [ 0:0 ] pldaggrefclkdig,
	input [ 2:0 ] pldeidleinfersel,
	input [ 17:0 ] pldgen3currentcoeff,
	input [ 2:0 ] pldgen3currentrxpreset,
	input [ 0:0 ] pldhclkin,
	input [ 0:0 ] pldoffcaldonein,
	input [ 0:0 ] pldpcspmaifrefclkdig,
	input [ 1:0 ] pldrate,
	input [ 0:0 ] pmaclklow,
	input [ 0:0 ] pmafref,
	input [ 0:0 ] pmaoffcalen,
	input [ 10:0 ] avmmaddress,
	input [ 1:0 ] avmmbyteen,
	input [ 0:0 ] avmmrstn,
	input [ 37:0 ] emsipcomin,
	input [ 19:0 ] emsipcomspecialin,
	input [ 0:0 ] entest,
	input [ 0:0 ] frzreg,
	input [ 0:0 ] iocsrrdydly,
	input [ 0:0 ] nfrzdrv,
	input [ 0:0 ] npor,
	input [ 3:0 ] pcs10gextraout,
	input [ 8:0 ] pcs10gtestso,
	input [ 19:0 ] pcs8gchnltestbusout,
	input [ 2:0 ] pcs8gpldextraout,
	input [ 5:0 ] pcs8gtestso,
	input [ 0:0 ] pcsaggtestso,
	input [ 3:0 ] pcsgen3extraout,
	input [ 17:0 ] pcsgen3rxdeemph,
	input [ 1:0 ] pcsgen3rxeqctrl,
	input [ 2:0 ] pcsgen3testso,
	input [ 9:0 ] pcspmaiftestbusout,
	input [ 0:0 ] pcspmaiftestso,
	input [ 0:0 ] pld8grefclkdig2,
	input [ 0:0 ] pldltr,
	input [ 0:0 ] pldoffcaldone,
	input [ 0:0 ] pldpartialreconfigin,
	input [ 11:0 ] pldreservedin,
	input [ 0:0 ] pldscanmoden,
	input [ 0:0 ] pldscanshiftn,
	input [ 0:0 ] plniotri,
	input [ 0:0 ] usermode,
	input [ 0:0 ] avmmclk,
	input [ 0:0 ] avmmread,
	input [ 0:0 ] avmmwrite,
	input [ 15:0 ] avmmwritedata,
	output [ 0:0 ] asynchdatain,
	output [ 0:0 ] pcs10ghardreset,
	output [ 0:0 ] pcs10ghardresetn,
	output [ 0:0 ] pcs10grefclkdig,
	output [ 2:0 ] pcs8geidleinfersel,
	output [ 0:0 ] pcs8gltr,
	output [ 1:0 ] pcs8gpowerdown,
	output [ 0:0 ] pcs8gprbsciden,
	output [ 0:0 ] pcs8grate,
	output [ 0:0 ] pcs8grefclkdig,
	output [ 0:0 ] pcs8grxpolarity,
	output [ 0:0 ] pcs8gtxdeemph,
	output [ 0:0 ] pcs8gtxdetectrxloopback,
	output [ 0:0 ] pcs8gtxelecidle,
	output [ 2:0 ] pcs8gtxmargin,
	output [ 0:0 ] pcs8gtxswing,
	output [ 0:0 ] pcsaggrefclkdig,
	output [ 17:0 ] pcsgen3currentcoeff,
	output [ 2:0 ] pcsgen3currentrxpreset,
	output [ 2:0 ] pcsgen3eidleinfersel,
	output [ 0:0 ] pcsgen3pldltr,
	output [ 1:0 ] pcsgen3rate,
	output [ 0:0 ] pcspcspmaifrefclkdig,
	output [ 0:0 ] pcspcspmaifscanmoden,
	output [ 0:0 ] pcspcspmaifscanshiftn,
	output [ 0:0 ] pld8gphystatus,
	output [ 0:0 ] pld8grxelecidle,
	output [ 2:0 ] pld8grxstatus,
	output [ 0:0 ] pld8grxvalid,
	output [ 0:0 ] pldclklow,
	output [ 0:0 ] pldfref,
	output [ 0:0 ] pldgen3masktxpll,
	output [ 0:0 ] pldoffcaldoneout,
	output [ 0:0 ] pldoffcalen,
	output [ 19:0 ] pldtestdata,
	output [ 2:0 ] emsipcomclkout,
	output [ 26:0 ] emsipcomout,
	output [ 19:0 ] emsipcomspecialout,
	output [ 0:0 ] emsipenablediocsrrdydly,
	output [ 3:0 ] pcs10gextrain,
	output [ 8:0 ] pcs10gtestsi,
	output [ 0:0 ] pcs8ghardreset,
	output [ 0:0 ] pcs8ghardresetn,
	output [ 3:0 ] pcs8gpldextrain,
	output [ 0:0 ] pcs8grefclkdig2,
	output [ 0:0 ] pcs8gscanmoden,
	output [ 5:0 ] pcs8gtestsi,
	output [ 0:0 ] pcsaggtestsi,
	output [ 3:0 ] pcsgen3extrain,
	output [ 0:0 ] pcsgen3hardreset,
	output [ 0:0 ] pcsgen3scanmoden,
	output [ 2:0 ] pcsgen3testsi,
	output [ 0:0 ] pcspmaifhardreset,
	output [ 0:0 ] pcspmaiftestsi,
	output [ 17:0 ] pldgen3rxdeemph,
	output [ 1:0 ] pldgen3rxeqctrl,
	output [ 0:0 ] pldnfrzdrv,
	output [ 0:0 ] pldpartialreconfigout,
	output [ 10:0 ] pldreservedout,
	output [ 0:0 ] rstsel,
	output [ 0:0 ] usrrstsel,
	output [ 15:0 ] avmmreaddata,
	output [ 0:0 ] blockselect
); 

	stratixv_hssi_common_pld_pcs_interface_encrypted 
	#(
		.enable_debug_info(enable_debug_info),

		.emsip_enable(emsip_enable),
		.pld_side_reserved_source0(pld_side_reserved_source0),
		.hrdrstctrl_en_cfgusr(hrdrstctrl_en_cfgusr),
		.pld_side_reserved_source10(pld_side_reserved_source10),
		.data_source(data_source),
		.pld_side_reserved_source1(pld_side_reserved_source1),
		.pld_side_reserved_source2(pld_side_reserved_source2),
		.pld_side_reserved_source3(pld_side_reserved_source3),
		.pld_side_reserved_source4(pld_side_reserved_source4),
		.pld_side_reserved_source5(pld_side_reserved_source5),
		.pld_side_reserved_source6(pld_side_reserved_source6),
		.pld_side_reserved_source7(pld_side_reserved_source7),
		.pld_side_reserved_source8(pld_side_reserved_source8),
		.pld_side_reserved_source9(pld_side_reserved_source9),
		.hrdrstctrl_en_cfg(hrdrstctrl_en_cfg),
		.testbus_sel(testbus_sel),
		.usrmode_sel4rst(usrmode_sel4rst),
		.pld_side_reserved_source11(pld_side_reserved_source11),
		.avmm_group_channel_index(avmm_group_channel_index),
		.use_default_base_address(use_default_base_address),
		.user_base_address(user_base_address)

	)
	stratixv_hssi_common_pld_pcs_interface_encrypted_inst	(
		.pcs10gtestdata(pcs10gtestdata),
		.pcs8gphystatus(pcs8gphystatus),
		.pcs8grxelecidle(pcs8grxelecidle),
		.pcs8grxstatus(pcs8grxstatus),
		.pcs8grxvalid(pcs8grxvalid),
		.pcsgen3masktxpll(pcsgen3masktxpll),
		.pcsgen3testout(pcsgen3testout),
		.pld10grefclkdig(pld10grefclkdig),
		.pld8gpowerdown(pld8gpowerdown),
		.pld8gprbsciden(pld8gprbsciden),
		.pld8grefclkdig(pld8grefclkdig),
		.pld8grxpolarity(pld8grxpolarity),
		.pld8gtxdeemph(pld8gtxdeemph),
		.pld8gtxdetectrxloopback(pld8gtxdetectrxloopback),
		.pld8gtxelecidle(pld8gtxelecidle),
		.pld8gtxmargin(pld8gtxmargin),
		.pld8gtxswing(pld8gtxswing),
		.pldaggrefclkdig(pldaggrefclkdig),
		.pldeidleinfersel(pldeidleinfersel),
		.pldgen3currentcoeff(pldgen3currentcoeff),
		.pldgen3currentrxpreset(pldgen3currentrxpreset),
		.pldhclkin(pldhclkin),
		.pldoffcaldonein(pldoffcaldonein),
		.pldpcspmaifrefclkdig(pldpcspmaifrefclkdig),
		.pldrate(pldrate),
		.pmaclklow(pmaclklow),
		.pmafref(pmafref),
		.pmaoffcalen(pmaoffcalen),
		.avmmaddress(avmmaddress),
		.avmmbyteen(avmmbyteen),
		.avmmrstn(avmmrstn),
		.emsipcomin(emsipcomin),
		.emsipcomspecialin(emsipcomspecialin),
		.entest(entest),
		.frzreg(frzreg),
		.iocsrrdydly(iocsrrdydly),
		.nfrzdrv(nfrzdrv),
		.npor(npor),
		.pcs10gextraout(pcs10gextraout),
		.pcs10gtestso(pcs10gtestso),
		.pcs8gchnltestbusout(pcs8gchnltestbusout),
		.pcs8gpldextraout(pcs8gpldextraout),
		.pcs8gtestso(pcs8gtestso),
		.pcsaggtestso(pcsaggtestso),
		.pcsgen3extraout(pcsgen3extraout),
		.pcsgen3rxdeemph(pcsgen3rxdeemph),
		.pcsgen3rxeqctrl(pcsgen3rxeqctrl),
		.pcsgen3testso(pcsgen3testso),
		.pcspmaiftestbusout(pcspmaiftestbusout),
		.pcspmaiftestso(pcspmaiftestso),
		.pld8grefclkdig2(pld8grefclkdig2),
		.pldltr(pldltr),
		.pldoffcaldone(pldoffcaldone),
		.pldpartialreconfigin(pldpartialreconfigin),
		.pldreservedin(pldreservedin),
		.pldscanmoden(pldscanmoden),
		.pldscanshiftn(pldscanshiftn),
		.plniotri(plniotri),
		.usermode(usermode),
		.avmmclk(avmmclk),
		.avmmread(avmmread),
		.avmmwrite(avmmwrite),
		.avmmwritedata(avmmwritedata),
		.asynchdatain(asynchdatain),
		.pcs10ghardreset(pcs10ghardreset),
		.pcs10ghardresetn(pcs10ghardresetn),
		.pcs10grefclkdig(pcs10grefclkdig),
		.pcs8geidleinfersel(pcs8geidleinfersel),
		.pcs8gltr(pcs8gltr),
		.pcs8gpowerdown(pcs8gpowerdown),
		.pcs8gprbsciden(pcs8gprbsciden),
		.pcs8grate(pcs8grate),
		.pcs8grefclkdig(pcs8grefclkdig),
		.pcs8grxpolarity(pcs8grxpolarity),
		.pcs8gtxdeemph(pcs8gtxdeemph),
		.pcs8gtxdetectrxloopback(pcs8gtxdetectrxloopback),
		.pcs8gtxelecidle(pcs8gtxelecidle),
		.pcs8gtxmargin(pcs8gtxmargin),
		.pcs8gtxswing(pcs8gtxswing),
		.pcsaggrefclkdig(pcsaggrefclkdig),
		.pcsgen3currentcoeff(pcsgen3currentcoeff),
		.pcsgen3currentrxpreset(pcsgen3currentrxpreset),
		.pcsgen3eidleinfersel(pcsgen3eidleinfersel),
		.pcsgen3pldltr(pcsgen3pldltr),
		.pcsgen3rate(pcsgen3rate),
		.pcspcspmaifrefclkdig(pcspcspmaifrefclkdig),
		.pcspcspmaifscanmoden(pcspcspmaifscanmoden),
		.pcspcspmaifscanshiftn(pcspcspmaifscanshiftn),
		.pld8gphystatus(pld8gphystatus),
		.pld8grxelecidle(pld8grxelecidle),
		.pld8grxstatus(pld8grxstatus),
		.pld8grxvalid(pld8grxvalid),
		.pldclklow(pldclklow),
		.pldfref(pldfref),
		.pldgen3masktxpll(pldgen3masktxpll),
		.pldoffcaldoneout(pldoffcaldoneout),
		.pldoffcalen(pldoffcalen),
		.pldtestdata(pldtestdata),
		.emsipcomclkout(emsipcomclkout),
		.emsipcomout(emsipcomout),
		.emsipcomspecialout(emsipcomspecialout),
		.emsipenablediocsrrdydly(emsipenablediocsrrdydly),
		.pcs10gextrain(pcs10gextrain),
		.pcs10gtestsi(pcs10gtestsi),
		.pcs8ghardreset(pcs8ghardreset),
		.pcs8ghardresetn(pcs8ghardresetn),
		.pcs8gpldextrain(pcs8gpldextrain),
		.pcs8grefclkdig2(pcs8grefclkdig2),
		.pcs8gscanmoden(pcs8gscanmoden),
		.pcs8gtestsi(pcs8gtestsi),
		.pcsaggtestsi(pcsaggtestsi),
		.pcsgen3extrain(pcsgen3extrain),
		.pcsgen3hardreset(pcsgen3hardreset),
		.pcsgen3scanmoden(pcsgen3scanmoden),
		.pcsgen3testsi(pcsgen3testsi),
		.pcspmaifhardreset(pcspmaifhardreset),
		.pcspmaiftestsi(pcspmaiftestsi),
		.pldgen3rxdeemph(pldgen3rxdeemph),
		.pldgen3rxeqctrl(pldgen3rxeqctrl),
		.pldnfrzdrv(pldnfrzdrv),
		.pldpartialreconfigout(pldpartialreconfigout),
		.pldreservedout(pldreservedout),
		.rstsel(rstsel),
		.usrrstsel(usrrstsel),
		.avmmreaddata(avmmreaddata),
		.blockselect(blockselect)
	);


endmodule
// --------------------------------------------------------------------
// This is auto-generated HSSI Simulation Atom Model Encryption Wrapper
// Module Name : ./sim_model_wrappers//stratixv_hssi_rx_pcs_pma_interface_wrapper.v
// --------------------------------------------------------------------

`timescale 1 ps/1 ps
module stratixv_hssi_rx_pcs_pma_interface
#(
	// parameter declaration and default value assignemnt
	parameter enable_debug_info = "false",	//Valid values: false|true; this is simulation-only parameter, for debug purpose only

	parameter selectpcs = "eight_g_pcs",	//Valid values: eight_g_pcs|ten_g_pcs|pcie_gen3|default
	parameter clkslip_sel = "pld",	//Valid values: pld|slip_eight_g_pcs
	parameter prot_mode = "other_protocols",	//Valid values: other_protocols|cpri_8g
	parameter avmm_group_channel_index = 0,	//Valid values: 0..2
	parameter use_default_base_address = "true",	//Valid values: false|true
	parameter user_base_address = 0	//Valid values: 0..2047
)
(
//input and output port declaration
	input [ 10:0 ] avmmaddress,
	input [ 1:0 ] avmmbyteen,
	input [ 0:0 ] avmmclk,
	input [ 0:0 ] avmmread,
	input [ 0:0 ] avmmrstn,
	input [ 0:0 ] avmmwrite,
	input [ 15:0 ] avmmwritedata,
	input [ 0:0 ] clockinfrompma,
	input [ 79:0 ] datainfrompma,
	input [ 0:0 ] pcs10grxclkiqout,
	input [ 0:0 ] pcs8grxclkiqout,
	input [ 0:0 ] pcs8grxclkslip,
	input [ 0:0 ] pcsemsiprxclkiqout,
	input [ 7:0 ] pcsgen3eyemonitorout,
	input [ 0:0 ] pldrxclkslip,
	input [ 0:0 ] pldrxpmarstb,
	input [ 0:0 ] pmaclkdiv33txorrxin,
	input [ 1:0 ] pmaeyemonitorin,
	input [ 4:0 ] pmareservedin,
	input [ 0:0 ] pmarxpllphaselockin,
	input [ 0:0 ] pmasigdet,
	input [ 0:0 ] pmasignalok,
	output [ 0:0 ] asynchdatain,
	output [ 15:0 ] avmmreaddata,
	output [ 0:0 ] blockselect,
	output [ 0:0 ] clkoutto10gpcs,
	output [ 0:0 ] clockoutto8gpcs,
	output [ 0:0 ] clockouttogen3pcs,
	output [ 79:0 ] dataoutto10gpcs,
	output [ 19:0 ] dataoutto8gpcs,
	output [ 31:0 ] dataouttogen3pcs,
	output [ 0:0 ] pcs10gclkdiv33txorrx,
	output [ 0:0 ] pcs10gsignalok,
	output [ 0:0 ] pcs8gsigdetni,
	output [ 1:0 ] pcsgen3eyemonitorin,
	output [ 0:0 ] pcsgen3pmasignaldet,
	output [ 0:0 ] pmaclkdiv33txorrxout,
	output [ 7:0 ] pmaeyemonitorout,
	output [ 4:0 ] pmareservedout,
	output [ 0:0 ] pmarxclkout,
	output [ 0:0 ] pmarxclkslip,
	output [ 0:0 ] pmarxpllphaselockout,
	output [ 0:0 ] pmarxpmarstb,
	output [ 0:0 ] reset
); 

	stratixv_hssi_rx_pcs_pma_interface_encrypted 
	#(
		.enable_debug_info(enable_debug_info),

		.selectpcs(selectpcs),
		.clkslip_sel(clkslip_sel),
		.prot_mode(prot_mode),
		.avmm_group_channel_index(avmm_group_channel_index),
		.use_default_base_address(use_default_base_address),
		.user_base_address(user_base_address)

	)
	stratixv_hssi_rx_pcs_pma_interface_encrypted_inst	(
		.avmmaddress(avmmaddress),
		.avmmbyteen(avmmbyteen),
		.avmmclk(avmmclk),
		.avmmread(avmmread),
		.avmmrstn(avmmrstn),
		.avmmwrite(avmmwrite),
		.avmmwritedata(avmmwritedata),
		.clockinfrompma(clockinfrompma),
		.datainfrompma(datainfrompma),
		.pcs10grxclkiqout(pcs10grxclkiqout),
		.pcs8grxclkiqout(pcs8grxclkiqout),
		.pcs8grxclkslip(pcs8grxclkslip),
		.pcsemsiprxclkiqout(pcsemsiprxclkiqout),
		.pcsgen3eyemonitorout(pcsgen3eyemonitorout),
		.pldrxclkslip(pldrxclkslip),
		.pldrxpmarstb(pldrxpmarstb),
		.pmaclkdiv33txorrxin(pmaclkdiv33txorrxin),
		.pmaeyemonitorin(pmaeyemonitorin),
		.pmareservedin(pmareservedin),
		.pmarxpllphaselockin(pmarxpllphaselockin),
		.pmasigdet(pmasigdet),
		.pmasignalok(pmasignalok),
		.asynchdatain(asynchdatain),
		.avmmreaddata(avmmreaddata),
		.blockselect(blockselect),
		.clkoutto10gpcs(clkoutto10gpcs),
		.clockoutto8gpcs(clockoutto8gpcs),
		.clockouttogen3pcs(clockouttogen3pcs),
		.dataoutto10gpcs(dataoutto10gpcs),
		.dataoutto8gpcs(dataoutto8gpcs),
		.dataouttogen3pcs(dataouttogen3pcs),
		.pcs10gclkdiv33txorrx(pcs10gclkdiv33txorrx),
		.pcs10gsignalok(pcs10gsignalok),
		.pcs8gsigdetni(pcs8gsigdetni),
		.pcsgen3eyemonitorin(pcsgen3eyemonitorin),
		.pcsgen3pmasignaldet(pcsgen3pmasignaldet),
		.pmaclkdiv33txorrxout(pmaclkdiv33txorrxout),
		.pmaeyemonitorout(pmaeyemonitorout),
		.pmareservedout(pmareservedout),
		.pmarxclkout(pmarxclkout),
		.pmarxclkslip(pmarxclkslip),
		.pmarxpllphaselockout(pmarxpllphaselockout),
		.pmarxpmarstb(pmarxpmarstb),
		.reset(reset)
	);


endmodule
// --------------------------------------------------------------------
// This is auto-generated HSSI Simulation Atom Model Encryption Wrapper
// Module Name : ./sim_model_wrappers//stratixv_hssi_rx_pld_pcs_interface_wrapper.v
// --------------------------------------------------------------------

`timescale 1 ps/1 ps
module stratixv_hssi_rx_pld_pcs_interface
#(
	// parameter declaration and default value assignemnt
	parameter enable_debug_info = "false",	//Valid values: false|true; this is simulation-only parameter, for debug purpose only

	parameter is_10g_0ppm = "false",	//Valid values: false|true
	parameter is_8g_0ppm = "false",	//Valid values: false|true
	parameter selectpcs = "eight_g_pcs",	//Valid values: eight_g_pcs|ten_g_pcs|default
	parameter data_source = "pld",	//Valid values: emsip|pld
	parameter avmm_group_channel_index = 0,	//Valid values: 0..2
	parameter use_default_base_address = "true",	//Valid values: false|true
	parameter user_base_address = 0	//Valid values: 0..2047
)
(
//input and output port declaration
	input [ 0:0 ] clockinfrom10gpcs,
	input [ 0:0 ] clockinfrom8gpcs,
	input [ 63:0 ] datainfrom10gpcs,
	input [ 63:0 ] datainfrom8gpcs,
	input [ 0:0 ] emsipenablediocsrrdydly,
	input [ 2:0 ] emsiprxclkin,
	input [ 19:0 ] emsiprxin,
	input [ 12:0 ] emsiprxspecialin,
	input [ 0:0 ] pcs10grxalignval,
	input [ 0:0 ] pcs10grxblklock,
	input [ 9:0 ] pcs10grxcontrol,
	input [ 0:0 ] pcs10grxcrc32err,
	input [ 0:0 ] pcs10grxdatavalid,
	input [ 0:0 ] pcs10grxdiagerr,
	input [ 1:0 ] pcs10grxdiagstatus,
	input [ 0:0 ] pcs10grxempty,
	input [ 0:0 ] pcs10grxframelock,
	input [ 0:0 ] pcs10grxhiber,
	input [ 0:0 ] pcs10grxmfrmerr,
	input [ 0:0 ] pcs10grxoflwerr,
	input [ 0:0 ] pcs10grxpempty,
	input [ 0:0 ] pcs10grxpfull,
	input [ 0:0 ] pcs10grxprbserr,
	input [ 0:0 ] pcs10grxpyldins,
	input [ 0:0 ] pcs10grxrdnegsts,
	input [ 0:0 ] pcs10grxrdpossts,
	input [ 0:0 ] pcs10grxrxframe,
	input [ 0:0 ] pcs10grxscrmerr,
	input [ 0:0 ] pcs10grxsherr,
	input [ 0:0 ] pcs10grxskiperr,
	input [ 0:0 ] pcs10grxskipins,
	input [ 0:0 ] pcs10grxsyncerr,
	input [ 3:0 ] pcs8ga1a2k1k2flag,
	input [ 0:0 ] pcs8galignstatus,
	input [ 0:0 ] pcs8gbistdone,
	input [ 0:0 ] pcs8gbisterr,
	input [ 0:0 ] pcs8gbyteordflag,
	input [ 0:0 ] pcs8gemptyrmf,
	input [ 0:0 ] pcs8gemptyrx,
	input [ 0:0 ] pcs8gfullrmf,
	input [ 0:0 ] pcs8gfullrx,
	input [ 0:0 ] pcs8gphystatus,
	input [ 0:0 ] pcs8grlvlt,
	input [ 3:0 ] pcs8grxblkstart,
	input [ 3:0 ] pcs8grxdatavalid,
	input [ 0:0 ] pcs8grxelecidle,
	input [ 2:0 ] pcs8grxstatus,
	input [ 1:0 ] pcs8grxsynchdr,
	input [ 0:0 ] pcs8grxvalid,
	input [ 0:0 ] pcs8gsignaldetectout,
	input [ 4:0 ] pcs8gwaboundary,
	input [ 0:0 ] pld10grxalignclr,
	input [ 0:0 ] pld10grxalignen,
	input [ 0:0 ] pld10grxbitslip,
	input [ 0:0 ] pld10grxclrbercount,
	input [ 0:0 ] pld10grxclrerrblkcnt,
	input [ 0:0 ] pld10grxdispclr,
	input [ 0:0 ] pld10grxpldclk,
	input [ 0:0 ] pld10grxpldrstn,
	input [ 0:0 ] pld10grxprbserrclr,
	input [ 0:0 ] pld10grxrden,
	input [ 0:0 ] pld8ga1a2size,
	input [ 0:0 ] pld8gbitlocreven,
	input [ 0:0 ] pld8gbitslip,
	input [ 0:0 ] pld8gbytereven,
	input [ 0:0 ] pld8gbytordpld,
	input [ 0:0 ] pld8gcmpfifourstn,
	input [ 0:0 ] pld8gencdt,
	input [ 0:0 ] pld8gphfifourstrxn,
	input [ 0:0 ] pld8gpldrxclk,
	input [ 0:0 ] pld8gpolinvrx,
	input [ 0:0 ] pld8grdenablermf,
	input [ 0:0 ] pld8grdenablerx,
	input [ 0:0 ] pld8grxurstpcsn,
	input [ 0:0 ] pld8gsyncsmeninput,
	input [ 0:0 ] pld8gwrdisablerx,
	input [ 0:0 ] pld8gwrenablermf,
	input [ 0:0 ] pldgen3rxrstn,
	input [ 0:0 ] pldgen3rxupdatefc,
	input [ 0:0 ] pldrxclkslipin,
	input [ 0:0 ] pldrxpmarstbin,
	input [ 0:0 ] pmaclkdiv33txorrx,
	input [ 0:0 ] rstsel,
	input [ 0:0 ] usrrstsel,
	input [ 0:0 ] pmarxplllock,
	input [ 10:0 ] avmmaddress,
	input [ 1:0 ] avmmbyteen,
	input [ 0:0 ] avmmrstn,
	input [ 0:0 ] pcs10grxfifodel,
	input [ 0:0 ] pcs10grxfifoinsert,
	input [ 0:0 ] avmmclk,
	input [ 0:0 ] avmmread,
	input [ 0:0 ] avmmwrite,
	input [ 15:0 ] avmmwritedata,
	output [ 0:0 ] asynchdatain,
	output [ 63:0 ] dataouttopld,
	output [ 2:0 ] emsiprxclkout,
	output [ 128:0 ] emsiprxout,
	output [ 15:0 ] emsiprxspecialout,
	output [ 0:0 ] pcs10grxalignclr,
	output [ 0:0 ] pcs10grxalignen,
	output [ 0:0 ] pcs10grxbitslip,
	output [ 0:0 ] pcs10grxclrbercount,
	output [ 0:0 ] pcs10grxclrerrblkcnt,
	output [ 0:0 ] pcs10grxdispclr,
	output [ 0:0 ] pcs10grxpldclk,
	output [ 0:0 ] pcs10grxpldrstn,
	output [ 0:0 ] pcs10grxprbserrclr,
	output [ 0:0 ] pcs10grxrden,
	output [ 0:0 ] pcs8ga1a2size,
	output [ 0:0 ] pcs8gbitlocreven,
	output [ 0:0 ] pcs8gbitslip,
	output [ 0:0 ] pcs8gbytereven,
	output [ 0:0 ] pcs8gbytordpld,
	output [ 0:0 ] pcs8gcmpfifourst,
	output [ 0:0 ] pcs8gencdt,
	output [ 0:0 ] pcs8gphfifourstrx,
	output [ 0:0 ] pcs8gpldrxclk,
	output [ 0:0 ] pcs8gpolinvrx,
	output [ 0:0 ] pcs8grdenablermf,
	output [ 0:0 ] pcs8grdenablerx,
	output [ 0:0 ] pcs8grxurstpcs,
	output [ 0:0 ] pcs8gsyncsmenoutput,
	output [ 0:0 ] pcs8gwrdisablerx,
	output [ 0:0 ] pcs8gwrenablermf,
	output [ 0:0 ] pcsgen3rxrst,
	output [ 0:0 ] pcsgen3rxrstn,
	output [ 0:0 ] pcsgen3rxupdatefc,
	output [ 0:0 ] pcsgen3syncsmen,
	output [ 0:0 ] pld10grxalignval,
	output [ 0:0 ] pld10grxblklock,
	output [ 0:0 ] pld10grxclkout,
	output [ 9:0 ] pld10grxcontrol,
	output [ 0:0 ] pld10grxcrc32err,
	output [ 0:0 ] pld10grxdatavalid,
	output [ 0:0 ] pld10grxdiagerr,
	output [ 1:0 ] pld10grxdiagstatus,
	output [ 0:0 ] pld10grxempty,
	output [ 0:0 ] pld10grxframelock,
	output [ 0:0 ] pld10grxhiber,
	output [ 0:0 ] pld10grxmfrmerr,
	output [ 0:0 ] pld10grxoflwerr,
	output [ 0:0 ] pld10grxpempty,
	output [ 0:0 ] pld10grxpfull,
	output [ 0:0 ] pld10grxprbserr,
	output [ 0:0 ] pld10grxpyldins,
	output [ 0:0 ] pld10grxrdnegsts,
	output [ 0:0 ] pld10grxrdpossts,
	output [ 0:0 ] pld10grxrxframe,
	output [ 0:0 ] pld10grxscrmerr,
	output [ 0:0 ] pld10grxsherr,
	output [ 0:0 ] pld10grxskiperr,
	output [ 0:0 ] pld10grxskipins,
	output [ 0:0 ] pld10grxsyncerr,
	output [ 3:0 ] pld8ga1a2k1k2flag,
	output [ 0:0 ] pld8galignstatus,
	output [ 0:0 ] pld8gbistdone,
	output [ 0:0 ] pld8gbisterr,
	output [ 0:0 ] pld8gbyteordflag,
	output [ 0:0 ] pld8gemptyrmf,
	output [ 0:0 ] pld8gemptyrx,
	output [ 0:0 ] pld8gfullrmf,
	output [ 0:0 ] pld8gfullrx,
	output [ 0:0 ] pld8grlvlt,
	output [ 3:0 ] pld8grxblkstart,
	output [ 0:0 ] pld8grxclkout,
	output [ 3:0 ] pld8grxdatavalid,
	output [ 1:0 ] pld8grxsynchdr,
	output [ 0:0 ] pld8gsignaldetectout,
	output [ 4:0 ] pld8gwaboundary,
	output [ 0:0 ] pldclkdiv33txorrx,
	output [ 0:0 ] pldrxclkslipout,
	output [ 0:0 ] pldrxiqclkout,
	output [ 0:0 ] pldrxpmarstbout,
	output [ 0:0 ] reset,
	output [ 0:0 ] pld10grxfifodel,
	output [ 0:0 ] pld10grxfifoinsert,
	output [ 15:0 ] avmmreaddata,
	output [ 0:0 ] blockselect
); 

	stratixv_hssi_rx_pld_pcs_interface_encrypted 
	#(
		.enable_debug_info(enable_debug_info),

		.is_10g_0ppm(is_10g_0ppm),
		.is_8g_0ppm(is_8g_0ppm),
		.selectpcs(selectpcs),
		.data_source(data_source),
		.avmm_group_channel_index(avmm_group_channel_index),
		.use_default_base_address(use_default_base_address),
		.user_base_address(user_base_address)

	)
	stratixv_hssi_rx_pld_pcs_interface_encrypted_inst	(
		.clockinfrom10gpcs(clockinfrom10gpcs),
		.clockinfrom8gpcs(clockinfrom8gpcs),
		.datainfrom10gpcs(datainfrom10gpcs),
		.datainfrom8gpcs(datainfrom8gpcs),
		.emsipenablediocsrrdydly(emsipenablediocsrrdydly),
		.emsiprxclkin(emsiprxclkin),
		.emsiprxin(emsiprxin),
		.emsiprxspecialin(emsiprxspecialin),
		.pcs10grxalignval(pcs10grxalignval),
		.pcs10grxblklock(pcs10grxblklock),
		.pcs10grxcontrol(pcs10grxcontrol),
		.pcs10grxcrc32err(pcs10grxcrc32err),
		.pcs10grxdatavalid(pcs10grxdatavalid),
		.pcs10grxdiagerr(pcs10grxdiagerr),
		.pcs10grxdiagstatus(pcs10grxdiagstatus),
		.pcs10grxempty(pcs10grxempty),
		.pcs10grxframelock(pcs10grxframelock),
		.pcs10grxhiber(pcs10grxhiber),
		.pcs10grxmfrmerr(pcs10grxmfrmerr),
		.pcs10grxoflwerr(pcs10grxoflwerr),
		.pcs10grxpempty(pcs10grxpempty),
		.pcs10grxpfull(pcs10grxpfull),
		.pcs10grxprbserr(pcs10grxprbserr),
		.pcs10grxpyldins(pcs10grxpyldins),
		.pcs10grxrdnegsts(pcs10grxrdnegsts),
		.pcs10grxrdpossts(pcs10grxrdpossts),
		.pcs10grxrxframe(pcs10grxrxframe),
		.pcs10grxscrmerr(pcs10grxscrmerr),
		.pcs10grxsherr(pcs10grxsherr),
		.pcs10grxskiperr(pcs10grxskiperr),
		.pcs10grxskipins(pcs10grxskipins),
		.pcs10grxsyncerr(pcs10grxsyncerr),
		.pcs8ga1a2k1k2flag(pcs8ga1a2k1k2flag),
		.pcs8galignstatus(pcs8galignstatus),
		.pcs8gbistdone(pcs8gbistdone),
		.pcs8gbisterr(pcs8gbisterr),
		.pcs8gbyteordflag(pcs8gbyteordflag),
		.pcs8gemptyrmf(pcs8gemptyrmf),
		.pcs8gemptyrx(pcs8gemptyrx),
		.pcs8gfullrmf(pcs8gfullrmf),
		.pcs8gfullrx(pcs8gfullrx),
		.pcs8gphystatus(pcs8gphystatus),
		.pcs8grlvlt(pcs8grlvlt),
		.pcs8grxblkstart(pcs8grxblkstart),
		.pcs8grxdatavalid(pcs8grxdatavalid),
		.pcs8grxelecidle(pcs8grxelecidle),
		.pcs8grxstatus(pcs8grxstatus),
		.pcs8grxsynchdr(pcs8grxsynchdr),
		.pcs8grxvalid(pcs8grxvalid),
		.pcs8gsignaldetectout(pcs8gsignaldetectout),
		.pcs8gwaboundary(pcs8gwaboundary),
		.pld10grxalignclr(pld10grxalignclr),
		.pld10grxalignen(pld10grxalignen),
		.pld10grxbitslip(pld10grxbitslip),
		.pld10grxclrbercount(pld10grxclrbercount),
		.pld10grxclrerrblkcnt(pld10grxclrerrblkcnt),
		.pld10grxdispclr(pld10grxdispclr),
		.pld10grxpldclk(pld10grxpldclk),
		.pld10grxpldrstn(pld10grxpldrstn),
		.pld10grxprbserrclr(pld10grxprbserrclr),
		.pld10grxrden(pld10grxrden),
		.pld8ga1a2size(pld8ga1a2size),
		.pld8gbitlocreven(pld8gbitlocreven),
		.pld8gbitslip(pld8gbitslip),
		.pld8gbytereven(pld8gbytereven),
		.pld8gbytordpld(pld8gbytordpld),
		.pld8gcmpfifourstn(pld8gcmpfifourstn),
		.pld8gencdt(pld8gencdt),
		.pld8gphfifourstrxn(pld8gphfifourstrxn),
		.pld8gpldrxclk(pld8gpldrxclk),
		.pld8gpolinvrx(pld8gpolinvrx),
		.pld8grdenablermf(pld8grdenablermf),
		.pld8grdenablerx(pld8grdenablerx),
		.pld8grxurstpcsn(pld8grxurstpcsn),
		.pld8gsyncsmeninput(pld8gsyncsmeninput),
		.pld8gwrdisablerx(pld8gwrdisablerx),
		.pld8gwrenablermf(pld8gwrenablermf),
		.pldgen3rxrstn(pldgen3rxrstn),
		.pldgen3rxupdatefc(pldgen3rxupdatefc),
		.pldrxclkslipin(pldrxclkslipin),
		.pldrxpmarstbin(pldrxpmarstbin),
		.pmaclkdiv33txorrx(pmaclkdiv33txorrx),
		.rstsel(rstsel),
		.usrrstsel(usrrstsel),
		.pmarxplllock(pmarxplllock),
		.avmmaddress(avmmaddress),
		.avmmbyteen(avmmbyteen),
		.avmmrstn(avmmrstn),
		.pcs10grxfifodel(pcs10grxfifodel),
		.pcs10grxfifoinsert(pcs10grxfifoinsert),
		.avmmclk(avmmclk),
		.avmmread(avmmread),
		.avmmwrite(avmmwrite),
		.avmmwritedata(avmmwritedata),
		.asynchdatain(asynchdatain),
		.dataouttopld(dataouttopld),
		.emsiprxclkout(emsiprxclkout),
		.emsiprxout(emsiprxout),
		.emsiprxspecialout(emsiprxspecialout),
		.pcs10grxalignclr(pcs10grxalignclr),
		.pcs10grxalignen(pcs10grxalignen),
		.pcs10grxbitslip(pcs10grxbitslip),
		.pcs10grxclrbercount(pcs10grxclrbercount),
		.pcs10grxclrerrblkcnt(pcs10grxclrerrblkcnt),
		.pcs10grxdispclr(pcs10grxdispclr),
		.pcs10grxpldclk(pcs10grxpldclk),
		.pcs10grxpldrstn(pcs10grxpldrstn),
		.pcs10grxprbserrclr(pcs10grxprbserrclr),
		.pcs10grxrden(pcs10grxrden),
		.pcs8ga1a2size(pcs8ga1a2size),
		.pcs8gbitlocreven(pcs8gbitlocreven),
		.pcs8gbitslip(pcs8gbitslip),
		.pcs8gbytereven(pcs8gbytereven),
		.pcs8gbytordpld(pcs8gbytordpld),
		.pcs8gcmpfifourst(pcs8gcmpfifourst),
		.pcs8gencdt(pcs8gencdt),
		.pcs8gphfifourstrx(pcs8gphfifourstrx),
		.pcs8gpldrxclk(pcs8gpldrxclk),
		.pcs8gpolinvrx(pcs8gpolinvrx),
		.pcs8grdenablermf(pcs8grdenablermf),
		.pcs8grdenablerx(pcs8grdenablerx),
		.pcs8grxurstpcs(pcs8grxurstpcs),
		.pcs8gsyncsmenoutput(pcs8gsyncsmenoutput),
		.pcs8gwrdisablerx(pcs8gwrdisablerx),
		.pcs8gwrenablermf(pcs8gwrenablermf),
		.pcsgen3rxrst(pcsgen3rxrst),
		.pcsgen3rxrstn(pcsgen3rxrstn),
		.pcsgen3rxupdatefc(pcsgen3rxupdatefc),
		.pcsgen3syncsmen(pcsgen3syncsmen),
		.pld10grxalignval(pld10grxalignval),
		.pld10grxblklock(pld10grxblklock),
		.pld10grxclkout(pld10grxclkout),
		.pld10grxcontrol(pld10grxcontrol),
		.pld10grxcrc32err(pld10grxcrc32err),
		.pld10grxdatavalid(pld10grxdatavalid),
		.pld10grxdiagerr(pld10grxdiagerr),
		.pld10grxdiagstatus(pld10grxdiagstatus),
		.pld10grxempty(pld10grxempty),
		.pld10grxframelock(pld10grxframelock),
		.pld10grxhiber(pld10grxhiber),
		.pld10grxmfrmerr(pld10grxmfrmerr),
		.pld10grxoflwerr(pld10grxoflwerr),
		.pld10grxpempty(pld10grxpempty),
		.pld10grxpfull(pld10grxpfull),
		.pld10grxprbserr(pld10grxprbserr),
		.pld10grxpyldins(pld10grxpyldins),
		.pld10grxrdnegsts(pld10grxrdnegsts),
		.pld10grxrdpossts(pld10grxrdpossts),
		.pld10grxrxframe(pld10grxrxframe),
		.pld10grxscrmerr(pld10grxscrmerr),
		.pld10grxsherr(pld10grxsherr),
		.pld10grxskiperr(pld10grxskiperr),
		.pld10grxskipins(pld10grxskipins),
		.pld10grxsyncerr(pld10grxsyncerr),
		.pld8ga1a2k1k2flag(pld8ga1a2k1k2flag),
		.pld8galignstatus(pld8galignstatus),
		.pld8gbistdone(pld8gbistdone),
		.pld8gbisterr(pld8gbisterr),
		.pld8gbyteordflag(pld8gbyteordflag),
		.pld8gemptyrmf(pld8gemptyrmf),
		.pld8gemptyrx(pld8gemptyrx),
		.pld8gfullrmf(pld8gfullrmf),
		.pld8gfullrx(pld8gfullrx),
		.pld8grlvlt(pld8grlvlt),
		.pld8grxblkstart(pld8grxblkstart),
		.pld8grxclkout(pld8grxclkout),
		.pld8grxdatavalid(pld8grxdatavalid),
		.pld8grxsynchdr(pld8grxsynchdr),
		.pld8gsignaldetectout(pld8gsignaldetectout),
		.pld8gwaboundary(pld8gwaboundary),
		.pldclkdiv33txorrx(pldclkdiv33txorrx),
		.pldrxclkslipout(pldrxclkslipout),
		.pldrxiqclkout(pldrxiqclkout),
		.pldrxpmarstbout(pldrxpmarstbout),
		.reset(reset),
		.pld10grxfifodel(pld10grxfifodel),
		.pld10grxfifoinsert(pld10grxfifoinsert),
		.avmmreaddata(avmmreaddata),
		.blockselect(blockselect)
	);


endmodule
// --------------------------------------------------------------------
// This is auto-generated HSSI Simulation Atom Model Encryption Wrapper
// Module Name : ./sim_model_wrappers//stratixv_hssi_tx_pcs_pma_interface_wrapper.v
// --------------------------------------------------------------------

`timescale 1 ps/1 ps
module stratixv_hssi_tx_pcs_pma_interface
#(
	// parameter declaration and default value assignemnt
	parameter enable_debug_info = "false",	//Valid values: false|true; this is simulation-only parameter, for debug purpose only

	parameter selectpcs = "eight_g_pcs",	//Valid values: eight_g_pcs|ten_g_pcs|pcie_gen3|default
	parameter avmm_group_channel_index = 0,	//Valid values: 0..2
	parameter use_default_base_address = "true",	//Valid values: false|true
	parameter user_base_address = 0	//Valid values: 0..2047
)
(
//input and output port declaration
	input [ 10:0 ] avmmaddress,
	input [ 1:0 ] avmmbyteen,
	input [ 0:0 ] avmmclk,
	input [ 0:0 ] avmmread,
	input [ 0:0 ] avmmrstn,
	input [ 0:0 ] avmmwrite,
	input [ 15:0 ] avmmwritedata,
	input [ 0:0 ] clockinfrompma,
	input [ 79:0 ] datainfrom10gpcs,
	input [ 19:0 ] datainfrom8gpcs,
	input [ 31:0 ] datainfromgen3pcs,
	input [ 0:0 ] pcs10gtxclkiqout,
	input [ 0:0 ] pcs8gtxclkiqout,
	input [ 0:0 ] pcsemsiptxclkiqout,
	input [ 0:0 ] pcsgen3gen3datasel,
	input [ 0:0 ] pldtxpmasyncpfbkp,
	input [ 0:0 ] pmaclkdiv33lcin,
	input [ 0:0 ] pmarxfreqtxcmuplllockin,
	input [ 0:0 ] pmatxlcplllockin,
	output [ 0:0 ] asynchdatain,
	output [ 15:0 ] avmmreaddata,
	output [ 0:0 ] blockselect,
	output [ 0:0 ] clockoutto10gpcs,
	output [ 0:0 ] clockoutto8gpcs,
	output [ 79:0 ] dataouttopma,
	output [ 0:0 ] pcs10gclkdiv33lc,
	output [ 0:0 ] pmaclkdiv33lcout,
	output [ 0:0 ] pmarxfreqtxcmuplllockout,
	output [ 0:0 ] pmatxclkout,
	output [ 0:0 ] pmatxlcplllockout,
	output [ 0:0 ] pmatxpmasyncpfbkp,
	output [ 0:0 ] reset
); 

	stratixv_hssi_tx_pcs_pma_interface_encrypted 
	#(
		.enable_debug_info(enable_debug_info),

		.selectpcs(selectpcs),
		.avmm_group_channel_index(avmm_group_channel_index),
		.use_default_base_address(use_default_base_address),
		.user_base_address(user_base_address)

	)
	stratixv_hssi_tx_pcs_pma_interface_encrypted_inst	(
		.avmmaddress(avmmaddress),
		.avmmbyteen(avmmbyteen),
		.avmmclk(avmmclk),
		.avmmread(avmmread),
		.avmmrstn(avmmrstn),
		.avmmwrite(avmmwrite),
		.avmmwritedata(avmmwritedata),
		.clockinfrompma(clockinfrompma),
		.datainfrom10gpcs(datainfrom10gpcs),
		.datainfrom8gpcs(datainfrom8gpcs),
		.datainfromgen3pcs(datainfromgen3pcs),
		.pcs10gtxclkiqout(pcs10gtxclkiqout),
		.pcs8gtxclkiqout(pcs8gtxclkiqout),
		.pcsemsiptxclkiqout(pcsemsiptxclkiqout),
		.pcsgen3gen3datasel(pcsgen3gen3datasel),
		.pldtxpmasyncpfbkp(pldtxpmasyncpfbkp),
		.pmaclkdiv33lcin(pmaclkdiv33lcin),
		.pmarxfreqtxcmuplllockin(pmarxfreqtxcmuplllockin),
		.pmatxlcplllockin(pmatxlcplllockin),
		.asynchdatain(asynchdatain),
		.avmmreaddata(avmmreaddata),
		.blockselect(blockselect),
		.clockoutto10gpcs(clockoutto10gpcs),
		.clockoutto8gpcs(clockoutto8gpcs),
		.dataouttopma(dataouttopma),
		.pcs10gclkdiv33lc(pcs10gclkdiv33lc),
		.pmaclkdiv33lcout(pmaclkdiv33lcout),
		.pmarxfreqtxcmuplllockout(pmarxfreqtxcmuplllockout),
		.pmatxclkout(pmatxclkout),
		.pmatxlcplllockout(pmatxlcplllockout),
		.pmatxpmasyncpfbkp(pmatxpmasyncpfbkp),
		.reset(reset)
	);


endmodule
// --------------------------------------------------------------------
// This is auto-generated HSSI Simulation Atom Model Encryption Wrapper
// Module Name : ./sim_model_wrappers//stratixv_hssi_tx_pld_pcs_interface_wrapper.v
// --------------------------------------------------------------------

`timescale 1 ps/1 ps
module stratixv_hssi_tx_pld_pcs_interface
#(
	// parameter declaration and default value assignemnt
	parameter enable_debug_info = "false",	//Valid values: false|true; this is simulation-only parameter, for debug purpose only

	parameter is_10g_0ppm = "false",	//Valid values: false|true
	parameter is_8g_0ppm = "false",	//Valid values: false|true
	parameter data_source = "pld",	//Valid values: emsip|pld
	parameter avmm_group_channel_index = 0,	//Valid values: 0..2
	parameter use_default_base_address = "true",	//Valid values: false|true
	parameter user_base_address = 0	//Valid values: 0..2047
)
(
//input and output port declaration
	input [ 0:0 ] clockinfrom10gpcs,
	input [ 0:0 ] clockinfrom8gpcs,
	input [ 63:0 ] datainfrompld,
	input [ 0:0 ] pcs10gtxburstenexe,
	input [ 0:0 ] pcs10gtxempty,
	input [ 0:0 ] pcs10gtxfifodel,
	input [ 0:0 ] pcs10gtxfifoinsert,
	input [ 0:0 ] pcs10gtxframe,
	input [ 0:0 ] pcs10gtxfull,
	input [ 0:0 ] pcs10gtxpempty,
	input [ 0:0 ] pcs10gtxpfull,
	input [ 0:0 ] pcs10gtxwordslipexe,
	input [ 0:0 ] pcs8gemptytx,
	input [ 0:0 ] pcs8gfulltx,
	input [ 6:0 ] pld10gtxbitslip,
	input [ 0:0 ] pld10gtxbursten,
	input [ 8:0 ] pld10gtxcontrol,
	input [ 0:0 ] pld10gtxdatavalid,
	input [ 1:0 ] pld10gtxdiagstatus,
	input [ 0:0 ] pld10gtxpldclk,
	input [ 0:0 ] pld10gtxwordslip,
	input [ 0:0 ] pld8gpldtxclk,
	input [ 0:0 ] pld8gpolinvtx,
	input [ 0:0 ] pld8grddisabletx,
	input [ 0:0 ] pld8grevloopbk,
	input [ 3:0 ] pld8gtxblkstart,
	input [ 4:0 ] pld8gtxboundarysel,
	input [ 3:0 ] pld8gtxdatavalid,
	input [ 1:0 ] pld8gtxsynchdr,
	input [ 0:0 ] pld8gwrenabletx,
	input [ 0:0 ] pldgen3txrstn,
	input [ 0:0 ] pmaclkdiv33lc,
	input [ 0:0 ] pmatxlcplllock,
	input [ 10:0 ] avmmaddress,
	input [ 1:0 ] avmmbyteen,
	input [ 0:0 ] avmmrstn,
	input [ 0:0 ] emsipenablediocsrrdydly,
	input [ 2:0 ] emsippcstxclkin,
	input [ 103:0 ] emsiptxin,
	input [ 12:0 ] emsiptxspecialin,
	input [ 0:0 ] pld10gtxpldrstn,
	input [ 0:0 ] pld8gphfifoursttxn,
	input [ 0:0 ] pld8gtxurstpcsn,
	input [ 0:0 ] pmatxcmuplllock,
	input [ 0:0 ] rstsel,
	input [ 0:0 ] usrrstsel,
	input [ 0:0 ] avmmclk,
	input [ 0:0 ] avmmread,
	input [ 0:0 ] avmmwrite,
	input [ 15:0 ] avmmwritedata,
	output [ 0:0 ] asynchdatain,
	output [ 63:0 ] dataoutto10gpcs,
	output [ 43:0 ] dataoutto8gpcs,
	output [ 6:0 ] pcs10gtxbitslip,
	output [ 0:0 ] pcs10gtxbursten,
	output [ 8:0 ] pcs10gtxcontrol,
	output [ 0:0 ] pcs10gtxdatavalid,
	output [ 1:0 ] pcs10gtxdiagstatus,
	output [ 0:0 ] pcs10gtxpldclk,
	output [ 0:0 ] pcs10gtxwordslip,
	output [ 0:0 ] pcs8gpldtxclk,
	output [ 0:0 ] pcs8gpolinvtx,
	output [ 0:0 ] pcs8grddisabletx,
	output [ 0:0 ] pcs8grevloopbk,
	output [ 3:0 ] pcs8gtxblkstart,
	output [ 4:0 ] pcs8gtxboundarysel,
	output [ 3:0 ] pcs8gtxdatavalid,
	output [ 1:0 ] pcs8gtxsynchdr,
	output [ 0:0 ] pcs8gwrenabletx,
	output [ 0:0 ] pcsgen3txrst,
	output [ 0:0 ] pcsgen3txrstn,
	output [ 0:0 ] pld10gtxburstenexe,
	output [ 0:0 ] pld10gtxclkout,
	output [ 0:0 ] pld10gtxempty,
	output [ 0:0 ] pld10gtxfifodel,
	output [ 0:0 ] pld10gtxfifoinsert,
	output [ 0:0 ] pld10gtxframe,
	output [ 0:0 ] pld10gtxfull,
	output [ 0:0 ] pld10gtxpempty,
	output [ 0:0 ] pld10gtxpfull,
	output [ 0:0 ] pld10gtxwordslipexe,
	output [ 0:0 ] pld8gemptytx,
	output [ 0:0 ] pld8gfulltx,
	output [ 0:0 ] pld8gtxclkout,
	output [ 0:0 ] pldclkdiv33lc,
	output [ 0:0 ] pldlccmurstbout,
	output [ 0:0 ] pldtxiqclkout,
	output [ 0:0 ] reset,
	output [ 2:0 ] emsippcstxclkout,
	output [ 11:0 ] emsiptxout,
	output [ 15:0 ] emsiptxspecialout,
	output [ 0:0 ] pcs10gtxpldrstn,
	output [ 0:0 ] pcs8gphfifoursttx,
	output [ 0:0 ] pcs8gtxurstpcs,
	output [ 0:0 ] pldtxpmasyncpfbkpout,
	output [ 15:0 ] avmmreaddata,
	output [ 0:0 ] blockselect
); 

	stratixv_hssi_tx_pld_pcs_interface_encrypted 
	#(
		.enable_debug_info(enable_debug_info),

		.is_10g_0ppm(is_10g_0ppm),
		.is_8g_0ppm(is_8g_0ppm),
		.data_source(data_source),
		.avmm_group_channel_index(avmm_group_channel_index),
		.use_default_base_address(use_default_base_address),
		.user_base_address(user_base_address)

	)
	stratixv_hssi_tx_pld_pcs_interface_encrypted_inst	(
		.clockinfrom10gpcs(clockinfrom10gpcs),
		.clockinfrom8gpcs(clockinfrom8gpcs),
		.datainfrompld(datainfrompld),
		.pcs10gtxburstenexe(pcs10gtxburstenexe),
		.pcs10gtxempty(pcs10gtxempty),
		.pcs10gtxfifodel(pcs10gtxfifodel),
		.pcs10gtxfifoinsert(pcs10gtxfifoinsert),
		.pcs10gtxframe(pcs10gtxframe),
		.pcs10gtxfull(pcs10gtxfull),
		.pcs10gtxpempty(pcs10gtxpempty),
		.pcs10gtxpfull(pcs10gtxpfull),
		.pcs10gtxwordslipexe(pcs10gtxwordslipexe),
		.pcs8gemptytx(pcs8gemptytx),
		.pcs8gfulltx(pcs8gfulltx),
		.pld10gtxbitslip(pld10gtxbitslip),
		.pld10gtxbursten(pld10gtxbursten),
		.pld10gtxcontrol(pld10gtxcontrol),
		.pld10gtxdatavalid(pld10gtxdatavalid),
		.pld10gtxdiagstatus(pld10gtxdiagstatus),
		.pld10gtxpldclk(pld10gtxpldclk),
		.pld10gtxwordslip(pld10gtxwordslip),
		.pld8gpldtxclk(pld8gpldtxclk),
		.pld8gpolinvtx(pld8gpolinvtx),
		.pld8grddisabletx(pld8grddisabletx),
		.pld8grevloopbk(pld8grevloopbk),
		.pld8gtxblkstart(pld8gtxblkstart),
		.pld8gtxboundarysel(pld8gtxboundarysel),
		.pld8gtxdatavalid(pld8gtxdatavalid),
		.pld8gtxsynchdr(pld8gtxsynchdr),
		.pld8gwrenabletx(pld8gwrenabletx),
		.pldgen3txrstn(pldgen3txrstn),
		.pmaclkdiv33lc(pmaclkdiv33lc),
		.pmatxlcplllock(pmatxlcplllock),
		.avmmaddress(avmmaddress),
		.avmmbyteen(avmmbyteen),
		.avmmrstn(avmmrstn),
		.emsipenablediocsrrdydly(emsipenablediocsrrdydly),
		.emsippcstxclkin(emsippcstxclkin),
		.emsiptxin(emsiptxin),
		.emsiptxspecialin(emsiptxspecialin),
		.pld10gtxpldrstn(pld10gtxpldrstn),
		.pld8gphfifoursttxn(pld8gphfifoursttxn),
		.pld8gtxurstpcsn(pld8gtxurstpcsn),
		.pmatxcmuplllock(pmatxcmuplllock),
		.rstsel(rstsel),
		.usrrstsel(usrrstsel),
		.avmmclk(avmmclk),
		.avmmread(avmmread),
		.avmmwrite(avmmwrite),
		.avmmwritedata(avmmwritedata),
		.asynchdatain(asynchdatain),
		.dataoutto10gpcs(dataoutto10gpcs),
		.dataoutto8gpcs(dataoutto8gpcs),
		.pcs10gtxbitslip(pcs10gtxbitslip),
		.pcs10gtxbursten(pcs10gtxbursten),
		.pcs10gtxcontrol(pcs10gtxcontrol),
		.pcs10gtxdatavalid(pcs10gtxdatavalid),
		.pcs10gtxdiagstatus(pcs10gtxdiagstatus),
		.pcs10gtxpldclk(pcs10gtxpldclk),
		.pcs10gtxwordslip(pcs10gtxwordslip),
		.pcs8gpldtxclk(pcs8gpldtxclk),
		.pcs8gpolinvtx(pcs8gpolinvtx),
		.pcs8grddisabletx(pcs8grddisabletx),
		.pcs8grevloopbk(pcs8grevloopbk),
		.pcs8gtxblkstart(pcs8gtxblkstart),
		.pcs8gtxboundarysel(pcs8gtxboundarysel),
		.pcs8gtxdatavalid(pcs8gtxdatavalid),
		.pcs8gtxsynchdr(pcs8gtxsynchdr),
		.pcs8gwrenabletx(pcs8gwrenabletx),
		.pcsgen3txrst(pcsgen3txrst),
		.pcsgen3txrstn(pcsgen3txrstn),
		.pld10gtxburstenexe(pld10gtxburstenexe),
		.pld10gtxclkout(pld10gtxclkout),
		.pld10gtxempty(pld10gtxempty),
		.pld10gtxfifodel(pld10gtxfifodel),
		.pld10gtxfifoinsert(pld10gtxfifoinsert),
		.pld10gtxframe(pld10gtxframe),
		.pld10gtxfull(pld10gtxfull),
		.pld10gtxpempty(pld10gtxpempty),
		.pld10gtxpfull(pld10gtxpfull),
		.pld10gtxwordslipexe(pld10gtxwordslipexe),
		.pld8gemptytx(pld8gemptytx),
		.pld8gfulltx(pld8gfulltx),
		.pld8gtxclkout(pld8gtxclkout),
		.pldclkdiv33lc(pldclkdiv33lc),
		.pldlccmurstbout(pldlccmurstbout),
		.pldtxiqclkout(pldtxiqclkout),
		.reset(reset),
		.emsippcstxclkout(emsippcstxclkout),
		.emsiptxout(emsiptxout),
		.emsiptxspecialout(emsiptxspecialout),
		.pcs10gtxpldrstn(pcs10gtxpldrstn),
		.pcs8gphfifoursttx(pcs8gphfifoursttx),
		.pcs8gtxurstpcs(pcs8gtxurstpcs),
		.pldtxpmasyncpfbkpout(pldtxpmasyncpfbkpout),
		.avmmreaddata(avmmreaddata),
		.blockselect(blockselect)
	);


endmodule

//******************************************************************************
//
//  Description:
//      This module is intended to provide a functional simulation model for the
//    stratixv_hssi_refclk_divider atom.
//
//  Special Notes:
//      Does not currently model all possible parameters. An error is thrown
//    for unhandled cases.
//
//******************************************************************************

`timescale 1 ps/1 ps

module stratixv_hssi_refclk_divider 
  #(  
      parameter divide_by                   =  1,
      parameter enabled                     = "false",
      parameter refclk_coupling_termination = "normal_100_ohm_termination",
      parameter reference_clock_frequency   = "0 ps",
      parameter avmm_group_channel_index    = 0,
      parameter use_default_base_address    = "true",
      parameter user_base_address           = 0
  ) (
  input           avmmrstn,
  input           avmmclk,
  input           avmmwrite,
  input           avmmread,
  input   [ 1:0]  avmmbyteen,
  input   [10:0]  avmmaddress,
  input   [15:0]  avmmwritedata,
  output  [15:0]  avmmreaddata,
  output          blockselect,

  input           refclkin,
  output          refclkout,

  input           nonuserfrompmaux
);


reg   rxp_div2;     // Clock divided by 2
wire  rxp_div2_180; // Clock divided by 2 with 180 degree phase shift

// Currently unused
assign  blockselect   = 1'b0;
assign  avmmreaddata  = 16'd0;

// Reference clock output
assign refclkout  = ( enabled == "false") && ( divide_by == 1 ) ? refclkin : 
                    ( enabled == "false") && ( divide_by == 2 ) ? rxp_div2_180 :
                    1'bx; // Drive unknown as we are not properly handling case where "enabled == true"


// Clock divider
initial begin
  rxp_div2  = 1'b1;

  if (enabled != "false")
    $display("[stratixv_hssi_refclk_divider] - ERROR! - Parameter \"enabled\" does not support value $s", enabled);
end

assign  rxp_div2_180 = ~rxp_div2; // mimic 180 degree phase shift as in ICD RTL

always @(posedge refclkin)
  rxp_div2  <= ~rxp_div2;

endmodule

`timescale 1 ps / 1 ps
module stratixv_hssi_aux_clock_div (
    clk,     // input clock
    reset,   // reset
    enable_d, // enable DPRIO
    d,        // division factor for DPRIO support
    clkout   // divided clock
);
input clk,reset;
input enable_d;
input [7:0] d;
output clkout;


parameter clk_divide_by  = 1;
parameter extra_latency  = 0;

integer clk_edges,m;
reg [2*extra_latency:0] div_n_register;
reg [7:0] d_factor_dly;
reg [31:0] clk_divide_value;

wire [7:0] d_factor;
wire int_reset;

initial
begin
    div_n_register = 'b0;
    clk_edges = -1;
    m = 0;
    d_factor_dly =  'b0;
    clk_divide_value = clk_divide_by;
end

assign d_factor = (enable_d === 1'b1) ? d : clk_divide_value[7:0];

always @(d_factor)
begin
    d_factor_dly <= d_factor;
end


// create a reset pulse when there is a change in the d_factor value
assign int_reset = (d_factor !== d_factor_dly) ? 1'b1 : 1'b0;

always @(posedge clk or negedge clk or posedge reset or posedge int_reset)
begin
    div_n_register <= {div_n_register, div_n_register[0]};

    if ((reset === 1'b1) || (int_reset === 1'b1)) 
    begin
        clk_edges = -1;
        div_n_register <= 'b0;
    end
    else
    begin
        if (clk_edges == -1) 
        begin
            div_n_register[0] <= clk;
            if (clk == 1'b1) clk_edges = 0;
        end
        else if (clk_edges % d_factor == 0) 
                div_n_register[0] <= ~div_n_register[0];
        if (clk_edges >= 0 || clk == 1'b1)
            clk_edges = (clk_edges + 1) % (2*d_factor) ;
    end
end

assign clkout = div_n_register[2*extra_latency];

endmodule

// --------------------------------------------------------------------
// This is auto-generated HSSI Simulation Atom Model Encryption Wrapper
// Module Name : ./sim_model_wrappers//stratixv_hssi_10g_rx_pcs_wrapper.v
// --------------------------------------------------------------------

`timescale 1 ps/1 ps
module stratixv_hssi_10g_rx_pcs
#(
	// parameter declaration and default value assignemnt
	parameter enable_debug_info = "false",	//Valid values: false|true; this is simulation-only parameter, for debug purpose only

	parameter channel_number = 0,	//Valid values: 0..65
	parameter frmgen_sync_word = 64'h78f678f678f678f6,	//Valid values: 
	parameter frmgen_scrm_word = 64'h2800000000000000,	//Valid values: 
	parameter frmgen_skip_word = 64'h1e1e1e1e1e1e1e1e,	//Valid values: 
	parameter frmgen_diag_word = 64'h6400000000000000,	//Valid values: 
	parameter test_bus_mode = "tx",	//Valid values: tx|rx
	parameter skip_ctrl = "skip_ctrl_default",	//Valid values: skip_ctrl_default
	parameter avmm_group_channel_index = 0,	//Valid values: 0..2
	parameter use_default_base_address = "true",	//Valid values: false|true
	parameter user_base_address = 0,	//Valid values: 0..2047
	parameter prot_mode = "disable_mode",	//Valid values: disable_mode|teng_baser_mode|interlaken_mode|sfis_mode|teng_sdi_mode|basic_mode|test_prbs_mode|test_prp_mode
	parameter sup_mode = "user_mode",	//Valid values: user_mode|engineering_mode|stretch_mode|engr_mode
	parameter dis_signal_ok = "dis_signal_ok_dis",	//Valid values: dis_signal_ok_dis|dis_signal_ok_en
	parameter gb_rx_idwidth = "width_32",	//Valid values: width_40|width_32|width_64|width_32_default
	parameter gb_rx_odwidth = "width_66",	//Valid values: width_32|width_40|width_50|width_67|width_64|width_66
	parameter bit_reverse = "bit_reverse_dis",	//Valid values: bit_reverse_dis|bit_reverse_en
	parameter gb_sel_mode = "internal",	//Valid values: internal|external
	parameter lpbk_mode = "lpbk_dis",	//Valid values: lpbk_dis|lpbk_en
	parameter test_mode = "test_off",	//Valid values: test_off|pseudo_random|prbs_31|prbs_23|prbs_9|prbs_7
	parameter blksync_bypass = "blksync_bypass_dis",	//Valid values: blksync_bypass_dis|blksync_bypass_en
	parameter blksync_pipeln = "blksync_pipeln_dis",	//Valid values: blksync_pipeln_dis|blksync_pipeln_en
	parameter blksync_knum_sh_cnt_prelock = "knum_sh_cnt_prelock_10g",	//Valid values: knum_sh_cnt_prelock_10g|knum_sh_cnt_prelock_40g100g
	parameter blksync_knum_sh_cnt_postlock = "knum_sh_cnt_postlock_10g",	//Valid values: knum_sh_cnt_postlock_10g|knum_sh_cnt_postlock_40g100g
	parameter blksync_enum_invalid_sh_cnt = "enum_invalid_sh_cnt_10g",	//Valid values: enum_invalid_sh_cnt_10g|enum_invalid_sh_cnt_40g100g
	parameter blksync_bitslip_wait_cnt = "bitslip_wait_cnt_min",	//Valid values: bitslip_wait_cnt_min|bitslip_wait_cnt_max|bitslip_wait_cnt_user_setting
	parameter bitslip_wait_cnt_user = 1,	//Valid values: 0..7
	parameter blksync_bitslip_type = "bitslip_comb",	//Valid values: bitslip_comb|bitslip_reg
	parameter blksync_bitslip_wait_type = "bitslip_match",	//Valid values: bitslip_match|bitslip_cnt
	parameter dispchk_bypass = "dispchk_bypass_dis",	//Valid values: dispchk_bypass_dis|dispchk_bypass_en
	parameter dispchk_rd_level = "dispchk_rd_level_min",	//Valid values: dispchk_rd_level_min|dispchk_rd_level_max|dispchk_rd_level_user_setting
	parameter dispchk_rd_level_user = 8'b1100000,	//Valid values: 8
	parameter dispchk_pipeln = "dispchk_pipeln_dis",	//Valid values: dispchk_pipeln_dis|dispchk_pipeln_en
	parameter descrm_bypass = "descrm_bypass_en",	//Valid values: descrm_bypass_dis|descrm_bypass_en
	parameter descrm_mode = "async",	//Valid values: async|sync
	parameter frmsync_bypass = "frmsync_bypass_dis",	//Valid values: frmsync_bypass_dis|frmsync_bypass_en
	parameter frmsync_pipeln = "frmsync_pipeln_dis",	//Valid values: frmsync_pipeln_dis|frmsync_pipeln_en
	parameter frmsync_mfrm_length = "frmsync_mfrm_length_min",	//Valid values: frmsync_mfrm_length_min|frmsync_mfrm_length_max|frmsync_mfrm_length_user_setting
	parameter frmsync_mfrm_length_user = 2048,	//Valid values: 0..8191
	parameter frmsync_knum_sync = "knum_sync_default",	//Valid values: knum_sync_default
	parameter frmsync_enum_sync = "enum_sync_default",	//Valid values: enum_sync_default
	parameter frmsync_enum_scrm = "enum_scrm_default",	//Valid values: enum_scrm_default
	parameter frmsync_flag_type = "all_framing_words",	//Valid values: all_framing_words|location_only
	parameter dec_64b66b_rxsm_bypass = "dec_64b66b_rxsm_bypass_dis",	//Valid values: dec_64b66b_rxsm_bypass_dis|dec_64b66b_rxsm_bypass_en
	parameter rx_sm_bypass = "rx_sm_bypass_dis",	//Valid values: rx_sm_bypass_dis|rx_sm_bypass_en
	parameter rx_sm_pipeln = "rx_sm_pipeln_dis",	//Valid values: rx_sm_pipeln_dis|rx_sm_pipeln_en
	parameter rx_sm_hiber = "rx_sm_hiber_en",	//Valid values: rx_sm_hiber_en|rx_sm_hiber_dis
	parameter ber_xus_timer_window = "xus_timer_window_10g",	//Valid values: xus_timer_window_10g|xus_timer_window_user_setting
	parameter ber_bit_err_total_cnt = "bit_err_total_cnt_10g",	//Valid values: bit_err_total_cnt_10g
	parameter crcchk_bypass = "crcchk_bypass_dis",	//Valid values: crcchk_bypass_dis|crcchk_bypass_en
	parameter crcchk_pipeln = "crcchk_pipeln_dis",	//Valid values: crcchk_pipeln_dis|crcchk_pipeln_en
	parameter crcflag_pipeln = "crcflag_pipeln_dis",	//Valid values: crcflag_pipeln_dis|crcflag_pipeln_en
	parameter crcchk_init = "crcchk_init_user_setting",	//Valid values: crcchk_init_user_setting
	parameter crcchk_init_user = 32'b11111111111111111111111111111111,	//Valid values: 
	parameter crcchk_inv = "crcchk_inv_dis",	//Valid values: crcchk_inv_dis|crcchk_inv_en
	parameter force_align = "force_align_dis",	//Valid values: force_align_dis|force_align_en
	parameter align_del = "align_del_en",	//Valid values: align_del_dis|align_del_en
	parameter control_del = "control_del_all",	//Valid values: control_del_all|control_del_none
	parameter rxfifo_mode = "phase_comp",	//Valid values: register_mode|clk_comp_10g|clk_comp_basic|generic_interlaken|generic_basic|phase_comp|phase_comp_dv|clk_comp|generic
	parameter master_clk_sel = "master_rx_pma_clk",	//Valid values: master_rx_pma_clk|master_tx_pma_clk|master_refclk_dig
	parameter rd_clk_sel = "rd_rx_pma_clk",	//Valid values: rd_rx_pld_clk|rd_rx_pma_clk|rd_refclk_dig
	parameter gbexp_clken = "gbexp_clk_dis",	//Valid values: gbexp_clk_dis|gbexp_clk_en
	parameter prbs_clken = "prbs_clk_dis",	//Valid values: prbs_clk_dis|prbs_clk_en
	parameter blksync_clken = "blksync_clk_dis",	//Valid values: blksync_clk_dis|blksync_clk_en
	parameter dispchk_clken = "dispchk_clk_dis",	//Valid values: dispchk_clk_dis|dispchk_clk_en
	parameter descrm_clken = "descrm_clk_dis",	//Valid values: descrm_clk_dis|descrm_clk_en
	parameter frmsync_clken = "frmsync_clk_dis",	//Valid values: frmsync_clk_dis|frmsync_clk_en
	parameter dec64b66b_clken = "dec64b66b_clk_dis",	//Valid values: dec64b66b_clk_dis|dec64b66b_clk_en
	parameter ber_clken = "ber_clk_dis",	//Valid values: ber_clk_dis|ber_clk_en
	parameter rand_clken = "rand_clk_dis",	//Valid values: rand_clk_dis|rand_clk_en
	parameter crcchk_clken = "crcchk_clk_dis",	//Valid values: crcchk_clk_dis|crcchk_clk_en
	parameter wrfifo_clken = "wrfifo_clk_dis",	//Valid values: wrfifo_clk_dis|wrfifo_clk_en
	parameter rdfifo_clken = "rdfifo_clk_dis",	//Valid values: rdfifo_clk_dis|rdfifo_clk_en
	parameter rxfifo_pempty = 7,	//Valid values: 
	parameter rxfifo_pfull = 23,	//Valid values: 
	parameter rxfifo_full = 31,	//Valid values: 
	parameter rxfifo_empty = 0,	//Valid values: 
	parameter bitslip_mode = "bitslip_dis",	//Valid values: bitslip_dis|bitslip_en
	parameter fast_path = "fast_path_dis",	//Valid values: fast_path_dis|fast_path_en
	parameter stretch_num_stages = "zero_stage",	//Valid values: zero_stage|one_stage|two_stage|three_stage
	parameter stretch_en = "stretch_en",	//Valid values: stretch_en|stretch_dis
	parameter iqtxrx_clkout_sel = "iq_rx_clk_out",	//Valid values: iq_rx_clk_out|iq_rx_pma_clk_div33
	parameter rx_dfx_lpbk = "dfx_lpbk_dis",	//Valid values: dfx_lpbk_dis|dfx_lpbk_en
	parameter rx_polarity_inv = "invert_disable",	//Valid values: invert_disable|invert_enable
	parameter rx_scrm_width = "bit64",	//Valid values: bit64|bit66|bit67
	parameter rx_true_b2b = "b2b",	//Valid values: single|b2b
	parameter rx_sh_location = "lsb",	//Valid values: lsb|msb
	parameter rx_fifo_write_ctrl = "blklock_stops",	//Valid values: blklock_stops|blklock_ignore
	parameter rx_testbus_sel = "crc32_chk_testbus1",	//Valid values: crc32_chk_testbus1|crc32_chk_testbus2|disp_chk_testbus1|disp_chk_testbus2|frame_sync_testbus1|frame_sync_testbus2|dec64b66b_testbus|rxsm_testbus|ber_testbus|blksync_testbus1|blksync_testbus2|gearbox_exp_testbus1|gearbox_exp_testbus2|prbs_ver_xg_testbus|descramble_testbus1|descramble_testbus2|rx_fifo_testbus1|rx_fifo_testbus2
	parameter rx_signal_ok_sel = "synchronized_ver",	//Valid values: synchronized_ver|nonsync_ver
	parameter rx_prbs_mask = "prbsmask128",	//Valid values: prbsmask128|prbsmask256|prbsmask512|prbsmask1024
	parameter ber_xus_timer_window_user = 21'b100110001001010	//Valid values: 21
)
(
//input and output port declaration
	input [ 10:0 ] avmmaddress,
	input [ 1:0 ] avmmbyteen,
	input [ 0:0 ] avmmclk,
	input [ 0:0 ] avmmread,
	input [ 0:0 ] avmmrstn,
	input [ 0:0 ] avmmwrite,
	input [ 15:0 ] avmmwritedata,
	input [ 9:0 ] dfxlpbkcontrolin,
	input [ 63:0 ] dfxlpbkdatain,
	input [ 0:0 ] dfxlpbkdatavalidin,
	input [ 0:0 ] hardresetn,
	input [ 79:0 ] lpbkdatain,
	input [ 0:0 ] pmaclkdiv33txorrx,
	input [ 0:0 ] refclkdig,
	input [ 0:0 ] rxalignclr,
	input [ 0:0 ] rxalignen,
	input [ 0:0 ] rxbitslip,
	input [ 0:0 ] rxclrbercount,
	input [ 0:0 ] rxclrerrorblockcount,
	input [ 0:0 ] rxdisparityclr,
	input [ 0:0 ] rxpldclk,
	input [ 0:0 ] rxpldrstn,
	input [ 0:0 ] rxpmaclk,
	input [ 79:0 ] rxpmadata,
	input [ 0:0 ] rxpmadatavalid,
	input [ 0:0 ] rxprbserrorclr,
	input [ 0:0 ] rxrden,
	input [ 0:0 ] txpmaclk,
	output [ 15:0 ] avmmreaddata,
	output [ 0:0 ] blockselect,
	output [ 0:0 ] rxalignval,
	output [ 0:0 ] rxblocklock,
	output [ 0:0 ] rxclkiqout,
	output [ 0:0 ] rxclkout,
	output [ 9:0 ] rxcontrol,
	output [ 0:0 ] rxcrc32error,
	output [ 63:0 ] rxdata,
	output [ 0:0 ] rxdatavalid,
	output [ 0:0 ] rxdiagnosticerror,
	output [ 1:0 ] rxdiagnosticstatus,
	output [ 0:0 ] rxfifodel,
	output [ 0:0 ] rxfifoempty,
	output [ 0:0 ] rxfifofull,
	output [ 0:0 ] rxfifoinsert,
	output [ 0:0 ] rxfifopartialempty,
	output [ 0:0 ] rxfifopartialfull,
	output [ 0:0 ] rxframelock,
	output [ 0:0 ] rxhighber,
	output [ 0:0 ] rxmetaframeerror,
	output [ 0:0 ] rxpayloadinserted,
	output [ 0:0 ] rxprbsdone,
	output [ 0:0 ] rxprbserr,
	output [ 0:0 ] rxrdnegsts,
	output [ 0:0 ] rxrdpossts,
	output [ 0:0 ] rxrxframe,
	output [ 0:0 ] rxscramblererror,
	output [ 0:0 ] rxskipinserted,
	output [ 0:0 ] rxskipworderror,
	output [ 0:0 ] rxsyncheadererror,
	output [ 0:0 ] rxsyncworderror,
	output [ 19:0 ] rxtestdata,
	output [ 0:0 ] syncdatain
); 

	stratixv_hssi_10g_rx_pcs_encrypted 
	#(
		.enable_debug_info(enable_debug_info),

		.channel_number(channel_number),
		.frmgen_sync_word(frmgen_sync_word),
		.frmgen_scrm_word(frmgen_scrm_word),
		.frmgen_skip_word(frmgen_skip_word),
		.frmgen_diag_word(frmgen_diag_word),
		.test_bus_mode(test_bus_mode),
		.skip_ctrl(skip_ctrl),
		.avmm_group_channel_index(avmm_group_channel_index),
		.use_default_base_address(use_default_base_address),
		.user_base_address(user_base_address),
		.prot_mode(prot_mode),
		.sup_mode(sup_mode),
		.dis_signal_ok(dis_signal_ok),
		.gb_rx_idwidth(gb_rx_idwidth),
		.gb_rx_odwidth(gb_rx_odwidth),
		.bit_reverse(bit_reverse),
		.gb_sel_mode(gb_sel_mode),
		.lpbk_mode(lpbk_mode),
		.test_mode(test_mode),
		.blksync_bypass(blksync_bypass),
		.blksync_pipeln(blksync_pipeln),
		.blksync_knum_sh_cnt_prelock(blksync_knum_sh_cnt_prelock),
		.blksync_knum_sh_cnt_postlock(blksync_knum_sh_cnt_postlock),
		.blksync_enum_invalid_sh_cnt(blksync_enum_invalid_sh_cnt),
		.blksync_bitslip_wait_cnt(blksync_bitslip_wait_cnt),
		.bitslip_wait_cnt_user(bitslip_wait_cnt_user),
		.blksync_bitslip_type(blksync_bitslip_type),
		.blksync_bitslip_wait_type(blksync_bitslip_wait_type),
		.dispchk_bypass(dispchk_bypass),
		.dispchk_rd_level(dispchk_rd_level),
		.dispchk_rd_level_user(dispchk_rd_level_user),
		.dispchk_pipeln(dispchk_pipeln),
		.descrm_bypass(descrm_bypass),
		.descrm_mode(descrm_mode),
		.frmsync_bypass(frmsync_bypass),
		.frmsync_pipeln(frmsync_pipeln),
		.frmsync_mfrm_length(frmsync_mfrm_length),
		.frmsync_mfrm_length_user(frmsync_mfrm_length_user),
		.frmsync_knum_sync(frmsync_knum_sync),
		.frmsync_enum_sync(frmsync_enum_sync),
		.frmsync_enum_scrm(frmsync_enum_scrm),
		.frmsync_flag_type(frmsync_flag_type),
		.dec_64b66b_rxsm_bypass(dec_64b66b_rxsm_bypass),
		.rx_sm_bypass(rx_sm_bypass),
		.rx_sm_pipeln(rx_sm_pipeln),
		.rx_sm_hiber(rx_sm_hiber),
		.ber_xus_timer_window(ber_xus_timer_window),
		.ber_bit_err_total_cnt(ber_bit_err_total_cnt),
		.crcchk_bypass(crcchk_bypass),
		.crcchk_pipeln(crcchk_pipeln),
		.crcflag_pipeln(crcflag_pipeln),
		.crcchk_init(crcchk_init),
		.crcchk_init_user(crcchk_init_user),
		.crcchk_inv(crcchk_inv),
		.force_align(force_align),
		.align_del(align_del),
		.control_del(control_del),
		.rxfifo_mode(rxfifo_mode),
		.master_clk_sel(master_clk_sel),
		.rd_clk_sel(rd_clk_sel),
		.gbexp_clken(gbexp_clken),
		.prbs_clken(prbs_clken),
		.blksync_clken(blksync_clken),
		.dispchk_clken(dispchk_clken),
		.descrm_clken(descrm_clken),
		.frmsync_clken(frmsync_clken),
		.dec64b66b_clken(dec64b66b_clken),
		.ber_clken(ber_clken),
		.rand_clken(rand_clken),
		.crcchk_clken(crcchk_clken),
		.wrfifo_clken(wrfifo_clken),
		.rdfifo_clken(rdfifo_clken),
		.rxfifo_pempty(rxfifo_pempty),
		.rxfifo_pfull(rxfifo_pfull),
		.rxfifo_full(rxfifo_full),
		.rxfifo_empty(rxfifo_empty),
		.bitslip_mode(bitslip_mode),
		.fast_path(fast_path),
		.stretch_num_stages(stretch_num_stages),
		.stretch_en(stretch_en),
		.iqtxrx_clkout_sel(iqtxrx_clkout_sel),
		.rx_dfx_lpbk(rx_dfx_lpbk),
		.rx_polarity_inv(rx_polarity_inv),
		.rx_scrm_width(rx_scrm_width),
		.rx_true_b2b(rx_true_b2b),
		.rx_sh_location(rx_sh_location),
		.rx_fifo_write_ctrl(rx_fifo_write_ctrl),
		.rx_testbus_sel(rx_testbus_sel),
		.rx_signal_ok_sel(rx_signal_ok_sel),
		.rx_prbs_mask(rx_prbs_mask),
		.ber_xus_timer_window_user(ber_xus_timer_window_user)

	)
	stratixv_hssi_10g_rx_pcs_encrypted_inst	(
		.avmmaddress(avmmaddress),
		.avmmbyteen(avmmbyteen),
		.avmmclk(avmmclk),
		.avmmread(avmmread),
		.avmmrstn(avmmrstn),
		.avmmwrite(avmmwrite),
		.avmmwritedata(avmmwritedata),
		.dfxlpbkcontrolin(dfxlpbkcontrolin),
		.dfxlpbkdatain(dfxlpbkdatain),
		.dfxlpbkdatavalidin(dfxlpbkdatavalidin),
		.hardresetn(hardresetn),
		.lpbkdatain(lpbkdatain),
		.pmaclkdiv33txorrx(pmaclkdiv33txorrx),
		.refclkdig(refclkdig),
		.rxalignclr(rxalignclr),
		.rxalignen(rxalignen),
		.rxbitslip(rxbitslip),
		.rxclrbercount(rxclrbercount),
		.rxclrerrorblockcount(rxclrerrorblockcount),
		.rxdisparityclr(rxdisparityclr),
		.rxpldclk(rxpldclk),
		.rxpldrstn(rxpldrstn),
		.rxpmaclk(rxpmaclk),
		.rxpmadata(rxpmadata),
		.rxpmadatavalid(rxpmadatavalid),
		.rxprbserrorclr(rxprbserrorclr),
		.rxrden(rxrden),
		.txpmaclk(txpmaclk),
		.avmmreaddata(avmmreaddata),
		.blockselect(blockselect),
		.rxalignval(rxalignval),
		.rxblocklock(rxblocklock),
		.rxclkiqout(rxclkiqout),
		.rxclkout(rxclkout),
		.rxcontrol(rxcontrol),
		.rxcrc32error(rxcrc32error),
		.rxdata(rxdata),
		.rxdatavalid(rxdatavalid),
		.rxdiagnosticerror(rxdiagnosticerror),
		.rxdiagnosticstatus(rxdiagnosticstatus),
		.rxfifodel(rxfifodel),
		.rxfifoempty(rxfifoempty),
		.rxfifofull(rxfifofull),
		.rxfifoinsert(rxfifoinsert),
		.rxfifopartialempty(rxfifopartialempty),
		.rxfifopartialfull(rxfifopartialfull),
		.rxframelock(rxframelock),
		.rxhighber(rxhighber),
		.rxmetaframeerror(rxmetaframeerror),
		.rxpayloadinserted(rxpayloadinserted),
		.rxprbsdone(rxprbsdone),
		.rxprbserr(rxprbserr),
		.rxrdnegsts(rxrdnegsts),
		.rxrdpossts(rxrdpossts),
		.rxrxframe(rxrxframe),
		.rxscramblererror(rxscramblererror),
		.rxskipinserted(rxskipinserted),
		.rxskipworderror(rxskipworderror),
		.rxsyncheadererror(rxsyncheadererror),
		.rxsyncworderror(rxsyncworderror),
		.rxtestdata(rxtestdata),
		.syncdatain(syncdatain)
	);


endmodule
// --------------------------------------------------------------------
// This is auto-generated HSSI Simulation Atom Model Encryption Wrapper
// Module Name : ./sim_model_wrappers//stratixv_hssi_10g_tx_pcs_wrapper.v
// --------------------------------------------------------------------

`timescale 1 ps/1 ps
module stratixv_hssi_10g_tx_pcs
#(
	// parameter declaration and default value assignemnt
	parameter enable_debug_info = "false",	//Valid values: false|true; this is simulation-only parameter, for debug purpose only

	parameter channel_number = 0,	//Valid values: 0..65
	parameter frmgen_sync_word = 64'h78f678f678f678f6,	//Valid values: 
	parameter frmgen_scrm_word = 64'h2800000000000000,	//Valid values: 
	parameter frmgen_skip_word = 64'h1e1e1e1e1e1e1e1e,	//Valid values: 
	parameter frmgen_diag_word = 64'h6400000000000000,	//Valid values: 
	parameter test_bus_mode = "tx",	//Valid values: tx|rx
	parameter skip_ctrl = "skip_ctrl_default",	//Valid values: skip_ctrl_default
	parameter prot_mode = "disable_mode",	//Valid values: disable_mode|teng_baser_mode|interlaken_mode|sfis_mode|teng_sdi_mode|basic_mode|test_prbs_mode|test_prp_mode|test_rpg_mode
	parameter sup_mode = "user_mode",	//Valid values: user_mode|engineering_mode|stretch_mode|engr_mode
	parameter ctrl_plane_bonding = "individual",	//Valid values: individual|ctrl_master|ctrl_slave_abv|ctrl_slave_blw
	parameter master_clk_sel = "master_tx_pma_clk",	//Valid values: master_tx_pma_clk|master_refclk_dig
	parameter wr_clk_sel = "wr_tx_pma_clk",	//Valid values: wr_tx_pld_clk|wr_tx_pma_clk|wr_refclk_dig
	parameter wrfifo_clken = "wrfifo_clk_dis",	//Valid values: wrfifo_clk_dis|wrfifo_clk_en
	parameter rdfifo_clken = "rdfifo_clk_dis",	//Valid values: rdfifo_clk_dis|rdfifo_clk_en
	parameter frmgen_clken = "frmgen_clk_dis",	//Valid values: frmgen_clk_dis|frmgen_clk_en
	parameter crcgen_clken = "crcgen_clk_dis",	//Valid values: crcgen_clk_dis|crcgen_clk_en
	parameter enc64b66b_txsm_clken = "enc64b66b_txsm_clk_dis",	//Valid values: enc64b66b_txsm_clk_dis|enc64b66b_txsm_clk_en
	parameter scrm_clken = "scrm_clk_dis",	//Valid values: scrm_clk_dis|scrm_clk_en
	parameter dispgen_clken = "dispgen_clk_dis",	//Valid values: dispgen_clk_dis|dispgen_clk_en
	parameter prbs_clken = "prbs_clk_dis",	//Valid values: prbs_clk_dis|prbs_clk_en
	parameter sqwgen_clken = "sqwgen_clk_dis",	//Valid values: sqwgen_clk_dis|sqwgen_clk_en
	parameter gbred_clken = "gbred_clk_dis",	//Valid values: gbred_clk_dis|gbred_clk_en
	parameter gb_tx_idwidth = "width_50",	//Valid values: width_32|width_40|width_50|width_67|width_64|width_66
	parameter gb_tx_odwidth = "width_32",	//Valid values: width_32|width_40|width_64|width_32_default
	parameter txfifo_mode = "phase_comp",	//Valid values: register_mode|clk_comp|interlaken_generic|basic_generic|phase_comp|generic
	parameter txfifo_pempty = 7,	//Valid values: 
	parameter txfifo_pfull = 23,	//Valid values: 
	parameter txfifo_empty = 0,	//Valid values: 
	parameter txfifo_full = 31,	//Valid values: 
	parameter frmgen_bypass = "frmgen_bypass_dis",	//Valid values: frmgen_bypass_dis|frmgen_bypass_en
	parameter frmgen_pipeln = "frmgen_pipeln_dis",	//Valid values: frmgen_pipeln_dis|frmgen_pipeln_en
	parameter frmgen_mfrm_length = "frmgen_mfrm_length_min",	//Valid values: frmgen_mfrm_length_min|frmgen_mfrm_length_max|frmgen_mfrm_length_user_setting
	parameter frmgen_mfrm_length_user = 5,	//Valid values: 
	parameter frmgen_pyld_ins = "frmgen_pyld_ins_dis",	//Valid values: frmgen_pyld_ins_dis|frmgen_pyld_ins_en
	parameter sh_err = "sh_err_dis",	//Valid values: sh_err_dis|sh_err_en
	parameter frmgen_burst = "frmgen_burst_dis",	//Valid values: frmgen_burst_dis|frmgen_burst_en
	parameter frmgen_wordslip = "frmgen_wordslip_dis",	//Valid values: frmgen_wordslip_dis|frmgen_wordslip_en
	parameter crcgen_bypass = "crcgen_bypass_dis",	//Valid values: crcgen_bypass_dis|crcgen_bypass_en
	parameter crcgen_init = "crcgen_init_user_setting",	//Valid values: crcgen_init_user_setting
	parameter crcgen_init_user = 32'b11111111111111111111111111111111,	//Valid values: 
	parameter crcgen_inv = "crcgen_inv_dis",	//Valid values: crcgen_inv_dis|crcgen_inv_en
	parameter crcgen_err = "crcgen_err_dis",	//Valid values: crcgen_err_dis|crcgen_err_en
	parameter enc_64b66b_txsm_bypass = "enc_64b66b_txsm_bypass_dis",	//Valid values: enc_64b66b_txsm_bypass_dis|enc_64b66b_txsm_bypass_en
	parameter tx_sm_bypass = "tx_sm_bypass_dis",	//Valid values: tx_sm_bypass_dis|tx_sm_bypass_en
	parameter tx_sm_pipeln = "tx_sm_pipeln_dis",	//Valid values: tx_sm_pipeln_dis|tx_sm_pipeln_en
	parameter scrm_bypass = "scrm_bypass_dis",	//Valid values: scrm_bypass_dis|scrm_bypass_en
	parameter test_mode = "test_off",	//Valid values: test_off|pseudo_random|sq_wave|prbs_31|prbs_23|prbs_9|prbs_7
	parameter pseudo_random = "all_0",	//Valid values: all_0|two_lf
	parameter pseudo_seed_a = "pseudo_seed_a_user_setting",	//Valid values: pseudo_seed_a_user_setting
	parameter pseudo_seed_a_user = 58'b1111111111111111111111111111111111111111111111111111111111,	//Valid values: 
	parameter pseudo_seed_b = "pseudo_seed_b_user_setting",	//Valid values: pseudo_seed_b_user_setting
	parameter pseudo_seed_b_user = 58'b1111111111111111111111111111111111111111111111111111111111,	//Valid values: 
	parameter bit_reverse = "bit_reverse_dis",	//Valid values: bit_reverse_dis|bit_reverse_en
	parameter scrm_seed = "scram_seed_user_setting",	//Valid values: scram_seed_min|scram_seed_max|scram_seed_user_setting
	parameter scrm_seed_user = 58'b1111111111111111111111111111111111111111111111111111111111,	//Valid values: 58
	parameter scrm_mode = "async",	//Valid values: async|sync
	parameter dispgen_bypass = "dispgen_bypass_dis",	//Valid values: dispgen_bypass_dis|dispgen_bypass_en
	parameter dispgen_err = "dispgen_err_dis",	//Valid values: dispgen_err_dis|dispgen_err_en
	parameter dispgen_pipeln = "dispgen_pipeln_dis",	//Valid values: dispgen_pipeln_dis|dispgen_pipeln_en
	parameter gb_sel_mode = "internal",	//Valid values: internal|external
	parameter sq_wave = "sq_wave_4",	//Valid values: sq_wave_1|sq_wave_4|sq_wave_5|sq_wave_6|sq_wave_8|sq_wave_10
	parameter bitslip_en = "bitslip_dis",	//Valid values: bitslip_dis|bitslip_en
	parameter fastpath = "fastpath_dis",	//Valid values: fastpath_dis|fastpath_en
	parameter distup_bypass_pipeln = "distup_bypass_pipeln_dis",	//Valid values: distup_bypass_pipeln_dis|distup_bypass_pipeln_en
	parameter distup_master = "distup_master_en",	//Valid values: distup_master_en|distup_master_dis
	parameter distdwn_bypass_pipeln = "distdwn_bypass_pipeln_dis",	//Valid values: distdwn_bypass_pipeln_dis|distdwn_bypass_pipeln_en
	parameter distdwn_master = "distdwn_master_en",	//Valid values: distdwn_master_en|distdwn_master_dis
	parameter compin_sel = "compin_master",	//Valid values: compin_master|compin_slave_top|compin_slave_bot|compin_default
	parameter comp_cnt = "comp_cnt_00",	//Valid values: comp_cnt_00|comp_cnt_02|comp_cnt_04|comp_cnt_06|comp_cnt_08|comp_cnt_0a|comp_cnt_0c|comp_cnt_0e|comp_cnt_10|comp_cnt_12|comp_cnt_14|comp_cnt_16|comp_cnt_18|comp_cnt_1a
	parameter indv = "indv_en",	//Valid values: indv_en|indv_dis
	parameter stretch_num_stages = "zero_stage",	//Valid values: zero_stage|one_stage|two_stage|three_stage
	parameter stretch_en = "stretch_en",	//Valid values: stretch_en|stretch_dis
	parameter iqtxrx_clkout_sel = "iq_tx_pma_clk",	//Valid values: iq_tx_pma_clk|iq_tx_pma_clk_div33
	parameter tx_testbus_sel = "crc32_gen_testbus1",	//Valid values: crc32_gen_testbus1|crc32_gen_testbus2|disp_gen_testbus1|disp_gen_testbus2|frame_gen_testbus1|frame_gen_testbus2|enc64b66b_testbus|txsm_testbus|tx_cp_bond_testbus|prbs_gen_xg_testbus|gearbox_red_testbus1|gearbox_red_testbus2|scramble_testbus1|scramble_testbus2|tx_fifo_testbus1|tx_fifo_testbus2
	parameter tx_true_b2b = "b2b",	//Valid values: single|b2b
	parameter tx_scrm_width = "bit64",	//Valid values: bit64|bit66|bit67
	parameter pmagate_en = "pmagate_dis",	//Valid values: pmagate_dis|pmagate_en
	parameter tx_polarity_inv = "invert_disable",	//Valid values: invert_disable|invert_enable
	parameter comp_del_sel_agg = "data_agg_del0",	//Valid values: data_agg_del0|data_agg_del1|data_agg_del2|data_agg_del3|data_agg_del4|data_agg_del5|data_agg_del6|data_agg_del7|data_agg_del8
	parameter distup_bypass_pipeln_agg = "distup_bypass_pipeln_agg_dis",	//Valid values: distup_bypass_pipeln_agg_dis|distup_bypass_pipeln_agg_en
	parameter distdwn_bypass_pipeln_agg = "distdwn_bypass_pipeln_agg_dis",	//Valid values: distdwn_bypass_pipeln_agg_dis|distdwn_bypass_pipeln_agg_en
	parameter tx_sh_location = "lsb",	//Valid values: lsb|msb
	parameter tx_scrm_err = "scrm_err_dis",	//Valid values: scrm_err_dis|scrm_err_en
	parameter avmm_group_channel_index = 0,	//Valid values: 0..2
	parameter use_default_base_address = "true",	//Valid values: false|true
	parameter user_base_address = 0,	//Valid values: 0..2047
	parameter phcomp_rd_del = "phcomp_rd_del1"	//Valid values: phcomp_rd_del5|phcomp_rd_del4|phcomp_rd_del3|phcomp_rd_del2|phcomp_rd_del1
)
(
//input and output port declaration
	input [ 10:0 ] avmmaddress,
	input [ 1:0 ] avmmbyteen,
	input [ 0:0 ] avmmclk,
	input [ 0:0 ] avmmread,
	input [ 0:0 ] avmmrstn,
	input [ 0:0 ] avmmwrite,
	input [ 15:0 ] avmmwritedata,
	input [ 0:0 ] distdwnindv,
	input [ 0:0 ] distdwninintlknrden,
	input [ 0:0 ] distdwninrden,
	input [ 0:0 ] distdwninrdpfull,
	input [ 0:0 ] distdwninwren,
	input [ 0:0 ] distupindv,
	input [ 0:0 ] distupinintlknrden,
	input [ 0:0 ] distupinrden,
	input [ 0:0 ] distupinrdpfull,
	input [ 0:0 ] distupinwren,
	input [ 0:0 ] hardresetn,
	input [ 0:0 ] pmaclkdiv33lc,
	input [ 0:0 ] refclkdig,
	input [ 6:0 ] txbitslip,
	input [ 0:0 ] txbursten,
	input [ 8:0 ] txcontrol,
	input [ 63:0 ] txdata,
	input [ 0:0 ] txdatavalid,
	input [ 1:0 ] txdiagnosticstatus,
	input [ 0:0 ] txdisparityclr,
	input [ 0:0 ] txpldclk,
	input [ 0:0 ] txpldrstn,
	input [ 0:0 ] txpmaclk,
	input [ 0:0 ] txwordslip,
	output [ 15:0 ] avmmreaddata,
	output [ 0:0 ] blockselect,
	output [ 8:0 ] dfxlpbkcontrolout,
	output [ 63:0 ] dfxlpbkdataout,
	output [ 0:0 ] dfxlpbkdatavalidout,
	output [ 0:0 ] distdwnoutdv,
	output [ 0:0 ] distdwnoutintlknrden,
	output [ 0:0 ] distdwnoutrden,
	output [ 0:0 ] distdwnoutrdpfull,
	output [ 0:0 ] distdwnoutwren,
	output [ 0:0 ] distupoutdv,
	output [ 0:0 ] distupoutintlknrden,
	output [ 0:0 ] distupoutrden,
	output [ 0:0 ] distupoutrdpfull,
	output [ 0:0 ] distupoutwren,
	output [ 79:0 ] lpbkdataout,
	output [ 0:0 ] syncdatain,
	output [ 0:0 ] txburstenexe,
	output [ 0:0 ] txclkiqout,
	output [ 0:0 ] txclkout,
	output [ 0:0 ] txfifodel,
	output [ 0:0 ] txfifoempty,
	output [ 0:0 ] txfifofull,
	output [ 0:0 ] txfifoinsert,
	output [ 0:0 ] txfifopartialempty,
	output [ 0:0 ] txfifopartialfull,
	output [ 0:0 ] txframe,
	output [ 79:0 ] txpmadata,
	output [ 0:0 ] txwordslipexe
); 

	stratixv_hssi_10g_tx_pcs_encrypted 
	#(
		.enable_debug_info(enable_debug_info),

		.channel_number(channel_number),
		.frmgen_sync_word(frmgen_sync_word),
		.frmgen_scrm_word(frmgen_scrm_word),
		.frmgen_skip_word(frmgen_skip_word),
		.frmgen_diag_word(frmgen_diag_word),
		.test_bus_mode(test_bus_mode),
		.skip_ctrl(skip_ctrl),
		.prot_mode(prot_mode),
		.sup_mode(sup_mode),
		.ctrl_plane_bonding(ctrl_plane_bonding),
		.master_clk_sel(master_clk_sel),
		.wr_clk_sel(wr_clk_sel),
		.wrfifo_clken(wrfifo_clken),
		.rdfifo_clken(rdfifo_clken),
		.frmgen_clken(frmgen_clken),
		.crcgen_clken(crcgen_clken),
		.enc64b66b_txsm_clken(enc64b66b_txsm_clken),
		.scrm_clken(scrm_clken),
		.dispgen_clken(dispgen_clken),
		.prbs_clken(prbs_clken),
		.sqwgen_clken(sqwgen_clken),
		.gbred_clken(gbred_clken),
		.gb_tx_idwidth(gb_tx_idwidth),
		.gb_tx_odwidth(gb_tx_odwidth),
		.txfifo_mode(txfifo_mode),
		.txfifo_pempty(txfifo_pempty),
		.txfifo_pfull(txfifo_pfull),
		.txfifo_empty(txfifo_empty),
		.txfifo_full(txfifo_full),
		.frmgen_bypass(frmgen_bypass),
		.frmgen_pipeln(frmgen_pipeln),
		.frmgen_mfrm_length(frmgen_mfrm_length),
		.frmgen_mfrm_length_user(frmgen_mfrm_length_user),
		.frmgen_pyld_ins(frmgen_pyld_ins),
		.sh_err(sh_err),
		.frmgen_burst(frmgen_burst),
		.frmgen_wordslip(frmgen_wordslip),
		.crcgen_bypass(crcgen_bypass),
		.crcgen_init(crcgen_init),
		.crcgen_init_user(crcgen_init_user),
		.crcgen_inv(crcgen_inv),
		.crcgen_err(crcgen_err),
		.enc_64b66b_txsm_bypass(enc_64b66b_txsm_bypass),
		.tx_sm_bypass(tx_sm_bypass),
		.tx_sm_pipeln(tx_sm_pipeln),
		.scrm_bypass(scrm_bypass),
		.test_mode(test_mode),
		.pseudo_random(pseudo_random),
		.pseudo_seed_a(pseudo_seed_a),
		.pseudo_seed_a_user(pseudo_seed_a_user),
		.pseudo_seed_b(pseudo_seed_b),
		.pseudo_seed_b_user(pseudo_seed_b_user),
		.bit_reverse(bit_reverse),
		.scrm_seed(scrm_seed),
		.scrm_seed_user(scrm_seed_user),
		.scrm_mode(scrm_mode),
		.dispgen_bypass(dispgen_bypass),
		.dispgen_err(dispgen_err),
		.dispgen_pipeln(dispgen_pipeln),
		.gb_sel_mode(gb_sel_mode),
		.sq_wave(sq_wave),
		.bitslip_en(bitslip_en),
		.fastpath(fastpath),
		.distup_bypass_pipeln(distup_bypass_pipeln),
		.distup_master(distup_master),
		.distdwn_bypass_pipeln(distdwn_bypass_pipeln),
		.distdwn_master(distdwn_master),
		.compin_sel(compin_sel),
		.comp_cnt(comp_cnt),
		.indv(indv),
		.stretch_num_stages(stretch_num_stages),
		.stretch_en(stretch_en),
		.iqtxrx_clkout_sel(iqtxrx_clkout_sel),
		.tx_testbus_sel(tx_testbus_sel),
		.tx_true_b2b(tx_true_b2b),
		.tx_scrm_width(tx_scrm_width),
		.pmagate_en(pmagate_en),
		.tx_polarity_inv(tx_polarity_inv),
		.comp_del_sel_agg(comp_del_sel_agg),
		.distup_bypass_pipeln_agg(distup_bypass_pipeln_agg),
		.distdwn_bypass_pipeln_agg(distdwn_bypass_pipeln_agg),
		.tx_sh_location(tx_sh_location),
		.tx_scrm_err(tx_scrm_err),
		.avmm_group_channel_index(avmm_group_channel_index),
		.use_default_base_address(use_default_base_address),
		.user_base_address(user_base_address),
		.phcomp_rd_del(phcomp_rd_del)

	)
	stratixv_hssi_10g_tx_pcs_encrypted_inst	(
		.avmmaddress(avmmaddress),
		.avmmbyteen(avmmbyteen),
		.avmmclk(avmmclk),
		.avmmread(avmmread),
		.avmmrstn(avmmrstn),
		.avmmwrite(avmmwrite),
		.avmmwritedata(avmmwritedata),
		.distdwnindv(distdwnindv),
		.distdwninintlknrden(distdwninintlknrden),
		.distdwninrden(distdwninrden),
		.distdwninrdpfull(distdwninrdpfull),
		.distdwninwren(distdwninwren),
		.distupindv(distupindv),
		.distupinintlknrden(distupinintlknrden),
		.distupinrden(distupinrden),
		.distupinrdpfull(distupinrdpfull),
		.distupinwren(distupinwren),
		.hardresetn(hardresetn),
		.pmaclkdiv33lc(pmaclkdiv33lc),
		.refclkdig(refclkdig),
		.txbitslip(txbitslip),
		.txbursten(txbursten),
		.txcontrol(txcontrol),
		.txdata(txdata),
		.txdatavalid(txdatavalid),
		.txdiagnosticstatus(txdiagnosticstatus),
		.txdisparityclr(txdisparityclr),
		.txpldclk(txpldclk),
		.txpldrstn(txpldrstn),
		.txpmaclk(txpmaclk),
		.txwordslip(txwordslip),
		.avmmreaddata(avmmreaddata),
		.blockselect(blockselect),
		.dfxlpbkcontrolout(dfxlpbkcontrolout),
		.dfxlpbkdataout(dfxlpbkdataout),
		.dfxlpbkdatavalidout(dfxlpbkdatavalidout),
		.distdwnoutdv(distdwnoutdv),
		.distdwnoutintlknrden(distdwnoutintlknrden),
		.distdwnoutrden(distdwnoutrden),
		.distdwnoutrdpfull(distdwnoutrdpfull),
		.distdwnoutwren(distdwnoutwren),
		.distupoutdv(distupoutdv),
		.distupoutintlknrden(distupoutintlknrden),
		.distupoutrden(distupoutrden),
		.distupoutrdpfull(distupoutrdpfull),
		.distupoutwren(distupoutwren),
		.lpbkdataout(lpbkdataout),
		.syncdatain(syncdatain),
		.txburstenexe(txburstenexe),
		.txclkiqout(txclkiqout),
		.txclkout(txclkout),
		.txfifodel(txfifodel),
		.txfifoempty(txfifoempty),
		.txfifofull(txfifofull),
		.txfifoinsert(txfifoinsert),
		.txfifopartialempty(txfifopartialempty),
		.txfifopartialfull(txfifopartialfull),
		.txframe(txframe),
		.txpmadata(txpmadata),
		.txwordslipexe(txwordslipexe)
	);


endmodule
// ----------------------------------------------------------------------------------
// This is the HSSI Simulation Atom Model Encryption wrapper for the AVMM Interface
// Module Name : stratixv_hssi_avmm_interface
// ----------------------------------------------------------------------------------

`timescale 1 ps/1 ps
module stratixv_hssi_avmm_interface
  #(
    parameter num_ch0_atoms = 0,
    parameter num_ch1_atoms = 0,
    parameter num_ch2_atoms = 0
    )
(
//input and output port declaration
    input  wire                 avmmrstn,
    input  wire                 avmmclk,
    input  wire                 avmmwrite,
    input  wire                 avmmread,
    input  wire  [ 1:0 ]        avmmbyteen,
    input  wire  [ 10:0 ]       avmmaddress,
    input  wire  [ 15:0 ]       avmmwritedata,
    input  wire  [ 90-1:0 ]     blockselect,
    input  wire  [ 90*16 -1:0 ] readdatachnl,

    output wire  [ 15:0 ]       avmmreaddata,

    output wire                 clkchnl,
    output wire                 rstnchnl,
    output wire  [ 15:0 ]       writedatachnl,
    output wire  [ 10:0 ]       regaddrchnl,
    output wire                 writechnl,
    output wire                 readchnl,
    output wire  [ 1:0 ]        byteenchnl,

    //The following ports are not modelled. They exist to match the avmm interface atom interface
    input  wire                 refclkdig,
    input  wire                 avmmreservedin,
    
    output wire                 avmmreservedout,
    output wire                 dpriorstntop,
    output wire                 dprioclktop,
    output wire                 mdiodistopchnl,
    output wire                 dpriorstnmid,
    output wire                 dprioclkmid,
    output wire                 mdiodismidchnl,
    output wire                 dpriorstnbot,
    output wire                 dprioclkbot,
    output wire                 mdiodisbotchnl,
    output wire  [ 3:0 ]        dpriotestsitopchnl,
    output wire  [ 3:0 ]        dpriotestsimidchnl,
    output wire  [ 3:0 ]        dpriotestsibotchnl,
 
    //The following ports belong to pm_adce and pm_tst_mux blocks in the PMA
    input  wire  [ 11:0 ]       pmatestbussel,
    output wire  [ 23:0 ]       pmatestbus,
  
    //
    input  wire                 scanmoden,
    input  wire                 scanshiftn,
    input  wire                 interfacesel,
    input  wire                 sershiftload
); 

  stratixv_hssi_avmm_interface_encrypted
  #(
    .num_ch0_atoms(num_ch0_atoms),
    .num_ch1_atoms(num_ch1_atoms),
    .num_ch2_atoms(num_ch2_atoms)
  ) stratixv_hssi_avmm_interface_encrypted_inst (
    .avmmrstn          (avmmrstn),
    .avmmclk           (avmmclk),
    .avmmwrite         (avmmwrite),
    .avmmread          (avmmread),
    .avmmbyteen        (avmmbyteen),
    .avmmaddress       (avmmaddress),
    .avmmwritedata     (avmmwritedata),
    .blockselect       (blockselect),
    .readdatachnl      (readdatachnl),
    .avmmreaddata      (avmmreaddata),
    .clkchnl           (clkchnl),
    .rstnchnl          (rstnchnl),
    .writedatachnl     (writedatachnl),
    .regaddrchnl       (regaddrchnl),
    .writechnl         (writechnl),
    .readchnl          (readchnl),
    .byteenchnl        (byteenchnl),
    .refclkdig         (refclkdig),
    .avmmreservedin    (avmmreservedin),
    .avmmreservedout   (avmmreservedout),
    .dpriorstntop      (dpriorstntop),
    .dprioclktop       (dprioclktop),
    .mdiodistopchnl    (mdiodistopchnl),
    .dpriorstnmid      (dpriorstnmid),
    .dprioclkmid       (dprioclkmid),
    .mdiodismidchnl    (mdiodismidchnl),
    .dpriorstnbot      (dpriorstnbot),
    .dprioclkbot       (dprioclkbot),
    .mdiodisbotchnl    (mdiodisbotchnl),
    .dpriotestsitopchnl(dpriotestsitopchnl),
    .dpriotestsimidchnl(dpriotestsimidchnl),
    .dpriotestsibotchnl(dpriotestsibotchnl),
    .pmatestbus        (pmatestbus),
    .pmatestbussel     (pmatestbussel),
    .scanmoden         (scanmoden),
    .scanshiftn        (scanshiftn),
    .interfacesel      (interfacesel),
    .sershiftload      (sershiftload)
  );

endmodule
