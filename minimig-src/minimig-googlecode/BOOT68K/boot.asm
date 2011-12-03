; Minimig bootloader - Copyright 2008, 2009 by Jakub Bednarski
;
; This file is part of Minimig
;
; Minimig is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 3 of the License, or
; (at your option) any later version.
;
; Minimig is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program.  If not, see <http://www.gnu.org/licenses/>.
;
;
; 2008-08-04	- code clean up
; 2008-08-17	- first complete version
; 2009-02-14	- added memory clear command
; 2009-09-11	- changed header signature and updated version number
; 2009-12-17	- changed header signature and updated version number
;		- added step pulse for updating disk change latch
; 2009-12-24	- updated version number
; 2010-04-14	- changed header signature and updated version number ($AA69)
;
;
; how to build:
; 1. assemble using ASM-One and save executable object
; 2. convert to binary form using reloc from WHDLoad
; 3. generate partial Verilog source using bin2vrlg

;------------------------------------------------------------------------------
; global register usage:
; D2 - X position of text cursor (0-79)
; D3 - Y position of text cursor (0-24) 
; A3 - text cursor framebuffer pointer
; A6 - $dff000 custom chip base

;------------------------------------------------------------------------------

VPOSR   = $04
INTREQR = $1E
DSKPTH  = $20
DSKLEN  = $24
LISAID  = $7C
COP1LCH = $80
COP1LCL = $82
COPJMP1 = $88
DIWSTRT = $8E
DIWSTOP = $90
DDFSTRT = $92
DDFSTOP = $94
DMACON  = $96
INTENA  = $9A
INTREQ  = $9C
ADKCON  = $9E
BPLCON0 = $100
BPLCON1 = $102
BPLCON2 = $104
BPL1MOD = $108
BPL2MOD = $10A
COLOR0  = $180
COLOR1  = $182

; memory allocation map
;
; 000000 +----------------+
;        | fpga boot rom  | 2 KB
; 000800 +----------------+
;        |                |
;        :                :
;        |                |
; 004000 +----------------+
;        |                |
;        :                :
;        : disk buffer    : 16 KB
;        :                :
;        |                |
; 008000 +----------------+
;        |                |
;        :                :
;        : display buffer : ~16 KB
;        :                :
;        |                |
; 00C100 +----------------+
;        | copper list    |
;        :                :
;        :                : ~16 KB
;        :                :
;        | stack          |
; 010000 +----------------+
;
; the last text line in the display buffer is not visible and always empty
; it's used for clearing the last visible text line while srolling up

plane0	    = $08000
copper	    = plane0+640/8*208
disk_buffer = plane0-$4000

;------------------------------------------------------------------------------

	dc.l	$00010000	; initial SSP
	dc.l	Start		; initial PC
	
;------------------------------------------------------------------------------
fpga_version:
	dc.b	"AA000000"	; FPGA core version - 8 ASCII characters

;------------------------------------------------------------------------------
	Start:
;------------------------------------------------------------------------------

	lea	$dff000,A6	; custom base
	
	bsr.w	ClearScreen

	move.w	#$9000,BPLCON0(A6)	;hires, 1 bitplane
	move.w	#$0000,BPLCON1(A6)	;horizontal scroll = 0
	move.w	#$0000,BPLCON2(A6)
	move.w	#$0000,BPL1MOD(A6)	;modulo = 0
	move.w	#$0000,BPL2MOD(A6)	;modulo = 0

	move.w	#$003C,DDFSTRT(A6)
	move.w	#$00D4,DDFSTOP(A6)
	move.w	#$2c81,DIWSTRT(A6)
	move.w	#$f4c1,DIWSTOP(A6)
;colours
	move.w	#$037f,COLOR0(A6)
	move.w	#$0fff,COLOR1(A6)

	lea	CopperList,A0
	lea	copper,A1
	moveq	#(CopperListEnd-CopperList)/4-1,D0

