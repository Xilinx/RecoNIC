//==============================================================================
// Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
// SPDX-License-Identifier: MIT
//
//==============================================================================

/** @file rdma_api.c
 *  @brief Implementation of user-space RDMA APIs.
 */

#include "rdma_api.h"

struct rdma_dev_t* create_rdma_dev(struct rn_dev_t* rn_dev) {
    int i;
    uint32_t num_qp;
    struct rdma_dev_t* rdma_dev = NULL;
    num_qp = rn_dev->num_qp;

    rdma_dev = (struct rdma_dev_t*) malloc(sizeof(struct rdma_dev_t));
    rdma_dev->glb_csr = (struct rdma_glb_csr_t*) malloc(sizeof(struct rdma_glb_csr_t));
    rdma_dev->qps_ptr = (struct rdma_qp_t**) malloc(num_qp * (sizeof(struct rdma_qp_t*)));
    rdma_dev->axil_ctl = rn_dev->axil_ctl;

    for(i=0; i<num_qp; i++) {
        rdma_dev->qps_ptr[i] = NULL;
    }
    rdma_dev->winSize = rn_dev->winSize;
    rdma_dev->rn_dev = rn_dev;
    rdma_dev->num_qp = rn_dev->num_qp;
    rn_dev->rdma_dev = (void* ) rdma_dev;

    return rdma_dev;
}

void open_rdma_dev(struct rdma_dev_t* rdma_dev, struct mac_addr_t local_mac, 
                   uint32_t local_ip, uint32_t udp_sport, uint16_t num_data_buf, 
                   uint16_t per_data_buf_size, uint64_t data_buf_baseaddr,
                   uint16_t ipkt_err_stat_q_size, uint64_t ipkt_err_stat_q_baseaddr,
                   uint16_t num_err_buf, uint16_t per_err_buf_size, 
                   uint64_t err_buf_baseaddr, uint64_t resp_err_pkt_buf_size, 
                   uint64_t resp_err_pkt_buf_baseaddr) {
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
  uint32_t interrupt_enable = 0x000000FF;
  uint32_t data_buf_size = 0;
  uint32_t err_buf_size = 0;

  struct rdma_glb_csr_t* rdma_global_config = rdma_dev->glb_csr;

  data_buf_size = (((uint32_t) per_data_buf_size)<<16) | ((uint32_t) num_data_buf);
  err_buf_size  = (((uint32_t) per_err_buf_size)<<16) | ((uint32_t) num_err_buf);
  rdma_global_config->data_buf_size              = data_buf_size;
  rdma_global_config->data_buf_baseaddr          = data_buf_baseaddr;
  rdma_global_config->ipkt_err_stat_q_size       = ipkt_err_stat_q_size;
  rdma_global_config->ipkt_err_stat_q_baseaddr   = ipkt_err_stat_q_baseaddr;
  rdma_global_config->err_buf_size               = err_buf_size;
  rdma_global_config->err_buf_baseaddr           = err_buf_baseaddr;
  rdma_global_config->resp_err_pkt_buf_size      = resp_err_pkt_buf_size;
  rdma_global_config->resp_err_pkt_buf_baseaddr  = resp_err_pkt_buf_baseaddr;
  
  rdma_global_config->interrupt_enable = interrupt_enable;
  rdma_global_config->src_mac.mac_lsb  = local_mac.mac_lsb;
  rdma_global_config->src_mac.mac_msb  = local_mac.mac_msb;
  rdma_global_config->src_ip           = local_ip;
  rdma_global_config->udp_sport        = (uint16_t) udp_sport;
  rdma_global_config->num_qp_enabled   = rdma_dev->num_qp;

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
  num_qp = (uint32_t) rdma_dev->num_qp;
  config_8bit = ((reserved1<<6) & 0x000000c0) | ((err_buf_en<<5) & 0x00000020) | ((tx_ack_gen<<3) & 0x00000018) | ((reserved2<<1) & 0x00000006) | (en_ernic & 0x00000001);
  xrnic_conf = ((udp_sport<<16) & 0xffff0000) | ((num_qp<<8) & 0x0000ff00) | (config_8bit & 0x000000ff);
  rdma_global_config->xrnic_conf = xrnic_conf;

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
  // --          For 250 MHz clock --> Program decimal 10
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
  rdma_global_config->xrnic_advanced_conf = xrnic_advanced_conf;

  config_rdma_global_csr(rdma_dev);
  fprintf(stderr, "Info: rdma_dev opened\n");
}

