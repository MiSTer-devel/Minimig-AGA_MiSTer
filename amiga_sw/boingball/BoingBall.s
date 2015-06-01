CUSTOM_BASE=$dff000
DMACONR=$dff002
VPOSR=$dff004
VHPOSR=$dff006
INTENAR=$dff01c
COPCON=$dff02e
BLTCON0=$dff040
BLTCON1=$dff042
BLTAFWM=$dff044
BLTALWM=$dff046
BLTAPTH=$dff050
BLTDPTH=$dff054
BLTSIZE=$dff058
BLTAMOD=$dff064
BLTDMOD=$dff066
COP1LCH=$dff080
COP2LCH=$dff084
COPJMP1=$dff088
DMACON=$dff096
INTENA=$dff09a
INTREQ=$dff09c
COLOR00=$dff180
COLOR01=$dff182
COLOR02=$dff184
COLOR03=$dff186

w	=320
h	=256
bplsize	=w*h/8


	;ORG $20000
	;LOAD $20000
	;JUMPPTR init
	SECTION Prog,CODE_C	; chip memory
  code_c
init:
	move.l 4.w,a6		; execbase
	clr.l d0
	move.l #gfxname,a1	; library name
	jsr -408(a6)		; OldOpenLibrary()
	move.l d0,a1		; move return value to a1
	move.l 38(a1),d4	; fetch current copper pointer
	jsr -414(a6)		; CloseLibrary()

	move.w INTENAR,d5	; save interrupts
	move.w DMACONR,d3	; save dmaconr

	move.w #$138,d0
	bsr WaitRaster

	move.w #$7fff,INTENA	; disable all bits in INTENA
	move.w #$7fff,INTREQ	; disable all bits in INTREQ
	move.w #$7fff,DMACON	; disable all bits in DMACON
	move.w #$87c0,DMACON	; enable important bits
	move.w #2,COPCON	; COPCON, enable danger mode
	move.l #Copper1,COP1LCH	; set copper1 pointer
	move.l #Copper2,COP2LCH	; set copper2 pointer
	move.w #0,COPJMP1	; start copper

	move.l #-1,BLTAFWM	; blitter setup
	move.w #$09f0,BLTCON0
	move.w #$0000,BLTCON1
	move.w #0,BLTAMOD
	move.w #32,BLTDMOD


mainloop:
Frame1:
	move.w #138,d0
	bsr WaitRaster
	lea bpl1,a1
	lea frame_1_plane0,a2
	lea bpl2,a3
	lea frame_1_plane1,a4
	bsr Ballsetup
	sub.w #1,d6
	move.w #20,d6
.wait:
	move.w #138,d0
	bsr WaitRaster
	dbf d6,.wait

waitmouse:
	btst #6,CIAAPRA		; test left mouse button
	bne mainloop

exit:
	move.w #$7fff,DMACON	; DMA control
	or.w #$8200,d3
	move.w d3,DMACON	; DMACON
	move.l d4,COP1LCH
	or #$c000,d5
	move d5,INTENA		; restore interrupts
	rts

Ballsetup:
bi0:
	move.w #64-1,d0
.rows:
	move.w (a2)+,(a1)+
	move.w (a2)+,(a1)+
	move.w (a2)+,(a1)+
	move.w (a2)+,(a1)+
	add.w #32,a1
	dbf d0,.rows
bi1:
	move.w #64-1,d0
.rows:
	move.w (a4)+,(a3)+
	move.w (a4)+,(a3)+
	move.w (a4)+,(a3)+
	move.w (a4)+,(a3)+
	add.w #32,a3
	dbf d0,.rows
	RTS


WaitRaster:			; wait for rasterline d0.w
	move.l #$1ff00,d2
	lsl.l #8,d0
	and.l d2,d0
	lea $dff004,a0
.wr:	move.l (a0),d1
	and.l d2,d1
	cmp.l d1,d0
	bne.s .wr
	RTS


gfxname:
	dc.b "graphics.library",0


	SECTION Bdata,DATA_C
  data_c

	EVEN
