//==============================================================================
// Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
// SPDX-License-Identifier: MIT
//
//==============================================================================

/** @file rdma_api.h
 *  @brief Header file of user-space RDMA APIs.
 */

#ifndef __RDMA_API_H__
#define __RDMA_API_H__

#include "auxiliary.h"
#include "reconic.h"
#include "reconic_reg.h"
#include "control_api.h"

/*! \def RQE_SIZE
    \brief Number of an RQ entry.

    Size RQ entry is aligned with 256B. Setting RQE_SIZE 512 indicates each RQE entry has 
    512*256 = 128KB
*/
#define RQE_SIZE 512

/*! \struct rdma_glb_csr_t
    \brief Structure used to store RDMA global control status registers.
*/
struct rdma_glb_csr_t {
  uint32_t data_buf_size;     /*!< data_buf_size data buffer size. 
                                   [15:0] Number of data buffers;
                                   [31:16 Data buffer size in bytes. */
  uint64_t data_buf_baseaddr; /*!< data_buf_baseaddr base address of a data buffer. */

  uint16_t ipkt_err_stat_q_size; /*!< ipkt_err_stat_q_size Incoming packet 
                                      error status queue size. 
                                      [15:0] Number of incoming error packet status
                                             queue entries;
                                      [31:16 Reserved. */
  uint64_t ipkt_err_stat_q_baseaddr; /*!< ipkt_err_stat_q_baseaddr Base address of 
                                          incoming packet error status queue. Used to
                                          store fatal code of an incoming error packet. */
  uint64_t err_buf_baseaddr;  /*!< err_buf_baseaddr base address of an error buffer. */
  uint32_t err_buf_size;      /*!< err_buf_size error buffer size. 
                                   [15:0] Number of error buffers;
                                   [31:16 Size of each error buffer in bytes. */
  uint64_t resp_err_pkt_buf_baseaddr; /*!< resp_err_pkt_buf_baseaddr base address of a response error packet buffer. */
  uint64_t resp_err_pkt_buf_size; /*!< resp_err_pkt_buf_size response error packet buffer size. */
  uint32_t interrupt_enable; /*!< interrupt_enable interrupt configuration. */
  struct mac_addr_t src_mac; /*!< src_mac source MAC address. */
  uint32_t src_ip;           /*!< src_ip source IP address. */
  uint16_t udp_sport;        /*!< udp_sport source UDP port. */
  uint8_t  num_qp_enabled;   /*!< num_qp_enabled Number of RDMA QP enabled. */
  uint32_t xrnic_conf;     /*!< xrnic_config ERNIC global configuration. */
  uint32_t xrnic_advanced_conf; /*!< xrnic_advanced_conf ERNIC advanced global configuration. */
};

/*! \struct rdma_dev_t
    \brief RDMA device structure.
*/
struct rdma_dev_t {
  struct rn_dev_t* rn_dev; /*!< rn_dev a pointer to the RecoNIC device. */
  struct rdma_glb_csr_t* glb_csr; /*!< glb_csr a pointer to RDMA global control status register structure. */
  struct rdma_qp_t** qps_ptr; /*!< qps_ptr a pointer to RDMA queue pairs. */
  uint32_t* axil_ctl; /*!< axil_ctl a pointer to PCIe register control interface. */
  uint32_t num_qp;    /*!< num_qp number of queue pair enabled. */
  struct win_size_t* winSize;    /*!< Window size mask for PCIe BDF address conversion. */
};

