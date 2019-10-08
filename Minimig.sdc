derive_pll_clocks

create_generated_clock -source [get_pins -compatibility_mode {*|pll|pll_inst|altera_pll_i|*[1].*|divclk}] \
                       -name SDRAM_CLK [get_ports {SDRAM_CLK}]

derive_clock_uncertainty

set_multicycle_path -from {*|TG68K:tg68k|TG68KdotC_Kernel:pf68K_Kernel_inst|*} -setup 3
set_multicycle_path -from {*|TG68K:tg68k|TG68KdotC_Kernel:pf68K_Kernel_inst|*} -hold 2
set_multicycle_path -from {emu:emu|TG68K:tg68k|z3ram_base*} -setup 2
set_multicycle_path -from {emu:emu|TG68K:tg68k|z3ram_base*} -hold 2
set_multicycle_path -from {emu:emu|TG68K:tg68k|z3ram_ena*} -setup 2
set_multicycle_path -from {emu:emu|TG68K:tg68k|z3ram_ena*} -hold 2
set_multicycle_path -from {emu:emu|TG68K:tg68k|NMI_addr[*]} -setup 2
set_multicycle_path -from {emu:emu|TG68K:tg68k|NMI_addr[*]} -hold 2

set_false_path -from {*|userio:USERIO1|cpu_config*}
set_false_path -from {*|userio:USERIO1|ide_config*}
set_false_path -from {*|minimig_m68k_bridge:CPU1|halt}

set_multicycle_path -from [get_clocks {*|pll|pll_inst|altera_pll_i|*[2].*|divclk}] -to [get_clocks {*|pll|pll_inst|altera_pll_i|*[0].*|divclk}] -setup 2
set_multicycle_path -from [get_clocks {*|pll|pll_inst|altera_pll_i|*[2].*|divclk}] -to [get_clocks {*|pll|pll_inst|altera_pll_i|*[0].*|divclk}] -hold 1

set_input_delay  -max -clock SDRAM_CLK  6.4ns [get_ports SDRAM_DQ[*]]
set_input_delay  -min -clock SDRAM_CLK  3.7ns [get_ports SDRAM_DQ[*]]
set_output_delay -max -clock SDRAM_CLK  1.6ns [get_ports {SDRAM_D* SDRAM_A* SDRAM_BA* SDRAM_n* SDRAM_CKE}]
set_output_delay -min -clock SDRAM_CLK -0.9ns [get_ports {SDRAM_D* SDRAM_A* SDRAM_BA* SDRAM_n* SDRAM_CKE}]
