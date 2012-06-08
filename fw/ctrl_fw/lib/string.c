/* string.c */
/* 2012, rok.krajnc@gmail.com */


#include "string.h"



//// basic string functions ////

// returns number of characters in s (not including terminating null character)
size_t strlen(const char *s)
{
  size_t cnt = 0;

  while (*s++) cnt++;

  return cnt;
}


// copy 'src' to 'dest' (strings may not overlap)
char *strcpy(char *dest, const char *src)
{
  char *d = dest;

  while ( (*dest++ = *src++) );

  return d;
}


// copy 'src' to 'dest' with size limit
char *strncpy(char *dest, const char *src, size_t n)
{
  char *d = dest;

  // copy src to dest
  while ( *src && n ) {
    *dest++ = *src++;
    n--;
  }

  // fill the remainder of d with nulls
  while (n--) *dest++ = '\0';

  return d;
}


// concatenate 'src' to 'dest' string
char *strcat(char *dest, const char *src)
{
  char *d = dest;

  // find the end of the destination string
  while (*dest++);

  // append the source string to the destination string
  while ( (*dest++ = *src++) );

  return d;
}


// concatenate 'src' to 'dest' string with size limit
char *strncat(char *dest, const char *src, size_t n)
{
  char *d = dest;

  // find the end of the destination string
  while (*dest++);

  // copy src to dest
  while ( (*dest = *src) && n-- ) {
    dest++;
    src++;
  }

  // add terminating '\0' character
  *dest = '\0';

  return d;
}


// compare 's1' to 's2', a zero return value means equal strings
int strcmp(const char *s1, const char *s2)
{
  while ( *s1 && (*s1 == *s2) ) {
    s1++;
    s2++;
  }

  return *s1 - *s2;
}


// compare up to 'n' characters of strings 's1' and 's2'
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


// locate first occurence of character 'c' in string 's'
char *strchr(const char *s, int c)
{
  // search for the character c
  while (*s && (*s != c) ) s++;

  return (char *)s;
}


// locate last occurence of character 'c' in string 's'
char *strrchr(const char *s, int c)
{
  char *fnd = NULL;

  // search for the character c
  while (*s) {
    if (*s == c)
      fnd = (char *)s;
    s++;
  }

  return fnd;
}



//// basic mem functions ////

// copy block of memory from 'src' to 'dest'
void *memcpy(void *dest, const void *src, size_t n)
{
  // check if 'src' and 'dest' are on LONG boundaries
  if ( (sizeof(unsigned long) -1) & ((unsigned long)dest | (unsigned long)src) ) {
    // no, do a byte-wide copy
    char *cs = (char *) src;
    char *cd = (char *) dest;
    while (n--)
      *cd++ = *cs++;
  } else {
    // yes, speed up copy process - copy as many LONGs as possible
    long *ls = (long *)src;
    long *ld = (long *)dest;

    size_t cnt = n >> 2;
    while (cnt--)
      *ld++ = *ls++;

    // finally copy the remaining bytes
    char *cs = (char *) (src + (n & ~0x03));
    char *cd = (char *) (dest + (n & ~0x03));

    cnt = n & 0x3;
    while (cnt--)
      *cd++ = *cs++;
  }

  return dest;
}


// copy 'n' bytes of memory from 'src' to 'dest'
void *memmove(void *dest, void *src, size_t n)
{
  char *d = dest;
  char *s = src;

  while (n--)
    *d++ = *s++;

  return dest;
}


// compare two blocks of memory up to 'n' bytes
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


// locate character 'c' in the first 'n' bytes of memory block 's'
void *memchr(const void *s, int c, size_t n)
{
  char *p = (void *)s;

  // search for the character c
  while ( (*p != c) && n-- )
    p++;

  return (*p == c) ? p : NULL;
}


// fill up to 'n' bytes of memory block 's' with character 'c'
void *memset(void *s, int c, size_t n)
{
  char *p = s;

  while (n--)
    *p++ = c;

  return s;
}



//// other functions ////

// locate start of word in string 'c'
char *next_word(char *c)
{
  while ((*c!=0) && (*c!=' ')) c++;
  while (*c==' ') c++;
  if (*c==0) return NULL;
  else return c;
}


