/*
Copyright 2005, 2006, 2007 Dennis van Weeren
Copyright 2008, 2009 Jakub Bednarski

This file is part of Minimig

Minimig is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3 of the License, or
(at your option) any later version.

Minimig is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

This is the Minimig OSD (on-screen-display) handler.

2012-02-09 - Split character rom out to separate header file, with upper 128 entries
             as rotated copies of the first 128 entries.  -- AMR

29-12-2006 - created
30-12-2006 - improved and simplified
-- JB --
2008-10-04 - ARM version
2008-10-26 - added cpu and floppy configuration functions
2008-12-31 - added enable HDD command
2009-02-03 - full keyboard support
2009-06-23 - hires OSD display
2009-08-23 - adapted ConfigIDE() - support for 2 hardfiles
*/

//#include "AT91SAM7S256.h"
#include "osd.h"
#include "hardware.h"
#include "stdio.h"

#include "charrom.h"
#include "logo.h"

#include "string.h"

// conversion table of Amiga keyboard scan codes to ASCII codes
const char keycode_table[128] =
{
      0,'1','2','3','4','5','6','7','8','9','0',  0,  0,  0,  0,  0,
    'Q','W','E','R','T','Y','U','I','O','P',  0,  0,  0,  0,  0,  0,
    'A','S','D','F','G','H','J','K','L',  0,  0,  0,  0,  0,  0,  0,
      0,'Z','X','C','V','B','N','M',  0,  0,  0,  0,  0,  0,  0,  0,
      0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
      0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
      0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
      0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
};

struct star
{
	int x, y;
	int dx, dy;
};

struct star stars[64];
char framebuffer[8][256];


void framebuffer_clear()
{
  DEBUG_FUNC_IN(DEBUG_F_OSD | DEBUG_L2);

	int i,j;
	for(i=0;i<8;++i)
	{
		for(j=0;j<256;++j)
		{
			framebuffer[i][j]=0;
		}
	}

  DEBUG_FUNC_OUT(DEBUG_F_OSD | DEBUG_L2);
}


void framebuffer_plot(int x,int y)
{
  DEBUG_FUNC_IN(DEBUG_F_OSD | DEBUG_L2);

	framebuffer[y/8][x]|=(1<<(y & 7));

  DEBUG_FUNC_OUT(DEBUG_F_OSD | DEBUG_L2);
}


static int quickrand()
{
  DEBUG_FUNC_IN(DEBUG_F_OSD | DEBUG_L2);

	static int prev;
	int r=*(volatile unsigned long *)0x80000c;
	r^=(prev&0xc75a)<<4;
	r^=(prev&0x5a7c)>>(prev&7);
	prev=r;
	return(r);

  DEBUG_FUNC_OUT(DEBUG_F_OSD | DEBUG_L2);
}


void StarsInit()
{
  DEBUG_FUNC_IN(DEBUG_F_OSD | DEBUG_L1);

	int i;
	for(i=0;i<64;++i)
	{
		stars[i].x=(quickrand()%228)<<4;	// X centre
		stars[i].y=(quickrand()%56)<<4;	// Y centre
			stars[i].dx=-(quickrand()&7)-3;
		stars[i].dy=0;
	}

  DEBUG_FUNC_OUT(DEBUG_F_OSD | DEBUG_L1);
}


void StarsUpdate()
{
  DEBUG_FUNC_IN(DEBUG_F_OSD | DEBUG_L2);

	framebuffer_clear();
	int i;
	for(i=0;i<64;++i)
	{
		stars[i].x+=stars[i].dx;
		stars[i].y+=stars[i].dy;
		if((stars[i].x<0)||(stars[i].x>(228<<4)) ||
			(stars[i].y<0)||(stars[i].y>(56<<4)))
		{
			stars[i].x=228<<4;
			stars[i].y=(quickrand()%56)<<4;
			stars[i].dx=-(quickrand()&7)-3;
			stars[i].dy=0;
		}			
		framebuffer_plot(stars[i].x>>4,stars[i].y>>4);
	}

  DEBUG_FUNC_OUT(DEBUG_F_OSD | DEBUG_L2);
}


