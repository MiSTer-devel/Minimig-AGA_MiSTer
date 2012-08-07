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

This is a simple FAT16 handler. It works on a sector basis to allow fastest acces on disk
images.

11-12-2005 - first version, ported from FAT1618.C

JB:
2008-10-11  - added SeekFile() and cluster_mask
            - limited file create and write support added
2009-05-01  - modified LoadDirectory() and GetDirEntry() to support sub-directories (with limitation of 511 files/subdirs per directory)
            - added GetFATLink() function
            - code cleanup
2009-05-03  - modified sorting algorithm in LoadDirectory() to display sub-directories above files
2009-08-23  - modified ScanDirectory() to support page scrolling and parent dir selection
2009-11-22  - modified FileSeek()
            - added FileReadEx()
2009-12-15  - all entries are now sorted by name with extension
            - directory short names are displayed with extensions

*/

#include <stdio.h>
#include <string.h>
//#include <ctype.h>
#include "mmc.h"
#include "fat.h"
//#include "swap.h"

int tolower(int c);

unsigned short directory_cluster;       // first cluster of directory (0 if root)
unsigned short entries_per_cluster;     // number of directory entries per cluster

// internal global variables
unsigned char fattype;              	// volume format 
unsigned char fat32 = 0;                // volume format is FAT32
unsigned long boot_sector;              // partition boot sector
unsigned long fat_start;                // start LBA of first FAT table
unsigned long data_start;               // start LBA of data field
unsigned long root_directory_cluster;   // root directory cluster (used in FAT32)
unsigned long root_directory_start;     // start LBA of directory table
unsigned long root_directory_size;      // size of directory region in sectors
unsigned char fat_number;               // number of FAT tables
unsigned char cluster_size;             // size of a cluster in sectors
unsigned long cluster_mask;             // binary mask of cluster number
unsigned short dir_entries;             // number of entry's in directory table
unsigned long fat_size;                 // size of fat

unsigned char sector_buffer[1024];       // sector buffer - room for two consecutive sectors...

struct PartitionEntry partitions[4];	// lbastart and sectors will be byteswapped as necessary
int partitioncount;

FATBUFFER fat_buffer;                   // buffer for caching fat entries
unsigned long buffered_fat_index;       // index of buffered FAT sector

char DirEntryLFN[MAXDIRENTRIES][261];
DIRENTRY DirEntry[MAXDIRENTRIES];
unsigned char sort_table[MAXDIRENTRIES];
unsigned char nDirEntries = 0;          // entries in DirEntry table
unsigned char iSelectedEntry = 0;       // selected entry index
unsigned long iCurrentDirectory = 0;    // cluster number of current directory, 0 for root
unsigned long iPreviousDirectory = 0;   // cluster number of previous directory

// temporary storage buffers
char t_DirEntryLFN[MAXDIRENTRIES][261];
DIRENTRY t_DirEntry[MAXDIRENTRIES];
unsigned char t_sort_table[MAXDIRENTRIES];


unsigned long SwapEndianL(unsigned long l)
{
	unsigned char c[4];
	c[0] = (unsigned char)(l & 0xff);
	c[1] = (unsigned char)((l >> 8) & 0xff);
	c[2] = (unsigned char)((l >> 16) & 0xff);
	c[3] = (unsigned char)((l >> 24) & 0xff);
	return((c[0]<<24)+(c[1]<<16)+(c[2]<<8)+c[3]);
}

void SwapPartitionBytes(int i)
{
	// We don't bother to byteswap the CHS geometry fields since we don't use them.
	partitions[i].startlba=SwapEndianL(partitions[i].startlba);
	partitions[i].sectors=SwapEndianL(partitions[i].sectors);
}

void bprintfl(const char *fmt,unsigned long l)
{
	char s[64];
	sprintf(s,fmt,l);
	fprintf(stderr, s);
}

