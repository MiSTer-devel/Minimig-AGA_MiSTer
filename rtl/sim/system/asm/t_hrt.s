; HRTmon (cart.v without the Action Replay, unchanged by it) on the real
; Minimig: stealth until the freeze key, then the NMI vector served at
; $A1000C, its custom register mirror at $A9F000.
;
;   rtl/sim/system/asm/build.sh t_hrt hrt_stub
;   rtl/sim/system/obj_dir/Vtb_top --rom rtl/sim/system/asm/build/t_hrt.rom \
;       --hrt rtl/sim/system/asm/build/hrt_stub.bin --cpu 0 --ms 300 --quiet
;
;   1    the cartridge does not answer before a freeze ($A1000C)
;   2    the freeze key entered it once
;   3    the mirror's COLOR00 as last written
;   4    the stacked PC within the wait loop
;   10   the NMI vector came from chip RAM, not the cartridge
;   255  an unexpected exception

	include "hw.i"

	ROMHEADER start

start:
	lea	$2000.w,sp
	move.b	#3,CIAA_DDRA
	move.b	#2,CIAA_PRA             ; OVL off: chip RAM at $000000
	lea	$0.w,a1
	move.w	#255,d0
.vec:	move.l	#unexpected,(a1)+
	dbra	d0,.vec
	move.l	#chip_nmi,$7C.w
	clr.w	$1F00.w
	move.l	$A1000C,d0
	TCHECKNE d0,$52790000,1         ; hidden: not the stub's addq.w #1,abs.w
	move.w	#$0ABC,CUSTOM+$180      ; COLOR00
	TMARK	4
	move.l	#200000,d1
wait:	tst.w	$1F00.w
	bne.s	entered
	subq.l	#1,d1
	bne.s	wait
	TFAIL	2
entered:
	moveq	#0,d0
	move.w	$1F00.w,d0
	TCHECK	d0,1,2
	move.w	$1F02.w,d0
	TCHECK	d0,$0ABC,3
	move.l	$1F04.w,d0
	cmp.l	#wait,d0
	bcs.s	.bad
	cmp.l	#entered,d0
	bls.s	.ok
.bad:	PUTHEX	d0
	TFAIL	4
.ok:	TPASS	0

chip_nmi:
	TFAIL	10
unexpected:
	TFAIL	255
