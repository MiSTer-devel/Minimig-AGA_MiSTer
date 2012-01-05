; CSTART.ASM  -  C startup-code for SIM68K

lomem  equ       $0100             ; Lowest usable address
himem  equ       $1000           ; Highest memory addres + 1
;stklen equ       $1000            ; Default stacksize
;fatbase		equ		$380400
RS232_base	            equ			$DA8000
IDEbase			equ			$DA2000
IDEbase2		equ			$DA1000
SPIbase		equ			$DA4000
KEYbase		equ			$DE0000
_secbuf		equ			$1000
;buffer1		equ			$10200

; IDE register map
ide_data	            equ $00	; r/w
ide_error	            equ $04	; r
ide_features	equ $04	; w
ide_scount	            equ $08	; r/w
ide_lba0	            equ $0c	; r/w
ide_lba1	            equ $10	; r/w
ide_lba2	            equ $14	; r/w
ide_lba3	            equ $18	; r/w
ide_status	            equ $1c	; r
ide_command	equ $1c	; w

; IDE commands
idecmd_read_sector	equ $20
idecmd_write_sector	equ $30
idecmd_packet	equ $a0
idecmd_identify	equ $ec
idecmd_identifypacket	equ $a1


       org       0
       dc.l      himem		;a7
       dc.l      start
       
       org		 $68
;       dc.l		hdf_sbr
;       dc.l		softirq
       
       org       lomem
;       org		 $68+8
       
       
start:
;       move.b    #'$',$da8000

;       lea      himem-$80,A0
;       lea      himem-$80,A7
;       move.l	a7,usp
;       and		#$F8FF,sr
       
       move		 #$5555,_cachevalid
;       jsr		_ide_init
       jsr		spi_init
       bne.s     start
       
		bsr			_FindVolume		
;       bsr       _main
       bne.s     start3
;       move.b	#'S',RS232_base
			bsr			fat_cdroot
			;d0 - LBA
			lea		mmio_name,a1
			bsr		fat_findfile
			beq.s     start3	
				
			lea		found_MM,a0
			bsr		put_msg
			move.l		#$2000,a0
			bsr		_LoadFile2
			beq.s     start4	
			jmp		$2000
start4     move  #$60fe,$2000
			jmp		$2000

;			bra.s     start4
start3			
			lea		notfound,a0
			bsr		put_msg
			
start2     bra.s     start2
;       xdef      _exit
notfound   dc.b"not "
found_MM   dc.b	"found "
mmio_name:	dc.b	"MENUE   SYS",0


       xdef      __putch
__putch:                           ; Basic character output routine
       move.b    7(A7),$da8000
       rts
       
       xdef      _OSD
_OSD:       
       
       xdef      _SPI
_SPI:       
	   move.b    7(A7),$da4001
@spi_1: move    $da4000,d0
	   bmi.s	@spi_1
       rts
      
       xdef		_EnableOsd
_EnableOsd:		
	   move.b 	#$20,$da4007
       rts
       
       xdef		_DisableOsd
_DisableOsd:		
	   move.b 	#$21,$da4007
       rts

       xdef		_EnableFpga
_EnableFpga:		
	   move.b 	#$10,$da4007
       rts
       
       xdef		_DisableFpga
_DisableFpga:		
	   move.b 	#$11,$da4007
       rts
       
       xdef		_EnableFpga
_EnableSPI:		
	   move.b 	#$02,$da4007
       rts
       
       xdef		_DisableFpga
_DisableSPI:		
	   move.b 	#$03,$da4007
       rts
 
;***************************************************
; SPI 
;***************************************************

;;unsigned char MMC_Read(unsigned long lba, unsigned char *ReadData)
;				xdef	_MMC_Read 
;_MMC_Read:
;				move.l    	4(A7),D1	;sector
;				move.l    	8(A7),A0	;buffer
;;				bra.s		cmd_read_sector

;cmd_read_block0:
;	;d1 Sector
;			lea		buffer0,a0


