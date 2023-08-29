#!/usr/bin/env python3
#==============================================================================
# Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
# SPDX-License-Identifier: MIT
#
#==============================================================================

import os
import sys
import glob
import subprocess
import random
import json
import math
import logging
import random
import packet_gen
from collections import OrderedDict
from os.path import isdir as isdir
from os.path import join as pjoin
from config_logger import logger

testcase_rootpath = pjoin(os.getcwd(), 'testcases')
tuple_name_gen  = 'Tuple.user'
packet_name_gen = 'Packet.user'
table_name_gen  = 'weight_tb.tbl'

rdma_sys_filename = 'rdma_sys_mem.txt'
rdma_dev_filename = 'rdma_dev_mem.txt'
rdma_global_config_filename = 'rdma_global_config.txt'
rdma_per_q_config_filename  = 'rdma_per_q_config.txt'
rdma_mr_config_filename     = 'rdma_mr_config.txt'
rdma_wqe_list_filename      = 'rdma_wqe_list.txt'
rdma_combined_cfg_filename  = 'rdma_combined_config.txt'
rdma1_stat_reg_cfg_filename = 'rdma1_stat_reg_config.txt'
rdma1_debug_stat_reg_cfg_filename = 'debug_rdma1_stat_reg_config.txt'
rdma2_global_config_filename = 'rdma2_global_config.txt'
rdma2_per_q_config_filename  = 'rdma2_per_q_config.txt'
# rdma2_per_q_recv_config.txt is used for remote RDMA to check incoming send operations
rdma2_perq_recv_config_filename = 'rdma2_per_q_recv_config.txt'
rdma2_mr_config_filename     = 'rdma2_mr_config.txt'
rdma2_combined_cfg_filename = 'rdma2_combined_config.txt'
rdma2_stat_reg_cfg_filename = 'rdma2_stat_reg_config.txt'
rdma2_debug_stat_reg_cfg_filename = 'debug_rdma2_stat_reg_config.txt'
non_roce_packet_filename    = 'packets.txt'

# Files for Compute Logic simulation
cl_init_mem    = "cl_init_mem.txt"
cl_golden_data = "cl_golden_data.txt"
cl_ctl_cmd     = "cl_ctl_cmd.txt"

sim_path = pjoin(os.getcwd(), 'scripts')

pc_metadata_width_in_byte = 18 # 18 bytes

def dir_walk(t_path):
  """Get directories under the t_path
  Args:
    t_path (string) : target path
  Return:
    a list of directories in string
  """
  dirs = [ pjoin(t_path, dir_t) for dir_t in os.listdir(t_path) if isdir(pjoin(t_path, dir_t))]
  return dirs

