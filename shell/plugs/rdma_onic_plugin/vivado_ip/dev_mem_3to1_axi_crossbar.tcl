#==============================================================================
# Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
# SPDX-License-Identifier: MIT
#
#==============================================================================
set device_memory_axi_crossbar dev_mem_3to1_axi_crossbar

create_ip -name axi_crossbar -vendor xilinx.com -library ip -version 2.1 -module_name $device_memory_axi_crossbar -dir ${ip_build_dir}

set_property -dict {
    CONFIG.ADDR_RANGES {1}
    CONFIG.NUM_SI {3}
    CONFIG.NUM_MI {1}
    CONFIG.ADDR_WIDTH {64}
    CONFIG.DATA_WIDTH {512}
    CONFIG.ID_WIDTH {5}
    CONFIG.S00_THREAD_ID_WIDTH {3}
    CONFIG.S01_THREAD_ID_WIDTH {3}
    CONFIG.S02_THREAD_ID_WIDTH {3}
    CONFIG.S00_WRITE_ACCEPTANCE {8}
    CONFIG.S01_WRITE_ACCEPTANCE {8}
    CONFIG.S02_WRITE_ACCEPTANCE {8}
    CONFIG.S00_READ_ACCEPTANCE {8}
    CONFIG.S01_READ_ACCEPTANCE {8}
    CONFIG.S02_READ_ACCEPTANCE {8}
    CONFIG.M00_WRITE_ISSUING {16}
    CONFIG.M00_READ_ISSUING {16}
    CONFIG.S00_SINGLE_THREAD {0}
    CONFIG.M00_A00_ADDR_WIDTH {64}
} [get_ips $device_memory_axi_crossbar]