;***************************************************
; SPI Commands
;INPUT:   D0 - sector
;         (A0 - Inputbuffer)
;RETURN:  D0=0 => OK D0|=0 => fail
;         D1 - used
;         A0 - Inputbuffer Start
;         
;***************************************************
cmd_read_sector:
	; vor Einsprung A0 setzen
			lea			_secbuf,a0
				cmp 		#$AAAA,_cachevalid
				bne.s		read_sd11
				cmp.l		_cachelba,d0
				bne.s		read_sd11
				moveq		#0,d0						;OK
				rts
read_sd11:
				move		 #$AAAA,_cachevalid
				move.l		d0,_cachelba
cmd_read_block
;			move.l	d0,d1
			bsr		cmd_read
			bne		read_error3		;Error
read1
			move	#20000,d1		;Timeout counter
			move	#-1,(a1)		;8 Takte fürs Lesen
read2		subq	#1,d1
			beq		read_error2		;Timeout
read_w1		move	(a1),d0
;			bmi		read_w1
			move	#-1,(a1)		;8 Takte fürs Lesen
;			lea		RS232_base,a4
;			move.b	#'=',(a4)
;			move.b	d0,(a4)		
;			lea		SPIbase,a1
			cmp.b	#$fe,d0
			bne		read2			;auf Start warten
			move	#511,d1
read_w2		move	(a1),d0
;			bmi		read_w2
			move	#-1,(a1)		;8 Takte fürs Lesen
			move.b	d0,(a0)+
;	move.b	d0,RS232_base
			dbra	d1,read_w2
;read_w3		move	(a1),d0
;			bmi		read_w3
			move	#-1,(a1)		;8 Takte fürs Lesen CRC
			move	#3,4(a1)		;sd_cs high
			lea		-$200(a0),a0
			moveq	#0,d0
			rts
read_error2	
			move	#$5555,_cachevalid
			lea		msg_timeout_Error,a0
			bsr		put_msg
			moveq	#-2,d0
			rts		
read_error3	move	#$5555,_cachevalid
			lea		msg_cmdtimeout_Error,a0
			bsr		put_msg
			moveq	#-1,d0
			rts		

		

;******************************************************
; SPI Commands
; INPUT:   D0 - sector
; RETURN:  D0=$FF => Timeout D0|=$FF => Command Return
;          D1|=$00 => Timeout
;          A1 - SPIbase
;******************************************************
cmd_reset:	move.l	#$950040,d1
			moveq	#0,d0
			bra		cmd_wr
			
cmd_init:	move.l	#$ff0041,d1
			moveq	#0,d0
			bra		cmd_wr
			
;cmd_write:	move.l	#$ff0058,d1
;			bra		cmd_wr
			
cmd_read:	move.l	#$ff0051,d1
			
cmd_wr
;			d1  crc,command	
			lea		SPIbase,a1
			move	#-1,(a1)	;8x clock
			move	#2,4(a1)	;sd_cs low
;			move	#-1,(a1)	;8x clock
			add.l	d0,d0
			swap	d0
			move	d1,(a1)		;cmd
			move	d0,(a1)		;31..24
			swap	d0
			rol		#8,d0
			move	d0,(a1)		;23..16
			rol		#8,d0
			move	d0,(a1)		;15..8
			move	#0,(a1)		;7..0
			swap	d1
			move	d1,(a1)		;crc
;			;wait for answer
			move	#4000,d1	;Timeout counter
			
cmd_wr10	sub		#1,d1
			beq		cmd_wr11	;Timeout
			move	#-1,(a1)	;8 Takte fürs Lesen
cmd_wr9		move	(a1),d0
			cmp.b	#$ff,d0
			beq		cmd_wr10
cmd_wr11
;	move.b	#'*',RS232_base
;	move.b	d0,RS232_base		
			or.b	d0,d0
			rts					;If d0=$FF => Timeout 
								
			
