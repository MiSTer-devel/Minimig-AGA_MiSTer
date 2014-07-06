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

// 2009-11-14   - OSD labels changed
// 2009-12-15   - added display of directory name extensions
// 2010-01-09   - support for variable number of tracks

//#include "AT91SAM7S256.h"
//#include "stdbool.h"
#include "stdio.h"
#include "string.h"
#include "errors.h"
#include "mmc.h"
#include "fat.h"
#include "osd.h"
#include "fpga.h"
#include "fdd.h"
#include "hdd.h"
#include "hardware.h"
#include "firmware.h"
#include "config.h"
#include "menu.h"


// other constants
#define DIRSIZE 8 // number of items in directory display window

unsigned char menustate = MENU_NONE1;
unsigned char parentstate;
unsigned char menusub = 0;
unsigned int menumask = 0; // Used to determine which rows are selectable...
unsigned long menu_timer;

extern unsigned char drives;
extern adfTYPE df[4];

extern configTYPE config;
extern fileTYPE file;
extern char s[40];

extern unsigned char fat32;

extern DIRENTRY DirEntry[MAXDIRENTRIES];
extern unsigned char sort_table[MAXDIRENTRIES];
extern unsigned char nDirEntries;
extern unsigned char iSelectedEntry;
extern unsigned long iCurrentDirectory;
extern char DirEntryLFN[MAXDIRENTRIES][261];
char DirEntryInfo[MAXDIRENTRIES][5]; // disk number info of dir entries
char DiskInfo[5]; // disk number info of selected entry

extern const char version[];

const char *config_filter_msg[] =  {"none", "HORIZONTAL", "VERTICAL", "H+V"};
const char *config_memory_chip_msg[] = {"0.5 MB", "1.0 MB", "1.5 MB", "2.0 MB"};
const char *config_memory_slow_msg[] = {"none  ", "0.5 MB", "1.0 MB", "1.5 MB"};
const char *config_scanlines_msg[] = {"off", "dim", "black"};
const char *config_memory_fast_msg[] = {"none  ", "2.0 MB", "4.0 MB"};
const char *config_cpu_msg[] = {"68000 ", "68010", "-----","020 alpha"};
const char *config_hdf_msg[] = {"Disabled", "Hardfile (disk img)", "MMC/SD card", "MMC/SD partition 1", "MMC/SD partition 2", "MMC/SD partition 3", "MMC/SD partition 4"};

const char *config_chipset_msg[] = {"OCS-A500", "OCS-A1000", "ECS", "---"};

char *config_autofire_msg[] = {"        AUTOFIRE OFF", "        AUTOFIRE FAST", "        AUTOFIRE MEDIUM", "        AUTOFIRE SLOW"};

enum HelpText_Message {HELPTEXT_NONE,HELPTEXT_MAIN,HELPTEXT_HARDFILE,HELPTEXT_CHIPSET,HELPTEXT_MEMORY,HELPTEXT_VIDEO};
const char *helptexts[]={
	0,
	"                                Welcome to Minimig!  Use the cursor keys to navigate the menus.  Use space bar or enter to select an item.  Press Esc or F12 to exit the menus.  Joystick emulation on the numeric keypad can be toggled with the numlock key, while pressing Ctrl-Alt-0 (numeric keypad) toggles autofire mode.",
	"                                Minimig can emulate an A600 IDE harddisk interface.  The emulation can make use of Minimig-style hardfiles (complete disk images) or UAE-style hardfiles (filesystem images with no partition table).  It is also possible to use either the entire SD card or an individual partition as an emulated harddisk.",
	"                                Minimig's processor core can emulate a 68000 or 68020 processor (though the 68020 mode is still experimental.)  If you're running software built for 68000, there's no advantage to using the 68020 mode, since the 68000 emulation runs just as fast.",
#ifdef ACTIONREPLAY_BROKEN
	"                                Minimig can make use of up to 2 megabytes of Chip RAM, up to 1.5 megabytes of Slow RAM (A500 Trapdoor RAM), and up to 8 megabytes of true Fast RAM.",
#else
	"                                Minimig can make use of up to 2 megabytes of Chip RAM, up to 1.5 megabytes of Slow RAM (A500 Trapdoor RAM), and up to 8 megabytes of true Fast RAM.  To use the Action Replay feature you will need an Action Replay 3 ROM file on the SD card, named AR3.ROM.  You will also need to set Fast RAM to no more than 2 megabytes.",
#endif
	"                                Minimig's video features include a blur filter, to simulate the poorer picture quality on older monitors, and also scanline generation to simulate the appearance of a screen with low vertical resolution.",
	0
};

//extern unsigned char DEBUG;

unsigned char config_autofire = 0;

// file selection menu variables
char *fs_pFileExt = NULL;
unsigned char fs_Options;
unsigned char fs_MenuSelect;
unsigned char fs_MenuCancel;

static char debuglines[8*32+1];
static char debugptr=0;

void _showdebugmessages()
{
  DEBUG_FUNC_IN(DEBUG_F_MENU | DEBUG_L2);

	int i;
	for(i=0;i<8;++i)
	{
		int j=(debugptr+i)&7;
		debuglines[j*32+31]=0;
		OsdWrite(i,&debuglines[j*32],i==7,0);
	}

  DEBUG_FUNC_OUT(DEBUG_F_MENU | DEBUG_L2);
}

void SelectFile(char* pFileExt, unsigned char Options, unsigned char MenuSelect, unsigned char MenuCancel)
{
  DEBUG_FUNC_IN(DEBUG_F_MENU | DEBUG_L1);

    // this function displays file selection menu

    if (strncmp(pFileExt, fs_pFileExt, 3) != 0) // check desired file extension
    { // if different from the current one go to the root directory and init entry buffer
        ChangeDirectory(DIRECTORY_ROOT);
        ScanDirectory(SCAN_INIT, pFileExt, Options);
    }

    fs_pFileExt = pFileExt;
    fs_Options = Options;
    fs_MenuSelect = MenuSelect;
    fs_MenuCancel = MenuCancel;

    menustate = MENU_FILE_SELECT1;

  DEBUG_FUNC_OUT(DEBUG_F_MENU | DEBUG_L1);
}

#define STD_EXIT "            exit"
#define HELPTEXT_DELAY 10000
#define FRAME_DELAY 150


void ShowSplash()
{
  DEBUG_FUNC_IN(DEBUG_F_MENU | DEBUG_L0);

	OsdSetTitle("Welcome",0);
    OsdWrite(0, "", 0,0);
	OsdDrawLogo(1,0,0);
	OsdDrawLogo(2,1,0);
	OsdDrawLogo(3,2,0);
	OsdDrawLogo(4,3,0);
	OsdDrawLogo(5,4,0);
    OsdWrite(6, "", 0,0);
    OsdWrite(7, "", 0,0);
	OsdEnable(0);

  DEBUG_FUNC_OUT(DEBUG_F_MENU | DEBUG_L0);
}


void HideSplash()
{
  DEBUG_FUNC_IN(DEBUG_F_MENU | DEBUG_L0);

	OsdDisable();

  DEBUG_FUNC_OUT(DEBUG_F_MENU | DEBUG_L0);
}