/*! \struct rdma_pd_t
    \brief Structure used to an RDMA Protection Domain entry.
*/
struct rdma_pd_t {
  uint32_t pd_num; /*!< pd_num 24-bit protection domain number. */
  uint32_t virtual_addr_lsb; /*!< virtual_addr_lsb virtual address (LSB) of the allocated buffer. */
  uint32_t virtual_addr_msb; /*!< virtual_addr_msb virtual address (MSB) of the allocated buffer. */
  uint32_t dma_addr_lsb; /*!< dma_addr_lsb physical address (LSB) of the allocated buffer. */
  uint32_t dma_addr_msb; /*!< dma_addr_msb physical address (MSB) of the allocated buffer. */
  // {24-bit pd_num, 8-bit r_key}
  uint32_t r_key; /*!< r_key 8-bit security key used in RDMA packets. */
  uint32_t buffer_size_lsb; /*!< buffer_size_lsb size (LSB) of the allocated buffer. */
  uint16_t buffer_size_msb; /*!< buffer_size_msb size (MSB) of the allocated buffer. */
  uint16_t pd_access_type; /*!< pd_access_type Buffer access type. 
                                4-bit pd_access_type:
                                -- 4'b0000: READ Only
                                -- 4'b0001: Write Only
                                -- 4'b0010: Read and Write
                                -- Other values: Not supported */
  struct rdma_buff_t* mr_buffer; /*!< mr_buffer a pointer to the allocated buffer. */
};

/*! \struct rdma_qp_t
    \brief RDMA queue pair structure.
*/
struct rdma_qp_t {
  struct rdma_dev_t* rdma_dev; /*!< rdma_dev An RDMA device. */
  uint32_t qpid;               /*!< qpid A queue pair ID. */
  struct rdma_buff_t* sq; /*!< sq a pointer to a send queue buffer. */
  uint32_t sq_psn;        /*!< sq_psn Packet sequence number for a sq request. */
  int sq_pidb;            /*!< sq_pidb SQ producer index doorbell. */
  int sq_cidb;            /*!< sq_cidb SQ consumer index doorbell. */

  struct rdma_buff_t* cq; /*!< cq a pointer to a completion queue buffer. */
  uint64_t cq_cidb_addr;  /*!< cq_cidb_addr completion queue consumer index doorbell address. */
  int cq_cidb;            /*!< cq_cidb completion queue consumer index doorbell. */

  // Receive queue and its doorbell
  struct rdma_buff_t* rq; /*!< rq a pointer to a receive queue buffer. */
  uint64_t rq_cidb_addr;  /*!< rq_cidb_addr receive queue consumer index doorbell address. */
  int rq_cidb;            /*!< rq_cidb receive queue consumer index doorbell. */
  int rq_pidb;            /*!< rq_cidb receive queue producer index doorbell. */
  uint32_t pd_num;        /*!< pd_num protection domain number associated. */
  struct rdma_pd_t* pd_entry; /*!< pd_entry protection domain entry associated. */
  uint32_t dst_qpid; /*!< dst_qpid destination queue pair ID. */
  uint32_t qdepth;   /*!< qdepth Queue pair depth. */
  uint32_t last_rq_psn; /*!< last_rq_psn Last RQ request PSN associated. */
  struct mac_addr_t* dst_mac; /*!< dst_mac destination MAC address. */
  uint32_t dst_ip; /*!< dst_ip destination IP address. */
};

/*! \struct rdma_wqe_t
    \brief RDMA Work Queue Element structure.
*/
struct rdma_wqe_t {
  uint16_t wrid;       /*!< wrid work request ID. */
  uint16_t reserved;   /*!< reserved reserved. */
  uint32_t laddr_low;  /*!< laddr_low local payload buffer adress (LSB). */
  uint32_t laddr_high; /*!< laddr_high local payload buffer adress (MSB). */
  uint32_t length;     /*!< length payload size for the transfer. */
  uint32_t opcode;     /*!< opcode 8-bit Opcode, only opcode[7:0] is valid, 
                            the rest opcode[31:8] should be set to 0. */
  uint32_t remote_offset_low;   /*!< remote_offset_low remote memory address offset (LSB). */
  uint32_t remote_offset_high;  /*!< remote_offset_low remote memory address offset (MSB). */
  uint32_t r_key;               /*!< r_key RDMA security key. */
  uint32_t send_small_payload0; /*!< send_small_payload0 small payload 0 for RDMA send. */
  uint32_t send_small_payload1; /*!< send_small_payload1 small payload 1 for RDMA send. */
  uint32_t send_small_payload2; /*!< send_small_payload2 small payload 2 for RDMA send. */
  uint32_t send_small_payload3; /*!< send_small_payload3 small payload 3 for RDMA send. */
  uint32_t immdt_data;          /*!< immdt_data immediate payload for RDMA packets. */
  uint32_t reserved0;           /*!< reserved0 reserved. */
  uint32_t reserved1;           /*!< reserved1 reserved. */
  uint32_t reserved2;           /*!< reserved2 reserved. */

};

