#!/usr/bin/env python3
#==============================================================================
# Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
# SPDX-License-Identifier: MIT
#
#==============================================================================

import os
import sys
import random
import json
import math
import logging
import config_logger
import functools
import numpy as np
# For scapy packet debug, use hexdump (pip install hexdump)
#import hexdump
import binascii as ba
import ernic_header as eh
from collections import OrderedDict
from os.path import join as pjoin
from scapy.all import *
# Add RoCEv2 packet support from scapy
from scapy.contrib.roce import *

logger = logging.getLogger('run_testcase.packet_gen')

class pktGenClass:
  def __init__(self, cfg_name, debug=False):
    self.num_flow = 4
    self.num_pkts = 64
    self.pkt_size = 64
    self.matrix_size = 4
    self.matrix_a_lst = []
    self.matrix_b_lst = []
    self.matrix_c_lst = []
    self.ctl_cmd_lst = []
    self.cl_init_mem = []
    self.cl_golden_mem = []
    self.cl_golden_data = []
    self.cfg_name = cfg_name
  
  def gen_dummy_pkt_str(self):
    """Generate dummy packet string
    Args:
      none
    Return:
      dummy packet string
    """
    dummy_pkt_str = ''
    total_len = self.pkt_size*2
    for i in range(total_len):
      if (i%2 == 1) and (i!=total_len-1):
        dummy_pkt_str = dummy_pkt_str + 'd' + ' '
      else:
        dummy_pkt_str = dummy_pkt_str + 'd'
    
    return dummy_pkt_str

  def create_matrix(self, matrix_size):
    """Create matrix
    Args:
      matrix_size (int): matrix size 
    Return:
      generated matrix
    """
    lst = [ [j+1 for j in range(matrix_size)] for i in range(matrix_size) ]
    matrix = np.array(lst)
    return matrix
  
  def mat2list(self, matrix):
    """Convert a matrix to a list
    Args:
      matrix (int array): Matrix
    Return:
      one dimensional list
    """
    lst = matrix.flatten().tolist()
    return lst

  def matrix_multiplication(self, a_array, b_array):
    """Matrix multiplication
    Args:
      a_array (int array): array A
      b_array (int array): array B
    Return:
      Return c array. The result is stored in self.cl_golden_data
    """
    c_array = np.matmul(a_array, b_array)
    c_list = self.mat2list(c_array)
    self.cl_golden_data = self.cl_golden_data + c_list
    return c_array

  def get_matrix_string(self, matrix, baseaddr, is_golden=False):
    """Generating initial memory data for compute logic simulation
    Args:
      matrix  (list): Matrix list
      baseaddr (int): baseaddress of array Matrix
    Return:
      cl_init_mem list with (data, memory address, size of data)
    """
    tmp_str = ""
    idx = 0
    for item in matrix:
      tmp_str  = tmp_str + format(item, '08x')
      idx = idx + 1
      if((idx % 16) == 0):
        addr = baseaddr + ((idx>>4) - 1) * 0x40
        logger.debug(f"[Addr = {addr: 016x}, baseaddr = {baseaddr: 016x}, idx = {idx}]")
        entry_str = format(addr, '016x') + ' ' + tmp_str + ' ' + '0040'
        if(is_golden == False):
          self.cl_init_mem.append(entry_str)
        else:
          self.cl_golden_mem.append(entry_str)
        tmp_str = ""

  def gen_cl_init_mem(self, a_baseaddr, b_baseaddr, c_baseaddr):
    """Generating initial memory data for compute logic simulation
    Args:
      a_baseaddr (int): baseaddress of array A
      b_baseaddr (int): baseaddress of array B
      c_baseaddr (int): baseaddress of array C
    Return:
      cl_init_mem list with (data, memory address, size of data)
    """
    logger.debug("Matrix A")
    self.get_matrix_string(self.matrix_a_lst, a_baseaddr)
    logger.debug("Matrix B")
    self.get_matrix_string(self.matrix_b_lst, b_baseaddr)
    logger.debug("Matrix C")
    self.get_matrix_string(self.matrix_c_lst, c_baseaddr)

  def gen_cl_ctl_cmd(self, a_baseaddr, b_baseaddr, c_baseaddr, a_row, a_col, b_col, ctl_cmd_num):
    """Generating control commands for Compute Logic simulation
    Args:
      a_baseaddr (int): baseaddress of array A
      b_baseaddr (int): baseaddress of array B
      c_baseaddr (int): baseaddress of array C
      a_row      (int): row size of array A
      a_col      (int): column size of array A
      b_col      (int): column size of array B
      ctl_cmd_num(int): number of control command generated
    Return:
      control command list for Compute Logic simulation
    """
    assert(ctl_cmd_num <= 8), 'Please reduce number of control command generated (<= 8) or increase size of AXI-BRAM'
    ctl_cmd_baseaddr = 0x3000 + 0x0
    size_ctl_cmd = 6
    kernel_id = 10
    a_row_col = ((a_row << 16) & 0xffff0000) | (a_col & 0x0000ffff)
    b_col_ker_id = ((b_col << 16) & 0xffff0000) | (kernel_id & 0x0000ffff)
    step = 3*(a_row*a_col*4)
    for i in range(ctl_cmd_num):
      tmp_lst = [size_ctl_cmd, a_baseaddr + i*step, b_baseaddr + i*step, c_baseaddr + i*step, a_row_col, b_col_ker_id]
      for item in tmp_lst:
        ctl_cmd_str = format(ctl_cmd_baseaddr, "08x") + ' ' + format(item, "08x")
        self.ctl_cmd_lst.append(ctl_cmd_str)

  def gen_cl_stimulus(self):
    """Generating control commands for Compute Logic simulation
    Args:
      none
    Return:
      return cl_init_mem, cl_reg_config and cl_golden files
    """
    a_baseaddr_seed = 0
    # Parse a json file
    with open(self.cfg_name, 'r') as f:
      config_dict = json.load(f)
    for item in config_dict:
      if (item == 'a_baseaddr'):
        a_baseaddr_seed = config_dict[item]
      if (item == 'b_baseaddr'):
        b_baseaddr_seed = config_dict[item]
      if (item == 'c_baseaddr'):
        c_baseaddr_seed = config_dict[item]
      if (item == 'row_col_size'):
        a_row = config_dict[item]
        a_col = config_dict[item]
        b_col = config_dict[item]                
      if (item == 'num_ctl_cmd'):
        num_ctl_cmd = config_dict[item]

    offset = 3*(a_row*a_col*4)
    for i in range(num_ctl_cmd):
      logger.info(f"Generating the {i}-th control command and its associated data")
      a_baseaddr = a_baseaddr_seed + offset*i
      b_baseaddr = b_baseaddr_seed + offset*i
      c_baseaddr = c_baseaddr_seed + offset*i
      # Get matrix lists
      matrix_a_tmp = self.create_matrix(a_row)
      matrix_b_tmp = self.create_matrix(a_row)
      self.matrix_a_lst = self.mat2list(matrix_a_tmp)
      self.matrix_b_lst = self.mat2list(matrix_b_tmp)
      self.matrix_c_lst = self.mat2list(np.zeros((a_row, b_col), dtype=int))

      # Matrix multiplication
      matrix_c = self.matrix_multiplication(matrix_a_tmp, matrix_b_tmp)
      matrix_c_list = self.mat2list(matrix_c)

      # Get cl_init_mem and cl_golden
      self.gen_cl_init_mem(a_baseaddr, b_baseaddr, c_baseaddr)
      self.get_matrix_string(matrix_c_list, c_baseaddr, is_golden=True)

    # Get cl_reg_config
    self.gen_cl_ctl_cmd(a_baseaddr_seed, b_baseaddr_seed, c_baseaddr_seed, a_row, a_col, b_col, num_ctl_cmd)

    # Convert int list to string list
    self.cl_golden_data = list(map('{:08x}'.format, [i for i in self.cl_golden_data]))

  def write_pkts2file(self, filename, header_str, pkts):
    """Write generated packets into a file
    Args:
      filename  (string)  : file name used to store generated packets
      header_str(string)  : header string when we write packets to a file
      pkts      (str list): a list of packet strings
    Returns:
      none
    """
    pkt_str = ''
    if (header_str != ''):
      pkt_str = header_str + '\n'
    for i in pkts:
      pkt_str = pkt_str + i + ';\n'
      with open(filename, 'w') as f:
        f.write(pkt_str)

  def write2file(self, filename, header_str, pkts, mode='w'):
    """Write generated data into a file
    Args:
      filename  (string)  : file name used to store generated packets
      header_str(string)  : header string when we write packets to a file
      pkts      (str list): a list of packet strings
      mode      (string)  : 'w' for write; 'a' for append
    Returns:
      none
    """
    pkt_str = ''
    if (header_str != ''):
      pkt_str = header_str + '\n'
    for i in pkts:
      pkt_str = pkt_str + i + '\n'
    
    if (mode == 'w'):
      with open(filename, 'w') as f:
        f.write(pkt_str)
    elif (mode == 'a'):
      with open(filename, 'a') as f:
        f.write(pkt_str)
    else:
      assert(False), "Please provide a correct file mode: 'w' or 'a'"

  def append2file(self, filename, header_str, pkts):
    """Append generated packets into a file
    Args:
      filename  (string) : file name used to store generated packets
      header_str (string) : header string when we write packets to a file
      pkts     (str list) : a list of packet strings
    Returns:
      none
    """
    pkt_str = ''
    if (header_str != ''):
      pkt_str = header_str + '\n'
    for i in pkts:
      pkt_str = pkt_str + i + '\n'
    with open(filename, 'a') as f:
      f.write(pkt_str)    

