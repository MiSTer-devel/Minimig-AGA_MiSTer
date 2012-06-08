/* hardware.c */
/* 2012, rok.krajnc@gmail.com */


#include "hardware.h"


unsigned long CheckButton(void)
{
//    return((~*AT91C_PIOA_PDSR) & BUTTON);
		return(0);
}


unsigned long GetTimer(unsigned long offset)
{
  unsigned long systimer = (*(volatile unsigned long *)0x80000c);
  systimer = systimer<< 16;
  systimer += offset << 16;
  return (systimer); // valid bits [31:16]
}


unsigned long CheckTimer(unsigned long time)
{
  unsigned long systimer = (*(volatile unsigned long *)0x80000c);
  systimer = systimer<< 16;
  time -= systimer;
  if(time & 0x80000000) return(1);
  return(0);
}


void WaitTimer(unsigned long time)
{
  time = GetTimer(time);
  while (!CheckTimer(time));
}


// heap management
extern int *_heap_start;
extern int *_heap_end;
static int *__heap_cur = 0;

void *hmalloc(int size)
{
  int *new, *old;

  if(__heap_cur == NULL) __heap_cur = (int *)&_heap_start;

  new = (int *)((int)__heap_cur + size);
  if(new > (int *)&_heap_end) return NULL;
  // TODO: more checkings if needed
  // heap bottom, top should be defined and checked

  old = __heap_cur;
  __heap_cur = new;

  return old;
}


// sys jump
void sys_jump(unsigned long addr)
{
  //disable_ints();
  __asm__("l.sw  0x4(r1),r9");
  __asm__("l.jalr  %0" : : "r" (addr));
  __asm__("l.nop");
  __asm__("l.lwz r9,0x4(r1)");
}

