//==============================================================================
// Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
// SPDX-License-Identifier: MIT
//
//==============================================================================

/** @file memory_api.h
 *  @brief User-space memory driver
 *
 *  Memory driver is used to read/write data from/to the device memory.
 *  The host serves as a master and prepares/configures DMA to communicate with 
 *  the device memory.
 */

#ifndef __MEMORY_API_H__
#define __MEMORY_API_H__

#include "auxiliary.h"

/*! \def DEVICE_MEMORY_ADDRESS_MASK
    \brief Device memory address mask.

    Use to make sure device memory addresses fall within 64GB range.
*/
#define DEVICE_MEMORY_ADDRESS_MASK 0x0000001FFFFFFFFF

/*! \def RW_MAX_SIZE
    \brief Maximum size in bytes of DMA transfer per transaction.

    RW_MAX_SIZE is set to 2GB
*/
#define RW_MAX_SIZE	0x7ffff000

/** @brief A function used to read data from the device memory to the host buffer.
 *  @param char_device Name of the character device used to interact with the FPGA 
 *                     for memory access.
 *  @param fd File descriptor of the char_device.
 *  @param buffer a destination host buffer used to store data.
 *  @param size size of data.
 *  @param dev_offset a source address offset of the device memory.
 *  @return Return size of data read successfully.
 */
ssize_t read_to_buffer(char *char_device, int fd, char *buffer, uint64_t size, uint64_t dev_offset);

/** @brief A function used to write data in the host buffer to the device memory.
 *  @param char_device Name of the character device used to interact with the FPGA 
 *                     for memory access.
 *  @param fd File descriptor of the char_device.
 *  @param buffer a source buffer located at the host side.
 *  @param size size of data.
 *  @param dev_offset a destination address offset of the device memory.
 *  @return Return size of data written successfully.
 */
ssize_t write_from_buffer(char *char_device, int fd, char *buffer, uint64_t size, uint64_t base);

#endif /* __MEMORY_API_H__ */