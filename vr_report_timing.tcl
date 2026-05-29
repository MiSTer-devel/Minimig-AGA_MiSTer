project_open Minimig -revision Minimig
create_timing_netlist -model slow
read_sdc
update_timing_netlist
# Worst setup paths across all corners; counter[0] = 113 MHz SDRAM/cache clock
report_timing -setup -npaths 20 -detail full_path -multi_corner \
    -file ../../../research/tmp/vr_worst_setup.rpt
report_timing -setup -npaths 20 -detail summary -multi_corner -stdout
project_close
