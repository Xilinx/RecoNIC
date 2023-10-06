//==============================================================================
// Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
// SPDX-License-Identifier: MIT
//
//==============================================================================
// Description: 
//    This is a program used to evaluate a systolic-array based matrix multiplication 
// 		accelerator on FPGA. The data will be copied from host memory to device memory
// 		via QDMA AXI-MM channel. When data is ready, the host will construct a control
// 		command and issue to the accelerator inside the RecoNIC shell. Then the
// 		accelerator reads data and starts computation. Once the computation is finished,
// 		it'll store results to destination configured in the control command received
// 		and at the same time, it will also write a complete signal to the status FIFO
// 		attached. The host will do polling on this status FIFO. Once, it detects non-
// 		empty of the FIFO, it will copy the result back to the host memory.
//==============================================================================

#include "network_systolic_mm.h"
#include "rn_register.h"
#include "rn_driver.h"

#define DEVICE_NAME_DEFAULT "/dev/reconic-mm"

uint8_t server;
uint8_t client;

struct mac_addr_t src_mac;
struct mac_addr_t dst_mac;

uint32_t src_ip         = 0;
char src_ip_str[16];
uint32_t dst_ip         = 0;
char dst_ip_str[16];
uint16_t tcp_sport      = 0;
uint16_t udp_sport      = 0;
uint8_t  num_qp         = 8;
uint16_t dst_qpid       = 2;

// For BDF configuration
uint32_t win_size_high = 0;
uint32_t win_size_low  = 0;

#define INFO    1
#define WARNING 2
#define ERROR   3

