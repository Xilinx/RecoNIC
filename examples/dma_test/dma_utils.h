//==============================================================================
// Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
// SPDX-License-Identifier: MIT
//
//==============================================================================

#ifndef __DMA_UTILS_H__
#define __DMA_UTILS_H__

#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <ctype.h>
#include <errno.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <time.h>

#include <getopt.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/types.h>
#include <assert.h>

/*
 * man 2 write:
 * On Linux, write() (and similar system calls) will transfer at most
 * 	0x7ffff000 (2,147,479,552) bytes, returning the number of bytes
 *	actually transferred.  (This is true on both 32-bit and 64-bit
 *	systems.)
 */

#define RW_MAX_SIZE	0x7ffff000
#define GB_DIV 1000000000
#define MB_DIV 1000000
#define KB_DIV 1000
#define NSEC_DIV 1000000000

extern int verbose;

uint64_t getopt_integer(char *optarg);

void dump_throughput_result(uint64_t size, float result, float lat_result);

void timespec_sub(struct timespec *t1, struct timespec *t2);

ssize_t read_to_buffer(char *fname, int fd, char *buffer, uint64_t size,
			uint64_t base);

ssize_t write_from_buffer(char *fname, int fd, char *buffer, uint64_t size,
			uint64_t base);

#endif // __DMA_UTILS_H__