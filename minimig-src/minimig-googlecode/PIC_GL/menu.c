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

Minimig on screen display menu

-- Goran Ljubojevic ---
2009-11-21	- Extracted from main
2009-12-01	- HandleUpDown added to save memory and make more clear code
2009-12-05	- Code cleaned a bit
			- Strigs adapted to a new font (arrows)
			- Added extensions for ADF and HDF display
2009-12-06	- Fixed Floppy no selection.
2009-12-09	- Added preselect menu after file selection fixes problem when reloading kickstart
2009-12-14	- Chipset settings modified to support latest Yacube FPGA PYQ090911 bin
			- Config Floppy speed modified
			- OsdReset, added constant for reset type
2009-12-20	- Unselecting HD Files Added
2009-12-23	- Fixed HD file unselection by clearing global file handle when no file selection done
2009-12-30	- Kickstart reloading code cleanup
2010-01-29	- Alternate core loading added
2010-08-20	- Chipset config features for new Yaqube core YQ100818
2010-08-26	- Added firmwareConfiguration.h
2010-09-07	- Added Info Menu display
			- Modified Chipset display handling
			- Modified Chipset config handling
2010-09-09	- Fixed Alternate core select always from root
2010-09-12	- Autofire handling 
2010-10-05	- Autofire handling conditionaly compiled
			- Turbo selection conditionlay compiled
			- Alternate cores selection conditionaly compiled
*/

#include <pic18.h>
#include <stdio.h>
#include <string.h>
#include "firmwareConfiguration.h"
#include "hardware.h"
#include "boot.h"
#include "osd.h"
#include "fat16.h"
#include "menu.h"
#include "adf.h"
#include "hdd.h"
#include "fileBrowser.h"
#include "config.h"


//global temporary buffer for strings
//defined in main.c
extern unsigned char s[32];

// variables
unsigned char menustate = MENU_NONE1;
unsigned char menusub = 0;

#ifdef	AUTOFIRE_RATE_KEYBOARD_SELECT || TURBO_MODE_KEYBOARD_SELECT
unsigned short menu_timer;
#endif

#ifdef AUTOFIRE_RATE_KEYBOARD_SELECT
unsigned char config_autofire = 0;
#endif


// "const" added before array to move arrays to rom
const char * const config_filter_msg[] =  {"none", "HOR ", "VER ", "H+V "};
const char * const config_memory_chip_msg[] = {"0.5 MB", "1.0 MB", "1.5 MB", "2.0 MB"};
const char * const config_memory_slow_msg[] = {"none  ", "0.5 MB", "1.0 MB", "1.5 MB"};
const char * const config_scanline_msg[] = {"Off", "Dim", "Blk"};
#if	defined(PGL100818)
const char * const config_chipset_msg[] = {"OCS-A500", "OCS-A1000", "ECS", "---"};
const char * const config_autofire_msg[] = {"Off", "Fast", "Medium", "Slow"};
#endif


// Variables for decoded events
bit up;
bit down;
bit select;
bit menu;
bit right;
bit left;
#if	defined(PGL100818)
bit ctrl = 0;
bit lalt = 0;
#endif

// File Selection
const unsigned char *fbFileExt;
unsigned char fbSelectedState;
unsigned char fbSelectedStatePreselect;
unsigned char fbExitState;
unsigned char fbAllowDirectorySelect;

#ifdef ALTERNATE_CORES
// Alternate Core Loaded
unsigned char bAlternateCoreLoaded;
#endif