;msg_time:			dc.b	"Timeout error"	,$d,$a,0
;msg_address:		dc.b	"Address error"	,$d,$a,0
;msg_crc:			dc.b	"crc error"		,$d,$a,0
;msg_illegal:		dc.b	"illegal error"	,$d,$a,0
;msg_para:			dc.b	"parameter error",$d,$a,0
;msg_any:			dc.b	"any error"		,$d,$a,0
;msg_cmdtime:		dc.b	"Command Time"	,$d,$a,0
;msg_readtime:		dc.b	"Read Time"		,$d,$a,0
msg_start_init		dc.b	"Start Init"	,$d,$a,0
msg_init_done		dc.b	"Init done"	    ,$d,$a,0
msg_init_fail		dc.b	"Init failure"	    ,$d,$a,0
msg_reset_fail		dc.b	"Reset failure"	    ,$d,$a,0
msg_cmdtimeout_Error	dc.b	"Command Timeout_Error"	    ,$d,$a,0
msg_timeout_Error	dc.b	"Timeout_Error"	    ,$d,$a,0

;pulse		lea		SPIbase,a1
;;			move	#2,4(a1)		;sd_cs low
;			move	#-1,(a1)	;8x clock
;pulse2		tst		(a1)
;			bmi		pulse2
;;			move	#3,4(a1)		;sd_cs high
;			rts
			
				xdef	_MMC_Init 
_MMC_Init:

spi_init
;	pea	msg_start_init,-(a7)
;	bsr	put_msga7
;	lea	4(a7),a7
			move.l	d2,-(a7)
			lea		SPIbase,a1
			move	#$FF,4(a1)		;all cs high
			move	#$20,8(a1)		;SPI Speed
			move	#100,d1
spi_init_w1	move	(a1),d0
			bmi		spi_init_w1
			move	#-1,(a1)	;8 Takte fürs Lesen
			dbra	d1,spi_init_w1
			
			move	#50,d2
;		bsr pulse	
spi_init_w2	bsr		cmd_reset
			move	#3,4(a1)		;sd_cs high
			cmp.b	#1,d0
			beq		spi_init_w3
			dbra	d2,spi_init_w2
			move.l	(a7)+,d2
			
	pea	msg_reset_fail,-(a7)
	bsr	put_msga7
	lea	4(a7),a7
			moveq	#-1,d0
			rts		;init fault
			
spi_init_w3	move	#50,d2
	pea	msg_start_init,-(a7)
	bsr	put_msga7
	lea	4(a7),a7
spi_init_w5	move	#40000,d1
spi_init_w4	dbra	d1,spi_init_w4		;wait
;		bsr pulse	
		move	#-1,(a1)	;8x clock

			bsr		cmd_init
			beq		spi_init_w6
			move	#3,4(a1)		;sd_cs high
			dbra	d2,spi_init_w5
			move.l	(a7)+,d2
	pea	msg_init_fail,-(a7)
	bsr	put_msga7
	lea	4(a7),a7
			or.b	d0,d0
			rts		;init fault
			
spi_init_w6;	move	#$00,8(a1)		;max SPI Speed 
			move	#3,4(a1)		;sd_cs high
;		bsr pulse	
		move	#-1,(a1)	;8x clock
	pea	msg_init_done,-(a7)
	bsr	put_msga7
	lea	4(a7),a7
			move.l	(a7)+,d2
			moveq	#0,d0
			rts
		

;	A0	Stringpointer 
put_msg		;lea 		RS232_base,a1
put_msg1	move.b		(a0)+,d0
			beq			put_msg_end
			move.b		d0,RS232_base
			bra			put_msg1
put_msg_end	rts

put_msga7	move.l		a0,-(a7)
			move.l		8(a7),a0
put_msg2	tst.b		(a0)
			beq			put_msg3
			move.b		(a0)+,RS232_base
			bra			put_msg2
put_msg3	move.l		(a7)+,a0
			rts

;_secbuf  ds.b 512
		