void print_log(int level, char* message) {
	switch(level) {
		case 1:
			fprintf(stderr, "[INFO] %s\n", message);
			break;
		case 2:
			fprintf(stderr, "[WARNING] %s\n", message);
			break;
		case 3:
			fprintf(stderr, "[ERROR] %s\n", message);
			break;
		default:
			break;
	}
}

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
	{"device"        , required_argument, NULL, 'd'},
	{"pcie_resource" , required_argument, NULL, 'p'},
	{"src_ip"        , required_argument, NULL, 'r'},
	{"dst_ip"        , required_argument, NULL, 'i'},
	{"udp_sport"     , required_argument, NULL, 'u'},
	{"tcp_sport"     , required_argument, NULL, 't'},
	{"dst_qp"        , required_argument, NULL, 'q'},
	{"server"        , no_argument      , NULL, 's'},
	{"client"        , no_argument      , NULL, 'c'},
	{"help"          , no_argument      , NULL, 'h'},
	{0               , 0                , 0   ,  0 }
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
	fprintf(stdout, "  -%c (--%s) Source IP address \n",
		long_opts[i].val, long_opts[i].name);
	i++;
	fprintf(stdout, "  -%c (--%s) Destination IP address \n",
		long_opts[i].val, long_opts[i].name);
	i++;
	fprintf(stdout, "  -%c (--%s) UDP source port \n",
		long_opts[i].val, long_opts[i].name);
	i++;
	fprintf(stdout, "  -%c (--%s) TCP source port \n",
		long_opts[i].val, long_opts[i].name);
	i++;
	fprintf(stdout, "  -%c (--%s) Destination QP number \n",
		long_opts[i].val, long_opts[i].name);
	i++;
	fprintf(stdout, "  -%c (--%s) Server node \n",
		long_opts[i].val, long_opts[i].name);
	i++;
	fprintf(stdout, "  -%c (--%s) Client node \n",
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

void open_rdma_dev(struct rn_dev_t* rn_dev, struct mac_addr_t local_mac, uint32_t local_ip, uint32_t udp_sport) {
  uint32_t xrnic_conf;
  uint32_t xrnic_advanced_conf;
  uint32_t en_ernic;
  uint32_t sw_override_enable;
  uint32_t sw_override_qp_num;
  uint32_t retry_cnt_fatal_dis;
  uint32_t base_count_width;
  uint32_t config_16bit;  
  uint32_t reserved1 = 0;
  uint32_t reserved2 = 0;
  uint32_t err_buf_en = 1;
  uint32_t tx_ack_gen = 0;
  uint32_t config_8bit = 0;
  uint32_t num_qp = 0;

  // configure RDMA global control status register
  // data buffer, IPKTERR queue buffer, error buffer and response error buffer are all stored in device memory.
  // Retry packet buffer is not used.
  // Currently, we use AXI-BRAM as the device memory, which only has 512KB (19-bit address width).
  // Data buffer base address          : 0x00000000; range 0x00000000 - 0x00049FFF; size 488KB
  // IPKERR buffer base address        : 0x0004A000; range 0x0004A000 - 0x0004BFFF; size 8KB (0x2000)
  // Error buffer base address         : 0x0004C000; range 0x0004C000 - 0x0004DFFF; size 8KB
  // Response error buffer base address: 0x0004E000; range 0x0004E000 - 0x0004FFFF; size 8KB

  write32_data(rn_dev->axil_ctl, RN_RDMA_GCSR_DATBUFBA, 0x00000000);
  fprintf(stderr, "[Register] RN_RDMA_GCSR_DATBUFBA=0x%x, value=0x%x\n", RN_RDMA_GCSR_DATBUFBA, 0x00000000);
  write32_data(rn_dev->axil_ctl, RN_RDMA_GCSR_DATBUFBAMSB, 0x00000000);
  fprintf(stderr, "[Register] RN_RDMA_GCSR_DATBUFBAMSB=0x%x, value=0x%x\n", RN_RDMA_GCSR_DATBUFBAMSB, 0x00000000);
  write32_data(rn_dev->axil_ctl, RN_RDMA_GCSR_DATBUFSZ, 499712); // 488KB
  fprintf(stderr, "[Register] RN_RDMA_GCSR_DATBUFSZ=0x%x, value=0x%x\n", RN_RDMA_GCSR_DATBUFSZ, 499712);

  write32_data(rn_dev->axil_ctl, RN_RDMA_GCSR_IPKTERRQBA, 0x0004A000);
  fprintf(stderr, "[Register] RN_RDMA_GCSR_IPKTERRQBA=0x%x, value=0x%x\n", RN_RDMA_GCSR_IPKTERRQBA, 0x0004A000);
  write32_data(rn_dev->axil_ctl, RN_RDMA_GCSR_IPKTERRQBAMSB, 0x00000000);
  fprintf(stderr, "[Register] RN_RDMA_GCSR_IPKTERRQBAMSB=0x%x, value=0x%x\n", RN_RDMA_GCSR_IPKTERRQBAMSB, 0x00000000);
  write32_data(rn_dev->axil_ctl, RN_RDMA_GCSR_IPKTERRQSZ, 8192); // 8KB
  fprintf(stderr, "[Register] RN_RDMA_GCSR_ERRBUFSZ=0x%x, value=0x%x\n", RN_RDMA_GCSR_IPKTERRQSZ, 8192);

  write32_data(rn_dev->axil_ctl, RN_RDMA_GCSR_ERRBUFBA, 0x0004C000);
  fprintf(stderr, "[Register] RN_RDMA_GCSR_ERRBUFBA=0x%x, value=0x%x\n", RN_RDMA_GCSR_ERRBUFBA, 0x0004C000);
  write32_data(rn_dev->axil_ctl, RN_RDMA_GCSR_ERRBUFBAMSB, 0x00000000);
  fprintf(stderr, "[Register] RN_RDMA_GCSR_ERRBUFBAMSB=0x%x, value=0x%x\n", RN_RDMA_GCSR_ERRBUFBAMSB, 0x00000000);
  write32_data(rn_dev->axil_ctl, RN_RDMA_GCSR_ERRBUFSZ, 8192); // 8KB
  fprintf(stderr, "[Register] RN_RDMA_GCSR_ERRBUFSZ=0x%x, value=0x%x\n", RN_RDMA_GCSR_ERRBUFSZ, 8192);

  write32_data(rn_dev->axil_ctl, RN_RDMA_GCSR_RESPERRPKTBA, 0x0004C000);
  fprintf(stderr, "[Register] RN_RDMA_GCSR_RESPERRPKTBA=0x%x, value=0x%x\n", RN_RDMA_GCSR_RESPERRPKTBA, 0x0004C000);
  write32_data(rn_dev->axil_ctl, RN_RDMA_GCSR_RESPERRPKTBAMSB, 0x00000000);
  fprintf(stderr, "[Register] RN_RDMA_GCSR_RESPERRPKTBAMSB=0x%x, value=0x%x\n", RN_RDMA_GCSR_RESPERRPKTBAMSB, 0x00000000);
  write32_data(rn_dev->axil_ctl, RN_RDMA_GCSR_RESPERRSZ, 8192); // 8KB
  fprintf(stderr, "[Register] RN_RDMA_GCSR_RESPERRSZ=0x%x, value=0x%x\n", RN_RDMA_GCSR_RESPERRSZ, 8192);
  write32_data(rn_dev->axil_ctl, RN_RDMA_GCSR_RESPERRSZMSB, 0);
  fprintf(stderr, "[Register] RN_RDMA_GCSR_RESPERRSZMSB=0x%x, value=0x%x\n", RN_RDMA_GCSR_RESPERRSZMSB, 0);

  // configure interrupt - enable all interrupt except for CNP scheduling
  write32_data(rn_dev->axil_ctl, RN_RDMA_GCSR_INTEN, 0x000000FF);
  fprintf(stderr, "[Register] RN_RDMA_GCSR_INTEN=0x%x, value=0x%x\n", RN_RDMA_GCSR_INTEN, 0x000000FF);

  // configure local MAC address
  write32_data(rn_dev->axil_ctl, RN_RDMA_GCSR_MACXADDLSB, local_mac.mac_lsb);
  fprintf(stderr, "[Register] RN_RDMA_GCSR_MACXADDLSB=0x%x, value=0x%x\n", RN_RDMA_GCSR_MACXADDLSB, local_mac.mac_lsb);
  write32_data(rn_dev->axil_ctl, RN_RDMA_GCSR_MACXADDMSB, local_mac.mac_msb);
  fprintf(stderr, "[Register] RN_RDMA_GCSR_MACXADDMSB=0x%x, value=0x%x\n", RN_RDMA_GCSR_MACXADDMSB, local_mac.mac_msb);

  // configure local IPv4 address
  write32_data(rn_dev->axil_ctl, RN_RDMA_GCSR_IPV4XADD, local_ip);
  fprintf(stderr, "[Register] RN_RDMA_GCSR_IPV4XADD=0x%x, value=0x%x\n", RN_RDMA_GCSR_IPV4XADD, local_ip);

  // configure XRNIC control register
  // -- [31:16]: UDP source port for out-going packets (4791-0x12b7 is used as UDP destination 
  //             port) 
  // -- [15:8] : number of QPs enabled, used 8 in simulation 
  // -- [7:6]  : reserved: set to 0
  // -- [5]    : Error buffer enable: set to 0
  // -- [4:3]  : TX ACK generation, use default option: 00 - ACK only generated on explicit 
  //             ACK request in the incoming packet or on timeout
  // -- [2:1]  : reserved
  // -- [0]    : ERNIC enable  
  en_ernic = 1;
  num_qp = (uint32_t) rn_dev->num_qp;
  config_8bit = ((reserved1<<6) & 0x000000c0) | ((err_buf_en<<5) & 0x00000020) | ((tx_ack_gen<<3) & 0x00000018) | ((reserved2<<1) & 0x00000006) | (en_ernic & 0x00000001);
  xrnic_conf = ((udp_sport<<16) & 0xffff0000) | ((num_qp<<8) & 0x0000ff00) | (config_8bit & 0x000000ff);
  write32_data(rn_dev->axil_ctl, RN_RDMA_GCSR_XRNICCONF, xrnic_conf);
  fprintf(stderr, "[Register] RN_RDMA_GCSR_XRNICCONF=0x%x, value=0x%x\n", RN_RDMA_GCSR_XRNICCONF, xrnic_conf);

  // Configure XRNIC Advance configuration
  // -- [0]    : SW override enable. Allows SW write access to the following
  // --          Read Only Registers – CQHEADn, STATCURRSQPTRn, and
  // --          STATRQPIDBn (where is the QP number)
  // -- [1]    : Reserved
  // -- [2]    : retry_cnt_fatal_dis
  // -- [15:3] : Reserved
  // -- [19:16]: Base count width
  // --          Approximate number of system clocks that make 4096us.
  // --          For 400 MHz clock -->Program decimal 11
  // --          For 200 MHz clock --> Program decimal 10
  // --          For 125 MHz clock --> Program decimal 09
  // --          For 100 MHz clock --> Program decimal 09
  // --          For N MHz clock ---> Value should be CLOG2(4.096 *N)
  // -- [20:23]: Reserved
  // -- [31:24]: Software Override QP Number
  sw_override_enable  = 0;
  retry_cnt_fatal_dis = 1;
  base_count_width    = 10;
  sw_override_qp_num  = 0;
  config_16bit = 0x0000000f & ( (sw_override_enable & 0x00000001) | ((retry_cnt_fatal_dis<<2) & 0x00000004) );
  xrnic_advanced_conf = config_16bit | ((base_count_width << 16) & 0x000f0000) | ( (sw_override_qp_num << 24) & 0xff000000);
  write32_data(rn_dev->axil_ctl, RN_RDMA_GCSR_XRNICADCONF, xrnic_advanced_conf);
  fprintf(stderr, "[Register] RN_RDMA_GCSR_XRNICADCONF=0x%x, value=0x%x\n", RN_RDMA_GCSR_XRNICADCONF, xrnic_advanced_conf);

  fprintf(stderr, "Info: rdma_dev opened\n");
}

uint64_t get_win_size() {
  return AXI_BAR_SIZE>>3;
}

void config_rn_dev_axib_bdf(struct rn_dev_t* dev, uint32_t high_addr, uint32_t low_addr) {

  uint64_t win_size = 0;
  uint32_t bdf_addr_mask_high = 0;
  uint32_t bdf_addr_mask_low  = 0;

  uint32_t bdf_addr_high = 0;
  uint32_t bdf_addr_low  = 0;

  uint32_t bdf_win_config;
  uint32_t bdf_win_size_in_4Kpage;

  if(dev == NULL) {
      fprintf(stderr, "Error: rn_dev is NULL\n");
      exit(EXIT_FAILURE);
  }

  win_size = get_win_size();
  win_size_high = (uint32_t) ((win_size & 0xffffffff00000000) >> 32);
  win_size_low  = (uint32_t) (win_size & 0x00000000ffffffff);

  bdf_addr_mask_high = ADDR_MASK - win_size_high;
  bdf_addr_mask_low  = ADDR_MASK - win_size_low;

  bdf_addr_high = high_addr & bdf_addr_mask_high;
  bdf_addr_low  = low_addr & bdf_addr_mask_low;

  bdf_win_size_in_4Kpage = (uint32_t) ( (((AXI_BAR_SIZE>>3) + 1)>>12) & 0x00000000ffffffff);
  bdf_win_config = 0xC0000000 | bdf_win_size_in_4Kpage;

  fprintf(stderr, "Info: Configuring QDMA AXI bridge BDF\n");
  write32_data(dev->axil_ctl, AXIB_BDF_ADDR_TRANSLATE_ADDR_LSB, bdf_addr_low);
  write32_data(dev->axil_ctl, AXIB_BDF_ADDR_TRANSLATE_ADDR_MSB, bdf_addr_high);
  write32_data(dev->axil_ctl, AXIB_BDF_PASID_RESERVED_ADDR, 0);
  write32_data(dev->axil_ctl, AXIB_BDF_FUNCTION_NUM_ADDR, 0);
  write32_data(dev->axil_ctl, AXIB_BDF_MAP_CONTROL_ADDR, bdf_win_config);
  write32_data(dev->axil_ctl, AXIB_BDF_RESERVED_ADDR, 0);
  fprintf(stderr, "[BDF] AXIB_BDF_ADDR_TRANSLATE_ADDR_LSB=0x%x, bdf_addr_low=0x%x\n", AXIB_BDF_ADDR_TRANSLATE_ADDR_LSB, bdf_addr_low);
  fprintf(stderr, "[BDF] AXIB_BDF_ADDR_TRANSLATE_ADDR_MSB=0x%x, bdf_addr_high=0x%x\n", AXIB_BDF_ADDR_TRANSLATE_ADDR_MSB, bdf_addr_high);
  fprintf(stderr, "[BDF] AXIB_BDF_MAP_CONTROL_ADDR=0x%x, bdf_win_config=0x%x\n", AXIB_BDF_MAP_CONTROL_ADDR, bdf_win_config);
  return;
}

struct rdma_dev_t* create_rdma_dev(uint32_t num_qp) {
  int i;
  struct rdma_dev_t* rdma_dev = NULL;
  rdma_dev = (struct rdma_dev_t*) malloc(sizeof(struct rdma_dev_t));
  rdma_dev->glb_csr = (struct rdma_glb_csr_t*) malloc(sizeof(struct rdma_glb_csr_t));
  rdma_dev->qps_ptr = (struct rdma_qp_t**) malloc(num_qp * (sizeof(struct rdma_qp_t*)));
  rdma_dev->axil_ctl = NULL;
  for(i=0; i<num_qp; i++) {
    rdma_dev->qps_ptr[i] = NULL;
  }

  return rdma_dev;
}

/* Used to get the PFN of a virtual address */
unsigned long get_page_frame_number_of_address(void *addr) {
  size_t return_code;  
  // Getting the pagemap file for the current process
  FILE *pagemap = fopen("/proc/self/pagemap", "rb");

  // Seek to the page that the buffer is on
  unsigned long offset = (unsigned long)addr / getpagesize() * PAGEMAP_LENGTH;
  if(fseek(pagemap, (unsigned long)offset, SEEK_SET) != 0) {
    fprintf(stderr, "[ERROR] Failed to seek pagemap to proper location\n");
    exit(1);
  }

  // The page frame number is in bits 0 - 54 so read the first 7 bytes and clear the 55th bit
  unsigned long page_frame_number = 0;
  return_code = fread(&page_frame_number, 1, PAGEMAP_LENGTH-1, pagemap);
  if(return_code != (PAGEMAP_LENGTH-1)) {
    fprintf(stderr, "Error: failed to get page frame number\n");
    return -1;
  }
  page_frame_number &= 0x7FFFFFFFFFFFFF;

  fclose(pagemap);
  return page_frame_number;
}

/* This function is used to get the physical address of a buffer. */
uint64_t get_buffer_paddr(void *buffer) {
  // Getting the page frame the buffer is in
  unsigned long page_frame_number = get_page_frame_number_of_address(buffer);
  
  fprintf(stderr, "Info: get_buffer_paddr - Page frame: 0x%lx\n", page_frame_number);
  
  // Getting the offset of the buffer into the page
  unsigned int distance_from_page_boundary = (unsigned long)buffer % getpagesize();
  
  fprintf(stderr, "Info: get_buffer_paddr - distance from page boundary: 0x%x\n", distance_from_page_boundary);

  uint64_t paddr = (uint64_t)(page_frame_number << PAGE_SHIFT) + (uint64_t)distance_from_page_boundary;

  fprintf(stderr, "Info: get_buffer_paddr - Physical address of buffer: 0x%lx\n", paddr);
  return paddr;
}

struct rn_dev_t* create_rn_dev(char* scr_filename, int* rn_scr, uint32_t scr_map_size, uint32_t num_qp) {
  int scr;
  int rdma = -1;
  void* axil_scr_base;
  uint32_t phy_addr_msb;
  uint32_t phy_addr_lsb;

  struct rn_dev_t* rn_dev = NULL;
  rn_dev = (struct rn_dev_t* ) malloc(sizeof(struct rn_dev_t));
  rn_dev->axil_map_size = scr_map_size;
  rn_dev->rdma_dev = (struct rdma_dev_t* ) malloc(sizeof(struct rdma_dev_t));
  rn_dev->rdma_dev = create_rdma_dev(num_qp);
  rn_dev->base_buf = NULL;
  fprintf(stderr, "create_rn_dev - rdma_dev->axil_ctl=0x%lx, rn_dev->axil_ctl=0x%lx\n", (uint64_t) rn_dev->rdma_dev->axil_ctl, (uint64_t) rn_dev->axil_ctl);
  rn_dev->rdma_dev->num_qp   = num_qp;

  if((scr = open(scr_filename, O_RDWR | O_SYNC)) == -1) {
    fprintf(stderr, "Error can't open %s file for the PCIe resource2!\n", scr_filename);
    exit(EXIT_FAILURE);
  }

  *rn_scr = scr;

  fprintf(stderr, "Info: scr(=%d)) file open successfully\n", scr);

  axil_scr_base = mmap(NULL, scr_map_size, PROT_READ | PROT_WRITE, MAP_SHARED, scr, 0);

  if (axil_scr_base == MAP_FAILED) {
    fprintf(stderr, "Error: axil_scr_base mmap failed\n");
    close(scr);
    exit(EXIT_FAILURE);
  }

  rn_dev->axil_ctl = (uint32_t* ) axil_scr_base;
  rn_dev->num_qp = num_qp;
  rn_dev->rdma_dev->axil_ctl = rn_dev->axil_ctl;

  fprintf(stderr, "create_rn_dev - rdma_dev->axil_ctl=0x%lx, rn_dev->axil_ctl=0x%lx\n", (uint64_t) rn_dev->rdma_dev->axil_ctl, (uint64_t) rn_dev->axil_ctl);

  // Allocate 128MB memory space from HugePages
  rn_dev->base_buf = (struct rdma_buff_t*) malloc(sizeof(struct rdma_buff_t));
  if(rn_dev->base_buf == NULL) {
    fprintf(stderr, "Error: failed to create rn_dev->base_buf\n");
    exit(EXIT_FAILURE);
  }

  rn_dev->base_buf->buffer = mmap(NULL, preallocated_hugepages * (1 << HUGE_PAGE_SHIFT),
                                  PROT_READ | PROT_WRITE, MAP_SHARED | MAP_ANONYMOUS | 
                                  MAP_HUGETLB, -1, 0);

  // Lock the buffer in physical memory
  if(mlock(rn_dev->base_buf->buffer, preallocated_hugepages * (1 << HUGE_PAGE_SHIFT)) == -1) {
    fprintf(stderr, "Error: failed to lock page in memory\n");
    exit(EXIT_FAILURE);
  }

  rn_dev->base_buf->dma_addr = get_buffer_paddr(rn_dev->base_buf->buffer);
  fprintf(stderr, "Info: allocated 1GB buffer vir addr = %p, physical addr = 0x%lx\n", rn_dev->base_buf->buffer, rn_dev->base_buf->dma_addr);

  phy_addr_msb = (uint32_t) ((rn_dev->base_buf->dma_addr & 0xffffffff00000000) >> 32);
  phy_addr_lsb = (uint32_t) ((rn_dev->base_buf->dma_addr & 0x00000000ffffffff));

  // Configure QDMA slave AXI bridge
  config_rn_dev_axib_bdf(rn_dev, phy_addr_msb, phy_addr_lsb);

  rn_dev->buffer_offset = (uint64_t) 0;

  return rn_dev;
}

uint32_t get_rdma_per_q_config_addr(uint32_t offset, uint32_t qpid) {
  return offset + 0x100 * (qpid-1);
}

uint32_t get_rdma_pd_config_addr(uint32_t offset, uint32_t pd_num) {
  return offset + 0x100 * pd_num;
}

void dump_registers(struct rdma_dev_t* rdma_dev, uint8_t is_sender, uint32_t qpid) {
  fprintf(stderr, "Info: Dump register values for debug purpose\n");

  fprintf(stderr, "Info: [RN_RDMA_GCSR_ERRBUFWPTR      = 0x%x] = 0x%x\n", RN_RDMA_GCSR_ERRBUFWPTR     ,read32_data(rdma_dev->axil_ctl, RN_RDMA_GCSR_ERRBUFWPTR));
  fprintf(stderr, "Info: [RN_RDMA_GCSR_IPKTERRQWPTR    = 0x%x] = 0x%x\n", RN_RDMA_GCSR_IPKTERRQWPTR   ,read32_data(rdma_dev->axil_ctl, RN_RDMA_GCSR_IPKTERRQWPTR));
  fprintf(stderr, "Info: [RN_RDMA_GCSR_INSRRPKTCNT     = 0x%x] = 0x%x\n", RN_RDMA_GCSR_INSRRPKTCNT    ,read32_data(rdma_dev->axil_ctl, RN_RDMA_GCSR_INSRRPKTCNT));
  fprintf(stderr, "Info: [RN_RDMA_GCSR_INAMPKTCNT      = 0x%x] = 0x%x\n", RN_RDMA_GCSR_INAMPKTCNT     ,read32_data(rdma_dev->axil_ctl, RN_RDMA_GCSR_INAMPKTCNT));
  fprintf(stderr, "Info: [RN_RDMA_GCSR_OUTIOPKTCNT     = 0x%x] = 0x%x\n", RN_RDMA_GCSR_OUTIOPKTCNT    ,read32_data(rdma_dev->axil_ctl, RN_RDMA_GCSR_OUTIOPKTCNT));
  fprintf(stderr, "Info: [RN_RDMA_GCSR_OUTAMPKTCNT     = 0x%x] = 0x%x\n", RN_RDMA_GCSR_OUTAMPKTCNT    ,read32_data(rdma_dev->axil_ctl, RN_RDMA_GCSR_OUTAMPKTCNT));
  fprintf(stderr, "Info: [RN_RDMA_GCSR_LSTINPKT        = 0x%x] = 0x%x\n", RN_RDMA_GCSR_LSTINPKT       ,read32_data(rdma_dev->axil_ctl, RN_RDMA_GCSR_LSTINPKT));
  fprintf(stderr, "Info: [RN_RDMA_GCSR_LSTOUTPKT       = 0x%x] = 0x%x\n", RN_RDMA_GCSR_LSTOUTPKT      ,read32_data(rdma_dev->axil_ctl, RN_RDMA_GCSR_LSTOUTPKT));
  fprintf(stderr, "Info: [RN_RDMA_GCSR_ININVDUPCNT     = 0x%x] = 0x%x\n", RN_RDMA_GCSR_ININVDUPCNT    ,read32_data(rdma_dev->axil_ctl, RN_RDMA_GCSR_ININVDUPCNT));
  fprintf(stderr, "Info: [RN_RDMA_GCSR_INNCKPKTSTS     = 0x%x] = 0x%x\n", RN_RDMA_GCSR_INNCKPKTSTS    ,read32_data(rdma_dev->axil_ctl, RN_RDMA_GCSR_INNCKPKTSTS));
  fprintf(stderr, "Info: [RN_RDMA_GCSR_OUTRNRPKTSTS    = 0x%x] = 0x%x\n", RN_RDMA_GCSR_OUTRNRPKTSTS   ,read32_data(rdma_dev->axil_ctl, RN_RDMA_GCSR_OUTRNRPKTSTS));
  fprintf(stderr, "Info: [RN_RDMA_GCSR_WQEPROCSTS      = 0x%x] = 0x%x\n", RN_RDMA_GCSR_WQEPROCSTS     ,read32_data(rdma_dev->axil_ctl, RN_RDMA_GCSR_WQEPROCSTS));
  fprintf(stderr, "Info: [RN_RDMA_GCSR_QPMSTS          = 0x%x] = 0x%x\n", RN_RDMA_GCSR_QPMSTS         ,read32_data(rdma_dev->axil_ctl, RN_RDMA_GCSR_QPMSTS));
  fprintf(stderr, "Info: [RN_RDMA_GCSR_INALLDRPPKTCNT  = 0x%x] = 0x%x\n", RN_RDMA_GCSR_INALLDRPPKTCNT ,read32_data(rdma_dev->axil_ctl, RN_RDMA_GCSR_INALLDRPPKTCNT));
  fprintf(stderr, "Info: [RN_RDMA_GCSR_INNAKPKTCNT     = 0x%x] = 0x%x\n", RN_RDMA_GCSR_INNAKPKTCNT    ,read32_data(rdma_dev->axil_ctl, RN_RDMA_GCSR_INNAKPKTCNT));
  fprintf(stderr, "Info: [RN_RDMA_GCSR_OUTNAKPKTCNT    = 0x%x] = 0x%x\n", RN_RDMA_GCSR_OUTNAKPKTCNT   ,read32_data(rdma_dev->axil_ctl, RN_RDMA_GCSR_OUTNAKPKTCNT));
  fprintf(stderr, "Info: [RN_RDMA_GCSR_RESPHNDSTS      = 0x%x] = 0x%x\n", RN_RDMA_GCSR_RESPHNDSTS     ,read32_data(rdma_dev->axil_ctl, RN_RDMA_GCSR_RESPHNDSTS));
  fprintf(stderr, "Info: [RN_RDMA_GCSR_RETRYCNTSTS     = 0x%x] = 0x%x\n", RN_RDMA_GCSR_RETRYCNTSTS    ,read32_data(rdma_dev->axil_ctl, RN_RDMA_GCSR_RETRYCNTSTS));
  fprintf(stderr, "Info: [RN_RDMA_GCSR_INCNPPKTCNT     = 0x%x] = 0x%x\n", RN_RDMA_GCSR_INCNPPKTCNT    ,read32_data(rdma_dev->axil_ctl, RN_RDMA_GCSR_INCNPPKTCNT));
  fprintf(stderr, "Info: [RN_RDMA_GCSR_OUTCNPPKTCNT    = 0x%x] = 0x%x\n", RN_RDMA_GCSR_OUTCNPPKTCNT   ,read32_data(rdma_dev->axil_ctl, RN_RDMA_GCSR_OUTCNPPKTCNT));
  fprintf(stderr, "Info: [RN_RDMA_GCSR_OUTRDRSPPKTCNT  = 0x%x] = 0x%x\n", RN_RDMA_GCSR_OUTRDRSPPKTCNT ,read32_data(rdma_dev->axil_ctl, RN_RDMA_GCSR_OUTRDRSPPKTCNT));
  fprintf(stderr, "Info: [RN_RDMA_GCSR_INTSTS          = 0x%x] = 0x%x\n", RN_RDMA_GCSR_INTSTS         ,read32_data(rdma_dev->axil_ctl, RN_RDMA_GCSR_INTSTS));
  fprintf(stderr, "Info: [RN_RDMA_GCSR_RQINTSTS1       = 0x%x] = 0x%x\n", RN_RDMA_GCSR_RQINTSTS1      ,read32_data(rdma_dev->axil_ctl, RN_RDMA_GCSR_RQINTSTS1));
  fprintf(stderr, "Info: [RN_RDMA_GCSR_RQINTSTS2       = 0x%x] = 0x%x\n", RN_RDMA_GCSR_RQINTSTS2      ,read32_data(rdma_dev->axil_ctl, RN_RDMA_GCSR_RQINTSTS2));
  fprintf(stderr, "Info: [RN_RDMA_GCSR_RQINTSTS3       = 0x%x] = 0x%x\n", RN_RDMA_GCSR_RQINTSTS3      ,read32_data(rdma_dev->axil_ctl, RN_RDMA_GCSR_RQINTSTS3));
  fprintf(stderr, "Info: [RN_RDMA_GCSR_RQINTSTS4       = 0x%x] = 0x%x\n", RN_RDMA_GCSR_RQINTSTS4      ,read32_data(rdma_dev->axil_ctl, RN_RDMA_GCSR_RQINTSTS4));
  fprintf(stderr, "Info: [RN_RDMA_GCSR_RQINTSTS5       = 0x%x] = 0x%x\n", RN_RDMA_GCSR_RQINTSTS5      ,read32_data(rdma_dev->axil_ctl, RN_RDMA_GCSR_RQINTSTS5));
  fprintf(stderr, "Info: [RN_RDMA_GCSR_RQINTSTS6       = 0x%x] = 0x%x\n", RN_RDMA_GCSR_RQINTSTS6      ,read32_data(rdma_dev->axil_ctl, RN_RDMA_GCSR_RQINTSTS6));
  fprintf(stderr, "Info: [RN_RDMA_GCSR_RQINTSTS7       = 0x%x] = 0x%x\n", RN_RDMA_GCSR_RQINTSTS7      ,read32_data(rdma_dev->axil_ctl, RN_RDMA_GCSR_RQINTSTS7));
  fprintf(stderr, "Info: [RN_RDMA_GCSR_RQINTSTS8       = 0x%x] = 0x%x\n", RN_RDMA_GCSR_RQINTSTS8      ,read32_data(rdma_dev->axil_ctl, RN_RDMA_GCSR_RQINTSTS8));
  fprintf(stderr, "Info: [RN_RDMA_GCSR_CQINTSTS1       = 0x%x] = 0x%x\n", RN_RDMA_GCSR_CQINTSTS1      ,read32_data(rdma_dev->axil_ctl, RN_RDMA_GCSR_CQINTSTS1));
  fprintf(stderr, "Info: [RN_RDMA_GCSR_CQINTSTS2       = 0x%x] = 0x%x\n", RN_RDMA_GCSR_CQINTSTS2      ,read32_data(rdma_dev->axil_ctl, RN_RDMA_GCSR_CQINTSTS2));
  fprintf(stderr, "Info: [RN_RDMA_GCSR_CQINTSTS3       = 0x%x] = 0x%x\n", RN_RDMA_GCSR_CQINTSTS3      ,read32_data(rdma_dev->axil_ctl, RN_RDMA_GCSR_CQINTSTS3));
  fprintf(stderr, "Info: [RN_RDMA_GCSR_CQINTSTS4       = 0x%x] = 0x%x\n", RN_RDMA_GCSR_CQINTSTS4      ,read32_data(rdma_dev->axil_ctl, RN_RDMA_GCSR_CQINTSTS4));
  fprintf(stderr, "Info: [RN_RDMA_GCSR_CQINTSTS5       = 0x%x] = 0x%x\n", RN_RDMA_GCSR_CQINTSTS5      ,read32_data(rdma_dev->axil_ctl, RN_RDMA_GCSR_CQINTSTS5));
  fprintf(stderr, "Info: [RN_RDMA_GCSR_CQINTSTS6       = 0x%x] = 0x%x\n", RN_RDMA_GCSR_CQINTSTS6      ,read32_data(rdma_dev->axil_ctl, RN_RDMA_GCSR_CQINTSTS6));
  fprintf(stderr, "Info: [RN_RDMA_GCSR_CQINTSTS7       = 0x%x] = 0x%x\n", RN_RDMA_GCSR_CQINTSTS7      ,read32_data(rdma_dev->axil_ctl, RN_RDMA_GCSR_CQINTSTS7));
  fprintf(stderr, "Info: [RN_RDMA_GCSR_CQINTSTS8       = 0x%x] = 0x%x\n", RN_RDMA_GCSR_CQINTSTS8      ,read32_data(rdma_dev->axil_ctl, RN_RDMA_GCSR_CQINTSTS8));
  fprintf(stderr, "Info: [RN_RDMA_QCSR_CQHEADi         = 0x%x] = 0x%x\n", get_rdma_per_q_config_addr(RN_RDMA_QCSR_CQHEADi, qpid), read32_data(rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_CQHEADi, qpid)));
  fprintf(stderr, "Info: [RN_RDMA_QCSR_STATSSNi        = 0x%x] = 0x%x\n", get_rdma_per_q_config_addr(RN_RDMA_QCSR_STATSSNi, qpid), read32_data(rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_STATSSNi, qpid)));
  fprintf(stderr, "Info: [RN_RDMA_QCSR_STATMSNi        = 0x%x] = 0x%x\n", get_rdma_per_q_config_addr(RN_RDMA_QCSR_STATMSNi, qpid), read32_data(rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_STATMSNi, qpid)));
  fprintf(stderr, "Info: [RN_RDMA_QCSR_STATQPi         = 0x%x] = 0x%x\n", get_rdma_per_q_config_addr(RN_RDMA_QCSR_STATQPi, qpid), read32_data(rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_STATQPi, qpid)));
  fprintf(stderr, "Info: [RN_RDMA_QCSR_STATCURSQPTRi   = 0x%x] = 0x%x\n", get_rdma_per_q_config_addr(RN_RDMA_QCSR_STATCURSQPTRi, qpid), read32_data(rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_STATCURSQPTRi, qpid)));
  fprintf(stderr, "Info: [RN_RDMA_QCSR_STATRESPSNi     = 0x%x] = 0x%x\n", get_rdma_per_q_config_addr(RN_RDMA_QCSR_STATRESPSNi, qpid), read32_data(rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_STATRESPSNi, qpid)));
  fprintf(stderr, "Info: [RN_RDMA_QCSR_STATRQBUFCAi    = 0x%x] = 0x%x\n", get_rdma_per_q_config_addr(RN_RDMA_QCSR_STATRQBUFCAi, qpid), read32_data(rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_STATRQBUFCAi, qpid)));
  fprintf(stderr, "Info: [RN_RDMA_QCSR_STATWQEi        = 0x%x] = 0x%x\n", get_rdma_per_q_config_addr(RN_RDMA_QCSR_STATWQEi, qpid), read32_data(rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_STATWQEi, qpid)));
  fprintf(stderr, "Info: [RN_RDMA_QCSR_STATRQPIDBi     = 0x%x] = 0x%x\n", get_rdma_per_q_config_addr(RN_RDMA_QCSR_STATRQPIDBi, qpid), read32_data(rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_STATRQPIDBi, qpid)));
  fprintf(stderr, "Info: [RN_RDMA_QCSR_STATRQBUFCAMSBi = 0x%x] = 0x%x\n", get_rdma_per_q_config_addr(RN_RDMA_QCSR_STATRQBUFCAMSBi, qpid), read32_data(rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_STATRQBUFCAMSBi, qpid)));

  if(is_sender) {
    fprintf(stderr, "Info: [RN_RDMA_QCSR_SQPIi           = 0x%x] = 0x%x\n", get_rdma_per_q_config_addr(RN_RDMA_QCSR_SQPIi, qpid), read32_data(rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_SQPIi, qpid)));
  }
  fprintf(stderr, "\n");

}

