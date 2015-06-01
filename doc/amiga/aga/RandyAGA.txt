                ________ ____________  ____________________
                \_ ____/ \______ \__ \/   \_____ \   |    /
                /   \  /\/    é/  \        \  é/  \_    _/
               /     \/  \        /  \/    /       \     \
               \_________/\______/   é____å___Ä____/ é____ç
               ∑∑∑∑(G°Ve$ •a':)∑\____è∑∑∑∑∑∑∑∑∑å_____è∑∑bZr

--------- RANDY of COMAX presents the AGA doc (V2.5) for AGA CODERS ----------

                        Programming AGA hardware
                      ===========================

Future Amigas will *NOT* support *ANY* of the new AGA registers.
If you want your product to work on the next generation
of Amigas then detect aga before of run, and if is not present exit
or use ECS, that will be supported as emulation in the new C= low-end
and high-end machines. That machines will have probably a totally new
ChipSet, without any $dffXXX register, and probably not bitplane system.

Even the processor isn't necessarily final. It is strongly
rumoured that the Motorola MC68060 is the final member of the
68000 series, and may not even come out. Expect Amigas in 2-3
years to come with RISC chip processors running 680x0 emulation.

This is my AGA detect routine 101%... (thanx to DDT/HBT for the last 1%)
It will detect AGA on the future updated AGA machines.
Instead making a CMPI.B #$f8,$dff07c on that new AGA machines only old chipset
will be detected!!!!

	LEA	$DFF000,A5
	MOVE.W	$7C(A5),D0	; DeniseID or LisaID in AGA
	MOVEQ	#30,D2		; Check 30 times ( prevents old denise random)
	ANDI.W	#%000000011111111,d0	; low byte only
DENLOOP:
	MOVE.W	$7C(A5),D1	; Denise ID (LisaID on AGA)
	ANDI.W	#%000000011111111,d1	; low byte only
	CMP.B	d0,d1		; same value?
	BNE.S	NOTAGA		; Not the same value, then OCS Denise!
	DBRA	D2,DENLOOP	; (THANX TO DDT/HBT FOR MULTICHECK HINT)
	ORI.B	#%11110000,D0	; MASK AGA REVISION (will work on new aga)
	CMPI.B	#%11111000,D0	; BIT 3=AGA (this bit will be=0 in AAA!)
	BNE.S	NOTAGA		; IS THE AGA CHIPSET PRESENT?
	ST.B	AGA 		; Set the AGA flag that will be tested later
NOTAGA:				; NOT AGA, BUT IS POSSIBLE AN AAA MACHINE!!

I have an A4000 at home and I needed to fix 3 or more AGA demos to work on
it, because them said: YOU NEED AN AGA MACHINE (!!)... that demos are:
NOP 1/muffbusters, RedNexRevivalIntro (for a bad processor test) and others..

New AGA features:

More Bitplanes - The maximum number of bitplanes has increased to 8 in all
resolution modes.  This translates to a 256 entry color table for each
available mode.

Enhanced Dual Playfield Support - Each playfield may now have up to 4
bitplanes.  The bank of 16 colors in the 256 color table is independently
selectable for each playfield.

Larger Palette - Each entry in the color table may now be 25 bits wide (8
bits each for Red, Blue, and Green data -- plus 1 bit for genlock
information).  This translates to a palette of 16,777,216 colors.

Enhanced Sprite Support - Sprite resolution can be set to lores, hires, or
super-hires, independent of screen resolution.  Attached sprites are now
available in all modes.  However, some new higher bandwidth modes may
only allow one sprite.  Odd and even sprites may use their own independent
16 color bank from the 256 color table.  Old format sprites may still be 16
bits wide, and new format sprites may be 32 or 64 bits wide.  Sprites may
now optionally appear in the border region.  The horizontal positioning
resolution of sprites has increased to 35ns (equivalent to super-hires
pixel widths.)

Enhanced hardware scrolling support - Two extra bits in $dff102
allow seamless scrolling of up to 64 bit wide bitplanes in all resolutions.
The resolution of bitplane scrolling has been increased to 35ns.

Hardware scan doubling support - 15khz bitplanes and sprites may now be
scan doubled for flicker free display on 31khz monitors, and for enhanced
display sharing with 31khz bitplanes.

ECS compatibility - New chips will power-up in an ECS compatibility mode,
which will allow many older self-booting programs to be run on new machines.
This is done with $dff1fc (FMODE):  $0003 = FULL AGA 64 bit Fetch
				    $0000 = ECS COMPATIBILITY (16 bits)
When using 4 or 8-bit R/G/B values, scale your values to 32 bits by
duplicating your 8 bit value in all 4 bytes of the 32 bit value.
When scaling up a 4 bit value, duplicate it in all nibbles.
e.g.:   8-bit red value $1F becomes $1F1F1F1F;
    4-bit red value $3  becomes $33333333;

ECSENA bit (formerly ENBPLCN3) is used to disable those register bits in
BPLCON3 that are never accessed by old copper lists, and in addition are
required by old style copper lists to be in their default
settings.Specifically ECSENA forces the following bits to their default low
settings: BRDRBLNK,BRDNTRAN,ZDCLKEN,EXTBLKEN, and BRDRSPRT.

CLXCON2 is reset by a write to CLXCON, so that old game programs will be
able to correctly detect collisions.

DIWHIGH is reset by writes to DIWSTRT or DIWSTOP. This is interlock is
inhertied from ECS Denise.

Important note about NUMBER OF COLORS:  Older IFF code (even earlier
newiff code) would not load more than 32 color registers.  The
new code has been updated to base its upper limit for color loading
on the ColorMap->Count of the ViewPort of the destination display.
Remove old limitations of 32 registers in your code, and replace
by limiting to ColorMap->Count registers.

Horizontal Comparators	(from C-18 AGA Doc)
----------------------
All programmable comparators with the exception of VHPOSW have 35nSec
resolution.: DIWHIGH,HBSTOP,SPRCTL,BPLCON1. BPLCON1 has additional
high-order bits as well. Note that horizontal bit position representing
140nSec resolution has been changed to 3rd least significant bit,where
before it used to be a field`s LSB, For example, bit 00 in BPLCON1 used to
be named PF1H0 and now it`s called PF1H2.

Coercion of 15KHz to 31KHz:
---------------------------
We have added new hardware features to LISA to aid in properly displaying
15KHz and 31KHz viewports together on the same 31KHz display. LISA can
globally set sprite resolution to LORES,HIRES, or SHRES.
LISA will ignore SH10 compare bits in SPRxPOS when scan-doubling, thereby
allowing ALICE to use these bits individually set scan-doubling.

Note: There is no longer any need to "scramble" SHRES color table entries. 
This artifice is no longer required and pepole who bypass ECS graphics
library calls to do their own 28MHz graphics are to be pointed at and
publicly humiliated.

***************************************************************************

To make a standard Amiga demo run on AGA chipset:

 Please insert the followings lines in your copperlist:

	dc.w	$106,$c00	;AGA sprites, palette and dual playfield reset
	dc.w	$1FC,0		;AGA sprites and burst reset

And remember to set $108, $10a, $8e and $90 or you will get the WB values!
***************************************************************************

Previously impossible deeper modes:

Table 1:  New ALICE Modes (In Addition to Modes Supported by ECS)

Mode		Planes	Colors			Bandwidth (See note 1)
----		------	------			----------------------
LORES (320x200)	6	64 (non HAM, non EHB)	1 (set KillEHB!)
		7	128			1
		8	256			1
		8	HAM 256,000+(see note 2)1

Dual playfield, Max 4 bitplane per playfield 16 colours per playfield.
The bank of 16 colours in the 256 colour palette is selectabel per playfield.

-------------------------------------------------------------------------------

HIRES (640x200)	5	32			2
		6	EHB 64 (see note 3)	2
		6	HAM 4096 (see note 4)	2
		6	64	(set killEHB)	2
		7	128			2
		8	256			2
		8	HAM 256,000+(see note 2)2

Dual playfield, Max 4 bitplane per playfield 16 colours per playfield.
The bank of 16 colours in the 256 colour palette is selectabel per playfield.

-------------------------------------------------------------------------------

SUPERHIRES (1280x200)
		1	2 (see note 5)		1
		2	4 (see note 5)		1
		3	8			2
		4	16			2
		5	32			4
		6	EHB 64 (see note 3)	4
		6	HAM 4096 (see note 4)	4
		6	64  (set KillEHB)	4
		7	128			4
		8	256			4
		8	HAM 256,000+(see note 2)4

Dual playfield, Max 4 bitplane per playfield 16 colours per playfield.
The bank of 16 colours in the 256 colour palette is selectabel per playfield.

-------------------------------------------------------------------------------

VGA  (160,320,640x480 non-int. 31Khz - multiscan or VGA monitor needed)

		1	2 (see note 5)		1
 		2	4 (see note 5)		1
 		3	8			2
		4	16			2
		5	32			4
		6	EHB 64 (see note 3)	4
		6	HAM 4096 (see note 4)	4
		6	64  (set KillEHB)	4
		7	128			4
		8	256			4
		8	HAM 256,000+(see note 2)4

Dual playfield, Max 4 bitplane per playfield 16 colours per playfield.
The bank of 16 colours in the 256 colour palette is selectabel per playfield.

-------------------------------------------------------------------------------

	Super 72 (848x614 interlaced, 70 Hz frame rate)     BANDWIDTH
	-----------------------------------------------	   -----------
	
	1 or 2 bitplanes, as ECS, but no colour fudging		1X
	3 Bitplanes		8 colours			2X
	4 Bitplanes		16 colours			2X
	5 Bitplanes		32 colours			4X
	6 Bitplanes		64 colours (Set	KillEHB)	4X
	7 Bitplanes		128 colours			4X
	8 Bitplanes		256 colours			4X
	6 Bitplanes EHB		32 * 2 colours			4X
	6 Bitplanes HAM		4O96 colours			4X
	8 Bitplanes HAM         any of 2~24 colours		4X

	Dual playfield,Max 4 bitplanes per playfield		2X or 4X
	16 colours per playfield . The bank of 16 colours
	in the 256 colour palette is selectable per playfield

Notes:
1 - The "Bandwidth" number describes the amount of fetch bandwidth required
by a particular screen mode.  For example, a 5 bit deep VGA screen requires
the 4x bandwidth fetch mode while a 1 bit VGA screen requires only the 1x
mode..  This translates to the hardware having to move data 4 times faster.
To be able to move data at these higher rates, the higher bandwidth modes
require data to be properly aligned in CHIP memory that is fast enough to
support the bandwidth.  Specifically, bandwidth fetch mode factors of 1
require data to be on 16 bit boundaries, factors of 2 require 32 bit
boundaries, and factors of 4 require 64 bit boundaries.  Restrictions like
these are the best reason to use the system allocation functions whenever
data is being prepared for the custom hardware.  It is not guaranteed that
all machines that have the new chipset will also have memory fast enough
for the 4x modes.  Therefore, the ONLY way to know whether or not the
machine will support the mode you want is to check the Display Database.
* BANDWIDTH 1: MOVE.W	#0,$DFF1FC
* BANDWIDTH 2: MOVE.W	#2,$DFF1FC	;THEN BITMAPS 32 BIT ALIGNED AND
					;MODULO = MODULO-4
* BANDWIDTH 4: MOVE.W	#3,$DFF1FC	;THEN BITMAPS 64 BIT ALIGNED AND
					;MODULO = MODULO-8

This table only shows the minimum required fetchmode (bandwidth) for each
screen mode.
You should always try and set the fetchmode as high as possible (if
you are 64-bit aligned and wide, then $11, if 32-bit aligned and wide
$01, etc...)

2 - New 8 bit HAM mode uses the upper 6 bits for 64 24-bit base register
colors or as a 6 bit modify value, plus the lower 2 bits for 18 bit hold or
modify mode control.  This mode could conceivably allow simultaneous
display of more than 256,000 colors (up to 16.8 million, presuming a
monitor / screenmode with enough pixels.)  Please note that while the
register planes and control planes are internally reversed in 8 bit HAM
(the control bits are the two LSBs instead of the two MSBs),  programs
using graphics.library and intuition.library will not have to deal with
this reversal, as it will be handled automatically for them.

3 - This is like the original EHB mode, but in new resolutions.  It uses 5
bits to yield 32 register colors, plus a sixth bit for 32 colors that are
1/2 as bright.

4 - This is like the original 6 bit Ham mode, but in new resolutions.  It
uses the lower 4 bits for 16 register colors, plus the upper 2 bits for
modify mode control.  This mode allows  simultaneous display of 4096
colors.

5 - These modes are unlike the old VGA and SUPERHIRES modes in that they
are not restricted to a nonstandard 64 color palette.

*******************************************************************************

What is HAM-8 Format? (from howtocode6)
---------------------

Ham-8 uses *lower* two bits as the command (either
new register (%00), or alter Red, Green or Blue component, as in
standard HAM), and the *upper* 6 bits (planes 2 to 7) as the
register(0 to 63), or as an 6 bit hold-and-modify value to modify
the top 6 bits of an 8-bit colour component.

The lower two bits of the colour component are not altered, so
initial palettes have to be chosen carefuly (or use Art
Department Professional! or anything that selects colours better)

*******************************************************************************
               
              From the OFFICIAL Advanced Amiga Chip Set (AA) Info.

                                AMIGA 1200

1. SUMMARY OF FEATURES FOR AA
-----------------------------

* 32 bit wide data bus supports input of 32-bit wide bitplane data and
  allows doubling of memory bandwidth. Additional doubling of bandwidth
  can be achieved by using Fast Page mode Ram. The same bandwidth
  enhancements are available for sprites. Also the maximum number of 
  bitplanes useable in all modes was increased to eight(8). 
  
* The Colour Palette has been expanded to 256 colors deep and 25 bits wide
  (8-RED, 8-GREEN, 8-BLUE, 1-GENLOCK). This permits display of 256
  simultaneous colors in all resolutions. A palette of 16,777,216 colours
  is available in all resolutions.

* 28Mhz clock input allows for cleaner definition of HIRES and SHRES pixels.
  ALICE's clock generator is sychronized by means of LISA's 14MHz SCLK
  outputs. Genlock XCLK and XCLKEN* pins have been eliminated (external
  MUX is now required).

* A new register bit allows sprites to appear in the screen border regions
  (BRDRSPRT). So you can move sprites also out the display window defined
  by DIWSTART and DIWSTOP, but remember to set also the bit 0 of $dff100
  (bit 1 of $dff106) 

* A bitplane mask field of 8-bits allows an address offset into the colour
  palette. Two 4-bit mask fields do the same for odd and even sprites.

* In Dual-Playfield modes, 2-4 bitplane playfields are now possible in all
  resolutions.

* Two Extra high-order playfield scroll bits allow seamless scrolling of
  up to 64 bit wide bitplanes in all resolutions. Resolution of bitplane
  scroll, display window, and horizontal sprite position has been improved
  to 35ns in all resolutions.

* A new 8 bitplane HAM mode has been created, 6 for colours and 2 for
  control bits. All HAM modes are available in all resolutions (not just
  LORES as before).

* A RST_input pin has been added, which resets all the bits contained in
  registers that were new for ECS or LISA:
  BPLCON3, BPLCON4, CLXCON2, DIWHIGH, FMODE

* Sprite resolution can be set to LORES, HIRES, SHRES, independant of
  bitplane resolution.

* Attached Sprites are now available in all resolutions.

* Hardware Scan Doubling support has been added for bitplanes and sprites.
  This is intended to allow 15KHz screens to be intelligently displayed
  on a 31KHz monitor, and share the display with 31KHz screens.


2. EXPLANATION OF NEW FEATURES
------------------------------

Bitplanes:
----------
There are now 8 bitplanes instead of 6. In single playfield modes they
can address 256 colours instead of just 64. As long as the memory 
architecture supports the bandwidth, all 8 bitplanes are available in all
3 resolutions. In the same vein, 4+4 bitplane dual playfield is available
in all 3 resolutions, unless bitplane scan-doubling is enabled, in which
case both playfields share the same bitplane modulus register. Bits 15 thru
8 of BPLCON4 comprise an 8-bit mask for the 8 bitplane address, XOR'ing the
individual bits. This allows the copper to exchange colour maps with a 
single instruction. BPLCON1 now contains an 8-bit scroll value for each of 
the playfields. Granularity of scroll now extends down to 35nSec. (1 SHRES
pixel), and scroll can delay playfield thru 32 bus cycles. Bits BPAGEM and
BPL32 in new register FMODE control size of bitplane data in BPLDAT thru 
BPL8DAT.

The old 6 bitplane HAM mode, unlike before, works in HIRES and SHRES
resolutions. As before bitplanes 5 and 6 control its function as follows:

BP6         BP5         RED         GREEN       BLUE
----------------------------------------------------------
0           0           select new base register (1 of 16)
0           1           hold        hold        modify
1           0           modify      hold        hold
1           1           hold        modify      hold

There is a new 8 bitplane HAM (Hold and Modify) mode. This mode is invoked
when BPU field in BPLCON0 is set to 8, and HAMEN is set. Bitplanes 1 and 2
are used as control bits analagous to the function of bitplanes 5 and 6 in 6
bitplane HAM mode:

BP2         BP1         RED         GREEN       BLUE
----------------------------------------------------------
0           0           select new base register (1 of 64)
0           1           hold        hold        modify
1           0           modify      hold        hold
1           1           hold        modify      hold

Since only 6 bitplanes are available for modify data, the data is placed
in the 6 MSB. The 2 LSB are left unmodified, which allows creation of all
16,777,216 colours simultaneously, assuming one had a large enough screen
and picked one's base registers judiciously. This HAM mode also works in
HIRES and SHRES modes.

For compatibility reasons EHB mode remains intact. Its existence is rather
moot in that we have more than enough colours in the colour table to replace 
its functionality. As before, EHB is invoked whenever SHRES= HIRES= HAMEN= 
DPF=0, and BPU=6. Please note that starting with ECS DENISE there is a bit 
in BPLCON2 which disables this mode (KILLEHB).

Sprites:
--------
Bits SPAGEM and SPR32 in FMODE whether size of sprite load data in SPR0DATA(B)
thru SPR7DATA(B) is 16,32 or 64 bits, analagous to bitplanes. BPLCON3 contains
several bits relating to sprite behavior, SPRES1 and SPRES0 control sprite
resolution, whether they conform to the ECS standard, or overide to LORES,
HIRES or SHRES. BRDRSPRT, when high, allows sprites to be visible in border
areas. ESPRM7 thru ESPRM4 allow relocation of the even sprite colour map.
OSPRM7 thru OSPRM4 allow relocation of the odd sprite colour map. In the case
of attached sprites OSPRM bits are used.

Colour Lookup Table:
--------------------
The colour table has grown from 32 13-bit registers to 256 25-bit registers.
Several new register bits have been added to BPLCON3 to facilitate loading
the table with only 32 register addresses. LOCT, selects either the 16 MSB
or LSB for loading. Loading the MSB always loads the LSB as well for
compatibility, so when 24-bit colours are desired load LSB after MSB.
BANK2,1,0 select 1 of 8 32 address banks for loading as follows:

BANK2       BANK1       BANK0       Colour Address Range
--------------------------------------------------------
0           0           0           COLOUR00 - COLOUR1F
0           0           1           COLOUR20 - COLOUR3F
0           1           0           COLOUR40 - COLOUR5F
0           1           1           COLOUR60 - COLOUR7f
1           0           0           COLOUR80 - COLOUR9F
1           0           1           COLOURA0 - COLOURBF
1           1           0           COLOURC0 - COLOURDF
1           1           1           COLOURE0 - COLOURFF

RDRAM bit in BPLCON2 causes LISA to interpret all colour table accesses as
reads.

Note: There is no longer any need to "Scramble" SHRES colour table entries.
This artifice is no longer required and people who bypass ECS graphics
library calls to do their own 28MHz graphics are to be pointed at and
publicly humiliated.

Collision:
----------
A new register CLXCON2 contains 4 new bits. ENBP7 and ENBP6 are the enable
bits for bitplanes 7 and 8, respectively. Similarly, MVBP7 and MVBP8 are
their match value bits. CLXDAT is unchanged.

Horizontal Comparators:
-----------------------
All programmable comparators with the exception of VHPOSW have 35nSec
resolutions; DIWHIGH, HBSTRT, HBSTOP, SPRCTL, BPLCON1. BPLCON1 has additional
high-order bits as well. Note that horizontal bit position representing
140nSec resoloution has been changed to 3rd least significant bit, where
before it used to be a field's LSB. For example, bit-0 in BPLCON1 used to
be named PF1H0 and now it's called PF1H2.

Coercion of 15KHz to 31KHz:
---------------------------
We have added new hardware features to LISA to aid in properly displaying
15KHz and 31KHz viewports together on the same 31KHz display. LISA can
globally set sprite resolution to LORES, HIRES, or SHRES. LISA will ignore
SH10 compare bit in SPRxPOS when scan-doubling, therby allowing ALICE to
use these bits to individually set scan-doubling.

			NEW AGA-ECS REGISTERS: (thanx to DDT/HBT for ECS help)

	;CUSTOM = $DFF000

vposr	EQU	$004	; Read vertical most significant bits (and frame flop)

    Bit   15 14 13 12 11 10 09 08  07 06 05 04 03  02 01 00
    Use  LOF I6 I5 I4 I3 I2 I1 I0 LOL -- -- -- -- v10 v9 V8
		
	LOF=Long frame(auto toggle control bit in BPLCON0)
	I0-I6 Chip identitication:
	8361 (Regular) or 8370 (Fat) (Agnus-ntsc)=10
	8367 (Pal) or 8371 (Fat-Pal) (Agnus-pal)=00
	8372 (Fat-hr) (agnushr),thru rev4 = 20 Pal,30 NTSC
	8372 (Fat-hr) (agnushr),rev 5 = 22 Pal, 31 NTSC 
	8374 (Alice) thru rev 2 = 22 Pal, 32 NTSC
	8374 (Alice) rev 3 thru rev 4 = 23 Pal, 33 NTSC
	LOL = Long line bit. When low, it indicates short raster line.
	v9,10 -- hires chips only (20,30 identifiers)

*******************************************************************************

cdang	EQU	$02e	; Copper control register
 	This is a 1-bit register that when set true, allows the copper to
 	access the blitter hardware. This bit is cleared by power-on reset,
 	so that the copper cannot access the blitter hardware.

	01	CDANG	  (STD)	Copper danger mode. Allows Copper access to
				blitter if set ($DFF03E to $DFF07E).
			  (ECS)	If clear copper can only access addresses
				($DFF03E to $DFF07E).  If set copper can
				access all chip registers.
*******************************************************************************

STREQU	    EQU   $038	;Strobe for horiz sync with VB (vert blank) and EQU
STRVBL	    EQU   $038	;Strobe for horiz sync with VB
STRHOR	    EQU   $03C	;Strobe for horiz sync
STRLONG	    EQU   $03E	;Strobe for identification of long horiz line (228cc)

One of the first 3 strobe addresses above, it is placed on the RGA bus during
the first refresh time slot of every other line, to identify lines with long
counts (228- NTSC, HTOTAL+2- VARBEAMEN=1 hires chips only).There are 4 refresh
time slots and any not used for strobes will leave a null (1FE) address on the
RGA bus.

*******************************************************************************

pad2d       EQU   $05A		; note: byte access only
				; function unknown
*******************************************************************************

bltcon0l    EQU   $05B		; note: byte access only - write only
				; Blitter control 0, lower 8 bits (minterms)

The BLTCON0L register writes the low bits of BLTCON0, thereby expediting
the set up of some blits and generally speeding up the software, since the
upper bits are often the same.

*******************************************************************************

bltcon1     EQU   $042          ; Blitter control register 1


Bit 7 (DOFF) of the BLTCON1 register, when set, disables the output of the
Blitter hardware on channel D.

This allows inputs to channels A, B and C and certain address modification
if necessary, without the Blitter outputting over channel D.

*******************************************************************************

bltsizv     EQU   $05C		; Blitter Size Vertical
	 0 H14 H13 H12 H11 H10  H9  H8  H7  H6  H5  H4  H3  H2  H1  H0
	H=Height (32768 lines Max)
*******************************************************************************

bltsizh     EQU   $05E
				; Blitter Size Horizontal
	 0   0   0   0   0 W10  W9  W8  W7  W6  W5  W4  W3  W2  W1  W0
	W=Width in words (2048 words = 32768 pixels Max)
	Writing this register starts the Blitter

With these two registers, blits up to 32K by 32K are now possible - much
larger than the original chip set could accept. The original commands are
retained for compatibility.  BLTSIZV should be written first, followed by
BLTSIZH, which starts the blitter.

*******************************************************************************
pad34	    EQU	  $068-$06a-$06c-$06e	;UNUSED

*******************************************************************************
pad3b	    EQU	  $076		;UNUSED

*******************************************************************************
BPLHDAT     EQU   $07A   	;Ext logic UHRES bit plane identifier

*******************************************************************************

SPRHDAT	    EQU   $078 	;Ext logic UltraHiRes sprite pointer and data identif.

This identifies the cycle when this pointer address is on  the bus accessing
the memory.

*******************************************************************************

deniseid    EQU   $07C	; (or Lisaid) Denise chip ID (to check the chipset)

Lower 8 bits:	- Random value if standard Denise is present
 		- $FC if ECS Denise is present
 		- $F8 if AGA chipset is present

The original Denise (8362) does not have this register, so whatever value is
left over on the bus from the last cycle will be there. ECS Denise (8373)
returns hex (fc) in the lower 8 bits.Lisa returns hex (f8). The upper 8 bits
of this register are loaded from the serial mouse bus, and are reserved for
future hardware implentation.

	The 8 low-order bits are encoded as follows:	(from C-18 AGA doc)

	BIT#  Description
	----  --------------------------------------------------
	 7-4  Lisa/Denise/ECS Denise Revision level(decrement to
	      bump revision level, hex F represents 0th rev. level).
	   3  Maintain as a 1 for future generation
	   2  When low indicates AA feature set (LISA) 
	   1  When low indicates ECS feature set (LISA or ECS DENISE)
	   0  Maintain as a 1 for future generation

*******************************************************************************

bplcon0     EQU   $100	; 15 = HIRES
			; 14 = BPU2 \
			; 13 = BPU1  |select num of bitplanes, from 0 thru 7
			; 12 = BPU0 /
			; 11 = HAM - old HAM, and HAM8 AGA (if bit 4 is set)
			; 10 = DBLPF - double playfield
			; 9  = COLOR - Composite video (Genlock)
			; 8  = GAUD  - Composite audio
			; 7  = UHRES - 1024*1024 (set also bit 9 in DMACON)
			; 6  = superhires 1280x 35ns
			; 5  = BPLHWRM - screen black and white, no copcolors
					;BYPASS = 0
			; 4  = 8 planes (then bits 12-14 must be 0)
			; 3  = LPEN - Light pen
			; 2  = LACE - Interlace mode
			; 1  = ERSY - External resync
			; 0  = ECSENA Enable bplcon3 register (ECS-AGA)

bit 7 of $dff100 is the UHRES bit  (ultra hires is think)...i don't know 
how this works exactly but my suspicions is that it is 1024*1024 and i 
only 1 bitplane deep... the bitplane pointer for UHRES is $dff1ec and 
$dff1ee!!!! so its a new bitplanepointer!!!! it only works in vram (what 
the hell is that anyway??)  you have also a vram spritepointer extra... 
(also uhres!!)..(also needs bits in DMACON).
Disables hard stops for vert, horiz display windows

BYPASS = Bitplanes are scrolled and prioritized normally, but bypass color
table and 8 bit wide data appear on R(7:0).

RST_pin resets all bits in all registers new to AA. These registers include:
BPLCON3, BPLCON4, CLXCON2, DIWHIGH, FMODE.

ECSENA bit (formerly ENBPLCN3) is used to disable those register bits in
BPLCON3 that are never accessed by old copper lists, and in addition are
required by old-style copper lists to be in their default settings.
Specifically, ECSENA forces the following bits to their default low settings:
BRDRBLNK, BRDNTRAN, ZDCLKEN, EXTBLKEN, and BRDRSPRT. When ECSENA is set high
again, the former settings for these bits are restored.

CLXCON2 is reset by a write to CLXCON, so that old game programs will be
able to correctly detect collisions.

*******************************************************************************
bplcon1     EQU   $102		; bits 8 to 14 used for 1/4 pixel scroll
				; 2 bits are for displacing the pixels in
				; steps of 1/4 for the odd planes and 2 for
				; the even planes. the other 2 pairs of bits
				; are for scrolling in steps of 16 pixels a
				; time (one pair for odd planes and one pair
				; for even). This means that you can move any
				; playfield 64 pixels to any side with
				; intervals of 1/4 pixel!!!
				; you have 256 possible scrollvalues=8bits...

	15	PF2H7 - 64 PIXEL SCROLL PF2 (AGA)
	14 	PF2H6 - 64 PIXEL SCROLL PF2 (AGA)
	13 	PF2H1 - FINE SCROLL PF2 (AGA SCROLL 35ns 1/4 of pixel)
	12 	PF2H0 - FINE SCROLL PF2
	11 	PF1H7 - 64 PIXEL SCROLL PF1 (AGA)
	10 	PF1H6 - 64 PIXEL SCROLL PF1 (AGA)
	09 	PF1H1 - FINE SCROLL PF1 (AGA SCROLL 35ns 1/4 of pixel)
	08	PF1H0 - FINE SCROLL PF1
	07	PF2H3
	06	PF2H2
	05	PF2H1
	04	PF2H0
	03	PF1H3
	02	PF1H2
	01	PF1H1
	00	PF1H0

	PF2H=Playfield 2 scroll code	PFlH=Playfield 1 scroll code

	PF2Hx = Playfield 2 horizontal scroll code, x=0-7

PF1Hx = Playfield 1 horizontal scroll code, x=0-7 where PFyH0=LSB=35ns
SHRES pixel (bits have been renamed, old PFyH0 now PFyH2, ect). Now that the
scroll range has been quadrupled to allow for wider (32 or 64 bits) bitplanes.

Smooth Hardware Scrolling (from howtocode 6)
-------------------------

Extra bits have been added to BPLCON1 to allow smoother hardware
scrolling and scrolling over a larger area.

Bits 8 (PF1H0) and 9 (PF1H1) are the new hi-resolution scroll bits for
playfield 0 and bits 12 (PF2H0) and 13 (PF2H1) are the new bits for
playfield 1.

Another two bits have been added for each bitplane at bits 10 (PF1H6)
and 11 (PF1H7) for playfield 1 and bits 14 (PF2H6) and 15 (PF2H7) to
increase the maximum scroll range from 16 lo-res pixels to 64 lo-res
pixels (or 256 superhires pixels).

Normal 0-16 positions therefore are normal, but it you want to
position your screen at a (super) hires position you need to set
the new bits, or if you require smooth hardware scrolling with either
2x or 4x  Fetch Mode.

*******************************************************************************

bplcon2     EQU   $104 ; Bit Plane Control Register 2 (video priority control)
	15	-
	14 ECS	ZDBPSEL2	\  Select one of the 8 BitPlanes
	13 ECS	ZDBPSEL1	 } in ZDBPEN genlock mod
	12 ECS	ZDBPSEL0	/
	11 ECS	ZDBPEN		Use BITPLANEKEY - use bitplane as genlock bits
	10 ECS	ZDCTEN		Use COLORKEY - colormapped genlock bit
	09 ECS	KILLEHB		Kill ExtraHalfBrite (for a normal 6bpl pic)
	08 AGA  RDRAM		All color tabs are reads
	07 AGA  SOGEN (ZDCLKEN)	Enable 14Mhz clock
	06	PF2PRI		PField 2 priority over PField 1
	05	PF2P2		\
	04	PF2P1		 } PField 2 sprite priority
	03	PF2P0		/
	02	PF1P2		\
	01	PF1P1 		 } PField 1 sprite priority
	00	PF1P0		/