cluster				ds.b	4	;$00		; 32-bit clusters
part_fat			ds.b	4	;$04		; 32-bit start of fat
part_rootdir		ds.b	4	;$08		; 32-bit root directory address
part_cstart			ds.b	4	;$0c		; 32-bit start of clusters
part_rootdirentrys	ds.b	2	;$10		; entris in root directory
vol_fstype			ds.b	2	;$12
vol_secperclus		ds.b	2	;$14
scount				ds.b	2	;$16		; number of sectors to read
dir_is_fat16root	ds.b	4	;$18		; marker for rootdir
sector_ptr			ds.b	4	;$1c
;dir_is_fat16root	equ	$20
lba					ds.b	4	;$24
spipass 			ds.b	2	;$10000

_cachevalid			ds.w	1
_cachelba			ds.l	1
_drive				ds.w	1
_fstype				ds.w	1
_rootcluster		ds.l	1
_rootsector			ds.l	1
_cluster			ds.l	1
_sectorcnt			ds.w	1
_sectorlba			ds.l	1
_attrib				ds.w	1

_volstart			ds.l	1	;start LBA of Volume
_fatstart			ds.l	1	;start LBA of first FAT table
_dirstart			ds.l	1	;start LBA of directory table
_datastart			ds.l	1	;start LBA of data field
_clustersize		ds.w	1	;size of a cluster in blocks
_rootdirentrys		ds.w	1	;number of entry's in directory table


		

;unsigned char _FindVolume(void)
		xdef	_FindVolume 
_FindVolume:
;				lea			IDEbase,a1            		;LBA  Secundar
;				btst.w		#2,_drive
;				beq.s		fd_m1
;				lea			IDEbase2,a1            		;LBA  Primaer
;;;wait for 1K30 config ready			
;fd_m1			;move.b		ide_status(a1),d0       		;7..0
;;				btst.b		#7,d0     		;busy?
;;				bne			fd_m1
;;				btst.b		#6,d0     		;ready?
;;				beq			fd_m1
;				
;;		move.l		_dirstart,d0
;;		rol.l			#8,d0
;;		move.b		d0,RS232_base
;;		rol.l			#8,d0
;;		move.b		d0,RS232_base
;;		rol.l			#8,d0
;;		move.b		d0,RS232_base
;;		rol.l			#8,d0
;;		move.b		d0,RS232_base
;	move.b		#'-',RS232_base			
;				move.b		ide_data(a1),d0       		;7..0
;				move.b		#$AA,ide_scount(a1)       	;7..0
;				move.b		ide_scount(a1),d0       		;7..0
;				cmpi.b		#$AA,d0
;				bne.s		fd_m1
;				move.b		#$55,ide_scount(a1)       	;7..0
;				move.b		ide_scount(a1),d0       		;7..0
;				cmpi.b		#$55,d0
;				bne.s		fd_m1
;	move.b		#'*',RS232_base			

;       move.b	#'F',RS232_base

;@checktype:
		moveq		#0,d0	;partitionstable
		move.l		d0,_volstart
;		bsr			_read_secbuf
		bsr			cmd_read_sector
		bne.s 		@error
;	move.b		#'*',RS232_base			
;	move.b		#'*',RS232_base			

		cmpi.b		#$55,$1fe(a0)
		bne.s		@error
		cmpi.b		#$AA,$1ff(a0)
		bne.s		@error
;	move.b		#'T',RS232_base	
			
		move.b		_drive,d0
		and.w		#$70,d0
		cmp.w		#$40,d0
		bcc.s		_testfat	;Superfloppy
	
		lea			_secbuf+$1be,a1		; pointer to partition table
		adda.w			d0,a1
;
;		move.b		4(a1),d0
;		cmpi.b		#01,d0		; fat12 uses $01
;		beq.s 		_foundfat
;		cmpi.b		#04,d0		; fat16 uses $04, $06, or $0e 
;		beq.s 		_foundfat
;		cmpi.b		#06,d0		; fat16 uses $04, $06, or $0e 
;		beq.s 		_foundfat
;		cmpi.b		#$0E,d0		; fat16 uses $04, $06, or $0e 
;		beq.s 		_foundfat
;		cmpi.b		#$0b,d0		; fat32 uses $0b or $0c
;		beq.s 		_foundfat
;		cmpi.b		#$0c,d0		; fat32 uses $0b or $0c
;		bne.s 		@next
		
