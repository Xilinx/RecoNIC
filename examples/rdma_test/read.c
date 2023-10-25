//==============================================================================
// Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
// SPDX-License-Identifier: MIT
//
//==============================================================================

#include "reconic.h"
#include "rdma_api.h"
#include "rdma_test.h"

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

// configure RDMA global control status register
// data buffer, IPKTERR queue buffer, error buffer, response error buffer and retry packet buffer are allocated at host memory in the current software RDMA APIs.
// We set default values to these buffers as below.
// Data buffer size          : 16MB, 256 Data buffers with each having 4KB. Buffers of 4K size each for 
//                             256 QPs and each QP with up to 16 outstanding transactions.
// IPKTERR buffer size       : 8KB for IPKTERR buffer. Each error status buffer entry is 64-bit wide. 
//                             The format is [63: 32] reserved;
//                                           [31 : 16] QP ID;
//                                           [15 :  0] Fatal code. 
// Error buffer size         : 64KB for error buffer. 256 packets of 256 bytes each. Packets that fail 
//                             packet validation are sent to the error buffer along with 4 bytes of 
//                             error syndrome.
// Response error buffer size: 64KB for response error buffer.
uint16_t num_data_buf          = 4096;
uint16_t per_data_buf_size     = 4096;
uint16_t ipkt_err_stat_q_size  = 8192;
uint16_t num_err_buf           = 256;
uint16_t per_err_buf_size      = 256;
uint64_t resp_err_pkt_buf_size = 65536;

struct rn_dev_t* rn_dev;