Using 64-colour mode (NOT extra halfbrite) requires setting the
KILLEHB (bit 9) in BPLCON2.

ZDBPSELx =3 bit field which selects which bitplane is to be used for ZD when
ZDBBPEN is set;000 selects BB1 and 111 selects BP8.

ZDBPEN = Causes ZD pin to mirror bitplane selected by ZDBPSELx bits. This does
not disable the ZD mode defined by ZDCTEN, but rather is "ored" with it.

ZDCTEN = Causes ZD pin to mirror bit #15 of the active entry in high color
table. When ZDCTEN is reset ZD reverts to mirroring color (0).

SOGEN = When set causes SOG output pin to go high

RDRAM bit in BPLCON2 causes LISA to interpret all colour table accesses as
reads instead of writing to it.

Lots of new genlock features were added to ECS denise and are carried over
to LISA. ZDBPEN in BPLCON2 allows any bitplane, delected by ZDBPSEL2,1,0,
to be used as a tansparency mask (ZD pin mirrors contents of selected
bitplane). ZDCTEN disables the old COLOUR00 is transparent mode, and allows
the bit-31 position of each colour in the colour table to control transparency
. ZDCLKEN generates a 14MHz clock synchronized with the video data that can
be used by video post-processors.
*******************************************************************************

bplcon3     EQU   $106	; 0  = EXTBLNKEN - external blank enable
			; 1  = BRDSPRT - EXTBLKZD - external blank ored
			;      into trnsprncy- sprites on BORDERS!
			; 2  = ZDCLKEN - zd pin outputs a 14mhz cloc
			; 3  = NO FUNCTIONS - SET TO ZERO
			; 4  = ECS BRDRTRAN Border opaque
			; 5  = ECS BRDRBLNK Border blank
			; 6  = AGA SPRES1 \sprite hires,lores,superhires
			; 7  = AGA SPRES0 /
			; 8  = NO FUNCTIONS - SET TO ZERO
			; 9  = LOCT - palette high or low nibble colour
			; 10 = PF2OF2 \
			; 11 = PF2OF1  } second playfield's offset in coltab
			; 12 = PF2OF0 /
			; 13 = BANK0 \
			; 14 = BANK1  } LOCT palette select 256
			; 15 = BANK2 /
			;