# RoCEv2 packet generation class
class GenRoCEClass(pktGenClass):
  ## We leverage ernic to generate rdma packets at the moment and only generate controls for ernic
  ## and verify data in either system or device memory
  def __init__(self, cfg_name, debug=False, debug_path=''):
    super().__init__(cfg_name, debug)
    self.debug_path       = debug_path
    self.top_module       = '' 
    self.eth_dst_seed     = '10:20:30:40:50:60'
    self.eth_src_seed     = 'a0:b0:c0:d0:e0:f0'
    self.eth_dst_noise    = 'cd:ab:ef:be:ad:de'
    self.ip_dst_seed      = '10.10.0.0'
    self.ip_src_seed      = '10.20.0.0'
    # Use dev_mem as the default src_baseaddr location
    self.src_baseaddr_location = 'dev_mem'
    self.src_baseaddr     = 0
    self.dst_baseaddr     = 0
    self.num_data_buffer  = 4
    self.non_roce_traffic = 0
    self.num_non_roce     = 0
    self.noise_roce_en    = 0
    self.num_flow         = 1
    self.non_roce_pkts    = []
    self.roce_noise_pkts  = []
    self.data_buffer_size = 4096
    self.rm_viraddr_seed  = 0x00000000abcd0000

    # memory region registered per pd_num: 32KB
    self.mr_buf_size      = 32768
    # consider memory region size and 256KB for data in system memory
    # we can only support up to 8 QPs in the current sim configuration generation
    self.num_qp           = 4
    self.udp_sport        = 0x4321
    # hex(4798) = 0x12b7
    self.udp_dport        = 4791
    self.destination_qpid = 2
    self.sq_depth         = 4
    self.rq_depth         = 4
    self.mtu_size         = 4096
    self.rq_buffer_size   = 2048
    # hex(4660) = 0x1234
    self.partition_key    = 0x1234
    # hex(26505) = 0x6789
    self.r_key            = 0x01
    self.sq_psn           = 0
    # udp protocol number is 0x11
    self.ip_proto         = 'udp'
    self.write_pkt_size   = 0
    self.read_pkt_size    = 0
    self.rsp_pkt_size     = 0
    self.paylaod_size     = 0
    self.pkt_op           = ''
    #self.num_pkts_per_flow= 0
    # We assume that only one src IPv4 address is used
    self.ip_src            = 0
    #self.ip_src_list      = []
    self.ip_dst_list      = []
    self.rdma_init_sys_mem  = []
    self.rdma_init_dev_mem  = []
    self.rdma_global_config = []
    self.rdma_per_q_config  = []
    self.rdma_mr_config     = []
    self.rdma_wqe_list      = []
    self.debug_wqe_list     = []
    self.qpid_sq_dict       = {}
    self.qpid_rq_dict       = {}
    self.qpid_cq_dict       = {}
    self.qpid_cq_db_dict    = {}
    self.rq_wptr_db_dict    = {}
    self.rdma1_stat_reg_config = []
    self.rdma1_debug_stat_reg_config = []

    # Configuration for remote RDMA peer
    self.rdma2_global_config = []
    self.rdma2_per_q_config  = []
    self.rdma2_mr_config     = []
    self.rdma2_per_q_recv_config     = []
    self.rdma2_stat_reg_config       = []
    self.rdma2_debug_stat_reg_config = []
    '''
    self.write_pkts     = []
    self.read_pkts      = []
    self.response_pkts  = []
    self.roce_pkts      = []
    '''
    # SQ doorbell value
    self.sq_pidb  = 0
    self.parse_json_config()
    if (self.top_module == 'rn_tb_2rdma_top'):
      self.gen_rdma_configurations(has_remote_peer=True)
    else:
      self.gen_rdma_configurations()
    self.gen_rdma_init_mem(self.num_pkts)
    self.gen_non_roce_packets(self.num_non_roce)
    if(self.noise_roce_en):
      mid_pos = int(len(self.non_roce_pkts)/2)
      self.gen_noise_roce_packets()
      self.non_roce_pkts = self.non_roce_pkts[:mid_pos] + self.roce_noise_pkts + self.non_roce_pkts[mid_pos:]

  #def get_num_pkts(self):
  #  self.num_pkts = self.num_flow * self.num_pkts_per_flow
  #  #self.num_pkts = len(self.roce_pkts) 

  def parse_json_config(self):
    """Parse configuration file in JSON format
    """
    with open(self.cfg_name, 'r') as f:
      config_dict = json.load(f)
    for item in config_dict:
      if (item == 'payload_size'):
        # payload_size in bytes: small fabric header only support {0, 4, 8}
        self.payload_size = config_dict[item]
        if (config_dict[item] == 0):
          self.no_payload = 1        
      if (item == 'number_flow'):
        self.num_flow = config_dict[item]          
      #if (item == 'number_pkts_per_flow'):
      #  self.num_pkts_per_flow = config_dict[item]
      if (item == 'pkt_op'):
        # pkt_op: 'write' and 'read'
        self.pkt_op = config_dict[item]
      if (item == 'non_roce_traffic'):
        if (config_dict[item] == 'yes'):
          self.non_roce_traffic = 1
        else:
          self.non_roce_traffic = 0
      if (item == 'num_non_roce'):
        self.num_non_roce = config_dict[item]        
      if (item == 'noise_roce_en'):
        if (config_dict[item] == 'yes'):
          self.noise_roce_en = 1
        else:
          self.noise_roce_en = 0
      if (item == 'ip_src_seed'):
        self.ip_src_seed = config_dict[item]
      if (item == 'ip_dst_seed'):
        self.ip_dst_seed = config_dict[item]
      if (item == 'udp_sport'):
        self.udp_sport = config_dict[item]
      if (item == 'udp_dport'):
        self.udp_dport = config_dict[item]
      if (item == 'payload_size'):
        self.paylaod_size = config_dict[item]
      if (item == 'src_baseaddr_location'):
        self.src_baseaddr_location = config_dict[item]
      if (item == 'src_baseaddr'):
        self.src_baseaddr = config_dict[item]
      if (item == 'dst_baseaddr'):
        self.dst_baseaddr = config_dict[item]
      if (item == 'num_data_buffer'):
        self.num_data_buffer = config_dict[item]
      if (item == 'data_buffer_size'):
        self.data_buffer_size = config_dict[item]
      if (item == 'mr_buf_size'):
        self.mr_buf_size = config_dict[item]
      if (item == 'num_qp'):
        self.num_qp = config_dict[item]
      if (item == 'udp_sport'):
        self.udp_sport = config_dict[item]
      if (item == 'destination_qpid'):
        self.destination_qpid = config_dict[item]
      if (item == 'sq_depth'):
        self.sq_depth = config_dict[item]
      if (item == 'rq_depth'):
        self.rq_depth = config_dict[item]
      if (item == 'mtu_size'):
        self.mtu_size = config_dict[item]
      if (item == 'rq_buffer_size'):
        self.rq_buffer_size = config_dict[item]
      if (item == 'partition_key'):
        self.partition_key = config_dict[item]
      if (item == 'r_key'):
        self.r_key = config_dict[item]
      if (item == 'sq_psn'):
        self.sq_psn = config_dict[item]
      if (item == 'top_module'):
        self.top_module = config_dict[item]

  def get_int32_ip(self, ip):
    assert(len(ip)==4), "Please provide a correct IPv4 address"
    int32_ip = (ip[3]<<24 | ip[2]<<16 | ip[1]<<8 | ip[0])
    return int32_ip

  def get_mac_addr(self, mac_str):
    mac_lst = [int(x, 16) for x in mac_str.split(':')]
    mac_lsb = (mac_lst[2]<<24 | mac_lst[3]<<16 | mac_lst[4]<<8 | mac_lst[5])
    mac_msb = ((mac_lst[0]<<8) | mac_lst[1]) & 0x0000ffff
    logger.debug(f"after mac_lsb_lst={mac_lsb:08x}")
    logger.debug(f"before mac_msb_lst={mac_msb:08x}")
    return mac_lsb, mac_msb

  def get_ip_list(self):
    ip_src_int_seed = [int(x) for x in self.ip_src_seed.split('.')]
    ip_dst_int_seed = [int(x) for x in self.ip_dst_seed.split('.')]
    ip_dst_lst_tmp = [[x for x in ip_dst_int_seed] for _ in range(self.num_flow)]
    self.ip_src = self.get_int32_ip(ip_src_int_seed)
    logger.info(f"self.ip_src = {self.ip_src}")
    for i in range(self.num_flow):
      ip_dst_lst_tmp[i][3] = i
      self.ip_dst_list.append(self.get_int32_ip(ip_dst_lst_tmp[i]))

  def gen_rdma_init_mem(self, num_pkts):
    """Initialize memory for constructing rdma packets
    Args:
      num_pkts    : number of rdma packets
    Notes: data will start from 0 and end with num_pkts - 1 and its size is 64B each.
    """
    ## AXI-BRAM on hardware has 512KB setup, where 256KB is reserved for memory regions (mr). 
    # For each flow, it only has one memory region allocated and each mr has 32KB, which means 
    # that we can have up to 8 flows. This is just the current sim config generation constraint
    # for simplicity, instead of the hardware limitation.
    assert(self.num_flow <= 8), 'Please reduce number of flow (<= 8) or increase size of AXI-BRAM'
    logger.debug(f'num_flow = {self.num_flow}; num_pkts = {num_pkts}')
    # Initialization payload for memory and actual payload in rdma packets are different. In 
    # the initialization phase, we always use 64B payload
    init_payload_size = 64
    logger.debug(f'Initialization payload size = {init_payload_size}B')
    # need to consider address
    addr_shift = int(math.log(init_payload_size, 2))
    num_8B_in_a_mr = 32*1024>>3
    for i in range(self.num_flow):
      # base address, 32KB per flow; remote_offs has 64-bit, which is 8 bytes
      base_addr = (i * (1 << 15)) & 0xffffffff
      for j in range(num_8B_in_a_mr):
        payload_data = i*(num_8B_in_a_mr) + j
        dest_addr    = base_addr + j*(1<<addr_shift)
        tmp_str = format(dest_addr, '016x') + ' ' + format(payload_data, '016x') + ' ' + format(init_payload_size, '04x')
        self.rdma_init_sys_mem.append(tmp_str)
    
    self.rdma_init_dev_mem = self.rdma_init_sys_mem
    self.rdma_init_sys_mem = self.rdma_init_sys_mem + self.rdma_wqe_list

  def get_rdma_per_q_config_addr(self, reg_offset, qpid):
    """Get RDMA per-queue configuration address
    Args:
      reg_offset (hex) : register offset
      qpid       (int) : queue pair ID
    Returns:
      addr       (int) : address offset
    """
    addr = reg_offset + 0x100 * (qpid-1)
    return addr

  def get_rdma_pd_config_addr(self, reg_offset, pd_num):
    """Get RDMA protection domain table configuration address
    Args:
      reg_offset (hex) : register offset
      pd_num     (int) : protection domain number
    Returns:
      addr       (int) : address offset
    """    
    addr = reg_offset + 0x100 * pd_num
    return addr

  def gen_rdma_global_csr_config(self, src_mac_lsb, src_mac_msb, src_ip, udp_sport, num_qp, dbuf_size=4096, num_dbuf=8, en_intr=0, is_remote_peer=False):
    """Generate RDMA global control status register configurations
    Args:
      src_mac_lsb (int): local MAC address lsb. 32-bit integer: [31:0] src_mac
      src_mac_msb (int): local MAC address msb. 32-bit integer: [47:32] src_mac
      src_ip      (int): local IPv4 address. 32-bit integer
      udp_sport   (int): UDP source port. 16-bit integer
      num_qp      (int): number of queue pairs enabled. 8-bit integer. Default is set to 8
      dbuf_size   (int): data buffer size. Set 4096B as default value
      num_dbuf    (int): number of data buffers. Set 8 as default value.
                         Memory space allocated for data buffer is 64KB. Thus
                         max num_dbuf in 4KB each is 16.
      en_intr     (int): 9-bit interrupt enable signals. Default is disabled
                         -- [0]: Incoming packet validation error interrupt enable
                         -- [1]: Incoming MAD packet received interrupt enable
                         -- [2]: Reserved
                         -- [3]: RNR NACK generated interrupt enable
                         -- [4]: WQE completion interrupt enable (asserted for QPs for
                                 which QPCONF[3] bit is set)
                         -- [5]: Illegal opcode posted in SEND Queue interrupt enable
                         -- [6]: RQ Packet received interrupt enable (asserted for QPs for
                                 which QPCONF[2] bit is set
                         -- [7]: Fatal error received interrupt enable
                         -- [8]: Interrupt enable for CNP scheduling
      is_remote_peer (bool): a signal to indicate remote peer. Default value is False
    Returns:
      rdma_gbl_config list
    """
    debug_str = ''
    rdma_gbl_config = []
    # incoming packet error status buffer offset: 0x30000
    # data buffer offset                        : 0x40000
    # error buffer offset                       : 0x50000
    # response error buffer offset              : 0x60000

    # Configure physical base address of incoming packet error status buffer. An error 
    # status entry in the buffer is 64-bit and has the format {32-bit reserved, 16-bit 
    # QP ID, 16-bit Fatal code}. For the detailed fatal code, please refer to ERNIC user 
    # guide PG332, Page 18, for more details. 
    #   IPKTERRQSZ[15:0]   RW - Number of incoming error pkt status queue entries;
    #   IPKTERRQSZ[31:16]  RW - reserved.
    #   IPKTERRQWPTR[15:0] RO - Write pointer doorbell for incoming error status queue.
    #                           ERNIC IP writes to the queue in a circular manner without
    #                           taking care of overflow. This needs to be handled in SW
    ipkt_errq_baseaddr = 0x30000
    config_str = format(eh.IPKTERRQBA, '08x') + ' ' + format(ipkt_errq_baseaddr, '08x')
    rdma_gbl_config.append(config_str)
    debug_str = debug_str + 'eh.IPKTERRQBA: ' + config_str + '\n'
    ipkt_errq_baseaddr_msb = 0x0
    config_str = format(eh.IPKTERRQBAMSB, '08x') + ' ' + format(ipkt_errq_baseaddr_msb, '08x')
    rdma_gbl_config.append(config_str)
    debug_str = debug_str + 'eh.IPKTERRQBAMSB: ' + config_str + '\n'
    ipkt_errq_sz = 1024
    config_str = format(eh.IPKTERRQSZ, '08x') + ' ' + format(ipkt_errq_sz, '08x')
    rdma_gbl_config.append(config_str)
    debug_str = debug_str + 'eh.IPKTERRQSZ: ' + config_str + '\n'

    # Configure data buffer size and number of data buffers
    # -- [31:16] data buffer size in bytes
    # -- [15:0]  number of data buffers
    # NOTE: data buffer is used to cache data for retransmission until
    #       it's acknowledged by the remot host
    assert((dbuf_size*num_dbuf) <= 64*1024), 'Data buffer exceeds allocated 32KB memory \
    space'
    data_buf_conf = ((dbuf_size << 16) & 0xffff0000) | (num_dbuf & 0x0000ffff)
    config_str = format(eh.DATBUFSZ, '08x') + ' ' + format(data_buf_conf, '08x')
    rdma_gbl_config.append(config_str)
    debug_str = debug_str + 'eh.DATBUFSZ: ' + config_str + '\n'

    # Configure physical base address of data buffer. The main memory in the simulation
    # only has 512KB and we split it into two memory space, each with 256KB. 
    # We reserve 64KB in the second memory space (0x40000 - 0x7ffff) for data buffer. 
    # Default address range for data buffer is set to 0x40000 (262144) - 0x4ffff (327679).
    data_buf_baseaddr = 0x40000
    config_str = format(eh.DATBUFBA, '08x') + ' ' + format(data_buf_baseaddr, '08x')
    rdma_gbl_config.append(config_str)
    debug_str = debug_str + 'eh.DATBUFBA: ' + config_str + '\n'
    data_buf_baseaddr_msb = 0
    config_str = format(eh.DATBUFBAMSB, '08x') + ' ' + format(data_buf_baseaddr_msb, '08x')
    rdma_gbl_config.append(config_str)
    debug_str = debug_str + 'eh.DATBUFBAMSB: ' + config_str + '\n'

    # Configure physical base address of error buffer. The ERNIC IP updates these buffers 
    # with incoming packets that fail validation. The writes to this buffer for all 
    # validation errors are enabled by writing a 1 to XRNICCONF[5]. If this bit is 
    # disabled, only packets that cause the QP to move to a FATAL state are written to 
    # the error buffer. We allocate 64KB (0x10000) for this buffer, starting from 
    # 0x50000 (327680) to 0x5ffff (393215).
    err_buf_baseaddr = 0x50000
    config_str = format(eh.ERRBUFBA, '08x') + ' ' + format(err_buf_baseaddr, '08x')
    rdma_gbl_config.append(config_str)
    debug_str = debug_str + 'eh.ERRBUFBA: ' + config_str + '\n'
    err_buf_baseaddr_msb = 0x0
    config_str = format(eh.ERRBUFBAMSB, '08x') + ' ' + format(err_buf_baseaddr_msb, '08x')
    rdma_gbl_config.append(config_str)
    debug_str = debug_str + 'eh.ERRBUFBAMSB: ' + config_str + '\n'
    #err_buf_sz = 0x10000
    err_buf_sz = ((dbuf_size << 16) & 0xffff0000) | (num_dbuf & 0x0000ffff)
    config_str = format(eh.ERRBUFSZ, '08x') + ' ' + format(err_buf_sz, '08x')
    rdma_gbl_config.append(config_str)
    debug_str = debug_str + 'eh.ERRBUFSZ: ' + config_str + '\n'

    # Configure physical base address of response error packet buffer. It's used to save 
    # all error response packet base address. The retried addresses are pulled from these 
    # buffers. We accocate 64KB (0x10000) for this buffer, starting from 0x60000 (393216)
    # to 0x6ffff (458751)
    rsp_err_pkt_baseaddr = 0x60000
    config_str = format(eh.RESPERRPKTBA, '08x') + ' ' + format(rsp_err_pkt_baseaddr, '08x')
    rdma_gbl_config.append(config_str)
    debug_str = debug_str + 'eh.RESPERRPKTBA: ' + config_str + '\n'    
    rsp_err_pkt_baseaddr_msb = 0
    config_str = format(eh.RESPERRPKTBAMSB, '08x') + ' ' + format(rsp_err_pkt_baseaddr_msb, '08x')
    rdma_gbl_config.append(config_str)
    debug_str = debug_str + 'eh.RESPERRPKTBAMSB: ' + config_str + '\n'    
    rsp_err_pkt_buf_sz = 0x10000
    config_str = format(eh.RESPERRSZ, '08x') + ' ' + format(rsp_err_pkt_buf_sz, '08x')
    rdma_gbl_config.append(config_str)
    debug_str = debug_str + 'eh.RESPERRSZ: ' + config_str + '\n'    
    rsp_err_pkt_buf_sz_msb = 0
    config_str = format(eh.RESPERRSZMSB, '08x') + ' ' + format(rsp_err_pkt_buf_sz_msb, '08x')
    rdma_gbl_config.append(config_str)
    debug_str = debug_str + 'eh.RESPERRSZMSB: ' + config_str + '\n'    

    # Configure interrupts. It's disabled by default
    config_str = format(eh.INTEN, '08x') + ' ' + format((en_intr & 0x000001ff), '08x')
    rdma_gbl_config.append(config_str)
    debug_str = debug_str + 'eh.INTEN: ' + config_str + '\n' 

    # Configure local mac address
    config_str = format(eh.MACXADDLSB, '08x') + ' ' + format(src_mac_lsb, '08x')
    rdma_gbl_config.append(config_str)
    debug_str = debug_str + 'eh.MACXADDLSB: ' + config_str + '\n' 
    config_str = format(eh.MACXADDMSB, '08x') + ' ' + format(src_mac_msb, '08x')
    rdma_gbl_config.append(config_str)
    debug_str = debug_str + 'eh.MACXADDMSB: ' + config_str + '\n' 

    # Configure local IPv4 address
    config_str = format(eh.IPv4XADD, '08x') + ' ' + format(src_ip, '08x')
    rdma_gbl_config.append(config_str)
    debug_str = debug_str + 'eh.IPv4XADD: ' + config_str + '\n' 

    # Configure XRNICCONF register
    # -- [31:16]: UDP source port for out-going packets (4791-0x12b7 is used as UDP destination 
    #             port) 
    # -- [15:8] : number of QPs enabled, used 8 in simulation 
    # -- [7:6]  : reserved: set to 0
    # -- [5]    : Error buffer enable: set to 0
    # -- [4:3]  : TX ACK generation, use default option: 00 - ACK only generated on explicit 
    #             ACK request in the incoming packet or on timeout
    # -- [2:1]  : reserved
    # -- [0]    : ERNIC enable
    reserved1 = 0
    reserved2 = 0
    err_buf_en = 1
    tx_ack_gen = 0
    en_ernic = 1
    config_8bit = ((reserved1<<6) & 0x000000c0) | ((err_buf_en<<5) & 0x00000020) | ((tx_ack_gen<<3) & 0x00000018) | ((reserved2<<1) & 0x00000006) | (en_ernic & 0x00000001)
    xrnic_conf = ((udp_sport<<16) & 0xffff0000) | ((num_qp<<8) & 0x0000ff00) | (config_8bit & 0x000000ff)
    config_str = format(eh.XRNICCONF, '08x') + ' ' + format(xrnic_conf, '08x')
    rdma_gbl_config.append(config_str)
    debug_str = debug_str + 'eh.XRNICCONF: ' + config_str + '\n'

    # Configure XRNIC Advance configuration
    ## -- [0]    : SW override enable. Allows SW write access to the following
    ## --          Read Only Registers – CQHEADn, STATCURRSQPTRn, and
    ## --          STATRQPIDBn (where is the QP number)
    ## -- [1]    : Reserved
    ## -- [2]    : retry_cnt_fatal_dis
    ## -- [15:3] : Reserved
    ## -- [19:16]: Base count width
    ## --          Approximate number of system clocks that make 4096us.
    ## --          For 400 MHz clock -->Program decimal 11
    ## --          For 200 MHz clock --> Program decimal 10
    ## --          For 125 MHz clock --> Program decimal 09
    ## --          For 100 MHz clock --> Program decimal 09
    ## --          For N MHz clock ---> Value should be CLOG2(4.096 *N)
    ## -- [20:23]: Reserved
    ## -- [31:24]: Software Override QP Number
    sw_override_enable  = 0
    retry_cnt_fatal_dis = 1
    base_count_width    = 10
    sw_override_qp_num  = 0
    config_16bit = 0x0000000f & ( (sw_override_enable & 0x00000001) | ((retry_cnt_fatal_dis<<2) & 0x00000004) )
    xrnic_advanced_conf = (config_16bit & 0x0000ffff) | ((base_count_width << 16) & 0x000f0000) | ( (sw_override_qp_num << 24) & 0xff000000)
    config_str = format(eh.XRNICADCONF, '08x') + ' ' + format(xrnic_advanced_conf, '08x')
    rdma_gbl_config.append(config_str)
    debug_str = debug_str + 'eh.XRNICADCONF: ' + config_str + '\n'

    if (self.debug_path != ''):
      if (is_remote_peer):
        debug_fname = pjoin(self.debug_path, f'debug_rdma2_global_csr_config.txt')
      else:
        debug_fname = pjoin(self.debug_path, f'debug_rdma_global_csr_config.txt')
      helper_lst = []
      helper_lst.append(debug_str)
      self.write2file(debug_fname, '', helper_lst)

    if(is_remote_peer):
      # Generate rdma1_stat_reg_config for simulation
      self.rdma1_stat_reg_config.append(format(eh.ERRBUFWPTR    , '08x'))
      self.rdma1_stat_reg_config.append(format(eh.IPKTERRQWPTR  , '08x'))
      self.rdma1_stat_reg_config.append(format(eh.INSRRPKTCNT   , '08x'))
      self.rdma1_stat_reg_config.append(format(eh.INAMPKTCNT    , '08x'))
      self.rdma1_stat_reg_config.append(format(eh.OUTIOPKTCNT   , '08x'))
      self.rdma1_stat_reg_config.append(format(eh.OUTAMPKTCNT   , '08x'))
      self.rdma1_stat_reg_config.append(format(eh.LSTINPKT      , '08x'))
      self.rdma1_stat_reg_config.append(format(eh.LSTOUTPKT     , '08x'))
      self.rdma1_stat_reg_config.append(format(eh.ININVDUPCNT   , '08x'))
      self.rdma1_stat_reg_config.append(format(eh.INNCKPKTSTS   , '08x'))
      self.rdma1_stat_reg_config.append(format(eh.OUTRNRPKTSTS  , '08x'))
      self.rdma1_stat_reg_config.append(format(eh.WQEPROCSTS    , '08x'))
      self.rdma1_stat_reg_config.append(format(eh.QPMSTS        , '08x'))
      self.rdma1_stat_reg_config.append(format(eh.INALLDRPPKTCNT, '08x'))
      self.rdma1_stat_reg_config.append(format(eh.INNAKPKTCNT   , '08x'))
      self.rdma1_stat_reg_config.append(format(eh.OUTNAKPKTCNT  , '08x'))
      self.rdma1_stat_reg_config.append(format(eh.RESPHNDSTS    , '08x'))
      self.rdma1_stat_reg_config.append(format(eh.RETRYCNTSTS   , '08x'))
      self.rdma1_stat_reg_config.append(format(eh.INCNPPKTCNT   , '08x'))
      self.rdma1_stat_reg_config.append(format(eh.OUTCNPPKTCNT  , '08x'))
      self.rdma1_stat_reg_config.append(format(eh.OUTRDRSPPKTCNT, '08x'))
      self.rdma1_stat_reg_config.append(format(eh.INTSTS        , '08x'))
      self.rdma1_stat_reg_config.append(format(eh.RQINTSTS1     , '08x'))
      self.rdma1_stat_reg_config.append(format(eh.RQINTSTS2     , '08x'))
      self.rdma1_stat_reg_config.append(format(eh.RQINTSTS3     , '08x'))
      self.rdma1_stat_reg_config.append(format(eh.RQINTSTS4     , '08x'))
      self.rdma1_stat_reg_config.append(format(eh.RQINTSTS5     , '08x'))
      self.rdma1_stat_reg_config.append(format(eh.RQINTSTS6     , '08x'))
      self.rdma1_stat_reg_config.append(format(eh.RQINTSTS7     , '08x'))
      self.rdma1_stat_reg_config.append(format(eh.RQINTSTS8     , '08x'))
      self.rdma1_stat_reg_config.append(format(eh.CQINTSTS1     , '08x'))
      self.rdma1_stat_reg_config.append(format(eh.CQINTSTS2     , '08x'))
      self.rdma1_stat_reg_config.append(format(eh.CQINTSTS3     , '08x'))
      self.rdma1_stat_reg_config.append(format(eh.CQINTSTS4     , '08x'))
      self.rdma1_stat_reg_config.append(format(eh.CQINTSTS5     , '08x'))    
      self.rdma1_stat_reg_config.append(format(eh.CQINTSTS6     , '08x'))
      self.rdma1_stat_reg_config.append(format(eh.CQINTSTS7     , '08x'))
      self.rdma1_stat_reg_config.append(format(eh.CQINTSTS8     , '08x'))

      self.rdma1_debug_stat_reg_config.append('eh.ERRBUFWPTR      : ' + format(eh.ERRBUFWPTR    , '08x'))
      self.rdma1_debug_stat_reg_config.append('eh.IPKTERRQWPTR    : ' + format(eh.IPKTERRQWPTR  , '08x'))
      self.rdma1_debug_stat_reg_config.append('eh.INSRRPKTCNT     : ' + format(eh.INSRRPKTCNT   , '08x'))
      self.rdma1_debug_stat_reg_config.append('eh.INAMPKTCNT      : ' + format(eh.INAMPKTCNT    , '08x'))
      self.rdma1_debug_stat_reg_config.append('eh.OUTIOPKTCNT     : ' + format(eh.OUTIOPKTCNT   , '08x'))
      self.rdma1_debug_stat_reg_config.append('eh.OUTAMPKTCNT     : ' + format(eh.OUTAMPKTCNT   , '08x'))
      self.rdma1_debug_stat_reg_config.append('eh.LSTINPKT        : ' + format(eh.LSTINPKT      , '08x'))
      self.rdma1_debug_stat_reg_config.append('eh.LSTOUTPKT       : ' + format(eh.LSTOUTPKT     , '08x'))
      self.rdma1_debug_stat_reg_config.append('eh.ININVDUPCNT     : ' + format(eh.ININVDUPCNT   , '08x'))
      self.rdma1_debug_stat_reg_config.append('eh.INNCKPKTSTS     : ' + format(eh.INNCKPKTSTS   , '08x'))
      self.rdma1_debug_stat_reg_config.append('eh.OUTRNRPKTSTS    : ' + format(eh.OUTRNRPKTSTS  , '08x'))
      self.rdma1_debug_stat_reg_config.append('eh.WQEPROCSTS      : ' + format(eh.WQEPROCSTS    , '08x'))
      self.rdma1_debug_stat_reg_config.append('eh.QPMSTS          : ' + format(eh.QPMSTS        , '08x'))
      self.rdma1_debug_stat_reg_config.append('eh.INALLDRPPKTCNT  : ' + format(eh.INALLDRPPKTCNT, '08x'))
      self.rdma1_debug_stat_reg_config.append('eh.INNAKPKTCNT     : ' + format(eh.INNAKPKTCNT   , '08x'))
      self.rdma1_debug_stat_reg_config.append('eh.OUTNAKPKTCNT    : ' + format(eh.OUTNAKPKTCNT  , '08x'))
      self.rdma1_debug_stat_reg_config.append('eh.RESPHNDSTS      : ' + format(eh.RESPHNDSTS    , '08x'))
      self.rdma1_debug_stat_reg_config.append('eh.RETRYCNTSTS     : ' + format(eh.RETRYCNTSTS   , '08x'))
      self.rdma1_debug_stat_reg_config.append('eh.INCNPPKTCNT     : ' + format(eh.INCNPPKTCNT   , '08x'))
      self.rdma1_debug_stat_reg_config.append('eh.OUTCNPPKTCNT    : ' + format(eh.OUTCNPPKTCNT  , '08x'))
      self.rdma1_debug_stat_reg_config.append('eh.OUTRDRSPPKTCNT  : ' + format(eh.OUTRDRSPPKTCNT, '08x'))
      self.rdma1_debug_stat_reg_config.append('eh.INTSTS          : ' + format(eh.INTSTS        , '08x'))
      self.rdma1_debug_stat_reg_config.append('eh.RQINTSTS1       : ' + format(eh.RQINTSTS1     , '08x'))
      self.rdma1_debug_stat_reg_config.append('eh.RQINTSTS2       : ' + format(eh.RQINTSTS2     , '08x'))
      self.rdma1_debug_stat_reg_config.append('eh.RQINTSTS3       : ' + format(eh.RQINTSTS3     , '08x'))
      self.rdma1_debug_stat_reg_config.append('eh.RQINTSTS4       : ' + format(eh.RQINTSTS4     , '08x'))
      self.rdma1_debug_stat_reg_config.append('eh.RQINTSTS5       : ' + format(eh.RQINTSTS5     , '08x'))
      self.rdma1_debug_stat_reg_config.append('eh.RQINTSTS6       : ' + format(eh.RQINTSTS6     , '08x'))
      self.rdma1_debug_stat_reg_config.append('eh.RQINTSTS7       : ' + format(eh.RQINTSTS7     , '08x'))
      self.rdma1_debug_stat_reg_config.append('eh.RQINTSTS8       : ' + format(eh.RQINTSTS8     , '08x'))
      self.rdma1_debug_stat_reg_config.append('eh.CQINTSTS1       : ' + format(eh.CQINTSTS1     , '08x'))
      self.rdma1_debug_stat_reg_config.append('eh.CQINTSTS2       : ' + format(eh.CQINTSTS2     , '08x'))
      self.rdma1_debug_stat_reg_config.append('eh.CQINTSTS3       : ' + format(eh.CQINTSTS3     , '08x'))
      self.rdma1_debug_stat_reg_config.append('eh.CQINTSTS4       : ' + format(eh.CQINTSTS4     , '08x'))
      self.rdma1_debug_stat_reg_config.append('eh.CQINTSTS5       : ' + format(eh.CQINTSTS5     , '08x'))    
      self.rdma1_debug_stat_reg_config.append('eh.CQINTSTS6       : ' + format(eh.CQINTSTS6     , '08x'))
      self.rdma1_debug_stat_reg_config.append('eh.CQINTSTS7       : ' + format(eh.CQINTSTS7     , '08x'))
      self.rdma1_debug_stat_reg_config.append('eh.CQINTSTS8       : ' + format(eh.CQINTSTS8     , '08x'))

      # Generate rdma2_stat_reg_config for simulation
      self.rdma2_stat_reg_config.append(format(eh.ERRBUFWPTR    , '08x'))
      self.rdma2_stat_reg_config.append(format(eh.IPKTERRQWPTR  , '08x'))
      self.rdma2_stat_reg_config.append(format(eh.INSRRPKTCNT   , '08x'))
      self.rdma2_stat_reg_config.append(format(eh.INAMPKTCNT    , '08x'))
      self.rdma2_stat_reg_config.append(format(eh.OUTIOPKTCNT   , '08x'))
      self.rdma2_stat_reg_config.append(format(eh.OUTAMPKTCNT   , '08x'))
      self.rdma2_stat_reg_config.append(format(eh.LSTINPKT      , '08x'))
      self.rdma2_stat_reg_config.append(format(eh.LSTOUTPKT     , '08x'))
      self.rdma2_stat_reg_config.append(format(eh.ININVDUPCNT   , '08x'))
      self.rdma2_stat_reg_config.append(format(eh.INNCKPKTSTS   , '08x'))
      self.rdma2_stat_reg_config.append(format(eh.OUTRNRPKTSTS  , '08x'))
      self.rdma2_stat_reg_config.append(format(eh.WQEPROCSTS    , '08x'))
      self.rdma2_stat_reg_config.append(format(eh.QPMSTS        , '08x'))
      self.rdma2_stat_reg_config.append(format(eh.INALLDRPPKTCNT, '08x'))
      self.rdma2_stat_reg_config.append(format(eh.INNAKPKTCNT   , '08x'))
      self.rdma2_stat_reg_config.append(format(eh.OUTNAKPKTCNT  , '08x'))
      self.rdma2_stat_reg_config.append(format(eh.RESPHNDSTS    , '08x'))
      self.rdma2_stat_reg_config.append(format(eh.RETRYCNTSTS   , '08x'))
      self.rdma2_stat_reg_config.append(format(eh.INCNPPKTCNT   , '08x'))
      self.rdma2_stat_reg_config.append(format(eh.OUTCNPPKTCNT  , '08x'))
      self.rdma2_stat_reg_config.append(format(eh.OUTRDRSPPKTCNT, '08x'))
      self.rdma2_stat_reg_config.append(format(eh.INTSTS        , '08x'))
      self.rdma2_stat_reg_config.append(format(eh.RQINTSTS1     , '08x'))
      self.rdma2_stat_reg_config.append(format(eh.RQINTSTS2     , '08x'))
      self.rdma2_stat_reg_config.append(format(eh.RQINTSTS3     , '08x'))
      self.rdma2_stat_reg_config.append(format(eh.RQINTSTS4     , '08x'))
      self.rdma2_stat_reg_config.append(format(eh.RQINTSTS5     , '08x'))
      self.rdma2_stat_reg_config.append(format(eh.RQINTSTS6     , '08x'))
      self.rdma2_stat_reg_config.append(format(eh.RQINTSTS7     , '08x'))
      self.rdma2_stat_reg_config.append(format(eh.RQINTSTS8     , '08x'))
      self.rdma2_stat_reg_config.append(format(eh.CQINTSTS1     , '08x'))
      self.rdma2_stat_reg_config.append(format(eh.CQINTSTS2     , '08x'))
      self.rdma2_stat_reg_config.append(format(eh.CQINTSTS3     , '08x'))
      self.rdma2_stat_reg_config.append(format(eh.CQINTSTS4     , '08x'))
      self.rdma2_stat_reg_config.append(format(eh.CQINTSTS5     , '08x'))    
      self.rdma2_stat_reg_config.append(format(eh.CQINTSTS6     , '08x'))
      self.rdma2_stat_reg_config.append(format(eh.CQINTSTS7     , '08x'))
      self.rdma2_stat_reg_config.append(format(eh.CQINTSTS8     , '08x'))

      self.rdma2_debug_stat_reg_config.append('eh.ERRBUFWPTR      : ' + format(eh.ERRBUFWPTR    , '08x'))
      self.rdma2_debug_stat_reg_config.append('eh.IPKTERRQWPTR    : ' + format(eh.IPKTERRQWPTR  , '08x'))
      self.rdma2_debug_stat_reg_config.append('eh.INSRRPKTCNT     : ' + format(eh.INSRRPKTCNT   , '08x'))
      self.rdma2_debug_stat_reg_config.append('eh.INAMPKTCNT      : ' + format(eh.INAMPKTCNT    , '08x'))
      self.rdma2_debug_stat_reg_config.append('eh.OUTIOPKTCNT     : ' + format(eh.OUTIOPKTCNT   , '08x'))
      self.rdma2_debug_stat_reg_config.append('eh.OUTAMPKTCNT     : ' + format(eh.OUTAMPKTCNT   , '08x'))
      self.rdma2_debug_stat_reg_config.append('eh.LSTINPKT        : ' + format(eh.LSTINPKT      , '08x'))
      self.rdma2_debug_stat_reg_config.append('eh.LSTOUTPKT       : ' + format(eh.LSTOUTPKT     , '08x'))
      self.rdma2_debug_stat_reg_config.append('eh.ININVDUPCNT     : ' + format(eh.ININVDUPCNT   , '08x'))
      self.rdma2_debug_stat_reg_config.append('eh.INNCKPKTSTS     : ' + format(eh.INNCKPKTSTS   , '08x'))
      self.rdma2_debug_stat_reg_config.append('eh.OUTRNRPKTSTS    : ' + format(eh.OUTRNRPKTSTS  , '08x'))
      self.rdma2_debug_stat_reg_config.append('eh.WQEPROCSTS      : ' + format(eh.WQEPROCSTS    , '08x'))
      self.rdma2_debug_stat_reg_config.append('eh.QPMSTS          : ' + format(eh.QPMSTS        , '08x'))
      self.rdma2_debug_stat_reg_config.append('eh.INALLDRPPKTCNT  : ' + format(eh.INALLDRPPKTCNT, '08x'))
      self.rdma2_debug_stat_reg_config.append('eh.INNAKPKTCNT     : ' + format(eh.INNAKPKTCNT   , '08x'))
      self.rdma2_debug_stat_reg_config.append('eh.OUTNAKPKTCNT    : ' + format(eh.OUTNAKPKTCNT  , '08x'))
      self.rdma2_debug_stat_reg_config.append('eh.RESPHNDSTS      : ' + format(eh.RESPHNDSTS    , '08x'))
      self.rdma2_debug_stat_reg_config.append('eh.RETRYCNTSTS     : ' + format(eh.RETRYCNTSTS   , '08x'))
      self.rdma2_debug_stat_reg_config.append('eh.INCNPPKTCNT     : ' + format(eh.INCNPPKTCNT   , '08x'))
      self.rdma2_debug_stat_reg_config.append('eh.OUTCNPPKTCNT    : ' + format(eh.OUTCNPPKTCNT  , '08x'))
      self.rdma2_debug_stat_reg_config.append('eh.OUTRDRSPPKTCNT  : ' + format(eh.OUTRDRSPPKTCNT, '08x'))
      self.rdma2_debug_stat_reg_config.append('eh.INTSTS          : ' + format(eh.INTSTS        , '08x'))
      self.rdma2_debug_stat_reg_config.append('eh.RQINTSTS1       : ' + format(eh.RQINTSTS1     , '08x'))
      self.rdma2_debug_stat_reg_config.append('eh.RQINTSTS2       : ' + format(eh.RQINTSTS2     , '08x'))
      self.rdma2_debug_stat_reg_config.append('eh.RQINTSTS3       : ' + format(eh.RQINTSTS3     , '08x'))
      self.rdma2_debug_stat_reg_config.append('eh.RQINTSTS4       : ' + format(eh.RQINTSTS4     , '08x'))
      self.rdma2_debug_stat_reg_config.append('eh.RQINTSTS5       : ' + format(eh.RQINTSTS5     , '08x'))
      self.rdma2_debug_stat_reg_config.append('eh.RQINTSTS6       : ' + format(eh.RQINTSTS6     , '08x'))
      self.rdma2_debug_stat_reg_config.append('eh.RQINTSTS7       : ' + format(eh.RQINTSTS7     , '08x'))
      self.rdma2_debug_stat_reg_config.append('eh.RQINTSTS8       : ' + format(eh.RQINTSTS8     , '08x'))
      self.rdma2_debug_stat_reg_config.append('eh.CQINTSTS1       : ' + format(eh.CQINTSTS1     , '08x'))
      self.rdma2_debug_stat_reg_config.append('eh.CQINTSTS2       : ' + format(eh.CQINTSTS2     , '08x'))
      self.rdma2_debug_stat_reg_config.append('eh.CQINTSTS3       : ' + format(eh.CQINTSTS3     , '08x'))
      self.rdma2_debug_stat_reg_config.append('eh.CQINTSTS4       : ' + format(eh.CQINTSTS4     , '08x'))
      self.rdma2_debug_stat_reg_config.append('eh.CQINTSTS5       : ' + format(eh.CQINTSTS5     , '08x'))    
      self.rdma2_debug_stat_reg_config.append('eh.CQINTSTS6       : ' + format(eh.CQINTSTS6     , '08x'))
      self.rdma2_debug_stat_reg_config.append('eh.CQINTSTS7       : ' + format(eh.CQINTSTS7     , '08x'))
      self.rdma2_debug_stat_reg_config.append('eh.CQINTSTS8       : ' + format(eh.CQINTSTS8     , '08x'))
      
    return rdma_gbl_config
    logger.info("RDMA global CSR configuration generation is done")

  def gen_rdma_configurations(self, has_remote_peer=False):
    """Generate RDMA configurations
    Args:
      has_remote_peer (bool): A signal used to indicate a system with remote RDMA peer
    Returns:
      none
    """
    logger.info('Generating RDMA configurations')
    logger.info(f'num_flows={self.num_flow}')
    mac_dst_lsb, mac_dst_msb = self.get_mac_addr(self.eth_dst_seed)
    mac_src_lsb, mac_src_msb = self.get_mac_addr(self.eth_src_seed)
    self.get_ip_list()
    ip_src = self.ip_src
    logger.info('Generating RDMA global CSR configuration')

    #  en_intr     (int): 9-bit interrupt enable signals. Default is disabled
    #                 -- [0]: Incoming packet validation error interrupt enable
    #                 -- [1]: Incoming MAD packet received interrupt enable
    #                 -- [2]: Reserved
    #                 -- [3]: RNR NACK generated interrupt enable
    #                 -- [4]: WQE completion interrupt enable (asserted for QPs for
    #                         which QPCONF[3] bit is set)
    #                 -- [5]: Illegal opcode posted in SEND Queue interrupt enable
    #                 -- [6]: RQ Packet received interrupt enable (asserted for QPs for
    #                         which QPCONF[2] bit is set
    #                 -- [7]: Fatal error received interrupt enable
    #                 -- [8]: Interrupt enable for CNP scheduling
    en_intr = 0x00ff
    self.rdma_global_config = self.gen_rdma_global_csr_config(mac_src_lsb, mac_src_msb, ip_src, self.udp_sport, self.num_qp, dbuf_size=self.data_buffer_size, num_dbuf=self.num_data_buffer, en_intr=en_intr)
    
    # TODO: Start here
    for i in range(self.num_flow):
      # qpid starts from 2, while pd_num starts from 0
      qpid = i+2
      # we use the same dst_qpid with qpid
      dst_qpid = i+2
      pd_num = i
      part_key = self.partition_key + i
      # r_key is 8-bit in ERNIC RDMA IP
      r_key    = (self.r_key + i) & 0x000000ff
      ip_dst = self.ip_dst_list[i]
      # generate rdma per-queue CSR configuration
      logger.info('Generating RDMA per-queue CSR configuration')

      self.gen_rdma_perq_csr_config(qpid, ip_dst, mac_dst_lsb, mac_dst_msb, dst_qpid, part_key, self.sq_psn, pd_num, sq_depth=self.sq_depth, rq_depth=self.rq_depth, mtu_sz=self.mtu_size, rq_buf_sz=self.rq_buffer_size)

      #virt_addr = pd_num*self.mr_buf_size
      virt_addr = self.rm_viraddr_seed
      phy_addr  = self.dst_baseaddr + i
      # generate rdma memory registration configuration. At the moment, assuming a unique pd_num per qpid
      logger.info('Generating RDMA per-pd_num memory registration configuration')
      self.gen_rdma_mr_per_pd_num(pd_num, self.mr_buf_size, r_key, virt_addr, phy_addr)

      if(has_remote_peer and (i==0)):
        # Only support one remote peer at the moment
        self.rdma2_global_config = self.gen_rdma_global_csr_config(mac_dst_lsb, mac_dst_msb, ip_dst, self.udp_sport, self.num_qp, dbuf_size=self.data_buffer_size, num_dbuf=self.num_data_buffer, en_intr=0, is_remote_peer=True)
        self.gen_rdma_perq_csr_config(qpid, ip_src, mac_src_lsb, mac_src_msb, dst_qpid, part_key, self.sq_psn, pd_num, sq_depth=self.sq_depth, rq_depth=self.rq_depth, mtu_sz=self.mtu_size, rq_buf_sz=self.rq_buffer_size, is_remote_peer=True)
        self.rdma2_mr_config = self.rdma_mr_config

      # generate a WQE
      wrid = i+1

      assert(self.src_baseaddr_location in eh.location_lst), "Please provide a correct location from ['dev_mem','sys_mem']"
      if(self.src_baseaddr_location == 'dev_mem'):
        #adding offset of 0xa35
        logger.info('Payload is stored at the device memory')
        payload_addr = eh.dev_offset + self.src_baseaddr + pd_num*self.mr_buf_size
      else:
        logger.info('Payload is stored at the host memory')
        payload_addr = self.src_baseaddr + pd_num*self.mr_buf_size
      payload_len = self.paylaod_size
      assert(payload_len>=16), "Please provide a payload > 16B, as we always set 'send_data' to 0 in a WQE"
      #remote_offset = self.dst_baseaddr + pd_num*self.mr_buf_size
      remote_offset = self.rm_viraddr_seed
      remote_key = r_key

      # opcode: 8-bit ERNIC RDMA opcode
      #   8’h00 -- 'write', RDMA WRITE
      #   8’h01 -- 'write_immdt', RDMA_WRITE WITH IMMDT
      #   8’h02 -- 'send', RDMA SEND
      #   8’h03 -- 'send_immdt', RDMA SEND WITH IMMDT
      #   8’h04 -- 'read', RDMA READ
      #   8’h0C -- 'send_inv', RDMA SEND WITH INVALIDATE
      #   All other values are reserved.
      assert(self.pkt_op in eh.opcode_lst), "Please provide a correct opcode from ['write', 'write_immdt', 'send', 'send_immdt', 'read', 'send_inv']"
      opcode = eh.opcode_lst.index(self.pkt_op)
      if (opcode == 0x5):
        opcode = 0x0c

      # Generate two send operations
      self.gen_rdma_wqe(qpid, wrid, 0, payload_addr, payload_len, opcode, remote_offset, remote_key)
      #self.gen_rdma_wqe(qpid, wrid, 1, payload_addr + 0x40, payload_len, opcode, remote_offset, remote_key)

      '''
      # FIXME: Temp multiple operations (read after write) testing
      opcode = eh.opcode_lst.index('write')
      if (opcode == 0x5):
        opcode = 0x0c
      self.gen_rdma_wqe(qpid, wrid, 0, payload_addr, payload_len, opcode, remote_offset, remote_key)

      # opcode: 8-bit ERNIC RDMA opcode
      #   8’h00 -- 'write', RDMA WRITE
      #   8’h01 -- 'write_immdt', RDMA_WRITE WITH IMMDT
      #   8’h02 -- 'send', RDMA SEND
      #   8’h03 -- 'send_immdt', RDMA SEND WITH IMMDT
      #   8’h04 -- 'read', RDMA READ
      #   8’h0C -- 'send_inv', RDMA SEND WITH INVALIDATE
      #   All other values are reserved.
      assert(self.pkt_op in eh.opcode_lst), "Please provide a correct opcode from ['write', 'write_immdt', 'send', 'send_immdt', 'read', 'send_inv']"
      opcode = eh.opcode_lst.index(self.pkt_op)
      if (opcode == 0x5):
        opcode = 0x0c
      self.gen_rdma_wqe(qpid, wrid+1, 1, payload_addr, payload_len, opcode, remote_offset, remote_key)
      '''
      # Configure SQPIi
      sq_pidb_offset = self.get_rdma_per_q_config_addr(eh.SQPIi, qpid)
      sq_pidb_config_str = format(sq_pidb_offset, '08x') + ' ' + format(self.sq_pidb, '08x')
      debug_str = 'eh.SQPIi: ' + sq_pidb_config_str + '\n'
      self.rdma_per_q_config.append(sq_pidb_config_str)

      # Configuration used to post receive operations of the remote peer
      if (opcode == 0x2) or (opcode == 0x3):
        # 1. poll rq_pidb
        rq_pidb_offset = self.get_rdma_per_q_config_addr(eh.STATRQPIDBi , qpid)
        # As we only have one send per queue, the golden number of send per queue is '1'
        rq_config_str = format(rq_pidb_offset, '08x') + ' ' + format(len(self.rdma_wqe_list), '08x')
        self.rdma2_per_q_recv_config.append(rq_config_str)
        # 2. Update rq_cidb with value from reading rq_pidb register
        rq_cidb_offset = self.get_rdma_per_q_config_addr(eh.RQCIi, qpid)
        # rq_cidb register will be updated with the returned value from rq_pidb. '0xffff_ffff'
        # is used to detect rq_cidb address when reading configuration file in the hardware
        # testbench.
        rq_config_str = format(rq_cidb_offset, '08x') + ' ' + format(0xffffffff, '08x')
        self.rdma2_per_q_recv_config.append(rq_config_str)
      
      if (self.debug_path != ''):
        debug_fname = pjoin(self.debug_path, f'debug_rdma_perq_csr_config_qpid_{qpid}.txt')
        helper_lst = []
        helper_lst.append(debug_str)
        self.write2file(debug_fname, '', helper_lst, mode='a')


  def gen_rdma_perq_csr_config(self, qpid, dst_ip, dst_mac_lsb, dst_mac_msb, dst_qpid, part_key, sq_psn, pd_num, sq_depth=8, rq_depth=8, en_rq_intr=0, en_cq_intr=0, en_hw_handshake=0, en_cqe_write=1, mtu_sz=4096, rq_buf_sz=1024, is_remote_peer=False):
    """Generate RDMA per-queue control status register configurations
    Args:
      qpid            (int): queue pair ID. ID range is [0, 255]
      dst_ip          (int): destination IPv4 address
      dst_mac_lsb     (int): destination MAC address lsb, which is 32 bits. [31:0] mac_lsb
      dst_mac_msb     (int): destination MAC address msb, which is 16 bits. [47:32] mac_msb
      dst_qpid        (int): destination connected queue pair ID, 24 bits
      part_key        (int): partition key, 16-bit
      sq_psn          (int): Send Queue packet sequence number, 24-bit
      pd_num          (int): protection domain number assigned to the qpid-th QP, 24-bit
      sq_depth        (int): depth of the qpid-th Send Queue, 16-bit. Default value is set to 8
      rq_depth        (int): depth of the qpid-th Receive Queue, 16-bit. Default value is set to 8
      en_rq_intr      (bit): enable RQ interrupt. Default value is 1'b0
      en_cq_intr      (bit): enable CQ interrupt. Default value is 1'b0
      en_hw_handshake (bit): enable hardware handshaking. Default value is 1'b0
      en_cqe_write    (bit): enable CQE write. Default value is 1'b1
      mtu_sz          (int): MTU size. Default is 4096B
      rq_buf_sz       (int): RQ buffer size. Default value is 1024B
      is_remote_peer (bool): a signal to indicate remote peer. Default value is False
    Returns:
      none
    """
    debug_str = ''
    # Configure destination IPv4 address for the qpid-th QP
    dst_ip_offset = self.get_rdma_per_q_config_addr(eh.IPDESADDR1i, qpid)
    config_str = format(dst_ip_offset, '08x') + ' ' + format(dst_ip, '08x')
    if(is_remote_peer):
      self.rdma2_per_q_config.append(config_str)
    else:
      self.rdma_per_q_config.append(config_str)
    debug_str = 'eh.IPDESADDR1i: ' + config_str + '\n'

    # Configure destination MAC address for the qpid-th QP
    dst_mac_lsb_offset = self.get_rdma_per_q_config_addr(eh.MACDESADDLSBi, qpid)
    config_str = format(dst_mac_lsb_offset, '08x') + ' ' + format(dst_mac_lsb, '08x')
    if(is_remote_peer):
      self.rdma2_per_q_config.append(config_str)
    else:
      self.rdma_per_q_config.append(config_str)
    debug_str = debug_str + 'eh.MACDESADDLSBi: ' + config_str + '\n'
    dst_mac_msb_offset = self.get_rdma_per_q_config_addr(eh.MACDESADDMSBi, qpid)
    config_str = format(dst_mac_msb_offset, '08x') + ' ' + format(dst_mac_msb, '08x')
    if(is_remote_peer):
      self.rdma2_per_q_config.append(config_str)
    else:
      self.rdma_per_q_config.append(config_str)
    debug_str = debug_str + 'eh.MACDESADDMSBi: ' + config_str + '\n'

    # Configure receive queue (rq) buffer for the qpid-th QP
    # [31:8]: receive queue buffer baseaddress is 256B aligned. 
    # 256B is equal to the receive queue buffer element size * depth of receive queue.
    # In the simulation, we set 0x70000 as the RQ buffer base address. Assume 8KB for each
    # SQ, RQ and CQ per flow. Maximum depth of SQ will be 128 (8KB/64)
    rq_buf_baseaddr_offset = self.get_rdma_per_q_config_addr(eh.RQBAi, qpid)
    # qpid starts from 2, 0x2000 = 8*1024, 8KB range
    rq_buf_baseaddr = 0x70000 + (qpid-2)*0x2000
    self.qpid_rq_dict[qpid] = rq_buf_baseaddr
    config_str = format(rq_buf_baseaddr_offset, '08x') + ' ' + format(rq_buf_baseaddr, '08x')
    if(is_remote_peer):
      self.rdma2_per_q_config.append(config_str)
    else:
      self.rdma_per_q_config.append(config_str)
    debug_str = debug_str + 'eh.RQBAi: ' + config_str + '\n'
    rq_buf_baseaddr_offset_msb = self.get_rdma_per_q_config_addr(eh.RQBAMSBi, qpid)
    config_str = format(rq_buf_baseaddr_offset_msb, '08x') + ' ' + format(0, '08x')
    if(is_remote_peer):
      self.rdma2_per_q_config.append(config_str)
    else:
      self.rdma_per_q_config.append(config_str)
    debug_str = debug_str + 'eh.RQBAMSBi: ' + config_str + '\n'

    # Configure completion queue (cq) buffer for the qpid-th QP
    # In the simulation, we set 0x80000 as the CQ buffer base address
    cq_buf_baseaddr_offset = self.get_rdma_per_q_config_addr(eh.CQBAi, qpid)
    cq_buf_baseaddr = 0x80000 + (qpid-2)*0x2000
    self.qpid_cq_dict[qpid] = cq_buf_baseaddr
    config_str = format(cq_buf_baseaddr_offset, '08x') + ' ' + format(cq_buf_baseaddr, '08x')
    if(is_remote_peer):
      self.rdma2_per_q_config.append(config_str)
    else:
      self.rdma_per_q_config.append(config_str)
    debug_str = debug_str + 'eh.CQBAi: ' + config_str + '\n'
    cq_buf_baseaddr_offset_msb = self.get_rdma_per_q_config_addr(eh.CQBAMSBi, qpid)
    cq_buf_baseaddr_msb = 0
    config_str = format(cq_buf_baseaddr_offset_msb, '08x') + ' ' + format(cq_buf_baseaddr_msb, '08x')
    if(is_remote_peer):
      self.rdma2_per_q_config.append(config_str)
    else:
      self.rdma_per_q_config.append(config_str)
    debug_str = debug_str + 'eh.CQBAMSBi: ' + config_str + '\n'

    # Configure send queue (sq) buffer for the qpid-th QP
    # In the simulation, we set 0x90000 as the SQ buffer base address
    sq_buf_baseaddr_offset = self.get_rdma_per_q_config_addr(eh.SQBAi, qpid)
    sq_buf_baseaddr = 0x90000 + (qpid-2)*0x2000
    self.qpid_sq_dict[qpid] = sq_buf_baseaddr
    config_str = format(sq_buf_baseaddr_offset, '08x') + ' ' + format(sq_buf_baseaddr, '08x')
    if(is_remote_peer):
      self.rdma2_per_q_config.append(config_str)
    else:
      self.rdma_per_q_config.append(config_str)
    debug_str = debug_str + 'eh.SQBAi: ' + config_str + '\n'
    sq_buf_baseaddr_offset_msb = self.get_rdma_per_q_config_addr(eh.SQBAMSBi, qpid)
    sq_buf_baseaddr_msb = 0
    config_str = format(sq_buf_baseaddr_offset_msb, '08x') + ' ' + format(sq_buf_baseaddr_msb, '08x')
    if(is_remote_peer):
      self.rdma2_per_q_config.append(config_str)
    else:
      self.rdma_per_q_config.append(config_str)
    debug_str = debug_str + 'eh.SQBAMSBi: ' + config_str + '\n'

    # Configure CQ door bell (DB) address for the qpid-th QP
    # This register provides the address of the Completion Queue doorbell register. 
    # Upon completion of a new SEND Work queue entry, the ERNIC IP updates the CQ 
    # doorbell values in the address pointed to by this register. Register space range
    # is from 0xa0000 to 0xa0fff
    cq_db_baseaddr_offset = self.get_rdma_per_q_config_addr(eh.CQDBADDi, qpid)
    cq_db_baseaddr        = 0xa0000 + (qpid-2)*0x100
    self.qpid_cq_db_dict[qpid] = cq_db_baseaddr
    config_str = format(cq_db_baseaddr_offset, '08x') + ' ' + format(cq_db_baseaddr, '08x')
    if(is_remote_peer):
      self.rdma2_per_q_config.append(config_str)
    else:
      self.rdma_per_q_config.append(config_str)
    debug_str = debug_str + 'eh.CQDBADDi: ' + config_str + '\n'
    cq_db_baseaddr_offset_msb = self.get_rdma_per_q_config_addr(eh.CQDBADDMSBi, qpid)
    cq_db_baseaddr_msb        = 0
    config_str = format(cq_db_baseaddr_offset_msb, '08x') + ' ' + format(cq_db_baseaddr_msb, '08x')
    if(is_remote_peer):
      self.rdma2_per_q_config.append(config_str)
    else:
      self.rdma_per_q_config.append(config_str)
    debug_str = debug_str + 'eh.CQDBADDMSBi: ' + config_str + '\n'

    # Configure receive queue write pointer door bell for the qpid-th QP
    # This register provides the address of the Receive Queue doorbell register. Upon 
    # reception of a new incoming RDMA SEND packet, the ERNIC IP updates the RQ doorbell 
    # values in the address pointed to by this register. Register space range is from
    # 0xa1000 to 0xa1fff
    rq_wptr_db_baseaddr_offset = self.get_rdma_per_q_config_addr(eh.RQWPTRDBADDi, qpid)
    rq_wptr_db_baseaddr = 0xa1000 + (qpid-2)*0x100
    self.rq_wptr_db_dict[qpid] = rq_wptr_db_baseaddr
    config_str = format(rq_wptr_db_baseaddr_offset, '08x') + ' ' + format(rq_wptr_db_baseaddr, '08x')
    if(is_remote_peer):
      self.rdma2_per_q_config.append(config_str)
    else:
      self.rdma_per_q_config.append(config_str)
    debug_str = debug_str + 'eh.RQWPTRDBADDi: ' + config_str + '\n'

    # Configure destination QP configuration for the qpid-th QP
    # This register is configured at connection time by the SW and provides the remote QPID 
    # connected to this QP. All outgoing packets from this QP are sent with this QPID as 
    # the destination QPID.
		# [23:0]: Destination Connected QPID
    dst_qpid_offset = self.get_rdma_per_q_config_addr(eh.DESTQPCONFi, qpid)
    config_str = format(dst_qpid_offset, '08x') + ' ' + format(dst_qpid, '08x')
    if(is_remote_peer):
      self.rdma2_per_q_config.append(config_str)
    else:
      self.rdma_per_q_config.append(config_str)
    debug_str = debug_str + 'eh.DESTQPCONFi: ' + config_str + '\n'

    # Configure queue depth for the qpid-th QP
    # This register defines the queue depths for send, completion and receive queues.
		# -- [15:0] : Send Q depth (CQ will have the same depth)
		# -- [31:16]: Receive Q depth
    qdepth_offset = self.get_rdma_per_q_config_addr(eh.QDEPTHi, qpid)
    qdepth = ((rq_depth<<16) & 0xffff0000) | (sq_depth & 0x0000ffff)
    config_str = format(qdepth_offset, '08x') + ' ' + format(qdepth, '08x')
    if(is_remote_peer):
      self.rdma2_per_q_config.append(config_str)
    else:
      self.rdma_per_q_config.append(config_str)
    debug_str = debug_str + 'eh.QDEPTHi: ' + config_str + '\n'

    # Configure queue pair control for the qpid-th QP
    # [0]: QP enable – Should be set to 1 for all active QPs. A disabled QP will not be 
    #      able to receive or transmit packets.
		# [2]: RQ interrupt enable – When enabled, allows the receive queue interrupt to be 
    #      generated for every new packet received on the receive queue
		# [3]: CQ interrupt enable – When enabled, allows the completion queue interrupt to 
    #      be generated for every send work queue entry completion
		# [4]: HW Handshake disable – This bit when reset to 0 enables the HW handshake ports 
    #      for doorbell exchange. If set, all doorbell values are exchanged through writes 
    #      through the AXI4 or AXI4-Lite interface.
		# [5]: CQE write enable – This bit when set, enables completion queue entry writes. 
    #      The writes are disabled when this bit is reset. CQE writes can be enabled to 
    #      debug failed completions.
		# [6]: QP under recovery. This bit need to be set in the fatal clearing process.
		# [7]: QP configured for IPv4 or IPv6
	  #      0 - IPv4
	  #      1 - IPv6 - not supported in this simulation
		# [10:8]: Path MTU
    #      000 – 256B 
    #      001 – 512B
    #      010 – 1024B
    #      011 – 2048B
    #      100 - 4096B (default)
    #      101 to 111 - Reserved
    # [31:16]: RQ Buffer size (in multiple of 256B). This is the size of each 
    #          element in the request and not the size of the entire request. 
    #          For example, when RQ Buffer size is 1 and we have two send operations.
    #          The baseaddress of RQ is 0x10000. Payload of the 1st send will be written
    #          into 0x10000, while payload of the 2nd send will be written into 
    #          (0x10000 + 1*256) = 0x10100
    mtu_list = [256, 512, 1024, 2048, 4096]
    assert(mtu_sz in mtu_list), "Please provide correct mtu size from [256, 512, 1024, 2048, 4096]"
    mtu_config = mtu_list.index(mtu_sz) & 0x00000007
    en_qp = 1
    ip_proto = 0
    qp_recovery = 0
    qp_ctrl_16bit = ((mtu_config<<8) & 0x0000ff00) | ((ip_proto<<7) & 0x00000080) | ((qp_recovery<<6) & 0x00000040) | ((en_cqe_write<<5) & 0x00000020) | ((en_hw_handshake<<4) & 0x00000010) | ((en_cq_intr<<3) & 0x00000008) | ((en_rq_intr<<2) & 0x00000004) | (en_qp & 0x00000003)
    qp_ctrl = ((rq_buf_sz<<16) & 0xffff0000) | (qp_ctrl_16bit & 0x0000ffff)
    qp_ctrl_offset = self.get_rdma_per_q_config_addr(eh.QPCONFi, qpid)
    config_str = format(qp_ctrl_offset, '08x') + ' ' + format(qp_ctrl, '08x')
    if(is_remote_peer):
      self.rdma2_per_q_config.append(config_str)
    else:
      self.rdma_per_q_config.append(config_str)
    debug_str = debug_str + 'eh.QPCONFi: ' + config_str + '\n'

    # Configure 8-bit traffic class, 8-bit time to live and 16-bit partition key
    traffic_class = 0
    time_to_live  = 64
    qp_adv_conf = ((part_key<<16) & 0xffff0000) | ((time_to_live<<8) & 0x0000ff00) | (traffic_class & 0x000000ff)
    qp_adv_conf_baseaddr = self.get_rdma_per_q_config_addr(eh.QPADVCONFi, qpid)
    config_str = format(qp_adv_conf_baseaddr, '08x') + ' ' + format(qp_adv_conf, '08x')
    if(is_remote_peer):
      self.rdma2_per_q_config.append(config_str)
    else:
      self.rdma_per_q_config.append(config_str)
    debug_str = debug_str + 'eh.QPADVCONFi: ' + config_str + '\n'

    # Configure SQ packet sequenece number (PSN) for the qpid-th QP
    # This register is initialized at connection time by the SW. After that the HW updates 
    # it for every outgoing packet and should not be updated by the SW.﻿ This register does 
    # not exist for QP1.
    sq_psn_offset = self.get_rdma_per_q_config_addr(eh.SQPSNi, qpid)
    config_str = format(sq_psn_offset, '08x') + ' ' + format((sq_psn & 0x00ffffff), '08x')
    if(is_remote_peer):
      self.rdma2_per_q_config.append(config_str) 
    else:
      self.rdma_per_q_config.append(config_str)
    debug_str = debug_str + 'eh.SQPSNi: ' + config_str + '\n'

    # Also need to configure receive PSN
    if(is_remote_peer):
      recv_psn_offset = self.get_rdma_per_q_config_addr(eh.LSTRQREQi, qpid)
      last_opcode = 0x0a
      # The last RQ PSN must be the incoming SEND PSN - 1
      config_str = format(recv_psn_offset, '08x') +  ' ' + format((((sq_psn-1) & 0x00ffffff) | ((last_opcode<<24) & 0xff000000)), '08x')
      self.rdma2_per_q_config.append(config_str)
      debug_str = debug_str + 'eh.LSTRQREQi: ' + config_str + '\n'

    # Configure protection domain number for the qpid-th QP
    # This register is 24-bit and contains the PD number assigned to the QP.
    pd_qp_offset = self.get_rdma_per_q_config_addr(eh.PDi, qpid)
    config_str = format(pd_qp_offset, '08x') + ' ' + format((pd_num & 0x00ffffff), '08x')
    if(is_remote_peer):
      self.rdma2_per_q_config.append(config_str)
    else:
      self.rdma_per_q_config.append(config_str)
    debug_str = debug_str + 'eh.PDi: ' + config_str

    if (self.debug_path != ''):
      if(is_remote_peer):
        debug_fname = pjoin(self.debug_path, f'debug_rdma2_perq_csr_config_qpid_{qpid}.txt')
      else:
        debug_fname = pjoin(self.debug_path, f'debug_rdma_perq_csr_config_qpid_{qpid}.txt')
      helper_lst = []
      helper_lst.append(debug_str)
      self.write2file(debug_fname, '', helper_lst)

    # Generate rdma2_stat_reg_config for simulation
    if(is_remote_peer):
      self.rdma1_stat_reg_config.append(format(self.get_rdma_per_q_config_addr(eh.CQHEADi        , qpid), '08x'))
      self.rdma1_stat_reg_config.append(format(self.get_rdma_per_q_config_addr(eh.STATSSNi       , qpid), '08x'))
      self.rdma1_stat_reg_config.append(format(self.get_rdma_per_q_config_addr(eh.STATMSNi       , qpid), '08x'))
      self.rdma1_stat_reg_config.append(format(self.get_rdma_per_q_config_addr(eh.STATQPi        , qpid), '08x'))
      self.rdma1_stat_reg_config.append(format(self.get_rdma_per_q_config_addr(eh.STATCURSQPTRi  , qpid), '08x'))
      self.rdma1_stat_reg_config.append(format(self.get_rdma_per_q_config_addr(eh.STATRESPSNi    , qpid), '08x'))
      self.rdma1_stat_reg_config.append(format(self.get_rdma_per_q_config_addr(eh.STATRQBUFCAi   , qpid), '08x'))
      self.rdma1_stat_reg_config.append(format(self.get_rdma_per_q_config_addr(eh.STATRQBUFCAMSBi, qpid), '08x'))
      self.rdma1_stat_reg_config.append(format(self.get_rdma_per_q_config_addr(eh.STATWQEi       , qpid), '08x'))
      self.rdma1_stat_reg_config.append(format(self.get_rdma_per_q_config_addr(eh.STATRQPIDBi    , qpid), '08x'))

      self.rdma1_debug_stat_reg_config.append('eh.CQHEADi         : ' + format(self.get_rdma_per_q_config_addr(eh.CQHEADi        , qpid), '08x'))
      self.rdma1_debug_stat_reg_config.append('eh.STATSSNi        : ' + format(self.get_rdma_per_q_config_addr(eh.STATSSNi       , qpid), '08x'))
      self.rdma1_debug_stat_reg_config.append('eh.STATMSNi        : ' + format(self.get_rdma_per_q_config_addr(eh.STATMSNi       , qpid), '08x'))
      self.rdma1_debug_stat_reg_config.append('eh.STATQPi         : ' + format(self.get_rdma_per_q_config_addr(eh.STATQPi        , qpid), '08x'))
      self.rdma1_debug_stat_reg_config.append('eh.STATCURSQPTRi   : ' + format(self.get_rdma_per_q_config_addr(eh.STATCURSQPTRi  , qpid), '08x'))
      self.rdma1_debug_stat_reg_config.append('eh.STATRESPSNi     : ' + format(self.get_rdma_per_q_config_addr(eh.STATRESPSNi    , qpid), '08x'))
      self.rdma1_debug_stat_reg_config.append('eh.STATRQBUFCAi    : ' + format(self.get_rdma_per_q_config_addr(eh.STATRQBUFCAi   , qpid), '08x'))
      self.rdma1_debug_stat_reg_config.append('eh.STATRQBUFCAMSBi : ' + format(self.get_rdma_per_q_config_addr(eh.STATRQBUFCAMSBi, qpid), '08x'))
      self.rdma1_debug_stat_reg_config.append('eh.STATWQEi        : ' + format(self.get_rdma_per_q_config_addr(eh.STATWQEi       , qpid), '08x'))
      self.rdma1_debug_stat_reg_config.append('eh.STATRQPIDBi     : ' + format(self.get_rdma_per_q_config_addr(eh.STATRQPIDBi    , qpid), '08x'))

      self.rdma2_stat_reg_config.append(format(self.get_rdma_per_q_config_addr(eh.CQHEADi        , qpid), '08x'))
      self.rdma2_stat_reg_config.append(format(self.get_rdma_per_q_config_addr(eh.STATSSNi       , qpid), '08x'))
      self.rdma2_stat_reg_config.append(format(self.get_rdma_per_q_config_addr(eh.STATMSNi       , qpid), '08x'))
      self.rdma2_stat_reg_config.append(format(self.get_rdma_per_q_config_addr(eh.STATQPi        , qpid), '08x'))
      self.rdma2_stat_reg_config.append(format(self.get_rdma_per_q_config_addr(eh.STATCURSQPTRi  , qpid), '08x'))
      self.rdma2_stat_reg_config.append(format(self.get_rdma_per_q_config_addr(eh.STATRESPSNi    , qpid), '08x'))
      self.rdma2_stat_reg_config.append(format(self.get_rdma_per_q_config_addr(eh.STATRQBUFCAi   , qpid), '08x'))
      self.rdma2_stat_reg_config.append(format(self.get_rdma_per_q_config_addr(eh.STATRQBUFCAMSBi, qpid), '08x'))
      self.rdma2_stat_reg_config.append(format(self.get_rdma_per_q_config_addr(eh.STATWQEi       , qpid), '08x'))
      self.rdma2_stat_reg_config.append(format(self.get_rdma_per_q_config_addr(eh.STATRQPIDBi    , qpid), '08x'))

      self.rdma2_debug_stat_reg_config.append('eh.CQHEADi         : ' + format(self.get_rdma_per_q_config_addr(eh.CQHEADi        , qpid), '08x'))
      self.rdma2_debug_stat_reg_config.append('eh.STATSSNi        : ' + format(self.get_rdma_per_q_config_addr(eh.STATSSNi       , qpid), '08x'))
      self.rdma2_debug_stat_reg_config.append('eh.STATMSNi        : ' + format(self.get_rdma_per_q_config_addr(eh.STATMSNi       , qpid), '08x'))
      self.rdma2_debug_stat_reg_config.append('eh.STATQPi         : ' + format(self.get_rdma_per_q_config_addr(eh.STATQPi        , qpid), '08x'))
      self.rdma2_debug_stat_reg_config.append('eh.STATCURSQPTRi   : ' + format(self.get_rdma_per_q_config_addr(eh.STATCURSQPTRi  , qpid), '08x'))
      self.rdma2_debug_stat_reg_config.append('eh.STATRESPSNi     : ' + format(self.get_rdma_per_q_config_addr(eh.STATRESPSNi    , qpid), '08x'))
      self.rdma2_debug_stat_reg_config.append('eh.STATRQBUFCAi    : ' + format(self.get_rdma_per_q_config_addr(eh.STATRQBUFCAi   , qpid), '08x'))
      self.rdma2_debug_stat_reg_config.append('eh.STATRQBUFCAMSBi : ' + format(self.get_rdma_per_q_config_addr(eh.STATRQBUFCAMSBi, qpid), '08x'))
      self.rdma2_debug_stat_reg_config.append('eh.STATWQEi        : ' + format(self.get_rdma_per_q_config_addr(eh.STATWQEi       , qpid), '08x'))
      self.rdma2_debug_stat_reg_config.append('eh.STATRQPIDBi     : ' + format(self.get_rdma_per_q_config_addr(eh.STATRQPIDBi    , qpid), '08x'))

    logger.info("RDMA per-queue CSR configuration generation is done")

  def gen_rdma_mr_per_pd_num(self, pd_num, buf_len, r_key, virt_addr, phy_addr):
    """Generate configurations for RDMA per-pd_num memory region registration 
    Args:
      pd_num    (int): protection domain number, 0-255
      buf_len   (int): buffer length
      r_key     (int): 8-bit r_key
      virt_addr (int): virtual address of the payload buffer
      phy_addr  (int): physical address of the payload buffer
      is_remote_peer (bool): a signal to indicate remote peer. Default value is False
    Returns:
      none
    """  
    debug_str = ''
    # configure protection domain number
    assert(pd_num<256), "The system only supports pd_number <= 255"
    pdnum_offset = self.get_rdma_pd_config_addr(eh.PDPDNUM, pd_num)
    config_str = format(pdnum_offset, '08x') + ' ' + format((pd_num & 0x00ffffff), '08x')
    self.rdma_mr_config.append(config_str)
    debug_str = 'eh.PDPDNUM: ' + config_str + '\n'

    # configure virtual address of the buffer
    virtaddr_lsb_offset = self.get_rdma_pd_config_addr(eh.VIRTADDRLSB, pd_num)
    virtaddr_lsb        = virt_addr
    config_str = format(virtaddr_lsb_offset, '08x') + ' ' + format(virtaddr_lsb, '08x')
    self.rdma_mr_config.append(config_str)
    debug_str = debug_str + 'eh.VIRTADDRLSB: ' + config_str + '\n'
    virtaddr_msb_offset = self.get_rdma_pd_config_addr(eh.VIRTADDRMSB, pd_num)
    virtaddr_msb        = 0x0
    config_str = format(virtaddr_msb_offset, '08x') + ' ' + format(virtaddr_msb, '08x')
    self.rdma_mr_config.append(config_str)
    debug_str = debug_str + 'eh.VIRTADDRMSB: ' + config_str + '\n'
    
    # configure physical (DMA) address of the buffer
    bufbaseaddr_lsb_offset = self.get_rdma_pd_config_addr(eh.BUFBASEADDRLSB, pd_num)
    bufbaseaddr_lsb        = phy_addr
    config_str = format(bufbaseaddr_lsb_offset, '08x') + ' ' + format(bufbaseaddr_lsb, '08x')
    self.rdma_mr_config.append(config_str)
    debug_str = debug_str + 'eh.BUFBASEADDRLSB: ' + config_str + '\n'
    bufbaseaddr_msb_offset = self.get_rdma_pd_config_addr(eh.BUFBASEADDRMSB, pd_num)
    bufbaseaddr_msb        = 0x0
    config_str = format(bufbaseaddr_msb_offset, '08x') + ' ' + format(bufbaseaddr_msb, '08x')
    self.rdma_mr_config.append(config_str)
    debug_str = debug_str + 'eh.BUFBASEADDRMSB: ' + config_str + '\n'

    # configure r_key
    r_key_offset = self.get_rdma_pd_config_addr(eh.BUFRKEY, pd_num)
    config_str = format(r_key_offset, '08x') + ' ' + format(r_key, '08x')
    self.rdma_mr_config.append(config_str)
    debug_str = debug_str + 'eh.BUFRKEY: ' + config_str + '\n'

    # configure buffer length
    buf_len_offset = self.get_rdma_pd_config_addr(eh.WRRDBUFLEN, pd_num)
    config_str = format(buf_len_offset, '08x') + ' ' + format(buf_len, '08x')
    self.rdma_mr_config.append(config_str)
    debug_str = debug_str + 'eh.WRRDBUFLEN: ' + config_str + '\n'

    # configure access description of the protection domain table
    # -- 	[3:0] Access description of the protection domain, and 
		#           > 4'b0000: READ Only
		#           > 4'b0001: Write Only
		#           > 4'b0010: Read and Write, default value
		#           > Other values: Not supported
	  #     [15:4]: Reserved
    #     [31:16] write/read buffer length MSB register [47:32]
    accessdesc_offset = self.get_rdma_pd_config_addr(eh.ACCESSDESC, pd_num)
    access_desc = 0x2
    #reserved    = 0
    #buf_len_msb = 0
    config_str = format(accessdesc_offset, '08x') + ' ' + format(access_desc, '08x')
    self.rdma_mr_config.append(config_str)
    debug_str = debug_str + 'eh.ACCESSDESC: ' + config_str + '\n'

    if (self.debug_path != ''):
      debug_fname = pjoin(self.debug_path, f'debug_rdma_memory_registration_pd_num_{pd_num}.txt')
      helper_lst = []
      helper_lst.append(debug_str)
      self.write2file(debug_fname, '', helper_lst)

    logger.info("RDMA per-pd_num memory region configuration generation is done")

  def gen_rdma_wqe(self, qpid, wrid, ith_wqe, payload_addr, payload_len, opcode, remote_offset, remote_key, send_data=0, immdt_data=0):
    """Generate RDMA work request entry (WQE)
    Args:
      qpid          (int): Queue Pair ID
      wrid          (int): 16-bit work request ID. Unique identifier for every WQE.
      ith_wqe       (int): the i-th WQE entry in a SQ.
      paylaod_addr  (int): base address of payload, 64-bit
      payload_len   (int): 32-bit payload length
      opcode        (int): 8-bit ERNIC RDMA opcode
                             8’h00 -- RDMA WRITE
                             8’h01 -- RDMA_WRITE WITH IMMDT
                             8’h02 -- RDMA SEND
                             8’h03 -- RDMA SEND WITH IMMDT
                             8’h04 -- RDMA READ
                             8’h0C -- RDMA SEND WITH INVALIDATE
                             All other values are reserved.
      remote_offset (int): 64-bit remote address offset
      remote_key    (int): 32-bit r_key (remote key)
      send_data     (int): 128-bit RDMA send data. If the data to be sent is less than or 
                           equal to 16B, this field is used to represent the data
      immdt_data    (int): 32-bit immediate data to be sent in ImmDt header
    Returns:
      none
    """
    # Get physical address of SQ buffer for storing WQE
    sq_wqe_offset = self.qpid_sq_dict[qpid] + (ith_wqe * 64)

    # Structure of a WQE
    # -- [15:0]   : 16-bit wrid
    # -- [31:16]  : 16-bit reserved
    # -- [95:32]  : 64-bit local payload address
    # -- [127:96] : 32-bit length of the transfer
    # -- [135:128]: 8-bit ERNIC rdma opcode
    # -- [159:136]: 24-bit reserved
    # -- [223:160]: 64-bit remote_offset
    # -- [255:224]: 32-bit remote tag
    # -- [383:256]: 128-bit send data
    # -- [415:384]: 32-bit immediate data
    # -- [511:416]: 96-bit reserved
    wqe_str = format(sq_wqe_offset, '016x') + ' ' + format(0, '024x') + format(immdt_data, '08x') + format(send_data, '032x') + format(remote_key, '08x') + format(remote_offset, '016x') + format(opcode, '08x') + format(payload_len, '08x') + format(payload_addr, '016x') + format(wrid, '08x') + ' ' + format(64, '04x')

    # address offset, wqe, wqe length (64B)
    self.rdma_wqe_list.append(wqe_str)

    debug_wqe_str = f"qpid=0x{qpid:08x}, sq_wqe_offset=0x{sq_wqe_offset:016x}, wrid=0x{wrid:04x}, payload_address=0x{payload_addr:016x}, payload_length=0x{payload_len:08x}, ernic_opcode=0x{opcode:02x}, remote_offset=0x{remote_offset:016x}, remote_key=0x{remote_key:08x}, send_data=0x{send_data:032x}, immdt_data={immdt_data:08x}\nwqe_str={wqe_str}\n"

    self.debug_wqe_list.append(debug_wqe_str)

    # Ring the SQ doorbell
    '''
    # FIXME: Hardcoded SQ doorbell with 2 for 2 RDMA operations testing
    if(ith_wqe == 1):
      self.sq_pidb = 2
      sq_pidb_offset = self.get_rdma_per_q_config_addr(eh.SQPIi, qpid)
      sq_pidb_config_str = format(sq_pidb_offset, '08x') + ' ' + format(self.sq_pidb, '08x')
      debug_str = 'eh.SQPIi: ' + sq_pidb_config_str + '\n'

      self.rdma_per_q_config.append(sq_pidb_config_str)

      if(len(self.rdma2_global_config) != 0):
        self.rdma1_stat_reg_config.append(format(self.get_rdma_per_q_config_addr(eh.SQPIi    , qpid), '08x'))
        self.rdma1_debug_stat_reg_config.append('eh.SQPIi           : ' + format(self.get_rdma_per_q_config_addr(eh.SQPIi, qpid), '08x'))
        self.rdma1_stat_reg_config.append(format(self.get_rdma_per_q_config_addr(eh.CQHEADi    , qpid), '08x'))
        self.rdma1_debug_stat_reg_config.append('eh.CQHEADi           : ' + format(self.get_rdma_per_q_config_addr(eh.CQHEADi, qpid), '08x'))

      if (self.debug_path != ''):
        debug_fname = pjoin(self.debug_path, f'debug_rdma_perq_csr_config_qpid_{qpid}.txt')
        helper_lst = []
        helper_lst.append(debug_str)
        self.write2file(debug_fname, '', helper_lst, mode='a')
    '''

    self.sq_pidb = self.sq_pidb + 1
    #sq_pidb_offset = self.get_rdma_per_q_config_addr(eh.SQPIi, qpid)
    #sq_pidb_config_str = format(sq_pidb_offset, '08x') + ' ' + format(self.sq_pidb, '08x')
    #debug_str = 'eh.SQPIi: ' + sq_pidb_config_str + '\n'

    #self.rdma_per_q_config.append(sq_pidb_config_str)

    # FIXME: In the current implementation, we only support one send per queue.
    # For send operations, we need to generate receive WQE as well
    #if (opcode == 0x2) or (opcode == 0x3):
    #  # 1. poll rq_pidb
    #  rq_pidb_offset = self.get_rdma_per_q_config_addr(eh.STATRQPIDBi , qpid)
    #  # As we only have one send per queue, the golden number of send per queue is '1'
    #  rq_config_str = format(rq_pidb_offset, '08x') + ' ' + format(1, '08x')
    #  self.rdma2_per_q_recv_config.append(rq_config_str)
    #  # 2. Update rq_cidb with value from reading rq_pidb register
    #  rq_cidb_offset = self.get_rdma_per_q_config_addr(eh.RQCIi, qpid)
    #  # rq_cidb register will be updated with the returned value from rq_pidb. '0xffff_ffff'
    #  # is used to detect rq_cidb address when reading configuration file in the hardware
    #  # testbench.
    #  rq_config_str = format(rq_cidb_offset, '08x') + ' ' + format(0xffffffff, '08x')
    #  self.rdma2_per_q_recv_config.append(rq_config_str)

    if(len(self.rdma2_global_config) != 0):
      self.rdma1_stat_reg_config.append(format(self.get_rdma_per_q_config_addr(eh.SQPIi    , qpid), '08x'))
      self.rdma1_debug_stat_reg_config.append('eh.SQPIi           : ' + format(self.get_rdma_per_q_config_addr(eh.SQPIi, qpid), '08x'))

    #if (self.debug_path != ''):
    #  debug_fname = pjoin(self.debug_path, f'debug_rdma_perq_csr_config_qpid_{qpid}.txt')
    #  helper_lst = []
    #  helper_lst.append(debug_str)
    #  self.write2file(debug_fname, '', helper_lst, mode='a')

    logger.info("A RDMA WQE is generated")

  def convert_packet_string(self, pkt_string):
    """Convert a packet string to a string format in the hex mode
    Args:
      pkt_string (string): raw packet string from scapy
    Returns:
      the packet string in the hex mode
    """
    pkt_str = ''
    for j in range(0, len(pkt_string)):
      if (j%2 == 1) and (j!=len(pkt_string)-1):
        pkt_str = pkt_str + pkt_string[j] + ' '
      else:
        pkt_str = pkt_str + pkt_string[j]
    return pkt_str

  def gen_non_roce_packets(self, num_packets):
    """Generate non-roce packets
    Args:
      num_packets (int): Number of non-roce packets generated
    Returns:
      none
    """
    logger.info("Generating non-roce packets")
    for i in range(0, num_packets):
      payload_str = format(i, '08x')
      payload = ba.unhexlify(payload_str)
      pkt = Ether(dst=self.eth_dst_seed, src=self.eth_src_seed)/IP(dst=self.ip_dst_seed, src=self.ip_src_seed)/TCP(sport=0x1111, dport=0xdddd)/Raw(load=payload)
      # For debug: hexdump(pkt)
      raw_pkt = raw(pkt)
      pkt_str_tmp = str(raw_pkt.hex())
      pkt_str = self.convert_packet_string(pkt_str_tmp)
      self.non_roce_pkts.append(pkt_str)

  def gen_noise_roce_packets(self, num_noise=16):
    """Generate roce noise packets
    Args:
      num_noise (int): Number of roce noise packets generated
    Returns:
      none
    """
    logger.info("Generating roce noise packets")
    for i in range(0, num_noise):
      payload_str = format(i, '08x')
      payload = ba.unhexlify(payload_str)
      pkt = Ether(dst=self.eth_dst_noise)/IP()/UDP(sport=0xdead)/BTH(opcode=6, pkey=0xbeef, psn=i)
      # For debug: hexdump(pkt)
      raw_pkt = raw(pkt)
      pkt_str_tmp = str(raw_pkt.hex())
      pkt_str = self.convert_packet_string(pkt_str_tmp)
      self.roce_noise_pkts.append(pkt_str)    

