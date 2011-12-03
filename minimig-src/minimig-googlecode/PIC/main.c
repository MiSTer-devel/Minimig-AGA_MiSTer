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
2009-11-27	- minor adaptations for 090911 FPGA firmware
2009-12-10	- changed boot command header id
2009-12-12	- modified mfm sync word exclusion list
			- fixed sector header generation
2009-12-17	- changed inter sector gap length
2009-12-18	- ReadTrack() function changed
2009-12-22	- updated mfm sync word exclusion list
2009-12-24	- updated version number
*/

#include <pic18.h>
#include <stdio.h>
#include <string.h>
#include "hardware.h"
#include "osd.h"
#include "mmc.h"
#include "fat16.h"

//#define DEBUG

const char version[] = {"$VER:PYQ091224"};

void CheckTrack(struct adfTYPE *drive);
void ReadTrack(struct adfTYPE *drive);
void SendFile(struct fileTYPE *file);
void WriteTrack(struct adfTYPE *drive);
unsigned char FindSync(struct adfTYPE *drive);
unsigned char GetHeader(unsigned char *pTrack, unsigned char *pSector);
unsigned char GetData(void);

char BootPrint(const char* text);
char BootUpload(struct fileTYPE *file, unsigned char base, unsigned char size);
void BootExit(void);
void ClearMemory(unsigned char base, unsigned char size);
void ErrorMessage(const char* message, unsigned char code);
unsigned short SectorToFpga(unsigned char sector, unsigned char track, unsigned char dsksynch, unsigned char dsksyncl);
void SectorGapToFpga(void);
void SectorHeaderToFpga(unsigned char n, unsigned char dsksynch, unsigned char dsksyncl);
char UploadKickstart(const unsigned char *name);
unsigned char Open(const unsigned char *name);
unsigned char ConfigureFpga(void);
void HandleFpga(void);
void HandleFDD(unsigned char c1, unsigned char c2);
void UpdateDriveStatus(void);
void InsertFloppy(struct adfTYPE *drive);
void ScrollDir(const unsigned char *type, unsigned char mode);
void PrintDir(void);
void User(void);
void LoadConfiguration(void);
void SaveConfiguration(void);

/*FPGA commands <c1> argument*/
#define 	CMD_RDTRK   0x01
#define 	CMD_WRTRK   0x02

/*floppy status*/
#define		DSK_INSERTED		0x01	/*disk is inserted*/
#define		DSK_WRITABLE		0x10	/*disk is writable*/

/*menu states*/
enum MENU
{
	MENU_NONE1,
	MENU_NONE2,
	MENU_MAIN1,
	MENU_MAIN2,
	MENU_FILE1,
	MENU_FILE2,
	MENU_RESET1,
	MENU_RESET2,
	MENU_SETTINGS1,
	MENU_SETTINGS2,
	MENU_ROMFILESELECT1,
	MENU_ROMFILESELECT2,
	MENU_ROMFILESELECTED1,
	MENU_ROMFILESELECTED2,
	MENU_SETTINGS_VIDEO1,
	MENU_SETTINGS_VIDEO2,
	MENU_SETTINGS_MEMORY1,
	MENU_SETTINGS_MEMORY2,
	MENU_SETTINGS_CHIPSET1,
	MENU_SETTINGS_CHIPSET2,
	MENU_SETTINGS_DRIVES1,
	MENU_SETTINGS_DRIVES2,
	MENU_ERROR
};

/*other constants*/
#define		DIRSIZE				8		/*size of directory display window*/
#define		REPEATTIME			50		/*repeat delay in 10ms units*/
#define		REPEATRATE			5		/*repeat rate in 10ms units*/

#define		EEPROM_FILTER_LORES		0x10
#define		EEPROM_FILTER_HIRES		0x11
#define		EEPROM_MEMORY			0x12
#define		EEPROM_CHIPSET			0x13
#define		EEPROM_FLOPPY_SPEED		0x14
#define		EEPROM_FLOPPY_DRIVES	0x15
#define		EEPROM_AR3DISABLED		0x16
#define		EEPROM_SCANLINE			0x17
#define		EEPROM_KICKNAME			0x18	//size 8

/*variables*/
struct direntryTYPE
{
	unsigned char name[8];   			/*name of file*/
	unsigned char attributes;
	unsigned short entry;
	unsigned short cluster;
};

struct adfTYPE
{
	unsigned char status;				/*status of floppy*/
	unsigned short cache[160];			/*cluster cache*/
	unsigned short clusteroffset;		/*cluster offset to handle tricky loaders*/
	unsigned char sectoroffset;			/*sector offset to handle tricky loaders*/
	unsigned char track;				/*current track*/
	unsigned char trackprev;			/*previous track*/
	unsigned char name[12];				/*floppy name*/
};

struct adfTYPE *pdfx;					/*drive select pointer*/
struct adfTYPE df[2];					/*drives information structure*/
struct fileTYPE file;					/*global file handle*/

bdata struct direntryTYPE directory[DIRSIZE];	/*directory array*/
unsigned char dirptr;					/*pointer into directory array*/

unsigned char menustate = MENU_NONE1;
unsigned char menusub = 0;

unsigned char s[25];					//temporary buffer for strings



const char *config_filter_msg[] =  {"none", "HOR ", "VER ", "H+V "};
const char *config_memory_chip_msg[] = {"0.5 MB", "1.0 MB", "1.5 MB", "2.0 MB"};
const char *config_memory_slow_msg[] = {"none  ", "0.5 MB", "1.0 MB", "1.5 MB"};
const char *config_scanline_msg[] = {"off", "dim", "blk"};

bdata unsigned char config_kickname[12];	//kickstart file name
unsigned char config_filter_lores = 0;
unsigned char config_filter_hires = 0;
unsigned char config_memory = 0;			//changes take effect after reset
unsigned char config_chipset = 0;
unsigned char config_floppy_speed = 0;
unsigned char config_floppy_drives = 0;		//number of floppy drives, the FPGA updates its drive number after reset
unsigned char config_ar3disabled = 0;		//change takes effect after next FPGA reconfiguration
unsigned char config_scanline = 0;

unsigned char floppy_drives = 0;			//curent number of active FPGA floppy drives

unsigned char Error;

void FatalError(unsigned char code)
{
	// code = number of blinks
	unsigned long t;
	unsigned char i;
	while (1)
	{
		i = code;
		do
		{
			t = 38000;
			while (--t) //wait 100ms
				DISKLED_ON;
			t = 2*38000;
			while (--t) //wait 200ms
				DISKLED_OFF;
		} while (--i);
		t = 8*38000;
		while (--t) //wait 900ms
			DISKLED_OFF;
	}
}

void LoadConfiguration(void)
{
	unsigned char i;
	unsigned char c;

	//check correctness of kickstart file name
	for (i=0;i<8;i++)
	{
		c = eeprom_read(EEPROM_KICKNAME+i);
		if (c>=32 && c<=127)	//only 0-9,A-Z and space allowed
			config_kickname[i] = c;
		else
		{
			strncpy(config_kickname,"KICK    ",8);	//if illegal character detected revert to default name
			break;
		}
	}

	//read video interpolation filter configuration for low resolution screen modes
	c = eeprom_read(EEPROM_FILTER_LORES);
	if (c>0x03)
		c = 0x00;
	config_filter_lores = c;

	//read video interpolation filter configuration for high resolution screen modes
	c = eeprom_read(EEPROM_FILTER_HIRES);
	if (c>0x03)
		c = 0x00;
	config_filter_hires = c;

	//read memory configuration
	c = eeprom_read(EEPROM_MEMORY);
	if (c>0x0F)
		c = 0x05;
	config_memory = c;

	//read CPU and chipset configuration
	c = eeprom_read(EEPROM_CHIPSET);
	if (c>0x0F)
		c = 0x00;
	config_chipset = c;

	//read floppy speed configuration
	c = eeprom_read(EEPROM_FLOPPY_SPEED);
	if (c>0x03)
		c = 0x00;
	config_floppy_speed = c;

	//read floppy drives configuration
	c = eeprom_read(EEPROM_FLOPPY_DRIVES);
	if (c>0x01)
		c = 0x00;
	config_floppy_drives = c;

	//read action replay configuration
	c = eeprom_read(EEPROM_AR3DISABLED);
	if (c>0x01)
		c = 0x00;
	config_ar3disabled = c;

	//read scanline configuration
	c = eeprom_read(EEPROM_SCANLINE);
	if (c>0x03)
		c = 0x00;
	config_scanline = c;
}