BANKx = Selects one of eight color banks, x=0-2.

Bits PF2OF2,1,0 in BPLCON3 determine second playfield's offset into the
colour table. This is now necessary since playfields in DPF mode can have
up to 4 bitplanes. Offset values are as defined in register map.
The bits 10 and 11 must be set as default to made the old 16 colours dual
playfiled, so remember that ($106,$c00) (Thanx to MUCSI/Muffbusters)
PF20Fx = Determine bit plane color table offset whe playfield 2 has priority
in dual playfield mode:

	PF20F || AFFECTED BITPLANE ||OFFSET	(From C-18 AGA doc)
	-------------------------------------------------------
	| 2 | 1 | 0 || 8 | 7 | 6 | 5 | 4 | 3 | 2 | 1 ||(decimal)
	-------------------------------------------------------
	| 0 | 0 | 0 || - | - | - | - | - | - | - | - || none
	| 0 | 0 | 1 || - | - | - | - | - | - | 1 | - || 2
	| 0 | 1 | 0 || - | - | - | - | - | 1 | - | - || 4
	| 0 | 1 | 1 || - | - | - | - | - | 1 | - | - || 8 (default)
	| 1 | 0 | 0 || - | - | - | 1 | - | - | - | - || 16
	| 1 | 0 | 1 || - | - | 1 | - | - | - | - | - || 32
	| 1 | 1 | 0 || - | 1 | - | - | - | - | - | - || 64
	| 1 | 1 | 1 || 1 | - | - | - | - | - | - | - || 128
          
LOCT = Dictates that subsequent color palette values will be written to a
second 12- bit color palette, constituting the RGB low minus order bits.
Writes to the normal hi monus order color palette automattically copied to
the low order for backwards compatibility.
(selects either the 16 MSB or LSB for loading)

BRDNTRAN in BPLCON3 generates an opaque border region which can be used to
frame live video. (Genlock)

BRDRBLNK = "Border area" is blanked instead of color (0).
Disabled when ECSENA low.

BRDRSPRT, when high, allows sprites to be visible out the display window.
but if you want it to work you have to enable ECSENA. This is bit 0 from 
$dff100! (this is for compatibilty reasons!)

ZDCLKEN = ZD pin outputs a 14MHz clock whose falling edge coincides with hires
(7MHz) video data. this bit when set disables all other ZD functions.
Disabled when ESCENA low.

EXTBLKEN = causes BLANK output to be programmable instead of reflecting
internal fixed decodes. Disabled when ESCENA low.

*******************************************************************************

bplcon4     EQU   $10C		; 0  ESPRM7 \
				; 1  ESPRM6  \ CHOOSE EVEN SPRITE PALETTE
				; 2  ESPRM5  /
				; 3  ESPRM4 /
				; 4  OSPRM4 \
				; 5  OSPRM4  \ CHOOSE ODD SPRITE PALETTE
				; 6  OSPRM4  /
				; 7  OSPRM4 /
				; 8  BPLAM0 \
				; 9  BPLAM1  \
				; 10 BPLAM2   |
				; 11 BPLAM3   | Switch colours without
				; 12 BPLAM4   | change the palette
				; 13 BPLAM5   |
				; 14 BPLAM6  /
				; 15 BPLAM7 /

BPLAMx = This 8 bit field is XOR`ed with the 8 bit plane color address,thereby
altering the color address sent to the color table (x=1-8)
Bits 15 thru 8 of BPLCON4 comprise an 8-bit mask for the 8 bitplane address,
XOR'ing the individual bits. This allows the copper to exchange colour maps
with a single instruction.

ESPRMx = 4 Bit field provides the 4 high order color table address bits for
even sprites: SPR0,SPR2,SPR4,SPR6. Default value is 0001 binary. (x=7-4)

OSPRMx = 4 Bit field provides the 4 high order color table address bits for
odd sprites: SPR1,SPR3,SPR5,SPR7. Default value is 0001 binary. (x=7-4)

*******************************************************************************

clxcon2     EQU   $10E		; 0 match value for bitplane 7 collision
				; 1 match value for bitplane 8 collision
				; 2-5: UNUSED
				; 6 ENBP8 enable bitplane 7 (match reqd coll)
				; 7 ENBP8 enable bitplane 8 (match reqd coll)
				; 8-15: UNUSED

A new register CLXCON2 contains 4 new bits. ENBP7 and ENBP6 are the enable
bits for bitplanes 7 and 8, respectively. Similarly, MVBP7 and MVBP8 are
their match value bits. CLXDAT is unchanged.

*******************************************************************************

BPL7DAT	    EQU   $11c   W     ;Bit plane 7 data (parallel to serial convert)
BPL8DAT     EQU   $11e   W     ;Bit plane 8 data (parallel to serial convert)

*******************************************************************************

SPRxPOS    EQU   $140/...	;Sprite x vert-horiz start position data.

	BIT#	SYM		FUNCTION
        ----    ----    	-----------------------------------------
	15-08  SV7-SV0  	Start vertical value.High bit (SV8) is 
				in SPRxCTL register below.
	07-00  SH10-SH3 	Sprite horizontal start value. Low order
				3 bits are in SPRxCTL register below. If 
				SSCAN2 bit in FMODE is set, then disable
				SH10 horizontal coincidence detect.This bit
				is then free to be used by ALICE as an 
				individual scan double enable.

*******************************************************************************

sprxctl	    EQU   $142/14A/152/15A/162/16A/172/17A
 Sprite x vert stop and control data

	BIT#	SYM		FUNCTION
        ----   ----    	----------------------------------------
	15-08	EV7-EV0         End (stop) vert. value. Low 8 bits 
	07	ATT		Sprite attach control bit (odd sprites only)
	06 AGA  SV9		Start vert value 10th bit.
	05 AGA  EV9		End (stop) vert. value 10th bit
	04 ECS  SH1=0		Start horiz. value, 70nS increment
	03 AGA  SH0=0		Start horiz. value 35nS increment
	02	SV8		Start vert. value 9th bit
	01	EV8		End (stop) vert. value 9th bit
	00	SH2		Start horiz.value,140nS increment

	These 2 registers work together as position, size and 
	feature sprite control registers.They are usually loaded
	by the sprite DMA channel, during horizontal blank,
	however they may be loaded by either processor any time.
	Writing to SPRxCTL disables the corresponding sprite.

*******************************************************************************

144/146/14C/14E/154/156/15C/15E/164/166/16C/16E/174/176/17C/17E
 Sprite image Data (From C-18 AGA doc)

These registers buffer the sprite image data.They are usually loaded by the
sprite DMA channel but may be loaded by either processor at any time. When a
horizontal coincidence occurs the buffers are dumped into shift registers and
serially outputed to the display, MSB first on the left.
NOTE: Writing to the A buffer enables (arms) the sprite.
Writing to the SPRxCTL registers disables the sprite.
If enabled, data in the A and B buffers will be output whenever the beam
counter equals the sprite horizontal position value in the SPRxPOS register.
In lowres mode, 1 sprite pixel is 1 bitplane pixel wide.In HRES and SHRES
mode, 1 sprite pixel is 2 bitplane pixels.
The DATB bits are the 2SBs (worth 2) for the color registers, and MSB for
SHRES. DATA bits are LSBs of the pixels.

*******************************************************************************

COLORxx  180-1BE  W		COLOR table xx	(From C-18 AGA DOC)

There 32 of these registers (xx=00-31) and together with the banking bits they
address the 256 locations in the color palette. There are actually two sets of
color regs, selection of which is controlled by the LOCT reg bit.
When LOCT = 0 the 4 MSB of red, green and blue video data are selected along
with the T bit for genlocks the low order set of registers is also selected as
well, so that the 4 bi valuesare automatically extended to 8 bits.
This provides compatibility with old software. If the full range of palette
values are desired, then LOCT can be set high and independant values for the 4
LSB of red, green  and blue can be written. The low order color registers do
not contain a transparency (T) bit.
The table below shows the color register bit usage.

	BIT#    15,14,13,12    11,10,09,08    07,06,05,04    03,02,01,00
	----    -----------    -----------    -----------    -----------
	LOCT=0  T  X  X  X     R7 R6 R5 R4    G7 G6 G5 G4    B7 B6 B5 B4
	LOCT=1  X  X  X  X     R3 R2 R1 R0    G3 G2 G1 G0    B3 B2 B1 B0 

	T = TRANSPARENCY     R = RED    G = GREEN    B = BLUE    X = UNUSED

T bit of COLOR00 thru COLOR31 sets ZD_pin HI, When that color is selected in
all video modes.

*******************************************************************************
htotal	    EQU   $1c0		; Highest number count, horiz line
				; (VARBEAMEN bit in BEAMCON0 must be set)

   HTOTAL    W   A     Highest number count in horizontal line

         Bit  15 14 13 12 11 10 09 08 07 06 05 04 03 02 10 00
         Use   0  0  0  0  0  0  0  0 h8 h7 h6 h5 h4 h3 h2 h1

Horiz line has theis many + 1 280nS increments. If the pal bit & LOLDIS are
not high, long line/skort line toggle will occur, and there will be this many
+2 every other line. Active if VARBEAMEN=1 or DUAL+1.

*******************************************************************************

hsstop	    EQU   $1c2		; Horizontal line position for HSYNC stop
			Sets # of colour clocks for sync stop (HTOTAL for bits)

*******************************************************************************

hbstrt	    EQU   $1c4		;  Horizontal line position for HBLANK start
hbstop	    EQU   $1c6		;  Horizontal line position for HBLANK stop

Bits 7-0 contain the stop and start positions, respectively, for programed
horizontal blanking in 280nS increments.Bits 10-8 provide a fine position
control in 35nS increments.

	BIT#    FUNCTION   DESCRIPTION	(from C-18 AGA doc)
	----    --------   -----------
	 15-11  x          (unused)
	 10     H1         140nS
	 09     H1         70nS
	 08     H0         35nS  
	 07     H10        35840nS
	 06     H9         17920nS
	 05     H8         8960nS
	 04     H7         4480nS
	 03     H6         2240nS
	 02     H5         1120nS
	 01     H4         560nS 
	 00     H3         280nS

*******************************************************************************

vtotal	    EQU   $1c8		;  Highest numbered vertical line
				; (VARBEAMEN bit in BEAMCON0 must be set)

   VTOTAL    W   A     Highest numbered vertical line

VTOTAL contains the line number at which to reset the vertical position
counter.  This value represents the number of lines in a field(+1). The
exception is if the INTERLACE bit is set (BPLCON0). In this case this
value represents the number of lines in the long field (+2) and the number
of lines in the short field (+1).

*******************************************************************************
vsstop	    EQU   $1ca		;  Vertical line position for VSYNC stop

*******************************************************************************
vbstrt	    EQU   $1cc		;  Vertical line for VBLANK start
vbstop	    EQU   $1ce		;  Vertical line for VBLANK stop

(V10-0 <- D10-0) Affects CSY pin if BLAKEN=1 and VSY pin if CSCBEN=1 (BEAMCON0)

*******************************************************************************
sprhstrt    EQU   $1d0		;UHRES sprite vertical displat start

 BIT#  15  14  13  12  11  10  09  08     07  06  05  04  03  02  01  00
        x   x   x   x   x  v10 v9  v8     v7  v6  v5  v4  v3  v2  v1  v0

*******************************************************************************
sprhstop    EQU   $1d2		;UHRES sprite vertical display stop

    BIT#  15  14  13  12  11  10  09  08     07  06  05  04  03  02  01  00
SPRHWRM   x   x   x   x   x  v10  v9  v8     v7  v6  v5  v4  v3  v2  v1  v0 

	SPRHWRM = Swaps the polarity of ARW* when the SPRHDAT comes
	out so that external devices can detect the RGA and put 
	things into memory.(ECS and later chips only)

*******************************************************************************
bplhstrt    EQU   $1d4		;UHRES bit plane vertical start

			This controls the line when the data fetch starts for
			the BPLHPTH,L pointers. V10-V0 on DB10-0.

*******************************************************************************
bplhstop    EQU   $1d6		;UHRES bit plane vertical stop

			BIT#   name
			----   ----
			15     BPLHWRM 
			14-11  Unused
			10-0   V10-V0

BPLHWRM = Swaps the polarity of ARW* when the BPLHDAT comes out so that
external devices can detect the RGA and put things into memory (from ECS)

*******************************************************************************
hhposw	    EQU   $1d8		;DUAL mode hires H beam counter write
hhposr	    EQU   $1da		;DUAL mode hires H beam counter read

This the secondary beam counter for the faster mode, triggering the UHRES
pointers & doing the comparisons for HBSTRT,STOP,HTOTAL,HSSRT,HSSTOP
(See HTOTAL for bits)

*******************************************************************************
beamcon0    EQU   $1dc		; Beam counter control register (ECS)
				; (SHRES,UHRES,PAL)
	15	-
	14 ECS	HARDDIS		Disable Hardwired vert/hor blank
	13 ECS	LPENDIS		Ignore latched pen value on vert pos read
	12 ECS	VARVBEN		Variable vertical blank enable
				Use VBSTRT/STOP disable hard window stop
	11 ECS	LOLDIS		Disable longline/shortline toggle
	10 ECS	CSCBEN		Composite sync redirection
	09 ECS	VARVSYEN	Variable vertical sync enable
	08 ECS	VARHSYEN	Variable horizontal sync enable
	07 ECS	VARBEAMEN	Variable beam counter comparator enable
	06 ECS	DISPLAYDUAL	Special ultra resolution enable
				(use UHRES pointer and standard pointers)
	05 ECS	DISPLAYPAL	Programmable PAL mode enable (pal/ntsc switch)
	04 ECS	VARCSYEN	Variable composite sync enable
	03 ECS	BLANKEN-CSBLANK	Composite blank redirection (out to CSY pin)
	02 ECS	CSYNCTRUE	Polarity control for Composite sync pin (TRUE)
	01 ECS	VSYNCTRUE	Polarity control for Vertical sync pin (TRUE)
	00 ECS	HSYNCTRUE	Polarity control for Horiz sync pin (TRUE)

	(From C-18 AGA DOC)

HARDDIS = This bit is used to disable the hardwire vertical horizontal
          window limits. It is cleared upon reset.

LPENDIS = When this bit is a low and LPE (BPLCON0,BIT 3) is enabled, the
          light-pen latched value(beam hit position) will be read by
          VHPOSR,VPOSR and HHPOSR. When the bit is a high the light-pen
          latched value is ignored and the actual beam counter position is
          read by  VHPOSR,VPOSR, and HHPOSR.

VARVBEN = Use the comparator generated vertical blank (from VBSTRT,VBSTOP)
          to run the internal chip stuff-sending RGA signals to Denise,
          starting sprites,resetting light pen. It also disables the hard
          stop on the vertical display window.

LOLDIS  = Disable long line/short toggle. This is useful for DUAL mode
          where even multiples are wanted, or in any single display
          where this toggling is not desired.

CSCBEN  = The variable composite sync comes out on the HSY pin, and the
          variable conosite blank comes out on the VSY pin. The idea is
          to allow all the information to come out of the chip for a
          DUAL mode display. The normal monitor uses the normal composite
          sync, and the variable composite sync &blank come out the HSY &
          VSY pins. The bits VARVSTEN & VARHSYEN (below) have priority over
          this control bit.

VARVSYEN= Comparator VSY -> VSY pin. The variable VSY is set vertically on
          VSSTRT, reset vertically on VSSTOP, with the horizontal position
          for set set & reset HSSTRT on short fields (all fields are short
          if LACE = 0) and HCENTER on long fields (every other field if
          LACE = 1).

VARHSYEN= Comparator HSY -> HSY pin. Set on HSSTRT value, reset on HSSTOP
          value.

VARBEAMEN=Enables the variable beam counter comparators to operate 
          (allowing diffrent beam counter total values) on the main horiz 
          counter. It also disables hard display stops on both horizontal
          and vertical.

DUAL    = Run the horizontal comparators with the alternate horizontal beam
          counter, and starts the UHRES pointer chain with the reset of
          this counter rather than the normal one. This allows the UHRES 
          pointers to come out more than once in a horizontal line,
          assuming there is some memory bandwidth left (it doesn`t work in
          640*400*4 interlace mode) also, to keep the two displays synced,
          the horizontal line lentghs should be multiples of each other.
          If you are amazingly clever, you might not need to do this.

