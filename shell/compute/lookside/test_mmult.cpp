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

#include "mmult.h"

//Array Size to access
#define DATA_SIZE 16

//Maximum Array Size
#define MAX_SIZE 16

// Software implementation of Matrix Multiplication
// The inputs are of the size (DATA_SIZE x DATA_SIZE)
void software_mmult(
    int in1[DATA_SIZE*DATA_SIZE], //Input Matrix 1
    int in2[DATA_SIZE*DATA_SIZE], //Input Matrix 2
    int out[DATA_SIZE*DATA_SIZE]  //Output Matrix
) {
    //Perform Matrix multiply Out = In1 x In2
    for (int i = 0; i < DATA_SIZE; i++) {
        for (int j = 0; j < DATA_SIZE; j++) {
            for (int k = 0; k < DATA_SIZE; k++) {
                out[i * DATA_SIZE + j] +=
                    in1[i * DATA_SIZE + k] * in2[k * DATA_SIZE + j];
            }
        }
    }
}

int main(int argc, char **argv) {

    //Allocate Memory in Host Memory
    if (DATA_SIZE > MAX_SIZE) {
        std::cout << "Size is bigger than internal buffer size, please use a "
                     "size smaller than "
                  << MAX_SIZE << "!" << std::endl;
        return EXIT_FAILURE;
    }

    size_t matrix_size = DATA_SIZE * DATA_SIZE;
    size_t matrix_size_bytes = sizeof(int) * matrix_size;

    int source_in1[matrix_size];
    int source_in2[matrix_size];
    int source_hw_results[matrix_size];
    int source_sw_results[matrix_size];

    // Create the test data and Software Result
    for (size_t i = 0; i < matrix_size; i++) {
        source_in1[i] = i % 10;
        source_in2[i] = i % 10;
        source_sw_results[i] = 0;
        source_hw_results[i] = 0;
    }

    int a_row = DATA_SIZE;
    int a_col = DATA_SIZE;
    int b_col = DATA_SIZE;
    int work_id = 0xdd;
    hls::stream<int> hw_kernel_id_out_stream;

    // Call hw implementation
    mmult(hw_kernel_id_out_stream, source_in1, source_in2, source_hw_results, a_row, a_col, b_col, work_id);

    // Compute Software Results
    software_mmult(source_in1, source_in2, source_sw_results);

    // Compare the results of the Device to the simulation
    int match = 0;
    for (int i = 0; i < DATA_SIZE * DATA_SIZE; i++) {
        if (source_hw_results[i] != source_sw_results[i]) {
            std::cout << "Error: Result mismatch" << std::endl;
            std::cout << "i = " << i << " CPU result = " << source_sw_results[i]
                      << " Hardware result = " << source_hw_results[i]
                      << std::endl;
            match = 1;
            break;
        }
    }

    /*
    // Check work id returned
    int hw_work_id;
    while(!hw_kernel_id_out_stream.empty());
    hw_work_id = hw_kernel_id_out_stream.read();
    if(hw_work_id != work_id) {
        std::cout << "Error: Work ID result mismatch" << std::endl;
        std::cout << "HW work id = " << hw_work_id << " CPU result = " << work_id
                  << std::endl;
        match = 1;
    }
	*/

    std::cout << "TEST " << (match ? "FAILED" : "PASSED") << std::endl;
    return (match ? EXIT_FAILURE : EXIT_SUCCESS);
}
