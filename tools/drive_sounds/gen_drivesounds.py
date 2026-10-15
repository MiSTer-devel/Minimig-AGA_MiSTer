#!/usr/bin/env python3
# gen_drivesounds.py [raw dir] [out] : drivesounds.bin, the drive sounds the Main copies to DDR3 for
# rtl/drive_sounds.v.
#
# Samples: Alastair M. Robinson, MinimigAGA-MiST-TC64 (GPL v3), sw/mkdrivesounds/*.raw, 16-bit signed little
# endian mono at 44.1 kHz. The file has the layout of his drivesnd.bin ("DRIVESND", then for every sound its
# number and its length in bytes, big endian 32-bit, and its samples, 16-bit signed big endian; 0 and 0 at the
# end), but the samples are kept as recorded: the gains of his mkdrivesounds.c are applied by the core.
import os, sys, struct

HERE = os.path.dirname(os.path.abspath(__file__))
src = sys.argv[1] if len(sys.argv) > 1 else HERE
out = sys.argv[2] if len(sys.argv) > 2 else os.path.join(HERE, 'drivesounds.bin')

SOUNDS = ['DiskInsert', 'DiskEject', 'MotorStart', 'MotorLoop', 'MotorStop', 'Step1', 'Step2', 'Step3', 'Step4']

b = bytearray(b'DRIVESND')
for n, name in enumerate(SOUNDS):
    raw = open(os.path.join(src, name + '.raw'), 'rb').read()
    raw = raw[:len(raw) // 2 * 2]
    s = struct.unpack('<%dh' % (len(raw) // 2), raw)
    b += struct.pack('>II', n, len(raw)) + struct.pack('>%dh' % len(s), *s)
    print('%d %-10s %6d samples, %4.0f ms' % (n, name, len(s), len(s) / 44.1))
b += struct.pack('>II', 0, 0)
open(out, 'wb').write(b)
print('%s: %d bytes' % (out, len(b)))