class testcaseClass:
  def __init__(self, sim_tool, test_rootpath, is_roce, is_debug, skip_pktgen, skip_sim, gui, t_testcase=''):
    self.sim_tool = sim_tool
    self.test_rootpath = test_rootpath
    self.is_roce     = is_roce
    self.is_debug    = is_debug
    self.skip_pktgen = skip_pktgen
    self.skip_sim    = skip_sim
    self.gui         = gui
    self.line_rate   = 40 # default value in Gbps
    if (t_testcase != ''):
      # Run testcases specified
      testcase_names = t_testcase.split(' ')
      for tc_name in testcase_names:
        logger.info('Running testcase %s' % (tc_name))
        self.run_testcase(tc_name)
        logger.info('Finished testcase %s' % (tc_name))
    else:
      # Run all the existing testcases
      logger.info('Regression Testing')
      self.explore_testcases()

  def explore_testcases(self):
    """Explore each testcase, generate input files, simulate
       and store results
    Args:
      none
    Returns:
      none
    """
    # Check all the testcase folders in current directory
    dirs = dir_walk(self.test_rootpath)
    tc_names = []
    for dir_t in dirs:
      tc_names.append(dir_t.split('/')[-1])
    for tc_name in tc_names:
      logger.info('Running testcase %s' % (tc_name))
      self.run_testcase(tc_name)
      logger.info('Finished testcase %s' % (tc_name))

  def run_testcase(self, tc_name):
    """Generate input files for the testcase 'tc_name' and
       start simulation
    Args:
      tc_name (string) : testcase name
    Returns:
      none
    """
    tc_dir = pjoin(self.test_rootpath, tc_name)
    logger.info('Testing directory: %s' % (tc_dir))

    config_file = glob.glob(pjoin(tc_dir, '*.json'))
    if(len(config_file) == 0):
      logger.error('Please provide a configuration file in JSON format')
      exit()
    elif (len(config_file) > 1):
      logger.error('Please only provide one configuration file')
      exit()
    else:
      pass
    
    # Top module name of testbenches, default is set to 'rn_tb_top'
    top_module = 'rn_tb_top'
    pkt_type = ''
    config_file = config_file[0]
    logger.info('config_file = %s' % config_file)
    with open(config_file, 'r') as f:
      config_dict = json.load(f)

    for item in config_dict:
      if(item == 'pkt_type'):
        pkt_type = config_dict[item]
      if(item == 'top_module'):
        top_module = config_dict[item]

    if(top_module == 'cl_tb_top'):
      # Simulation for Compute Logic
      # Get cl_init_mem file
      logger.info('Generating files for Compute Logic simulation')
      cl_init_mem_fname    = pjoin(tc_dir, cl_init_mem)
      cl_ctl_cmd_fname     = pjoin(tc_dir, cl_ctl_cmd)
      cl_golden_data_fname = pjoin(tc_dir, cl_golden_data)
      cl_gen = packet_gen.pktGenClass(config_file)
      cl_gen.gen_cl_stimulus()
      cl_gen.write2file(cl_init_mem_fname, '', cl_gen.cl_init_mem)
      cl_gen.write2file(cl_ctl_cmd_fname, '', cl_gen.ctl_cmd_lst)
      cl_gen.write2file(cl_golden_data_fname, '', cl_gen.cl_golden_mem)
      logger.info('Files are generated for Compute Logic simulation')
    else:
      # A temp file to store temp information
      if (self.skip_pktgen == 0 and self.is_roce == 0 and pkt_type == "eth"):
        logger.info('Generating traditional Ethernet packets')
        # Generate packets with the give configuration file
        pkt_gen = packet_gen.GenEthClass(config_file)
        
        # Construct sending packets with mixed flows
        pc_pkt_fname = pjoin(tc_dir, packet_name_gen)
        logger.info('Constructing RxM PC packets')
        num_pkts = self.construct_pc_packets(tc_name, pc_pkt_fname, pkt_gen) 

        # Create a metadata tuple as the input to SDNet generated files
        meta_tuple_fname = pjoin(tc_dir, tuple_name_gen)
        logger.debug('meta_tuple_fname = %s' % (meta_tuple_fname))
        self.gen_pc_metadata(meta_tuple_fname, num_pkts)
        logger.info('Packet data, metadata tuple and weight table content are ready')
      
      if (self.skip_pktgen == 0 and self.is_roce == 1 and pkt_type == "rocev2"):
        logger.info('Constructing RDMA packets - Only support RoCEv2 protocol')
        if (is_debug):
          pkt_gen = packet_gen.GenRoCEClass(config_file, debug=True, debug_path=tc_dir)
        else:
          pkt_gen = packet_gen.GenRoCEClass(config_file)

        #mem_hdr_str = "% memory address; payload; size of payload in byte"
        mem_hdr_str = ""
        rdma_combined_config = []
        rdma2_combined_config = []
        rdma_dev_fname = pjoin(tc_dir, rdma_dev_filename)
        rdma_sys_fname = pjoin(tc_dir, rdma_sys_filename)
        rdma_glb_cfg_fname  = pjoin(tc_dir, rdma_global_config_filename)
        rdma_perq_cfg_fname = pjoin(tc_dir, rdma_per_q_config_filename)
        rdma_mr_cfg_fname   = pjoin(tc_dir, rdma_mr_config_filename)
        rdma_wqe_list_fname = pjoin(tc_dir, rdma_wqe_list_filename)
        rdma_combined_cfg_fname  = pjoin(tc_dir, rdma_combined_cfg_filename)
        rdma1_stat_cfg_fname = pjoin(tc_dir, rdma1_stat_reg_cfg_filename)
        rdma1_debug_stat_cfg_fname = pjoin(tc_dir, rdma1_debug_stat_reg_cfg_filename)
        rdma2_glb_cfg_fname  = pjoin(tc_dir, rdma2_global_config_filename)
        rdma2_perq_cfg_fname = pjoin(tc_dir, rdma2_per_q_config_filename)
        rdma2_perq_recv_cfg_fname = pjoin(tc_dir, rdma2_perq_recv_config_filename)
        rdma2_mr_cfg_fname   = pjoin(tc_dir, rdma2_mr_config_filename)
        rdma2_combined_cfg_fname = pjoin(tc_dir, rdma2_combined_cfg_filename)
        rdma2_stat_cfg_fname = pjoin(tc_dir, rdma2_stat_reg_cfg_filename)
        rdma2_debug_stat_cfg_fname = pjoin(tc_dir, rdma2_debug_stat_reg_cfg_filename)

        non_roce_packets_fname = pjoin(tc_dir, non_roce_packet_filename)

        if ((top_module == 'rn_tb_top') or (top_module == 'rn_tb_2rdma_top')):
          # For write test:
          #   1. To construct rdma payload data, we need to initialize system memory
          #   2. To verify write operations, we need to read device memory
          pkt_gen.write2file(rdma_sys_fname, mem_hdr_str, pkt_gen.rdma_init_sys_mem)
          pkt_gen.write2file(rdma_dev_fname, mem_hdr_str, pkt_gen.rdma_init_dev_mem)
          pkt_gen.write2file(rdma_glb_cfg_fname, '', pkt_gen.rdma_global_config)
          pkt_gen.write2file(rdma_perq_cfg_fname, '', pkt_gen.rdma_per_q_config)
          pkt_gen.write2file(rdma_mr_cfg_fname, '', pkt_gen.rdma_mr_config)
          pkt_gen.write2file(rdma_wqe_list_fname, '', pkt_gen.rdma_wqe_list)
          rdma_combined_config = pkt_gen.rdma_global_config + pkt_gen.rdma_mr_config + pkt_gen.rdma_per_q_config
          pkt_gen.write2file(rdma_combined_cfg_fname, '', rdma_combined_config)
          if (top_module == 'rn_tb_2rdma_top'):
            pkt_gen.write2file(rdma1_stat_cfg_fname, '', pkt_gen.rdma1_stat_reg_config)
            pkt_gen.write2file(rdma1_debug_stat_cfg_fname, '', pkt_gen.rdma1_debug_stat_reg_config)
            pkt_gen.write2file(rdma2_glb_cfg_fname, '', pkt_gen.rdma2_global_config)
            pkt_gen.write2file(rdma2_perq_cfg_fname, '', pkt_gen.rdma2_per_q_config)
            pkt_gen.write2file(rdma2_perq_recv_cfg_fname ,'', pkt_gen.rdma2_per_q_recv_config)
            pkt_gen.write2file(rdma2_mr_cfg_fname, '', pkt_gen.rdma2_mr_config)
            rdma2_combined_config = pkt_gen.rdma2_global_config + pkt_gen.rdma2_per_q_config + pkt_gen.rdma2_mr_config
            pkt_gen.write2file(rdma2_combined_cfg_fname, '', rdma2_combined_config)
            pkt_gen.write2file(rdma2_stat_cfg_fname, '', pkt_gen.rdma2_stat_reg_config)
            pkt_gen.write2file(rdma2_debug_stat_cfg_fname, '', pkt_gen.rdma2_debug_stat_reg_config)
          if (is_debug):
            debug_wqe_fname = pjoin(tc_dir, f'debug_rdma_wqe_list.txt')
            pkt_gen.write2file(debug_wqe_fname, '', pkt_gen.debug_wqe_list)

        if (pkt_gen.non_roce_traffic == 1):
          non_roce_hdr_string = f'% number of non-roce packets: {pkt_gen.num_non_roce};'
          pkt_gen.write_pkts2file(non_roce_packets_fname, non_roce_hdr_string, pkt_gen.non_roce_pkts)
      
    # Start simulation
    if (self.skip_sim == 0):
      self.start_simulation(tc_name, self.sim_tool, sim_path, top_module, self.gui)
    else:
      # self.skip_sim == 1
      pass
    logger.info('Simulation finished')

  def construct_pc_packets(self, tc_name, pc_pkt_fname, pkt_gen):
    """Construct RxM packets for classification
    Args:
      tc_name        (string) : testcase name
      pc_pkt_fname (string) : file name to store the sending packets
      pkt_gen    (pktGenClass): an instance of the pktGenClass
    Returns:
      total_flow_pkts_num            : number of actual packets inside 
                                      the sending queue
    """
    total_pkt_header_size = 134
    pkt_str = pkt_gen.rxm_pkt_hex_dict
    pc_pkts = []

    # handle packet size
    pkt_size = pkt_gen.pkt_size
    payload_size = pkt_size - total_pkt_header_size
    logger.debug("pkt_size = %s, payload size = %s" % (pkt_size, payload_size))
    if (pkt_size < total_pkt_header_size):
      logger.error('Please increase pkt_size (packet size should be > %d) in configuration file' % total_pkt_header_size)
      exit()

    # write to pc_pkt_fname  
    logger.info('Writing packets into a file')
    # logger.debug('pkt_str = %s' % pkt_str)
    header_str = ''
    self.write_pkts_2_file(pc_pkt_fname, header_str, pkt_str)
    return 1
    # self.write_pkts_2_file(pc_pkt_fname, header_str, flow_pkts)

  def write_pkts_2_file(self, pkt_fname, header_str, pkts):
    """Write generated packets into a file
    Args:
      pkt_fname  (string) : file name used to store generated packets
      header_str (string) : header string when we write packets to a file
      pkts     (str list) : a list of packet strings
    Returns:
      none
    """
    # pkt_str = header_str + '\n'
    pkt_str = ''
    for i in pkts:
      # pkt_str = pkt_str + ';\n'
      pkt_str = pkt_str + pkts[i][0] + ';\n'
    with open(pkt_fname, 'w') as f:
      f.write(pkt_str)

  def start_simulation(self, tc_name, sim_tool, sim_path, top_module, gui):
    """Compile libraries and perform functional simulation
    Args:
      tc_name     (str) : testcase name
      sim_tool    (str) : simulation tools: {xsim, questasim}
      sim_path    (str) : path to simulation scripts
      top_module  (str) : name of top module in testbenches
      gui         (str) : on|off - simulator's gui mode
    Returns:
      none      
    """
    logger.info(f'Simulating {top_module} with the {sim_tool} simulator')
    cur_dir = os.getcwd()
    os.chdir(sim_path)
    os.system(f'./simulate.sh -top {top_module} -g {gui} -t {tc_name} -s {sim_tool}')
    os.chdir(cur_dir)
    logger.info(f'Finished simulation for {tc_name}')

  def gen_pc_metadata(self, fpath, num_pkts):
    """Generate pc metadata and write to a file ('Tuple.user')
    pc metadata has 18 bytes and its structure is defined below:
    Total 22 bytes (176bits)
      bit<32> index; -- pkt idx
      bit<32> src_ip;
      bit<16> sport;
      bit<16> pktlen; -- include ether/ip/tcp
      bit<8>  data_offs; -- point to payload (without headers)
      bit<32> tcp_seq; -- 0
      bit<8>  op; -- rxm_op_header.op
      bit<32> tag; -- 0 
    When generating xnic metadata, only configure the 'seq'
    field and set '0' to the rest.

    Args:
      fpath                (str) : path for output file
      num_pkts             (int) : total number of packets generated with dummy data
      dummy_index_lst (int list) : a list storing indexes of dummy packets
    Returns:
      none
    """
    index = '00000001'
    str_tmp = ''
    str_t = ''

    for i in range(0, pc_metadata_width_in_byte*2-8):
      str_tmp = str_tmp + '0'
    # idx = 0
    for i in range(0, num_pkts):
    #   if not i in dummy_index_lst:
    #     idx = idx + 1
    #     str_t = str_t + format(idx, '#010x')[2:] + str_tmp + '\n'
    #   else:
    #     # Appending 0xffff_ffff to the string
      str_t = str_t + index + str_tmp + '\n'

    with open(fpath, 'w') as f:
      f.write(str_t)

