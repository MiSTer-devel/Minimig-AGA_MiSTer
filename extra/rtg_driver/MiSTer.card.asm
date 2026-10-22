; Minimig.card - P96 RTG driver for the Minimig Amiga core
; MiSTer specific version

; Adapted by Alastair M. Robinson from a similar project
; for the Replay board - WWW.FPGAArcade.COM

; Replay.card - P96 RTG driver for the REPLAY Amiga core
; Copyright (C) FPGAArcade community
;
; Contributors : Jakub Bednarski, Mike Johnson, Jim Drew, Erik Hemming, Nicolas Hamel
;
; This software is licensed under LPGLv2.1 ; see LICENSE file


; 0.1 - Cut down to the bare bones...

        machine 68020

        include P96/P96BoardInfo.i
        include P96/P96ModeInfo.i
        include P96/P96CardStruct.i

        include hardware/custom.i
        include hardware/intbits.i
        include exec/exec.i
        include lvo/exec_lib.i

; If you define the Debug Symbol make sure the monitor file is in
; sys:storage/monitors - debug output seems to crash the system if
; it happens during startup.

;debug

;HasBlitter
;blitterhistory
;HasSprite

beacon:
        move.l  #8191,d0
.loop
        move.w  d0,$dff180
        dbf     d0,.loop
        rts

BUG MACRO
        IFD     debug

        ifnc    "","\9"
        move.l  \9,-(sp)
        endc
        ifnc    "","\8"
        move.l  \8,-(sp)
        endc
        ifnc    "","\7"
        move.l  \7,-(sp)
        endc
        ifnc    "","\6"
        move.l  \6,-(sp)
        endc
        ifnc    "","\5"
        move.l  \5,-(sp)
        endc
        ifnc    "","\4"
        move.l  \4,-(sp)
        endc
        ifnc    "","\3"
        move.l  \3,-(sp)
        endc
        ifnc    "","\2"
        move.l  \2,-(sp)
        endc

        jsr     bugprintf

        dc.b    \1,$d,$a,0
        even

        adda.w  #(NARG-1)*4,sp

        ENDC
        ENDM

****************************************************************************
;       section ReplayRTG,code
****************************************************************************
MEMORY_SIZE   EQU $800000   ; 8MB framebuffer
MEMORY_BASE   EQU $02000000
REGISTER_BASE EQU $b80100

FB_BASE EQU $27000000 ; MiSTer physical memory address

; B80100:B80101 :  8:0 : ADDR[24:16]
; B80102:B80103 : 15:0 : ADDR[15:0]
; B80104:B80105 : 5:0  : FORMAT[5:0]
; B80106:B80107 :    0 : ENABLE
; B80108:B80109 : 11:0 : HSIZE
; B8010A:B8010B : 11:0 : VSIZE
; B8010C:B8010D : 13:0 : STRIDE
; B8010E:B8010F :  7:0 : ID = 50 / VERSION = 01

; B80400..B807FF CLUT : 256 * 32bits 00 / RR / GG / BB

REG_ADDRESS EQU 0
REG_FORMAT  EQU 4
REG_ENABLE  EQU 6
REG_HSIZE   EQU 8
REG_VSIZE   EQU 10
REG_STRIDE  EQU 12
REG_ID      EQU 14
REG_PALETTE EQU $300

;------------------------------------------------------------------------------
ProgStart:
;------------------------------------------------------------------------------

        moveq   #-1,d0
        rts

        IFD     debug
        bra.b   _bugprintf_end
bugprintf:
        movem.l d0-d1/a0-a3/a6,-(sp)
        move.l  $4.w,a6
        move.l  28(sp),a0
        lea     32(sp),a1
        lea     .putch(pc),a2
        move.l  a6,a3
        jsr     beacon
        jsr     -522(a6)                ; _LVORawDoFmt

.skip   move.l  28(sp),a0
.end:   move.b  (a0)+,d0
        bne.b   .end
        move.l  a0,d0
        addq.l  #1,d0
        and.l   #$fffffffe,d0
        move.l  d0,28(sp)
        movem.l (sp)+,d0-d1/a0-a3/a6
        rts

