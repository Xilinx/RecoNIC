#==============================================================================
# Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
# SPDX-License-Identifier: MIT
#
#==============================================================================
open_project ker_write_wqe
set_top ker_write_wqe
add_files ./ker_write_wqe.cpp
add_files -tb ./ker_write_wqe.h -cflags "-Wno-unknown-pragmas" -csimflags "-Wno-unknown-pragmas"
add_files -tb ./test_ker_write_wqe.cpp -cflags "-Wno-unknown-pragmas" -csimflags "-Wno-unknown-pragmas"
open_solution "solution1" -flow_target vivado
set_part {xcvu9p-flga2104-2L-e}
create_clock -period 4 -name default
config_interface -m_axi_alignment_byte_size 64 -m_axi_max_widen_bitwidth 512
csim_design
csynth_design
exit