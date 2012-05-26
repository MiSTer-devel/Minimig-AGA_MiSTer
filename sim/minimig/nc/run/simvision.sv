# SimVision Command Script (Tue Mar 13 18:18:20 CET 2012)
#
# Version 10.20.s071
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
preferences set signal-type-colors {
	group #0000FF
	overlay #0000FF
	input #FFFF00
	output #FFA500
	inout #00FFFF
	internal #00FF00
	fiber #FF99FF
	errorsignal #FF0000
	assertion #FF0000
	unknown #FFFFFF
}
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
  position -pos 3
  name OperatingMode
}
preferences set plugin-enable-svdatabrowser 0
preferences set toolbar-txe_waveform_toggle-WaveWindow {
  usual
  position -pos 1
}
preferences set plugin-enable-groupscope 0
preferences set key-bindings {
	Edit>Undo "Ctrl+Z"
	Edit>Redo "Ctrl+Y"
	Edit>Copy "Ctrl+C"
	Edit>Cut "Ctrl+X"
	Edit>Paste "Ctrl+V"
	Edit>Delete "Del"
        Select>All "Ctrl+A"
        Edit>Select>All "Ctrl+A"
        Edit>SelectAll "Ctrl+A"
      	openDB "Ctrl+O"
        Simulation>Run "F2"
        Simulation>Next "F6"
        Simulation>Step "F5"
        #Schematic window
        View>Zoom>Fit "Alt+="
        View>Zoom>In "Alt+I"
        View>Zoom>Out "Alt+O"
        #Waveform Window
	View>Zoom>InX "Alt+I"
	View>Zoom>OutX "Alt+O"
	View>Zoom>FullX "Alt+="
	View>Zoom>InX_widget "I"
	View>Zoom>OutX_widget "O"
	View>Zoom>FullX_widget "="
	View>Zoom>FullY_widget "Y"
	View>Zoom>Cursor-Baseline "Alt+Z"
	View>Center "Alt+C"
	View>ExpandSequenceTime>AtCursor "Alt+X"
	View>CollapseSequenceTime>AtCursor "Alt+S"
	Edit>Create>Group "Ctrl+G"
	Edit>Ungroup "Ctrl+Shift+G"
	Edit>Create>Marker "Ctrl+M"
	Edit>Create>Condition "Ctrl+E"
	Edit>Create>Bus "Ctrl+W"
	Explore>NextEdge "Ctrl+]"
	Explore>PreviousEdge "Ctrl+["
	ScrollRight "Right arrow"
	ScrollLeft "Left arrow"
	ScrollUp "Up arrow"
	ScrollDown "Down arrow"
	PageUp "PageUp"
	PageDown "PageDown"
	TopOfPage "Home"
	BottomOfPage "End"
}
preferences set schematic-show-cells 1
preferences set plugin-enable-interleaveandcompare 0
preferences set use-signal-type-icons 0
preferences set toolbar-SimControl-WatchWindow {
  usual
  hide vplan
  shown 0
}
preferences set toolbar-Windows-WaveWindow {
  usual
  position -pos 4
}
preferences set txe-navigate-waveform-next-child no
preferences set toolbar-Edit-WatchWindow {
  usual
  shown 0
}
preferences set toolbar-WaveZoom-WaveWindow {
  usual
  position -row 1
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
	file /home/rokk/Dropbox/work/electronics/fpga/minimig-de1/sim/minimig/nc/out/wav/wav.trn
}]
if {$dbNames(realName1) == ""} {
    set dbNames(realName1) wav
}

#
# Groups
#
catch {group new -name cfide -overlay 0}

group using cfide
group set -overlay 0
group set -comment {}
group clear 0 end

group insert \
    [subst  {$dbNames(realName1)::[format {soc_tb.soc_top.cfide.TxD}]} ] \
    [subst  {$dbNames(realName1)::[format {soc_tb.soc_top.cfide.addr[23:0]}]} ] \
    [subst  {$dbNames(realName1)::[format {soc_tb.soc_top.cfide.cpudata[15:0]}]} ] \
    [subst  {$dbNames(realName1)::[format {soc_tb.soc_top.cfide.cpudata_in[15:0]}]} ] \
    [subst  {$dbNames(realName1)::[format {soc_tb.soc_top.cfide.cpuena}]} ] \
    [subst  {$dbNames(realName1)::[format {soc_tb.soc_top.cfide.cpuena_in}]} ] \
    [subst  {$dbNames(realName1)::[format {soc_tb.soc_top.cfide.enaWRreg}]} ] \
    [subst  {$dbNames(realName1)::[format {soc_tb.soc_top.cfide.memce}]} ] \
    [subst  {$dbNames(realName1)::[format {soc_tb.soc_top.cfide.memdata_in[15:0]}]} ] \
    [subst  {$dbNames(realName1)::[format {soc_tb.soc_top.cfide.n_reset}]} ] \
    [subst  {$dbNames(realName1)::[format {soc_tb.soc_top.cfide.sd_clk}]} ] \
    [subst  {$dbNames(realName1)::[format {soc_tb.soc_top.cfide.sd_cs[7:0]}]} ] \
    [subst  {$dbNames(realName1)::[format {soc_tb.soc_top.cfide.sd_di}]} ] \
    [subst  {$dbNames(realName1)::[format {soc_tb.soc_top.cfide.sd_dimm}]} ] \
    [subst  {$dbNames(realName1)::[format {soc_tb.soc_top.cfide.sd_do}]} ] \
    [subst  {$dbNames(realName1)::[format {soc_tb.soc_top.cfide.state[1:0]}]} ] \
    [subst  {$dbNames(realName1)::[format {soc_tb.soc_top.cfide.sysclk}]} ] \
    [subst  {$dbNames(realName1)::[format {soc_tb.soc_top.cfide.lds}]} ] \
    [subst  {$dbNames(realName1)::[format {soc_tb.soc_top.cfide.uds}]} ]

