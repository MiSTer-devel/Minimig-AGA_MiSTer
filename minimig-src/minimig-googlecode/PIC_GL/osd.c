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

This is the Minimig OSD (on-screen-display) handler.

29-12-2006	- created
30-12-2006	- improved and simplified

-- JB --
2009-02-03	- added arrows characters (codes 240-243)
			- added full keyboard support
			- added configuration functions for floppy, scanline and chipset
			
-- Goran Ljubojevic --
2009-11-13	- Constants moved to header file
			- OSD size defined lines and bytes
			- Code cleanup
			- OSD Font moved to separate file for easier change
2009-12-05	- OsdGetCtrl, repeat - changed to short to save memory and smaller code
			- OsdWrite added switch for new FPGA support
2010-08-21	- Support for new YQ100818 core
			- Hires OSD display restored
2010-08-26	- Added firmwareConfiguration.h
2010-09-07	- Added Configure AutoFire function
			- Modified OSD Enable to allow Keyboard disabled when OSD visible
			- TODO: Define Wait Vertical Blank For OSD Update
			- TODO: Fix OsdGetCtrl repeat and delays check ARM source
			- Renamed config IDE define
			- Renamed config chipset define 
2010-09-12	- Keycode table reduced in size
2010-10-05	- Fixed key repeat and delay for new core FYQ100818
*/

#include <pic18.h>
#include "firmwareConfiguration.h"
#include "hardware.h"
#include "osd.h"
#include "osdFont.h"

//Amiga keyboard codes to ASCII convertion table
#if	defined(PGL100818)
const char keycode_table[64] =
{
	0x0,'1','2','3','4','5','6','7','8','9','0',0x0,0x0,0x0,0x0,0x0,
	'Q','W','E','R','T','Y','U','I','O','P',0x0,0x0,0x0,0x0,0x0,0x0,
	'A','S','D','F','G','H','J','K','L',0x0,0x0,0x0,0x0,0x0,0x0,0x0,
	0x0,'Z','X','C','V','B','N','M',0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0
};
#else
const char keycode_table[128] =
{
	0x0,'1','2','3','4','5','6','7','8','9','0',0x0,0x0,0x0,0x0,0x0,
	'Q','W','E','R','T','Y','U','I','O','P',0x0,0x0,0x0,0x0,0x0,0x0,
	'A','S','D','F','G','H','J','K','L',0x0,0x0,0x0,0x0,0x0,0x0,0x0,
	0x0,'Z','X','C','V','B','N','M',0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,
	0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,
	0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,
	0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,
	0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0
};
#endif


// write a null-terminated string <s> to the OSD buffer starting at line <n>
void OsdWrite(unsigned char n, const unsigned char *s, char invert)
{
	unsigned short byte_cnt;
	unsigned char b;
	const unsigned char *p;

	// select OSD SPI device
	EnableOsd();

	// select buffer and line to write to
	if (invert)
	{	SPI(OSDCMDWRITE|0x10|n);	}
	else
	{	SPI(OSDCMDWRITE|n);	}

	// Start Counting bytes
	byte_cnt = 0;
	
	// send all characters in string to OSD
	while(1)
	{
		b=*(s++);

		// end of string
		if (0 == b)
		{	break;	}
		else if (0x0d == b || 0x0a == b)	//cariage return / linefeed, go to next line
		{
			// Clear rest of line
			for(; byte_cnt < OSD_LINE_BYTES; byte_cnt++)
			{	SPI(0x00);	}

			// Start Counting bytes
			byte_cnt = 0;
			
			// increment line counter
			if(++n >= OSD_NO_LINES)
			{	n=0;	}

			// send new line number to OSD
			DisableOsd();
			EnableOsd();
			SPI(OSDCMDWRITE|n);
		}
		else
		{
			#if	defined(PGL090421) || defined(PGL090911) || defined(PGL100818)
				// Send Space
				SPI(0x00);
	
				// Send Character each byte
				p=&charfont[b][0];
				SPI(*(p++));
				SPI(*(p++));
				SPI(*(p++));
				SPI(*(p++));
				SPI(*(p++));
				
				byte_cnt += 6;
	
			#elif	defined(PGL091224) 
				// Send Space
				SPI(0x00);
				SPI(0x00);
	
				// Send Character each byte
				p=&charfont[b][0];
				SPI(*(p));
				SPI(*(p++));
	
				SPI(*(p));
				SPI(*(p++));
				
				SPI(*(p));
				SPI(*(p++));
				
				SPI(*(p));
				SPI(*(p++));
				
				SPI(*(p));
				SPI(*(p++));
				
				byte_cnt += 12;
			#endif
		}
	}
	
	// Clear rest of line
	for(; byte_cnt < OSD_LINE_BYTES; byte_cnt++)
	{	SPI(0x00);	}
	
	// deselect OSD SPI device
	DisableOsd();
}


