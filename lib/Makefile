# ==============================================================================
#  Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
#  SPDX-License-Identifier: MIT
# 
# ==============================================================================
#
# Makefile
# -- The script is used to generate library files: libreconic.so and libreconic.a
#
# ==============================================================================

# Compiler and flags
CC = gcc
CFLAGS = -Wall -Werror -fPIC

# Directories
SRC_DIR = $(CURDIR)
OBJ_DIR = $(CURDIR)/obj
LIB_DIR = $(CURDIR)

# Source files
SRCS = $(wildcard $(SRC_DIR)/*.c)
OBJS = $(patsubst $(SRC_DIR)/%.c,$(OBJ_DIR)/%.o,$(SRCS))

# Output libraries
LIB_NAME = libreconic
SHARED_LIB = $(LIB_DIR)/$(LIB_NAME).so
STATIC_LIB = $(LIB_DIR)/$(LIB_NAME).a

# Targets
all: $(SHARED_LIB) $(STATIC_LIB)

$(SHARED_LIB): $(OBJS)
	$(CC) -shared -o $@ $^

$(STATIC_LIB): $(OBJS)
	ar rcs $@ $^

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c
	@mkdir -p $(OBJ_DIR)
	$(CC) $(CFLAGS) -c -o $@ $<

clean:
	rm -rf $(OBJ_DIR) $(SHARED_LIB) $(STATIC_LIB)

.PHONY: all clean
