//==============================================================================
// Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
// SPDX-License-Identifier: MIT
//
//==============================================================================

#include "hls_stream.h"


void parse_ctl_cmd(hls::stream<uint32_t> &ctl_cmd_stream, int &sq_pidb_cnt, int &cq_db_cnt, int &sq_pidb_addr, int &wrid, int &wqe_count, int &laddr_msb, int &laddr_lsb, int &payload_len, int &opcode, int &remote_offset_msb, int &remote_offset_lsb, int &r_key, int &send_small_payload0, int &send_small_payload1, int &send_small_payload2, int &send_small_payload3, int &immdt_data, int &sq_addr_lsb, int &sq_addr_msb);

void hw_hndshk(hls::stream<uint32_t> &ctl_cmd_stream, int &sq_pidb_cnt, int &cq_db_cnt, int &sq_pidb_addr, int &wrid, int &wqe_count, int &laddr_msb, int &laddr_lsb, int &payload_len, int &opcode, int &remote_offset_msb, int &remote_offset_lsb, int &r_key, int &send_small_payload0, int &send_small_payload1, int &send_small_payload2, int &send_small_payload3, int &immdt_data, int &sq_addr_lsb, int &sq_addr_msb);