void config_rdma_global_csr (struct rdma_dev_t* rdma_dev) {
  uint32_t data_buf_baseaddr_lsb;
  uint32_t data_buf_baseaddr_msb;
  uint32_t ipkt_err_stat_q_size;
  uint32_t ipkt_err_stat_q_baseaddr_lsb;
  uint32_t ipkt_err_stat_q_baseaddr_msb;
  uint32_t err_buf_baseaddr_lsb;
  uint32_t err_buf_baseaddr_msb;
  uint32_t resp_err_pkt_buf_baseaddr_lsb;
  uint32_t resp_err_pkt_buf_baseaddr_msb;
  uint32_t resp_err_pkt_buf_size_lsb;
  uint32_t resp_err_pkt_buf_size_msb;

  struct rdma_glb_csr_t* global_csr = rdma_dev->glb_csr;
  uint32_t win_size_low  = rdma_dev->winSize->win_size_lsb;
  uint32_t win_size_high = rdma_dev->winSize->win_size_msb;

  if(is_device_address(global_csr->data_buf_baseaddr)) {
    // Device memory address
    data_buf_baseaddr_lsb = ((uint32_t) ((global_csr->data_buf_baseaddr) & 0x00000000ffffffff));
    data_buf_baseaddr_msb = ((uint32_t) ((global_csr->data_buf_baseaddr >> 32) & 0x00000000ffffffff));
  } else {
    // Host memory address
    data_buf_baseaddr_lsb = ((uint32_t) ((global_csr->data_buf_baseaddr) & 0x00000000ffffffff)) & win_size_low;
    data_buf_baseaddr_msb = ((uint32_t) ((global_csr->data_buf_baseaddr >> 32) & 0x00000000ffffffff)) & win_size_high;
  }

  ipkt_err_stat_q_size = (uint32_t) global_csr->ipkt_err_stat_q_size;
  if(is_device_address(global_csr->ipkt_err_stat_q_baseaddr)) {
    // Device memory address
    ipkt_err_stat_q_baseaddr_lsb = ((uint32_t) ((global_csr->ipkt_err_stat_q_baseaddr) & 0x00000000ffffffff));
    ipkt_err_stat_q_baseaddr_msb = ((uint32_t) ((global_csr->ipkt_err_stat_q_baseaddr >> 32) & 0x00000000ffffffff));
  } else {
    // Host memory address
    ipkt_err_stat_q_baseaddr_lsb = ((uint32_t) ((global_csr->ipkt_err_stat_q_baseaddr) & 0x00000000ffffffff)) & win_size_low;
    ipkt_err_stat_q_baseaddr_msb = ((uint32_t) ((global_csr->ipkt_err_stat_q_baseaddr >> 32) & 0x00000000ffffffff)) & win_size_high;
  }

  if(is_device_address(global_csr->err_buf_baseaddr)) {
    // Device memory address
    err_buf_baseaddr_lsb = ((uint32_t) ((global_csr->err_buf_baseaddr) & 0x00000000ffffffff));
    err_buf_baseaddr_msb = ((uint32_t) ((global_csr->err_buf_baseaddr >> 32) & 0x00000000ffffffff));
  } else {
    // Host memory address
    err_buf_baseaddr_lsb = ((uint32_t) ((global_csr->err_buf_baseaddr) & 0x00000000ffffffff)) & win_size_low;
    err_buf_baseaddr_msb = ((uint32_t) ((global_csr->err_buf_baseaddr >> 32) & 0x00000000ffffffff)) & win_size_high;
  }

  if(is_device_address(global_csr->resp_err_pkt_buf_baseaddr)) {
    // Device memory address
    resp_err_pkt_buf_baseaddr_lsb = ((uint32_t) ((global_csr->resp_err_pkt_buf_baseaddr) & 0x00000000ffffffff));
    resp_err_pkt_buf_baseaddr_msb = ((uint32_t) ((global_csr->resp_err_pkt_buf_baseaddr >> 32) & 0x00000000ffffffff));
  } else {
    // Host memory address
    resp_err_pkt_buf_baseaddr_lsb = ((uint32_t) ((global_csr->resp_err_pkt_buf_baseaddr) & 0x00000000ffffffff)) & win_size_low;
    resp_err_pkt_buf_baseaddr_msb = ((uint32_t) ((global_csr->resp_err_pkt_buf_baseaddr >> 32) & 0x00000000ffffffff)) & win_size_high;
  }
  resp_err_pkt_buf_size_lsb = ((uint32_t) ((global_csr->resp_err_pkt_buf_size) & 0x00000000ffffffff));;
  resp_err_pkt_buf_size_msb = ((uint32_t) ((global_csr->resp_err_pkt_buf_size >> 32) & 0x00000000ffffffff));;

  write32_data(rdma_dev->axil_ctl, RN_RDMA_GCSR_DATBUFBA, data_buf_baseaddr_lsb);
  Debug("[Register] RN_RDMA_GCSR_DATBUFBA=0x%x, value=0x%x\n", RN_RDMA_GCSR_DATBUFBA, data_buf_baseaddr_lsb);
  write32_data(rdma_dev->axil_ctl, RN_RDMA_GCSR_DATBUFBAMSB, data_buf_baseaddr_msb);
  Debug("[Register] RN_RDMA_GCSR_DATBUFBAMSB=0x%x, value=0x%x\n", RN_RDMA_GCSR_DATBUFBAMSB, data_buf_baseaddr_msb);
  write32_data(rdma_dev->axil_ctl, RN_RDMA_GCSR_DATBUFSZ, global_csr->data_buf_size);
  Debug("[Register] RN_RDMA_GCSR_DATBUFSZ=0x%x, value=0x%x\n", RN_RDMA_GCSR_DATBUFSZ, global_csr->data_buf_size);

  write32_data(rdma_dev->axil_ctl, RN_RDMA_GCSR_IPKTERRQBA, ipkt_err_stat_q_baseaddr_lsb);
  Debug("[Register] RN_RDMA_GCSR_IPKTERRQBA=0x%x, value=0x%x\n", RN_RDMA_GCSR_IPKTERRQBA, ipkt_err_stat_q_baseaddr_lsb);
  write32_data(rdma_dev->axil_ctl, RN_RDMA_GCSR_IPKTERRQBAMSB, ipkt_err_stat_q_baseaddr_msb);
  Debug("[Register] RN_RDMA_GCSR_IPKTERRQBAMSB=0x%x, value=0x%x\n", RN_RDMA_GCSR_IPKTERRQBAMSB, ipkt_err_stat_q_baseaddr_msb);
  write32_data(rdma_dev->axil_ctl, RN_RDMA_GCSR_IPKTERRQSZ, ipkt_err_stat_q_size);
  Debug("[Register] RN_RDMA_GCSR_ERRBUFSZ=0x%x, value=0x%x\n", RN_RDMA_GCSR_IPKTERRQSZ, ipkt_err_stat_q_size);

  write32_data(rdma_dev->axil_ctl, RN_RDMA_GCSR_ERRBUFBA, err_buf_baseaddr_lsb);
  Debug("[Register] RN_RDMA_GCSR_ERRBUFBA=0x%x, value=0x%x\n", RN_RDMA_GCSR_ERRBUFBA, err_buf_baseaddr_lsb);
  write32_data(rdma_dev->axil_ctl, RN_RDMA_GCSR_ERRBUFBAMSB, err_buf_baseaddr_msb);
  Debug("[Register] RN_RDMA_GCSR_ERRBUFBAMSB=0x%x, value=0x%x\n", RN_RDMA_GCSR_ERRBUFBAMSB, err_buf_baseaddr_msb);
  write32_data(rdma_dev->axil_ctl, RN_RDMA_GCSR_ERRBUFSZ, global_csr->err_buf_size);
  Debug("[Register] RN_RDMA_GCSR_ERRBUFSZ=0x%x, value=0x%x\n", RN_RDMA_GCSR_ERRBUFSZ, global_csr->err_buf_size);

  write32_data(rdma_dev->axil_ctl, RN_RDMA_GCSR_RESPERRPKTBA, resp_err_pkt_buf_baseaddr_lsb);
  Debug("[Register] RN_RDMA_GCSR_RESPERRPKTBA=0x%x, value=0x%x\n", RN_RDMA_GCSR_RESPERRPKTBA, resp_err_pkt_buf_baseaddr_lsb);
  write32_data(rdma_dev->axil_ctl, RN_RDMA_GCSR_RESPERRPKTBAMSB, resp_err_pkt_buf_baseaddr_msb);
  Debug("[Register] RN_RDMA_GCSR_RESPERRPKTBAMSB=0x%x, value=0x%x\n", RN_RDMA_GCSR_RESPERRPKTBAMSB, resp_err_pkt_buf_baseaddr_msb);
  write32_data(rdma_dev->axil_ctl, RN_RDMA_GCSR_RESPERRSZ, resp_err_pkt_buf_size_lsb);
  Debug("[Register] RN_RDMA_GCSR_RESPERRSZ=0x%x, value=0x%x\n", RN_RDMA_GCSR_RESPERRSZ, resp_err_pkt_buf_size_lsb);
  write32_data(rdma_dev->axil_ctl, RN_RDMA_GCSR_RESPERRSZMSB, resp_err_pkt_buf_size_msb);
  Debug("[Register] RN_RDMA_GCSR_RESPERRSZMSB=0x%x, value=0x%x\n", RN_RDMA_GCSR_RESPERRSZMSB, resp_err_pkt_buf_size_msb);

  // configure interrupt - enable all interrupt except for CNP scheduling
  write32_data(rdma_dev->axil_ctl, RN_RDMA_GCSR_INTEN, global_csr->interrupt_enable);
  Debug("[Register] RN_RDMA_GCSR_INTEN=0x%x, value=0x%x\n", RN_RDMA_GCSR_INTEN, global_csr->interrupt_enable);

  // configure local MAC address
  write32_data(rdma_dev->axil_ctl, RN_RDMA_GCSR_MACXADDLSB, global_csr->src_mac.mac_lsb);
  Debug("[Register] RN_RDMA_GCSR_MACXADDLSB=0x%x, value=0x%x\n", RN_RDMA_GCSR_MACXADDLSB, global_csr->src_mac.mac_lsb);
  write32_data(rdma_dev->axil_ctl, RN_RDMA_GCSR_MACXADDMSB, global_csr->src_mac.mac_msb);
  Debug("[Register] RN_RDMA_GCSR_MACXADDMSB=0x%x, value=0x%x\n", RN_RDMA_GCSR_MACXADDMSB, global_csr->src_mac.mac_msb);

  // configure local IPv4 address
  write32_data(rdma_dev->axil_ctl, RN_RDMA_GCSR_IPV4XADD, global_csr->src_ip);
  Debug("[Register] RN_RDMA_GCSR_IPV4XADD=0x%x, value=0x%x\n", RN_RDMA_GCSR_IPV4XADD, global_csr->src_ip);

  write32_data(rdma_dev->axil_ctl, RN_RDMA_GCSR_XRNICCONF, global_csr->xrnic_conf);
  Debug("[Register] RN_RDMA_GCSR_XRNICCONF=0x%x, value=0x%x\n", RN_RDMA_GCSR_XRNICCONF, global_csr->xrnic_conf);

  write32_data(rdma_dev->axil_ctl, RN_RDMA_GCSR_XRNICADCONF, global_csr->xrnic_advanced_conf);
  Debug("[Register] RN_RDMA_GCSR_XRNICADCONF=0x%x, value=0x%x\n", RN_RDMA_GCSR_XRNICADCONF, global_csr->xrnic_advanced_conf);

  fprintf(stderr, "Info: RDMA global control status registers are configured.\n");
}

