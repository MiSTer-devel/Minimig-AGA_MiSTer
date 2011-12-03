#ifndef OSD_H_INCLUDED
#define	OSD_H_INCLUDED

/*constants*/
#define KEY_MENU  0x88
#define KEY_ESC   0x45
#define KEY_ENTER 0x44
#define KEY_SPACE 0x40
#define KEY_UP    0x4C
#define KEY_DOWN  0x4D
#define KEY_LEFT  0x4F
#define KEY_RIGHT 0x4E
#define KEY_F1    0x50
#define KEY_F2    0x51
#define KEY_F3    0x52
#define KEY_F4    0x53
#define KEY_F5    0x54
#define KEY_F6    0x55
#define KEY_F7    0x56
#define KEY_F8    0x57
#define KEY_F9    0x58
#define KEY_F10   0x59

/*functions*/
void OsdWrite(unsigned char n,const unsigned char *s, char invert);
void OsdClear(void);
void OsdEnable(void);
void OsdDisable(void);
void OsdReset(unsigned char boot);
void ConfigFilter(unsigned char lores, unsigned char hires);
void ConfigMemory(unsigned char memory);
void ConfigChipset(unsigned char chipset);
void ConfigFloppy(unsigned char drives, unsigned char speed);
void ConfigScanline(unsigned char scanline);
unsigned char OsdGetCtrl(void);
unsigned char GetASCIIKey(unsigned char keycode);

#endif
