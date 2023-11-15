//==============================================================================
// Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
// SPDX-License-Identifier: MIT
//
//==============================================================================

/** @file reconic.h
 *  @brief The header file of the RecoNIC user-space API library.
 *
 */

#ifndef __RECONIC_H__
#define __RECONIC_H__

#include "auxiliary.h"
#include "reconic_reg.h"
#include "memory_api.h"
#include "control_api.h"

/*! \var device
    \brief A global string used to represent a character device for device memory access
*/
extern char* device;

/*! \var fpga_fd
    \brief A global variable used to represent a file descriptor of a character device
          for memory access.
*/
extern int fpga_fd;

/*! \def HOST_MEM
    \brief A macro string to represet host memory
*/
#define HOST_MEM "host_mem"

/*! \def DEVICE_MEM
    \brief A macro string to represet device memory
*/
#define DEVICE_MEM "dev_mem"

/*! \def DEVICE_MEM_SIZE
    \brief A macro string to indicate device memory size in bytes.

    The current implement leverages only one 4GB DDR4 memory on U250. Maximum number of 
    DDR4 allowed on Alveo U250 is 4.
*/
#define DEVICE_MEM_SIZE 4294967296

/*! \def HARDWARE_PAGE_SIZE
    \brief HARDWARE_PAGE_SIZE is used to determine payload size per AXI4-MM transaction on hardware.

    HARDWARE_PAGE_SIZE = 4096 (4KB)
*/
#define HARDWARE_PAGE_SIZE 4096

/*! \def HARDWARE_PAGE_SIZE_ALIGNMENT_MASK
    \brief HARDWARE_PAGE_SIZE_ALIGNMENT_MASK is used to get address aligned with HARDWARE_PAGE_SIZE.

    HARDWARE_PAGE_SIZE_ALIGNMENT_MASK = 0xfffffffffffff000
*/
#define HARDWARE_PAGE_SIZE_ALIGNMENT_MASK 0xfffffffffffff000

/*! \def HARDWARE_PAGE_SIZE_ADDRESS_MASK
    \brief HARDWARE_PAGE_SIZE_ADDRESS_MASK is used to get address within HARDWARE_PAGE_SIZE.

    HARDWARE_PAGE_SIZE_ADDRESS_MASK = 0x0000000000000fff
*/
#define HARDWARE_PAGE_SIZE_ADDRESS_MASK 0x0000000000000fff

/*! \def PAGE_SHIFT
    \brief PAGE_SHIFT is used to determine the page size.

    PAGE_SIZE = (1 << PAGE_SHIFT)
*/
#define PAGE_SHIFT      12  // 4KB

/*! \def PAGEMAP_LENGTH
    \brief Length of a PAGEMAP entry.

    Each pagemap entry has 64 bits, which is 8 bytes
*/
#define PAGEMAP_LENGTH  8

// 2MB for each huge page
/*! \def HUGE_PAGE_SHIFT
    \brief It indicates 2MB for each hugepage.
*/
#define HUGE_PAGE_SHIFT 21

/*! \def DEVICE_MEM_OFFSET
    \brief Device memory address offset.
*/
#define DEVICE_MEM_OFFSET 0xa350000000000000

/*! \def DEVICE_MEM_MASK
    \brief Device memory address mask.
*/
#define DEVICE_MEM_MASK 0xfff0000000000000

/*! \struct mac_addr_t
    \brief MAC address type.
*/
struct mac_addr_t {
  uint32_t mac_lsb; /*!< mac_lsb LSB of a MAC address. */
  uint32_t mac_msb; /*!< mac_msb MSB of a MAC address. */
};

/*! \struct win_size_t
    \brief Window size mask for PCIe BDF address conversion.
*/
struct win_size_t {
  uint32_t win_size_lsb; /*!< Window size mask LSB. */
  uint32_t win_size_msb; /*!< Window size mask MSB. */
};

/*! \struct rdma_buff_t
    \brief RDMA buffer structure.
*/
struct rdma_buff_t {
  void* buffer;      /*!< buffer virtual address of an RDMA buffer. */
  uint64_t dma_addr; /*!< physical address of an RDMA buffer. */
  uint32_t buf_size; /*!< buffer size. */
};

