/*
Copyright 2005, 2006, 2007 Dennis van Weeren

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

Minimig boot controller / floppy emulator / on screen display

27-11-2005	- started coding
29-01-2005	- done a lot of work
06-02-2006	- it start to look like something!
19-02-2006	- improved floppy dma offset code
02-01-2007	- added osd support
11-02-2007	- added insert floppy progress bar
01-07-2007	- added filetype filtering for directory routines

JB:
2008-02-09	- added error handling
			number of blinks:
			1: neither mmc nor sd card detected
			2: fat16 filesystem not detected
			3: FPGA configuration error (INIT low or DONE high before config)
			4: no MINIMIG1.BIN file found
			5: FPGA configuration error (DONE is low after config)
			6: no kickstart file found

2008-07-18	- better read support (sector loaders are now less confused)
			- write support added (strict sector format checking - may not work with non DOS games)
			- removed bug in filename filtering (initial directory fill didn't filter)
			- communication interface with new bootloader
			- OSD control of reset, ram configuration, interpolation filters and kickstart

WriteTrack errors:
	#20 : unexpected dma transfer end (sector header)
	#21 : no second sync word found
	#22 : first header byte not 0xFF
	#23 : second header byte (track number) not within 0..159 range
	#24 : third header byte (sector number) not within 0..10 range
	#25 : fourth header byte (sectors to gap number) not within 1..11 range
	#26 : header checksum error
	#27 : track number in sector header not the same as drive head position
	#28 : unexpected dma transfer end (sector data)
	#29 : data checksum error
	#30 : write attempt to protected disk

2008-07-25	- update of write sector header format checking
			- disk led active during writes to disk

2009-03-01	- porting of ARM firmware features
2009-03-13	- forcing of PAL/NTSC mode with F1/F2 key after uploading FPGA configuration
2009-03-22	- fixed disabling of Action Replay ROM loading
			- changed cursor position after ADF file selection
			- now ESC allows to exit OSD menu
2009-04-05	- Action Replay may be disabled by pressing MENU button while its ROM upload should start

-- Goran Ljubojevic ---
2009-08-30	- separated fileBrowser.c to overcome compiler ram issues
2009-09-10	- Directory selection
2009-09-20	- Supporty for new FPGA bin 090911 by yaqube
2009-11-13	- Max Floppy Drives added
 			- Floppy selection reworked
2009-11-14	- HandleFDD moved to adf.c
			- UpdateDriveStatus to adf.c
			- Added extra menu for settigns and reset
2009-11-21	- menu moved to separate files
2009-11-30	- Code cleaned a bit, string replaced with constants 
2009-12-04	- HDD Detection added
2009-12-05	- Boot Wait before key read replaced with wait function
2009-12-97	- Pic version changed to PGLYYMMDD
			- Added FPGA version to display
2009-12-14	- OsdReset, added constant for reset type
2009-12-20	- AR3 not generating failure when enabled and no rom found.
2009-12-30	- Boot CPU Speed display modified to turbo/normal
			- Boot CPU speed set using constant 
			- Boot Agnus display updated only displayed when old FPGA core is used
			- PAL/NTSC switch constants used
			- Code cleanup comments removed
			- ConfigureFpga modified to accept default string filename
2010-01-29	- FPGA Core reset on PIC reset to allow reseting cores that are messed up SPI lines to SD card e.g. VIC20
			- Main loop added handling for alternate core, for future alternate core requests
2010-08-26	- Added firmwareConfiguration.h
2010-09-07	- Added handling for new NTSC mode variables
			- TODO: changes to floppy handling (Check ARM source AYQ100818)
			- TODO: improved menu button handling (Check ARM source AYQ100818)
			- improved FPGA configuration routines (This allready might be done in alternate core handling) (Check ARM source AYQ100818)
			- TODO: added support for OSD vsync (Check ARM source AYQ100818)
			- support for joystick emulation (Check ARM source AYQ100818)
2010-10-09	- Finished support for FYQ100818
			- support for joystick emulation auto fire
			- support for turbo mode switching
*/

#include <pic18.h>
#include <stdio.h>
#include <string.h>
#include "firmwareConfiguration.h"
#include "boot.h"
#include "hardware.h"
#include "osd.h"
#include "mmc.h"
#include "fat16.h"
#include "adf.h"
#include "fileBrowser.h"
#include "hdd.h"
#include "menu.h"
#include "config.h"

// Enable / Disable debug output
//#define DEBUG_MAIN

const char version[] = { "$VER:" DEF_TO_STRING(PIC_REV) "\0" };