void HandleUI(void)
{
	unsigned char i;
	unsigned char c;

	/*get user control codes*/
	c = OsdGetCtrl();

	/*decode and set events*/
	up = 0;
	down = 0;
	select = 0;
	menu = 0;
	right = 0;
	left = 0;

	#if	defined(PGL100818)
	// Control and Left Alt key handling
	if (c==KEY_CTRL)					{	ctrl = 1;	}
	if (c==(KEY_CTRL|KEY_UPSTROKE))		{	ctrl = 0;	}
	if (c==KEY_LALT)					{	lalt = 1;	}
	if (c==(KEY_LALT|KEY_UPSTROKE))		{	lalt = 0;	}
	#endif

	#ifdef AUTOFIRE_RATE_KEYBOARD_SELECT
	if (c==KEY_KP0)						{	AutoFireSwitch();	}
	#endif

	#ifdef TURBO_MODE_KEYBOARD_SELECT
	if (c==KEY_KPPLUS)					{	TurboModeSwitch(1);	}
	if (c==KEY_KPMINUS)					{	TurboModeSwitch(0);	}
	#endif
	
	if (c==KEY_UP)						{	up = 1;	}
	if (c==KEY_DOWN)					{	down = 1;	}
	if (c==KEY_ENTER || c==KEY_SPACE)	{	select = 1;	}
	if (c==KEY_MENU)					{	menu = 1;	}
	if (c==KEY_RIGHT)					{	right = 1;	}
	if (c==KEY_LEFT)					{	left = 1;	}

	//esc key when OSD is on
	if (c==KEY_ESC && menustate!=MENU_NONE2)	{	menu = 1;	}

	// menu state machine
	switch (menustate)
	{
		/******************************************************************/
		/*no menu selected / menu exited / menu not displayed			  */
		/******************************************************************/
		case MENU_NONE1 :
			OsdDisable();
			menustate = MENU_NONE2;
			break;

		case MENU_NONE2 :
			// check if user wants to go to menu
			if (menu)
			{
				menustate = MENU_MAIN1;
				menusub = 0;
				OsdClear();
				#if		defined(PGL090421) || defined(PGL090911) || defined(PGL091224)
					OsdEnable();
				#elif	defined(PGL100818)
					OsdEnable(DISABLE_KEYBOARD);
				#endif
			}
			break;

		/******************************************************************/
		/*main menu: insert/eject floppy, reset and exit*/
		/******************************************************************/
		case MENU_MAIN1 :
			/*menu title*/
			OsdWrite(0, "  **Minimig Menu** \x1A", 0);
	
			// Display Floppy drives
			for(i=0; i < MAX_FLOPPY_DRIVES; i++)
			{
				sprintf(s," DF%d: ",i);
				if(i > config.floppy_drives)
				{	strcat(s, "disabled");	}
				else
				{
					if (df[i].status & DSK_INSERTED)
					{
						// floppy is inserted
						strncat(s, df[i].name, 8);
						strcat(s,".");
						strncat(s, &df[i].name[8], 3);
	
						// floppy is writable or read-only
						strcat(s, df[i].status & DSK_WRITABLE ? " RW" : " RO");
					}
					else
					{
						// no floppy
						strcat(s, "------------   ");
					}
				}
	
				// Display Floppy info from first line 
				OsdWrite(i+2, s, menusub == i);
			}
			
			// exit menu
			OsdWrite(7, "        exit", menusub==MAX_FLOPPY_DRIVES );
	
			// goto to second state of main menu
			menustate = MENU_MAIN2;
			break;

		case MENU_MAIN2 :
			// menu pressed
			if (menu)
			{	menustate = MENU_NONE1;	}
			else if (up)
			{
				// up pressed
				if (menusub > 0)
				{	menusub--;	}
	
				if (menusub < MAX_FLOPPY_DRIVES && menusub > config.floppy_drives)
				{	menusub = config.floppy_drives;	}
				
				menustate = MENU_MAIN1;
			}
			else if (down)
			{
				// down pressed
				if (menusub < (MAX_FLOPPY_DRIVES + 1) )
				{	menusub++;	}
		
				if (menusub < MAX_FLOPPY_DRIVES && menusub > config.floppy_drives)
				{	menusub = MAX_FLOPPY_DRIVES;	}
	
				menustate = MENU_MAIN1;
			}
			else if (right)
			{
				menustate = MENU_MAIN_EXT1;
				menusub = 0;
				OsdClear();
			}
			else if (select) 
			{
				// select pressed
				if (menusub < MAX_FLOPPY_DRIVES)
				{
					if (df[menusub].status & DSK_INSERTED)
					{
						// eject floppy
						df[menusub].status = 0;
						menustate = MENU_MAIN1;
					}
					else
					{
						df[menusub].status = 0;
						pdfx = &df[menusub];
						
						SelectFile(defFloppyExt, MENU_FLOPPY_SELECTED, menusub, MENU_MAIN1, 1);
					}
				}
				else if (menusub == MAX_FLOPPY_DRIVES )
				{
					// exit menu
					menustate = MENU_NONE1;
				}
			}
			break;

		case MENU_FLOPPY_SELECTED:
			// Select floppy
			InsertFloppy(pdfx);

			//Go to back to main menu
			menustate = MENU_MAIN1;
			OsdClear();
			break;

		/******************************************************************/
		/* Exteneded main menu */
		/******************************************************************/
		case MENU_MAIN_EXT1:
			OsdWrite(0, "\x1B **Minimig Menu**", 0);
			#ifdef ALTERNATE_CORES
			OsdWrite(2, "      settings", 0 == menusub);	// settings
			OsdWrite(3, "      alternate core", 1 == menusub);	// load alternate core
			OsdWrite(4, "      reset", 2 == menusub);		// reset system
			OsdWrite(7, "        exit", 3 == menusub);		// exit menu
			#else
			OsdWrite(2, "      settings", 0 == menusub);	// settings
			OsdWrite(3, "      reset", 1 == menusub);		// reset system
			OsdWrite(7, "        exit", 2 == menusub);		// exit menu
			#endif
			menustate = MENU_MAIN_EXT2;
			break;

		case MENU_MAIN_EXT2:
			#ifdef ALTERNATE_CORES
			HandleUpDown(MENU_MAIN_EXT1, 3);
			#else
			HandleUpDown(MENU_MAIN_EXT1, 2);
			#endif

			if (select) 
			{
				#ifdef ALTERNATE_CORES
					// select pressed
					if (0 == menusub)
					{
						// settings
						menustate = MENU_SETTINGS1;
						OsdClear();
					}
					else if (1 == menusub)
					{
						// Always Core From Root
						OpenRootDirectory(&currentDir);
						// Select Alternate Core
						SelectFile(defCoreExt, MENU_ALTCORE_SELECTED, menusub, MENU_MAIN_EXT1, 0);
					}
					else if (2 == menusub)
					{
						// reset
						menustate = MENU_RESET1;
						menusub = 1;
						OsdClear();
					}
					else if (3 == menusub)
					{
						// exit menu
						menustate = MENU_NONE1;
					}
				#else
					// select pressed
					if (0 == menusub)
					{
						// settings
						menustate = MENU_SETTINGS1;
						OsdClear();
					}
					else if (1 == menusub)
					{
						// reset
						menustate = MENU_RESET1;
						OsdClear();
					}
					else if (2 == menusub)
					{
						// exit menu
						menustate = MENU_NONE1;
					}
				#endif
			}
			
			if (menu)
			{
				menustate = MENU_MAIN1;
			}
			else if (left)
			{
				menustate = MENU_MAIN1;
				menusub = 0;
				OsdClear();
			}
			break;

		/****************************************************************/
		/* File requester menu 											*/
		/****************************************************************/
		case MENU_FILE1:
			PrintDir();
			menustate = MENU_FILE2;
			break;

		case MENU_FILE2:
			if ((i = GetASCIIKey(c)))
			{
				// Scroll to selected letter
				ScrollDir(fbFileExt, i);
				menustate = MENU_FILE1;
			}
			else if (down)
			{
				// scroll down through file requester
				ScrollDir(fbFileExt, DIRECTORY_BROWSE_NEXT);
				menustate = MENU_FILE1;
			}
			else if (up)
			{
				// scroll up through file requester
				ScrollDir(fbFileExt, DIRECTORY_BROWSE_PREV);
				menustate = MENU_FILE1;
			}
			
			if (select)
			{
				// File Selecteed
				if (directory[dirptr].name[0])
				{
					file = directory[dirptr];
					if(file.attributes & FAT_ATTRIB_DIR)
					{
						if(fbAllowDirectorySelect)
						{
							OpenDirectory(&file, &currentDir);
							ScrollDir(fbFileExt, DIRECTORY_BROWSE_START);
						}
						menustate = MENU_FILE1;
					}
					else
					{
						// File Selected exit File requester
						menustate = fbSelectedState;
						menusub = fbSelectedStatePreselect;
					}
					OsdClear();
				}
			}
			
			if (menu)
			{
				// Exit File requester
				menustate = fbExitState;
				OsdClear();
			}
			break;

		/******************************************************************/
		/* reset menu */
		/******************************************************************/
		case MENU_RESET1 :
			/*menu title*/
			OsdWrite(0, "    Reset Minimig?", 0);
			OsdWrite(2, "         yes", 0 == menusub);
			OsdWrite(3, "         no", 1 == menusub);
	
			/*goto to second state of reset menu*/
			menustate = MENU_RESET2;
			break;

		case MENU_RESET2:
			HandleUpDown(MENU_RESET1, 1);
			
			if (select && 0 == menusub)
			{
				menustate = MENU_NONE1;
				OsdReset(RESET_NORMAL);
			}
	
			if (menu || (select && 1 == menusub)) /*exit menu*/
			{
				menustate = MENU_MAIN_EXT1;
				OsdClear();
			}
			break;

		/******************************************************************/
		/*settings menu*/
		/******************************************************************/
		case MENU_SETTINGS1 :
			/*menu title*/
			OsdWrite(0, "   ** SETTINGS **", 0);
	
			OsdWrite(2, "      chipset", 0 == menusub);
			OsdWrite(3, "      memory", 1 == menusub);
			OsdWrite(4, "      drives", 2 == menusub);
			OsdWrite(5, "      video", 3 == menusub);
	
			if (4 == menusub)
			{	OsdWrite(7, "  \x19     exit      \x19", 1);	}
			else if (5 == menusub)
			{	OsdWrite(7, "  \x18     save      \x18", 1);	}
			else
			{	OsdWrite(7, "        exit", 0);		}
	
			/*goto to second state of settings menu*/
			menustate = MENU_SETTINGS2;
			break;

		case MENU_SETTINGS2:
			HandleUpDown(MENU_SETTINGS1, 5);
			
			if (select)
			{
				if (0 == menusub)
				{
					menustate = MENU_SETTINGS_CHIPSET1;
					OsdClear();
				}
				else if (1 == menusub)
				{
					menustate = MENU_SETTINGS_MEMORY1;
					menusub = 0;
					OsdClear();
				}
				else if (2 == menusub)
				{
					menustate = MENU_SETTINGS_DRIVES1;
					menusub = 0;
					OsdClear();
				}
				else if (3 == menusub)
				{
					menustate = MENU_SETTINGS_VIDEO1;
					menusub = 0;
					OsdClear();
				}
				else if (4 == menusub) // return to main menu
				{
					menustate = MENU_MAIN_EXT1;
					menusub = 0;
					OsdClear();
				}
				else if (5 == menusub)
				{
					SaveConfiguration();
					menustate = MENU_MAIN_EXT1;
					menusub = 0;
					OsdClear();
				}
			}
			
			if (menu)
			{
				// return to main menu
				menustate = MENU_MAIN_EXT1;
				menusub = 0;
				OsdClear();
			}
			break;

		/******************************************************************/
		/* chipset settings menu */
		/******************************************************************/
		case MENU_SETTINGS_CHIPSET1 :
			OsdWrite(0, " \x1B  -= CHIPSET =-  \x1A", 0);
	
			#if	defined(PGL090421)
				strcpy(s, "      CPU : ");
				strcat(s, config.chipset & CONFIG_CPU_28MHZ ? "28.36MHz " : " 7.09MHz");
				OsdWrite(2, s, 0 == menusub);
	
				strcpy(s, "  Blitter : ");
				strcat(s, config.chipset & CONFIG_BLITTER_FAST ? "fast  " : "normal");
				OsdWrite(3, s, 1 == menusub);
	
				strcpy(s, "    Agnus : ");
				strcat(s, config.chipset & CONFIG_AGNUS_NTSC ? "NTSC" : "PAL ");
				OsdWrite(4, s, 2 == menusub);
			#elif	defined(PGL090911) || defined(PGL091224)
				strcpy(s, "      CPU : ");
				strcat(s, config.chipset & CONFIG_CPU_TURBO ? "turbo " : "normal");
				OsdWrite(2, s, 0 == menusub);
	
				strcpy(s, "    Agnus : ");
				strcat(s, config.chipset & CONFIG_AGNUS_NTSC ? "NTSC  " : "PAL ");
				OsdWrite(3, s, 1 == menusub);
	
				strcpy(s, "    Agnus : ");
				strcat(s, config.chipset & CONFIG_AGNUS_ECS ? "ECS" : "OCS");
				OsdWrite(4, s, 2 == menusub);
			#elif	defined(PGL100818)
				strcpy(s, "      CPU : ");
				strcat(s, config.chipset & CONFIG_TURBO ? "turbo " : "normal");
				OsdWrite(2, s, 0 == menusub);
	
				strcpy(s, "    Video : ");
				strcat(s, config.chipset & CONFIG_NTSC ? "NTSC  " : "PAL ");
				OsdWrite(3, s, 1 == menusub);
	
				strcpy(s, "  Chipset : ");
				strcat(s, config_chipset_msg[config.chipset >> 2 & 0x03]);
				OsdWrite(4, s, 2 == menusub);
			#endif
	
			OsdWrite(7, "        exit", 3 == menusub);
	
			/*goto to second state of reset menu*/
			menustate = MENU_SETTINGS_CHIPSET2;
			break;

		case MENU_SETTINGS_CHIPSET2 :
			HandleUpDown(MENU_SETTINGS_CHIPSET1, 3);
	
			if (select)
			{
				#if	defined(PGL090421)

					if (0 == menusub)
					{
						config.chipset ^= CONFIG_CPU_28MHZ;
						menustate = MENU_SETTINGS_CHIPSET1;
						ConfigChipset(config.chipset);
					}
					else if (1 == menusub)
					{
						config.chipset ^= CONFIG_BLITTER_FAST;
						menustate = MENU_SETTINGS_CHIPSET1;
						ConfigChipset(config.chipset);
					}
					else if (2 == menusub)
					{
						config.chipset ^= CONFIG_AGNUS_NTSC;
						menustate = MENU_SETTINGS_CHIPSET1;
						ConfigChipset(config.chipset);
					}
					else if (3 == menusub)/*return to settings menu*/
					{
						menustate = MENU_SETTINGS1;
						menusub = 0;
						OsdClear();
					}

				#elif	defined(PGL090911) || defined(PGL091224)

					if (0 == menusub)
					{
						config.chipset ^= CONFIG_CPU_TURBO;
						menustate = MENU_SETTINGS_CHIPSET1;
						ConfigChipset(config.chipset);
					}
					else if (1 == menusub)
					{
						config.chipset ^= CONFIG_AGNUS_NTSC;
						menustate = MENU_SETTINGS_CHIPSET1;
						ConfigChipset(config.chipset);
					}
					else if (2 == menusub)
					{
						config.chipset ^= CONFIG_AGNUS_ECS;
						menustate = MENU_SETTINGS_CHIPSET1;
						ConfigChipset(config.chipset);
					}
					else if (3 == menusub)/*return to settings menu*/
					{
						menustate = MENU_SETTINGS1;
						menusub = 0;
						OsdClear();
					}

				#elif	defined(PGL100818)

					if (0 == menusub)
					{
						config.chipset ^= CONFIG_TURBO;
						menustate = MENU_SETTINGS_CHIPSET1;
						ConfigChipset(config.chipset);
					}
					else if (1 == menusub)
					{
						config.chipset ^= CONFIG_NTSC;
						menustate = MENU_SETTINGS_CHIPSET1;
						ConfigChipset(config.chipset);
					}
					else if (2 == menusub)
					{
						if(config.chipset & CONFIG_ECS)
						{	config.chipset &= ~(CONFIG_ECS|CONFIG_A1000);	}
						else
						{	config.chipset += CONFIG_A1000;	}

						menustate = MENU_SETTINGS_CHIPSET1;
						ConfigChipset(config.chipset);
					}
					else if (3 == menusub)/*return to settings menu*/
					{
						menustate = MENU_SETTINGS1;
						menusub = 0;
						OsdClear();
					}
					
				#endif
			}
	
			if (menu)/*return to settings menu*/
			{
				menustate = MENU_SETTINGS1;
				menusub = 0;
				OsdClear();
			}
			else if (right)
			{
				menustate = MENU_SETTINGS_MEMORY1;
				menusub = 0;
				OsdClear();
			}
			else if (left)
			{
				menustate = MENU_SETTINGS_VIDEO1;
				menusub = 0;
				OsdClear();
			}
			break;

		/******************************************************************/
		/* memory settings menu */
		/******************************************************************/
		case MENU_SETTINGS_MEMORY1 :
			/*menu title*/
			OsdWrite(0, " \x1B  -= MEMORY =-   \x1A", 0);
	
			strcpy(s, "  CHIP : ");
			strcat(s, config_memory_chip_msg[config.memory & 0x03]);
			OsdWrite(2, s, 0 == menusub);
	
			strcpy(s, "  SLOW : ");
			strcat(s, config_memory_slow_msg[config.memory >> 2 & 0x03]);
			OsdWrite(3, s, 1 == menusub);
	
			strcpy(s, "  ROM  : ");
			strncat(s, config.kickname, 8);
			OsdWrite(4, s, 2 == menusub);
	
			strcpy(s, "  AR3  : ");
			strcat(s, config.ar3 ? "enabled " : "disabled");
			OsdWrite(5, s, 3 == menusub);
	
			OsdWrite(7, "        exit", 4 == menusub);
	
			/*goto to second state of memory settings menu*/
			menustate = MENU_SETTINGS_MEMORY2;
			break;

		case MENU_SETTINGS_MEMORY2 :
			HandleUpDown(MENU_SETTINGS_MEMORY1, 4);
	
			if (select)
			{
				if (0 == menusub)
				{
					config.memory = config.memory + 1 & 0x03 | config.memory & ~0x03;
					menustate = MENU_SETTINGS_MEMORY1;
					ConfigMemory(config.memory);
				}
				else if (1 == menusub)
				{
					config.memory = config.memory + 4 & 0x0C | config.memory & ~0x0C;
					menustate = MENU_SETTINGS_MEMORY1;
					ConfigMemory(config.memory);
				}
				else if (2 == menusub)
				{
					// Always Open Rom From Root
					OpenRootDirectory(&currentDir);
					SelectFile(defRomExt, MENU_ROMFILESELECTED1, 0, MENU_SETTINGS_MEMORY1, 0);
				}
				else if (3 == menusub)
				{
					config.ar3 ^= 0x01;
					menustate = MENU_SETTINGS_MEMORY1;
				}
				else if (4 == menusub)/*return to settings menu*/
				{
					menustate = MENU_SETTINGS1;
					menusub = 1;
					OsdClear();
				}
			}
	
			if (menu)/*return to settings menu*/
			{
				menustate = MENU_SETTINGS1;
				menusub = 1;
				OsdClear();
			}
			else if (right)
			{
				menustate = MENU_SETTINGS_DRIVES1;
				menusub = 0;
				OsdClear();
			}
			else if (left)
			{
				menustate = MENU_SETTINGS_CHIPSET1;
				menusub = 0;
				OsdClear();
			}
			break;

		/******************************************************************/
		/* floppy/hdd settings menu */
		/******************************************************************/
		case MENU_SETTINGS_DRIVES1 :
			OsdWrite(0, " \x1B  -= DRIVES =-   \x1A", 0);
	
			sprintf(s,"   drives   : %d", config.floppy_drives + 1);
			OsdWrite(2, s, 0 == menusub);
	
			sprintf(s,"   speed    : %s", config.floppy_speed ? "2x " : "1x");
			OsdWrite(3, s, 1 == menusub);
	
			sprintf(s,"   A600 IDE : %s", config.ide ? "on " : "off");
			OsdWrite(4, s, menusub == 2);
	
	        sprintf(s,"  hardfiles : %d", (hdf[0].present & hdf[0].enabled) + (hdf[1].present & hdf[1].enabled));
	        OsdWrite(5,s, 3 == menusub);
	
			OsdWrite(7, "        exit", 4 == menusub);
	
			/*goto to second state of floppy menu*/
			menustate = MENU_SETTINGS_DRIVES2;
			break;

		case MENU_SETTINGS_DRIVES2 :
			HandleUpDown(MENU_SETTINGS_DRIVES1, 4);
	
			if (select)
			{
				if (0 == menusub)
				{
					config.floppy_drives++;
					if(config.floppy_drives > (MAX_FLOPPY_DRIVES-1))
					{	config.floppy_drives = 0;	}
					menustate = MENU_SETTINGS_DRIVES1;
					ConfigFloppy(config.floppy_drives, config.floppy_speed);
				}
				else if (1 == menusub)
				{
					config.floppy_speed ^= CONFIG_FLOPPY2X; 
					menustate = MENU_SETTINGS_DRIVES1;
					ConfigFloppy(config.floppy_drives, config.floppy_speed);
				}
				else if (2 == menusub)
				{
	                config.ide ^= 0x01;
	                menustate = MENU_SETTINGS_DRIVES1;
	                ConfigIDE(config.ide, hdf[0].present & hdf[0].enabled, hdf[1].present & hdf[1].enabled);
				}
				else if (3 == menusub)
				{
	                menustate = MENU_SETTINGS_HARDFILE1;
	                menusub = 0;
	    			OsdClear();
				}
				else if (4 == menusub)/*return to settings menu*/
				{
					menustate = MENU_SETTINGS1;
					menusub = 2;
					OsdClear();
				}
			}
	
			if (menu)/*return to settings menu*/
			{
				menustate = MENU_SETTINGS1;
				menusub = 2;
				OsdClear();
			}
			else if (right)
			{
				menustate = MENU_SETTINGS_VIDEO1;
				menusub = 0;
				OsdClear();
			}
			else if (left)
			{
				menustate = MENU_SETTINGS_MEMORY1;
				menusub = 0;
				OsdClear();
			}
			break;


		/******************************************************************/
		/* HDD settings menu */
		/******************************************************************/
		case MENU_SETTINGS_HARDFILE1:
			OsdWrite(0, "   -= HARDFILES =-", 0);
	
			// Display HardFiles
			for(i=0; i < 2; i++)
			{
		        strcpy(s, i ? "  Slave: " : " Master: ");
		        strcat(s, hdf[i].present ? (hdf[i].enabled ? "enabled" : "disabled") : "n/a");
		        OsdWrite(2+(i*2), s, menusub == (0 + (i*2)));
		        if (hdf[i].present)
		        {	sprintf(s,"         %.8s.%.3s", hdf[i].file.name, &hdf[i].file.name[8]);	}
		        else
		        {	strcpy(s, "         Not found");	}
		        OsdWrite(3+(i*2), s, menusub == (1 + (i*2)));
			}

			OsdWrite(7, "        exit", menusub == 4);
	
	        menustate = MENU_SETTINGS_HARDFILE2;
			break;

		case MENU_SETTINGS_HARDFILE2:
			HandleUpDown(MENU_SETTINGS_HARDFILE1, 4);
	
			if (select)
			{
				if (0 == menusub)
				{
					if (hdf[0].present)
					{
						hdf[0].enabled ^= 0x01;
						menustate = MENU_HARDFILE_SELECTED;
						OsdClear();
					}
				}
				else if (2 == menusub)
				{
					if (hdf[1].present)
					{
						hdf[1].enabled ^= 0x01;
						menustate = MENU_HARDFILE_SELECTED;
						OsdClear();
					}
				}
				else if ((1 == menusub) || (3 == menusub))
				{
					i = menusub>>1;
					if(hdf[i].file.name[0])
					{
						// Clear HD File and File Handle
						memset(&hdf[i],0,sizeof(struct hdfTYPE));
						memset(&file,0,sizeof(struct fileTYPE));
						menustate = MENU_HARDFILE_SELECTED;
						OsdClear();
					}
					else
					{
						// Always Open Hard disk file from Root
						OpenRootDirectory(&currentDir);
						SelectFile(defHardDiskExt, MENU_HARDFILE_SELECTED, menusub, MENU_SETTINGS_HARDFILE1, 0);
					}
				}
				else if (4 == menusub) // return to previous menu
				{
					menustate = MENU_SETTINGS_DRIVES1;
					OsdClear();
				}
	        }
	
	        if (menu) // return to previous menu
	        {	
	        	menustate = MENU_SETTINGS_DRIVES1;
				OsdClear();
	        }
			break;
			
		/******************************************************************/
		/* HDD Selected */
		/******************************************************************/
		case MENU_HARDFILE_SELECTED:
			// Selected Master
			if(1 == menusub)
			{	OpenHardfile(0, file.name);		}

			// Selected Slave
			if (3 == menusub)
			{	OpenHardfile(1, file.name);		}
			
			// Reconfigure HD Files
			ConfigIDE(config.ide, hdf[0].present & hdf[0].enabled, hdf[1].present & hdf[1].enabled);

			// Return to HD File Selection
        	menustate = MENU_SETTINGS_HARDFILE1;
			break;

		/******************************************************************/
		/* video settings menu */
		/******************************************************************/
		case MENU_SETTINGS_VIDEO1 :
			OsdWrite(0, " \x1B   -= VIDEO =-   \x1A", 0);
	
			strcpy(s, "  Lores Filter: ");
			strcpy( &s[16], config_filter_msg[config.filter_lores]);
			OsdWrite(2, s, 0 == menusub);
	
			strcpy(s, "  Hires Filter: ");
			strcpy( &s[16], config_filter_msg[config.filter_hires]);
			OsdWrite(3, s, 1 == menusub);
	
			strcpy(s, "  Scanline    : ");
			strcpy( &s[16], config_scanline_msg[config.scanline]);
			OsdWrite(4, s, 2 == menusub);
	
			OsdWrite(7, "        exit", 3 == menusub);
	
			// goto to second state of video settings menu
			menustate = MENU_SETTINGS_VIDEO2;
			break;

		case MENU_SETTINGS_VIDEO2:
			HandleUpDown(MENU_SETTINGS_VIDEO1, 3);
	
			if (select)
			{
				if (0 == menusub)
				{
					config.filter_lores++;
					config.filter_lores &= 0x03;
					menustate = MENU_SETTINGS_VIDEO1;
					ConfigFilter(config.filter_lores, config.filter_hires);
				}
				else if (1 == menusub)
				{
					config.filter_hires++;
					config.filter_hires &= 0x03;
					menustate = MENU_SETTINGS_VIDEO1;
					ConfigFilter(config.filter_lores, config.filter_hires);
				}
				else if (2 == menusub)
				{
					config.scanline++;
					if (config.scanline > 2)
					{	config.scanline = 0;	}
					menustate = MENU_SETTINGS_VIDEO1;
					ConfigScanline(config.scanline);
				}
				else if (3 == menusub)/*return to settings menu*/
				{
					menustate = MENU_SETTINGS1;
					OsdClear();
				}
			}
	
			if (menu)/*return to settings menu*/
			{
				menustate = MENU_SETTINGS1;
				menusub = 3;
				OsdClear();
			}
			else if (right)
			{
				menustate = MENU_SETTINGS_CHIPSET1;
				menusub = 0;
				OsdClear();
			}
			else if (left)
			{
				menustate = MENU_SETTINGS_DRIVES1;
				menusub = 0;
				OsdClear();
			}
			break;

		/******************************************************************/
		/*rom file select message menu*/
		/******************************************************************/
		case MENU_ROMFILESELECTED1:
			/*menu title*/
			OsdWrite(0, "  Reload Kickstart?", 0);
			OsdWrite(2, "         yes", 0 == menusub);
			OsdWrite(3, "         no", 1 == menusub);
	
			menustate = MENU_ROMFILESELECTED2;
			break;

		case MENU_ROMFILESELECTED2 :
			HandleUpDown(MENU_ROMFILESELECTED1, 1);
	
			if (select)
			{
				if (0 == menusub)
				{
					if (directory[dirptr].name[0])
					{
						memcpy((void*)config.kickname, (void*)directory[dirptr].name, 12);
	
						OsdDisable();

						//reset to bootloader
						OsdReset(RESET_BOOTLOADER);
						
						#if	defined(PGL090421)
							ConfigChipset(config.chipset|CONFIG_CPU_28MHZ);			//force CPU turbo mode
						#elif	defined(PGL090911) || defined(PGL091224)
							ConfigChipset(config.chipset|CONFIG_CPU_TURBO);			//force CPU turbo mode
						#elif	defined(PGL100818) 
							ConfigChipset(config.chipset|CONFIG_TURBO);				//force CPU turbo mode
						#endif

						ConfigFloppy(1, 1);
						
						if (0 == UploadKickstart(config.kickname))
						{	BootExit();	}

						ConfigChipset(config.chipset);
						ConfigFloppy(config.floppy_drives, config.floppy_speed);
					}
					menustate = MENU_NONE1;
				}
				else if (1 == menusub)/*exit menu*/
				{
					menustate = MENU_SETTINGS_MEMORY1;
					menusub = 2;
					OsdClear();
				}
			}
	
			if (menu)/*exit menu*/
			{
				menustate = MENU_SETTINGS_MEMORY1;
				menusub = 2;
				OsdClear();
			}
			break;

		#ifdef ALTERNATE_CORES
		/******************************************************************/
		/*Alternate Core Selected */
		/******************************************************************/
		case MENU_ALTCORE_SELECTED:
			
			// Check if default core selected
			for(i=0; i<11; i++)
			{
				if (directory[dirptr].name[i]!=defFPGAName[i])
				{	break;	}
			}
			
			if (11 != i)
			{
				// Close Menu
				OsdDisable();
				menustate = MENU_NONE1;

				// Load Selected core
				if (ConfigureFpga(directory[dirptr].name))
				{
					// Mark Alternate Core Loaded
					bAlternateCoreLoaded = 1;
				}
			}
			else
			{
				// Default Core Selected Exit
				menustate = MENU_MAIN_EXT1;
				menusub = 1;
				OsdClear();
			}
			break;
		#endif

		/******************************************************************/
		/*error message menu*/
		/******************************************************************/
		case MENU_ERROR:
			/*exit when menu button is pressed*/
			if (menu)
			{	menustate = MENU_NONE1;	}
			break;

		#ifdef	AUTOFIRE_RATE_KEYBOARD_SELECT || TURBO_MODE_KEYBOARD_SELECT
		/******************************************************************/
		/*Info message menu*/
		/******************************************************************/
		case MENU_INFO:
			/*exit when menu button is pressed*/
			if (menu)
			{	menustate = MENU_NONE1;		}
			else if (CheckTimer(menu_timer))
			{	menustate = MENU_NONE1;		}
			break;
		#endif
	
		/******************************************************************/
		/*we should never come here*/
		/******************************************************************/
		default:
			break;
	}
}


