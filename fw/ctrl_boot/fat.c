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

#include "hardware.h"
#include "mmc.h"
#include "fat.h"
#include "swap.h"

#include "string.h"

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

// external functions
extern unsigned long GetTimer(unsigned long);


//unsigned char FindDrive(void)
//{
//    buffered_fat_index = -1;
//
//    if (!MMC_Read(0, sector_buffer)) // read MBR
//        return(0);
//
//    //printf("partition type: 0x%02X (", sector_buffer[450]);
//    //switch (sector_buffer[450])
//    //{
//    //case 0x00:
//    //    //printf("NONE");
//    //    break;
//    //case 0x01:
//    //    //printf("FAT12");
//    //    break;
//    //case 0x04:
//    //case 0x06:
//    //    //printf("FAT16");
//    //    break;
//    //case 0x0B:
//    //case 0x0C:
//    //    //printf("FAT32");
//    //    break;
//    //default:
//    //    //printf("UNKNOWN");
//    //    break;
//    //}
//    //printf(")\r");
//
//    if (sector_buffer[450] != 0x04 && sector_buffer[450] != 0x06 && sector_buffer[450] != 0x0B && sector_buffer[450] != 0x0C) // first partition filesystem type: FAT16
//    {
//        //printf("Unsupported partition type!\r");
//        return(0);
//    }
//
//    if (sector_buffer[450] == 0x0B || sector_buffer[450] == 0x0C)
//       fat32 = 1;
//
//    if (sector_buffer[510] != 0x55 || sector_buffer[511] != 0xaa)  // check signature
//        return(0);
//
//    // get start of first partition
//    boot_sector = sector_buffer[467];
//    boot_sector <<= 8;
//    boot_sector |= sector_buffer[466];
//    boot_sector <<= 8;
//    boot_sector |= sector_buffer[455];
//    boot_sector <<= 8;
//    boot_sector |= sector_buffer[454];
//
//    if (!MMC_Read(boot_sector, sector_buffer)) // read boot sector
//        return(0);
//
//    // check for near-jump or short-jump opcode
//    if (sector_buffer[0] != 0xe9 && sector_buffer[0] != 0xeb)
//        return(0);
//
//    // check if blocksize is really 512 bytes
//    if (sector_buffer[11] != 0x00 || sector_buffer[12] != 0x02)
//        return(0);
//
//    // check medium descriptor byte, must be 0xf8 for hard drive
//    if (sector_buffer[21] != 0xf8)
//        return(0);
//
//    if (fat32)
//    {
//        if (strncmp((const char*)&sector_buffer[0x52], "FAT32   ", 8) != 0) // check file system type
//            return(0);
//
//        cluster_size = sector_buffer[0x0D]; // get cluster_size in sectors
//        cluster_mask = ~(cluster_size - 1); // calculate cluster mask
//        dir_entries = cluster_size << 4; // total number of dir entries (16 entries per sector)
//        root_directory_size = cluster_size; // root directory size in sectors
//        fat_start = boot_sector + sector_buffer[0x0E] + (sector_buffer[0x0F] << 8); // reserved sector count before FAT table (usually 32 for FAT32)
//        fat_number = sector_buffer[0x10];
//        fat_size = sector_buffer[0x24] + (sector_buffer[0x25] << 8) + (sector_buffer[0x26] << 16) + (sector_buffer[0x27] << 24);
//        data_start = fat_start + (fat_number * fat_size);
//        root_directory_cluster = sector_buffer[0x2C] + (sector_buffer[0x2D] << 8) + (sector_buffer[0x2E] << 16) + ((sector_buffer[0x2F] & 0x0F) << 24);
//        root_directory_start = (root_directory_cluster - 2) * cluster_size + data_start;
//    }
//    else
//    {
//        // calculate drive's parameters from bootsector, first up is size of directory
//        dir_entries = sector_buffer[17] + (sector_buffer[18] << 8);
//        root_directory_size = ((dir_entries << 5) + 511) >> 9;
//
//        // calculate start of FAT,size of FAT and number of FAT's
//        fat_start = boot_sector + sector_buffer[14] + (sector_buffer[15] << 8);
//        fat_size = sector_buffer[22] + (sector_buffer[23] << 8);
//        fat_number = sector_buffer[16];
//
//        // calculate start of directory
//        root_directory_start = fat_start + (fat_number * fat_size);
//        root_directory_cluster = 0; // unused
//
//        // get cluster_size
//        cluster_size = sector_buffer[13];
//
//        // calculate cluster mask
//        cluster_mask = ~(cluster_size - 1);
//
//        // calculate start of data
//        data_start = root_directory_start + root_directory_size;
//    }
//
//
//    // some debug output
//    //printf("fat_size: %lu\r", fat_size);
//    //printf("fat_number: %u\r", fat_number);
//    //printf("fat_start: %lu\r", fat_start);
//    //printf("root_directory_start: %lu\r", root_directory_start);
//    //printf("dir_entries: %u\r", dir_entries);
//    //printf("data_start: %lu\r", data_start);
//    //printf("cluster_size: %u\r", cluster_size);
//    //printf("cluster_mask: %08lX\r", cluster_mask);
//
//    return(1);
//}


