//==============================================================================
// Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
// SPDX-License-Identifier: MIT
//
//==============================================================================

#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include "hls_stream.h"


void ker_write_sqpidb(hls::stream<uint32_t> &qpid_wqecount, int sq_pidb_cnt, int sq_pidb_addr, hls::stream<uint64_t> &addr_sqpidbcount, uint64_t global_hw_timer, uint64_t &hw_start_timer, uint16_t &qpid, int wqe_count)
{
    uint32_t qpid_wqecount_local;
    uint64_t addr_sqpidbcount_tmp;
    qpid_wqecount_local = qpid_wqecount.read();
    qpid = (qpid_wqecount_local >> 16) & 0x0000ffff;
    addr_sqpidbcount_tmp = sq_pidb_addr;
    addr_sqpidbcount_tmp = (addr_sqpidbcount_tmp << 16) | ((wqe_count+sq_pidb_cnt) & 0x0000ffff);
    addr_sqpidbcount.write(addr_sqpidbcount_tmp);
    hw_start_timer = global_hw_timer;
}