void HandleFpga(void);

//global temporary buffer for strings
unsigned char s[32];


/* This is where it all starts after reset */
void main(void)
{
	unsigned short time;
	unsigned char tmp;

	// Reset Floppy status
	memset(df,0,sizeof(df));
	// Reset HD status
	memset(hdf,0,sizeof(hdf));

	#ifdef ALTERNATE_CORES
	// Reset Alternate Core Loaded Status on reset 
	bAlternateCoreLoaded = 0;
	#endif
	
	// initialize hardware
	HardwareInit();
	// Reset FPGA to programming mode to allow core changes
	// This is for problematic cores that messup SD card SPI
	ResetFPGA();

	printf("Minimig by Dennis van Weeren\r\n");
	printf("Bug fixes, mods and extensions by Jakub Bednarski\r\n");
	printf("SDHC, FAT16/32, Dir, LFN, HDD support by Goran Ljubojevic\r\n\r\n");
	printf("FPGA Rev. " DEF_TO_STRING(FPGA_REV) ", PIC Rev. %s\r\n\r\n", version+5);

	// Load Config form eeprom
	LoadConfiguration();

	// intialize mmc card
	if (!MMC_Init())
	{	FatalError(1);	}

	// initalize FAT partition
	if (!FindDrive())
	{
		#ifdef MAIN_DEBUG
		printf("No FAT16/32 filesystem!\r\n");
		#endif
		FatalError(2);
	}

	/*configure FPGA*/
	if (ConfigureFpga(defFPGAName))
	{	printf("\r\nFPGA configured\r\n");	}
	else
	{
		#ifdef MAIN_DEBUG
		printf("\r\nFPGA configuration failed\r\n");
		#endif
		FatalError(3);
	}

	//let's wait some time till reset is inactive so we can get a valid keycode
	DISKLED_OFF;
	WaitTimer(50);
	
	//get key code
	tmp = OsdGetCtrl();

	#if	defined(PGL090421) || defined(PGL090911) || defined(PGL091224)
		if (tmp == KEY_F1)	{	config.chipset |= CONFIG_AGNUS_NTSC;	}	//force NTSC mode
		if (tmp == KEY_F2)	{	config.chipset &= ~CONFIG_AGNUS_NTSC;	}	//force PAL mode
	#elif	defined(PGL100818)
		if (tmp == KEY_F1)	{	config.chipset |= CONFIG_NTSC;	}	//force NTSC mode
		if (tmp == KEY_F2)	{	config.chipset &= ~CONFIG_NTSC;	}	//force PAL mode
	#endif

	#if	defined(PGL090421)
		ConfigChipset(config.chipset|CONFIG_CPU_28MHZ);			//force CPU turbo mode
	#elif	defined(PGL090911) || defined(PGL091224) 
		ConfigChipset(config.chipset|CONFIG_CPU_TURBO);			//force CPU turbo mode
	#elif	defined(PGL100818)
		ConfigChipset(config.chipset|CONFIG_TURBO);				//force CPU turbo mode
	#endif

	#if	defined(PGL090421) || defined(PGL090911) || defined(PGL091224)
		if (config.chipset & CONFIG_AGNUS_NTSC)		//reset if NTSC mode requested because FPGA boots in PAL mode by default
		{	OsdReset(RESET_BOOTLOADER);	}
	#elif	defined(PGL100818)
		if (config.chipset & CONFIG_NTSC)		//reset if NTSC mode requested because FPGA boots in PAL mode by default
		{	OsdReset(RESET_BOOTLOADER);	}
	#endif

	ConfigFloppy(1, 1);					//high speed mode for ROM loading

	sprintf(s, "PIC firmware %s\n", version+5);
	BootPrint(s);

	#if	defined(PGL090421)
		sprintf(s, "CPU clock     : %s MHz", config.chipset & CONFIG_CPU_28MHZ ? "28.36": "7.09");
		BootPrint(s);
		sprintf(s, "Blitter speed : %s", config.chipset & CONFIG_BLITTER_FAST ? "fast": "normal");
		BootPrint(s);
	#elif	defined(PGL090911) || defined(PGL091224)
		sprintf(s, "CPU clock     : %s", config.chipset & CONFIG_CPU_TURBO ? "turbo": "normal");
		BootPrint(s);
	#elif	defined(PGL100818)
		sprintf(s, "CPU clock     : %s", config.chipset & CONFIG_TURBO ? "turbo": "normal");
		BootPrint(s);
	#endif
	
	sprintf(s, "Chip RAM size : %s", config_memory_chip_msg[config.memory&3]);
	BootPrint(s);
	sprintf(s, "Slow RAM size : %s", config_memory_slow_msg[config.memory>>2&3]);
	BootPrint(s);
	sprintf(s, "Floppy drives : %d", config.floppy_drives + 1);
	BootPrint(s);
	sprintf(s, "Floppy speed  : %s\n", config.floppy_speed ? "2x": "1x");
	BootPrint(s);


	// Load Kickstart
	if (UploadKickstart(config.kickname))
	{
		strcpy(config.kickname, defKickName);
		if (UploadKickstart(config.kickname))
		{	FatalError(6);	}
	}

	//load Action Replay ROM if not disabled
	if (config.ar3 && !CheckButton())
	{
		tmp = UploadActionReplay(defARName); 
		if(40 == tmp)
		{	config.ar3 = 0;		}
		else if(41 == tmp)
		{	FatalError(7);		}
	}


	#ifdef HDD_SUPPORT_ENABLE

	// Hard drives config 
    sprintf(s, "\nA600 IDE HDC is %s.", config.ide ? "enabled" : "disabled");
    BootPrint(s);
	
    tmp=0;
	do
	{
		// Copy config file name to temp string for HD File open search
		strncpy(s, hdf[tmp].file.name, 12);
		if (!OpenHardfile(tmp, s))
	    {
			// Not Found, try default name
			sprintf(s, defHDFileName, tmp);
			OpenHardfile(tmp, s);
	    }

	    // Display Info
	    sprintf(s, "%s HDD is %s.\n", tmp ? "Slave" : "Master",
	    	hdf[tmp].present ? (hdf[tmp].enabled ? "enabled" : "disabled") : "not present"
	    );
	    BootPrint(s);

	    // Display Present HDD file info
	    if(hdf[tmp].present)
	    {
	    	sprintf(s, "File: %s", hdf[tmp].file.name);
	    	BootPrint(s);

	    	sprintf(s, "CHS: %d.%d.%d", hdf[tmp].cylinders, hdf[tmp].heads, hdf[tmp].sectors);
	    	BootPrint(s);
	    	
	    	sprintf(s, "Size: %d MB\n", ((((unsigned long) hdf[tmp].cylinders) * hdf[tmp].heads * hdf[tmp].sectors) >> 11));
	    	BootPrint(s);
	    }

	    // Next HD File
	}
	while ((++tmp) < 2);

	/*
    if (selectedPartiton.clusterSize < 64)
    {
        BootPrint("\n***************************************************");
        BootPrint(  "*  It's recommended to reformat your memory card  *");
        BootPrint(  "*   using 32 KB clusters to improve performance   *");
        BootPrint(  "***************************************************");
    }
	*/

	// Finally Config IDE
	ConfigIDE(config.ide, hdf[0].present & hdf[0].enabled, hdf[1].present & hdf[1].enabled);
	#endif

	
	#ifdef MAIN_DEBUG
	printf("Bootloading is complete.\r\n");
	#endif

	BootPrint("Exiting bootloader...\n");

	// Wait 2 sec for OSD show just to be able to see on screen stuff
	WaitTimer(200);
	
	//config memory and chipset features
	ConfigMemory(config.memory);
	ConfigChipset(config.chipset);
	ConfigFloppy(config.floppy_drives, config.floppy_speed);

	BootExit();

	ConfigFilter(config.filter_lores, config.filter_hires);	//set interpolation filters
	ConfigScanline(config.scanline);						//set scanline effect

	/******************************************************************************/
	/*  System is up now                                                          */
	/******************************************************************************/

	// get initial timer for checking user interface
	time = GetTimer(5);

	while (1)
	{
		#ifdef ALTERNATE_CORES
		//TODO: Handle Alternate Core Requests
		if (bAlternateCoreLoaded)
		{	continue;	}
		#endif

		// handle command
		HandleFpga();

		// handle user interface
		if (CheckTimer(time))
		{
			time = GetTimer(2);
			HandleUI();
		}
	}
}


// Handle an FPGA command
void HandleFpga(void)
{
	unsigned char  c1, c2;

	EnableFpga();
	c1 = SPI(0);	//cmd request and drive number
	c2 = SPI(0);	//track number
	SPI(0);
	SPI(0);
	SPI(0);
	SPI(0);
	DisableFpga();

	HandleFDD(c1,c2);
	
	#ifdef HDD_SUPPORT_ENABLE
	HandleHDD(c1,c2);
	#endif

	UpdateDriveStatus();
}



