# SimVision Command Script (Thu Jun 19 17:04:52 CEST 2014)
#
# Version 13.20.s008
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
	file /home/rokk/Dropbox/work/electronics/fpga/minimig-de1/sim/ps2mouse/nc/out/wav/wav.trn
}]
if {$dbNames(realName1) == ""} {
    set dbNames(realName1) wav
}

#
# Mnemonic Maps
#
mmap new -reuse -name {Boolean as Logic} -radix %x -contents {{%c=FALSE -edgepriority 1 -shape low}
{%c=TRUE -edgepriority 1 -shape high}}
mmap new -reuse -name {Example Map} -radix %x -contents {{%b=11???? -bgcolor orange -label REG:%x -linecolor yellow -shape bus}
{%x=1F -bgcolor red -label ERROR -linecolor white -shape EVENT}
{%x=2C -bgcolor red -label ERROR -linecolor white -shape EVENT}
{%x=* -label %x -linecolor gray -shape bus}}

#
# Design Browser windows
#
if {[catch {window new WatchList -name "Design Browser 1" -geometry 700x500+0+0}] != ""} {
    window geometry "Design Browser 1" 700x500+0+0
}
window target "Design Browser 1" on
browser using {Design Browser 1}
browser set -scope [subst  {$dbNames(realName1)::[format {ps2mouse_tb.ps2mouse.configure}]} ]
browser set \
    -signalsort name
browser yview see [subst  {$dbNames(realName1)::[format {ps2mouse_tb.ps2mouse.configure}]} ]
browser timecontrol set -lock 0

#
# Waveform windows
#
if {[catch {window new WaveWindow -name "Waveform 1" -geometry 1680x998+1600+147}] != ""} {
    window geometry "Waveform 1" 1680x998+1600+147
}
window target "Waveform 1" on
waveform using {Waveform 1}
waveform sidebar visibility partial
waveform set \
    -primarycursor TimeA \
    -signalnames name \
    -signalwidth 175 \
    -units ns \
    -valuewidth 75
waveform baseline set -time 619,191,000ps

set id [waveform add -signals [subst  {
	{$dbNames(realName1)::[format {ps2mouse_tb.ps2mouse.clk}]}
	{$dbNames(realName1)::[format {ps2mouse_tb.ps2mouse.rst}]}
	{$dbNames(realName1)::[format {ps2mouse_tb.ps2mouse.mclk}]}
	{$dbNames(realName1)::[format {ps2mouse_tb.ps2mouse.mdat}]}
	{$dbNames(realName1)::[format {ps2mouse_tb.ps2mouse.mclk_en}]}
	{$dbNames(realName1)::[format {ps2mouse_tb.ps2mouse.mclk_i}]}
	{$dbNames(realName1)::[format {ps2mouse_tb.ps2mouse.mclk_o}]}
	{$dbNames(realName1)::[format {ps2mouse_tb.ps2mouse.mdat_en}]}
	{$dbNames(realName1)::[format {ps2mouse_tb.ps2mouse.mdat_i}]}
	{$dbNames(realName1)::[format {ps2mouse_tb.ps2mouse.mdat_o}]}
	{$dbNames(realName1)::[format {ps2mouse_tb.ps2mouse.ps2_tx.dat[7:0]}]}
	{$dbNames(realName1)::[format {ps2mouse_tb.ps2mouse.ps2_tx.i}]}
	{$dbNames(realName1)::[format {ps2mouse_tb.ps2mouse.ps2_tx.parity}]}
	{$dbNames(realName1)::[format {ps2mouse_tb.ps2mouse.ps2_tx.status}]}
	{$dbNames(realName1)::[format {ps2mouse_tb.ps2mouse.ps2_rx.dat[7:0]}]}
	{$dbNames(realName1)::[format {ps2mouse_tb.ps2mouse.ps2_rx.i}]}
	{$dbNames(realName1)::[format {ps2mouse_tb.ps2mouse.ps2_rx.parity}]}
	{$dbNames(realName1)::[format {ps2mouse_tb.ps2mouse.ps2_rx.status}]}
	{$dbNames(realName1)::[format {ps2mouse_tb.ps2mouse_ctrl.msend[11:0]}]}
	{$dbNames(realName1)::[format {ps2mouse_tb.ps2mouse_ctrl.msend[8:1]}]}
	{$dbNames(realName1)::[format {ps2mouse_tb.ps2mouse_ctrl.msready}]}
	{$dbNames(realName1)::[format {ps2mouse_tb.ps2mouse_ctrl.msreset}]}
	{$dbNames(realName1)::[format {ps2mouse_tb.ps2mouse_ctrl.mreceive[10:0]}]}
	{$dbNames(realName1)::[format {ps2mouse_tb.ps2mouse_ctrl.mreceive[8:1]}]}
	{$dbNames(realName1)::[format {ps2mouse_tb.ps2mouse_ctrl.mrready}]}
	{$dbNames(realName1)::[format {ps2mouse_tb.ps2mouse_ctrl.mrreset}]}
	{$dbNames(realName1)::[format {ps2mouse_tb.ps2mouse.configure.configured}]}
	{$dbNames(realName1)::[format {ps2mouse_tb.ps2mouse_ctrl.mclkneg}]}
	{$dbNames(realName1)::[format {ps2mouse_tb.ps2mouse_ctrl.mpacket[3:0]}]}
	{$dbNames(realName1)::[format {ps2mouse_tb.ps2mouse_ctrl.dat_out[11:0]}]}
	{$dbNames(realName1)::[format {ps2mouse_tb.ps2mouse_ctrl.dat_cnt[3:0]}]}
	{$dbNames(realName1)::[format {ps2mouse_tb.ps2mouse_ctrl.mclkout}]}
	{$dbNames(realName1)::[format {ps2mouse_tb.ps2mouse_ctrl.mdatout}]}
	{$dbNames(realName1)::[format {ps2mouse_tb.ps2mouse_ctrl.mstate[2:0]}]}
	{$dbNames(realName1)::[format {ps2mouse_tb.ps2mouse_ctrl.mtready}]}
	{$dbNames(realName1)::[format {ps2mouse_tb.ps2mouse_ctrl.mtimer[15:0]}]}
	{$dbNames(realName1)::[format {ps2mouse_tb.ps2mouse_ctrl.mtreset}]}
	{$dbNames(realName1)::[format {ps2mouse_tb.ps2mouse_ctrl.mthalf}]}
	{$dbNames(realName1)::[format {ps2mouse_tb.ps2mouse.intellimouse}]}
	{$dbNames(realName1)::[format {ps2mouse_tb.ps2mouse_ctrl.intellimouse}]}
	{$dbNames(realName1)::[format {ps2mouse_tb.ps2mouse_ctrl._mleft}]}
	{$dbNames(realName1)::[format {ps2mouse_tb.ps2mouse_ctrl._mright}]}
	{$dbNames(realName1)::[format {ps2mouse_tb.ps2mouse_ctrl._mthird}]}
	{$dbNames(realName1)::[format {ps2mouse_tb.ps2mouse_ctrl.xcount[7:0]}]}
	{$dbNames(realName1)::[format {ps2mouse_tb.ps2mouse_ctrl.ycount[7:0]}]}
	{$dbNames(realName1)::[format {ps2mouse_tb.ps2mouse_ctrl.zcount[7:0]}]}
	} ]]

waveform xview limits 14494117.899ns 36565637.131ns

#
# Waveform Window Links
#