.putch: move.l	a6,-(sp)
        move.l  a3,a6
        jmp     -516(a6)                ; _LVORawPutChar (execPrivate9)
        move.l	(sp)+,a6
_bugprintf_end:
        rts
        ENDC

;------------------------------------------------------------------------------
RomTag:
;------------------------------------------------------------------------------

        dc.w    RTC_MATCHWORD
        dc.l    RomTag
        dc.l    ProgEnd
        dc.b    RTF_AUTOINIT    ;RT_FLAGS
        dc.b    1               ;RT_VERSION
        dc.b    NT_LIBRARY      ;RT_TYPE
        dc.b    0               ;RT_PRI
        dc.l    MinimigCard
        dc.l    IDString
        dc.l    InitTable
CardName:
        dc.b    'MiSTer',0
MinimigCard:
        dc.b    'MiSTer.card',0,0
        dc.b    '$VER: '
IDString:
        dc.b    'MiSTer.card 0.1 (19.Oct.2020)',0
        dc.b    0
expansionLibName:
        dc.b    'expansion.library',0
intuitionLibName:
        dc.b    'intuition.library',0
        cnop    0,4

InitTable:
        dc.l    CARD_SIZEOF     ;DataSize
        dc.l    FuncTable       ;FunctionTable
        dc.l    DataTable       ;DataTable
        dc.l    InitRoutine
FuncTable:
        dc.l    Open
        dc.l    Close
        dc.l    Expunge
        dc.l    ExtFunc
        dc.l    FindCard
        dc.l    InitCard
        dc.l    -1
DataTable:
        INITBYTE        LN_TYPE,NT_LIBRARY
        INITBYTE        LN_PRI,206
        INITLONG        LN_NAME,MinimigCard
        INITBYTE        LIB_FLAGS,LIBF_SUMUSED|LIBF_CHANGED
        INITWORD        LIB_VERSION,1
        INITWORD        LIB_REVISION,0
        INITLONG        LIB_IDSTRING,IDString
        INITLONG        CARD_NAME,CardName
        dc.w            0,0

;------------------------------------------------------------------------------
InitRoutine:
;------------------------------------------------------------------------------

;       BUG "Minimig.card InitRoutine()"

        movem.l a5,-(sp)
        movea.l d0,a5
        move.l  a6,CARD_EXECBASE(a5)
        move.l  a0,CARD_SEGMENTLIST(a5)
        lea     expansionLibName(pc),a1
        moveq   #0,d0
        jsr     _LVOOpenLibrary(a6)

        move.l  d0,CARD_EXPANSIONBASE(a5)
        beq.s   .fail

        lea     intuitionLibName(pc),a1
        moveq   #0,d0
        jsr     _LVOOpenLibrary(a6)
        move.l  d0,CARD_INTUITIONBASE(a5)
        bne.s   .exit

.fail
        movem.l d7/a5/a6,-(sp)
        move.l  #(AT_Recovery|AG_OpenLib|AO_ExpansionLib),d7
        movea.l $4.w,a6
        jsr     _LVOAlert(a6)

        movem.l (sp)+,d7/a5/a6
.exit:
        move.l  a5,d0
        movem.l (sp)+,a5
        rts

;------------------------------------------------------------------------------
Open:
;------------------------------------------------------------------------------

        addq.w  #1,LIB_OPENCNT(a6)
        bclr    #3,CARD_FLAGS(a6)

        IFD blitterhistory
        move.l  a0,-(sp)
        lea     $80000,a0
        moveq.l #16,d0
.fill:
        clr.l   (a0)+
        dbra    d0,.fill

        move.l  (sp)+,a0
        ENDC

        move.l  a6,d0
        rts

;------------------------------------------------------------------------------
Close:
;------------------------------------------------------------------------------

        moveq   #0,d0
        subq.w  #1,LIB_OPENCNT(a6)
        bne.b   .exit

        btst    #3,CARD_FLAGS(a6)
        beq.b   .exit

        bsr.b   Expunge

.exit:
        rts

