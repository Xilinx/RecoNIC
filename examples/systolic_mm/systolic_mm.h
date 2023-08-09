//==============================================================================
// Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
// SPDX-License-Identifier: MIT
//
//==============================================================================
#ifndef __SYSTOLIC_MM__
#define __SYSTOLIC_MM__

#include <assert.h>
#include <fcntl.h>
#include <getopt.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <time.h>

#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>

#include "rn_register.h"

#define SIZE_DEFAULT (32)
#define COUNT_DEFAULT (1)

#define RW_MAX_SIZE	0x7ffff000
#define GB_DIV 1000000000
#define MB_DIV 1000000
#define KB_DIV 1000
#define NSEC_DIV 1000000000

//Array Size to access
#define DATA_SIZE 16

//Maximum Array Size
#define MAX_SIZE 16

typedef struct {
	uint32_t ctl_cmd_size;
	uint32_t a_baseaddr;
	uint32_t b_baseaddr;
	uint32_t c_baseaddr;
	uint16_t a_row;
	uint16_t a_col;
	uint16_t b_col;
	uint16_t work_id;
} ctl_cmd_t;

/* Subtract timespec t2 from t1
 *
 * Both t1 and t2 must already be normalized
 * i.e. 0 <= nsec < 1000000000
 */
static int timespec_check(struct timespec *t)
{
	if ((t->tv_nsec < 0) || (t->tv_nsec >= 1000000000))
		return -1;
	return 0;

}

void timespec_sub(struct timespec *t1, struct timespec *t2)
{
	if (timespec_check(t1) < 0) {
		fprintf(stderr, "invalid time #1: %lld.%.9ld.\n",
			(long long)t1->tv_sec, t1->tv_nsec);
		return;
	}
	if (timespec_check(t2) < 0) {
		fprintf(stderr, "invalid time #2: %lld.%.9ld.\n",
			(long long)t2->tv_sec, t2->tv_nsec);
		return;
	}
	t1->tv_sec -= t2->tv_sec;
	t1->tv_nsec -= t2->tv_nsec;
	if (t1->tv_nsec >= 1000000000) {
		t1->tv_sec++;
		t1->tv_nsec -= 1000000000;
	} else if (t1->tv_nsec < 0) {
		t1->tv_sec--;
		t1->tv_nsec += 1000000000;
	}
}

#endif