// time delay after which file/dir name starts to scroll
#define SCROLL_DELAY 1000
#define SCROLL_DELAY2 50

static unsigned long scroll_offset=0; // file/dir name scrolling position
static unsigned long scroll_timer=0;  // file/dir name scrolling timer

extern char s[40];

static int arrow;
static unsigned char titlebuffer[64];

static void rotatechar(unsigned char *in,unsigned char *out)
{
  DEBUG_FUNC_IN(DEBUG_F_OSD | DEBUG_L2);

	int a;
	int b;
	int c;
	for(b=0;b<8;++b)
	{
		a=0;
		for(c=0;c<8;++c)
		{
			a<<=1;
			a|=(in[c]>>b)&1;
		}
		out[b]=a;
	}		

  DEBUG_FUNC_OUT(DEBUG_F_OSD | DEBUG_L2);
}


void OsdSetTitle(char *s,int a)
{
  DEBUG_FUNC_IN(DEBUG_F_OSD | DEBUG_L2);

	// Compose the title, condensing character gaps
	arrow=a;
	char zeros=0;
	int i=0;
  char j=0;
	int outp=0;
	while(1)
	{
		int c=s[i++];
		if(c && (outp<64))
		{
	        unsigned char *p = &charfont[c][0];
			for(j=0;j<8;++j)
			{
				unsigned char nc=*p++;
				if(nc)
				{
					zeros=0;
					titlebuffer[outp++]=nc;
				}
				else if(zeros==0)
				{
					titlebuffer[outp++]=0;
					zeros=1;
				}
				if(outp>63)
					break;
			}
		}
		else
			break;
	}
	for(i=outp;i<64;++i)
	{
		titlebuffer[i]=0;
	}

	// Now centre it:
	int c=(63-outp)/2;
	for(i=(63-c);i>=0;--i)
	{
		titlebuffer[i+c]=titlebuffer[i];
	}
	for(i=0;i<c;++i)
		titlebuffer[i]=0;

	// Finally rotate it.
	for(i=0;i<64;i+=8)
	{
		unsigned char tmp[8];
		rotatechar(&titlebuffer[i],tmp);
		for(c=0;c<8;++c)
		{
			titlebuffer[i+c]=tmp[c];
		}
	}

  DEBUG_FUNC_OUT(DEBUG_F_OSD | DEBUG_L2);
}


void OsdWrite(unsigned char n, char *s, unsigned char invert, unsigned char stipple)
{
  DEBUG_FUNC_IN(DEBUG_F_OSD | DEBUG_L2);

	OsdWriteOffset(n,s,invert,stipple,0);

  DEBUG_FUNC_OUT(DEBUG_F_OSD | DEBUG_L2);
}


