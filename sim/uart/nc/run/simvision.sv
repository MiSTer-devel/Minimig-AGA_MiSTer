# SimVision Command Script (Fri Mar 15 00:47:56 CET 2013)
#
# Version 05.82.p001
#
# You can restore this configuration with:
#
#     simvision -input /home/rkrajnc/Dropbox/work/electronics/fpga/minimig-de1/sim/uart/nc/run/simvision.sv
#  or simvision -input /home/rkrajnc/Dropbox/work/electronics/fpga/minimig-de1/sim/uart/nc/run/simvision.sv database1 database2 ...
#


#
# preferences
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
preferences set signal-type-colors {input #FFFF00 fiber #FF99FF errorsignal #FF0000 assertion #FF0000 unknown #FFFFFF group #0099ff output #FFA500 internal #00ff00 overlay #0000FF inout #00FFFF}
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
preferences set toolbar-TimeSearch-WaveWindow {
  usual
  position -row 0 -pos 3 -anchor e
}
preferences set waveform-print-paper {A4 (210mm x 297mm)}
preferences set waveform-height 12
preferences set show-signal-tooltip 1
preferences set sfb-colors {register #beded1 assignStmt gray85 variable #beded1 force #faa385}
preferences set sb-syntax-types {
    {-name "VHDL/VHDL-AMS" -cleanname "vhdl" -extensions {.vhd .vhdl}}
    {-name "Verilog/Verilog-AMS" -cleanname "verilog" -extensions {.v .vams .vms .va}}
    {-name "C" -cleanname "c" -extensions {.c}}
    {-name "C++" -cleanname "c++" -extensions {.h .hpp .cc .cpp .CC}}
    {-name "SystemC" -cleanname "systemc" -extensions {.h .hpp .cc .cpp .CC}}
}
preferences set txe-search-show-linenumbers 1
preferences set toolbar-OperatingMode-WaveWindow {
  usual
  position -pos 3
  name OperatingMode
}
preferences set schematic-show-rtl 1
preferences set plugin-enable-svdatabrowser 0
preferences set toolbar-NavSignalList-WaveWindow {
  usual
  position -row 0 -pos 4 -anchor e
}
preferences set toolbar-txe_waveform_toggle-WaveWindow {
  usual
  position -pos 1
}
preferences set toolbar-Windows-SrcBrowser {
  usual
  hide icheck
}
preferences set plugin-enable-groupscope 0
preferences set key-bindings {PageUp PageUp ScrollLeft {Left arrow} View>ExpandSequenceTime>AtCursor Alt+X View>Zoom>FullX_widget = #Waveform Window Edit>Undo Ctrl+Z Simulation>Next F6 View>Zoom>InX Alt+I View>Zoom>In Alt+I File>CloseWindow Ctrl+Shift+w ScrollUp {Up arrow} View>Zoom>Out Alt+O ScrollRight {Right arrow} PageDown PageDown Select>All Ctrl+A Edit>Delete Del Edit>Copy Ctrl+C View>Zoom>FullX Alt+= ScrollDown {Down arrow} Simulation>Run F2 openDB Ctrl+O Edit>Cut Ctrl+X Edit>Create>Marker Ctrl+M Edit>Create>Bus Ctrl+W Edit>Paste Ctrl+V Explore>NextEdge Ctrl+\] View>Zoom>Cursor-Baseline Alt+Z View>Center Alt+C Edit>Select>All Ctrl+A View>Zoom>FullY_widget Y Edit>Create>Group Ctrl+G #Schematic window View>Zoom>OutX Alt+O Edit>Ungroup Ctrl+Shift+G Edit>SelectAll Ctrl+A View>CollapseSequenceTime>AtCursor Alt+S Edit>Create>Condition Ctrl+E TopOfPage Home Edit>Redo Ctrl+Y View>Zoom>InX_widget I Simulation>Step F5 View>Zoom>Fit Alt+= View>Zoom>OutX_widget O Explore>PreviousEdge {Ctrl+[} BottomOfPage End}
preferences set schematic-show-cells 1
preferences set plugin-enable-interleaveandcompare 0
preferences set toolbar-SimControl-WatchWindow {
  usual
  hide vplan
  shown 0
}
preferences set waveform-print-colors {As shown on screen}
preferences set toolbar-Windows-WaveWindow {
  usual
  hide icheck
  position -pos 6
}
preferences set txe-navigate-waveform-next-child 0
preferences set toolbar-Windows-WatchList {
  usual
  hide icheck
}
preferences set toolbar-Edit-WatchWindow {
  usual
  shown 0
}
preferences set toolbar-WaveZoom-WaveWindow {
  usual
  position -row 0 -pos 5
}
preferences set sb-syntax-extensions-systemc {.h .hpp .cc .cpp .CC}
preferences set vhdl-colors {H #00ffff L #00ffff 0 {} X #ff0000 - {} 1 {} U #9900ff Z #ff9900 W #ff0000}
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
# databases
#
database require wav -hints {
	file ../out/wav/wav.trn
	file /home/rkrajnc/Dropbox/work/electronics/fpga/minimig-de1/sim/uart/nc/out/wav/wav.trn
}

#
# cursors
#
set time 28120.95ns
if {[catch {cursor new -name  TimeA -time $time}] != ""} {
    cursor set -using TimeA -time $time
}

#
# mmaps
#
mmap new -reuse -name {Boolean as Logic} -contents {
{%c=FALSE -edgepriority 1 -shape low}
{%c=TRUE -edgepriority 1 -shape high}
}
mmap new -reuse -name {Example Map} -contents {
{%b=11???? -bgcolor orange -label REG:%x -linecolor yellow -shape bus}
{%x=1F -bgcolor red -label ERROR -linecolor white -shape EVENT}
{%x=2C -bgcolor red -label ERROR -linecolor white -shape EVENT}
{%x=* -label %x -linecolor gray -shape bus}
}

#
# Design Browser windows
#
if {[catch {window new WatchList -name "Design Browser 1" -geometry 700x500+610+354}] != ""} {
    window geometry "Design Browser 1" 700x500+610+354
}
window target "Design Browser 1" on
browser using {Design Browser 1}
browser set \
    -scope uart_tb.uart_verilog2
browser yview see uart_tb.uart_verilog2
browser timecontrol set -lock 0

#
# Waveform windows
#
if {[catch {window new WaveWindow -name "Waveform 1" -geometry 1920x1117+0+22}] != ""} {
    window geometry "Waveform 1" 1920x1117+0+22
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
cursor set -using TimeA -time 28,120.95ns
waveform baseline set -time 0

set id [waveform add -signals [list uart_tb.clk \
	uart_tb.rst \
	uart_tb.uart_vhdl_master:rga_i \
	uart_tb.uart_vhdl_master:data_i \
	uart_tb.uart_vhdl_master:data_o ]]
set id [waveform add -signals [list uart_tb.uart_vhdl:UART_MOD:r ]]
waveform hierarchy expand $id
set id [waveform add -signals [list {uart_tb.uart_verilog2.serper[15:0]} \
	{uart_tb.uart_verilog2.serdatr[4:0]} \
	{uart_tb.uart_verilog2.rx_state[1:0]} \
	{uart_tb.uart_verilog2.rx_cnt[15:0]} \
	{uart_tb.uart_verilog2.rx_shift[9:0]} \
	{uart_tb.uart_verilog2.rx_data[9:0]} \
	uart_tb.uart_verilog2.rx_rbf \
	uart_tb.uart_verilog2.rx_rxd \
	uart_tb.uart_verilog2.rx_irq ]]

waveform xview limits 42041.282984ns 43001.282984ns