PAL     = Set appropriate decodes (in normal mode) for PAL. In variable
          beam counter mode this bit disables the long line/short line
          toggle- ends up short line.

VARCSYEN= Enables CSY from the variable decoders to come out the CSY
          (VARCSY is set on HSSTRT match always, and also on HCENTER
          match when in vertical sync. It is reset on HSSTOP match when VSY
          and on both HBSTRT &HBSTOP matches during VSY. A reasonable
          composite can be generated by setting HCENTER half a horiz line
          from HSSTRT, and HBSTOP at (HSSTOP-HSSTRT) before HCENTER, with
          HBSTRT at (HSSTOP-HSSTRT) before .... see below 

*******************************************************************************
HSSTRT	    EQU   $1DE		; Horizontal sync start (VARHSY)
		Sets # of colour clocks for sync start (HTOTAL for bits)
		See BEAMCON0 for details of when these 2 are active.

*******************************************************************************
vsstrt	    EQU   $1e0		;  Vertical sync start (VARVSY)
				; (VARVSYEN bit in BEAMCON0 must be set)
*******************************************************************************
hcenter     EQU   $1e2		;  Horizontal position for VSynch on interlace
				;  (or CCKs on long field)

this is necessary for interlace mode with variable beam counters. 
See BEAMCON0 for when it affects chip outputs. See HTOTAL for bits.

*******************************************************************************
diwhigh     EQU   $1e4	; highest bits for the diwstrt/stop

DIWHIGH is reset by writes to DIWSTRT or DIWSTOP. This interlock is inherited
from ECS Denise.

Display window upper bits for start, stop this is an added register for Hires
chips, and allows larger start & stop ranges. If it is not written, the above 
(DIWSTRT,STOP) description holds. If this register is written, direct start &
stop positions anywhere on the screen. It doesn`t affect the UHRES pointers.
 
	BIT# 15  14  13  12  11  10  09  08  07  06  05  04  03  02  01  00
	      X   X  H10 H1  H0  V10 V9  V8   X   X  H10 H1  H0  V10 V9  V8
			(stop)		    |		(start)

Take care (X) bits should always be written to 0 to maintain upwards
compatibility. H1 and H0 values define 70ns amd 35ns increments respectively,
and new LISA bits.

NOTE:	In all 3 display window registers, horizontal bit
	positions have been renamed to reflect HIRES pixel increments, e.g.
	what used to be called H0 is now referred to as H2.

*******************************************************************************
BPLHMOD     EQU   $1E6		; modulo of the bitplane of UHRES
		;This is the number (sign extended) that is added to the
		;UHRES bit plane pointer (BPLHPTL,H) every line, and
		;then another 2 is added, just like the other modulos.

*******************************************************************************
SPRHPTH     EQU   $1E8		; sprite pointer for UHRES (high 5 bits)
SPRHPTL     EQU	  $1EA		; sprite pointer for UHRES (low 15 bits)

This pointer is activated in the 1st and 3rd `free` cycles (see BPLHPTH,L)
after horiz line start.It increments for the next line.

*******************************************************************************
BPL1HPTH    EQU	  $1EC		; VRAM BITPLANE POINTER FOR UHRES (high 5 bits)

*******************************************************************************
BPL1HPTL    EQU	  $1EE		; VRAM BITPLANE POINTER FOR UHRES (low 15 bits)

		When UHRES is enabled, this pointer comes out on the
		2nd 'free' cycle after the start of each horizontal
		line. It`s modulo is added every time it comes out.
		'free' means priority above the copper and below the
		fixed stuff (audio,sprites....).
		BPLHDAT comes out as an identifier on the RGA lines when
		the pointer address is valid so that external detectors
		can use this to do the special cycle for the VRAMs, The
		SHRHDAT gets the first and third free cycles.

*******************************************************************************
fmode	    EQU   $1fc	; 0  = BPL32 - bitplane 32 bit wide mode
			; 1  = BPAGEM - bitplane page mode (double cas)
			      (REMEMBER to align 32 or 64 bits the bitplanes)
			; 2  = SPR32 -sprite 32 bit wide mode
			; 3  = SPAGEM -sprite page mode (double cas)
			      (REMEMBER to align 32 or 64 bits the sprite)
			; 4-13 = UNUSED
			; 14 = BSCAN2 enabled use of 2nd P/F modulus on an
			;      alternate line basis to suppott bitplane scan
			       doubling! (probably for fancy monitors!)
			; 15 = SSCAN2, global enable for sprite scan doubling

	BPAGEM BPL32 Bitplane Fetch Increment Memory Cycle Bus Width
	------------------------------------------------------------
	  0	0    By 2 bytes    (as before) normal CAS     16
	  0	1    By 4 bytes 	       normal CAS     32
	  1	0    By 4 bytes 	       double CAS     16
	  1 	1    By 8 bytes      	       double CAS 32

	SPAGEM SPR32 Sprite Fetch Increment  Memory Cycle  Bus Width
	------------------------------------------------------------
	  0     0    By 2 bytes    (as before) normal CAS     16
	  0     1    By 4 bytes                normal CAS     32
	  1     0    By 4 bytes                double CAS     16
	  1     1    By 8 bytes                double CAS     32

SSCAN2 bit in FMODE enables sprite scan-doubling. When enabled, individual
SH10 bits in SPRxPOS registers control whether or not a given sprite is to
be scan-doubled. When V0 bit of SPRxPOS register matches V0 bit of vertical
beam counter, the given sprite's DMA is disabled and LISA reuses the sprite
data from the previous line. When sprites are scan-doubled, only the
position and control registers need be modified by the programmer; the data
registers need no modification.

NOTE: Sprite vertical start and stop positions must be of the same parity,
i.e. both odd or both even.

For non-interlaced screens, bitplane scandoubling is enabled (bit 14 BSCAN2
in FMODE) This repeats each scanline twice. A side effect of this is that the
bitplane modulos are unavailable for user control.

BSCAN bit 14 in FMODE enables bitplane scan-doubling. When V0 bit of DIWSTRT
matches V0 of vertical beam counter, BPL1MOD contains the modulus for the
display line, else BPLMOD is used. When scan-doubled both odd and even
bitplanes use the same modulus on a given line, whereas in normal mode
odd bitplanes used BPL1MOD and even bitplanes used BPL2MOD. As a result
Dual Playfield screens will probably not display correctly when scan-doubled.

DDFSTRT  and  DDFSTOP values should be modified if you change
the burst mode.	(From YRAGAEL & JUNKIE doc)

 Eg:  If  you  use  LONG  burst  mode  to open an Hires screen
     starting   at   hardware   horizontal   position  STARTX:
     DDFSTRT=(STARTX-17)/2 and no more DDFSTRT=(STARTX-9)/2

Why  ?   Very  easy.  You need 4 cycles to read a word (using all  the
bitplanes) in Hires.  If you want the image to start at  STARTX,  you  must
read the first word 4 cycles before its horizontal  position.   Add  0.5
cycles (it's needed !).  This gives  DDFSTRT=(STARTX-9)/2.   If  you are in
LONG burst mode, then  you  will read a long.  This will take 8 cycles.
So you must  read  the  first  long  8.5  cycles  before  the  STARTX
position:  DDFSTRT=(STARTX-17)/2.  That's all.

The Magic FMode Register (from howtocode6.txt)
------------------------
If you set your 1200/4000 to a hiresmode (such as 1280x512 Superhires
256 colours) and disassemble the copperlist, you find fun things
happen to the FMODE register ($dff1fc). The FMODE register determines
the amount of words transferred between chipram and the Lisa chip
in each data fetch. NOTE: Using a data fetch > 0 in standard LOWRES or
in hires resolutions, the COPPERLIST will be faster (will leave free
more time for the 680x0 and blitter), but the BLITTER speed is the SAME.

$dff1fc bits 0 and 1 value

$00 - Normal (word aligned bitmaps) - for standard ECS modes
      and up to 8 bitplanes 320x256

$01 - Double (longword aligned bitmaps) - for 640x256 modes in
      more than 16 colours

$10 - Double (longword aligned bitmaps) - Same effect, for 640x256 modes
      but different things happen... Not sure why!

$11 - Quadruple [x4] (64-bit aligned bitmaps) - for 1280x256 modes...

Fetch Mode Required for Displays
--------------------------------

*ALL* ECS and lower screenmodes require only 1x datafetch. All modes
run *FASTER* with at least 2x bandwidth, so try and use 2x bandwitdh
if possible.

Bits 2 and 3 do the same for sprite width, as has been mentioned elsewhere...

Remember... To take advantage of the increased fetchmodes (which give
you more processor time to play with!) your bitmaps must be on 64-bit
boundaries and be multiples of 64-bits wide (8 bytes)

* New for AA ChipSet (V39)
				- $DFF100 -
 HIRES HAM		:	%1000100000000000 - LACE: %1000100000000100
 SUPERHIRES HAM		:	%1000100001000000 - LACE: %1000100001000100
 (is possible to do hires and superhires EHB)
*******************************************************************************
Bitplanes:
Set 0 to 7 bitplanes as before in $dff100.
Set 8 bitplanes by setting bit 4 of $dff100, bits 12 to 15 should be zero.
For Hires when you have 8 bitplanes remember to set the bit 0 and 1 of $dff1fc

8 bitplanes:

 The  number of bitplanes used to be specify with bits 14 to 12 of register
$DFF0100.   Since  there were just 3 bits, it would have been impossible to
use more than 7 bitplanes.

 To  use  8  bitplanes, switch bit 4 of register $DFF100.  Don't forget to
clear bits 14 to 12 for further compatiblity :).

bit 4 | 8 bitplanes mode
------------------------
  0   | Not Selected
------------------------
  1   | Selected
------------------------

Using 64-colour mode (NOT extra halfbrite) requires setting the
KILLEHB (bit 9) in BPLCON2.

*******************************************************************************
Colour Registers:

There are now 256 colour registers, all accessed through the original
32 registers

AGA works with 8 differents palettes of 32 colors each, re-using
colour registers from $0180 to $01BE.

You can choose the palette you want to access via the bits 13 to 15 of
register $0106


bit 15 | bit 14 | bit 13 | Selected palette
-------+--------+--------+------------------------------
   0   |    0   |    0   | Palette 0 (color 0 to 31)
   0   |    0   |    1   | Palette 1 (color 32 to 63)
   0   |    1   |    0   | Palette 2 (color 64 to 95)
   0   |    1   |    1   | Palette 3 (color 96 to 127)
   1   |    0   |    0   | Palette 4 (color 128 to 159)
   1   |    0   |    1   | Palette 5 (color 160 to 191)
   1   |    1   |    0   | Palette 6 (color 192 to 223)
   1   |    1   |    1   | Palette 7 (color 224 to 255)
*******************************************************************************
To move a 24-bit colour value into a colour register requires
two writes to the register:

First clear bit 9 of $dff106
Move high nibbles of each colour component to colour registers

Then set bit 9 of $dff106
Move low nibbles of each colour components to colour registers

bit 9 | Access
------------------------------------------------
  0   | Access to 4 high bits of R,G,B components
------------------------------------------------
  1   | Access to 4 low bits of R,G,B components
------------------------------------------------

 You  must respect the order:  first move the 3*4 HIGH bits and then the 3*4
 LOW bits !

For example, to change colour zero to the colour $123456

   dc.l $01060000
   dc.l $01800135
   dc.l $01060200
   dc.l $01800246

 If you use 12 bits colors, just 3*4 high bits of the color are considered.

	AN EXAMPLE OF AGA COPPERLIST:


	DC.W	$106,$c00	;SELECT PALETTE 0 (0-31),HIGH BITS
COLP0:
	DC.W	$180,$000,$182,$000,$184,$000,$186,$000	;HIGH NIBBLES OF
	DC.W	$188,$000,$18A,$000,$18C,$000,$18E,$000	;COLOURS 0-31
	DC.W	$190,$000,$192,$000,$194,$000,$196,$000	;
	DC.W	$198,$000,$19A,$000,$19C,$000,$19E,$000	;
	DC.W	$1A0,$000,$1A2,$000,$1A4,$000,$1A6,$000
	DC.W	$1A8,$000,$1AA,$000,$1AC,$000,$1AE,$000
	DC.W	$1B0,$000,$1B2,$000,$1B4,$000,$1B6,$000
	DC.W	$1B8,$000,$1BA,$000,$1BC,$000,$1BE,$000

	DC.W	$106,$e00	;SELECT PALETTE 0 (0-31), LOW NIBBLES
COLP0B:
	DC.W	$180,$000,$182,$000,$184,$000,$186,$000	;LOW NIBBLES OF
	DC.W	$188,$000,$18A,$000,$18C,$000,$18E,$000	;COLOURS 0-31
	DC.W	$190,$000,$192,$000,$194,$000,$196,$000	;
	DC.W	$198,$000,$19A,$000,$19C,$000,$19E,$000	;
	DC.W	$1A0,$000,$1A2,$000,$1A4,$000,$1A6,$000
	DC.W	$1A8,$000,$1AA,$000,$1AC,$000,$1AE,$000
	DC.W	$1B0,$000,$1B2,$000,$1B4,$000,$1B6,$000
	DC.W	$1B8,$000,$1BA,$000,$1BC,$000,$1BE,$000

	DC.W	$106,$2C00	;SELECT PALETTE 1 (31-63), HIGH NIBBLES
COLP1:
	DC.W	$180,$000,$182,$000.... ETC.

	DC.W	$106,$2E00	;SELECT PALETTE 1 (31-63), LOW NIBBLES
COLP1B:
	DC.W	$180,$000,$182,$000.... ETC.

	DC.W	$106,$4C00	;SELECT PALETTE 2 (64-95), HIGH NIBBLES
COLP2:
	DC.W	$180,$000,$182,$000.... ETC.

	DC.W	$106,$4E00	;SELECT PALETTE 2 (64-95), LOW NIBBLES
COLP2B:
	DC.W	$180,$000,$182,$000.... ETC.

	DC.W	$106,$6C00	;SELECT PALETTE 3 (96-127), HIGH NIBBLES
COLP3:
	DC.W	$180,$000,$182,$000.... ETC.

	DC.W	$106,$6E00	;SELECT PALETTE 3 (96-127), LOW NIBBLES
COLP3B:
	DC.W	$180,$000,$182,$000.... ETC.

	DC.W	$106,$8C00	;SELECT PALETTE 4 (128-159), HIGH NIBBLES
COLP4:
	DC.W	$180,$000,$182,$000.... ETC.

	DC.W	$106,$8E00	;SELECT PALETTE 4 (128-159), LOW NIBBLES
COLP4B:
	DC.W	$180,$000,$182,$000.... ETC.

	DC.W	$106,$AC00	;SELECT PALETTE 5 (160-191), HIGH NIBBLES
COLP5:
	DC.W	$180,$000,$182,$000.... ETC.

	DC.W	$106,$AE00	;SELECT PALETTE 5 (160-191), LOW NIBBLES
COLP5B:
	DC.W	$180,$000,$182,$000.... ETC.

	DC.W	$106,$CC00	;SELECT PALETTE 6 (192-223), HIGH NIBBLES
COLP6:
	DC.W	$180,$000,$182,$000.... ETC.

	DC.W	$106,$CE00	;SELECT PALETTE 6 (192-223), LOW NIBBLES
COLP6B:
	DC.W	$180,$000,$182,$000.... ETC.

	DC.W	$106,$EC00	;SELECT PALETTE 7 (224-255), HIGH NIBBLES
COLP7:
	DC.W	$180,$000,$182,$000.... ETC.

	DC.W	$106,$EE00	;SELECT PALETTE 7 (224-255), LOW NIBBLES
COLP7B:
	DC.W	$180,$000,$182,$000.... ETC.

*******************************************************************************
Bplmod: The modulo is usually in aga mode the same as in normal mode minus 8.
So if your normal modulo = 0 then the agamodulo is -8. (if you use FMODE=3!)
if you use FMODE =$2 then the modulo is -4.
*******************************************************************************
Sprites:
To  change  the  resolution  of the sprite, just use bit 7 and 6 of
register $0106 (BPLCON3)

bit 7 | bit 6 | Resolution
------+-------+-----------
  0   |   0   | ECS Defaults      (Lo-res/Hi-res = 140ns, Superhires = 70ns)
  0   |   1   | Always lowres     (140ns)
  1   |   0   | Always hireres    (70ns)
  1   |   1   | Always superhires (35ns)
--------------------------

(70ns sprites may not be available unless the lace bit in BPLCON0 is set)
*******************************************************************************
For 32-bit and 64-bit wide sprites use bit 3 and 2 of register $01FC
Sprite format (in particular the control words) vary for each width.

bit 3 | bit 2 | Wide        | Control Words
------+-------+-------------+----------------------------------
  0   |   0   | 16 pixels   | 2 words (normal)
  1   |   0   | 32 pixels   | 2 longwords
  0   |   1   | 32 pixels   | 2 longwords
  1   |   1   | 64 pixels   | 2 double long words (4 longwords)
---------------------------------------------------------------
Wider sprites are not available under all conditions.
The  copper  doesn't read the spritelist in the same way regarding the wide
you choose for your sprite

The adress of a 16 pixels wide sprite must be multiple of 2
The adress of a 32 pixels wide sprite must be multiple of 4
The adress of a 64 pixels wide sprite must be multiple of 16

16 pixels wide reading:

word C1, word C2
word A1, word B1
.
.
.
word An, word Bn
$0000 0000

C1=first control word
C2=second control word

Ai and Bi are combined via OR to form the sprite

32 pixels wide reading:

	CNOP	0,8		;ALIGN 64 BIT

SPRITE32:			;EXAMPLE OF 32 PIXELS WIDE AGA SPRITE
VSTART:
	dc.b 0		;LONG C1
HSTART:
	DC.b 0
	DC.W 0
VSTOP:
	DC.b 0,0	;LONG C2
	dc.w 0
 dc.L %00000000000000111100000000000000,%0000000000001000000000000000000;sprite
 dc.L %00000000000011111111000000000000,%0000000000010111100000000000000
long A3, long B3
.
.
.
long An, long Bn
	DC.W	0,0,0,0		;END OF THE SPRITE

C1=first control long
   the  first control word is the high word of C1.  The low word of C1 must
   contain the second control word.
C2=second control long
   the second control word is the high word of C2. Low word of C2 is $0000

Ai and Bi are combined via OR to form the sprite

64 pixels wide reading:

	CNOP	0,8		;ALIGN 64 BIT

SPRITE64:			;EXAMPLE OF 32 PIXELS WIDE AGA SPRITE
VSTART:
	DC.B	0		;DOUBLE C1
HSTART:
	DC.B	0
	DC.W	0
	DC.L	0
VSTOP:
	DC.B	0,0		;DOUBLE C2
	DC.W	0
	DC.L	0
double A1, double B1
.
.
.
double An, double Bn
	DC.W	0,0,0,0,0,0,0,0	;END OF THE SPRITE

C1=first control double
   C1=W3:W2:W1:W0 (Wi=words)
   W3 is first control word
   W2 and W1 are second control word
C2=second control double
   C2=W3:W2:W1:W0 (Wi=words)
   W3 is second control word

Ai and Bi are combined via OR to form the sprite

***************************************************************************

Moving sprites with 1/4 pixels precision: (from Yragael)

Use bits 3 and 4 of the second control word of a sprite to adjust its
position to the 1/4 pixel in lowres (every pixel in SuperHires):

 bit 0 of second control word=bit 2 horizontal position
 bit 3 of second control word=bit 0 horizontal position
 bit 4 of second control word=bit 1 horizontal position

 The position of a sprite is now coded on 11 bits and no more 9 bits !

***************************************************************************
Change the sprite palette:

 All  sprites  used to be displayed with ONE 16 colors palette.  The result
used to be the following:

Sprites | Colors
------------------
   0-1  |  00-03
------------------
   2-3  |  04-07
------------------
   4-5  |  08-11
------------------
   6-7  |  12-15
------------------

 So you could just use ONE palette to display sprites.  This palette ranged
from  color  00  to color 15.  Now you can display odd sprites in a palette
different from the one used to display even sprites.
 Since 256 colors are available on AGA chipset, this give 16 palettes of 16
colors  each.  You can choose which one will be used to display odd sprites
and  which one will be used to display even sprites.  The colors associated
to a sprite in the 16 colors palette it uses is the same as usual.  I mean:

Sprites |            Colors
-------------------------------------------
   0    | 00-03 of the even sprites palette
-------------------------------------------
   2    | 04-07 of the even sprites palette
-------------------------------------------
   4    | 08-11 of the even sprites palette
-------------------------------------------
   6    | 12-15 of the even sprites palette
-------------------------------------------
   1    | 00-03 of the odd sprites palette
-------------------------------------------
   3    | 04-07 of the odd sprites palette
-------------------------------------------
   5    | 08-11 of the odd sprites palette
-------------------------------------------
   7    | 12-15 of the odd sprites palette
-------------------------------------------

 Bits  7  to  4  of  register $DFF010C are used to choose the number of the
palette  used to display even sprites, bits 3 to 0 of register $DFF010C are
used to choose the palette used to display odd sprites.

 So, for even sprites:

bit 7 | bit 6 | bit 5 | bit 4 | First color of the sprite palette
-------------------------------------------------------------------------
  0   |   0   |   0   |   0   | $0180/palette 0 (color 0)
-------------------------------------------------------------------------
  0   |   0   |   0   |   1   | $01A0/palette 0 (color 15)
-------------------------------------------------------------------------
  0   |   0   |   1   |   0   | $0180/palette 1 (color 31)
-------------------------------------------------------------------------
  0   |   0   |   1   |   1   | $01A0/palette 1 (color 47)
-------------------------------------------------------------------------
  0   |   1   |   0   |   0   | $0180/palette 2 (color 63)
-------------------------------------------------------------------------
  0   |   1   |   0   |   1   | $01A0/palette 2 (color 79)
-------------------------------------------------------------------------
  0   |   1   |   1   |   0   | $0180/palette 3 (color 95)
-------------------------------------------------------------------------
  0   |   1   |   1   |   1   | $01A0/palette 3 (color 111)
-------------------------------------------------------------------------
  1   |   0   |   0   |   0   | $0180/palette 4 (color 127)
-------------------------------------------------------------------------
  1   |   0   |   0   |   1   | $01A0/palette 4 (color 143)
-------------------------------------------------------------------------
  1   |   0   |   1   |   0   | $0180/palette 5 (color 159)
-------------------------------------------------------------------------
  1   |   0   |   1   |   1   | $01A0/palette 5 (color 175)
-------------------------------------------------------------------------
  1   |   1   |   0   |   0   | $0180/palette 6 (color 191)
-------------------------------------------------------------------------
  1   |   1   |   0   |   1   | $01A0/palette 6 (color 207)
-------------------------------------------------------------------------
  1   |   1   |   1   |   0   | $0180/palette 7 (color 223)
-------------------------------------------------------------------------
  1   |   1   |   1   |   1   | $01A0/palette 7 (color 239)
-------------------------------------------------------------------------

Another tab for bits 0 to 3 (even) and 4 to 7 (odd) of register $dff010C.

bit 3 | bit 2 | bit 1 | bit 0 | Even sprites
bit 7 | bit 6 | bit 5 | bit 4 | Odd Sprites
------+-------+-------+-------+------------------------------------------
  0   |   0   |   0   |   0   | $0180/palette 0 (coulor 0)
  0   |   0   |   0   |   1   | $01A0/palette 0 (color 15)
  0   |   0   |   1   |   0   | $0180/palette 1 (color 31)
  0   |   0   |   1   |   1   | $01A0/palette 1 (color 47)
  0   |   1   |   0   |   0   | $0180/palette 2 (color 63)
  0   |   1   |   0   |   1   | $01A0/palette 2 (color 79)
  0   |   1   |   1   |   0   | $0180/palette 3 (color 95)
  0   |   1   |   1   |   1   | $01A0/palette 3 (color 111)
  1   |   0   |   0   |   0   | $0180/palette 4 (color 127)
  1   |   0   |   0   |   1   | $01A0/palette 4 (color 143)
  1   |   0   |   1   |   0   | $0180/palette 5 (color 159)
  1   |   0   |   1   |   1   | $01A0/palette 5 (color 175)
  1   |   1   |   0   |   0   | $0180/palette 6 (color 191)
  1   |   1   |   0   |   1   | $01A0/palette 6 (color 207)
  1   |   1   |   1   |   0   | $0180/palette 7 (color 223)
  1   |   1   |   1   |   1   | $01A0/palette 7 (color 239)
-------------------------------------------------------------------------

********************     REALLY IMPORTANT   ************************

Bitplanes, sprites and copperlists must be, under
certain circumstances, 64-bit aligned under AGA. Again to benefit from
maximum bandwitdh bitplanes should also only be multiples of 64-bits wide,
so if you want an extra area on the side of your screen for smooth blitter
scrolling it must be *8 bytes* wide, not two as normal.

This also raises another problem. You can no longer use AllocMem() to
allocate bitplane/sprite memory directly.

Either use AllocMem(sizeofplanes+8) and calculate how many
bytes you have to skip at the front to give 64-bit alignment
(remember this assumes either you allocate each bitplane
individually or make sure the bitplane size is also an
exact multiple of 64-bits), or you can use the new V39
function AllocBitMap()


For example:

      CNOP  0,8
sprite   incbin "myspritedata"

      CNOP  0,8
bitplane incbin "mybitplane"

and so on.

IF YOU FORGOT TO ALIGN 64 BITS THE PICTURE WILL APPEAR CUTTED.

A common error is unwanted sprites pointing at address $0.
If the longword at address $0 isn't zero you'll get some funny looking
sprites at unpredictable places.

The right way of getting rid of sprites is to point them to an address
you for sure know is #$00000000 (0.l), and with AGA you may need to
point to FOUR long words of 0 on a 64-bit boundary

***************************************************************************

USING THE SUPERHIRES MODE (From ECS Machines like a500+,a600)

To  use  the  SuperHires  mode  (1280  pixels  wide), just use the bit 6 of
register $0100

bit 6 | Mode SuperHires
-----------------------
  0   | Non selectionne
-----------------------
  1   | Selectionne
-----------------------

***************************************************************************

SWITCHING THE PALETTE (From YRAGAEL & JUNKIE doc)

 You  can switch colors in the palette.  A switching operation
between color n∞A and color n∞B is defined as follows:

 - Contents of hardware color registers aren't modified

 - All  which  used  to  be  displayed  using color n∞A is now
   displayed  using  color  n∞B,  and  all  which  used  to be
   displayed with color n∞B is now displayed with color n∞B

 Bits 15 to 8 of register $DFF10C are used for switching:

 Bit          15 14 13 12 11 10 09 08 
 Name         S7 S6 S5 S4 S3 S2 S1 S0

 When  a  Sn  bit  is  selected, the hardware works on the 256
colors palette, starting from color 00:

 - Group  of  2^n  colors  from  color  00 to color (2^n)-1 is
   switched  with  group of 2^n colors from color 2^n to color
   2^n+(2^n)-1

 - Group of 2^n colors from color 2*2^n to color 2*2^n+(2^n)-1
   is  switched  with  group of 2^n colors from color 3*2^n to
   color 3*2^n+(2^n)-1

 - ...

 The  switching  operation ends when the hardware doesn't find
any more groups of colors to switch.

 Eg: Bit Sn=1 is selected. Here is what the palette looks like
     before and after the switching operation.  The copperlist
     is absolutely not modified:

     Before switching | After switching
     ---------------------------------
         Color 00     |   Color 02
         Color 01     |   Color 03
         Color 02     |   Color 00
         Color 03     |   Color 01
         Color 04     |   Color 06
         Color 05     |   Color 07
         Color 06     |   Color 04
         Color 07     |   Color 05
         ...          |   ...

      Colors have been switched, using groups of 2^1=2 colors.

 You can't switch one and only color.  If you decide to modify
the Sn bits, this will affects the whole palette.

 Switching  operation  can  be  combined.  If more than one Sn
bits   are   selected   in  register  $DFF10C,  the  switching
operations for each bits will be executed one after the other,
starting from bit S0 to bit S8.

 Eg: $DFF10C  contains $0500.  Bits S0 and S2 are selected The
     hardware  first  switches the palette using groups of 2^0
     colors,  and  THEN  sitches  the  resulting palette using
     groups of 2^2 colors:

     Before switching | Switching S0 | Switching S2
     ---------------------------------------------
         Color 00     |   Color 01   |  Color 05
         Color 01     |   Color 00   |  Color 04
         Color 02     |   Color 03   |  Color 07
         Color 03     |   Color 02   |  Color 06
         Color 04     |   Color 05   |  Color 01
         Color 05     |   Color 04   |  Color 00
         Color 06     |   Color 07   |  Color 03
         Color 07     |   Color 06   |  Color 02
         Color 08     |   Color 09   |  Color 13
         Color 09     |   Color 08   |  Color 12
         Color 10     |   Color 11   |  Color 15
         Color 11     |   Color 10   |  Color 14
         Color 12     |   Color 13   |  Color 09
         Color 13     |   Color 12   |  Color 08
         Color 14     |   Color 15   |  Color 11
         Color 15     |   Color 14   |  Color 10
         ...          |   ...        |  ...

***************************************************************************

		VGA/PRODUCTIVITY 640x480 not interlaced

This resolution is supported on Amiga from the first ECS machines, and it
requires a multiscan monitor. Is used by programs like AMAX, as 4 colours
productivity resolution.
This resolution is MUCH improved in the AGA machines: now is possible to
display 256 or HAM8 screens in 640x480 not interlaced, and much A1200/A4000
users have a multiscan monitor, so why not USE that resolution???
The best way is to add a monitor selection request before start the demo/game,
because why made VGA ONLY demos??

   NTSC (525 lines, 227.5 colorclocks per scan line)
   PAL  (625 lines, 227.5 colorclocks per scan line)
   VGA  (525 lines, 114.0 colorclocks per scan line)

Programmable synchronization is implemented through five new enhanced
Agnus registers:

   VSSTRT    W   A     Vertical line position for VSYNC  start
   VSSTOP    W   A     Vertical line position for VSYNC  stop
   HSSTRT    W   A     Horizontal line position for HSYNC  start
   HSSTOP    W   A     Horizontal line position for HSYNC  stop
   HCENTER   W   A     Horizontal position for Vsync on interlace

A reasonable composite can be generated by setting HCENTER half a
horizontal line from HSSTRT, and HBSTOP at (HSSTOP-HSSTRT) before HCENTER,
with HBSTRT at (HSSTOP-HSSTRT) before HSSTRT.

Programmable blanking is implemented through four new ECS Agnus registers:

   HBSTRT    W   A     Horizontal line position for HBLANK start
   HBSTOP    W   A     Horizontal line position for HBLANK stop
   VBSTRT    W   A     Vertical   line position for VBLANK start
   VBSTOP    W   A     Vertical   line position for VBLANK stop

To change the horizontal frequency from 15Khz (TV,1084 monitor) to 31Khz is
needed to change the register BEAMCON0 ($dff1dc) and set the right values on
other ECS registers like that:

	LEA	$DFF000,A0
	MOVE.W	#%0001101110001000,$1DC(A0)	;BEACON0
				;3 - COMPOSITE BLANK OUT TO CSY PIN
				;7 - VARIABLE BEAM COUNTER COMPARATOR ENABLED
				;8 - VARIABLE HORIZONTAL SYNC ENABLED
				;9 - VARIABLE VERTICAL SYNC ENABLED
				;11- DISABLE LONGLINE/SHORTLINE TOGGLE
				;12- VARIABLE VERTICAL BLANK ENABLED
	MOVE.W	#$71,$1C0(A0)	;HTOTAL - HIGHEST NUMBER COUNT, HORIZ LINE
	MOVE.W	#8,$1C4(A0)	;HBSTRT - HORIZONTAL LINE POS FOR HBLANK START
	MOVE.W	#14,$1DE(A0)	;HORIZONTAL SYNC START
	MOVE.W	#$1C,$1C2(A0)	;HORIZONTAL LINE POSITION FOR HSYNC STOP
	MOVE.W	#$1E,$1C6(A0)	;HORIZONTAL LINE POSITION FOR HBLANK STOP
	MOVE.W	#$46,$1E2(A0)	;HORIZONTAL POSITION FOR VSYNCH IN INTERLACE
	MOVE.W	#$20C,$1C8(A0)	;VTOTAL - HIGHEST NUMB VERTICAL LINE
	MOVE.W	#0,$1CC(A0)	;VERTICAL LINE FOR VBLANK START
	MOVE.W	#3,$1E0(A0)	;VERTICAL SYNC START
;	MOVE.W	#$200,$1E4(A0)
	MOVE.W	#$100,$1E4(A0)
	MOVE.W	#5,$1CA(A0)	;VERTICAL LINE POSITION FOR VSYNC STOP
	MOVE.W	#$1D,$1CE(A0)	;VERTICAL LINE FOR VBLANK STOP
	MOVE.W	#%00010010,$104(A0)	;
	MOVE.W	#%0000110000100001,$106(A0)	; 0 - external blank enable
						; 5 - BORDER BLANK
						; 10-11 AGA dual playfiled fix
	MOVE.W	#$1241,$100(A0) ;VGA screenmode with 2 colours... add the
;	MOVE.W	#$1245,$100(A0)	;required bitplanes if you are on AGA machine
				;but remember to move $3 on $dff1fc if you
				;need more than 2 colours (the old ECS mode)

Then point $dff080 to your copperlist. Remember that bit 0 of $dff100 must
be set to enable all the ECS+ features, and that if you need more than 4
colours you MUST set the bits 0 and 1 of $dff1fc and align bitmaps to
64 bits addresses... good luck and remember that the monitor selection must
be a WINDOW or another OS FRIENDLY request, because who has a multiscan
monitor runs the WB in VGA mode. then after you will start to BASH the METAL
in VGA or 15Khz mode.

	An Example of VGA copperlist:	(Tested on A1200+VGA monitor)

COPPERLIST:	;offcourse remember to set the ECS registers before!

	;	sprite pointers

	dc.l	$C01FFFE
	dc.l	$1800F00
BPLP:
	dc.l	$E00000		;bitplane pointers
	dc.l	$E20000		;point here a 640x480 picture
	dc.l	$E40000		;same as a laced one
	dc.l	$E60000
	dc.l	$E80000
	dc.l	$EA0000
	dc.l	$EC0000
	dc.l	$EE0000

	DC.W	$180,0		;modulo
	DC.W	$10A,0

	dc.W	$8E,$1c45	;diwstrt
	dc.W	$90,$ffe5	;diwstop
	dc.W	$92,$0018	;ddfstrt
	dc.W	$94,$0068	;ddfstop
	dc.w	$1e4,$100

	;here the palette... same as the normal palette on AGA

	dc.w	$1fc,$8003	
	DC.W	$100,$1241	;bplcon0

	dc.l	$FFFFFFFE	;end of coplist
	dc.l	$FFFFFFFE


                         Amiga TO VGA CABLE!	(By Gabry)

 That are the instructions about how to make a amiga-vga cable,
so that you should be able to use a standard, cheap, coloured VGA
monitor (used for the shit PC's) to see the ECS/AGA video wonderings!
 Infact the possesion of a VGA monitor gives you the chance to use
the famous Productivity mode (640x480 non-interlaced or 640x990
laced!) with prgs that support it.
 Remember that on VGA only monitors you will watch only 31Khz not laced
 resolutions, not normal GAMES or DEMOS that open an own copperlist. To
 watch also normal stuff you have to use also a normal monitor or a TV
 with a cable switcher (boring) or you must use a C= 1950/1960/1940/1942 or
 other MULTISYNC monitors that are capable to display also 15Khz screens.
 The cable should fit for every kind of VGA and SuperVGA monitor,
but if there would be problems,

 1-check all connections and bridges
 2-check out your monitor frequencies (they should be 31.5 to 35.5
   the horizontal, and 50 to 90 Hz the vertical one)
 3-check out if you have the ECS chipset at least (amiga 500 or
   greater)
 4-check out if your software support the productivity modes.

 Remember also that only with the Multiscan and VGAOnly (supplied
with WB 3.0 disks) drivers loaded you can activate the monitor by
WB. I suggest you to use prgs like ForceMonitor (PD) to make
all old interlaced prgs run in productivity, too.

Amiga I/O Connector Pins / Video

Video ...DB23 MALE
------------------
For A500, A1000, A1200, A2000 and A3000 unless otherwise stated

   1   XCLK* (external clock)    13   GNDRTN (Ground Return for XCLKEN*)
   2   XCLKEN* (xclk enable)     14   ZD* (Genlock overlay)
   3   RED                       15   C1* (Cock out)
   4   GREEN                     16   GND
   5   BLUE                      17   GND
   6   DI (Digital Intensity)    18   GND
   7   DB (Digital blue)         19   GND
   8   DG (Digital green)        20   GND
   9   DR (Digital red)          21   -5 VOLT POWER(A1000,A2000,A3000,A4000)
   10  CSYNC* (composite sync)        -12 VOLT POWER (A500,A1200)
   11  HSYNC* (horizontal sync)  22   +12 VOLT POWER
   12  VSYNC* (vertical sync)    23   +5 VOLT POWER

****What you need:

 1 DB 25 pin female connector (for the amiga)
 1 DB 15 pin female connector (for the VGA monitor)
 15 cm (max) of 6 pole cable
 1 friend that makes the work if you are lazy or not enough cool

****The connections:	; (that cable dont works on some VGA monitors)
			; (Let me know if you find better connections)

VGA Monitor         Amiga DB23
Pin 1  (Red) ----- Pin 3  (An Red)
Pin 2  (Grn) ----- Pin 4  (An Green)
Pin 3  (Blu) ----- Pin 5  (An Blu)
Pin 13 (H.S) ----- Pin 11 (Horizontal Sync 47 Ohm)
Pin 14 (V.S) ----- Pin 12 (Vertical Synch 47 Ohm)
Pin 5,6,7,8,10,11 ---- Pin 17,18,19	(Ground)


****Remarks:

 VGA side:

Pin 5 the self-test input for the monitor
      (a dead pin on standard VGA cards);

Pin 6,7,8 the video analogic RGB ground;
          connected to the video ground on the amiga
          (pin 17,18,19)

Pin 10 the Sync ground

Pin 11 monitor identification (connected to pin 5 and 10)

(Remember to bridge the pin 5,6,7,8,10,11 together on the
 VGA side and the pin 17,18,19 on the amiga one!)

  Written with an Amiga 1200 in 640x480 (non laced!)
   screen on a VGA monitor...   18.08.93 Gabry

Monitor Problems (FROM HOWTOCODE 7)
----------------

Unfortunately the A1200/AGA chipset does not have the deinterlacer
circuitry present in the Amiga 3000, but instead has new 'deinterlaced'
modes. This gives the A1200 the capability of running workbench (and
almost all OS legal software) the ability to run flicker free at high
resolution on a multiscan or Super VGA monitor.

Unlike the Amiga 3000 hardware it produces these flicker free modes
by generating a custom copperlist, so any programs that generate
their own copperlists will continue to run at the old flickery 15Khz
frequency unless they add their own deinterlace code.

This is a big problem for many A1200 owners as there are very few multiscan
monitors that support 15Khz displays now. Most multiscan monitors will
not display screen at less than 27Khz. People with A1200/4000 and this
kind of monitor *CANNOT* view any games or demos that write their own
copperlists. (If anybody starts to add a monitor selection...)

Can you help them out? Unfortunately it's not easy. Deinterlacing is
done in AGA by doing two things.

Firstly different horizontal and vertical frequencies are set (These
are set to unusual values for anyone used to Amiga or PC displays!
For example, DblPal is set by default to 27Khz horizontal and 48Hz
vertical) It's important to realise that the vertical frequency
changes too!

Secondly, for non-interlaced screens, bitplane scandoubling is enabled (bit
BSCAN2 in FMODE) This repeats each scanline twice. A side effect of this is
that the bitplane modulos are unavailable for user control.

SO: Write nasty copperlist code to work with both standard and
promoted displays (a good idea!) with a monitor selection before

The Commodore 1084/1085, Philips 8833/8852 and the
Commodore 1950/1960/1940/1942 monitors are all capable of running 15Khz
screens.

***************************************************************************

allocbitmap "graphics.library" V39 new JSR for allocate GFX bitmap

AllocBitMap -- Allocate a bitmap and attach bitplanes to it. (V39)

bitmap=AllocBitMap(sizex,sizey,depth, flags, friend_bitmap)
          -918       d0    d1    d2     d3       a0

struct BitMap *AllocBitMap(ULONG,ULONG,ULONG,ULONG, struct BitMap *);

Allocates and initializes a bitmap structure. Allocates and initializes
bitplane data, and sets the bitmap's planes to point to it.

IN:
   sizex = the width (in pixels) for the bitmap data.

   sizey = the height (in pixels).

   depth = the number of bitplanes deep for the allocation.

   flags = BMF_CLEAR - Clear the bitmap.

           BMF_DISPLAYABLE - bitmap displayable on AGA machines in
           all modes.

           BMF_INTERLEAVED - bitplanes are interleaved

   friend_bitmap = pointer to another bitmap, or NULL. If this pointer
                   If present, bitmap will be allocated so blitting
                   between the two is simplified.

For Free the bitmap allocated use FREEBITMAP(V39)

FreeBitMap -- free a bitmap created by AllocBitMap

FreeBitMap(bm)
  -924     a0

VOID FreeBitMap(struct BitMap *)

Frees bitmap and all associated bitplanes

***************************************************************************

----- AND REMEMBER THAT AGA MACHINES HAVE A 68020 OR GREATER PROCESSOR -----

So why dont use it? the processor will run faster especially if you have 32 bit
fast ram and you load the code in that 32bit fastram. The speed will be DOUBLE
or *3 or *5 on A4000, if you load the code in fastram intead of chipram.
And remember that you have a 32bit processor, so the speed will be more if
you align the routines to 32 bit addresses (1 longword), using the command
CNOP 0,4 before all the routines and the datas.

WARNING: from 68010 the VBR can be chaged from $0 to fast ram, so all
the interrupt vectors (like $6c) and trap vectors (like $80) will be in
fast ram at VBR+$6c and VBR+$80... that is not a problem if you know that!
is possible to move to $0 the VBR to make old software compatible, but NOW
we must code NEW software enjoyng the (little) speed increasing of the VBR
in fast RAM... so all the needed is to KNOW where is the VBR and made offsets
from the VBRBASE, like:

GETVBR:
	MOVE.L	4.W,A6
	SUBA.L	A1,A1
	btst.b	#0,$129(a6)	; Tests for a 68010 or higher Processor
	beq.S	INTDONE		; is a 68000!!
	LEA	SUPERCODE(PC),A5 ;is a 68010, or 20, or 30, or 40, or 60 or ?
	JSR	-$1E(A6)	; execute 'supercode' routine in supervisor
	BRA.S	INTDONE

	CNOP	0,4	;32 bit align (longword)
**********************EXCEPTION CODE IN SUPERVISOR 010 AND UP**************
SUPERCODE:
	dc.l  	$4e7a9801	; Movec Vbr,A1 (68010 or higher instruction)
				; that is the hexadecimal value because not all
				; assemblers can assemble 68010 instructions.
	RTE			; return from Exception...
***************************************************************************
	CNOP	0,4	;32 bit align (longword)
INTDONE:
	LEA	$DFF000,A5	;
	LEA	VBRBASE(PC),A0
	move.l  a1,(A0)		; SAVE THE VBRBASE IN 'VBRBASE' LABEL
	LEA	OLDINT(PC),A2
	move.l	$6c(a1),(A2)	; $6c(a1) (old interrupt address) saved
	....

The VBR is set to $0 at the boot, so a trakmo or a demo that runs from a disk
with own startup-sequence will work also with $6c.w and $80.w, but the VBR
is moved to FAST RAM by the SETPATCH command or by other utility.

If you code 3d or fractal routines and you place them on 32bit fast ram the
speed will change on different processors, instead if you move all the code
in CHIP ram or on a fixed address (via ORG&LOAD) in CHIP probably the speed
will be the same on all processors. This mean that the routines that dont like
the speed of A4000 will be placed in CHIP ( section NAME,CODE_C ) and the
routines that like more speed than A1200 without expansion will be placed in
the 32 BIT fastram (if exists, via section name,CODE ). If you need routines
located on fixed addresses try to place much parts on FAST. I think the best
way to code is to make relocatable code, with sections in FAST, and crunched
with Powerpacker instead of absolute addresses crunchers.If you code a trackmo,
then try to detect where is the fast ram, and move the right code on it.
For example the A4000 have the 32 bit fast ram from $07c00000 to $07ffffff.

How to use the CACHE memory: on 68020+ there is a 256byte Instruction Cache,
that speeds up the operations because the instructions on loops are read
from CACHE instead of from RAM. The only problem is that if you use self
modifyng code in some cases the change will be not done...  example:

	MOVE.W #0,d6	; if cache is not cleared before will bw loaded the
CHANGEX: EQU *-2	; instruction stored in CACHE before changing it,
			; and you will cause no change of values or crashs!
.			; (Icache on 68020/30 is 256 bytes,on 040 is 4096 b.)
.
	ADDI.W #$50,CHANGEX	;Change the instruction
.
. Here you have to clear the CACHE! (flush)
.

Clear the cache before execute changed instructions, or the modified
instruction will be read from the cache and will be the same MOVE.W #0,D6.

 (From howToCode 7)
For good performance, it is critical that you code your important loops
to execute entirely from the on-chip 256-byte Icache. A straight line loop
258 bytes long will execute slower than a 254 byte one.
A loop of 258 bytes will only cause a cache miss (a word at either
the beginning or the end of the loop). Only a loop of 512 bytes will
cause the entire cache to miss. Of course a loop of 254 bytes will
be faster than one of 258 bytes, but only marginally.
....................
On 68030 and 68040 there is also a DataCache, that loads the DATA,
and after reads from cache instead of from RAM. If you change the data
will be happen the same of Instruction Cache: the modified data can be
read from cache. (256 byte on 68030, 4096 bye on 68040)
-ON AMIGA THE DATA CACHE WORKS ONLY ON FAST RAM-

 Example:

SCROLLVALUE:
	DC.W	; will be loaded in Data Cache only if in FAST RAM!
.
.
	ADDQ.W	#1,SCROLLVALUE	;change the data
.
.	; now clear the DCACHE if SCROLLVALUE is in fastram or it will
.	; be the same value in cache!
.

Offcourse remember: to make your code faster on 030+ use tabs 254 bytes
long and load them in FAST RAM!

Do not remove IntructionCache or DataCache if is possible, enjoy it! and if
you want to remove it, do not assume that the CACR bits are the same on all
processors! much demos like DESERT DREAMS/KEFRENS crash on 040 because there
is a REMOVE CACHE routine that sets the bits of 68020/30 CACR...
before changing CACR you MUST detect the processor, then after enable/disable!

NOCACHE2030:	;if a 020 or 030 is detected

	BSR.W	CACHECLR	; clear the cache before enable/disable!
	dc.l	$4e7a0002	;movec	cacr,d0 (68020+ instruction)
	BCLR.L	#8,d0		;Data Cache 68030 (BCLR = disabled)
	BCLR.L	#0,d0		;Instruction Cache 68020-30 (BCLR = disabled)
	dc.l	$4e7b0002	;movec	d0,CACR (68020+ instruction)
	rte

NOCACHE40:

	BSR.W	CACHECLR	; clear the cache before enable/disable!
	dc.l	$4e7a0002	;movec	cacr,d0 (68020+ instruction)
	BCLR.L	#31,d0		;Data Cache 68040 (BCLR = disabled)
	BCLR.L	#15,d0		;Instruction Cache 68040 (BCLR = disabled)
	dc.l	$4e7b0002	;movec	d0,CACR (68020+ instruction)
	rte

NOTE: (from C= autodocs V40)

	For all current Amiga models, Chip memory is set with Instruction
	caching enabled, data caching disabled.  This prevents coherency
	conflicts with the blitter or other custom chip DMA.  Custom chip
	registers are marked as non-cacheable by the hardware.

TIPS: (From HOWTOCODE 7)

Write-accesses to chip-ram incur wait-states. However, other processor
instructions can execute while results are being written to memory:

        move.l  d0,(a0)+        ; store x coordinate
        move.l  d1,(a0)+        ; store y coordinate
        add.l   d2,d0           ; x+=deltax
        add.l   d3,d1           ; y+=deltay

;       will be slower than:

        move.l  d0,(a0)+        ; store x coordinate
        add.l   d2,d0           ; x+=deltax
        move.l  d1,(a0)+        ; store y coordinate
        add.l   d3,d1           ; y+=deltay

	(From HowToCode 7)
The 68020 adds a number of enhancements to the 68000 architecture,
including new addressing modes and instructions. Some of these are
unconditional speedups, while others only sometimes help:

 (to assemble 68020+ instructions use TFA ASMONE or DEVPAC 3.x)

o   Scaled Indexing. The 68000 addressing mode (disp,An,Dn) can have
    a scale factor of 2,4,or 8 applied to the data register on the 68020.
    This is totally free in terms of instruction length and execution time.
    An example is:

        68000                   68020
        -----                   -----
        add.w   d0,d0           move.w  (0,a1,d0.w*2),d1
        move.w  (0,a1,d0.w),d1

o   16 bit offsets on An+Rn modes. The 68000 only supported 8 bit
    displacements when using the sum of an address register and another
    register as a memory address. The 68020 supports 16 bit displacements.
    This costs one extra cycle when the instruction is not in cache, but is
    free if the instruction is in cache. 32 bit displacements can also be
    used, but they cost 4 additional clock cycles.

o   Data registers can be used as addresses. (d0) is 3 cycles slower than
    (a0), and it only takes 2 cycles to move a data register to an address
    register, but this can help in situations where there is not a free
    address register.

o   Memory indirect addressing. These instructions can help in some
    circumstances when there are not any free register to load a pointer
    into. Otherwise, they lose.

    New instructions:

o   Extended precision divide an multiply instructions. The 68020 can
    perform 32x32->32, 32x32->64 multiplication and 32/32 and 64/32
    division. These are significantly faster than the multi-precision
    operations which are required on the 68000.

o   EXTB. Sign extend byte to longword. Faster than the equivalent
    EXT.W EXT.L sequence on the 68000.

o   Compare immediate and TST work in program-counter relative mode
    on the 68020.

o   Bit field instructions. BFINS inserts a bitfield, and is faster
    than 2 MOVEs plus and AND and an OR. This instruction can be used
    nicely in fill routines or text plotting. BFEXTU/BFEXTS can extract
    and optionally sign-extend a bitfield on an arbitrary boundary.
    BFFFO can find the highest order bit set in a field. BFSET, BFCHG,
    and BFCLR can set, complement, or clear up to 32 bits at arbitrary
    boundaries.

o   On the 020, all shift instructions execute in the same amount of time,
    regardless of how many bits are shifted. Note that ASL and ASR are
    slower than LSL and LSR. The break-even point on ADD Dn,Dn versus LSL
    is at two shifts.

o   Many tradeoffs on the 020 are different than the 68000.

o   The 020 has PACK an UNPACK which can be useful.

	-the 68040 CopyBack-

The reason the 68040 is different is that it has a "copyback" mode. In this
mode (which WILL be used by people because it increases speed dramatically)
writes get cached and aren't guaranteed to be written out to main memory
immediately. Thus 4 subsequent byte writes will require only one longword
main memory write access. Now you might have heard that the 68040 does
bus-snooping. The odd thing is that it doesn't snoop the internal cache
buses!
Thus if you stuff some code into memory and try to execute it, chances are
some of it will still be in the data cache. The code cache won't know about
this and won't be notified when it caches from main memory those locations
which do not yet contain code still to be written out from the data caches.
This problem is amplified by the absolutely huge size of the caches.
So programs that move code, like the explosion algorithms, need to do a
cache flush after being done.
On the a4000 the copyback and the MMU are off at the boot (after a power off)
so you can be sure that there are no problems if you run a trackmo or a demo
from a disk, but from WB 3.0 the mmu and the CopyBack are activated (using the
68040.library) and you have to consider that.
The better thing is to detect if we are runnning on A4000 and disable the MMU
with that routine:

	MOVE.L	4.W,A6
	btst.b	#3,$129(a6)	; Tests for a 68040 or higher Processor
	bne.S	P68040		;
	rts

P68040:
	move.l	4.w,a6
	lea	NO040MMU(PC),a5
	jsr	-$1e(a6)	;execute NO040MMU as exception
	rts

NO040MMU:			;(Thanx to Rhino/team HOI and Remote Control)
	lea	$FFC000,a0
	dc.l	$4e7b8004	; movec a0,ITT0
	dc.l	$4e7b8005	; movec a0,ITT1
	dc.l	$4e7b8007	; movec a0,DTT1
	lea	$c040,a0
	dc.l	$4e7b8006	; movec a0,DTT0
	lea	$30000,a0
	dc.l	$4e7b8806	; movec a0,URP ;
	dc.l	$4e7b8807	; movec a0,SRP ;Supervisor Root pointer reg.
	suba.l	a0,a0
	dc.l	$4e7b8003	; movec a0,TC ;translation code register
	rte
NOTE:
Much MMU disable routines have only a MOVEC A0,TC without other instructions
before... that works on 030 mmu, but cause a GREAT RESET+GURU on A4000/040.
Do not remove 68030 MMU, because some A3000's that loads kickstart in ram
crashs if you try to disable cache.

Blitter clears
--------------
If you use the blitter to clear large areas, you can generally
improve speed on higher processors (68020+) by replacing it by
a cache-loop that clears with movem.l instead:

        moveq  #0,d0
        moveq  #0,d1
        moveq  #0,d2
        moveq  #0,d3
        moveq  #0,d4
        moveq  #0,d5
        moveq  #0,d6
        sub.l  a0,a0
        sub.l  a1,a1
        sub.l  a2,a2
        sub.l  a3,a3
        sub.l  a4,a4
        sub.l  a5,a5

        lea    EndofBitplane,a6
        move.w #(bytes in plane/156)-1,d7
.Clear
        movem.l d0-d6/a0-a5,-(a6)
        movem.l d0-d6/a0-a5,-(a6)
        movem.l d0-d6/a0-a5,-(a6)
        dbf d7,.Clear

; final couple of movems may be needed to clear last few bytes of screen...

This loop was (on my 1200) almost three times faster than
the blitter.

With 68000-68010 you can gain some time by NOT using blitter-
nasty and the movem-loop.

*****************************************************************************
*       NOW READ HOW TO CODE DEMOS/GAMES THAT WORKS ON ALL MACHINES!        *
*****************************************************************************

Well, after an explanation of the NEW AGA features, I must also explain how
to find compatibility bugs. Having a powerful Amiga means also have to fix
a lot of old stuff! I fixed myself a lot of old and NEW! demos/games to work
on machines better than A500... is BORING! so I think is better to code
demos that dont need a fix to work.

Here I made a report of the bugs that cause an incompatibility also if
caches are disabled, VBR is to ZERO, and AGA is reset adding:

	dc.w	$1fc,0
	dc.w	$106,$c00
	dc.w	$10c,$11

In the Copperlist...

REPORT:

1) Demos crunched with an old absolute address CRUNCHER... most old decrunch
   routines cause a crash before execute the demo... I just decrunched them
   on A500 and I repacked them with STONECRUNCH 4 if absolute address or
   powerpacker if was relocatable code (better)

2) NO BLITTER WORK END WAIT BEFORE A NEW BLIT... especially in code
   older than 1990. That coders said: it works, so why add a waitblit
   routine?? but faster processors make the CRASH possible!

	LEA	$dff000,a5