;_foundfat:
;read_vol_sector	
;	move.b		#'F',RS232_base			
		move.l		8(a1),d0	;LBA
		ror.w		#8,d0
		swap		d0
		ror.w		#8,d0
		move.l		d0,_volstart
;		lea			_secbuf,a0
;		bsr			_read_secbuf
		bsr			cmd_read_sector	; read sector 
		bne.s		@error
		cmpi.b		#$55,$1fe(a0)
		bne.s		@error
		cmpi.b		#$AA,$1ff(a0)
		beq.s		_testfat
;		bne.s		@error
;		bsr.s		_testfat
;		bne.s		@next
;		rts					;volume is loaded
@error:
;		move.b		#'E',RS232_base			
		moveq		#-1,d0
		rts

;@next:
;		move.b		#'X',RS232_base	
;		adda.w		#$10,a1
;		cmpa.l		#_secbuf+$1fe,a1
;		bne		@checktype
;test floppy format CF	

_testfat:
		cmpi.l		#$46415431,$36(a0)	;"FAT1"
		bne.s		_testfat_2
		move.b		#12,_fstype
		cmpi.l		#$32202020,$3A(a0)	;"2   "
		beq.s		_testfat_ex
		move.b		#16,_fstype
		cmpi.l		#$36202020,$3A(a0)	;"6   "
		beq.s		_testfat_ex
_testfat_2:
		move.b		#$00,_fstype
		cmpi.l		#$46415433,$52(a0)	;"FAT3"
		bne.s		@error
		cmpi.l		#$32202020,$56(a0)	;"2   "
		bne.s		@error
		move.b		#32,_fstype
_testfat_ex:
		move.l		$0a(a0),d0	; make sure sector size is 512
		and.l		#$FFFF00,d0
		cmpi.l		#$00200,d0
		bne		@error
;		and.l		#$FFFFFF00,d0
;		ror.l		#8,d0
;		cmpi.w		#$002,d0
;		bne.s		@error
;		swap		d0
;		move.w		d0,_clustersize	; number of sectors per cluster
		
			move.l		_volstart,d1
;			moveq		#0,d0
			move.w		$e(a0),d0		;reserved Sectors
			ror.w		#8,d0
			add.l		d0,d1
			move.l		d1,_fatstart			;Fat Table
		cmpi.b		#32,_fstype
		bne.s		 @fat16
		
;@fat32:
		move.l		$2c(a0),d0	; cluster of root directory
		ror.w		#8,d0
		swap		d0
		ror.w		#8,d0
;		move.l		d0,_dirstart	;cluster	
		move.l		d0,_rootcluster
; find start of clusters
		move.l		$24(a0),d0	;FAT Size
		ror.w		#8,d0
		swap		d0
		ror.w		#8,d0
_add_start32		
		add.l		d0,d1
		subq.b		#1,$10(a0)
		bne.s		_add_start32
		bra.s		subcluster
		
@fat16
			moveq		#0,d0
			move.l		d0,_rootcluster
			move.w		$16(a0),d0				;Sectors per Fat
			ror.w		#8,d0
root_sect	add.l		d0,d1
			subi.b		#1,$10(a0);d2			;number of FAT Copies
			bne			root_sect
;			move.l		d1,_dirstart			;Root sector - LBA
			move.l		d1,_rootsector
			
			move.b		$12(a0),d0
			lsl			#8,d0
			move.b		$11(a0),d0
			move		d0,_rootdirentrys
			lsr			#4,d0
			add.l		d0,d1
subcluster:	
			moveq		#0,d0
			move.b		$d(a0),d0
			move		d0,_clustersize
			sub.l		d0,d1					; subtract two clusters to compensate
			sub.l		d0,d1					; for reserved values 0 and 1
			move.l		d1,_datastart			;start of clusters
			