uint32_t get_rdma_per_q_config_addr(uint32_t offset, uint32_t qpid) {
  return offset + 0x100 * (qpid-1);
}

uint32_t get_rdma_pd_config_addr(uint32_t offset, uint32_t pd_num) {
  return offset + 0x100 * pd_num;
}

struct rdma_pd_t* allocate_rdma_pd(struct rdma_dev_t* rdma_dev, uint32_t pd_num) {
  struct rdma_pd_t* rdma_pd = NULL;

  if(rdma_dev != NULL) {
    rdma_pd = (struct rdma_pd_t* ) malloc(sizeof(struct rdma_pd_t));
    rdma_pd->pd_num = pd_num;
    rdma_pd->pd_access_type = 2 & 0x0000ffff;
    write32_data(rdma_dev->axil_ctl, get_rdma_pd_config_addr(RN_RDMA_PDT_PDPDNUM, pd_num), pd_num);
    Debug("[Register] RN_RDMA_PDT_PDPDNUM=0x%x, pd_num=%d, value=0x%x\n", get_rdma_pd_config_addr(RN_RDMA_PDT_PDPDNUM, pd_num), pd_num, pd_num);

    //rdma_pd->mr_buffer = (struct rdma_buff_t*) malloc(sizeof(struct rdma_buff_t));
    rdma_pd->mr_buffer = NULL;
  }else{
    fprintf(stderr, "Error: rdma_dev is empty\n");
    exit(EXIT_FAILURE);
  }

  return rdma_pd;
}

