/*---------------------------------------------------------------------------*/
/*-         ATMEL Microcontroller Software Support  -  ROUSSET  -            */
/*---------------------------------------------------------------------------*/
/* The software is delivered "AS IS" without warranty or condition of any    */
/* kind, either express, implied or statutory. This includes without	     */
/* limitation any warranty or condition with respect to merchantability or   */
/* fitness for any particular purpose, or against the infringements of	     */
/* intellectual property rights of others.				     */
/*---------------------------------------------------------------------------*/
/*- File source          : GCC_FLASH.ld                                      */
/*- Object               : Linker Script File for Flash Workspace            */
/*- Compilation flag     : None                                              */
/*-                                                                          */
/*- 1.0 11/Mar/05 JPP    : Creation S256                                     */
/*---------------------------------------------------------------------------*/

/* 
   24-02-2006  Ewout Boks. Adapted from AT91SAM7S64-RAM.ld script by M. Thomas. 
   - Changed the memory sections to model the AT91SAM7S256 .
   - tested succesfully with AT91SAM7 GPIO Example and PEEDI debugger
     on AT91SAM7S-EK equipped with AT91SAM7S256 
*/

/* Memory Definitions */

MEMORY
{
  FLASH (rx) : ORIGIN = 0x00100000, LENGTH = 0x00040000
  DATA (rw)  : ORIGIN = 0x00200000, LENGTH = 0x00010000
  STACK (rw) : ORIGIN = 0x00210000, LENGTH = 0x00000000
}


/* Section Definitions */

SECTIONS
{
  /* first section is .text which is used for code */
  . = 0x0000000;
  .text : { *Cstartup.o (.text) }>FLASH =0
  .text :
  {
    *(.text)                   /* remaining code */

    *(.glue_7t) *(.glue_7)

  } >FLASH

  . = ALIGN(4);

  /* .rodata section which is used for read-only data (constants) */

  .rodata :
  {
    *(.rodata)
  } >FLASH

  . = ALIGN(4);

  _etext = . ;
  PROVIDE (etext = .);

  /* .data section which is used for initialized data */

  .data : AT (_etext)
  {
    _data = . ;
    *(.data)
    SORT(CONSTRUCTORS)
    . = ALIGN(4);
    *(.ramsection)         /* "RAM-Functions" */ /* added by mthomas */
  } >DATA
  . = ALIGN(4);

  _edata = . ;
   PROVIDE (edata = .);

  /* .bss section which is used for uninitialized data */

  .bss :
  {
    __bss_start = . ;
    __bss_start__ = . ;
    *(.bss)
    *(COMMON)
  } 
  . = ALIGN(4);
  __bss_end__ = . ;
  __end__ = . ;
  _end = .;
  PROVIDE (end = .);

    . = ALIGN(4);
   .int_data :  
   { 
   *(.internal_ram_top) 
   }> STACK 



  /* Stabs debugging sections.  */
  .stab          0 : { *(.stab) }
  .stabstr       0 : { *(.stabstr) }
  .stab.excl     0 : { *(.stab.excl) }
  .stab.exclstr  0 : { *(.stab.exclstr) }
  .stab.index    0 : { *(.stab.index) }
  .stab.indexstr 0 : { *(.stab.indexstr) }
  .comment       0 : { *(.comment) }
  /* DWARF debug sections.
     Symbols in the DWARF debugging sections are relative to the beginning
     of the section so we begin them at 0.  */
  /* DWARF 1 */
  .debug          0 : { *(.debug) }
  .line           0 : { *(.line) }
  /* GNU DWARF 1 extensions */
  .debug_srcinfo  0 : { *(.debug_srcinfo) }
  .debug_sfnames  0 : { *(.debug_sfnames) }
  /* DWARF 1.1 and DWARF 2 */
  .debug_aranges  0 : { *(.debug_aranges) }
  .debug_pubnames 0 : { *(.debug_pubnames) }
  /* DWARF 2 */
  .debug_info     0 : { *(.debug_info .gnu.linkonce.wi.*) }
  .debug_abbrev   0 : { *(.debug_abbrev) }
  .debug_line     0 : { *(.debug_line) }
  .debug_frame    0 : { *(.debug_frame) }
  .debug_str      0 : { *(.debug_str) }
  .debug_loc      0 : { *(.debug_loc) }
  .debug_macinfo  0 : { *(.debug_macinfo) }
  /* SGI/MIPS DWARF 2 extensions */
  .debug_weaknames 0 : { *(.debug_weaknames) }
  .debug_funcnames 0 : { *(.debug_funcnames) }
  .debug_typenames 0 : { *(.debug_typenames) }
  .debug_varnames  0 : { *(.debug_varnames) }

}