struct rdma_pd_t* allocate_rdma_pd(struct rn_dev_t* rn_dev, uint32_t pd_num, uint32_t r_key) {
  struct rdma_pd_t* rdma_pd = NULL;

  if(rn_dev != NULL) {
    rdma_pd = (struct rdma_pd_t* ) malloc(sizeof(struct rdma_pd_t));
    rdma_pd->pd_num = pd_num;
    rdma_pd->pd_access_type = 2 & 0x0000ffff;
    write32_data(rn_dev->axil_ctl, get_rdma_pd_config_addr(RN_RDMA_PDT_PDPDNUM, pd_num), pd_num);
    fprintf(stderr, "[Register] RN_RDMA_PDT_PDPDNUM=0x%x, pd_num=%d, value=0x%x\n", get_rdma_pd_config_addr(RN_RDMA_PDT_PDPDNUM, pd_num), pd_num, pd_num);

    //rdma_pd->mr_buffer = (struct rdma_buff_t*) malloc(sizeof(struct rdma_buff_t));
    rdma_pd->mr_buffer = NULL;
  }else{
    fprintf(stderr, "Error: rn_dev is empty\n");
    exit(EXIT_FAILURE);
  }

  return rdma_pd;
}

struct rdma_buff_t* allocate_rdma_buffer(struct rn_dev_t* rn_dev, uint64_t buf_size) {
  struct rdma_buff_t* rdma_buffer;
  rdma_buffer = (struct rdma_buff_t*) malloc(sizeof(struct rdma_buff_t));

