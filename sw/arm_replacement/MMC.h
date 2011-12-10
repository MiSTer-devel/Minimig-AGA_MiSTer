
#define CARDTYPE_NONE 0
#define CARDTYPE_MMC  1
#define CARDTYPE_SD   2
#define CARDTYPE_SDHC 3

unsigned char MMC_Init(void);
unsigned long MMC_Read(unsigned long lba, unsigned char *pReadBuffer);
unsigned long MMC_Write(unsigned long lba, unsigned char *pWriteBuffer);


