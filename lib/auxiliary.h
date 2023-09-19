//==============================================================================
// Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
// SPDX-License-Identifier: MIT
//
//==============================================================================

/** @file auxiliary.h
 *  @brief Helper functions and declarations.
 *
 */

#ifndef __AUXILIARY_H__
#define __AUXILIARY_H__

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <net/if.h>
#include <ifaddrs.h>
#include <sys/mman.h>
#include <netdb.h>
#include <errno.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <inttypes.h>
#include <string.h>
#include <assert.h>
#include <time.h>

#ifndef CLOCK_MONOTONIC
#define CLOCK_MONOTONIC 1
#endif
#define NSEC_DIV 1000000000

/*! \var debug
    \brief A global variable used to print out debug message
*/
extern int debug;

/*! \def BIT(nr)
    \brief Get the 'nr'-th bit mask.
*/
#define BIT(nr) (1UL << (nr))

/*! \def Debug(fmt, ...)
    \brief Define a debug message format.
*/
#define Debug(fmt, ...) \
    if(debug == 1) { \
        fprintf(stderr, "%s:%d:%s(): " fmt, __FILE__, \
            __LINE__, __func__, ##__VA_ARGS__); \
    }

/*
#define Debug(fmt, ...) \
   if(getenv("DEBUG") && atoi(getenv("DEBUG")) == 1) { \
       fprintf(stderr, "%s:%d:%s(): " fmt, __FILE__, \
           __LINE__, __func__, ##__VA_ARGS__); \
   }
*/

/*! \def htonll(x)
    \brief Conversion from host byte order to network byte order.
*/
#define htonll(x) (((uint64_t)htonl((x) & 0xFFFFFFFF) << 32) | htonl((x) >> 32))

/*! \def ntohll(x)
    \brief Conversion from network byte order to host byte order.
*/
#define ntohll(x) (((uint64_t)ntohl((x) & 0xFFFFFFFF) << 32) | ntohl((x) >> 32))

/** @brief Subtract timespec t2 from t1
 *  @param t1 A timespec pointer as an end timer. Result is stored in the end timer.
 *  @param t2 A timespec pointer as a start timer.
 *  @return void.
 */
void timespec_sub(struct timespec *t1, struct timespec *t2);

#endif /* __AUXILIARY_H__ */