def find_idxes_of_elem_in_lst(key, lst):
  idx_lst = []
  idx = 0
  for item in lst:
    if item in key:
      idx_lst.append(idx)
    idx = idx + 1
  return idx_lst

def find_elem_in_lst(key, lst):
  idx = 0
  for item in lst:
    if item in key:
      return idx
    else:
      idx = idx + 1
  return -1

def delete_elem_from_lst (target_lst, lst_pool):
  """Remove all elements of target_lst in lst_pool
  Args:
    target_lst (list) : a list with elements to be removed
    lst_pool   (list) : a list pool
  Returns: 
    none
  Note:
    Elements in target_lst must be also inside lst_pool
  """
  for value in target_lst:
    lst_pool.remove(value)

def print_help():
  logger.info('Usage:')
  logger.info('  python run_testcase.py [options] regression, ')
  logger.info('  python run_testcase.py [options] -tc "testcase1 testcase2 ... testcasek"')
  logger.info('Options:')
  logger.info('  -debug     : Debug mode')
  logger.info('  -questasim : Use Questa Sim as the simulator. Default is Vivado XSIM')
  logger.info('  -roce      : Generate configuration files for RDMA simulation')
  logger.info('  -no_pktgen : Run testcases without re-generating packets')
  logger.info('  -no_sim    : Only run analysis on the previous simulation results')
  logger.info('  -gui       : Use gui mode with the simulator')

