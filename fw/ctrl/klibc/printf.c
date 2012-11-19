#include <stdio.h>
#include <stdarg.h>

#include "hardware.h"

char buf[256];

int printf(const char *fmt,...)
{
	int i;
	
	va_list ap;
	va_start(ap, fmt);
	int num = vsnprintf(buf, 256, fmt, ap);
	va_end(ap);
	
	for(i=0;i<num;i++) {
		RS232(buf[i]);
	}
	
	return num;
}

#undef putchar

int putchar(int c)
{
	RS232(c);
	return 1;
}

int puts(const char *str)
{
	while(*str != '\0') {
		RS232(*str);
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