// Handle Up Down menu navigation
void HandleUpDown(unsigned char state, unsigned char max)
{
	if (down && menusub < max)
	{
		menusub++;
		menustate = state;
	}

	if (up && menusub > 0)
	{
		menusub--;
		menustate = state;
	}
}


void SelectFile(const char* extension, unsigned char selectedState, unsigned char selectedStatePreselect, unsigned char exitState, unsigned char allowDirectorySelect)
{
	// Set File Browser settings and fill initial directory
	fbFileExt = extension;
	fbSelectedState = selectedState;
	fbSelectedStatePreselect = selectedStatePreselect;
	fbExitState = exitState;
	fbAllowDirectorySelect = allowDirectorySelect;
	
	// Prefill Directory
	ScrollDir(fbFileExt, DIRECTORY_BROWSE_START);

	// Go to File Browser
	menustate = MENU_FILE1;
	OsdClear();
}


// Display OSD Error message
void ErrorMessage(const char* message, unsigned char code)
{
	unsigned char i;
	menustate = MENU_ERROR;
	OsdClear();
	OsdWrite(0,"    *** ERROR ***",1);
	strncpy(s,message,21);
	s[21] = 0;
	OsdWrite(2,s,0);

	if (code)
	{
		sprintf(s,"  error #%d",code);
		OsdWrite(4,s,0);
	}
	#if	defined(PGL090421) || defined(PGL090911) || defined(PGL091224)
		OsdEnable();
	#elif	defined(PGL100818) 
		OsdEnable(0);	// Don't dissable keyboard
	#endif
}


