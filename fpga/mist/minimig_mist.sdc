
# time information
set_time_format -unit ns -decimal_places 3


#create clocks
create_clock -name pll_in_clk -period 37.037  [get_ports {CLOCK_27[0]}]
create_clock -name spi_clk    -period 40.000  [get_ports {SPI_SCK}]

# pll clocks
derive_pll_clocks


# generated clocks
create_generated_clock -name clk_7 -source [get_pins {amiga_clk|amiga_clk_i|altpll_component|auto_generated|pll1|clk[2]}] -divide_by 4 [get_pins {amiga_clk|clk7_cnt[1]|q}]


# name PLL clocks
set clk_sdram "amiga_clk|amiga_clk_i|altpll_component|auto_generated|pll1|clk[0]"
set clk_114   "amiga_clk|amiga_clk_i|altpll_component|auto_generated|pll1|clk[1]"
set clk_28    "amiga_clk|amiga_clk_i|altpll_component|auto_generated|pll1|clk[2]"


# name SDRAM ports
set sdram_outputs [get_ports {SDRAM_DQ[*] SDRAM_A[*] SDRAM_DQML SDRAM_DQMH SDRAM_nWE SDRAM_nCAS SDRAM_nRAS SDRAM_nCS SDRAM_BA[*] SDRAM_CKE}]
set sdram_inputs  [get_ports {SDRAM_DQ[*]}]


# clock groups
set_clock_groups -exclusive -group [get_clocks {amiga_clk|amiga_clk_i|altpll_component|auto_generated|pll1|clk[0] amiga_clk|amiga_clk_i|altpll_component|auto_generated|pll1|clk[1] amiga_clk|amiga_clk_i|altpll_component|auto_generated|pll1|clk[2]}] -group [get_clocks {spi_clk}]


# clock uncertainty
derive_clock_uncertainty


# input delay
set_input_delay -clock $clk_sdram -max 6.4 $sdram_inputs
set_input_delay -clock $clk_sdram -min 3.2 $sdram_inputs
#set_input_delay -clock $clk_sdram -max 6.5 $sdram_inputs
#set_input_delay -clock $clk_sdram -min 2.7 $sdram_inputs

#output delay
set_output_delay -clock $clk_sdram -max  1.5 $sdram_outputs
set_output_delay -clock $clk_sdram -min -0.8 $sdram_outputs


# false paths
set_false_path -from * -to [get_ports {LED}]
set_false_path -from * -to [get_ports {UART_TX}]
set_false_path -from [get_ports {UART_RX}] -to *
set_false_path -from * -to [get_ports {VGA_*}]
set_false_path -from * -to [get_ports {AUDIO_L}]
set_false_path -from * -to [get_ports {AUDIO_R}]


# multicycle paths
set_multicycle_path 4 -to [get_fanouts [get_pins {amiga_clk|clk7_en_reg|q*}]  -through [get_pins -hierarchical *|*ena*]] -end -setup
set_multicycle_path 3 -to [get_fanouts [get_pins {amiga_clk|clk7_en_reg|q*}]  -through [get_pins -hierarchical *|*ena*]] -end -hold
set_multicycle_path 4 -to [get_fanouts [get_pins {amiga_clk|clk7n_en_reg|q*}] -through [get_pins -hierarchical *|*ena*]] -end -setup
set_multicycle_path 3 -to [get_fanouts [get_pins {amiga_clk|clk7n_en_reg|q*}] -through [get_pins -hierarchical *|*ena*]] -end -hold
set_multicycle_path 2 -to $clk_114 -from $clk_sdram -end -setup
#set_multicycle_path 1 -to $clk_114 -from $clk_sdram -end -hold


# JTAG
set ports [get_ports -nowarn {altera_reserved_tck}]
if {[get_collection_size $ports] == 1} {
  create_clock -name tck -period 100.000 [get_ports {altera_reserved_tck}]
  set_clock_groups -exclusive -group altera_reserved_tck
  set_output_delay -clock tck 20 [get_ports altera_reserved_tdo]
  set_input_delay  -clock tck 20 [get_ports altera_reserved_tdi]
  set_input_delay  -clock tck 20 [get_ports altera_reserved_tms]
  set tck altera_reserved_tck
  set tms altera_reserved_tms
  set tdi altera_reserved_tdi
  set tdo altera_reserved_tdo
  set_false_path -from *                -to [get_ports $tdo]
  set_false_path -from [get_ports $tms] -to *
  set_false_path -from [get_ports $tdi] -to *
}
