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

This is a simple FAT16 handler. It works on a sector basis to allow fastest acces on disk
images.

11-12-2005	- first version, ported from FAT1618.C
-- JB --
2009-03-01	- code cleanup
			- changed name to fat16.c
			- added clustermask variable
			- modulo operations changed to bitfield operations
			- changed division and multiplication to bitshifts (where possible)
			- some arithmetic optimizations
-- Goran Ljubojevic --
2009-08-19	- fat attributes
			- code cleanup to make more obvious blocks
			- debug option to switch on/off print 
2009-04-24	- Added use of fat structures instead offsets to make code more readable
			- local partition variables replaced by partitionType structure
2009-08-30	- FAT32 detection
2009-09-06	- FAT16/32 Read directory, file, root dir support only
			- Open now uses new function GetDirectoryEntry that supports FAT16/32
			- FILESEEK modes renamed to directory seek modes because that is why is used
2009-09-08	- Code cleaned up redundand lba checks removed
			- Directory search back
			- Removed obsolete FileSearch in faveour of GetDirectoryEntry
2009-09-09	- FindPreviousDirectoryEntry created
2009-10-15	- Removed string buffer reference from main not needed
2009-12-05	- Open file cleaned code
2009-12-09	- Fixed FindPreviousDirectoryEntry when just looking for long filename
			- Fixed '.' not added to filename when no extension.
2009-12-20	- Fixed displaying correct root dir entries when short names and volume entry found
			- Fixed LFN search when previous entries are either volume or short dir entires
2009-12-23	- Fixed File Open when no file is found handle is cleared
2010-01-24	- Added FileReadEx function
2010-08-26	- Added firmwareConfiguration.h
*/

#include <stdio.h>
#include <string.h>
#include "firmwareConfiguration.h"
#include "mmc.h"
#include "fat16.h"

// sector buffer
unsigned char secbuf[512];

// Selected Partition
//static struct partitionTYPE selectedPartiton;
struct partitionTYPE selectedPartiton;

unsigned char longFilename[MAX_LFN_SIZE];		// Default long filename entry
struct fileTYPE file;							// global file handle
struct fileTYPE currentDir;						// global directory file handle

// Long filename entry char pos
static const unsigned char charLFNPos[] = { 1, 3, 5, 7, 9, 14, 16, 18, 20, 22, 24, 28, 30 };