void HandleUI(void)
{
  DEBUG_FUNC_IN(DEBUG_F_MENU | DEBUG_L2);

    unsigned char i, c, up, down, select, menu, right, left, plus, minus;
    unsigned long len;
    static hardfileTYPE t_hardfile[2]; // temporary copy of former hardfile configuration
    static unsigned char ctrl = false;
    static unsigned char lalt = false;
	char enable;
	static long helptext_timer;
	static const char *helptext;
	static char helpstate=0;

    // get user control codes
    c = OsdGetCtrl();

    // decode and set events
    menu = false;
    select = false;
    up = false;
    down = false;
    left = false;
    right = false;
	plus=false;
	minus=false;

    switch (c)
    {
    case KEY_CTRL :
        ctrl = true;
        break;
    case KEY_CTRL | KEY_UPSTROKE :
        ctrl = false;
        break;
    case KEY_LALT :
        lalt = true;
        break;
    case KEY_LALT | KEY_UPSTROKE :
        lalt = false;
        break;
    case KEY_KPPLUS :
        if (ctrl && lalt)
        {
            config.chipset |= CONFIG_TURBO;
            ConfigChipset(config.chipset);
            if (menustate == MENU_SETTINGS_CHIPSET2)
                menustate = MENU_SETTINGS_CHIPSET1;
            else if (menustate == MENU_NONE2 || menustate == MENU_INFO)
                InfoMessage("             TURBO");
        }
		else
			plus=true;
        break;
    case KEY_KPMINUS :
        if (ctrl && lalt)
        {
            config.chipset &= ~CONFIG_TURBO;
            ConfigChipset(config.chipset);
            if (menustate == MENU_SETTINGS_CHIPSET2)
                menustate = MENU_SETTINGS_CHIPSET1;
            else if (menustate == MENU_NONE2 || menustate == MENU_INFO)
                InfoMessage("             NORMAL");
        }
		else
			minus=true;
        break;
    case KEY_KP0 :
        if (ctrl && lalt)
        {
            if (menustate == MENU_NONE2 || menustate == MENU_INFO)
            {
                config_autofire++;
                config_autofire &= 3;
                ConfigAutofire(config_autofire);
                if (menustate == MENU_NONE2 || menustate == MENU_INFO)
                    InfoMessage(config_autofire_msg[config_autofire]);
            }
        }
        break;
    case KEY_MENU :
        if (ctrl && lalt)
		{
			OsdSetTitle("Debug",0);
			DebugMode=DebugMode^1;
	        menustate = MENU_NONE1;
		}
		else
	        menu = true;
        break;
    case KEY_ESC :
        if (menustate != MENU_NONE2)
            menu = true;
        break;
    case KEY_ENTER :
    case KEY_SPACE :
        select = true;
        break;
    case KEY_UP :
        up = true;
        break;
    case KEY_DOWN :
        down = true;
        break;
    case KEY_LEFT :
        left = true;
        break;
    case KEY_RIGHT :
        right = true;
        break;
    }

	if(menu || select || up || down || left || right )
	{
		if(helpstate)
			OsdWrite(7,STD_EXIT,(menumask-((1<<(menusub+1))-1))<=0,0); // Redraw the Exit line...
		helpstate=0;
		helptext_timer=GetTimer(HELPTEXT_DELAY);
	}

	if(helptext)
	{
		if(helpstate<9)
		{
			if(CheckTimer(helptext_timer))
			{
				helptext_timer=GetTimer(FRAME_DELAY);
				OsdWriteOffset(7,STD_EXIT,0,0,helpstate);
				++helpstate;
			}
		}
		else if(helpstate==9)
		{
			ScrollReset();
			++helpstate;
		}
		else
			ScrollText(7,helptext,0,0,0);
	}

	// Standardised menu up/down.
	// The screen should set menumask, bit 0 to make the top line selectable, bit 1 for the 2nd line, etc.
	// (Lines in this context don't have to correspond to rows on the OSD.)
	// Also set parentstate to the appropriate menustate.
	if(menumask)
	{
        if ((unsigned)down && ((unsigned)menumask>=(unsigned)(1<<(menusub+1))))	// Any active entries left?
		{
			do
				menusub++;
			while((menumask & (1<<menusub)) == 0);
            menustate = parentstate;
        }

        if (up && menusub > 0 && (menumask<<(8-menusub)))
        {
			do
				--menusub;
			while((menumask & (1<<menusub)) == 0);
            menustate = parentstate;
        }
	}


    switch (menustate)
    {
        /******************************************************************/
        /* no menu selected                                               */
        /******************************************************************/
    case MENU_NONE1 :
		helptext=helptexts[HELPTEXT_NONE];
		menumask=0;
		if(DebugMode)
		{
			helptext=helptexts[HELPTEXT_NONE];
			OsdEnable(0);
		}
		else
	        OsdDisable();
        menustate = MENU_NONE2;
        break;

    case MENU_NONE2 :
		if(DebugMode)
			_showdebugmessages();
        if (menu)
        {
            menustate = MENU_MAIN1;
            menusub = 0;
            OsdClear();
            OsdEnable(DISABLE_KEYBOARD);
        }
        break;

        /******************************************************************/
        /* main menu                                                      */
        /******************************************************************/
    case MENU_MAIN1 :
		menumask=0x70;	// b01110000 Floppy turbo, Harddisk options & Exit.
		OsdSetTitle("Minimig",OSD_ARROW_RIGHT);
		helptext=helptexts[HELPTEXT_MAIN];

        // floppy drive info
		// We display a line for each drive that's active
		// in the config file, but grey out any that the FPGA doesn't think are active.
		// We also print a help text in place of the last drive if it's inactive.
        for (i = 0; i < 4; i++)
        {
			if(i==config.floppy.drives+1)
				OsdWrite(i," KP +/- to add/remove drives",0,1);
			else
			{
		        strcpy(s, " dfx: ");
		        s[3] = i + '0';
				if(i<=drives)
				{
					menumask|=(1<<i);	// Make enabled drives selectable

				    if (df[i].status & DSK_INSERTED) // floppy disk is inserted
				    {
				        strncpy(&s[6], df[i].name, sizeof(df[0].name));
						if(!(df[i].status & DSK_WRITABLE))
					        strcpy(&s[6 + sizeof(df[i].name)-1], " \x17"); // padlock icon for write-protected disks
						else
					        strcpy(&s[6 + sizeof(df[i].name)-1], "  "); // clear padlock icon for write-enabled disks
				    }
				    else // no floppy disk
					{
				        strcat(s, "* no disk *");
					}
				}
				else if(i<=config.floppy.drives)
				{
					strcat(s,"* active after reset *");
				}
				else
					strcpy(s,"");
		        OsdWrite(i, s, menusub == i,(i>drives)||(i>config.floppy.drives));
			}
        }
		sprintf(s," Floppy disk turbo : %s",config.floppy.speed ? "on" : "off");
        OsdWrite(4, s, menusub==4,0);
        OsdWrite(5, " Hard disk settings \x16", menusub == 5,0);
        OsdWrite(6, "", 0,0);
        OsdWrite(7, STD_EXIT, menusub == 6,0);

        menustate = MENU_MAIN2;
		parentstate=MENU_MAIN1;
        break;

    case MENU_MAIN2 :
        if (menu)
            menustate = MENU_NONE1;
		else if(plus && (config.floppy.drives<3))
		{
			config.floppy.drives++;
			ConfigFloppy(config.floppy.drives,config.floppy.speed);
	        menustate = MENU_MAIN1;
		}
		else if(minus && (config.floppy.drives>0))
		{
			config.floppy.drives--;
			ConfigFloppy(config.floppy.drives,config.floppy.speed);
	        menustate = MENU_MAIN1;
		}
        else if (select)
        {
            if (menusub < 4)
            {
                if (df[menusub].status & DSK_INSERTED) // eject selected floppy
                {
                    df[menusub].status = 0;
                    menustate = MENU_MAIN1;
                }
                else
                {
                    df[menusub].status = 0;
                    SelectFile("ADF", SCAN_DIR | SCAN_LFN, MENU_FILE_SELECTED, MENU_MAIN1);
                }
            }
            else if (menusub == 4)	// Toggle floppy turbo
			{
                config.floppy.speed^=1;
				ConfigFloppy(config.floppy.drives,config.floppy.speed);
                menustate = MENU_MAIN1;
			}
            else if (menusub == 5)	// Go to harddrives page.
			{
                 t_hardfile[0] = config.hardfile[0];
                 t_hardfile[1] = config.hardfile[1];
                 menustate = MENU_SETTINGS_HARDFILE1;
				 menusub=0;
			}
            else if (menusub == 6)
                menustate = MENU_NONE1;
        }
        else if (c == KEY_BACK) // eject all floppies
        {
            for (i = 0; i <= drives; i++)
                df[i].status = 0;

            menustate = MENU_MAIN1;
        }
        else if (right)
        {
            menustate = MENU_MAIN2_1;
            menusub = 0;
        }
        break;

    case MENU_FILE_SELECTED : // file successfully selected

         InsertFloppy(&df[menusub]);
         menustate = MENU_MAIN1;
         menusub++;
         if (menusub > drives)
             menusub = 6;

         break;

        /******************************************************************/
        /* second part of the main menu                                   */
        /******************************************************************/
    case MENU_MAIN2_1 :
		helptext=helptexts[HELPTEXT_MAIN];
		menumask=0x3f;
 		OsdSetTitle("Settings",OSD_ARROW_LEFT|OSD_ARROW_RIGHT);
        OsdWrite(0, "    load configuration", menusub == 0,0);
        OsdWrite(1, "    save configuration", menusub == 1,0);
        OsdWrite(2, "", 0,0);
        OsdWrite(3, "    chipset settings \x16", menusub == 2,0);
        OsdWrite(4, "     memory settings \x16", menusub == 3,0);
        OsdWrite(5, "      video settings \x16", menusub == 4,0);
        OsdWrite(6, "", 0,0);
        OsdWrite(7, STD_EXIT, menusub == 5,0);

		parentstate = menustate;
        menustate = MENU_MAIN2_2;
        break;

    case MENU_MAIN2_2 :

        if (menu)
            menustate = MENU_NONE1;
        else if (select)
        {
            if (menusub == 0)
            {
                menusub = 0;
                menustate = MENU_LOADCONFIG_1;
            }
            else if (menusub == 1)
            {
                menusub = 0;
                menustate = MENU_SAVECONFIG_1;
            }
            else if (menusub == 2)
            {
                menustate = MENU_SETTINGS_CHIPSET1;
                menusub = 0;
            }
            else if (menusub == 3)
            {
                menustate = MENU_SETTINGS_MEMORY1;
                menusub = 0;
            }
            else if (menusub == 4)
            {
                menustate = MENU_SETTINGS_VIDEO1;
                menusub = 0;
            }
            else if (menusub == 5)
                menustate = MENU_NONE1;
        }
        else if (left)
        {
            menustate = MENU_MAIN1;
            menusub = 0;
        }
        else if (right)
        {
            menustate = MENU_MISC1;
            menusub = 0;
        }
        break;

    case MENU_MISC1 :
		helptext=helptexts[HELPTEXT_MAIN];
		menumask=0x0f;	// Reset, about and exit.
 		OsdSetTitle("Misc",OSD_ARROW_LEFT);
        OsdWrite(0, "    Reset", menusub == 0,0);
        OsdWrite(1, "", 0,0);
        OsdWrite(2, "    Return to Chameleon", menusub == 1,0);
//        OsdWrite(3, "    (Not yet implemented)", 0,1);
        OsdWrite(3, "", 0,0);
        OsdWrite(4, "    About", menusub == 2,0);
        OsdWrite(5, "", 0,0);
        OsdWrite(6, "", 0,0);
        OsdWrite(7, STD_EXIT, menusub == 3,0);

		parentstate = menustate;
        menustate = MENU_MISC2;
        break;

    case MENU_MISC2 :

        if (menu)
            menusub=0, menustate = MENU_NONE1;
		if (left)
			menusub=0, menustate = MENU_MAIN2_1;
        else if (select)
        {
            if (menusub == 0)	// Reset
            {
                menusub = 0;
				menustate=MENU_RESET1;
			}
            if (menusub == 1)	// Reconfig
            {
				menusub=0;
				menustate=MENU_RECONF1;
			}
            if (menusub == 2)	// About
            {
				menusub=0;
				menustate=MENU_ABOUT1;
			}
            if (menusub == 3)	// Exit
            {
				menustate=MENU_NONE1;
			}
		}
		break;

	case MENU_ABOUT1 :
		helptext=helptexts[HELPTEXT_NONE];
		menumask=0x01;	// Just Exit
 		OsdSetTitle("About",0);
		OsdDrawLogo(0,0,1);
		OsdDrawLogo(1,1,1);
		OsdDrawLogo(2,2,1);
		OsdDrawLogo(3,3,1);
		OsdDrawLogo(4,4,1);
		OsdDrawLogo(6,6,1);
//        OsdWrite(1, "", 0,0);
//        OsdWriteDoubleSize(2,"   Minimig",0);
//        OsdWriteDoubleSize(3,"   Minimig",1);
//        OsdWrite(4, "", 0,0);
        OsdWrite(5, "", 0,0);
        OsdWrite(6, "", 0,0);
        OsdWrite(7, STD_EXIT, menusub == 0,0);

		StarsInit();
		ScrollReset();

		parentstate = menustate;
        menustate = MENU_ABOUT2;
        break;

	case MENU_ABOUT2 :
		StarsUpdate();
		OsdDrawLogo(0,0,1);
		OsdDrawLogo(1,1,1);
		OsdDrawLogo(2,2,1);
		OsdDrawLogo(3,3,1);
		OsdDrawLogo(4,4,1);
		OsdDrawLogo(6,6,1);
		ScrollText(5,"                                 Minimig by Dennis van Weeren.  Chipset improvements by Jakub Bednarski and Sascha Boing.  TG68 softcore and Chameleon port by Tobias Gubener.  Menu / disk code by Dennis van Weeren, Jakub Bednarski and Alastair M. Robinson.  Build process, repository and tooling by Christian Vogelgsang.  Minimig logo based on a design by Loriano Pagni.  Minimig is distributed under the terms of the GNU General Public License version 3.",0,0,0);
        if (select || menu)
        {
			menusub = 2;
			menustate=MENU_MISC1;
		}
		break;

    case MENU_LOADCONFIG_1 :
		helptext=helptexts[HELPTEXT_NONE];
		if(parentstate!=menustate)	// First run?
		{
			menumask=0x20;
			SetConfigurationFilename(0); if(ConfigurationExists(0)) menumask|=0x01;
			SetConfigurationFilename(1); if(ConfigurationExists(0)) menumask|=0x02;
			SetConfigurationFilename(2); if(ConfigurationExists(0)) menumask|=0x04;
			SetConfigurationFilename(3); if(ConfigurationExists(0)) menumask|=0x08;
			SetConfigurationFilename(4); if(ConfigurationExists(0)) menumask|=0x10;
		}
		parentstate=menustate;
 		OsdSetTitle("Load",0);

        OsdWrite(0, "", 0,0);
        OsdWrite(1, "          Default", menusub == 0,(menumask & 1)==0);
        OsdWrite(2, "          1", menusub == 1,(menumask & 2)==0);
        OsdWrite(3, "          2", menusub == 2,(menumask & 4)==0);
        OsdWrite(4, "          3", menusub == 3,(menumask & 8)==0);
        OsdWrite(5, "          4", menusub == 4,(menumask & 0x10)==0);
        OsdWrite(6, "", 0,0);
        OsdWrite(7, STD_EXIT, menusub == 5,0);

        menustate = MENU_LOADCONFIG_2;
        break;

    case MENU_LOADCONFIG_2 :

        if (down)
        {
//            if (menusub < 3)
            if (menusub < 5)
                menusub++;
            menustate = MENU_LOADCONFIG_1;
        }
        else if (select)
        {
			if(menusub<5)
			{
				OsdDisable();
				SetConfigurationFilename(menusub);
				LoadConfiguration(NULL);
//				OsdReset(RESET_NORMAL);
	   	        menustate = MENU_NONE1;
			}
			else
			{
				menustate = MENU_MAIN2_1;
				menusub = 0;
			}
        }
        if (menu) // exit menu
        {
            menustate = MENU_MAIN2_1;
            menusub = 0;
        }
        break;

        /******************************************************************/
        /* file selection menu                                            */
        /******************************************************************/
    case MENU_FILE_SELECT1 :
		helptext=helptexts[HELPTEXT_NONE];
 		OsdSetTitle("Select",0);
        PrintDirectory();
        menustate = MENU_FILE_SELECT2;
        break;

    case MENU_FILE_SELECT2 :
		menumask=0;
 
        ScrollLongName(); // scrolls file name if longer than display line

        if (c == KEY_HOME)
        {
            ScanDirectory(SCAN_INIT, fs_pFileExt, fs_Options);
            menustate = MENU_FILE_SELECT1;
        }

        if (c == KEY_BACK)
        {
            if (iCurrentDirectory) // if not root directory
            {
                ScanDirectory(SCAN_INIT, fs_pFileExt, fs_Options);
                ChangeDirectory(DirEntry[sort_table[iSelectedEntry]].StartCluster + (fat32 ? (DirEntry[sort_table[iSelectedEntry]].HighCluster & 0x0FFF) << 16 : 0));
                if (ScanDirectory(SCAN_INIT_FIRST, fs_pFileExt, fs_Options))
                    ScanDirectory(SCAN_INIT_NEXT, fs_pFileExt, fs_Options);

                menustate = MENU_FILE_SELECT1;
            }
        }

        if (c == KEY_PGUP)
        {
            ScanDirectory(SCAN_PREV_PAGE, fs_pFileExt, fs_Options);
            menustate = MENU_FILE_SELECT1;        }

        if (c == KEY_PGDN)
        {
            ScanDirectory(SCAN_NEXT_PAGE, fs_pFileExt, fs_Options);
            menustate = MENU_FILE_SELECT1;
        }

        if (down) // scroll down one entry
        {
            ScanDirectory(SCAN_NEXT, fs_pFileExt, fs_Options);
            menustate = MENU_FILE_SELECT1;
        }

        if (up) // scroll up one entry
        {
            ScanDirectory(SCAN_PREV, fs_pFileExt, fs_Options);
            menustate = MENU_FILE_SELECT1;
        }

        if ((i = GetASCIIKey(c)))
        { // find an entry beginning with given character
            if (nDirEntries)
            {
                if (DirEntry[sort_table[iSelectedEntry]].Attributes & ATTR_DIRECTORY)
                { // it's a directory
                    if (i < DirEntry[sort_table[iSelectedEntry]].Name[0])
                    {
                        if (!ScanDirectory(i, fs_pFileExt, fs_Options | FIND_FILE))
                            ScanDirectory(i, fs_pFileExt, fs_Options | FIND_DIR);
                    }
                    else if (i > DirEntry[sort_table[iSelectedEntry]].Name[0])
                    {
                        if (!ScanDirectory(i, fs_pFileExt, fs_Options | FIND_DIR))
                            ScanDirectory(i, fs_pFileExt, fs_Options | FIND_FILE);
                    }
                    else
                    {
                        if (!ScanDirectory(i, fs_pFileExt, fs_Options)) // find nexr
                            if (!ScanDirectory(i, fs_pFileExt, fs_Options | FIND_FILE))
                                ScanDirectory(i, fs_pFileExt, fs_Options | FIND_DIR);
                    }
                }
                else
                { // it's a file
                    if (i < DirEntry[sort_table[iSelectedEntry]].Name[0])
                    {
                        if (!ScanDirectory(i, fs_pFileExt, fs_Options | FIND_DIR))
                            ScanDirectory(i, fs_pFileExt, fs_Options | FIND_FILE);
                    }
                    else if (i > DirEntry[sort_table[iSelectedEntry]].Name[0])
                    {
                        if (!ScanDirectory(i, fs_pFileExt, fs_Options | FIND_FILE))
                            ScanDirectory(i, fs_pFileExt, fs_Options | FIND_DIR);
                    }
                    else
                    {
                        if (!ScanDirectory(i, fs_pFileExt, fs_Options)) // find next
                            if (!ScanDirectory(i, fs_pFileExt, fs_Options | FIND_DIR))
                                ScanDirectory(i, fs_pFileExt, fs_Options | FIND_FILE);
                    }
                }
            }
            menustate = MENU_FILE_SELECT1;
        }

        if (select)
        {
            if (DirEntry[sort_table[iSelectedEntry]].Attributes & ATTR_DIRECTORY)
            {
                ChangeDirectory(DirEntry[sort_table[iSelectedEntry]].StartCluster + (fat32 ? (DirEntry[sort_table[iSelectedEntry]].HighCluster & 0x0FFF) << 16 : 0));
                {
                    if (strncmp((char*)DirEntry[sort_table[iSelectedEntry]].Name, "..", 2) == 0)
                    { // parent dir selected
                         if (ScanDirectory(SCAN_INIT_FIRST, fs_pFileExt, fs_Options))
                             ScanDirectory(SCAN_INIT_NEXT, fs_pFileExt, fs_Options);
                         else
                             ScanDirectory(SCAN_INIT, fs_pFileExt, fs_Options);
                    }
                    else
                        ScanDirectory(SCAN_INIT, fs_pFileExt, fs_Options);

                    menustate = MENU_FILE_SELECT1;
                }
            }
            else
            {
                if (nDirEntries)
                {
                    file.long_name[0] = 0;
                    len = strlen(DirEntryLFN[sort_table[iSelectedEntry]]);
                    if (len > 4)
                        if (DirEntryLFN[sort_table[iSelectedEntry]][len-4] == '.')
                            len -= 4; // remove extension

                    if (len > sizeof(file.long_name))
                        len = sizeof(file.long_name);

                    strncpy(file.name, (const char*)DirEntry[sort_table[iSelectedEntry]].Name, sizeof(file.name));
                    memset(file.long_name, 0, sizeof(file.long_name));
                    strncpy(file.long_name, DirEntryLFN[sort_table[iSelectedEntry]], len);
                    strncpy(DiskInfo, DirEntryInfo[iSelectedEntry], sizeof(DiskInfo));

                    file.size = DirEntry[sort_table[iSelectedEntry]].FileSize;
                    file.attributes = DirEntry[sort_table[iSelectedEntry]].Attributes;
                    file.start_cluster = DirEntry[sort_table[iSelectedEntry]].StartCluster + (fat32 ? (DirEntry[sort_table[iSelectedEntry]].HighCluster & 0x0FFF) << 16 : 0);
                    file.cluster = file.start_cluster;
                    file.sector = 0;

                    menustate = fs_MenuSelect;
                }
            }
        }

        if (menu)
        {
            menustate = fs_MenuCancel;
        }

        break;

        /******************************************************************/
        /* reset menu                                                     */
        /******************************************************************/
    case MENU_RESET1 :
		helptext=helptexts[HELPTEXT_NONE];
		OsdSetTitle("Reset",0);
		menumask=0x03;	// Yes / No
		parentstate=menustate;

        OsdWrite(0, "", 0,0);
        OsdWrite(1, "         Reset Minimig?", 0,0);
        OsdWrite(2, "", 0,0);
        OsdWrite(3, "               yes", menusub == 0,0);
        OsdWrite(4, "               no", menusub == 1,0);
        OsdWrite(5, "", 0,0);
        OsdWrite(6, "", 0,0);
        OsdWrite(7, "", 0,0);

        menustate = MENU_RESET2;
        break;

    case MENU_RESET2 :

        if (select && menusub == 0)
        {
            menustate = MENU_NONE1;
            OsdReset(RESET_NORMAL);
        }

        if (menu || (select && (menusub == 1))) // exit menu
        {
            menustate = MENU_MISC1;
            menusub = 0;
        }
        break;

        /******************************************************************/
        /* reconfigure confirmation                                       */
        /******************************************************************/
    case MENU_RECONF1 :
		helptext=helptexts[HELPTEXT_NONE];
		OsdSetTitle("Exit",0);
		menumask=0x03;	// Yes / No
		parentstate=menustate;

        OsdWrite(0, "", 0,0);
        OsdWrite(1, "     Return to Chameleon?", 0,0);
        OsdWrite(2, "", 0,0);
        OsdWrite(3, "               yes", menusub == 0,0);
        OsdWrite(4, "               no", menusub == 1,0);
        OsdWrite(5, "", 0,0);
        OsdWrite(6, "", 0,0);
        OsdWrite(7, "", 0,0);

        menustate = MENU_RECONF2;
        break;

    case MENU_RECONF2 :

        if (select && menusub == 0)
        {
            OsdReconfig();
        }

        if (menu || (select && (menusub == 1))) // exit menu
        {
            menustate = MENU_MISC1;
            menusub = 1;
        }
        break;

        /******************************************************************/
        /* settings menu                                                  */
        /******************************************************************/
/*
    case MENU_SETTINGS1 :
		menumask=0;
 		OsdSetTitle("Settings",0);

        OsdWrite(0, "", 0,0);
        OsdWrite(1, "             chipset", menusub == 0,0);
        OsdWrite(2, "             memory", menusub == 1,0);
        OsdWrite(3, "             drives", menusub == 2,0);
        OsdWrite(4, "             video", menusub == 3,0);
        OsdWrite(5, "", 0,0);
        OsdWrite(6, "", 0,0);

        if (menusub == 5)
            OsdWrite(7, "  \x12           save           \x12", 1,0);
        else if (menusub == 4)
            OsdWrite(7, "  \x13           exit           \x13", 1,0);
        else
            OsdWrite(7, STD_EXIT, 0,0);

        menustate = MENU_SETTINGS2;
        break;

    case MENU_SETTINGS2 :

        if (down && menusub < 5)
        {
            menusub++;
            menustate = MENU_SETTINGS1;
        }

        if (up && menusub > 0)
        {
            menusub--;
            menustate = MENU_SETTINGS1;
        }

        if (select)
        {
            if (menusub == 0)
            {
                menustate = MENU_SETTINGS_CHIPSET1;
                menusub = 0;
            }
            else if (menusub == 1)
            {
                menustate = MENU_SETTINGS_MEMORY1;
                menusub = 0;
            }
            else if (menusub == 2)
            {
                menustate = MENU_SETTINGS_DRIVES1;
                menusub = 0;
            }
            else if (menusub == 3)
            {
                menustate = MENU_SETTINGS_VIDEO1;
                menusub = 0;
            }
            else if (menusub == 4)
            {
                menustate = MENU_MAIN2_1;
                menusub = 1;
            }
            else if (menusub == 5)
            {
//                SaveConfiguration(0);	// Use slot-based config filename instead
										
                menustate = MENU_SAVECONFIG_1;
                menusub = 0;
            }
        }

        if (menu)
        {
            menustate = MENU_MAIN2_1;
            menusub = 1;
        }
        break;
*/

    case MENU_SAVECONFIG_1 :
		helptext=helptexts[HELPTEXT_NONE];
		menumask=0x3f;
		parentstate=menustate;
 		OsdSetTitle("Save",0);

        OsdWrite(0, "", 0, 0);
        OsdWrite(1, "        Default", menusub == 0,0);
        OsdWrite(2, "        1", menusub == 1,0);
        OsdWrite(3, "        2", menusub == 2,0);
        OsdWrite(4, "        3", menusub == 3,0);
        OsdWrite(5, "        4", menusub == 4,0);
        OsdWrite(6, "", 0,0);
//        OsdWrite(7, "              exit", menusub == 3);
        OsdWrite(7, STD_EXIT, menusub == 5,0);

        menustate = MENU_SAVECONFIG_2;
        break;

    case MENU_SAVECONFIG_2 :

        if (menu)
		{
            menustate = MENU_MAIN2_1;
            menusub = 5;
		}

        else if (up)
        {
            if (menusub > 0)
                menusub--;
            menustate = MENU_SAVECONFIG_1;
        }
        else if (down)
        {
//            if (menusub < 3)
            if (menusub < 5)
                menusub++;
            menustate = MENU_SAVECONFIG_1;
        }
        else if (select)
        {
			if(menusub<5)
			{
				SetConfigurationFilename(menusub);
				SaveConfiguration(NULL);
		        menustate = MENU_NONE1;
			}
			else
			{
				menustate = MENU_MAIN2_1;
				menusub = 1;
			}
        }
        if (menu) // exit menu
        {
            menustate = MENU_MAIN2_1;
            menusub = 1;
        }
        break;



        /******************************************************************/
        /* chipset settings menu                                          */
        /******************************************************************/
    case MENU_SETTINGS_CHIPSET1 :
		helptext=helptexts[HELPTEXT_CHIPSET];
		menumask=0;
 		OsdSetTitle("Chipset",OSD_ARROW_LEFT|OSD_ARROW_RIGHT);

        OsdWrite(0, "", 0,0);
        strcpy(s, "         CPU : ");
//        strcat(s, config.chipset & CONFIG_TURBO ? "turbo" : "normal");
        strcat(s, config_cpu_msg[config.cpu & 0x03]);
        OsdWrite(1, s, menusub == 0,0);
        strcpy(s, "       Video : ");
        strcat(s, config.chipset & CONFIG_NTSC ? "NTSC" : "PAL");
        OsdWrite(2, s, menusub == 1,0);
        strcpy(s, "     Chipset : ");
        strcat(s, config_chipset_msg[config.chipset >> 2 & 3]);
        OsdWrite(3, s, menusub == 2,0);
        OsdWrite(4, "", 0,0);
        OsdWrite(5, "", 0,0);
        OsdWrite(6, "", 0,0);
        OsdWrite(7, STD_EXIT, menusub == 3,0);

        menustate = MENU_SETTINGS_CHIPSET2;
        break;

    case MENU_SETTINGS_CHIPSET2 :

        if (down && menusub < 3)
        {
            menusub++;
            menustate = MENU_SETTINGS_CHIPSET1;
        }

        if (up && menusub > 0)
        {
            menusub--;
            menustate = MENU_SETTINGS_CHIPSET1;
        }

        if (select)
        {
            if (menusub == 0)
            {
//                config.chipset ^= CONFIG_TURBO;
                menustate = MENU_SETTINGS_CHIPSET1;
                config.cpu += 1; 
                if ((config.cpu & 0x03)==0x02)
					config.cpu += 1; 
//                ConfigChipset(config.chipset);
                ConfigCPU(config.cpu);

            }
            else if (menusub == 1)
            {
                config.chipset ^= CONFIG_NTSC;
                menustate = MENU_SETTINGS_CHIPSET1;
                ConfigChipset(config.chipset);
            }
            else if (menusub == 2)
            {
                if (config.chipset & CONFIG_ECS)
                   config.chipset &= ~(CONFIG_ECS|CONFIG_A1000);
                else
                    config.chipset += CONFIG_A1000;

                menustate = MENU_SETTINGS_CHIPSET1;
                ConfigChipset(config.chipset);
            }
            else if (menusub == 3)
            {
                menustate = MENU_MAIN2_1;
                menusub = 2;
            }
        }

        if (menu)
        {
            menustate = MENU_MAIN2_1;
            menusub = 2;
        }
        else if (right)
        {
            menustate = MENU_SETTINGS_MEMORY1;
            menusub = 0;
        }
        else if (left)
        {
            menustate = MENU_SETTINGS_VIDEO1;
            menusub = 0;
        }
        break;

        /******************************************************************/
        /* memory settings menu                                           */
        /******************************************************************/
    case MENU_SETTINGS_MEMORY1 :
		helptext=helptexts[HELPTEXT_MEMORY];
		menumask=0x3f;
		parentstate=menustate;

 		OsdSetTitle("Memory",OSD_ARROW_LEFT|OSD_ARROW_RIGHT);

        OsdWrite(0, "", 0,0);
        strcpy(s, "      CHIP : ");
        strcat(s, config_memory_chip_msg[config.memory & 0x03]);
        OsdWrite(1, s, menusub == 0,0);
        strcpy(s, "      SLOW : ");
        strcat(s, config_memory_slow_msg[config.memory >> 2 & 0x03]);
        OsdWrite(2, s, menusub == 1,0);
        strcpy(s, "      FAST : ");
        strcat(s, config_memory_fast_msg[config.memory >> 4 & 0x03]);
        OsdWrite(3, s, menusub == 2,0);

        OsdWrite(4, "", 0,0);

        strcpy(s, "      ROM  : ");
        if (config.kickstart.long_name[0])
            strncat(s, config.kickstart.long_name, sizeof(config.kickstart.long_name));
        else
            strncat(s, config.kickstart.name, sizeof(config.kickstart.name));
        OsdWrite(5, s, menusub == 3,0);

#ifdef ACTIONREPLAY_BROKEN
        OsdWrite(0, "", 0,0);
		menumask&=0xef;	// Remove bit 4
#else
        strcpy(s, "      AR3  : ");
        strcat(s, config.disable_ar3 ? "disabled" : "enabled ");
        OsdWrite(6, s, menusub == 4,config.memory&0x20);	// Grey out AR3 if more than 2MB fast memory
#endif

        OsdWrite(7, STD_EXIT, menusub == 5,0);

        menustate = MENU_SETTINGS_MEMORY2;
        break;

    case MENU_SETTINGS_MEMORY2 :
        if (select)
        {
            if (menusub == 0)
            {
                config.memory = ((config.memory + 1) & 0x03) | (config.memory & ~0x03);
                menustate = MENU_SETTINGS_MEMORY1;
                ConfigMemory(config.memory);
            }
            else if (menusub == 1)
            {
                config.memory = ((config.memory + 4) & 0x0C) | (config.memory & ~0x0C);
                menustate = MENU_SETTINGS_MEMORY1;
                ConfigMemory(config.memory);
            }
            else if (menusub == 2)
            {
                config.memory = ((config.memory + 0x10) & 0x30) | (config.memory & ~0x30);
                if ((config.memory & 0x30) == 0x30)
					config.memory -= 0x30;
//				if (!(config.disable_ar3 & 0x01)&&(config.memory & 0x20))
//                    config.memory &= ~0x30;
                menustate = MENU_SETTINGS_MEMORY1;
                ConfigMemory(config.memory);
            }
            else if (menusub == 3)
            {
                SelectFile("ROM", SCAN_LFN, MENU_ROMFILE_SELECTED, MENU_SETTINGS_MEMORY1);
            }
            else if (menusub == 4)
            {
		    if (!(config.disable_ar3 & 0x01)||(config.memory & 0x20))
                    config.disable_ar3 |= 0x01;
		    else
                    config.disable_ar3 &= 0xFE;
                menustate = MENU_SETTINGS_MEMORY1;
            }
            else if (menusub == 5)
            {
                menustate = MENU_MAIN2_1;
                menusub = 3;
            }
        }

        if (menu)
        {
            menustate = MENU_MAIN2_1;
            menusub = 3;
        }
        else if (right)
        {
            menustate = MENU_SETTINGS_VIDEO1;
            menusub = 0;
        }
        else if (left)
        {
            menustate = MENU_SETTINGS_CHIPSET1;
            menusub = 0;
        }
        break;

        /******************************************************************/
        /* drive settings menu                                            */
        /******************************************************************/
/*
    case MENU_SETTINGS_DRIVES1 :
		menumask=0;
 
		OsdSetTitle("Drives",OSD_ARROW_LEFT|OSD_ARROW_RIGHT);

        OsdWrite(0, "", 0,0);
        sprintf(s, "        drives : %d", config.floppy.drives + 1,0);
        OsdWrite(1, s, menusub == 0,0);
        strcpy(s, "         speed : ");
        strcat(s, config.floppy.speed ? "fast " : "normal");
        OsdWrite(2, s, menusub == 1,0);
        OsdWrite(3, "", 0,0);
        strcpy(s, "      A600 IDE : ");
        strcat(s, config.enable_ide ? "on " : "off");
        OsdWrite(4, s, menusub == 2,0);
        sprintf(s, "     hardfiles : %d", (config.hardfile[0].present & config.hardfile[0].enabled) + (config.hardfile[1].present & config.hardfile[1].enabled));
        OsdWrite(5,s, menusub == 3,0);
        OsdWrite(6, "", 0,0);
        OsdWrite(7, STD_EXIT, menusub == 4,0);

        menustate = MENU_SETTINGS_DRIVES2;
        break;

    case MENU_SETTINGS_DRIVES2 :

        if (down && menusub < 4)
        {
            menusub++;
            menustate = MENU_SETTINGS_DRIVES1;
        }

        if (up && menusub > 0)
        {
            menusub--;
            menustate = MENU_SETTINGS_DRIVES1;
        }

        if (select)
        {
            if (menusub == 0)
            {
                config.floppy.drives++;
                config.floppy.drives &= 0x03;
                menustate = MENU_SETTINGS_DRIVES1;
                ConfigFloppy(config.floppy.drives, config.floppy.speed);
            }
            else if (menusub == 1)
            {
                config.floppy.speed++;
                config.floppy.speed &= 0x01;
                menustate = MENU_SETTINGS_DRIVES1;
                ConfigFloppy(config.floppy.drives, config.floppy.speed);
            }
            else if (menusub == 2)
            {
                config.enable_ide ^= 0x01;
                menustate = MENU_SETTINGS_DRIVES1;
                ConfigIDE(config.enable_ide, config.hardfile[0].present && config.hardfile[0].enabled, config.hardfile[1].present && config.hardfile[1].enabled);
            }
            else if (menusub == 3)
            {
                t_hardfile[0] = config.hardfile[0];
                t_hardfile[1] = config.hardfile[1];
                menustate = MENU_SETTINGS_HARDFILE1;
                menusub = 4;
            }
            else if (menusub == 4)
            {
                menustate = MENU_SETTINGS1;
                menusub = 2;
            }
        }

        if (menu)
        {
            menustate = MENU_SETTINGS1;
            menusub = 2;
        }
        else if (right)
        {
            menustate = MENU_SETTINGS_VIDEO1;
            menusub = 0;
        }
        else if (left)
        {
            menustate = MENU_SETTINGS_MEMORY1;
            menusub = 0;
        }
        break;

*/

        /******************************************************************/
        /* hardfile settings menu                                         */
        /******************************************************************/

		// FIXME!  Nasty race condition here.  Changing HDF type has immediate effect
		// which could be disastrous if the user's writing to the drive at the time!
		// Make the menu work on the copy, not the original, and copy on acceptance,
		// not on rejection.
    case MENU_SETTINGS_HARDFILE1 :
		helptext=helptexts[HELPTEXT_HARDFILE];
		OsdSetTitle("Harddisks",0);

		parentstate = menustate;
		menumask=0x21;	// b00100001 - On/off & exit enabled by default...
		if(config.enable_ide)
			menumask|=0x0a;  // b00001010 - HD0 and HD1 type
        strcpy(s, "   A600 IDE : ");
        strcat(s, config.enable_ide ? "on " : "off");
        OsdWrite(0, s, menusub == 0,0);
        OsdWrite(1, "", 0,0);

        strcpy(s, " Master : ");
		if(config.hardfile[0].enabled==(HDF_FILE|HDF_SYNTHRDB))
			strcat(s,"Hardfile (filesys)");
		else
	        strcat(s, config_hdf_msg[config.hardfile[0].enabled & HDF_TYPEMASK]);
        OsdWrite(2, s, config.enable_ide ? (menusub == 1) : 0 ,config.enable_ide==0);

        if (config.hardfile[0].present)
        {
            strcpy(s, "                                ");
            if (config.hardfile[0].long_name[0])
                strncpy(&s[14], config.hardfile[0].long_name, sizeof(config.hardfile[0].long_name));
            else
                strncpy(&s[14], config.hardfile[0].name, sizeof(config.hardfile[0].name));
        }
        else
            strcpy(s, "       ** file not found **");

		enable=config.enable_ide && ((config.hardfile[0].enabled&HDF_TYPEMASK)==HDF_FILE);
		if(enable)
			menumask|=0x04;	// Make hardfile selectable
	    OsdWrite(3, s, enable ? (menusub == 2) : 0 , enable==0);

        strcpy(s, "  Slave : ");
		if(config.hardfile[1].enabled==(HDF_FILE|HDF_SYNTHRDB))
			strcat(s,"Hardfile (filesys)");
		else
	        strcat(s, config_hdf_msg[config.hardfile[1].enabled & HDF_TYPEMASK]);
        OsdWrite(4, s, config.enable_ide ? (menusub == 3) : 0 ,config.enable_ide==0);
        if (config.hardfile[1].present)
        {
            strcpy(s, "                                ");
            if (config.hardfile[1].long_name[0])
                strncpy(&s[14], config.hardfile[1].long_name, sizeof(config.hardfile[0].long_name));
            else
                strncpy(&s[14], config.hardfile[1].name, sizeof(config.hardfile[0].name));
        }
        else
            strcpy(s, "       ** file not found **");

		enable=config.enable_ide && ((config.hardfile[1].enabled&HDF_TYPEMASK)==HDF_FILE);
		if(enable)
			menumask|=0x10;	// Make hardfile selectable
        OsdWrite(5, s, enable ? (menusub == 4) : 0 ,enable==0);

        OsdWrite(6, "", 0,0);
        OsdWrite(7, STD_EXIT, menusub == 5,0);

        menustate = MENU_SETTINGS_HARDFILE2;

        break;

    case MENU_SETTINGS_HARDFILE2 :
        if (select)
        {
            if (menusub == 0)
            {
				config.enable_ide=(config.enable_ide==0);
				menustate = MENU_SETTINGS_HARDFILE1;
            }
            if (menusub == 1)
            {
				if(config.hardfile[0].enabled==HDF_FILE)
				{
					config.hardfile[0].enabled|=HDF_SYNTHRDB;
				}
				else if(config.hardfile[0].enabled==(HDF_FILE|HDF_SYNTHRDB))
				{
					config.hardfile[0].enabled&=~HDF_SYNTHRDB;
					config.hardfile[0].enabled +=1;
				}
				else
				{
					config.hardfile[0].enabled +=1;
					config.hardfile[0].enabled %=HDF_CARDPART0+partitioncount;
				}
                menustate = MENU_SETTINGS_HARDFILE1;
            }
            else if (menusub == 2)
            {
                SelectFile("HDF", SCAN_LFN, MENU_HARDFILE_SELECTED, MENU_SETTINGS_HARDFILE1);
            }
            else if (menusub == 3)
            {
				if(config.hardfile[1].enabled==HDF_FILE)
				{
					config.hardfile[1].enabled|=HDF_SYNTHRDB;
				}
				else if(config.hardfile[1].enabled==(HDF_FILE|HDF_SYNTHRDB))
				{
					config.hardfile[1].enabled&=~HDF_SYNTHRDB;
					config.hardfile[1].enabled +=1;
				}
				else
				{
					config.hardfile[1].enabled +=1;
					config.hardfile[1].enabled %=HDF_CARDPART0+partitioncount;
				}
				menustate = MENU_SETTINGS_HARDFILE1;
            }
            else if (menusub == 4)
            {
                SelectFile("HDF", SCAN_LFN, MENU_HARDFILE_SELECTED, MENU_SETTINGS_HARDFILE1);
            }
            else if (menusub == 5) // return to previous menu
            {
                menustate = MENU_HARDFILE_EXIT;
            }
        }

        if (menu) // return to previous menu
        {
            menustate = MENU_HARDFILE_EXIT;
        }
        break;

        /******************************************************************/
        /* hardfile selected menu                                         */
        /******************************************************************/
    case MENU_HARDFILE_SELECTED :
        if (menusub == 2) // master drive selected
        {
			// Read RDB from selected drive and determine type...
            memcpy((void*)config.hardfile[0].name, (void*)file.name, sizeof(config.hardfile[0].name));
            memcpy((void*)config.hardfile[0].long_name, (void*)file.long_name, sizeof(config.hardfile[0].long_name));
			switch(GetHDFFileType(file.name))
			{
				case HDF_FILETYPE_RDB:
					config.hardfile[0].enabled=HDF_FILE;
		            config.hardfile[0].present = 1;
			        menustate = MENU_SETTINGS_HARDFILE1;
					break;
				case HDF_FILETYPE_DOS:
					config.hardfile[0].enabled=HDF_FILE|HDF_SYNTHRDB;
		            config.hardfile[0].present = 1;
			        menustate = MENU_SETTINGS_HARDFILE1;
					break;
				case HDF_FILETYPE_UNKNOWN:
		            config.hardfile[0].present = 1;
					if(config.hardfile[0].enabled==HDF_FILE)	// Warn if we can't detect the type
						menustate=MENU_SYNTHRDB1;
					else
						menustate=MENU_SYNTHRDB2_1;
					menusub=0;
					break;
				case HDF_FILETYPE_NOTFOUND:
				default:
		            config.hardfile[0].present = 0;
			        menustate = MENU_SETTINGS_HARDFILE1;
					break;
			}
			
        }

        if (menusub == 4) // slave drive selected
        {
            memcpy((void*)config.hardfile[1].name, (void*)file.name, sizeof(config.hardfile[1].name));
            memcpy((void*)config.hardfile[1].long_name, (void*)file.long_name, sizeof(config.hardfile[1].long_name));
			switch(GetHDFFileType(file.name))
			{
				case HDF_FILETYPE_RDB:
					config.hardfile[1].enabled=HDF_FILE;
		            config.hardfile[1].present = 1;
			        menustate = MENU_SETTINGS_HARDFILE1;
					break;
				case HDF_FILETYPE_DOS:
					config.hardfile[1].enabled=HDF_FILE|HDF_SYNTHRDB;
		            config.hardfile[1].present = 1;
			        menustate = MENU_SETTINGS_HARDFILE1;
					break;
				case HDF_FILETYPE_UNKNOWN:
		            config.hardfile[1].present = 1;
					if(config.hardfile[1].enabled==HDF_FILE)	// Warn if we can't detect the type...
						menustate=MENU_SYNTHRDB1;
					else
						menustate=MENU_SYNTHRDB2_1;
					menusub=0;
					break;
				case HDF_FILETYPE_NOTFOUND:
				default:
		            config.hardfile[1].present = 0;
			        menustate = MENU_SETTINGS_HARDFILE1;
					break;
			}
        }
        break;

     // check if hardfile configuration has changed
    case MENU_HARDFILE_EXIT :

         if (memcmp(config.hardfile, t_hardfile, sizeof(t_hardfile)) != 0)
         {
             menustate = MENU_HARDFILE_CHANGED1;
             menusub = 1;
         }
         else
         {
             menustate = MENU_MAIN1;
             menusub = 5;
         }

         break;

    // hardfile configuration has changed, ask user if he wants to use the new settings
    case MENU_HARDFILE_CHANGED1 :
		menumask=0x03;
		parentstate=menustate;
 		OsdSetTitle("Confirm",0);

        OsdWrite(0, "", 0,0);
        OsdWrite(1, "    Changing configuration", 0,0);
        OsdWrite(2, "      requires reset.", 0,0);
        OsdWrite(3, "", 0,0);
        OsdWrite(4, "       Reset Minimig?", 0,0);
        OsdWrite(5, "", 0,0);
        OsdWrite(6, "             yes", menusub == 0,0);
        OsdWrite(7, "             no", menusub == 1,0);

        menustate = MENU_HARDFILE_CHANGED2;
        break;

    case MENU_HARDFILE_CHANGED2 :
        if (select)
        {
            if (menusub == 0) // yes
            {
				// FIXME - waiting for user-confirmation increases the window of opportunity for file corruption!

                if ((config.hardfile[0].enabled != t_hardfile[0].enabled)
					|| (strncmp(config.hardfile[0].name, t_hardfile[0].name, sizeof(t_hardfile[0].name)) != 0))
				{
                    OpenHardfile(0);
//					if((config.hardfile[0].enabled == HDF_FILE) && !FindRDB(0))
//						menustate = MENU_SYNTHRDB1;
				}

                if (config.hardfile[1].enabled != t_hardfile[1].enabled
					|| (strncmp(config.hardfile[1].name, t_hardfile[1].name, sizeof(t_hardfile[1].name)) != 0))
				{
                    OpenHardfile(1);
//					if((config.hardfile[1].enabled == HDF_FILE) && !FindRDB(1))
//						menustate = MENU_SYNTHRDB2_1;
				}

				if(menustate==MENU_HARDFILE_CHANGED2)
				{
	                ConfigIDE(config.enable_ide, config.hardfile[0].present && config.hardfile[0].enabled, config.hardfile[1].present && config.hardfile[1].enabled);
    	            OsdReset(RESET_NORMAL);
				
	                menustate = MENU_NONE1;
				}
            }
            else if (menusub == 1) // no
            {
                memcpy(config.hardfile, t_hardfile, sizeof(t_hardfile)); // restore configuration
                menustate = MENU_MAIN1;
                menusub = 3;
            }
        }

        if (menu)
        {
            memcpy(config.hardfile, t_hardfile, sizeof(t_hardfile)); // restore configuration
            menustate = MENU_MAIN1;
            menusub = 3;
        }
        break;

    case MENU_SYNTHRDB1 :
		menumask=0x01;
		parentstate=menustate;
 		OsdSetTitle("Warning",0);
        OsdWrite(0, "", 0,0);
        OsdWrite(1, " No partition table found -", 0,0);
        OsdWrite(2, " Hardfile image may need", 0,0);
        OsdWrite(3, " to be prepped with HDToolbox,", 0,0);
        OsdWrite(4, " then formatted.", 0,0);
        OsdWrite(5, "", 0,0);
        OsdWrite(6, "", 0,0);
        OsdWrite(7, "             OK", menusub == 0,0);

        menustate = MENU_SYNTHRDB2;
        break;


    case MENU_SYNTHRDB2_1 :

		menumask=0x01;
		parentstate=menustate;
 		OsdSetTitle("Warning",0);
        OsdWrite(0, "", 0,0);
        OsdWrite(1, " No filesystem recognised.", 0,0);
        OsdWrite(2, " Hardfile may need formatting", 0,0);
        OsdWrite(3, " (or may simply be an", 0,0);
        OsdWrite(4, " unrecognised filesystem)", 0,0);
        OsdWrite(5, "", 0,0);
        OsdWrite(6, "", 0,0);
        OsdWrite(7, "             OK", menusub == 0,0);

        menustate = MENU_SYNTHRDB2;
        break;


    case MENU_SYNTHRDB2 :
        if (select || menu)
        {
            if (menusub == 0) // OK
		        menustate = MENU_SETTINGS_HARDFILE1;
        }
        break;


        /******************************************************************/
        /* video settings menu                                            */
        /******************************************************************/
    case MENU_SETTINGS_VIDEO1 :
		menumask=0x0f;
		parentstate=menustate;
		helptext=helptexts[HELPTEXT_VIDEO];
 
		OsdSetTitle("Video",OSD_ARROW_LEFT|OSD_ARROW_RIGHT);
        OsdWrite(0, "", 0,0);
        strcpy(s, "   Lores Filter : ");
        strcat(s, config_filter_msg[config.filter.lores & 0x03]);
        OsdWrite(1, s, menusub == 0,0);
        strcpy(s, "   Hires Filter : ");
        strcat(s, config_filter_msg[config.filter.hires & 0x03]);
        OsdWrite(2, s, menusub == 1,0);
        strcpy(s, "   Scanlines    : ");
        strcat(s, config_scanlines_msg[config.scanlines % 3]);
        OsdWrite(3, s, menusub == 2,0);
        OsdWrite(4, "", 0,0);
        OsdWrite(5, "", 0,0);
        OsdWrite(6, "", 0,0);
        OsdWrite(7, STD_EXIT, menusub == 3,0);

        menustate = MENU_SETTINGS_VIDEO2;
        break;

    case MENU_SETTINGS_VIDEO2 :
        if (select)
        {
            if (menusub == 0)
            {
                config.filter.lores++;
                config.filter.lores &= 0x03;
                menustate = MENU_SETTINGS_VIDEO1;
                //ConfigFilter(config.filter.lores, config.filter.hires);
                ConfigVideo(config.filter.hires, config.filter.lores, config.scanlines);
            }
            else if (menusub == 1)
            {
                config.filter.hires++;
                config.filter.hires &= 0x03;
                menustate = MENU_SETTINGS_VIDEO1;
                //ConfigFilter(config.filter.lores, config.filter.hires);
                ConfigVideo(config.filter.hires, config.filter.lores, config.scanlines);
            }
            else if (menusub == 2)
            {
                config.scanlines++;
                if (config.scanlines > 2)
                    config.scanlines = 0;
                menustate = MENU_SETTINGS_VIDEO1;
                //ConfigScanlines(config.scanlines);
                ConfigVideo(config.filter.hires, config.filter.lores, config.scanlines);
            }

            else if (menusub == 3)
            {
                menustate = MENU_MAIN2_1;
                menusub = 4;
            }
        }

        if (menu)
        {
            menustate = MENU_MAIN2_1;
            menusub = 4;
        }
        else if (right)
        {
            menustate = MENU_SETTINGS_CHIPSET1;
            menusub = 0;
        }
        else if (left)
        {
            menustate = MENU_SETTINGS_MEMORY1;
            menusub = 0;
        }
        break;

        /******************************************************************/
        /* rom file selected menu                                         */
        /******************************************************************/
    case MENU_ROMFILE_SELECTED :

         menusub = 1;
		 menustate=MENU_ROMFILE_SELECTED1;
         // no break intended

    case MENU_ROMFILE_SELECTED1 :
		menumask=0x03;
		parentstate=menustate;
 		OsdSetTitle("Confirm",0);
        OsdWrite(0, "", 0,0);
        OsdWrite(1, "       Reload Kickstart?", 0,0);
        OsdWrite(2, "", 0,0);
        OsdWrite(3, "              yes", menusub == 0,0);
        OsdWrite(4, "              no", menusub == 1,0);
        OsdWrite(5, "", 0,0);
        OsdWrite(6, "", 0,0);
        OsdWrite(7, "", 0,0);

        menustate = MENU_ROMFILE_SELECTED2;
        break;

    case MENU_ROMFILE_SELECTED2 :

        if (select)
        {
            if (menusub == 0)
            {
                memcpy((void*)config.kickstart.name, (void*)file.name, sizeof(config.kickstart.name));
                memcpy((void*)config.kickstart.long_name, (void*)file.long_name, sizeof(config.kickstart.long_name));

                OsdDisable();
                //OsdReset(RESET_BOOTLOADER);
                //ConfigChipset(config.chipset | CONFIG_TURBO);
                //ConfigFloppy(config.floppy.drives, CONFIG_FLOPPY2X);
                EnableOsd();
                SPI(OSD_CMD_RST);
                rstval = (SPI_RST_CPU | SPI_CPU_HLT);
                SPI(rstval);
                DisableOsd();
                SPIN(); SPIN(); SPIN(); SPIN();
                UploadKickstart(config.kickstart.name);
                EnableOsd();
                SPI(OSD_CMD_RST);
                rstval = (SPI_RST_USR | SPI_RST_CPU);
                SPI(rstval);
                DisableOsd();
                SPIN(); SPIN(); SPIN(); SPIN();
                EnableOsd();
                SPI(OSD_CMD_RST);
                rstval = 0;
                SPI(rstval);
                DisableOsd();
                SPIN(); SPIN(); SPIN(); SPIN();
                //ConfigChipset(config.chipset); // restore CPU speed mode
                //ConfigFloppy(config.floppy.drives, config.floppy.speed); // restore floppy speed mode

                menustate = MENU_NONE1;
            }
            else if (menusub == 1)
            {
                menustate = MENU_SETTINGS_MEMORY1;
                menusub = 2;
            }
        }

        if (menu)
        {
            menustate = MENU_SETTINGS_MEMORY1;
            menusub = 2;
        }
        break;

//        /******************************************************************/
//        /* firmware menu */
//        /******************************************************************/
//    case MENU_FIRMWARE1 :
//
//        OsdWrite(0, "        *** Firmware ***", 0);
//        OsdWrite(1, "", 0);
//        sprintf(s, "     ARM s/w ver. %s", version + 5);
//        OsdWrite(2, s, 0);
//        OsdWrite(3, "", 0);
//        OsdWrite(4, "             update", menusub == 0);
//        OsdWrite(5, "             options", menusub == 1);
//        OsdWrite(6, "", 0);
//        OsdWrite(7, "              exit", menusub == 2);
//
//        menustate = MENU_FIRMWARE2;
//        break;
//
//    case MENU_FIRMWARE2 :
//
//        if (menu)
//        {
//            menusub = 2;
//            menustate = MENU_MAIN2_1;
//        }
//        else if (up)
//        {
//            if (menusub > 0)
//                menusub--;
//            menustate = MENU_FIRMWARE1;
//        }
//        else if (down)
//        {
//            if (menusub < 2)
//                menusub++;
//            menustate = MENU_FIRMWARE1;
//        }
//        else if (select)
//        {
//            if (menusub == 0)
//            {
////                if (CheckFirmware(&file, "FIRMWAREUPG"))
////                    menustate = MENU_FIRMWARE_UPDATE1;
////                else
//                    menustate = MENU_FIRMWARE_UPDATE_ERROR1;
//                menusub = 1;
//                OsdClear();
//            }
//            else if (menusub == 1)
//            {
//                menustate = MENU_FIRMWARE_OPTIONS1;
//                menusub = 1;
//                OsdClear();
//            }
//            else if (menusub == 2)
//            {
//                menustate = MENU_MAIN2_1;
//                menusub = 2;
//            }
//        }
//        break;
//
//        /******************************************************************/
//        /* firmware update message menu */
//        /******************************************************************/
//    case MENU_FIRMWARE_UPDATE1 :
//
//        OsdWrite(2, "          Are you sure?", 0);
//
//        OsdWrite(6, "               yes", menusub == 0);
//        OsdWrite(7, "               no", menusub == 1);
//
//        menustate = MENU_FIRMWARE_UPDATE2;

//        break;
//
//    case MENU_FIRMWARE_UPDATE2 :
//
//        if (down && menusub < 1)
//        {
//            menusub++;
//            menustate = MENU_FIRMWARE_UPDATE1;
//        }
//
//        if (up && menusub > 0)
//        {
//            menusub--;
//            menustate = MENU_FIRMWARE_UPDATE1;
//        }
//
//        if (select)
//        {
//            if (menusub == 0)
//            {
//                menustate = MENU_FIRMWARE_UPDATING1;
//                menusub = 0;
//                OsdClear();
//            }
//            else if (menusub == 1)
//            {
//                menustate = MENU_FIRMWARE1;
//                menusub = 2;
//            }
//        }
//        break;
//
//        /******************************************************************/
//        /* firmware update in progress message menu*/
//        /******************************************************************/
//    case MENU_FIRMWARE_UPDATING1 :
//
//        OsdWrite(1, "        Updating firmware", 0);
//        OsdWrite(3, "           Please wait", 0);
//        menustate = MENU_FIRMWARE_UPDATING2;
//        break;
//
//    case MENU_FIRMWARE_UPDATING2 :
//
////        WriteFirmware(&file);
//        Error = ERROR_UPDATE_FAILED;
//        menustate = MENU_FIRMWARE_UPDATE_ERROR1;
//        menusub = 0;
//        OsdClear();
//        break;
//
//        /******************************************************************/
//        /* firmware update error message menu*/
//        /******************************************************************/
//    case MENU_FIRMWARE_UPDATE_ERROR1 :
//
//        switch (Error)
//        {
//        case ERROR_FILE_NOT_FOUND :
//            OsdWrite(1, "          Update file", 0);
//            OsdWrite(2, "           not found!", 0);
//            break;
//        case ERROR_INVALID_DATA :
//            OsdWrite(1, "            Invalid ", 0);
//            OsdWrite(2, "          update file!", 0);
//            break;
//        case ERROR_UPDATE_FAILED :
//            OsdWrite(2, "         Update failed!", 0);
//            break;
//        }
//        OsdWrite(7, "               OK", 1);
//        menustate = MENU_FIRMWARE_UPDATE_ERROR2;
//        break;
//
//    case MENU_FIRMWARE_UPDATE_ERROR2 :
//
//        if (select)
//        {
//            menustate = MENU_FIRMWARE1;
//            menusub = 2;
//        }
//        break;
//
//        /******************************************************************/
//        /* firmware options menu */
//        /******************************************************************/
//    case MENU_FIRMWARE_OPTIONS1 :
//
//        OsdWrite(0, "          ** Options **", 0);
//
////        if (GetSPIMode() == SPIMODE_FAST)
////            OsdWrite(2, "        Fast SPI enabled", menusub == 0);
////        else
//            OsdWrite(2, "        Enable Fast SPI ", menusub == 0);
//
//        OsdWrite(7, "              exit", menusub == 1);
//
//        menustate = MENU_FIRMWARE_OPTIONS2;
//        break;
//
//    case MENU_FIRMWARE_OPTIONS2 :
//
//        if (c == KEY_F8)
//        {
//            if (DEBUG)
//            {
//                DEBUG = 0;
//                printf("DEBUG OFF\r");
//            }
//            else
//            {
//                DEBUG = 1;
//                printf("DEBUG ON\r");
//            }
//        }
//        else if (menu)
//        {
//            menusub = 1;
//            menustate = MENU_FIRMWARE1;
//        }
//        else if (up)
//        {
////            if (menusub > 0  && GetSPIMode() != SPIMODE_FAST)
//                menusub--;
//
//            menustate = MENU_FIRMWARE_OPTIONS1;
//        }
//        else if (down)
//        {
//            if (menusub < 1)
//                menusub++;
//            menustate = MENU_FIRMWARE_OPTIONS1;
//        }
//        else if (select)
//        {
//            if (menusub == 0)
//            {
//                menusub = 1;
//                menustate = MENU_FIRMWARE_OPTIONS_ENABLE1;
//                OsdClear();
//            }
//            else if (menusub == 1)
//            {
//                menusub = 1;
//                menustate = MENU_FIRMWARE1;
//            }
//        }
//        break;
//
//        /******************************************************************/
//        /* SPI high speed mode enable message menu*/
//        /******************************************************************/
//    case MENU_FIRMWARE_OPTIONS_ENABLE1 :
//
//        OsdWrite(0, "    Enabling fast SPI without", 0);
//        OsdWrite(1, "      hardware modification", 0);
//        OsdWrite(2, "          will be fatal!", 0);
//        OsdWrite(4, "             Enable?", 0);
//        OsdWrite(6, "               yes", menusub == 0);
//        OsdWrite(7, "               no", menusub == 1);
//
//        menustate = MENU_FIRMWARE_OPTIONS_ENABLE2;
//        break;
//
//    case MENU_FIRMWARE_OPTIONS_ENABLE2 :
//
//        if (down && menusub < 1)
//        {
//            menusub++;
//            menustate = MENU_FIRMWARE_OPTIONS_ENABLE1;
//        }
//
//        if (up && menusub > 0)
//        {
//            menusub--;
//            menustate = MENU_FIRMWARE_OPTIONS_ENABLE1;
//        }
//
//        if (select)
//        {
//            if (menusub == 0)
//            {
////                SetSPIMode(SPIMODE_FAST);
//                menustate = MENU_FIRMWARE_OPTIONS_ENABLED1;
//                menusub = 0;
//                OsdClear();
//            }
//            else if (menusub == 1)
//            {
//                menustate = MENU_FIRMWARE_OPTIONS1;
//                menusub = 0;
//                OsdClear();
//            }
//        }
//        break;
//
//        /******************************************************************/
//        /* SPI high speed mode enabled message menu*/
//        /******************************************************************/
//    case MENU_FIRMWARE_OPTIONS_ENABLED1 :
//
//        OsdWrite(1, "    Fast SPI mode will be", 0);
//        OsdWrite(2, "    activated after restart.", 0);
//        OsdWrite(3, "    Hold MENU button while", 0);
//        OsdWrite(4, "    powering-on to disable it.", 0);
//
//        OsdWrite(7, "               OK", menusub == 0);
//
//        menustate = MENU_FIRMWARE_OPTIONS_ENABLED2;
//        break;
//
//    case MENU_FIRMWARE_OPTIONS_ENABLED2 :
//
//        if (select)
//        {
//            menustate = MENU_NONE1;
//            menusub = 0;
//            OsdClear();
//        }
//        break;

        /******************************************************************/
        /* error message menu                                             */
        /******************************************************************/
    case MENU_ERROR :

        if (menu)
            menustate = MENU_MAIN1;

        break;

        /******************************************************************/
        /* popup info menu                                                */
        /******************************************************************/
    case MENU_INFO :

        if (menu)
            menustate = MENU_MAIN1;
        else if (CheckTimer(menu_timer))
            menustate = MENU_NONE1;

        break;

        /******************************************************************/
        /* we should never come here                                      */
        /******************************************************************/
    default :

        break;
    }

  DEBUG_FUNC_OUT(DEBUG_F_MENU | DEBUG_L2);
}