Screen:
bpl1:
	dcb.b bplsize
bpl1E:
bpl2:
	dcb.b bplsize
bpl2E:


	EVEN
Boingball:
	INCLUDE "BoingBall_data.s"



	EVEN
Copper1:
	dc.w $01fc,$0000	; FMODE, slow fetch mode for AGA compatibility
	dc.w $0100,$0200	; clear all bits in BPLCON0, except colorburst
	dc.w $008e,$2c81	; DIWSTRT, screen topleft
	dc.w $0090,$2cc1	; DIWSTOP, scren bottomright
	dc.w $0092,$0038	; DDFSTRT, DMA fetch start
	dc.w $0094,$00d0	; DDFSTOP, DMA fetch stop
	dc.w $0108,$0000	; BPL1MOD, modulo for odd planes
	dc.w $010a,$0000	; BPL2MOD, modulo for even planes
	dc.w $0102,$0000	; BPLCON1, bitplane control scroll value

CopCol:				; setup colors
	dc.w $0180,$0000
	dc.w $0182,$0aaa
	dc.w $0184,$0a00
	dc.w $0186,$0000

CopBplP:			; setup bitplane pointers
	dc.w $00e0,(bpl1>>16)&$ffff
	dc.w $00e2,(bpl1)&$ffff
	dc.w $00e4,(bpl2>>16)&$ffff
	dc.w $00e6,(bpl2)&$ffff

	dc.w $0100,$2200	; BPLCON0, enable bitplane dma

	dc.w $008a,$0000	; COPJMP2, restart at location 2

	dc.w $ffff,$fffe	; wait, end copper list


	EVEN
Copper2:
c2f1:
	; setup blitter
	dc.w $0050,(frame_1_plane0>>16)&$ffff
	dc.w $0052,(frame_1_plane0)&$ffff
	dc.w $0054,((bpl1+64)>>16)&$ffff
	dc.w $0056,((bpl1+64))&$ffff
	dc.w $0058,(64<<6+4)
	dc.w $0107,$7ffe	; wait blitter end
	dc.w $0050,(frame_1_plane1>>16)&$ffff
	dc.w $0052,(frame_1_plane1)&$ffff
	dc.w $0054,((bpl2+64)>>16)&$ffff
	dc.w $0056,((bpl2+64))&$ffff
	dc.w $0058,(64<<6+4)
	dc.w $0084,(c2f11>>16)&$ffff
	dc.w $0086,(c2f11)&$ffff
	dc.w $ffff,$fffe	; wait end copper list
c2f11:
	dc.w $0084,(c2f12>>16)&$ffff
	dc.w $0086,(c2f12)&$ffff
	dc.w $ffff,$fffe	; wait end copper list
c2f12:
	dc.w $0084,(c2f13>>16)&$ffff
	dc.w $0086,(c2f13)&$ffff
	dc.w $ffff,$fffe	; wait end copper list
c2f13:
	dc.w $0084,(c2f14>>16)&$ffff
	dc.w $0086,(c2f14)&$ffff
	dc.w $ffff,$fffe	; wait end copper list
c2f14:
	dc.w $0084,(c2f15>>16)&$ffff
	dc.w $0086,(c2f15)&$ffff
	dc.w $ffff,$fffe	; wait end copper list
c2f15:
	dc.w $0084,(c2f2>>16)&$ffff
	dc.w $0086,(c2f2)&$ffff
	dc.w $ffff,$fffe	; wait end copper list

c2f2:
	; setup blitter
	dc.w $0050,(frame_2_plane0>>16)&$ffff
	dc.w $0052,(frame_2_plane0)&$ffff
	dc.w $0054,((bpl1+64)>>16)&$ffff
	dc.w $0056,((bpl1+64))&$ffff
	dc.w $0058,(64<<6+4)
	dc.w $0107,$7ffe	; wait blitter end
	dc.w $0050,(frame_2_plane1>>16)&$ffff
	dc.w $0052,(frame_2_plane1)&$ffff
	dc.w $0054,((bpl2+64)>>16)&$ffff
	dc.w $0056,((bpl2+64))&$ffff
	dc.w $0058,(64<<6+4)
	dc.w $0084,(c2f21>>16)&$ffff
	dc.w $0086,(c2f21)&$ffff
	dc.w $ffff,$fffe	; wait end copper list
