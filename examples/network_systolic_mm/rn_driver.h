//==============================================================================
// Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
// SPDX-License-Identifier: MIT
//
//==============================================================================

#ifndef _RN_DRIVER_H_
#define _RN_DRIVER_H_

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <errno.h>

#include "rn_register.h"

# define htonll(x) (((uint64_t)htonl((x) & 0xFFFFFFFF) << 32) | htonl((x) >> 32))
# define ntohll(x) (((uint64_t)ntohl((x) & 0xFFFFFFFF) << 32) | ntohl((x) >> 32))

#define DEVICE_NAME "/dev/reconic-mm"

#define TCP_PORT 11111

#define LISTENQ 8 /*maximum number of client connections */

#define STR_LENGTH 256
#define UDP_DPORT 4791

// 2MB for each huge page
#define HUGE_PAGE_SHIFT 21

#define preallocated_hugepages 64

#define BUFFER_SIZE (1 << HUGE_PAGE_SHIFT)

// Number of bytes in a pagemap entry
#define PAGE_SHIFT      12  // 4KB
#define PAGEMAP_LENGTH  8  

#define RQE_SIZE 256

// Hardcoded some of the configurations
#define P_KEY 0x1234
#define R_KEY 0x0008

struct mac_addr_t {
  uint32_t mac_lsb;
  uint32_t mac_msb;
};

// RDMA buffer structure
struct rdma_buff_t {
  void* buffer;
  uint64_t dma_addr;
};

// RDMA Work Queue Element structure
struct rdma_wqe_t {
  // work request ID. Unique ID for each WQE
  uint16_t wrid;
  uint16_t reserved;
  // local payload buffer adress
  uint32_t laddr_low;
  uint32_t laddr_high;
  // payload size for the transfer
  uint32_t length;
  // 8-bit Opcode, only opcode[7:0] is valid, the rest opcode[31:8] should be set to 0
  uint32_t opcode;
  uint32_t remote_offset_low;
  uint32_t remote_offset_high;
  uint32_t r_key;
  uint32_t send_small_payload0;
  uint32_t send_small_payload1;
  uint32_t send_small_payload2;
  uint32_t send_small_payload3;
  uint32_t immdt_data;
  uint32_t reserved0;
  uint32_t reserved1;
  uint32_t reserved2;
};

// RDMA Completion Queue Element structure
struct rdma_cqe_t {
  uint16_t wrid;
  uint8_t  opcode;
  uint8_t  errflag;
};

// RDMA Protection Domain entry structure
struct rdma_pd_t {
  // 24-bit pd number
  uint32_t pd_num;
  // virtual address of the allocated buffer
  uint32_t virtual_addr_lsb;
  uint32_t virtual_addr_msb;
  // DMA address of the allocated buffer
  uint32_t dma_addr_lsb;
  uint32_t dma_addr_msb;
  // {24-bit pd_num, 8-bit r_key}
  uint32_t r_key;
  uint32_t buffer_size_lsb;
  uint16_t buffer_size_msb;
  // 4-bit pd_access_type:
  // -- 4'b0000: READ Only
	// -- 4'b0001: Write Only
	// -- 4'b0010: Read and Write
  // -- Other values: Not supported
  uint16_t pd_access_type;

  struct rdma_buff_t* mr_buffer;
};

struct rdma_glb_csr_t {
  uint16_t data_buf_size;
  uint16_t num_data_buf;
  uint64_t data_buf_baseaddr;
  uint64_t err_buf_baseaddr;
  uint32_t err_buf_size;
  uint64_t resp_err_pkt_buf_baseaddr;
  uint32_t resp_err_pkt_buf_size;
  uint8_t  interrupt_enable;
  struct mac_addr_t src_mac;
  uint32_t src_ip;
  uint16_t udp_sport;
  uint8_t  num_qp_enabled;
  uint8_t  xrnic_config;
};

// RDMA Queue Pair structure
struct rdma_qp_t {
  struct rdma_dev_t* rdma_dev;
  uint32_t qpid;
  // Send queue and its doorbell
  struct rdma_buff_t* sq;
  uint32_t sq_psn;
  int sq_pidb;
  int sq_cidb;

  // Completion queue and its doorbell
  struct rdma_buff_t* cq;
  uint64_t cq_cidb_addr;
  int cq_cidb;

  // Receive queue and its doorbell
  struct rdma_buff_t* rq;
  uint64_t rq_cidb_addr;
  int rq_cidb;
  int rq_pidb;

  // pd number
  uint32_t pd_num;

  // protection domain entry
  struct rdma_pd_t* pd_entry;

  // destination queue pair ID
  uint32_t dst_qpid;

  // Q depth
  uint32_t qdepth;

  // Last rq req for QPi
  uint32_t last_rq_psn;

  // destination MAC address
  struct mac_addr_t* dst_mac;

  // destination IP address
  uint32_t dst_ip;
};

struct rdma_dev_t {
  struct rdma_glb_csr_t* glb_csr;
  struct rdma_qp_t** qps_ptr;
  uint32_t* axil_ctl;
  uint32_t num_qp;
};

struct rn_dev_t {
  uint32_t* axil_ctl;
  uint32_t  axil_map_size;
  struct rdma_buff_t* base_buf;
  struct rdma_dev_t* rdma_dev;
  uint64_t buffer_offset;
  unsigned char num_qp;
};

uint32_t convert_ip_addr_to_uint(char* ip_addr);
void search_options(int argc, char **argv);
void* get_vir_addr(int* rn_ptr, void* map_base, size_t* map_size, off_t target_addr);
void write32_data(uint32_t* base_address, off_t offset, uint32_t value);
uint32_t read32_data(uint32_t* base_address, off_t offset);

struct rn_dev_t* create_rn_dev(char* scr_filename, int* rn_scr, uint32_t scr_map_size, uint32_t num_qp);
struct rdma_dev_t* create_rdma_dev(uint32_t num_qp);
void open_rdma_dev(struct rn_dev_t* rn_dev, struct mac_addr_t local_mac, uint32_t local_ip, uint32_t udp_sport);


ssize_t read_to_buffer(char *fname, int rn, char *buffer, uint64_t size,
			uint64_t base);
ssize_t write_from_buffer(char *fname, int rn, char *buffer, uint64_t size,
			uint64_t base);

#endif /* _RN_DRIVER_H_ */