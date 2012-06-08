/* stdio.h */
/* 2012, rok.krajnc@gmail.com */

#ifndef __STDIO_H__
#define __STDIO_H__

#include <stddef.h>
#include <stdarg.h>


// macros for converting digits to letters and vice versa
#define to_char(n)  ((n) + '0')
#define to_digit(c) ((c) - '0')
#define is_digit(c) ((unsigned)to_digit(c) <= 9)
#define to_xdigit(c) (((c)<='9') ? (c) - '0' : ((c)<='F') ? (c) - 'A' + 10 : (c) - 'a' + 10)
#define is_xdigit(c) ((unsigned)to_xdigit(c) <= 15)


int vsnprintf(char *buffer, size_t n, const char *format, va_list ap);
int sprintf(char *buffer, const char *format, ...);
int printf(const char *fmt,...);
#undef putchar
int putchar(int c);
int puts(const char *str);
int tolower(int c);



#endif // __STDIO_H__

