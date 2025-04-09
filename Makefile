################################################################################
# Makefile for VNP4 Project
#
# quick usage:
#   $ make                      # Build the entire project. same make build-open-nic-shell
#   $ make build-open-nic-shell # Build Open NIC Shell
#   $ make get-devices          # Show FPGA Device List
#   $ make program-bit          # Program FPGA with bitstream
#   $ make program-mcs          # Program flash memory with MCS file
#   $ make generate-p4-ip       # Generate Vitis Net P4 IP core from P4 file
#   $ make alias-custom-ip      # Create symbolic link to custom IP for Open NIC Shell
#   $ make p4-drivers           # Build p4-drivers
#   $ make sw                   # Build sw based on p4-drivers
#   $ make log                  # Show vnp4_framework/open-nic-shell/script/vivado.log
#   $ make ide                  # Open vivado GUI
#   $ make clean-log            # Remove vivado log files
#   $ make clean                # Remove generated files (not include BUILD_PATH)
#   $ make clean-all            # Remove generated files (include BUILD_PATH)
################################################################################
.PHONY: all build-open-nic-shell get-devices program-bit program-mcs generate-p4-ip alias-custom-ip p4-drivers sw log ide clean-log clean clean-all

###########################################################################
##### Project Build Script Options
###########################################################################
P4_FILE           := $(abspath main.p4)
SW_PATH           := $(abspath sw)
BUILD_PATH        := $(abspath build)
USER_EXTERNS_PATH := $(abspath user_externs)

###########################################################################
##### OpenNIC Build Script Options (open-nic-shell/script/build.tcl)
###########################################################################
## Build options
BOARD           := au50
TAG             := vnp4_nic
JOBS            := $(shell nproc)
SYNTH_IP        := 1
IMPL            := 1
POST_IMPL       := 1

USER_PLUGIN     := $(abspath vnp4_framework/user_plugin/shared_txrx_250)

## Design parameters
BUILD_TIMESTAMP := $(shell date +%y%m%d%H%M)
MIN_PKT_LEN     := 64
MAX_PKT_LEN     := 1514
NUM_PHYS_FUNC   := 1
NUM_QDMA        := 1
NUM_CMAC_PORT   := 1

###########################################################################
##### Program Options
###########################################################################
PROGRAM_HW_SERVER   := 127.0.0.1:3121
PROGRAM_DEVICE_NAME := xcu50_u55n_0
PROGRAM_FLASH_PART  := mt25qu01g-spi-x1_x2_x4

###########################################################################
##### Config Defines
###########################################################################
ifeq ($(TAG),"")
    OPEN_NIC_SHELL_BUILD_NAME := $(BOARD)
else
    OPEN_NIC_SHELL_BUILD_NAME := $(BOARD)_$(TAG)
endif

OPEN_NIC_SHELL_PATH       := $(abspath vnp4_framework/open-nic-shell)
OPEN_NIC_SHELL_BUILD_PATH := $(OPEN_NIC_SHELL_PATH)/build/$(OPEN_NIC_SHELL_BUILD_NAME)
OPEN_NIC_SHELL_IMPLE_PATH := $(OPEN_NIC_SHELL_BUILD_PATH)/open_nic_shell/open_nic_shell.runs/impl_1
OPEN_NIC_SHELL_BIT_FILE   := $(OPEN_NIC_SHELL_IMPLE_PATH)/open_nic_shell.bit
OPEN_NIC_SHELL_MCS_FILE   := $(OPEN_NIC_SHELL_IMPLE_PATH)/open_nic_shell.mcs
BOARD_SETTING_TCL_FILE    := $(OPEN_NIC_SHELL_PATH)/script/board_settings/$(BOARD).tcl

CUSTOM_IP_PATH := $(BUILD_PATH)/ip
BIT_FILE       := $(BUILD_PATH)/open_nic_shell.bit
MCS_FILE       := $(BUILD_PATH)/open_nic_shell.mcs

