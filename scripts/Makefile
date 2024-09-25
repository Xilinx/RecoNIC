# ==============================================================================
#  Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
#  SPDX-License-Identifier: MIT
# 
# ==============================================================================
#
# Makefile
# -- The script is used to prepare build files and build the project to generate
#    hardware bitstream
#
# ==============================================================================

# Please make sure you have exported BOARD_REPO in your system environment
ROOT_DIR     := ..
SHELL_DIR    := $(ROOT_DIR)/shell
SCRIPT_DIR   := $(ROOT_DIR)/scripts
BUILD_DIR    := $(ROOT_DIR)/build
RN_BUILD_DIR := $(BUILD_DIR)/reconic

IMPL       ?= 1

OVERWRITE  ?= 1

GEN_HLS    ?= 0

BOARD      ?= au250

PYTHON_EXE ?= python

# Check Vivado version
VIVADO_VERSION := $(shell vivado -version | grep ^Vivado |  sed -n 's/.*\(v[0-9]*.[0-9]*\).*/\1/p')

# Module directories
## RecoNIC top module
RN_TOP            := $(SHELL_DIR)/top
## Packet Classification module
PC                := packet_classification
PKT_CLASSI_DIR    := $(SHELL_DIR)/$(PC)
## Tag Matching module
TM                := tag_matching
TAG_MATCH_DIR     := $(SHELL_DIR)/$(TM)
## Address Translator module
AT                := address_translator
ADDR_TRANS_DIR    := $(SHELL_DIR)/$(AT)
## Lookaside Compute module
LC                := lookside
LOOKASIDE_COMP_DIR := $(SHELL_DIR)/compute/$(LC)
## TODO: Add Streaming Compute module
#SC                := streaming
#STREAMING_COMP_DIR := $(SHELL_DIR)/compute/$(SC)
## Utilities
UTILITIES_DIR     := $(SHELL_DIR)/utilities
## Plugs
PLUGS_DIR         := $(SHELL_DIR)/plugs

PLUGIN_DIR     := $(PLUGS_DIR)/rdma_onic_plugin
SMARTNIC_DIR := $(ROOT_DIR)/base_nics/open-nic-shell/src/box_250mhz
SMARTNIC_SCRIPT_DIR := $(ROOT_DIR)/base_nics/open-nic-shell/script

build_nic: build_reconic
ifeq ($(IMPL), 1)
	cd $(SMARTNIC_SCRIPT_DIR); vivado -mode batch -source build.tcl -tclargs -max_pkt_len 9600 -impl 1 -overwrite $(OVERWRITE) -board_repo $(BOARD_REPO) -board $(BOARD)
else
	cd $(SMARTNIC_SCRIPT_DIR); vivado -mode batch -source build.tcl -tclargs -max_pkt_len 9600 -impl 0 -overwrite $(OVERWRITE) -board_repo $(BOARD_REPO) -board $(BOARD)
endif

build_reconic: clean_build hls_build
	mkdir -p $(BUILD_DIR)
	mkdir -p $(RN_BUILD_DIR)
	mkdir -p $(RN_BUILD_DIR)/$(LC)
	cp -rf $(PLUGIN_DIR)/* $(BUILD_DIR)/
	cp -rf $(RN_TOP) $(RN_BUILD_DIR)/
	cp -rf $(PKT_CLASSI_DIR) $(RN_BUILD_DIR)/
	cp -rf $(UTILITIES_DIR) $(RN_BUILD_DIR)/
	cp $(LOOKASIDE_COMP_DIR)/*.sv $(RN_BUILD_DIR)/$(LC)/
	cp $(LOOKASIDE_COMP_DIR)/interface/*.v $(RN_BUILD_DIR)/$(LC)/
	cp $(LOOKASIDE_COMP_DIR)/kernel/*.v $(RN_BUILD_DIR)/$(LC)/
	cd $(BUILD_DIR); $(PYTHON_EXE) $(SCRIPT_DIR)/build_tcl.py -nic rdma-opennic
	cp -rf $(BUILD_DIR)/* $(SMARTNIC_DIR)/

hls_build:
ifeq ($(GEN_HLS), 1)
	mkdir -p $(LOOKASIDE_COMP_DIR)/interface
	mkdir -p $(LOOKASIDE_COMP_DIR)/kernel
	cd $(LOOKASIDE_COMP_DIR); vitis_hls -f ./cl_box.tcl; vitis_hls -f ./mmult.tcl
	cp $(LOOKASIDE_COMP_DIR)/cl_box/solution1/syn/verilog/* $(LOOKASIDE_COMP_DIR)/interface/
	cp $(LOOKASIDE_COMP_DIR)/mmult/solution1/syn/verilog/* $(LOOKASIDE_COMP_DIR)/kernel/
else
ifeq (,$(wildcard $(LOOKASIDE_COMP_DIR)/interface/cl_box.v))
	mkdir -p $(LOOKASIDE_COMP_DIR)/interface
	cd $(LOOKASIDE_COMP_DIR); vitis_hls -f ./cl_box.tcl
	cp $(LOOKASIDE_COMP_DIR)/cl_box/solution1/syn/verilog/* $(LOOKASIDE_COMP_DIR)/interface/
else
	@echo "Use old files in $(LOOKASIDE_COMP_DIR)/interface"
endif

ifeq (,$(wildcard $(LOOKASIDE_COMP_DIR)/kernel/mmult.v))
	mkdir -p $(LOOKASIDE_COMP_DIR)/kernel
	cd $(LOOKASIDE_COMP_DIR); vitis_hls -f ./mmult.tcl
	cp $(LOOKASIDE_COMP_DIR)/mmult/solution1/syn/verilog/* $(LOOKASIDE_COMP_DIR)/kernel/
else
	@echo "Use old files in $(LOOKASIDE_COMP_DIR)/kernel"
endif
endif

clean_build:
	rm -rf $(BUILD_DIR)/*

clean:
	rm -rf $(BUILD_DIR)/*
	rm -rf $(SMARTNIC_DIR)/*
