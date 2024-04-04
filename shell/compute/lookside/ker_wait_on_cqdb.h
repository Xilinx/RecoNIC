//==============================================================================
// Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
// SPDX-License-Identifier: MIT
//
//==============================================================================

#include "hls_stream.h"


void ker_wait_on_cqdb(int cq_db_cnt, hls::stream<uint64_t> &addr_cqdbcount, uint16_t wqecount);