// write a null-terminated string <s> to the OSD buffer starting at line <n>
void OsdWriteOffset(unsigned char n, char *s, unsigned char invert, unsigned char stipple,char offset)
{
  DEBUG_FUNC_IN(DEBUG_F_OSD | DEBUG_L2);

    unsigned short i;
    unsigned char b;
    const unsigned char *p;
	unsigned char stipplemask=0xff;
	int linelimit=OSDLINELEN;
	int arrowmask=arrow;
	if(n==7 && (arrow & OSD_ARROW_RIGHT))
		linelimit-=22;

	if(stipple)
	{
		stipplemask=0x55;
		stipple=0xff;
	}
	else
		stipple=0;

    // select OSD SPI device
    EnableOsd();

    // select buffer and line to write to
//    if (invert)
//        SPI(OSDCMDWRITE | 0x10 | n);
//    else
        //SPI(OSDCMDWRITE | n);
        SPI(OSD_CMD_OSD_WR);
        SPI(0x00); SPI(0x00); SPI(0x00); SPI(n);

	if(invert)
		invert=255;

    i = 0;
    // send all characters in string to OSD
    while (1)
    {
		if(i==0)	// Render sidestripe
		{
	        p = &titlebuffer[(7-n)*8];
			SPI(0xff);
			SPI(0xff);
	        SPI(255^*p); SPI(255^*p++);
	        SPI(255^*p); SPI(255^*p++);
	        SPI(255^*p); SPI(255^*p++);
	        SPI(255^*p); SPI(255^*p++);
	        SPI(255^*p); SPI(255^*p++);
	        SPI(255^*p); SPI(255^*p++);
	        SPI(255^*p); SPI(255^*p++);
	        SPI(255^*p); SPI(255^*p++);
			SPI(0xff);
			SPI(0xff);
			SPI(0x00);
			SPI(0x00);
	        i += 22;
		}
		else if(n==7 && (arrowmask & OSD_ARROW_LEFT))	// Draw initial arrow
		{
			SPI(0);
			SPI(0);
			SPI(0);
		    p = &charfont[0x10][0];
	        SPI(*p++<<offset); SPI(*p++<<offset); SPI(*p++<<offset); SPI(*p++<<offset);
	        SPI(*p++<<offset); SPI(*p++<<offset); SPI(*p++<<offset); SPI(*p++<<offset);
		    p = &charfont[0x14][0];
	        SPI(*p++<<offset); SPI(*p++<<offset); SPI(*p++<<offset); SPI(*p++<<offset);
	        SPI(*p++<<offset); SPI(*p++<<offset); SPI(*p++<<offset); SPI(*p++<<offset);
			SPI(0);
			SPI(0);
			SPI(0);
			SPI(invert);
			SPI(invert);
			i+=24;
			arrowmask&=~OSD_ARROW_LEFT;
			if(*s++ == 0) break;	// Skip 3 characters, to keep alignent the same.
			if(*s++ == 0) break;
			if(*s++ == 0) break;
		}
		else
		{
		    b = *s++;

		    if (b == 0) // end of string
		        break;

		    else if (b == 0x0d || b == 0x0a) // cariage return / linefeed, go to next line
		    {
		        // increment line counter
		        if (++n >= linelimit)
		            n = 0;
		        // send new line number to OSD
		        DisableOsd();
		        EnableOsd();
		        //SPI(OSDCMDWRITE | n);
            SPI(OSD_CMD_OSD_WR);
            SPI(0x00); SPI(0x00); SPI(0x00); SPI(n);

		    }
			else if(i<(linelimit-8)) // normal character
		    {
		        p = &charfont[b][0];
		        SPI(((*p++<<offset)&stipplemask)^invert);	stipplemask^=stipple;
		        SPI(((*p++<<offset)&stipplemask)^invert);	stipplemask^=stipple;
		        SPI(((*p++<<offset)&stipplemask)^invert);	stipplemask^=stipple;
		        SPI(((*p++<<offset)&stipplemask)^invert);	stipplemask^=stipple;
		        SPI(((*p++<<offset)&stipplemask)^invert);	stipplemask^=stipple;
		        SPI(((*p++<<offset)&stipplemask)^invert);	stipplemask^=stipple;
		        SPI(((*p++<<offset)&stipplemask)^invert);	stipplemask^=stipple;
		        SPI(((*p++<<offset)&stipplemask)^invert);	stipplemask^=stipple;
		        i += 8;
		    }
		}
    }
    for (; i < linelimit; i++) // clear end of line
       SPI(invert);
	if(n==7 && (arrowmask & OSD_ARROW_RIGHT))	// Draw final arrow if needed
	{
		SPI(0);
		SPI(0);
		SPI(0);
        p = &charfont[0x15][0];
        SPI(*p++<<offset); SPI(*p++<<offset); SPI(*p++<<offset); SPI(*p++<<offset);
        SPI(*p++<<offset); SPI(*p++<<offset); SPI(*p++<<offset); SPI(*p++<<offset);
        p = &charfont[0x11][0];
        SPI(*p++<<offset); SPI(*p++<<offset); SPI(*p++<<offset); SPI(*p++<<offset);
        SPI(*p++<<offset); SPI(*p++<<offset); SPI(*p++<<offset); SPI(*p++<<offset);
		SPI(0);
		SPI(0);
		SPI(0);
		i+=22;
	}

    // deselect OSD SPI device
    DisableOsd();

  DEBUG_FUNC_OUT(DEBUG_F_OSD | DEBUG_L2);
}