// FindDrive checks if a card is present. if a card is present it will check for
// a valid FAT16 or FAT32 primary partition
unsigned char FindDrive(void)
{
	unsigned long fatsize;						// size of fat
	unsigned long dirsize;						// size of directory region in sectors

	struct MBR_Disk	*mbr = (struct MBR_Disk *)secbuf;
	struct FAT_Boot_Sector *boot = (struct FAT_Boot_Sector *)secbuf;
	
	// read partition sector
	if (!MMC_Read(0,secbuf))
	{
		#ifdef FAT16_DEBUG
		printf("Error Unable to read partition sector.\r\n");
		#endif
		return(0);	
	}
	
	// check for fat signature
	if (0xAA55 != mbr->signature)
	{	
		#ifdef FAT16_DEBUG
		printf("Error invalid FAT signature.\r\n");
		#endif
		return(0);	
	}

	// Check partition type
	switch(mbr->partitions[0].Type)
	{
		case PARTITION_TYPE_FAT16_32MB:
		case PARTITION_TYPE_FAT16:
			// first partition filesystem type: FAT16
			selectedPartiton.fatType = 0x10;
			// get start of first partition
			selectedPartiton.partStart = mbr->partitions[0].LBAFirst;
			break;

		case PARTITION_TYPE_FAT32:
		case PARTITION_TYPE_FAT32_LBA:
			// First partition filesystem type: FAT32
			selectedPartiton.fatType = 0x20;
			// get start of first partition
			selectedPartiton.partStart = mbr->partitions[0].LBAFirst;
			break;
			
		default:
			#ifdef FAT16_DEBUG
			printf("Error no FAT partition found.\r\n");
			#endif
			return(0);
	}

	// read boot sector
	if (!MMC_Read(selectedPartiton.partStart, secbuf))
	{	
		#ifdef FAT16_DEBUG
		printf("Error unable to read boot sector.\r\n");
		#endif
		return(0);	
	}

	// check for near-jump or short-jump opcode
	if(0xE9 != boot->jumpInstruction[0] && 0xEB != boot->jumpInstruction[0])
	{	
		#ifdef FAT16_DEBUG
		printf("Error invalid 0x%02X boot sector jump.\r\n", boot->jumpInstruction[0]);
		#endif
		return(0);	
	}
	
	// check if blocksize is really 512 bytes
	if (0x200 != boot->bytesPerSector)
	{
		#ifdef FAT16_DEBUG
		printf("Error block size not 512 bytes it is 0x%04X.\r\n", boot->bytesPerSector);
		#endif
		return(0);	
	}
	
	// check medium descriptor byte, must be 0xf8 for hard drive
	if(0xF8 != boot->mediaDescriptor)
	{
		#ifdef FAT16_DEBUG
		printf("Error invalid media descriptor.\r\n");
		#endif
		return(0);	
	}
	
	// get clustersize
	selectedPartiton.clusterSize = boot->sectorsPerCluster;
	// calculate cluster mask
	selectedPartiton.clusterMask = ~(selectedPartiton.clusterSize-1);

	
	/* calculate drive's parameters from bootsector, first up is size of directory */
	/* Get Max ROOT Dir entries FAT16 only !!*/
	selectedPartiton.rootDirEntries = boot->maxRootEntries;

	/*calculate start of FAT,size of FAT and number of FAT's*/
	selectedPartiton.fatStart = selectedPartiton.partStart + boot->reservedSectorCount;
	selectedPartiton.fatNo = boot->noOfFATs;

	// When FAT16 
	if (0x10 == selectedPartiton.fatType)
	{
		fatsize = boot->sectorsPerFAT;
		// Fat 16 Root dir cluster
		selectedPartiton.rootDirCluster = 0;
		// calculate start of FAT16 ROOT directory 
		selectedPartiton.rootDirStart = selectedPartiton.fatStart + (selectedPartiton.fatNo * fatsize);
		// Calculate dire size in sectors
		dirsize = ((selectedPartiton.rootDirEntries<<5)+511)>>9;
		// calculate start of data
		selectedPartiton.dataStart = selectedPartiton.rootDirStart + dirsize;
	}
	else
	{
		fatsize = boot->extParams.fat32Ext.sectorsPerFAT;
		// calculate data start
		selectedPartiton.dataStart = selectedPartiton.fatStart + (selectedPartiton.fatNo * fatsize);
		// Fat 32 Root dir cluster
		selectedPartiton.rootDirCluster = boot->extParams.fat32Ext.rootDirCluster; 
		// Get FAT32 root dir start 
		selectedPartiton.rootDirStart = selectedPartiton.dataStart + (selectedPartiton.rootDirCluster-2)* selectedPartiton.clusterSize;
	}

	// Open Root Directory
	OpenRootDirectory(&currentDir);
	
	#ifdef FAT16_DEBUG
	// some debug output
	printf("\r\nFAT%02d partition found.\r\n",selectedPartiton.fatType);
	printf("Fat Size:	%ld\r\n",fatsize);
	printf("No of fats:	%d\r\n",selectedPartiton.fatNo);
	printf("Fat start:	%ld\r\n", selectedPartiton.fatStart);
	printf("Direntries:	%d\r\n",selectedPartiton.rootDirEntries);
	printf("Dir start:	%ld\r\n", selectedPartiton.rootDirStart);
	printf("Data start:	%ld\r\n", selectedPartiton.dataStart);
	printf("Cluster size:	%d\r\n",selectedPartiton.clusterSize);
	printf("Cluster mask:	%08lX\r\n",selectedPartiton.clusterMask);
	#endif

	return(1);
}


