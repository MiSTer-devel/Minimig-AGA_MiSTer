
#include "string.h"


void *memchr(const void *s, int c, size_t n)
{
  const unsigned char *sp = s;

  while (n--) {
    if (*sp == (unsigned char)c)
      return (void *)sp;
    sp++;
  }

  return NULL;
}


int memcmp(const void *s1, const void *s2, size_t n)
{
  const unsigned char *c1 = s1, *c2 = s2;
  int d = 0;

  while (n--) {
    d = (int)*c1++ - (int)*c2++;
    if (d)
      break;
  }

  return d;
}


void *memcpy(void *dst, const void *src, size_t n)
{
  const char *p = src;
  char *q = dst;

  while (n--) {
    *q++ = *p++;
  }

  return dst;
}


void *memmove(void *dst, const void *src, size_t n)
{
  const char *p = src;
  char *q = dst;

  if (q < p) {
    while (n--) {
      *q++ = *p++;
    }
  } else {
    p += n;
    q += n;
    while (n--) {
      *--q = *--p;
    }
  }

  return dst;
}


void *memrchr(const void *s, int c, size_t n)
{
  const unsigned char *sp = (const unsigned char *)s + n - 1;

  while (n--) {
    if (*sp == (unsigned char)c)
      return (void *)sp;
    sp--;
  }

  return NULL;
}


void *memset(void *dst, int c, size_t n)
{
  char *q = dst;

  while (n--) {
    *q++ = c;
  }

  return dst;
}


void memswap(void *m1, void *m2, size_t n)
{
  char *p = m1;
  char *q = m2;
  char tmp;

  while (n--) {
    tmp = *p;
    *p = *q;
    *q = tmp;

    p++;
    q++;
  }
}




int strcasecmp(const char *s1, const char *s2)
{
  const unsigned char *c1 = (const unsigned char *)s1;
  const unsigned char *c2 = (const unsigned char *)s2;
  unsigned char ch;
  int d = 0;

  while (1) {
    /* toupper() expects an unsigned char (implicitly cast to int)
       as input, and returns an int, which is exactly what we want. */
    d = toupper(ch = *c1++) - toupper(*c2++);
    if (d || !ch)
      break;
  }

  return d;
}


char *strcat(char *dst, const char *src)
{
  strcpy(strchr(dst, '\0'), src);
  return dst;
}


char *strchr(const char *s, int c)
{
  while (*s != (char)c) {
    if (!*s)
      return NULL;
    s++;
  }

  return (char *)s;
}


int strcmp(const char *s1, const char *s2)
{
  const unsigned char *c1 = (const unsigned char *)s1;
  const unsigned char *c2 = (const unsigned char *)s2;
  unsigned char ch;
  int d = 0;

  while (1) {
    d = (int)(ch = *c1++) - (int)*c2++;
    if (d || !ch)
      break;
  }

  return d;
}


char *strcpy(char *dst, const char *src)
{
  char *q = dst;
  const char *p = src;
  char ch;

  do {
    *q++ = ch = *p++;
  } while (ch);

  return dst;
}

/*
char *strdup(const char *s)
{
  int l = strlen(s) + 1;
  char *d = malloc(l);

  if (d)
    memcpy(d, s, l);

  return d;
}
*/

size_t strlcat(char *dst, const char *src, size_t size)
{
  size_t bytes = 0;
  char *q = dst;
  const char *p = src;
  char ch;

  while (bytes < size && *q) {
    q++;
    bytes++;
  }
  if (bytes == size)
    return (bytes + strlen(src));

  while ((ch = *p++)) {
    if (bytes + 1 < size)
      *q++ = ch;

    bytes++;
  }

  *q = '\0';
  return bytes;
}


size_t strlcpy(char *dst, const char *src, size_t size)
{
  size_t bytes = 0;
  char *q = dst;
  const char *p = src;
  char ch;

  while ((ch = *p++)) {
    if (bytes + 1 < size)
      *q++ = ch;

    bytes++;
  }

  /* If size == 0 there is no space for a final null... */
  if (size)
    *q = '\0';

  return bytes;
}


size_t strlen(const char *s)
{
  const char *ss = s;
  while (*ss)
    ss++;
  return ss - s;
}


int strncasecmp(const char *s1, const char *s2, size_t n)
{
  const unsigned char *c1 = (const unsigned char *)s1;
  const unsigned char *c2 = (const unsigned char *)s2;
  unsigned char ch;
  int d = 0;

  while (n--) {
    /* toupper() expects an unsigned char (implicitly cast to int)
       as input, and returns an int, which is exactly what we want. */
    d = toupper(ch = *c1++) - toupper(*c2++);
    if (d || !ch)
      break;
  }

  return d;
}


char *strncat(char *dst, const char *src, size_t n)
{
  char *q = strchr(dst, '\0');
  const char *p = src;
  char ch;

  while (n--) {
    *q++ = ch = *p++;
    if (!ch)
      return dst;
  }
  *q = '\0';

  return dst;
}


int strncmp(const char *s1, const char *s2, size_t n)
{
  const unsigned char *c1 = (const unsigned char *)s1;
  const unsigned char *c2 = (const unsigned char *)s2;
  unsigned char ch;
  int d = 0;

  while (n--) {
    d = (int)(ch = *c1++) - (int)*c2++;
    if (d || !ch)
      break;
  }

  return d;
}


char *strncpy(char *dst, const char *src, size_t n)
{
  char *q = dst;
  const char *p = src;
  char ch;

  while (n) {
    n--;
    *q++ = ch = *p++;
    if (!ch)
      break;
  }

  /* The specs say strncpy() fills the entire buffer with NUL.  Sigh. */
  memset(q, 0, n);

  return dst;
}

/*
char *strndup(const char *s, size_t n)
{
  size_t l = strnlen(s, n);
  char *d = malloc(l + 1);
  if (!d)
    return NULL;

  memcpy(d, s, l);
  d[l] = '\0';
  return d;
}
*/

size_t strnlen(const char *s, size_t maxlen)
{
  const char *ss = s;

  /* Important: the maxlen test must precede the reference through ss;
     since the byte beyond the maximum may segfault */
  while ((maxlen > 0) && *ss) {
    ss++;
    maxlen--;
  }
  return ss - s;
}


char *strrchr(const char *s, int c)
{
  const char *found = NULL;

  while (*s) {
    if (*s == (char)c)
      found = s;
    s++;
  }

  return (char *)found;
}




int toupper(int c)
{
  if( c>='a' && c<='z') return (c +'A' - 'a');
  else return c;
}


int tolower(int c)
{
  if((c>='A')&&(c<='Z')) return (c + 'a' - 'A');
  else return c;
}

