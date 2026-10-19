# Drive sounds

The `.raw` samples (16-bit signed little endian, mono, 44.1 kHz) are by Alastair M. Robinson, from
[MinimigAGA-MiST-TC64](https://github.com/minimig-dev/MinimigAGA-MiST-TC64) `sw/mkdrivesounds`
(GPL v3, commits 4e6cf76a and 0164186c, August 2020): disk insert and eject, motor start, run and stop,
four head steps.

`gen_drivesounds.py` puts them, as recorded, in `releases/drivesounds.bin`, with the layout of his `drivesnd.bin`:
`DRIVESND`, then for every sound its number and its length in bytes (32-bit big endian) and its samples
(16-bit signed big endian), and `0`, `0` at the end. The gains of his `mkdrivesounds.c` are applied by
`rtl/drive_sounds.v`, on the sum of the voices.

`drivesounds.bin` goes in `games/Amiga` on the SD card, where the updater puts it from `releases/`. The Main copies it to DDR3 when the core starts, and
the OSD option Audio & Video > Drive Sounds works only when it has found the file.
