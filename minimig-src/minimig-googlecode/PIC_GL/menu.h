#ifndef MENU_H_
#define MENU_H_

// Enables / Disables Alternate core loading
// ALTERNATE_CORES -> Defined in firmwareConfiguration.h

// menu states
enum MENU
{
	MENU_NONE1,
	MENU_NONE2,
	MENU_MAIN1,
	MENU_MAIN2,
	MENU_MAIN_EXT1,
	MENU_MAIN_EXT2,
	MENU_FILE1,
	MENU_FILE2,
	MENU_FLOPPY_SELECTED,
	MENU_RESET1,
	MENU_RESET2,
	MENU_SETTINGS1,
	MENU_SETTINGS2,
	MENU_ROMFILESELECTED1,
	MENU_ROMFILESELECTED2,
	MENU_SETTINGS_VIDEO1,
	MENU_SETTINGS_VIDEO2,
	MENU_SETTINGS_MEMORY1,
	MENU_SETTINGS_MEMORY2,
	MENU_SETTINGS_CHIPSET1,
	MENU_SETTINGS_CHIPSET2,
	MENU_SETTINGS_DRIVES1,
	MENU_SETTINGS_DRIVES2,
	MENU_ERROR,
	MENU_SETTINGS_HARDFILE1,
	MENU_SETTINGS_HARDFILE2,
	MENU_HARDFILE_SELECTED,
	#ifdef ALTERNATE_CORES
	MENU_ALTCORE_SELECTED,
	#endif
	#ifdef	AUTOFIRE_RATE_KEYBOARD_SELECT || TURBO_MODE_KEYBOARD_SELECT
	MENU_INFO,
	#endif
};

// Extern exposed variables
extern const char * const config_memory_chip_msg[];
extern const char * const config_memory_slow_msg[];

#ifdef ALTERNATE_CORES
// Alternate Core Loaded
extern unsigned char bAlternateCoreLoaded;
#endif

void HandleUI(void);
void HandleUpDown(unsigned char state, unsigned char max);
void SelectFile(const char* extension, unsigned char selectedState, unsigned char selectedStatePreselect, unsigned char exitState, unsigned char allowDirectorySelect);

void ErrorMessage(const char* message, unsigned char code);

#ifdef AUTOFIRE_RATE_KEYBOARD_SELECT
	void AutoFireSwitch(void);
#endif

#ifdef TURBO_MODE_KEYBOARD_SELECT
	void TurboModeSwitch(unsigned char bTurbo);
#endif

#ifdef	AUTOFIRE_RATE_KEYBOARD_SELECT || TURBO_MODE_KEYBOARD_SELECT
	void InfoMessage(char *message);
#endif

#endif /*MENU_H_*/
