/* hardware.h */
/* 2012, rok.krajnc@gmail.com */

#ifndef __HARDWARE_H__
#define __HARDWARE_H__

#include "system.h"

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
#define SPI_fast()      (*((volatile unsigned int *)0x800010)=0x00)
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

void putchar(char c);
void putstring(char *s);

void sputchar(char c);


#endif // __HARDWARE_H__

