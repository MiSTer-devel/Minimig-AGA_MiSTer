#ifndef FIRMWARECONFIGURATION_H_INCLUDED
#define FIRMWARECONFIGURATION_H_INCLUDED

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

Firmware configuration for different versions of minimig fpga firmwares
This file needs to be included in all c files

-- Goran Ljubojevic ---
2010-08-26	- First version extracted definitions extacted from hardware.h
2010-10-04	- Copying config values from other files
*/

// To String helper define
#define _DEF_TO_STRING(str)	#str
#define DEF_TO_STRING(str)	_DEF_TO_STRING(str)

// PIC firmware revision definition
// Each firmware definition is linked to FPGA revision firmware
// Note only one firmware can be uncommented at the time because 
// other files are conditionaly compiled 

// This is for FPGA revision YQ090421
// FPGA source is available here: http://code.google.com/p/minimig/source/browse/#svn/tags/YQ090421
//								  http://code.google.com/p/minimig/downloads/detail?name=minimig_source_YQ090421.zip&can=2&q=
// FPGA binary is available here: http://code.google.com/p/minimig/downloads/detail?name=minimig_build_YQ090421.zip&can=2&q=
//#define	PGL090421	PGL090421


// This is for FPGA revision YQ090911
// FPGA source is available here: http://code.google.com/p/minimig/source/browse/#svn/tags/YQ090911
// FPGA binary is available here: http://code.google.com/p/minimig/downloads/detail?name=minimig_YQ090911.zip&can=2&q=
//#define	PGL090911	PGL090911


// This is for FPGA revision YQ091224
// FPGA source is available here: 
// FPGA binary is available here: http://code.google.com/p/minimig/downloads/detail?name=FYQ091224.zip&can=2&q=
//#define	PGL091224	PGL091224

// This is for FPGA revision FYQ100818
// FPGA binary is available here: http://code.google.com/p/minimig/downloads/detail?name=FYQ100818.zip&can=2&q=
#define	PGL100818	PGL100818



// Each revision of firmware has different set of features on fpga core
// depending on that there is set of different features in pic firmware
#if	defined(PGL090421)
	//TODO: Define features
#elif	defined(PGL090911)
	//TODO: Define features
	// FAT32 and SDHC
#elif	defined(PGL091224)
	//TODO: Define features
	// FAT32 and SDHC

	// Enable / Disable HDD support
	#define	HDD_SUPPORT_ENABLE

	// Enables / Disables Alternate core loading
	#define ALTERNATE_CORES

#elif	defined(PGL100818)
	//TODO: Define features
	// FAT32 and SDHC
	
	// Enable / Disable HDD support
	#define	HDD_SUPPORT_ENABLE

	// Enables / Disables Alternate core loading
	// Note: You can use this feature if you disable 
	// turbo mode selection because there is not enough memory on pic flash
	//#define ALTERNATE_CORES

	// Enable / Disable Joystick autofire mode select through keyboard
	// lctrl+lalt+NumPad0 - switches autofire rate
	#define AUTOFIRE_RATE_KEYBOARD_SELECT
	
	// Enable / Disable Turbo mode select through keyboard
	// lctrl+lalt+NumPad+ - switches on the turbo mode
	// lctrl+lalt+NumPad- - switches off the turbo mode
	#define TURBO_MODE_KEYBOARD_SELECT
#endif

// Enable/Disable Use file name for sepecific core version instead default minimig1.bin
//#define USE_CORE_SPECIFIC_FILENAME


#endif /*FIRMWARECONFIGURATION_H_INCLUDED*/
