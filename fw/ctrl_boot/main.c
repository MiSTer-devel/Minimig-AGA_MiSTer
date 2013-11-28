/* main.c */

/*******************************************************************************
** MINIMIG-DE1 startup **
Copyright 2012, rok.krajnc@gmail.com

This is main startup firmware for the ctrl block in the Minimig DE1 port

This file is part of Minimig

Minimig is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3 of the License, or
(at your option) any later version.

Minimig is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*******************************************************************************/


// RK : 2012-06-04  initial version


#include "hardware.h"
#include "mmc.h"
#include "fat.h"


fileTYPE file;
static const char * firmware="DE1_BOOTBIN";
char led;

void main(void) __attribute__ ((noreturn));
void FatalError(void) __attribute__ ((noreturn));


void main(void)
{
  DEBUG_FUNC_IN();

  // !!! a pointer to start of RAM
  unsigned char* ram = ((unsigned char *)0x400000);

  // initialize SD card
  LEDS(led=0xf);
  if (!MMC_Init()) FatalError();

  // find drive
  LEDS(led=0x8);
  if (!FindDrive()) FatalError();

  // open file
  LEDS(led=0x3);
  LoadFile(firmware,ram);
#if 0
  if (!FileOpen(&ft, firmware)) FatalError();

  // load firmware to RAM
  LEDS(led=0x1);
  for(i=0; i<((ft.size>>9)+1); i++) {
    FileRead(&ft, ram+(i*512));
    FileNextSector(&ft);
  }
#endif
  // jump to RAM firmware
  LEDS(led=0x0);
  DisableCard();
  sys_jump(0x400004);

  // loop forever
  while(1);

  DEBUG_FUNC_OUT();
}


// fatal error
void FatalError(void)
{
  DEBUG_FUNC_IN();

  DisableCard();

  // loop forever
  while(1) {
    TIMER_wait(200);
    LEDS(0x0);
    TIMER_wait(200);
    LEDS(led);
  }

  DEBUG_FUNC_OUT();
}

