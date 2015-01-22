// ini_parser.c
// 2015, rok.krajnc@gmail.com


//// includes ////
#include <string.h>
#include <inttypes.h>
#include "debug.h"
#include "ini_parser.h"
#include "rafile.h"


//// defines ////
#define INI_BUF_SIZE            512
#define INI_LINE_SIZE           33

#define INI_SECTION_START       '['
#define INI_SECTION_END         ']'
#define INI_SECTION_INVALID_ID  0


//// macros ////
#define CHAR_IS_NUM(c)          (((c) >= '0') && ((c) <= '9'))
#define CHAR_IS_ALPHA_LOWER(c)  (((c) >= 'a') && ((c) <= 'z'))
#define CHAR_IS_ALPHA_UPPER(c)  (((c) >= 'A') && ((c) <= 'Z'))
#define CHAR_IS_ALPHA(c)        (CHAR_IS_ALPHA_LOWER(c) || CHAR_IS_ALPHA_UPPER(c))
#define CHAR_IS_ALPHANUM(c)     (CHAR_IS_ALPHA_LOWER(c) || CHAR_IS_ALPHA_UPPER(c) || CHAR_IS_NUM(c))
#define CHAR_IS_SPECIAL(c)      (((c) == '[') || ((c) == ']') || ((c) == '-') || ((c) == '_') || ((c) == ',') || ((c) == '='))
#define CHAR_IS_VALID(c)        (CHAR_IS_ALPHANUM(c) || CHAR_IS_SPECIAL(c))
#define CHAR_IS_WHITESPACE(c)   (((c) == ' ') || ((c) == '\t') || ((c) == '\r') || ((c) == '\n'))
#define CHAR_IS_SPACE(c)        (((c) == ' ') || ((c) == '\t'))
#define CHAR_IS_LINEEND(c)      (((c) == '\n'))
#define CHAR_IS_COMMENT(c)      (((c) == ';'))
#define CHAR_TO_UPPERCASE(c)    ({ char _c = (c); if (CHAR_IS_ALPHA_LOWER(_c)) _c = _c - 'a' + 'A'; _c;})
#define CHAR_TO_LOWERCASE(c)    ({ char _c = (c); if (CHAR_IS_ALPHA_UPPER(_c)) _c = _c - 'A' + 'a'; _c;})


//// globals ////
RAFile ini_file;


//// ini_getch() ////
char ini_getch()
{
  static int ini_pt = 0;

  if ((ini_pt&0x3ff) == 0x200) {
    // reload buffer
    RARead(&ini_file, sector_buffer, INI_BUF_SIZE);
  }

  if (ini_pt >= ini_file.file.size) return 0;
  else return sector_buffer[(ini_pt++)&0x1ff];
}


//// ini_findch() ////
char ini_findch(char c)
{
  char t;
  do {
    t = ini_getch();
  } while ((t != 0) && (t != c));
  return t;
}


//// ini_getline() ////
int ini_getline(char* line)
{
  char c;
  char ignore=0;
  int i=0;

  while(i<(INI_LINE_SIZE-1)) {
    c = ini_getch();
    if ((!c) || CHAR_IS_LINEEND(c)) break;
    else if (CHAR_IS_COMMENT(c) && !ignore) ignore++;
    else if (CHAR_IS_VALID(c) && !ignore) line[i++] = CHAR_TO_UPPERCASE(c);
  }
  line[i] = '\0';
  return c != 0;
}


//// ini_get_section() ////
int ini_get_section(const ini_cfg_t* cfg, char* buf)
{
  int i=0;

  // get section start marker
  if (buf[0] != INI_SECTION_START) {
    return INI_SECTION_INVALID_ID;
  } else buf++;

  // get section stop marker
  while (1) {
    if (buf[i] == INI_SECTION_END) {
      buf[i] = '\0';
      break;
    }
    i++;
    if (i >= INI_LINE_SIZE) {
      return INI_SECTION_INVALID_ID;
    }
  }

  // parse section
  for (i=0; i<cfg->nsections; i++) {
    if (!strcmp(buf, cfg->sections[i].name)) {
      ini_parser_debugf("Got SECTION '%s' with ID %d", buf, cfg->sections[i].id);
      return cfg->sections[i].id;
    }  
  }

  return INI_SECTION_INVALID_ID;
}