/*
unsigned char FindDrive(void)
{

    buffered_fat_index = -1;

    if (!MMC_Read(0, sector_buffer)) { // read MBR
        fprintf(stderr, "Cannot read MBR");
        return(0);
    }

    fprintf(stderr, "partition type: 0x%02X (", sector_buffer[450]);
    switch (sector_buffer[450])
    {
    case 0x00:
        fprintf(stderr, "NONE");
        break;
    case 0x01:
        fprintf(stderr, "FAT12");
        break;
    case 0x04:
    case 0x06:
        fprintf(stderr, "FAT16");
        break;
    case 0x0B:
    case 0x0C:
        fprintf(stderr, "FAT32");
        break;
    default:
        fprintf(stderr, "UNKNOWN");
        break;
    }
    fprintf(stderr, ")\n");



    if (sector_buffer[450] != 0x04 && sector_buffer[450] != 0x06 && sector_buffer[450] != 0x0B && sector_buffer[450] != 0x0C) // first partition filesystem type: FAT16
    {
        fprintf(stderr, "Unsupported partition type!\n");
        return(0);
    }

    if (sector_buffer[450] == 0x0B || sector_buffer[450] == 0x0C)
       fat32 = 1;

    if (sector_buffer[510] != 0x55 || sector_buffer[511] != 0xaa)  // check signature
        return(0);

    // get start of first partition
    boot_sector = sector_buffer[467];
    boot_sector <<= 8;
    boot_sector |= sector_buffer[466];
    boot_sector <<= 8;
    boot_sector |= sector_buffer[455];
    boot_sector <<= 8;
    boot_sector |= sector_buffer[454];

    if (!MMC_Read(boot_sector, sector_buffer)) // read boot sector
        return(0);

    // check for near-jump or short-jump opcode
    if (sector_buffer[0] != 0xe9 && sector_buffer[0] != 0xeb)
        return(0);

    // check if blocksize is really 512 bytes
    if (sector_buffer[11] != 0x00 || sector_buffer[12] != 0x02)
        return(0);

    // check medium descriptor byte, must be 0xf8 for hard drive
    if (sector_buffer[21] != 0xf8)
        return(0);

    if (fat32)
    {
        if (strncmp((const char*)&sector_buffer[0x52], "FAT32   ", 8) != 0) // check file system type
            return(0);

        cluster_size = sector_buffer[0x0D]; // get cluster_size in sectors
        cluster_mask = ~(cluster_size - 1); // calculate cluster mask
        dir_entries = cluster_size << 4; // total number of dir entries (16 entries per sector)
        root_directory_size = cluster_size; // root directory size in sectors
        fat_start = boot_sector + sector_buffer[0x0E] + (sector_buffer[0x0F] << 8); // reserved sector count before FAT table (usually 32 for FAT32)
        fat_number = sector_buffer[0x10];
        fat_size = sector_buffer[0x24] + (sector_buffer[0x25] << 8) + (sector_buffer[0x26] << 16) + (sector_buffer[0x27] << 24);
        data_start = fat_start + (fat_number * fat_size);
        root_directory_cluster = sector_buffer[0x2C] + (sector_buffer[0x2D] << 8) + (sector_buffer[0x2E] << 16) + ((sector_buffer[0x2F] & 0x0F) << 24);
        root_directory_start = (root_directory_cluster - 2) * cluster_size + data_start;
    }
    else
    {
        // calculate drive's parameters from bootsector, first up is size of directory
        dir_entries = sector_buffer[17] + (sector_buffer[18] << 8);
        root_directory_size = ((dir_entries << 5) + 511) >> 9;

        // calculate start of FAT,size of FAT and number of FAT's
        fat_start = boot_sector + sector_buffer[14] + (sector_buffer[15] << 8);
        fat_size = sector_buffer[22] + (sector_buffer[23] << 8);
        fat_number = sector_buffer[16];

        // calculate start of directory
        root_directory_start = fat_start + (fat_number * fat_size);
        root_directory_cluster = 0; // unused

        // get cluster_size
        cluster_size = sector_buffer[13];

        // calculate cluster mask
        cluster_mask = ~(cluster_size - 1);

        // calculate start of data
        data_start = root_directory_start + root_directory_size;
    }


    // some debug output
    fprintf(stderr, "fat_size: %lu\n", fat_size);
    fprintf(stderr, "fat_number: %u\n", fat_number);
    fprintf(stderr, "fat_start: %lu\n", fat_start);
    fprintf(stderr, "root_directory_start: %lu\n", root_directory_start);
    fprintf(stderr, "dir_entries: %u\n", dir_entries);
    fprintf(stderr, "data_start: %lu\n", data_start);
    fprintf(stderr, "cluster_size: %u\n", cluster_size);
    fprintf(stderr, "cluster_mask: %08lX\n", cluster_mask);

    return(1);
}
*/