CopperListCopyLoop:
	move.l	(A0)+,(A1)+
	dbra	D0,CopperListCopyLoop

	move.l	#copper,COP1LCH(A6)
	move.w	D0,COPJMP1(A6)		;restart copper

	move.w	#%1000001110010000,DMACON(A6) ; DMAEN|BPLEN|COPEN|DSKEN
	move.w	#$7FFF,ADKCON(A6)	;disable word sync

;------------------------------------------------------------------------------

	lea	title_msg,A0
	bsr.w	PrintText

	lea	bootloader_msg,A0
	bsr.w	PrintText

	lea	fpga_msg,A0
	bsr.w	PrintText

	lea	Start-8,A2
	moveq	#8-1,D7

fpgaver_loop:
	move.b	(A2)+,D0
	bsr	putc
	dbra	D7,fpgaver_loop

	lea	agnus_msg,A0
	bsr.w	PrintText

	;Agnus ID is in VPOSR register
	move.w	VPOSR(A6),D0
	lsr.w	#8,D0
	andi.b	#$7F,D0
	bsr	putx			; returns with D0 in D1

	lea	pal_msg,A0
	btst	#4,D1
	beq	pal_agnus		; in PAL Agnus VPOSR.12 is 0
	lea	ntsc_msg,A0

pal_agnus:
	bsr	PrintText

	lea	denise_msg,A0
	bsr.w	PrintText
	move.w	LISAID(A6),D0
	bsr	putx

	moveq	#10,D0
	bsr	putc

	moveq	#10,D0
	bsr	putc

	move.b	#$03,$BFE201	; _led and ovl as outputs
	move.b	#$00,$BFE001	; _led active

	move.b	#$FF,$BFD300	; drive control signals as outputs
	move.b	#$F7,$BFD100	; _sel0 active

wait_for_diskchange:
	move.b	#$F6,$BFD100	; _sel0 and _step active
	move.b	#$F7,$BFD100	; _sel0 active
	btst	#2,$BFE001	; _chng active? (disk present)
	beq	wait_for_diskchange

read_cmd:
	move.w	#12,D0		; read size
	bsr	DiskRead

	move.l	#disk_buffer,A0
	cmp.w	#$AA69,(A0)+
	bne	bad_header

	move.w	(A0)+,D0

;-------------------------------
	cmd1:
;-------------------------------

	cmp.w	#1,D0		; print text command?
	bne	no_cmd_1	

	move.l	(A0)+,D0
	bsr	DiskRead
	lea	disk_buffer,A0
	bsr	PrintText

	moveq	#10,D0
	bsr	putc
	
	bra	end_cmd

no_cmd_1:

;-------------------------------
	cmd_2:
;-------------------------------
	
	cmp.w	#2,D0		; memory upload command?
	bne	no_cmd_2

	move.l	(A0)+,A4	; memory base
	move.l	A4,A5
	move.l	(A0)+,D4	; memory size
	move.l	D4,D5

	lea	memory_base_msg,A0
	bsr	PrintText

	move.l	A4,D0
	bsr	putxl

	lea	memory_size_msg,A0
	bsr	PrintText

	move.l	D4,D0
	bsr	putxl

	moveq	#10,D0
	bsr	putc

	lea	progress_msg,A0
	bsr	PrintText
	sub.w	#33,D2
	sub.w	#33,A3

upload_loop:
	;move.l	#$4000,D6
	move.l	D5,D6
	lsr.l	#5,D6
	cmp.l	D4,D6
	blt	_no_lt
	move.l	D4,D6
_no_lt:
	move.w	D6,D0
	bsr	DiskRead	

	move.w	D6,D0
	lsr.w	#2,D0
	subq.w	#1,D0
copy_loop:
	move.l	(A0)+,(A4)+
	dbra	D0,copy_loop

	moveq	#127,D0
	bsr	putc

	bchg.b	#1,$BFE001	; LED

	sub.l	D6,D4
	bgt	upload_loop

	cmpa.l	#$F80000,A5
	bne	no_256KB

	cmp.l	#$40000,D5
	bne	no_256KB

	movea.l	A5,A4
	adda.l	D5,A4
	moveq	#-1,D5
