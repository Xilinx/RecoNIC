# *************************************************************************
#
# Copyright 2020 Xilinx, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# *************************************************************************
set qdma qdma_no_sriov
create_ip -name qdma -vendor xilinx.com -library ip -module_name $qdma -dir ${ip_build_dir}
set_property -dict {
    CONFIG.mode_selection {Advanced}
    CONFIG.en_gt_selection {true}
    CONFIG.csr_axilite_slave {true}
    CONFIG.dsc_byp_mode {Descriptor_bypass_and_internal}
    CONFIG.axibar_highaddr_0 {0x000000FFFFFFFFFF}
    CONFIG.dma_reset_source_sel {Phy_Ready}
    CONFIG.pf0_bar2_scale_qdma {Megabytes}
    CONFIG.pf1_bar2_scale_qdma {Megabytes}
    CONFIG.pf2_bar2_scale_qdma {Megabytes}
    CONFIG.pf3_bar2_scale_qdma {Megabytes}
    CONFIG.en_bridge_slv {true}
    CONFIG.dma_intf_sel_qdma {AXI_MM_and_AXI_Stream_with_Completion}
    CONFIG.en_axi_mm_qdma {true}
    CONFIG.axibar_notranslate {false}
    CONFIG.vdm_en {1}
    CONFIG.xlnx_ref_board {AU280}
    CONFIG.pf0_base_class_menu_qdma {Network_controller}
    CONFIG.pf0_class_code_base_qdma {02}
    CONFIG.pf0_class_code_sub_qdma {80}
    CONFIG.pf0_sub_class_interface_menu_qdma {Other_network_controller}
    CONFIG.pf0_class_code_qdma {028000}
    CONFIG.pf1_base_class_menu_qdma {Network_controller}
    CONFIG.pf1_class_code_base_qdma {02}
    CONFIG.pf1_class_code_sub_qdma {80}
    CONFIG.pf1_sub_class_interface_menu_qdma {Other_network_controller}
    CONFIG.pf1_class_code_qdma {028000}
} [get_ips $qdma]

set_property CONFIG.tl_pf_enable_reg $num_phys_func [get_ips $qdma]
set_property CONFIG.num_queues $num_queue [get_ips $qdma]