void SaveConfiguration(void)
{
	unsigned char i;
	unsigned char c;

	//write kickstart file name
	for (i=0;i<8;i++)
		if (config_kickname[i] != eeprom_read(EEPROM_KICKNAME+i))
			eeprom_write(EEPROM_KICKNAME+i,config_kickname[i]);

	//write video interpolation filter configuration for low resolution screen modes
	if (config_filter_lores != eeprom_read(EEPROM_FILTER_LORES))
		eeprom_write(EEPROM_FILTER_LORES,config_filter_lores);

	//write video interpolation filter configuration for high resolution screen modes
	if (config_filter_hires != eeprom_read(EEPROM_FILTER_HIRES))
		eeprom_write(EEPROM_FILTER_HIRES,config_filter_hires);

	//write memory configuration
	if (config_memory != eeprom_read(EEPROM_MEMORY))
		eeprom_write(EEPROM_MEMORY,config_memory);

	//write CPU and chipset configuration
	if (config_chipset != eeprom_read(EEPROM_CHIPSET))
		eeprom_write(EEPROM_CHIPSET,config_chipset);

	//write floppy speed configuration
	if (config_floppy_speed != eeprom_read(EEPROM_FLOPPY_SPEED))
		eeprom_write(EEPROM_FLOPPY_SPEED,config_floppy_speed);

	//write floppy drives configuration
	if (config_floppy_drives != eeprom_read(EEPROM_FLOPPY_DRIVES))
		eeprom_write(EEPROM_FLOPPY_DRIVES,config_floppy_drives);

	//write action replay configuration
	if (config_ar3disabled != eeprom_read(EEPROM_AR3DISABLED))
		eeprom_write(EEPROM_AR3DISABLED,config_ar3disabled);

	//write scanline configuration
	if (config_scanline != eeprom_read(EEPROM_SCANLINE))
		eeprom_write(EEPROM_SCANLINE,config_scanline);
}

/*This is where it all starts after reset*/
void main(void)
{
	unsigned short time;
	unsigned char key;
	unsigned long t;

	/*initialize hardware*/
	HardwareInit();

	LoadConfiguration();
	strncpy(&config_kickname[8],"ROM",3);	//add rom file extension

	printf("\rMinimig by Dennis van Weeren");
	printf("\rBug fixes, mods and extensions by Jakub Bednarski\r\r");
	printf("Version %s\r\r", version+5);

	/*intialize mmc card*/
	if (MMC_Init()==0)
	{
		FatalError(1);
	}

	/*initalize FAT partition*/
	if (FindDrive())
	{
		printf("FAT16 filesystem found!\r");
	}
	else
	{
		printf("No FAT16 filesystem!\r");
		FatalError(2);
	}

	/*	if (DONE) //FPGA has not been configured yet
	{
	printf("FPGA already configured\r");
	}
	else
	*/
	{
		/*configure FPGA*/
		if (ConfigureFpga())
		{
			printf("FPGA configured\r");
		}
		else
		{
			printf("FPGA configuration failed\r");
			FatalError(3);
		}
	}

	t = 38000;
	while (--t) //let's wait some time till reset is inactive so we can get a valid keycode
		DISKLED_OFF;

	key = OsdGetCtrl();		//get key code

	if (key==KEY_F1)
		config_chipset |= 0x04;      //force NTSC mode

	if (key==KEY_F2)
		config_chipset &= ~0x04;      //force PAL mode

	ConfigChipset(config_chipset|0x01); //force CPU turbo mode

	OsdReset(1);

	ConfigFloppy(1, 1);				//high speed mode for ROM loading

	sprintf(s, "PIC firmware %s\n", version+5);
	BootPrint(s);

	sprintf(s, "CPU clock     : %s", config_chipset & 0x01 ? "turbo": "normal");
	BootPrint(s);
	sprintf(s, "Agnus         : %s-%s", config_chipset & 0x08 ? "ECS": "OCS", config_chipset & 0x04 ? "NTSC": "PAL");
	BootPrint(s);
	sprintf(s, "Chip RAM size : %s", config_memory_chip_msg[config_memory&3]);
	BootPrint(s);
	sprintf(s, "Slow RAM size : %s", config_memory_slow_msg[config_memory>>2&3]);
	BootPrint(s);

	sprintf(s, "Floppy drives : %d", config_floppy_drives + 1);
	BootPrint(s);
	sprintf(s, "Floppy speed  : %s\n", config_floppy_speed ? "fast": "normal");
	BootPrint(s);

	if (UploadKickstart(config_kickname))
	{
		strcpy(config_kickname,"KICK    ROM");
		if (UploadKickstart(config_kickname))
			FatalError(6);
	}

	if (!config_ar3disabled && !CheckButton())	//load Action Replay ROM if not disabled
		if (Open("AR3     ROM"))
			if (file.len==0x40000)
			{//256KB Action Replay 3 ROM
				BootPrint("\nUploading Action Replay ROM...");
				BootUpload(&file,0x40,0x04);
				ClearMemory(0x44,0x04);
			}
			else
			{
				BootPrint("\nUnsupported AR3.ROM file size!!!");
				FatalError(6);
			}

	printf("Bootloading is complete.\r");

	BootPrint("\nExiting bootloader...");

	//config memory and chipset features
	ConfigMemory(config_memory);
	ConfigChipset(config_chipset);
	ConfigFloppy(config_floppy_drives, config_floppy_speed);

	BootExit();

	ConfigFilter(config_filter_lores, config_filter_hires); //set interpolation filters
	ConfigScanline(config_scanline); //set scanline effect

	df[0].status = 0;
	df[1].status = 0;

	/******************************************************************************/
	/*  System is up now                                                          */
	/******************************************************************************/

	/*fill initial directory*/
	ScrollDir("ADF",0);

	/*get initial timer for checking user interface*/
	time = GetTimer(5);

	while (1)
	{
		/*handle command*/
		HandleFpga();

		/*handle user interface*/
		if (CheckTimer(time))
		{
			time = GetTimer(2);
			User();
		}
	}
}

char UploadKickstart(const unsigned char *name)
{
	if (Open(name))
	{
		if (file.len==0x80000)
		{//512KB Kickstart ROM
			BootPrint("Uploading 512KB Kickstart...");
			BootUpload(&file,0xF8,0x08);
		}
		else if (file.len==0x40000)
		{//256KB Kickstart ROM
			BootPrint("Uploading 256KB Kickstart...");
			BootUpload(&file,0xF8,0x04);
		}
		else
		{
			BootPrint("Unsupported Kickstart ROM file size!");
			return 41;
		}
	}
	else
	{
		sprintf(s,"No \"%11s\" file!",name);
		BootPrint(s);
		return 40;
	}
	return 0;
}

char BootPrint(const char* text)
{
	char c1,c2,c3,c4;
	char cmd;
	const char* p;
	unsigned char n;

	p = text;
	n = 0;
	while (*(p++) != 0)
		n++; //calculating string length

	cmd = 1;
	while (1)
	{
		EnableFpga();
		c1 = SPI(0x10); //track read command
		c2 = SPI(0x01); //disk presentt
		SPI(0);
		SPI(0);
		c3 = SPI(0);
		c4 = SPI(0);

		if (c1 & CMD_RDTRK)
		{
			if (cmd)
			{//command phase
				if (c3==0x80 && c4==0x06)	//command packet size must be 12 bytes
				{
					cmd = 0;
					SPI(0xAA); //command header 0xAA67
					SPI(0x68);
					SPI(0x00); //cmd: 0x0001 = print texts
					SPI(0x01);
					//data packet size in bytes
					SPI(0x00);
					SPI(0x00);
					SPI(0x00);
					SPI(n+2); // +2 because only even byte count is possible to send and we have to send termination zero byte
					//don't care
					SPI(0x00);
					SPI(0x00);
					SPI(0x00);
					SPI(0x00);
				}
				else break;
			}
			else
			{//data phase
				if (c3==0x80 && c4==((n+2)>>1))
				{
					p = text;
					n = c4<<1;
					while (n--)
					{
						c4 = *p;
						SPI(c4);
						if (c4) //if current character is not zero go to next one
							p++;
					}
					DisableFpga();
					return 1;
				}
				else break;
			}
		}
		DisableFpga();
	}
	DisableFpga();
	return 0;
}

