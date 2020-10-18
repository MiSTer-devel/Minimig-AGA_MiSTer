if exist MiSTer.card.o del MiSTer.card.o
vasmm68k_mot -Iinclude -Fhunk -phxass -opt-fconst -nowarn=62 MiSTer.card.asm
vc MiSTer.card.o -nostdlib -o MiSTer.card
pause
