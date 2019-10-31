derive_pll_clocks
derive_clock_uncertainty

set_multicycle_path -from {emu|cpu_wrapper|cpu|*} -to [get_clocks {*|pll|pll_inst|altera_pll_i|*[0].*|divclk}] -setup 2
set_multicycle_path -from {emu|cpu_wrapper|cpu|*} -to [get_clocks {*|pll|pll_inst|altera_pll_i|*[0].*|divclk}] -hold 1

set_max_delay 14.5 -from {emu|amiga_clk|cck*} -to {emu|ram1|*}
set_max_delay 14.5 -from {emu|minimig|*} -to {emu|ram1|*}

set_max_delay  9.0 -from {emu|ram*|cpu_cache|*} -to {emu|cpu_wrapper|*}

set_false_path -from {emu|cpu_wrapper|z3ram_*}
set_false_path -from {emu|cpu_wrapper|z2ram_*}

set_false_path -from {emu|minimig|USERIO1|cpu_config*}
set_false_path -from {emu|minimig|USERIO1|ide_config*}
set_false_path -from {emu|minimig|CPU1|halt}
set_false_path -from {emu|reset_s*}

# SDRAM
create_generated_clock -name SDRAM_CLK -source [get_pins -compatibility_mode {*|pll|pll_inst|altera_pll_i|*[1].*|divclk}] [get_ports {SDRAM_CLK}]

#set_input_delay  -max -clock SDRAM_CLK  6.4ns [get_ports SDRAM_DQ[*]]
#set_input_delay  -min -clock SDRAM_CLK  3.7ns [get_ports SDRAM_DQ[*]]
#set_output_delay -max -clock SDRAM_CLK  1.6ns [get_ports {SDRAM_D* SDRAM_A* SDRAM_BA* SDRAM_n* SDRAM_CKE}]
#set_output_delay -min -clock SDRAM_CLK -0.9ns [get_ports {SDRAM_D* SDRAM_A* SDRAM_BA* SDRAM_n* SDRAM_CKE}]

set_multicycle_path -to {SDRAM_D* SDRAM_A* SDRAM_BA* SDRAM_n*} -start -setup 2
set_multicycle_path -to {SDRAM_D* SDRAM_A* SDRAM_BA* SDRAM_n*} -start -hold 1
