#ifndef OSD_H_INCLUDED
#define OSD_H_INCLUDED

/*constants*/
#define OSDCTRLUP       0x01        /*OSD up control*/
#define OSDCTRLDOWN     0x02        /*OSD down control*/
#define OSDCTRLSELECT   0x04        /*OSD select control*/
#define OSDCTRLMENU     0x08        /*OSD menu control*/
#define OSDCTRLRIGHT    0x10        /*OSD right control*/
#define OSDCTRLLEFT     0x20        /*OSD left control*/

#define KEY_MENU  0x88
#define KEY_PGUP  0x81
#define KEY_PGDN  0x82
#define KEY_HOME  0x84
#define KEY_ESC   0x45
#define KEY_ENTER 0x44
#define KEY_BACK  0x41
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

#define CONFIG_TURBO 1
#define CONFIG_NTSC 4
#define CONFIG_ECS 8

#define CONFIG_FLOPPY1X 0
#define CONFIG_FLOPPY2X 1

#define RESET_NORMAL 0
#define RESET_BOOTLOADER 1

/*functions*/
void OsdWrite(unsigned char n, char *s, unsigned char inver);
void OsdClear(void);
void OsdEnable(void);
void OsdDisable(void);
void OsdReset(unsigned char boot);
void ConfigFilter(unsigned char lores, unsigned char hires);
void ConfigMemory(unsigned char memory);
void ConfigChipset(unsigned char chipset);
void ConfigFloppy(unsigned char drives, unsigned char speed);
void ConfigScanlines(unsigned char scanlines);
void ConfigIDE(unsigned char gayle, unsigned char master, unsigned char slave);
unsigned char OsdGetCtrl(void);
unsigned char GetASCIIKey(unsigned char c);
void OSD_PrintText(unsigned char line, char *text, unsigned long start, unsigned long width, unsigned long offset, unsigned char invert);


#endif

