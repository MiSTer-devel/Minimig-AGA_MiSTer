#include "or32_defs.h"
#include "spr_defs.h"

#define ROM_START 0x000000
#define RAM_START 0x400000

.extern		__stack
.extern		__data_start
.extern		__data_end
.extern		__data_rom
.extern   __text_start
.extern   __rom_size

.section	.stack, "aw", @nobits
.space		OR32_STACK_SIZE
_stack:	


.section	.vectors, "ax"	

/* this word holds firmware length */
.org      0
  .word   __rom_size

/* reset procedure */
.org      OR32_RESET_VECTOR_RAM
_reset:
real_reset:
  /* four cycles delay */
  l.nop   0x1
  l.nop   0x2
  l.nop   0x3
  l.nop   0x4

  /* go into supervisor mode */
  l.addi  r3,r0,SPR_SR_SM
  l.mtspr r0,r3,SPR_SR

  /* stack initialization */
  l.movhi r1,hi(__stack)
  l.ori   r1,r1,lo(__stack)

  /* clear r0 */
  l.movhi r0, 0x0

  /* rom copy */
  l.movhi r2, hi(RAM_START)
  l.ori   r2,r2,lo(RAM_START)
  l.movhi r3, hi(__data_end)
  l.ori   r3,r3,lo(__data_end)
  l.movhi r4, hi(ROM_START)
  l.ori   r4,r4,lo(ROM_START)
rom_copy_start:
  l.sfgeu r2,r3
  l.bf    rom_copy_end
  l.nop
  l.lwz	r5,0(r4)
  l.sw	0(r2),r5
  l.addi	r2,r2,4
  l.addi  r4,r4,4
  l.bnf	  rom_copy_start
  l.nop
rom_copy_end:

  /* continue executing from RAM - next instruction is now in RAM */
  l.movhi r3,hi(__text_start)
  l.ori   r3,r3,lo(__text_start)
  l.jr    r3
  l.nop
  
.section .text, "ax"
  l.nop
  
  /* bss initialization */
  l.movhi r2, hi(__bss_start)
  l.ori   r2,r2,lo(__bss_start)
  l.movhi r3, hi(__bss_end)
  l.ori   r3,r3,lo(__bss_end)
bss_init_start:
  l.sfgeu r2,r3
  l.bf    bss_init_end
  l.nop
  l.sw	0(r2),r0
  l.addi	r2,r2,4
  l.bnf	bss_init_start
  l.nop
bss_init_end:

  /* jump to main */
  l.movhi	r3,hi(main)
  l.ori	r3,r3,lo(main)
  l.jr	r3
  l.nop


/* or1200 soft mul & soft div */
#include "or32.S"

