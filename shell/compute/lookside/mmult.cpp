//==============================================================================
// Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
// Copyright (c) 2022, Xilinx, Inc.
// SPDX-License-Identifier: MIT
//
//==============================================================================
//   
//    This is a matrix multiplication example which showcases the "Systolic Array"
//    based algorithm design. Systolic array type of implementation is well suited
//    for FPGAs.
//
//    The example is modified from from https://github.com/Xilinx/SDAccel_Examples/
//    blob/master/getting_started/kernel_opt/systolic_array_c/src/mmult.cpp
//==============================================================================

/*
Kernel Description :
   
    This kernel is a systolic array based matrix multiplication. Though the 
    maximum size of the input matrices are restricted to a smaller MAX_SIZE, it
    is still possible to use this approach and get better performance for larger
    matrices by using tiling.
    
    Arguments :
    
        int *a     (input )  --> Input  Matrix A
        int *b     (input )  --> Input  Matrix B
        int *c     (output)  --> Output Matrix
        int  a_row (input )  --> Row Size Matrix A
        int  a_col (input )  --> Col Size Matrix A
        int  b_col (input )  --> Col Size Matrix B
    Kernel Configuration :
        
        Max Size    --> 16
    
    Note : 
        Max Size is dependent on the available DSP resources in the FPGA
*/

#include <stdio.h>
#include <stdint.h>
#include <string.h>

#include "mmult.h"

//Maximum Array Size
#define MAX_SIZE 16
//#define MAX_SIZE 32

//TRIPCOUNT identifier
const unsigned int c_size = MAX_SIZE;

void mmult(hls::stream<int> &work_id_out_stream,
           const int *a, // Read-Only Matrix A
           const int *b, // Read-Only Matrix B
           int *c,       // Output Result
           int a_row,    // Matrix A Row Size
           int a_col,    // Matrix A Col Size
           int b_col,    // Matrix B Col Size
           int work_id
) {
   //#pragma HLS INTERFACE m_axi port=a offset=slave bundle=gmem
   //#pragma HLS INTERFACE m_axi port=b offset=slave bundle=gmem
   //#pragma HLS INTERFACE m_axi port=c offset=slave bundle=gmem
   //#pragma HLS INTERFACE s_axilite port=a bundle=control
   //#pragma HLS INTERFACE s_axilite port=b bundle=control
   //#pragma HLS INTERFACE s_axilite port=c bundle=control

   //#pragma HLS INTERFACE s_axilite port=a_row bundle=control
   //#pragma HLS INTERFACE s_axilite port=a_col bundle=control
   //#pragma HLS INTERFACE s_axilite port=b_col bundle=control
   //#pragma HLS INTERFACE s_axilite port=return bundle=control

   //#pragma HLS INTERFACE ap_fifo port=ctl_cmd_stream

   #pragma HLS INTERFACE m_axi port=a offset=direct bundle=systolic
   #pragma HLS INTERFACE m_axi port=b offset=direct bundle=systolic
   #pragma HLS INTERFACE m_axi port=c offset=direct bundle=systolic

   #pragma HLS INTERFACE ap_vld port=a_row
   #pragma HLS INTERFACE ap_vld port=a_col
   #pragma HLS INTERFACE ap_vld port=b_col
   #pragma HLS INTERFACE ap_vld port=work_id

   #pragma HLS INTERFACE mode=ap_ctrl_hs port=return

    int b_row = a_col;
    int c_row = a_row;
    int c_col = b_col;

    // Local memory to store input and output matrices
    int localA[MAX_SIZE][MAX_SIZE];
   #pragma HLS ARRAY_PARTITION variable=localA dim=1 complete

    int localB[MAX_SIZE][MAX_SIZE];
   #pragma HLS ARRAY_PARTITION variable=localB dim=2 complete

    int localC[MAX_SIZE][MAX_SIZE];
#pragma HLS ARRAY_PARTITION variable = localC dim = 0 complete

// Burst reads on input matrices from global memory
// Read Input A
readA:
    memcpy(localA, a, (MAX_SIZE*MAX_SIZE)*sizeof(int));

// Read Input B
readB:
    memcpy(localB, b, (MAX_SIZE*MAX_SIZE)*sizeof(int));

    // Perform systolic matrix multiply
    // local matrices localA and localB have been partitioned in dimensions
    // 1 and 2 respectively. local matrix C has been partitioned completely

    // This partitioning enables to access MAX_SIZE elements in parallel in
    // the local matrices. Because of the mode of access of array elements,
    // we are able to perform MAX_SIZE*MAX_SIZE operations in parallel.

    // Note : i, j and k loops are interchanged.

    // The top loop systolic1 runs only for a_col iterations instead of
    // MAX_SIZE like the inner loops. The inner loops have fixed loop
    // iteration counts to enable complete unroll

    // The following diagram explains how the matrix multiply happens
    //
    //        B_0        B_1        B_2        B_3
    //         |          |          |          |
    //         v          v          v          v
    //        ___        ___        ___        ___
    //       |   |      |   |      |   |      |   |
    //  A0_->|C00| ---- |C01| ---- |C02| ---- |C03|
    //       |___|      |___|      |___|      |___|
    //         |          |          |          |
    //        ___        ___        ___        ___
    //       |   |      |   |      |   |      |   |
    //  A1_->|C10| ---- |C11| ---- |C12| ---- |C13|
    //       |___|      |___|      |___|      |___|
    //         |          |          |          |
    //        ___        ___        ___        ___
    //       |   |      |   |      |   |      |   |
    //  A2_->|C20| ---- |C21| ---- |C21| ---- |C21|
    //       |___|      |___|      |___|      |___|
    //         |          |          |          |
    //        ___        ___        ___        ___
    //       |   |      |   |      |   |      |   |
    //  A3_->|C30| ---- |C31| ---- |C32| ---- |C33|
    //       |___|      |___|      |___|      |___|

systolic1:
    for (int k = 0; k < a_col; k++) {
       #pragma HLS LOOP_TRIPCOUNT min=c_size max=c_size
       #pragma HLS PIPELINE II=1
    systolic2:
        for (int i = 0; i < MAX_SIZE; i++) {
        systolic3:
            for (int j = 0; j < MAX_SIZE; j++) {

                // Get previous sum
                int last = (k == 0) ? 0 : localC[i][j];

                // Update current sum
                // Handle boundary conditions
                int a_val = (i < a_row && k < a_col) ? localA[i][k] : 0;
                int b_val = (k < b_row && j < b_col) ? localB[k][j] : 0;
                int result = last + a_val * b_val;

                // Write back results
                localC[i][j] = result;
            }
        }
    }

// Burst write from output matrices to global memory
// Burst write from matrix C
writeC:
	memcpy(c, localC, (MAX_SIZE*MAX_SIZE)*sizeof(int));

    work_id_out_stream.write(work_id);
}