if __name__ == "__main__":
  argv_len = len(sys.argv)
  #logger.getLogger('run_testcase').setLevel(logging.INFO)

  if (argv_len < 3):
    print_help()
    exit() 

  # Parse options
  idx_tc        = find_elem_in_lst('-tc', sys.argv)
  idx_debug     = find_elem_in_lst('-debug', sys.argv)
  idx_roce      = find_elem_in_lst('-roce', sys.argv)
  idx_no_pktgen = find_elem_in_lst('-no_pktgen', sys.argv)
  idx_sim       = find_elem_in_lst('-no_sim', sys.argv)
  idx_reg       = find_elem_in_lst('regression', sys.argv)
  idx_simtool   = find_elem_in_lst('-questasim', sys.argv)
  idx_gui       = find_elem_in_lst('-gui', sys.argv)

  is_debug = 0

  if(idx_debug != -1):
    is_debug = 1
    logger.setLevel(logging.DEBUG)

  if(idx_roce != -1):
    is_roce = 1
  else:
    is_roce = 0

  if(idx_no_pktgen != -1):
    skip_pktgen = 1
  else:
    skip_pktgen = 0
  
  if(idx_sim != -1):
    skip_sim = 1
  else:
    skip_sim = 0

  if(idx_simtool != -1):
    sim_tool = 'questasim'
  else:
    sim_tool = 'xsim'

  if(idx_gui != -1):
    gui = 'on'
  else:
    gui = 'off'

  tc_dir = pjoin(testcase_rootpath, sys.argv[idx_tc+1])
  logger.debug('Testing directory: %s' % (tc_dir))

  if(idx_reg != -1):
    regre_test = testcaseClass(sim_tool, testcase_rootpath, is_roce, is_debug, skip_pktgen, skip_sim, gui)
  elif(idx_tc != -1):
    test = testcaseClass(sim_tool, testcase_rootpath, is_roce, is_debug, skip_pktgen, skip_sim, gui, sys.argv[idx_tc+1])
  else:
    logger.error('Wrong arguments')
    print_help()
    exit()