// clear buffer <c>
void OsdClear(void)
{
	unsigned short n;

	// select OSD SPI device
	EnableOsd();

	// select buffer to write to
	SPI(OSDCMDWRITE|0x18);

	// clear buffer
	for(n=0; n < (OSD_LINE_BYTES * OSD_NO_LINES); n++)
	{	SPI(0x00);	}

	// deselect OSD SPI device
	DisableOsd();
}

// enable displaying of OSD
#if		defined(PGL090421) || defined(PGL090911) || defined(PGL091224)

void OsdEnable(void)
{
	OsdCommand(OSDCMDENABLE);
}

#elif	defined(PGL100818)

void OsdEnable(unsigned char mode)
{
	OsdCommand(OSDCMDENABLE | (mode & DISABLE_KEYBOARD));
}

#endif

#ifdef AUTOFIRE_RATE_KEYBOARD_SELECT

void ConfigAutofire(unsigned char autofire)
{
	OsdCommand(OSDCMDAUTOFIRE | (autofire & 0x03));		
}

#endif


// disable displaying of OSD
void OsdDisable(void)
{
	OsdCommand(OSDCMDDISABLE);
}

void OsdReset(unsigned char boot)
{
	OsdCommand(OSDCMDRST | (boot&0x01));
}

void ConfigFilter(unsigned char lores, unsigned char hires)
{
	OsdCommand(OSDCMDCFGFLT | ((hires&0x03)<<2) | (lores&0x03));
}

void ConfigMemory(unsigned char memory)
{
	OsdCommand(OSDCMDCFGMEM | (memory&0x0F));
}

void ConfigChipset(unsigned char chipset)
{
	#if	defined(PGL090421) || defined(PGL090911) || defined(PGL091224)
		OsdCommand(OSDCMDCFGCPU | (chipset&0x0F));
	#elif	defined(PGL100818) 
		OsdCommand(OSDCMDCFGCHP | (chipset&0x0F));
	#endif
}

void ConfigFloppy(unsigned char drives, unsigned char speed)
{
	OsdCommand(OSDCMDCFGFLP | ((drives&0x03)<<2) | (speed&0x03));
}

void ConfigScanline(unsigned char scanline)
{
	OsdCommand(OSDCMDCFGSCL | (scanline&0x0F));
}

void ConfigIDE(unsigned char gayle, unsigned char master, unsigned char slave)
{
	#if	defined(PGL090421) || defined(PGL090911) || defined(PGL091224)
		OsdCommand(OSDCMDENAHDD | (slave ? 4 : 0) | (master ? 2 : 0) | (gayle ? 1 : 0));
	#elif	defined(PGL100818) 
		OsdCommand(OSDCMDCFGIDE | (slave ? 4 : 0) | (master ? 2 : 0) | (gayle ? 1 : 0));
	#endif
}

// get key status
unsigned char OsdGetCtrl(void)
{
	static unsigned char c2;
	static unsigned short repeat;
	unsigned char c1,c;

	// send command and get current ctrl status
	c1 = OsdCommand(OSDCMDREAD);

	// add front menu button
	if (CheckButton())
	{	c1 = KEY_MENU;	}

	// generate normal "key-pressed" event
	c = 0;
	if (c1!=c2)
	{	c = c1;	}

	c2 = c1;

	/*generate repeat "key-pressed" events
	do not for menu button*/
	#if	defined(PGL100818)
		if (c1 & KEY_UPSTROKE)
		{	repeat = GetTimer(REPEATDELAY);		}
		else if (CheckTimer(repeat))
		{
			repeat = GetTimer(REPEATRATE);
			if (c1==KEY_UP || c1==KEY_DOWN || GetASCIIKey(c1))
			{	c = c1;	}
		}
	#else
		if (!c1)
		{	repeat = GetTimer(REPEATDELAY);		}
		else if (CheckTimer(repeat))
		{
			repeat = GetTimer(REPEATRATE);
			if (c1==KEY_UP || c1==KEY_DOWN || GetASCIIKey(c1))
			{	c = c1;	}
		}
	#endif

	// return events
	return(c);
}

unsigned char GetASCIIKey(unsigned char keycode)
{
	#if	defined(PGL100818)
	return keycode & KEY_UPSTROKE ? 0 : keycode_table[keycode&0x3F];
	#else
	return keycode & KEY_UPSTROKE ? 0 : keycode_table[keycode&0x7F];
	#endif
}


