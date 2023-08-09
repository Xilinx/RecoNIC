//==============================================================================
// Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
// SPDX-License-Identifier: MIT
//
//==============================================================================
//  Description: 
//    This is a program used to evaluate a systolic-array based matrix multiplication 
//		accelerator on FPGA. The data will be copied from host memory to device memory
//		via QDMA AXI-MM channel. When data is ready, the host will construct a control
//		command and issue to the accelerator inside the reconic shell. Then the
//		accelerator reads data and starts computation. Once the computation is finished,
//		it'll store results to destination configured in the control command received
//		and at the same time, it will also write a complete signal to the status FIFO
//		attached. The host will do polling on this status FIFO. Once, it detects non-
//		empty of the FIFO, it will copy the result back to the host memory.
//==============================================================================

#include "systolic_mm.h"

#define DEVICE_NAME_DEFAULT "/dev/reconic-mm"

// Software implementation of Matrix Multiplication
// The inputs are of the size (DATA_SIZE x DATA_SIZE)
void software_mmult(
    int in1[DATA_SIZE*DATA_SIZE], //Input Matrix 1
    int in2[DATA_SIZE*DATA_SIZE], //Input Matrix 2
    int out[DATA_SIZE*DATA_SIZE]  //Output Matrix
) {
    //Perform Matrix multiply Out = In1 x In2
    for (int i = 0; i < DATA_SIZE; i++) {
        for (int j = 0; j < DATA_SIZE; j++) {
            for (int k = 0; k < DATA_SIZE; k++) {
                out[i * DATA_SIZE + j] +=
                    in1[i * DATA_SIZE + k] * in2[k * DATA_SIZE + j];
            }
        }
    }
}

static struct option const long_opts[] = {
	{"device"       , required_argument, NULL, 'd'},
	{"pcie_resource", required_argument, NULL, 'p'},
	{"help"         , no_argument      , NULL, 'h'},
	{0              , 0                , 0   ,  0 }
};

static void usage(const char *name)
{
	int i = 0;

	fprintf(stdout, "usage: %s [OPTIONS]\n\n", name);

	fprintf(stdout, "  -%c (--%s) character device name (defaults to %s)\n",
		long_opts[i].val, long_opts[i].name, DEVICE_NAME_DEFAULT);
	i++;
	fprintf(stdout, "  -%c (--%s) PCIe resource \n",
		long_opts[i].val, long_opts[i].name);
	i++;
	fprintf(stdout, "  -%c (--%s) print usage help and exit\n",
		long_opts[i].val, long_opts[i].name);
}

void init_ctl_cmd(ctl_cmd_t* ctl_cmd, uint32_t a_baseaddr, uint32_t b_baseaddr, \
									uint32_t c_baseaddr, uint32_t ctl_cmd_size, uint16_t a_row, \
									uint16_t a_col, uint16_t b_col, uint16_t work_id) {
	ctl_cmd->ctl_cmd_size = ctl_cmd_size;
	ctl_cmd->a_baseaddr = a_baseaddr;
	ctl_cmd->b_baseaddr = b_baseaddr;
	ctl_cmd->c_baseaddr = c_baseaddr;
	ctl_cmd->a_row = a_row;
	ctl_cmd->a_col = a_col;
	ctl_cmd->b_col = b_col;
	ctl_cmd->work_id = work_id;
}

ssize_t read_to_buffer(char *fname, int fd, char *buffer, uint64_t size,
			uint64_t base)
{
	ssize_t rc;
	uint64_t count = 0;
	char *buf = buffer;
	off_t offset = base;

	do { /* Support zero byte transfer */
		uint64_t bytes = size - count;

		if (bytes > RW_MAX_SIZE)
			bytes = RW_MAX_SIZE;

		if (offset) {
			rc = lseek(fd, offset, SEEK_SET);
			if (rc < 0) {
				fprintf(stderr,
					"%s, seek off 0x%lx failed %zd.\n",
					fname, offset, rc);
				perror("seek file");
				return -EIO;
			}
			if (rc != offset) {
				fprintf(stderr,
					"%s, seek off 0x%lx != 0x%lx.\n",
					fname, rc, offset);
				return -EIO;
			}
		}

		/* read data from file into memory buffer */
		rc = read(fd, buf, bytes);
		if (rc < 0) {
			fprintf(stderr,
				"%s, read off 0x%lx + 0x%lx failed %zd.\n",
				fname, offset, bytes, rc);
			perror("read file");
			return -EIO;
		}
		if (rc != bytes) {
			fprintf(stderr,
				"%s, R off 0x%lx, 0x%lx != 0x%lx.\n",
				fname, count, rc, bytes);
			return -EIO;
		}

		count += bytes;
		buf += bytes;
		offset += bytes;
	} while (count < size);

	if (count != size) {
		fprintf(stderr, "%s, R failed 0x%lx != 0x%lx.\n",
				fname, count, size);
		return -EIO;
	}
	return count;
}

