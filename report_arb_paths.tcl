project_open Minimig
create_timing_netlist
read_sdc Minimig.sdc
update_timing_netlist

puts "=== Top 10 worst setup paths overall ==="
report_timing -setup -npaths 10 -detail summary

puts ""
puts "=== Paths involving chipdma_arb (any direction) ==="
report_timing -setup -npaths 5 -detail summary -from {emu|chipdma_arb|*}
report_timing -setup -npaths 5 -detail summary -to   {emu|chipdma_arb|*}

delete_timing_netlist
project_close