c2f21:
	dc.w $0084,(c2f22>>16)&$ffff
	dc.w $0086,(c2f22)&$ffff
	dc.w $ffff,$fffe	; wait end copper list
c2f22:
	dc.w $0084,(c2f23>>16)&$ffff
	dc.w $0086,(c2f23)&$ffff
	dc.w $ffff,$fffe	; wait end copper list
c2f23:
	dc.w $0084,(c2f24>>16)&$ffff
	dc.w $0086,(c2f24)&$ffff
	dc.w $ffff,$fffe	; wait end copper list
c2f24:
	dc.w $0084,(c2f25>>16)&$ffff
	dc.w $0086,(c2f25)&$ffff
	dc.w $ffff,$fffe	; wait end copper list
c2f25:
	dc.w $0084,(c2f3>>16)&$ffff
	dc.w $0086,(c2f3)&$ffff
	dc.w $ffff,$fffe	; wait end copper list

c2f3:
	; setup blitter
	dc.w $0050,(frame_3_plane0>>16)&$ffff
	dc.w $0052,(frame_3_plane0)&$ffff
	dc.w $0054,((bpl1+64)>>16)&$ffff
	dc.w $0056,((bpl1+64))&$ffff
	dc.w $0058,(64<<6+4)
	dc.w $0107,$7ffe	; wait blitter end
	dc.w $0050,(frame_3_plane1>>16)&$ffff
	dc.w $0052,(frame_3_plane1)&$ffff
	dc.w $0054,((bpl2+64)>>16)&$ffff
	dc.w $0056,((bpl2+64))&$ffff
	dc.w $0058,(64<<6+4)
	dc.w $0084,(c2f4>>16)&$ffff
	dc.w $0086,(c2f31)&$ffff
	dc.w $ffff,$fffe	; wait end copper list
c2f31:
	dc.w $0084,(c2f32>>16)&$ffff
	dc.w $0086,(c2f32)&$ffff
	dc.w $ffff,$fffe	; wait end copper list
c2f32:
	dc.w $0084,(c2f33>>16)&$ffff
	dc.w $0086,(c2f33)&$ffff
	dc.w $ffff,$fffe	; wait end copper list
c2f33:
	dc.w $0084,(c2f34>>16)&$ffff
	dc.w $0086,(c2f34)&$ffff
	dc.w $ffff,$fffe	; wait end copper list
c2f34:
	dc.w $0084,(c2f35>>16)&$ffff
	dc.w $0086,(c2f35)&$ffff
	dc.w $ffff,$fffe	; wait end copper list
c2f35:
	dc.w $0084,(c2f4>>16)&$ffff
	dc.w $0086,(c2f4)&$ffff
	dc.w $ffff,$fffe	; wait end copper list

c2f4:
	; setup blitter
	dc.w $0050,(frame_4_plane0>>16)&$ffff
	dc.w $0052,(frame_4_plane0)&$ffff
	dc.w $0054,((bpl1+64)>>16)&$ffff
	dc.w $0056,((bpl1+64))&$ffff
	dc.w $0058,(64<<6+4)
	dc.w $0107,$7ffe	; wait blitter end
	dc.w $0050,(frame_4_plane1>>16)&$ffff
	dc.w $0052,(frame_4_plane1)&$ffff
	dc.w $0054,((bpl2+64)>>16)&$ffff
	dc.w $0056,((bpl2+64))&$ffff
	dc.w $0058,(64<<6+4)
	dc.w $0084,(c2f41>>16)&$ffff
	dc.w $0086,(c2f41)&$ffff
	dc.w $ffff,$fffe	; wait end copper list
c2f41:
	dc.w $0084,(c2f42>>16)&$ffff
	dc.w $0086,(c2f42)&$ffff
	dc.w $ffff,$fffe	; wait end copper list
