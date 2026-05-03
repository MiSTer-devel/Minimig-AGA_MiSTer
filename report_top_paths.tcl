project_open Minimig
create_timing_netlist
read_sdc Minimig.sdc
update_timing_netlist

puts "=== Worst clk_114 -> clk_114 setup (within-clock) ==="
report_timing -setup -npaths 3 -detail summary \
    -from_clock { emu|pll|pll_inst|altera_pll_i|cyclonev_pll|counter[0].output_counter|divclk } \
    -to_clock   { emu|pll|pll_inst|altera_pll_i|cyclonev_pll|counter[0].output_counter|divclk }

puts ""
puts "=== Detailed worst within-clock_114 path ==="
report_timing -setup -npaths 1 -detail full_path \
    -from_clock { emu|pll|pll_inst|altera_pll_i|cyclonev_pll|counter[0].output_counter|divclk } \
    -to_clock   { emu|pll|pll_inst|altera_pll_i|cyclonev_pll|counter[0].output_counter|divclk }

delete_timing_netlist
project_close
