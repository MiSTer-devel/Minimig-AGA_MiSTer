; The Action Replay cartridge (AR5, DeMoN v2 layout at $A80000) on the real
; Minimig: its freezes, control register, register snapshot and stealth;
; ported from Maximig's test.  The same program runs on the 68000 (fx68k)
; and the 68020 (TG68K).
;
;   rtl/sim/system/asm/build.sh t_ar ar_stub
;   rtl/sim/system/obj_dir/Vtb_top --rom rtl/sim/system/asm/build/t_ar.rom \
;       --ar rtl/sim/system/asm/build/ar_stub.bin --cpu 0 --ms 300 --quiet
;
; Hidden, nothing answers at $A80000 (on Minimig that reads 0): the checks
; are that the ROM's control word ($20182018) is not there.
;
; ar_stub records each entry at $1E00 + 16n (see there) and sets the mode
; for the next: 2 (a CIA-A PRA read freezes), 1 (a CIA-B PRB write), 0.
;   1    the cartridge answers before a freeze
;   2-9  entry 0, the reset freeze: the first word written to chip RAM after
;        the system reset (not a byte); cause 3; the snapshot holds DMACON
;        and COLOR00 as written before it and is RAM; the cartridge RAM is
;        RAM, the ROM ignores writes
;   10   the NMI vector came from chip RAM, not the cartridge
;   11   the cartridge still answers after its exit
;   20-22  entry 1: the $BFE001 read (mode 2), cause 1
;   30-32  entry 2: mode 1: a PRA read does not freeze, a $BFD100 write does,
;          cause 2
;   40     mode 0: neither freezes
;   50-54  entry 3: the freeze key, cause 0, the snapshot's COLOR00
;   255    an unexpected exception

	include "hw.i"

REC	equ	$1E00
AFTER	equ	32                      ; bytes of NOPs a freeze may take to be taken

	ROMHEADER start

start:
	; (the stack as Kickstart sets it: on the 68020 the reset SSP is read with
	; a 32-bit chip cycle, whose second word comes from chip RAM under OVL)
	lea	$2000.w,sp
	move.b	#3,CIAA_DDRA
	move.b	#2,CIAA_PRA             ; OVL off: chip RAM at $000000
	move.l	$A80000,d0
	TCHECKNE d0,$20182018,1         ; hidden: not the cartridge
	move.w	#$7FFF,CUSTOM+$096      ; DMACON
	move.w	#$0123,CUSTOM+$180      ; COLOR00
	move.b	d0,$300.w               ; a byte: no freeze
	rept	AFTER/2
	nop
	endr
	move.w	#$5555,$302.w           ; the first word: the reset freeze
after1:
	rept	AFTER/2
	nop
	endr

	; the vector table, from here on
	lea	$0.w,a1
	move.w	#255,d0
.vec:	move.l	#unexpected,(a1)+
	dbra	d0,.vec
	move.l	#chip_nmi,$7C.w

	lea	REC.w,a0
	move.l	12(a0),d0
	bsr	in_after1
	moveq	#3,d0
	and.b	(a0),d0
	TCHECK	d0,3,3
	moveq	#3,d0
	and.b	1(a0),d0
	TCHECK	d0,3,4
	moveq	#0,d0
	move.w	2(a0),d0
	TCHECK	d0,$7FFF,5
	move.w	4(a0),d0
	TCHECK	d0,$0123,6
	move.w	6(a0),d0
	TCHECK	d0,$0456,7
	move.w	8(a0),d0
	TCHECK	d0,$1234,8
	move.w	10(a0),d0
	TCHECK	d0,$A5A5,9
	move.l	$A80000,d0
	TCHECKNE d0,$20182018,11

	; mode 2: a read of CIA-A PRA freezes
	move.b	CIAA_PRA,d0
after2:
	rept	AFTER/2
	nop
	endr
	lea	REC+16.w,a0
	move.l	12(a0),d0
	lea	after2,a1
	bsr	in_after
	TCHECK	d0,1,20
	moveq	#3,d0
	and.b	(a0),d0
	TCHECK	d0,1,21
	moveq	#3,d0
	and.b	1(a0),d0
	TCHECK	d0,1,22

	; mode 1: a PRA read does not freeze, a write of CIA-B PRB does
	move.b	CIAA_PRA,d0
	rept	AFTER/2
	nop
	endr
	move.l	REC+32+12.w,d0
	TCHECK	d0,0,30
	move.b	#$FF,$BFD100
after3:
	rept	AFTER/2
	nop
	endr
	lea	REC+32.w,a0
	move.l	12(a0),d0
	lea	after3,a1
	bsr	in_after
	TCHECK	d0,1,31
	moveq	#3,d0
	and.b	(a0),d0
	TCHECK	d0,2,32

	; mode 0: neither
	move.b	CIAA_PRA,d0
	move.b	#$FF,$BFD100
	rept	AFTER/2
	nop
	endr
	move.l	REC+48+12.w,d0
	TCHECK	d0,0,40

	; the freeze key
	move.w	#$0789,CUSTOM+$180
	TMARK	4
	move.l	#200000,d1
.wait:	tst.l	REC+48+12.w
	bne.s	.entered
	subq.l	#1,d1
	bne.s	.wait
	TFAIL	50
.entered:
	lea	REC+48.w,a0
	moveq	#3,d0
	and.b	(a0),d0
	TCHECK	d0,0,51
	moveq	#0,d0
	move.w	4(a0),d0
	TCHECK	d0,$0789,52
	move.w	6(a0),d0
	TCHECK	d0,$0456,53
	move.l	$A80000,d0
	TCHECKNE d0,$20182018,54
	TPASS	0

; d0 (a stacked PC) within AFTER bytes from after1: else fail 2
in_after1:
	lea	after1,a1
	bsr	in_after
	TCHECK	d0,1,2
	rts

; d0 = 1 if d0 (a stacked PC) is within AFTER bytes from a1, else 0
in_after:
	sub.l	a1,d0
	cmp.l	#AFTER,d0
	bhi.s	.no
	moveq	#1,d0
	rts
.no:	PUTHEX	d0
	moveq	#0,d0
	rts

chip_nmi:
	TFAIL	10
unexpected:
	TFAIL	255