// Find file by name and open it's file handle
unsigned char Open(struct fileTYPE *file, const unsigned char *name)
{
	unsigned char i;

	#ifdef FAT16_DEBUG
	printf("\r\nOpen file: %s\r\n",name);
	#endif
	
	if (GetDirectoryEntry(file,&currentDir,DIRECTORY_BROWSE_START))
	{
		do
		{
			#ifdef FAT16_DEBUG
			printf(" reading: %s\r\n",file->name);
			#endif
	
			for(i=0; i<11; i++)
			{
				if (file->name[i]!=name[i])
				{	break;	}
			}
			
			if (i==11)
			{
				#ifdef FAT16_DEBUG
				printf("Found!\r\n");
				#endif
				return (1);
			}
		}
		while (GetDirectoryEntry(file,&currentDir,DIRECTORY_BROWSE_NEXT));
	}
	
	#ifdef FAT16_DEBUG
	printf("NOT Found\r\n");
	#endif

	// Clear file handle if file Can't be open
	memset(file,0,sizeof(struct fileTYPE));
	return (0);
}


// Open Root directory
void OpenRootDirectory(struct fileTYPE *dir)
{
	// Clear Entry
	memset(dir,0,sizeof(dir));
	dir->name[0] = '/';
	dir->attributes = FAT_ATTRIB_DIR;
	dir->firstCluster = selectedPartiton.rootDirCluster;
	dir->cluster = dir->firstCluster;
}


// Open selected directory
void OpenDirectory(struct fileTYPE *file, struct fileTYPE *dir)
{
	// Copy structure;
	memcpy(dir, file, sizeof(struct fileTYPE));
	
	// Reset reading pointers
	dir->cluster = dir->firstCluster;
	dir->sector = 0;

	#ifdef FAT16_DEBUG
	DisplayFileInfo("Directory open: ", dir);
	#endif
}


// Get Directory Entry
unsigned char GetDirectoryEntry(struct fileTYPE *file, struct fileTYPE *dir,  unsigned char mode)
{
	short entryOffset;
	char rc;

	// Clear long file name
	memset(longFilename,0,MAX_LFN_SIZE);

	// Check for mode
	switch(mode)
	{
		case DIRECTORY_BROWSE_NEXT:
			file->entry++;
			break;
		
		case DIRECTORY_BROWSE_PREV:
		case DIRECTORY_BROWSE_CURRENT:
			if(!FindPreviousDirectoryEntry(file, dir, mode))
			{	return(0);	}
			break;
			
		case DIRECTORY_BROWSE_START:
		default:
			file->entry = 0;
			break;
	}
	
	//Seek directory to selected file entry
	if(!FileSeek(dir, file->entry >> 4))
	{	return(0);	}

	// Infinite loop for search
	while(1)
	{
		// Read sector in buffer, MMC Read will not read sector if allready in buffer
		if (!MMC_Read(GetLBA(dir),secbuf))
		{	return(0);	}

		// Calculate file entry offset in directory sector, 16 entries in sector 32 byte big
		entryOffset = (file->entry & 0xF) << 5;

		// Process directory entry
		rc = ProcessDirEntry(file, (union FAT_directoryEntry *)(secbuf + entryOffset));
		if(!rc)
		{	return (0);		}
		else if(1 == rc)
		{	return(1);		}
		
		// Go to next Fat Entry
		file->entry++;
		
		// Check should we seek directory to next sector
		if(!(file->entry & 0xF))
		{	FileNextSector(dir);	}
	}

	// Return error
	return(0);
}