WaitBlit0:
	BTST.B	#6,2(a5)
WaitBlit1:
	BTST.B	#6,2(a5)	; 2 times for a bug in very old chips
	BNE.S	WaitBlit1

3) Crap copperlist pointing that works only on 1.x kickstarts:

	move.l  4.w,a6		; execbase
	move.l  (a6),a6		; ???
	move.l  (a6),a6		; HAHAHA! GFXBASE???
	move.l	$26(a6),OLDCOP	; HAHAHA! SAVE OLD COPLIST???
	move.l	#MYCOP,$32(a6)	; DOUBLE HAHAHAHA! POINT COPLIST???
	...
   That great piece of crap code was on an ORACLE intro and on other old
   demos.. remember to OPEN gfxbase to save old coplist and to point the
   coplist with a MOVE.L #MYCOP,$dff080... is better.

4) self modyfing code: that will cause problems if Instruction cache is
   Enabled. Some examples:

	divu.w	#0,d0	; the value will be changed before execute, but
MYLABEL:		; with ICACHE enabled the instruction probably will
	EQU	*-2	; be read from CACHE unchanged.. and a DIVISION BY
			; ZERO will stop the fun.
or:

	JMP	0	; the address will be moved here.. but if cache is on
MYLABEL:		; we will have a GREAT JUMP TO 0!! with awesome GURU
	EQU	*-6	; (or EQU *-5, EQU *-4...)