c2f42:
	dc.w $0084,(c2f43>>16)&$ffff
	dc.w $0086,(c2f43)&$ffff
	dc.w $ffff,$fffe	; wait end copper list
c2f43:
	dc.w $0084,(c2f44>>16)&$ffff
	dc.w $0086,(c2f44)&$ffff
	dc.w $ffff,$fffe	; wait end copper list
c2f44:
	dc.w $0084,(c2f45>>16)&$ffff
	dc.w $0086,(c2f45)&$ffff
	dc.w $ffff,$fffe	; wait end copper list
c2f45:
	dc.w $0084,(c2f5>>16)&$ffff
	dc.w $0086,(c2f5)&$ffff
	dc.w $ffff,$fffe	; wait end copper list

c2f5:
	; setup blitter
	dc.w $0050,(frame_5_plane0>>16)&$ffff
	dc.w $0052,(frame_5_plane0)&$ffff
	dc.w $0054,((bpl1+64)>>16)&$ffff
	dc.w $0056,((bpl1+64))&$ffff
	dc.w $0058,(64<<6+4)
	dc.w $0107,$7ffe	; wait blitter end
	dc.w $0050,(frame_5_plane1>>16)&$ffff
	dc.w $0052,(frame_5_plane1)&$ffff
	dc.w $0054,((bpl2+64)>>16)&$ffff
	dc.w $0056,((bpl2+64))&$ffff
	dc.w $0058,(64<<6+4)
	dc.w $0084,(c2f51>>16)&$ffff
	dc.w $0086,(c2f51)&$ffff
	dc.w $ffff,$fffe	; wait end copper list
c2f51:
	dc.w $0084,(c2f52>>16)&$ffff
	dc.w $0086,(c2f52)&$ffff
	dc.w $ffff,$fffe	; wait end copper list
c2f52:
	dc.w $0084,(c2f53>>16)&$ffff
	dc.w $0086,(c2f53)&$ffff
	dc.w $ffff,$fffe	; wait end copper list
c2f53:
	dc.w $0084,(c2f54>>16)&$ffff
	dc.w $0086,(c2f54)&$ffff
	dc.w $ffff,$fffe	; wait end copper list
c2f54:
	dc.w $0084,(c2f55>>16)&$ffff
	dc.w $0086,(c2f55)&$ffff
	dc.w $ffff,$fffe	; wait end copper list
c2f55:
	dc.w $0084,(c2f6>>16)&$ffff
	dc.w $0086,(c2f6)&$ffff
	dc.w $ffff,$fffe	; wait end copper list

c2f6:
	; setup blitter
	dc.w $0050,(frame_6_plane0>>16)&$ffff
	dc.w $0052,(frame_6_plane0)&$ffff
	dc.w $0054,((bpl1+64)>>16)&$ffff
	dc.w $0056,((bpl1+64))&$ffff
	dc.w $0058,(64<<6+4)
	dc.w $0107,$7ffe	; wait blitter end
	dc.w $0050,(frame_6_plane1>>16)&$ffff
	dc.w $0052,(frame_6_plane1)&$ffff
	dc.w $0054,((bpl2+64)>>16)&$ffff
	dc.w $0056,((bpl2+64))&$ffff
	dc.w $0058,(64<<6+4)
	dc.w $0084,(c2f61>>16)&$ffff
	dc.w $0086,(c2f61)&$ffff
	dc.w $ffff,$fffe	; wait end copper list
c2f61:
	dc.w $0084,(c2f62>>16)&$ffff
	dc.w $0086,(c2f62)&$ffff
	dc.w $ffff,$fffe	; wait end copper list
c2f62:
	dc.w $0084,(c2f63>>16)&$ffff
	dc.w $0086,(c2f63)&$ffff
	dc.w $ffff,$fffe	; wait end copper list
c2f63:
	dc.w $0084,(c2f64>>16)&$ffff
	dc.w $0086,(c2f64)&$ffff
	dc.w $ffff,$fffe	; wait end copper list