void OsdDrawLogo(unsigned char n, char row,char superimpose)
{
  DEBUG_FUNC_IN(DEBUG_F_OSD | DEBUG_L1);

    unsigned short i;
    const unsigned char *p;
	int linelimit=OSDLINELEN;

    // select OSD SPI device
    EnableOsd();

    // select buffer and line to write to
    //SPI(OSDCMDWRITE | n);
    SPI(OSD_CMD_OSD_WR);
    SPI(0x00); SPI(0x00); SPI(0x00); SPI(n);

	const unsigned char *lp=logodata[(int)row];
	int bytes=sizeof(logodata[0]);
	if((unsigned int)row>=(sizeof(logodata)/bytes))
		lp=0;
    i = 0;
    // send all characters in string to OSD

	if(superimpose)
	{
		char *bg=framebuffer[n];
		while (bytes)
		{
			if(i==0)	// Render sidestripe
			{
			    p = &titlebuffer[(7-n)*8];
				SPI(0xff);
				SPI(0xff);
			    SPI(255^*p); SPI(255^*p++);
			    SPI(255^*p); SPI(255^*p++);
			    SPI(255^*p); SPI(255^*p++);
			    SPI(255^*p); SPI(255^*p++);
			    SPI(255^*p); SPI(255^*p++);
			    SPI(255^*p); SPI(255^*p++);
			    SPI(255^*p); SPI(255^*p++);
			    SPI(255^*p); SPI(255^*p++);
				SPI(0xff);
				SPI(0xff);
				SPI(0x00);
				SPI(0x00);
			    i += 22;
			}
			if(i>=linelimit)
				break;
			if(lp)
				SPI(*lp++ | *bg++);
			else
				SPI(*bg++);
			--bytes;
			++i;
		}
	    for (; i < linelimit; i++) // clear end of line
	       SPI(*bg++);
    }
	else
	{
		while (bytes)
		{
			if(i==0)	// Render sidestripe
			{
			    p = &titlebuffer[(7-n)*8];
				SPI(0xff);
				SPI(0xff);
			    SPI(255^*p); SPI(255^*p++);
			    SPI(255^*p); SPI(255^*p++);
			    SPI(255^*p); SPI(255^*p++);
			    SPI(255^*p); SPI(255^*p++);
			    SPI(255^*p); SPI(255^*p++);
			    SPI(255^*p); SPI(255^*p++);
			    SPI(255^*p); SPI(255^*p++);
			    SPI(255^*p); SPI(255^*p++);
				SPI(0xff);
				SPI(0xff);
				SPI(0x00);
				SPI(0x00);
			    i += 22;
			}
			if(i>=linelimit)
				break;
			if(lp)
				SPI(*lp++);
			else
				SPI(0);
			--bytes;
			++i;
		}
	    for (; i < linelimit; i++) // clear end of line
	       SPI(0);
	}
    // deselect OSD SPI device
    DisableOsd();

  DEBUG_FUNC_OUT(DEBUG_F_OSD | DEBUG_L1);
}


