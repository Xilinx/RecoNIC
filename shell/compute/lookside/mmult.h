//==============================================================================
// Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
// SPDX-License-Identifier: MIT
//
//==============================================================================

#ifndef __MMULT_H__
#define __MMULT_H__

#include "hls_stream.h"

void mmult(hls::stream<int> &work_id_out_stream,
           const int *a, // Read-Only Matrix A
           const int *b, // Read-Only Matrix B
           int *c,       // Output Result
           int a_row,    // Matrix A Row Size
           int a_col,    // Matrix A Col Size
           int b_col,    // Matrix B Col Size
           int work_id
          );

#endif