// Finds prevoius directory entry
// Mode
//	DIRECTORY_BROWSE_CURRENT - Find Begining of long file name for current entry if exists
//	DIRECTORY_BROWSE_PREV - Find Full previous entry including long file name
unsigned char FindPreviousDirectoryEntry(struct fileTYPE *file, struct fileTYPE *dir, unsigned char mode)
{
	unsigned short entryStart;
	unsigned short entrySectorOffset;
	union FAT_directoryEntry * dirEntry;
	
	if(0 == file->entry )
	{
		// Exit with error if nothing to search
		if(DIRECTORY_BROWSE_PREV == mode)
		{	return(0);	}
		else
		{	return(1);	}
	}

	// Keep Original entry pos
	entryStart = file->entry;

	//Seek directory to selected file entry
	if(!FileSeek(dir, file->entry >> 4))
	{	return(0);	}

	// Loop untill we reach directory start or we find valid entry
	do
	{
		// Move to previous entry
		file->entry--;

		// Calculate file entry offset in directory sector, 16 entries in sector
		entrySectorOffset = file->entry & 0xF;

		// Check if was last sector entry
		if(0xF == entrySectorOffset)
		{
			// Just calc current sector
			dir->sector = (unsigned long) file->entry >> 4;

			// Check if we were on cluster boundary
			if(~selectedPartiton.clusterMask == (dir->sector & ~selectedPartiton.clusterMask))
			{
				//Seek directory to selected entry sector
				if(!FileSeek(dir, file->entry >> 4))
				{	return(0);	}
			}
		}

		// Read sector in buffer, MMC Read will not read sector if allready in buffer
		if (!MMC_Read(GetLBA(dir),secbuf))
		{	return(0);	}

		// Get Dir entry for checking
		dirEntry = (union FAT_directoryEntry *)(secbuf + (entrySectorOffset << 5));

		#ifdef FAT16_DEBUG
		printf("Entry:%03d attr: 0x%02X, name: '%c', 0x%02X, fullname: %s\r\n",
				file->entry, 
				dirEntry->entry.attributes, 
				dirEntry->entry.shortName.name[0], 
				dirEntry->entry.shortName.name[0],
				dirEntry->entry.shortName.name
		);
		printf("E:%04X A:%02X Name: %s\r\n", file->entry, dirEntry->entry.attributes, file->name);
		#endif


		// Check if we are at directory end
		if(FAT_ENTRY_FREE == dirEntry->entry.shortName.name[0])
		{	return(0);	}

		// Check if file deleted, just skip it
		if(FAT_ENTRY_DELETED == dirEntry->entry.shortName.name[0])
		{	continue;	}

		// Check if last long filename entry, and just exit
		if(FAT_ATTRIB_LFN_TEXT == dirEntry->entry.attributes)
		{
			// Exit if LFN search and we found it
			if((DIRECTORY_BROWSE_CURRENT == mode) && (dirEntry->LFN.sequenceNo & FAT_LFN_LAST_MASK))
			{	return(1);	}
		}
		else if (0 == (dirEntry->entry.attributes & (FAT_ATTRIB_HIDDEN | FAT_ATTRIB_SYSTEM | FAT_ATTRIB_VOLUME)) )
		{
			// Check if normal entry
			if(DIRECTORY_BROWSE_CURRENT == mode)
			{
				// Normal entry found when browsing current, just move to next entry
				file->entry++;
				return(1);
			}
			else
			{
				// On first entry exit nothing to search more
				if(0 == file->entry)
				{	
					return (1);
				}
				else
				{
					// Entry found, continue searching for LFN
					mode = DIRECTORY_BROWSE_CURRENT;
					entryStart = file->entry;
				}
			}
		}
		else if((dirEntry->entry.attributes & FAT_ATTRIB_VOLUME) && (DIRECTORY_BROWSE_CURRENT == mode))
		{
			// Normal entry found when browsing current, just move to next entry
			file->entry++;
			return(1);
		}
		
	} 
	while(file->entry > 0);
	
	// Exit we didn't find it, restore original file entry pos
	file->entry = entryStart;
	return (0);
}


