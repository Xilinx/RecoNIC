#==============================================================================
# Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
# SPDX-License-Identifier: MIT
#
#==============================================================================
set rdma rdma_core
create_ip -name ernic -vendor xilinx.com -library ip -version 3.1 -module_name $rdma -dir ${ip_build_dir}

set_property -dict {
    CONFIG.C_NUM_QP {32} 
    CONFIG.C_S_AXI_LITE_ADDR_WIDTH {32}
    CONFIG.C_M_AXI_ADDR_WIDTH {64} 
    CONFIG.C_EN_DEBUG_PORTS {1} 
    CONFIG.C_MAX_WR_RETRY_DATA_BUF_DEPTH {2048} 
    CONFIG.C_EN_INITIATOR_LITE {1} 
} [get_ips $rdma]