#include <stdio.h>
#include <stdlib.h>
#include "fat.h"
#include "mmc.h"

FILE* ifp;

int main()
{

  // init
  fprintf(stderr, "MMC_Init()\n");
  if(!MMC_Init()) fprintf(stderr, "ERR : MMC_Init() failed\n");

  // find drive
  fprintf(stderr, "FindDrive()\n");
  if(!FindDrive()) fprintf(stderr, "ERR : FindDrive() failed\n");

  exit (EXIT_SUCCESS);
}

