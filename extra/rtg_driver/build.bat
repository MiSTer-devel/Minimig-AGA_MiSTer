@echo off
if exist MiSTer.card.o del MiSTer.card.o
vasmm68k_mot -quiet -Iinclude -Fhunk -phxass -opt-fconst -nowarn=62 MiSTer.card.asm
vc MiSTer.card.o -nostdlib -o MiSTer.card
echo Done.

rem pause 2 seconds
ping 127.0.0.1 -n 2 >nul
