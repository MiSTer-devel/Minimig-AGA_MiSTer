/* hardware.c */
/* 2012, rok.krajnc@gmail.com */


#include "hardware.h"
#include "fw_stdio.h"


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


void putchar(char c)
{
  RS232(c);
}


void putstring(char * s)
{
  while(*s != '\0') RS232(*s++);
}

void sputchar(char c)
{
  __s[__sp++] = c;
}
