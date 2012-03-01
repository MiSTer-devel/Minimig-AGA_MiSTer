		xref	_main;
;		xref	_s;
		xref	_sprintf;
;       xdef      _SPI
       xdef      _putch
       xdef      _printf
       xdef      _SwapBBBB
       xdef      _SwapBB
       xdef      _SwapWW
RS232_base	            equ			$DA8000
		SECTION	,CODE
		move.l	#$1000,a7
		jmp _main
;_SPI:       
;;	   move.b    7(A7),$da8001
;	   move.b    7(A7),$da4001
;	   move.b	    $da4001,d0
;;	   move.w	    $da4000,d0
;;	   andi.l	#$ff,d0
;;@spi_1: move    $da4000,d0
;;	   bmi.s	@spi_1
;       rts
_putch:                           ; Basic character output routine
       move.b    7(A7),$da8001
       rts
       
_printf:                           ; Basic character output routine
		move.l	(a7)+,rettmp
		pea		rs_buf
		bsr		_sprintf
		move.l	(a7),a0
		move.l	rettmp,(a7)
_printfa
		move.b	(a0)+,d0
		beq		_printfe
       move.b    d0,$da8001
       bra		_printfa
_printfe       
       rts
rettmp	ds.l	1
rs_buf  ds.b	256

_SwapBBBB
		move.l	4(a7),d0
		rol.w		#8,d0
		swap	d0
		rol.w		#8,d0
		rts

_SwapBB
		move.l	4(a7),d0
		rol.w		#8,d0
		rts

_SwapWW
		move.l	4(a7),d0
		swap	d0
		rts

		END
		