/** @brief Create an RDMA device.
 *  @param rn_dev A pointer to the RecoNIC device.
 *  @return a pointer to the RDMA deivce created.
 */
struct rdma_dev_t* create_rdma_dev(struct rn_dev_t* rn_dev);

/** @brief Configure an RDMA device.
 *  @param rdma_dev a pointer to the RDMA deivce created.
 *  @param local_mac local MAC address.
 *  @param local_ip  local IP address.
 *  @param udp_sport UDP source port.
 *  @param num_data_buf Number of data buffers.
 *  @param per_data_buf_size size of each data buffer in bytes
 *  @param data_buf_baseaddr base address of a data buffer used to store all outgoing
 *                           RDMA write data until it is acknowledged by the remote host.
 *                           In the event of retransmission, the retried data is pulled
 *                           from these buffers
 *  @param ipkt_err_stat_q_size Incoming packet error status queue size (16-bit).
 *  @param ipkt_err_stat_q_baseaddr Base address of incoming packet error status queue. 
 *                                  Used to store fatal code of an incoming error packet.
 *  @param num_err_buf Number of error buffers.
 *  @param per_err_buf_size size of each error buffer in bytes
 *  @param err_buf_baseaddr base address of error buffer. Error packets will be written to
 *                          the error buffer.
 *  @param resp_err_pkt_buf_size used to save all error response pkt size during retry.
 *  @param resp_err_pkt_buf_baseaddr used to save all error response packet msb base address.
 *                                   The retried addresses are pulled from these buffers
 *  @return void.
 */
void open_rdma_dev(struct rdma_dev_t* rdma_dev, struct mac_addr_t local_mac, uint32_t local_ip, 
                   uint32_t udp_sport, uint16_t num_data_buf, uint16_t per_data_buf_size, 
                   uint64_t data_buf_baseaddr, uint16_t ipkt_err_stat_q_size, 
                   uint64_t ipkt_err_stat_q_baseaddr, uint16_t num_err_buf, 
                   uint16_t per_err_buf_size, uint64_t err_buf_baseaddr, 
                   uint64_t resp_err_pkt_buf_size, uint64_t resp_err_pkt_buf_baseaddr);

/** @brief Configure RDMA global control status registers.
 *  @param rdma_dev A pointer to the RDMA device.
 *  @return void.
 */
void config_rdma_global_csr (struct rdma_dev_t* rdma_dev);

/** @brief Allocate an RDMA protection domain entry.
 *  @param rdma_dev A pointer to the RDMA device.
 *  @param pd_num protection domain number.
 *  @return a pointer to the RDMA protection domain entry allocated.
 */
struct rdma_pd_t* allocate_rdma_pd(struct rdma_dev_t* rdma_dev, uint32_t pd_num);

/** @brief Register a memory region in the RDMA engine.
 *  @param rdma_dev A pointer to the RDMA device.
 *  @param rdma_pd A pointer to the RDMA protection domain entry.
 *  @param r_key RDMA security key or remote tag.
 *  @param rdma_buf the RDMA buffer to be registered.
 *  @return void.
 */
void rdma_register_memory_region(struct rdma_dev_t* rdma_dev, struct rdma_pd_t* rdma_pd, 
                                 uint32_t r_key, struct rdma_buff_t* rdma_buf);

