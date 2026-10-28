; Test programs for Minimig's full-system simulation (rtl/sim/system): they
; run from the Kickstart ROM's place on the real machine and report through
; the simulation's mailbox at $00F00000 (nothing on Minimig decodes it; the
; bench watches the CPU's chip bus):
;   +0  result: $600D0000+n pass, $BAD00000+n fail (ends the run)
;   +4  a character
;   +8  a long word, printed in hex
;   +12 a time mark n (the bench prints the simulated time)

MBOX     equ $00F00000
CIAA_PRA equ $00BFE001
CIAA_DDRA equ $00BFE201
CUSTOM   equ $00DFF000

; the ROM header the 68040 boots from: SSP and PC (read through OVL)
ROMHEADER macro
	org	$F80000
	dc.l	$00002000           ; supervisor stack (chip RAM, valid once OVL is off)
	dc.l	\1                  ; reset PC
	endm

PUTC	macro
	move.l	\1,MBOX+4
	endm

PUTHEX	macro
	move.l	\1,MBOX+8
	endm

TMARK	macro
	move.l	#\1,MBOX+12
	endm

TPASS	macro
	move.l	#$600D0000+\1,MBOX
.\@:	bra.s	.\@
	endm

TFAIL	macro
	move.l	#$BAD00000+\1,MBOX
.\@:	bra.s	.\@
	endm

; print the zero-terminated string at \1 (uses a0, d0)
TPRINT	macro
	lea	\1,a0
	bsr	print_str
	endm

; check: if \1 (a data register) != \2 (immediate), fail with code \3
TCHECK	macro
	cmp.l	#\2,\1
	beq.s	.\@
	PUTHEX	\1
	TFAIL	\3
.\@:
	endm

; check: if \1 (a data register) == \2 (immediate), fail with code \3
TCHECKNE macro
	cmp.l	#\2,\1
	bne.s	.\@
	PUTHEX	\1
	TFAIL	\3
.\@:
	endm
