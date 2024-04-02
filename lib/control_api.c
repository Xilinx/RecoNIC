//==============================================================================
// Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
// SPDX-License-Identifier: MIT
//
//==============================================================================

/** @file control_api.c
 *  @brief User-space control driver
 *
 *  Control driver consists of register control and compute control APIs.
 *  Register control APIs are used to configure registers in FPGA.
 *  Compute control APIs are used to interact with accelerators in FPGA.
 */

#include "control_api.h"

void write32_data(uint32_t* pcie_axil_base, off_t offset, uint32_t value) {
  uint32_t* config_addr;

  config_addr = (uint32_t* ) ((uintptr_t) pcie_axil_base + offset);
  *(config_addr) = value;  
}

uint32_t read32_data(uint32_t* pcie_axil_base, off_t offset) {
  uint32_t value;
  uint32_t* config_addr;

  config_addr = (uint32_t* ) ((uintptr_t) pcie_axil_base + offset);
  value = *((uint32_t* ) config_addr);
  
  return value;
}

void gen_ctl_cmd(ctl_cmd_t* ctl_cmd, uint32_t a_baseaddr, uint32_t b_baseaddr, \
									uint32_t c_baseaddr, uint32_t ctl_cmd_size, uint16_t a_row, \
									uint16_t a_col, uint16_t b_col, uint16_t work_id) {
	ctl_cmd->ctl_cmd_size = ctl_cmd_size;
	ctl_cmd->a_baseaddr = a_baseaddr;
	ctl_cmd->b_baseaddr = b_baseaddr;
	ctl_cmd->c_baseaddr = c_baseaddr;
	ctl_cmd->a_row = a_row;
	ctl_cmd->a_col = a_col;
	ctl_cmd->b_col = b_col;
	ctl_cmd->work_id = work_id;
}

void issue_ctl_cmd(void* axil_base, uint32_t offset, ctl_cmd_t* ctl_cmd) {
	uint32_t ctl_cmd_element;
	write32_data((uint32_t*) axil_base, offset, ctl_cmd->ctl_cmd_size);
	write32_data((uint32_t*) axil_base, offset, ctl_cmd->a_baseaddr);
	write32_data((uint32_t*) axil_base, offset, ctl_cmd->b_baseaddr);
	write32_data((uint32_t*) axil_base, offset, ctl_cmd->c_baseaddr);
	ctl_cmd_element = ((ctl_cmd->a_row << 16) & 0xffff0000) | (ctl_cmd->a_col & 0x0000ffff);
	write32_data((uint32_t*) axil_base, offset, ctl_cmd_element);
	ctl_cmd_element = ((ctl_cmd->b_col << 16) & 0xffff0000) | (ctl_cmd->work_id & 0x0000ffff);
	write32_data((uint32_t*) axil_base, offset, ctl_cmd_element);
}

void gen_init_wqe_cmd(init_wqe_cmd* init_wqe_cmd, uint32_t cmd_size, uint32_t init_sq_pidb_cnt, uint32_t init_cq_db_cnt, uint32_t sq_pidb_addr, uint16_t wrid,uint16_t opcode, uint32_t wqe_count, uint64_t laddr, uint32_t payload_len, uint64_t remote_offset, uint32_t r_key, uint32_t send_small_payload0, uint32_t send_small_payload1, uint32_t send_small_payload2, uint32_t send_small_payload3, uint32_t immdt_data, uint32_t sq_addr_msb, uint32_t sq_addr_lsb) {
	init_wqe_cmd->cmd_size = cmd_size;
	init_wqe_cmd->init_sq_pidb_cnt = init_sq_pidb_cnt;
	init_wqe_cmd->init_cq_db_cnt = init_cq_db_cnt;
	init_wqe_cmd->sq_pidb_addr = sq_pidb_addr;
	init_wqe_cmd->wrid = wrid;
	init_wqe_cmd->opcode = opcode;
	init_wqe_cmd->wqe_count = wqe_count;
	init_wqe_cmd->laddr_lsb = (laddr & 0x00000000ffffffff);
	init_wqe_cmd->laddr_msb = ((laddr >> 32) & 0x00000000ffffffff);
	init_wqe_cmd->payload_len = payload_len;
	init_wqe_cmd->remote_offset_lsb = (remote_offset & 0x00000000ffffffff);
	init_wqe_cmd->remote_offset_msb = ((remote_offset >> 32) & 0x00000000ffffffff);
	init_wqe_cmd->r_key = r_key;
	init_wqe_cmd->send_small_payload0 = send_small_payload0;
	init_wqe_cmd->send_small_payload1 = send_small_payload1;
	init_wqe_cmd->send_small_payload2 = send_small_payload2;
	init_wqe_cmd->send_small_payload3 = send_small_payload3;
	init_wqe_cmd->immdt_data = immdt_data;
	init_wqe_cmd->sq_addr_msb = sq_addr_msb;
	init_wqe_cmd->sq_addr_lsb = sq_addr_lsb;
}

void issue_init_wqe_cmd(void* axil_base, uint32_t offset, init_wqe_cmd* init_wqe_cmd) {
	uint32_t cmd_element;
	write32_data((uint32_t*) axil_base, offset, init_wqe_cmd->cmd_size);
	write32_data((uint32_t*) axil_base, offset, init_wqe_cmd->init_sq_pidb_cnt);
	write32_data((uint32_t*) axil_base, offset, init_wqe_cmd->init_cq_db_cnt);
	write32_data((uint32_t*) axil_base, offset, init_wqe_cmd->sq_pidb_addr);
	cmd_element = ((init_wqe_cmd->wrid << 16) & 0xffff0000) | (init_wqe_cmd->opcode & 0x0000ffff);
	write32_data((uint32_t*) axil_base, offset, cmd_element);
	write32_data((uint32_t*) axil_base, offset, init_wqe_cmd->wqe_count);
	write32_data((uint32_t*) axil_base, offset, init_wqe_cmd->laddr_msb);
	write32_data((uint32_t*) axil_base, offset, init_wqe_cmd->laddr_lsb);
	write32_data((uint32_t*) axil_base, offset, init_wqe_cmd->payload_len);
	write32_data((uint32_t*) axil_base, offset, init_wqe_cmd->remote_offset_msb);
	write32_data((uint32_t*) axil_base, offset, init_wqe_cmd->remote_offset_lsb);
	write32_data((uint32_t*) axil_base, offset, init_wqe_cmd->r_key);
	write32_data((uint32_t*) axil_base, offset, init_wqe_cmd->send_small_payload0);
	write32_data((uint32_t*) axil_base, offset, init_wqe_cmd->send_small_payload1);
	write32_data((uint32_t*) axil_base, offset, init_wqe_cmd->send_small_payload2);
	write32_data((uint32_t*) axil_base, offset, init_wqe_cmd->send_small_payload3);
	write32_data((uint32_t*) axil_base, offset, init_wqe_cmd->immdt_data);
	write32_data((uint32_t*) axil_base, offset, init_wqe_cmd->sq_addr_msb);
	write32_data((uint32_t*) axil_base, offset, init_wqe_cmd->sq_addr_lsb);
}

uint32_t wait_compute(void* axil_base, uint32_t offset) {
  uint32_t compute_done = 0;
	while(compute_done == 0) {
			compute_done = read32_data((uint32_t*) axil_base, offset);
	}
  return compute_done;
}

uint32_t wait_finish_rdma(void* axil_base, uint32_t offset) {
  uint32_t compute_done = 0;
	while(compute_done == 0) {
			compute_done = read32_data((uint32_t*) axil_base, offset);
	}
  return compute_done;
}