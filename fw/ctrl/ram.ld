MEMORY {
	ram (rwx)	: ORIGIN = 0x00400000, LENGTH = 512k
	}

/* Always be sure to change both - MEMORY and next variables */
__ram_start = 0x00400000;
__ram_length = 512k;

__stack     = __ram_start + __ram_length - 0x4;
_heap_end   = __stack - 0x1000;
PROVIDE (__stack =  __ram_start + __ram_length - 0x4);
PROVIDE (__rom_size = __data_end - __ram_start);

SECTIONS
{
	.vectors :
	{
	 *(.vectors)
  . = ALIGN(0x4);
	} > ram

	.text :
	{
  PROVIDE(__text_start = .);
	 *(.text)
   *(.text.*)
	 . = ALIGN(0x4);
	} > ram
        
  .rodata :
  {
	 *(.rodata)
   *(.rodata.str1.1)
  } > ram

	. = ALIGN(0x4);
	__data_ram = .;
	PROVIDE(__data_ram = .);

	.data : AT (__data_ram)
	{
	 . = ALIGN(0x4);
	 __data_start = .;
	 PROVIDE (__data_start = .);
	 *(.data)
   *(.data.*)
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

