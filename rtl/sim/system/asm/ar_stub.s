; ar_stub: a stand-in for AR5.ROM (the Action Replay, DeMoN v2 layout), loaded
; where Main uploads it ($A80000: ROM to $ABFFFF, RAM from $AC0000; sim_main
; --ar).  Its NMI vector at +$7C enters here at every freeze; each entry n
; records, for t_ar to check, in the 16 bytes at $1E00 + 16n of chip RAM:
;   +0  the byte at +1 of the control register (the cause in D1-D0)
;   +1  the byte at +3 (the cause again)
;   +2  the snapshot's DMACON ($ACF096)
;   +4  the snapshot's COLOR00 ($ACF180)
;   +6  the snapshot's COLOR00 after writing $0456 to it (RAM)
;   +8  a word of the cartridge RAM after writing $1234 to it
;   +10 the ROM word at +$200 after writing $FFFF to it (ignored: $A5A5)
;   +12 the stacked PC
; then sets the mode modes[n] through the control register and returns.
; The entry count is in the cartridge RAM ($AC0100, 0 in this image).

	org	$A80000
ctl:	dc.l	$20182018               ; the control register's long word (AR5: FreezeState)
	dcb.b	$7C-(*-ctl),0
	dc.l	entry                   ; the NMI vector

entry:	movem.l	d0-d2/a0-a1,-(sp)
	move.l	$AC0100,d2              ; n
	addq.l	#1,$AC0100
	move.l	d2,d1
	lsl.l	#4,d1
	lea	$1E00.w,a0
	add.l	d1,a0
	move.b	$A80001,(a0)
	move.b	$A80003,1(a0)
	move.w	$ACF096,2(a0)
	move.w	$ACF180,4(a0)
	move.w	#$0456,$ACF180
	move.w	$ACF180,6(a0)
	move.w	#$1234,$AC0200
	move.w	$AC0200,8(a0)
	move.w	#$FFFF,$A80200
	move.w	$A80200,10(a0)
	move.l	22(sp),12(a0)           ; the stacked PC (format 0: SR, PC, vector)
	lea	modes(pc),a1
	add.l	d2,d2
	move.w	(a1,d2.l),$A80000       ; the mode: the byte at +1
	movem.l	(sp)+,d0-d2/a0-a1
	rte

modes:	dc.w	$0002,$0001,$0000,$0000,$0000

	dcb.b	$200-(*-ctl),0
	dc.w	$A5A5                   ; +$200
	dcb.b	$40000-(*-ctl),$FF      ; the rest of the ROM
	dcb.b	$200,0                  ; the RAM: the entry count at $AC0100
