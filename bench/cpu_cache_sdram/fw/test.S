; defines
STACK	equ $100

;init
init_sp:
	dc.l STACK
init_pc:
	dc.l START

;program
	ORG	$10
START:
	move.l #$200000,A0
	move.w #$dead,(A0)+
	move.w #$beef,(A0)+
	move.w #$0123,(A0)+
	move.w #$4567,(A0)+

LOOP:
	jmp LOOP

	END	START
