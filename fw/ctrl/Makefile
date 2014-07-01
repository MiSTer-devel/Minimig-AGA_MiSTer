# MINIMIG-DE1
# ctrl boot firmware
# 2012, rok.krajnc@gmail.com

### tools ###

# make sure or32-elf-gcc is in path, or comment next line and set path
OR32_TOOLCHAIN_PATH=

ifndef OR32_TOOLCHAIN_PATH
OR32_TOOLCHAIN_PATH=/opt/or32-elf-1.0rc1/bin/
endif

ifndef CROSS_COMPILE
CROSS_COMPILE = $(OR32_TOOLCHAIN_PATH)or32-elf-
endif


# programs
AS      = $(CROSS_COMPILE)as
LD      = $(CROSS_COMPILE)ld
CC      = $(CROSS_COMPILE)gcc
AR      = $(CROSS_COMPILE)ar
NM      = $(CROSS_COMPILE)nm
STRIP   = $(CROSS_COMPILE)strip
OBJCOPY = $(CROSS_COMPILE)objcopy
OBJDUMP = $(CROSS_COMPILE)objdump
RANLIB  = $(CROSS_COMPILE)ranlib


# flags
CFLAGS +=   -W -Winline -std=gnu99 -g \
            -Os \
            -fomit-frame-pointer -ffreestanding -static -combine -fwhole-program \
            -fno-strict-aliasing \
            -fno-builtin -nostdlib \
            -Wl,--relax \
            -msoft-mul -msoft-div
# -fpack_struct
# -Wpacked -Wpadded

LDFLAGS +=


### variables ###
BUILD_USER=\"$(USER)\"
BUILD_T=$$(date +%Y-%m-%d)
BUILD_TIME=\"$(BUILD_T)\"
BUILD_N=$$(cat build_num.txt)
BUILD_NUM=\"$(BUILD_N)\"
BUILD_R=$$(git rev-parse --verify HEAD)
BUILD_REV=\"$(BUILD_R)\"
BUILD_TG=$$(git describe --tags --abbrev=0)
BUILD_TAG=\"$(BUILD_TG)\"

BINDIR=bin
OBJDIR=obj


### fw specific ###



# include dirs
CINCLUDES += -I. -Ilib/ -Iklibc/

# headers
#CHEADERS=lib/string.h lib/stdio.h hardware.h or32_defs.h spr_defs.h firmware.h config.h errors.h charrom.h fat.h fdd.h fpga.h hdd.h hdd_internal.h logo.h menu.h mmc.h osd.h rafile.h swap.h

# asm sources
ASM_SOURCES=start.S

# KLIBC sources
KLIBC_SOURCES=klibc/memcmp.c klibc/memcpy.c klibc/memset.c klibc/printf.c klibc/sprintf.c klibc/strcat.c klibc/strchr.c klibc/strcpy.c klibc/strlen.c klibc/strncat.c klibc/strncmp.c klibc/strncpy.c klibc/vsnprintf.c

# common sources
COMMON_SOURCES=hardware.c boot.c config.c fat.c fdd.c fpga.c hdd.c main.c menu.c mmc.c osd.c rafile.c swap.c serial.c

# all sources
ALL_SOURCES = $(ASM_SOURCES) $(KLIBC_SOURCES) $(COMMON_SOURCES)

# linker script
ROM_LD=rom.ld
RAM_LD=ram.ld

# get target from commandline
ifeq ($(target),ROM)
  LD_SCRIPT=$(ROM_LD)
  MSG=Making ROM image ...
else
  LD_SCRIPT=$(RAM_LD)
  CFLAGS+=-DRAM_FW
  MSG=Making RAM image ...
endif


### build specific ###

# default fw source
FW_SOURCES=


### build rules ###

# all
all:
	@mkdir -p bin
	@make bin/de1_boot.bin

bin/de1_boot.or32: Makefile $(LD_SCRIPT) $(ALL_SOURCES)
	@echo $(MSG)
	@echo $@
	@$(CC) -Wl,-Map,$(@:.or32=.map) -D__BUILD_USER=$(BUILD_USER) -D__BUILD_TIME=$(BUILD_TIME) -D__BUILD_NUM=$(BUILD_NUM) -D__BUILD_REV=$(BUILD_REV) -D__BUILD_TAG=$(BUILD_TAG) $(CFLAGS) $(CINCLUDES) $(ALL_SOURCES) -T$(LD_SCRIPT) -o $@
	@echo -n $$(($$(cat build_num.txt) + 1)) > build_num.txt
	@$(OBJDUMP) -DSx $@ > $(@:.or32=.dis.S)

# bin file
bin/de1_boot.bin: bin/de1_boot.or32
	@echo $@
	@$(OBJCOPY) -O binary $< $@

# clean
clean:
	@echo clean
	@rm -rf ./bin

