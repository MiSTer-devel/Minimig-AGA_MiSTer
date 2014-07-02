# SimVision Command Script (Fri Feb 14 15:18:33 CET 2014)
#
# Version 11.10.s052
#
# You can restore this configuration with:
#
#     simvision -input sdm.sv
#  or simvision -input sdm.sv database1 database2 ...
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
preferences set txe-navigate-search-locate 0
preferences set txe-view-hold 0
preferences set toolbar-CursorControl-WaveWindow {
  usual
  position -row 0 -pos 2
}
preferences set toolbar-Windows-WatchWindow {
  usual
  shown 0
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
  hide vplan
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
	file /proj/tmp/rokk/sdm/sim/sdm/nc/out/wav/wav.trn
}]
if {$dbNames(realName1) == ""} {
    set dbNames(realName1) wav
}

#
# Cursors
#
set time 0
if {[catch {cursor new -name  TimeA -time $time}] != ""} {
    cursor set -using TimeA -time $time
}
set time 0
if {[catch {cursor new -name  TimeB -time $time}] != ""} {
    cursor set -using TimeB -time $time
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
# Design Browser windows
#
if {[catch {window new WatchList -name "Design Browser 3" -geometry 1021x681+-30400+-31887}] != ""} {
    window geometry "Design Browser 3" 1021x681+-30400+-31887
}
window target "Design Browser 3" on
browser using {Design Browser 3}
browser set -scope [subst  {$dbNames(realName1)::[format {sdm_tb}]} ]
browser set \
    -signalsort name
browser yview see [subst  {$dbNames(realName1)::[format {sdm_tb}]} ]
browser timecontrol set -lock 0

#
# Waveform windows
#
if {[catch {window new WaveWindow -name "Waveform 1" -geometry 1680x998+1600+135}] != ""} {
    window geometry "Waveform 1" 1680x998+1600+135
}
window target "Waveform 1" on
waveform using {Waveform 1}
waveform sidebar visibility partial
waveform set \
    -primarycursor TimeA \
    -signalnames name \
    -signalwidth 175 \
    -units ns \
    -valuewidth 100
cursor set -using TimeA -time 0
waveform baseline set -time 332,928,260ps

set id [waveform add -signals [subst  {
	{$dbNames(realName1)::[format {sdm_tb.clk}]}
	{$dbNames(realName1)::[format {sdm_tb.sdm.seed1[23:0]}]}
	{$dbNames(realName1)::[format {sdm_tb.sdm.seed2[18:0]}]}
	{$dbNames(realName1)::[format {sdm_tb.sdm.seed_sum[23:0]}]}
	{$dbNames(realName1)::[format {sdm_tb.sdm.seed_prev[23:0]}]}
	{$dbNames(realName1)::[format {sdm_tb.sdm.seed_out[23:0]}]}
	{$dbNames(realName1)::[format {sdm_tb.sdm.int_cnt[3:0]}]}
	{$dbNames(realName1)::[format {sdm_tb.sdm.ldata_cur[14:0]}]}
	{$dbNames(realName1)::[format {sdm_tb.sdm.ldata_prev[14:0]}]}
	{$dbNames(realName1)::[format {sdm_tb.sdm.ldata_step[15:0]}]}
	{$dbNames(realName1)::[format {sdm_tb.sdm.ldata_int[18:0]}]}
	{$dbNames(realName1)::[format {sdm_tb.sdm.ldata_int_out[14:0]}]}
	{$dbNames(realName1)::[format {sdm_tb.sdm.ldata_gain[16:0]}]}
	{$dbNames(realName1)::[format {sdm_tb.sdm.sd_l_aca1[18:0]}]}
	{$dbNames(realName1)::[format {sdm_tb.sdm.sd_l_aca2[21:0]}]}
	{$dbNames(realName1)::[format {sdm_tb.sdm.sd_l_ac1[18:0]}]}
	{$dbNames(realName1)::[format {sdm_tb.sdm.sd_l_ac2[21:0]}]}
	{$dbNames(realName1)::[format {sdm_tb.sdm.sd_l_quant[22:0]}]}
	{$dbNames(realName1)::[format {sdm_tb.sdm.sd_l_er0[16:0]}]}
	{$dbNames(realName1)::[format {sdm_tb.sdm.sd_l_er0_prev[16:0]}]}
	{$dbNames(realName1)::[format {sdm_tb.sdm.left}]}
	} ]]
set id [waveform add -signals [subst  {
	{$dbNames(realName1)::[format {sdm_tb.lmean}]}
	} ]]
waveform format $id -trace analogSampleAndHold
waveform axis range $id -for default -min -0.38098655292449585 -max 0.38143391307980246 -scale linear
set id [waveform add -signals [subst  {
	{$dbNames(realName1)::[format {sdm_tb.rmean}]}
	} ]]
waveform format $id -trace analogSampleAndHold
waveform axis range $id -for default -min -0.38098655292449585 -max 0.38143391307980246 -scale linear

waveform xview limits 0 1024145.98ns

#
# Waveform Window Links
#

