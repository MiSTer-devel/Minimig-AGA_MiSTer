////////////////////////////////////////////////////////////////////////////////
// hardware.c                                                                 //
// Various hardware-related & helper functions and defines                    //
//                                                                            //
// Copyright 2008-2009 Jakub Bednarski                                        //
// Copyright 2012-     Christian Vogelgsang, A.M. Robinson, Rok Krajnc        //
//                                                                            //
// This file is part of Minimig                                               //
//                                                                            //
// Minimig is free software; you can redistribute it and/or modify            //
// it under the terms of the GNU General Public License as published by       //
// the Free Software Foundation; either version 2 of the License, or          //
// (at your option) any later version.                                        //
//                                                                            //
// Minimig is distributed in the hope that it will be useful,                 //
// but WITHOUT ANY WARRANTY; without even the implied warranty of             //
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              //
// GNU General Public License for more details.                               //
//                                                                            //
// You should have received a copy of the GNU General Public License          //
// along with this program.  If not, see <http://www.gnu.org/licenses/>.      //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
// Changelog                                                                  //
//                                                                            //
// 2012-08-02 - rok.krajnc@gmail.com                                          //
// Updated with OR1200-specific functions and defines                         //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////



#include "hardware.h"


//// button ////
unsigned long CheckButton(void)
{
//  return((~*AT91C_PIOA_PDSR) & BUTTON);
  return(0);
}

//// timer ////
unsigned long GetTimer(unsigned long offset)
{
  unsigned long systimer = TIMER_get();
  systimer = systimer<< 16;
  systimer += offset << 16;
  return (systimer); // valid bits [31:16]
}


unsigned long CheckTimer(unsigned long time)
{
  unsigned long systimer = TIMER_get();
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


//// heap management() ////
extern int *_heap_start;
extern int *_heap_end;
static int *__heap_cur = 0;

void *hmalloc(int size)
{
  int *new, *old;

  if(__heap_cur == NULL) __heap_cur = (int *)&_heap_start;

  new = (int *)((int)__heap_cur + size);
  if(new > (int *)&_heap_end) return NULL;

  old = __heap_cur;
  __heap_cur = new;

  return old;
}


//// sys jump() ////
void sys_jump(unsigned long addr)
{
//  disable_ints();
  __asm__("l.sw  0x4(r1),r9");
  __asm__("l.jalr  %0" : : "r" (addr));
  __asm__("l.nop");
//  __asm__("l.lwz r9,0x4(r1)");
}


//// sys_load() ////
void sys_load(uint32_t * origin, uint32_t * dest, uint32_t size, uint32_t * routine)
{
  disable_ints();
  __asm__ __volatile__ ("l.add r4,r0,%0" : : "r" (origin)   : "r4");
  __asm__ __volatile__ ("l.add r2,r0,%0" : : "r" (dest)     : "r2");
  __asm__ __volatile__ ("l.add r3,r0,%0" : : "r" (size)     : "r3");
  __asm__ __volatile__ ("l.jr  %0"       : : "r" (routine)        );
}