There is a solution!! you need to CLEAR the cache before execute modified
instructions, or remove the self mod. tricks that are not useful... but
dont remove caches, enjoy it! the CLEAR CACHE routine is this:


CACHECLR:
	MOVEM.L	D0/A5-A6,-(SP)
	MOVE.L	4.W,A6		;EXECBASE IN A6
	BTST.B	#1,$129(A6)	;TESTS FOR A 68020+
	BEQ.S	NOCACHE
	BSR.S	DOCLEAR
NOCACHE:
	MOVEM.L	(SP)+,D0/A5-A6
	RTS

	CNOP	0,4

DOCLEAR:
	MOVE.L	4.W,A6		;EXECBASE IN A6
	LEA	CCLEAR(PC),A5
	JSR	-$1E(A6)	;Execute CCLEAR as supervisor
	RTS

	CNOP	0,4

CCLEAR:
	BTST.B	#3,$129(A6)	;TESTS FOR A 68040
	BNE.S	CLR040
				;CLEAR 68020/30 ICACHE AND 030 DCACHE
	ORI.W	#$700,SR	;DISABLE INTERRUPTS
	dc.l	$4E7A0002	;MOVEC	CACR,D0
	BSET.L	#3,D0		;CLEAR INSTRUCTION CACHE 020/030
	BSET.L	#11,D0		;CLEAR DATA CACHE 030
	dc.l	$4E7B0002	;MOVEC	D0,CACR
	RTE

	CNOP	0,4

