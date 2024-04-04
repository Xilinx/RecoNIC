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
#include "ker_write_wqe.h"

int main(int argc, char **argv) {

  int sq_pidb_cnt = 0x00000000;
  int cq_db_cnt   = 0x00000000;
  int sq_pidb_addr= 0x00020338;
  int wrid = 0x00000001;
  int opcode = 0x00000004;
  int wqe_count = 0x00000002;
  int laddr_msb = 0x00000000;
  int laddr_lsb = 0x00000400;
  int payload_len = 0x00000040;
  int remote_offset_msb = 0x00000000;
  int remote_offset_lsb = 0xabcd0000;
  int r_key = 0x00000016;
  int send_small_payload0 = 0x00000000;
  int send_small_payload1 = 0x00000000;
  int send_small_payload2 = 0x00000000;
  int send_small_payload3 = 0x00000000;
  int immdt_data = 0x00000000;
  int sq_addr_msb = 0x00000000;
  int sq_addr_lsb = 0x00090000;

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
    int sq_addr_sys_mem_sw [32] = {0};
    int sq_addr_sys_mem_hw [32];

    sq_addr_sys_mem_sw [0] = (int) wrid;
    sq_addr_sys_mem_sw [1] = (int) laddr_lsb;
    sq_addr_sys_mem_sw [2] = (int) laddr_msb;
    sq_addr_sys_mem_sw [3] = (int) payload_len;
    sq_addr_sys_mem_sw [4] = (int) opcode;
    sq_addr_sys_mem_sw [5] = (int) remote_offset_lsb;
    sq_addr_sys_mem_sw [6] = (int) remote_offset_msb;
    sq_addr_sys_mem_sw [7] = (int) r_key;
    sq_addr_sys_mem_sw [8] = (int) send_small_payload0;
    sq_addr_sys_mem_sw [9] = (int) send_small_payload1;
    sq_addr_sys_mem_sw [10] = (int) send_small_payload2;
    sq_addr_sys_mem_sw [11] = (int) send_small_payload3;
    sq_addr_sys_mem_sw [12] = (int) immdt_data;

    sq_addr_sys_mem_sw [16] = (int) wrid;
    sq_addr_sys_mem_sw [17] = (int) laddr_lsb;
    sq_addr_sys_mem_sw [18] = (int) laddr_msb;
    sq_addr_sys_mem_sw [19] = (int) payload_len;
    sq_addr_sys_mem_sw [20] = (int) opcode;
    sq_addr_sys_mem_sw [21] = (int) remote_offset_lsb;
    sq_addr_sys_mem_sw [22] = (int) remote_offset_msb;
    sq_addr_sys_mem_sw [23] = (int) r_key;
    sq_addr_sys_mem_sw [24] = (int) send_small_payload0;
    sq_addr_sys_mem_sw [25] = (int) send_small_payload1;
    sq_addr_sys_mem_sw [26] = (int) send_small_payload2;
    sq_addr_sys_mem_sw [27] = (int) send_small_payload3;
    sq_addr_sys_mem_sw [28] = (int) immdt_data;

    ker_write_wqe(wrid, wqe_count, laddr_msb, laddr_lsb, payload_len, opcode, remote_offset_msb, remote_offset_lsb, r_key, send_small_payload0, send_small_payload1, send_small_payload2, send_small_payload3, immdt_data, sq_addr_sys_mem_hw);

        for (int i = 0; i < 16; i++) {
        if (sq_addr_sys_mem_hw[i] != sq_addr_sys_mem_sw[i]) {
            std::cout << "Error: Result mismatch" << std::endl;
            std::cout << "i = " << i << " CPU result = " << sq_addr_sys_mem_sw[i]
                      << " Hardware result = " << sq_addr_sys_mem_hw[i]
                      << std::endl;
            match = 1;
            break;
        }
    }

    for (int i = 16; i < 32; i++) {
        if (sq_addr_sys_mem_hw[i] != sq_addr_sys_mem_sw[i]) {
            std::cout << "Error: Result mismatch" << std::endl;
            std::cout << "i = " << i << " CPU result = " << sq_addr_sys_mem_sw[i]
                      << " Hardware result = " << sq_addr_sys_mem_hw[i]
                      << std::endl;
            match = 1;
            break;
        }
    }

    std::cout << "TEST " << (match ? "FAILED" : "PASSED") << std::endl;
    return (match ? EXIT_FAILURE : EXIT_SUCCESS);
}