void rdma_register_memory_region(struct rdma_dev_t* rdma_dev, struct rdma_pd_t* rdma_pd, uint32_t r_key, struct rdma_buff_t* rdma_buf) {
  uint32_t pd_num;
  uint64_t buffer_size;
  uint32_t access_config;

  uint32_t win_size_low  = rdma_dev->winSize->win_size_lsb;
  uint32_t win_size_high = rdma_dev->winSize->win_size_msb;

  fprintf(stderr, "Info: rdma_register_memory_region - registering memory region\n");
  if(rdma_dev == NULL) {
    fprintf(stderr, "Error: rdma_dev is NULL\n");
    exit(EXIT_FAILURE);    
  }

  if(rdma_pd == NULL) {
    fprintf(stderr, "Error: rdma_pd is NULL\n");
    exit(EXIT_FAILURE);
  }

  if(rdma_buf == NULL) {
    fprintf(stderr, "Error: rdma_buf is NULL\n");
    exit(EXIT_FAILURE);
  }

  rdma_pd->mr_buffer = rdma_buf;
  if(is_device_address(rdma_buf->dma_addr)) {
    // Buffer in device memory
    rdma_pd->dma_addr_lsb = (uint32_t) (rdma_pd->mr_buffer->dma_addr & 0x00000000ffffffff);
    rdma_pd->dma_addr_msb = (uint32_t) ((rdma_pd->mr_buffer->dma_addr >> 32) & 0x00000000ffffffff);
  } else {
    // Buffer in host memory
    rdma_pd->dma_addr_lsb = (uint32_t) (rdma_pd->mr_buffer->dma_addr & 0x00000000ffffffff & win_size_low);
    rdma_pd->dma_addr_msb = (uint32_t) ((rdma_pd->mr_buffer->dma_addr >> 32) & 0x00000000ffffffff & win_size_high);
  }
  buffer_size = (uint64_t) rdma_pd->mr_buffer->buf_size;

  // Configure protection domain entry
  pd_num = rdma_pd->pd_num;
  rdma_pd->virtual_addr_lsb = (uint32_t)(((uint64_t) rdma_pd->mr_buffer->buffer) & 0x00000000ffffffff);
  rdma_pd->virtual_addr_msb = (uint32_t)((((uint64_t) rdma_pd->mr_buffer->buffer)>>32) & 0x00000000ffffffff);
  rdma_pd->buffer_size_lsb = (uint32_t) (buffer_size & 0x00000000ffffffff);
  rdma_pd->buffer_size_msb = (uint32_t) ((buffer_size>>32) & 0x00000000ffffffff);
  rdma_pd->r_key = r_key;

  if(rdma_dev->axil_ctl == 0) {
    fprintf(stderr, "Error: rdma_dev->axil_ctl=0x%lx is not valid!\n", (uint64_t) rdma_dev->axil_ctl);
    exit(EXIT_FAILURE);
  }

  write32_data(rdma_dev->axil_ctl, get_rdma_pd_config_addr(RN_RDMA_PDT_VIRTADDRLSB, pd_num), rdma_pd->virtual_addr_lsb);
  Debug("[Register] RN_RDMA_PDT_VIRTADDRLSB=0x%x, pd_num=%d, value=0x%x\n", get_rdma_pd_config_addr(RN_RDMA_PDT_VIRTADDRLSB, pd_num), pd_num, rdma_pd->virtual_addr_lsb);
  write32_data(rdma_dev->axil_ctl, get_rdma_pd_config_addr(RN_RDMA_PDT_VIRTADDRMSB, pd_num), rdma_pd->virtual_addr_msb);
  Debug("[Register] RN_RDMA_PDT_VIRTADDRMSB=0x%x, pd_num=%d, value=0x%x\n", get_rdma_pd_config_addr(RN_RDMA_PDT_VIRTADDRMSB, pd_num), pd_num, rdma_pd->virtual_addr_msb);
  write32_data(rdma_dev->axil_ctl, get_rdma_pd_config_addr(RN_RDMA_PDT_BUFBASEADDRLSB, pd_num), rdma_pd->dma_addr_lsb);
  Debug("[Register] RN_RDMA_PDT_BUFBASEADDRLSB=0x%x, pd_num=%d, value=0x%x\n", get_rdma_pd_config_addr(RN_RDMA_PDT_BUFBASEADDRLSB, pd_num), pd_num, rdma_pd->dma_addr_lsb);
  write32_data(rdma_dev->axil_ctl, get_rdma_pd_config_addr(RN_RDMA_PDT_BUFBASEADDRMSB, pd_num), rdma_pd->dma_addr_msb);
  Debug("[Register] RN_RDMA_PDT_BUFBASEADDRMSB=0x%x, pd_num=%d, value=0x%x\n", get_rdma_pd_config_addr(RN_RDMA_PDT_BUFBASEADDRMSB, pd_num), pd_num, rdma_pd->dma_addr_msb);
  write32_data(rdma_dev->axil_ctl, get_rdma_pd_config_addr(RN_RDMA_PDT_BUFRKEY, pd_num), r_key);
  Debug("[Register] RN_RDMA_PDT_BUFRKEY=0x%x, pd_num=%d, value=0x%x\n", get_rdma_pd_config_addr(RN_RDMA_PDT_BUFRKEY, pd_num), pd_num, r_key);

  write32_data(rdma_dev->axil_ctl, get_rdma_pd_config_addr(RN_RDMA_PDT_WRRDBUFLEN, pd_num), buffer_size);
  Debug("[Register] RN_RDMA_PDT_WRRDBUFLEN=0x%x, pd_num=%d, value=0x%lx B\n", get_rdma_pd_config_addr(RN_RDMA_PDT_WRRDBUFLEN, pd_num), pd_num, buffer_size);
  access_config = ((rdma_pd->buffer_size_msb<<16) | rdma_pd->pd_access_type);
  write32_data(rdma_dev->axil_ctl, get_rdma_pd_config_addr(RN_RDMA_PDT_ACCESSDESC, pd_num), access_config);
  Debug("[Register] RN_RDMA_PDT_ACCESSDESC=0x%x, pd_num=%d, value=0x%x\n", get_rdma_pd_config_addr(RN_RDMA_PDT_ACCESSDESC, pd_num), pd_num, access_config);

  fprintf(stderr, "Info: memory region for the %d-th PD is registered\n", pd_num);
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

void config_last_rq_psn(struct rdma_dev_t* rdma_dev, uint32_t qpid, uint32_t last_rq_psn)
{              
  uint32_t rq_opcode = 0x0000000a; // Just a random op-code to avoid opcode sequence error
  uint32_t rq_conf = ((rq_opcode<<24) & 0xff000000) | (last_rq_psn & 0x00ffffff);

  write32_data(rdma_dev->axil_ctl, 
              get_rdma_per_q_config_addr(RN_RDMA_QCSR_LSTRQREQi, qpid), 
              rq_conf);
  fprintf(stderr, "[Register] RN_RDMA_QCSR_LSTRQREQi=0x%x, qpid=%d, value=0x%x\n", 
                    get_rdma_per_q_config_addr(RN_RDMA_QCSR_LSTRQREQi, qpid), 
                    qpid, 
                    rq_conf);
  rdma_dev->qps_ptr[qpid]->last_rq_psn = last_rq_psn;
}

void config_sq_psn(struct rdma_dev_t* rdma_dev, uint32_t qpid, uint32_t sq_psn){
  write32_data(rdma_dev->axil_ctl, 
              get_rdma_per_q_config_addr(RN_RDMA_QCSR_SQPSNi, qpid), 
              sq_psn);
  fprintf(stderr, "[Register] RN_RDMA_QCSR_SQPSNi=0x%x, qpid=%d, value=0x%x\n", 
                  get_rdma_per_q_config_addr(RN_RDMA_QCSR_SQPSNi, qpid), 
                  qpid, 
                  sq_psn);
  rdma_dev->qps_ptr[qpid]->sq_psn = sq_psn;
}

struct rdma_qp_t* allocate_rdma_qp(struct rdma_dev_t* rdma_dev,
                                   uint32_t qpid,
                                   uint32_t dst_qpid,
                                   struct rdma_pd_t* pd_entry,
                                   uint64_t cq_cidb_addr,
                                   uint64_t rq_cidb_addr,
                                   uint32_t qdepth,
                                   char*    buf_location,
                                   struct mac_addr_t* dst_mac,
                                   uint32_t dst_ip,
                                   uint32_t partion_key,
                                   uint32_t r_key) {
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
  struct rdma_qp_t* qp;
  uint32_t mtu_config;
  uint32_t en_qp;
  //uint32_t ip_proto;
  uint32_t qp_config;
  uint32_t traffic_class;
  uint32_t time_to_live;
  uint32_t qp_adv_conf;
  uint32_t rq_buffer_entry_size;
  uint32_t cq_size;
  uint32_t rq_size;
  uint32_t sq_size;
  uint32_t win_size_low  = rdma_dev->winSize->win_size_lsb;
  uint32_t win_size_high = rdma_dev->winSize->win_size_msb;

  qp = (struct rdma_qp_t* ) malloc(sizeof(struct rdma_qp_t));
  qp->rdma_dev = rdma_dev;
  qp->qpid = qpid;
  qp->dst_qpid = dst_qpid;
  fprintf(stderr, "Allocating qp->sq\n");
  // Each WQE has 64 bytes
  sq_size = rdma_dev->num_qp * qdepth * 64;
  cq_size = rdma_dev->num_qp * qdepth * 4;
  rq_size = rdma_dev->num_qp * qdepth * RQE_SIZE;

  Debug("sq_size = %d, cq_size = %d, rq_size %d, buf_location = %s\n", sq_size, cq_size, rq_size, buf_location);
  qp->sq = allocate_rdma_buffer(rdma_dev->rn_dev, (uint64_t) sq_size, buf_location);
  qp->sq_pidb = 0;
  qp->sq_cidb = 0;

  fprintf(stderr, "Allocating qp->cq\n");
  // Each CQE has 4 bytes
  qp->cq = allocate_rdma_buffer(rdma_dev->rn_dev, (uint64_t) cq_size, buf_location);
  qp->cq_cidb = 0;

  if(is_device_address(cq_cidb_addr)) {
    // Device memory address
    cq_cidb_addr_lsb = ((uint32_t) ((cq_cidb_addr) & 0x00000000ffffffff));
    cq_cidb_addr_msb = ((uint32_t) ((cq_cidb_addr >> 32) & 0x00000000ffffffff));
  } else {
    // Host memory address
    cq_cidb_addr_lsb = ((uint32_t) ((cq_cidb_addr) & 0x00000000ffffffff)) & win_size_low;
    cq_cidb_addr_msb = ((uint32_t) ((cq_cidb_addr >> 32) & 0x00000000ffffffff)) & win_size_high;
  }

  qp->cq_cidb_addr = cq_cidb_addr;
  fprintf(stderr, "Allocating qp->rq\n");

  // Each RQE is 256B
  qp->rq = allocate_rdma_buffer(rdma_dev->rn_dev, (uint64_t) rq_size, buf_location);
  //rdma_register_memory_region(rdma_dev, pd_entry, r_key, qp->rq);
  qp->rq_cidb = 0;
  qp->rq_pidb = 0;

  if(is_device_address(rq_cidb_addr)) {
    // Device memory address
    rq_cidb_addr_lsb = ((uint32_t) ((rq_cidb_addr) & 0x00000000ffffffff));
    rq_cidb_addr_msb = ((uint32_t) ((rq_cidb_addr >> 32) & 0x00000000ffffffff));
  } else {
    // Host memory address
    rq_cidb_addr_lsb = ((uint32_t) ((rq_cidb_addr) & 0x00000000ffffffff)) & win_size_low;
    rq_cidb_addr_msb = ((uint32_t) ((rq_cidb_addr >> 32) & 0x00000000ffffffff)) & win_size_high;
  }
  qp->rq_cidb_addr = rq_cidb_addr;
  
  qp->pd_entry = pd_entry;
  
  qp->qdepth   = qdepth;
  qp->dst_mac = dst_mac;
  qp->dst_ip  = dst_ip;
  rdma_dev->qps_ptr[qpid] = qp;

  fprintf(stderr, "Info: queue pair setting is done! Configuring RDMA per-queu CSR registers\n");
  Debug("DEBUG: rdma_dev->rn_dev->axil_ctl = 0x%lx, rdma_dev->axil_ctl = 0x%lx\n", 
                  (uint64_t) rdma_dev->rn_dev->axil_ctl, 
                  (uint64_t) rdma_dev->axil_ctl);

  if(rdma_dev->axil_ctl == 0) {
    fprintf(stderr, "Error: rdma_dev->axil_ctl=0x%lx is not valid!\n", 
                    (uint64_t) rdma_dev->axil_ctl);
    exit(EXIT_FAILURE);
  }

  // Configure RDMA per-queue CSR registers
  write32_data(rdma_dev->axil_ctl, 
              get_rdma_per_q_config_addr(RN_RDMA_QCSR_IPDESADDR1i, qpid), 
              dst_ip);
  Debug("[Register] RN_RDMA_QCSR_IPDESADDR1i=0x%x, qpid=%d, value=0x%x\n", 
                    get_rdma_per_q_config_addr(RN_RDMA_QCSR_IPDESADDR1i, qpid),  
                    qpid, 
                    dst_ip);
  write32_data(rdma_dev->axil_ctl, 
                get_rdma_per_q_config_addr(RN_RDMA_QCSR_MACDESADDLSBi, qpid), 
                dst_mac->mac_lsb);
  Debug("[Register] RN_RDMA_QCSR_MACDESADDLSBi=0x%x, qpid=%d, value=0x%x\n", 
                    get_rdma_per_q_config_addr(RN_RDMA_QCSR_MACDESADDLSBi, qpid), 
                    qpid, 
                    dst_mac->mac_lsb);
  write32_data(rdma_dev->axil_ctl, 
              get_rdma_per_q_config_addr(RN_RDMA_QCSR_MACDESADDMSBi, qpid), 
              dst_mac->mac_msb);
  Debug("[Register] RN_RDMA_QCSR_MACDESADDMSBi=0x%x, qpid=%d, value=0x%x\n", 
                    get_rdma_per_q_config_addr(RN_RDMA_QCSR_MACDESADDMSBi, qpid), 
                    qpid, 
                    dst_mac->mac_msb);
  
  // Mask the physical address of sq, rq and cq
  Debug("DEBUG: win_size_high = 0x%x, win_size_low = 0x%x\n", 
                  win_size_high, 
                  win_size_low);

  if(is_device_address(qp->sq->dma_addr)) {
    // Device memory address
    sq_addr_lsb = ((uint32_t) ((qp->sq->dma_addr) & 0x00000000ffffffff));
    sq_addr_msb = ((uint32_t) ((qp->sq->dma_addr >> 32) & 0x00000000ffffffff));
  } else {
    // Host memory address
    sq_addr_lsb = ((uint32_t) ((qp->sq->dma_addr) & 0x00000000ffffffff)) & win_size_low;
    sq_addr_msb = ((uint32_t) ((qp->sq->dma_addr >> 32) & 0x00000000ffffffff)) & win_size_high;
  }

  write32_data(rdma_dev->axil_ctl, 
                get_rdma_per_q_config_addr(RN_RDMA_QCSR_SQBAi, qpid),  
                sq_addr_lsb);
  Debug("[Register] RN_RDMA_QCSR_SQBAi=0x%x, qpid=%d, value=0x%x\n", 
                  get_rdma_per_q_config_addr(RN_RDMA_QCSR_SQBAi, qpid), 
                  qpid, 
                  sq_addr_lsb);
  write32_data(rdma_dev->axil_ctl, 
                get_rdma_per_q_config_addr(RN_RDMA_QCSR_SQBAMSBi, qpid), 
                sq_addr_msb);
  Debug("[Register] RN_RDMA_QCSR_SQBAMSBi=0x%x, qpid=%d, value=0x%x\n", 
                  get_rdma_per_q_config_addr(RN_RDMA_QCSR_SQBAMSBi, qpid), 
                  qpid, 
                  sq_addr_msb);
  Debug("DEBUG: qp->sq->dma_addr = 0x%lx, sq_addr_msb = 0x%x, sq_addr_lsb = 0x%x\n", 
                  qp->sq->dma_addr, 
                  sq_addr_msb, 
                  sq_addr_lsb);

  if(is_device_address(qp->cq->dma_addr)) {
    // Device memory address
    cq_addr_lsb = ((uint32_t) ((qp->cq->dma_addr) & 0x00000000ffffffff));
    cq_addr_msb = ((uint32_t) ((qp->cq->dma_addr >> 32) & 0x00000000ffffffff));
  } else {
    // Host memory address
    cq_addr_lsb = ((uint32_t) ((qp->cq->dma_addr) & 0x00000000ffffffff)) & win_size_low;
    cq_addr_msb = ((uint32_t) ((qp->cq->dma_addr >> 32) & 0x00000000ffffffff)) & win_size_high;
  }

  write32_data(rdma_dev->axil_ctl, 
              get_rdma_per_q_config_addr(RN_RDMA_QCSR_CQBAi, qpid), 
              cq_addr_lsb);
  Debug("[Register] RN_RDMA_QCSR_CQBAi=0x%x, qpid=%d, value=0x%x\n", 
                  get_rdma_per_q_config_addr(RN_RDMA_QCSR_CQBAi, qpid), 
                  qpid, 
                  cq_addr_lsb);
  write32_data(rdma_dev->axil_ctl, 
                get_rdma_per_q_config_addr(RN_RDMA_QCSR_CQBAMSBi, qpid), 
                cq_addr_msb);
  Debug("[Register] RN_RDMA_QCSR_CQBAMSBi=0x%x, qpid=%d, value=0x%x\n", 
                    get_rdma_per_q_config_addr(RN_RDMA_QCSR_CQBAMSBi, qpid), 
                    qpid, 
                    cq_addr_msb);
  Debug("DEBUG: qp->cq->dma_addr = 0x%lx, cq_addr_msb = 0x%x, cq_addr_lsb = 0x%x\n", 
                  qp->cq->dma_addr, 
                  cq_addr_msb, 
                  cq_addr_lsb);

  if(is_device_address(qp->rq->dma_addr)) {
    // Device memory address
    rq_addr_lsb = ((uint32_t) ((qp->rq->dma_addr) & 0x00000000ffffffff));
    rq_addr_msb = ((uint32_t) ((qp->rq->dma_addr >> 32) & 0x00000000ffffffff));
  } else {
    // Host memory address
    rq_addr_lsb = ((uint32_t) ((qp->rq->dma_addr) & 0x00000000ffffffff)) & win_size_low;
    rq_addr_msb = ((uint32_t) ((qp->rq->dma_addr >> 32) & 0x00000000ffffffff)) & win_size_high;
  }

  write32_data(rdma_dev->axil_ctl, 
                get_rdma_per_q_config_addr(RN_RDMA_QCSR_RQBAi, qpid), 
                rq_addr_lsb);
  Debug("[Register] RN_RDMA_QCSR_RQBAi=0x%x, qpid=%d, value=0x%x\n", 
                    get_rdma_per_q_config_addr(RN_RDMA_QCSR_RQBAi, qpid), 
                    qpid, 
                    rq_addr_lsb);
  write32_data(rdma_dev->axil_ctl, 
                get_rdma_per_q_config_addr(RN_RDMA_QCSR_RQBAMSBi, qpid), 
                rq_addr_msb);
  Debug("[Register] RN_RDMA_QCSR_RQBAMSBi=0x%x, qpid=%d, value=0x%x\n", 
                    get_rdma_per_q_config_addr(RN_RDMA_QCSR_RQBAMSBi, qpid), 
                    qpid, 
                    rq_addr_msb);
  Debug("DEBUG: qp->rq->dma_addr = 0x%lx, rq_addr_msb = 0x%x, rq_addr_lsb = 0x%x\n",
                    qp->rq->dma_addr, 
                    rq_addr_msb, 
                    rq_addr_lsb);

  // CQ DB address
  write32_data(rdma_dev->axil_ctl, 
              get_rdma_per_q_config_addr(RN_RDMA_QCSR_CQDBADDi, qpid), 
              cq_cidb_addr_lsb);
  Debug("[Register] RN_RDMA_QCSR_CQDBADDi=0x%x, qpid=%d, value=0x%x\n", 
                    get_rdma_per_q_config_addr(RN_RDMA_QCSR_CQDBADDi, qpid), 
                    qpid, 
                    cq_cidb_addr_lsb);
  write32_data(rdma_dev->axil_ctl, 
                get_rdma_per_q_config_addr(RN_RDMA_QCSR_CQDBADDMSBi, qpid), 
                cq_cidb_addr_msb);
  Debug("[Register] RN_RDMA_QCSR_CQDBADDMSBi=0x%x, qpid=%d, value=0x%x\n", 
                    get_rdma_per_q_config_addr(RN_RDMA_QCSR_CQDBADDMSBi, qpid), 
                    qpid, 
                    cq_cidb_addr_msb);
  Debug("DEBUG: cq_cidb_addr = 0x%lx\n", cq_cidb_addr);

  // RQ DB address
  write32_data(rdma_dev->axil_ctl, 
              get_rdma_per_q_config_addr(RN_RDMA_QCSR_RQWPTRDBADDi, qpid), 
              rq_cidb_addr_lsb);
  Debug("[Register] RN_RDMA_QCSR_RQWPTRDBADDi=0x%x, qpid=%d, value=0x%x\n", 
                    get_rdma_per_q_config_addr(RN_RDMA_QCSR_RQWPTRDBADDi, qpid), 
                    qpid, 
                    rq_cidb_addr_lsb);
  write32_data(rdma_dev->axil_ctl, 
              get_rdma_per_q_config_addr(RN_RDMA_QCSR_RQWPTRDBADDMSBi, qpid), 
              rq_cidb_addr_msb);
  Debug("[Register] RN_RDMA_QCSR_RQWPTRDBADDMSBi=0x%x, qpid=%d, value=0x%x\n", 
                    get_rdma_per_q_config_addr(RN_RDMA_QCSR_RQWPTRDBADDMSBi, qpid), 
                    qpid, 
                    rq_cidb_addr_msb);
  Debug("DEBUG: rq_cidb_addr = 0x%lx\n", rq_cidb_addr);
  
  // Destination QP configuration
  write32_data(rdma_dev->axil_ctl, 
              get_rdma_per_q_config_addr(RN_RDMA_QCSR_DESTQPCONFi, qpid), 
              dst_qpid);
  Debug("[Register] RN_RDMA_QCSR_DESTQPCONFi=0x%x, qpid=%d, value=0x%x\n", 
                    get_rdma_per_q_config_addr(RN_RDMA_QCSR_DESTQPCONFi, qpid), 
                    qpid, 
                    dst_qpid);

  // Queue depth configuration
  write32_data(rdma_dev->axil_ctl, 
                get_rdma_per_q_config_addr(RN_RDMA_QCSR_QDEPTHi, qpid), 
                (qdepth | qdepth << 16));
  Debug("[Register] RN_RDMA_QCSR_QDEPTHi=0x%x, qpid=%d, value=0x%x\n", 
                    get_rdma_per_q_config_addr(RN_RDMA_QCSR_QDEPTHi, qpid), 
                    qpid, 
                    (qdepth | qdepth << 16));

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
  qp_config = (en_qp & 0x00000001) | 
                (0xc & 0x0000000c) | 
                (0x30 & 0x000000f0) | 
                ((mtu_config<<8) & 0x0000ff00) | 
                ((rq_buffer_entry_size<<16) & 0xffff0000);
  write32_data(rdma_dev->axil_ctl, 
                get_rdma_per_q_config_addr(RN_RDMA_QCSR_QPCONFi, qpid), 
                qp_config);
  Debug("[Register] RN_RDMA_QCSR_QPCONFi=0x%x, qpid=%d, value=0x%x\n", 
                    get_rdma_per_q_config_addr(RN_RDMA_QCSR_QPCONFi, qpid), 
                    qpid, 
                    qp_config);

  // Queue pair advanced control configuration
  traffic_class = 0;
  time_to_live  = 64;
  qp_adv_conf = ((partion_key<<16) & 0xffff0000) | 
                ((time_to_live<<8) & 0x0000ff00) | 
                (traffic_class & 0x000000ff);
  write32_data(rdma_dev->axil_ctl, 
                get_rdma_per_q_config_addr(RN_RDMA_QCSR_QPADVCONFi, qpid), 
                qp_adv_conf);
  Debug("[Register] RN_RDMA_QCSR_QPADVCONFi=0x%x, qpid=%d, value=0x%x\n", 
                    get_rdma_per_q_config_addr(RN_RDMA_QCSR_QPADVCONFi, qpid), 
                    qpid, 
                    qp_adv_conf);

  // PD number configuration
  write32_data(rdma_dev->axil_ctl, 
                get_rdma_per_q_config_addr(RN_RDMA_QCSR_PDi, qpid), 
                pd_entry->pd_num);
  Debug("[Register] RN_RDMA_QCSR_PDi=0x%x, qpid=%d, value=0x%x\n", 
                    get_rdma_per_q_config_addr(RN_RDMA_QCSR_PDi, qpid), 
                    qpid, 
                    pd_entry->pd_num);

  fprintf(stderr, "Info: allocate_rdma_qp - Successfully allocated a rdma qp\n");
  return qp;
}

void create_a_wqe(struct rdma_dev_t* rdma_dev, 
                  uint32_t qpid, 
                  uint16_t wrid, 
                  uint32_t wqe_idx, 
                  uint64_t laddr, 
                  uint32_t length, 
                  uint32_t opcode, 
                  uint64_t remote_offset, 
                  uint32_t r_key, 
                  uint32_t send_small_payload0, 
                  uint32_t send_small_payload1, 
                  uint32_t send_small_payload2, 
                  uint32_t send_small_payload3, 
                  uint32_t immdt_data) {

  uint32_t high_addr;
  uint32_t low_addr;
  uint64_t masked_buf_addr;
  struct rdma_wqe_t* wqe;
  uint32_t win_size_low  = rdma_dev->winSize->win_size_lsb;
  uint32_t win_size_high = rdma_dev->winSize->win_size_msb;

  if(is_device_address(laddr)) {
    // Device memory address
    high_addr = (uint32_t) ((laddr & 0xffffffff00000000) >> 32);
    low_addr  = (uint32_t) (laddr & 0x00000000ffffffff);
  } else {
    // Host memory address
    high_addr = ((uint32_t) ((laddr & 0xffffffff00000000) >> 32)) & win_size_high;
    low_addr  = ((uint32_t) (laddr & 0x00000000ffffffff)) & win_size_low;
  }

  masked_buf_addr = (((uint64_t) high_addr) << 32) | ((uint64_t) low_addr);
  Debug("Info: WQE mem_buffer = 0x%lx, masked_mem_buffer = 0x%lx\n", laddr, masked_buf_addr);

  struct rdma_buff_t* sq = rdma_dev->qps_ptr[qpid]->sq;
  if(is_device_address(sq->dma_addr)) {
    // SQ is allocated at device memory
    wqe = (struct rdma_wqe_t* ) malloc(sizeof(struct rdma_wqe_t));
  } else {
    // SQ is allocated at host memory
    wqe = &(((struct rdma_wqe_t*) sq->buffer)[wqe_idx]);
  }
  memset(wqe, 0, sizeof(struct rdma_wqe_t));

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
  Debug("[WQE] wrid=0x%x\n", (uint32_t) wqe->wrid);
  Debug("[WQE] laddr_low=0x%x\n", wqe->laddr_low);
  Debug("[WQE] laddr_high=0x%x\n", wqe->laddr_high);
  Debug("[WQE] length=0x%x\n", wqe->length);
  Debug("[WQE] opcode=0x%x\n", wqe->opcode);
  Debug("[WQE] remote_offset_low=0x%x\n", wqe->remote_offset_low);
  Debug("[WQE] remote_offset_high=0x%x\n", wqe->remote_offset_high);
  Debug("[WQE] r_key=0x%x\n", wqe->r_key);
  Debug("[WQE] send_small_payload0=0x%x\n", wqe->send_small_payload0);
  Debug("[WQE] send_small_payload1=0x%x\n", wqe->send_small_payload1);
  Debug("[WQE] send_small_payload2=0x%x\n", wqe->send_small_payload2);
  Debug("[WQE] send_small_payload3=0x%x\n", wqe->send_small_payload3);
  Debug("[WQE] immdt_data=0x%x\n", wqe->immdt_data);
  if(is_device_address(sq->dma_addr)) {
    // Write WQE to SQ in the device memory
    Debug("DEBUG: Write WQE to the device memory\n");
    ssize_t rc = write_from_buffer(device, fpga_fd, (char* ) wqe, sizeof(struct rdma_wqe_t), (sq->dma_addr + (wqe_idx*sizeof(struct rdma_wqe_t))));
    if (rc < 0){
      fprintf(stderr, "Error: Failed to write WQE to the device memory!\n");
      exit(EXIT_FAILURE);
    } else {
      Debug("DEBUG: successfully write WQE to the device memory!\n");
    }
    free(wqe);
  }
}

int poll_rq_pidb(struct rdma_dev_t* rdma_dev, uint32_t qpid) {
  struct rdma_qp_t* qp = rdma_dev->qps_ptr[qpid];
  int rq_pidb = read32_data(rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_STATRQPIDBi, qpid));

  // If poll, read until greater than what we previously have read
  Debug("DEBUG: Polling on RQ PIDB. Count: 0x%x\n", rq_pidb);
  if(getenv("DEBUG") && atoi(getenv("DEBUG")) == 1) {
    dump_registers(rdma_dev, 0, qpid);
  }
  while(rq_pidb == qp->rq_pidb) {
      rq_pidb = read32_data(rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_STATRQPIDBi, qpid));
  }

  qp->rq_pidb = rq_pidb;        
  return qp->rq_pidb;
}

