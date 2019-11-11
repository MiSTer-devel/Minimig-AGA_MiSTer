set_multicycle_path -start -setup -from [get_keepers *fx68k:*|Ir[*]] -to [get_keepers *fx68k:*|microAddr[*]] 2
set_multicycle_path -start -hold -from [get_keepers  *fx68k:*|Ir[*]] -to [get_keepers *fx68k:*|microAddr[*]] 1
set_multicycle_path -start -setup -from [get_keepers *fx68k:*|Ir[*]] -to [get_keepers *fx68k:*|nanoAddr[*]] 2
set_multicycle_path -start -hold -from [get_keepers  *fx68k:*|Ir[*]] -to [get_keepers *fx68k:*|nanoAddr[*]] 1
