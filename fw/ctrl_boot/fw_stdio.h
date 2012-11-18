/* fw_stdio.h */
/* 2012, rok.krajnc@gmail.com */

#ifndef __FW_STDIO_H__
#define __FW_STDIO_H__

#include "hardware.h"
  
// macros for converting digits to letters and vice versa
#define to_char(n)  ((n) + '0')
#define to_digit(c) ((c) - '0')
#define is_digit(c) ((unsigned)to_digit(c) <= 9)
#define to_xdigit(c) (((c)<='9') ? (c) - '0' : ((c)<='F') ? (c) - 'A' + 10 : (c) - 'a' + 10)
#define is_xdigit(c) ((unsigned)to_xdigit(c) <= 15)

/* prints a number x, in l chars long string, if s is set number is signed, r = radix */
void uprintnum(int x, int l, int s, int r);

/* parses decimal number */
char *scand(char *s, int *f);

/* parses hex number */
char *scanh(char *s, unsigned *f);

/* parses decimal or hex number */
char *scani(char *s, int *f);

/* printf like function
   supports %. where '.' can be:
   % - '%' char
   b - binary
   o - octal
   d - decimal  
   x - hex
   f - fixed point
   c - char
   s - string

   any format can be preceded by a positive number, specifying the output string lenght, e.g.:
   uprintf("%5b", 10); // prints '  110'
*/
void vprintf(char, void (*pc)(const char), const char *fmt0, ...);

#define  printf(x ...) vprintf(0, putchar, x)

#define uprintf(x ...) vprintf(0, uputchar, x)
#define sprintf(x ...) vprintf(1, sputchar, x)
#define qprintf(x ...) vprintf(0, qputchar, x)
#define pprintf(x ...) vprintf(0, pputchar, x)


#endif

