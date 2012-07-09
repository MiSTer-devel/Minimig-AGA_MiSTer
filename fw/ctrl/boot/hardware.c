/* hardware.c */
/* 2012, rok.krajnc@gmail.com */


#include "hardware.h"


unsigned long GetTimer(unsigned long offset)
{
  unsigned long systimer = (*(volatile unsigned long *)0x80000c);
  systimer = systimer<< 20;
  systimer += offset << 20;
  return (systimer); // valid bits [31:20]
}


unsigned long CheckTimer(unsigned long time)
{
  unsigned long systimer = (*(volatile unsigned long *)0x80000c);
  systimer = systimer<< 20;
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