// FindDrive() checks if a card is present and contains FAT formatted primary partition
unsigned char FindDrive(void)
{
    buffered_fat_index = -1;

    if (!MMC_Read(0, sector_buffer)) // read MBR
        return(0);

	boot_sector=0;
	partitioncount=1;

	// If we can identify a filesystem on block 0 we don't look for partitions
    if (strncmp((const char*)&sector_buffer[0x36], "FAT16   ", 8)==0) // check for FAT16
		partitioncount=0;
    if (strncmp((const char*)&sector_buffer[0x52], "FAT32   ", 8)==0) // check for FAT32
		partitioncount=0;

  fprintf(stderr, "Partition count: %d\n", partitioncount);

	if(partitioncount)
	{
		// We have at least one partition, parse the MBR.
		struct MasterBootRecord *mbr=(struct MasterBootRecord *)sector_buffer;
		memcpy(&partitions[0],&mbr->Partition[0],sizeof(struct PartitionEntry));
		memcpy(&partitions[1],&mbr->Partition[1],sizeof(struct PartitionEntry));
		memcpy(&partitions[2],&mbr->Partition[2],sizeof(struct PartitionEntry));
		memcpy(&partitions[3],&mbr->Partition[3],sizeof(struct PartitionEntry));

    fprintf(stderr, "Signature: 0x%04x\n", mbr->Signature);

		switch(mbr->Signature)
		{
			case 0x55aa:	// Little-endian MBR on a big-endian system
				fprintf(stderr, "Swapping byte order of partition entries\n");
				SwapPartitionBytes(0);
				SwapPartitionBytes(1);
				SwapPartitionBytes(2);
				SwapPartitionBytes(3);
				// fall through...
			case 0xaa55:
				// get start of first partition
				boot_sector = partitions[0].startlba;
				bprintfl("Start: %ld\n",partitions[0].startlba);
				for(partitioncount=4;(partitions[partitioncount-1].sectors==0) && (partitioncount>1); --partitioncount)
					;
				bprintfl("PartitionCount: %ld\n",partitioncount);
				int i;
				for(i=0;i<partitioncount;++i)
				{
					bprintfl("Partition: %ld",i);
					bprintfl("  Start: %ld",partitions[i].startlba);
					bprintfl("  Size: %ld\n",partitions[i].sectors);
				}
//				WaitTimer(5000);
				if (!MMC_Read(boot_sector, sector_buffer)) // read discriptor
				    return(0);
				fprintf(stderr, "Read boot sector from first partition\n");
				break;
			default:
				fprintf(stderr, "No partition signature found\n");
				break;
		}
	}

    if (strncmp((const char*)&sector_buffer[0x36], "FAT16   ", 8)==0) // check for FAT16
		fattype = 16;

    if (strncmp((const char*)&sector_buffer[0x52], "FAT32   ", 8)==0) // check for FAT32
		fattype = 32;
	
    fprintf(stderr, "partition type: 0x%02X (", sector_buffer[450]);
    switch (fattype)
    {
		case 0:
		    fprintf(stderr, "NONE");
		    break;
		case 12:
		    fprintf(stderr, "FAT12");
		    break;
		case 16:
		    fprintf(stderr, "FAT16");
		    break;
		case 32:
		    fprintf(stderr, "FAT32");
		    fat32 = 1;
		    break;
		default:
		    fprintf(stderr, "UNKNOWN");
		    break;
    }
    fprintf(stderr, ")\n");

    if (fattype != 32 && fattype != 16) // first partition filesystem type: FAT16 or FAT32
    {
        fprintf(stderr, "Unsupported partition type!\n");
        return(0);
    }

    if (sector_buffer[510] != 0x55 || sector_buffer[511] != 0xaa)  // check signature
        return(0);

//    if (!MMC_Read(boot_sector, sector_buffer)) // read boot sector
//        return(0);

    // check for near-jump or short-jump opcode
    if (sector_buffer[0] != 0xe9 && sector_buffer[0] != 0xeb)
        return(0);

    // check if blocksize is really 512 bytes
    if (sector_buffer[11] != 0x00 || sector_buffer[12] != 0x02)
        return(0);

    // check medium descriptor byte, must be 0xf8 for hard drive
    if (sector_buffer[21] != 0xf8)
        return(0);

    if (fat32)
    {
        if (strncmp((const char*)&sector_buffer[0x52], "FAT32   ", 8) != 0) // check file system type
            return(0);

        cluster_size = sector_buffer[0x0D]; // get cluster_size in sectors
        cluster_mask = ~(cluster_size - 1); // calculate cluster mask
        dir_entries = cluster_size << 4; // total number of dir entries (16 entries per sector)
        root_directory_size = cluster_size; // root directory size in sectors
        fat_start = boot_sector + sector_buffer[0x0E] + (sector_buffer[0x0F] << 8); // reserved sector count before FAT table (usually 32 for FAT32)
        fat_number = sector_buffer[0x10];
        fat_size = sector_buffer[0x24] + (sector_buffer[0x25] << 8) + (sector_buffer[0x26] << 16) + (sector_buffer[0x27] << 24);
        data_start = fat_start + (fat_number * fat_size);
        root_directory_cluster = sector_buffer[0x2C] + (sector_buffer[0x2D] << 8) + (sector_buffer[0x2E] << 16) + ((sector_buffer[0x2F] & 0x0F) << 24);
        root_directory_start = (root_directory_cluster - 2) * cluster_size + data_start;
    }
    else
    {
        // calculate drive's parameters from bootsector, first up is size of directory
        dir_entries = sector_buffer[17] + (sector_buffer[18] << 8);
        root_directory_size = ((dir_entries << 5) + 511) >> 9;

        // calculate start of FAT,size of FAT and number of FAT's
        fat_start = boot_sector + sector_buffer[14] + (sector_buffer[15] << 8);
        fat_size = sector_buffer[22] + (sector_buffer[23] << 8);
        fat_number = sector_buffer[16];

        // calculate start of directory
        root_directory_start = fat_start + (fat_number * fat_size);
        root_directory_cluster = 0; // unused

        // get cluster_size
        cluster_size = sector_buffer[13];

        // calculate cluster mask
        cluster_mask = ~(cluster_size - 1);

        // calculate start of data
        data_start = root_directory_start + root_directory_size;
    }


    // some debug output
    fprintf(stderr, "fat_size: %lu\n", fat_size);
    fprintf(stderr, "fat_number: %u\n", fat_number);
    fprintf(stderr, "fat_start: %lu\n", fat_start);
    fprintf(stderr, "root_directory_start: %lu\n", root_directory_start);
    fprintf(stderr, "dir_entries: %u\n", dir_entries);
    fprintf(stderr, "data_start: %lu\n", data_start);
    fprintf(stderr, "cluster_size: %u\n", cluster_size);
    fprintf(stderr, "cluster_mask: %08lX\n", cluster_mask);

    return(1);
}