char BootUpload(struct fileTYPE *file, unsigned char base, unsigned char size)
// this function sends given file to minimig's memory
// base - memory base address (bits 23..16)
// size - memory size (bits 23..16)
{
	char c1,c2,c3,c4;
	char cmd;

	cmd = 1;
	while (1)
	{
		EnableFpga();
		c1 = SPI(0x10); //track read command
		c2 = SPI(0x01); //disk present
		SPI(0);
		SPI(0);
		c3 = SPI(0);
		c4 = SPI(0);
		//printf("CMD%d:%02X,%02X,%02X,%02X\r",cmd,c1,c2,c3,c4);
		if (c1 & CMD_RDTRK)
		{
			if (cmd)
			{//command phase
				if (c3==0x80 && c4==0x06)	//command packet size 12 bytes
				{
					cmd = 0;
					SPI(0xAA);
					SPI(0x68);	//command header 0xAA67
					SPI(0x00);
					SPI(0x02);	//cmd: 0x0002 = upload memory
					//memory base address
					SPI(0x00);
					SPI(base);
					SPI(0x00);
					SPI(0x00);
					//memory size
					SPI(0x00);
					SPI(size);
					SPI(0x00);
					SPI(0x00);
				}
				else break;
			}
			else
			{//data phase
				DisableFpga();
				printf("uploading ROM file\r");
				//send rom image to FPGA
				SendFile(file);
				printf("\rROM file uploaded\r");
				return 0;
			}
		}
		DisableFpga();
	}
	DisableFpga();
	return -1;
}

void BootExit(void)
{
	char c1,c2,c3,c4;
	while (1)
	{
		EnableFpga();
		c1 = SPI(0x10); //track read command
		c2 = SPI(0x01); //disk present
		SPI(0);
		SPI(0);
		c3 = SPI(0);
		c4 = SPI(0);
		if (c1 & CMD_RDTRK)
		{
			if (c3==0x80 && c4==0x06)	//command packet size 12 bytes
			{
				SPI(0xAA); //command header 0xAA67
				SPI(0x68);
				SPI(0x00); //cmd: 0x0003 = restart
				SPI(0x03);
				//don't care
				SPI(0x00);
				SPI(0x00);
				SPI(0x00);
				SPI(0x00);
				//don't care
				SPI(0x00);
				SPI(0x00);
				SPI(0x00);
				SPI(0x00);
			}
			DisableFpga();
			return;
		}
		DisableFpga();
	}
}

void ClearMemory(unsigned char base, unsigned char size)
{
	unsigned char c1, c2, c3, c4;

	while (1)
	{
		EnableFpga();
		c1 = SPI(0x10); //track read command
		c2 = SPI(0x01); //disk present
		SPI(0);
		SPI(0);
		c3 = SPI(0);
		c4 = SPI(0);
		if (c1 & CMD_RDTRK)
		{
			if (c3==0x80 && c4==0x06)//command packet size 12 bytes
			{
				SPI(0xAA); //command header 0xAA67
				SPI(0x68);
				SPI(0x00); //cmd: 0x0004 = clear memory
				SPI(0x04);
				//memory base address
				SPI(0x00);
				SPI(base);
				SPI(0x00);
				SPI(0x00);
				//memory size
				SPI(0x00);
				SPI(size);
				SPI(0x00);
				SPI(0x00);
			}
			DisableFpga();
			return;
		}
		DisableFpga();
	}
}

