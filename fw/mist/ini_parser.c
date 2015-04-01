// ini_parser.c
// 2015, rok.krajnc@gmail.com


//#define INI_PARSER_TEST


//// includes ////
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <inttypes.h>
#include "ini_parser.h"
#ifndef INI_PARSER_TEST
#include "debug.h"
#include "rafile.h"
#endif


//// defines ////
#define INI_EOT                 4 // End-Of-Transmission

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
#define CHAR_IS_QUOTE(c)        (((c) == '"'))
#define CHAR_TO_UPPERCASE(c)    ({ char _c = (c); if (CHAR_IS_ALPHA_LOWER(_c)) _c = _c - 'a' + 'A'; _c;})
#define CHAR_TO_LOWERCASE(c)    ({ char _c = (c); if (CHAR_IS_ALPHA_UPPER(_c)) _c = _c - 'A' + 'a'; _c;})


//// debug func ////
#ifdef INI_PARSER_TEST
#define ini_parser_debugf(a, ...) fprintf(stderr, a "\n", __VA_ARGS__)
#endif

//// globals ////
#ifdef INI_PARSER_TEST
FILE* ini_fp = NULL;
char  sector_buffer[INI_BUF_SIZE] = {0};
int   ini_size=0;
#else
RAFile ini_file;
#endif


//// ini_getch() ////
char ini_getch()
{
  static int ini_pt = 0;

  if ((ini_pt&0x3ff) == 0x200) {
    // reload buffer
    #ifdef INI_PARSER_TEST
    fread(sector_buffer, sizeof(char), INI_BUF_SIZE, ini_fp);
    #else
    RARead(&ini_file, sector_buffer, INI_BUF_SIZE);
    #endif
  }

  #ifdef INI_PARSER_TEST
  if (ini_pt >= ini_size) return 0;
  #else
  if (ini_pt >= ini_file.file.size) return 0;
  #endif
  else return sector_buffer[(ini_pt++)&0x1ff];
}


//// ini_putch() ////
int ini_putch(char c)
{
  static int ini_pt = 0;

  sector_buffer[ini_pt++] = c;

  if ((ini_pt%0x3ff) == 0x200) {
    // write buffer
    ini_pt = 0;
    #ifdef INI_PARSER_TEST
    fwrite(sector_buffer, sizeof(char), INI_BUF_SIZE, ini_fp);
    #else
    //#error
    #endif
  }
  return ini_pt;
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
  char literal=0;
  int i=0;

  while(i<(INI_LINE_SIZE-1)) {
    c = ini_getch();
    if ((!c) || CHAR_IS_LINEEND(c)) break;
    else if (CHAR_IS_QUOTE(c)) literal ^= 1;
    else if (CHAR_IS_COMMENT(c) && !ignore && !literal) ignore++;
    else if (literal) line[i++] = c;
    else if (CHAR_IS_VALID(c) && !ignore) line[i++] = c;
  }
  line[i] = '\0';
  return c==0 ? INI_EOT : literal ? 1 : 0;
}


