//==============================================================================
// Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
// SPDX-License-Identifier: MIT
//
//==============================================================================

/** @file control_api.h
 *  @brief User-space control driver
 *
 *  Control driver consists of register control and compute control APIs.
 *  Register control APIs are used to configure registers in FPGA.
 *  Compute control APIs are used to interact with accelerators in FPGA.
 */

#ifndef __CONTROL_API_H__
#define __CONTROL_API_H__

#include "auxiliary.h"
#include "reconic_reg.h"

/*! \struct ctl_cmd_t
    \brief Compute control command structure.
*/
typedef struct {
	uint32_t ctl_cmd_size; /*!< ctl_cmd_size size of a compute control command. */
	uint32_t a_baseaddr;   /*!< a_baseaddr baseaddress of array A. */
	uint32_t b_baseaddr;   /*!< b_baseaddr baseaddress of array B. */
	uint32_t c_baseaddr;   /*!< c_baseaddr baseaddress of array C. */
	uint16_t a_row;        /*!< a_row row size of array A. */
	uint16_t a_col;        /*!< a_col column size of array A. */
	uint16_t b_col;        /*!< b_col column size of array B. */
	uint16_t work_id;      /*!< work_id a work/job ID. */
} ctl_cmd_t;

/** @brief Register control API: A function used to write data to FPGA registers.
 *  @param pcie_axil_base AXIL base address of a PCIe device.
 *  @param offset Register offset.
 *  @param value data to be configured in the register.
 *  @return void.
 */
void write32_data(uint32_t* pcie_axil_base, off_t offset, uint32_t value);

/** @brief Register control API: A function used to read data from FPGA registers.
 *  @param pcie_axil_base AXIL base address of a PCIe device.
 *  @param offset Register offset.
 *  @return the register value.
 */
uint32_t read32_data(uint32_t* pcie_axil_base, off_t offset);

/** @brief Compute control API: A function used to construct a compute control command.
 *  @param ctl_cmd A compute control command pointer.
 *  @param a_baseaddr baseaddress of array A.
 *  @param b_baseaddr baseaddress of array B.
 *  @param b_baseaddr baseaddress of array C.
 *  @param ctl_cmd_size size of a control command.
 *  @param a_row row size of array A.
 *  @param a_col column size of array A.
 *  @param b_col column size of array B.
 *  @param work_id a work/job ID.
 *  @return void.
 */
void gen_ctl_cmd(ctl_cmd_t* ctl_cmd, uint32_t a_baseaddr, uint32_t b_baseaddr, \
									uint32_t c_baseaddr, uint32_t ctl_cmd_size, uint16_t a_row, \
									uint16_t a_col, uint16_t b_col, uint16_t work_id);

/** @brief Compute control API: A function used to issue a compute control command to 
 *         FPGA accelerators.
 *  @param axil_base AXIL base address of a PCIe device.
 *  @param offset base address of a control FIFO associated to the target accelerator.
 *  @param ctl_cmd a control command pointer.
 *  @param b_baseaddr baseaddress of array C.
 *  @param ctl_cmd_size size of a control command.
 *  @param a_row row size of array A.
 *  @param a_col column size of array A.
 *  @param b_col column size of array B.
 *  @param work_id a work/job ID.
 *  @return void.
 */
void issue_ctl_cmd(void* axil_base, uint32_t offset, ctl_cmd_t* ctl_cmd);

/** @brief Compute control API: A function used to check whether a compute request has been
 *         served.
 *  @param axil_base AXIL base address of a PCIe device.
 *  @param offset address offset of a status FIFO associated to the target accelerator.
 *  @return the work ID.
 */
uint32_t wait_compute(void* axil_base, uint32_t offset);

#endif /* __CONTROL_API_H__ */