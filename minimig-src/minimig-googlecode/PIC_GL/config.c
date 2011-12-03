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

Minimig configuration Load/Save

-- Goran Ljubojevic ---
2009-11-21	- Extracted from main
2009-11-26	- Default EEPROM Config (disabled, idea is to clear config on flash)
2009-11-29	- Fixed loading saving configuration, functions for loading/saving extracted
2009-11-30	- Defaults for kickstart and Action Replay Added
2009-12-04	- IDE Config Load/Save Added
			- Code Cleaned a bit
2009-12-24	- Fixed loading saving chipset settings for minimg FPGA firmware PYQ090911
2010-08-26	- Added firmwareConfiguration.h
2010-09-07	- Added default FPGA file name depending on PIC code version
2010-09-12	- Default EEPROM config enabled and set for default config to avoid issues on flash
*/

#include <pic18.h>
#include <stdio.h>
#include <string.h>
#include "firmwareConfiguration.h"
#include "fat16.h"
#include "adf.h"
#include "hdd.h"
#include "config.h"

// Default EEprom config, clear on flash
__EEPROM_DATA(0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0);	// Empty
__EEPROM_DATA(0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0);	// Empty
__EEPROM_DATA(0x0,0x0,0x4,0x0,0x1,0x3,0x1,0x0);	// Filter LoRes, Filter HiRes, Memory, Chipset, Floppy Speed, Floppy Drives, Ar Enable, Scan Line
__EEPROM_DATA('K','I','C','K',' ',' ',' ',' ');	// Kick name(8)
__EEPROM_DATA('R','O','M',0x0,0x0,0x1,0x1,'H');	// Kick name(4), IDE enabled, IDE Master, IDE Slave, HDFile0(1) 
__EEPROM_DATA('D','F','I','L','E','0','0','H'); // HDFile0(8)
__EEPROM_DATA('D','F',0x0,'H','D','F','I','L'); // HDFile0(3), HDFile1(5) 
__EEPROM_DATA('E','0','1','H','D','F',0x0,0x0); // HDFile1(7)
__EEPROM_DATA(0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0);	// Empty
__EEPROM_DATA(0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0);	// Empty
__EEPROM_DATA(0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0);	// Empty
__EEPROM_DATA(0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0);	// Empty
__EEPROM_DATA(0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0);	// Empty
__EEPROM_DATA(0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0);	// Empty
__EEPROM_DATA(0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0);	// Empty
__EEPROM_DATA(0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0);	// Empty
__EEPROM_DATA(0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0);	// Empty
__EEPROM_DATA(0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0);	// Empty
__EEPROM_DATA(0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0);	// Empty
__EEPROM_DATA(0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0);	// Empty
__EEPROM_DATA(0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0);	// Empty
__EEPROM_DATA(0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0);	// Empty
__EEPROM_DATA(0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0);	// Empty
__EEPROM_DATA(0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0);	// Empty
__EEPROM_DATA(0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0);	// Empty
__EEPROM_DATA(0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0);	// Empty
__EEPROM_DATA(0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0);	// Empty
__EEPROM_DATA(0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0);	// Empty
__EEPROM_DATA(0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0);	// Empty
__EEPROM_DATA(0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0);	// Empty
__EEPROM_DATA(0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0);	// Empty
__EEPROM_DATA(0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0);	// Empty

// Current config in ram
struct configType	config;

// Default FPGA file name
#if defined(PGL090421) && defined(USE_CORE_SPECIFIC_FILENAME)
	const unsigned char defFPGAName[]	= "YQ090421BIN";
#elif defined(PGL090911) && defined(USE_CORE_SPECIFIC_FILENAME)
	const unsigned char defFPGAName[]	= "YQ090911BIN";
#elif defined(PGL091224) && defined(USE_CORE_SPECIFIC_FILENAME)
	const unsigned char defFPGAName[]	= "YQ091224BIN";
#elif defined(PGL100818) && defined(USE_CORE_SPECIFIC_FILENAME)
	const unsigned char defFPGAName[]	= "YQ100818BIN";
#else
	const unsigned char defFPGAName[]	= "MINIMIG1BIN";
#endif

const unsigned char defKickName[]	= "KICK    ROM";
const unsigned char defARName[] 	= "AR3     ROM";
const unsigned char	defHDFileName[]	= "HDFILE%02dHDF";

// Default file extensions
const unsigned char defFloppyExt[]		= "ADF";	// Defult floppy extension
const unsigned char defRomExt[]			= "ROM";	// Defult rom extension
const unsigned char defHardDiskExt[]	= "HDF";	// Defult hard disk file extension
const unsigned char defCoreExt[]		= "BIN";	// Defult core extension


