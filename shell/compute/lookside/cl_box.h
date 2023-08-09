//==============================================================================
// Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
// SPDX-License-Identifier: MIT
//
//==============================================================================

#ifndef __RN_CL_WRAPPER__
#define __RN_CL_WRAPPER__

#include "hls_stream.h"

void parse_ctl_cmd(hls::stream<uint32_t> &ctl_cmd_stream, int &a_baseaddr, int &b_baseaddr, \
                   int &c_baseaddr, int &a_row, int &a_col, int &b_col, int &work_id);

void cl_box(hls::stream<uint32_t> &ctl_cmd_stream, int &a_baseaddr, int &b_baseaddr, \
            int &c_baseaddr, int &a_row, int &a_col, int &b_col, int &work_id);

#endif