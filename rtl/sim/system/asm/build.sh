#!/bin/sh
# Assemble rtl/sim/system/asm/<name>.s for the 68000 into build/<name>.rom
# (512 KB, the Kickstart ROM's image at $F80000) and build/<name>.bin.
set -e
cd "$(dirname "$0")"
VASM=${VASM:-/opt/amiga-cc/vbcc/bin/vasmm68k_mot}
mkdir -p build
for t in "$@"; do
	$VASM -quiet -Fbin -m68000 -no-opt -L build/$t.lst -o build/$t.bin $t.s
	python3 -c "
b = open('build/$t.bin','rb').read()
assert len(b) <= 0x80000, 'image too big'
open('build/$t.rom','wb').write(b + b'\xff' * (0x80000 - len(b)))
"
	echo "build/$t.rom"
done
