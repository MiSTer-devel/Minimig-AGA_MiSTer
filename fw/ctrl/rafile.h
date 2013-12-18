#ifndef RAFILE_H
#define RAFILE_H

/*	Utility functions to provide the Minimig OSD code with file access
	at single-byte rather than 512-byte-block granularity.
	Copyright (c) 2012 by Alastair M. Robinson

	Contributed to the Minimig project, which is free software;
	you can redistribute it and/or modify it under the terms of
	the GNU General Public License as published by the Free Software Foundation;
	either version 3 of the License, or (at your option) any later version.

	Minimig is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#include "fat.h"

typedef struct
{
	fileTYPE file;
	unsigned long size;
	unsigned long ptr;
	unsigned char buffer[512];	// Each RandomAccessFile has its own sector_buffer
} RAFile;

int RARead(RAFile *file,unsigned char *pBuffer, unsigned long bytes);
int RASeek(RAFile *file,unsigned long offset,unsigned long origin);
int RAOpen(RAFile *file,const char *filename);
#endif

