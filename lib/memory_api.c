//==============================================================================
// Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
// SPDX-License-Identifier: MIT
//
//==============================================================================

/** @file memory_api.c
 *  @brief User-space memory driver.
 *
 *  Memory driver is used to read/write data from/to the device memory.
 *  The host serves as a master and prepares/configures DMA to communicate with 
 *  the device memory.
 *
 */

#include "memory_api.h"

ssize_t read_to_buffer(char *char_device, int fd, char *buffer, uint64_t size,
			uint64_t dev_offset)
{
	ssize_t rc;
	uint64_t count = 0;
	char *buf = buffer;
	off_t offset = dev_offset & DEVICE_MEMORY_ADDRESS_MASK;

	do { /* Support zero byte transfer */
		uint64_t bytes = size - count;

		if (bytes > RW_MAX_SIZE)
			bytes = RW_MAX_SIZE;

    rc = lseek(fd, offset, SEEK_SET);
    if (rc < 0) {
      fprintf(stderr,
        "%s, seek off 0x%lx failed %zd.\n",
        char_device, offset, rc);
      perror("seek file");
      return -EIO;
    }
    if (rc != offset) {
      fprintf(stderr,
        "%s, seek off 0x%lx != 0x%lx.\n",
        char_device, rc, offset);
      return -EIO;
    }
		

		/* read data from file into memory buffer */
		rc = read(fd, buf, bytes);
		if (rc < 0) {
			fprintf(stderr,
				"%s, read off 0x%lx + 0x%lx failed %zd.\n",
				char_device, offset, bytes, rc);
			perror("read file");
			return -EIO;
		}
		if (rc != bytes) {
			fprintf(stderr,
				"%s, R off 0x%lx, 0x%lx != 0x%lx.\n",
				char_device, count, rc, bytes);
			return -EIO;
		}

		count += bytes;
		buf += bytes;
		offset += bytes;
	} while (count < size);

	if (count != size) {
		fprintf(stderr, "%s, R failed 0x%lx != 0x%lx.\n",
				char_device, count, size);
		return -EIO;
	}
	return count;
}

ssize_t write_from_buffer(char *char_device, int fd, char *buffer, uint64_t size,
			uint64_t dev_offset)
{
	ssize_t rc;
	uint64_t count = 0;
	char *buf = buffer;
	off_t offset = dev_offset & DEVICE_MEMORY_ADDRESS_MASK;

	do { /* Support zero byte transfer */
		uint64_t bytes = size - count;

		if (bytes > RW_MAX_SIZE)
			bytes = RW_MAX_SIZE;

    rc = lseek(fd, offset, SEEK_SET);
    if (rc < 0) {
      fprintf(stderr,
        "%s, seek off 0x%lx failed %zd.\n",
        char_device, offset, rc);
      perror("seek file");
      return -EIO;
    }
    if (rc != offset) {
      fprintf(stderr,
        "%s, seek off 0x%lx != 0x%lx.\n",
        char_device, rc, offset);
      return -EIO;
    }

		/* write data to file from memory buffer */
		rc = write(fd, buf, bytes);
		if (rc < 0) {
			fprintf(stderr, "%s, W off 0x%lx, 0x%lx failed %zd.\n",
				char_device, offset, bytes, rc);
			perror("write file");
			return -EIO;
		}
		if (rc != bytes) {
			fprintf(stderr, "%s, W off 0x%lx, 0x%lx != 0x%lx.\n",
				char_device, offset, rc, bytes);
			return -EIO;
		}

		count += bytes;
		buf += bytes;
		offset += bytes;
	} while (count < size);

	if (count != size) {
		fprintf(stderr, "%s, R failed 0x%lx != 0x%lx.\n",
				char_device, count, size);
		return -EIO;
	}
	return count;
}