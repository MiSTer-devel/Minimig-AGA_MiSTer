#include "stdio.h"
#include "stdarg.h"

char buf[256];

#define TX ((volatile char *)0xda8001)

int printf(const char *fmt,...)
{
	int i;
	
	va_list ap;
	va_start(ap, fmt);
	int num = vsnprintf(buf, 256, fmt, ap);
	va_end(ap);
	
	for(i=0;i<num;i++) {
		*TX = buf[i];
	}
	
	return num;
}

#undef putchar

int putchar(int c)
{
	*TX = (char)c;
	return 1;
}

int puts(const char *str)
{
	while(*str != '\0') {
		*TX = *str;
		str++;
	}
	return 0;
}

int tolower(int c)
{
	if((c>='A')&&(c<='Z')) {
		return c + 'a' - 'A';
	} else {
		return c;
	}
}
