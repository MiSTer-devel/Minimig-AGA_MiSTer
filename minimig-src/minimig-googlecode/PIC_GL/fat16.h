#ifndef _FAT16_H_INCLUDED
#define _FAT16_H_INCLUDED

// Enable / Disable Debug info in Fat Module
//#define FAT16_DEBUG


/* Partition Type Defninition */
#define PARTITION_TYPE_FREE			0x00	/* The partition table entry is not used. */
#define PARTITION_TYPE_FAT12		0x01	/* The partition contains a FAT12 filesystem. */
#define PARTITION_TYPE_FAT16_32MB	0x04	/* The partition contains a FAT16 filesystem with 32MB maximum. */
#define PARTITION_TYPE_EXTENDED		0x05	/* The partition is an extended partition with its own partition table. */
#define PARTITION_TYPE_FAT16		0x06	/* The partition contains a FAT16 filesystem. */
#define PARTITION_TYPE_FAT32		0x0b	/* The partition contains a FAT32 filesystem. */
#define PARTITION_TYPE_FAT32_LBA 	0x0c	/* The partition contains a FAT32 filesystem with LBA. */
#define PARTITION_TYPE_FAT16_LBA 	0x0e	/* The partition contains a FAT16 filesystem with LBA. */
#define PARTITION_TYPE_EXTENDED_LBA	0x0f	/* The partition is an extended partition with LBA. */
#define PARTITION_TYPE_UNKNOWN		0xff	/* The partition has an unknown type. */


/* File Attributes */
#define FAT_ATTRIB_READONLY	(1 << 0)	// The file is read-only.
#define FAT_ATTRIB_HIDDEN	(1 << 1)	// The file is hidden.
#define FAT_ATTRIB_SYSTEM	(1 << 2)	// The file is a system file.
#define FAT_ATTRIB_VOLUME	(1 << 3)	// The file is empty and has the volume label as its name.
#define FAT_ATTRIB_DIR		(1 << 4)	// The file is a directory.
#define FAT_ATTRIB_ARCHIVE	(1 << 5)	// The file has to be archived.
#define FAT_ATTRIB_LFN_TEXT	(FAT_ATTRIB_VOLUME | FAT_ATTRIB_SYSTEM | FAT_ATTRIB_HIDDEN | FAT_ATTRIB_READONLY)	// 0x0F Long filename entry

#define FAT_LFN_LAST_MASK	0x40		// Last long entry flag

#define MAX_LFN_SIZE	128				// Maximum supported long file name, default is 256

/* Directory Seek Modes */
#define DIRECTORY_BROWSE_START		0		// start search from beginning of directory
#define	DIRECTORY_BROWSE_CURRENT	1		// find current directory entry
#define	DIRECTORY_BROWSE_NEXT		2		// find next file in directory
#define	DIRECTORY_BROWSE_PREV		3		// find previous file in directory


/* First Characters in Fat name */
#define FAT_ENTRY_FREE				0x00	/* Fat entry is free */
#define FAT_ENTRY_KANJI				0x05	/* Fat entry is kanji */
#define FAT_ENTRY_PARENT_DIRECTORY	0x2E	/* Fat entry is directory or parent direcotry */
#define FAT_ENTRY_DELETED			0xE5	/* Fat entry is deleted */


/* Define partition structure */
struct PRIMARY_Partition
{
	unsigned char Status;					// Partition status
	unsigned char CHSFirstBlock[3];
	unsigned char Type;						// Partition type
	unsigned char CHSLastBlock[3];
	unsigned long LBAFirst;					// First LBA block
	unsigned long LBABlocks;				// Number of LBA blocks in partition
};


/* Define Master Boot Record */
struct MBR_Disk
{
	unsigned char				bootCode[440];	// Code Area
	unsigned long				diskSignature;	// Optional Disk signature
	unsigned short				reserved;		// Usually Nulls; 0x0000
	struct PRIMARY_Partition	partitions[4];	// Table of primary partitions (Four 16-byte entries, IBM Partition Table scheme)
	unsigned short				signature;		// MBR signature; 0xAA55
};


