/* string.c */
/* 2012, rok.krajnc@gmail.com */


#include "string.h"

/* returns number of characters in s (not including terminating null character) */
size_t strlen(const char *s)
{
  size_t cnt = 0;

  /* count the length of string s, not including the \0 character */
  while (*s++)
    cnt++;

  return cnt;
}


/* Copy 'src' to 'dest'. Strings may not overlap. */
char *strcpy(char *dest, const char *src)
{
  char *d = dest;

  /* copy src to dest */
  while ( (*dest++ = *src++) );

  return d;
}


char *strncpy(char *dest, const char *src, size_t n)
{
  char *d = dest;

  /* copy src to dest */
  while ( *src && n ) {
    *dest++ = *src++;
    n--;
  }

  /* fill the remainder of d with nulls */
  while (n--)
    *dest++ = '\0';

  return d;
}


char *strcat(char *dest, const char *src)
{
  char *d = dest;

  /* find the end of the destination string */
  while (*dest++);

  /* append the source string to the destination string */
  while ( (*dest++ = *src++) );

  return d;
}


char *strncat(char *dest, const char *src, size_t n)
{
  char *d = dest;

  /* find the end of the destination string */
  while (*dest++);

  /* copy src to dest */
  while ( (*dest = *src) && n-- ) {
    dest++;
    src++;
  }


  /* add terminating '\0' character */
  *dest = '\0';

  return d;
}


int strcmp(const char *s1, const char *s2)
{
  while ( *s1 && (*s1 == *s2) ) {
    s1++;
    s2++;
  }

  return *s1 - *s2;
}


int strncmp(const char *s1, const char *s2, size_t n)
{
	if (n == 0)
		return 0;

  while ( *s1 && (*s1 == *s2) && --n ) {
    s1++;
    s2++;
  }

  return *s1 - *s2;
}


char *strchr(const char *s, int c)
{
  /* search for the character c */
  while (*s && (*s != c) )
    s++;

  return (char *)s;
}


char *strrchr(const char *s, int c)
{
  char *fnd = NULL;

  /* search for the character c */
  while (*s) {
    if (*s == c)
      fnd = (char *)s;
    s++;
  }

  return fnd;
}


/* Basic mem functions */
void *memcpy(void *dest, const void *src, size_t n)
{
  /* check if 'src' and 'dest' are on LONG boundaries */
  if ( (sizeof(unsigned long) -1) & ((unsigned long)dest | (unsigned long)src) ) {
    /* no, do a byte-wide copy */
    char *cs = (char *) src;
    char *cd = (char *) dest;

    while (n--)
      *cd++ = *cs++;
  } else {
    /* yes, speed up copy process */
    /* copy as many LONGs as possible */
    long *ls = (long *)src;
    long *ld = (long *)dest;

    size_t cnt = n >> 2;
    while (cnt--)
      *ld++ = *ls++;

    /* finally copy the remaining bytes */
    char *cs = (char *) (src + (n & ~0x03));
    char *cd = (char *) (dest + (n & ~0x03));

    cnt = n & 0x3;
    while (cnt--)
      *cd++ = *cs++;
  }

  return dest;
}


void *memmove(void *dest, void *src, size_t n)
{
  char *d = dest;
  char *s = src;

  while (n--)
    *d++ = *s++;

  return dest;
}


int memcmp(const void *s1, const void *s2, size_t n)
{
  char *p1 = (void *)s1;
  char *p2 = (void *)s2;

  while ( (*p1 == *p2) && n-- ) {
    p1++;
    p2++;
  }

  return *p1 - *p2;
}


void *memchr(const void *s, int c, size_t n)
{
  char *p = (void *)s;

  /* search for the character c */
  while ( (*p != c) && n-- )
    p++;

  return (*p == c) ? p : NULL;
}


void *memset(void *s, int c, size_t n)
{
  char *p = s;

  while (n--)
    *p++ = c;

  return s;
}


char *next_word(char *c)
{
  while ((*c!=0) && (*c!=' ')) c++;
  while (*c==' ') c++;
  if (*c==0) return NULL;
  else return c;
}