// Process directory entry
// Returns:
//	0 - Error stop proccessing
//	1 - Ok finished processing file entry found
//	2 - Continue processing
unsigned char ProcessDirEntry(struct fileTYPE *file, union FAT_directoryEntry * dirEntry)
{
	short i;
	short char_offset;

	// Check if we are at directory end
	if(FAT_ENTRY_FREE == dirEntry->entry.shortName.name[0])
	{	
		#ifdef FAT16_DEBUG
		printf ("Entry free %d\r\n", file->entry);
		#endif
		return(0);	
	}

	// Check if file deleted
	if(FAT_ENTRY_DELETED != dirEntry->entry.shortName.name[0])
	{	
		// Check if longfilename
		if(FAT_ATTRIB_LFN_TEXT == dirEntry->entry.attributes)
		{
			// Calc pos to copy part of LFN
	        char_offset = ((dirEntry->LFN.sequenceNo & 0x3f)-1) * 13;
	        
	        // Copy part of LFN
	        for(i = 0; i < 13 && (char_offset + i) < (MAX_LFN_SIZE - 1); i++)
	        {  	longFilename[char_offset + i] = dirEntry->bytes[charLFNPos[i]];		}
		}
		else if (dirEntry->entry.attributes & (FAT_ATTRIB_HIDDEN | FAT_ATTRIB_SYSTEM | FAT_ATTRIB_VOLUME) )
		{
			#ifdef FAT16_DEBUG
			printf ("Skiping entry no:%d attr:0x%02X\r\n", file->entry, dirEntry->entry.attributes);
			#endif
			// Clear longfile name just in case
			memset(longFilename,0,MAX_LFN_SIZE);
		}
		else
		{
			//copy name
			memcpy(&file->name, &dirEntry->entry.shortName, 11);
			file->name[11] = 0x00;															// In theory not needed since never trashed
			file->attributes = dirEntry->entry.attributes;
			file->len = dirEntry->entry.length;												// get length of file
			file->firstCluster = (unsigned long)dirEntry->entry.firstClusterLow;			// get first cluster of file
			file->firstCluster |= ((unsigned long)dirEntry->entry.firstClusterHigh)<<16;	// FAT32 high bytes of cluster TODO: Check if fat 32 before using value
			file->cluster = file->firstCluster;												// Copy Cluster to first cluster
			file->sector = 0;																// reset sector index

			// Check if there is no LFN than copy short name as LFN
			// Skip entries that have LFN and entries starting with '.' (Parent and Current dir)
			if(!longFilename[0] && (file->name[0] != '.') )
			{
				char_offset = 0;
				for(i=0; i < 11; i++)
				{
					if(file->name[i] != ' ')
					{	longFilename[char_offset++] = file->name[i];	}

					if(7 == i)
					{	longFilename[char_offset++] = '.';		}
				}
				
				// Delete Last dot
				if(longFilename[char_offset-1]=='.')
				{	char_offset--;	}

				longFilename[char_offset] = 0x00;
			}
			
			#ifdef FAT16_DEBUG
			DisplayFileInfo("File found ", file);
			#endif
			
			return(1);
		}
	}
	
	return (2);
}


// point to next sector in file
unsigned char FileNextSector(struct fileTYPE *file)
{
	// increment sector index
	file->sector++;

	// if we are now in another cluster, look up cluster
	if ((file->sector & ~selectedPartiton.clusterMask)==0)
	{
		GetNextClusterIndexFromFAT(file);
	}

	return(1);
}


unsigned char FileSeek(struct fileTYPE *file, unsigned long sector)
{
	long currentClusterNo;
	long clusterNo;

	// Calculate Current ClusterNo to avoid seek if new secor is on same cluster
	currentClusterNo = (long)file->sector;
	currentClusterNo /= (long)selectedPartiton.clusterSize;
	
	// Sector in file to read
	file->sector = sector;

	// Calculate new ClusterNO in file
	clusterNo = (long)file->sector;
	clusterNo /= (long)selectedPartiton.clusterSize;

	//Calc ClusterNo Difference
	currentClusterNo -= clusterNo; 
	
	// Check if We are on same cluster
	if(0 == currentClusterNo)
	{	return(1);	}
	
	// Reset current cluster in file to firs
	file->cluster = file->firstCluster;
	
	#ifdef FAT16_DEBUG
	DisplayFileInfo("File seek ", file);
	#endif
	
	// If first cluster in file exit 
	if(0 == clusterNo)
	{	return(1);	}

	// Loop through cluster links
	while(--clusterNo >= 0)
	{
		GetNextClusterIndexFromFAT(file);

		#ifdef FAT16_DEBUG
		printf (" -seek: clusterNo: 0x%08lX", clusterNo);
		printf (" , cluster: 0x%08lX\r\n", file->cluster);
		#endif
	}

	return(1);
}


