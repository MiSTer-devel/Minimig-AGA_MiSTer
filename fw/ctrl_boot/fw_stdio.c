/* fw_stdio.c */
/* 2012, rok.krajnc@gmail.com */

#include <stdarg.h>
#include "string.h"
#include "fw_stdio.h"


/* prints a number x, in l chars long string, if s is set number is signed, r = radix */
void vprintnum(void (*pc)(char), int x, int l, int s, int r)
{
  const char *digs = "0123456789abcdef";
  unsigned u = (unsigned)x;
  char buf[32];
  int n = 0;
  int sign = 0;

  if (r < 0) {
    r = -r;
    digs = "0123456789ABCDEF";
  }

  if (s) {
    if (x < 0) {
      sign = 1;
      u = -x;
    }
  }

  if (u == 0) {
    buf[n++] = '0';
  } else {
    while (u > 0) {
      buf[n++] = digs[u % r];
      u /= r;
    }
  }
  if (sign)
    buf[n++] = '-';

  if (l > 0) {
    while (l-- > n)
      pc('0');
  }
  while (n)
    pc(buf[--n]);

  while (l++ < 0)
    pc(' ');
}


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
void vprintf(char null_terminated, void (*pc)(char), const char *fmt0, ...)
{
  const char *fmt;  /* format string */
  va_list args;
  int l, t;
  char *s;
  va_start (args, fmt0);

  //assert(fmt0 != NULL);

  for (fmt = fmt0; *fmt;) {
    if (*fmt == '%') {
      l = 0;
      fmt++;
reformat:
      switch (*(fmt++)) {
      case '%':
        pc('%');
        break;
      case 'd':
        vprintnum(pc, va_arg(args, int), l, 1, 10);
        break;
      case 'b':
        vprintnum(pc, va_arg(args, int), l, 0, 2);
        break;
      case 'o':
        vprintnum(pc, va_arg(args, int), l, 0, 8);
        break;
      case 'X':
        vprintnum(pc, va_arg(args, int), l, 0, -16);
        break;
      case 'x':
        vprintnum(pc, va_arg(args, int), l, 0, 16);
        break;
      case 'c':
        while (l-- > 1)
          pc(' ');
        pc(va_arg(args, int));
        break;
      case 's':
        s = va_arg(args, char *);
        if (s == NULL)
          s = "(null)";

        t = strlen(s);
        l -= t;
        if (l < 0) l = 0;
        while (l--)
          pc(' ');
        while (*s)
          pc(*s++);
        break;
      default:
        t = *(fmt - 1) - '0';
        //assert(t >= 0 && t <= 9);
        l = l * 10 + t;
        goto reformat;
      }
    } else
      pc(*(fmt++));
  }

  va_end (args);
  
  if (null_terminated)
    pc('\0');
}


/* parses decimal number */
char *scand(char *s, int *f)
{
  int sign = 0;
  int d = 0;
  if (*s == '-') {
    sign = 1;
    s++;
  }
  while (*s >= '0' && *s <= '9') {
    d = d * 10 + *s - '0';
    s++;
  }
  *f = sign ? -d : d;
  return s;
}


/* parses hex number */
char *scanh(char *s, unsigned *f)
{
  int d = 0;
  while ((*s >= '0' && *s <= '9') || (*s >= 'A' && *s <= 'F') || (*s >= 'a' && *s <= 'f')) {
    int t;
    if (*s >= 'a')
      t = *s - 'a' + 10;
    else if (*s >= 'A')
      t = *s - 'A' + 10;
    else
      t = *s - '0';

    d = d * 16 + t;
    s++;
  }
  *f = d;
  return s;
}


/* parses decimal or hex number */
 char *scani(char *s, int *f)
{
  if (*s == '0' && *(s+1) == 'x') {
    s += 2;
    return scanh(s, (unsigned *)f);
  }
  return scand(s, f);
}

