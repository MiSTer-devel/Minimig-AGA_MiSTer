#ifndef OSD_H_INCLUDED
#define OSD_H_INCLUDED

/*constants*/
#define OSDCTRLUP        0x01        /*OSD up control*/
#define OSDCTRLDOWN      0x02        /*OSD down control*/
#define OSDCTRLSELECT    0x04        /*OSD select control*/
#define OSDCTRLMENU      0x08        /*OSD menu control*/
#define OSDCTRLRIGHT     0x10        /*OSD right control*/
#define OSDCTRLLEFT      0x20        /*OSD left control*/

// some constants
#define OSDNLINE         8           // number of lines of OSD
#define OSDLINELEN       256         // single line length in bytes
#define OSDCMDREAD       0x00        // OSD read controller/key status
#define OSDCMDWRITE      0x20        // OSD write video data command
#define OSDCMDENABLE     0x41        // OSD enable command
#define OSDCMDDISABLE    0x40        // OSD disable command
#define OSDCMDRST        0x80        // OSD reset command
#define OSDCMDAUTOFIRE   0x84        // OSD autofire command
#define OSDCMDCFGSCL     0xA0        // OSD settings: scanlines effect
#define OSDCMDCFGIDE     0xB0        // OSD enable HDD command
#define OSDCMDCFGFLP     0xC0        // OSD settings: floppy config
#define OSDCMDCFGCHP     0xD0        // OSD settings: chipset config
#define OSDCMDCFGFLT     0xE0        // OSD settings: filter
#define OSDCMDCFGMEM     0xF0        // OSD settings: memory config
#define OSDCMDCFGCPU     0xFC        // OSD settings: CPU config

#define DISABLE_KEYBOARD 0x02        // disable keyboard while OSD is active

#define REPEATDELAY      500         // repeat delay in 1ms units
#define REPEATRATE       50          // repeat rate in 1ms units
#define BUTTONDELAY      20          // repeat rate in 1ms units

#define KEY_UPSTROKE     0x80
#define KEY_MENU         0x69
#define KEY_PGUP         0x6C
#define KEY_PGDN         0x6D
#define KEY_HOME         0x6A
#define KEY_ESC          0x45
#define KEY_ENTER        0x44
#define KEY_BACK         0x41
#define KEY_SPACE        0x40
#define KEY_UP           0x4C
#define KEY_DOWN         0x4D
#define KEY_LEFT         0x4F
#define KEY_RIGHT        0x4E
#define KEY_F1           0x50
#define KEY_F2           0x51
#define KEY_F3           0x52
#define KEY_F4           0x53
#define KEY_F5           0x54
#define KEY_F6           0x55
#define KEY_F7           0x56
#define KEY_F8           0x57
#define KEY_F9           0x58
#define KEY_F10          0x59
#define KEY_CTRL         0x63
#define KEY_LALT         0x64
#define KEY_KPPLUS       0x5E
#define KEY_KPMINUS      0x4A
#define KEY_KP0          0x0F

#define CONFIG_TURBO     1
#define CONFIG_NTSC      2
#define CONFIG_A1000     4
#define CONFIG_ECS       8

#define CONFIG_FLOPPY1X  0
#define CONFIG_FLOPPY2X  1

#define RESET_NORMAL 0
#define RESET_BOOTLOADER 1

/*functions*/
void OsdWrite(unsigned char n, char *s, unsigned char inver);
void OsdClear(void);
void OsdEnable(unsigned char mode);
void OsdDisable(void);
void OsdWaitVBL(void);
void OsdReset(unsigned char boot);
void ConfigFilter(unsigned char lores, unsigned char hires);
void ConfigMemory(unsigned char memory);
void ConfigCPU(unsigned char cpu);
void ConfigChipset(unsigned char chipset);
void ConfigFloppy(unsigned char drives, unsigned char speed);
void ConfigScanlines(unsigned char scanlines);
void ConfigIDE(unsigned char gayle, unsigned char master, unsigned char slave);
void ConfigAutofire(unsigned char autofire);
unsigned char OsdGetCtrl(void);
unsigned char GetASCIIKey(unsigned char c);
void OSD_PrintText(unsigned char line, char *text, unsigned long start, unsigned long width, unsigned long offset, unsigned char invert);


#endif

