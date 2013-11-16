# SimVision Command Script (Tue Jul 30 00:27:31 CEST 2013)
#
# Version 05.82.p001
#
# You can restore this configuration with:
#
#     simvision -input /home/rkrajnc/Dropbox/work/electronics/fpga/minimig-de1/sim/minimig/nc/run/temp.sv
#  or simvision -input /home/rkrajnc/Dropbox/work/electronics/fpga/minimig-de1/sim/minimig/nc/run/temp.sv database1 database2 ...
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
	file /home/rkrajnc/Dropbox/work/electronics/fpga/minimig-de1/sim/minimig/nc/out/wav/wav.trn
}

#
# cursors
#
set time 126632848000fs
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
if {[catch {window new WatchList -name "Design Browser 1" -geometry 862x716+34+64}] != ""} {
    window geometry "Design Browser 1" 862x716+34+64
}
window target "Design Browser 1" on
browser using {Design Browser 1}
browser set \
    -scope soc_tb.soc_top.minimig.USERIO1.osd1
browser yview see soc_tb.soc_top.minimig.USERIO1.osd1
browser timecontrol set -lock 0

#
# Waveform windows
#
if {[catch {window new WaveWindow -name "Waveform 1" -geometry 1280x971+1920+22}] != ""} {
    window geometry "Waveform 1" 1280x971+1920+22
}
window target "Waveform 1" on
waveform using {Waveform 1}
waveform sidebar visibility partial
waveform set \
    -primarycursor TimeA \
    -signalnames name \
    -signalwidth 175 \
    -units ns \
    -valuewidth 86
cursor set -using TimeA -time 126,632,848,000fs
waveform baseline set -time 107,949,032,000fs