fat_ex:
			moveq		#0,d0
			rts


;;D0 to hex			
;debug_hex	movem.l		d1/a1,-(a7)
;			lea 		RS232_base,a1
;			move.b		#' ',(a1)
;			move.b		#' ',(a1)
;			move.b		#'-',(a1)
;			move.b		#'-',(a1)
;			moveq		#7,d1
;dhex2		rol.l		#4,d0	
;			swap		d1
;			move		d0,d1
;			and 		#$0F,d1
;			add			#$30,d1
;			cmp			#$3a,d1
;			bcs			dhex1
;			add			#$7,d1
;dhex1		move.b		d1,(a1)
;			swap		d1
;			dbra		d1,dhex2
;			move.b		#'-',(a1)
;			move.b		#'-',(a1)
;			move.b		#' ',(a1)
;			move.b		#' ',(a1)
;			movem.l		(a7)+,d1/a1
;			rts

fat_cdroot:
;			cmpi.b		#32,_fstype
			move.l		_dirstart,d0	; cluster of basic directory
			move.l		d0,_cluster	
			bne.s		 cdfat_32
		
			clr.l		_cluster
			move.w		_rootdirentrys,d0
			lsr			#4,d0
			move.w		d0,_sectorcnt
			move.l		_rootsector,d0
			move.l		d0,_sectorlba		;lba
			rts

cluster2lba:		
			move.l		_cluster,d0
cdfat_32:	
			move.w		_clustersize,d1
			move.w		d1,_sectorcnt
@fat32_1:		
			lsr			#1,d1
			bcs.s		@fat32_2
			lsl.l		#1,d0
			bra.s		@fat32_1
@fat32_2:
			add.l		_datastart,d0
			move.l		d0,_sectorlba	
			rts


		
		xdef	_SearchFile 
_SearchFile:

			move.l 		4(a7),a1	;ptr name
			bsr			fat_cdroot
			;d0 - LBA
fat_findfile
;		bsr			_read_secbuf
;		a1 - ptr to name
		movem.l		d2/a2,-(a7)
		move.l		a1,a2
fat_findfile_m4
		bsr			cmd_read_sector	; read sector 
		bne		fat_findfile_m8
;			move.l		d2,-(a7)
			moveq		#15,d2
fat_findfile_m3
			tst.b	(a0)		;end
			beq.s		fat_findfile_m8
			moveq		#10,d0
fat_findfile_m2			
;       move.b	(a0,d0),RS232_base
			move.b		(a2,d0),d1
			cmp.b		(a0,d0),d1
			beq			fat_findfile_m1
			add.b		#$20,d1		;
			cmp.b		(a0,d0),d1
			bne			fat_findfile_m9
fat_findfile_m1	
			dbra		d0,fat_findfile_m2
;file found	
			moveq	#0,d0
			move.b	11(a0),d0
			move.w	d0,_attrib
			cmpi.b		#32,_fstype
			bne.s		 sfs_m3
			move.w	20(a0),d0		;high cluster
			ror.w	#8,d0
			swap	d0
sfs_m3:		move.w	26(a0),d0		;high cluster
			ror.w	#8,d0
			move.l	d0,_cluster
		movem.l		(a7)+,d2/a2
			moveq	#-1,d0
			rts


fat_findfile_m9
			adda		#$0020,a0
			dbra		d2,fat_findfile_m3		
			
;fat_read_next_sector:
;			move.l		(a7)+,d2
			move.l 		_sectorlba,d0	
			addq.l		#1,d0		 
			move.l 		d0,_sectorlba			 

			subi.w		#1,_sectorcnt
			bne 		fat_findfile_m4
			bsr			next_cluster
			beq.s		fat_findfile_m8
			bsr			cluster2lba		
			bra			fat_findfile_m4
fat_findfile_m8			
		movem.l		(a7)+,d2/a2
			moveq		#0,d0			;file not found
			rts

		xdef	_LoadFile 
