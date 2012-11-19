#ifndef MENU_H
#define MENU_H

#include "fdd.h" // for adfTYPE definition

/*menu states*/
enum MENU
{
    MENU_NONE1,
    MENU_NONE2,
    MENU_MAIN1,
    MENU_MAIN2,
    MENU_MISC1,
    MENU_MISC2,
    MENU_ABOUT1,
    MENU_ABOUT2,
    MENU_FILE_SELECT1,
    MENU_FILE_SELECT2,
    MENU_FILE_SELECTED,
    MENU_RESET1,
    MENU_RESET2,
    MENU_RECONF1,
    MENU_RECONF2,
    MENU_SETTINGS1,
    MENU_SETTINGS2,
    MENU_ROMFILE_SELECTED,
    MENU_ROMFILE_SELECTED1,
    MENU_ROMFILE_SELECTED2,
    MENU_SETTINGS_VIDEO1,
    MENU_SETTINGS_VIDEO2,
    MENU_SETTINGS_MEMORY1,
    MENU_SETTINGS_MEMORY2,
    MENU_SETTINGS_CHIPSET1,
    MENU_SETTINGS_CHIPSET2,
    MENU_SETTINGS_DRIVES1,
    MENU_SETTINGS_DRIVES2,
    MENU_SETTINGS_HARDFILE1,
    MENU_SETTINGS_HARDFILE2,
    MENU_HARDFILE_SELECT1,
    MENU_HARDFILE_SELECT2,
    MENU_HARDFILE_SELECTED,
    MENU_HARDFILE_EXIT,
    MENU_HARDFILE_CHANGED1,
    MENU_HARDFILE_CHANGED2,
    MENU_SYNTHRDB1,
    MENU_SYNTHRDB2,
    MENU_SYNTHRDB2_1,
    MENU_SYNTHRDB2_2,
    MENU_MAIN2_1,
    MENU_MAIN2_2,
    MENU_LOADCONFIG_1,
    MENU_LOADCONFIG_2,
    MENU_SAVECONFIG_1,
    MENU_SAVECONFIG_2,
    MENU_FIRMWARE1,
    MENU_FIRMWARE2,
    MENU_FIRMWARE_UPDATE1,
    MENU_FIRMWARE_UPDATE2,
    MENU_FIRMWARE_UPDATE_ERROR1,
    MENU_FIRMWARE_UPDATE_ERROR2,
    MENU_FIRMWARE_UPDATING1,
    MENU_FIRMWARE_UPDATING2,
    MENU_FIRMWARE_OPTIONS1,
    MENU_FIRMWARE_OPTIONS2,
    MENU_FIRMWARE_OPTIONS_ENABLE1,
    MENU_FIRMWARE_OPTIONS_ENABLE2,
    MENU_FIRMWARE_OPTIONS_ENABLED1,
    MENU_FIRMWARE_OPTIONS_ENABLED2,
    MENU_ERROR,
    MENU_INFO,
};

// UI strings, used by boot messages
extern const char *config_filter_msg[];
extern const char *config_memory_chip_msg[];
extern const char *config_memory_slow_msg[];
extern const char *config_memory_fast_msg[];
extern const char *config_scanline_msg[];


void InsertFloppy(adfTYPE *drive);
void HandleUI(void);
void PrintDirectory(void);
void ScrollLongName(void);
void ErrorMessage(const char *message, unsigned char code);
void InfoMessage(char *message);
void DebugMessage(char *message);
void _showdebugmessages();
void ShowSplash();
void HideSplash();

#endif

