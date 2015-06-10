# SimVision Command Script (Tue Jun 09 05:55:34 PM CEST 2015)
#
# Version 14.10.s003
#
# You can restore this configuration with:
#
#     simvision -input simvision.sv
#  or simvision -input simvision.sv database1 database2 ...
#


#
# Preferences
#
preferences set toolbar-Standard-WatchWindow {
  usual
  shown 0
}
preferences set toolbar-SimControl-WatchList {
  usual
  hide set_break
}
preferences set waveform-print-variables all
preferences set txe-locate-add-fibers 1
preferences set signal-type-colors {input #FFFF00 fiber #FF99FF errorsignal #FF0000 assertion #FF0000 unknown #FFFFFF group #0000FF output #FFA500 internal #00FF00 overlay #0000FF inout #00FFFF}
preferences set schematic-color-highlight #ff0000
preferences set txe-view-hold 0
preferences set txe-navigate-search-locate 0
preferences set plugin-enable-svdatabrowser-new 1
preferences set toolbar-Windows-WatchWindow {
  usual
  shown 0
}
preferences set toolbar-CursorControl-WaveWindow {
  usual
  position -row 0 -pos 2
}
preferences set verilog-colors {Su #ff0099 0 {} 1 {} HiZ #ff9900 We #00ffff Pu #9900ff Sm #00ff99 X #ff0000 StrX #ff0000 other #ffff00 Z #ff9900 Me #0000ff La #ff00ff St {}}
preferences set txe-navigate-waveform-locate 1
preferences set txe-view-hidden 0
preferences set waveform-print-paper {A4 (210mm x 297mm)}
preferences set waveform-height 12
preferences set show-signal-tooltip 1
preferences set sfb-colors {register #beded1 assignStmt gray85 variable #beded1 force #faa385}
preferences set txe-search-show-linenumbers 1
preferences set sb-syntax-types {
    {-name "VHDL/VHDL-AMS" -cleanname "vhdl" -extensions {.vhd .vhdl}}
    {-name "Verilog/Verilog-AMS" -cleanname "verilog" -extensions {.v .vams .vms .va}}
    {-name "C" -cleanname "c" -extensions {.c}}
    {-name "C++" -cleanname "c++" -extensions {.h .hpp .cc .cpp .CC}}
    {-name "SystemC" -cleanname "systemc" -extensions {.h .hpp .cc .cpp .CC}}
}
preferences set schematic-show-rtl 1
preferences set toolbar-OperatingMode-WaveWindow {
  usual
  position -pos 4
  name OperatingMode
}
preferences set plugin-enable-svdatabrowser 0
preferences set toolbar-txe_waveform_toggle-WaveWindow {
  usual
  position -pos 1
}
preferences set plugin-enable-groupscope 0
preferences set key-bindings {PageUp PageUp ScrollLeft {Left arrow} View>ExpandSequenceTime>AtCursor Alt+X View>Zoom>FullX_widget = #Waveform Window Edit>Undo Ctrl+Z Simulation>Next F6 View>Zoom>InX Alt+I View>Zoom>In Alt+I File>CloseWindow Ctrl+Shift+w ScrollUp {Up arrow} View>Zoom>Out Alt+O ScrollRight {Right arrow} PageDown PageDown Select>All Ctrl+A Edit>Delete Del Edit>Copy Ctrl+C View>Zoom>FullX Alt+= ScrollDown {Down arrow} Simulation>Run F2 openDB Ctrl+O Edit>Cut Ctrl+X Edit>Create>Marker Ctrl+M Edit>Create>Bus Ctrl+W Edit>Paste Ctrl+V Explore>NextEdge Ctrl+\] View>Zoom>Cursor-Baseline Alt+Z View>Center Alt+C Edit>Select>All Ctrl+A View>Zoom>FullY_widget Y Edit>Create>Group Ctrl+G #Schematic window View>Zoom>OutX Alt+O Edit>Ungroup Ctrl+Shift+G Edit>SelectAll Ctrl+A View>CollapseSequenceTime>AtCursor Alt+S Edit>Create>Condition Ctrl+E TopOfPage Home Edit>Redo Ctrl+Y View>Zoom>InX_widget I Simulation>Step F5 View>Zoom>Fit Alt+= View>Zoom>OutX_widget O Explore>PreviousEdge {Ctrl+[} BottomOfPage End}
preferences set schematic-show-cells 1
preferences set plugin-enable-interleaveandcompare 0
preferences set use-signal-type-icons 0
preferences set toolbar-SimControl-WatchWindow {
  usual
  shown 0
}
preferences set txe-navigate-waveform-next-child 0
preferences set toolbar-Edit-WatchWindow {
  usual
  shown 0
}
preferences set toolbar-WaveZoom-WaveWindow {
  usual
  position -row 0 -pos 5
}
preferences set sb-syntax-extensions-systemc {.h .hpp .cc .cpp .CC}
preferences set vhdl-colors {X #ff0000 0 {} L #00ffff H #00ffff U #9900ff 1 {} - {} Z #ff9900 W #ff0000}
preferences set color-verilog-by-value 0
preferences set txe-locate-scroll-x 1
preferences set txe-locate-scroll-y 1
preferences set txe-locate-pop-waveform 1
preferences set whats-new-dont-show-at-startup 1
preferences set use-signal-type-colors 1
preferences set toolbar-TimeSearch-WatchWindow {
  usual
  shown 0
}

#
# Databases
#
array set dbNames ""
set dbNames(realName1) [ database require wav -hints {
	file ../out/wav/wav.trn
	file /home/rokk/Dropbox/work/electronics/fpga/minimig-mist/sim/cpu_cache_sdram/nc/out/wav/wav.trn
}]
if {$dbNames(realName1) == ""} {
    set dbNames(realName1) wav
}

#
# Mnemonic Maps
#
mmap new -reuse -name {Boolean as Logic} -radix %b -contents {{%c=FALSE -edgepriority 1 -shape low}
{%c=TRUE -edgepriority 1 -shape high}}
mmap new -reuse -name {Example Map} -radix %x -contents {{%b=11???? -bgcolor orange -label REG:%x -linecolor yellow -shape bus}
{%x=1F -bgcolor red -label ERROR -linecolor white -shape EVENT}
{%x=2C -bgcolor red -label ERROR -linecolor white -shape EVENT}
{%x=* -label %x -linecolor gray -shape bus}}

#
# Waveform windows
#
if {[catch {window new WaveWindow -name "Waveform 1" -geometry 1680x998+1600+56}] != ""} {
    window geometry "Waveform 1" 1680x998+1600+56
}
window target "Waveform 1" on
waveform using {Waveform 1}
waveform sidebar select designbrowser
waveform set \
    -primarycursor TimeA \
    -signalnames name \
    -signalwidth 175 \
    -units ns \
    -valuewidth 90
waveform baseline set -time 0

set id [waveform add -signals [subst  {
	{$dbNames(realName1)::[format {cpu_cache_sdram_tb.sdram_ctrl.sysclk}]}
	{$dbNames(realName1)::[format {cpu_cache_sdram_tb.sdram_ctrl.reset_in}]}
	{$dbNames(realName1)::[format {cpu_cache_sdram_tb.sdram_ctrl.cache_rst}]}
	{$dbNames(realName1)::[format {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.cpu_cs}]}
	{$dbNames(realName1)::[format {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.cpu_adr[24:0]}]}
	{$dbNames(realName1)::[format {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.cpu_ir}]}
	{$dbNames(realName1)::[format {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.cpu_dr}]}
	{$dbNames(realName1)::[format {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.cpu_we}]}
	{$dbNames(realName1)::[format {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.cpu_bs[1:0]}]}
	{$dbNames(realName1)::[format {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.cpu_dat_w[15:0]}]}
	{$dbNames(realName1)::[format {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.cpu_dat_r[15:0]}]}
	{$dbNames(realName1)::[format {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.cpu_ack}]}
	{$dbNames(realName1)::[format {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.cpu_sm_state[7:0]}]}
	{$dbNames(realName1)::[format {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.sdr_sm_state[7:0]}]}
	{$dbNames(realName1)::[format {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.cache_init_done}]}
	{$dbNames(realName1)::[format {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.sdr_sm_adr[9:0]}]}
	{$dbNames(realName1)::[format {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.sdr_sm_iram0_we}]}
	{$dbNames(realName1)::[format {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.sdr_sm_iram1_we}]}
	{$dbNames(realName1)::[format {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.sdr_sm_dram0_we}]}
	{$dbNames(realName1)::[format {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.sdr_sm_dram1_we}]}
	{$dbNames(realName1)::[format {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.sdr_sm_mem_dat_w[15:0]}]}
	{$dbNames(realName1)::[format {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.sdr_sm_tag_adr[13:0]}]}
	{$dbNames(realName1)::[format {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.sdr_sm_itag_we}]}
	{$dbNames(realName1)::[format {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.sdr_sm_dtag_we}]}
	{$dbNames(realName1)::[format {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.sdr_sm_tag_dat_w[31:0]}]}
	{$dbNames(realName1)::[format {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.sdr_read_ack}]}
	{$dbNames(realName1)::[format {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.sdr_read_req}]}
	{$dbNames(realName1)::[format {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.itag0_valid}]}
	{$dbNames(realName1)::[format {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.itag0_match}]}
	{$dbNames(realName1)::[format {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.itag1_valid}]}
	{$dbNames(realName1)::[format {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.itag1_match}]}
	{$dbNames(realName1)::[format {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.dtag0_valid}]}
	{$dbNames(realName1)::[format {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.dtag0_match}]}
	{$dbNames(realName1)::[format {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.dtag1_valid}]}
	{$dbNames(realName1)::[format {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.dtag1_match}]}
	{$dbNames(realName1)::[format {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.cpu_sm_itag_we}]}
	{$dbNames(realName1)::[format {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.cpu_sm_dtag_we}]}
	{$dbNames(realName1)::[format {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.cpu_sm_iram0_we}]}
	{$dbNames(realName1)::[format {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.cpu_sm_iram1_we}]}
	{$dbNames(realName1)::[format {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.cpu_sm_dram0_we}]}
	{$dbNames(realName1)::[format {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.cpu_sm_dram1_we}]}
	{$dbNames(realName1)::[format {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.sdr_sm_dlru}]}
	{$dbNames(realName1)::[format {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.sdr_sm_id}]}
	} ]]
set id [waveform add -signals [subst  {
	{$dbNames(realName1)::[format {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.dtram.mem[0:255]}]}
	} ]]
waveform hierarchy expand $id
set id [waveform add -signals [subst  {
	{$dbNames(realName1)::[format {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.itram.mem[0:255]}]}
	} ]]

waveform xview limits 63525.42ns 63650.42ns

#
# Waveform Window Links
#

#
# Layout selection
#