copy256KB_loop:
	move.l	(A5)+,(A4)+
	dbra	D5,copy256KB_loop

no_256KB:

	moveq	#10,D0
	bsr	putc

	bra	end_cmd
no_cmd_2:

;-------------------------------
	cmd_3:
;-------------------------------

	cmp.w	#3,D0		; exit bootloader command?
	bne	no_cmd_3

	bset.b	#1,$BFE001	; LED off
	tst.b	$BFC000

end_wait:
	bra.b	end_wait

no_cmd_3:

;-------------------------------
	cmd_4:
;-------------------------------
	
	cmp.w	#4,D0		; memory clear command?
	bne	no_cmd_4

	move.l	(A0)+,A4	; memory base
	move.l	(A0)+,D4	; memory size

	moveq	#0,D0
clear_loop:
	move.l	D0,(A4)+

	subq.l	#4,D4		; decrement loop counter
	bgt	clear_loop

	bra	end_cmd

no_cmd_4:

;-------------------------------
;-------------------------------

	move.w	D0,D7
	move.w	#$0F00,COLOR0(A6)
	lea	unknown_command_msg,A0
	bsr	PrintText

	move.w	D7,D0
	bsr	putxw

infinite_loop:
	bra	infinite_loop

bad_header:
	move.w	#$0F00,COLOR0(A6)
	lea	incompatible_firmware_msg,A0
	bsr	PrintText
	bra	infinite_loop

end_cmd:

	bra	read_cmd

;------------------------------------------------------------------------------
	DiskRead:
;------------------------------------------------------------------------------
; Args:
; 	D0 - read size in bytes
; Results:
; 	A0 - disk buffer
; Scratch:
; 	D0

	move.w	#$0002,INTREQ(A6)	;clear disk block finished irq
	movea.l	#disk_buffer,A0
	move.l	A0,DSKPTH(A6)
	lsr.w	#1,D0
	ori.w	#$8000,D0		;set DMAEN
	move.w	D0,DSKLEN(A6)
	move.w	D0,DSKLEN(A6)		;start disk dma

wait_for_diskdma:
	move.w	INTREQR(A6),D0
	btst	#1,D0			;disk block finished 
	beq	wait_for_diskdma

	rts

;------------------------------------------------------------------------------
	putxl:
;------------------------------------------------------------------------------
; Args: D0.w - character

	swap	D0
	bsr	putxw
	swap	D1
	move.l	D1,D0
;	bsr	putxw		;optimization
;	rts	

;------------------------------------------------------------------------------
	putxw:
;------------------------------------------------------------------------------
; Args: D0.w - character

	ror.w	#8,D0
	bsr	putx
	move.l	D1,D0
	ror.w	#8,D0
;	bsr	putx		;optimization
;	rts	

;------------------------------------------------------------------------------
	putx:
;------------------------------------------------------------------------------
; Args: D0.b - number to print (0-255)

	move.l	D0,D1
	lsr.b	#4,D0
	bsr	putcx

	move.l	D1,D0
	andi.b	#$0F,D0
;	bsr	putcx		;optimization
;	rts
	
;------------------------------------------------------------------------------
	putcx:
;------------------------------------------------------------------------------
; Args: D0.b - number to print (0-15)
	
	add.b	#'0',D0
	cmp.b	#'9',D0
	ble	putcx_le9
	add.b	#'A'-'9'-1,D0
putcx_le9:
;	bsr	putc		;optimization
;	rts
	
;------------------------------------------------------------------------------
	putc:
;------------------------------------------------------------------------------
; Args: D0.b - character
; scratch: D0,A0,A1

	movea.l	A3,A1		; framebuffer cursor pointer
	lea	1(A3),A3
	cmp.b	#10,D0		; LF?
	bne.b	no_LF

	suba.w	D2,A3		; return to the beginning of the line
	move.w	#0,D2		; PosX
	lea	8*640/8-1(A3),A3
	bra.b	incPosY	