CLR040:				;CLEAR 68040 ICACHE AND DCACHE
	dc.W	$F4F8		;CPUSHA	BC (OR	DC.W $F478 CPUSHA DC FOR DCAC)
	RTE

That routine work also on kickstart 1.x and must be called also after loading
code from disk or after memory (illegal) modification that could cause invalid
or stale data.

On 68030/68040 processors is available also the DATA CACHE, that make the
same job for DATAS, if are on FAST RAM.


5) CAPSLOCK FLASH ROUTINES: some demos have a routine that cause a flash of
   the CapsLock key in the keyboard, like ODISSEY demo by Alcatraz... that
   routine works well on a500,a1000,a2000,a3000,a4000 but cause a RESET on
   a1200!! so DO NOT USE THAT KIND OF ROUTINES or your demo will crash

CAPSLOCK:
	LEA	$BFE000,A2
	MOVEQ	#6,D1		; because the bit 6 of $bfee01 is the
				; input-output bit of $bfec01
	CLR.B	$801(A2)	; TODLO - bit 7-0 del timer a 50-60hz
				; reset timer
	CLR.B	$C01(A2)	;CLear the SDR (synchrous serial shitf
				;connected to the keyboard) - 8 bits -
DOFLASH:
	BSET	D1,$E01(A2)	; Output
	BCLR	D1,$E01(A2)	; Input
	CMPI.B	#50,$801(A2)	; Wait 50 blanks (CIA timer) 
	BGE.S	DONE
	BSET	D1,$E01(A2)	; Output
	BCLR	D1,$E01(A2)	; Input
	MOVE.W	$DFF01E,D0	; Intreqr in d0
	ANDI.W	#%00000010,D0	; checks for I/O PORTS 
	BEQ.S	DOFLASH