void OsdWriteDoubleSize(unsigned char n, char *s, unsigned char pass)
{
  DEBUG_FUNC_IN(DEBUG_F_OSD | DEBUG_L2);

    unsigned short i;
    unsigned char b;
    const unsigned char *p;
	int linelimit=OSDLINELEN;

    // select OSD SPI device
    EnableOsd();

    // select buffer and line to write to
    //SPI(OSDCMDWRITE | n);
    SPI(OSD_CMD_OSD_WR);
    SPI(0x00); SPI(0x00); SPI(0x00); SPI(n);

    i = 0;
    // send all characters in string to OSD
    while (1)
    {
		if(i==0)	// Render sidestripe
		{
	        p = &titlebuffer[(7-n)*8];
			SPI(0xff);
			SPI(0xff);
	        SPI(255^*p); SPI(255^*p++);
	        SPI(255^*p); SPI(255^*p++);
	        SPI(255^*p); SPI(255^*p++);
	        SPI(255^*p); SPI(255^*p++);
	        SPI(255^*p); SPI(255^*p++);
	        SPI(255^*p); SPI(255^*p++);
	        SPI(255^*p); SPI(255^*p++);
	        SPI(255^*p); SPI(255^*p++);
			SPI(0xff);
			SPI(0xff);
			SPI(0x00);
			SPI(0x00);
	        i += 22;
		}
		else
		{
		    b = *s++;

		    if (b == 0) // end of string
		        break;

			else if(i<(linelimit-16)) // normal character
		    {
				int c;
		        p = &charfont[b][0];
				if(pass)	// Draw the bottom half..
				{
					int j;
					for(j=0;j<8;++j)
					{
						c=*p++;
						c=(c&0xf0)>>4;
						c=(c&0x08)<<1 | c;	// ....ABCD => ...AABCD
						c=(c&0x1c)<<1 | (c & 0x07);	// ...AABCD => ..AABBCD
						c=(c&0x3e)<<1 | (c & 0x03); // ..AABBCD => .AABBCCD
						c=c<<1 | (c&0x01); // .AABBCCD => AABBCCDD
						SPI(c); SPI(c);
					}
				}
				else	// Draw the top half...
				{
					int j;
					for(j=0;j<8;++j)
					{
						c=*p++;
						c=c&0xf;
						c=(c&0x08)<<1 | c;	// ....ABCD => ...AABCD
						c=(c&0x1c)<<1 | (c & 0x07);	// ...AABCD => ..AABBCD
						c=(c&0x3e)<<1 | (c & 0x03); // ..AABBCD => .AABBCCD
						c=c<<1 | (c&0x01); // .AABBCCD => AABBCCDD
						SPI(c); SPI(c);
					}
				}				
		        i += 16;
		    }
		}
    }
    for (; i < linelimit; i++) // clear end of line
       SPI(0);

    // deselect OSD SPI device
    DisableOsd();

  DEBUG_FUNC_OUT(DEBUG_F_OSD | DEBUG_L2);
}


// write a null-terminated string <s> to the OSD buffer starting at line <n>
void OSD_PrintText(unsigned char line, char *text, unsigned long start, unsigned long width, unsigned long offset, unsigned char invert)
{
  DEBUG_FUNC_IN(DEBUG_F_OSD | DEBUG_L2);

// line : OSD line number (0-7)
// text : pointer to null-terminated string
// start : start position (in pixels)
// width : printed text length in pixels
// offset : scroll offset in pixels counting from the start of the string (0-7)
// invert : invertion flag

    const unsigned char *p;
	int i,j;

    // select OSD SPI device
    EnableOsd();

    // select buffer and line to write to
//    if (invert)
//       SPI(OSDCMDWRITE | 0x10 | line);
//    else
    //SPI(OSDCMDWRITE | line);
    SPI(OSD_CMD_OSD_WR);
    SPI(0x00); SPI(0x00); SPI(0x00); SPI(line);

	if(invert)
		invert=0xff;

    p = &titlebuffer[(7-line)*8];
	if(start>2)
	{
		SPI(0xff); SPI(0xff); start-=2;
	}
	
	i=start>16 ? 16 : start;
	for(j=0;j<(i/2);++j)
	{
		SPI(255^*p); SPI(255^*p++);
	}
	if(i&1)
		SPI(255^*p);
	start-=i;

	if(start>2)
		SPI(0xff), SPI(0xff), start-=2;

    while (start--)
          SPI(0x00);

    if (offset)
    {
        width -= 8 - offset;
        p = &charfont[(unsigned int)*text++][offset];
        for (; offset < 8; offset++)
            SPI(*p++^invert);
    }

    while (width > 8)
    {
            p = &charfont[(unsigned int)*text++][0];
            SPI(*p++^invert);
            SPI(*p++^invert);
            SPI(*p++^invert);
            SPI(*p++^invert);
            SPI(*p++^invert);
            SPI(*p++^invert);
            SPI(*p++^invert);
            SPI(*p++^invert);
            width -= 8;
    }

    if (width)
    {
        p = &charfont[(unsigned int)*text++][0];
        while (width--)
              SPI(*p++^invert);
    }

    DisableOsd();

  DEBUG_FUNC_OUT(DEBUG_F_OSD | DEBUG_L2);
}