no_LF:
	ext.w	D0
	sub.w	#32,D0		; font table begins with space character
	asl.w	#3,D0		; every character is 8 line high
	lea	font8,A0
	adda.w	D0,A0		; calculate font offset in table

	moveq	#8-1,D0		; number of lines
char_copy_loop:
	move.b	(A0)+,(A1)	; copy line
	lea	640/8(A1),A1
	dbra	D0,char_copy_loop

	addq	#1,D2		; inc PosX
	cmp.w	#80,D2		; last position?
	bne.b	no_EOL

	moveq	#0,D2		; return to the beginnig of the line
	adda.w	#7*640/8,A3

incPosY:
	addq.w	#1,D3		; inc PosY
	cmp.w	#25,D3		; check PosY
	bne.b	not_last_line

	subq.w	#1,D3		; PosY
	suba.w	#8*640/8,A3
	bsr.b	ScrollScreen
not_last_line:
no_EOL:
	rts

;------------------------------------------------------------------------------
	PrintText:
;------------------------------------------------------------------------------
; Args: A0 - pointer to NULL terminated text string
; Scratch: A2

	movea.l	A0,A2
next_char:
	movea.l	A3,A1
	moveq	#0,D0
	move.b	(A2)+,D0
	beq.b	end_of_string
	bsr.b	putc
	bra.b	next_char
end_of_string:
	rts

;------------------------------------------------------------------------------
	ScrollScreen:
;------------------------------------------------------------------------------
;scratch: D0,A0,A1

	lea	plane0,A0
	lea	8*640/8(A0),A1
	move.w	#640*200/8/4-1,D0
scrollscreen_loop:
	move.l	(A1)+,(A0)+
	dbra	D0,scrollscreen_loop
	rts
	
;------------------------------------------------------------------------------
	ClearScreen:
;------------------------------------------------------------------------------

	moveq	#0,D2		; PosX
	moveq	#0,D3		; PosY
	lea	plane0,A3	; PosPtr
	movea.l	A3,A0
	moveq	#0,D0
	move.w	#640*208/32-1,D1
clrscr_loop:
	move.l	D0,(A0)+
	dbra	D1,clrscr_loop	
	rts

;------------------------------------------------------------------------------
	CopperList:
;------------------------------------------------------------------------------

;bitplane pointers
bplptrs:
	dc.w $0e0,(plane0>>16)&$FFFF
	dc.w $0e2,plane0&$FFFF

	dc.w $ffff,$fffe

;------------------------------------------------------------------------------
	CopperListEnd:
;------------------------------------------------------------------------------

title_msg:	
	dc.b	"Minimig by Dennis van Weeren",10
	dc.b	"Bug fixes, mods and extensions by Jakub Bednarski",10
	dc.b	"For updates and support please visit www.minimig.net",10,0

bootloader_msg:
	dc.b	10,"Bootloader BYQ091224",10,0

fpga_msg:
	dc.b	10,"FPGA core F",0

agnus_msg:
	dc.b	10,10,"Agnus ID: $",0
pal_msg:
	dc.b	" (PAL)",0
ntsc_msg:
	dc.b	" (NTSC)",0
denise_msg:	
	dc.b	" Denise ID: $",0

memory_base_msg:
	dc.b	"Memory base: $",0
memory_size_msg:
	dc.b	", size: $",0
progress_msg:
	dc.b	"[________________________________]",0


incompatible_firmware_msg:
	dc.b	10,"Incompatible MCU firmware!",0	

unknown_command_msg:
	dc.b	10,"Unknown command: $",0

