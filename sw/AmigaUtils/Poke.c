/*
// Poke.c
// 2013, rok.krajnc@gmail.com
// Sets memory location to data
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char** argv)
{
  unsigned int adr, dat;

  if (argc != 3) {
    fprintf(stderr, "Usage: %s address data\n", argv[0]);
    exit(EXIT_FAILURE);
  }

  adr = strtoul(argv[1], NULL, 0);
  dat = strtoul(argv[2], NULL, 0);

  *((unsigned int*)(adr)) = dat;

  exit(EXIT_SUCCESS);
}

