/* system.h */
/* 2012, rok.krajnc@gmail.com */

#ifndef __SYSTEM_H__
#define __SYSTEM_H__

#include "spr_defs.h"
#include "or32_defs.h"


// system clock
#define SYS_CLOCK  50000000
#define SYS_PERIOD_NS 20


// NULL
#ifndef NULL
#define NULL 0
#endif


// read & write to mem
#define read8(adr)          (*((volatile unsigned char *)(adr)))
#define read16(adr)         (*((volatile unsigned short *)(adr)))
#define read32(adr)         (*((volatile unsigned int *)(adr)))
#define write8(adr, data)   (*((volatile unsigned char *)(adr)) = (data))
#define write16(adr, data)  (*((volatile unsigned short *)(adr)) = (data))
#define write32(adr, data)  (*((volatile unsigned int *)(adr)) = (data))

// align
#define ALIGN(addr,size) ((addr + (size-1))&(~(size-1)))

// string
#define XSTR(x)           STR(x)
#define STR(x)            #x

// func pointer
#define FUNC(r,n,p...)       r _##n(p); r (*n)(p) = _##n; r _##n(p)

// atomic operation
#define ATOMIC(x...)    {unsigned val = disable_ints(); {x;} restore_ints(val);}

// read & write or1200 SPR
#define mtspr(spr, value) { asm("l.mtspr\t\t%0,%1,0": : "r" (spr), "r" (value)); }
#define mfspr(spr)        ({ unsigned long __val;                                   \
                             asm("l.mfspr\t\t%0,%1,0" : "=r" (__val) : "r" (spr));  \
                             __val; })

// enable & disable ints
#define disable_ints() ({ unsigned __x = mfspr(SPR_SR);     \
                         mtspr(SPR_SR, __x & ~SPR_SR_IEE);  \
                         __x; })

#define restore_ints(x) mtspr(SPR_SR, x)
#define enable_ints()   mtspr(SPR_SR, mfspr(SPR_SR) | SPR_SR_IEE)


#define report(val) { asm("l.add r3,r0,%0": :"r" (val)); \
                      asm("l.nop\t2"); }


void *hmalloc(int size);
void sys_jump(unsigned long addr);


#endif // __SYSTEM_H__

