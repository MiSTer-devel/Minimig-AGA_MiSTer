/*
Copyright 2005, 2006, 2007 Dennis van Weeren
Copyright 2008, 2009 Jakub Bednarski

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
*/

// 2008-10-04   - porting to ARM
// 2008-10-06   - support for 4 floppy drives
// 2008-10-30   - hdd write support
// 2009-05-01   - subdirectory support
// 2009-06-26   - SDHC and FAT32 support
// 2009-08-10   - hardfile selection
// 2009-09-11   - minor changes to hardware initialization routine
// 2009-10-10   - any length fpga core file support
// 2009-11-14   - adapted floppy gap size
//              - changes to OSD labels
// 2009-12-24   - updated version number
// 2010-01-09   - changes to floppy handling
// 2010-07-28   - improved menu button handling
//              - improved FPGA configuration routines
//              - added support for OSD vsync
// 2010-08-15   - support for joystick emulation
// 2010-08-18   - clean-up


//// includes ////
//#include "AT91SAM7S256.h"
#include "errors.h"
#include "hardware.h"
#include "mmc.h"
#include "fat.h"
#include "osd.h"
#include "fpga.h"
#include "fdd.h"
#include "hdd.h"
#include "firmware.h"
#include "menu.h"
#include "config.h"

#include <stdio.h>
#include <string.h>
#include <inttypes.h>


//// global variables ////
const char version[] = {"$VER:AYQ100818_RB2"};
const char * firmware="1          ";
extern adfTYPE df[4];
unsigned char Error;
char s[40];


//// FatalError() ////
void FatalError(unsigned long error)
{
  DEBUG_FUNC_IN();

  unsigned long i;

  sprintf(s,"Fatal error: %lu\n", error);
  BootPrint("FatalError...\n");
  BootPrint(s);

  while (1) {
    for (i = 0; i < error; i++) {
      DISKLED_ON;
      WaitTimer(250);
      DISKLED_OFF;
      WaitTimer(250);
    }
    WaitTimer(1000);
  }

  DEBUG_FUNC_OUT();
}


//// HandleFpga() ////
void HandleFpga(void)
{
//  DEBUG_FUNC_IN();

  unsigned char  c1, c2;

  EnableFpga();
  c1 = SPI(0); // cmd request and drive number
  c2 = SPI(0); // track number
  SPI(0);
  SPI(0);
  SPI(0);
  SPI(0);
  DisableFpga();

  HandleFDD(c1, c2);
  HandleHDD(c1, c2);

  UpdateDriveStatus();

//  DEBUG_FUNC_OUT();
}


//// main() ////
#ifdef __GNUC__
void main(void)
#else
__geta4 void main(void)
#endif
{
  DEBUG_FUNC_IN();

  uint32_t spiclk;
  fileTYPE sd_boot_file;

  // boot message
  printf("\r**** MINIMIG-DE1 ****\r\r");
  printf("Build no. ");
  printf(__BUILD_NUM);
  //printf(" by ");
  //printf(__BUILD_USER);
  printf("\rgit commit ");
  printf(__BUILD_REV);
  printf("\r\r");
  printf("For updates, see https://github.com/rkrajnc/minimig-de1\r");
  printf("For support, see http://www.minimig.net/\r\r");
  printf("Minimig by Dennis van Weeren\r");
  printf("Updates by Jakub Bednarski, Tobias Gubener, Sascha Boing, A.M. Robinson & others\r");
  printf("DE1 port by Rok Krajnc (rok.krajnc@gmail.com)\r\r");
  printf("Version %s\r\r", version+5);


  //ShowSplash();

  BootPrint("OSD_CA01.SYS is here...\n");

  sprintf(s, "** ARM firmware %s **\n", version + 5);
  BootPrint(s);

//  OsdDisable();

  if (!MMC_Init()) FatalError(1);

  BootPrint("Init done again - hunting for drive...\n");

  spiclk = 100000 / (20*(read32(REG_SPI_DIV_ADR) + 2));
  printf("SPI divider: %u\r", read32(REG_SPI_DIV_ADR));
  printf("SPI clock: %u.%uMHz\r", spiclk/100, spiclk%100);

  if (!FindDrive()) FatalError(2);
        
  BootPrint("found DRIVE...\n");

  ChangeDirectory(DIRECTORY_ROOT);

  //eject all disk
  df[0].status = 0;
  df[1].status = 0;
  df[2].status = 0;
  df[3].status = 0;

  config.kickstart.name[0]=0;
  SetConfigurationFilename(0); // Use default config
  LoadConfiguration(0);  // Use slot-based config filename

  sprintf(s, "SPI clock: %u.%uMHz\n", spiclk/100, spiclk%100);
  BootPrint(s);
  //HideSplash();

/*
  // try to open SD card firmware and load it
  printf("Opening firmware file %s ... ", firmware);
  if (FileOpen(&sd_boot_file, firmware)) {
    printf("OK, filesize: %u\r", sd_boot_file.size);
    hmalloc(64*1024); // allocate some buffer space in case new firmware is bigger
    uint32_t * fw_ram = (uint32_t *)hmalloc(sd_boot_file.size); // allocate space for firmware
    if (!fw_ram) {
      printf("Cannot allocate memory for firmware!\r");
      FatalError(0);
    }
    printf("Loading firmware to RAM ... ");
    if (!FileReadEx(&sd_boot_file, fw_ram, (sd_boot_file.size + (sd_boot_file.size&0x1ff))>>9)) {
      printf ("\rFailed loading firmware to RAM!\r");
      FatalError(0);
    }
    printf("OK, initializing copy routine, size %u ...\r", sizeof(fw_copy_routine));
    uint32_t * fw_copy = (uint32_t *)hmalloc(sizeof(fw_copy_routine));
    if (!fw_copy) {
      printf("Cannot allocate memory for firmware copy routine!\r");
      FatalError(0);
    }
    memcpy(fw_copy, fw_copy_routine, sizeof(fw_copy_routine));
    sys_load(fw_ram, RAM_START, RAM_START + sd_boot_file.size, fw_copy);
  }
  printf("FAILED - no firmware on SD card. Continuing with FLASH firmware.\r");

  // TODO must add firmware version & version test - otherwise the SDcard firmware will load itself again in an endless loop!
  // TODO Or a simple single bit register that gets set once SDcard fw is loaded.
*/

  // main loop
  while (1) {
    HandleFpga();
    HandleUI();
  }

  DEBUG_FUNC_OUT();
}