  if(rdma_buffer == NULL) {
    fprintf(stderr, "Error: failed to create rdma_buffer\n");
    exit(EXIT_FAILURE);
  }

  rdma_buffer->buffer = rn_dev->base_buf->buffer + rn_dev->buffer_offset;
  rn_dev->buffer_offset += buf_size;
  
  // Get the physical address of the buffer
  rdma_buffer->dma_addr = get_buffer_paddr(rdma_buffer->buffer);
  fprintf(stderr, "Info: allocated buffer vir addr = %p, physical addr = %lx, rn_dev->buffer_offset = 0x%lx\n", rdma_buffer->buffer, rdma_buffer->dma_addr, rn_dev->buffer_offset);
  fprintf(stderr, "Info: allocate_rdma_buffer - successfully allocated rdma buffer\n");
  return rdma_buffer;
}

struct rdma_buff_t* allocate_hugepages_buffer(uint32_t num_hugepages) {
  struct rdma_buff_t* rdma_buffer;
  rdma_buffer = (struct rdma_buff_t*) malloc(sizeof(struct rdma_buff_t));

  if(rdma_buffer == NULL) {
    fprintf(stderr, "Error: failed to create rdma_buffer\n");
    exit(EXIT_FAILURE);
  }

  rdma_buffer->buffer = mmap(NULL, num_hugepages * (1 << HUGE_PAGE_SHIFT),
                             PROT_READ | PROT_WRITE, MAP_SHARED | MAP_ANONYMOUS | 
                             MAP_HUGETLB, -1, 0);

  if(rdma_buffer->buffer == NULL) {
    fprintf(stderr, "Error: failed to allocate hugepage memory\n");
    exit(EXIT_FAILURE);
  }

  // Lock the buffer in physical memory
  if(mlock(rdma_buffer->buffer, num_hugepages * (1 << HUGE_PAGE_SHIFT)) == -1) {
    fprintf(stderr, "Error: failed to lock %d page in memory\n", num_hugepages);
    exit(EXIT_FAILURE);
  }

  rdma_buffer->dma_addr = get_buffer_paddr(rdma_buffer->buffer);

  return rdma_buffer;
}

struct rdma_buff_t* rdma_register_memory_region(struct rn_dev_t* rn_dev, struct rdma_pd_t* rdma_pd, uint32_t r_key, uint32_t num_hugepages, uint64_t dev_buf_offset, uint64_t dev_buf_size) {
  uint32_t pd_num;
  uint64_t buffer_size;
  uint32_t access_config;

  fprintf(stderr, "Info: rdma_register_memory_region - registering memory region\n");
  if(rn_dev->rdma_dev == NULL) {
    fprintf(stderr, "Error: rdma_dev is NULL\n");
    exit(EXIT_FAILURE);    
  }

  if(rdma_pd == NULL) {
    fprintf(stderr, "Error: rdma_pd is NULL\n");
    exit(EXIT_FAILURE);
  }

  if(dev_buf_size == 0) {
    fprintf(stderr, "Info: rdma_register_memory_region - allocate rdma buffer\n");
    rdma_pd->mr_buffer = allocate_hugepages_buffer(num_hugepages);
    buffer_size = ((uint64_t) num_hugepages) * ((uint64_t) 1 << HUGE_PAGE_SHIFT);
    rdma_pd->dma_addr_lsb = (uint32_t) (rdma_pd->mr_buffer->dma_addr & 0x00000000ffffffff & win_size_low);
    rdma_pd->dma_addr_msb = (uint32_t) ((rdma_pd->mr_buffer->dma_addr >> 32) & 0x00000000ffffffff & win_size_high);
  } else {
    // no virtual address for the device memory
    fprintf(stderr, "Info: rdma_register_memory_region - allocate device buffer\n");
    rdma_pd->mr_buffer = (struct rdma_buff_t* ) malloc(sizeof(struct rdma_buff_t));
    //rdma_pd->mr_buffer->buffer = (void* ) dev_buf_offset;
    //rdma_pd->mr_buffer->dma_addr = dev_buf_offset;
    rdma_pd->mr_buffer->buffer = (void* ) 0;
    rdma_pd->mr_buffer->dma_addr = (uint64_t) dev_buf_offset;
    buffer_size = dev_buf_size;
    rdma_pd->dma_addr_lsb = (uint32_t) (rdma_pd->mr_buffer->dma_addr & 0x00000000ffffffff);
    rdma_pd->dma_addr_msb = (uint32_t) ((rdma_pd->mr_buffer->dma_addr >> 32) & 0x00000000ffffffff);
  }

  if(rdma_pd->mr_buffer == NULL) {
    fprintf(stderr, "Error: rdma_pd->mr_buffer is NULL\n");
    exit(EXIT_FAILURE);
  }

  // Configure protection domain entry
  pd_num = rdma_pd->pd_num;
  rdma_pd->virtual_addr_lsb = (uint32_t)(((uint64_t) rdma_pd->mr_buffer->buffer) & 0x00000000ffffffff);
  rdma_pd->virtual_addr_msb = (uint32_t)((((uint64_t) rdma_pd->mr_buffer->buffer)>>32) & 0x00000000ffffffff);
  rdma_pd->buffer_size_lsb = (uint32_t) (buffer_size & 0x00000000ffffffff);
  rdma_pd->buffer_size_msb = (uint32_t) ((buffer_size>>32) & 0x00000000ffffffff);
  rdma_pd->r_key = r_key;

  if(rn_dev->axil_ctl == 0) {
    fprintf(stderr, "Error: rdma_dev->axil_ctl=0x%lx is not valid!\n", (uint64_t) rn_dev->axil_ctl);
    exit(EXIT_FAILURE);
  }

  // Register 1GB memory region
  write32_data(rn_dev->axil_ctl, get_rdma_pd_config_addr(RN_RDMA_PDT_VIRTADDRLSB, pd_num), rdma_pd->virtual_addr_lsb);
  fprintf(stderr, "[Register] RN_RDMA_PDT_VIRTADDRLSB=0x%x, pd_num=%d, value=0x%x\n", get_rdma_pd_config_addr(RN_RDMA_PDT_VIRTADDRLSB, pd_num), pd_num, rdma_pd->virtual_addr_lsb);
  write32_data(rn_dev->axil_ctl, get_rdma_pd_config_addr(RN_RDMA_PDT_VIRTADDRMSB, pd_num), rdma_pd->virtual_addr_msb);
  fprintf(stderr, "[Register] RN_RDMA_PDT_VIRTADDRMSB=0x%x, pd_num=%d, value=0x%x\n", get_rdma_pd_config_addr(RN_RDMA_PDT_VIRTADDRMSB, pd_num), pd_num, rdma_pd->virtual_addr_msb);
  write32_data(rn_dev->axil_ctl, get_rdma_pd_config_addr(RN_RDMA_PDT_BUFBASEADDRLSB, pd_num), rdma_pd->dma_addr_lsb);
  fprintf(stderr, "[Register] RN_RDMA_PDT_BUFBASEADDRLSB=0x%x, pd_num=%d, value=0x%x\n", get_rdma_pd_config_addr(RN_RDMA_PDT_BUFBASEADDRLSB, pd_num), pd_num, rdma_pd->dma_addr_lsb);
  write32_data(rn_dev->axil_ctl, get_rdma_pd_config_addr(RN_RDMA_PDT_BUFBASEADDRMSB, pd_num), rdma_pd->dma_addr_msb);
  fprintf(stderr, "[Register] RN_RDMA_PDT_BUFBASEADDRMSB=0x%x, pd_num=%d, value=0x%x\n", get_rdma_pd_config_addr(RN_RDMA_PDT_BUFBASEADDRMSB, pd_num), pd_num, rdma_pd->dma_addr_msb);
  write32_data(rn_dev->axil_ctl, get_rdma_pd_config_addr(RN_RDMA_PDT_BUFRKEY, pd_num), r_key);
  fprintf(stderr, "[Register] RN_RDMA_PDT_BUFRKEY=0x%x, pd_num=%d, value=0x%x\n", get_rdma_pd_config_addr(RN_RDMA_PDT_BUFRKEY, pd_num), pd_num, r_key);

  write32_data(rn_dev->axil_ctl, get_rdma_pd_config_addr(RN_RDMA_PDT_WRRDBUFLEN, pd_num), buffer_size);
  fprintf(stderr, "[Register] RN_RDMA_PDT_WRRDBUFLEN=0x%x, pd_num=%d, value=0x%lx B\n", get_rdma_pd_config_addr(RN_RDMA_PDT_WRRDBUFLEN, pd_num), pd_num, buffer_size);
  access_config = ((rdma_pd->buffer_size_msb<<16) | rdma_pd->pd_access_type);
  write32_data(rn_dev->axil_ctl, get_rdma_pd_config_addr(RN_RDMA_PDT_ACCESSDESC, pd_num), access_config);
  fprintf(stderr, "[Register] RN_RDMA_PDT_ACCESSDESC=0x%x, pd_num=%d, value=0x%x\n", get_rdma_pd_config_addr(RN_RDMA_PDT_ACCESSDESC, pd_num), pd_num, access_config);

  fprintf(stderr, "Info: memory region is registered\n");

  return rdma_pd->mr_buffer;
}

struct rdma_buff_t* allocate_rn_memory(struct rn_dev_t* rn_dev, uint32_t num_hugepages, uint64_t dev_buf_offset, uint64_t dev_buf_size) {
  uint64_t buffer_size;
  uint32_t hugepage_size;
  struct rdma_buff_t* tmp_buffer;

  hugepage_size = (1 << HUGE_PAGE_SHIFT);

  fprintf(stderr, "Info: allocate_rn_memory - allocating memory from registerred memory region\n");
  if(rn_dev == NULL) {
    fprintf(stderr, "Error: rn_dev is NULL\n");
    exit(EXIT_FAILURE);    
  }

  if(dev_buf_size == 0) {
    fprintf(stderr, "Info: allocate_rn_memory - allocate rdma buffer\n");
    tmp_buffer = allocate_rdma_buffer(rn_dev, (uint64_t) hugepage_size);
  } else {
    // no virtual address for the device memory
    fprintf(stderr, "Info: allocate_rn_memory - allocate device buffer\n");
    tmp_buffer = (struct rdma_buff_t* ) malloc(sizeof(struct rdma_buff_t));
    //rdma_pd->mr_buffer->buffer = (void* ) dev_buf_offset;
    //rdma_pd->mr_buffer->dma_addr = dev_buf_offset;
    tmp_buffer->buffer = (void* ) 0;
    tmp_buffer->dma_addr = (uint64_t) 0;
  }

  fprintf(stderr, "Info: memory is allocated from the registered region!\n");

  return tmp_buffer;
}

struct rdma_qp_t* allocate_rdma_qp(struct rn_dev_t* rn_dev, uint32_t qpid, uint32_t pd_num, uint32_t sq_psn, struct rdma_pd_t* pd_entry, uint64_t cq_cidb_addr, uint64_t rq_cidb_addr, uint32_t dst_qpid, uint32_t qdepth, struct mac_addr_t* dst_mac, uint32_t dst_ip, uint32_t partion_key, uint8_t is_remote) {
  uint32_t sq_addr_lsb;
  uint32_t sq_addr_msb;
  uint32_t cq_addr_lsb;
  uint32_t cq_addr_msb;
  uint32_t rq_addr_lsb;
  uint32_t rq_addr_msb;
  uint32_t cq_cidb_addr_lsb;
  uint32_t cq_cidb_addr_msb;
  uint32_t rq_cidb_addr_lsb;
  uint32_t rq_cidb_addr_msb;
  struct rdma_dev_t* rdma_dev;
  struct rdma_qp_t* qp;
  uint32_t mtu_config;
  uint32_t en_qp;
  //uint32_t ip_proto;
  uint32_t qp_config;
  uint32_t traffic_class;
  uint32_t time_to_live;
  uint32_t qp_adv_conf;
  uint32_t rq_buffer_entry_size;
  uint32_t hugepage_size;
  uint32_t last_rq_psn;
  uint32_t last_rq_opcode = 0x0000000a; // To avoid opcode sequence error
  uint32_t last_rq_conf;
  rdma_dev = rn_dev->rdma_dev;

  hugepage_size = (1 << HUGE_PAGE_SHIFT);

