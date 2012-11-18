MEMORY {
  rom (rx)  : ORIGIN = 0x00000000, LENGTH = 5120
	ram (rwx)	: ORIGIN = 0x00440000, LENGTH = 128k
	}

/* Always be sure to change both - MEMORY and next variables */
__ram_start = 0x00440000;
__ram_length = 128k;
__rom_start = 0x00000000;
__rom_length = 5120;

__stack     = __ram_start + __ram_length - 0x4;
_heap_end   = __stack - 0x1000;
PROVIDE (__stack =  __ram_start + __ram_length - 0x4);
PROVIDE (__rom_size = __data_rom + __data_end - __data_start);

SECTIONS
{
	.vectors :
	{
	 *(.vectors)
  . = ALIGN(0x4);
	} > rom

	.text :
	{
  PROVIDE(__text_start = .);
	 *(.text)
   *(.text.*)
	 . = ALIGN(0x4);
	} > rom
        
  .rodata :
  {
	 *(.rodata)
   *(.rodata.str1.1)
   . = ALIGN(0x4);
  } > rom

	__data_rom = .;
	PROVIDE(__data_rom = .);

	.data : AT (__data_rom)
	{
	 . = ALIGN(0x4);
	 __data_start = .;
	 PROVIDE (__data_start = .);
	 *(.data)
   *(.data.*)
	 . = ALIGN(0x4);
	 __data_end = .;
	 PROVIDE (__data_end = .);
	} > ram

	.bss :
	{
	 . = ALIGN(0x4);
	 __bss_start = .;
	 PROVIDE (__bss_start = .);
	 *(.bss)
	 __bss_end = .;
	 PROVIDE (__bss_end = .);
	} > ram

  . = ALIGN(0x4);
  PROVIDE (_heap_start = .);


	.stack :
	{
	 *(.stack)
	} > ram
}

