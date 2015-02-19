// ini_parser.h
// 2015, rok.krajnc@gmail.com

#ifndef __INI_PARSER_H__
#define __INI_PARSER_H__

// float support adds over 20kBytes to the firmware size
// #define INI_ENABLE_FLOAT

//// includes ////
#include <inttypes.h>


//// type definitions ////
typedef struct {
  int id;
  char* name;
} ini_section_t;

typedef enum {UINT8=0, INT8, UINT16, INT16, UINT32, INT32, 
#ifdef INI_ENABLE_FLOAT
	      FLOAT, 
#endif
	      STRING} ini_vartypes_t;

typedef struct {
  char* name;
  void* var;
  ini_vartypes_t type;
  int min;
  int max;
  int section_id;
} ini_var_t;

typedef struct {
  const char* filename;
  const ini_section_t* sections;
  const ini_var_t* vars;
  int nsections;
  int nvars;
} ini_cfg_t;


//// functions ////
void ini_parse(const ini_cfg_t* cfg);
void ini_save(const ini_cfg_t* cfg);

#endif // __INI_PARSER_H__

