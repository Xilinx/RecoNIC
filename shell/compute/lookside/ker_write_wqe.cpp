//==============================================================================
// Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
// SPDX-License-Identifier: MIT
//
//==============================================================================

#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include "hls_stream.h"


void ker_write_wqe(int wrid, int wqe_count, int laddr_msb, int laddr_lsb, int payload_len, int opcode, int remote_offset_msb, int remote_offset_lsb, int r_key, int send_small_payload0, int send_small_payload1, int send_small_payload2, int send_small_payload3, int immdt_data, int* sq_addr_sys_mem)
{
    #pragma HLS INTERFACE m_axi port=sq_addr_sys_mem offset=direct bundle=hw_hndshk_sys_mem

    int wqe[16] = {0};
    wqe[0] = (int) wrid;
    wqe[1] = (int) laddr_lsb;
    wqe[2] = (int) laddr_msb;
    wqe[3] = (int) payload_len;
    wqe[4] = (int) opcode;
    wqe[5] = (int) remote_offset_lsb;
    wqe[6] = (int) remote_offset_msb;
    wqe[7] = (int) r_key;
    wqe[8] = (int) send_small_payload0;
    wqe[9] = (int) send_small_payload1;
    wqe[10] = (int) send_small_payload2;
    wqe[11] = (int) send_small_payload3;
    wqe[12] = (int) immdt_data;
    
    for(int i=0 ; i < wqe_count ; i++)
    {
        memcpy(sq_addr_sys_mem, wqe, 16 * sizeof(int));
        sq_addr_sys_mem = sq_addr_sys_mem + 0x10;
    }
}