/** @brief Allocate a host-side buffer.
 *  @param num_hugepages Number of hugepages requested.
 *  @return a pointer to an RDMA buffer allocated.
 */
struct rdma_buff_t* allocate_hugepages_buffer(uint32_t num_hugepages);

/** @brief Configure last RQ packet sequence number.
 *  @param rdma_dev A pointer to the RDMA device.
 *  @param qpid the corresponding QP ID.
 *  @param last_rq_psn the last RQ packet sequence number at the local side.
 *  @return void.
 */
void config_last_rq_psn(struct rdma_dev_t* rdma_dev, uint32_t qpid, uint32_t last_rq_psn);

/** @brief Configure SQ packet sequence number.
 *  @param rdma_dev A pointer to the RDMA device.
 *  @param qpid the corresponding QP ID.
 *  @param sq_psn the SQ packet sequence number at the local side.
 *  @return void.
 */
void config_sq_psn(struct rdma_dev_t* rdma_dev, uint32_t qpid, uint32_t sq_psn);

/** @brief Allocate an RDMA queue pair.
 *  @param rdma_dev A pointer to the RDMA device.
 *  @param qpid A QP ID.
 *  @param dst_qpid A destination QP ID.
 *  @param pd_entry Pointer to a protection domain entry.
 *  @param cq_cidb_addr Base address of the CQ consumer index doorbell.
 *  @param rq_cidb_addr Base address of the RQ consumer index doorbell.
 *  @param qdepth Queue depth used to allocate SQ, CQ and RQ. Each WQE has 64B,
 *                each CQE has 4B and each RQE has 256B. 
 *                Total size of SQ is calculated by num_qp * depth * WQE
 *                Total size of CQ is calculated by num_qp * depth * CQE
 *                Total size of RQ is calculated by num_qp * depth * RQE
 *  @param buf_location Location to allocate a buffer: "host_mem" or "dev_mem".
 *  @param dst_mac Destination MAC address.
 *  @param dst_ip Destination IP address.
 *  @param partion_key Partion key.
 *  @param r_key RDMA security key or remote tag.
 *  @return a pointer to the allocated RDMA queue pair.
 */
struct rdma_qp_t* allocate_rdma_qp(struct rdma_dev_t* rdma_dev,
                                   uint32_t qpid,
                                   uint32_t dst_qpid,
                                   struct rdma_pd_t* pd_entry,
                                   uint64_t cq_cidb_addr,
                                   uint64_t rq_cidb_addr,
                                   uint32_t qdepth,
                                   char*    buf_location,
                                   struct mac_addr_t* dst_mac,
                                   uint32_t dst_ip,
                                   uint32_t partion_key,
                                   uint32_t r_key);

/** @brief Create an RDMA work queue element.
 *  @param rdma_dev A pointer to the RDMA device.
 *  @param qpid A QP ID.
 *  @param wrid A work request ID.
 *  @param wqe_idx WQE index.
 *  @param laddr Physical base address for the payload to be exchanged.
 *  @param length Payload size to be exchanged.
 *  @param qdepth Queue depth used to allocate RQ.
 *  @param dst_mac Destination MAC address.
 *  @param dst_ip Destination IP address.
 *  @param partion_key Partion key.
 *  @return a pointer to the allocated RDMA queue pair.
 */
void create_a_wqe(struct rdma_dev_t* rdma_dev,
                  uint32_t qpid,
                  uint16_t wrid,
                  uint32_t wqe_idx,
                  uint64_t laddr,
                  uint32_t length,
                  uint32_t opcode,
                  uint64_t remote_offset,
                  uint32_t r_key,
                  uint32_t send_small_payload0,
                  uint32_t send_small_payload1,
                  uint32_t send_small_payload2,
                  uint32_t send_small_payload3,
                  uint32_t immdt_data);

/** @brief Poll CQ consumer index doorbell to check whether RDMA read/write is completed 
 *         and get its value.
 *  @param rdma_dev A pointer to the RDMA device.
 *  @param qpid The target queue pair ID.
 *  @param sq_cidb value of SQ consumer index doorbell.
 *  @return value of RDMA CQ consumer index doorbel register.
 */
