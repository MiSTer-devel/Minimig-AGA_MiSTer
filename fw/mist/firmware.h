typedef struct
{
    unsigned long flags;
    unsigned long base;
    unsigned long size;
    unsigned long crc;
} romTYPE;

typedef struct
{
    unsigned char id[8];
    unsigned char version[16];
    romTYPE       rom;
    unsigned long padding[117];
    unsigned long crc;
} UPGRADE;

#define true -1
#define false 0

unsigned long CalculateCRC32(unsigned long crc, unsigned char *pBuffer, unsigned long nSize);
unsigned char CheckFirmware(fileTYPE *file, char *name);
void WriteFirmware(fileTYPE *file, char *name) RAMFUNC;
char *GetFirmwareVersion(fileTYPE *file, char *name);