/* FAT 16 Extened bios parametars block */
struct FAT16_ExtBiosParams
{
	unsigned char	physicalDriveNo;		// Physical drive number 
	unsigned char	reserved;				// Reserved ("current head") In Windows NT bit 0 is a dirty flag to request chkdsk at boot time. bit 1 requests surface scan too.[28]
	unsigned char	extBootSignature;		// Extended boot signature. Value is 0x29[27] or 0x28.
	unsigned long	ID;						// ID (serial number)
	unsigned char	volumeLabel[11];		// Volume Label, padded with blanks (0x20).	
	unsigned char	FATFileSystemType[8];	// FAT file system type, padded with blanks (0x20), e.g.: "FAT12   ", "FAT16   ". This is not meant to be used to determine drive type, however, some utilities use it in this way.
	unsigned char	OsBootCode[448];		// Operating system boot code
};


/* FAT32 Extended parametars block */
struct FAT32_ExtBiosParams
{
	unsigned long	sectorsPerFAT;			// Sectors per file allocation table 
	unsigned short	flags;					// FAT Flags 
	unsigned short	version;				// Version
	unsigned long	rootDirCluster;			// Cluster number of root directory start
	unsigned short	fsInformationSector;	// Sector number of FS Information Sector 
	unsigned short 	bootSectorCopy;			// Sector number of a copy of this boot sector 
	unsigned char	reserved1[12];			// Reserved 
	unsigned char	physicalDriveNo;		// Physical drive number 
	unsigned char	reserved2;				// Reserved 
	unsigned char	extBootSignature;		// Extended boot signature. 
	unsigned long	ID;						// ID (serial number) 
	unsigned char	volumeLabel[11];		// Volume Label 
	unsigned char	FATFileSystemType[8];	// FAT file system type: "FAT32   " 
	unsigned char	OsBootCode[420];		// Operating system boot code 
};


/* Fat Boot Sector */
struct FAT_Boot_Sector
{
	unsigned char	jumpInstruction[3];		// Jump instruction. This instruction will be executed and will skip past the rest of the (non-executable) header if the partition is booted from. See Volume Boot Record. If the jump is two-byte near jmp it is followed by a NOP instruction. 
	unsigned char	oemName[8];				// OEM Name (padded with spaces). This value determines in which system disk was formatted. MS-DOS checks this field to determine which other parts of the boot record can be relied on.[25][26] Common values are IBM  3.3 (with two spaces between the "IBM" and the "3.3"), MSDOS5.0 and MSWIN4.1 and mkdosfs. 
	unsigned short	bytesPerSector;			// Bytes per sector. A common value is 512, especially for file systems on IDE (or compatible) disks. The BIOS Parameter Block starts here. 
	unsigned char	sectorsPerCluster;		// Sectors per cluster. Allowed values are powers of two from 1 to 128. However, the value must not be such that the number of bytes per cluster becomes greater than 32 KB. 
	unsigned short	reservedSectorCount;	// Reserved sector count. The number of sectors before the first FAT in the file system image. Should be 1 for FAT12/FAT16. Usually 32 for FAT32. 
	unsigned char	noOfFATs;				// Number of file allocation tables. Almost always 2.
	unsigned short	maxRootEntries;			// Maximum number of root directory entries. Only used on FAT12 and FAT16, where the root directory is handled specially. Should be 0 for FAT32. This value should always be such that the root directory ends on a sector boundary (i.e. such that its size becomes a multiple of the sector size). 224 is typical for floppy disks. 
	unsigned short	totalSectorsFAT16;		// Total sectors (if zero, use 4 byte value at offset totalSectorsFAT32) 
	unsigned char	mediaDescriptor;		// Media descriptor 0xF8 Fixed disk (i.e. Hard disk).
	unsigned short	sectorsPerFAT;			// Sectors per File Allocation Table for FAT12/FAT16 
	unsigned short	sectorsPerTrack;		// Sectors per track 
	unsigned short	noHeads;				// Number of heads 
	unsigned long	hiddenSectors;			// Hidden sectors 
	unsigned long	totalSectorsFAT32;		// Total sectors (if greater than 65535; otherwise, see offset totalSectorsFAT16) 
	union
	{
		struct FAT16_ExtBiosParams	fat16Ext;
		struct FAT32_ExtBiosParams	fat32Ext;
	} extParams;
	unsigned short	signature;				// Boot sector signature (0x55 0xAA)
};


