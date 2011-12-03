#ifndef _FAT16_H_INCLUDED
#define _FAT16_H_INCLUDED

struct fileTYPE
{
	unsigned char name[12];   			/*name of file*/
	unsigned char attributes;
	unsigned short entry;				/*file-entry index in directory table*/
	unsigned short sec;  				/*sector index in file*/
	unsigned long len;					/*file size*/
	unsigned long cluster;				/*current cluster*/
};

/*global sector buffer, data for read/write actions is stored here.
BEWARE, this buffer is also used and thus trashed by all other functions*/
extern unsigned char secbuf[512];		/*sector buffer*/

/*constants*/
#define FILESEEK_START			0		/*start search from beginning of directory*/
#define	FILESEEK_NEXT			1		/*find next file in directory*/
#define	FILESEEK_PREV			2		/*find previous file in directory*/

/*functions*/
unsigned char FindDrive(void);
unsigned char FileSearch(struct fileTYPE *file, unsigned char mode);
unsigned char FileNextSector(struct fileTYPE *file);
unsigned char FileRead(struct fileTYPE *file);
unsigned char FileWrite(struct fileTYPE *file);

#endif