_LoadFile:
			move.l 		4(a7),a0	;Loadaddr
			
_LoadFile2:
			bsr			cluster2lba
_LoadFile1:	
			bsr			cmd_read_block
			bne.s		lferror
			
;fat_read_next_sector:
			adda.l		#$200,a0
			move.l 		_sectorlba,d0	
			addq.l		#1,d0		 
			move.l 		d0,_sectorlba			 

			subi.w		#1,_sectorcnt
			bne 		_LoadFile1
			move.l		a0,-(a7)
			bsr			next_cluster
			move.l		(a7)+,a0
			bne			_LoadFile2
;			moveq		#0,d0
			move.l		a0,d0
			rts
lferror:	moveq		#0,d0		
			rts
			
			
next_cluster:
		cmpi.b		#32,_fstype
		beq.s		 fnc_m32
		cmpi.b		#12,_fstype
		beq.s		 fnc_m12

;FAT16
		move.l    	_cluster,D0
		lsr.l     	#8,D0
		add.l		_fatstart,D0
;		bsr			_read_secbuf
		bsr			cmd_read_sector	; read sector 
		bne.s		fnc_end
;		moveq		#0,d0
		move.b    	_cluster+3,D0
		add.w		d0,d0
		move.w		(a0,d0),d0
		ror.w		#8,d0
		move.l    	D0,_cluster
		or.l		#$ffff000f,d0
		cmp.w		#$ffff,d0
		rts
fnc_m32:	
;FAT32
		move.l    	_cluster,D0
		lsr.l     	#7,D0
		add.l		_fatstart,D0
;		bsr			_read_secbuf
		bsr			cmd_read_sector	; read sector 
		bne.s		fnc_end
;		moveq		#0,d0
		move.b    	_cluster+3,D0
		and.w		#$7f,d0
		add.w		d0,d0
		add.w		d0,d0
		move.l		(a0,d0),d0
		ror.w		#8,d0
		swap		d0
		ror.w		#8,d0
		move.l    	D0,_cluster
		or.l		#$f0000007,d0
		cmp.l		#$ffffffff,d0
		rts
fnc_end:
		moveq		#0,d0
		rts
		

fnc_m12:	
;FAT12
		move.l		d2,-(a7)
		move.l    	_cluster,D0	;cluster
;	bsr	debug_hex
		move.l		d0,d1
		add.l		d0,d0
		add.l		d1,d0		;*3
		move.l		d0,d1		;nibbles
		lsr.l     	#8,D0		
		lsr.l     	#2,D0		;cluster*1.5/256
		add.l		_fatstart,D0
		move.l		d0,d2
;	bsr	debug_hex
;		bsr			_read_secbuf
		bsr			cmd_read_sector	; read sector 
		bne.s		fnc_end2
		move.l		d1,d0
		lsr.l		#1,d0
		and.w		#$1ff,d0
		cmp			#$1ff,d0
		bne			fnc_m14
		
		move.b		(a0,d0),d0
		exg.l		d0,d2
		addq.l		#1,d0
;		bsr			_read_secbuf
		bsr			cmd_read_sector	; read sector 
		bne.s		fnc_end2
		lsl			#8,d2
		move.b		(a0),d2
		bra.s		fnc_m15
		
fnc_m14:		
		move.b		(a0,d0),d2
		lsl			#8,d2
		move.b		1(a0,d0.w),d2
fnc_m15:
		rol.w		#8,d2
		and			#1,d1
		beq.s		fnc_m13
		lsr			#4,d2
fnc_m13:
		and.l		#$FFF,d2
		move.l    	D2,_cluster
		or.l		#$fffff00f,d2
		move.l		d2,d0
;	move.l	d2,d0	
;	bsr	debug_hex
		move.l		(a7)+,d2
		cmp.w		#$ffff,d0
		rts

fnc_end2:
		move.l		(a7)+,d2
		moveq		#0,d0
		rts
		

		
		
			