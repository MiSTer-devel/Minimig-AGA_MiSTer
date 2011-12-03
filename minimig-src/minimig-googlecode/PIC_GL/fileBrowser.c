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

-- Goran Ljubojevic --
2009-08-30	- separated fileBrowser.c/fileBrowser.h to overcome compiler ram issues
2009-09-06	- ScrollDir now uses memcpy instead manual dir entry copy to save rom space 
2009-09-08	- ScrollDir uses direct structure copy beacuse directory is list of file entries smaller memory footprint
2009-10-15	- Removed extern string buffer reference defined in main
2009-12-13	- Fixed ScrollDir when searching for file begining with specific character 
2010-08-21	- Directory displayed with "<dir>" prefix instead only "d"
			- String buffer for directory write depends on OSD line length now
2010-08-26	- Added firmwareConfiguration.h
2010-09-07	- Modified directory list display
			- Added handling for different OSD line size
*/

#include <pic18.h>
#include <stdio.h>
#include <string.h>
#include "firmwareConfiguration.h"
#include "hardware.h"
#include "osd.h"
#include "fat16.h"
#include "fileBrowser.h"
#include "osdFont.h"


unsigned char dirptr;						// pointer into directory array
bdata struct fileTYPE directory[DIRSIZE];	// directory array 

const unsigned char defDirMarker[] = "<dir> ";	// Default directory marker

// print the contents of directory[] and the pointer dirptr onto the OSD
void PrintDir(void)
{
	unsigned char i;

	// Define string buffer needed +1 char for \0
	unsigned char s[(OSD_LINE_BYTES / (OSD_FONT_CHAR_WIDTH+OSD_FONT_CHAR_SPACING))+1];

	if (0 == directory[0].name[0])
	{
		OsdWrite(0,"   No files!",1);
		return;
	}

	for(i=0;i < DIRSIZE;i++)
	{
		// Clear temp string and terminate
		memset(s,' ',sizeof(s));
		s[sizeof(s)-1] = 0;

		// Display Entry
		if (directory[i].name[0])
		{	
			// Read dir Entry over again to get LFN
			GetDirectoryEntry(&directory[i], &currentDir, DIRECTORY_BROWSE_CURRENT);

			// Mark directory
			if(directory[i].attributes & FAT_ATTRIB_DIR)
			{	strcpy(s,defDirMarker);	}
			
			// Copy name for display
			if(longFilename[0])
			{
				strncpy(
					&s[sizeof(defDirMarker)-1],
					longFilename,
					sizeof(s)-sizeof(defDirMarker)-2
				);
			}
			else
			{
				strncpy(
					&s[sizeof(defDirMarker)-1],
					directory[i].name,
					sizeof(s)-sizeof(defDirMarker)-2
				);
			}
		}

		OsdWrite(i, s, i==dirptr);
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

	if (DIRECTORY_BROWSE_START == mode)
	{
		// Reset Directory pointer
		dirptr = 0;
		
		// Clear All directory entries
		memset(directory,0,sizeof(directory));

		// reset directory to the beginning
		i = 0;
		seekmode = DIRECTORY_BROWSE_START;

		// fill directory with available files
		while (i < DIRSIZE)
		{
			// search file
			if (!GetDirectoryEntry(&file, &currentDir, seekmode)) 
			{	break;	}

			seekmode = DIRECTORY_BROWSE_NEXT;

			// Check for valid entry, directory or required file type
			if ((file.attributes & FAT_ATTRIB_DIR) || (type[0]=='*') || (0 == strncmp(&file.name[8],type,3)) )
			{
				directory[i] = file;
				i++;
			}
		}
	}

	else if (DIRECTORY_BROWSE_NEXT == mode)
	{
		// scroll down
		// pointer is at bottom of directory window
		if (dirptr >= DIRSIZE-1)
		{
			file = directory[DIRSIZE-1];

			// search next file and check for filetype/wildcard and/or end of directory
			do
			{
				rc = GetDirectoryEntry(&file, &currentDir, DIRECTORY_BROWSE_NEXT);

				// Exit if directory we are going to display them too
				if ((file.attributes & FAT_ATTRIB_DIR) && rc)
				{	break;	}
			}
			while ((type[0]!='*') && (0 != strncmp(&file.name[8],type,3)) && rc);

			// update directory[] if file found
			if (rc)
			{
				// Move Directory entries up
				for (i=0; i < (DIRSIZE-1); i++)
				{	directory[i] = directory[i+1];	}
				// Fill Last Entry in dir list
				directory[DIRSIZE-1] = file;
			}
		}
		else
		{
			// just move pointer in window
			dirptr++;
			if (0 == directory[dirptr].name[0])
			{	dirptr--;	}
		}
	}
	else if (DIRECTORY_BROWSE_PREV == mode)
	{
		// scroll up
		// pointer is at top of directory window
		if (0 == dirptr)
		{
			file = directory[0];

			// search previous file and check for filetype/wildcard and/or end of directory
			do
			{
				rc = GetDirectoryEntry(&file, &currentDir, DIRECTORY_BROWSE_PREV);

				// Exit if directory we are going to display them too
				if ((file.attributes & FAT_ATTRIB_DIR) && rc)
				{	break;	}
			}
			while ((type[0]!='*') && (0 != strncmp(&file.name[8],type,3)) && rc);

			// update directory[] if file found
			if (rc)
			{
				// Move Dir List Down
				for (i=DIRSIZE-1;i>0;i--)
				{	directory[i] = directory[i-1];	}
				// Fill First Entry in dir list
				directory[0] = file;
			}
		}
		else
		{
			// just move pointer in window
			dirptr--;
		}
	}
	else if (32 <= mode)
	{
		//find entry beginnig with the given character
		i = 0;

		//check if any file is already displayed
		if (directory[0].name[0])
		{
			//begin searching from the first displayed entry
			file = directory[0];
			
			//search for the next entry
			seekmode = DIRECTORY_BROWSE_NEXT;

			// fill directory with available files
			while (i<DIRSIZE)
			{
				if(GetDirectoryEntry(&file, &currentDir, seekmode))
				{
					//entry found
					seekmode = DIRECTORY_BROWSE_NEXT;

					//the whole directory was traversed and we reached the starting point so there is no other files beginnig with the given character
					if (file.entry==directory[0].entry)
					{
						//if the first displayed entry begins with the given character then select it
						if (directory[0].name[0]==mode)
						{	dirptr = 0;	}

						return;
					}

					// check filetype and the first character of the entry name or directory
					if (mode == file.name[0]
							&& ((file.attributes & FAT_ATTRIB_DIR) || (type[0]=='*') || (strncmp(&file.name[8],type,3)==0)) )
					{
						dirptr = 0;

						//clear the display list
						memset(directory, 0, sizeof(directory));

						//add found entry to the display list
						directory[i] = file;
						i++;

						//search for the other files to display (only file type matters)
						while (i<DIRSIZE)
						{
							if(!GetDirectoryEntry(&file, &currentDir, DIRECTORY_BROWSE_NEXT))
							{
								//the end of the directory has been reached
								return;
							}

							// Check if directory and filetype
							if ((file.attributes & FAT_ATTRIB_DIR) || (type[0]=='*') || (strncmp(&file.name[8],type,3)==0)) 
							{
								directory[i] = file;
								i++;
							}
						}
					}
				}
				else
				{
					//the end of the directory reached, start from the beginning
					seekmode = DIRECTORY_BROWSE_START;
				}
			}
		}
	}
}
