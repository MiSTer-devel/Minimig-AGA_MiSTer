// mist_cfg.h
// 2015, rok.krajnc@gmail.com


#ifndef __MIST_CFG_H__
#define __MIST_CFG_H__


//// includes ////
#include <inttypes.h>
#include "ini_parser.h"


//// type definitions ////
typedef struct {
  uint8_t scandoubler;
} mist_cfg_t;


//// functions ////
void mist_ini_parse();


//// global variables ////
extern const ini_cfg_t mist_ini_cfg;
extern mist_cfg_t mist_cfg;


#endif // __MIST_CFG_H__

