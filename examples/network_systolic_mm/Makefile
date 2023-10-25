#==============================================================================
# Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
# SPDX-License-Identifier: MIT
#
#==============================================================================
#
#   This file is part of the RecoNIC's systolic-array-based matrix 
#   multiplication test application
#   
#==============================================================================

# Compiler and flags
CC = gcc
CFLAGS = -Wall -Werror
LDFLAGS = -L../../lib
LDLIBS = -lreconic

# Directories
SRC_DIR = $(CURDIR)
OBJ_DIR = $(CURDIR)/obj
BIN_DIR = $(CURDIR)

# Source files
SRCS = $(wildcard $(SRC_DIR)/*.c)
OBJS = $(patsubst $(SRC_DIR)/%.c,$(OBJ_DIR)/%.o,$(SRCS))

# Library path
LIB_INCLUDE = -I../../lib

# Generate target names from source file names
TARGETS = $(patsubst $(SRC_DIR)/%.c,$(BIN_DIR)/%,$(SRCS))

# Default target
all: $(TARGETS)

# Rule to build each target
$(BIN_DIR)/%: $(OBJ_DIR)/%.o
	@mkdir -p $(BIN_DIR)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^ $(LDLIBS)

# Rule to build object files from source files
$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c
	@mkdir -p $(OBJ_DIR)
	$(CC) $(CFLAGS) $(LIB_INCLUDE) -c -o $@ $<

clean:
	rm -rf $(OBJ_DIR) $(TARGETS)

.PHONY: all clean