/* string.h */
/* 2012, rok.krajnc@gmail.com */

#ifndef __STRING_H__
#define __STRING_H__


// type definitions
//typedef unsigned int size_t;
#include <stddef.h>

#ifndef NULL
#define NULL 0
#endif


// basic string functions
size_t  strlen  (const char *s);
char   *strcpy  (char *dest,     const char *src);
char   *strncpy (char *dest,     const char *src, size_t n);
char   *strcat  (char *dest,     const char *src);
char   *strncat (char *dest,     const char *src, size_t n);
int     strcmp  (const char *s1, const char *s2);
int     strncmp (const char *s1, const char *s2,  size_t n);
char   *strchr  (const char *s,  int c);
char   *strrchr (const char *s,  int c);

// basic mem functions
void   *memcpy  (void *dest,     const void *src, size_t n);
void   *memmove (void *dest,     void *src,       size_t n);
int     memcmp  (const void *s1, const void *s2,  size_t n);
void   *memchr  (const void *s,  int c,           size_t n);
void   *memset  (void *d,        int c,           size_t n);

// other functions
char *next_word(char *c);


#endif // __STRING_H__