// FAT Directory Entry
struct FAT_dirEntryDefault
{
	struct
	{
		unsigned char name[8];			// File name
		unsigned char ext[3];			// File name extension
	} shortName;						// Short file name
	unsigned char attributes;			// File attributes
	unsigned char reserved;				// Reserved
	unsigned char createTimeFineRes;	// Create time fine resolution 10ms
	unsigned short createTime;			// Create time
	unsigned short createDate;			// Create date
	unsigned short lastAccessDate;		// Last access date
	unsigned short firstClusterHigh;	// First cluster high two bytes (FAT32 only)
	unsigned short modifiedTime;		// Last modified time
	unsigned short modifiedDate;		// Last modified date
	unsigned short firstClusterLow;		// First cluster low two bytes
	unsigned long length;				// File length
};


// FAT LFN Directory entry structure
struct	FAT_dirEntryLFN
{
	unsigned char	sequenceNo;			// Sequence number for long file name entry
	unsigned short	fiveUTF16[5];		// Five UTF16 characters
	unsigned char	attributes;			// Attributes always 0x0F
	unsigned char	type;				// LFN entry type always 0x00
	unsigned char	checksum;			// Dos file name checksum
	unsigned short	sixUTF16[6];		// Six UTF16 characters
	unsigned short	firstCluster;		// First cluster always 0x0000
	unsigned short	twoUTF16[2];		// Two UTF16 characters
};


// FAT file entry structure all possible structures combined
union FAT_directoryEntry
{
	struct 	FAT_dirEntryDefault	entry;		// Default File Entry
	struct 	FAT_dirEntryLFN		LFN;		// FAT LFN file entry structure
	unsigned char				bytes[32];	// Simple Byte Buffer
};


/* Structure containing selected partition data */
struct partitionTYPE
{
	unsigned char	fatType;		// 0x10=FAT16, 0x20=FAT32
	unsigned long	partStart;		// start LBA of partition
	unsigned long	fatStart;		// start LBA of first FAT table
	unsigned long	dataStart;		// start LBA of data field
	unsigned long	rootDirCluster;	// root directory cluster 
	unsigned long	rootDirStart;	// start LBA of root directory table
	unsigned short	rootDirEntries;	// start LBA of root directory table
	unsigned char	fatNo;			// number of FAT tables
	unsigned char	clusterSize;	// size of a cluster in blocks
	unsigned long	clusterMask;	// binary mask of cluster number
};


/* Fat file entry structure */
struct fileTYPE
{
	unsigned char	name[12];   		// Short file name
	unsigned char	attributes;			// File attributes
	unsigned short	entry;				// File-entry index in directory table
	unsigned long	sector;  			// Sector index in file
	unsigned long	len;				// File size
	unsigned long	cluster;			// Current cluster
	unsigned long	firstCluster;		// First file cluster
};


// global sector buffer, data for read/write actions is stored here.
extern unsigned char secbuf[512];

// Selected Partition
extern struct partitionTYPE selectedPartiton;
// Default long filename entry
extern unsigned char longFilename[MAX_LFN_SIZE];
// global file handle
extern struct fileTYPE file;
// global current directory file handle
extern struct fileTYPE currentDir;


/*Fat Functions */
unsigned char FindDrive(void);

void OpenRootDirectory(struct fileTYPE *dir);
void OpenDirectory(struct fileTYPE *file, struct fileTYPE *dir);

unsigned char Open(struct fileTYPE *file, const unsigned char *name);
unsigned char GetDirectoryEntry(struct fileTYPE *file, struct fileTYPE *dir, unsigned char mode);
unsigned char FindPreviousDirectoryEntry(struct fileTYPE *file, struct fileTYPE *dir, unsigned char mode);
unsigned char ProcessDirEntry(struct fileTYPE *file, union FAT_directoryEntry * dirEntry);
unsigned char FileNextSector(struct fileTYPE *file);
unsigned char FileSeek(struct fileTYPE *file, unsigned long sector);
unsigned long GetLBA(struct fileTYPE *file);
unsigned char FileRead(struct fileTYPE *file);
unsigned char FileReadEx(struct fileTYPE *file, unsigned char* data);
unsigned char FileWrite(struct fileTYPE *file);
unsigned char GetNextClusterIndexFromFAT(struct fileTYPE *file);

#ifdef FAT16_DEBUG
void PrintSector(unsigned char *sec);
void DisplayFileInfo(const unsigned char *info, struct fileTYPE *file);
#endif


#endif