void ScrollLongName(void)
{
  DEBUG_FUNC_IN(DEBUG_F_MENU | DEBUG_L2);

// this function is called periodically when file selection window is displayed
// it checks if predefined period of time has elapsed and scrolls the name if necessary

    char k = sort_table[iSelectedEntry];
	static int len;
	int max_len;

    if (DirEntryLFN[k][0]) // && CheckTimer(scroll_timer)) // scroll if long name and timer delay elapsed
    {
		// FIXME - yuk, we don't want to do this every frame!
        len = strlen(DirEntryLFN[k]); // get name length

        if (len > 4)
            if (DirEntryLFN[k][len - 4] == '.')
                len -= 4; // remove extension

        max_len = 30; // number of file name characters to display (one more required for scrolling)
        if (DirEntry[k].Attributes & ATTR_DIRECTORY)
            max_len = 25; // number of directory name characters to display

		ScrollText(iSelectedEntry,DirEntryLFN[k],len,max_len,1);
    }

  DEBUG_FUNC_OUT(DEBUG_F_MENU | DEBUG_L2);
}


char* GetDiskInfo(char* lfn, long len)
{
  DEBUG_FUNC_IN(DEBUG_F_MENU | DEBUG_L1);

// extracts disk number substring form file name
// if file name contains "X of Y" substring where X and Y are one or two digit number
// then the number substrings are extracted and put into the temporary buffer for further processing
// comparision is case sensitive

    short i, k;
    static char info[] = "XX/XX"; // temporary buffer
    static char template[4] = " of "; // template substring to search for
    char *ptr1, *ptr2, c;
    unsigned char cmp;

    if (len > 20) // scan only names which can't be fully displayed
    {
        for (i = (unsigned short)len - 1 - sizeof(template); i > 0; i--) // scan through the file name starting from its end
        {
            ptr1 = &lfn[i]; // current start position
            ptr2 = template;
            cmp = 0;
            for (k = 0; (unsigned int)k < sizeof(template); k++) // scan through template
            {
                cmp |= *ptr1++ ^ *ptr2++; // compare substrings' characters one by one
                if (cmp)
                   break; // stop further comparing if difference already found
            }

            if (!cmp) // match found
            {
                k = i - 1; // no need to check if k is valid since i is greater than zero

                c = lfn[k]; // get the first character to the left of the matched template substring
                if (c >= '0' && c <= '9') // check if a digit
                {
                    info[1] = c; // copy to buffer
                    info[0] = ' '; // clear previous character
                    k--; // go to the preceding character
                    if (k >= 0) // check if index is valid
                    {
                        c = lfn[k];
                        if (c >= '0' && c <= '9') // check if a digit
                            info[0] = c; // copy to buffer
                    }

                    k = i + sizeof(template); // get first character to the right of the mached template substring
                    c = lfn[k]; // no need to check if index is valid
                    if (c >= '0' && c <= '9') // check if a digit
                    {
                        info[3] = c; // copy to buffer
                        info[4] = ' '; // clear next char
                        k++; // go to the followwing character
                        if (k < len) // check if index is valid
                        {
                            c = lfn[k];
                            if (c >= '0' && c <= '9') // check if a digit
                                info[4] = c; // copy to buffer
                        }
                        return info;
                    }
                }
            }
        }
    }
    return NULL;

  DEBUG_FUNC_OUT(DEBUG_F_MENU | DEBUG_L1);
}


