//==============================================================================
// Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
// SPDX-License-Identifier: MIT
//
//==============================================================================

#include <stdio.h>
#include <stdint.h>
#include <cassert>
#include "hls_stream.h"


void ker_wait_on_cqdb(int cq_db_cnt, hls::stream<uint64_t> &addr_cqdbcount, uint16_t wqecount)
{
    uint64_t addr_cqdbcount_tmp;
    uint32_t cq_db_cnt_local;
    addr_cqdbcount_tmp = addr_cqdbcount.read();
    cq_db_cnt_local = addr_cqdbcount_tmp & 0x0000ffff;

    while (cq_db_cnt_local != (wqecount+cq_db_cnt))
    {
        addr_cqdbcount_tmp = addr_cqdbcount.read();
        cq_db_cnt_local = cq_db_cnt_local + addr_cqdbcount_tmp & 0x0000ffff;
    }

}