ssize_t write_from_buffer(char *fname, int fd, char *buffer, uint64_t size,
			uint64_t base)
{
	ssize_t rc;
	uint64_t count = 0;
	char *buf = buffer;
	off_t offset = base;

	do { /* Support zero byte transfer */
		uint64_t bytes = size - count;

		if (bytes > RW_MAX_SIZE)
			bytes = RW_MAX_SIZE;

		if (offset) {
			rc = lseek(fd, offset, SEEK_SET);
			if (rc < 0) {
				fprintf(stderr,
					"%s, seek off 0x%lx failed %zd.\n",
					fname, offset, rc);
				perror("seek file");
				return -EIO;
			}
			if (rc != offset) {
				fprintf(stderr,
					"%s, seek off 0x%lx != 0x%lx.\n",
					fname, rc, offset);
				return -EIO;
			}
		}

		/* write data to file from memory buffer */
		rc = write(fd, buf, bytes);
		if (rc < 0) {
			fprintf(stderr, "%s, W off 0x%lx, 0x%lx failed %zd.\n",
				fname, offset, bytes, rc);
			perror("write file");
			return -EIO;
		}
		if (rc != bytes) {
			fprintf(stderr, "%s, W off 0x%lx, 0x%lx != 0x%lx.\n",
				fname, offset, rc, bytes);
			return -EIO;
		}

		count += bytes;
		buf += bytes;
		offset += bytes;
	} while (count < size);

	if (count != size) {
		fprintf(stderr, "%s, R failed 0x%lx != 0x%lx.\n",
				fname, count, size);
		return -EIO;
	}
	return count;
}

void write32_data(uint32_t* base_address, off_t offset, uint32_t value) {
  uint32_t* config_addr;

  config_addr = (uint32_t* ) ((uintptr_t) base_address + offset);
  *(config_addr) = value;  
}

uint32_t read32_data(uint32_t* base_address, off_t offset) {
  uint32_t value;
  uint32_t* config_addr;

  config_addr = (uint32_t* ) ((uintptr_t) base_address + offset);
  value = *((uint32_t* ) config_addr);
  
  return value;
}

void issue_ctl_cmd(void* axil_base, uint32_t offset, ctl_cmd_t* ctl_cmd) {
	uint32_t ctl_cmd_element;
	write32_data((uint32_t*) axil_base, RN_CLR_CTL_CMD, ctl_cmd->ctl_cmd_size);
	write32_data((uint32_t*) axil_base, RN_CLR_CTL_CMD, ctl_cmd->a_baseaddr);
	write32_data((uint32_t*) axil_base, RN_CLR_CTL_CMD, ctl_cmd->b_baseaddr);
	write32_data((uint32_t*) axil_base, RN_CLR_CTL_CMD, ctl_cmd->c_baseaddr);
	ctl_cmd_element = ((ctl_cmd->a_row << 16) & 0xffff0000) | (ctl_cmd->a_col & 0x0000ffff);
	write32_data((uint32_t*) axil_base, RN_CLR_CTL_CMD, ctl_cmd_element);
	ctl_cmd_element = ((ctl_cmd->b_col << 16) & 0xffff0000) | (ctl_cmd->work_id & 0x0000ffff);
	write32_data((uint32_t*) axil_base, RN_CLR_CTL_CMD, ctl_cmd_element);
}