class GenEthClass(pktGenClass):
  def __init__(self, cfg_name, debug=False):
    super().__init__(cfg_name, debug)
    self.eth_dst_seed  = '10:00:10:00:10:00'
    self.eth_src_seed  = '20:00:20:00:20:00'
    self.ip_dst_seed   = '10.10.0.0'
    self.ip_src_seed   = '10.20.0.0'
    self.ip_proto      = 'tcp'
    self.arp_ipdst_seed= '17.17.17.0'
    self.arp_eth_dst   = 'ff:ff:ff:ff:ff:ff'
    self.num_arp_types = 64
    self.sport     = 80
    self.dport     = 80
    self.twoTuple = []
    self.twoTuple_hexs_dict = OrderedDict()
    self.rxm_pkt_obj_dict = OrderedDict()
    self.rxm_pkt_hex_dict = OrderedDict()
    
    self.parse_json_config()
    self.pkts_generation_rxm()

  def parse_json_config(self):
    """Parse configuration file in JSON format
    """
    with open(self.cfg_name, 'r') as f:
      config_dict = json.load(f)
    for item in config_dict:
      if (item == 'packet_size'):
        self.pkt_size = config_dict[item]
      if (item == 'number_flow'):
        self.num_flow = config_dict[item]
      if (item == 'number_pkts'):
        self.num_pkts = config_dict[item]
      if (item == 'eth_dst'):
        self.eth_dst_seed = config_dict[item]
      if (item == 'eth_src'):
        self.eth_src_seed = config_dict[item]
      if (item == 'ip_dst'):
        self.ip_dst_seed = config_dict[item]
      if (item == 'ip_src'):
        self.ip_src_seed = config_dict[item]

  def conv_str_eth_addr_2_hexstr(self, str_eth_addr):
    """Convert Ethernet address to hex string
    Args:
      str_eth_addr (str): Ethernet addres in string
    Returns:
      string: hex string
    """
    strs = str_eth_addr.split(':')
    hexstr = reduce(lambda x,y: x+y, strs)
    return hexstr

  def conv_str_ip_addr_2_hexstr(self, str_ip_addr):
    """Convert IP address to hex string
    Args:
      str_ip_addr (str): IP address in string
    Returns:
      string: hex string
    Note:
      IP address like 10.0.0.1 should be converted to
      0a 00 00 01
    """
    strs = str_ip_addr.split('.')
    strs = [ str(format(int(i),'#04x'))[2:] for i in strs]
    hexstr = reduce(lambda x,y: x+y, strs)
    return hexstr

  def conv_twoTup_2_hexstr(self, ip_src, sport):
    """Generate two tuple from a given twoTuple
    Args:
      ip_dst  : Destination IP address
      dport   : TCP/UDP destination port
    Returns:
      twoTup (hex string): a two tuple consists of
          Source IP address       32 bytes
          TCP destination port    16 bytes
        Total ------------------  48 bytes
    Note:
      """
    # Convert to hex strings
    s_src    = self.conv_str_ip_addr_2_hexstr(ip_src)
    s_sport = str(format(sport, '#06x'))[2:]
    return (s_src + s_sport)

if __name__ == "__main__":
  argv_len = len(sys.argv)
  if (argv_len < 2):
    logger.info('Usage: python packet_gen.py config.json')
    exit()
  config_fname = sys.argv[1]
  pkt_gen = pktGenClass(config_fname)



