derive_pll_clocks
derive_clock_uncertainty

set_multicycle_path -from {emu|cpu_wrapper|cpu_inst*} -to [get_clocks {*|pll|pll_inst|altera_pll_i|*[0].*|divclk}] -setup 2
set_multicycle_path -from {emu|cpu_wrapper|cpu_inst*} -to [get_clocks {*|pll|pll_inst|altera_pll_i|*[0].*|divclk}] -hold 1

set_multicycle_path -from {emu|amiga_clk|cck*} -to {emu|ram1|*} -setup 2
set_multicycle_path -from {emu|amiga_clk|cck*} -to {emu|ram1|*} -hold 1
set_multicycle_path -from {emu|minimig|*} -to {emu|ram1|*} -setup 2
set_multicycle_path -from {emu|minimig|*} -to {emu|ram1|*} -hold 1

set_false_path -from {emu|cpu_wrapper|z3ram_*}
set_false_path -from {emu|cpu_wrapper|z2ram_*}

set_false_path -from {emu|minimig|USERIO1|cpu_config*}
set_false_path -from {emu|minimig|USERIO1|ide_config*}
set_false_path -from {emu|minimig|CPU1|halt}
set_false_path -from {emu|reset_s*}

# SDRAM
create_generated_clock -name SDRAM_CLK -source [get_pins -compatibility_mode {*|pll|pll_inst|altera_pll_i|*[1].*|divclk}] [get_ports {SDRAM_CLK}]

set_multicycle_path -to {SDRAM_D* SDRAM_A* SDRAM_BA* SDRAM_n*} -start -setup 2
set_multicycle_path -to {SDRAM_D* SDRAM_A* SDRAM_BA* SDRAM_n*} -start -hold 1
