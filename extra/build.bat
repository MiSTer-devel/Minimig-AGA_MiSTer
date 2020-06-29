@echo off

rmdir /s /q DEVS 2>nul
rmdir /s /q L    2>nul
mkdir DEVS
mkdir L

echo MiSTerFileSystem
vc MiSTerFileSystem.c -S -o MiSTerFileSystem.asm
python comment_out_sections.py
vc bcpl_start.asm MiSTerFileSystem.asm bcpl_end.asm -nostdlib -o l\MiSTerFileSystem
python patch_bin.py
del MiSTerFileSystem.asm
copy MountList devs\MountList >nul

echo dummy.device
vc dummy.c -O3 -nostdlib -o devs\dummy.device

echo MiSTer_share.lha
del MiSTer_share.lha
lhant -a MiSTer_share.lha L\MiSTerFileSystem DEVS\dummy.device DEVS\MountList

rmdir /s /q DEVS 2>nul
rmdir /s /q L    2>nul

pause