  qp = (struct rdma_qp_t* ) malloc(sizeof(struct rdma_qp_t));
  qp->rdma_dev = rn_dev->rdma_dev;
  qp->qpid = qpid;
  fprintf(stderr, "DEBUG: Allocating qp->sq\n");
  qp->sq = allocate_rdma_buffer(rn_dev, (uint64_t) hugepage_size);
  qp->sq_pidb = 0;
  qp->sq_cidb = 0;
  qp->sq_psn  = sq_psn;
  fprintf(stderr, "DEBUG: Allocating qp->cq\n");
  qp->cq = allocate_rdma_buffer(rn_dev, (uint64_t) hugepage_size);
  qp->cq_cidb = 0;
  qp->cq_cidb_addr = cq_cidb_addr;
  fprintf(stderr, "DEBUG: Allocating qp->rq\n");
  qp->rq = allocate_rdma_buffer(rn_dev, (uint64_t) hugepage_size);
  qp->rq_cidb = 0;
  qp->rq_pidb = 0;
  qp->rq_cidb_addr = rq_cidb_addr;
  qp->pd_num = pd_num;
  qp->pd_entry = pd_entry;
  qp->dst_qpid = dst_qpid;
  qp->qdepth   = qdepth;
  qp->dst_mac = dst_mac;
  qp->dst_ip  = dst_ip;
  rdma_dev->qps_ptr[qpid] = qp;

  fprintf(stderr, "Info: queue pair setting is done! Configuring RDMA per-queu CSR registers\n");
  fprintf(stderr, "Info: rn_dev->axil_ctl = 0x%lx, rdma_dev->axil_ctl = 0x%lx\n", (uint64_t) rn_dev->axil_ctl, (uint64_t) rdma_dev->axil_ctl);

  if(rdma_dev->axil_ctl == 0) {
    fprintf(stderr, "Error: rdma_dev->axil_ctl=0x%lx is not valid!\n", (uint64_t) rdma_dev->axil_ctl);
    exit(EXIT_FAILURE);
  }

  // Configure RDMA per-queue CSR registers
  write32_data(rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_IPDESADDR1i, qpid), dst_ip);
  fprintf(stderr, "[Register] RN_RDMA_QCSR_IPDESADDR1i=0x%x, qpid=%d, value=0x%x\n", get_rdma_per_q_config_addr(RN_RDMA_QCSR_IPDESADDR1i, qpid), qpid, dst_ip);
  write32_data(rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_MACDESADDLSBi, qpid), dst_mac->mac_lsb);
  fprintf(stderr, "[Register] RN_RDMA_QCSR_MACDESADDLSBi=0x%x, qpid=%d, value=0x%x\n", get_rdma_per_q_config_addr(RN_RDMA_QCSR_MACDESADDLSBi, qpid), qpid, dst_mac->mac_lsb);
  write32_data(rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_MACDESADDMSBi, qpid), dst_mac->mac_msb);
  fprintf(stderr, "[Register] RN_RDMA_QCSR_MACDESADDMSBi=0x%x, qpid=%d, value=0x%x\n", get_rdma_per_q_config_addr(RN_RDMA_QCSR_MACDESADDMSBi, qpid), qpid, dst_mac->mac_msb);
  
  // Mask the physical address of sq, rq and cq
  fprintf(stderr, "DEBUG: win_size_high = 0x%x, win_size_low = 0x%x\n", win_size_high, win_size_low);
  sq_addr_lsb = ((uint32_t) ((qp->sq->dma_addr) & 0x00000000ffffffff)) & win_size_low;
  sq_addr_msb = ((uint32_t) ((qp->sq->dma_addr >> 32) & 0x00000000ffffffff)) & win_size_high;
  write32_data(rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_SQBAi, qpid),  sq_addr_lsb);
  fprintf(stderr, "[Register] RN_RDMA_QCSR_SQBAi=0x%x, qpid=%d, value=0x%x\n", get_rdma_per_q_config_addr(RN_RDMA_QCSR_SQBAi, qpid), qpid, sq_addr_lsb);
  write32_data(rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_SQBAMSBi, qpid), sq_addr_msb);
  fprintf(stderr, "[Register] RN_RDMA_QCSR_SQBAMSBi=0x%x, qpid=%d, value=0x%x\n", get_rdma_per_q_config_addr(RN_RDMA_QCSR_SQBAMSBi, qpid), qpid, sq_addr_msb);
  fprintf(stderr, "DEBUG: qp->sq->dma_addr = 0x%lx, sq_addr_msb = 0x%x, sq_addr_lsb = 0x%x\n", qp->sq->dma_addr, sq_addr_msb, sq_addr_lsb);
  fprintf(stderr, "DEBUG: RN_RDMA_QCSR_SQBAi(0x%x) = 0x%x\n", get_rdma_per_q_config_addr(RN_RDMA_QCSR_SQBAi, qpid), sq_addr_lsb);
  fprintf(stderr, "DEBUG: RN_RDMA_QCSR_SQBAMSBi(0x%x) = 0x%x\n", get_rdma_per_q_config_addr(RN_RDMA_QCSR_SQBAMSBi, qpid), sq_addr_msb);

  cq_addr_lsb = ((uint32_t) ((qp->cq->dma_addr) & 0x00000000ffffffff)) & win_size_low;
  cq_addr_msb = ((uint32_t) ((qp->cq->dma_addr >> 32) & 0x00000000ffffffff)) & win_size_high;
  write32_data(rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_CQBAi, qpid),  cq_addr_lsb);
  fprintf(stderr, "[Register] RN_RDMA_QCSR_CQBAi=0x%x, qpid=%d, value=0x%x\n", get_rdma_per_q_config_addr(RN_RDMA_QCSR_CQBAi, qpid), qpid, cq_addr_lsb);
  write32_data(rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_CQBAMSBi, qpid), cq_addr_msb);
  fprintf(stderr, "[Register] RN_RDMA_QCSR_CQBAMSBi=0x%x, qpid=%d, value=0x%x\n", get_rdma_per_q_config_addr(RN_RDMA_QCSR_CQBAMSBi, qpid), qpid, cq_addr_msb);
  fprintf(stderr, "DEBUG: qp->cq->dma_addr = 0x%lx, cq_addr_msb = 0x%x, cq_addr_lsb = 0x%x\n", qp->cq->dma_addr, cq_addr_msb, cq_addr_lsb);
  fprintf(stderr, "DEBUG: RN_RDMA_QCSR_CQBAi(0x%x) = 0x%x\n", get_rdma_per_q_config_addr(RN_RDMA_QCSR_CQBAi, qpid), cq_addr_lsb);
  fprintf(stderr, "DEBUG: RN_RDMA_QCSR_CQBAMSBi(0x%x) = 0x%x\n", get_rdma_per_q_config_addr(RN_RDMA_QCSR_CQBAMSBi, qpid), cq_addr_msb);

  rq_addr_lsb = ((uint32_t) ((qp->rq->dma_addr) & 0x00000000ffffffff)) & win_size_low;
  rq_addr_msb = ((uint32_t) ((qp->rq->dma_addr >> 32) & 0x00000000ffffffff)) & win_size_high;
  write32_data(rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_RQBAi, qpid),  rq_addr_lsb);
  fprintf(stderr, "[Register] RN_RDMA_QCSR_RQBAi=0x%x, qpid=%d, value=0x%x\n", get_rdma_per_q_config_addr(RN_RDMA_QCSR_RQBAi, qpid), qpid, rq_addr_lsb);
  write32_data(rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_RQBAMSBi, qpid), rq_addr_msb);
  fprintf(stderr, "[Register] RN_RDMA_QCSR_RQBAMSBi=0x%x, qpid=%d, value=0x%x\n", get_rdma_per_q_config_addr(RN_RDMA_QCSR_RQBAMSBi, qpid), qpid, rq_addr_msb);
  fprintf(stderr, "DEBUG: qp->rq->dma_addr = 0x%lx, rq_addr_msb = 0x%x, rq_addr_lsb = 0x%x\n", qp->rq->dma_addr, rq_addr_msb, rq_addr_lsb);
  fprintf(stderr, "DEBUG: RN_RDMA_QCSR_RQBAi(0x%x) = 0x%x\n", get_rdma_per_q_config_addr(RN_RDMA_QCSR_RQBAi, qpid), rq_addr_lsb);
  fprintf(stderr, "DEBUG: RN_RDMA_QCSR_RQBAMSBi(0x%x) = 0x%x\n", get_rdma_per_q_config_addr(RN_RDMA_QCSR_RQBAMSBi, qpid), rq_addr_msb);  

  // CQ DB address
  cq_cidb_addr_lsb = (uint32_t) (cq_cidb_addr & 0x00000000ffffffff);
  cq_cidb_addr_msb = (uint32_t) ((cq_cidb_addr>>32) & 0x00000000ffffffff);
  write32_data(rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_CQDBADDi, qpid), cq_cidb_addr_lsb);
  fprintf(stderr, "[Register] RN_RDMA_QCSR_CQDBADDi=0x%x, qpid=%d, value=0x%x\n", get_rdma_per_q_config_addr(RN_RDMA_QCSR_CQDBADDi, qpid), qpid, cq_cidb_addr_lsb);
  write32_data(rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_CQDBADDMSBi, qpid), cq_cidb_addr_msb);
  fprintf(stderr, "[Register] RN_RDMA_QCSR_CQDBADDMSBi=0x%x, qpid=%d, value=0x%x\n", get_rdma_per_q_config_addr(RN_RDMA_QCSR_CQDBADDMSBi, qpid), qpid, cq_cidb_addr_msb);
  fprintf(stderr, "DEBUG: cq_cidb_addr = 0x%lx\n", cq_cidb_addr);
  fprintf(stderr, "DEBUG: RN_RDMA_QCSR_CQDBADDi(0x%x) = 0x%x\n", get_rdma_per_q_config_addr(RN_RDMA_QCSR_CQDBADDi, qpid), cq_cidb_addr_lsb);
  fprintf(stderr, "DEBUG: RN_RDMA_QCSR_CQDBADDMSBi(0x%x) = 0x%x\n", get_rdma_per_q_config_addr(RN_RDMA_QCSR_CQDBADDMSBi, qpid), cq_cidb_addr_msb); 

  // RQ DB address
  rq_cidb_addr_lsb = (uint32_t) (rq_cidb_addr & 0x00000000ffffffff);
  rq_cidb_addr_msb = (uint32_t) ((rq_cidb_addr>>32) & 0x00000000ffffffff);
  write32_data(rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_RQWPTRDBADDi, qpid), rq_cidb_addr_lsb);
  fprintf(stderr, "[Register] RN_RDMA_QCSR_RQWPTRDBADDi=0x%x, qpid=%d, value=0x%x\n", get_rdma_per_q_config_addr(RN_RDMA_QCSR_RQWPTRDBADDi, qpid), qpid, rq_cidb_addr_lsb);
  write32_data(rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_RQWPTRDBADDMSBi, qpid), rq_cidb_addr_msb);
  fprintf(stderr, "[Register] RN_RDMA_QCSR_RQWPTRDBADDMSBi=0x%x, qpid=%d, value=0x%x\n", get_rdma_per_q_config_addr(RN_RDMA_QCSR_RQWPTRDBADDMSBi, qpid), qpid, rq_cidb_addr_msb);
  fprintf(stderr, "DEBUG: rq_cidb_addr = 0x%lx\n", rq_cidb_addr);
  fprintf(stderr, "DEBUG: RN_RDMA_QCSR_RQWPTRDBADDi(0x%x) = 0x%x\n", get_rdma_per_q_config_addr(RN_RDMA_QCSR_RQWPTRDBADDi, qpid), rq_cidb_addr_lsb);
  fprintf(stderr, "DEBUG: RN_RDMA_QCSR_RQWPTRDBADDMSBi(0x%x) = 0x%x\n", get_rdma_per_q_config_addr(RN_RDMA_QCSR_RQWPTRDBADDMSBi, qpid), rq_cidb_addr_msb); 

  // Destination QP configuration
  write32_data(rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_DESTQPCONFi, qpid), dst_qpid);
  fprintf(stderr, "[Register] RN_RDMA_QCSR_DESTQPCONFi=0x%x, qpid=%d, value=0x%x\n", get_rdma_per_q_config_addr(RN_RDMA_QCSR_DESTQPCONFi, qpid), qpid, dst_qpid);

  // Queue depth configuration
  write32_data(rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_QDEPTHi, qpid), qdepth);
  fprintf(stderr, "[Register] RN_RDMA_QCSR_QDEPTHi=0x%x, qpid=%d, value=0x%x\n", get_rdma_per_q_config_addr(RN_RDMA_QCSR_QDEPTHi, qpid), qpid, qdepth);

  // Queue pair control configuration
  // [0]: QP enable – Should be set to 1 for all active QPs. A disabled QP will not be 
  //      able to receive or transmit packets.
	// [2]: RQ interrupt enable – When enabled, allows the receive queue interrupt to be 
  //      generated for every new packet received on the receive queue
	// [3]: CQ interrupt enable – When enabled, allows the completion queue interrupt to 
  //      be generated for every send work queue entry completion
	// [4]: HW Handshake disable – This bit when reset to 0 enables the HW handshake ports 
  //      for doorbell exchange. If set, all doorbell values are exchanged through writes 
  //      through the AXI4 or AXI4-Lite interface.
	// [5]: CQE write enable – This bit when set, enables completion queue entry writes. 
  //      The writes are disabled when this bit is reset. CQE writes can be enabled to 
  //      debug failed completions.
	// [6]: QP under recovery. This bit need to be set in the fatal clearing process.
	// [7]: QP configured for IPv4 or IPv6
	//      0 - IPv4
	//      1 - IPv6 - not supported in this simulation
	// [10:8]: Path MTU
  //      000 – 256B 
  //      001 – 512B
  //      010 – 1024B
  //      011 – 2048B
  //      100 - 4096B (default)
  //      101 to 111 - Reserved
  // [31:16]: RQ Buffer size (in multiple of 256B). This is the size of each buffer 
  //          element in the request and not the size of the entire request.
  en_qp = 1;
  //ip_proto = 0;
  mtu_config = 4;
  rq_buffer_entry_size = RQE_SIZE;
  //qp_config = (en_qp & 0x0000000f) | (0x20 & 0x000000f0) | ((mtu_config<<8) & 0x0000ff00) | ((rq_buffer_entry_size<<16) & 0xffff0000);
  // set QPCONFi[4] = 1 to disable HW handshake
  // enable QPCONFi[2] and QPCONFi[3]
  qp_config = (en_qp & 0x00000001) | (0xc & 0x0000000c) | (0x10 & 0x000000f0) | ((mtu_config<<8) & 0x0000ff00) | ((rq_buffer_entry_size<<16) & 0xffff0000);
  write32_data(rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_QPCONFi, qpid), qp_config);
  fprintf(stderr, "[Register] RN_RDMA_QCSR_QPCONFi=0x%x, qpid=%d, value=0x%x\n", get_rdma_per_q_config_addr(RN_RDMA_QCSR_QPCONFi, qpid), qpid, qp_config);

  // Queue pair advanced control configuration
  traffic_class = 0;
  time_to_live  = 64;
  qp_adv_conf = ((partion_key<<16) & 0xffff0000) | ((time_to_live<<8) & 0x0000ff00) | (traffic_class & 0x000000ff);
  write32_data(rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_QPADVCONFi, qpid), qp_adv_conf);
  fprintf(stderr, "[Register] RN_RDMA_QCSR_QPADVCONFi=0x%x, qpid=%d, value=0x%x\n", get_rdma_per_q_config_addr(RN_RDMA_QCSR_QPADVCONFi, qpid), qpid, qp_adv_conf);

  // SQ base PSN configuration
  write32_data(rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_SQPSNi, qpid), sq_psn);
  fprintf(stderr, "[Register] RN_RDMA_QCSR_SQPSNi=0x%x, qpid=%d, value=0x%x\n", get_rdma_per_q_config_addr(RN_RDMA_QCSR_SQPSNi, qpid), qpid, sq_psn);

  if(!is_remote) {
    // Get a different number for last_rq_psn
    last_rq_psn = sq_psn - 2048; // make it 0x2bc for easy debug
    // Update register
    last_rq_conf = ((last_rq_opcode<<24) & 0xff000000) | (last_rq_psn & 0x00ffffff);
    write32_data(rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_LSTRQREQi, qpid), last_rq_conf);
    fprintf(stderr, "[Register] RN_RDMA_QCSR_LSTRQREQi=0x%x, qpid=%d, value=0x%x\n", get_rdma_per_q_config_addr(RN_RDMA_QCSR_LSTRQREQi, qpid), qpid, last_rq_conf);
    qp->last_rq_psn = last_rq_psn;
  } else {
    qp->last_rq_psn = 0;
  }

  // PD number configuration
  write32_data(rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_PDi, qpid), pd_num);
  fprintf(stderr, "[Register] RN_RDMA_QCSR_PDi=0x%x, qpid=%d, value=0x%x\n", get_rdma_per_q_config_addr(RN_RDMA_QCSR_PDi, qpid), qpid, pd_num);

  fprintf(stderr, "Info: allocate_rdma_qp - Successfully allocated a rdma qp\n");
  return qp;
}

