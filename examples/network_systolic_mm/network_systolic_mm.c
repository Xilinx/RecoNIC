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

  uint32_t ctl_cmd_size = 6;
  uint16_t a_row = DATA_SIZE;
  uint16_t a_col = DATA_SIZE;
  uint16_t b_col = DATA_SIZE;

  uint32_t work_id = 0xdd;
  uint32_t hw_work_id = 0;
  int compute_done;
  ssize_t rc;
  ssize_t rc1;
  ssize_t rc2;
  double total_time = 0.0;
  struct timespec ts_start, ts_end;

  int   pcie_resource_fd;
  char  val = 0;

  struct rdma_buff_t* cidb_buffer;
  struct rdma_buff_t* tmp_buffer;
  struct rdma_buff_t* mr_bufferA = malloc(sizeof(struct rdma_buff_t));
  struct rdma_buff_t* mr_bufferB = malloc(sizeof(struct rdma_buff_t));
  struct rdma_buff_t* device_bufferA;
  struct rdma_buff_t* device_bufferB;
  struct rdma_buff_t* device_bufferC;
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
  uint32_t transfer_size;

  uint64_t read_A_offset;
  uint64_t read_B_offset;
  int      ret_val;

  uint64_t read_offset;
  uint32_t* matrix_data;

  server = 0;
  client = 0;
  dst_qpid = 2;

  // systolic MM variables
  size_t matrix_size = DATA_SIZE * DATA_SIZE;
  uint32_t source_hw_results[matrix_size];
  int source_in1[matrix_size];
  int source_in2[matrix_size];
  int source_sw_results[matrix_size];

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
      //payload_size = (uint32_t) atoi(optarg);
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
  //sq_psn = 0xabc;

  fprintf(stderr, "Info: OPEN DEVICE FILE\n");
  // Open the character device, reconic-mm, for data communication between host and device memory
  fpga_fd = open(device, O_RDWR);
  if (fpga_fd < 0) {
    fprintf(stderr, "unable to open device %s, %d.\n", device, fpga_fd);
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

  fprintf(stderr, "Info: generating matrix data, matrix_size = %ld\n", matrix_size);
  matrix_data = (uint32_t* ) malloc(matrix_size * sizeof(uint32_t));
  if(matrix_data != NULL)
  {
  for (uint32_t i = 0; i < matrix_size; i++) {
      matrix_data[i] = i % 10;
    }
  fprintf(stderr, "Info: Software Matrix Data generated\n");
  }
  else {
    fprintf(stderr, "Error: matrix_data Memory allocation failed\n");
  }

  if(client) {
    memset(&server_addr, '\0', sizeof(struct sockaddr_in));
    server_addr.sin_family = AF_INET;
    server_addr.sin_port   = htons(tcp_sport);
    server_addr.sin_addr.s_addr = inet_addr(dst_ip_str);

    fprintf(stderr, "Info: Client is connecting to a remote server\n");
    connect(sockfd, (struct sockaddr* )&server_addr, sizeof(server_addr));

    fprintf(stderr, "Info: Client is connected to a remote server\n");

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

    wqe_idx   = 0;
    wrid      = 0;
    transfer_size = matrix_size * 4;

    fprintf(stderr, "Info: creating an RDMA read WQE for getting Array A\n");

    device_bufferA = allocate_rdma_buffer(rn_dev, (uint64_t) transfer_size, "dev_mem");
    device_bufferB = allocate_rdma_buffer(rn_dev, (uint64_t) transfer_size, "dev_mem");
    device_bufferC = allocate_rdma_buffer(rn_dev, (uint64_t) transfer_size, "dev_mem");

    clock_gettime(CLOCK_MONOTONIC, &ts_start);

    create_a_wqe(rn_dev->rdma_dev, qpid, wrid, wqe_idx, device_bufferA->dma_addr, transfer_size, RNIC_OP_READ, read_A_offset, R_KEY, 0, 0, 0, 0, 0);

    // Post RDMA operation
    ret_val = rdma_post_send(rn_dev->rdma_dev, qpid);
    if(ret_val>=0) {
      fprintf(stderr, "Successfully sent an RDMA read operation for Array A!\n");
    } else {
      fprintf(stderr, "Failed to send an RDMA read operation for Array A!\n");
    }

    wqe_idx++;

    dump_registers(rn_dev->rdma_dev, 1, qpid);

    create_a_wqe(rn_dev->rdma_dev, qpid, wrid, wqe_idx, device_bufferB->dma_addr, transfer_size, RNIC_OP_READ, read_B_offset, R_KEY, 0, 0, 0, 0, 0);

    // Post RDMA operation
    ret_val = rdma_post_send(rn_dev->rdma_dev, qpid);
    if(ret_val>=0) {
      fprintf(stderr, "Successfully sent an RDMA read operation for Array B!\n");
    } else {
      fprintf(stderr, "Failed to send an RDMA read operation for Array B!\n");
    }

    dump_registers(rn_dev->rdma_dev, 1, qpid);

    // Messages are ready, now we can launch the computation kernel
    // Construct control command and issue to the RecoNIC shell
    ctl_cmd_t ctl_cmd;
    gen_ctl_cmd(&ctl_cmd, (uint32_t) device_bufferA->dma_addr, (uint32_t) device_bufferB->dma_addr, (uint32_t) device_bufferC->dma_addr, ctl_cmd_size, a_row, a_col, b_col, work_id);

    // Start FPGA accelerator
    issue_ctl_cmd((void *)rdma_dev->axil_ctl, RN_CLR_CTL_CMD, &ctl_cmd);

    // Polling the status register and get data back

    compute_done = wait_compute((void *)rdma_dev->axil_ctl, RN_CLR_JOB_COMPLETED_NOT_READ);

    fprintf(stderr, "Info: Is Computation finished, compute_done = %d\n", compute_done);

    rc = read_to_buffer(device, fpga_fd, (char*) source_hw_results, matrix_size*4, (uint64_t)device_bufferC->dma_addr);
    fprintf(stderr, "Info: The value of rc is %ld\n",rc);
    if (rc < 0)
        goto out;

    clock_gettime(CLOCK_MONOTONIC, &ts_end);

    /* subtract the start time from the end time */
    timespec_sub(&ts_end, &ts_start);
    total_time = (ts_end.tv_sec + ((double)ts_end.tv_nsec/NSEC_DIV));

    fprintf(stderr, "** Avg time device %s, total time %f sec, size = %d\n",	device, total_time, DATA_SIZE);

    // Compute Software Results
    // Create the test data and Software Result
    for (int i = 0; i < matrix_size; i++) {
      source_in1[i] = i % 10;
      source_in2[i] = i % 10;
      source_sw_results[i] = 0;
    }

    software_mmult(source_in1, source_in2, source_sw_results);

    hw_work_id = read32_data(rdma_dev->axil_ctl, RN_CLR_KER_STS);

    fprintf(stderr, "hw_work_id = 0x%x\n", hw_work_id);

    // Compare the results of the Device to the simulation
    int not_match = 0;
    for (int i = 0; i < DATA_SIZE * DATA_SIZE; i++) {
        if (source_hw_results[i] != source_sw_results[i]) {
            fprintf(stderr, "Error: Result mismatch\n");
            fprintf(stderr, "i = %d,  CPU result = %d\n", i, source_sw_results[i]);
            fprintf(stderr, "Hardware result = %d\n",source_hw_results[i]);
            not_match = 1;
            break;
        }
    }

    if(work_id != hw_work_id) {
      not_match = 1;
    }

    if(not_match) {
      fprintf(stderr, "Test failed!\n");
      rc = -1;
    } else {
      fprintf(stderr, "Test passed!\n");
      rc = 0;
    }
  }

  if(server) {
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

    tmp_buffer = allocate_rdma_buffer(rn_dev, 4096, /*qp_location*/"dev_mem");
    rdma_register_memory_region(rdma_dev, rdma_pd, R_KEY, tmp_buffer);
    fprintf(stderr, "Info: allocating buffer for array A\n");
    mr_bufferA->buffer   = tmp_buffer->buffer;
    mr_bufferA->dma_addr = tmp_buffer->dma_addr;
    fprintf(stderr, "Info: mr_bufferA->buffer = %p, mr_bufferA->dma_addr = 0x%lx\n", (uint64_t *) mr_bufferA->buffer, mr_bufferA->dma_addr);
    fprintf(stderr, "Info: allocating buffer for array B\n");
    mr_bufferB->buffer   = (void *) ((uint64_t) tmp_buffer->buffer + ((uint64_t) (matrix_size << 2)));
    mr_bufferB->dma_addr = tmp_buffer->dma_addr + ((uint64_t) (matrix_size << 2));
    fprintf(stderr, "Info: mr_bufferB->buffer = %p, mr_bufferB->dma_addr = 0x%lx\n", (uint64_t *) mr_bufferB->buffer, mr_bufferB->dma_addr);

    if(is_device_address(tmp_buffer->dma_addr)) {
      // Device memory address
      fprintf(stderr, "Info: copy matrix data to the device memory\n");
      rc1 = write_from_buffer(device, fpga_fd, (char* ) matrix_data, (uint32_t)(matrix_size*4), mr_bufferA->dma_addr);
      rc2 = write_from_buffer(device, fpga_fd, (char* ) matrix_data, (uint32_t)(matrix_size*4), mr_bufferB->dma_addr);
      if (rc1 < 0 || rc2 < 0){
        goto out;
        fprintf(stderr, "Info: copied matrix data to the device memory succesfully\n");
      }
    } else {
      // Host memory address
      fprintf(stderr, "Info: Initialize matrix data on the host memory\n");
      for (size_t i = 0; i < matrix_size; i++) {
        *((uint32_t* )(mr_bufferA->buffer) + i) = i % 10;
        *((uint32_t* )(mr_bufferB->buffer) + i) = i % 10;
    }
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
  free(cidb_buffer);
  free(data_buf);
  free(ipkterr_buf);
  free(err_buf);
  free(resp_err_pkt_buf);
  free(matrix_data);
  close(fpga_fd);
  close(pcie_resource_fd);
  destroy_rn_dev(rn_dev);
  return 0;
}
