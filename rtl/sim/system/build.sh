#!/bin/sh
# The full-system simulation of Minimig (Verilator): emu (Minimig.sv) with
# its real RTL -- the TG68K converted from VHDL by GHDL -- and models of the
# SDRAM chip and the DDR3 port.  OBJ=<dir> picks the object directory
# (default obj_dir).
set -e
cd "$(dirname "$0")"
R=$(cd ../../.. && pwd)
mkdir -p gen
T=$R/rtl/tg68k
if [ ! -f gen/tg68k.v ] || [ -n "$(find $T -name '*.vhd' -newer gen/tg68k.v)" ]; then
	# cpu_wrapper's generics; the module takes them as parameters again
	ghdl --synth --std=08 -fsynopsys --latches --out=verilog \
		-gsr_read=2 -gvbr_stackframe=2 -gextaddr_mode=2 -gmul_mode=2 -gdiv_mode=2 -gbitfield=2 \
		$T/TG68K_Pack.vhd $T/TG68K_ALU.vhd $T/TG68K_MMU030.vhd $T/TG68KdotC_Kernel.vhd \
		-e TG68KdotC_Kernel > gen/tg68k.tmp 2> gen/ghdl.log
	# VHDL names are case-insensitive: the kernel's ports as cpu_wrapper
	# names them (lower case), and its generics as parameters
	python3 - <<'PY'
import re
s = open('gen/tg68k.tmp').read()
i = s.index('module TG68KdotC_Kernel')
j = s.index('endmodule', i)
m = s[i:j]
hdr = m[:m.index(');')]
for name in set(re.findall(r'(?:input|output|inout)\s+(?:\[[^\]]*\]\s*)?(\w+)', hdr)):
	if name != name.lower():
		m = re.sub(r'\b' + name + r'\b', name.lower(), m)
m = m.replace('module TG68KdotC_Kernel', 'module TG68KdotC_Kernel\n  #(parameter sr_read = 2, vbr_stackframe = 2, extaddr_mode = 2, mul_mode = 2, div_mode = 2, bitfield = 2)', 1)
open('gen/tg68k.v', 'w').write(s[:i] + m + s[j:])
PY
	rm gen/tg68k.tmp
fi
SRC=$(python3 - "$R" <<'PY'
import os, re, sys
R = sys.argv[1]
out = []
def qip(path):
	d = os.path.dirname(path)
	for l in open(path):
		m = re.search(r'-name (\w+) (?:\[file join \$::quartus\(qip_path\) )?"?([^"\]\s]+)', l)
		if not m: continue
		kind, f = m.groups()
		p = os.path.normpath(os.path.join(d if 'qip_path' in l else R, f))
		if kind == 'QIP_FILE': qip(p)
		elif kind in ('VERILOG_FILE', 'SYSTEMVERILOG_FILE') and os.path.exists(p): out.append(p)
qip(os.path.join(R, 'files.qip'))
print(' '.join(out))
PY
)
echo '`define BUILD_DATE "sim"' > gen/build_id.v
SYS="$R/sys/hps_io.sv $R/sys/video_mixer.sv $R/sys/scandoubler.v $R/sys/hq2x.sv $R/sys/gamma_corr.sv
 $R/sys/video_freak.sv $R/sys/math.sv $R/sys/mt32pi.sv $R/sys/iir_filter.v"
verilator --cc --exe --build --no-timing -j 24 -O3 --x-assign fast --x-initial fast \
	-Wno-fatal -Wno-WIDTH -Wno-CASEINCOMPLETE -Wno-PINMISSING -Wno-TIMESCALEMOD -Wno-MULTIDRIVEN \
	-Wno-UNOPTFLAT -Wno-BLKANDNBLK -Wno-LATCH -Wno-COMBDLY -Wno-IMPLICIT -Wno-PINCONNECTEMPTY -Wno-PROCASSWIRE \
	-DMISTER_FB=1 -DMISTER_FB_PALETTE=1 \
	--top-module tb_top -Mdir ${OBJ:-obj_dir} \
	-CFLAGS "-O2 -march=native" \
	-Igen -I$R -I$R/rtl -I$R/rtl/tg68k -I$R/rtl/fx68k -I$R/sys \
	gen/tg68k.v sim_lib/dpram.sv sim_lib/altsyncram.v sim_lib/pll_sim.sv $SRC $SYS \
	sdram_model.sv ddr3_model.sv tb_top.sv sim_main.cpp "$@"
# fx68k reads its microcode from the working directory
ln -sf $R/rtl/fx68k/microrom.mem $R/rtl/fx68k/nanorom.mem .
echo "built ${OBJ:-obj_dir}/Vtb_top"