// print directory contents
void PrintDirectory(void)
{
  DEBUG_FUNC_IN(DEBUG_F_MENU | DEBUG_L1);

    unsigned char i;
    unsigned char k;
    unsigned long len;
    char *lfn;
    char *info;
    char *p;
    unsigned char j;

    s[32] = 0; // set temporary string length to OSD line length

	ScrollReset();

    for (i = 0; i < 8; i++)
    {
        memset(s, ' ', 32); // clear line buffer
        if (i < nDirEntries)
        {
            k = sort_table[i]; // ordered index in storage buffer
            lfn = DirEntryLFN[k]; // long file name pointer
            DirEntryInfo[i][0] = 0; // clear disk number info buffer

            if (lfn[0]) // item has long name
            {
                len = strlen(lfn); // get name length
                info = NULL; // no disk info

                if (!(DirEntry[k].Attributes & ATTR_DIRECTORY)) // if a file
                {
                if (len > 4)
                    if (lfn[len-4] == '.')
                        len -= 4; // remove extension

                info = GetDiskInfo(lfn, len); // extract disk number info

                if (info != NULL)
                   memcpy(DirEntryInfo[i], info, 5); // copy disk number info if present
                }

                if (len > 30)
                    len = 30; // trim display length if longer than 30 characters

                if (i != iSelectedEntry && info != NULL)
                { // display disk number info for not selected items
                    strncpy(s + 1, lfn, 30-6); // trimmed name
                    strncpy(s + 1+30-5, info, 5); // disk number
                }
                else
                    strncpy(s + 1, lfn, len); // display only name
            }
            else  // no LFN
            {
                strncpy(s + 1, (const char*)DirEntry[k].Name, 8); // if no LFN then display base name (8 chars)
                if (DirEntry[k].Attributes & ATTR_DIRECTORY && DirEntry[k].Extension[0] != ' ')
                {
                    p = (char*)&DirEntry[k].Name[7];
                    j = 8;
                    do
                    {
                        if (*p-- != ' ')
                            break;
                    } while (--j);

                    s[1 + j++] = '.';
                    strncpy(s + 1 + j, (const char*)DirEntry[k].Extension, 3); // if no LFN then display base name (8 chars)
                }
            }

            if (DirEntry[k].Attributes & ATTR_DIRECTORY) // mark directory with suffix
                strcpy(&s[22], " <DIR>");
        }
        else
        {
            if (i == 0 && nDirEntries == 0) // selected directory is empty
                strcpy(s, "          No files!");
        }

        OsdWrite(i, s, i == iSelectedEntry,0); // display formatted line text
    }

  DEBUG_FUNC_OUT(DEBUG_F_MENU | DEBUG_L1);
}