#ifdef AUTOFIRE_RATE_KEYBOARD_SELECT

void AutoFireSwitch()
{
	// Control + Left Alt + Keypad 0 and not in menu
	if(ctrl && lalt && (menustate == MENU_NONE2 || menustate == MENU_INFO))
	{
		config_autofire++;
		config_autofire &= 0x03;
		ConfigAutofire(config_autofire);
		sprintf(s, "AutoFire:%s", config_autofire_msg[config_autofire]);
		InfoMessage(s);
	}
}

#endif

#ifdef TURBO_MODE_KEYBOARD_SELECT

void TurboModeSwitch(unsigned char bTurbo)
{
	// Control + Left Alt + Keypad Plus/Minus
	if(ctrl && lalt)
	{
		if(bTurbo)
		{	config.chipset |= CONFIG_TURBO;	}
		else
		{	config.chipset &= ~CONFIG_TURBO;	}
		ConfigChipset(config.chipset);

		if (menustate == MENU_SETTINGS_CHIPSET2)
		{	menustate = MENU_SETTINGS_CHIPSET1;	}
		else if (menustate == MENU_NONE2 || menustate == MENU_INFO)
		{
			sprintf(s, "Turbo:%s", bTurbo ? "On":"Off");
			InfoMessage(s);
		}
	}
}

#endif

#ifdef AUTOFIRE_RATE_KEYBOARD_SELECT || TURBO_MODE_KEYBOARD_SELECT

void InfoMessage(char *message)
{   
	// TODO: Make it wait Vertical Blank
	//OsdWaitVBL();

	if (menustate != MENU_INFO)
	{	
		OsdClear();
		// do not disable keyboard
		OsdEnable(0);
	}
	
	OsdWrite(1, message, 0);
	// Keep it for one sec on screen
	menu_timer = GetTimer(100);
	menustate = MENU_INFO;
}

#endif
