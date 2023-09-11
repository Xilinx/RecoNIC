#==============================================================================
# Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
# SPDX-License-Identifier: MIT
#
#==============================================================================
create_ip -name axi_bram_ctrl -vendor xilinx.com -library ip -version 4.1 -module_name $ip -dir ${ip_build_dir}

set_property -dict {
    CONFIG.DATA_WIDTH {512}
    CONFIG.SUPPORTS_NARROW_BURST {1}
    CONFIG.SINGLE_PORT_BRAM {0}
    CONFIG.ECC_TYPE {0}
    CONFIG.BMG_INSTANCE {INTERNAL}
    CONFIG.MEM_DEPTH {16384}
    CONFIG.ID_WIDTH {5}
    CONFIG.RD_CMD_OPTIMIZATION {0}
} [get_ips $ip]