//// ini_putline() ////
int ini_putline(char* line)
{
  int ini_pt, i=0;

  while(i<(INI_LINE_SIZE-1)) {
    if (!line[i]) break;
    ini_pt = ini_putch(line[i++]);
  }
  return ini_pt;
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

  // convert to uppercase
  for (i=0; i<INI_LINE_SIZE; i++) {
    if (!buf[i]) break;
    else buf[i] = CHAR_TO_UPPERCASE(buf[i]);
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

  // find var
  while(1) {
    if (buf[i] == '=') {
      buf[i] = '\0';
      break;
    } else if (buf[i] == '\0') return (void*)0;
    i++;
  }

  // convert to uppercase
  for (j=0; j<=i; j++) {
    if (!buf[j]) break;
    else buf[j] = CHAR_TO_UPPERCASE(buf[j]);
  }

  // parse var
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
#ifdef INI_ENABLE_FLOAT
      case FLOAT:
        *(float*)(cfg->vars[var_id].var) = strtof(&(buf[i]), NULL);
        if (*(float*)(cfg->vars[var_id].var) > cfg->vars[var_id].max) *(float*)(cfg->vars[var_id].var) = cfg->vars[var_id].max;
        if (*(float*)(cfg->vars[var_id].var) < cfg->vars[var_id].min) *(float*)(cfg->vars[var_id].var) = cfg->vars[var_id].min;
        break;
#endif
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
  int line_status;

  // open ini file
  #ifdef INI_PARSER_TEST
  if ((ini_fp = fopen(cfg->filename, "rb")) == NULL) { 
  #else
  if (!RAOpen(&ini_file, cfg->filename)) {
  #endif
    ini_parser_debugf("Can't open file %s !", cfg->filename);
    return;
  }

  #ifdef INI_PARSER_TEST
  // save size
  fseek(ini_fp, 0L, SEEK_END);
  ini_size = ftell(ini_fp);
  fseek(ini_fp, 0L, SEEK_SET);
  #endif

  #ifdef INI_PARSER_TEST
  ini_parser_debugf("Opened file %s with size %d bytes.", cfg->filename, ini_size);
  #else
  ini_parser_debugf("Opened file %s with size %d bytes.", cfg->filename, ini_file.file.size);
  #endif

  // preload buffer
  #ifdef INI_PARSER_TEST
  fread(sector_buffer, sizeof(char), INI_BUF_SIZE, ini_fp);
  #else
  RARead(&ini_file, sector_buffer, INI_BUF_SIZE);
  #endif

  // parse ini
  while (1) {
    // get line
    line_status = ini_getline(line);
    // if valid line
    if (line_status != 1) {
      if (line[0] == INI_SECTION_START) {
        // if first char in line is INI_SECTION_START, get section
        section = ini_get_section(cfg, line);
      } else {
        // otherwise this is a variable, get it
        ini_get_var(cfg, section, line);
      }
    }
    // if end of file, stop
    if (line_status == INI_EOT) break;
  }

  #ifdef INI_PARSER_TEST
  // close file
  fclose(ini_fp);
  #endif
}


//// ini_save() ////
void ini_save(const ini_cfg_t* cfg)
{
  int section, var, ini_pt;
  char line[INI_LINE_SIZE] = {0};

  // open ini file
  #ifdef INI_PARSER_TEST
  if ((ini_fp = fopen(cfg->filename, "wb")) == NULL) {
  #else
  { //#error
  #endif
    ini_parser_debugf("Can't open file %s !", cfg->filename);
    return;
  }

  // loop over sections
  for (section=0; section<cfg->nsections; section++) {
    ini_parser_debugf("writing section %s ...", cfg->sections[section].name);
    sprintf(line, "[%s]\n", cfg->sections[section].name);
    ini_pt = ini_putline(line);
    // loop over vars
    for (var=0; var<cfg->nvars; var++) {
      if (cfg->vars[var].section_id == cfg->sections[section].id) {
        ini_parser_debugf("writing var %s", cfg->vars[var].name);
        switch (cfg->vars[var].type) {
          case UINT8:
          case UINT16:
          case UINT32:
            sprintf(line, "%s=%u\n", cfg->vars[var].name, *(uint32_t*)(cfg->vars[var].var));
            break;
          case INT8:
          case INT16:
          case INT32:
            sprintf(line, "%s=%d\n", cfg->vars[var].name, *(int32_t*)(cfg->vars[var].var));
            break;
          #ifdef INI_ENABLE_FLOAT
          case FLOAT:
            sprintf(line, "%s=%f\n", cfg->vars[var].name, *(float*)(cfg->vars[var].var));
            break;
          #endif
          case STRING:
            sprintf(line, "%s=\"%s\"\n", cfg->vars[var].name, (char*)(cfg->vars[var].var));
            break;
        }
        ini_pt = ini_putline(line);
      }
    }
  }

  // in case the buffer is not written yet, write it now
  if (ini_pt) {
    #ifdef INI_PARSER_TEST
    fwrite(sector_buffer, sizeof(char), ini_pt, ini_fp);
    #else
    //#error
    #endif
  }
}

