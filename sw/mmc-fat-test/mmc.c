/* mmc.c */

#include <stdio.h>
#include <stdlib.h>
#include <inttypes.h>
#include "mmc.h"


#define FN "amiga.img"

extern FILE* ifp;

unsigned char MMC_Init(void)
{

  if((ifp = fopen(FN, "rb")) == NULL) {
    fprintf(stderr, "ERR : can't open input file %s\n", FN);
    return 0;
  }

  return 1;
}


unsigned char MMC_Read(unsigned long lba, unsigned char *pReadBuffer)
{
  uint32_t i;
  uint8_t * p;

  // seek file to requested position
  rewind(ifp);
  if(fseek(ifp, lba*512, SEEK_SET) != 0) {
    fprintf(stderr, "ERR : couldn't seek to position %u\n", lba*512);
    return 0;
  }

  if (pReadBuffer) {
    p = pReadBuffer;
    for(i=0; i<128; i++) {
      *(p++) = fgetc(ifp);
      *(p++) = fgetc(ifp);
      *(p++) = fgetc(ifp);
      *(p++) = fgetc(ifp);
    }
  }
  return 1;
}