int poll_cq_cidb(struct rdma_dev_t* rdma_dev, uint32_t qpid, int sq_cidb) {
  int cq_cidb;
  uint32_t timeout_cnt = 0;
  cq_cidb = read32_data(rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_CQHEADi, qpid));
  Debug("[Register] RN_RDMA_QCSR_CQHEADi=0x%x, qpid=%d, value=0x%x\n", get_rdma_per_q_config_addr(RN_RDMA_QCSR_CQHEADi, qpid), qpid, cq_cidb);

  Debug("DEBUG: before polling: sq_cidb = %d; Polling CQ CIDB = %d\n", sq_cidb, cq_cidb);
  // dump_registers(rdma_dev, 1, qpid);
  while(cq_cidb == sq_cidb) {
    cq_cidb = read32_data(rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_CQHEADi, qpid));
    timeout_cnt += 1;
    if(timeout_cnt > TIMEOUT_THRESHOLD) {
      goto timeout_action;
    }
    //fprintf(stderr, "Waiting for completion doorbell index update\n");
  }

  Debug("DEBUG: after polling: sq_cidb = %d; Polling CQ CIDB = %d\n", sq_cidb, cq_cidb);
  return cq_cidb;

timeout_action:
  fprintf(stderr, "ERROR: poll_cq_cidb timeout! sq_cidb = %d; Polling CQ CIDB = %d\n", sq_cidb, cq_cidb);
  dump_registers(rdma_dev, 1, qpid);
  return -1;
}