void _strncpy(char* pStr1, const char* pStr2, size_t nCount)
{
  DEBUG_FUNC_IN(DEBUG_F_MENU | DEBUG_L2);

// customized strncpy() function to fill remaing destination string part with spaces

    while (*pStr2 && nCount)
    {
        *pStr1++ = *pStr2++; // copy strings
        nCount--;
    }

    while (nCount--)
        *pStr1++ = ' '; // fill remaining space with spaces

  DEBUG_FUNC_OUT(DEBUG_F_MENU | DEBUG_L2);
}


// insert floppy image pointed to to by global <file> into <drive>
void InsertFloppy(adfTYPE *drive)
{
  DEBUG_FUNC_IN(DEBUG_F_MENU | DEBUG_L1);

    unsigned char i, j;
    unsigned long tracks;

    // calculate number of tracks in the ADF image file
    tracks = file.size / (512*11);
    if (tracks > MAX_TRACKS)
    {
        printf("UNSUPPORTED ADF SIZE!!! Too many tracks: %lu\r", tracks);
        tracks = MAX_TRACKS;
    }
    drive->tracks = (unsigned char)tracks;

    // fill index cache
    for (i = 0; i < tracks; i++) // for every track get its start position within image file
    {
        drive->cache[i] = file.cluster; // start of the track within image file
        for (j = 0; j < 11; j++)
            FileNextSector(&file); // advance by track length (11 sectors)
    }

    // copy image file name into drive struct
    if (file.long_name[0]) // file has long name
        _strncpy(drive->name, file.long_name, sizeof(drive->name)); // copy long name
    else
    {
        strncpy(drive->name, file.name, 8); // copy base name
        memset(&drive->name[8], ' ', sizeof(drive->name) - 8); // fill the rest of the name with spaces
    }

    if (DiskInfo[0]) // if selected file has valid disk number info then copy it to its name in drive struct
    {
        drive->name[16] = ' '; // precede disk number info with space character
        strncpy(&drive->name[17], DiskInfo, sizeof(DiskInfo)); // copy disk number info
    }

    // initialize the rest of drive struct
    drive->status = DSK_INSERTED;
    if (!(file.attributes & ATTR_READONLY)) // read-only attribute
        drive->status |= DSK_WRITABLE;

    drive->cluster_offset = drive->cache[0];
    drive->sector_offset = 0;
    drive->track = 0;
    drive->track_prev = -1;

    // some debug info
    if (file.long_name[0])
        printf("Inserting floppy: \"%s\"\r", file.long_name);
    else
        printf("Inserting floppy: \"%.11s\"\r", file.name);

    printf("file attributes: 0x%02X\r", file.attributes);
    printf("file size: %lu (%lu KB)\r", file.size, file.size >> 10);
    printf("drive tracks: %u\r", drive->tracks);
    printf("drive status: 0x%02X\r", drive->status);

  DEBUG_FUNC_OUT(DEBUG_F_MENU | DEBUG_L1);
}


