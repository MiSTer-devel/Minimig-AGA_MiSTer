# fw makefile
# 2012, rok.krajnc@gmail.com


### tools ###

# tools path
ifndef OR32_OLD_TOOLCHAIN_PATH
OR32_OLD_TOOLCHAIN_PATH=~/Dropbox/work/electronics/fpga/jpegdec/sw/or32-toolchain-3.2-old/bin/
endif

ifndef OR32_TOOLCHAIN_PATH
OR32_TOOLCHAIN_PATH=~/Dropbox/work/electronics/fpga/jpegdec/sw/or32-elf-1.0rc1/bin/
endif

ifndef CROSS_COMPILE
CROSS_COMPILE = $(OR32_TOOLCHAIN_PATH)or32-elf-
endif


# programs
AS	= $(CROSS_COMPILE)as
LD	= $(CROSS_COMPILE)ld
CC	= $(CROSS_COMPILE)gcc
AR	= $(CROSS_COMPILE)ar
NM	= $(CROSS_COMPILE)nm
STRIP	= $(CROSS_COMPILE)strip
OBJCOPY = $(CROSS_COMPILE)objcopy
OBJDUMP = $(CROSS_COMPILE)objdump
RANLIB	= $(CROSS_COMPILE)ranlib


# flags
CFLAGS +=   -W -Wall -std=gnu99 -g \
            -Os \
            -fomit-frame-pointer -ffreestanding -static -combine -fwhole-program \
            -fno-strict-aliasing \
            -fno-builtin -nostdlib \
            -Wl,--relax \
            -msoft-mul -msoft-div
            #-ffunction-sections -fdata-sections -Wl,--gc-sections

LDFLAGS +=


### variables ###
BUILD_USER=\"$(USER)\"
BUILD_T=$$(date +%Y-%m-%d)
BUILD_TIME=\"$(BUILD_T)\"
BUILD_NUM=$$(cat build_num.txt)


### fw specific ###

# include dirs
CINCLUDES += -I./common

# headers
HEADERS=

# asm sources
ASM_SOURCES=start.S

# common sources
COMMON_SOURCES=main.c

# all sources
ALL_SOURCES = $(ASM_SOURCES) $(COMMON_SOURCES)

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
	@echo "There is no all rule."
	@echo $@
	@make out/fw.hex


bin/firmware.or32: $(LD_SCRIPT) $(ALL_SOURCES) $(FW_SOURCES)
	@echo $(MSG)
	@echo bin/firmware.or32
	@$(CC) -Wl,-Map,bin/firmware.map -D__BUILD_USER=$(BUILD_USER) -D__BUILD_TIME=$(BUILD_TIME) -D__BUILD_NUM=$(BUILD_NUM) $(CFLAGS) $(CINCLUDES) $(ALL_SOURCES) -T$(LD_SCRIPT) -o bin/firmware.or32
	@echo $$(($$(cat build_num.txt) + 1)) > build_num.txt
	@$(OBJDUMP) -DSx bin/firmware.or32 > bin/firmware.dis.S

# bin file
bin/firmware.bin: bin/firmware.or32
	@echo bin/firmware.bin
	@$(OBJCOPY) -O binary bin/firmware.or32 bin/firmware.bin

# hex file
out/fw.hex out/rom.hex: bin/firmware.bin
	@echo out/fw.hex
	@xxd -ps -c 4 bin/firmware.bin > out/fw.hex
	@xxd -ps -c 1 bin/firmware.bin > out/rom.hex
	@cat $@ | sed 's/^/0x/' > out/fw.serial
	@unix2dos out/fw.serial
	@wc -l out/fw.serial

# altera memory initialization file
out/fw.mif: out/fw.hex
	@echo out/fw.mif
	@../sw/hex2mif/hex2mif.py out/fw.hex out/fw.mif

# clean
clean:
	@echo clean
	@rm -rf ./out/*
	@rm -rf ./bin/*
	@rm -rf ./obj/*

