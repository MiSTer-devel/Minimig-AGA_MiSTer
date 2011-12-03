#ifndef OSDFONT_H_
#define OSDFONT_H_

#define	OSD_FONT_CHAR_NUMBER	128	// Number of characters in font
#define	OSD_FONT_CHAR_WIDTH		5	// Number of pixels of font width
#define	OSD_FONT_CHAR_SPACING	1	// Number of pixels for character spacing

// Just Define Global font for include
extern const unsigned char charfont[OSD_FONT_CHAR_NUMBER][OSD_FONT_CHAR_WIDTH];

#endif /*OSDFONT_H_*/