// Reads FAT Cluster index for specified 
unsigned char GetNextClusterIndexFromFAT(struct fileTYPE *file)
{
	unsigned short index;
	unsigned long fatSectorLba;

	// calculate sector that contains FAT-link
	fatSectorLba = selectedPartiton.fatStart;

	if(selectedPartiton.fatType & 0x10)
	{
		// FAT16 256 cluster infos in sector on disk
		fatSectorLba += (file->cluster) >> 8;

		// calculate offset
		index = (file->cluster) & 0xFF;
		index <<= 1;
	}
	else
	{
		// FAT32 128 cluster infos in sector on disk
		fatSectorLba += (file->cluster) >> 7;

		// FAT32 128 cluster infos in sector
		index = (file->cluster) & 0x7F;
		index <<= 2;
	}

	// read sector of FAT
	if (!MMC_Read(fatSectorLba, secbuf))
	{	return(0);	}

	if(selectedPartiton.fatType & 0x10)
	{
		// get FAT-link
		file->cluster = *((unsigned short*)&secbuf[index]);

		// TODO: Exit if end of cluster chain
//		if(0xFFFF == file->cluster)
//		{	return(0);	}
	}
	else
	{
		// For FAT32 Read long instead short
		file->cluster = *((unsigned long*)&secbuf[index]);
		file->cluster &= 0x0FFFFFFF;

		// TODO: Exit if end of cluster chain
//		if(0x0FFFFFFF == file->cluster)
//		{	return(0);	}
	}
	
	return (1);
}


// Calculate LBA from current file position cluster and sector
unsigned long GetLBA(struct fileTYPE *file)
{
	unsigned long lba;

	// Calc sector to read, When first cluster is 0 it is root directory of FAT16
	if(0 == file->firstCluster)
	{
		lba = selectedPartiton.rootDirStart;
		lba += file->sector;
	}
	else
	{
		lba = selectedPartiton.dataStart;							// start of data in partition
		lba += (file->cluster-2) * selectedPartiton.clusterSize;	// cluster offset
		lba += file->sector & ~selectedPartiton.clusterMask;		// sector offset in cluster
	}
	
	return lba;
}


// read sector into buffer
unsigned char FileRead(struct fileTYPE *file)
{
//	return MMC_Read(GetLBA(file),secbuf);
	return FileReadEx(file, secbuf);
}

unsigned char FileReadEx(struct fileTYPE *file, unsigned char* data)
{
	return MMC_Read(GetLBA(file),data);
}

// write buffer to sector
unsigned char FileWrite(struct fileTYPE *file)
{
	return(MMC_Write(GetLBA(file),secbuf));
}


#ifdef FAT16_DEBUG

void PrintSector(unsigned char *sec)
{
	int i = 512;
	do
	{
		printf("0x%02X ", *(sec++));
		if(!(i % 16))
		{	printf("\r\n");	}
	}
	while(--i);
	printf("\r\n");
}

void DisplayFileInfo(const unsigned char *info, struct fileTYPE *file)
{
	printf("%s \"%s\"", info, file->name);
	printf(" LFN:\"%s\"\r\n", longFilename);
	printf(" entry: 0x%04X", file->entry);
	printf(" attr: 0x%02X", file->attributes);
	printf(" length: 0x%08lX", file->len);
	printf(" first cluster: 0x%08lX", file->firstCluster);
	printf(" cluster: 0x%08lX", file->cluster);
	printf(" sector: 0x%08lX", file->sector);
	printf("\r\n");
}

#endif