int read_cq_cidb(struct rdma_dev_t* rdma_dev, uint32_t qpid, int sq_cidb) {
  int cq_cidb;
  uint32_t timeout_cnt = 0;
  cq_cidb = read32_data(rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_CQHEADi, qpid));
  fprintf(stderr, "[Register] RN_RDMA_QCSR_CQHEADi=0x%x, qpid=%d, value=0x%x\n", get_rdma_per_q_config_addr(RN_RDMA_QCSR_CQHEADi, qpid), qpid, cq_cidb);

  fprintf(stderr, "INFO: before polling: sq_cidb = %d; Polling CQ CIDB = %d\n", sq_cidb, cq_cidb);
  while(cq_cidb == sq_cidb) {
    cq_cidb = read32_data(rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_CQHEADi, qpid));
    timeout_cnt += 1;
    if(timeout_cnt > TIMEOUT_THRESHOLD) {
      goto timeout_action;
    }
    //fprintf(stderr, "Waiting for completion doorbell index update\n");
  }

  fprintf(stderr, "INFO: after polling: sq_cidb = %d; Polling CQ CIDB = %d\n", sq_cidb, cq_cidb);
  return cq_cidb;

timeout_action:
  fprintf(stderr, "ERROR: read_cq_cidb timeout!\n");
  dump_registers(rdma_dev, 1, qpid);
  return -1;
}

int read_rq_pidb(struct rdma_dev_t* rdma_dev, uint32_t qpid) {
  struct rdma_qp_t* qp = rdma_dev->qps_ptr[qpid];
  int rp_pidb = read32_data(rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_STATRQPIDBi, qpid));

  // If poll, read until greater than what we previously have read
  fprintf(stderr, "Polling on RQ PIDB. Count: 0x%x\n", rp_pidb);
  while(rp_pidb == qp->rq_pidb) {
      rp_pidb = read32_data(rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_STATRQPIDBi, qpid));
  }

  qp->rq_pidb++;        
  return qp->rq_pidb;
}

void create_a_wqe(struct rdma_dev_t* rdma_dev, uint32_t qpid, uint16_t wrid, uint32_t wqe_idx, uint64_t laddr, uint32_t length, uint32_t opcode, uint64_t remote_offset, uint32_t r_key, uint32_t send_small_payload0, uint32_t send_small_payload1, uint32_t send_small_payload2, uint32_t send_small_payload3, uint32_t immdt_data) {

  uint32_t high_addr;
  uint32_t low_addr;
  uint64_t masked_buf_addr;

  high_addr = ((uint32_t) ((laddr & 0xffffffff00000000) >> 32)) & win_size_high;
  low_addr  = ((uint32_t) (laddr & 0x00000000ffffffff)) & win_size_low;
  masked_buf_addr = (((uint64_t) high_addr) << 32) | ((uint64_t) low_addr);
  fprintf(stderr, "Info: WQE mem_buffer = 0x%lx, masked_mem_buffer = 0x%lx\n", laddr, masked_buf_addr);

  struct rdma_buff_t* sq = rdma_dev->qps_ptr[qpid]->sq;
  struct rdma_wqe_t* wqe = &(((struct rdma_wqe_t*) sq->buffer)[wqe_idx]);

  wqe->wrid = wrid;
  //wqe->laddr = masked_buf_addr;
  wqe->laddr_low = low_addr;
  wqe->laddr_high = high_addr;
  wqe->opcode = opcode & 0x000000ff;
  wqe->length = length;
  //wqe->remote_offset = remote_offset;
  wqe->remote_offset_low  = (uint32_t) (remote_offset & 0x00000000ffffffff);
  wqe->remote_offset_high = (uint32_t) ((remote_offset & 0xffffffff00000000) >> 32);
  wqe->r_key = r_key;
  wqe->send_small_payload0 = send_small_payload0;
  wqe->send_small_payload1 = send_small_payload1;
  wqe->send_small_payload2 = send_small_payload2;
  wqe->send_small_payload3 = send_small_payload3;
  wqe->immdt_data = immdt_data;
  fprintf(stderr, "[WQE] wrid=0x%x\n", (uint32_t) wqe->wrid);
  fprintf(stderr, "[WQE] laddr_low=0x%x\n", wqe->laddr_low);
  fprintf(stderr, "[WQE] laddr_high=0x%x\n", wqe->laddr_high);
  fprintf(stderr, "[WQE] length=0x%x\n", wqe->length);
  fprintf(stderr, "[WQE] opcode=0x%x\n", wqe->opcode);
  fprintf(stderr, "[WQE] remote_offset_low=0x%x\n", wqe->remote_offset_low);
  fprintf(stderr, "[WQE] remote_offset_high=0x%x\n", wqe->remote_offset_high);
  fprintf(stderr, "[WQE] r_key=0x%x\n", wqe->r_key);
  fprintf(stderr, "[WQE] send_small_payload0=0x%x\n", wqe->send_small_payload0);
  fprintf(stderr, "[WQE] send_small_payload1=0x%x\n", wqe->send_small_payload1);
  fprintf(stderr, "[WQE] send_small_payload2=0x%x\n", wqe->send_small_payload2);
  fprintf(stderr, "[WQE] send_small_payload3=0x%x\n", wqe->send_small_payload3);
  fprintf(stderr, "[WQE] immdt_data=0x%x\n", wqe->immdt_data);
}

uint32_t rdma_post_send(struct rdma_dev_t* rdma_dev, uint32_t qpid) {
  if(rdma_dev == NULL) {
    fprintf(stderr, "Error: rdma_dev is NULL\n");  
    exit(EXIT_FAILURE);
  }

  struct rdma_qp_t* qp = rdma_dev->qps_ptr[qpid];

  // Increase send queue producer index doorbell
  fprintf(stderr, "DEBUG: Reading hardware SQPIi (0x%x) = 0x%x\n", get_rdma_per_q_config_addr(RN_RDMA_QCSR_SQPIi, qpid), read32_data(rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_SQPIi, qpid)));
  fprintf(stderr, "DEBUG: original qp->sq_pidb = 0x%x\n", qp->sq_pidb);
  
  qp->sq_pidb++;

  // Update sq_pidb to hardware
  write32_data(rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_SQPIi, qpid), qp->sq_pidb);
  fprintf(stderr, "[Register] RN_RDMA_QCSR_SQPIi=0x%x, qpid=%d, value=0x%x\n", get_rdma_per_q_config_addr(RN_RDMA_QCSR_SQPIi, qpid), qpid, qp->sq_pidb);
  fprintf(stderr, "DEBUG: Update hardware sq db idx from software = %d\n", qp->sq_pidb);

  // polling on completion, by checking CQ doorbell
  qp->cq_cidb = read_cq_cidb(rdma_dev, qpid, qp->sq_cidb);
  qp->sq_cidb++;

  if(qp->cq_cidb < 0) {
    return -1;
  } else {
    return 1;
  }
}

void* rdma_post_receive(struct rdma_dev_t* rdma_dev, struct rdma_qp_t* qp) {
    if(rdma_dev == NULL) {
        fprintf(stderr, "Error: rdma_dev is empty\n");
        return NULL;
    }

    if(qp == NULL) {
        fprintf(stderr, "Error: qp is empty\n");
        return NULL;
    }

    void *rqe = NULL;
    
    int rq_pidb = read_rq_pidb(rdma_dev, qp->qpid);
    if(rq_pidb == -1) {
        fprintf(stderr, "Error: rdma_post_receive failed\n");
        exit(EXIT_FAILURE);
    }

    // Pointing to the RQE
    if(rq_pidb == 0) {
        rqe = qp->rq->buffer + (qp->qdepth - 1) * RQE_SIZE;
    }
    else {
        rqe = qp->rq->buffer + (rq_pidb - 1) * RQE_SIZE;
    }

    write32_data(rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_RQCIi, qp->qpid), rq_pidb);
    fprintf(stderr, "[Register] RN_RDMA_QCSR_RQCIi=0x%x, qpid=%d, value=0x%x\n", get_rdma_per_q_config_addr(RN_RDMA_QCSR_RQCIi, qp->qpid), qp->qpid, rq_pidb);

    return rqe;
}

int destroy_rdma_pd_entry(struct rdma_pd_t* pd) {
  if(pd != NULL) {
    free(pd->mr_buffer);
    pd = NULL;
  }

  return 0;
}

void rdma_qp_fatal_recovery(struct rdma_dev_t* rdma_dev, uint32_t qpid) {
  // TODO: need to add fatal recovery logic
}

