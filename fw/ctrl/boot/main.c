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
#include "string.h"
#include "fw_stdio.h"
#include "mmc.h"
#include "fat.h"


fileTYPE file;
static const char * firmware="DE1_BOOT.BIN";


void main(void) __attribute__ ((noreturn));
void FatalError(void) __attribute__ ((noreturn));


void main(void)
{
  fileTYPE ft;

  // !!! a pointer to start of RAM
  unsigned char * ram = ((unsigned char *)0x400000);

  // boot message
  //printf("\r\r**** MINIMIG-DE1 startup ****\r");
  //printf("2012, rok.krajnc@gmail.com\r\r");
  //printf("Build no. ");
  //printf(__BUILD_NUM);
  //printf(" by ");
  //printf(__BUILD_USER);
  //printf("\rgit commit ");
  //printf(__BUILD_REV);
  //printf("\r\rFor updates, see https://github.com/rkrajnc/minimig-de1\r\r");

  // initialize SD card
  //printf("Initializing SD card ... ");
  if (!MMC_Init()) FatalError();
  //printf("OK\r");

  // find drive
  //printf("Finding valid FAT ... ");
  if (!FindDrive()) FatalError();
  //printf("OK\r");

  ChangeDirectory(DIRECTORY_ROOT);

  // open file
  //printf("Opening firmware file "); printf(firmware); printf(" ... ");
  if (!FileOpen(&ft, firmware)) FatalError();
  //printf("OK\r");

  // load firmware to RAM
  //printf("Loading firmware to RAM ...");
  if (!FileReadEx(&ft, ram, ft.size)) FatalError();
  //printf("OK\r");

  // jump to RAM firmware
  //printf("Jumping to firmware ... see you on the other side.\r\r");
  sys_jump(0x400004);

  // loop forever
  while(1);
}


// fatal error
void FatalError(void)
{
  //printf("FAILED\r");

  // TODO add LEDS

  // loop forever
  while(1);
}

