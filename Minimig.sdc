derive_pll_clocks
derive_clock_uncertainty

set_multicycle_path -from {emu|cpu_wrapper|cpu_inst*} -to {emu|ram*} -setup 2
set_multicycle_path -from {emu|cpu_wrapper|cpu_inst*} -to {emu|ram*} -hold 1

set_multicycle_path -from {emu|amiga_clk|cck*} -to {emu|ram1|*} -setup 2
set_multicycle_path -from {emu|amiga_clk|cck*} -to {emu|ram1|*} -hold 1
set_multicycle_path -from {emu|minimig|*} -to {emu|ram1|*} -setup 2
set_multicycle_path -from {emu|minimig|*} -to {emu|ram1|*} -hold 1

set_false_path -from {emu|cpu_wrapper|z3ram_*}
set_false_path -from {emu|cpu_wrapper|z2ram_*}

set_false_path -from {emu|minimig|USERIO1|cpu_config*}
set_false_path -from {emu|minimig|USERIO1|ide_config*}
set_false_path -from {emu|minimig|USERIO1|bootrom}
set_false_path -from {emu|minimig|CPU1|halt}

# A2065: the card's 68k side (clk_sys) reaches its DDR3 mailbox (DDRAM_CLK,
# clk_114) over 2-FF level-detect CDC handshakes inside a2065_regfile and
# a2065_ddram. Those are self-timed and need no multicycle exception. If the
# fitter reports real violations across that boundary, add a targeted
# set_false_path/set_max_delay derived from report_timing — do not guess.

# yc_out chroma LUT: multicycle retained from the old bridge, where boardram BRAM
# placement congestion pushed this path to -0.471ns. The flat-DDR3 design removes
# that BRAM, so this exception may now be UNNECESSARY. Re-validate against the
# merged fitter run (R3); keep only if report_timing still shows the path marginal.
set_multicycle_path -from {yc_out|chroma_LUT_BURST[*]} \
                    -to   {yc_out|phase[*].u[*]} -setup 2
set_multicycle_path -from {yc_out|chroma_LUT_BURST[*]} \
                    -to   {yc_out|phase[*].u[*]} -hold 1

# emu PLL cross-clock: counter[1]→counter[0] marginal path
set_multicycle_path -setup 2 -from [get_clocks "emu|pll|pll_inst|altera_pll_i|cyclonev_pll|counter\[1\].output_counter|divclk"] -to [get_clocks "emu|pll|pll_inst|altera_pll_i|cyclonev_pll|counter\[0\].output_counter|divclk"]
set_multicycle_path -hold 1 -from [get_clocks "emu|pll|pll_inst|altera_pll_i|cyclonev_pll|counter\[1\].output_counter|divclk"] -to [get_clocks "emu|pll|pll_inst|altera_pll_i|cyclonev_pll|counter\[0\].output_counter|divclk"]

#these constraints aren't really correct, but help fitting.
#28MHz pixel clock might be affected when scandoubler fx is used.
set_multicycle_path -to {*Hq2x*} -setup 2
set_multicycle_path -to {*Hq2x*} -hold 1
set_multicycle_path -from [get_clocks { *|pll|pll_inst|altera_pll_i|*[0].*|divclk}] -to {ascal|*} -setup 2
set_multicycle_path -from [get_clocks { *|pll|pll_inst|altera_pll_i|*[0].*|divclk}] -to {ascal|*} -hold 1
