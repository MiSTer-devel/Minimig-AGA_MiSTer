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


#include "stdio.h"
#include "hardware.h"

//// firmware copy routine ////
uint32_t fw_copy_routine[] = {
  // fw_copy:
  0x18400040, // l.movhi r2,  // destination start
  0xa8420000, // l.ori r2,r2, // destination start
  0x18600041, // l.movhi r3,  // fw end
  0xa8633900, // l.ori r3,r3, // fw end
  0x18800000, // l.movhi r4,  // fw start
  0xa8840000, // l.ori r4,r4, // fw start
  // fw_copy_start:
  0xe4621800, // l.sfgeu r2,r3
  0x10000008, // l.bf 400050 <fw_copy_end>
  0x15000000, // l.nop 0x0
  0x84a40000, // l.lwz r5,0x0(r4)
  0xd4022800, // l.sw 0x0(r2),r5
  0x9c420004, // l.addi r2,r2,0x4
  0x9c840004, // l.addi r4,r4,0x4
  0x0ffffff9, // l.bnf 40002c <fw_copy_start>
  0x15000000, // l.nop 0x0
  // fw_copy_end:
  0x18200047, // l.movhi r1,0x47
  0xa821fffc, // l.ori r1,r1,0xfffc
  0x18600040, // l.movhi r3,0x40
  0xa86300c8, // l.ori r3,r3,0xc8
  0x44001800, // l.jr r3
  0x15000000  // l.nop 0x0
};

uint32_t rstval = 0;


//// button ////
unsigned long CheckButton(void)
{
  DEBUG_FUNC_IN(DEBUG_F_HARDWARE | DEBUG_L3);

//  return((~*AT91C_PIOA_PDSR) & BUTTON);
  return(0);

  DEBUG_FUNC_OUT(DEBUG_F_HARDWARE | DEBUG_L3);
}

//// timer ////
unsigned long GetTimer(unsigned long offset)
{
  DEBUG_FUNC_IN(DEBUG_F_HARDWARE | DEBUG_L3);

  unsigned long systimer = TIMER_get();
  systimer = systimer<< 16;
  systimer += offset << 16;
  return (systimer); // valid bits [31:16]

  DEBUG_FUNC_OUT(DEBUG_F_HARDWARE | DEBUG_L3);
}


unsigned long CheckTimer(unsigned long time)
{
  DEBUG_FUNC_IN(DEBUG_F_HARDWARE | DEBUG_L3);

  unsigned long systimer = TIMER_get();
  systimer = systimer<< 16;
  time -= systimer;
  if(time & 0x80000000) return(1);
  return(0);

  DEBUG_FUNC_OUT(DEBUG_F_HARDWARE | DEBUG_L3);
}


void WaitTimer(unsigned long time)
{
  DEBUG_FUNC_IN(DEBUG_F_HARDWARE | DEBUG_L3);

  time = GetTimer(time);
  while (!CheckTimer(time));

  DEBUG_FUNC_OUT(DEBUG_F_HARDWARE | DEBUG_L3);
}


//// heap management() ////
extern int *_heap_start;
extern int *_heap_end;
static int *__heap_cur = 0;

void *hmalloc(int size)
{
  DEBUG_FUNC_IN(DEBUG_F_HARDWARE | DEBUG_L3);

  int *new, *old;

  if(__heap_cur == NULL) __heap_cur = (int *)&_heap_start;

  new = (int *)((int)__heap_cur + size);
  if(new > (int *)&_heap_end) return NULL;

  old = __heap_cur;
  __heap_cur = new;

  return old;

  DEBUG_FUNC_OUT(DEBUG_F_HARDWARE | DEBUG_L3);
}


//// sys jump() ////
void sys_jump(unsigned long addr)
{
  DEBUG_FUNC_IN(DEBUG_F_HARDWARE | DEBUG_L3);

  disable_ints();
  __asm__("l.sw  0x4(r1),r9");
  __asm__("l.jalr  %0" : : "r" (addr));
  __asm__("l.nop");
  __asm__("l.lwz r9,0x4(r1)");

  DEBUG_FUNC_OUT(DEBUG_F_HARDWARE | DEBUG_L3);
}


//// sys_load() ////
void sys_load(uint32_t * origin, uint32_t * dest, uint32_t size, uint32_t * routine)
{
  DEBUG_FUNC_IN(DEBUG_F_HARDWARE | DEBUG_L3);

  disable_ints();
  __asm__ __volatile__ ("l.add r4,r0,%0" : : "r" (origin)   : "r4");
  __asm__ __volatile__ ("l.add r2,r0,%0" : : "r" (dest)     : "r2");
  __asm__ __volatile__ ("l.add r3,r0,%0" : : "r" (size)     : "r3");
  __asm__ __volatile__ ("l.jr  %0"       : : "r" (routine)        );

  DEBUG_FUNC_OUT(DEBUG_F_HARDWARE | DEBUG_L3);
}