void LoadConfiguration(void)
{
	char i;
	char ts[12];

	//Get Default Kickstart
	GetConfigStringValue(EEPROM_KICKNAME, config.kickname, defKickName, 12);
	
	#ifdef CONFIG_DEBUG
	printf("Config Kickstart from eeprom: %.8s.%.3s\r\n", config.kickname, &config.kickname[8]);
	#endif

	//read video interpolation filter configuration for low resolution screen modes
	config.filter_lores = GetConfigValue(EEPROM_FILTER_LORES, 0x03, 0x00);

	//read video interpolation filter configuration for high resolution screen modes
	config.filter_hires = GetConfigValue(EEPROM_FILTER_HIRES, 0x03, 0x00);

	//read memory configuration
	config.memory = GetConfigValue(EEPROM_MEMORY, 0x0F, 0x05);

	//read CPU and chipset configuration
	config.chipset = GetConfigValue(EEPROM_CHIPSET, 0x0F, 0x00);

	//read floppy speed configuration
	config.floppy_speed = GetConfigValue(EEPROM_FLOPPY_SPEED, 0x03, 0x00);

	//read floppy drives configuration
	config.floppy_drives = GetConfigValue(EEPROM_FLOPPY_DRIVES, MAX_FLOPPY_DRIVES-1, 0x00);

	//read action replay configuration
	config.ar3 = GetConfigValue(EEPROM_AR3_ENABLED, 0x01, 0x01);

	//read scanline configuration
	config.scanline = GetConfigValue(EEPROM_SCANLINE, 0x03, 0x00);
	
	//read ide configuration
	config.ide = GetConfigValue(EEPROM_IDE_ENABLED, 0x01, 0x00);

	i=0;
	do
	{
		//read IDE configuration (Master, Slave)
		hdf[i].enabled = GetConfigValue(EEPROM_IDE_PORTS + i, 0x01, 0x00);

		// Create Default HD File Name
		sprintf(ts, defHDFileName, i);
		
		//read HD File Name (Master, Slave)
		GetConfigStringValue(EEPROM_IDE_HDFILES + (i*12), hdf[i].file.name, ts, 12);
		
		#ifdef CONFIG_DEBUG
		printf("Config HD File from eeprom: %.8s.%.3s\r\n", hdf[i].file.name, &hdf[i].file.name[8]);
		#endif
	}
	while((++i) < 2);
}



void SaveConfiguration(void)
{
	char i;

	//write kickstart file name
	SaveConfigValues(EEPROM_KICKNAME, config.kickname, 12);
	
	//write video interpolation filter configuration for low resolution screen modes
	SaveConfigValue(EEPROM_FILTER_LORES, config.filter_lores);

	//write video interpolation filter configuration for high resolution screen modes
	SaveConfigValue(EEPROM_FILTER_HIRES, config.filter_hires);

	//write memory configuration
	SaveConfigValue(EEPROM_MEMORY, config.memory);

	//write CPU and chipset configuration
	SaveConfigValue(EEPROM_CHIPSET, config.chipset);

	//write floppy speed configuration
	SaveConfigValue(EEPROM_FLOPPY_SPEED, config.floppy_speed);

	//write floppy drives configuration
	SaveConfigValue(EEPROM_FLOPPY_DRIVES, config.floppy_drives);

	//write action replay configuration
	SaveConfigValue(EEPROM_AR3_ENABLED, config.ar3);
	
	//write scanline configuration
	SaveConfigValue(EEPROM_SCANLINE, config.scanline);
	
	//write IDE configuration
	SaveConfigValue(EEPROM_IDE_ENABLED, config.ide);

	i=0;
	do
	{
		// write IDE ports (Master, Slave)
		SaveConfigValue(EEPROM_IDE_PORTS+i, hdf[i].enabled);
		// write IDE HD File Names (Master, Slave)
		SaveConfigValues(EEPROM_IDE_HDFILES + (i*12), hdf[i].file.name, 12);
	}
	while ((++i)<2);
}

void SaveConfigValue(unsigned char address, unsigned char value)
{
	if (value != eeprom_read(address))
	{	eeprom_write(address,value);	}
}

void SaveConfigValues(unsigned char address, unsigned char *values, unsigned char count)
{
	do
	{	SaveConfigValue(address++, *(values++));	}
	while(--count);
}


void GetConfigStringValue(unsigned char address, unsigned char* value, const unsigned char *def, unsigned char count)
{
	unsigned char i;
	unsigned char c;

	for (i=0;i < count;i++)
	{
		c = eeprom_read(address+i);
		//only 0-9,A-Z and space allowed, and \0 for zero terminated strings
		if ( 0==c || (c>=32 && c<=127))
		{	value[i] = c;	}
		else
		{
			#ifdef CONFIG_DEBUG
			printf("Illegal char 0x%02X at %d reading eeprom string!\r\n",c,i);
			#endif
			//if illegal character detected revert to default
			strncpy(value,def,count);
			break;
		}
	}
	
	// Check if string empty, copy default value
	if(!value[0])
	{	strncpy(value,def,count);	}
}

unsigned char GetConfigValue(unsigned char address, unsigned char max, unsigned char def)
{
	if(max < eeprom_read(address))
	{	return def;	}
	else
	{	return eeprom_read(address);	}
}

