//==============================================================================
// Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
// SPDX-License-Identifier: MIT
//
//==============================================================================

#include "hls_stream.h"


void ker_write_sqpidb(hls::stream<uint32_t> &qpid_wqecount, int sq_pidb_cnt, int sq_pidb_addr, hls::stream<uint64_t> &addr_sqpidbcount, uint64_t global_hw_timer, uint64_t &hw_start_timer, uint16_t &qpid, int wqe_count);