#include <stdlib.h>
#include <stdio.h>
#include <string.h>

int main()
{
  unsigned int ddfseq;

  printf("old sequencer:\n");
  printf("ddfseq shres hires lores\n");
  for (ddfseq=0; ddfseq<8; ddfseq++) {
    unsigned int ddfseq_neg = (~ddfseq);
    unsigned int shres = (((ddfseq_neg&1)?1:0)<<0);
    unsigned int hires = (((ddfseq_neg&1)?1:0)<<1) | (((ddfseq_neg&2)?1:0)<<0);
    unsigned int lores = (((ddfseq_neg&1)?1:0)<<2) | (((ddfseq_neg&2)?1:0)<<1) | (((ddfseq_neg&4)?1:0)<<0);
    printf("%01d      %01d     %01d     %01d\n", ddfseq, shres, hires, lores);
  }
  printf("\n");

  printf("new sequencer:\n");
  printf("  mode 1 = 2-fetch sequence (SHRES FMode = 0)\n");
  printf("  mode 2 = 4-fetch sequence (HRES FMode = 0, SHRES FMode = 1)\n");
  printf("  mode 3 = 8-fetch sequence (LRES FMode = 0, HRES FMode = 1, SHRES, FMode = 3)\n");
  printf("  mode 4 = 8-fetch sequence followed by 8 free cycles (LRES FMode = 1, HRES FMode = 3)\n");
  printf("  mode 5 = 8-fetch sequence followed by 24 free cycles (LRES FMode = 3)\n");
  printf("ddfseq 01 02 03 04 05\n");
  for (ddfseq=0; ddfseq<32; ddfseq++) {
    unsigned int ddfseq_neg = (~ddfseq);
    unsigned int m1 = (((ddfseq_neg&1)?1:0)<<0);
    unsigned int m2 = (((ddfseq_neg&1)?1:0)<<1) | (((ddfseq_neg&2)?1:0)<<0);
    unsigned int m3 = (((ddfseq_neg&1)?1:0)<<2) | (((ddfseq_neg&2)?1:0)<<1) | (((ddfseq_neg&4)?1:0)<<0);
    unsigned int m4 = (((ddfseq    &8)?1:0)<<3) | (((ddfseq_neg&1)?1:0)<<2) | (((ddfseq_neg&2)?1:0)<<1) | (((ddfseq_neg&4)?1:0)<<0);
    unsigned int m5 = (((ddfseq   &16)?1:0)<<4) | (((ddfseq    &8)?1:0)<<3) | (((ddfseq_neg&1)?1:0)<<2) | (((ddfseq_neg&2)?1:0)<<1) | (((ddfseq_neg&4)?1:0)<<0);
    printf("%02d     %02d %02d %02d %02d %02d\n", ddfseq, m1, m2, m3, m4, m5);
  }


  exit(EXIT_SUCCESS);
}