// clear OSD frame buffer
void OsdClear(void)
{
  DEBUG_FUNC_IN(DEBUG_F_OSD | DEBUG_L2);

    unsigned short n;

    // select OSD SPI device
    EnableOsd();

    // select buffer to write to
    //SPI(OSDCMDWRITE | 0x18);
    SPI(OSD_CMD_OSD_WR);
    SPI(0x00); SPI(0x00); SPI(0x00); SPI(0x18);

    // clear buffer
    for (n = 0; n < (OSDLINELEN * OSDNLINE); n++)
        SPI(0x00);

    // deselect OSD SPI device
    DisableOsd();

  DEBUG_FUNC_OUT(DEBUG_F_OSD | DEBUG_L2);
}


void OsdWaitVBL(void)
{
  DEBUG_FUNC_IN(DEBUG_F_OSD | DEBUG_L1);

//    unsigned long pioa_old = 0;
//    unsigned long pioa = 0;
//
//    while ((~pioa ^ pioa_old) & INIT_B)
//    {
//        pioa_old = pioa;
//        pioa = *AT91C_PIOA_PDSR;
//    }

  DEBUG_FUNC_OUT(DEBUG_F_OSD | DEBUG_L1);
}


// enable displaying of OSD
void OsdEnable(unsigned char mode)
{
  DEBUG_FUNC_IN(DEBUG_F_OSD | DEBUG_L2);

    EnableOsd();
    //SPI(OSDCMDENABLE | (mode & DISABLE_KEYBOARD));
    SPI(OSD_CMD_OSD);
    SPI(0x01 | (mode & DISABLE_KEYBOARD));
    DisableOsd();

  DEBUG_FUNC_OUT(DEBUG_F_OSD | DEBUG_L2);
}


// disable displaying of OSD
void OsdDisable(void)
{
  DEBUG_FUNC_IN(DEBUG_F_OSD | DEBUG_L2);

    EnableOsd();
    //SPI(OSDCMDDISABLE);
    SPI(OSD_CMD_OSD);
    SPI(0x00);
    DisableOsd();

  DEBUG_FUNC_OUT(DEBUG_F_OSD | DEBUG_L2);
}


void OsdReset(unsigned char boot)
{
  DEBUG_FUNC_IN(DEBUG_F_OSD | DEBUG_L2);

    EnableOsd();
    //SPI(OSDCMDRST | (boot & 0x01));
    SPI(OSD_CMD_RST);
    //SPI(0x2 | (boot & 0x01));
    SPI(0x1);
    DisableOsd();
    EnableOsd();
    SPI(OSD_CMD_RST);
    SPI(0x0);
    DisableOsd();

  DEBUG_FUNC_OUT(DEBUG_F_OSD | DEBUG_L2);
}


void OsdReconfig()
{
  DEBUG_FUNC_IN(DEBUG_F_OSD | DEBUG_L2);

	EnableOsd();
	//SPI(OSDCMDRECONFIG);
  SPI(OSD_CMD_RST);
  SPI(0x02);
	DisableOsd();
	EnableOsd();
  SPI(OSD_CMD_RST);
  SPI(0x00);
	DisableOsd();

  DEBUG_FUNC_OUT(DEBUG_F_OSD | DEBUG_L2);
}


//void ConfigFilter(unsigned char lores, unsigned char hires, unsigned char scanlines)
//{
//    EnableOsd();
//    //SPI(OSDCMDCFGFLT | ((hires & 0x03) << 2) | (lores & 0x03));
//    SPI(OSD_CMD_VID);
//    SPI(((hires & 0x03) << 4) | ((lores & 0x03)<<2) | (scanlines & 0x03));
//    DisableOsd();
//}
//
//void ConfigScanlines(unsigned char scanlines)
//{
//    EnableOsd();
//    //SPI(OSDCMDCFGSCL | (scanlines & 0x0F)); TODO! same reg as OSD_CMD_VID!
//    DisableOsd();
//}