;------------------------------------------------------------------------------
Expunge:
;------------------------------------------------------------------------------

        movem.l d2/a5/a6,-(sp)
        movea.l a6,a5
        movea.l CARD_EXECBASE(a5),a6
        tst.w   LIB_OPENCNT(a5)
        beq.b   .remove

        bset    #3,CARD_FLAGS(a5)
        moveq   #0,d0
        bra.b   .exit

.remove:
        move.l  CARD_SEGMENTLIST(a5),d2
        movea.l a5,a1
        jsr     _LVORemove(a6)

        movea.l CARD_EXPANSIONBASE(a5),a1
        jsr     _LVOCloseLibrary(a6)

        moveq   #0,d0
        movea.l a5,a1
        move.w  LIB_NEGSIZE(a5),d0
        suba.l  d0,a1
        add.w   LIB_POSSIZE(a5),d0
        jsr     _LVOFreeMem(a6)

        move.l  d2,d0
.exit:
        movem.l (sp)+,d2/a5/a6
        rts

;------------------------------------------------------------------------------
ExtFunc:
;------------------------------------------------------------------------------

        moveq   #0,d0
        rts

;------------------------------------------------------------------------------
FindCard:
;------------------------------------------------------------------------------
;  BOOL FindCard(struct BoardInfo *bi)
;

;  FindCard is called in the first stage of the board initialisation and
;  configuration and is used to look if there is a free and unconfigured
;  board of the type the driver is capable of managing. If it finds one,
;  it immediately reserves it for use by Picasso96, usually by clearing
;  the CDB_CONFIGME bit in the flags field of the ConfigDev struct of
;  this expansion card. But this is only a common example, a driver can
;  do whatever it wants to mark this card as used by the driver. This
;  mechanism is intended to ensure that a board is only configured and
;  used by one driver. FindBoard also usually fills some fields of the
;  BoardInfo struct supplied by the caller, the rtg.library, for example
;  the MemoryBase, MemorySize and RegisterBase fields.

        move.l  #MEMORY_SIZE  ,PSSO_BoardInfo_MemorySize(a0)
        move.l  #REGISTER_BASE,PSSO_BoardInfo_RegisterBase(a0)
        move.l  #MEMORY_BASE  ,PSSO_BoardInfo_MemoryBase(a0)
        
        moveq   #-1,d0
        rts