void SwapPartitionBytes(int i)
{
	// We don't bother to byteswap the CHS geometry fields since we don't use them.
	partitions[i].startlba=SwapBBBB(partitions[i].startlba);
	partitions[i].sectors=SwapBBBB(partitions[i].sectors);
}

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

	if(partitioncount)
	{
		// We have at least one partition, parse the MBR.
		struct MasterBootRecord *mbr=(struct MasterBootRecord *)sector_buffer;
		memcpy(&partitions[0],&mbr->Partition[0],sizeof(struct PartitionEntry));
		memcpy(&partitions[1],&mbr->Partition[1],sizeof(struct PartitionEntry));
		memcpy(&partitions[2],&mbr->Partition[2],sizeof(struct PartitionEntry));
		memcpy(&partitions[3],&mbr->Partition[3],sizeof(struct PartitionEntry));

		switch(mbr->Signature)
		{
			case 0x55aa:	// Little-endian MBR on a big-endian system
				//BootPrint("Swapping byte order of partition entries");
				SwapPartitionBytes(0);
				SwapPartitionBytes(1);
				SwapPartitionBytes(2);
				SwapPartitionBytes(3);
				// fall through...
			case 0xaa55:
				// get start of first partition
				boot_sector = partitions[0].startlba;
				//bprintfl("Start: %ld\n",partitions[0].startlba);
				for(partitioncount=4;(partitions[partitioncount-1].sectors==0) && (partitioncount>1); --partitioncount)
					;
				//bprintfl("PartitionCount: %ld\n",partitioncount);
				int i;
				for(i=0;i<partitioncount;++i)
				{
					//bprintfl("Partition: %ld",i);
					//bprintfl("  Start: %ld",partitions[i].startlba);
					//bprintfl("  Size: %ld\n",partitions[i].sectors);
				}
//				WaitTimer(5000);
				if (!MMC_Read(boot_sector, sector_buffer)) // read discriptor
				    return(0);
				//BootPrint("Read boot sector from first partition\n");
				break;
			default:
				//BootPrint("No partition signature found\n");
				break;
		}
	}

    if (strncmp((const char*)&sector_buffer[0x36], "FAT16   ", 8)==0) // check for FAT16
		fattype = 16;

    if (strncmp((const char*)&sector_buffer[0x52], "FAT32   ", 8)==0) // check for FAT32
		fattype = 32;
	
    //printf("partition type: 0x%02X (", sector_buffer[450]);

    fat32 = (fattype==32) ? 1 : 0;

    if (fattype != 32 && fattype != 16) // first partition filesystem type: FAT16 or FAT32
    {
        //putstring("Unsupported partition type!\r");
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
    //printf("fat_size: %lu\r", fat_size);
    //printf("fat_number: %u\r", fat_number);
    //printf("fat_start: %lu\r", fat_start);
    //printf("root_directory_start: %lu\r", root_directory_start);
    //printf("dir_entries: %u\r", dir_entries);
    //printf("data_start: %lu\r", data_start);
    //printf("cluster_size: %u\r", cluster_size);
    //printf("cluster_mask: %08lX\r", cluster_mask);

    return(1);
}

