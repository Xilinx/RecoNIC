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

CC ?= gcc

CFLAGS += -g
CFLAGS += -I.
CFLAGS += $(EXTRA_FLAGS)

MM = systolic_mm
MM_OBJS := systolic_mm.o

ifneq ($(CROSS_COMPILE_FLAG),)
	CC=$(CROSS_COMPILE_FLAG)gcc
endif

all: clean systolic_mm

systolic_mm: $(MM_OBJS)
	$(CC) -lrt -o $@ $< -D_FILE_OFFSET_BITS=64 -D_GNU_SOURCE -D_LARGE_FILE_SOURCE

%.o: %.c
	$(CC) $(CFLAGS) -c -std=c99 -o $@ $< -D_FILE_OFFSET_BITS=64 -D_GNU_SOURCE -D_LARGE_FILE_SOURCE -D_AIO_AIX_SOURCE

clean:
	@rm -f *.o */*.o
	rm -rf *.o *.bin systolic_mm