void ConfigVideo(unsigned char hires, unsigned char lores, unsigned char scanlines)
{
  DEBUG_FUNC_IN(DEBUG_F_OSD | DEBUG_L1);

    EnableOsd();
    //SPI(OSDCMDCFGFLT | ((hires & 0x03) << 2) | (lores & 0x03));
    SPI(OSD_CMD_VID);
    SPI(((hires & 0x03) << 4) | ((lores & 0x03)<<2) | (scanlines & 0x03));
    DisableOsd();

  DEBUG_FUNC_OUT(DEBUG_F_OSD | DEBUG_L1);
}


void ConfigMemory(unsigned char memory)
{
  DEBUG_FUNC_IN(DEBUG_F_OSD | DEBUG_L1);

    EnableOsd();
    //SPI(OSDCMDCFGMEM | (memory & 0x03));				//chip
    //DisableOsd();
    //EnableOsd();
    //SPI(OSDCMDCFGMEM | 0x04 | ((memory>>2) & 0x03));	//slow
    //DisableOsd();
    //EnableOsd();
    //SPI(OSDCMDCFGMEM | 0x08 | ((memory>>4) & 0x03));	//fast
    SPI(OSD_CMD_MEM);
    SPI(memory);
    DisableOsd();
    //EnableOsd(); TODO BUG probably!
//    SPI(OSDCMDCFGCPU|  0x00);	//68000  -  Don't want to disable '020 here!  AMR
//    DisableOsd();

  DEBUG_FUNC_OUT(DEBUG_F_OSD | DEBUG_L1);
}

void ConfigCPU(unsigned char cpu)
{
  DEBUG_FUNC_IN(DEBUG_F_OSD | DEBUG_L1);

    EnableOsd();
    //SPI(OSDCMDCFGCPU | (cpu & 0x03));					//CPU
    SPI(OSD_CMD_CPU);
    SPI(cpu & 0x0f);
    DisableOsd();

  DEBUG_FUNC_OUT(DEBUG_F_OSD | DEBUG_L1);
}

void ConfigChipset(unsigned char chipset)
{
  DEBUG_FUNC_IN(DEBUG_F_OSD | DEBUG_L1);

    EnableOsd();
    //SPI(OSDCMDCFGCHP | (chipset & 0x0F));
    SPI(OSD_CMD_CHIP);
    SPI(chipset & 0x0f);
    DisableOsd();

  DEBUG_FUNC_OUT(DEBUG_F_OSD | DEBUG_L1);
}

void ConfigFloppy(unsigned char drives, unsigned char speed)
{
  DEBUG_FUNC_IN(DEBUG_F_OSD | DEBUG_L1);

    EnableOsd();
    //SPI(OSDCMDCFGFLP | ((drives & 0x03) << 2) | (speed & 0x03));
    SPI(OSD_CMD_FLP);
    SPI(((drives & 0x03) << 2) | (speed & 0x03));
    DisableOsd();

  DEBUG_FUNC_OUT(DEBUG_F_OSD | DEBUG_L1);
}

void ConfigScanlines(unsigned char scanlines)
{
  DEBUG_FUNC_IN(DEBUG_F_OSD | DEBUG_L1);

    EnableOsd();
    //SPI(OSDCMDCFGSCL | (scanlines & 0x0F)); TODO! same reg as OSD_CMD_VID!
    DisableOsd();

  DEBUG_FUNC_OUT(DEBUG_F_OSD | DEBUG_L1);
}


void ConfigIDE(unsigned char gayle, unsigned char master, unsigned char slave)
{
  DEBUG_FUNC_IN(DEBUG_F_OSD | DEBUG_L1);

    EnableOsd();
    //SPI(OSDCMDCFGIDE | (slave ? 4 : 0) | (master ? 2 : 0) | (gayle ? 1 : 0));
    SPI(OSD_CMD_HDD);
    SPI((slave ? 4 : 0) | (master ? 2 : 0) | (gayle ? 1 : 0));
    DisableOsd();

  DEBUG_FUNC_OUT(DEBUG_F_OSD | DEBUG_L1);
}


void ConfigAutofire(unsigned char autofire)
{
  DEBUG_FUNC_IN(DEBUG_F_OSD | DEBUG_L1);

    EnableOsd();
    //SPI(OSDCMDAUTOFIRE | (autofire & 0x03));
    SPI(OSD_CMD_JOY);
    SPI(autofire & 0x03);
    DisableOsd();

  DEBUG_FUNC_OUT(DEBUG_F_OSD | DEBUG_L1);
}


