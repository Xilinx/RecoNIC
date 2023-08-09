//==============================================================================
// Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
// SPDX-License-Identifier: MIT
//
//==============================================================================

#include <stdio.h>
#include <stdint.h>
#include "hls_stream.h"

// TODO: Do not consider tiled based MM at the moment
void parse_ctl_cmd(hls::stream<uint32_t> &ctl_cmd_stream, int &a_baseaddr, int &b_baseaddr, \
                   int &c_baseaddr, int &a_row, int &a_col, int &b_col, int &work_id) {

    uint32_t cmd_array[5] = {0};
    uint32_t ctl_cmd;
    bool has_item;
    uint32_t cmd_size;
    uint32_t cmd_recved = 0;

    cmd_size = ctl_cmd_stream.read();
    while(cmd_recved <= (cmd_size-2)){
        cmd_array[cmd_recved] = ctl_cmd_stream.read();
        cmd_recved = cmd_recved + 1;
    }

    a_baseaddr = (int) cmd_array[0];
    b_baseaddr = (int) cmd_array[1];
    c_baseaddr = (int) cmd_array[2];
    a_row = (int) (cmd_array[3] >> 16);
    a_col = (int) (cmd_array[3] & 0x0000ffff);
    b_col = (int) (cmd_array[4] >> 16);
    work_id = (int) (cmd_array[4] & 0x0000ffff);
}

// TODO: In the current implementation, we let the host to send control commands for simplicity.
//       In the future, we need to implement a logic by just sending base addresses of control
//       commands and let a kernel to get actual control command by itself via AXI interface.
// TODO: Do not consider tiled based MM at the moment
void cl_box(hls::stream<uint32_t> &ctl_cmd_stream, int &a_baseaddr, int &b_baseaddr, \
            int &c_baseaddr, int &a_row, int &a_col, int &b_col, int &work_id) {

    //#pragma HLS INTERFACE ap_vld port=a_baseaddr
    //#pragma HLS INTERFACE ap_vld port=b_baseaddr
    //#pragma HLS INTERFACE ap_vld port=c_baseaddr
    #pragma HLS interface mode=ap_ctrl_hs port=return

	#pragma HLS inline recursive

    uint32_t ctl_cmd;
    uint32_t cmd_size;
    bool has_item;

    parse_ctl_cmd(ctl_cmd_stream, a_baseaddr, b_baseaddr, c_baseaddr, a_row, a_col, b_col, work_id);

}