int poll_cq_cidb(struct rdma_dev_t* rdma_dev, uint32_t qpid, int sq_cidb);

/** @brief Update RDMA RQ consumer index doorbell register.
 *  @param rdma_dev A pointer to the RDMA device.
 *  @param qp a pointer to a queue pair.
 *  @param db_val doorbell value to be programmed.
 *  @return void.
 */
void write_rq_cidb(struct rdma_dev_t* rdma_dev, struct rdma_qp_t* qp, uint32_t db_val);

/** @brief Poll RQ producer index doorbell register and get its value.
 *  @param rdma_dev A pointer to the RDMA device.
 *  @param qpid The target QP ID.
 *  @return value of RQ producer index doorbell register of the the qpid-th QP.
 */
int poll_rq_pidb(struct rdma_dev_t* rdma_dev, uint32_t qpid);

/** @brief Post an RDMA operation.
 *  @param rdma_dev A pointer to the RDMA device.
 *  @param qpid The target QP ID.
 *  @return Success (0) or Failure (-1).
 */
int rdma_post_send(struct rdma_dev_t* rdma_dev, uint32_t qpid);

/** @brief Post a batch of RDMA operations.
 *  @param rdma_dev A pointer to the RDMA device.
 *  @param qpid The target QP ID.
 *  @param batch_size batch size.
 *  @return Success (0) or Failure (-1).
 */
int rdma_post_batch_send(struct rdma_dev_t* rdma_dev, uint32_t qpid, uint32_t batch_size);

/** @brief Post an RDMA receive request.
 *  @param rdma_dev A pointer to the RDMA device.
 *  @param qp a pointer to a queue pair.
 *  @return void.
 */
void* rdma_post_receive(struct rdma_dev_t* rdma_dev, struct rdma_qp_t* qp);

/** @brief Release RQE consumed by updating RQ consumer index doorbell.
 *  @param rdma_dev A pointer to the RDMA device.
 *  @param qp a pointer to a queue pair.
 *  @return Number of RQ requests pending. '0' means all RQ requests have been served.
 */
uint8_t rdma_release_rq_consumed(struct rdma_dev_t* rdma_dev, struct rdma_qp_t* qp);

/** @brief Reset RDMA device when encountering fatal error.
 *  @param rdma_dev A pointer to the RDMA device.
 *  @param qpid the QP ID that has the fatal issues.
 *  @return void.
 */
void rdma_qp_fatal_recovery(struct rdma_dev_t* rdma_dev, uint32_t qpid);

/** @brief Destroy the RDMA protection domain entry generated.
 *  @param pd A pointer to the RDMA protection domain.
 *  @return void.
 */
void destroy_rdma_pd_entry(struct rdma_pd_t* pd);

/** @brief Destroy the RDMA queue pair generated.
 *  @param qp a pointer to a queue pair.
 *  @return Success (0).
 */
int destroy_rdma_qp(struct rdma_qp_t* qp);

/** @brief Destroy the RDMA device.
 *  @param rdma_dev A pointer to the RDMA device.
 *  @return Success (0).
 */
int destroy_rdma_dev(struct rdma_dev_t* rdma_dev);

/** @brief Destroy a RecoNIC device.
 *  @param rn_dev A pointer to the RecoNIC device.
 *  @return Success (0) or Failure (-1).
 */
int destroy_rn_dev(struct rn_dev_t* rn_dev);

/** @brief Print RDMA registers for debug purpose.
 *  @param rdma_dev A pointer to the RDMA device.
 *  @param is_sender a flag to indicate a sender or receiver.
 *  @param qpid the target QP ID.
 *  @return void.
 */
void dump_registers(struct rdma_dev_t* rdma_dev, uint8_t is_sender, uint32_t qpid);

#endif /* __RDMA_API_H__ */