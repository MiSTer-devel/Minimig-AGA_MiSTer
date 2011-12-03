#ifndef _MMC_H_INCLUDED
#define _MMC_H_INCLUDED

unsigned char MMC_Init(void);
unsigned char MMC_Read(unsigned long lba, unsigned char *ReadData);
unsigned char MMC_Write(unsigned long lba, unsigned char *WriteData);

#endif
