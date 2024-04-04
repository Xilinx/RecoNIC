//==============================================================================
// Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
// Copyright (c) 2022, Xilinx, Inc.
// SPDX-License-Identifier: MIT
//
//==============================================================================

/*******************************************************************************
Description: 
    This is a matrix multiplication which showcases the "Systolic Array" based 
    algorithm design. Systolic array type of implementation is well suited for 
    FPGAs. It is a good coding practice to convert base algorithm into Systolic 
    Array implementation if it is feasible to do so.
*******************************************************************************/
#include <iostream>
#include <stdio.h>
#include <stdint.h>

#include "hls_stream.h"
#include "hw_hndshk.h"

#define CTL_CMD_SIZE 19

void init_streams(hls::stream<uint32_t> &ctl_cmds, hls::stream<int> &sw_status_stream) {
  int i=0;
  int sq_pidb_cnt = 0x00000000;
  int cq_db_cnt   = 0x00000000;
  int sq_pidb_addr= 0x00020338;
  int wrid_opcode = 0x00010004;
  int wqe_count = 0x00000001;
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

    ctl_cmds.write(CTL_CMD_SIZE);
    ctl_cmds.write(sq_pidb_cnt);
    ctl_cmds.write(cq_db_cnt);
    ctl_cmds.write(sq_pidb_addr);
    ctl_cmds.write(wrid_opcode);
    ctl_cmds.write(wqe_count);
    ctl_cmds.write(laddr_msb);
    ctl_cmds.write(laddr_lsb);
    ctl_cmds.write(payload_len);
    ctl_cmds.write(remote_offset_msb);
    ctl_cmds.write(remote_offset_lsb);
    ctl_cmds.write(r_key);
    ctl_cmds.write(send_small_payload0);
    ctl_cmds.write(send_small_payload1);
    ctl_cmds.write(send_small_payload2);
    ctl_cmds.write(send_small_payload3);
    ctl_cmds.write(immdt_data);
    ctl_cmds.write(sq_addr_msb);
    ctl_cmds.write(sq_addr_lsb);
    sw_status_stream.write(sq_pidb_addr);
}

int main(int argc, char **argv) {

    hls::stream<uint32_t> ctl_cmd_stream;
    hls::stream<int> hw_status_stream;
    hls::stream<int> sw_status_stream;

    int sq_pidb_cnt;
    int cq_db_cnt;
    int sq_pidb_addr;
    
    int match = 0;

    
    int wrid;
    int wqe_count;
    int laddr_msb;
    int laddr_lsb;
    int payload_len;
    int opcode;
    int remote_offset_msb;
    int remote_offset_lsb;
    int r_key;
    int send_small_payload0;
    int send_small_payload1;
    int send_small_payload2;
    int send_small_payload3;
    int immdt_data;
    int sq_addr_lsb;
    int sq_addr_msb;

    int sw_sq_pidb_addr;

    // Initialize input and golden streams
    init_streams(ctl_cmd_stream, sw_status_stream);

    hw_hndshk(ctl_cmd_stream, sq_pidb_cnt, cq_db_cnt, sq_pidb_addr, wrid, wqe_count, laddr_msb, laddr_lsb, payload_len, opcode, remote_offset_msb, remote_offset_lsb, r_key, send_small_payload0, send_small_payload1, send_small_payload2, send_small_payload3, immdt_data, sq_addr_lsb, sq_addr_msb);

        sw_sq_pidb_addr = sw_status_stream.read();

        if ((sw_sq_pidb_addr != sq_pidb_addr) ) {
            std::cout << "Error: Result mismatch" << std::endl;
            std::cout << " sw_sq_pidb_addr = " << sw_sq_pidb_addr
                      << " Hardware sq_pidb_addr = " << sq_pidb_addr
                      << " opcode = " << opcode
                      << " sq_addr_lsb = " << sq_addr_lsb
                      << " wqe count = " << wqe_count
                      << std::endl;
            match = 1;
        }
    std::cout << " sw_sq_pidb_addr = " << sw_sq_pidb_addr
              << " Hardware sq_pidb_addr = " << sq_pidb_addr
              << " opcode = " << opcode
              << " sq_addr = " << sq_addr_lsb
              << " wqe count = " << wqe_count
              << std::endl;
    std::cout << "TEST " << (match ? "FAILED" : "PASSED") << std::endl;
    return (match ? EXIT_FAILURE : EXIT_SUCCESS);
}