unsigned char FileOpen(fileTYPE *file, const char *name)
{
    unsigned long  iDirectory = 0;       // only root directory is supported
    DIRENTRY      *pEntry = NULL;        // pointer to current entry in sector buffer
    unsigned long  iDirectorySector;     // current sector of directory entries table
    unsigned long  iDirectoryCluster;    // start cluster of subdirectory or FAT32 root directory
    unsigned long  iEntry;               // entry index in directory cluster or FAT16 root directory
    unsigned long  nEntries;             // number of entries per cluster or FAT16 root directory size

    iDirectoryCluster = root_directory_cluster;
    iDirectorySector = root_directory_start;
    nEntries = fat32 ?  cluster_size << 4 : root_directory_size << 4; // 16 entries per sector

    while (1)
    {
        for (iEntry = 0; iEntry < nEntries; iEntry++)
        {
            if ((iEntry & 0x0F) == 0) // first entry in sector, load the sector
            {
                MMC_Read(iDirectorySector++, sector_buffer); // root directory is linear
                pEntry = (DIRENTRY*)sector_buffer;
            }
            else
                pEntry++;


            if (pEntry->Name[0] != SLOT_EMPTY && pEntry->Name[0] != SLOT_DELETED) // valid entry??
            {
                if (!(pEntry->Attributes & (ATTR_VOLUME | ATTR_DIRECTORY))) // not a volume nor directory
                {
                    if (strncmp((const char*)pEntry->Name, name, sizeof(file->name)) == 0)
                    {
                        strncpy(file->name, (const char*)pEntry->Name, sizeof(file->name));
                        file->attributes = pEntry->Attributes;
                        file->size = SwapBBBB(pEntry->FileSize); 		// for 68000
                        file->start_cluster = SwapBB(pEntry->StartCluster) + (fat32 ? (SwapBB(pEntry->HighCluster) & 0x0FFF) << 16 : 0); 	// it only works when using little endian long representation for 68000 
                        file->cluster =  file->start_cluster;
                        file->sector = 0;
                        file->entry.sector = iDirectorySector - 1;
                        file->entry.index = iEntry & 0x0F;

                        //printf("file \"%s\" found\r", name);

                        return(1);
                    }
                }
            }
        }

        if (fat32) // subdirectory is a linked cluster chain
        {
            iDirectoryCluster = GetFATLink(iDirectoryCluster); // get next cluster in chain

            if (fat32 ? (iDirectoryCluster & 0x0FFFFFF8) == 0x0FFFFFF8 : (iDirectoryCluster & 0xFFF8) == 0xFFF8) // check if end of cluster chain
                break; // no more clusters in chain

            iDirectorySector = data_start + cluster_size * (iDirectoryCluster - 2); // calculate first sector address of the new cluster
        }
        else
            break;
    }

    //printf("file \"%s\" not found\r", name);
    memset(file, 0, sizeof(fileTYPE));
    return(0);
}




// GetFATLink
unsigned long GetFATLink(unsigned long cluster)
{
// this function returns linked cluster for the given one
// remember to check if the returned value indicates end of chain condition

    unsigned long fat_index;
    unsigned short buffer_index;

    if (fat32)
    {
        fat_index    = cluster >> 7;    // calculate sector number in the FAT32 that contains the desired link (256 links per sector)
        buffer_index = cluster & 0x7F;  // calculate offset in the buffered FAT32 sector containing the link
    }
    else
    {
        fat_index    = cluster >> 8;    // calculate sector number in the FAT16 that contains the desired link (256 links per sector)
        buffer_index = cluster & 0xFF;  // calculate offset in the buffered FAT16 sector containing the link
    }

    // read the desired FAT sector if not already in the buffer
    if (fat_index != buffered_fat_index)
    {
        if (!MMC_Read(fat_start+fat_index, (unsigned char*)&fat_buffer))
            return(0);

        // remember the index of buffered FAT sector
        buffered_fat_index = fat_index;
    }

//    return(fat32 ? fat_buffer.fat32[buffer_index] & 0x0FFFFFFF : fat_buffer.fat16[buffer_index]); // get FAT link
    return(fat32 ? SwapBBBB(fat_buffer.fat32[buffer_index]) & 0x0FFFFFFF : SwapBB(fat_buffer.fat16[buffer_index])); // get FAT link for 68000
}


// FileNextSector
unsigned char FileNextSector(fileTYPE *file)
{
    unsigned long sb;
    unsigned short i;

    // increment sector index
    file->sector++;

    // cluster's boundary crossed?
    if ((file->sector&~cluster_mask) == 0)
    {
        if (fat32)
        {
            sb = file->cluster >> 7; // calculate sector number containing FAT-link
            i = file->cluster & 0x7F; // calculate link offsset within sector
        }
        else
        {
            sb = file->cluster >> 8; // calculate sector number containing FAT-link
            i = file->cluster & 0xFF; // calculate link offsset within sector
        }

        // read sector of FAT if not already in the buffer
        if (sb != buffered_fat_index)
        {
            if (!MMC_Read(fat_start + sb, (unsigned char*)&fat_buffer))
                return(0);

            // remember current buffer index
            buffered_fat_index = sb;
        }

        file->cluster = fat32 ? SwapBBBB(fat_buffer.fat32[i]) & 0x0FFFFFFF : SwapBB(fat_buffer.fat16[i]); // get FAT link
    }

    return(1);
}


// FileRead
unsigned char FileRead(fileTYPE *file, unsigned char *pBuffer)
{
    unsigned long sb;

    sb = data_start;                         // start of data in partition
    sb += cluster_size * (file->cluster-2);  // cluster offset
    sb += file->sector & ~cluster_mask;      // sector offset in cluster

    if (!MMC_Read(sb, pBuffer)) // read sector from drive
        return(0);
    else
        return(1);
}