int main(int argc, char *argv[])
{
	int cmd_opt;
	char *device = DEVICE_NAME_DEFAULT;
	char *pcie_device = NULL;
	int reconic_fd;
	uint64_t address = 0;
	uint64_t offset = 0;
	uint64_t count = COUNT_DEFAULT;

	uint32_t ctl_cmd_size = 6;
	uint16_t a_row = DATA_SIZE;
	uint16_t a_col = DATA_SIZE;
	uint16_t b_col = DATA_SIZE;
	uint32_t a_baseaddr = 0;
	uint32_t b_baseaddr = a_row*a_col*4;
	uint32_t c_baseaddr = a_row*a_col*4*2;
	uint32_t work_id = 0xdd;
	uint32_t hw_work_id = 0;
	uint32_t compute_done;
	uint32_t axil_map_size = RN_SCR_MAP_SIZE;
	ssize_t rc;
	double total_time = 0;
	double avg_time = 0;
	struct timespec ts_start, ts_end;
	void* axil_base;

	size_t matrix_size = DATA_SIZE * DATA_SIZE;
	size_t matrix_size_bytes = sizeof(int) * matrix_size;

	while ((cmd_opt =
		getopt_long(argc, argv, "d:p:h", long_opts,
			    NULL)) != -1) {
		switch (cmd_opt) {
		case 'd':
			/* device node name */
			//fprintf(stdout, "'%s'\n", optarg);
			device = strdup(optarg);
			break;
		case 'p':
			/* PCIe resource file name */
			pcie_device = strdup(optarg);
			break;
		/* print usage help and exit */
		case 'h':
		default:
			usage(argv[0]);
			exit(0);
			break;
		}
	}

	/*
	int source_in1[matrix_size];
	int source_in2[matrix_size];
	int source_hw_results[matrix_size];
	int source_sw_results[matrix_size];
	*/

	int* source_in1 = NULL;
	int* source_in2 = NULL;
	int* source_hw_results = NULL;
	int source_sw_results[matrix_size];

	posix_memalign((void **)&source_in1, 1024, matrix_size*4);
	if (!source_in1) {
		fprintf(stderr, "OOM %lu.\n", matrix_size*4);
		rc = -ENOMEM;
		free(source_in1);
		goto out;
	}

	// Lock the page in memory
	if(mlock(source_in1, matrix_size*4*3) == -1) {
		fprintf(stderr, "Failed to lock page in memory: %s\n", strerror(errno));
		free(source_in1);
		goto out;
	}

	posix_memalign((void **)&source_in2, 1024, matrix_size*4);
	if (!source_in2) {
		fprintf(stderr, "OOM %lu.\n", matrix_size*4);
		rc = -ENOMEM;
		free(source_in2);
		goto out;
	}

	// Lock the page in memory
	if(mlock(source_in2, matrix_size*4*3) == -1) {
		fprintf(stderr, "Failed to lock page in memory: %s\n", strerror(errno));
		free(source_in2);
		goto out;
	}

	posix_memalign((void **)&source_hw_results, 1024, matrix_size*4);
	if (!source_hw_results) {
		fprintf(stderr, "OOM %lu.\n", matrix_size*4);
		rc = -ENOMEM;
		free(source_hw_results);
		goto out;
	}

	// Lock the page in memory
	if(mlock(source_hw_results, matrix_size*4*3) == -1) {
		fprintf(stderr, "Failed to lock page in memory: %s\n", strerror(errno));
		free(source_hw_results);
		goto out;
	}
	
	/*
	char* data = NULL;
	int* source_in1 = NULL;
	int* source_in2 = NULL;
	int* source_hw_results = NULL;
	int source_sw_results[matrix_size];

	posix_memalign((void **)&data, 4096, matrix_size*4*3);
	if (!data) {
		fprintf(stderr, "OOM %lu.\n", matrix_size*4*3);
		rc = -ENOMEM;
		free(data);
		goto out;
	}

	// Lock the page in memory
	if(mlock(data, matrix_size*4*3) == -1) {
		fprintf(stderr, "Failed to lock page in memory: %s\n", strerror(errno));
		free(data);
		goto out;
	}

	source_in1 = (int *) (data);
	source_in2 = (int *) (data + matrix_size*4);
	source_hw_results = (int *) (data + matrix_size*4*2);
	*/

	// Create the test data and Software Result
	for (size_t i = 0; i < matrix_size; i++) {
		source_in1[i] = i % 10;
		source_in2[i] = i % 10;
		source_sw_results[i] = 0;
		source_hw_results[i] = 0;
	}

	// Get register control access
	reconic_fd = open(pcie_device, O_RDWR | O_SYNC);
	if(reconic_fd < 0) {
		fprintf(stderr, "unable to open pcie resource %s, %d.\n",
						pcie_device, reconic_fd);
		perror("open pcie device");
		return -EINVAL;
	}

	axil_base = mmap(NULL, axil_map_size, PROT_READ | PROT_WRITE, MAP_SHARED, reconic_fd, 0);

  if (axil_base == MAP_FAILED) {
    printf("Error: axil_base mmap failed\n");
    close(reconic_fd);
    return -EINVAL;
  }

	// Copy data from host memory to device memory
	int fpga_fd = open(device, O_RDWR);
	if (fpga_fd < 0) {
		fprintf(stderr, "unable to open device %s, %d.\n",
			device, fpga_fd);
		perror("open device");
		close(fpga_fd);
		return -EINVAL;
	}

	clock_gettime(CLOCK_MONOTONIC, &ts_start);
	
	rc = write_from_buffer(device, fpga_fd, (char*) source_in1, matrix_size*4, (uint64_t) a_baseaddr);
	if (rc < 0)
			goto out;

	rc = write_from_buffer(device, fpga_fd, (char*) source_in2, matrix_size*4, (uint64_t)b_baseaddr);
	if (rc < 0)
			goto out;
	
	/*
	rc = write_from_buffer(device, fpga_fd, (char*) source_in1, matrix_size*4*3, (uint64_t) a_baseaddr);
	if (rc < 0)
			goto out;
	*/

	// Construct control command and issue to the reconic shell
	ctl_cmd_t ctl_cmd;
	init_ctl_cmd(&ctl_cmd, a_baseaddr, b_baseaddr, c_baseaddr, ctl_cmd_size, a_row, a_col, b_col, work_id);

	// Start FPGA accelerator
	issue_ctl_cmd(axil_base, RN_CLR_CTL_CMD, &ctl_cmd);

	// Polling the status register and get data back
	compute_done = 0;
	while(compute_done == 0) {
		compute_done = read32_data((uint32_t*) axil_base, RN_CLR_JOB_COMPLETED_NOT_READ);
	}

	rc = read_to_buffer(device, fpga_fd, (char*) source_hw_results, matrix_size*4, (uint64_t)c_baseaddr);
	if (rc < 0)
			goto out;

	//rc = read_to_buffer(device, fpga_fd, (char*) source_in1, matrix_size*4*3, (uint64_t)a_baseaddr);

	rc = clock_gettime(CLOCK_MONOTONIC, &ts_end);

	/* subtract the start time from the end time */
	timespec_sub(&ts_end, &ts_start);
	total_time += (ts_end.tv_sec + ((double)ts_end.tv_nsec/NSEC_DIV));

	fprintf(stdout, "** Avg time device %s, total time %f sec, size = %d\n",	device, total_time, DATA_SIZE);

	// Compute Software Results
	software_mmult(source_in1, source_in2, source_sw_results);

	hw_work_id = read32_data((uint32_t*) axil_base, RN_CLR_KER_STS);

	// Compare the results of the Device to the simulation
	int not_match = 0;
	for (int i = 0; i < DATA_SIZE * DATA_SIZE; i++) {
			if (source_hw_results[i] != source_sw_results[i]) {
					fprintf(stdout, "Error: Result mismatch\n");
					fprintf(stdout, "i = %d,  CPU result = %d\n", i, source_sw_results[i]);
					fprintf(stdout, "Hardware result = %d\n",source_hw_results[i]);
					not_match = 1;
					break;
			}
	}

	if(work_id != hw_work_id) {
		not_match = 1;
	}

	if(not_match) {
		fprintf(stdout, "Test failed!\n");
		rc = -1;
	} else {
		fprintf(stdout, "Test passed!\n");
		rc = 0;
	}

	/*
	free(source_in1);
	free(source_in2);
	free(source_hw_results);
	*/

out:
	close(reconic_fd);
	close(fpga_fd);

	return rc;
}
