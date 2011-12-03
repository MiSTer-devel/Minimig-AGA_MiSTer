#ifndef CONFIG_H_
#define CONFIG_H_

// Enable/disable config debug
//#define CONFIG_DEBUG

// EEPROM Locations to save config
#define		EEPROM_FILTER_LORES		0x10
#define		EEPROM_FILTER_HIRES		0x11
#define		EEPROM_MEMORY			0x12
#define		EEPROM_CHIPSET			0x13
#define		EEPROM_FLOPPY_SPEED		0x14
#define		EEPROM_FLOPPY_DRIVES	0x15
#define		EEPROM_AR3_ENABLED		0x16
#define		EEPROM_SCANLINE			0x17
#define		EEPROM_KICKNAME			0x18	//size 12
#define		EEPROM_IDE_ENABLED		0x24
#define		EEPROM_IDE_PORTS		0x25	//size 2 	Master, Slave
#define		EEPROM_IDE_HDFILES		0x27	//size 24	Master, Slave


// Structure for minimig configuration
struct configType
{
	unsigned char	kickname[12];	//kickstart file name
	unsigned char	filter_lores;	
	unsigned char	filter_hires;
	unsigned char	memory;			//chip and fast mem, changes take effect after reset
	unsigned char	chipset;
	unsigned char	floppy_speed;
	unsigned char	floppy_drives;	//number of floppy drives, the FPGA updates its drive number after reset
	unsigned char	ar3;			//change takes effect after next FPGA reconfiguration
	unsigned char	scanline;
	unsigned char	ide;			// Enable/Disable IDE interface
};


// Variable Global Configuration
// Extern for usage in other modules
extern struct configType	config;

// Defaults extern variables 
extern const unsigned char defFPGAName[];		// Default FPGA Binary name
extern const unsigned char defKickName[];		// Default Kickstart name
extern const unsigned char defARName[];			// Default Action Replay name
extern const unsigned char defHDFileName[];		// Default Hard disk file format
extern const unsigned char defFloppyExt[];		// Defult floppy extension
extern const unsigned char defRomExt[];			// Defult rom extension
extern const unsigned char defHardDiskExt[];	// Defult hard disk file extension
extern const unsigned char defCoreExt[];		// Defult core extension


void LoadConfiguration(void);
void SaveConfiguration(void);

unsigned char GetConfigValue(unsigned char address, unsigned char max, unsigned char def);
void GetConfigStringValue(unsigned char address, unsigned char* value, const unsigned char *def, unsigned char count);

void SaveConfigValue(unsigned char address, unsigned char value);
void SaveConfigValues(unsigned char address, unsigned char *values, unsigned char count);

#endif /*CONFIG_H_*/
