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
#include "ker_write_sqpidb.h"

int main(int argc, char **argv) {

    hls::stream<uint32_t> qpid_wqecount;
    hls::stream<uint64_t> addr_sqpidbcount;

int sq_pidb_cnt = 0x00000000;
  int sq_pidb_addr= 0x00020338;
  int wqe_count = 0x00000001;

    int qpid_wqecount_tmp = 0x00020005;
    int64_t addr_sqpidbcount_sw = 0x0000000203380001;
    int64_t addr_cqdbcount_tmp = 0x0000000000000005;
    int sw_sq_pidb_addr;
    int64_t addr_sqpidbcount_hw;
    int hw_timer_tmp;
    int64_t global_hw_timer = 0x000000000000000f;
    int wqecount;
    uint64_t hw_start_timer;
    uint16_t qpid;
    int match = 0;

    qpid_wqecount.write(qpid_wqecount_tmp);


    ker_write_sqpidb(qpid_wqecount, sq_pidb_cnt, sq_pidb_addr, addr_sqpidbcount, global_hw_timer, hw_start_timer, qpid, wqe_count);

        addr_sqpidbcount_hw = addr_sqpidbcount.read();

        if ((addr_sqpidbcount_hw != addr_sqpidbcount_sw) ) {
            std::cout << "Error: Result mismatch" << std::endl;
            std::cout << " software sq_pidb_addr = " << addr_sqpidbcount_sw
                      << " addr_sqpidbcount_hw = " << addr_sqpidbcount_hw
                      << " hw_start_timer = " << hw_start_timer
                      << " qpid = " << qpid
                      << std::endl;
            match = 1;
        }
    std::cout << " Hardware sq_pidb_addr = " << sq_pidb_addr
              << " addr_sqpidbcount_hw = " << addr_sqpidbcount_hw
              << " hw_start_timer = " << hw_start_timer
              << " qpid = " << qpid
              << std::endl;
    std::cout << "TEST " << (match ? "FAILED" : "PASSED") << std::endl;
    return (match ? EXIT_FAILURE : EXIT_SUCCESS);
}
