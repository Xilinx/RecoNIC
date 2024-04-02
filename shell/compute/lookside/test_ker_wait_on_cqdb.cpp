//==============================================================================
// Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
// Copyright (c) 2022, Xilinx, Inc.
// SPDX-License-Identifier: MIT
//
//==============================================================================

/*******************************************************************************

*******************************************************************************/
#include <iostream>
#include <stdio.h>
#include <stdint.h>

#include "hls_stream.h"
#include "ker_wait_on_cqdb.h"

int main(int argc, char **argv) {

    hls::stream<uint64_t> addr_cqdbcount;
    //hls::stream<uint32_t> hw_timer;

    int cq_db_cnt = 0;
    int64_t addr_cqdbcount_tmp = 0x0000000000000005;
    //int hw_timer_tmp;
    //int64_t global_hw_timer = 0x000000000000000f;
    int16_t wqecount = 0x0005;
    //uint64_t hw_start_timer = 0x0000000000000000;
    //uint16_t qpid = 0x0002;

    int match = 0;

    addr_cqdbcount.write(addr_cqdbcount_tmp);

    ker_wait_on_cqdb(cq_db_cnt, addr_cqdbcount, wqecount);


        if ((addr_cqdbcount_tmp & 0x0000ffff) != wqecount) {
            std::cout << "Error: Result mismatch" << std::endl;
            std::cout << " wqecount = " << wqecount
                      << std::endl;
            match = 1;
        }
    std::cout << " wqecount = " << wqecount
              << std::endl;
    std::cout << "TEST " << (match ? "FAILED" : "PASSED") << std::endl;
    return (match ? EXIT_FAILURE : EXIT_SUCCESS);
}