int rdma_post_send(struct rdma_dev_t* rdma_dev, uint32_t qpid) {
  if(rdma_dev == NULL) {
    fprintf(stderr, "Error: rdma_dev is NULL\n");  
    exit(EXIT_FAILURE);
  }

  struct rdma_qp_t* qp = rdma_dev->qps_ptr[qpid];

  // Increase send queue producer index doorbell
  Debug("DEBUG: Reading hardware SQPIi (0x%x) = 0x%x\n", get_rdma_per_q_config_addr(RN_RDMA_QCSR_SQPIi, qpid), read32_data(rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_SQPIi, qpid)));
  Debug("DEBUG: original qp->sq_pidb = 0x%x\n", qp->sq_pidb);
  
  qp->sq_pidb++;

  // Update sq_pidb to hardware
  write32_data(rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_SQPIi, qpid), qp->sq_pidb);
  Debug("[Register] RN_RDMA_QCSR_SQPIi=0x%x, qpid=%d, value=0x%x\n", get_rdma_per_q_config_addr(RN_RDMA_QCSR_SQPIi, qpid), qpid, qp->sq_pidb);
  Debug("DEBUG: Update hardware sq db idx from software = %d\n", qp->sq_pidb);
  Debug("DEBUG: Reading hardware SQPIi (0x%x) = 0x%x\n", get_rdma_per_q_config_addr(RN_RDMA_QCSR_SQPIi, qpid), read32_data(rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_SQPIi, qpid)));

  // polling on completion, by checking CQ doorbell
  qp->cq_cidb = poll_cq_cidb(rdma_dev, qpid, qp->sq_cidb);
  qp->sq_cidb++;

  if(qp->cq_cidb < 0) {
    return -1;
  } else {
    return 0;
  }
}

