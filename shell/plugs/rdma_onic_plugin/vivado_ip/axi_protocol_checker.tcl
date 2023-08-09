#==============================================================================
# Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
# SPDX-License-Identifier: MIT
#
#==============================================================================
create_ip -name axi_protocol_checker -vendor xilinx.com -library ip -version 2.0 -module_name $ip -dir ${ip_build_dir}

set_property -dict [list CONFIG.ADDR_WIDTH {64} CONFIG.DATA_WIDTH {512} CONFIG.READ_WRITE_MODE {READ_WRITE} CONFIG.MAX_RD_BURSTS {16} CONFIG.MAX_WR_BURSTS {16} CONFIG.HAS_SYSTEM_RESET {0} CONFIG.ENABLE_MARK_DEBUG {1} CONFIG.CHK_ERR_RESP {0} CONFIG.HAS_WSTRB {1}] [get_ips $ip]
