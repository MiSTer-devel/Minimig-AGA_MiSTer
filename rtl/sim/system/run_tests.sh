#!/bin/sh
# The full-system tests (build.sh's simulation of emu):
#   t_ar   the Action Replay (AR5, DeMoN v2 layout): its freezes (the reset,
#          a CIA-A PRA read, a CIA-B PRB write, the freeze key), control
#          register, register snapshot and stealth -- on the 68000 (fx68k)
#          and the 68020 (TG68K)
#   t_hrt  HRTmon: stealth, the freeze key's NMI vector at $A1000C, its
#          custom register mirror at $A9F000
set -e
cd "$(dirname "$0")"
OBJ=${OBJ:-obj_dir}
OBJ=$OBJ ./build.sh > build.log 2>&1 || { tail -30 build.log; exit 1; }
asm/build.sh t_ar ar_stub t_hrt hrt_stub > /dev/null
fail=0
for cpu in 0 3; do
	out=$(timeout 1800 ./$OBJ/Vtb_top --rom asm/build/t_ar.rom --ar asm/build/ar_stub.bin --cpu $cpu --ms 300 --quiet 2>&1) || true
	if echo "$out" | grep -q '^\[mailbox\].*result 600D'; then echo "t_ar (cpu $cpu) PASS"; else echo "$out"; echo "t_ar (cpu $cpu) FAIL"; fail=1; fi
	out=$(timeout 1800 ./$OBJ/Vtb_top --rom asm/build/t_hrt.rom --hrt asm/build/hrt_stub.bin --cpu $cpu --ms 300 --quiet 2>&1) || true
	if echo "$out" | grep -q '^\[mailbox\].*result 600D'; then echo "t_hrt (cpu $cpu) PASS"; else echo "$out"; echo "t_hrt (cpu $cpu) FAIL"; fail=1; fi
done
[ $fail -eq 0 ] && echo "ALL PASSED" || echo "FAILURES"
exit $fail