;------------------------------------------------------------------------------
InitCard:
;------------------------------------------------------------------------------
;  a0:  struct BoardInfo

        movem.l a2/a5/a6,-(sp)
        movea.l a0,a2

        lea     CardName(pc),a1
        move.l  a1,PSSO_BoardInfo_BoardName(a2)
        move.l  #10,PSSO_BoardInfo_BoardType(a2)
        move.l  #0,PSSO_BoardInfo_GraphicsControllerType(a2)
        move.l  #0,PSSO_BoardInfo_PaletteChipType(a2)

        ori.w   #2,PSSO_BoardInfo_RGBFormats(a2)   ; CLUT
        ori.w   #8,PSSO_BoardInfo_RGBFormats(a2)   ; RGBFB_B8G8R8
        ori.w   #16,PSSO_BoardInfo_RGBFormats(a2)  ; RGBFB_R5G6B5PC 
        ori.w   #256,PSSO_BoardInfo_RGBFormats(a2) ; RGBFB_R8G8B8A8
        
        move.w  #8,PSSO_BoardInfo_BitsPerCannon(a2)
        move.l  #MEMORY_SIZE-$40000,PSSO_BoardInfo_MemorySpaceSize(a2)
        move.l  PSSO_BoardInfo_MemoryBase(a2),d0
        move.l  d0,PSSO_BoardInfo_MemorySpaceBase(a2)
        addi.l  #MEMORY_SIZE-$4000,d0
        move.l  d0,PSSO_BoardInfo_MouseSaveBuffer(a2)
        
        ori.l   #(1<<20),PSSO_BoardInfo_Flags(a2)       ; BIF_INDISPLAYCHAIN
        ;ori.l   #(1<<1),PSSO_BoardInfo_Flags(a2)        ; BIF_NOMEMORYMODEMIX

        lea     SetSwitch(pc),a1
        move.l  a1,PSSO_BoardInfo_SetSwitch(a2)
        lea     SetDAC(pc),a1
        move.l  a1,PSSO_BoardInfo_SetDAC(a2)
        lea     SetGC(pc),a1
        move.l  a1,PSSO_BoardInfo_SetGC(a2)
        lea     SetPanning(pc),a1
        move.l  a1,PSSO_BoardInfo_SetPanning(a2)
        lea     CalculateBytesPerRow(pc),a1
        move.l  a1,PSSO_BoardInfo_CalculateBytesPerRow(a2)
        lea     CalculateMemory(pc),a1
        move.l  a1,PSSO_BoardInfo_CalculateMemory(a2)
        lea     GetCompatibleFormats(pc),a1
        move.l  a1,PSSO_BoardInfo_GetCompatibleFormats(a2)
        lea     SetColorArray(pc),a1
        move.l  a1,PSSO_BoardInfo_SetColorArray(a2)
        lea     SetDPMSLevel(pc),a1
        move.l  a1,PSSO_BoardInfo_SetDPMSLevel(a2)
        lea     SetDisplay(pc),a1
        move.l  a1,PSSO_BoardInfo_SetDisplay(a2)
        lea     SetMemoryMode(pc),a1
        move.l  a1,PSSO_BoardInfo_SetMemoryMode(a2)
        lea     SetWriteMask(pc),a1
        move.l  a1,PSSO_BoardInfo_SetWriteMask(a2)
        lea     SetReadPlane(pc),a1
        move.l  a1,PSSO_BoardInfo_SetReadPlane(a2)
        lea     SetClearMask(pc),a1
        move.l  a1,PSSO_BoardInfo_SetClearMask(a2)
        lea     WaitVerticalSync(pc),a1
        move.l  a1,PSSO_BoardInfo_WaitVerticalSync(a2)
;       lea     (Reserved5,pc),a1
;       move.l  a1,(PSSO_BoardInfo_Reserved5,a2)
        lea     SetClock(pc),a1
        move.l  a1,PSSO_BoardInfo_SetClock(a2)
        lea     ResolvePixelClock(pc),a1
        move.l  a1,PSSO_BoardInfo_ResolvePixelClock(a2)
        lea     GetPixelClock(pc),a1
        move.l  a1,PSSO_BoardInfo_GetPixelClock(a2)

;        lea     AllocCardMem(pc),a1
;        move.l  a1,PSSO_BoardInfo_AllocCardMem(a2)
;        lea     FreeCardMem(pc),a1
;        move.l  a1,PSSO_BoardInfo_FreeCardMem(a2)

        move.l  #113440000,PSSO_BoardInfo_MemoryClock(a2)

        move.l  #1,(PSSO_BoardInfo_PixelClockCount+0,a2)
        move.l  #1,(PSSO_BoardInfo_PixelClockCount+4,a2)
        move.l  #1,(PSSO_BoardInfo_PixelClockCount+8,a2)
        move.l  #1,(PSSO_BoardInfo_PixelClockCount+12,a2)
        move.l  #1,(PSSO_BoardInfo_PixelClockCount+16,a2)