void User(void)
{
	unsigned char i, c, up, down, select, menu, right, left;

	/*get user control codes*/
	c = OsdGetCtrl();

	/*decode and set events*/
	up = 0;
	down = 0;
	select = 0;
	menu = 0;
	right = 0;
	left = 0;

	if (c==KEY_UP)
		up = 1;
	if (c==KEY_DOWN)
		down = 1;
	if (c==KEY_ENTER || c==KEY_SPACE)
		select = 1;
	if (c==KEY_MENU)
		menu = 1;
	if (c==KEY_RIGHT)
		right = 1;
	if (c==KEY_LEFT)
		left = 1;
	if (c==KEY_ESC && menustate!=MENU_NONE2)//esc key when OSD is on
		menu = 1;

	/*menu state machine*/
	switch (menustate)
	{
		/******************************************************************/
		/*no menu selected / menu exited / menu not displayed*/
		/******************************************************************/
	case MENU_NONE1 :
		OsdDisable();
		menustate = MENU_NONE2;
		break;

	case MENU_NONE2 :
		if (menu)/*check if user wants to go to menu*/
		{
			menustate = MENU_MAIN1;
			menusub = 0;
			OsdClear();
			OsdEnable();
		}
		break;

		/******************************************************************/
		/*main menu: insert/eject floppy, reset and exit*/
		/******************************************************************/
	case MENU_MAIN1 :
		/*menu title*/
		OsdWrite(0, " ** Minimig Menu **", 0);

		// df0: drive info
		strcpy(s, " df0: ");
		if (df[0].status & DSK_INSERTED)// floppy is inserted
		{
			strncat(s, df[0].name, 8);
			strcat(s, df[0].status & DSK_WRITABLE ? " RW" : " RO"); // floppy is writable or read-only
		}
		else // no floppy
			strcat(s, "--------   ");

		OsdWrite(2, s, menusub==0);

		// df1: drive info
		strcpy(s, " df1: ");
		if (floppy_drives<1)
			strcat(s, "disabled");
		else
		{
			if (df[1].status & DSK_INSERTED)// floppy is inserted
			{
				strncat(s, df[1].name, 8);
				strcat(s, df[1].status & DSK_WRITABLE ? " RW" : " RO"); // floppy is writable or read-only
			}
			else // no floppy
				strcat(s, "--------   ");
		}
		OsdWrite(3, s, menusub==1);

		/* settings */
		OsdWrite(4, "      settings", menusub==2);

		/*reset system*/
		OsdWrite(5, "      reset", menusub==3);

		/*exit menu*/
		OsdWrite(7, "        exit", menusub==4);

		/*goto to second state of main menu*/
		menustate = MENU_MAIN2;
		break;

	case MENU_MAIN2 :

		if (menu)/*menu pressed*/
			menustate = MENU_NONE1;
		else if (up)/*up pressed*/
		{
			if (menusub > 0)
				menusub--;
			if (menusub<2 && menusub>floppy_drives)
				menusub = floppy_drives;
			menustate = MENU_MAIN1;
		}
		else if (down)/*down pressed*/
		{
			if (menusub<4)
				menusub++;
			if (menusub<2 && menusub>floppy_drives)
				menusub = 2;
			menustate = MENU_MAIN1;
		}
		else if (select)/*select pressed*/
		{
			if (menusub < 2)
			{
				if (df[menusub].status & DSK_INSERTED)// eject floppy
				{
					df[menusub].status = 0;
					menustate = MENU_MAIN1;
				}
				else
				{
					df[menusub].status = 0;
					pdfx = & df[menusub];
					menustate = MENU_FILE1;
					OsdClear();
				}
			}
			if (menusub==2)/*settings*/
			{
				menusub = 0;
				menustate = MENU_SETTINGS1;
				OsdClear();
			}
			else if (menusub==3)/*reset*/
			{
				menusub = 1;
				menustate = MENU_RESET1;
				OsdClear();
			}

			else if (menusub==4)/*exit menu*/
				menustate = MENU_NONE1;
		}
		break;

		/******************************************************************/
		/* adf file requester menu */
		/******************************************************************/
	case MENU_FILE1 :
		PrintDir();
		menustate = MENU_FILE2;
		break;

	case MENU_FILE2 :
		if ((i = GetASCIIKey(c)))
		{
			ScrollDir("ADF", i);
			menustate = MENU_FILE1;
		}
		if (down)/*scroll down through file requester*/
		{
			ScrollDir("ADF", 1);
			menustate = MENU_FILE1;
		}

		if (up)/*scroll up through file requester*/
		{
			ScrollDir("ADF", 2);
			menustate = MENU_FILE1;
		}

		if (select)/*insert floppy*/
		{
			if (directory[dirptr].name[0])
			{
				strncpy(file.name,directory[dirptr].name,8);
				file.attributes = directory[dirptr].attributes;
				file.cluster = directory[dirptr].cluster;
				file.sec = 0;
				InsertFloppy(pdfx);
			}

			menustate = MENU_MAIN1;
			menusub = 4;	//main menu exit
			OsdClear();
		}

		if (menu)/*return to main menu*/
		{
			menustate = MENU_MAIN1;
			OsdClear();
		}
		break;

		/******************************************************************/
		/* reset menu */
		/******************************************************************/
	case MENU_RESET1 :
		/*menu title*/
		OsdWrite(0, "    Reset Minimig?", 0);
		OsdWrite(2, "         yes", menusub==0);
		OsdWrite(3, "         no", menusub==1);

		/*goto to second state of reset menu*/
		menustate = MENU_RESET2;
		break;

	case MENU_RESET2 :
		if (down && menusub<1)
		{
			menusub++;
			menustate = MENU_RESET1;
		}

		if (up && menusub>0)
		{
			menusub--;
			menustate = MENU_RESET1;
		}

		if (select && menusub==0)
		{
			menustate = MENU_NONE1;
			OsdReset(0);
		}

		if (menu || (select && menusub==1))/*exit menu*/
		{
			menustate = MENU_MAIN1;
			menusub = 3;
			OsdClear();
		}
		break;

		/******************************************************************/
		/*settings menu*/
		/******************************************************************/
	case MENU_SETTINGS1 :
		/*menu title*/
		OsdWrite(0, "   ** SETTINGS **", 0);

		OsdWrite(2, "      chipset", menusub==0);
		OsdWrite(3, "      memory", menusub==1);
		OsdWrite(4, "      drives", menusub==2);
		OsdWrite(5, "      video", menusub==3);

		if (menusub==5)
			OsdWrite(7, "  \xF2     save      \xF2", 1);
		else if (menusub==4)
			OsdWrite(7, "  \xF3     exit      \xF3", 1);
		else
			OsdWrite(7, "        exit       ", 0);

		/*goto to second state of settings menu*/
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
			if (menusub==0)
			{
				menustate = MENU_SETTINGS_CHIPSET1;
				menusub = 0;
				OsdClear();
			}
			else if (menusub==1)
			{
				menustate = MENU_SETTINGS_MEMORY1;
				menusub = 0;
				OsdClear();
			}
			else if (menusub==2)
			{
				menustate = MENU_SETTINGS_DRIVES1;
				menusub = 0;
				OsdClear();
			}
			else if (menusub==3)
			{
				menustate = MENU_SETTINGS_VIDEO1;
				menusub = 0;
				OsdClear();
			}
			else if (menusub==4)/*return to main menu*/
			{
				menustate = MENU_MAIN1;
				menusub = 2;
				OsdClear();
			}
			else if (menusub==5)
			{
				SaveConfiguration();
				menustate = MENU_MAIN1;
				menusub = 2;
				OsdClear();
			}
		}

		if (menu)/*return to main menu*/
		{
			menustate = MENU_MAIN1;
			menusub = 2;
			OsdClear();
		}
		break;

		/******************************************************************/
		/* chipset settings menu */
		/******************************************************************/
	case MENU_SETTINGS_CHIPSET1 :

		OsdWrite(0, " \xF0     CHIPSET     \xF1", 0);

		strcpy(s, "      CPU : ");
		strcat(s, config_chipset & 0x01 ? "turbo " : "normal");
		OsdWrite(2, s, menusub==0);

		strcpy(s, "    Agnus : ");
		strcat(s, config_chipset & 0x04 ? "NTSC" : "PAL ");
		OsdWrite(3, s, menusub==1);

		strcpy(s, "    Agnus : ");
		strcat(s, config_chipset & 0x08 ? "ECS" : "OCS");
		OsdWrite(4, s, menusub==2);

		OsdWrite(7, "        exit", menusub==3);

		/*goto to second state of reset menu*/
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
			if (menusub==0)
			{
				config_chipset ^= 0x01;
				menustate = MENU_SETTINGS_CHIPSET1;
				ConfigChipset(config_chipset);
			}
			else if (menusub==1)
			{
				config_chipset ^= 0x04;
				menustate = MENU_SETTINGS_CHIPSET1;
				ConfigChipset(config_chipset);
			}
			else if (menusub==2)
			{
				config_chipset ^= 0x08;
				menustate = MENU_SETTINGS_CHIPSET1;
				ConfigChipset(config_chipset);
			}
			else if (menusub==3)/*return to settings menu*/
			{
				menustate = MENU_SETTINGS1;
				menusub = 0;
				OsdClear();
			}
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
		OsdWrite(0, " \xF0      MEMORY     \xF1", 0);

		strcpy(s, "  CHIP : ");
		strcat(s, config_memory_chip_msg[config_memory & 0x03]);
		OsdWrite(2, s, menusub==0);

		strcpy(s, "  SLOW : ");
		strcat(s, config_memory_slow_msg[config_memory >> 2 & 0x03]);
		OsdWrite(3, s, menusub==1);

		strcpy(s, "  ROM  : ");
		strncat(s, config_kickname, 8);
		OsdWrite(4, s, menusub==2);

		strcpy(s, "  AR3  : ");
		strcat(s, config_ar3disabled ? "disabled" : "enabled ");
		OsdWrite(5, s, menusub==3);

		OsdWrite(7, "        exit", menusub==4);

		/*goto to second state of memory settings menu*/
		menustate = MENU_SETTINGS_MEMORY2;
		break;

	case MENU_SETTINGS_MEMORY2 :
		if (down && menusub < 4)
		{
			menusub++;
			menustate = MENU_SETTINGS_MEMORY1;
		}

		if (up && menusub > 0)
		{
			menusub--;
			menustate = MENU_SETTINGS_MEMORY1;
		}

		if (select)
		{
			if (menusub==0)
			{
				config_memory = config_memory + 1 & 0x03 | config_memory & ~0x03;
				menustate = MENU_SETTINGS_MEMORY1;
				ConfigMemory(config_memory);
			}
			else if (menusub==1)
			{
				config_memory = config_memory + 4 & 0x0C | config_memory & ~0x0C;
				menustate = MENU_SETTINGS_MEMORY1;
				ConfigMemory(config_memory);
			}
			else if (menusub==2)
			{
				ScrollDir("ROM", 0);
				menustate = MENU_ROMFILESELECT1;
				OsdClear();
			}
			else if (menusub==3)
			{
				config_ar3disabled ^= 0x01;
				config_ar3disabled &= 0x01;
				menustate = MENU_SETTINGS_MEMORY1;
			}
			else if (menusub==4)/*return to settings menu*/
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
		/* floppy settings menu */
		/******************************************************************/
	case MENU_SETTINGS_DRIVES1 :

		OsdWrite(0, " \xF0      DRIVES     \xF1", 0);

		sprintf(s, "   drives   : %d", config_floppy_drives + 1);
		OsdWrite(2, s, menusub==0);

		strcpy(s, "   speed    : ");
		strcat(s, config_floppy_speed ? "fast  " : "normal");
		OsdWrite(3, s, menusub==1);

		OsdWrite(7, "        exit", menusub==2);

		/*goto to second state of floppy menu*/
		menustate = MENU_SETTINGS_DRIVES2;
		break;

	case MENU_SETTINGS_DRIVES2 :
		if (down && menusub<2)
		{
			menusub++;
			menustate = MENU_SETTINGS_DRIVES1;
		}

		if (up && menusub>0)
		{
			menusub--;
			menustate = MENU_SETTINGS_DRIVES1;
		}

		if (select)
		{
			if (menusub==0)
			{
				config_floppy_drives++;
				config_floppy_drives &= 0x01;
				menustate = MENU_SETTINGS_DRIVES1;
				ConfigFloppy(config_floppy_drives, config_floppy_speed);
			}
			else if (menusub==1)
			{
				config_floppy_speed++;
				config_floppy_speed &= 0x01;
				menustate = MENU_SETTINGS_DRIVES1;
				ConfigFloppy(config_floppy_drives, config_floppy_speed);
			}
			else if (menusub==2)/*return to settings menu*/
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
		/* video settings menu */
		/******************************************************************/
	case MENU_SETTINGS_VIDEO1 :
		/*menu title*/
		OsdWrite(0, " \xF0      VIDEO      \xF1", 0);

		strcpy(s, "  Lores Filter: ");
		strcpy( & s[16], config_filter_msg[config_filter_lores]);
		OsdWrite(2, s, menusub==0);

		strcpy(s, "  Hires Filter: ");
		strcpy( & s[16], config_filter_msg[config_filter_hires]);
		OsdWrite(3, s, menusub==1);

		strcpy(s, "  Scanline    : ");
		strcpy( & s[16], config_scanline_msg[config_scanline]);
		OsdWrite(4, s, menusub==2);

		OsdWrite(7, "        exit", menusub==3);

		/*goto to second state of video settings menu*/
		menustate = MENU_SETTINGS_VIDEO2;
		break;

	case MENU_SETTINGS_VIDEO2 :
		if (down && menusub < 3)
		{
			menusub++;
			menustate = MENU_SETTINGS_VIDEO1;
		}

		if (up && menusub > 0)
		{
			menusub--;
			menustate = MENU_SETTINGS_VIDEO1;
		}

		if (select)
		{
			if (menusub==0)
			{
				config_filter_lores++;
				config_filter_lores &= 0x03;
				menustate = MENU_SETTINGS_VIDEO1;
				ConfigFilter(config_filter_lores, config_filter_hires);
			}
			else if (menusub==1)
			{
				config_filter_hires++;
				config_filter_hires &= 0x03;
				menustate = MENU_SETTINGS_VIDEO1;
				ConfigFilter(config_filter_lores, config_filter_hires);
			}
			else if (menusub==2)
			{
				config_scanline++;
				if (config_scanline > 2)
					config_scanline = 0;
				menustate = MENU_SETTINGS_VIDEO1;
				ConfigScanline(config_scanline);
			}
			else if (menusub==3)/*return to settings menu*/
			{
				menustate = MENU_SETTINGS1;
				menusub = 3;
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
		/*rom file select menu*/
		/******************************************************************/
	case MENU_ROMFILESELECT1 :
		PrintDir();
		menustate = MENU_ROMFILESELECT2;
		break;

	case MENU_ROMFILESELECT2 :
		if (down)/*scroll down through file requester*/
		{
			ScrollDir("ROM", 1);
			menustate = MENU_ROMFILESELECT1;
		}

		if (up)/*scroll up through file requester*/
		{
			ScrollDir("ROM", 2);
			menustate = MENU_ROMFILESELECT1;
		}

		if (select)/*select rom file*/
		{
			menustate = MENU_ROMFILESELECTED1;
			menusub = 1;
			OsdClear();
		}

		if (menu)/*return to memory settings menu*/
		{
			ScrollDir("ADF", 0);
			menustate = MENU_SETTINGS_MEMORY1;
			menusub = 2;
			OsdClear();
		}

		break;

		/******************************************************************/
		/*rom file select message menu*/
		/******************************************************************/
	case MENU_ROMFILESELECTED1 :
		/*menu title*/
		OsdWrite(0, "  Reload Kickstart?", 0);
		OsdWrite(2, "         yes", menusub==0);
		OsdWrite(3, "         no", menusub==1);

		menustate = MENU_ROMFILESELECTED2;
		break;

	case MENU_ROMFILESELECTED2 :
		if (down && menusub < 1)
		{
			menusub++;
			menustate = MENU_ROMFILESELECTED1;
		}

		if (up && menusub > 0)
		{
			menusub--;
			menustate = MENU_ROMFILESELECTED1;
		}

		if (select)
		{
			if (menusub==0)
			{
				if (directory[dirptr].name[0])
				{
					memcpy((void*)config_kickname, (void*)directory[dirptr].name, 8);
					memcpy((void*)&config_kickname[8], "ROM", 3);

					OsdDisable();
					OsdReset(1); //reset to bootloader
					ConfigChipset(config_chipset|0x01);
					ConfigFloppy(1, 1);
					if (UploadKickstart(config_kickname)==0)
					{
						BootExit();
					}
					ConfigChipset(config_chipset);
					ConfigFloppy(config_floppy_drives, config_floppy_speed);
					ScrollDir("ADF", 0);
				}
				menustate = MENU_NONE1;
			}
			else if (menusub==1)/*exit menu*/
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

		/******************************************************************/
		/*error message menu*/
		/******************************************************************/
	case MENU_ERROR :
		if (menu)/*exit when menu button is pressed*/
		{
			menustate = MENU_NONE1;
		}
		break;
		/******************************************************************/
		/*we should never come here*/
		/******************************************************************/
	default :
		break;
	}
}


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
	OsdEnable();
}

/*print the contents of directory[] and the pointer dirptr onto the OSD*/
void PrintDir(void)
{
	unsigned char i;

	for(i=0;i<21;i++)
		s[i] = ' ';
	s[21] = 0;

	if (directory[0].name[0]==0)
		OsdWrite(0,"   No files!",1);
	else
		for(i=0;i<DIRSIZE;i++)
		{
			if (directory[i].name[0])
				strncpy(&s[3],directory[i].name,8);
			else
				strncpy(&s[3],"        ",8);
			OsdWrite(i,s,i==dirptr);
		}
}

/*This function "scrolls" through the flashcard directory and fills the directory[] array to be printed later.
modes set by <mode>:
0: fill directory[] starting at beginning of directory on flashcard
1: move down through directory
2: move up through directory
>=32: jumps to the next file beginning with the given character, wraps around at the end of directory
This function can also filter on filetype. <type> must point to a string containing the 3-letter filetype
to filter on. If the first character is a '*', no filter is applied (wildcard)*/
void ScrollDir(const unsigned char *type, unsigned char mode)
{
	unsigned char i;
	unsigned char seekmode;
	unsigned char rc;

	if (mode==0)
	{// reset directory to the beginning
		i = 0;
		seekmode = FILESEEK_START;
		dirptr = 0;
		memset(directory,0,sizeof(directory));
		/*fill directory with available files*/
		while (i<DIRSIZE)
		{
			if (!FileSearch(&file,seekmode))/*search file*/
				break;
			seekmode = FILESEEK_NEXT;
			if ((type[0]=='*') || (strncmp(&file.name[8],type,3)==0))/*check filetype*/
			{
				strncpy(directory[i].name,file.name,8);
				directory[i].attributes = file.attributes;
				directory[i].entry = file.entry;
				directory[i].cluster = file.cluster;
				i++;
			}
		}

	}
	else if (mode==1)
	{ // scroll down
		if (dirptr >= DIRSIZE-1)/*pointer is at bottom of directory window*/
		{
			strncpy(file.name,directory[DIRSIZE-1].name,8);
			file.attributes = directory[DIRSIZE-1].attributes;
			file.entry = directory[DIRSIZE-1].entry;
			file.cluster = directory[DIRSIZE-1].cluster;

			/*search next file and check for filetype/wildcard and/or end of directory*/
			do
			rc = FileSearch(&file,FILESEEK_NEXT);
			while ((type[0]!='*') && (strncmp(&file.name[8],type,3)) && rc);

			/*update directory[] if file found*/
			if (rc)
			{
				for (i=0;i<DIRSIZE-1;i++)
					directory[i] = directory[i+1];

				strncpy(directory[DIRSIZE-1].name,file.name,8);
				directory[DIRSIZE-1].attributes = file.attributes;
				directory[DIRSIZE-1].entry = file.entry;
				directory[DIRSIZE-1].cluster = file.cluster;
			}
		}
		else/*just move pointer in window*/
		{
			dirptr++;
			if (directory[dirptr].name[0]==0)
				dirptr--;
		}
	}
	else if (mode==2)
	{ // scroll up
		if (dirptr==0)/*pointer is at top of directory window*/
		{
			strncpy(file.name,directory[0].name,8);
			file.attributes = directory[0].attributes;
			file.entry = directory[0].entry;
			file.cluster = directory[0].cluster;

			/*search previous file and check for filetype/wildcard and/or end of directory*/
			do
			rc = FileSearch(&file,FILESEEK_PREV);
			while ((type[0]!='*') && (strncmp(&file.name[8],type,3)) && rc);

			/*update directory[] if file found*/
			if (rc)
			{
				for (i=DIRSIZE-1;i>0;i--)
					directory[i] = directory[i-1];

				strncpy(directory[0].name,file.name,8);
				directory[0].attributes = file.attributes;
				directory[0].entry = file.entry;
				directory[0].cluster = file.cluster;
			}
		}
		else/*just move pointer in window*/
			dirptr--;
	}
	else if (mode>=32)
	{//find entry beginnig with the given character
		i = 0;
		if (directory[0].name[0]) //check if any file is already displayed
		{
			//begin searching from the first displayed entry
			strncpy(file.name,directory[0].name,8);
			file.attributes = directory[0].attributes;
			file.entry = directory[0].entry;
			file.cluster = directory[0].cluster;

			seekmode = FILESEEK_NEXT; //search for the next entry
			/*fill directory with available files*/
			while (i<DIRSIZE)
			{
				if (FileSearch(&file,seekmode))
				{//entry found
					seekmode = FILESEEK_NEXT;
					if (file.entry==directory[0].entry) //the whole directory was traversed and we reached the starting point so there is no other files beginnig with the given character
					{
						if (directory[0].name[0]==mode) //if the first displayed entry begins with the given character then select it
							dirptr = 0;
						return;
					}

					if (file.name[0]==mode && ((type[0]=='*') || (strncmp(&file.name[8],type,3)==0))) // check filetype and the first character of the entry name
					{
						dirptr = 0;
						memset(directory,0,sizeof(directory)); //clear the display list
						//add found entry to the display list
						strncpy(directory[i].name,file.name,8);
						directory[i].attributes = file.attributes;
						directory[i].entry = file.entry;
						directory[i].cluster = file.cluster;
						i++;

						while (i<DIRSIZE) //search for the other files to display (only file type matters)
						{
							if (!FileSearch(&file,FILESEEK_NEXT))
								return; //the end of the directory has been reached

							if ((type[0]=='*') || (strncmp(&file.name[8],type,3)==0)) //check filetype
							{
								strncpy(directory[i].name,file.name,8);
								directory[i].attributes = file.attributes;
								directory[i].entry = file.entry;
								directory[i].cluster = file.cluster;
								i++;
							}
						}
					}
				}
				else
					seekmode = FILESEEK_START; //the end of the directory reached, start from the beginning
			}
		}
	}
}

/*insert floppy image pointed to to by global <file> into <drive>*/
void InsertFloppy(struct adfTYPE *drive)
{
	unsigned char i,j;
	unsigned char k,l;

	/*clear OSD and prepare progress bar*/
	OsdClear();
	OsdWrite(1,"     Inserting",0);
	OsdWrite(2,"     floppy...",0);
	strcpy(s,"[                  ]");

	k = 0;
	l = 1;
	/*fill cache*/
	for (i=0;i<160;i++)
	{
		k++;
		if (k==9)
		{
			k = 0;
			s[l++]='*';
			OsdWrite(4,s,0);
		}

		drive->cache[i] = file.cluster;
		for (j=0;j<11;j++)
			FileNextSector(&file);
	}

	/*copy name*/
	for (i=0;i<12;i++)
		drive->name[i]=file.name[i];

	/*initialize rest of struct*/
	drive->status = DSK_INSERTED;
	if (!(file.attributes&0x01))//read-only attribute
		drive->status |= DSK_WRITABLE;
	drive->clusteroffset=drive->cache[0];
	drive->sectoroffset=0;
	drive->track=0;
	drive->trackprev=-1;
	printf("Inserting floppy: \"%s\", attributes: %02X\r",file.name,file.attributes);
	printf("drive status: %02X\r",drive->status);
}

/*Handle an FPGA command*/
void HandleFpga(void)
{
	unsigned char  c1, c2;

	EnableFpga();
	c1 = SPI(0); //cmd request and drive number
	c2 = SPI(0); //track number
	SPI(0);
	SPI(0);
	SPI(0);
	SPI(0);
	DisableFpga();

	HandleFDD(c1,c2);

	UpdateDriveStatus();
}

void HandleFDD(unsigned char c1, unsigned char c2)
{
	unsigned char sel;
	floppy_drives = (c1 >> 4) & 0x03; //number of active floppy drives
	if (floppy_drives>1)
		floppy_drives = 1;

	if (c1 & CMD_RDTRK)
	{
		DISKLED_ON;
		sel = (c1 >> 6) & 0x03;
		df[sel].track = c2;
		ReadTrack( & df[sel]);
		DISKLED_OFF;
	}
	else if (c1 & CMD_WRTRK)
	{
		DISKLED_ON;
		sel = (c1 >> 6) & 0x03;
		df[sel].track = c2;
		WriteTrack( & df[sel]);
		DISKLED_OFF;
	}
}

void UpdateDriveStatus(void)
{
	EnableFpga();
	SPI(0x10);
	SPI(df[0].status | (df[1].status<<1));
	DisableFpga();
}

/*CheckTrack, respond with disk status*/
void CheckTrack(struct adfTYPE *drive)
{
	EnableFpga();
	SPI(0x00);
	SPI(0x00);
	SPI(0x00);
	SPI(drive->status);
	DisableFpga();
}

/*load kickstart rom*/
void SendFile(struct fileTYPE *file)
{
	unsigned char c1,c2;
	unsigned char j;
	unsigned short n;
	unsigned char *p;

	n = file->len/512;	//sector count (rounded up)
	while (n--)
	{
		/*read sector from mmc*/
		FileRead(file);

		do
		{
			/*read command from FPGA*/
			EnableFpga();
			c1 = SPI(0);
			c2 = SPI(0);
			SPI(0);
			SPI(0);
			SPI(0);
			SPI(0);
			DisableFpga();
		}
		while (!(c1&CMD_RDTRK));

		putchar('.');

		/*send sector to fpga*/
		EnableFpga();
		c1 = SPI(0);
		c2 = SPI(0);
		SPI(0);
		SPI(0);
		SPI(0);
		SPI(0);
		p=secbuf;
		j=128;

		do
		{
			SSPBUF=*(p++);
			while (!BF);
			SSPBUF=*(p++);
			while (!BF);
			SSPBUF=*(p++);
			while (!BF);
			SSPBUF=*(p++);
			while (!BF);
		}
		while (--j);

		DisableFpga();
		FileNextSector(file);
	}
}

/*configure FPGA*/
unsigned char ConfigureFpga(void)
{
	unsigned short t;
	unsigned char *ptr;

	/*reset FGPA configuration sequence*/
	PROG_B = 0;
	PROG_B = 1;

	/*now wait for INIT to go high*/
	t = 50000;
	while (!INIT_B)
		if (--t==0)
		{
			printf("FPGA init is NOT high!\r");
			FatalError(3);
			//return(0);
		}

		printf("FPGA init is high\r");

		if (DONE)
		{
			printf("FPGA done is high before configuration!\r");
			FatalError(3);
		}

		/*open bitstream file*/
		if (Open("MINIMIG1BIN")==0)
		{
			printf("No FPGA configuration file found!\r");
			FatalError(4);
		}

		printf("FPGA bitstream file opened\r");

		/*send all bytes to FPGA in loop*/
		t = 0;
		do
		{
			/*read sector if 512 (64*8) bytes done*/
			if (t%64==0)
			{
				if ((t>>9)&1)
					DISKLED_ON;
				else
					DISKLED_OFF;

				putchar('*');
				if (!FileRead(&file))
					return(0);
				ptr=secbuf;
			}

			/*send data in packets of 8 bytes*/
			ShiftFpga(*(ptr++));
			ShiftFpga(*(ptr++));
			ShiftFpga(*(ptr++));
			ShiftFpga(*(ptr++));
			ShiftFpga(*(ptr++));
			ShiftFpga(*(ptr++));
			ShiftFpga(*(ptr++));
			ShiftFpga(*(ptr++));
			t++;

			/*read next sector if 512 (64*8) bytes done*/
			if (t%64==0)
			{
				FileNextSector(&file);
			}
		}
		while (t<26549);

		printf("\rFPGA bitstream loaded\r");
		DISKLED_OFF;

		/*check if DONE is high*/
		if (DONE)
			return(1);
		else
		{
			printf("FPGA done is NOT high!\r");
			FatalError(5);
		}
		return 0;
}

/*read a track from disk*/
void ReadTrack(struct adfTYPE *drive)
{ //track number is updated in drive struct before calling this function

	unsigned char sector;
	unsigned char c1, c2, c3, c4;
	unsigned char dsksynch, dsksyncl;
	unsigned short n;

	/*display track number: cylinder & head*/
#ifdef DEBUG
	printf("*%d:", drive->track);
#endif

	if (drive->track != drive->trackprev)
	{ /*track step or track 0, start at beginning of track*/
		drive->trackprev = drive->track;
		sector = 0;
		file.cluster = drive->cache[drive->track];
		file.sec = drive->track * 11;
		drive->sectoroffset = sector;
		drive->clusteroffset = file.cluster;
	}
	else
	{ /*same track, start at next sector in track*/
		sector = drive->sectoroffset;
		file.cluster = drive->clusteroffset;
		file.sec = (drive->track*11) + sector;
	}

	EnableFpga();
	c1 = SPI(0); //read request signal
	c2 = SPI(0); //track number (cylinder & head)
	dsksynch = SPI(0); //disk sync high byte
	dsksyncl = SPI(0); //disk sync low byte
	c3 = 0x3F & SPI(0); //msb of mfm words to transfer
	c4 = SPI(0); //lsb of mfm words to transfer
	DisableFpga();

#ifdef DEBUG
	printf("(%d)[%02X%02X]:", c1>>6, dsksynch, dsksyncl);
#endif

	while (1)
	{
		FileRead(&file);

		EnableFpga();

		/*check if FPGA is still asking for data*/
		c1 = SPI(0); //read request signal
		c2 = SPI(0); //track number (cylinder & head)
		dsksynch = SPI(0); //disk sync high byte
		dsksyncl = SPI(0); //disk sync low byte
		c3 = SPI(0); //msb of mfm words to transfer
		c4 = SPI(0); //lsb of mfm words to transfer

        // workaround for Wiz'n'Liz and North&South (might brake other games)
        if ((dsksynch == 0x00 && dsksyncl == 0x00) || (dsksynch == 0x89 && dsksyncl == 0x14) || (dsksynch == 0xA1 && dsksyncl == 0x44))
        {
            dsksynch = 0x44;
            dsksyncl = 0x89;
        }
        // North&South: $A144
        // Wiz'n'Liz (Copy Lock): $8914
        // Prince of Persia: $4891
        // Commando: $A245

#ifdef DEBUG
		printf("%X:%02X%02X", sector, c3, c4);
#endif

		c3 &= 0x3F;

		//some loaders stop dma if sector header isn't what they expect
		//we don't check dma transfer count after sending every word
		//so the track can be changed while we are sending the rest of the previous sector
		//in this case let's start transfer from the beginning
		if (c2==drive->track)
			/*send sector if fpga is still asking for data*/
			if (c1 & CMD_RDTRK)
			{
				if (c3==0 && c4<4)
					SectorHeaderToFpga(c4, dsksynch, dsksyncl);
				else
				{
					n = SectorToFpga(sector, drive->track, dsksynch, dsksyncl);

#ifdef DEBUG // printing remaining dma count
					printf("-%04X", n);
#endif

					n--;
					c3 = (n>>8) & 0x3F;
					c4 = (unsigned char)n;

					if (c3==0 && c4<4)
					{
						SectorHeaderToFpga(c4, dsksynch, dsksyncl);
#ifdef DEBUG
						printf("+%X", c4);
#endif
					}
					else if (sector==10)
					{
						SectorGapToFpga();
#ifdef DEBUG
						printf("+++");
#endif
					}
				}
			}

			/*we are done accessing FPGA*/
			DisableFpga();

			//track has changed
			if (c2!=drive->track)
				break;

			//read dma request
			if (!(c1 & CMD_RDTRK))
				break;

			sector++;
			if (sector<11)
			{
				FileNextSector(&file);
			}
			else //go to the start of current track
			{
				sector = 0;
				file.cluster = drive->cache[drive->track];
				file.sec = drive->track * 11;
			}

			//remember current sector and cluster
			drive->sectoroffset = sector;
			drive->clusteroffset = file.cluster;

#ifdef DEBUG
			printf("->");
#endif
	}
#ifdef DEBUG
	printf(":OK\r");
#endif
}

unsigned char FindSync(struct adfTYPE * drive)
//this function reads data from fifo till it finds sync word
// or fifo is empty and dma inactive (so no more data is expected)
{
	unsigned char  c1, c2, c3, c4;
	unsigned short n;

	while (1)
	{
		EnableFpga();
		c1 = SPI(0); //write request signal
		c2 = SPI(0); //track number (cylinder & head)
		if (!(c1 & CMD_WRTRK))
			break;
		if (c2 != drive->track)
			break;
		SPI(0); //disk sync high byte
		SPI(0); //disk sync low byte
		c3 = SPI(0) & 0xBF; //msb of mfm words to transfer
		c4 = SPI(0); //lsb of mfm words to transfer

		if (c3==0 && c4==0)
			break;

		n = ((c3 & 0x3F) << 8) + c4;

		while (n--)
		{
			c3 = SPI(0);
			c4 = SPI(0);
			if (c3==0x44 && c4==0x89)
			{
				DisableFpga();
#ifdef DEBUG
				printf("#SYNC:");
#endif
				return 1;
			}
		}
		DisableFpga();
	} DisableFpga();
	return 0;
}

unsigned char GetHeader(unsigned char * pTrack, unsigned char * pSector)
//this function reads data from fifo till it finds sync word or dma is inactive
{
	unsigned char c, c1, c2, c3, c4;
	unsigned char i;
	unsigned char checksum[4];

	Error = 0;
	while (1)
	{
		EnableFpga();
		c1 = SPI(0); //write request signal
		c2 = SPI(0); //track number (cylinder & head)
		if (!(c1 & CMD_WRTRK))
			break;
		SPI(0); //disk sync high byte
		SPI(0); //disk sync low byte
		c3 = SPI(0); //msb of mfm words to transfer
		c4 = SPI(0); //lsb of mfm words to transfer

		if ((c3 & 0x3F) != 0 || c4 > 24)//remaining header data is 25 mfm words
		{
			c1 = SPI(0); //second sync lsb
			c2 = SPI(0); //second sync msb
			if (c1 != 0x44 || c2 != 0x89)
			{
				Error = 21;
				printf("\rSecond sync word missing...\r");
				break;
			}

			c = SPI(0);
			checksum[0] = c;
			c1 = (c&0x55)<<1;
			c = SPI(0);
			checksum[1] = c;
			c2 = (c&0x55)<<1;
			c = SPI(0);
			checksum[2] = c;
			c3 = (c&0x55)<<1;
			c = SPI(0);
			checksum[3] = c;
			c4 = (c&0x55)<<1;

			c = SPI(0);
			checksum[0] ^= c;
			c1 |= c&0x55;
			c = SPI(0);
			checksum[1] ^= c;
			c2 |= c&0x55;
			c = SPI(0);
			checksum[2] ^= c;
			c3 |= c&0x55;
			c = SPI(0);
			checksum[3] ^= c;
			c4 |= c&0x55;

			if (c1 != 0xFF)//always 0xFF
				Error = 22;
			else if (c2 > 159)//Track number (0-159)
				Error = 23;
			else if (c3 > 10)//Sector number (0-10)
				Error = 24;
			else if (c4 > 11 || c4==0)//Number of sectors to gap (1-11)
				Error = 25;

			if (Error)
			{
				printf("\rWrong header: %d.%d.%d.%d\r", c1, c2, c3, c4);
				break;
			}

#ifdef DEBUG
			printf("T%dS%d\r", c2, c3);
#endif

			*pTrack = c2;
			*pSector = c3;

			for (i = 0; i < 8; i++)
			{
				checksum[0] ^= SPI(0);
				checksum[1] ^= SPI(0);
				checksum[2] ^= SPI(0);
				checksum[3] ^= SPI(0);
			}

			checksum[0] &= 0x55;
			checksum[1] &= 0x55;
			checksum[2] &= 0x55;
			checksum[3] &= 0x55;

			c1 = (SPI(0)&0x55)<<1;
			c2 = (SPI(0)&0x55)<<1;
			c3 = (SPI(0)&0x55)<<1;
			c4 = (SPI(0)&0x55)<<1;

			c1 |= SPI(0)&0x55;
			c2 |= SPI(0)&0x55;
			c3 |= SPI(0)&0x55;
			c4 |= SPI(0)&0x55;

			if (c1!=checksum[0] || c2!=checksum[1] || c3!=checksum[2] || c4!=checksum[3])
			{
				Error = 26;
				break;
			}

			DisableFpga();
			return 1;
		}
		else //not enough data for header
			if ((c3&0x80)==0)//write dma is not active
			{
				Error = 20;
				break;
			}

			DisableFpga();
	}

	DisableFpga();
	return 0;
}

unsigned char GetData(void)
{
	unsigned char c, c1, c2, c3, c4;
	unsigned char i;
	unsigned char *p;
	unsigned short n;
	unsigned char checksum[4];

	Error = 0;
	while (1)
	{
		EnableFpga();
		c1 = SPI(0); //write request signal
		c2 = SPI(0); //track number (cylinder & head)
		if (!(c1 & CMD_WRTRK))
			break;
		SPI(0); //disk sync high byte
		SPI(0); //disk sync low byte
		c3 = SPI(0); //msb of mfm words to transfer
		c4 = SPI(0); //lsb of mfm words to transfer

		n = ((c3&0x3F)<<8) + c4;

		if (n >= 0x204)
		{
			c1 = (SPI(0)&0x55)<<1;
			c2 = (SPI(0)&0x55)<<1;
			c3 = (SPI(0)&0x55)<<1;
			c4 = (SPI(0)&0x55)<<1;

			c1 |= SPI(0)&0x55;
			c2 |= SPI(0)&0x55;
			c3 |= SPI(0)&0x55;
			c4 |= SPI(0)&0x55;

			checksum[0] = 0;
			checksum[1] = 0;
			checksum[2] = 0;
			checksum[3] = 0;

			/*odd bits of data field*/
			i = 128;
			p = secbuf;
			do
			{
				c = SPI(0);
				checksum[0] ^= c;
				*p++ = (c&0x55)<<1;
				c = SPI(0);
				checksum[1] ^= c;
				*p++ = (c&0x55)<<1;
				c = SPI(0);
				checksum[2] ^= c;
				*p++ = (c&0x55)<<1;
				c = SPI(0);
				checksum[3] ^= c;
				*p++ = (c&0x55)<<1;
			}
			while (--i);

			/*even bits of data field*/
			i = 128;
			p = secbuf;
			do
			{
				c = SPI(0);
				checksum[0] ^= c;
				*p++ |= c&0x55;
				c = SPI(0);
				checksum[1] ^= c;
				*p++ |= c&0x55;
				c = SPI(0);
				checksum[2] ^= c;
				*p++ |= c&0x55;
				c = SPI(0);
				checksum[3] ^= c;
				*p++ |= c&0x55;
			}
			while (--i);

			checksum[0] &= 0x55;
			checksum[1] &= 0x55;
			checksum[2] &= 0x55;
			checksum[3] &= 0x55;

			if (c1 != checksum[0] || c2 != checksum[1] || c3 != checksum[2] || c4 != checksum[3])
			{
				Error = 29;
				break;
			}

			DisableFpga();
			return 1;
		}
		else //not enough data in fifo
			if ((c3 & 0x80)==0)//write dma is not active
			{
				Error = 28;
				break;
			}

			DisableFpga();
	}
	DisableFpga();
	return 0;
}

void WriteTrack(struct adfTYPE *drive)
{
	unsigned char sector;
	unsigned char Track;
	unsigned char Sector;

	//setting file pointer to begining of current track
	file.cluster = drive->cache[drive->track];
	file.sec = drive->track * 11;
	sector = 0;

	drive->trackprev = drive->track + 1; //just to force next read from the start of current track

#ifdef DEBUG
	printf("*%d:\r", drive->track);
#endif

	while (FindSync(drive))
	{
		if (GetHeader(&Track, &Sector))
		{
			if (Track==drive->track)
			{
				while (sector != Sector)
				{
					if (sector < Sector)
					{
						FileNextSector(&file);
						sector++;
					}
					else
					{
						file.cluster = drive->cache[drive->track];
						file.sec = drive->track * 11;
						sector = 0;
					}
				}

				if (GetData())
				{
					if (drive->status & DSK_WRITABLE)
						FileWrite(&file);
					else
					{
						Error = 30;
						printf("Write attempt to protected disk!\r");
					}
				}
			}
			else
				Error = 27; //track number reported in sector header is not the same as current drive track
		} if (Error)
		{
			printf("WriteTrack: error %d\r", Error);
			ErrorMessage("  WriteTrack", Error);
		}
	}

}

unsigned char Open(const unsigned char *name)
{
	unsigned char i,j;

	if (FileSearch(&file,0))
	{
		do
		{
			i=0;
			for (j=0;j<11;j++)
				if (file.name[j]==name[j])
					i++;
			if (i==11)
			{
				printf("file \"%s\" found\r",name);
				return 1;
			}
		}
		while (FileSearch(&file,1));
	}
	printf("file \"%s\" not found\r",name);
	return 0;
}

/*this function sends the data in the sector buffer to the FPGA, translated
into an Amiga floppy format sector
sector is the sector number in the track
track is the track number
note that we do not insert clock bits because they will be stripped
by the Amiga software anyway*/
unsigned short SectorToFpga(unsigned char sector, unsigned char track, unsigned char dsksynch, unsigned char dsksyncl)
{
	unsigned char c, i;
	unsigned char csum[4];
	unsigned char *p;
	unsigned char c3, c4;

	/*preamble*/
	SPI(0xAA);
	SPI(0xAA);
	SPI(0xAA);
	SPI(0xAA);

	/*synchronization*/
	SPI(dsksynch);
	SPI(dsksyncl);
	SPI(dsksynch);
	SPI(dsksyncl);

	/*clear header checksum*/
	csum[0]=0;
	csum[1]=0;
	csum[2]=0;
	csum[3]=0;

	/*odd bits of header*/
	c=0x55;
	csum[0]^=c;
	SPI(c);
	c=(track>>1)&0x55;
	csum[1]^=c;
	SPI(c);
	c=(sector>>1)&0x55;
	csum[2]^=c;
	SPI(c);
	c=((11-sector)>>1)&0x55;
	csum[3]^=c;
	SPI(c);

	/*even bits of header*/
	c=0x55;
	csum[0]^=c;
	SPI(c);
	c=track&0x55;
	csum[1]^=c;
	SPI(c);
	c=sector&0x55;
	csum[2]^=c;
	SPI(c);
	c=(11-sector)&0x55;
	csum[3]^=c;
	SPI(c);

	/*sector label and reserved area (changes nothing to checksum)*/
	for (i=0;i<32;i++)
		SPI(0xAA);

	/*checksum over header*/
	SPI((csum[0]>>1)|0xaa);
	SPI((csum[1]>>1)|0xaa);
	SPI((csum[2]>>1)|0xaa);
	SPI((csum[3]>>1)|0xaa);
	SPI(csum[0]|0xaa);
	SPI(csum[1]|0xaa);
	SPI(csum[2]|0xaa);
	SPI(csum[3]|0xaa);

	/*calculate data checksum*/
	csum[0]=0;
	csum[1]=0;
	csum[2]=0;
	csum[3]=0;
	i=128;
	p=secbuf;
	do
	{
		c=*(p++);
		csum[0]^=c>>1;
		csum[0]^=c;
		c=*(p++);
		csum[1]^=c>>1;
		csum[1]^=c;
		c=*(p++);
		csum[2]^=c>>1;
		csum[2]^=c;
		c=*(p++);
		csum[3]^=c>>1;
		csum[3]^=c;
	}
	while (--i);
	csum[0]&=0x55;
	csum[1]&=0x55;
	csum[2]&=0x55;
	csum[3]&=0x55;


	/*checksum over data*/
	SPI((csum[0]>>1)|0xaa);
	SPI((csum[1]>>1)|0xaa);
	SPI((csum[2]>>1)|0xaa);
	SPI((csum[3]>>1)|0xaa);
	SPI(csum[0]|0xaa);
	SPI(csum[1]|0xaa);
	SPI(csum[2]|0xaa);
	SPI(csum[3]|0xaa);

	/*odd bits of data field*/
	i=128;
	p=secbuf;
	do
	{
		c=*(p++);
		c>>=1;
		c|=0xaa;
		SSPBUF=c;
		while (!BF);

		c=*(p++);
		c>>=1;
		c|=0xaa;
		SSPBUF=c;
		while (!BF);

		c=*(p++);
		c>>=1;
		c|=0xaa;
		SSPBUF=c;
		while (!BF);

		c=*(p++);
		c>>=1;
		c|=0xaa;
		SSPBUF=c;
		while (!BF);
	}
	while (--i);

	/*even bits of data field*/
	i=128;
	p=secbuf;
	do
	{
		c=*(p++);
		SSPBUF=c|0xaa;
		while (!BF);
		c=*(p++);
		SSPBUF=c|0xaa;
		while (!BF);
		c=*(p++);
		SSPBUF=c|0xaa;
		while (!BF);
		c3 = SSPBUF;
		c=*(p++);
		SSPBUF=c|0xaa;
		while (!BF);
		c4 = SSPBUF;
	}
	while (--i);

	return((c3<<8)|c4);
}

void SectorGapToFpga()
{
	unsigned char i;
	i = 175;
	do
	{
		SPI(0xAA);
		SPI(0xAA);
		SPI(0xAA);
		SPI(0xAA);
	}
	while (--i);
}

void SectorHeaderToFpga(unsigned char n, unsigned char dsksynch, unsigned char dsksyncl)
{
	if (n)
	{
		SPI(0xAA);
		SPI(0xAA);

		if (--n)
		{
			SPI(0xAA);
			SPI(0xAA);

			if (--n)
			{
				SPI(dsksynch);
				SPI(dsksyncl);
			}
		}
	}
}
