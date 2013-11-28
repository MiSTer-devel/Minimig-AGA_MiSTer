# MINIMIG-DE1
# ctrl boot firmware
# 2012, rok.krajnc@gmail.com


### paths ###
HEX2MEM_DIR = ../../sw/hex2mem/
HEX2MIF_DIR = ../../sw/hex2mif/


### tools ###

# make sure or32-elf-gcc is in path, or comment next line and set path
OR32_TOOLCHAIN_PATH=

ifndef OR32_TOOLCHAIN_PATH
OR32_TOOLCHAIN_PATH=/opt/or32-elf-1.0rc1/bin/
endif

ifndef CROSS_COMPILE
CROSS_COMPILE = $(OR32_TOOLCHAIN_PATH)or32-elf-
endif


### programs ###
AS      = $(CROSS_COMPILE)as
LD      = $(CROSS_COMPILE)ld
CC      = $(CROSS_COMPILE)gcc
AR      = $(CROSS_COMPILE)ar
NM      = $(CROSS_COMPILE)nm
STRIP   = $(CROSS_COMPILE)strip
OBJCOPY = $(CROSS_COMPILE)objcopy
OBJDUMP = $(CROSS_COMPILE)objdump
RANLIB  = $(CROSS_COMPILE)ranlib
XXD     = xxd
HEX2MEM = $(HEX2MEM_DIR)hex2mem.py
HEX2MIF = $(HEX2MIF_DIR)hex2mif.py


### flags ###
CFLAGS +=   -W -Wall -Wpadded -Winline -std=gnu99 -g \
            -Os \
            -fomit-frame-pointer -ffreestanding -static -combine -fwhole-program \
            -fno-strict-aliasing \
            -fno-builtin -nostdlib \
            -Wl,--relax \
            -msoft-mul -msoft-div

LDFLAGS +=

XXDFLAGS=-ps -c 4
HEXFLAGS=-w 8 -s 1024 -n


### variables ###
BUILD_USER=\"$(USER)\"
BUILD_T=$$(date +%Y-%m-%d)
BUILD_TIME=\"$(BUILD_T)\"
BUILD_N=$$(cat build_num.txt)
BUILD_NUM=\"$(BUILD_N)\"
BUILD_R=$$(git rev-parse --verify HEAD)
BUILD_REV=\"$(BUILD_R)\"

BINDIR=bin
OBJDIR=obj


### fw specific ###

# include dirs
CINCLUDES +=

# headers
HEADERS=spr_defs.h or32_defs.h hardware.h string.h swap.h errors.h mmc.h fat.h

# asm sources
ASM_SOURCES=start.S

# common sources
COMMON_SOURCES=main.c hardware.c string.c swap.c mmc.c fat.c
 
# all sources
ALL_SOURCES = $(ASM_SOURCES) $(COMMON_SOURCES)

# linker script
ROM_LD=rom.ld
RAM_LD=ram.ld

# get target from commandline
ifeq ($(target),RAM)
  LD_SCRIPT=$(RAM_LD)
  CFLAGS+=-DRAM_FW
  MSG=Making RAM image ...
else
  LD_SCRIPT=$(ROM_LD)
  CFLAGS+=-DROM_FW
  MSG=Making ROM image ...
endif


### build rules ###

# all
all: bin bin/ctrl_boot.v bin/ctrl_boot.mif

bin:
	@mkdir -p bin

bin/ctrl_boot.or32: Makefile $(LD_SCRIPT) $(ALL_SOURCES)
	@echo $(MSG)
	@echo $@
	@$(CC) -Wl,-Map,$(@:.or32=.map) -D__BUILD_USER=$(BUILD_USER) -D__BUILD_TIME=$(BUILD_TIME) -D__BUILD_NUM=$(BUILD_NUM) -D__BUILD_REV=$(BUILD_REV) $(CFLAGS) $(CINCLUDES) $(ALL_SOURCES) -T$(LD_SCRIPT) -o $@
	@echo -n $$(($$(cat build_num.txt) + 1)) > build_num.txt
	@$(OBJDUMP) -DSx $@ > $(@:.or32=.dis.S)

bin/ctrl_boot.bin: bin/ctrl_boot.or32
	@echo $@
	@$(OBJCOPY) -O binary $< $@

bin/ctrl_boot.hex : bin/ctrl_boot.bin
	@echo $@
	@$(XXD) $(XXDFLAGS) $(@:.hex=.bin) > $@

bin/ctrl_boot.v : bin/ctrl_boot.hex
	@echo $@
	@$(HEX2MEM) $(HEXFLAGS) $(@:.v=.hex) $@

bin/ctrl_boot.mif : bin/ctrl_boot.hex
	@echo $@
	@$(HEX2MIF) $(@:.mif=.hex) $@

# clean
clean:
	@echo clean
	@rm -rf ./bin