;- Planar
;- Chunky
;- HiColor
;- Truecolor
;- Truecolor + Alpha

        move.w  #4095,(PSSO_BoardInfo_MaxHorValue+0,a2)
        move.w  #4095,(PSSO_BoardInfo_MaxVerValue+0,a2)
        move.w  #4095,(PSSO_BoardInfo_MaxHorValue+2,a2)
        move.w  #4095,(PSSO_BoardInfo_MaxVerValue+2,a2)
        move.w  #4095,(PSSO_BoardInfo_MaxHorValue+4,a2)
        move.w  #4095,(PSSO_BoardInfo_MaxVerValue+4,a2)
        move.w  #4095,(PSSO_BoardInfo_MaxHorValue+6,a2)
        move.w  #4095,(PSSO_BoardInfo_MaxVerValue+6,a2)
        move.w  #4095,(PSSO_BoardInfo_MaxHorValue+8,a2)
        move.w  #4095,(PSSO_BoardInfo_MaxVerValue+8,a2)

        move.w  #2048,(PSSO_BoardInfo_MaxHorResolution+0,a2)
        move.w  #2048,(PSSO_BoardInfo_MaxVerResolution+0,a2)
        move.w  #2048,(PSSO_BoardInfo_MaxHorResolution+2,a2)
        move.w  #2048,(PSSO_BoardInfo_MaxVerResolution+2,a2)
        move.w  #2048,(PSSO_BoardInfo_MaxHorResolution+4,a2)
        move.w  #2048,(PSSO_BoardInfo_MaxVerResolution+4,a2)
        move.w  #2048,(PSSO_BoardInfo_MaxHorResolution+6,a2)
        move.w  #2048,(PSSO_BoardInfo_MaxVerResolution+6,a2)
        move.w  #2048,(PSSO_BoardInfo_MaxHorResolution+8,a2)
        move.w  #2048,(PSSO_BoardInfo_MaxVerResolution+8,a2)

;        lea     PSSO_BoardInfo_HardInterrupt(a2),a1
;        lea     VBL_ISR(pc),a0
;        move.l  a0,IS_CODE(a1)
;        moveq   #INTB_VERTB,d0
;        move.l  $4,a6
;        jsr     _LVOAddIntServer(a6)

;       FIXME - disable vblank interrupt for now.
;       ori.l   #(1<<4),PSSO_BoardInfo_Flags(a2)        ; BIF_VBLANKINTERRUPT
;       lea     SetInterrupt(pc),a1
;       move.l  a1,PSSO_BoardInfo_SetInterrupt(a2)

        IFD     HasBlitter
        ori.l   #(1<<15),PSSO_BoardInfo_Flags(a2)       ; BIF_BLITTER
        lea     BlitRectNoMaskComplete(pc),a1
        move.l  a1,PSSO_BoardInfo_BlitRectNoMaskComplete(a2)
        lea     BlitRect(pc),a1
        move.l  a1,PSSO_BoardInfo_BlitRect(a2)
        lea     WaitBlitter(pc),a1
        move.l  a1,PSSO_BoardInfo_WaitBlitter(a2)
        ENDC

        IFD     HasSprite
        ori.l   #(1<<0),PSSO_BoardInfo_Flags(a2)        ; BIF_HARDWARESPRITE
        lea     SetSprite(pc),a1
        move.l  a1,PSSO_BoardInfo_SetSprite(a2)
        lea     SetSpritePosition(pc),a1
        move.l  a1,PSSO_BoardInfo_SetSpritePosition(a2)
        lea     SetSpriteImage(pc),a1
        move.l  a1,PSSO_BoardInfo_SetSpriteImage(a2)
        lea     SetSpriteColor(pc),a1
        move.l  a1,PSSO_BoardInfo_SetSpriteColor(a2)
        ENDC

        ori.l   #(1<<3),PSSO_BoardInfo_Flags(a2)        ; BIF_CACHEMODECHANGE
        move.l  PSSO_BoardInfo_MemoryBase(a2),(PSSO_BoardInfo_MemorySpaceBase,a2)
        move.l  PSSO_BoardInfo_MemorySize(a2),(PSSO_BoardInfo_MemorySpaceSize,a2)

        movea.l PSSO_BoardInfo_RegisterBase(a2),a0

        moveq   #-1,d0
.exit:
        movem.l (sp)+,a2/a5/a6
        rts

;------------------------------------------------------------------------------
SetSwitch:
;------------------------------------------------------------------------------
;  a0:  struct BoardInfo
;  d0.w:                BOOL state
;  this function should set a board switch to let the Amiga signal pass
;  through when supplied with a 0 in d0 and to show the board signal if
;  a 1 is passed in d0. You should remember the current state of the
;  switch to avoid unneeded switching. If your board has no switch, then
;  simply supply a function that does nothing except a RTS.
;
;  NOTE: Return the opposite of the switch-state. BDK

        move.w  PSSO_BoardInfo_MoniSwitch(a0),d1
        andi.w  #$FFFE,d1
        tst.b   d0
        beq.b   .off

        ori.w   #$0001,d1
