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
    unsigned char version[8];
    romTYPE       rom;
    unsigned long padding[119];
    unsigned long crc;
} UPGRADE;

#define NVCONFIG 0x3FFFC
#define NVCONFIG_SPIMODE 0x00000001
#define SPIMODE_NORMAL 0
#define SPIMODE_FAST 1

#define true -1
#define false 0

unsigned long CalculateCRC32(unsigned long crc, unsigned char *pBuffer, unsigned long nSize);
unsigned char CheckFirmware(fileTYPE *file, char *name);
unsigned long WriteFirmware(fileTYPE *file);
void SetSPIMode(unsigned long mode);
unsigned long GetSPIMode(void);