/*! \struct rn_dev_t
    \brief A RecoNIC device structure.
*/
struct rn_dev_t {
  uint32_t* axil_ctl;           /*!< axil_ctl Base address for PCIe register control. */
  uint32_t  axil_map_size;      /*!< axil_map_size Mapping size for PCIe register control. */
  struct rdma_buff_t* base_buf; /*!< base_buf Pre-allocated host buffer. */
  void* rdma_dev;               /*!< rdma_dev A RDMA device. 
                                     type: struct rdma_dev_t* */
  uint64_t buffer_offset;       /*!< buffer_offset offset of a free pre-allocated buffer. */
  uint64_t dev_buffer_offset;   /*!< dev_buffer_offset offset of a free device buffer. */
  unsigned char num_qp;         /*!< num_qp Number of RDMA queue pairs required. */
  struct win_size_t* winSize;   /*!< Window size mask for PCIe BDF address conversion. */
};

/** @brief Convert IP address from string to unsigned int.
 *  @param ip_addr IP address string.
 *  @return IP address in unsigned int type.
 */
uint32_t convert_ip_addr_to_uint(char* ip_addr);

/** @brief Convert MAC address string with colons to mac_addr_t type.
 *  @param mac_addr_char MAC address string with colons.
 *  @return MAC address in mac_addr_t type.
 */
struct mac_addr_t convert_mac_addr_str_to_uint(char* mac_addr_str);

/** @brief Convert MAC address string without colons to mac_addr_t type.
 *  @param mac_addr_char MAC address string without colons (e.g., ifreq.ifr_hwaddr.sa_data).
 *  @return MAC address in mac_addr_t type.
 */
struct mac_addr_t convert_mac_addr_to_uint(unsigned char* mac_addr_char);

/** @brief Get MAC address in mac_addr_t according to IP address string given.
 *  @param sockfd a socket descriptor.
 *  @param ip_str IP address string.
 *  @return MAC address in mac_addr_t type.
 */
struct mac_addr_t get_mac_addr_from_str_ip(int sockfd, char* ip_str);

/** @brief Check whether a given address is an address in device memory or host memory.
 *  @param address a given address.
 *  @return 1 - device memory address; 0 - host memory address.
 */
uint8_t is_device_address(uint64_t address);

/** @brief Get page frame number of a virtual address.
 *  @param addr a virtual address.
 *  @return Page frame number.
 */
unsigned long get_page_frame_number_of_address(void *addr);

/** @brief Get physical address of a virtual address.
 *  @param buffer virtual address of a buffer.
 *  @return Physical address of a buffer.
 */
uint64_t get_buffer_paddr(void *buffer);

/** @brief Get AXI BAR mapping window mask for calculating BDF address mask.
 *  @return Window mask.
 */
uint64_t get_win_size();

/** @brief Configure the BDF table of the PCIe slave bridge for address conversion.
 *  @param rn_dev A RecoNIC device.
 *  @param high_addr High 32-bit physical address of an allocated host buffer.
 *  @param low_addr Low 32-bit physical address of an allocated host buffer.
 *  @return void.
 */
void config_rn_dev_axib_bdf(struct rn_dev_t* rn_dev, uint32_t high_addr, uint32_t low_addr);

/** @brief Allocate a buffer for RDMA communication.
 *  @param rn_dev A pointer to the RecoNIC device.
 *  @param buf_size buffer size.
 *  @param buf_location buffer location, either host memory ("host_mem") 
 *                      or device memory ("dev_mem").
 *  @return a pointer to the RDMA buffer allocated.
 */
struct rdma_buff_t* allocate_rdma_buffer(struct rn_dev_t* rn_dev, uint64_t buf_size, char* buf_location);

/** @brief Create a RecoNIC device.
 *  @param pcie_resource Path to resource2 of a PCIe device.
 *  @param rn_scr File descriptor of the PCIe device resource2 for FPGA register access.
 *  @param num_hugepages_request Pre-allocate a hugepage buffer with the size of 
 *                               num_hugepages_request * per_hugepage_size
 *  @param num_qp Number of RDMA queue pairs required.
 *  @return A RecoNIC device pointer.
 */
struct rn_dev_t* create_rn_dev(char* pcie_resource, int* pcie_resource_fd, uint32_t num_hugepages_request, uint32_t num_qp);

#endif /* __RECONIC_H__ */
