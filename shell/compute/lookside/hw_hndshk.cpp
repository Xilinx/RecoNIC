//==============================================================================
// Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
// SPDX-License-Identifier: MIT
//
//==============================================================================

#include <stdio.h>
#include <stdint.h>
#include "hls_stream.h"


void parse_ctl_cmd(hls::stream<uint32_t> &ctl_cmd_stream, int &sq_pidb_cnt, int &cq_db_cnt, int &sq_pidb_addr, int &wrid, int &wqe_count, int &laddr_msb, int &laddr_lsb, int &payload_len, int &opcode, int &remote_offset_msb, int &remote_offset_lsb, int &r_key, int &send_small_payload0, int &send_small_payload1, int &send_small_payload2, int &send_small_payload3, int &immdt_data, int &sq_addr_lsb, int &sq_addr_msb)
{
    //parse parameters
    uint32_t cmd_array[18] = {0};
    uint32_t ctl_cmd;
    bool has_item;
    
    uint32_t cmd_size;
    uint32_t cmd_recved;

    cmd_size = ctl_cmd_stream.read();
    cmd_recved = 0;

    while(cmd_recved <= (cmd_size-2)){
        cmd_array[cmd_recved] = ctl_cmd_stream.read();
        cmd_recved = cmd_recved + 1;
    }
    sq_pidb_cnt = (int) cmd_array[0];
    cq_db_cnt = (int) cmd_array[1];
    sq_pidb_addr = (int) cmd_array[2];
    opcode = (int) cmd_array[3] & 0x0000ffff;
    wrid = (int) ((cmd_array[3] >> 16) & 0x0000ffff);
    wqe_count = (int) cmd_array[4];
    laddr_msb = (int) cmd_array[5];
    laddr_lsb = (int) cmd_array[6];
    payload_len = (int) cmd_array[7];
    remote_offset_msb = (int) cmd_array[8];
    remote_offset_lsb = (int) cmd_array[9];
    r_key = (int) cmd_array[10];
    send_small_payload0 = (int) cmd_array[11];
    send_small_payload1 = (int) cmd_array[12];
    send_small_payload2 = (int) cmd_array[13];
    send_small_payload3 = (int) cmd_array[14];
    immdt_data = (int) cmd_array[15];
    sq_addr_msb = cmd_array[16];
    sq_addr_lsb = cmd_array[17];

}


void hw_hndshk(hls::stream<uint32_t> &ctl_cmd_stream, int &sq_pidb_cnt, int &cq_db_cnt, int &sq_pidb_addr, int &wrid, int &wqe_count, int &laddr_msb, int &laddr_lsb, int &payload_len, int &opcode, int &remote_offset_msb, int &remote_offset_lsb, int &r_key, int &send_small_payload0, int &send_small_payload1, int &send_small_payload2, int &send_small_payload3, int &immdt_data, int &sq_addr_lsb, int &sq_addr_msb) {

    #pragma HLS interface mode=ap_ctrl_hs port=return

    uint32_t ctl_cmd;
    bool has_item;
    uint32_t cmd_size;

    parse_ctl_cmd(ctl_cmd_stream, sq_pidb_cnt, cq_db_cnt, sq_pidb_addr, wrid, wqe_count, laddr_msb, laddr_lsb, payload_len, opcode, remote_offset_msb, remote_offset_lsb, r_key, send_small_payload0, send_small_payload1, send_small_payload2, send_small_payload3, immdt_data, sq_addr_lsb, sq_addr_msb);

}
