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
#include "cl_box.h"

#define NUM_ENTRY 1
#define CTL_CMD_SIZE 6

void init_streams(hls::stream<uint32_t> &ctl_cmds, hls::stream<int> &sw_status_stream) {
  int i=0;
  int a_baseaddr = 0x00010000;
  int b_baseaddr = 0x00020000;
  int c_baseaddr = 0x00030000;
  // a_row = 16, b_row = 16
  int a_row_col  = 0x00100010;
  int b_col   = 0x0010;
  int work_id = 0x00dd;
  int ctl_last = (b_col<<16) | work_id;
  for(i=0; i<NUM_ENTRY; i++) {
    ctl_cmds.write(CTL_CMD_SIZE);
    ctl_cmds.write(a_baseaddr + i*0x100);
    ctl_cmds.write(b_baseaddr + i*0x100);
    ctl_cmds.write(c_baseaddr + i*0x100);
    ctl_cmds.write(a_row_col);
    ctl_cmds.write(ctl_last + i);
    sw_status_stream.write(work_id + i);
  }
}

int main(int argc, char **argv) {

    //Allocate Memory in Host Memory
    hls::stream<uint32_t> ctl_cmd_stream;
    hls::stream<int> hw_status_stream;
    hls::stream<int> sw_status_stream;

    int a_baseaddr;
    int b_baseaddr;
    int c_baseaddr;
    int a_row;
    int a_col;
    int b_col;

    int match = 0;
    int sw_work_id;
    int hw_work_id;

    // Initialize input and golden streams
    init_streams(ctl_cmd_stream, sw_status_stream);

    // Call hw implementation
    //cl_box(ctl_cmd_stream, hw_status_stream, a_baseaddr, b_baseaddr, c_baseaddr, a_row, a_col, b_col);
    cl_box(ctl_cmd_stream, a_baseaddr, b_baseaddr, c_baseaddr, a_row, a_col, b_col, hw_work_id);

    // Compare the results of the Device to the simulation
    for (int i = 0; i < NUM_ENTRY; i++) {
        sw_work_id = sw_status_stream.read();
        //hw_work_id = hw_status_stream.read();
        if (sw_work_id != hw_work_id) {
            std::cout << "Error: Result mismatch" << std::endl;
            std::cout << "i = " << i << " CPU result = " << sw_work_id
                      << " Hardware result = " << hw_work_id
                      << std::endl;
            match = 1;
            break;
        }
    }

    std::cout << "TEST " << (match ? "FAILED" : "PASSED") << std::endl;
    return (match ? EXIT_FAILURE : EXIT_SUCCESS);
}
