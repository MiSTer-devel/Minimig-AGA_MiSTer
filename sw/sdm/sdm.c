// sdm.c


#include <stdio.h>
#include <stdlib.h>


int main (int argc, char** argv)
{
  int i;
  int a0;
  int a1;
  int step;
  int out;
  unsigned int n;

  a0 = 4;
  a1 = -4;
  step = a1 - a0;
  n=4;
  out = a0<<n;
  printf("a0=%d  a1=%d  step=%d  n=%d  out=%d\n", a0, a1, step, n, out);
  for (i=0; i<(1<<n); i++) {
    out += step;
    printf("%d  out=%d (%d)\n", i, out, out>>n);
  }
  printf("out>>n=%d\n", out>>n);

  exit(EXIT_SUCCESS);
}