c2f64:
	dc.w $0084,(c2f65>>16)&$ffff
	dc.w $0086,(c2f65)&$ffff
	dc.w $ffff,$fffe	; wait end copper list
c2f65:
	dc.w $0084,(c2f7>>16)&$ffff
	dc.w $0086,(c2f7)&$ffff
	dc.w $ffff,$fffe	; wait end copper list

c2f7:
	; setup blitter
	dc.w $0050,(frame_7_plane0>>16)&$ffff
	dc.w $0052,(frame_7_plane0)&$ffff
	dc.w $0054,((bpl1+64)>>16)&$ffff
	dc.w $0056,((bpl1+64))&$ffff
	dc.w $0058,(64<<6+4)
	dc.w $0107,$7ffe	; wait blitter end
	dc.w $0050,(frame_7_plane1>>16)&$ffff
	dc.w $0052,(frame_7_plane1)&$ffff
	dc.w $0054,((bpl2+64)>>16)&$ffff
	dc.w $0056,((bpl2+64))&$ffff
	dc.w $0058,(64<<6+4)
	dc.w $0084,(c2f71>>16)&$ffff
	dc.w $0086,(c2f71)&$ffff
	dc.w $ffff,$fffe	; wait end copper list
c2f71:
	dc.w $0084,(c2f72>>16)&$ffff
	dc.w $0086,(c2f72)&$ffff
	dc.w $ffff,$fffe	; wait end copper list
c2f72:
	dc.w $0084,(c2f73>>16)&$ffff
	dc.w $0086,(c2f73)&$ffff
	dc.w $ffff,$fffe	; wait end copper list
c2f73:
	dc.w $0084,(c2f74>>16)&$ffff
	dc.w $0086,(c2f74)&$ffff
	dc.w $ffff,$fffe	; wait end copper list
c2f74:
	dc.w $0084,(c2f75>>16)&$ffff
	dc.w $0086,(c2f75)&$ffff
	dc.w $ffff,$fffe	; wait end copper list
c2f75:
	dc.w $0084,(c2f8>>16)&$ffff
	dc.w $0086,(c2f8)&$ffff
	dc.w $ffff,$fffe	; wait end copper list

c2f8:
	; setup blitter
	dc.w $0050,(frame_8_plane0>>16)&$ffff
	dc.w $0052,(frame_8_plane0)&$ffff
	dc.w $0054,((bpl1+64)>>16)&$ffff
	dc.w $0056,((bpl1+64))&$ffff
	dc.w $0058,(64<<6+4)
	dc.w $0107,$7ffe	; wait blitter end
	dc.w $0050,(frame_8_plane1>>16)&$ffff
	dc.w $0052,(frame_8_plane1)&$ffff
	dc.w $0054,((bpl2+64)>>16)&$ffff
	dc.w $0056,((bpl2+64))&$ffff
	dc.w $0058,(64<<6+4)
	dc.w $0084,(c2f81>>16)&$ffff
	dc.w $0086,(c2f81)&$ffff
	dc.w $ffff,$fffe	; wait end copper list
c2f81:
	dc.w $0084,(c2f82>>16)&$ffff
	dc.w $0086,(c2f82)&$ffff
	dc.w $ffff,$fffe	; wait end copper list
c2f82:
	dc.w $0084,(c2f83>>16)&$ffff
	dc.w $0086,(c2f83)&$ffff
	dc.w $ffff,$fffe	; wait end copper list
c2f83:
	dc.w $0084,(c2f84>>16)&$ffff
	dc.w $0086,(c2f84)&$ffff
	dc.w $ffff,$fffe	; wait end copper list
c2f84:
	dc.w $0084,(c2f85>>16)&$ffff
	dc.w $0086,(c2f85)&$ffff
	dc.w $ffff,$fffe	; wait end copper list
c2f85:
	dc.w $0084,(c2f1>>16)&$ffff
	dc.w $0086,(c2f1)&$ffff
	dc.w $ffff,$fffe	; wait end copper list