int rdma_post_batch_send(struct rdma_dev_t* rdma_dev, uint32_t qpid, uint32_t batch_size) {
  if(rdma_dev == NULL) {
    fprintf(stderr, "Error: rdma_dev is NULL\n");  
    exit(EXIT_FAILURE);
  }

  struct rdma_qp_t* qp = rdma_dev->qps_ptr[qpid];

  // Increase send queue producer index doorbell
  Debug("DEBUG: Reading hardware SQPIi (0x%x) = 0x%x\n", get_rdma_per_q_config_addr(RN_RDMA_QCSR_SQPIi, qpid), read32_data(rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_SQPIi, qpid)));
  Debug("DEBUG: original qp->sq_pidb = 0x%x\n", qp->sq_pidb);
  
  qp->sq_pidb += batch_size;

    if((qp->qdepth < batch_size) || ((qp->sq_pidb > qp->qdepth))) {
    fprintf(stderr, "Error: SQ overflow\n");
    exit(EXIT_FAILURE);
  }

  // Update sq_pidb to hardware
  write32_data(rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_SQPIi, qpid), qp->sq_pidb);
  Debug("[Register] RN_RDMA_QCSR_SQPIi=0x%x, qpid=%d, value=0x%x\n", get_rdma_per_q_config_addr(RN_RDMA_QCSR_SQPIi, qpid), qpid, qp->sq_pidb);
  Debug("DEBUG: Update hardware sq db idx from software = %d\n", qp->sq_pidb);
  Debug("DEBUG: Reading hardware SQPIi (0x%x) = 0x%x\n", get_rdma_per_q_config_addr(RN_RDMA_QCSR_SQPIi, qpid), read32_data(rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_SQPIi, qpid)));
  Debug("[Register] RN_RDMA_QCSR_CQHEADi=0x%x, qpid=%d, value=0x%x\n", get_rdma_per_q_config_addr(RN_RDMA_QCSR_CQHEADi, qpid), qpid, qp->cq_cidb);
  // polling on completion, by checking CQ doorbell
  while(qp->cq_cidb < qp->sq_pidb) {
    // Wait for all WQE to be completed
    qp->cq_cidb = poll_cq_cidb(rdma_dev, qpid, qp->sq_cidb);
    qp->sq_cidb = qp->cq_cidb;
  }

  if(qp->cq_cidb < 0) {
    return -1;
  } else {
    return 0;
  }
}

