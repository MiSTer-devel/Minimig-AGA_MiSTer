#ifndef FDD_H
#define FDD_H

// floppy disk interface defs
#define CMD_RDTRK 0x01
#define CMD_WRTRK 0x02

// floppy status
#define DSK_INSERTED 0x01 /*disk is inserted*/
#define DSK_WRITABLE 0x10 /*disk is writable*/

#define MAX_TRACKS (83*2)

typedef struct
{
    unsigned char status; /*status of floppy*/
    unsigned char tracks; /*number of tracks*/
    unsigned long cache[MAX_TRACKS]; /*cluster cache*/
    unsigned long cluster_offset; /*cluster offset to handle tricky loaders*/
    unsigned char sector_offset; /*sector offset to handle tricky loaders*/
    unsigned char track; /*current track*/
    unsigned char track_prev; /*previous track*/
    char          name[22]; /*floppy name*/
} adfTYPE;

void SectorGapToFpga(void);
void SectorHeaderToFpga(unsigned char n, unsigned char dsksynch, unsigned char dsksyncl);
//unsigned short SectorToFpga(unsigned char sector, unsigned char track, unsigned char dsksynch, unsigned char dsksyncl);
void ReadTrack(adfTYPE *drive);
unsigned char FindSync(adfTYPE *drive);
unsigned char GetHeader(unsigned char *pTrack, unsigned char *pSector);
unsigned char GetData(void);
void WriteTrack(adfTYPE *drive);
void UpdateDriveStatus(void);
void HandleFDD(unsigned char c1, unsigned char c2);

#endif

