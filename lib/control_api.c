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

uint32_t wait_compute(void* axil_base, uint32_t offset) {
  uint32_t compute_done = 0;
	while(compute_done == 0) {
			compute_done = read32_data((uint32_t*) axil_base, offset);
	}
  return compute_done;
}