DONE:
  ; NOW ON A1200 the CRASH is DONE! (who knows what kind of keyboard has!)


6) CRAP REPLAYROUTINE:

I finded the bug in the PARADOX intro and other demos: the problem is the
replayroutine:

MT_MUSIC:
	MOVEM.L	D0-D4/D7/A0-A6,-(SP)
	LEA	0,A4	; WHY USE $0 for OFFSETS??? changing the first bytes
	....		; of mem you will cause a crash (on kick 3.0 for sure)

Change the $0 with a buffer!:

MT_MUSIC:
	MOVEM.L	D0-D4/D7/A0-A6,-(SP)
	LEA	LABEL,A4
	....

and at the end of routine place the buffer!
 
LABEL:
	dcb.b	50,0


7) ADDRESS ERRORS:

   use of $C00000 absolute address... some old stuff that require 1MB loads
   the high 512k of code to $C00000, where is placed the A500 expansion
   memory.. but with 1MB CHIP machines (a500+,a600...) this mem is placed
   from $80000 to $100000... and $C00000 not exists! if you want to place
   code in FAST RAM use the "SECTION name,CODE" option in assembler!

   Adressing modes: (From HowToCode 7)

Always pad out 24-bit addresses (eg $123456) with ZEROs in the high
byte ($00123456). Do not use the upper byte for data, for storing
your IQ, for scrolly messages or for anything else.
32 bit CPUs like the 020 use also high byte. Example:
  move.b #$ff,$00000004 will change 8 bits of the ExecBase pointer CRASHING!

Similarly, on non ECS machines the bottom 512k of memory was paged
four times on the address bus, eg:

	move.l #$12345678,$0

	move.l	$80000,d0	; d0 = $12345678
	move.l	$100000,d1	; d1 = $12345678
	move.l	$180000,d2	; d2 = $12345678

This does not work on ECS and upwards!!!! You will get meaningless
results if you try this, so PLEASE do not do it!

8) 68040 Problems: I finded that the demos/games that dont works on 040 and
   works on 020/030 have the only bug in the DISABLE CACHE ROUTINE: the
   coders added an instruction to disable caches that works on 020/030 and
   crash on 040... so the stuff without NOCACHE intructions works on A4000
   removing caches at the boot, instead who added a crap nocache routine
   made his production a4000 not compatible! (hi kefrens, digital....)

9) bad loaders: some demos/trackmo use a bad delay routine for the loader
   that feature a DBRA loop, that if is loaded on cache is too fast and
   cause errors... use CIA timers to wait!! and remember to clear the CACHE
   after data load!

10) Timing: do not use DBRA loops or many NOP's to syncronize your code, use
    vertical beam or CIA. And remember also that in faster processors you
    have to wait the beam more times to prevent flicks (if the routine is
    updating the bitplanes when the beam is painting them!) Example:

WAIT1:
	MOVE.L	$dff004,D0	; VPOSR
	LSR.L	#8,D0
	ANDI.W	#%111111111,D0	; Select only the VPOS bits
	CMPI.W	#255,D0		; wait line 255
	BNE.S	WAIT1

	JSR	DOTFLAG		; execute a routine

WAIT1:
	MOVE.L	$dff004,D0	; VPOSR
	LSR.L	#8,D0
	ANDI.W	#%111111111,D0	; Select only the VPOS bits
	CMPI.W	#300,D0		; wait line 300
	BNE.S	WAIT1

	JSR	VECTOR1		;

   With a multiwait you will be sure that routines will be executed in the
   same beam-time of a 68000 machine.
   I think is better to use VPOSR to synchronize the code, because using
   the $6c interrupt you have to reset the VBR and I noticed that some
   demos that use interrupts works bad many times.

11) Do not use the CLR instruction on $dffXXX registers, because with strobe
    registers (like $dff088) you will strobe it twice, and I noticed problems
    using clr with other registers, like $dff064.. 

	MOVE.W	#0,$DFF088	; no more CLR.W $dff088!

	MOVE.W	#0,$DFF064	; no more CLR.W $dff064

12) Remember to align the code and data to 32 bit addresses adding the
    command CNOP 0,4 before the labels. That will speed up the code if
    will be loaded in 32bit fast ram. But remember to align data to word
    almost to speed up 68020+ also if the code is in CHIP RAM

13) Do not set reserved bits in $dffXXX! use only the know bits of in the
    future your code will cause strange effects on more enhanced chips!

14) Remember to call a disable() ; JSR -$78(a6) ; before modify INTENA status
    at the start of your code! I fixed many intros adding this only and the
    enable() ; JSR -$7e(a6) ; at the end. Probably on kick 3.x there are
    system interrupt routines that cause problems if are not disabled

*****************************************************************************
   AMIGA RULES!   AMIGA RULES!   AMIGA RULES!   AMIGA RULES!   AMIGA RULES!
*****************************************************************************

A big Hello from me (RANDY!) to all the trainemakers and my friends around
the universe. Try to live in peace and code something to keep amiga alive.

Remember to add COMAX in the GREETINGSLIST of your 680x0 compatible demo if
you learned reading this doc! I like to read greetings on scrolltexts!


To contact COMAX call one of our boards:

 MINDBENDERS  #1   +39-10-676672
 MINDBENDERS  #2   +39-10-625930
 CIRCLE OF BLOOD   +39-30-8901112
 THE MOON          +39-81-7662581
 TOTAL ECLIPSE     +46-31-572545
 MOZART'S MANSION  +1-904-7650360

CODERS,AGA GRAPHICIANS write to:

	COMAX
	P.O. BOX 107
	55100 LUCCA
	ITALY

 (Offcourse no lamers... but who knows if a guy is really lame?)

        _________ _______      ____  ____      ____            _____
       /        ¨|      ¨\ <S>/   ¨\/   ¨\    /   ¨\______    /    ¨\
      //        ||       \\  //          \\  //    \\    ¨\  /     //
     //    \_____è  ____  \\//            \\/       \\    \\/     //
    //     /    ¨|  ¨\ |   \\              \\        \\    \\    //
   //           ||    \è    \\              \\__Äç    \\         /\
  //            ||           \\              \\  ¨     \\         \\
 //             ||            \\              \\__      \\         \\
 \\             ||            //  \ //        //| \     //   \\     \\
  \\   __________Ä________   /å___/\/\____   /å_è  \   /å____/\\    //
   \  /                   \  /            \  /      \  /       \   //
    \/                     \/              \/        \/         \  /
                                                                 \/
