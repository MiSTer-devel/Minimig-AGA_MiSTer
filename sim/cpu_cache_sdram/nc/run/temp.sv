# SimVision Command Script (Thu Mar 06 23:27:30 CET 2014)
#
# Version 05.82.p001
#
# You can restore this configuration with:
#
#     simvision -input /home/rkrajnc/Dropbox/work/electronics/fpga/minimig-de1/sim/cpu_cache_sdram/nc/run/temp.sv
#  or simvision -input /home/rkrajnc/Dropbox/work/electronics/fpga/minimig-de1/sim/cpu_cache_sdram/nc/run/temp.sv database1 database2 ...
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
  position -row 0 -pos 3
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
  position -anchor e
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
preferences set use-signal-type-icons 0
preferences set toolbar-SimControl-WatchWindow {
  usual
  hide vplan
  shown 0
}
preferences set waveform-print-colors {As shown on screen}
preferences set toolbar-Windows-WaveWindow {
  usual
  hide icheck
  position -row 1
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
  position -row 1 -pos 1
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
	file /home/rkrajnc/Dropbox/work/electronics/fpga/minimig-de1/sim/cpu_cache_sdram/nc/out/wav/wav.trn
}

#
# groups
#
catch {group new -name cache -overlay 0}
catch {group new -name sys -overlay 0}
catch {group new -name tg68_ram -overlay 0}
catch {group new -name cpu_fast -overlay 0}

group using cache
group set -overlay 0
group set -comment {}
group set -parents {}
group set -groups {}
group clear 0 end

group insert \
    cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.clk \
    cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.rst \
    cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.cpu_cs \
    {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.cpu_adr[24:1]} \
    {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.cpu_state[5:0]} \
    cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.cpu_wr \
    cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.cpu_rd \
    {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.cpu_bs[1:0]} \
    {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.cpu_dat_w[15:0]} \
    {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.cpu_dat_r[15:0]} \
    cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.cpu_ack \
    cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.tag_w0_match \
    cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.tag_w1_match \
    {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.state[2:0]} \
    cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.st_tag_we \
    cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.st_mem_we_0 \
    cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.st_mem_we_1 \
    cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.st_lru \
    cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.sdr_cpucycle \
    {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.sdr_state[3:0]} \
    {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.tag_ram.mem[0:127]} \
    {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.st_adr[8:0]} \
    {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.mem_ram_1.wraddress[8:0]} \
    cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.mem_ram_1.wren \
    {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.mem_ram_0.wraddress[8:0]} \
    cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.mem_ram_0.wren \
    {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.mem_ram_0.mem0[0:511]} \
    {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.mem_ram_0.mem1[0:511]} \
    {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.st_tag_dat_w[31:0]} \
    cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.st_tag_we \
    cpu_cache_sdram_tb.tg68_rst \
    cpu_cache_sdram_tb.sdram_ctrl.reset \
    cpu_cache_sdram_tb.sdram_ctrl.cache_rst \
    cpu_cache_sdram_tb.sdram_ctrl.reset_in \
    cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.rst \
    {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.adr_idx[6:0]} \
    {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.mem_ram_1.q[15:0]} \
    {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.mem_ram_0.q[15:0]} \
    {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.sdr_dat_r[15:0]} \
    {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.cpu_dat_r[15:0]} \
    {cpu_cache_sdram_tb.sdram_ctrl.sdata_reg[15:0]} \
    cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.mem_ram_1.wren \
    {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.mem_ram_1.wraddress[8:0]} \
    {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.mem_ram_1.data[15:0]} \
    {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.mem_ram_1.mem0[0:511]} \
    {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.mem_ram_1.mem1[0:511]} \
    {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.st_adr[8:0]}

group using sys
group set -overlay 0
group set -comment {}
group set -parents {}
group set -groups {}
group clear 0 end

group insert \
    cpu_cache_sdram_tb.clk_114 \
    cpu_cache_sdram_tb.clk_28 \
    cpu_cache_sdram_tb.clk_7 \
    cpu_cache_sdram_tb.RST \
    cpu_cache_sdram_tb.pll_locked \
    cpu_cache_sdram_tb.reset_out

group using tg68_ram
group set -overlay 0
group set -comment {}
group set -parents {}
group set -groups {}
group clear 0 end

group insert \
    cpu_cache_sdram_tb.tg68_ram.tg68_as \
    {cpu_cache_sdram_tb.tg68_ram.tg68_adr[31:0]} \
    cpu_cache_sdram_tb.tg68_ram.tg68_rw \
    cpu_cache_sdram_tb.tg68_ram.tg68_uds \
    cpu_cache_sdram_tb.tg68_ram.tg68_lds \
    {cpu_cache_sdram_tb.tg68_ram.tg68_dat_in[15:0]} \
    {cpu_cache_sdram_tb.tg68_ram.tg68_dat_out[15:0]} \
    cpu_cache_sdram_tb.tg68_ram.tg68_dtack

group using cpu_fast
group set -overlay 0
group set -comment {}
group set -parents {}
group set -groups {}
group clear 0 end

group insert \
    {cpu_cache_sdram_tb.sdram_ctrl.cpuAddr[24:1]} \
    cpu_cache_sdram_tb.sdram_ctrl.cpu_dma \
    {cpu_cache_sdram_tb.sdram_ctrl.cpustate[5:0]} \
    {cpu_cache_sdram_tb.sdram_ctrl.cpuWR[15:0]} \
    cpu_cache_sdram_tb.sdram_ctrl.cpuU \
    cpu_cache_sdram_tb.sdram_ctrl.cpuL \
    {cpu_cache_sdram_tb.sdram_ctrl.cpuRD[15:0]} \
    cpu_cache_sdram_tb.sdram_ctrl.cpuena

#
# cursors
#
set time 54935ns
if {[catch {cursor new -name  TimeA -time $time}] != ""} {
    cursor set -using TimeA -time $time
}
set time 0
if {[catch {cursor new -name  TimeB -time $time}] != ""} {
    cursor set -using TimeB -time $time
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
if {[catch {window new WatchList -name "Design Browser 1" -geometry 1074x654+50+100}] != ""} {
    window geometry "Design Browser 1" 1074x654+50+100
}
window target "Design Browser 1" on
browser using {Design Browser 1}
browser set \
    -scope cpu_cache_sdram_tb.sdram_ctrl.cpu_cache
browser yview see cpu_cache_sdram_tb.sdram_ctrl.cpu_cache
browser timecontrol set -lock 0

#
# Waveform windows
#
if {[catch {window new WaveWindow -name "Waveform 1" -geometry 1425x977+7+22}] != ""} {
    window geometry "Waveform 1" 1425x977+7+22
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
cursor set -using TimeA -time 54,935ns
waveform baseline set -time 17,724,992,000fs

set groupId [waveform add -groups sys]

set id [waveform add -signals [list cpu_cache_sdram_tb.tg68k:reset ]]
set groupId [waveform add -groups tg68_ram]

set groupId [waveform add -groups cpu_fast]

set groupId [waveform add -groups cache]

set id [waveform add -signals [list {cpu_cache_sdram_tb.sdram_ctrl.cpu_cache.cpu_state[5:0]} ]]
waveform hierarchy expand $id

waveform xview limits 83868.438371ns 85197.255107ns
