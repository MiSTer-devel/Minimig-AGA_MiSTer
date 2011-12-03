
typedef struct
{
    char name[8];
    char long_name[16];
} kickstartTYPE;

typedef struct
{
    unsigned char lores;
    unsigned char hires;
} filterTYPE;

typedef struct
{
    unsigned char speed;
    unsigned char drives;
} floppyTYPE;

typedef struct
{
    unsigned char enabled;
    unsigned char present;
    char name[8];
    char long_name[16];
} hardfileTYPE;

typedef struct
{
    char          id[8];
    unsigned long version;
    kickstartTYPE kickstart;
    filterTYPE    filter;
    unsigned char memory;
    unsigned char chipset;
    floppyTYPE    floppy;
    unsigned char disable_ar3;
    unsigned char enable_ide;
    unsigned char scanlines;
    hardfileTYPE  hardfile[2];
} configTYPE;

extern configTYPE config; 