//// ini_get_var() ////
void* ini_get_var(const ini_cfg_t* cfg, int cur_section, char* buf)
{
  int i=0, j=0;
  int var_id = -1;

  // get var
  while(1) {
    if (buf[i] == '=') {
      buf[i] = '\0';
      break;
    } else if (buf[i] == '\0') return (void*)0;
    i++;
  }
  for (j=0; j<cfg->nvars; j++) {
    if ((!strcmp(buf, cfg->vars[j].name)) && (cfg->vars[j].section_id == cur_section)) var_id = j;
  }

  // get data
  if (var_id != -1) {
    ini_parser_debugf("Got VAR '%s' with VALUE %s", buf, &(buf[i+1]));
    i++;
    switch (cfg->vars[var_id].type) {
      case UINT8:
        *(uint8_t*)(cfg->vars[var_id].var) = strtoul(&(buf[i]), NULL, 0);
        if (*(uint8_t*)(cfg->vars[var_id].var) > cfg->vars[var_id].max) *(uint8_t*)(cfg->vars[var_id].var) = cfg->vars[var_id].max;
        if (*(uint8_t*)(cfg->vars[var_id].var) < cfg->vars[var_id].min) *(uint8_t*)(cfg->vars[var_id].var) = cfg->vars[var_id].min;
        break;
      case INT8:
        *(int8_t*)(cfg->vars[var_id].var) = strtol(&(buf[i]), NULL, 0);
        if (*(int8_t*)(cfg->vars[var_id].var) > cfg->vars[var_id].max) *(int8_t*)(cfg->vars[var_id].var) = cfg->vars[var_id].max;
        if (*(int8_t*)(cfg->vars[var_id].var) < cfg->vars[var_id].min) *(int8_t*)(cfg->vars[var_id].var) = cfg->vars[var_id].min;
        break;
      case UINT16:
        *(uint8_t*)(cfg->vars[var_id].var) = strtoul(&(buf[i]), NULL, 0);
        if (*(uint16_t*)(cfg->vars[var_id].var) > cfg->vars[var_id].max) *(uint16_t*)(cfg->vars[var_id].var) = cfg->vars[var_id].max;
        if (*(uint16_t*)(cfg->vars[var_id].var) < cfg->vars[var_id].min) *(uint16_t*)(cfg->vars[var_id].var) = cfg->vars[var_id].min;
        break;
      case INT16:
        *(int16_t*)(cfg->vars[var_id].var) = strtol(&(buf[i]), NULL, 0);
        if (*(int16_t*)(cfg->vars[var_id].var) > cfg->vars[var_id].max) *(int16_t*)(cfg->vars[var_id].var) = cfg->vars[var_id].max;
        if (*(int16_t*)(cfg->vars[var_id].var) < cfg->vars[var_id].min) *(int16_t*)(cfg->vars[var_id].var) = cfg->vars[var_id].min;
        break;
      case UINT32:
        *(uint8_t*)(cfg->vars[var_id].var) = strtoul(&(buf[i]), NULL, 0);
        if (*(uint32_t*)(cfg->vars[var_id].var) > cfg->vars[var_id].max) *(uint32_t*)(cfg->vars[var_id].var) = cfg->vars[var_id].max;
        if (*(uint32_t*)(cfg->vars[var_id].var) < cfg->vars[var_id].min) *(uint32_t*)(cfg->vars[var_id].var) = cfg->vars[var_id].min;
        break;
      case INT32:
        *(int32_t*)(cfg->vars[var_id].var) = strtol(&(buf[i]), NULL, 0);
        if (*(int32_t*)(cfg->vars[var_id].var) > cfg->vars[var_id].max) *(int32_t*)(cfg->vars[var_id].var) = cfg->vars[var_id].max;
        if (*(int32_t*)(cfg->vars[var_id].var) < cfg->vars[var_id].min) *(int32_t*)(cfg->vars[var_id].var) = cfg->vars[var_id].min;
        break;
      case FLOAT:
        *(float*)(cfg->vars[var_id].var) = strtof(&(buf[i]), NULL);
        if (*(float*)(cfg->vars[var_id].var) > cfg->vars[var_id].max) *(float*)(cfg->vars[var_id].var) = cfg->vars[var_id].max;
        if (*(float*)(cfg->vars[var_id].var) < cfg->vars[var_id].min) *(float*)(cfg->vars[var_id].var) = cfg->vars[var_id].min;
        break;
      case STRING:
        strncpy((char*)(cfg->vars[var_id].var), &(buf[i]), cfg->vars[var_id].max);
        break;
    }
    return (void*)(&(cfg->vars[var_id].var));
  }

  return (void*)0;
}


//// ini_parse() ////
void ini_parse(const ini_cfg_t* cfg)
{
  char line[INI_LINE_SIZE] = {0};
  int section = INI_SECTION_INVALID_ID;

  // open ini file
  if (!RAOpen(&ini_file, cfg->filename)) {
    ini_parser_debugf("Can't open file %s !", cfg->filename);
    return;
  }

  ini_parser_debugf("Opened file %s with size %d bytes.", cfg->filename, ini_file.file.size);

  // preload buffer
  RARead(&ini_file, sector_buffer, INI_BUF_SIZE);

  // parse ini
  while (1) {
    // get line
    if (!ini_getline(line)) break;
    if (line[0] == INI_SECTION_START) {
      // if first char in line is INI_SECTION_START, get section
      section = ini_get_section(cfg, line);
    } else {
      // otherwise this is a variable, get it
      ini_get_var(cfg, section, line);
    }
  }
}


//// ini_save() ////
void ini_save(const ini_cfg_t* cfg)
{
  // TODO
}

