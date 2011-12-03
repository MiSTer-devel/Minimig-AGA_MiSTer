#ifndef OSD_H_INCLUDED
#define	OSD_H_INCLUDED


#define OSDCTRLUP		0x01		//OSD up control
#define OSDCTRLDOWN		0x02		//OSD down control 
#define OSDCTRLSELECT	0x04		//OSD select control 
#define OSDCTRLMENU		0x08		//OSD menu control 
#define OSDCTRLRIGHT	0x10		//OSD right control 
#define OSDCTRLLEFT		0x20		//OSD left control


#if	defined(PGL090421) || defined(PGL090911) || defined(PGL091224)
	#define OSDCMDREAD      0x00		// OSD read controller/key status
	#define OSDCMDWRITE     0x20        // OSD write video data command
	#define OSDCMDENABLE    0x60        // OSD enable command
	#define OSDCMDDISABLE   0x40        // OSD disable command
	#define OSDCMDRST       0x80        // OSD reset command
	#define OSDCMDCFGSCL    0xA0        // OSD settings: scanline effect
	#define OSDCMDENAHDD    0xB0        // OSD enable HDD command
	#define OSDCMDCFGFLP    0xC0        // OSD settings: floppy config
	#define OSDCMDCFGCPU    0xD0        // OSD settings: cpu config
	#define OSDCMDCFGFLT    0xE0        // OSD settings: filter
	#define OSDCMDCFGMEM    0xF0        // OSD settings: memory config
#elif	defined(PGL100818) 
	#define OSDCMDREAD      0x00		// OSD read controller/key status
	#define OSDCMDWRITE     0x20        // OSD write video data command
	#define OSDCMDENABLE	0x41		// OSD enable command  AYQ100818
	#define OSDCMDDISABLE   0x40        // OSD disable command
	#define OSDCMDRST       0x80        // OSD reset command
	#define OSDCMDAUTOFIRE	0x84		// OSD autofire command AYQ100818 
	#define OSDCMDCFGSCL    0xA0        // OSD settings: scanline effect
	#define OSDCMDCFGIDE    0xB0        // OSD settings: IDE config
	#define OSDCMDCFGFLP    0xC0        // OSD settings: floppy config
	#define OSDCMDCFGCHP    0xD0        // OSD settings: chipset config
	#define OSDCMDCFGFLT    0xE0        // OSD settings: filter
	#define OSDCMDCFGMEM    0xF0        // OSD settings: memory config
#endif


// Menu keyboard repeat and delay
#if	defined(PGL100818)
	#define DISABLE_KEYBOARD 0x02        // disable keyboard while OSD is active
//	#define BUTTONDELAY		2			// repeat rate in 10ms units
#endif

#define REPEATDELAY		50			// repeat delay in 10ms units
#define REPEATRATE		2			// repeat rate in 10ms units



// Amiga Keyboard CODES 
#if	defined(PGL090421) || defined(PGL090911) || defined(PGL091224)
	#define KEY_UPSTROKE	0x80
	#define KEY_MENU		0x88
	#define KEY_ESC			0x45
	#define KEY_ENTER		0x44
	#define KEY_SPACE		0x40
	#define KEY_UP			0x4C
	#define KEY_DOWN		0x4D
	#define KEY_LEFT		0x4F
	#define KEY_RIGHT		0x4E
	#define KEY_F1			0x50
	#define KEY_F2			0x51
	#define KEY_F3			0x52
	#define KEY_F4			0x53
	#define KEY_F5			0x54
	#define KEY_F6			0x55
	#define KEY_F7			0x56
	#define KEY_F8			0x57
	#define KEY_F9			0x58
	#define KEY_F10			0x59