int destroy_rdma_qp(struct rdma_qp_t* qp){
  uint32_t en_qp;
  uint32_t mtu_config;
  uint32_t rq_buffer_entry_size;
  uint32_t qp_config;
  uint32_t rt_value;

  if(qp != NULL) {
    // Read STATQPi to make sure STATQPi[7:0] = 8'd0 and STATQPi[10:9] = 2'b11;
    rt_value = read32_data(qp->rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_STATQPi, qp->qpid));
    if(!(((rt_value & 0x000000ff)==0) && (((rt_value>>9) & 0x00000003) == 0x3))) {
      fprintf(stderr, "Warning: QP in fatal status\n");
      // call rdma_qp_fatal_recovery()
      rdma_qp_fatal_recovery(qp->rdma_dev, qp->qpid);
    }

    // Check whether SQPIi and CQHEADi have the same value
    rt_value = read32_data(qp->rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_CQHEADi, qp->qpid));
    if (rt_value != read32_data(qp->rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_SQPIi, qp->qpid))) {
      fprintf(stderr, "Warning: CQHEADi and SQPIi for QP%d are mismatched\n", qp->qpid);
      // call rdma_qp_fatal_recovery()
      rdma_qp_fatal_recovery(qp->rdma_dev, qp->qpid);
    }

    // Enable software override mode (1'b1) in XRNICADCONF[0] and disable QP (1'b0) in QPCONFi[0]
    rt_value = read32_data(qp->rdma_dev->axil_ctl, RN_RDMA_GCSR_XRNICADCONF);
    write32_data(qp->rdma_dev->axil_ctl, RN_RDMA_GCSR_XRNICADCONF, (rt_value | 0x00000001));
    rt_value = read32_data(qp->rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_QPCONFi, qp->qpid));
    write32_data(qp->rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_QPCONFi, qp->qpid),  (rt_value & 0xfffffffe));

    // Reset RQWPTRDBADDi, SQPIi, CQHEADi, RQCIi, STATRQPIDBi, STATCURSQPTRi, SQPSNi, LSTRQREQi 
    // and STATMSNi by 0; Configure QP under recovery in QPCONFi[6]
    write32_data(qp->rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_RQWPTRDBADDi, qp->qpid), 0);
    write32_data(qp->rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_SQPIi, qp->qpid), 0);
    write32_data(qp->rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_CQHEADi, qp->qpid), 0);
    write32_data(qp->rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_RQCIi, qp->qpid), 0);
    write32_data(qp->rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_STATRQPIDBi, qp->qpid), 0);
    write32_data(qp->rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_STATCURSQPTRi, qp->qpid), 0);
    write32_data(qp->rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_SQPSNi, qp->qpid), 0);
    write32_data(qp->rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_LSTRQREQi, qp->qpid), 0);
    write32_data(qp->rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_STATMSNi, qp->qpid), 0);
    rt_value = read32_data(qp->rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_QPCONFi, qp->qpid));
    write32_data(qp->rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_QPCONFi, qp->qpid),  (rt_value | 0x00000040));

    // Disable software override mode (1'b0) in XRNICADCONF[0]
    rt_value = read32_data(qp->rdma_dev->axil_ctl, RN_RDMA_GCSR_XRNICADCONF);
    write32_data(qp->rdma_dev->axil_ctl, RN_RDMA_GCSR_XRNICADCONF, (rt_value & 0xfffffffe));

    // Free memory allocated for SQ, RQ and CQ
    free(qp->sq);
    free(qp->rq);
    free(qp->cq);

    destroy_rdma_pd_entry(qp->pd_entry);
    qp = NULL;
  }

  return 0;
}

int destroy_rdma_dev(struct rdma_dev_t* rdma_dev) {
  int i;
  uint32_t rnic_enable;
  uint32_t rnic_config;
  if(rdma_dev != NULL) {
    free(rdma_dev->glb_csr);
    for(i=0; i<rdma_dev->num_qp; i++) {
      destroy_rdma_qp(rdma_dev->qps_ptr[i]);
    }

    // Disable RNIC hardware
    rnic_enable = 0;
    rnic_config = rnic_enable & 0xffffffff;
    write32_data(rdma_dev->axil_ctl, RN_RDMA_GCSR_XRNICCONF, rnic_config);
    rdma_dev = NULL;
  }

  return 0;
}

