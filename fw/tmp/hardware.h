/* hardware.h */
/* 2012, rok.krajnc@gmail.com */

#ifndef __HARDWARE_H__
#define __HARDWARE_H__


// minimig stuff

#define DISKLED_ON // *AT91C_PIOA_SODR = DISKLED;
#define DISKLED_OFF // *AT91C_PIOA_CODR = DISKLED;

#define EnableCard()    (*((volatile unsigned int *)0x800014)=0x11)
#define DisableCard()   (*((volatile unsigned int *)0x800014)=0x10)
#define EnableFpga()    (*((volatile unsigned int *)0x800014)=0x22)
#define DisableFpga()   (*((volatile unsigned int *)0x800014)=0x20)
#define EnableOsd()     (*((volatile unsigned int *)0x800014)=0x44)
#define DisableOsd()    (*((volatile unsigned int *)0x800014)=0x40)
#define EnableDMode()   (*((volatile unsigned int *)0x800014)=0x88)
#define DisableDMode()  (*((volatile unsigned int *)0x800014)=0x80)

#define SPI_slow()      (*((volatile unsigned int *)0x800010)=0x3f)
#define SPI_fast()      (*((volatile unsigned int *)0x800010)=0x06)
#define SPI_write(x)    (*((volatile unsigned int *)0x800018)=(x))
#define SPI_read()      (*((volatile unsigned int *)0x800018))
#define SPI(x)          (SPI_write(x), SPI_read())
#define SPI_block(x)    (*((volatile unsigned int *)0x80001c)=(x))

#define RS232(x)        (*((volatile unsigned int *)0x800008)=(x))

#define TIMER_get()     (*((volatile unsigned int *)0x80000c))
#define TIMER_set(x)    (*((volatile unsigned int *)0x80000c)=(x))
#define TIMER_wait(x)   (TIMER_set(0), while (TIMER_get()<(x)))

#define SPIN            (SPI_read()) // Waste a few cycles to let the FPGA catch up

unsigned long CheckButton(void);
void Timer_Init(void);
unsigned long GetTimer(unsigned long offset);
unsigned long CheckTimer(unsigned long time);
void WaitTimer(unsigned long time);

#define RST_system()    (*((volatile unsigned int *)0x800000)=(1))
#define RST_minimig()   (*((volatile unsigned int *)0x800004)=(1))


// OR1200 stuff

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


#endif // __HARDWARE_H__