void write_rq_cidb(struct rdma_dev_t* rdma_dev, struct rdma_qp_t* qp, uint32_t db_val) {
  // Keeping note of what the cidb is at
  qp->rq_cidb = db_val;
  
  // Writing to the card
  write32_data(rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_RQCIi, qp->qpid), db_val);
  
  return;
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

  int rq_pidb = poll_rq_pidb(rdma_dev, qp->qpid);
  if(rq_pidb == -1) {
    fprintf(stderr, "Error: rdma_post_receive failed\n");
    exit(EXIT_FAILURE);
  }

  // Pointing to the RQE
  if(rq_pidb == 0) {
    rqe = (void* ) ((uint64_t) qp->rq->buffer + (uint64_t) ((qp->qdepth - 1) * RQE_SIZE));
  }
  else {
    rqe = (void* ) ((uint64_t) qp->rq->buffer + (uint64_t) ((rq_pidb - 1) * RQE_SIZE));
  }

  return rqe;
}

uint8_t rdma_release_rq_consumed (struct rdma_dev_t* rdma_dev, struct rdma_qp_t* qp) {
  int rq_pidb;
  uint8_t rc = 0;

  // Check whether all RQ requests are received
  rq_pidb = read32_data(rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_STATRQPIDBi, qp->qpid));

  if (rq_pidb != qp->rq_pidb) {
    // We still have RQ requests pending.
    rc = 1;
  }

  write_rq_cidb(rdma_dev, qp, qp->rq_pidb);
  // write32_data(rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_RQCIi, qp->qpid), rq_pidb);
  Debug("[Register] RN_RDMA_QCSR_RQCIi=0x%x, qpid=%d, value=0x%x\n", get_rdma_per_q_config_addr(RN_RDMA_QCSR_RQCIi, qp->qpid), qp->qpid, rq_pidb);

  return rc;
}

void rdma_qp_fatal_recovery(struct rdma_dev_t* rdma_dev, uint32_t qpid) {
  fprintf(stderr, "\n\n***** QP%d FATAL RECOVERY *****\n", qpid);
  // Steps to clear traffic on QP:
  uint32_t rt_value;
  uint32_t timeout_cnt = 0;

  /* 1. Wait till SQ/OSQ are empty */
  while(1) {
    rt_value = read32_data(rdma_dev->axil_ctl, 
                           get_rdma_per_q_config_addr(RN_RDMA_QCSR_STATQPi, qpid));
    // Debug("[Register] RN_RDMA_QCSR_STATQPi=0x%x, qpid=%d, value=0x%x\n", 
    //                 get_rdma_per_q_config_addr(RN_RDMA_QCSR_STATQPi, qpid), 
    //                 qpid, 
    //                 rt_value);
    if ((rt_value >> 9) & 0x3)
			break;
  }

  /* 2. Check SQ PI == CQ Head */
  timeout_cnt = 0;
  while(read32_data(rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_CQHEADi, qpid)) 
        != read32_data(rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_SQPIi, qpid))) {
    timeout_cnt += 1;
    if (timeout_cnt > 100000){
      fprintf(stderr, "TIMEOUT: CQHEADi:0x%x and SQPIi:0x%x are different\n", 
                      read32_data(rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_CQHEADi, qpid)),
                      read32_data(rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_SQPIi, qpid)));
      exit(EXIT_FAILURE);
    }
  }
  
  /* Disable the QP */
  rt_value = read32_data(rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_QPCONFi, qpid));
  write32_data(rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_QPCONFi, qpid), 
              (rt_value & ~(BIT(0)))); // set bit [0] to 0
  rt_value = read32_data(rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_QPCONFi, qpid));
  write32_data(rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_QPCONFi, qpid), 
              (rt_value | BIT(6))); // set bit [6] to 1
  rt_value = read32_data(rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_QPCONFi, qpid));
  Debug("[Register] RN_RDMA_QCSR_QPCONFi=0x%x, qpid=%d, value=0x%x\n", 
                    get_rdma_per_q_config_addr(RN_RDMA_QCSR_QPCONFi, qpid), 
                    qpid, rt_value);
}

void destroy_rdma_pd_entry(struct rdma_pd_t* pd) {
  if(pd != NULL) {
    free(pd);
    pd = NULL;
  }
}

int destroy_rdma_qp(struct rdma_qp_t* qp) {
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
    
    uint32_t test = read32_data(qp->rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_CQHEADi, qp->qpid));
    Debug("[DEBUG] Destroying dev: %p, RN_RDMA_QCSR_CQHEADi=0x%x, qpid=%d, value=0x%x\n", qp->rdma_dev->axil_ctl,
                            get_rdma_per_q_config_addr(RN_RDMA_QCSR_CQHEADi, qp->qpid), qp->qpid, test);
    
    write32_data(qp->rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_QPCONFi, qp->qpid),  (rt_value | 0x00000040));
    test = read32_data(qp->rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_CQHEADi, qp->qpid));
    Debug("[DEBUG] Destroying dev: %p, RN_RDMA_QCSR_CQHEADi=0x%x, qpid=%d, value=0x%x\n", qp->rdma_dev->axil_ctl,
                            get_rdma_per_q_config_addr(RN_RDMA_QCSR_CQHEADi, qp->qpid), qp->qpid, test);
    
    // Disable software override mode (1'b0) in XRNICADCONF[0]
    rt_value = read32_data(qp->rdma_dev->axil_ctl, RN_RDMA_GCSR_XRNICADCONF);
    write32_data(qp->rdma_dev->axil_ctl, RN_RDMA_GCSR_XRNICADCONF, (rt_value & 0xfffffffe));
  
    test = read32_data(qp->rdma_dev->axil_ctl, get_rdma_per_q_config_addr(RN_RDMA_QCSR_CQHEADi, qp->qpid));
    Debug("[DEBUG] Destroying dev: %p, RN_RDMA_QCSR_CQHEADi=0x%x, qpid=%d, value=0x%x\n", qp->rdma_dev->axil_ctl,
                            get_rdma_per_q_config_addr(RN_RDMA_QCSR_CQHEADi, qp->qpid), qp->qpid, test);
  
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
    destroy_rdma_dev((struct rdma_dev_t* ) rn_dev->rdma_dev);
    rn_dev = NULL;
  }

  return 0;
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
