derive_pll_clocks
derive_clock_uncertainty

set_multicycle_path -from {emu|cpu_wrapper|cpu_inst*} -to {emu|ram*} -setup 2
set_multicycle_path -from {emu|cpu_wrapper|cpu_inst*} -to {emu|ram*} -hold 1

set_multicycle_path -from {emu|amiga_clk|cck*} -to {emu|ram1|*} -setup 2
set_multicycle_path -from {emu|amiga_clk|cck*} -to {emu|ram1|*} -hold 1
set_multicycle_path -from {emu|minimig|*} -to {emu|ram1|*} -setup 2
set_multicycle_path -from {emu|minimig|*} -to {emu|ram1|*} -hold 1

# CD32 Akiko PBX address path to SDRAM. pbx_byte_idx only advances on dma_ack,
# which fires at most once per 6+ emu-clk cycles (chipdma_arb's S_DRIVE takes 4
# cycles minimum). Address is stable for well over 2 launch-clk cycles before
# the next update, so a 2-cycle setup multicycle is safe. Mirrors the existing
# emu|minimig|* -> emu|ram1|* relaxation. Without this, pbx_seccnt -> sd_addr
# violates by ~2.5 ns.
set_multicycle_path -from {emu|fastchip|akiko|*} -to {emu|ram1|*} -setup 2
set_multicycle_path -from {emu|fastchip|akiko|*} -to {emu|ram1|*} -hold 1
set_multicycle_path -from {emu|chipdma_arb|*}    -to {emu|ram1|*} -setup 2
set_multicycle_path -from {emu|chipdma_arb|*}    -to {emu|ram1|*} -hold 1

# 2026-05-29: amiga_clk c1/c3 are the 7 MHz-rate phase regs in the 28 MHz
# (clk_28) domain (c1 <= ~c3). The chip-arming address path launches from c1,
# passes through chipdma_arb combinational logic, and lands on sdram_ctrl.sd_addr
# captured by the 113 MHz SDRAM clock. -from matches the LAUNCH register (c1),
# not the chipdma_arb pass-through nodes, so the existing chipdma_arb|* and cck*
# relaxations did NOT cover it -> sd_addr violated -0.49 ns. clk_114:clk_28 is 4:1;
# sdram_ctrl edge-detects ~old_7m&c_7m (sdram_ctrl.v:237-243) so a c1 launch at fast
# edge N is detected at N+1 and the state-0 RAS capture (sdram_ctrl.v:301-318) is at
# N+2 -> exactly 2 clk_114 cycles, never the adjacent edge. setup-2 matches (Codex-verified
# SAFE 2026-05-29); setup>=3 would NOT be safe. Mirrors the cck*/chipdma_arb relaxations.
set_multicycle_path -from {emu|amiga_clk|c1*} -to {emu|ram1|*} -setup 2
set_multicycle_path -from {emu|amiga_clk|c1*} -to {emu|ram1|*} -hold 1
set_multicycle_path -from {emu|amiga_clk|c3*} -to {emu|ram1|*} -setup 2
set_multicycle_path -from {emu|amiga_clk|c3*} -to {emu|ram1|*} -hold 1

# Phase B v2: bridge DMA write port on ram2 (DDR3) is now a proper CDC
# handshake. chipdma_arb (clk_sys) registers dma_ddr_cs_r + the entire DDR
# bus (addr / wr / l / u) on arm_now and holds them stable until S_ACK.
# ddram_ctrl (clk_114) synchronizes dmaCS through a 2-FF chain, edge-detects
# the rise, and latches data on that edge — by which point the data has
# been valid in chipdma_arb for many clk_114 cycles. dmaACK comes back as a
# level signal, synchronized by a 2-FF chain inside chipdma_arb.
#
# Net effect: dmaCS is the ONLY cross-domain bit that needs proper timing
# (sync chain handles metastability). The data lines are stable-by-handshake,
# so set_false_path is correct.
#
# The previous v1 multicycle hacks were the wrong shape for this CDC — slow→
# fast multicycle 4 still left -8 ns slack on these paths, and at -2.1 ns
# post-fit worst, the bridge UIO init never completed on hardware (akiko log
# stayed at 0 bytes). v2 RTL removes the violation by construction.
set_false_path -from {*chipdma_arb*dma_ddr_addr_r*} -to {*ddram_ctrl*}
set_false_path -from {*chipdma_arb*dma_ddr_wr_r*}   -to {*ddram_ctrl*}
set_false_path -from {*chipdma_arb*dma_ddr_l_r*}    -to {*ddram_ctrl*}
set_false_path -from {*chipdma_arb*dma_ddr_u_r*}    -to {*ddram_ctrl*}
# Phase B v2.1: also false_path the two CDC sync first-stages. dma_ddr_cs_r
# → dmaCS_sync1 is the slow→fast (clk_sys → clk_114) handshake; dmaACK_r
# → ddr_in_ack_sync1 is the reverse. Both are absorbed by 2-FF synchronizer
# chains in their target domains — metastable-tolerant by construction.
# Without this, Quartus tries to time them at single cycle and reports
# −3.7 ns slack. (Functionally fine, but report should be clean.)
set_false_path -from {*chipdma_arb*dma_ddr_cs_r*}   -to {*ddram_ctrl*dmaCS_sync*}
set_false_path -from {*ddram_ctrl*dmaACK_r*}        -to {*chipdma_arb*ddr_in_ack_sync*}

set_false_path -from {emu|cpu_wrapper|z3ram_*}
set_false_path -from {emu|cpu_wrapper|z2ram_*}

set_false_path -from {emu|minimig|USERIO1|cpu_config*}
set_false_path -from {emu|minimig|USERIO1|ide_config*}
set_false_path -from {emu|minimig|USERIO1|bootrom}
set_false_path -from {emu|minimig|CPU1|halt}

#these constraints aren't really correct, but help fitting.
#28MHz pixel clock might be affected when scandoubler fx is used.
set_multicycle_path -to {*Hq2x*} -setup 2
set_multicycle_path -to {*Hq2x*} -hold 1
set_multicycle_path -from [get_clocks { *|pll|pll_inst|altera_pll_i|*[0].*|divclk}] -to {ascal|*} -setup 2
set_multicycle_path -from [get_clocks { *|pll|pll_inst|altera_pll_i|*[0].*|divclk}] -to {ascal|*} -hold 1