set id [waveform add -signals [list soc_tb.soc_top.tg68_as \
	{soc_tb.soc_top.tg68_adr[31:0]} \
	soc_tb.soc_top.tg68_rw \
	soc_tb.soc_top.tg68_uds \
	soc_tb.soc_top.tg68_lds \
	{soc_tb.soc_top.tg68_dat_in[15:0]} \
	{soc_tb.soc_top.tg68_dat_out[15:0]} \
	soc_tb.soc_top.tg68_dtack \
	soc_tb.soc_top.minimig.CPU1._as \
	soc_tb.soc_top.minimig.CPU1._as28m \
	soc_tb.soc_top.minimig.CPU1._dtack \
	soc_tb.soc_top.minimig.CPU1._lds \
	soc_tb.soc_top.minimig.CPU1._ta \
	soc_tb.soc_top.minimig.CPU1._ta_n \
	soc_tb.soc_top.minimig.CPU1._uds \
	{soc_tb.soc_top.minimig.CPU1.address[23:1]} \
	{soc_tb.soc_top.minimig.CPU1.address_out[23:1]} \
	soc_tb.soc_top.minimig.CPU1.blk \
	soc_tb.soc_top.minimig.CPU1.bls \
	soc_tb.soc_top.minimig.CPU1.c1 \
	soc_tb.soc_top.minimig.CPU1.c3 \
	soc_tb.soc_top.minimig.CPU1.cck \
	soc_tb.soc_top.minimig.CPU1.clk \
	soc_tb.soc_top.minimig.CPU1.clk28m \
	soc_tb.soc_top.minimig.CPU1.cpu_clk \
	soc_tb.soc_top.minimig.CPU1.cpu_speed \
	{soc_tb.soc_top.minimig.CPU1.cpudatain[15:0]} \
	{soc_tb.soc_top.minimig.CPU1.data[15:0]} \
	{soc_tb.soc_top.minimig.CPU1.data_in[15:0]} \
	{soc_tb.soc_top.minimig.CPU1.data_out[15:0]} \
	soc_tb.soc_top.minimig.CPU1.dbr \
	soc_tb.soc_top.minimig.CPU1.dbs \
	soc_tb.soc_top.minimig.CPU1.doe \
	{soc_tb.soc_top.minimig.CPU1.eclk[9:0]} \
	soc_tb.soc_top.minimig.CPU1.enable \
	soc_tb.soc_top.minimig.CPU1.hwr \
	soc_tb.soc_top.minimig.CPU1.l_as \
	soc_tb.soc_top.minimig.CPU1.l_as28m \
	soc_tb.soc_top.minimig.CPU1.l_dtack \
	soc_tb.soc_top.minimig.CPU1.l_lds \
	soc_tb.soc_top.minimig.CPU1.l_uds \
	{soc_tb.soc_top.minimig.CPU1.ldata_in[15:0]} \
	soc_tb.soc_top.minimig.CPU1.lr_w \
	soc_tb.soc_top.minimig.CPU1.lvpa \
	soc_tb.soc_top.minimig.CPU1.lwr \
	{soc_tb.soc_top.minimig.CPU1.memory_config[3:0]} \
	soc_tb.soc_top.minimig.CPU1.nrdy \
	soc_tb.soc_top.minimig.CPU1.r_w \
	soc_tb.soc_top.minimig.CPU1.rd \
	soc_tb.soc_top.minimig.CPU1.turbo \
	soc_tb.soc_top.minimig.CPU1.turbo_cpu \
	soc_tb.soc_top.minimig.CPU1.vma \
	soc_tb.soc_top.minimig.CPU1.vpa \
	soc_tb.soc_top.minimig.CPU1.xbs \
	{soc_tb.soc_top.amiga_clk.eclk[9:0]} \
	soc_tb.soc_top.amiga_clk.c1 \
	soc_tb.soc_top.amiga_clk.c1_r \
	soc_tb.soc_top.amiga_clk.c3 \
	soc_tb.soc_top.amiga_clk.c3_r \
	soc_tb.soc_top.amiga_clk.cck \
	{soc_tb.soc_top.amiga_clk.clk7_cnt[1:0]} \
	soc_tb.soc_top.amiga_clk.clk7_en \
	soc_tb.soc_top.amiga_clk.clk7_en_reg \
	soc_tb.soc_top.amiga_clk.clk_7 \
	soc_tb.soc_top.amiga_clk.clk_28 \
	soc_tb.soc_top.amiga_clk.clk_28_r \
	soc_tb.soc_top.amiga_clk.clk_114 \
	soc_tb.soc_top.amiga_clk.clk_114_r \
	soc_tb.soc_top.amiga_clk.clk_in \
	soc_tb.soc_top.amiga_clk.clk_sdram \
	soc_tb.soc_top.amiga_clk.clk_sdram_r \
	{soc_tb.soc_top.amiga_clk.e_cnt[3:0]} \
	{soc_tb.soc_top.amiga_clk.eclk[9:0]} \
	soc_tb.soc_top.amiga_clk.locked \
	soc_tb.soc_top.amiga_clk.pll_locked_r \
	soc_tb.soc_top.amiga_clk.rst \
	soc_tb.soc_top.ctrl_top.ctrl_regs.clk \
	soc_tb.soc_top.ctrl_top.ctrl_regs.rst \
	soc_tb.soc_top.ctrl_top.ctrl_regs.cs \
	{soc_tb.soc_top.ctrl_top.ctrl_regs.adr[21:0]} \
	{soc_tb.soc_top.ctrl_top.ctrl_regs.sel[3:0]} \
	soc_tb.soc_top.ctrl_top.ctrl_regs.we \
	{soc_tb.soc_top.ctrl_top.ctrl_regs.dat_w[31:0]} \
	{soc_tb.soc_top.ctrl_top.ctrl_regs.dat_r[31:0]} \
	soc_tb.soc_top.ctrl_top.ctrl_regs.ack \
	soc_tb.soc_top.ctrl_top.ctrl_regs.spi_clk \
	soc_tb.soc_top.ctrl_top.ctrl_regs.spi_di \
	soc_tb.soc_top.ctrl_top.ctrl_regs.spi_do \
	{soc_tb.soc_top.ctrl_top.ctrl_regs.spi_cs_n[3:0]} \
	{soc_tb.soc_top.minimig.USERIO1.osd1.mem_cnt[15:0]} \
	{soc_tb.soc_top.minimig.USERIO1.osd1.mem_page[15:0]} \
	soc_tb.soc_top.minimig.USERIO1.osd1.spi_mem_write_sel \
	{soc_tb.soc_top.minimig.USERIO1.osd1.wrdat[7:0]} \
	soc_tb.soc_top.minimig.USERIO1.osd1.sdo \
	soc_tb.soc_top.minimig.USERIO1.osd1.sdi \
	soc_tb.soc_top.minimig.USERIO1.osd1.sck \
	soc_tb.soc_top.minimig.USERIO1.osd1._scs \
	soc_tb.soc_top.minimig.USERIO1.osd1.cmd \
	{soc_tb.soc_top.minimig.USERIO1.osd1.cmd_dat[5:0]} \
	soc_tb.soc_top.ctrl_top.rst \
	soc_tb.soc_top.minimig.RAM1._bhe \
	soc_tb.soc_top.minimig.RAM1._ble \
	{soc_tb.soc_top.minimig.RAM1._ce[3:0]} \
	soc_tb.soc_top.minimig.RAM1._oe \
	soc_tb.soc_top.minimig.RAM1._we \
	soc_tb.soc_top.sdram.chipL \
	soc_tb.soc_top.sdram.chipU \
	{soc_tb.soc_top.sdram.chipWR[15:0]} \
	{soc_tb.soc_top.sdram.chipRD[15:0]} \
	soc_tb.soc_top.minimig.USERIO1.osd1.spi_invalidate \
	{soc_tb.soc_top.sdram.cpuAddr[24:1]} \
	soc_tb.soc_top.sdram.chip_dma \
	soc_tb.soc_top.sdram.chipRW \
	{soc_tb.soc_top.minimig.RAM1.ramdata_in[15:0]} \
	{soc_tb.soc_top.minimig.RAM1.data_out[15:0]} \
	{soc_tb.soc_top.minimig.RAM1.data_in[15:0]} \
	{soc_tb.soc_top.minimig.RAM1.data[15:0]} \
	soc_tb.soc_top.tg68k:data_read \
	{soc_tb.soc_top.minimig.USERIO1.osd1.mem_adr[31:0]} \
	soc_tb.soc_top.minimig.USERIO1.osd1.mem_toggle \
	soc_tb.soc_top.minimig.USERIO1.osd1.mem_as ]]

waveform xview limits 63006.312ns 191006.312ns