#
# Cursors
#
set time 339268ns
if {[catch {cursor new -name  TimeA -time $time}] != ""} {
    cursor set -using TimeA -time $time
}

#
# Mnemonic Maps
#
mmap new -reuse -name {Boolean as Logic} -radix %b -contents {
{%c=FALSE -edgepriority 1 -shape low}
{%c=TRUE -edgepriority 1 -shape high}
}
mmap new -reuse -name {Example Map} -radix %x -contents {
{%b=11???? -bgcolor orange -label REG:%x -linecolor yellow -shape bus}
{%x=1F -bgcolor red -label ERROR -linecolor white -shape EVENT}
{%x=2C -bgcolor red -label ERROR -linecolor white -shape EVENT}
{%x=* -label %x -linecolor gray -shape bus}
}

#
# Design Browser windows
#
if {[catch {window new WatchList -name "Design Browser 1" -geometry 1050x731+0+0}] != ""} {
    window geometry "Design Browser 1" 1050x731+0+0
}
window target "Design Browser 1" on
browser using {Design Browser 1}
browser set -scope [subst  {$dbNames(realName1)::[format {soc_tb.soc_top.minimig}]} ]
browser set \
    -showinternals 0 \
    -signalsort name
browser yview see [subst  {$dbNames(realName1)::[format {soc_tb.soc_top.minimig}]} ]
browser timecontrol set -lock 0

#
# Waveform windows
#
if {[catch {window new WaveWindow -name "Waveform 1" -geometry 1600x1153+0+0}] != ""} {
    window geometry "Waveform 1" 1600x1153+0+0
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
cursor set -using TimeA -time 339,268ns
waveform baseline set -time 0

set id [waveform add -signals [subst  {
	{$dbNames(realName1)::[format {soc_tb.soc_top.tg68:clk}]}
	{$dbNames(realName1)::[format {soc_tb.soc_top.tg68:reset}]}
	{$dbNames(realName1)::[format {soc_tb.soc_top.tg68:clkena_in}]}
	{$dbNames(realName1)::[format {soc_tb.soc_top.tg68_fast:clk}]}
	{$dbNames(realName1)::[format {soc_tb.soc_top.tg68_fast:clkena_in}]}
	{$dbNames(realName1)::[format {soc_tb.soc_top.tg68_fast:reset}]}
	{$dbNames(realName1)::[format {soc_tb.soc_top.tg68_fast:enaRDreg}]}
	{$dbNames(realName1)::[format {soc_tb.soc_top.tg68_fast:enaWRreg}]}
	{$dbNames(realName1)::[format {soc_tb.soc_top.tg68_fast:IPL}]}
	{$dbNames(realName1)::[format {soc_tb.soc_top.tg68_fast:state_out}]}
	{$dbNames(realName1)::[format {soc_tb.soc_top.tg68_fast:address}]}
	{$dbNames(realName1)::[format {soc_tb.soc_top.tg68_fast:data_in}]}
	{$dbNames(realName1)::[format {soc_tb.soc_top.tg68_fast:data_write}]}
	{$dbNames(realName1)::[format {soc_tb.soc_top.tg68_fast:LDS}]}
	{$dbNames(realName1)::[format {soc_tb.soc_top.tg68_fast:UDS}]}
	{$dbNames(realName1)::[format {soc_tb.soc_top.tg68_fast:wr}]}
	} ]]

set groupId0 [waveform add -groups cfide]

set id [waveform add -signals [subst  {
	{$dbNames(realName1)::[format {soc_tb.soc_top.cfide.srom.address[9:0]}]}
	{$dbNames(realName1)::[format {soc_tb.soc_top.cfide.srom.byteena[1:0]}]}
	{$dbNames(realName1)::[format {soc_tb.soc_top.cfide.srom.clock}]}
	{$dbNames(realName1)::[format {soc_tb.soc_top.cfide.srom.data[15:0]}]}
	{$dbNames(realName1)::[format {soc_tb.soc_top.cfide.srom.q[15:0]}]}
	{$dbNames(realName1)::[format {soc_tb.soc_top.cfide.srom.wren}]}
	{$dbNames(realName1)::[format {soc_tb.soc_top.minimig.red[3:0]}]}
	{$dbNames(realName1)::[format {soc_tb.soc_top.minimig.green[3:0]}]}
	{$dbNames(realName1)::[format {soc_tb.soc_top.minimig.blue[3:0]}]}
	{$dbNames(realName1)::[format {soc_tb.soc_top.minimig._hsync}]}
	{$dbNames(realName1)::[format {soc_tb.soc_top.minimig._vsync}]}
	} ]]

waveform xview limits 0 5142859.019ns

#
# Waveform Window Links
#