font8:
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00	; SPACE
	dc.b	$18,$18,$18,$18,$18,$00,$18,$00	; !
	dc.b	$6C,$6C,$00,$00,$00,$00,$00,$00	; "
	dc.b	$6C,$6C,$FE,$6C,$FE,$6C,$6C,$00	; #
	dc.b	$18,$3E,$60,$3C,$06,$7C,$18,$00	; $
	dc.b	$00,$66,$AC,$D8,$36,$6A,$CC,$00	; %
	dc.b	$38,$6C,$68,$76,$DC,$CE,$7B,$00	; &
	dc.b	$18,$18,$30,$00,$00,$00,$00,$00	; '
	dc.b	$0C,$18,$30,$30,$30,$18,$0C,$00	; (
	dc.b	$30,$18,$0C,$0C,$0C,$18,$30,$00	; )
	dc.b	$00,$66,$3C,$FF,$3C,$66,$00,$00	; *
	dc.b	$00,$18,$18,$7E,$18,$18,$00,$00	; +
	dc.b	$00,$00,$00,$00,$00,$18,$18,$30	; ,
	dc.b	$00,$00,$00,$7E,$00,$00,$00,$00	; -
	dc.b	$00,$00,$00,$00,$00,$18,$18,$00	; .
	dc.b	$03,$06,$0C,$18,$30,$60,$C0,$00	; /
	dc.b	$3C,$66,$6E,$7E,$76,$66,$3C,$00	; 0
	dc.b	$18,$38,$78,$18,$18,$18,$18,$00	; 1
	dc.b	$3C,$66,$06,$0C,$18,$30,$7E,$00	; 2
	dc.b	$3C,$66,$06,$1C,$06,$66,$3C,$00	; 3
	dc.b	$1C,$3C,$6C,$CC,$FE,$0C,$0C,$00	; 4
	dc.b	$7E,$60,$7C,$06,$06,$66,$3C,$00	; 5
	dc.b	$1C,$30,$60,$7C,$66,$66,$3C,$00	; 6
	dc.b	$7E,$06,$06,$0C,$18,$18,$18,$00	; 7
	dc.b	$3C,$66,$66,$3C,$66,$66,$3C,$00	; 8
	dc.b	$3C,$66,$66,$3E,$06,$0C,$38,$00	; 9
	dc.b	$00,$18,$18,$00,$00,$18,$18,$00	; :
	dc.b	$00,$18,$18,$00,$00,$18,$18,$30	; ;
	dc.b	$00,$06,$18,$60,$18,$06,$00,$00	; <
	dc.b	$00,$00,$7E,$00,$7E,$00,$00,$00	; =
	dc.b	$00,$60,$18,$06,$18,$60,$00,$00	; >
	dc.b	$3C,$66,$06,$0C,$18,$00,$18,$00	; ?
	dc.b	$7C,$C6,$DE,$D6,$DE,$C0,$78,$00	; @
	dc.b	$3C,$66,$66,$7E,$66,$66,$66,$00	; A
	dc.b	$7C,$66,$66,$7C,$66,$66,$7C,$00	; B
	dc.b	$1E,$30,$60,$60,$60,$30,$1E,$00	; C
	dc.b	$78,$6C,$66,$66,$66,$6C,$78,$00	; D
	dc.b	$7E,$60,$60,$78,$60,$60,$7E,$00	; E
	dc.b	$7E,$60,$60,$78,$60,$60,$60,$00	; F
	dc.b	$3C,$66,$60,$6E,$66,$66,$3E,$00	; G
	dc.b	$66,$66,$66,$7E,$66,$66,$66,$00	; H
	dc.b	$3C,$18,$18,$18,$18,$18,$3C,$00	; I
	dc.b	$06,$06,$06,$06,$06,$66,$3C,$00	; J
	dc.b	$C6,$CC,$D8,$F0,$D8,$CC,$C6,$00	; K
	dc.b	$60,$60,$60,$60,$60,$60,$7E,$00	; L
	dc.b	$C6,$EE,$FE,$D6,$C6,$C6,$C6,$00	; M
	dc.b	$C6,$E6,$F6,$DE,$CE,$C6,$C6,$00	; N
	dc.b	$3C,$66,$66,$66,$66,$66,$3C,$00	; O
	dc.b	$7C,$66,$66,$7C,$60,$60,$60,$00	; P
	dc.b	$78,$CC,$CC,$CC,$CC,$DC,$7E,$00	; Q
	dc.b	$7C,$66,$66,$7C,$6C,$66,$66,$00	; R
	dc.b	$3C,$66,$70,$3C,$0E,$66,$3C,$00	; S
	dc.b	$7E,$18,$18,$18,$18,$18,$18,$00	; T
	dc.b	$66,$66,$66,$66,$66,$66,$3C,$00	; U
	dc.b	$66,$66,$66,$66,$3C,$3C,$18,$00	; V
	dc.b	$C6,$C6,$C6,$D6,$FE,$EE,$C6,$00	; W
	dc.b	$C3,$66,$3C,$18,$3C,$66,$C3,$00	; X
	dc.b	$C3,$66,$3C,$18,$18,$18,$18,$00	; Y
	dc.b	$FE,$0C,$18,$30,$60,$C0,$FE,$00	; Z
	dc.b	$3C,$30,$30,$30,$30,$30,$3C,$00	; [
	dc.b	$C0,$60,$30,$18,$0C,$06,$03,$00	; \
	dc.b	$3C,$0C,$0C,$0C,$0C,$0C,$3C,$00	; ]
	dc.b	$10,$38,$6C,$C6,$00,$00,$00,$00	; ^
	dc.b	$00,$00,$00,$00,$00,$00,$00,$FE	; _
	dc.b	$18,$18,$0C,$00,$00,$00,$00,$00	; `
	dc.b	$00,$00,$3C,$06,$3E,$66,$3E,$00	; a
	dc.b	$60,$60,$7C,$66,$66,$66,$7C,$00	; b
	dc.b	$00,$00,$3C,$60,$60,$60,$3C,$00	; c
	dc.b	$06,$06,$3E,$66,$66,$66,$3E,$00	; d
	dc.b	$00,$00,$3C,$66,$7E,$60,$3C,$00	; e
	dc.b	$1C,$30,$7C,$30,$30,$30,$30,$00	; f
	dc.b	$00,$00,$3E,$66,$66,$3E,$06,$3C	; g
	dc.b	$60,$60,$7C,$66,$66,$66,$66,$00	; h
	dc.b	$18,$00,$18,$18,$18,$18,$0C,$00	; i
	dc.b	$0C,$00,$0C,$0C,$0C,$0C,$0C,$78	; j
	dc.b	$60,$60,$66,$6C,$78,$6C,$66,$00	; k
	dc.b	$18,$18,$18,$18,$18,$18,$0C,$00	; l
	dc.b	$00,$00,$EC,$FE,$D6,$C6,$C6,$00	; m
	dc.b	$00,$00,$7C,$66,$66,$66,$66,$00	; n
	dc.b	$00,$00,$3C,$66,$66,$66,$3C,$00	; o
	dc.b	$00,$00,$7C,$66,$66,$7C,$60,$60	; p
	dc.b	$00,$00,$3E,$66,$66,$3E,$06,$06	; q
	dc.b	$00,$00,$7C,$66,$60,$60,$60,$00	; r
	dc.b	$00,$00,$3C,$60,$3C,$06,$7C,$00	; s
	dc.b	$30,$30,$7C,$30,$30,$30,$1C,$00	; t
	dc.b	$00,$00,$66,$66,$66,$66,$3E,$00	; u
	dc.b	$00,$00,$66,$66,$66,$3C,$18,$00	; v
	dc.b	$00,$00,$C6,$C6,$D6,$FE,$6C,$00	; w
	dc.b	$00,$00,$C6,$6C,$38,$6C,$C6,$00	; x
	dc.b	$00,$00,$66,$66,$66,$3C,$18,$30	; y
	dc.b	$00,$00,$7E,$0C,$18,$30,$7E,$00	; z
	dc.b	$0E,$18,$18,$70,$18,$18,$0E,$00	; {
	dc.b	$18,$18,$18,$18,$18,$18,$18,$00	; |
	dc.b	$70,$18,$18,$0E,$18,$18,$70,$00	; }
	dc.b	$72,$9C,$00,$00,$00,$00,$00,$00	; ~
	dc.b	$FE,$FE,$FE,$FE,$FE,$FE,$FE,$00	; 
