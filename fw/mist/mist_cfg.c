// mist_cfg.c
// 2015, rok.krajnc@gmail.com


//// includes ////
#include "ini_parser.h"
#include "mist_cfg.h"
#include "user_io.h"
#include "usb/usb.h"

//// mist_ini_parse() ////
void mist_ini_parse()
{
  ini_parse(&mist_ini_cfg);
}


//// vars ////
// config data
mist_cfg_t mist_cfg = {.scandoubler_disable = 0};

// mist ini sections
const ini_section_t mist_ini_sections[] = {
  {1, "MIST"}
};

// mist ini vars
const ini_var_t mist_ini_vars[] = {
  {"SCANDOUBLER_DISABLE", (void*)(&(mist_cfg.scandoubler_disable)), UINT8, 0, 1, 1},
  {"KEY_REMAP", (void*)user_io_key_remap, CUSTOM_HANDLER, 0, 0, 1},
  //  {"JOYSTICK_AXIS_REMAP", (void*)user_io_joystick_axis_remap, CUSTOM_HANDLER, 0, 0, 1},
  {"JOYSTICK_BUTTON_REMAP", (void*)hid_joystick_axis_remap, CUSTOM_HANDLER, 0, 0, 1}
}; 

// mist ini config
const ini_cfg_t mist_ini_cfg = {
  "MIST    INI",
  mist_ini_sections,
  mist_ini_vars,
  (int)(sizeof(mist_ini_sections) / sizeof(ini_section_t)),
  (int)(sizeof(mist_ini_vars)     / sizeof(ini_var_t))
};

