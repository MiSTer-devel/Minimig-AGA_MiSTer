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
#include "boot.h"
#include "boot_logo.h"
#include "boot_print.h"
#include "serial.h"

#include "stdio.h"
#include "string.h"
#include <inttypes.h>


//// global variables ////
const char * firmware="1          ";
unsigned char Error;
extern adfTYPE df[4];
char s[40];
char led = 0;

//// FatalError() ////
void FatalError(unsigned long error)
{
  DEBUG_FUNC_IN(DEBUG_F_MAIN | DEBUG_L2);

  sprintf(s,"Fatal error: %lu", error);
  BootPrintEx(s);
  printf(s);

  // loop forever
  while(1) {
    TIMER_wait(200);
    LEDS(0x0);
    TIMER_wait(200);
    LEDS(error);
  }

  DEBUG_FUNC_OUT(DEBUG_F_MAIN | DEBUG_L2);
}


//// HandleFpga() ////
void HandleFpga(void)
{
  DEBUG_FUNC_IN(DEBUG_F_MAIN | DEBUG_L3);

  unsigned char  c1, c2;

  LEDS(led = !led);
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

  DEBUG_FUNC_OUT(DEBUG_F_MAIN | DEBUG_L3);
}


//// main() ////
#ifdef __GNUC__
void main(void)
#else
__geta4 void main(void)
#endif
{
  DEBUG_FUNC_IN(DEBUG_F_MAIN | DEBUG_L0);

  uint32_t spiclk;
  fileTYPE sd_boot_file;

  // enable normal SPI
  SPI_normal();

  // wait for SDRAM controller
  printf("Waiting for SDRAM ... ");
  while ((read32(REG_SYS_STAT_ADR) & 0x1));
  printf("OK (%01x)\r", read32(REG_SYS_STAT_ADR));

  // reset, unreset and halt cpu
  printf("Unresetting from ctrl block ...\r");
  write32(REG_RST_ADR, 0);
  EnableOsd();
  SPI(OSD_CMD_RST);
  rstval = (SPI_RST_USR | SPI_RST_CPU | SPI_CPU_HLT);
  SPI(rstval);
  DisableOsd();
  SPIN(); SPIN(); SPIN(); SPIN();
  EnableOsd();
  SPI(OSD_CMD_RST);
  rstval = (SPI_RST_CPU | SPI_CPU_HLT);
  SPI(rstval);
  DisableOsd();
  SPIN(); SPIN(); SPIN(); SPIN();

  // initialize SD card
  if (!MMC_Init()) FatalError(1);
  printf("SD card found ...\r");

  // find filesystem
  if (!FindDrive()) FatalError(2);
  ChangeDirectory(DIRECTORY_ROOT);
  printf("Drive found ...\r");

  // boot message
  BootInit();
  BootPrintEx("**** MINIMIG-DE1 by Rok Krajnc (rok.krajnc@gmail.com) ****");
  BootPrintEx(" ");
  BootPrintEx("Original Minimig by Dennis van Weeren");
  BootPrintEx("Updates by Jakub Bednarski, Tobias Gubener, Sascha Boing, A.M. Robinson & others");
  BootPrintEx("For updates & code see https://github.com/rkrajnc/minimig-de1");
  BootPrintEx("For support, see http://www.minimig.net");
  //BootPrintEx(" ");
  //sprintf(s, "Build git commit: %s", __BUILD_REV);
  //BootPrintEx(s);
  sprintf(s, "Build git tag: %s", __BUILD_TAG);
  BootPrintEx(s);
  BootPrintEx(" ");
  spiclk = 100000 / (20*(read32(REG_SPI_DIV_ADR) + 2));
  sprintf(s, "SPI clock: %u.%uMHz", spiclk/100, spiclk%100);
  BootPrintEx(s);
  //BootPrintEx(" ");
  TIMER_wait(3000);

  //eject all disks
  df[0].status = 0;
  df[1].status = 0;
  df[2].status = 0;
  df[3].status = 0;
 
  BootPrintEx("Booting ...");
  config.kickstart.name[0]=0;
  SetConfigurationFilename(0); // Use default config

  LoadConfiguration(0);  // Use slot-based config filename

  SPI_fast();

  // main loop
  while (1) {
    HandleFpga();
    HandleUI();
    HandleSerial();
  }

  DEBUG_FUNC_OUT(DEBUG_F_MAIN | DEBUG_L0);
}

