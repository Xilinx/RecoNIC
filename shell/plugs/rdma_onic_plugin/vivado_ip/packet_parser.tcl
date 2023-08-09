#==============================================================================
# Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
# SPDX-License-Identifier: MIT
#
#==============================================================================
set prj_root [file normalize ..]
set p4_filepath ${prj_root}/src/box_250mhz/reconic/packet_classification

if {[info exists p4_dir]} {
  set p4file [glob -directory ${p4_dir} *.p4]
} else {
  set p4file [glob -directory ${p4_filepath} *.p4]
}

puts "p4file = ${p4file}"
create_ip -name vitis_net_p4 -vendor xilinx.com -library ip -version 1.0 -module_name packet_parser -dir ${ip_build_dir}

set_property CONFIG.P4_FILE "${p4file}" [get_ips packet_parser]

set_property -dict [list CONFIG.USER_META_DATA_WIDTH {263} CONFIG.JSON_TIMESTAMP {1653047084} CONFIG.TOTAL_LATENCY {23} CONFIG.S_AXI_ADDR_WIDTH {0} CONFIG.M_AXI_HBM_DATA_WIDTH {256} CONFIG.M_AXI_HBM_ADDR_WIDTH {33} CONFIG.M_AXI_HBM_ID_WIDTH {6} CONFIG.M_AXI_HBM_PROTOCOL {0} CONFIG.AXIS_CLK_FREQ_MHZ {250.0} CONFIG.PKT_RATE {250.0} CONFIG.CAM_MEM_CLK_FREQ_MHZ {250.0} CONFIG.USER_METADATA_ENABLES {pc_metadata_t.is_rdma {input true output true} pc_metadata_t.msn {input true output true} pc_metadata_t.psn {input true output true} pc_metadata_t.se {input true output true} pc_metadata_t.r_key {input true output true} pc_metadata_t.dma_length {input true output true} pc_metadata_t.pktlen {input true output true} pc_metadata_t.opcode {input true output true} pc_metadata_t.udp_dport {input true output true} pc_metadata_t.udp_sport {input true output true} pc_metadata_t.ip_dst {input true output true} pc_metadata_t.ip_src {input true output true} pc_metadata_t.index {input true output true}} CONFIG.USER_META_FORMAT {pc_metadata_t.is_rdma {length 1 start 0 end 0} pc_metadata_t.msn {length 24 start 1 end 24} pc_metadata_t.psn {length 24 start 25 end 48} pc_metadata_t.se {length 1 start 49 end 49} pc_metadata_t.r_key {length 32 start 50 end 81} pc_metadata_t.dma_length {length 32 start 82 end 113} pc_metadata_t.pktlen {length 16 start 114 end 129} pc_metadata_t.opcode {length 5 start 130 end 134} pc_metadata_t.udp_dport {length 16 start 135 end 150} pc_metadata_t.udp_sport {length 16 start 151 end 166} pc_metadata_t.ip_dst {length 32 start 167 end 198} pc_metadata_t.ip_src {length 32 start 199 end 230} pc_metadata_t.index {length 32 start 231 end 262}} CONFIG.Component_Name {packet_parser}] [get_ips packet_parser]