.off:
        move.w  PSSO_BoardInfo_MoniSwitch(a0),d0
        cmp.w   d0,d1
        beq.b   .done

        move.w  d1,PSSO_BoardInfo_MoniSwitch(a0)

        andi.l  #$1,d1
        movea.l PSSO_BoardInfo_RegisterBase(a0),a0
        move.w  d1,REG_ENABLE(a0)
        BUG     "RTG:DisplaySwitch = %lx",d1
.done:
    ;   bsr.w   SetInterrupt
        andi.w  #$0001,d0
        rts

;------------------------------------------------------------------------------
SetDAC:
;------------------------------------------------------------------------------
;  a0: struct BoardInfo
;  d7: RGBFTYPE RGBFormat
;  This function is called whenever the RGB format of the display changes,
;  e.g. from chunky to TrueColor. Usually, all you have to do is to set
;  the RAMDAC of your board accordingly.

        movea.l PSSO_BoardInfo_RegisterBase(a0),a0
        move.w  .setdac_Format(pc,d7.l*2),d0
        move.w  d0,REG_FORMAT(a0)
        BUG     "RTG:DisplayFormat = %lx",d0
        rts

;  [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
;  [3]   : 0=16bits 565 1=16bits 1555
;  [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
;  [5]   : Swap Bytes

.setdac_Format:
        dc.w    3          ;  1    RGBFB_NONE      planar mode (the name is historical)
        dc.w    3      +32 ;+ 2    RGBFB_CLUT      palette mode, set colors when opening screen using tags or use SetRGB32/LoadRGB32(...)
        dc.w    5          ;  4    RGBFB_R8G8B8    TrueColor RGB (8 bit each)
        dc.w    5   +16+32 ;+ 8    RGBFB_B8G8R8    TrueColor BGR (8 bit each)
        dc.w    4   +16+32 ;+ 16   RGBFB_R5G6B5PC  HiColor16 (5 bit R, 6 bit G, 5 bit B), format: gggbbbbbrrrrrggg
        dc.w    4 +8       ;  32   RGBFB_R5G5B5PC  HiColor15 (5 bit each), format: gggbbbbb0rrrrrgg
        dc.w    6          ;  64   RGBFB_A8R8G8B8  4 Byte TrueColor ARGB (A unused alpha channel)
        dc.w    6   +16    ;  128  RGBFB_A8B8G8R8  4 Byte TrueColor ABGR (A unused alpha channel)
        dc.w    6      +32 ;+ 256  RGBFB_R8G8B8A8  4 Byte TrueColor RGBA (A unused alpha channel)
        dc.w    6   +16    ;  512  RGBFB_B8G8R8A8  4 Byte TrueColor BGRA (A unused alpha channel)
        dc.w    4          ;  1024 RGBFB_R5G6B5    HiColor16 (5 bit R, 6 bit G, 5 bit B), format: rrrrrggggggbbbbb
        dc.w    4 +8       ;  2048 RGBFB_R5G5B5    HiColor15 (5 bit each), format: 0rrrrrgggggbbbbb
        dc.w    4          ;  4096 RGBFB_B5G6R5PC  HiColor16 (5 bit R, 6 bit G, 5 bit B), format: gggrrrrrbbbbbggg
        dc.w    4 +8+16    ;  8192 RGBFB_B5G5R5PC  HiColor15 (5 bit each), format: gggrrrrr0bbbbbbgg
        
;------------------------------------------------------------------------------
SetGC:
;------------------------------------------------------------------------------
;  a0: struct BoardInfo
;  a1: struct ModeInfo
;  d0: BOOL Border
;  This function is called whenever another ModeInfo has to be set. This
;  function simply sets up the CRTC and TS registers to generate the
;  timing used for that screen mode. You should not set the DAC, clocks
;  or linear start adress. They will be set when appropriate by their
;  own functions.

; For MiSTer, just set image size

        move.l  a1,PSSO_BoardInfo_ModeInfo(a0)
        movea.l PSSO_BoardInfo_RegisterBase(a0),a0

        move.w  PSSO_ModeInfo_Width(a1),d0
        moveq   #0,d1
        move.b  PSSO_ModeInfo_Depth(a1),d1
        addq.w  #7,d1
        lsr.w   #3,d1
        mulu.w  d1,d0
        move.w  d0,REG_STRIDE(a0)
        BUG     "RTG:BytesPerLine = %lx",d0
        
        move.w  PSSO_ModeInfo_Width(a1),d0
        move.w  d0,REG_HSIZE(a0)
        BUG     "RTG:HSIZE = %lx",d0
        
        move.w  PSSO_ModeInfo_Height(a1),d0
        move.w  d0,REG_VSIZE(a0)
        BUG     "RTG:VSIZE = %lx",d0
                
        rts

;------------------------------------------------------------------------------
SetPanning:
;------------------------------------------------------------------------------
;  a0: struct BoardInfo
;  a1: UBYTE* Memory
;  d0: WORD Width
;  d1: WORD XOffset
;  d2: WORD YOffset
;  d7: RGBFTYPE RGBFormat
;  This function sets the view origin of a display which might also be
;  overscanned. In register a1 you get the start address of the screen
;  bitmap on the Amiga side. You will have to subtract the starting
;  address of the board memory from that value to get the memory start
;  offset within the board. Then you get the offset in pixels of the
;  left upper edge of the visible part of an overscanned display. From
;  these values you will have to calculate the LinearStartingAddress
;  fields of the CRTC registers.

        movea.l PSSO_BoardInfo_RegisterBase(a0),a0
        move.l  a1,d0
        sub.l   #MEMORY_BASE,d0
        add.l   #FB_BASE,d0
        BUG     "RTG:ADDRESS = %lx",d0
        move.l  d0,REG_ADDRESS(a0)
        rts
        
;------------------------------------------------------------------------------
CalculateBytesPerRow:
;------------------------------------------------------------------------------
;  a0:  struct BoardInfo
;  d0:  uae_u16 Width
;  d7:  RGBFTYPE RGBFormat
;  This function calculates the amount of bytes needed for a line of
;  "Width" pixels in the given RGBFormat.

        cmpi.l  #16,d7
        bcc.b   .exit

        move.w  .base(pc,d7.l*2),d1
        jmp     .base(pc,d1.w)

.base:
        dc.w    .pp_1Bit-.base
        dc.w    .pp_1Byte-.base
        dc.w    .pp_3Bytes-.base
        dc.w    .pp_3Bytes-.base
        dc.w    .pp_2Bytes-.base
        dc.w    .pp_2Bytes-.base
        dc.w    .pp_4Bytes-.base
        dc.w    .pp_4Bytes-.base
        dc.w    .pp_4Bytes-.base
        dc.w    .pp_4Bytes-.base
        dc.w    .pp_2Bytes-.base
        dc.w    .pp_2Bytes-.base
        dc.w    .pp_2Bytes-.base
        dc.w    .pp_2Bytes-.base
        dc.w    .pp_2Bytes-.base
        dc.w    .pp_1Byte-.base

.pp_4Bytes:
        add.w   d0,d0
.pp_2Bytes:
        add.w   d0,d0
        bra.b   .exit

.pp_3Bytes:
        move.w  d0,d1
        add.w   d0,d1
        add.w   d1,d0
        bra.b   .exit

.pp_1Bit:
        lsr.w   #3,d0

.pp_1Byte:

.exit:
        rts

;------------------------------------------------------------------------------
CalculateMemory:
;------------------------------------------------------------------------------

        move.l  a1,d0
        rts

;------------------------------------------------------------------------------
SetColorArray:
;------------------------------------------------------------------------------
;  a0: struct BoardInfo
;  d0.w: startindex
;  d1.w: count
;  when this function is called, your driver has to fetch "count" color
;  values starting at "startindex" from the CLUT field of the BoardInfo
;  structure and write them to the hardware. The color values are always
;  between 0 and 255 for each component regardless of the number of bits
;  per cannon your board has. So you might have to shift the colors
;  before writing them to the hardware.

;       BUG     "SetColorArray ( %ld / %ld )",d0,d1

        lea     PSSO_BoardInfo_CLUT(a0),a1
        movea.l PSSO_BoardInfo_RegisterBase(a0),a0

        lea     (a1,d0.w),a1
        lea     (a1,d0.w*2),a1
        adda.l  #REG_PALETTE,a0
        lea     (a0,d0.w*4),a0

        bra.b   .sla_loop_end

.sla_loop:
        moveq   #0,d0
        move.b  (a1)+,d0
        lsl.w   #8,d0
        move.b  (a1)+,d0
        lsl.l   #8,d0
        move.b  (a1)+,d0

        move.l  d0,(a0)+
.sla_loop_end
        dbra    d1,.sla_loop

        rts

;------------------------------------------------------------------------------
SetDPMSLevel:
;------------------------------------------------------------------------------

        rts

;------------------------------------------------------------------------------
SetDisplay:
;------------------------------------------------------------------------------
;  a0:  struct BoardInfo
;  d0:  BOOL state
;  This function enables and disables the video display.
;
;  NOTE: return the opposite of the state

        BUG "SetDisplay %ld",d0
        not.b   d0
        andi.w  #1,d0
        rts

;------------------------------------------------------------------------------
SetMemoryMode:
;------------------------------------------------------------------------------

        rts

;------------------------------------------------------------------------------
SetWriteMask:
;------------------------------------------------------------------------------

        rts

;------------------------------------------------------------------------------
SetReadPlane:
;------------------------------------------------------------------------------

        rts

;------------------------------------------------------------------------------
SetClearMask:
;------------------------------------------------------------------------------

        move.b  d0,PSSO_BoardInfo_ClearMask(a0)
        rts

;------------------------------------------------------------------------------
WaitVerticalSync:
;------------------------------------------------------------------------------
;  a0:  struct BoardInfo
;  This function waits for the next horizontal retrace.
        BUG     "WaitVerticalSync"

; On minimig can simply use VPOSR for this

.wait_done:
        rts

;------------------------------------------------------------------------------
Reserved5:
;------------------------------------------------------------------------------
;       BUG     "Reserved5"

;       movea.l PSSO_BoardInfo_RegisterBase(a0),a0
;       btst.b  #7,VDE_DisplayStatus(a0)        ;Vertical retrace
;       sne     d0
;       extb.l  d0
        rts

;------------------------------------------------------------------------------
SetClock:
;------------------------------------------------------------------------------

;       MiSTer framebuffer : Not used
        rts

;------------------------------------------------------------------------------
ResolvePixelClock:
;------------------------------------------------------------------------------
; ARGS:
;       d0 - requested pixel clock frequency
; RESULT:
;       d0 - pixel clock index

;       MiSTer framebuffer : Not used

        move.l  #100000000,PSSO_ModeInfo_PixelClock(a1)
        moveq   #1,d0
        rts

;------------------------------------------------------------------------------
GetPixelClock:
;------------------------------------------------------------------------------
        move.l  #100000000,d0
        rts

;------------------------------------------------------------------------------
SetInterrupt:
;------------------------------------------------------------------------------

;       bchg.b  #1,$bfe001

;       movea.l PSSO_BoardInfo_RegisterBase(a0),a1
;       tst.b   d0
;       beq.b   .disable

;       move.w  VDE_InterruptEnable(a1),d0
;       bne.b   .done

;       move.w  #$0001,VDE_InterruptEnable(a1)
;       BUG     "VDE_InterruptEnable = $0001"

.done:  rts

;.disable:
;       move.w  VDE_InterruptEnable(a1),d0
;       beq.b   .done

;       move.w  #$0000,VDE_InterruptEnable(a1)
;       BUG     "VDE_InterruptEnable = $0000"
;       bra.b   .done

;------------------------------------------------------------------------------
VBL_ISR:
;------------------------------------------------------------------------------

        moveq   #0,d0
        rts

;------------------------------------------------------------------------------
GetCompatibleFormats:
;------------------------------------------------------------------------------

        moveq   #-1,d0
        rts

;==============================================================================

ProgEnd:
        end
