; hrt_stub: a stand-in for HRTMON.ROM, loaded where Main uploads it ($A10000;
; sim_main --hrt), its entry at $A1000C (the NMI vector cart.v serves).  Each
; entry counts in chip RAM at $1F00 and records, for t_hrt to check:
;   $1F02  COLOR00 from HRTmon's custom register mirror ($A9F180)
;   $1F04  the stacked PC
; and returns.

	org	$A10000
	dc.l	0,0,0                   ; (HRTmon's header: the entry follows)
entry:	addq.w	#1,$1F00.w
	move.w	$A9F180,$1F02.w
	move.l	2(sp),$1F04.w
	rte