// get key status
unsigned char OsdGetCtrl(void)
{
  DEBUG_FUNC_IN(DEBUG_F_OSD | DEBUG_L2);

    static unsigned char c2;
    static unsigned long delay;
    static unsigned long repeat;
    static unsigned char repeat2;
    unsigned char c1,c;

    // send command and get current ctrl status
    EnableOsd();
    c1 = SPI(OSD_CMD_READ);
    DisableOsd();

    // add front menu button
    if (!CheckButton())
        delay = GetTimer(BUTTONDELAY);
    else if (CheckTimer(delay))
    {
        c1 = KEY_MENU;
        delay = GetTimer(-1);
    }

    // generate normal "key-pressed" event
    c = 0;
    if (c1 != c2)
       c = c1;

    c2 = c1;

    // generate repeat "key-pressed" events
    if (c1 & KEY_UPSTROKE)
    {
        repeat = GetTimer(REPEATDELAY);
    }
    else if (CheckTimer(repeat))
    {
        repeat = GetTimer(REPEATRATE);
        if (c1 == KEY_UP || c1 == KEY_DOWN)
           c = c1;
        repeat2++;
        if (repeat2 == 2)
        {
            repeat2 = 0;
            if (c1 == KEY_PGUP || c1 == KEY_PGDN || GetASCIIKey(c1))
                c = c1;
        }
    }

    return(c);

  DEBUG_FUNC_OUT(DEBUG_F_OSD | DEBUG_L2);
}


unsigned char GetASCIIKey(unsigned char keycode)
{
  DEBUG_FUNC_IN(DEBUG_F_OSD | DEBUG_L2);

    if (keycode & KEY_UPSTROKE)
       return 0;

    return keycode_table[keycode & 0x7F];

  DEBUG_FUNC_OUT(DEBUG_F_OSD | DEBUG_L2);
}


void ScrollText(char n,const char *str, int len,int max_len,unsigned char invert)
{
  DEBUG_FUNC_IN(DEBUG_F_OSD | DEBUG_L2);

// this function is called periodically when a string longer than the window is displayed.

    #define BLANKSPACE 10 // number of spaces between the end and start of repeated name

    long offset;
	if(!max_len)
		max_len=30;

    if (str && str[0] && CheckTimer(scroll_timer)) // scroll if long name and timer delay elapsed
    {
        scroll_timer = GetTimer(SCROLL_DELAY2); // reset scroll timer to repeat delay

        scroll_offset++; // increase scroll position (1 pixel unit)
        memset(s, ' ', 32); // clear buffer

		if(!len)
	        len = strlen(str); // get name length

        if (len > max_len) // scroll name if longer than display size
        {
            if (scroll_offset >= ((unsigned int)len + BLANKSPACE) << 3) // reset scroll position if it exceeds predefined maximum
                scroll_offset = 0;

            offset = scroll_offset >> 3; // get new starting character of the name (scroll_offset is no longer in 2 pixel unit)

            len -= offset; // remaining number of characters in the name

			if(len>max_len)
				len=max_len;

            if (len > 0)
                strncpy(s, &str[offset], len); // copy name substring

            if (len < max_len - BLANKSPACE) // file name substring and blank space is shorter than display line size
                strncpy(s + len + BLANKSPACE, str, max_len - len - BLANKSPACE); // repeat the name after its end and predefined number of blank space

            OSD_PrintText(n, s, 22, (max_len - 1) << 3, (scroll_offset & 0x7), invert); // OSD print function with pixel precision
        }
    }

  DEBUG_FUNC_OUT(DEBUG_F_OSD | DEBUG_L2);
}


void ScrollReset()
{
  DEBUG_FUNC_IN(DEBUG_F_OSD | DEBUG_L2);

    scroll_timer = GetTimer(SCROLL_DELAY); // set timer to start name scrolling after predefined time delay
    scroll_offset = 0; // start scrolling from the start

  DEBUG_FUNC_OUT(DEBUG_F_OSD | DEBUG_L2);
}