/*  Error Message */
void ErrorMessage(const char *message, unsigned char code)
{
  DEBUG_FUNC_IN(DEBUG_F_MENU | DEBUG_L1);

    if (menustate == MENU_NONE2)
        menustate = MENU_ERROR;

    if (menustate == MENU_ERROR)
    {
//        OsdClear();
 		OsdSetTitle("Error",0);
        OsdWrite(0, "         *** ERROR ***", 1,0);
	    OsdWrite(1, "", 0,0);
        strncpy(s, message, 32);
        s[32] = 0;
        OsdWrite(2, s, 0,0);

        s[0] = 0;
        if (code)
            sprintf(s, "    #%d", code);

	    OsdWrite(3, "", 0,0);
        OsdWrite(4, s, 0,0);

	    OsdWrite(5, "", 0,0);
	    OsdWrite(6, "", 0,0);
	    OsdWrite(7, "", 0,0);

        OsdEnable(0); // do not disable KEYBOARD
    }

  DEBUG_FUNC_OUT(DEBUG_F_MENU | DEBUG_L1);
}


void InfoMessage(char *message)
{
  DEBUG_FUNC_IN(DEBUG_F_MENU | DEBUG_L1);

    OsdWaitVBL();
    if (menustate != MENU_INFO)
    {
//        OsdClear();
 		OsdSetTitle("Message",0);
        OsdEnable(0); // do not disable keyboard
    }
    OsdWrite(0, "", 0,0);
    OsdWrite(1, message, 0,0);
    OsdWrite(2, "", 0,0);
    OsdWrite(3, "", 0,0);
    OsdWrite(4, "", 0,0);
    OsdWrite(5, "", 0,0);
    OsdWrite(6, "", 0,0);
    OsdWrite(7, "", 0,0);
    menu_timer = GetTimer(1000);
    menustate = MENU_INFO;

  DEBUG_FUNC_OUT(DEBUG_F_MENU | DEBUG_L1);
}


void DebugMessage(char *message)
{
  DEBUG_FUNC_IN(DEBUG_F_MENU | DEBUG_L1);

	strncpy(&debuglines[debugptr*32],message,31);
	debuglines[debugptr*32+31]=0;
	debugptr=(debugptr+1)&7;

  DEBUG_FUNC_OUT(DEBUG_F_MENU | DEBUG_L1);
}

