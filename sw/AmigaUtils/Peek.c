/*
// peek.c
// 2013, rok.krajnc@gmail.com
// Reads memory location
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char** argv)
{
  unsigned int adr, dat;

  if (argc != 2) {
    fprintf(stderr, "Usage: %s address\n", argv[0]);
    exit(EXIT_FAILURE);
  }

  adr = strtoul(argv[1], NULL, 0);
  dat = *((unsigned int*)(adr));

  fprintf(stdout, "*(0x%08x) = 0x%08x\n", adr, dat);

  exit(EXIT_SUCCESS);
}

