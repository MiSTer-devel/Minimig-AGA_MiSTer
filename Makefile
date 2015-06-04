# MINIMIG-MIST
# top makefile
# 2015, rok.krajnc@gmail.com


### board ###
BOARD?=mist


### release ###
RELEASE?=minimig-mist-test

### paths ###
REL_DIR      = rel
FW_DIR       = fw
FPGA_DIR     = fpga
FW_SRC_DIR   = $(FW_DIR)/$(BOARD)
FPGA_SRC_DIR = $(FPGA_DIR)/$(BOARD)
FW_REL_DIR   = $(REL_DIR)/$(RELEASE)
FPGA_REL_DIR = $(REL_DIR)/$(RELEASE)


### files ###
FW_BIN_FILES   = $(FW_SRC_DIR)/firmware.bin $(FW_SRC_DIR)/firmware.hex $(FW_SRC_DIR)/firmware.upg
FPGA_BIN_FILES = $(FPGA_SRC_DIR)/out/minimig_mist.rbf


### build rules ###
BUILD_OPT=clean all


# all
all: dirs
	@echo Building all ...
	@make fw
	@make fpga
	@echo DONE building all!

# directories
dirs: Makefile
	@echo Creating release dirs $(REL_DIR)/$(RELEASE) ...
	@mkdir -p $(REL_DIR)
	@mkdir -p $(REL_DIR)/$(RELEASE)
	@mkdir -p $(FW_REL_DIR)
	@mkdir -p $(FPGA_REL_DIR)

# fw
fw: Makefile dirs
	@echo Building firmware in $(FW_SRC_DIR) ...
	@$(MAKE) -C $(FW_SRC_DIR) $(BUILD_OPT)
	@cp $(FW_BIN_FILES) $(FW_REL_DIR)/

# fpga
fpga: Makefile dirs
	@echo Building FPGA in $(FPGA_SRC_DIR) ...
	@$(MAKE) -C $(FPGA_SRC_DIR) $(BUILD_OPT)
	@cp $(FPGA_BIN_FILES) $(FPGA_REL_DIR)/

# clean
clean:
	@echo Clearing release dir ...
#	@rm -rf $(FW_REL_DIR)
#	@rm -rf $(FPGA_REL_DIR)
	@$(MAKE) -C $(FW_SRC_DIR) clean
	@$(MAKE) -C $(FPGA_SRC_DIR) clean

