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

// FIXME - detect number of partitions on the SD card, and allow that many to be selected as hard files.

//#include "AT91SAM7S256.h"
#include "stdio.h"
#include "string.h"
#include "hardware.h"

#include "errors.h"
#include "mmc.h"
#include "fat.h"
#include "osd.h"
#include "fpga.h"
#include "fdd.h"
#include "hdd.h"
#include "firmware.h"
#include "menu.h"
#include "config.h"


const char version[] = {"$VER:AYQ100818_RB2"};

extern adfTYPE df[4];

unsigned char Error;
char s[40];

void FatalError(unsigned long error)
{
    unsigned long i;

    sprintf(s,"Fatal error: %u\n", error);
    BootPrint("FatalError...\n");
	BootPrint(s);

    while (1)
    {
        for (i = 0; i < error; i++)
        {
            DISKLED_ON;
            WaitTimer(250);
            DISKLED_OFF;
            WaitTimer(250);
        }
        WaitTimer(1000);
    }
}


void HandleFpga(void)
{
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
}

#ifdef __GNUC__
void main(void)
#else
__geta4 void main(void)
#endif
{
	debugmsg[0]=0;
	debugmsg2[0]=0;
//    unsigned long time;
//    unsigned short spiclk;

	ShowSplash();

    BootPrint("OSD_CA01.SYS is here...\n");

    DISKLED_ON;

//    Timer_Init();
//
//    USART_Init(115200);

    printf("\rMinimig by Dennis van Weeren");
    printf("\rARM Controller by Jakub Bednarski\r\r");
    printf("Version %s\r\r", version+5);

    sprintf(s, "** ARM firmware %s **\n", version + 5);
    BootPrint(s);

//	OsdDisable();

//    SPI_Init();

//    if (CheckButton()) // if menu button pressed fall back to slow SPI mode
//       SetSPIMode(SPIMODE_NORMAL);

    if (!MMC_Init())
        FatalError(1);

    BootPrint("Init done again - hunting for drive...\n");

//    spiclk = 7;//MCLK / ((AT91C_SPI_CSR[0] & AT91C_SPI_SCBR) >> 8) / 1000000;
//    printf("spiclk: %u MHz\r", spiclk);

    if (!FindDrive())
        FatalError(2);
        
    BootPrint("found DRIVE...\n");

    ChangeDirectory(DIRECTORY_ROOT);

//    time = GetTimer(0);
//    if (ConfigureFpga())
//    {
//        time = GetTimer(0) - time;
//        printf("FPGA configured in %u ms\r", time >> 20);
//    }
//    else
//    {
//        printf("FPGA configuration failed\r");
//        FatalError(3);
//    }

//    WaitTimer(100); // let's wait some time till reset is inactive so we can get a valid keycode
//eject all disk
	df[0].status = 0;
	df[1].status = 0;
	df[2].status = 0;
	df[3].status = 0;

	config.kickstart.name[0]=0;
	SetConfigurationFilename(0); // Use default config
    LoadConfiguration(0);	// Use slot-based config filename

//    sprintf(s, "SPI clock: %u MHz\n", spiclk);
//    BootPrint(s);
 	HideSplash();

    while (1)
    {
        HandleFpga();
        HandleUI();
    }

}

