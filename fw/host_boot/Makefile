# MINIMIG-DE1
# host boot firmware
# 2012, rok.krajnc@gmail.com


### programs ###
VASM    = ../../sw/vasm/vasmm68k_mot
XXD     = xxd
HEX2MEM = ../../sw/hex2mem/hex2mem.py


### flags ###
ASMFLAGS=-m68000 -showopt -Fbin
XXDFLAGS=-ps -c 2
HEXFLAGS=-a 10 -s 1024 -w 4


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


### files ###

# asm sources
ASM_SOURCES=hostboot.asm


### build rules ###

# all
all:
	@echo Making host boot firmware ...
	@make bin
	@make bin/hostboot.v

bin:
	@echo $@
	@mkdir -p $(BINDIR)

bin/hostboot.bin : Makefile bin $(ASM_SOURCES)
	@echo $@
	@$(VASM) $(ASMFLAGS) $(ASM_SOURCES) -o $@

bin/hostboot.hex : Makefile bin bin/hostboot.bin
	@echo $@
	@$(XXD) $(XXDFLAGS) $(@:.hex=.bin) > $@

bin/hostboot.v : Makefile bin bin/hostboot.hex
	@echo $@
	@$(HEX2MEM) $(HEXFLAGS) $(@:.v=.hex) $@

# clean
clean:
	@echo clean
	@rm -rf ./$(BINDIR)