int main(int argc, char *argv[])
{
  int sockfd;
  int accepted_sockfd;
  struct sockaddr_in server_addr;
  struct sockaddr_in client_addr;
  socklen_t addr_size;
  char command[64];
  FILE *dst_mac_fp;
  char *line = NULL;
  size_t len = 0;
  char *tmp_mac_addr_ptr = NULL;
  char tmp_mac_addr_str[18] = "";
  ssize_t command_read;

  int cmd_opt;
  device = DEVICE_NAME_DEFAULT;
  char *pcie_resource = NULL;
  char *qp_location = QP_LOCATION_DEFAULT;
  double total_time = 0.0;
  struct timespec ts_start, ts_end;
  double bandwidth  = 0.0;
  //payload size in bytes
  uint32_t payload_size = 4;
  int   pcie_resource_fd;
  char  val = 0;

  struct rdma_buff_t* cidb_buffer;
  struct rdma_buff_t* tmp_buffer;
  struct rdma_buff_t* device_buffer;

  uint64_t cq_cidb_addr;
  uint64_t rq_cidb_addr;

  struct rdma_dev_t* rdma_dev;

  struct rdma_buff_t* data_buf;
  struct rdma_buff_t* ipkterr_buf;
  struct rdma_buff_t* err_buf;
  struct rdma_buff_t* resp_err_pkt_buf;

  uint32_t rq_psn = 0xabc;
  uint32_t sq_psn = 0xabc + 1;
  uint32_t qpid;
  uint32_t dst_qpid;
  uint32_t qdepth;
  uint16_t wrid;
  uint32_t wqe_idx;
  //uint32_t transfer_size;

  uint64_t read_A_offset;
  int      ret_val;

  uint64_t read_offset;
  uint32_t* sw_golden;
  ssize_t rc;

  server = 0;
  client = 0;
  dst_qpid = 2;

  sockfd = socket(AF_INET, SOCK_STREAM, 0);

  while ((cmd_opt = getopt_long(argc, argv, "d:p:r:i:u:t:q:z:l:scgh", \
          long_opts, NULL)) != -1) {
    switch (cmd_opt) {
    case 'd':
      /* device node name */
      fprintf(stderr, "Info: Device - %s\n", optarg);
      device = optarg;
      break;
    case 'p':
      /* PCIe resource file name */
      fprintf(stderr, "Info: PCIe resource file: %s\n", optarg);
      pcie_resource = optarg;
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
      sprintf(command, "arp -a %s", dst_ip_str);
      dst_mac_fp = popen(command, "r");
      if(dst_mac_fp == NULL) {
        perror("Error: popen\n");
        exit(EXIT_FAILURE);
      }

      while((command_read = getline(&line, &len, dst_mac_fp)) != -1) {
        // Check if we find an entry
        if (strstr(line, "no match found") != NULL) {
          fprintf(stderr, "Error: No arp cache entry for the IP (%s). Please use \"arping | ping -c 1 %s\" to create the cache entry", dst_ip_str, dst_ip_str);
          exit(0);
        }

        if (strstr(line, "at") != NULL) {
          // Get the MAC address from the line
          tmp_mac_addr_ptr = strstr(line, "at")+3;
          strncpy(tmp_mac_addr_str, tmp_mac_addr_ptr, 17);
          dst_mac = convert_mac_addr_str_to_uint(tmp_mac_addr_str);
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
    case 'z':
      payload_size = (uint32_t) atoi(optarg);
      break;
    case 'l':
      /* QP allocated at host memory or device memory */
      fprintf(stderr, "Info: QP allocated at: %s\n", optarg);
      qp_location = optarg;
      if (!(strcmp(qp_location, HOST_MEM) || strcmp(qp_location, DEVICE_MEM))) {
        usage(argv[0]);
        exit(0);
      }
      break;
    case 's':
      server = 1;
      client = 0;
      break;
    case 'c':
      server = 0;
      client = 1;
      break;
    case 'g':
      debug = 1;
      break;
    /* print usage help and exit */
    case 'h':
    default:
      fprintf(stderr, "Info: cmd_opt = %c\n", cmd_opt);
      usage(argv[0]);
      exit(0);
      break;
    }
  }

  src_mac = get_mac_addr_from_str_ip(sockfd, src_ip_str);

  /* 
   * 1. Create an RecoNIC device instance
   */  
  fprintf(stderr, "Info: Creating rn_dev\n");
  rn_dev = create_rn_dev(pcie_resource, &pcie_resource_fd, preallocated_hugepages, num_qp);

  /* 
   * 2. Create an RDMA device instance
   */
  fprintf(stderr, "Info: CREATE RDMA DEVICE\n");
  rdma_dev = create_rdma_dev(rn_dev);

  /* 
   * 3. Allocate memory for CQ and RQ's cidb buffers, data buffer, 
   *    incoming_pkt_error_stat_q buffer, err_buffer and response error pkt buffer.
   */
  // Allocate a hugepage for the CQ and RQ's cidb buffer. They share the same hugepage
  // cidb is 32-bit, and each queue pair will have both cq_cidb and rq_cidb. Therefor, 
  // we set base address of rq_cidb_addr to cq_cidb_addr + (num_qp<<2)
  uint32_t cidb_buffer_size = (1 << HUGE_PAGE_SHIFT);
  cidb_buffer = allocate_rdma_buffer(rn_dev, (uint64_t) cidb_buffer_size, "host_mem");
  cq_cidb_addr = cidb_buffer->dma_addr;
  rq_cidb_addr = cidb_buffer->dma_addr + (num_qp<<2);

  // data buffer, incoming_pkt_error_stat_q buffer, err_buffer and response error pkt buffer
  data_buf = allocate_rdma_buffer(rn_dev, (uint64_t) (num_data_buf*per_data_buf_size), "host_mem");
  ipkterr_buf = allocate_rdma_buffer(rn_dev, (uint64_t) ipkt_err_stat_q_size, "host_mem");
  err_buf = allocate_rdma_buffer(rn_dev, (uint64_t) (num_err_buf*per_err_buf_size), "host_mem");
  resp_err_pkt_buf = allocate_rdma_buffer(rn_dev, (uint64_t) resp_err_pkt_buf_size, "host_mem");

  /* 
   * 4. Open RDMA engine 
   */
  fprintf(stderr, "Info: OPEN RDMA DEVICE\n");
  open_rdma_dev(rdma_dev, src_mac, src_ip, udp_sport, num_data_buf, per_data_buf_size,
                data_buf->dma_addr, ipkt_err_stat_q_size, ipkterr_buf->dma_addr, num_err_buf,
                per_err_buf_size, err_buf->dma_addr, resp_err_pkt_buf_size, resp_err_pkt_buf->dma_addr);

  /* 
   * 5. Allocate protection domain for queues and memory regions
   */
  fprintf(stderr, "Info: ALLOCATE PD\n");
  struct rdma_pd_t* rdma_pd = allocate_rdma_pd(rdma_dev, 0 /* pd_num */);

  qdepth = 64;
  qpid   = 2;

  fprintf(stderr, "Info: OPEN DEVICE FILE\n");
  // Open the character device, reconic-mm, for data communication between host and device memory
  fpga_fd = open(device, O_RDWR);
  if (fpga_fd < 0) {
    fprintf(stderr, "unable to open device %s, %d.\n",
      device, fpga_fd);
    perror("open device");
    close(fpga_fd);
    return -EINVAL;
  }

  /* 
   * 6. Allocate a queue pair
   */
  fprintf(stderr, "Info: ALLOCATE RDMA QP\n");
  // Allocate SQ, CQ and RQ: (num_qp * qdepth * entry_size)
  //  --  32KB SQ (8 SQs, each has 4KB and can accommodate 64 WQEs)
  //  --   2KB CQ (8 CQs, each has 256B and can accommodate 64 CQEs)
  //  -- 128KB RQ (8 RQs, each has 16KB and can accommodate 64 RQE)
  // All SQ, CQ and RQ resources can be used for a single QP.
    //struct rdma_qp_t* qp = 
  allocate_rdma_qp(rdma_dev, qpid, dst_qpid, rdma_pd, cq_cidb_addr, rq_cidb_addr, qdepth, qp_location, &dst_mac, dst_ip, P_KEY, R_KEY);

  /* 
   * 7. Configure last_rq_psn, so that the RDMA packets can be accepted at the remote side
   */
  fprintf(stderr, "Info: CONFIGURE PSN\n");
  config_last_rq_psn(rdma_dev, qpid, rq_psn);
  config_sq_psn(rdma_dev, qpid, sq_psn);

  // Get golden data for verification
  fprintf(stderr, "payload_size = %d, payload_size>>2 = %d\n", payload_size, payload_size>>2);
  sw_golden = (uint32_t* ) malloc(payload_size);
  for (uint32_t i = 0; i < payload_size>>2; i++) {
    sw_golden[i] = i % 10;
  }


  if(client) {

    uint32_t buf_size;
    uint64_t buf_phy_addr;

    buf_size = payload_size;
    
    uint32_t* recv_tmp = malloc(buf_size);

    memset(&server_addr, '\0', sizeof(struct sockaddr_in));
    server_addr.sin_family = AF_INET;
    server_addr.sin_port   = htons(tcp_sport);
    server_addr.sin_addr.s_addr = inet_addr(dst_ip_str);

    fprintf(stderr, "Info: Client is connecting to a remote server\n");
    connect(sockfd, (struct sockaddr* )&server_addr, sizeof(server_addr));

    fprintf(stderr, "Info: Client is connected to a remote server\n");

    rc = read(sockfd, &read_A_offset, sizeof(read_A_offset));

    if(rc > 0) {
      fprintf(stderr, "Info: client received remote offset of A = 0x%lx\n", ntohll(read_A_offset));
    } else {
      fprintf(stderr, "Error: Can't receive remote offset of A from the remote peer\n");
      close(sockfd);
      return -1;
    }

    read_A_offset = ntohll(read_A_offset);

    wqe_idx   = 0;
    wrid      = 0;

    device_buffer = allocate_rdma_buffer(rn_dev, (uint64_t) payload_size, "dev_mem");

    buf_phy_addr = device_buffer->dma_addr;

    fprintf(stderr, "Info: creating an RDMA read WQE for getting data\n");
    create_a_wqe(rn_dev->rdma_dev, qpid, wrid, wqe_idx, device_buffer->dma_addr, payload_size, RNIC_OP_READ, read_A_offset, R_KEY, 0, 0, 0, 0, 0);
    clock_gettime(CLOCK_MONOTONIC, &ts_start);
    ret_val = rdma_post_send(rn_dev->rdma_dev, qpid);
    clock_gettime(CLOCK_MONOTONIC, &ts_end);
    if(ret_val>=0) {
      fprintf(stderr, "Successfully sent an RDMA read operation\n");
    } else {
      fprintf(stderr, "Failed to send an RDMA read operation\n");
    }

    dump_registers(rn_dev->rdma_dev, 1, qpid);

    fprintf(stderr, "Info: All data has been received!\n");
    fprintf(stderr, "Info: buffer physical address is 0x%lx\n",buf_phy_addr);

    /* subtract the start time from the end time */
    timespec_sub(&ts_end, &ts_start);
    total_time = (ts_end.tv_sec + ((double)ts_end.tv_nsec/NSEC_DIV));
    bandwidth = ((double) payload_size) / total_time;
    fprintf(stderr, "Info: Time spent %f usec, size = %d bytes, Bandwidth = %f gigabits/sec\n",	total_time*1000000, payload_size, ((bandwidth*8)/1000000000));

    if(is_device_address(buf_phy_addr)) {
      // Copy data from device memory to host memory
      rc = read_to_buffer(device, fpga_fd, (char* ) recv_tmp, (uint64_t) payload_size, (uint64_t) buf_phy_addr);
      fprintf(stderr, "Info: The value of rc is %ld\n",rc);
      if(rc < 0) {
        fprintf(stderr, "Error: read_to_buffer failed with rc = %ld\n", rc);
        goto out;
      }
    } else {
      // Link RQ to recv_tmp buffer, as RQ is also in host memory
      recv_tmp = (uint32_t* ) device_buffer->buffer;
      fprintf(stderr,"Buffer contents: %ls\n", recv_tmp);
    }
/*
    for (uint32_t i = 0; i < payload_size>>2; i++) {
        fprintf(stderr, "Info: received data: recv[%d]=%d\n", i, recv_tmp[i]);
    }*/

    /* 
    * 10. Check received data.
    */
    fprintf(stderr, "Info: CHECK RECEIVED DATA\n");
    for (uint32_t i = 0; i < payload_size>>2; i++) {
      if(recv_tmp[i] != sw_golden[i]) {
        fprintf(stderr, "Error: received data mismatched: recv[%d]=%d, sw_golden[%d]=%d\n", i, recv_tmp[i], i, sw_golden[i]);
        goto out;
      }
    }

    fprintf(stderr, "Info: Data read successfully\n");

    // Free buffer
    if(is_device_address(buf_phy_addr)) {
      free(recv_tmp);
    }
    fprintf(stderr, "Info: Printing RDMA registers from the client side\n");
    // Dump RDMA registers
    dump_registers(rdma_dev, 1, qpid);


  }

  if(server) {
    // Connect to the remote peer via TCP/IP
    //uint32_t* sent_tmp = malloc(payload_size);
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

    tmp_buffer = allocate_rdma_buffer(rn_dev, payload_size, /*qp_location*/"dev_mem");
    rdma_register_memory_region(rdma_dev, rdma_pd, R_KEY, tmp_buffer);
    fprintf(stderr, "Info: allocating buffer for payload data\n");
    fprintf(stderr, "Info: tmp_buffer->buffer = %p, tmp_buffer->dma_addr = 0x%lx\n", (uint64_t *) tmp_buffer->buffer, tmp_buffer->dma_addr);

    if(is_device_address(tmp_buffer->dma_addr)) {
      // Device memory address
      fprintf(stderr, "Info: copy payload data to the device memory\n");
      rc = write_from_buffer(device, fpga_fd, (char* ) sw_golden, (uint32_t)(payload_size), tmp_buffer->dma_addr);
      fprintf(stderr, "Info: copied payload data to the device memory succesfully rc = %ld\n", rc);
      if (rc < 0){
        goto out;
      }
    } else {
      // Host memory address
      fprintf(stderr, "Info: Initialize payload data on the host memory\n");
      for (uint32_t i = 0; i < payload_size>>2; i++) {
        *((uint32_t* )(tmp_buffer->buffer) + i) = i % 10;
      }
    }

    read_offset = htonll((uint64_t) tmp_buffer->buffer);
    write(accepted_sockfd, &read_offset, sizeof(uint64_t));
    fprintf(stderr, "Sending read_offset (%lx) to the remote client\n", ntohll(read_offset));
    /*
    rc = read_to_buffer(device, fpga_fd, (char* ) sent_tmp, (uint64_t) payload_size, (uint64_t) tmp_buffer->dma_addr);
    for (uint32_t i = 0; i < payload_size>>2; i++) {
        fprintf(stderr, "Info: sent data: sent[%d]=%d\n", i, sent_tmp[i]);
    }*/

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
  free(cidb_buffer);
  free(data_buf);
  free(ipkterr_buf);
  free(err_buf);
  free(resp_err_pkt_buf);
  free(sw_golden);
  close(fpga_fd);
  close(pcie_resource_fd);
  destroy_rn_dev(rn_dev);
  return 0;
}