#elif	defined(PGL100818) 
	#define KEY_UPSTROKE	0x80
	#define KEY_MENU		0x69
	#define KEY_PGUP		0x6C 
	#define KEY_PGDN		0x6D 
	#define KEY_HOME		0x6A 
	#define KEY_ESC			0x45
	#define KEY_ENTER		0x44
	#define KEY_BACK		0x41 
	#define KEY_SPACE		0x40
	#define KEY_UP			0x4C
	#define KEY_DOWN		0x4D
	#define KEY_LEFT		0x4F
	#define KEY_RIGHT		0x4E
	#define KEY_F1			0x50
	#define KEY_F2			0x51
	#define KEY_F3			0x52
	#define KEY_F4			0x53
	#define KEY_F5			0x54
	#define KEY_F6			0x55
	#define KEY_F7			0x56
	#define KEY_F8			0x57
	#define KEY_F9			0x58
	#define KEY_F10			0x59
	#define KEY_CTRL		0x63 
	#define KEY_LALT		0x64 
	#define KEY_KPPLUS		0x5E 
	#define KEY_KPMINUS		0x4A 
	#define KEY_KP0			0x0F 
#endif

 
// Chipset Config bits 
#if	defined(PGL090421)
	#define CONFIG_CPU_28MHZ	0x01	// PGL090421 - CPU 7.09MHz/28.36MHz
	#define CONFIG_BLITTER_FAST	0x02	// PGL090421 - Blitter Normal/Fast
	#define CONFIG_AGNUS_NTSC	0x04	// PGL090421 & PYQ090911 - Agnus PAL/NTSC
#elif	defined(PGL090911) || defined(PGL091224)
	#define CONFIG_CPU_TURBO	0x01	// PYQ090911 - CPU Normal/Turbo
	#define CONFIG_AGNUS_NTSC	0x04	// PGL090421 & PYQ090911 - Agnus PAL/NTSC
	#define CONFIG_AGNUS_ECS	0x08	// PYQ090911 - Agnus: OCS/ECS
#elif	defined(PGL100818)
	#define CONFIG_TURBO		0x01	// AYQ100818 - CPU Normal/Turbo
	#define CONFIG_NTSC			0x02	// AYQ100818 - PAL/NTSC
	#define CONFIG_A1000		0x04	// AYQ100818 - A1000
	#define CONFIG_ECS			0x08	// AYQ100818 - OCS/ECS chipset
#endif


// some constants
#define OSD_NO_LINES		8			// number of lines of OSD

#if		defined(PGL090421)
	#define	OSD_LINE_BYTES		128		// single line length in bytes
#elif	defined(PGL090911) || defined(PGL091224) || defined(PGL100818)
	#define	OSD_LINE_BYTES		256		// single line length in bytes
#endif


// Floppy speed
#define	CONFIG_FLOPPY1X		0x00	// Normal floppy speed
#define	CONFIG_FLOPPY2X 	0x01	// Double floppy speed

// OSD Reset type
#define RESET_NORMAL		0x00	// Reset Amiga
#define RESET_BOOTLOADER	0x01	// Reset To Boot Loader

/*functions*/
#if		defined(PGL090421) || defined(PGL090911) || defined(PGL091224)
	void OsdEnable(void);
#elif	defined(PGL100818)
	void OsdEnable(unsigned char mode);
#endif

#ifdef AUTOFIRE_RATE_KEYBOARD_SELECT
	void ConfigAutofire(unsigned char autofire);
#endif
	
void OsdWrite(unsigned char n,const unsigned char *s, char invert);
void OsdClear(void);
void OsdDisable(void);
void OsdReset(unsigned char boot);
void ConfigFilter(unsigned char lores, unsigned char hires);
void ConfigMemory(unsigned char memory);
void ConfigChipset(unsigned char chipset);
void ConfigFloppy(unsigned char drives, unsigned char speed);
void ConfigScanline(unsigned char scanline);
void ConfigIDE(unsigned char gayle, unsigned char master, unsigned char slave);
unsigned char OsdGetCtrl(void);
unsigned char GetASCIIKey(unsigned char keycode);

#endif