int destroy_rn_dev(struct rn_dev_t* rn_dev) {
  if(rn_dev != NULL) {
    free(rn_dev->base_buf);
    destroy_rdma_dev(rn_dev->rdma_dev);
    rn_dev = NULL;
  }

  return 0;
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

uint32_t convert_ip_addr_to_uint(char* ip_addr){
    unsigned char ip_char[4] = {0};
    uint32_t ip;
    sscanf(ip_addr, "%hhu.%hhu.%hhu.%hhu", &ip_char[0],&ip_char[1],&ip_char[2],&ip_char[3]);
    //fprintf(stderr, "ip = %u.%u.%u.%u\n", ip_char[0], ip_char[1], ip_char[2], ip_char[3]);
    ip = (ip_char[0]<<24) | (ip_char[1]<<16) | (ip_char[2]<<8) | ip_char[3];
    return ip;
}

struct mac_addr_t convert_mac_addr_to_uint(unsigned char* mac_addr_char) {
  struct mac_addr_t mac_addr_inst;
  uint32_t mac_addr_lsb;
  uint32_t mac_addr_msb;

  fprintf(stderr, "Info: mac_addr_t = %02x:%02x:%02x:%02x:%02x:%02x\n", mac_addr_char[0], mac_addr_char[1], mac_addr_char[2], mac_addr_char[3], mac_addr_char[4], mac_addr_char[5]);

  mac_addr_msb = ((mac_addr_char[0]<<8) | mac_addr_char[1]) & 0x0000ffff;
  mac_addr_lsb = ((mac_addr_char[2]<<24) | (mac_addr_char[3]<<16) | (mac_addr_char[4]<<8) | mac_addr_char[5]) & 0xffffffff;
  mac_addr_inst.mac_lsb = mac_addr_lsb;
  mac_addr_inst.mac_msb = mac_addr_msb;
  return mac_addr_inst;
}

struct mac_addr_t convert_mac_addr_str_to_uint(char* mac_addr_str) {
  struct mac_addr_t mac_addr_inst;
  uint32_t mac_addr_lsb;
  uint32_t mac_addr_msb;
  uint32_t mac_addr_array[6] = {0};
  sscanf(mac_addr_str, "%x:%x:%x:%x:%x:%x", &mac_addr_array[0],&mac_addr_array[1],&mac_addr_array[2],&mac_addr_array[3],&mac_addr_array[4],&mac_addr_array[5]);

  fprintf(stderr, "Info: mac_addr_t = %02x:%02x:%02x:%02x:%02x:%02x\n", mac_addr_array[0], mac_addr_array[1], mac_addr_array[2], mac_addr_array[3], mac_addr_array[4], mac_addr_array[5]);

  mac_addr_msb = ((mac_addr_array[0]<<8) | mac_addr_array[1]) & 0x0000ffff;
  mac_addr_lsb = ((mac_addr_array[2]<<24) | (mac_addr_array[3]<<16) | (mac_addr_array[4]<<8) | mac_addr_array[5]) & 0xffffffff;
  mac_addr_inst.mac_lsb = mac_addr_lsb;
  mac_addr_inst.mac_msb = mac_addr_msb;
  return mac_addr_inst;
}

int main(int argc, char *argv[])
{
	int sockfd;
	int accepted_sockfd;
	struct sockaddr_in server_addr;
	struct sockaddr_in client_addr;
	socklen_t addr_size;
	struct ifreq ifreq_local;
	struct ifreq ifreq_remote;

	// Get MAC address of a peer
	int family;
	int return_value;
	char tmp_ip[NI_MAXHOST];
	struct sockaddr_in *remote_ip_addr;
	struct ifaddrs* ifaddr;
	struct ifaddrs* ifa;
	char command[64];
	FILE *dst_mac_fp;
	char *line = NULL;
	size_t len = 0;
	unsigned char tmp_mac_addr_ptr[6];
	char tmp_mac_addr_str[18] = "";
	ssize_t command_read;

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

  char* cdev_name = NULL;
  int   cdev_fd;
  int   rn_scr;
  char  val = 0;

  struct rn_dev_t* rn_dev;
  struct rdma_buff_t* cidb_buffer;
  struct rdma_buff_t* tmp_buffer;
  struct rdma_buff_t* mr_bufferA;
	struct rdma_buff_t* mr_bufferB;
  struct rdma_buff_t* device_bufferA;
	struct rdma_buff_t* device_bufferB;
	struct rdma_buff_t* device_bufferC;
  uint32_t num_hugepages = 1;
  uint64_t cq_cidb_addr;
  uint64_t rq_cidb_addr;
  uint32_t pd_num;

  uint32_t sq_psn;
  uint32_t qpid;
  uint32_t dst_qpid;
  uint32_t qdepth;
  uint16_t wrid;
  uint32_t wqe_idx;
  uint32_t transfer_size;
  uint64_t remote_offset;
  uint64_t dev_offset;
  uint64_t read_A_offset;
	uint64_t read_B_offset;
  int      ret_val;
	char* result_buffer = NULL;

  uint8_t is_remote;
  uint32_t send_data;
  uint32_t remote_last_rq_psn;

  uint64_t read_offset;
  int      fpga_fd;

  server = 0;
  client = 0;
  pd_num = 0;
	dst_qpid = 2;

	// systolic MM variables
	size_t matrix_size = DATA_SIZE * DATA_SIZE;
	size_t matrix_size_bytes = sizeof(int) * matrix_size;	
	int source_hw_results[matrix_size];
	uint32_t source_in1[matrix_size];
	uint32_t source_in2[matrix_size];
	int source_sw_results[matrix_size];

	sockfd = socket(AF_INET, SOCK_STREAM, 0);

	/*
	uint8_t device_arg;
	uint8_t pcie_arg;
	uint8_t src_ip_arg;
	uint8_t dst_ip_arg;
	*/

	while ((cmd_opt =
		getopt_long(argc, argv, "d:p:r:i:u:t:q:f:sch", long_opts,
			    NULL)) != -1) {
		switch (cmd_opt) {
		case 'd':
			/* device node name */
			//fprintf(stdout, "'%s'\n", optarg);
			device = optarg;
			break;
		case 'p':
			/* PCIe resource file name */
			pcie_device = optarg;
			break;
		case 'r':
			src_ip = convert_ip_addr_to_uint(optarg);
      strcpy(src_ip_str, optarg);
      fprintf(stderr, "src_ip_str = %s\n", (char*) src_ip_str);
			break;
		case 'i':
			dst_ip = convert_ip_addr_to_uint(optarg);
      strcpy(dst_ip_str, optarg);
      fprintf(stderr, "dst_ip_str = %s\n", (char*) dst_ip_str);
			fprintf(stderr, "Info: getting MAC address of destination IP (%s)\n", dst_ip_str);
			sprintf(command, "arp -a %s", dst_ip_str);
			dst_mac_fp = popen(command, "r");
			if(dst_mac_fp == NULL) {
				perror("Error: popen\n");
				exit(EXIT_FAILURE);
			}

			while((command_read = getline(&line, &len, dst_mac_fp)) != -1) {
				// Check if we find an entry
				if (strstr(line, "no match found") != NULL) {
					fprintf(stderr, "No arp cache entry for the IP (%s). Please use \"arping | ping -c 1 %s\" to create the cache entry", dst_ip_str, dst_ip_str);
					exit(0);
				}
 
				if (strstr(line, "at") != NULL) {
					// Get the MAC address from the line
					tmp_mac_addr_ptr = strstr(line, "at")+3;
					strncpy(tmp_mac_addr_str, tmp_mac_addr_ptr, 17);
					dst_mac = convert_mac_addr_str_to_uint((unsigned char *) tmp_mac_addr_str);
					break;
				}
			}

			pclose(dst_mac_fp);
			free(line);

			break;
		case 'u':
			udp_sport = (uint16_t) atoi(optarg);
			break;
		case 't':
			tcp_sport = (uint16_t) atoi(optarg);
			break;
		case 'q':
			dst_qpid  = (uint32_t) atoi(optarg);
			break;
		case 's':
			server = 1;
      client = 0;
			break;
		case 'c':
			server = 0;
      client = 1;
			break;
		/* print usage help and exit */
		case 'h':
		default:
			//fprintf(stderr, "Info: cmd_opt = %c\n", cmd_opt);
			usage(argv[0]);
			exit(0);
			break;
		}
	}

	// Getting MAC address of a remote peer
	if(getifaddrs(&ifaddr) == -1) {
		fprintf(stderr, "Error: not able to getifaddrs\n");
		exit(EXIT_FAILURE);
	}

	for(ifa = ifaddr; ifa != NULL; ifa = ifa->ifa_next) {
		family = ifa->ifa_addr->sa_family;
		// Skip interfaces that are not IPv4 addresses
		if(family != AF_INET) {
			continue;
		}

		return_value = getnameinfo(ifa->ifa_addr, sizeof(struct sockaddr_in), tmp_ip, NI_MAXHOST, NULL, 0, NI_NUMERICHOST);

		fprintf(stderr, "Info: tmp_ip = %s\n", tmp_ip);

		if(return_value != 0) {
			fprintf(stderr, "Error: getnameinfo() failed with %s\n", gai_strerror(return_value));
			exit(EXIT_FAILURE);
		}

		if (strcmp(tmp_ip, src_ip_str) == 0) {
			fprintf(stderr, "Info: Found network interface: %s\n", ifa->ifa_name);
			strncpy(ifreq_local.ifr_name, (char* ) ifa->ifa_name, IFNAMSIZ -1);
			ioctl(sockfd, SIOCGIFHWADDR, &ifreq_local);
			fprintf(stderr, "Getting src_mac address:\n");
			src_mac = convert_mac_addr_to_uint((unsigned char* ) ifreq_local.ifr_hwaddr.sa_data);
			break;
		}
	}

	// Create RecoNIC device instance
	fprintf(stderr, "Info: Creating rn_dev\n");
	rn_dev = create_rn_dev(pcie_device, &rn_scr, RN_SCR_MAP_SIZE, num_qp);

	// Open RDMA engine
	fprintf(stderr, "Info: Opening rdma_dev\n");
	open_rdma_dev(rn_dev, src_mac, src_ip, udp_sport);

  // Allocate a hugepage for the CQ and RQ's cidb buffer. They share the same hugepage
  // cidb is 32-bit, and each queue pair will have both cq_cidb and rq_cidb. Therefor, 
  // we set base address of rq_cidb_addr to cq_cidb_addr + (num_qp<<2)
  fprintf(stderr, "Info: creating rdma_buffer for cq_cidb and rq_cidb\n");
  uint32_t cidb_buffer_size = (1 << HUGE_PAGE_SHIFT);
  cidb_buffer = allocate_rdma_buffer(rn_dev, (uint64_t) cidb_buffer_size);
  cq_cidb_addr = cidb_buffer->dma_addr;
  rq_cidb_addr = cidb_buffer->dma_addr + (num_qp<<2);
	fprintf(stderr, "Info: done with cq_cidb and rq_cidb buffer allocation\n");

	// Allocate protection domain for queues and memory regions
  struct rdma_pd_t* rdma_pd = allocate_rdma_pd(rn_dev, pd_num, R_KEY);
  fprintf(stderr, "Info: rdma_pd is allocated\n");

	qdepth = 64;
	qpid   = 2;
	sq_psn = 0xabc;

  // Copy data from host memory to device memory
  fpga_fd = open(device, O_RDWR);
  if (fpga_fd < 0) {
    fprintf(stderr, "unable to open device %s, %d.\n",
      device, fpga_fd);
    perror("open device");
    close(fpga_fd);
    return -EINVAL;
  }

  if(client) {

    // Get remote_last_rq_psn from the server
    memset(&server_addr, '\0', sizeof(struct sockaddr_in));
    server_addr.sin_family = AF_INET;
    server_addr.sin_port   = htons(tcp_sport);
    server_addr.sin_addr.s_addr = inet_addr(dst_ip_str);

    fprintf(stderr, "Info: Client is connecting to a remote server\n");
    connect(sockfd, (struct sockaddr* )&server_addr, sizeof(server_addr));

    fprintf(stderr, "Info: Client is connected to a remote server\n");

    rc = read(sockfd, &remote_last_rq_psn, sizeof(remote_last_rq_psn));
    if(rc > 0) {
      fprintf(stderr, "Info: client received remote last_rq_psn = 0x%x\n", ntohl(remote_last_rq_psn));
    } else {
      fprintf(stderr, "Error: Can't receive remote_last_rq_psn from the remote peer\n");
      return -1;
    }

    // get remote virtual address from the server for a RDMA read operation
    rc = read(sockfd, &read_A_offset, sizeof(read_A_offset));

    if(rc > 0) {
      fprintf(stderr, "Info: client received remote offset of A = 0x%lx\n", ntohll(read_A_offset));
    } else {
      fprintf(stderr, "Error: Can't receive remote offset of A from the remote peer\n");
      close(sockfd);
      return -1;
    }

    read_A_offset = ntohll(read_A_offset);

    rc = read(sockfd, &read_B_offset, sizeof(read_B_offset));

    if(rc > 0) {
      fprintf(stderr, "Info: client received remote offset of B = 0x%lx\n", ntohll(read_B_offset));
    } else {
      fprintf(stderr, "Error: Can't receive remote offset of B from the remote peer\n");
      close(sockfd);
      return -1;
    }

    read_B_offset = ntohll(read_B_offset);

    is_remote = 1;
		wqe_idx   = 0;
		wrid      = 0;
		transfer_size = matrix_size * 4;
    dev_offset = 0;

    fprintf(stderr, "Info: creating an RDMA read WQE for getting Array A\n");
    device_bufferA = (struct rdma_buff_t*) malloc(sizeof(struct rdma_buff_t));
    device_bufferA->buffer = NULL;
    device_bufferA->dma_addr = dev_offset;

    device_bufferB = (struct rdma_buff_t*) malloc(sizeof(struct rdma_buff_t));
    device_bufferB->buffer = NULL;
    device_bufferB->dma_addr = dev_offset + transfer_size;

		device_bufferC = (struct rdma_buff_t*) malloc(sizeof(struct rdma_buff_t));
		device_bufferC->buffer = NULL;
		device_bufferC->dma_addr = dev_offset + (uint64_t) (transfer_size<<1);

		clock_gettime(CLOCK_MONOTONIC, &ts_start);

    remote_last_rq_psn = ntohl(remote_last_rq_psn);
    sq_psn = remote_last_rq_psn + 1;
    allocate_rdma_qp(rn_dev, qpid, pd_num, sq_psn, rdma_pd, cq_cidb_addr, rq_cidb_addr, dst_qpid, qdepth, &dst_mac, dst_ip, P_KEY, is_remote);

    //create_a_wqe(rn_dev->rdma_dev, qpid, wrid+1, wqe_idx+1, device_buffer->dma_addr, transfer_size, RNIC_OP_READ, read_offset, R_KEY, 0, 0, 0, 0, 0);
    create_a_wqe(rn_dev->rdma_dev, qpid, wrid, wqe_idx, device_bufferA->dma_addr, transfer_size, RNIC_OP_READ, read_A_offset, R_KEY, 0, 0, 0, 0, 0);

    // Post RDMA operation
    ret_val = (int) rdma_post_send(rn_dev->rdma_dev, qpid);
    if(ret_val>0) {
      fprintf(stderr, "Successfully sent an RDMA read operation for Array A!\n");
    } else {
      fprintf(stderr, "Failed to send an RDMA read operation for Array A!\n");
    }

		wqe_idx++;

		dump_registers(rn_dev->rdma_dev, 1, qpid);

		create_a_wqe(rn_dev->rdma_dev, qpid, wrid, wqe_idx, device_bufferB->dma_addr, transfer_size, RNIC_OP_READ, read_B_offset, R_KEY, 0, 0, 0, 0, 0);

    // Post RDMA operation
    ret_val = (int) rdma_post_send(rn_dev->rdma_dev, qpid);
    if(ret_val>0) {
      fprintf(stderr, "Successfully sent an RDMA read operation for Array B!\n");
    } else {
      fprintf(stderr, "Failed to send an RDMA read operation for Array B!\n");
    }

    dump_registers(rn_dev->rdma_dev, 1, qpid);

		// Messages are ready, now we can launch the computation kernel
			// Construct control command and issue to the RecoNIC shell
		ctl_cmd_t ctl_cmd;
		init_ctl_cmd(&ctl_cmd, (uint32_t) device_bufferA->dma_addr, (uint32_t) device_bufferB->dma_addr, (uint32_t) device_bufferC->dma_addr, ctl_cmd_size, a_row, a_col, b_col, work_id);

		// Start FPGA accelerator
		issue_ctl_cmd((void *)rn_dev->axil_ctl, RN_CLR_CTL_CMD, &ctl_cmd);

		// Polling the status register and get data back
		compute_done = 0;
		while(compute_done == 0) {
			compute_done = read32_data(rn_dev->axil_ctl, RN_CLR_JOB_COMPLETED_NOT_READ);
		}

    fprintf(stderr, "Info: Computation is finished!\n");

		rc = read_to_buffer(device, fpga_fd, (char*) source_hw_results, matrix_size*4, (uint64_t)device_bufferC->dma_addr);
		if (rc < 0)
				goto out;

		//rc = read_to_buffer(device, fpga_fd, (char*) source_in1, matrix_size*4*3, (uint64_t)a_baseaddr);

		rc = clock_gettime(CLOCK_MONOTONIC, &ts_end);

		/* subtract the start time from the end time */
		timespec_sub(&ts_end, &ts_start);
		total_time += (ts_end.tv_sec + ((double)ts_end.tv_nsec/NSEC_DIV));

		fprintf(stdout, "** Avg time device %s, total time %f sec, size = %d\n",	device, total_time, DATA_SIZE);

		// Compute Software Results
		// Create the test data and Software Result
		for (size_t i = 0; i < matrix_size; i++) {
			source_in1[i] = i % 10;
			source_in2[i] = i % 10;
			source_sw_results[i] = 0;
		}

		software_mmult(source_in1, source_in2, source_sw_results);

		hw_work_id = read32_data(rn_dev->axil_ctl, RN_CLR_KER_STS);

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
  }

  if(server) {
    is_remote = 0;
    struct rdma_qp_t* qp = allocate_rdma_qp(rn_dev, qpid, pd_num, sq_psn, rdma_pd, cq_cidb_addr, rq_cidb_addr, dst_qpid, qdepth, &dst_mac, dst_ip, P_KEY, is_remote);

    // Connect to the remote peer via TCP/IP
    memset(&server_addr, '\0', sizeof(struct sockaddr_in));
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(tcp_sport);
    server_addr.sin_addr.s_addr = inet_addr((char *) src_ip_str);

    bind(sockfd, (struct sockaddr*) &server_addr, sizeof(struct sockaddr_in));

    fprintf(stderr, "Info: Server is listening to a remote peer\n");
    listen(sockfd, LISTENQ);

    addr_size = sizeof(client_addr);
    accepted_sockfd = accept(sockfd, (struct sockaddr*)&client_addr, &addr_size);

    fprintf(stderr, "Info: Server is connected to a remote peer\n");

    send_data = htonl(qp->last_rq_psn);
    write(accepted_sockfd, &send_data, sizeof(uint32_t));

    fprintf(stderr, "Sending last_rq_psn (%d) to the remote client\n", qp->last_rq_psn);

    // RDMA read operation
    tmp_buffer = rdma_register_memory_region(rn_dev, rdma_pd, R_KEY, 1, 0, 0);
    fprintf(stderr, "Info: allocating buffer for array A\n");
    mr_bufferA->buffer   = tmp_buffer->buffer;
    mr_bufferA->dma_addr = tmp_buffer->dma_addr;
    fprintf(stderr, "Info: mr_bufferA->buffer = %p, mr_bufferA->dma_addr = 0x%lx\n", (uint64_t *) mr_bufferA->buffer, mr_bufferA->dma_addr);
    fprintf(stderr, "Info: allocating buffer for array B\n");
    mr_bufferB->buffer   = (void *) ((uint64_t) tmp_buffer->buffer + ((uint64_t) (matrix_size << 2)));
    mr_bufferB->dma_addr = tmp_buffer->dma_addr + ((uint64_t) (matrix_size << 2));
    fprintf(stderr, "Info: mr_bufferB->buffer = %p, mr_bufferB->dma_addr = 0x%lx\n", (uint64_t *) mr_bufferB->buffer, mr_bufferB->dma_addr);

		// Create the test data and Software Result
		for (size_t i = 0; i < matrix_size; i++) {
			*((uint32_t* )(mr_bufferA->buffer) + i) = i % 10;
			*((uint32_t* )(mr_bufferB->buffer) + i) = i % 10;
		}

    fprintf(stderr, "Info: Host buffer vir address used for RDMA read operation is mr_bufferA = %p, mr_bufferB = %p\n", (uint64_t *) mr_bufferA->buffer, (uint64_t *) mr_bufferB->buffer);
    
		read_offset = htonll((uint64_t) mr_bufferA->buffer);
    write(accepted_sockfd, &read_offset, sizeof(uint64_t));
		fprintf(stderr, "Sending read_offsetA (%lx) to the remote client\n", ntohll(read_offset));

		read_offset = htonll((uint64_t) mr_bufferB->buffer);
    write(accepted_sockfd, &read_offset, sizeof(uint64_t));
    fprintf(stderr, "Sending read_offsetB (%lx) to the remote client\n", ntohll(read_offset));

    // Does the client finish its RDMA operation?
    fprintf(stderr, "Does the client finish its RDMA read operation? If yes, please press any key\n");
    
    while(val != '\r' && val != '\n') {
      val = getchar();
    }
    fprintf(stderr, "\n");

    dump_registers(rn_dev->rdma_dev, 0, qpid);

    if(shutdown(accepted_sockfd, SHUT_RDWR) < 0){
      fprintf(stderr, "accepted_sockfd shutdown failed\n");
      fprintf(stderr, "Error: %s\n", strerror(errno));
    }
    close(accepted_sockfd);
  }

  if(shutdown(sockfd, SHUT_RDWR) < 0){
    fprintf(stderr, "sockfd shutdown failed\n");
    fprintf(stderr, "Error: %s\n", strerror(errno));
  }
	close(sockfd);	

out:
	close(fpga_fd);
  close(rn_scr);
  destroy_rn_dev(rn_dev);
	return rc;
}