###########################################################################
##### Tasks
###########################################################################
all: build-open-nic-shell

build-open-nic-shell: generate-p4-ip alias-custom-ip
	cd $(OPEN_NIC_SHELL_PATH)/script && vivado -mode batch -source build.tcl -tclargs \
		-board $(BOARD) \
		-tag $(TAG) \
		-jobs $(JOBS) \
		-synth_ip $(SYNTH_IP) \
		-impl $(IMPL) \
		-post_impl $(POST_IMPL) \
		-user_plugin $(USER_PLUGIN) \
		-build_timestamp $(BUILD_TIMESTAMP) \
		-min_pkt_len $(MIN_PKT_LEN) \
		-max_pkt_len $(MAX_PKT_LEN) \
		-num_phys_func $(NUM_PHYS_FUNC) \
		-num_qdma $(NUM_QDMA) \
		-num_cmac_port $(NUM_CMAC_PORT) \
		-rebuild 1
	mkdir -p "$(BUILD_PATH)"
	@if [ "$(IMPL)" = "1" ]; then \
		rm -f "$(BIT_FILE)"; \
		cp "$(OPEN_NIC_SHELL_BIT_FILE)" "$(BUILD_PATH)"; \
	fi
	@if [ "$(POST_IMPL)" = "1" ]; then \
		rm -f "$(MCS_FILE)"; \
		cp "$(OPEN_NIC_SHELL_MCS_FILE)" "$(BUILD_PATH)"; \
	fi

generate-p4-ip:
	mkdir -p "$(CUSTOM_IP_PATH)"
	vivado -mode batch -source "$(USER_PLUGIN)/scripts/generate_vitis_net_p4_ip.tcl" \
		-tclargs "$(BOARD_SETTING_TCL_FILE)" "$(CUSTOM_IP_PATH)" "$(P4_FILE)" "$(USER_EXTERNS_PATH)"

alias-custom-ip:
	mkdir -p "$(CUSTOM_IP_PATH)"
	mkdir -p "$(OPEN_NIC_SHELL_BUILD_PATH)/vivado_ip"
	ln -s "$(CUSTOM_IP_PATH)" "$(OPEN_NIC_SHELL_BUILD_PATH)/vivado_ip/custom"

get-devices:
	vivado -mode batch -notrace -source vnp4_framework/scripts/get_devices.tcl -tclargs $(PROGRAM_HW_SERVER)

program-bit: $(BIT_FILE)
	vivado -mode batch -source vnp4_framework/scripts/program_bit.tcl -tclargs $(PROGRAM_HW_SERVER) $(PROGRAM_DEVICE_NAME) $(BIT_FILE)

program-mcs: $(MCS_FILE)
	vivado -mode batch -source vnp4_framework/scripts/program_mcs.tcl -tclargs $(PROGRAM_HW_SERVER) $(PROGRAM_DEVICE_NAME) $(MCS_FILE) $(PROGRAM_FLASH_PART)

p4-drivers:
	cd $(BUILD_PATH)/ip/vitis_net_p4_core/src/sw/drivers && make INSTALL_ROOT=$(SW_PATH)/driver

sw: p4-drivers
	cd $(SW_PATH) && make

log:
	cat $(OPEN_NIC_SHELL_PATH)/script/vivado.log

ide: $(OPEN_NIC_SHELL_BUILD_PATH)/open_nic_shell/open_nic_shell.xpr
	vivado $(OPEN_NIC_SHELL_BUILD_PATH)/open_nic_shell/open_nic_shell.xpr &

clean-log:
	rm -f vivado*.log vivado*.jou vivado*.str

clean: clean-log
	rm -rf $(OPEN_NIC_SHELL_PATH)/build
	rm -f  $(OPEN_NIC_SHELL_PATH)/script/vivado.log

clean-all: clean
	rm -rf $(BUILD_PATH)
