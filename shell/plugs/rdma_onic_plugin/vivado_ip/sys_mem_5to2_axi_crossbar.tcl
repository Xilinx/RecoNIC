#==============================================================================
# Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
# SPDX-License-Identifier: MIT
#
#==============================================================================
set system_memory_axi_crossbar sys_mem_5to2_axi_crossbar

create_ip -name axi_crossbar -vendor xilinx.com -library ip -version 2.1 -module_name $system_memory_axi_crossbar -dir ${ip_build_dir}

set_property -dict {
    CONFIG.ADDR_RANGES {1}
    CONFIG.NUM_SI {5}
    CONFIG.NUM_MI {2}
    CONFIG.ADDR_WIDTH {64}
    CONFIG.DATA_WIDTH {512}
    CONFIG.ID_WIDTH {3}
    CONFIG.S15_THREAD_ID_WIDTH {0}
    CONFIG.S00_WRITE_ACCEPTANCE {8}
    CONFIG.S01_WRITE_ACCEPTANCE {8}
    CONFIG.S02_WRITE_ACCEPTANCE {8}
    CONFIG.S03_WRITE_ACCEPTANCE {8}
    CONFIG.S04_WRITE_ACCEPTANCE {8}
    CONFIG.S00_READ_ACCEPTANCE {8}
    CONFIG.S01_READ_ACCEPTANCE {8}
    CONFIG.S02_READ_ACCEPTANCE {8}
    CONFIG.S03_READ_ACCEPTANCE {8}
    CONFIG.S04_READ_ACCEPTANCE {8}
    CONFIG.M00_WRITE_ISSUING {16}
    CONFIG.M00_READ_ISSUING {16}
    CONFIG.M01_WRITE_ISSUING {16}
    CONFIG.M01_READ_ISSUING {16}
    CONFIG.S00_SINGLE_THREAD {0}
    CONFIG.M00_A00_ADDR_WIDTH {52}
    CONFIG.M01_A00_ADDR_WIDTH {36}
    CONFIG.M00_A00_BASE_ADDR {0x0000000000000000}
    CONFIG.M01_A00_BASE_ADDR {0xa350000000000000}
} [get_ips $system_memory_axi_crossbar]