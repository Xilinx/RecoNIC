//==============================================================================
// Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
// SPDX-License-Identifier: MIT
//
//==============================================================================
`timescale 1ns/1ps

import rn_tb_pkg::*;

module rn_tb_top;

string traffic_filename          = "packets";
string table_filename            = "";
string rsp_table_filename        = "";
string golden_resp_filename      = "";
string get_req_feedback_filename = "";
string axi_read_info_filename    = "";
string axi_dev_mem_filename      = "rdma_dev_mem";
string axi_sys_mem_filename      = "rdma_sys_mem";
string rdma_combined_cfg_filename= "rdma_combined_config";
/*
string table_filename            = "table";
string rsp_table_filename        = "rsp_table";
string golden_resp_filename      = "responses_golden";
string get_req_feedback_filename = "get_req_feedback_golden";
string axi_read_info_filename    = "axi_read_info";
*/
longint num_pkts;
mbox_pkt_str_t gen_pkt_mbox;

logic axil_clk;
logic axil_rstn;
logic axis_clk;
logic axis_rstn;

// Metadata
logic [USER_META_DATA_WIDTH-1:0] user_metadata_out;
logic                            user_metadata_out_valid;

// RDMA AXI4-Lite register channel
logic        s_axil_rdma_awvalid;
logic [31:0] s_axil_rdma_awaddr;
logic        s_axil_rdma_awready;
logic        s_axil_rdma_wvalid;
logic [31:0] s_axil_rdma_wdata;
logic        s_axil_rdma_wready;
logic        s_axil_rdma_bvalid;
logic  [1:0] s_axil_rdma_bresp;
logic        s_axil_rdma_bready;
logic        s_axil_rdma_arvalid;
logic [31:0] s_axil_rdma_araddr;
logic        s_axil_rdma_arready;
logic        s_axil_rdma_rvalid;
logic [31:0] s_axil_rdma_rdata;
logic  [1:0] s_axil_rdma_rresp;
logic        s_axil_rdma_rready;

// RecoNIC AXI4-Lite register channel
logic        s_axil_rn_awvalid;
logic [31:0] s_axil_rn_awaddr;
logic        s_axil_rn_awready;
logic        s_axil_rn_wvalid;
logic [31:0] s_axil_rn_wdata;
logic        s_axil_rn_wready;
logic        s_axil_rn_bvalid;
logic  [1:0] s_axil_rn_bresp;
logic        s_axil_rn_bready;
logic        s_axil_rn_arvalid;
logic [31:0] s_axil_rn_araddr;
logic        s_axil_rn_arready;
logic        s_axil_rn_rvalid;
logic [31:0] s_axil_rn_rdata;
logic  [1:0] s_axil_rn_rresp;
logic        s_axil_rn_rready;

// Receive packets from CMAC RX path
logic         s_axis_cmac_rx_tvalid;
logic [511:0] s_axis_cmac_rx_tdata;
logic  [63:0] s_axis_cmac_rx_tkeep;
logic         s_axis_cmac_rx_tlast;
logic  [15:0] s_axis_cmac_rx_tuser_size;
logic         s_axis_cmac_rx_tready;

// Expose roce packets from CMAC RX path after packet classification, 
// for debug only
logic         m_axis_cmac_rx_roce_tvalid;
logic [511:0] m_axis_cmac_rx_roce_tdata;
logic  [63:0] m_axis_cmac_rx_roce_tkeep;
logic         m_axis_cmac_rx_roce_tlast;

// Send non-roce packets to QDMA rx path
logic         m_axis_qdma_c2h_tvalid;
logic [511:0] m_axis_qdma_c2h_tdata;
logic  [63:0] m_axis_qdma_c2h_tkeep;
logic         m_axis_qdma_c2h_tlast;
logic  [15:0] m_axis_qdma_c2h_tuser_size;
logic         m_axis_qdma_c2h_tready;

// Get non-roce packets from QDMA tx path
logic         s_axis_qdma_h2c_tvalid;
logic [511:0] s_axis_qdma_h2c_tdata;
logic  [63:0] s_axis_qdma_h2c_tkeep;
logic         s_axis_qdma_h2c_tlast;
logic  [15:0] s_axis_qdma_h2c_tuser_size;
logic         s_axis_qdma_h2c_tready;

// Send packets to CMAC tx path
logic         m_axis_cmac_tx_tvalid;
logic [511:0] m_axis_cmac_tx_tdata;
logic  [63:0] m_axis_cmac_tx_tkeep;
logic         m_axis_cmac_tx_tlast;
logic  [15:0] m_axis_cmac_tx_tuser_size;
logic         m_axis_cmac_tx_tready;

// Initialize device memory
logic   [3:0] m_axi_init_dev_awid;
logic  [63:0] m_axi_init_dev_awaddr;
logic   [7:0] m_axi_init_dev_awlen;
logic   [2:0] m_axi_init_dev_awsize;
logic   [1:0] m_axi_init_dev_awburst;
logic         m_axi_init_dev_awlock;
logic   [3:0] m_axi_init_dev_awcache;
logic   [2:0] m_axi_init_dev_awprot;
logic   [3:0] m_axi_init_dev_awqos;
logic   [3:0] m_axi_init_dev_awregion;
logic         m_axi_init_dev_awvalid;
logic         m_axi_init_dev_awready;
// AXI write data channel
logic [511:0] m_axi_init_dev_wdata;
logic  [63:0] m_axi_init_dev_wstrb;
logic         m_axi_init_dev_wlast;
logic         m_axi_init_dev_wvalid;
logic         m_axi_init_dev_wready;
// AXI write response channel
logic   [3:0] m_axi_init_dev_bid;
logic   [1:0] m_axi_init_dev_bresp;
logic         m_axi_init_dev_bvalid;
logic         m_axi_init_dev_bready;

// Read data from device memory for debug purpose
logic   [3:0] m_axi_veri_dev_arid;
logic  [63:0] m_axi_veri_dev_araddr;
logic   [7:0] m_axi_veri_dev_arlen;
logic   [2:0] m_axi_veri_dev_arsize;
logic   [1:0] m_axi_veri_dev_arburst;
logic         m_axi_veri_dev_arlock;
logic   [3:0] m_axi_veri_dev_arcache;
logic   [3:0] m_axi_veri_dev_arqos;
logic   [3:0] m_axi_veri_dev_arregion;
logic   [2:0] m_axi_veri_dev_arprot;
logic         m_axi_veri_dev_arvalid;
logic         m_axi_veri_dev_arready;
// AXI read data channel
logic   [3:0] m_axi_veri_dev_rid;
logic [511:0] m_axi_veri_dev_rdata;
logic   [1:0] m_axi_veri_dev_rresp;
logic         m_axi_veri_dev_rlast;
logic         m_axi_veri_dev_rvalid;
logic         m_axi_veri_dev_rready;

// Initialize system memory
logic   [3:0] m_axi_init_sys_awid;
logic  [63:0] m_axi_init_sys_awaddr;
logic   [7:0] m_axi_init_sys_awlen;
logic   [2:0] m_axi_init_sys_awsize;
logic   [1:0] m_axi_init_sys_awburst;
logic         m_axi_init_sys_awlock;
logic   [3:0] m_axi_init_sys_awcache;
logic   [2:0] m_axi_init_sys_awprot;
logic   [3:0] m_axi_init_sys_awqos;
logic   [3:0] m_axi_init_sys_awregion;
logic         m_axi_init_sys_awvalid;
logic         m_axi_init_sys_awready;
// AXI write data channel
logic [511:0] m_axi_init_sys_wdata;
logic  [63:0] m_axi_init_sys_wstrb;
logic         m_axi_init_sys_wlast;
logic         m_axi_init_sys_wvalid;
logic         m_axi_init_sys_wready;
// AXI write response channel
logic   [3:0] m_axi_init_sys_bid;
logic   [1:0] m_axi_init_sys_bresp;
logic         m_axi_init_sys_bvalid;
logic         m_axi_init_sys_bready;

// Read data from system memory for debug purpose
logic   [3:0] m_axi_veri_sys_arid;
logic  [63:0] m_axi_veri_sys_araddr;
logic   [7:0] m_axi_veri_sys_arlen;
logic   [2:0] m_axi_veri_sys_arsize;
logic   [1:0] m_axi_veri_sys_arburst;
logic         m_axi_veri_sys_arlock;
logic   [3:0] m_axi_veri_sys_arcache;
logic   [3:0] m_axi_veri_sys_arqos;
logic   [3:0] m_axi_veri_sys_arregion;
logic   [2:0] m_axi_veri_sys_arprot;
logic         m_axi_veri_sys_arvalid;
logic         m_axi_veri_sys_arready;
// AXI read data channel
logic   [3:0] m_axi_veri_sys_rid;
logic [511:0] m_axi_veri_sys_rdata;
logic   [1:0] m_axi_veri_sys_rresp;
logic         m_axi_veri_sys_rlast;
logic         m_axi_veri_sys_rvalid;
logic         m_axi_veri_sys_rready;

// RDMA AXI MM interface used to store payload from RDMA MAD, Send or Write operation
logic           axi_rdma_send_write_payload_awid;
logic  [63 : 0] axi_rdma_send_write_payload_awaddr;
logic  [31 : 0] axi_rdma_send_write_payload_awuser;
logic   [3 : 0] axi_rdma_send_write_payload_awqos;
logic   [7 : 0] axi_rdma_send_write_payload_awlen;
logic   [2 : 0] axi_rdma_send_write_payload_awsize;
logic   [1 : 0] axi_rdma_send_write_payload_awburst;
logic   [3 : 0] axi_rdma_send_write_payload_awcache;
logic   [2 : 0] axi_rdma_send_write_payload_awprot;
logic           axi_rdma_send_write_payload_awvalid;
logic           axi_rdma_send_write_payload_awready;
logic [511 : 0] axi_rdma_send_write_payload_wdata;
logic  [63 : 0] axi_rdma_send_write_payload_wstrb;
logic           axi_rdma_send_write_payload_wlast;
logic           axi_rdma_send_write_payload_wvalid;
logic           axi_rdma_send_write_payload_wready;
logic           axi_rdma_send_write_payload_awlock;
logic           axi_rdma_send_write_payload_bid;
logic   [1 : 0] axi_rdma_send_write_payload_bresp;
logic           axi_rdma_send_write_payload_bvalid;
logic           axi_rdma_send_write_payload_bready;
logic           axi_rdma_send_write_payload_arid;
logic  [63 : 0] axi_rdma_send_write_payload_araddr;
logic   [7 : 0] axi_rdma_send_write_payload_arlen;
logic   [2 : 0] axi_rdma_send_write_payload_arsize;
logic   [1 : 0] axi_rdma_send_write_payload_arburst;
logic   [3 : 0] axi_rdma_send_write_payload_arcache;
logic   [2 : 0] axi_rdma_send_write_payload_arprot;
logic           axi_rdma_send_write_payload_arvalid;
logic           axi_rdma_send_write_payload_arready;
logic           axi_rdma_send_write_payload_rid;
logic [511 : 0] axi_rdma_send_write_payload_rdata;
logic   [1 : 0] axi_rdma_send_write_payload_rresp;
logic           axi_rdma_send_write_payload_rlast;
logic           axi_rdma_send_write_payload_rvalid;
logic           axi_rdma_send_write_payload_rready;
logic           axi_rdma_send_write_payload_arlock;
logic     [3:0] axi_rdma_send_write_payload_arqos;

// RDMA AXI MM interface used to store payload from RDMA Read response operation
logic           axi_rdma_rsp_payload_awid;
logic  [63 : 0] axi_rdma_rsp_payload_awaddr;
logic   [3 : 0] axi_rdma_rsp_payload_awqos;
logic   [7 : 0] axi_rdma_rsp_payload_awlen;
logic   [2 : 0] axi_rdma_rsp_payload_awsize;
logic   [1 : 0] axi_rdma_rsp_payload_awburst;
logic   [3 : 0] axi_rdma_rsp_payload_awcache;
logic   [2 : 0] axi_rdma_rsp_payload_awprot;
logic           axi_rdma_rsp_payload_awvalid;
logic           axi_rdma_rsp_payload_awready;
logic [511 : 0] axi_rdma_rsp_payload_wdata;
logic  [63 : 0] axi_rdma_rsp_payload_wstrb;
logic           axi_rdma_rsp_payload_wlast;
logic           axi_rdma_rsp_payload_wvalid;
logic           axi_rdma_rsp_payload_wready;
logic           axi_rdma_rsp_payload_awlock;
logic           axi_rdma_rsp_payload_bid;
logic   [1 : 0] axi_rdma_rsp_payload_bresp;
logic           axi_rdma_rsp_payload_bvalid;
logic           axi_rdma_rsp_payload_bready;
logic           axi_rdma_rsp_payload_arid;
logic  [63 : 0] axi_rdma_rsp_payload_araddr;
logic   [7 : 0] axi_rdma_rsp_payload_arlen;
logic   [2 : 0] axi_rdma_rsp_payload_arsize;
logic   [1 : 0] axi_rdma_rsp_payload_arburst;
logic   [3 : 0] axi_rdma_rsp_payload_arcache;
logic   [2 : 0] axi_rdma_rsp_payload_arprot;
logic           axi_rdma_rsp_payload_arvalid;
logic           axi_rdma_rsp_payload_arready;
logic           axi_rdma_rsp_payload_rid;
logic [511 : 0] axi_rdma_rsp_payload_rdata;
logic   [1 : 0] axi_rdma_rsp_payload_rresp;
logic           axi_rdma_rsp_payload_rlast;
logic           axi_rdma_rsp_payload_rvalid;
logic           axi_rdma_rsp_payload_rready;
logic           axi_rdma_rsp_payload_arlock;
logic   [3 : 0] axi_rdma_rsp_payload_arqos;

// RDMA AXI MM interface used to get wqe from system memory
logic           axi_rdma_get_wqe_awid;
logic  [63 : 0] axi_rdma_get_wqe_awaddr;
logic   [3 : 0] axi_rdma_get_wqe_awqos;
logic   [7 : 0] axi_rdma_get_wqe_awlen;
logic   [2 : 0] axi_rdma_get_wqe_awsize;
logic   [1 : 0] axi_rdma_get_wqe_awburst;
logic   [3 : 0] axi_rdma_get_wqe_awcache;
logic   [2 : 0] axi_rdma_get_wqe_awprot;
logic           axi_rdma_get_wqe_awvalid;
logic           axi_rdma_get_wqe_awready;
logic [511 : 0] axi_rdma_get_wqe_wdata;
logic  [63 : 0] axi_rdma_get_wqe_wstrb;
logic           axi_rdma_get_wqe_wlast;
logic           axi_rdma_get_wqe_wvalid;
logic           axi_rdma_get_wqe_wready;
logic           axi_rdma_get_wqe_awlock;
logic           axi_rdma_get_wqe_bid;
logic   [1 : 0] axi_rdma_get_wqe_bresp;
logic           axi_rdma_get_wqe_bvalid;
logic           axi_rdma_get_wqe_bready;
logic           axi_rdma_get_wqe_arid;
logic  [63 : 0] axi_rdma_get_wqe_araddr;
logic   [7 : 0] axi_rdma_get_wqe_arlen;
logic   [2 : 0] axi_rdma_get_wqe_arsize;
logic   [1 : 0] axi_rdma_get_wqe_arburst;
logic   [3 : 0] axi_rdma_get_wqe_arcache;
logic   [2 : 0] axi_rdma_get_wqe_arprot;
logic           axi_rdma_get_wqe_arvalid;
logic           axi_rdma_get_wqe_arready;
logic           axi_rdma_get_wqe_rid;
logic [511 : 0] axi_rdma_get_wqe_rdata;
logic   [1 : 0] axi_rdma_get_wqe_rresp;
logic           axi_rdma_get_wqe_rlast;
logic           axi_rdma_get_wqe_rvalid;
logic           axi_rdma_get_wqe_rready;
logic           axi_rdma_get_wqe_arlock;
logic   [3 : 0] axi_rdma_get_wqe_arqos;

// RDMA AXI MM interface used to get payload from system memory
logic           axi_rdma_get_payload_awid;
logic  [63 : 0] axi_rdma_get_payload_awaddr;
logic   [3 : 0] axi_rdma_get_payload_awqos;
logic   [7 : 0] axi_rdma_get_payload_awlen;
logic   [2 : 0] axi_rdma_get_payload_awsize;
logic   [1 : 0] axi_rdma_get_payload_awburst;
logic   [3 : 0] axi_rdma_get_payload_awcache;
logic   [2 : 0] axi_rdma_get_payload_awprot;
logic           axi_rdma_get_payload_awvalid;
logic           axi_rdma_get_payload_awready;
logic [511 : 0] axi_rdma_get_payload_wdata;
logic  [63 : 0] axi_rdma_get_payload_wstrb;
logic           axi_rdma_get_payload_wlast;
logic           axi_rdma_get_payload_wvalid;
logic           axi_rdma_get_payload_wready;
logic           axi_rdma_get_payload_awlock;
logic           axi_rdma_get_payload_bid;
logic   [1 : 0] axi_rdma_get_payload_bresp;
logic           axi_rdma_get_payload_bvalid;
logic           axi_rdma_get_payload_bready;
logic           axi_rdma_get_payload_arid;
logic  [63 : 0] axi_rdma_get_payload_araddr;
logic   [7 : 0] axi_rdma_get_payload_arlen;
logic   [2 : 0] axi_rdma_get_payload_arsize;
logic   [1 : 0] axi_rdma_get_payload_arburst;
logic   [3 : 0] axi_rdma_get_payload_arcache;
logic   [2 : 0] axi_rdma_get_payload_arprot;
logic           axi_rdma_get_payload_arvalid;
logic           axi_rdma_get_payload_arready;
logic           axi_rdma_get_payload_rid;
logic [511 : 0] axi_rdma_get_payload_rdata;
logic   [1 : 0] axi_rdma_get_payload_rresp;
logic           axi_rdma_get_payload_rlast;
logic           axi_rdma_get_payload_rvalid;
logic           axi_rdma_get_payload_rready;
logic           axi_rdma_get_payload_arlock;
logic   [3 : 0] axi_rdma_get_payload_arqos;

// RDMA AXI MM interface used to update rdma completion to system memory
logic           axi_rdma_completion_awid;
logic  [63 : 0] axi_rdma_completion_awaddr;
logic   [3 : 0] axi_rdma_completion_awqos;
logic   [7 : 0] axi_rdma_completion_awlen;
logic   [2 : 0] axi_rdma_completion_awsize;
logic   [1 : 0] axi_rdma_completion_awburst;
logic   [3 : 0] axi_rdma_completion_awcache;
logic   [2 : 0] axi_rdma_completion_awprot;
logic           axi_rdma_completion_awvalid;
logic           axi_rdma_completion_awready;
logic [511 : 0] axi_rdma_completion_wdata;
logic  [63 : 0] axi_rdma_completion_wstrb;
logic           axi_rdma_completion_wlast;
logic           axi_rdma_completion_wvalid;
logic           axi_rdma_completion_wready;
logic           axi_rdma_completion_awlock;
logic           axi_rdma_completion_bid;
logic   [1 : 0] axi_rdma_completion_bresp;
logic           axi_rdma_completion_bvalid;
logic           axi_rdma_completion_bready;
logic           axi_rdma_completion_arid;
logic  [63 : 0] axi_rdma_completion_araddr;
logic   [7 : 0] axi_rdma_completion_arlen;
logic   [2 : 0] axi_rdma_completion_arsize;
logic   [1 : 0] axi_rdma_completion_arburst;
logic   [3 : 0] axi_rdma_completion_arcache;
logic   [2 : 0] axi_rdma_completion_arprot;
logic           axi_rdma_completion_arvalid;
logic           axi_rdma_completion_arready;
logic           axi_rdma_completion_rid;
logic [511 : 0] axi_rdma_completion_rdata;
logic   [1 : 0] axi_rdma_completion_rresp;
logic           axi_rdma_completion_rlast;
logic           axi_rdma_completion_rvalid;
logic           axi_rdma_completion_rready;
logic           axi_rdma_completion_arlock;
logic   [3 : 0] axi_rdma_completion_arqos;

logic           axi_qdma_mm_awready;
logic           axi_qdma_mm_wready;
logic     [3:0] axi_qdma_mm_bid;
logic     [1:0] axi_qdma_mm_bresp;
logic           axi_qdma_mm_bvalid;
logic           axi_qdma_mm_arready;
logic     [3:0] axi_qdma_mm_rid;
logic   [511:0] axi_qdma_mm_rdata;
logic     [1:0] axi_qdma_mm_rresp;
logic           axi_qdma_mm_rlast;
logic           axi_qdma_mm_rvalid;
logic     [3:0] axi_qdma_mm_awid;
logic    [63:0] axi_qdma_mm_awaddr;
logic    [31:0] axi_qdma_mm_awuser;
logic     [7:0] axi_qdma_mm_awlen;
logic     [2:0] axi_qdma_mm_awsize;
logic     [1:0] axi_qdma_mm_awburst;
logic     [2:0] axi_qdma_mm_awprot;
logic           axi_qdma_mm_awvalid;
logic           axi_qdma_mm_awlock;
logic     [3:0] axi_qdma_mm_awcache;
logic   [511:0] axi_qdma_mm_wdata;
logic    [63:0] axi_qdma_mm_wuser;
logic    [63:0] axi_qdma_mm_wstrb;
logic           axi_qdma_mm_wlast;
logic           axi_qdma_mm_wvalid;
logic           axi_qdma_mm_bready;
logic     [3:0] axi_qdma_mm_arid;
logic    [63:0] axi_qdma_mm_araddr;
logic    [31:0] axi_qdma_mm_aruser;
logic     [7:0] axi_qdma_mm_arlen;
logic     [2:0] axi_qdma_mm_arsize;
logic     [1:0] axi_qdma_mm_arburst;
logic     [2:0] axi_qdma_mm_arprot;
logic           axi_qdma_mm_arvalid;
logic           axi_qdma_mm_arlock;
logic     [3:0] axi_qdma_mm_arcache;
logic           axi_qdma_mm_rready;

// AXI MM interface used to access the device memory
logic   [1:0] axi_dev_mem_awid;
logic  [63:0] axi_dev_mem_awaddr;
logic   [7:0] axi_dev_mem_awlen;
logic   [2:0] axi_dev_mem_awsize;
logic   [1:0] axi_dev_mem_awburst;
logic         axi_dev_mem_awlock;
logic   [3:0] axi_dev_mem_awqos;
logic   [3:0] axi_dev_mem_awregion;
logic   [3:0] axi_dev_mem_awcache;
logic   [2:0] axi_dev_mem_awprot;
logic         axi_dev_mem_awvalid;
logic         axi_dev_mem_awready;
logic [511:0] axi_dev_mem_wdata;
logic  [63:0] axi_dev_mem_wstrb;
logic         axi_dev_mem_wlast;
logic         axi_dev_mem_wvalid;
logic         axi_dev_mem_wready;
logic   [1:0] axi_dev_mem_bid;
logic   [1:0] axi_dev_mem_bresp;
logic         axi_dev_mem_bvalid;
logic         axi_dev_mem_bready;
logic   [1:0] axi_dev_mem_arid;
logic  [63:0] axi_dev_mem_araddr;
logic   [7:0] axi_dev_mem_arlen;
logic   [2:0] axi_dev_mem_arsize;
logic   [1:0] axi_dev_mem_arburst;
logic         axi_dev_mem_arlock;
logic   [3:0] axi_dev_mem_arqos;
logic   [3:0] axi_dev_mem_arregion;
logic   [3:0] axi_dev_mem_arcache;
logic   [2:0] axi_dev_mem_arprot;
logic         axi_dev_mem_arvalid;
logic         axi_dev_mem_arready;
logic   [1:0] axi_dev_mem_rid;
logic [511:0] axi_dev_mem_rdata;
logic   [1:0] axi_dev_mem_rresp;
logic         axi_dev_mem_rlast;
logic         axi_dev_mem_rvalid;
logic         axi_dev_mem_rready;

// RDMA AXI MM interface used to store payload from RDMA Read response operation
logic           axi_compute_logic_awid;
logic  [63 : 0] axi_compute_logic_awaddr;
logic   [3 : 0] axi_compute_logic_awqos;
logic   [7 : 0] axi_compute_logic_awlen;
logic   [2 : 0] axi_compute_logic_awsize;
logic   [1 : 0] axi_compute_logic_awburst;
logic   [3 : 0] axi_compute_logic_awcache;
logic   [2 : 0] axi_compute_logic_awprot;
logic           axi_compute_logic_awvalid;
logic           axi_compute_logic_awready;
logic [511 : 0] axi_compute_logic_wdata;
logic  [63 : 0] axi_compute_logic_wstrb;
logic           axi_compute_logic_wlast;
logic           axi_compute_logic_wvalid;
logic           axi_compute_logic_wready;
logic           axi_compute_logic_awlock;
logic           axi_compute_logic_bid;
logic   [1 : 0] axi_compute_logic_bresp;
logic           axi_compute_logic_bvalid;
logic           axi_compute_logic_bready;
logic           axi_compute_logic_arid;
logic  [63 : 0] axi_compute_logic_araddr;
logic   [7 : 0] axi_compute_logic_arlen;
logic   [2 : 0] axi_compute_logic_arsize;
logic   [1 : 0] axi_compute_logic_arburst;
logic   [3 : 0] axi_compute_logic_arcache;
logic   [2 : 0] axi_compute_logic_arprot;
logic           axi_compute_logic_arvalid;
logic           axi_compute_logic_arready;
logic           axi_compute_logic_rid;
logic [511 : 0] axi_compute_logic_rdata;
logic   [1 : 0] axi_compute_logic_rresp;
logic           axi_compute_logic_rlast;
logic           axi_compute_logic_rvalid;
logic           axi_compute_logic_rready;
logic           axi_compute_logic_arlock;
logic   [3 : 0] axi_compute_logic_arqos;

// AXI MM interface used to access the system memory (s_axib_* of the QDMA IP)
logic     [1:0] axi_sys_mem_awid;
logic    [63:0] axi_sys_mem_awaddr;
logic     [7:0] axi_sys_mem_awlen;
logic     [2:0] axi_sys_mem_awsize;
logic     [1:0] axi_sys_mem_awburst;
logic           axi_sys_mem_awlock;
logic     [3:0] axi_sys_mem_awqos;
logic     [3:0] axi_sys_mem_awregion;
logic     [3:0] axi_sys_mem_awcache;
logic     [2:0] axi_sys_mem_awprot;
logic           axi_sys_mem_awvalid;
logic           axi_sys_mem_awready;
logic   [511:0] axi_sys_mem_wdata;
logic    [63:0] axi_sys_mem_wstrb;
logic           axi_sys_mem_wlast;
logic           axi_sys_mem_wvalid;
logic           axi_sys_mem_wready;
logic     [1:0] axi_sys_mem_bid;
logic     [1:0] axi_sys_mem_bresp;
logic           axi_sys_mem_bvalid;
logic           axi_sys_mem_bready;
logic     [1:0] axi_sys_mem_arid;
logic    [63:0] axi_sys_mem_araddr;
logic     [7:0] axi_sys_mem_arlen;
logic     [2:0] axi_sys_mem_arsize;
logic     [1:0] axi_sys_mem_arburst;
logic           axi_sys_mem_arlock;
logic     [3:0] axi_sys_mem_arqos;
logic     [3:0] axi_sys_mem_arregion;
logic     [3:0] axi_sys_mem_arcache;
logic     [2:0] axi_sys_mem_arprot;
logic           axi_sys_mem_arvalid;
logic           axi_sys_mem_arready;
logic     [1:0] axi_sys_mem_rid;
logic   [511:0] axi_sys_mem_rdata;
logic     [1:0] axi_sys_mem_rresp;
logic           axi_sys_mem_rlast;
logic           axi_sys_mem_rvalid;
logic           axi_sys_mem_rready;
logic    [63:0] axi_sys_mem_wuser;
logic    [63:0] axi_sys_mem_ruser;
logic    [11:0] axi_sys_mem_awuser;
logic    [11:0] axi_sys_mem_aruser;
logic rdma_intr;

// Singals used to indicate completion of memory initialization
logic init_sys_mem_done;
logic init_dev_mem_done;

// AXI4 protocol write checker
logic [160-1:0] sys_pc_status;
logic           sys_pc_asserted;
logic [160-1:0] dev_pc_status;
logic           dev_pc_asserted;

logic start_config_rdma;

logic [2:0]     three_unused_bit0;
logic [2:0]     three_unused_bit1;
logic [2:0]     three_unused_bit2;
logic [2:0]     three_unused_bit3;

rn_tb_generator generator (
  .traffic_filename(traffic_filename),
  .num_pkts        (num_pkts),
  .mbox_pkt_str    (gen_pkt_mbox)
);

rn_tb_driver driver(
  .num_pkts          (num_pkts),
  .table_filename    (""),
  .rsp_table_filename(""),
  .rdma_cfg_filename (rdma_combined_cfg_filename),
  .rdma_stat_filename(""),

  .mbox_pkt_str(gen_pkt_mbox), 
  // Output stimulus
  .m_axis_tvalid    (s_axis_cmac_rx_tvalid),
  .m_axis_tdata     (s_axis_cmac_rx_tdata),
  .m_axis_tkeep     (s_axis_cmac_rx_tkeep),
  .m_axis_tlast     (s_axis_cmac_rx_tlast),
  .m_axis_tuser_size(s_axis_cmac_rx_tuser_size),
  .m_axis_tready    (s_axis_cmac_rx_tready),

  .m_axil_rn_awvalid(s_axil_rn_awvalid),
  .m_axil_rn_awaddr (s_axil_rn_awaddr),
  .m_axil_rn_awready(s_axil_rn_awready),
  .m_axil_rn_wvalid (s_axil_rn_wvalid),
  .m_axil_rn_wdata  (s_axil_rn_wdata),
  .m_axil_rn_wready (s_axil_rn_wready),
  .m_axil_rn_bvalid (s_axil_rn_bvalid),
  .m_axil_rn_bresp  (s_axil_rn_bresp),
  .m_axil_rn_bready (s_axil_rn_bready),
  .m_axil_rn_arvalid(s_axil_rn_arvalid),
  .m_axil_rn_araddr (s_axil_rn_araddr),
  .m_axil_rn_arready(s_axil_rn_arready),
  .m_axil_rn_rvalid (s_axil_rn_rvalid),
  .m_axil_rn_rdata  (s_axil_rn_rdata),
  .m_axil_rn_rresp  (s_axil_rn_rresp),
  .m_axil_rn_rready (s_axil_rn_rready),

  .m_axil_rdma_awvalid(s_axil_rdma_awvalid),
  .m_axil_rdma_awaddr (s_axil_rdma_awaddr),
  .m_axil_rdma_awready(s_axil_rdma_awready),
  .m_axil_rdma_wvalid (s_axil_rdma_wvalid),
  .m_axil_rdma_wdata  (s_axil_rdma_wdata),
  .m_axil_rdma_wready (s_axil_rdma_wready),
  .m_axil_rdma_bvalid (s_axil_rdma_bvalid),
  .m_axil_rdma_bresp  (s_axil_rdma_bresp),
  .m_axil_rdma_bready (s_axil_rdma_bready),
  .m_axil_rdma_arvalid(s_axil_rdma_arvalid),
  .m_axil_rdma_araddr (s_axil_rdma_araddr),
  .m_axil_rdma_arready(s_axil_rdma_arready),
  .m_axil_rdma_rvalid (s_axil_rdma_rvalid),
  .m_axil_rdma_rdata  (s_axil_rdma_rdata),
  .m_axil_rdma_rresp  (s_axil_rdma_rresp),
  .m_axil_rdma_rready (s_axil_rdma_rready),

  .start_sim         (axis_rstn),
  .start_config_rdma (start_config_rdma),
  .start_stat_rdma   (1'b0),
  .stimulus_all_sent(),

  .axil_clk (axil_clk), 
  .axil_rstn(axil_rstn),
  .axis_clk (axis_clk), 
  .axis_rstn(axis_rstn)
);

assign start_config_rdma = init_sys_mem_done && init_dev_mem_done;

// Instantiate reconic integration
rdma_rn_wrapper rdma_rn_wrapper_inst (
  // AXI4-Lite RDMA register channel
  .s_axil_rdma_awvalid         (s_axil_rdma_awvalid),
  .s_axil_rdma_awaddr          (s_axil_rdma_awaddr),
  .s_axil_rdma_awready         (s_axil_rdma_awready),
  .s_axil_rdma_wvalid          (s_axil_rdma_wvalid),
  .s_axil_rdma_wdata           (s_axil_rdma_wdata),
  .s_axil_rdma_wready          (s_axil_rdma_wready),
  .s_axil_rdma_bvalid          (s_axil_rdma_bvalid),
  .s_axil_rdma_bresp           (s_axil_rdma_bresp),
  .s_axil_rdma_bready          (s_axil_rdma_bready),
  .s_axil_rdma_arvalid         (s_axil_rdma_arvalid),
  .s_axil_rdma_araddr          (s_axil_rdma_araddr),
  .s_axil_rdma_arready         (s_axil_rdma_arready),
  .s_axil_rdma_rvalid          (s_axil_rdma_rvalid),
  .s_axil_rdma_rdata           (s_axil_rdma_rdata),
  .s_axil_rdma_rresp           (s_axil_rdma_rresp),
  .s_axil_rdma_rready          (s_axil_rdma_rready),

  // AXI4-Lite RecoNIC register channel
  .s_axil_rn_awvalid           (s_axil_rn_awvalid),
  .s_axil_rn_awaddr            (s_axil_rn_awaddr),
  .s_axil_rn_awready           (s_axil_rn_awready),
  .s_axil_rn_wvalid            (s_axil_rn_wvalid),
  .s_axil_rn_wdata             (s_axil_rn_wdata),
  .s_axil_rn_wready            (s_axil_rn_wready),
  .s_axil_rn_bvalid            (s_axil_rn_bvalid),
  .s_axil_rn_bresp             (s_axil_rn_bresp),
  .s_axil_rn_bready            (s_axil_rn_bready),
  .s_axil_rn_arvalid           (s_axil_rn_arvalid),
  .s_axil_rn_araddr            (s_axil_rn_araddr),
  .s_axil_rn_arready           (s_axil_rn_arready),
  .s_axil_rn_rvalid            (s_axil_rn_rvalid),
  .s_axil_rn_rdata             (s_axil_rn_rdata),
  .s_axil_rn_rresp             (s_axil_rn_rresp),
  .s_axil_rn_rready            (s_axil_rn_rready),

  // Receive packets from CMAC RX path
  .s_axis_cmac_rx_tvalid       (s_axis_cmac_rx_tvalid),
  .s_axis_cmac_rx_tdata        (s_axis_cmac_rx_tdata),
  .s_axis_cmac_rx_tkeep        (s_axis_cmac_rx_tkeep),
  .s_axis_cmac_rx_tlast        (s_axis_cmac_rx_tlast),
  .s_axis_cmac_rx_tuser_size   (s_axis_cmac_rx_tuser_size),
  .s_axis_cmac_rx_tready       (s_axis_cmac_rx_tready),

  // Expose roce packets from CMAC RX path after packet classification, 
  // for debug only
  .m_axis_cmac2rdma_roce_tdata (m_axis_cmac_rx_roce_tdata),
  .m_axis_cmac2rdma_roce_tkeep (m_axis_cmac_rx_roce_tkeep),
  .m_axis_cmac2rdma_roce_tvalid(m_axis_cmac_rx_roce_tvalid),
  .m_axis_cmac2rdma_roce_tlast (m_axis_cmac_rx_roce_tlast),

  // Send packets to CMAC TX path
  .m_axis_cmac_tx_tvalid       (m_axis_cmac_tx_tvalid),
  .m_axis_cmac_tx_tdata        (m_axis_cmac_tx_tdata),
  .m_axis_cmac_tx_tkeep        (m_axis_cmac_tx_tkeep),
  .m_axis_cmac_tx_tlast        (m_axis_cmac_tx_tlast),
  .m_axis_cmac_tx_tuser_size   (m_axis_cmac_tx_tuser_size),
  .m_axis_cmac_tx_tready       (m_axis_cmac_tx_tready),

  // Get packets from QDMA TX path
  .s_axis_qdma_h2c_tvalid      (s_axis_qdma_h2c_tvalid),
  .s_axis_qdma_h2c_tdata       (s_axis_qdma_h2c_tdata),
  .s_axis_qdma_h2c_tkeep       (s_axis_qdma_h2c_tkeep),
  .s_axis_qdma_h2c_tlast       (s_axis_qdma_h2c_tlast),
  .s_axis_qdma_h2c_tuser_size  (s_axis_qdma_h2c_tuser_size),
  .s_axis_qdma_h2c_tready      (s_axis_qdma_h2c_tready),

  // Send packets to QDMA RX path
  .m_axis_qdma_c2h_tvalid      (m_axis_qdma_c2h_tvalid),
  .m_axis_qdma_c2h_tdata       (m_axis_qdma_c2h_tdata),
  .m_axis_qdma_c2h_tkeep       (m_axis_qdma_c2h_tkeep),
  .m_axis_qdma_c2h_tlast       (m_axis_qdma_c2h_tlast),
  .m_axis_qdma_c2h_tuser_size  (m_axis_qdma_c2h_tuser_size),
  .m_axis_qdma_c2h_tready      (m_axis_qdma_c2h_tready),

  // RDMA AXI MM interface used to store payload from RDMA MAD, Send or Write operation
  .m_axi_rdma_send_write_payload_awid       (axi_rdma_send_write_payload_awid),
  .m_axi_rdma_send_write_payload_awaddr     (axi_rdma_send_write_payload_awaddr),
  .m_axi_rdma_send_write_payload_awuser     (axi_rdma_send_write_payload_awuser),
  .m_axi_rdma_send_write_payload_awlen      (axi_rdma_send_write_payload_awlen),
  .m_axi_rdma_send_write_payload_awsize     (axi_rdma_send_write_payload_awsize),
  .m_axi_rdma_send_write_payload_awburst    (axi_rdma_send_write_payload_awburst),
  .m_axi_rdma_send_write_payload_awcache    (axi_rdma_send_write_payload_awcache),
  .m_axi_rdma_send_write_payload_awprot     (axi_rdma_send_write_payload_awprot),
  .m_axi_rdma_send_write_payload_awvalid    (axi_rdma_send_write_payload_awvalid),
  .m_axi_rdma_send_write_payload_awready    (axi_rdma_send_write_payload_awready),
  .m_axi_rdma_send_write_payload_wdata      (axi_rdma_send_write_payload_wdata),
  .m_axi_rdma_send_write_payload_wstrb      (axi_rdma_send_write_payload_wstrb),
  .m_axi_rdma_send_write_payload_wlast      (axi_rdma_send_write_payload_wlast),
  .m_axi_rdma_send_write_payload_wvalid     (axi_rdma_send_write_payload_wvalid),
  .m_axi_rdma_send_write_payload_wready     (axi_rdma_send_write_payload_wready),
  .m_axi_rdma_send_write_payload_awlock     (axi_rdma_send_write_payload_awlock),
  .m_axi_rdma_send_write_payload_bid        (axi_rdma_send_write_payload_bid),
  .m_axi_rdma_send_write_payload_bresp      (axi_rdma_send_write_payload_bresp),
  .m_axi_rdma_send_write_payload_bvalid     (axi_rdma_send_write_payload_bvalid),
  .m_axi_rdma_send_write_payload_bready     (axi_rdma_send_write_payload_bready),
  .m_axi_rdma_send_write_payload_arid       (axi_rdma_send_write_payload_arid),
  .m_axi_rdma_send_write_payload_araddr     (axi_rdma_send_write_payload_araddr),
  .m_axi_rdma_send_write_payload_arlen      (axi_rdma_send_write_payload_arlen),
  .m_axi_rdma_send_write_payload_arsize     (axi_rdma_send_write_payload_arsize),
  .m_axi_rdma_send_write_payload_arburst    (axi_rdma_send_write_payload_arburst),
  .m_axi_rdma_send_write_payload_arcache    (axi_rdma_send_write_payload_arcache),
  .m_axi_rdma_send_write_payload_arprot     (axi_rdma_send_write_payload_arprot),
  .m_axi_rdma_send_write_payload_arvalid    (axi_rdma_send_write_payload_arvalid),
  .m_axi_rdma_send_write_payload_arready    (axi_rdma_send_write_payload_arready),
  .m_axi_rdma_send_write_payload_rid        (axi_rdma_send_write_payload_rid),
  .m_axi_rdma_send_write_payload_rdata      (axi_rdma_send_write_payload_rdata),
  .m_axi_rdma_send_write_payload_rresp      (axi_rdma_send_write_payload_rresp),
  .m_axi_rdma_send_write_payload_rlast      (axi_rdma_send_write_payload_rlast),
  .m_axi_rdma_send_write_payload_rvalid     (axi_rdma_send_write_payload_rvalid),
  .m_axi_rdma_send_write_payload_rready     (axi_rdma_send_write_payload_rready),
  .m_axi_rdma_send_write_payload_arlock     (axi_rdma_send_write_payload_arlock),

  // RDMA AXI MM interface used to store payload from RDMA Read response operation
  .m_axi_rdma_rsp_payload_awid         (axi_rdma_rsp_payload_awid),
  .m_axi_rdma_rsp_payload_awaddr       (axi_rdma_rsp_payload_awaddr),
  .m_axi_rdma_rsp_payload_awlen        (axi_rdma_rsp_payload_awlen),
  .m_axi_rdma_rsp_payload_awsize       (axi_rdma_rsp_payload_awsize),
  .m_axi_rdma_rsp_payload_awburst      (axi_rdma_rsp_payload_awburst),
  .m_axi_rdma_rsp_payload_awcache      (axi_rdma_rsp_payload_awcache),
  .m_axi_rdma_rsp_payload_awprot       (axi_rdma_rsp_payload_awprot),
  .m_axi_rdma_rsp_payload_awvalid      (axi_rdma_rsp_payload_awvalid),
  .m_axi_rdma_rsp_payload_awready      (axi_rdma_rsp_payload_awready),
  .m_axi_rdma_rsp_payload_wdata        (axi_rdma_rsp_payload_wdata),
  .m_axi_rdma_rsp_payload_wstrb        (axi_rdma_rsp_payload_wstrb),
  .m_axi_rdma_rsp_payload_wlast        (axi_rdma_rsp_payload_wlast),
  .m_axi_rdma_rsp_payload_wvalid       (axi_rdma_rsp_payload_wvalid),
  .m_axi_rdma_rsp_payload_wready       (axi_rdma_rsp_payload_wready),
  .m_axi_rdma_rsp_payload_awlock       (axi_rdma_rsp_payload_awlock),
  .m_axi_rdma_rsp_payload_bid          (axi_rdma_rsp_payload_bid),
  .m_axi_rdma_rsp_payload_bresp        (axi_rdma_rsp_payload_bresp),
  .m_axi_rdma_rsp_payload_bvalid       (axi_rdma_rsp_payload_bvalid),
  .m_axi_rdma_rsp_payload_bready       (axi_rdma_rsp_payload_bready),
  .m_axi_rdma_rsp_payload_arid         (axi_rdma_rsp_payload_arid),
  .m_axi_rdma_rsp_payload_araddr       (axi_rdma_rsp_payload_araddr),
  .m_axi_rdma_rsp_payload_arlen        (axi_rdma_rsp_payload_arlen),
  .m_axi_rdma_rsp_payload_arsize       (axi_rdma_rsp_payload_arsize),
  .m_axi_rdma_rsp_payload_arburst      (axi_rdma_rsp_payload_arburst),
  .m_axi_rdma_rsp_payload_arcache      (axi_rdma_rsp_payload_arcache),
  .m_axi_rdma_rsp_payload_arprot       (axi_rdma_rsp_payload_arprot),
  .m_axi_rdma_rsp_payload_arvalid      (axi_rdma_rsp_payload_arvalid),
  .m_axi_rdma_rsp_payload_arready      (axi_rdma_rsp_payload_arready),
  .m_axi_rdma_rsp_payload_rid          (axi_rdma_rsp_payload_rid),
  .m_axi_rdma_rsp_payload_rdata        (axi_rdma_rsp_payload_rdata),
  .m_axi_rdma_rsp_payload_rresp        (axi_rdma_rsp_payload_rresp),
  .m_axi_rdma_rsp_payload_rlast        (axi_rdma_rsp_payload_rlast),
  .m_axi_rdma_rsp_payload_rvalid       (axi_rdma_rsp_payload_rvalid),
  .m_axi_rdma_rsp_payload_rready       (axi_rdma_rsp_payload_rready),
  .m_axi_rdma_rsp_payload_arlock       (axi_rdma_rsp_payload_arlock),

  // RDMA AXI MM interface used to fetch WQE entries in the senq queue from DDR by the QP manager
  .m_axi_rdma_get_wqe_awid             (axi_rdma_get_wqe_awid),
  .m_axi_rdma_get_wqe_awaddr           (axi_rdma_get_wqe_awaddr),
  .m_axi_rdma_get_wqe_awlen            (axi_rdma_get_wqe_awlen),
  .m_axi_rdma_get_wqe_awsize           (axi_rdma_get_wqe_awsize),
  .m_axi_rdma_get_wqe_awburst          (axi_rdma_get_wqe_awburst),
  .m_axi_rdma_get_wqe_awcache          (axi_rdma_get_wqe_awcache),
  .m_axi_rdma_get_wqe_awprot           (axi_rdma_get_wqe_awprot),
  .m_axi_rdma_get_wqe_awvalid          (axi_rdma_get_wqe_awvalid),
  .m_axi_rdma_get_wqe_awready          (axi_rdma_get_wqe_awready),
  .m_axi_rdma_get_wqe_wdata            (axi_rdma_get_wqe_wdata),
  .m_axi_rdma_get_wqe_wstrb            (axi_rdma_get_wqe_wstrb),
  .m_axi_rdma_get_wqe_wlast            (axi_rdma_get_wqe_wlast),
  .m_axi_rdma_get_wqe_wvalid           (axi_rdma_get_wqe_wvalid),
  .m_axi_rdma_get_wqe_wready           (axi_rdma_get_wqe_wready),
  .m_axi_rdma_get_wqe_awlock           (axi_rdma_get_wqe_awlock),
  .m_axi_rdma_get_wqe_bid              (axi_rdma_get_wqe_bid),
  .m_axi_rdma_get_wqe_bresp            (axi_rdma_get_wqe_bresp),
  .m_axi_rdma_get_wqe_bvalid           (axi_rdma_get_wqe_bvalid),
  .m_axi_rdma_get_wqe_bready           (axi_rdma_get_wqe_bready),
  .m_axi_rdma_get_wqe_arid             (axi_rdma_get_wqe_arid),
  .m_axi_rdma_get_wqe_araddr           (axi_rdma_get_wqe_araddr),
  .m_axi_rdma_get_wqe_arlen            (axi_rdma_get_wqe_arlen),
  .m_axi_rdma_get_wqe_arsize           (axi_rdma_get_wqe_arsize),
  .m_axi_rdma_get_wqe_arburst          (axi_rdma_get_wqe_arburst),
  .m_axi_rdma_get_wqe_arcache          (axi_rdma_get_wqe_arcache),
  .m_axi_rdma_get_wqe_arprot           (axi_rdma_get_wqe_arprot),
  .m_axi_rdma_get_wqe_arvalid          (axi_rdma_get_wqe_arvalid),
  .m_axi_rdma_get_wqe_arready          (axi_rdma_get_wqe_arready),
  .m_axi_rdma_get_wqe_rid              (axi_rdma_get_wqe_rid),
  .m_axi_rdma_get_wqe_rdata            (axi_rdma_get_wqe_rdata),
  .m_axi_rdma_get_wqe_rresp            (axi_rdma_get_wqe_rresp),
  .m_axi_rdma_get_wqe_rlast            (axi_rdma_get_wqe_rlast),
  .m_axi_rdma_get_wqe_rvalid           (axi_rdma_get_wqe_rvalid),
  .m_axi_rdma_get_wqe_rready           (axi_rdma_get_wqe_rready),
  .m_axi_rdma_get_wqe_arlock           (axi_rdma_get_wqe_arlock),

  // RDMA AXI MM interface used to get payload of an outgoing RDMA send/write and read response packets
  .m_axi_rdma_get_payload_awid          (axi_rdma_get_payload_awid),
  .m_axi_rdma_get_payload_awaddr        (axi_rdma_get_payload_awaddr),
  .m_axi_rdma_get_payload_awlen         (axi_rdma_get_payload_awlen),
  .m_axi_rdma_get_payload_awsize        (axi_rdma_get_payload_awsize),
  .m_axi_rdma_get_payload_awburst       (axi_rdma_get_payload_awburst),
  .m_axi_rdma_get_payload_awcache       (axi_rdma_get_payload_awcache),
  .m_axi_rdma_get_payload_awprot        (axi_rdma_get_payload_awprot),
  .m_axi_rdma_get_payload_awvalid       (axi_rdma_get_payload_awvalid),
  .m_axi_rdma_get_payload_awready       (axi_rdma_get_payload_awready),
  .m_axi_rdma_get_payload_wdata         (axi_rdma_get_payload_wdata),
  .m_axi_rdma_get_payload_wstrb         (axi_rdma_get_payload_wstrb),
  .m_axi_rdma_get_payload_wlast         (axi_rdma_get_payload_wlast),
  .m_axi_rdma_get_payload_wvalid        (axi_rdma_get_payload_wvalid),
  .m_axi_rdma_get_payload_wready        (axi_rdma_get_payload_wready),
  .m_axi_rdma_get_payload_awlock        (axi_rdma_get_payload_awlock),
  .m_axi_rdma_get_payload_bid           (axi_rdma_get_payload_bid),
  .m_axi_rdma_get_payload_bresp         (axi_rdma_get_payload_bresp),
  .m_axi_rdma_get_payload_bvalid        (axi_rdma_get_payload_bvalid),
  .m_axi_rdma_get_payload_bready        (axi_rdma_get_payload_bready),
  .m_axi_rdma_get_payload_arid          (axi_rdma_get_payload_arid),
  .m_axi_rdma_get_payload_araddr        (axi_rdma_get_payload_araddr),
  .m_axi_rdma_get_payload_arlen         (axi_rdma_get_payload_arlen),
  .m_axi_rdma_get_payload_arsize        (axi_rdma_get_payload_arsize),
  .m_axi_rdma_get_payload_arburst       (axi_rdma_get_payload_arburst),
  .m_axi_rdma_get_payload_arcache       (axi_rdma_get_payload_arcache),
  .m_axi_rdma_get_payload_arprot        (axi_rdma_get_payload_arprot),
  .m_axi_rdma_get_payload_arvalid       (axi_rdma_get_payload_arvalid),
  .m_axi_rdma_get_payload_arready       (axi_rdma_get_payload_arready),
  .m_axi_rdma_get_payload_rid           (axi_rdma_get_payload_rid),
  .m_axi_rdma_get_payload_rdata         (axi_rdma_get_payload_rdata),
  .m_axi_rdma_get_payload_rresp         (axi_rdma_get_payload_rresp),
  .m_axi_rdma_get_payload_rlast         (axi_rdma_get_payload_rlast),
  .m_axi_rdma_get_payload_rvalid        (axi_rdma_get_payload_rvalid),
  .m_axi_rdma_get_payload_rready        (axi_rdma_get_payload_rready),
  .m_axi_rdma_get_payload_arlock        (axi_rdma_get_payload_arlock),

  // RDMA AXI MM interface used to write completion entries to a completion queue in the DDR
  .m_axi_rdma_completion_awid           (axi_rdma_completion_awid),
  .m_axi_rdma_completion_awaddr         (axi_rdma_completion_awaddr),
  .m_axi_rdma_completion_awlen          (axi_rdma_completion_awlen),
  .m_axi_rdma_completion_awsize         (axi_rdma_completion_awsize),
  .m_axi_rdma_completion_awburst        (axi_rdma_completion_awburst),
  .m_axi_rdma_completion_awcache        (axi_rdma_completion_awcache),
  .m_axi_rdma_completion_awprot         (axi_rdma_completion_awprot),
  .m_axi_rdma_completion_awvalid        (axi_rdma_completion_awvalid),
  .m_axi_rdma_completion_awready        (axi_rdma_completion_awready),
  .m_axi_rdma_completion_wdata          (axi_rdma_completion_wdata),
  .m_axi_rdma_completion_wstrb          (axi_rdma_completion_wstrb),
  .m_axi_rdma_completion_wlast          (axi_rdma_completion_wlast),
  .m_axi_rdma_completion_wvalid         (axi_rdma_completion_wvalid),
  .m_axi_rdma_completion_wready         (axi_rdma_completion_wready),
  .m_axi_rdma_completion_awlock         (axi_rdma_completion_awlock),
  .m_axi_rdma_completion_bid            (axi_rdma_completion_bid),
  .m_axi_rdma_completion_bresp          (axi_rdma_completion_bresp),
  .m_axi_rdma_completion_bvalid         (axi_rdma_completion_bvalid),
  .m_axi_rdma_completion_bready         (axi_rdma_completion_bready),
  .m_axi_rdma_completion_arid           (axi_rdma_completion_arid),
  .m_axi_rdma_completion_araddr         (axi_rdma_completion_araddr),
  .m_axi_rdma_completion_arlen          (axi_rdma_completion_arlen),
  .m_axi_rdma_completion_arsize         (axi_rdma_completion_arsize),
  .m_axi_rdma_completion_arburst        (axi_rdma_completion_arburst),
  .m_axi_rdma_completion_arcache        (axi_rdma_completion_arcache),
  .m_axi_rdma_completion_arprot         (axi_rdma_completion_arprot),
  .m_axi_rdma_completion_arvalid        (axi_rdma_completion_arvalid),
  .m_axi_rdma_completion_arready        (axi_rdma_completion_arready),
  .m_axi_rdma_completion_rid            (axi_rdma_completion_rid),
  .m_axi_rdma_completion_rdata          (axi_rdma_completion_rdata),
  .m_axi_rdma_completion_rresp          (axi_rdma_completion_rresp),
  .m_axi_rdma_completion_rlast          (axi_rdma_completion_rlast),
  .m_axi_rdma_completion_rvalid         (axi_rdma_completion_rvalid),
  .m_axi_rdma_completion_rready         (axi_rdma_completion_rready),
  .m_axi_rdma_completion_arlock         (axi_rdma_completion_arlock),

  .m_axi_compute_logic_awid             (axi_compute_logic_awid),
  .m_axi_compute_logic_awaddr           (axi_compute_logic_awaddr),
  .m_axi_compute_logic_awqos            (axi_compute_logic_awqos),
  .m_axi_compute_logic_awlen            (axi_compute_logic_awlen),
  .m_axi_compute_logic_awsize           (axi_compute_logic_awsize),
  .m_axi_compute_logic_awburst          (axi_compute_logic_awburst),
  .m_axi_compute_logic_awcache          (axi_compute_logic_awcache),
  .m_axi_compute_logic_awprot           (axi_compute_logic_awprot),
  .m_axi_compute_logic_awvalid          (axi_compute_logic_awvalid),
  .m_axi_compute_logic_awready          (axi_compute_logic_awready),
  .m_axi_compute_logic_wdata            (axi_compute_logic_wdata),
  .m_axi_compute_logic_wstrb            (axi_compute_logic_wstrb),
  .m_axi_compute_logic_wlast            (axi_compute_logic_wlast),
  .m_axi_compute_logic_wvalid           (axi_compute_logic_wvalid),
  .m_axi_compute_logic_wready           (axi_compute_logic_wready),
  .m_axi_compute_logic_awlock           (axi_compute_logic_awlock),
  .m_axi_compute_logic_bid              (axi_compute_logic_bid),
  .m_axi_compute_logic_bresp            (axi_compute_logic_bresp),
  .m_axi_compute_logic_bvalid           (axi_compute_logic_bvalid),
  .m_axi_compute_logic_bready           (axi_compute_logic_bready),
  .m_axi_compute_logic_arid             (axi_compute_logic_arid),
  .m_axi_compute_logic_araddr           (axi_compute_logic_araddr),
  .m_axi_compute_logic_arlen            (axi_compute_logic_arlen),
  .m_axi_compute_logic_arsize           (axi_compute_logic_arsize),
  .m_axi_compute_logic_arburst          (axi_compute_logic_arburst),
  .m_axi_compute_logic_arcache          (axi_compute_logic_arcache),
  .m_axi_compute_logic_arprot           (axi_compute_logic_arprot),
  .m_axi_compute_logic_arvalid          (axi_compute_logic_arvalid),
  .m_axi_compute_logic_arready          (axi_compute_logic_arready),
  .m_axi_compute_logic_rid              (axi_compute_logic_rid),
  .m_axi_compute_logic_rdata            (axi_compute_logic_rdata),
  .m_axi_compute_logic_rresp            (axi_compute_logic_rresp),
  .m_axi_compute_logic_rlast            (axi_compute_logic_rlast),
  .m_axi_compute_logic_rvalid           (axi_compute_logic_rvalid),
  .m_axi_compute_logic_rready           (axi_compute_logic_rready),
  .m_axi_compute_logic_arlock           (axi_compute_logic_arlock),
  .m_axi_compute_logic_arqos            (axi_compute_logic_arqos),

  .rdma_intr(rdma_intr),
  .axil_aclk(axil_clk),
  .axil_rstn(axil_rstn),
  .axis_aclk(axis_clk),
  .axis_rstn(axis_rstn)
);

// Always receive packets sent to CMAC tx path
assign m_axis_cmac_tx_tready =1'b1;

// AXI crossbar used to access device memory
axi_interconnect_to_dev_mem axi_interconnect_to_dev_mem_inst(
  .s_axi_rdma_send_write_payload_awid    (axi_rdma_send_write_payload_awid),
  .s_axi_rdma_send_write_payload_awaddr  (axi_rdma_send_write_payload_awaddr),
  .s_axi_rdma_send_write_payload_awqos   (axi_rdma_send_write_payload_awqos),
  .s_axi_rdma_send_write_payload_awlen   (axi_rdma_send_write_payload_awlen),
  .s_axi_rdma_send_write_payload_awsize  (axi_rdma_send_write_payload_awsize),
  .s_axi_rdma_send_write_payload_awburst (axi_rdma_send_write_payload_awburst),
  .s_axi_rdma_send_write_payload_awcache (axi_rdma_send_write_payload_awcache),
  .s_axi_rdma_send_write_payload_awprot  (axi_rdma_send_write_payload_awprot),
  .s_axi_rdma_send_write_payload_awvalid (axi_rdma_send_write_payload_awvalid),
  .s_axi_rdma_send_write_payload_awready (axi_rdma_send_write_payload_awready),
  .s_axi_rdma_send_write_payload_wdata   (axi_rdma_send_write_payload_wdata),
  .s_axi_rdma_send_write_payload_wstrb   (axi_rdma_send_write_payload_wstrb),
  .s_axi_rdma_send_write_payload_wlast   (axi_rdma_send_write_payload_wlast),
  .s_axi_rdma_send_write_payload_wvalid  (axi_rdma_send_write_payload_wvalid),
  .s_axi_rdma_send_write_payload_wready  (axi_rdma_send_write_payload_wready),    
  .s_axi_rdma_send_write_payload_awlock  (axi_rdma_send_write_payload_awlock),
  .s_axi_rdma_send_write_payload_bid     (axi_rdma_send_write_payload_bid),
  .s_axi_rdma_send_write_payload_bresp   (axi_rdma_send_write_payload_bresp),
  .s_axi_rdma_send_write_payload_bvalid  (axi_rdma_send_write_payload_bvalid),
  .s_axi_rdma_send_write_payload_bready  (axi_rdma_send_write_payload_bready),
  .s_axi_rdma_send_write_payload_arid    (axi_rdma_send_write_payload_arid),
  .s_axi_rdma_send_write_payload_araddr  (axi_rdma_send_write_payload_araddr),
  .s_axi_rdma_send_write_payload_arlen   (axi_rdma_send_write_payload_arlen),
  .s_axi_rdma_send_write_payload_arsize  (axi_rdma_send_write_payload_arsize),
  .s_axi_rdma_send_write_payload_arburst (axi_rdma_send_write_payload_arburst),
  .s_axi_rdma_send_write_payload_arcache (axi_rdma_send_write_payload_arcache),
  .s_axi_rdma_send_write_payload_arprot  (axi_rdma_send_write_payload_arprot),
  .s_axi_rdma_send_write_payload_arvalid (axi_rdma_send_write_payload_arvalid),
  .s_axi_rdma_send_write_payload_arready (axi_rdma_send_write_payload_arready),
  .s_axi_rdma_send_write_payload_rid     (axi_rdma_send_write_payload_rid),
  .s_axi_rdma_send_write_payload_rdata   (axi_rdma_send_write_payload_rdata),
  .s_axi_rdma_send_write_payload_rresp   (axi_rdma_send_write_payload_rresp),
  .s_axi_rdma_send_write_payload_rlast   (axi_rdma_send_write_payload_rlast),
  .s_axi_rdma_send_write_payload_rvalid  (axi_rdma_send_write_payload_rvalid),
  .s_axi_rdma_send_write_payload_rready  (axi_rdma_send_write_payload_rready),
  .s_axi_rdma_send_write_payload_arlock  (axi_rdma_send_write_payload_arlock),
  .s_axi_rdma_send_write_payload_arqos   (axi_rdma_send_write_payload_arqos),

  .s_axi_rdma_rsp_payload_awid           (axi_rdma_rsp_payload_awid),
  .s_axi_rdma_rsp_payload_awaddr         (axi_rdma_rsp_payload_awaddr),
  .s_axi_rdma_rsp_payload_awqos          (axi_rdma_rsp_payload_awqos),
  .s_axi_rdma_rsp_payload_awlen          (axi_rdma_rsp_payload_awlen),
  .s_axi_rdma_rsp_payload_awsize         (axi_rdma_rsp_payload_awsize),
  .s_axi_rdma_rsp_payload_awburst        (axi_rdma_rsp_payload_awburst),
  .s_axi_rdma_rsp_payload_awcache        (axi_rdma_rsp_payload_awcache),
  .s_axi_rdma_rsp_payload_awprot         (axi_rdma_rsp_payload_awprot),
  .s_axi_rdma_rsp_payload_awvalid        (axi_rdma_rsp_payload_awvalid),
  .s_axi_rdma_rsp_payload_awready        (axi_rdma_rsp_payload_awready),
  .s_axi_rdma_rsp_payload_wdata          (axi_rdma_rsp_payload_wdata),
  .s_axi_rdma_rsp_payload_wstrb          (axi_rdma_rsp_payload_wstrb),
  .s_axi_rdma_rsp_payload_wlast          (axi_rdma_rsp_payload_wlast),
  .s_axi_rdma_rsp_payload_wvalid         (axi_rdma_rsp_payload_wvalid),
  .s_axi_rdma_rsp_payload_wready         (axi_rdma_rsp_payload_wready),
  .s_axi_rdma_rsp_payload_awlock         (axi_rdma_rsp_payload_awlock),
  .s_axi_rdma_rsp_payload_bid            (axi_rdma_rsp_payload_bid),
  .s_axi_rdma_rsp_payload_bresp          (axi_rdma_rsp_payload_bresp),
  .s_axi_rdma_rsp_payload_bvalid         (axi_rdma_rsp_payload_bvalid),
  .s_axi_rdma_rsp_payload_bready         (axi_rdma_rsp_payload_bready),
  .s_axi_rdma_rsp_payload_arid           (axi_rdma_rsp_payload_arid),
  .s_axi_rdma_rsp_payload_araddr         (axi_rdma_rsp_payload_araddr),
  .s_axi_rdma_rsp_payload_arlen          (axi_rdma_rsp_payload_arlen),
  .s_axi_rdma_rsp_payload_arsize         (axi_rdma_rsp_payload_arsize),
  .s_axi_rdma_rsp_payload_arburst        (axi_rdma_rsp_payload_arburst),
  .s_axi_rdma_rsp_payload_arcache        (axi_rdma_rsp_payload_arcache),
  .s_axi_rdma_rsp_payload_arprot         (axi_rdma_rsp_payload_arprot),
  .s_axi_rdma_rsp_payload_arvalid        (axi_rdma_rsp_payload_arvalid),
  .s_axi_rdma_rsp_payload_arready        (axi_rdma_rsp_payload_arready),
  .s_axi_rdma_rsp_payload_rid            (axi_rdma_rsp_payload_rid),
  .s_axi_rdma_rsp_payload_rdata          (axi_rdma_rsp_payload_rdata),
  .s_axi_rdma_rsp_payload_rresp          (axi_rdma_rsp_payload_rresp),
  .s_axi_rdma_rsp_payload_rlast          (axi_rdma_rsp_payload_rlast),
  .s_axi_rdma_rsp_payload_rvalid         (axi_rdma_rsp_payload_rvalid),
  .s_axi_rdma_rsp_payload_rready         (axi_rdma_rsp_payload_rready),
  .s_axi_rdma_rsp_payload_arlock         (axi_rdma_rsp_payload_arlock),
  .s_axi_rdma_rsp_payload_arqos          (axi_rdma_rsp_payload_arqos),

  .s_axi_qdma_mm_awid                    (axi_qdma_mm_awid),
  .s_axi_qdma_mm_awaddr                  (axi_qdma_mm_awaddr),
  .s_axi_qdma_mm_awqos                   (axi_qdma_mm_awqos),
  .s_axi_qdma_mm_awlen                   (axi_qdma_mm_awlen),
  .s_axi_qdma_mm_awsize                  (axi_qdma_mm_awsize),
  .s_axi_qdma_mm_awburst                 (axi_qdma_mm_awburst),
  .s_axi_qdma_mm_awcache                 (axi_qdma_mm_awcache),
  .s_axi_qdma_mm_awprot                  (axi_qdma_mm_awprot),
  .s_axi_qdma_mm_awvalid                 (axi_qdma_mm_awvalid),
  .s_axi_qdma_mm_awready                 (axi_qdma_mm_awready),
  .s_axi_qdma_mm_wdata                   (axi_qdma_mm_wdata),
  .s_axi_qdma_mm_wstrb                   (axi_qdma_mm_wstrb),
  .s_axi_qdma_mm_wlast                   (axi_qdma_mm_wlast),
  .s_axi_qdma_mm_wvalid                  (axi_qdma_mm_wvalid),
  .s_axi_qdma_mm_wready                  (axi_qdma_mm_wready),
  .s_axi_qdma_mm_awlock                  (axi_qdma_mm_awlock),
  .s_axi_qdma_mm_bid                     (axi_qdma_mm_bid),
  .s_axi_qdma_mm_bresp                   (axi_qdma_mm_bresp),
  .s_axi_qdma_mm_bvalid                  (axi_qdma_mm_bvalid),
  .s_axi_qdma_mm_bready                  (axi_qdma_mm_bready),
  .s_axi_qdma_mm_arid                    (axi_qdma_mm_arid),
  .s_axi_qdma_mm_araddr                  (axi_qdma_mm_araddr),
  .s_axi_qdma_mm_arlen                   (axi_qdma_mm_arlen),
  .s_axi_qdma_mm_arsize                  (axi_qdma_mm_arsize),
  .s_axi_qdma_mm_arburst                 (axi_qdma_mm_arburst),
  .s_axi_qdma_mm_arcache                 (axi_qdma_mm_arcache),
  .s_axi_qdma_mm_arprot                  (axi_qdma_mm_arprot),
  .s_axi_qdma_mm_arvalid                 (axi_qdma_mm_arvalid),
  .s_axi_qdma_mm_arready                 (axi_qdma_mm_arready),
  .s_axi_qdma_mm_rid                     (axi_qdma_mm_rid),
  .s_axi_qdma_mm_rdata                   (axi_qdma_mm_rdata),
  .s_axi_qdma_mm_rresp                   (axi_qdma_mm_rresp),
  .s_axi_qdma_mm_rlast                   (axi_qdma_mm_rlast),
  .s_axi_qdma_mm_rvalid                  (axi_qdma_mm_rvalid),
  .s_axi_qdma_mm_rready                  (axi_qdma_mm_rready),
  .s_axi_qdma_mm_arlock                  (axi_qdma_mm_arlock),
  .s_axi_qdma_mm_arqos                   (axi_qdma_mm_arqos),

  .s_axi_compute_logic_awid              (m_axi_init_dev_awid),
  .s_axi_compute_logic_awaddr            (m_axi_init_dev_awaddr),
  .s_axi_compute_logic_awqos             (m_axi_init_dev_awqos),
  .s_axi_compute_logic_awlen             (m_axi_init_dev_awlen),
  .s_axi_compute_logic_awsize            (m_axi_init_dev_awsize),
  .s_axi_compute_logic_awburst           (m_axi_init_dev_awburst),
  .s_axi_compute_logic_awcache           (m_axi_init_dev_awcache),
  .s_axi_compute_logic_awprot            (m_axi_init_dev_awprot),
  .s_axi_compute_logic_awvalid           (m_axi_init_dev_awvalid),
  .s_axi_compute_logic_awready           (m_axi_init_dev_awready),
  .s_axi_compute_logic_wdata             (m_axi_init_dev_wdata),
  .s_axi_compute_logic_wstrb             (m_axi_init_dev_wstrb),
  .s_axi_compute_logic_wlast             (m_axi_init_dev_wlast),
  .s_axi_compute_logic_wvalid            (m_axi_init_dev_wvalid),
  .s_axi_compute_logic_wready            (m_axi_init_dev_wready),
  .s_axi_compute_logic_awlock            (m_axi_init_dev_awlock),
  .s_axi_compute_logic_bid               (m_axi_init_dev_bid),
  .s_axi_compute_logic_bresp             (m_axi_init_dev_bresp),
  .s_axi_compute_logic_bvalid            (m_axi_init_dev_bvalid),
  .s_axi_compute_logic_bready            (m_axi_init_dev_bready),
  .s_axi_compute_logic_arid              (m_axi_veri_dev_arid),
  .s_axi_compute_logic_araddr            (m_axi_veri_dev_araddr),
  .s_axi_compute_logic_arlen             (m_axi_veri_dev_arlen),
  .s_axi_compute_logic_arsize            (m_axi_veri_dev_arsize),
  .s_axi_compute_logic_arburst           (m_axi_veri_dev_arburst),
  .s_axi_compute_logic_arcache           (m_axi_veri_dev_arcache),
  .s_axi_compute_logic_arprot            (m_axi_veri_dev_arprot),
  .s_axi_compute_logic_arvalid           (m_axi_veri_dev_arvalid),
  .s_axi_compute_logic_arready           (m_axi_veri_dev_arready),
  .s_axi_compute_logic_rid               (m_axi_veri_dev_rid),
  .s_axi_compute_logic_rdata             (m_axi_veri_dev_rdata),
  .s_axi_compute_logic_rresp             (m_axi_veri_dev_rresp),
  .s_axi_compute_logic_rlast             (m_axi_veri_dev_rlast),
  .s_axi_compute_logic_rvalid            (m_axi_veri_dev_rvalid),
  .s_axi_compute_logic_rready            (m_axi_veri_dev_rready),
  .s_axi_compute_logic_arlock            (m_axi_veri_dev_arlock),
  .s_axi_compute_logic_arqos             (m_axi_veri_dev_arqos),
/*
  .s_axi_compute_logic_awid              (axi_compute_logic_awid),
  .s_axi_compute_logic_awaddr            (axi_compute_logic_awaddr),
  .s_axi_compute_logic_awqos             (axi_compute_logic_awqos),
  .s_axi_compute_logic_awlen             (axi_compute_logic_awlen),
  .s_axi_compute_logic_awsize            (axi_compute_logic_awsize),
  .s_axi_compute_logic_awburst           (axi_compute_logic_awburst),
  .s_axi_compute_logic_awcache           (axi_compute_logic_awcache),
  .s_axi_compute_logic_awprot            (axi_compute_logic_awprot),
  .s_axi_compute_logic_awvalid           (axi_compute_logic_awvalid),
  .s_axi_compute_logic_awready           (axi_compute_logic_awready),
  .s_axi_compute_logic_wdata             (axi_compute_logic_wdata),
  .s_axi_compute_logic_wstrb             (axi_compute_logic_wstrb),
  .s_axi_compute_logic_wlast             (axi_compute_logic_wlast),
  .s_axi_compute_logic_wvalid            (axi_compute_logic_wvalid),
  .s_axi_compute_logic_wready            (axi_compute_logic_wready),
  .s_axi_compute_logic_awlock            (axi_compute_logic_awlock),
  .s_axi_compute_logic_bid               (axi_compute_logic_bid),
  .s_axi_compute_logic_bresp             (axi_compute_logic_bresp),
  .s_axi_compute_logic_bvalid            (axi_compute_logic_bvalid),
  .s_axi_compute_logic_bready            (axi_compute_logic_bready),
  .s_axi_compute_logic_arid              (axi_compute_logic_arid),
  .s_axi_compute_logic_araddr            (axi_compute_logic_araddr),
  .s_axi_compute_logic_arlen             (axi_compute_logic_arlen),
  .s_axi_compute_logic_arsize            (axi_compute_logic_arsize),
  .s_axi_compute_logic_arburst           (axi_compute_logic_arburst),
  .s_axi_compute_logic_arcache           (axi_compute_logic_arcache),
  .s_axi_compute_logic_arprot            (axi_compute_logic_arprot),
  .s_axi_compute_logic_arvalid           (axi_compute_logic_arvalid),
  .s_axi_compute_logic_arready           (axi_compute_logic_arready),
  .s_axi_compute_logic_rid               (axi_compute_logic_rid),
  .s_axi_compute_logic_rdata             (axi_compute_logic_rdata),
  .s_axi_compute_logic_rresp             (axi_compute_logic_rresp),
  .s_axi_compute_logic_rlast             (axi_compute_logic_rlast),
  .s_axi_compute_logic_rvalid            (axi_compute_logic_rvalid),
  .s_axi_compute_logic_rready            (axi_compute_logic_rready),
  .s_axi_compute_logic_arlock            (axi_compute_logic_arlock),
  .s_axi_compute_logic_arqos             (axi_compute_logic_arqos),
*/

  .m_axi_dev_mem_awaddr                  (axi_dev_mem_awaddr),
  .m_axi_dev_mem_awprot                  (axi_dev_mem_awprot),
  .m_axi_dev_mem_awvalid                 (axi_dev_mem_awvalid),
  .m_axi_dev_mem_awready                 (axi_dev_mem_awready),
  .m_axi_dev_mem_awsize                  (axi_dev_mem_awsize),
  .m_axi_dev_mem_awburst                 (axi_dev_mem_awburst),
  .m_axi_dev_mem_awcache                 (axi_dev_mem_awcache),
  .m_axi_dev_mem_awlen                   (axi_dev_mem_awlen),
  .m_axi_dev_mem_awlock                  (axi_dev_mem_awlock),
  .m_axi_dev_mem_awqos                   (axi_dev_mem_awqos),
  .m_axi_dev_mem_awregion                (axi_dev_mem_awregion),
  .m_axi_dev_mem_awid                    (axi_dev_mem_awid),
  .m_axi_dev_mem_wdata                   (axi_dev_mem_wdata),
  .m_axi_dev_mem_wstrb                   (axi_dev_mem_wstrb),
  .m_axi_dev_mem_wvalid                  (axi_dev_mem_wvalid),
  .m_axi_dev_mem_wready                  (axi_dev_mem_wready),
  .m_axi_dev_mem_wlast                   (axi_dev_mem_wlast),
  .m_axi_dev_mem_bresp                   (axi_dev_mem_bresp),
  .m_axi_dev_mem_bvalid                  (axi_dev_mem_bvalid),
  .m_axi_dev_mem_bready                  (axi_dev_mem_bready),
  .m_axi_dev_mem_bid                     (axi_dev_mem_bid),
  .m_axi_dev_mem_araddr                  (axi_dev_mem_araddr),
  .m_axi_dev_mem_arprot                  (axi_dev_mem_arprot),
  .m_axi_dev_mem_arvalid                 (axi_dev_mem_arvalid),
  .m_axi_dev_mem_arready                 (axi_dev_mem_arready),
  .m_axi_dev_mem_arsize                  (axi_dev_mem_arsize),
  .m_axi_dev_mem_arburst                 (axi_dev_mem_arburst),
  .m_axi_dev_mem_arcache                 (axi_dev_mem_arcache),
  .m_axi_dev_mem_arlock                  (axi_dev_mem_arlock),
  .m_axi_dev_mem_arlen                   (axi_dev_mem_arlen),
  .m_axi_dev_mem_arqos                   (axi_dev_mem_arqos),
  .m_axi_dev_mem_arregion                (axi_dev_mem_arregion),
  .m_axi_dev_mem_arid                    (axi_dev_mem_arid),
  .m_axi_dev_mem_rdata                   (axi_dev_mem_rdata),
  .m_axi_dev_mem_rresp                   (axi_dev_mem_rresp),
  .m_axi_dev_mem_rvalid                  (axi_dev_mem_rvalid),
  .m_axi_dev_mem_rready                  (axi_dev_mem_rready),
  .m_axi_dev_mem_rlast                   (axi_dev_mem_rlast),
  .m_axi_dev_mem_rid                     (axi_dev_mem_rid), 

  .axis_aclk   (axis_clk),
  .axis_arestn (axis_rstn)   
);

// AXI crossbar used to access system memory (used dev_memory crossbar for initialization/debug)
axi_interconnect_to_dev_mem axi_interconnect_to_sys_mem_inst(
  .s_axi_rdma_send_write_payload_awid    (axi_rdma_get_wqe_awid),
  .s_axi_rdma_send_write_payload_awaddr  (axi_rdma_get_wqe_awaddr),
  .s_axi_rdma_send_write_payload_awqos   (axi_rdma_get_wqe_awqos),
  .s_axi_rdma_send_write_payload_awlen   (axi_rdma_get_wqe_awlen),
  .s_axi_rdma_send_write_payload_awsize  (axi_rdma_get_wqe_awsize),
  .s_axi_rdma_send_write_payload_awburst (axi_rdma_get_wqe_awburst),
  .s_axi_rdma_send_write_payload_awcache (axi_rdma_get_wqe_awcache),
  .s_axi_rdma_send_write_payload_awprot  (axi_rdma_get_wqe_awprot),
  .s_axi_rdma_send_write_payload_awvalid (axi_rdma_get_wqe_awvalid),
  .s_axi_rdma_send_write_payload_awready (axi_rdma_get_wqe_awready),
  .s_axi_rdma_send_write_payload_wdata   (axi_rdma_get_wqe_wdata),
  .s_axi_rdma_send_write_payload_wstrb   (axi_rdma_get_wqe_wstrb),
  .s_axi_rdma_send_write_payload_wlast   (axi_rdma_get_wqe_wlast),
  .s_axi_rdma_send_write_payload_wvalid  (axi_rdma_get_wqe_wvalid),
  .s_axi_rdma_send_write_payload_wready  (axi_rdma_get_wqe_wready),    
  .s_axi_rdma_send_write_payload_awlock  (axi_rdma_get_wqe_awlock),

  .s_axi_rdma_send_write_payload_bid     (axi_rdma_get_wqe_bid),
  .s_axi_rdma_send_write_payload_bresp   (axi_rdma_get_wqe_bresp),
  .s_axi_rdma_send_write_payload_bvalid  (axi_rdma_get_wqe_bvalid),
  .s_axi_rdma_send_write_payload_bready  (axi_rdma_get_wqe_bready),
  .s_axi_rdma_send_write_payload_arid    (axi_rdma_get_wqe_arid),
  .s_axi_rdma_send_write_payload_araddr  (axi_rdma_get_wqe_araddr),
  .s_axi_rdma_send_write_payload_arlen   (axi_rdma_get_wqe_arlen),
  .s_axi_rdma_send_write_payload_arsize  (axi_rdma_get_wqe_arsize),
  .s_axi_rdma_send_write_payload_arburst (axi_rdma_get_wqe_arburst),
  .s_axi_rdma_send_write_payload_arcache (axi_rdma_get_wqe_arcache),
  .s_axi_rdma_send_write_payload_arprot  (axi_rdma_get_wqe_arprot),
  .s_axi_rdma_send_write_payload_arvalid (axi_rdma_get_wqe_arvalid),
  .s_axi_rdma_send_write_payload_arready (axi_rdma_get_wqe_arready),
  .s_axi_rdma_send_write_payload_rid     (axi_rdma_get_wqe_rid),
  .s_axi_rdma_send_write_payload_rdata   (axi_rdma_get_wqe_rdata),
  .s_axi_rdma_send_write_payload_rresp   (axi_rdma_get_wqe_rresp),
  .s_axi_rdma_send_write_payload_rlast   (axi_rdma_get_wqe_rlast),
  .s_axi_rdma_send_write_payload_rvalid  (axi_rdma_get_wqe_rvalid),
  .s_axi_rdma_send_write_payload_rready  (axi_rdma_get_wqe_rready),
  .s_axi_rdma_send_write_payload_arlock  (axi_rdma_get_wqe_arlock),
  .s_axi_rdma_send_write_payload_arqos   (axi_rdma_get_wqe_arqos),

  .s_axi_rdma_rsp_payload_awid           (axi_rdma_get_payload_awid),
  .s_axi_rdma_rsp_payload_awaddr         (axi_rdma_get_payload_awaddr),
  .s_axi_rdma_rsp_payload_awqos          (axi_rdma_get_payload_awqos),
  .s_axi_rdma_rsp_payload_awlen          (axi_rdma_get_payload_awlen),
  .s_axi_rdma_rsp_payload_awsize         (axi_rdma_get_payload_awsize),
  .s_axi_rdma_rsp_payload_awburst        (axi_rdma_get_payload_awburst),
  .s_axi_rdma_rsp_payload_awcache        (axi_rdma_get_payload_awcache),
  .s_axi_rdma_rsp_payload_awprot         (axi_rdma_get_payload_awprot),
  .s_axi_rdma_rsp_payload_awvalid        (axi_rdma_get_payload_awvalid),
  .s_axi_rdma_rsp_payload_awready        (axi_rdma_get_payload_awready),
  .s_axi_rdma_rsp_payload_wdata          (axi_rdma_get_payload_wdata),
  .s_axi_rdma_rsp_payload_wstrb          (axi_rdma_get_payload_wstrb),
  .s_axi_rdma_rsp_payload_wlast          (axi_rdma_get_payload_wlast),
  .s_axi_rdma_rsp_payload_wvalid         (axi_rdma_get_payload_wvalid),
  .s_axi_rdma_rsp_payload_wready         (axi_rdma_get_payload_wready),
  .s_axi_rdma_rsp_payload_awlock         (axi_rdma_get_payload_awlock),
  .s_axi_rdma_rsp_payload_bid            (axi_rdma_get_payload_bid),
  .s_axi_rdma_rsp_payload_bresp          (axi_rdma_get_payload_bresp),
  .s_axi_rdma_rsp_payload_bvalid         (axi_rdma_get_payload_bvalid),
  .s_axi_rdma_rsp_payload_bready         (axi_rdma_get_payload_bready),
  .s_axi_rdma_rsp_payload_arid           (axi_rdma_get_payload_arid),
  .s_axi_rdma_rsp_payload_araddr         (axi_rdma_get_payload_araddr),
  .s_axi_rdma_rsp_payload_arlen          (axi_rdma_get_payload_arlen),
  .s_axi_rdma_rsp_payload_arsize         (axi_rdma_get_payload_arsize),
  .s_axi_rdma_rsp_payload_arburst        (axi_rdma_get_payload_arburst),
  .s_axi_rdma_rsp_payload_arcache        (axi_rdma_get_payload_arcache),
  .s_axi_rdma_rsp_payload_arprot         (axi_rdma_get_payload_arprot),
  .s_axi_rdma_rsp_payload_arvalid        (axi_rdma_get_payload_arvalid),
  .s_axi_rdma_rsp_payload_arready        (axi_rdma_get_payload_arready),
  .s_axi_rdma_rsp_payload_rid            (axi_rdma_get_payload_rid),
  .s_axi_rdma_rsp_payload_rdata          (axi_rdma_get_payload_rdata),
  .s_axi_rdma_rsp_payload_rresp          (axi_rdma_get_payload_rresp),
  .s_axi_rdma_rsp_payload_rlast          (axi_rdma_get_payload_rlast),
  .s_axi_rdma_rsp_payload_rvalid         (axi_rdma_get_payload_rvalid),
  .s_axi_rdma_rsp_payload_rready         (axi_rdma_get_payload_rready),
  .s_axi_rdma_rsp_payload_arlock         (axi_rdma_get_payload_arlock),
  .s_axi_rdma_rsp_payload_arqos          (axi_rdma_get_payload_arqos),

  //.s_axi_qdma_mm_awid                    (axi_rdma_completion_awid),
  .s_axi_qdma_mm_awid                    (0),
  .s_axi_qdma_mm_awaddr                  (axi_rdma_completion_awaddr),
  .s_axi_qdma_mm_awqos                   (axi_rdma_completion_awqos),
  .s_axi_qdma_mm_awlen                   (axi_rdma_completion_awlen),
  .s_axi_qdma_mm_awsize                  (axi_rdma_completion_awsize),
  .s_axi_qdma_mm_awburst                 (axi_rdma_completion_awburst),
  .s_axi_qdma_mm_awcache                 (axi_rdma_completion_awcache),
  .s_axi_qdma_mm_awprot                  (axi_rdma_completion_awprot),
  .s_axi_qdma_mm_awvalid                 (axi_rdma_completion_awvalid),
  .s_axi_qdma_mm_awready                 (axi_rdma_completion_awready),
  .s_axi_qdma_mm_wdata                   (axi_rdma_completion_wdata),
  .s_axi_qdma_mm_wstrb                   (axi_rdma_completion_wstrb),
  .s_axi_qdma_mm_wlast                   (axi_rdma_completion_wlast),
  .s_axi_qdma_mm_wvalid                  (axi_rdma_completion_wvalid),
  .s_axi_qdma_mm_wready                  (axi_rdma_completion_wready),
  .s_axi_qdma_mm_awlock                  (axi_rdma_completion_awlock),
  .s_axi_qdma_mm_bid                     (axi_rdma_completion_bid),
  .s_axi_qdma_mm_bresp                   (axi_rdma_completion_bresp),
  .s_axi_qdma_mm_bvalid                  (axi_rdma_completion_bvalid),
  .s_axi_qdma_mm_bready                  (axi_rdma_completion_bready),
  //.s_axi_qdma_mm_arid                    (axi_rdma_completion_arid),
  .s_axi_qdma_mm_arid                    (0),
  .s_axi_qdma_mm_araddr                  (axi_rdma_completion_araddr),
  .s_axi_qdma_mm_arlen                   (axi_rdma_completion_arlen),
  .s_axi_qdma_mm_arsize                  (axi_rdma_completion_arsize),
  .s_axi_qdma_mm_arburst                 (axi_rdma_completion_arburst),
  .s_axi_qdma_mm_arcache                 (axi_rdma_completion_arcache),
  .s_axi_qdma_mm_arprot                  (axi_rdma_completion_arprot),
  .s_axi_qdma_mm_arvalid                 (axi_rdma_completion_arvalid),
  .s_axi_qdma_mm_arready                 (axi_rdma_completion_arready),
  .s_axi_qdma_mm_rid                     (axi_rdma_completion_rid),
  .s_axi_qdma_mm_rdata                   (axi_rdma_completion_rdata),
  .s_axi_qdma_mm_rresp                   (axi_rdma_completion_rresp),
  .s_axi_qdma_mm_rlast                   (axi_rdma_completion_rlast),
  .s_axi_qdma_mm_rvalid                  (axi_rdma_completion_rvalid),
  .s_axi_qdma_mm_rready                  (axi_rdma_completion_rready),
  .s_axi_qdma_mm_arlock                  (axi_rdma_completion_arlock),
  .s_axi_qdma_mm_arqos                   (axi_rdma_completion_arqos),

  .s_axi_compute_logic_awid              (m_axi_init_sys_awid),
  .s_axi_compute_logic_awaddr            (m_axi_init_sys_awaddr),
  .s_axi_compute_logic_awqos             (m_axi_init_sys_awqos),
  .s_axi_compute_logic_awlen             (m_axi_init_sys_awlen),
  .s_axi_compute_logic_awsize            (m_axi_init_sys_awsize),
  .s_axi_compute_logic_awburst           (m_axi_init_sys_awburst),
  .s_axi_compute_logic_awcache           (m_axi_init_sys_awcache),
  .s_axi_compute_logic_awprot            (m_axi_init_sys_awprot),
  .s_axi_compute_logic_awvalid           (m_axi_init_sys_awvalid),
  .s_axi_compute_logic_awready           (m_axi_init_sys_awready),
  .s_axi_compute_logic_wdata             (m_axi_init_sys_wdata),
  .s_axi_compute_logic_wstrb             (m_axi_init_sys_wstrb),
  .s_axi_compute_logic_wlast             (m_axi_init_sys_wlast),
  .s_axi_compute_logic_wvalid            (m_axi_init_sys_wvalid),
  .s_axi_compute_logic_wready            (m_axi_init_sys_wready),
  .s_axi_compute_logic_awlock            (m_axi_init_sys_awlock),
  .s_axi_compute_logic_bid               (m_axi_init_sys_bid),
  .s_axi_compute_logic_bresp             (m_axi_init_sys_bresp),
  .s_axi_compute_logic_bvalid            (m_axi_init_sys_bvalid),
  .s_axi_compute_logic_bready            (m_axi_init_sys_bready),
  .s_axi_compute_logic_arid              (m_axi_veri_sys_arid),
  .s_axi_compute_logic_araddr            (m_axi_veri_sys_araddr),
  .s_axi_compute_logic_arlen             (m_axi_veri_sys_arlen),
  .s_axi_compute_logic_arsize            (m_axi_veri_sys_arsize),
  .s_axi_compute_logic_arburst           (m_axi_veri_sys_arburst),
  .s_axi_compute_logic_arcache           (m_axi_veri_sys_arcache),
  .s_axi_compute_logic_arprot            (m_axi_veri_sys_arprot),
  .s_axi_compute_logic_arvalid           (m_axi_veri_sys_arvalid),
  .s_axi_compute_logic_arready           (m_axi_veri_sys_arready),
  .s_axi_compute_logic_rid               (m_axi_veri_sys_rid),
  .s_axi_compute_logic_rdata             (m_axi_veri_sys_rdata),
  .s_axi_compute_logic_rresp             (m_axi_veri_sys_rresp),
  .s_axi_compute_logic_rlast             (m_axi_veri_sys_rlast),
  .s_axi_compute_logic_rvalid            (m_axi_veri_sys_rvalid),
  .s_axi_compute_logic_rready            (m_axi_veri_sys_rready),
  .s_axi_compute_logic_arlock            (m_axi_veri_sys_arlock),
  .s_axi_compute_logic_arqos             (m_axi_veri_sys_arqos),

  .m_axi_dev_mem_awaddr                  (axi_sys_mem_awaddr),
  .m_axi_dev_mem_awprot                  (axi_sys_mem_awprot),
  .m_axi_dev_mem_awvalid                 (axi_sys_mem_awvalid),
  .m_axi_dev_mem_awready                 (axi_sys_mem_awready),
  .m_axi_dev_mem_awsize                  (axi_sys_mem_awsize),
  .m_axi_dev_mem_awburst                 (axi_sys_mem_awburst),
  .m_axi_dev_mem_awcache                 (axi_sys_mem_awcache),
  .m_axi_dev_mem_awlen                   (axi_sys_mem_awlen),
  .m_axi_dev_mem_awlock                  (axi_sys_mem_awlock),
  .m_axi_dev_mem_awqos                   (axi_sys_mem_awqos),
  .m_axi_dev_mem_awregion                (axi_sys_mem_awregion),
  .m_axi_dev_mem_awid                    (axi_sys_mem_awid),
  .m_axi_dev_mem_wdata                   (axi_sys_mem_wdata),
  .m_axi_dev_mem_wstrb                   (axi_sys_mem_wstrb),
  .m_axi_dev_mem_wvalid                  (axi_sys_mem_wvalid),
  .m_axi_dev_mem_wready                  (axi_sys_mem_wready),
  .m_axi_dev_mem_wlast                   (axi_sys_mem_wlast),
  .m_axi_dev_mem_bresp                   (axi_sys_mem_bresp),
  .m_axi_dev_mem_bvalid                  (axi_sys_mem_bvalid),
  .m_axi_dev_mem_bready                  (axi_sys_mem_bready),
  .m_axi_dev_mem_bid                     (axi_sys_mem_bid),
  .m_axi_dev_mem_araddr                  (axi_sys_mem_araddr),
  .m_axi_dev_mem_arprot                  (axi_sys_mem_arprot),
  .m_axi_dev_mem_arvalid                 (axi_sys_mem_arvalid),
  .m_axi_dev_mem_arready                 (axi_sys_mem_arready),
  .m_axi_dev_mem_arsize                  (axi_sys_mem_arsize),
  .m_axi_dev_mem_arburst                 (axi_sys_mem_arburst),
  .m_axi_dev_mem_arcache                 (axi_sys_mem_arcache),
  .m_axi_dev_mem_arlock                  (axi_sys_mem_arlock),
  .m_axi_dev_mem_arlen                   (axi_sys_mem_arlen),
  .m_axi_dev_mem_arqos                   (axi_sys_mem_arqos),
  .m_axi_dev_mem_arregion                (axi_sys_mem_arregion),
  .m_axi_dev_mem_arid                    (axi_sys_mem_arid),
  .m_axi_dev_mem_rdata                   (axi_sys_mem_rdata),
  .m_axi_dev_mem_rresp                   (axi_sys_mem_rresp),
  .m_axi_dev_mem_rvalid                  (axi_sys_mem_rvalid),
  .m_axi_dev_mem_rready                  (axi_sys_mem_rready),
  .m_axi_dev_mem_rlast                   (axi_sys_mem_rlast),
  .m_axi_dev_mem_rid                     (axi_sys_mem_rid), 

  .axis_aclk   (axis_clk),
  .axis_arestn (axis_rstn)   
);
/*
axi_interconnect_to_sys_mem axi_interconnect_to_sys_mem_inst(
  .s_axi_rdma_get_wqe_awid        (axi_rdma_get_wqe_awid),
  .s_axi_rdma_get_wqe_awaddr      (axi_rdma_get_wqe_awaddr),
  .s_axi_rdma_get_wqe_awqos       (axi_rdma_get_wqe_awqos),
  .s_axi_rdma_get_wqe_awlen       (axi_rdma_get_wqe_awlen),
  .s_axi_rdma_get_wqe_awsize      (axi_rdma_get_wqe_awsize),
  .s_axi_rdma_get_wqe_awburst     (axi_rdma_get_wqe_awburst),
  .s_axi_rdma_get_wqe_awcache     (axi_rdma_get_wqe_awcache),
  .s_axi_rdma_get_wqe_awprot      (axi_rdma_get_wqe_awprot),
  .s_axi_rdma_get_wqe_awvalid     (axi_rdma_get_wqe_awvalid),
  .s_axi_rdma_get_wqe_awready     (axi_rdma_get_wqe_awready),
  .s_axi_rdma_get_wqe_wdata       (axi_rdma_get_wqe_wdata),
  .s_axi_rdma_get_wqe_wstrb       (axi_rdma_get_wqe_wstrb),
  .s_axi_rdma_get_wqe_wlast       (axi_rdma_get_wqe_wlast),
  .s_axi_rdma_get_wqe_wvalid      (axi_rdma_get_wqe_wvalid),
  .s_axi_rdma_get_wqe_wready      (axi_rdma_get_wqe_wready),    
  .s_axi_rdma_get_wqe_awlock      (axi_rdma_get_wqe_awlock),
  .s_axi_rdma_get_wqe_bid         (axi_rdma_get_wqe_bid),
  .s_axi_rdma_get_wqe_bresp       (axi_rdma_get_wqe_bresp),
  .s_axi_rdma_get_wqe_bvalid      (axi_rdma_get_wqe_bvalid),
  .s_axi_rdma_get_wqe_bready      (axi_rdma_get_wqe_bready),
  .s_axi_rdma_get_wqe_arid        (axi_rdma_get_wqe_arid),
  .s_axi_rdma_get_wqe_araddr      (axi_rdma_get_wqe_araddr),
  .s_axi_rdma_get_wqe_arlen       (axi_rdma_get_wqe_arlen),
  .s_axi_rdma_get_wqe_arsize      (axi_rdma_get_wqe_arsize),
  .s_axi_rdma_get_wqe_arburst     (axi_rdma_get_wqe_arburst),
  .s_axi_rdma_get_wqe_arcache     (axi_rdma_get_wqe_arcache),
  .s_axi_rdma_get_wqe_arprot      (axi_rdma_get_wqe_arprot),
  .s_axi_rdma_get_wqe_arvalid     (axi_rdma_get_wqe_arvalid),
  .s_axi_rdma_get_wqe_arready     (axi_rdma_get_wqe_arready),
  .s_axi_rdma_get_wqe_rid         (axi_rdma_get_wqe_rid),
  .s_axi_rdma_get_wqe_rdata       (axi_rdma_get_wqe_rdata),
  .s_axi_rdma_get_wqe_rresp       (axi_rdma_get_wqe_rresp),
  .s_axi_rdma_get_wqe_rlast       (axi_rdma_get_wqe_rlast),
  .s_axi_rdma_get_wqe_rvalid      (axi_rdma_get_wqe_rvalid),
  .s_axi_rdma_get_wqe_rready      (axi_rdma_get_wqe_rready),
  .s_axi_rdma_get_wqe_arlock      (axi_rdma_get_wqe_arlock),
  .s_axi_rdma_get_wqe_arqos       (axi_rdma_get_wqe_arqos),

  .s_axi_rdma_get_payload_awid    (axi_rdma_get_payload_awid),
  .s_axi_rdma_get_payload_awaddr  (axi_rdma_get_payload_awaddr),
  .s_axi_rdma_get_payload_awqos   (axi_rdma_get_payload_awqos),
  .s_axi_rdma_get_payload_awlen   (axi_rdma_get_payload_awlen),
  .s_axi_rdma_get_payload_awsize  (axi_rdma_get_payload_awsize),
  .s_axi_rdma_get_payload_awburst (axi_rdma_get_payload_awburst),
  .s_axi_rdma_get_payload_awcache (axi_rdma_get_payload_awcache),
  .s_axi_rdma_get_payload_awprot  (axi_rdma_get_payload_awprot),
  .s_axi_rdma_get_payload_awvalid (axi_rdma_get_payload_awvalid),
  .s_axi_rdma_get_payload_awready (axi_rdma_get_payload_awready),
  .s_axi_rdma_get_payload_wdata   (axi_rdma_get_payload_wdata),
  .s_axi_rdma_get_payload_wstrb   (axi_rdma_get_payload_wstrb),
  .s_axi_rdma_get_payload_wlast   (axi_rdma_get_payload_wlast),
  .s_axi_rdma_get_payload_wvalid  (axi_rdma_get_payload_wvalid),
  .s_axi_rdma_get_payload_wready  (axi_rdma_get_payload_wready),
  .s_axi_rdma_get_payload_awlock  (axi_rdma_get_payload_awlock),
  .s_axi_rdma_get_payload_bid     (axi_rdma_get_payload_bid),
  .s_axi_rdma_get_payload_bresp   (axi_rdma_get_payload_bresp),
  .s_axi_rdma_get_payload_bvalid  (axi_rdma_get_payload_bvalid),
  .s_axi_rdma_get_payload_bready  (axi_rdma_get_payload_bready),
  .s_axi_rdma_get_payload_arid    (axi_rdma_get_payload_arid),
  .s_axi_rdma_get_payload_araddr  (axi_rdma_get_payload_araddr),
  .s_axi_rdma_get_payload_arlen   (axi_rdma_get_payload_arlen),
  .s_axi_rdma_get_payload_arsize  (axi_rdma_get_payload_arsize),
  .s_axi_rdma_get_payload_arburst (axi_rdma_get_payload_arburst),
  .s_axi_rdma_get_payload_arcache (axi_rdma_get_payload_arcache),
  .s_axi_rdma_get_payload_arprot  (axi_rdma_get_payload_arprot),
  .s_axi_rdma_get_payload_arvalid (axi_rdma_get_payload_arvalid),
  .s_axi_rdma_get_payload_arready (axi_rdma_get_payload_arready),
  .s_axi_rdma_get_payload_rid     (axi_rdma_get_payload_rid),
  .s_axi_rdma_get_payload_rdata   (axi_rdma_get_payload_rdata),
  .s_axi_rdma_get_payload_rresp   (axi_rdma_get_payload_rresp),
  .s_axi_rdma_get_payload_rlast   (axi_rdma_get_payload_rlast),
  .s_axi_rdma_get_payload_rvalid  (axi_rdma_get_payload_rvalid),
  .s_axi_rdma_get_payload_rready  (axi_rdma_get_payload_rready),
  .s_axi_rdma_get_payload_arlock  (axi_rdma_get_payload_arlock),
  .s_axi_rdma_get_payload_arqos   (axi_rdma_get_payload_arqos),

  .s_axi_rdma_completion_awid     (axi_rdma_completion_awid),
  .s_axi_rdma_completion_awaddr   (axi_rdma_completion_awaddr),
  .s_axi_rdma_completion_awqos    (axi_rdma_completion_awqos),
  .s_axi_rdma_completion_awlen    (axi_rdma_completion_awlen),
  .s_axi_rdma_completion_awsize   (axi_rdma_completion_awsize),
  .s_axi_rdma_completion_awburst  (axi_rdma_completion_awburst),
  .s_axi_rdma_completion_awcache  (axi_rdma_completion_awcache),
  .s_axi_rdma_completion_awprot   (axi_rdma_completion_awprot),
  .s_axi_rdma_completion_awvalid  (axi_rdma_completion_awvalid),
  .s_axi_rdma_completion_awready  (axi_rdma_completion_awready),
  .s_axi_rdma_completion_wdata    (axi_rdma_completion_wdata),
  .s_axi_rdma_completion_wstrb    (axi_rdma_completion_wstrb),
  .s_axi_rdma_completion_wlast    (axi_rdma_completion_wlast),
  .s_axi_rdma_completion_wvalid   (axi_rdma_completion_wvalid),
  .s_axi_rdma_completion_wready   (axi_rdma_completion_wready),
  .s_axi_rdma_completion_awlock   (axi_rdma_completion_awlock),
  .s_axi_rdma_completion_bid      (axi_rdma_completion_bid),
  .s_axi_rdma_completion_bresp    (axi_rdma_completion_bresp),
  .s_axi_rdma_completion_bvalid   (axi_rdma_completion_bvalid),
  .s_axi_rdma_completion_bready   (axi_rdma_completion_bready),
  .s_axi_rdma_completion_arid     (axi_rdma_completion_arid),
  .s_axi_rdma_completion_araddr   (axi_rdma_completion_araddr),
  .s_axi_rdma_completion_arlen    (axi_rdma_completion_arlen),
  .s_axi_rdma_completion_arsize   (axi_rdma_completion_arsize),
  .s_axi_rdma_completion_arburst  (axi_rdma_completion_arburst),
  .s_axi_rdma_completion_arcache  (axi_rdma_completion_arcache),
  .s_axi_rdma_completion_arprot   (axi_rdma_completion_arprot),
  .s_axi_rdma_completion_arvalid  (axi_rdma_completion_arvalid),
  .s_axi_rdma_completion_arready  (axi_rdma_completion_arready),
  .s_axi_rdma_completion_rid      (axi_rdma_completion_rid),
  .s_axi_rdma_completion_rdata    (axi_rdma_completion_rdata),
  .s_axi_rdma_completion_rresp    (axi_rdma_completion_rresp),
  .s_axi_rdma_completion_rlast    (axi_rdma_completion_rlast),
  .s_axi_rdma_completion_rvalid   (axi_rdma_completion_rvalid),
  .s_axi_rdma_completion_rready   (axi_rdma_completion_rready),
  .s_axi_rdma_completion_arlock   (axi_rdma_completion_arlock),
  .s_axi_rdma_completion_arqos    (axi_rdma_completion_arqos),

  .m_axi_sys_mem_awaddr           (axi_sys_mem_awaddr),
  .m_axi_sys_mem_awprot           (axi_sys_mem_awprot),
  .m_axi_sys_mem_awvalid          (axi_sys_mem_awvalid),
  .m_axi_sys_mem_awready          (axi_sys_mem_awready),
  .m_axi_sys_mem_awsize           (axi_sys_mem_awsize),
  .m_axi_sys_mem_awburst          (axi_sys_mem_awburst),
  .m_axi_sys_mem_awcache          (axi_sys_mem_awcache),
  .m_axi_sys_mem_awlen            (axi_sys_mem_awlen),
  .m_axi_sys_mem_awlock           (axi_sys_mem_awlock),
  .m_axi_sys_mem_awqos            (axi_sys_mem_awqos),
  .m_axi_sys_mem_awregion         (axi_sys_mem_awregion),
  .m_axi_sys_mem_awid             (axi_sys_mem_awid),
  .m_axi_sys_mem_wdata            (axi_sys_mem_wdata),
  .m_axi_sys_mem_wstrb            (axi_sys_mem_wstrb),
  .m_axi_sys_mem_wvalid           (axi_sys_mem_wvalid),
  .m_axi_sys_mem_wready           (axi_sys_mem_wready),
  .m_axi_sys_mem_wlast            (axi_sys_mem_wlast),
  .m_axi_sys_mem_bresp            (axi_sys_mem_bresp),
  .m_axi_sys_mem_bvalid           (axi_sys_mem_bvalid),
  .m_axi_sys_mem_bready           (axi_sys_mem_bready),
  .m_axi_sys_mem_bid              (axi_sys_mem_bid),
  .m_axi_sys_mem_araddr           (axi_sys_mem_araddr),
  .m_axi_sys_mem_arprot           (axi_sys_mem_arprot),
  .m_axi_sys_mem_arvalid          (axi_sys_mem_arvalid),
  .m_axi_sys_mem_arready          (axi_sys_mem_arready),
  .m_axi_sys_mem_arsize           (axi_sys_mem_arsize),
  .m_axi_sys_mem_arburst          (axi_sys_mem_arburst),
  .m_axi_sys_mem_arcache          (axi_sys_mem_arcache),
  .m_axi_sys_mem_arlock           (axi_sys_mem_arlock),
  .m_axi_sys_mem_arlen            (axi_sys_mem_arlen),
  .m_axi_sys_mem_arqos            (axi_sys_mem_arqos),
  .m_axi_sys_mem_arregion         (axi_sys_mem_arregion),
  .m_axi_sys_mem_arid             (axi_sys_mem_arid),
  .m_axi_sys_mem_rdata            (axi_sys_mem_rdata),
  .m_axi_sys_mem_rresp            (axi_sys_mem_rresp),
  .m_axi_sys_mem_rvalid           (axi_sys_mem_rvalid),
  .m_axi_sys_mem_rready           (axi_sys_mem_rready),
  .m_axi_sys_mem_rlast            (axi_sys_mem_rlast),
  .m_axi_sys_mem_rid              (axi_sys_mem_rid), 

  .axis_aclk   (axis_clk),
  .axis_arestn (axis_rstn)   
);
*/

// Memory subsytem
// -- used AXI-MM BRAM to replace device DDR at the moment
// -- 512KB for system memory
axi_mm_bram axi_dev_mem_inst (
  .s_axi_aclk      (axis_clk),
  .s_axi_aresetn   (axis_rstn),
  .s_axi_awid      ({3'd0,axi_dev_mem_awid}),
  .s_axi_awaddr    (axi_dev_mem_awaddr[18:0]),
  .s_axi_awlen     (axi_dev_mem_awlen),
  .s_axi_awsize    (axi_dev_mem_awsize),
  .s_axi_awburst   (axi_dev_mem_awburst),
  .s_axi_awlock    (axi_dev_mem_awlock),
  .s_axi_awcache   (axi_dev_mem_awcache),
  .s_axi_awprot    (axi_dev_mem_awprot),
  .s_axi_awvalid   (axi_dev_mem_awvalid),
  .s_axi_awready   (axi_dev_mem_awready),
  .s_axi_wdata     (axi_dev_mem_wdata),
  .s_axi_wstrb     (axi_dev_mem_wstrb),
  .s_axi_wlast     (axi_dev_mem_wlast),
  .s_axi_wvalid    (axi_dev_mem_wvalid),
  .s_axi_wready    (axi_dev_mem_wready),
  .s_axi_bid       ({three_unused_bit2,axi_dev_mem_bid}),
  .s_axi_bresp     (axi_dev_mem_bresp),
  .s_axi_bvalid    (axi_dev_mem_bvalid),
  .s_axi_bready    (axi_dev_mem_bready),
  .s_axi_arid      ({3'd0,axi_dev_mem_arid}),
  .s_axi_araddr    (axi_dev_mem_araddr[18:0]),
  .s_axi_arlen     (axi_dev_mem_arlen),
  .s_axi_arsize    (axi_dev_mem_arsize),
  .s_axi_arburst   (axi_dev_mem_arburst),
  .s_axi_arlock    (axi_dev_mem_arlock),
  .s_axi_arcache   (axi_dev_mem_arcache),
  .s_axi_arprot    (axi_dev_mem_arprot),
  .s_axi_arvalid   (axi_dev_mem_arvalid),
  .s_axi_arready   (axi_dev_mem_arready),
  .s_axi_rid       ({three_unused_bit3,axi_dev_mem_rid}),
  .s_axi_rdata     (axi_dev_mem_rdata),
  .s_axi_rresp     (axi_dev_mem_rresp),
  .s_axi_rlast     (axi_dev_mem_rlast),
  .s_axi_rvalid    (axi_dev_mem_rvalid),
  .s_axi_rready    (axi_dev_mem_rready)
);

// Memory subsytem
// -- used AXI-MM BRAM to replace system DDR at the moment
// -- 1024KB for system memory
axi_sys_mm axi_sys_mem_inst (
  .s_axi_aclk      (axis_clk),
  .s_axi_aresetn   (axis_rstn),
  .s_axi_awid      ({3'd0,axi_sys_mem_awid}),
  .s_axi_awaddr    (axi_sys_mem_awaddr[19:0]),
  .s_axi_awlen     (axi_sys_mem_awlen),
  .s_axi_awsize    (axi_sys_mem_awsize),
  .s_axi_awburst   (axi_sys_mem_awburst),
  .s_axi_awlock    (axi_sys_mem_awlock),
  .s_axi_awcache   (axi_sys_mem_awcache),
  .s_axi_awprot    (axi_sys_mem_awprot),
  .s_axi_awvalid   (axi_sys_mem_awvalid),
  .s_axi_awready   (axi_sys_mem_awready),
  .s_axi_wdata     (axi_sys_mem_wdata),
  .s_axi_wstrb     (axi_sys_mem_wstrb),
  .s_axi_wlast     (axi_sys_mem_wlast),
  .s_axi_wvalid    (axi_sys_mem_wvalid),
  .s_axi_wready    (axi_sys_mem_wready),
  .s_axi_bid       ({three_unused_bit0,axi_sys_mem_bid}),
  .s_axi_bresp     (axi_sys_mem_bresp),
  .s_axi_bvalid    (axi_sys_mem_bvalid),
  .s_axi_bready    (axi_sys_mem_bready),
  .s_axi_arid      ({3'd0,axi_sys_mem_arid}),
  .s_axi_araddr    (axi_sys_mem_araddr[19:0]),
  .s_axi_arlen     (axi_sys_mem_arlen),
  .s_axi_arsize    (axi_sys_mem_arsize),
  .s_axi_arburst   (axi_sys_mem_arburst),
  .s_axi_arlock    (axi_sys_mem_arlock),
  .s_axi_arcache   (axi_sys_mem_arcache),
  .s_axi_arprot    (axi_sys_mem_arprot),
  .s_axi_arvalid   (axi_sys_mem_arvalid),
  .s_axi_arready   (axi_sys_mem_arready),
  .s_axi_rid       ({three_unused_bit1,axi_sys_mem_rid}),
  .s_axi_rdata     (axi_sys_mem_rdata),
  .s_axi_rresp     (axi_sys_mem_rresp),
  .s_axi_rlast     (axi_sys_mem_rlast),
  .s_axi_rvalid    (axi_sys_mem_rvalid),
  .s_axi_rready    (axi_sys_mem_rready)
);

assign axi_rdma_send_write_payload_awqos = 16'd0;
assign axi_rdma_send_write_payload_arqos = 16'd0;
assign axi_rdma_rsp_payload_awqos = 4'd0;
assign axi_rdma_rsp_payload_arqos = 4'd0;
assign axi_qdma_mm_awqos  = 4'd0;
assign axi_qdma_mm_arqos  = 4'd0;

assign m_axi_veri_sys_arqos = 4'd0;
assign m_axi_veri_dev_arqos = 4'd0;

assign axi_rdma_get_wqe_awqos     = 4'd0;
assign axi_rdma_get_wqe_arqos     = 4'd0;
assign axi_rdma_get_payload_awqos = 4'd0;
assign axi_rdma_get_payload_arqos = 4'd0;
assign axi_rdma_completion_awqos  = 4'd0;
assign axi_rdma_completion_arqos  = 4'd0;

assign axi_sys_mem_wuser  = 64'd0;
assign axi_sys_mem_aruser = 12'd0;
assign axi_sys_mem_awuser = 12'd0;

// instantiate AXI4 protocol write checker for device memory
axi_protocol_checker axi4_veri_mem_checker (
  // - Write Address Channel Signals
  .pc_axi_awaddr   (m_axi_init_dev_awaddr),
  .pc_axi_awprot   (m_axi_init_dev_awprot),
  .pc_axi_awvalid  (m_axi_init_dev_awvalid),
  .pc_axi_awready  (m_axi_init_dev_awready),
  .pc_axi_awsize   (m_axi_init_dev_awsize),
  .pc_axi_awburst  (m_axi_init_dev_awburst),
  .pc_axi_awcache  (m_axi_init_dev_awcache),
  .pc_axi_awlen    (m_axi_init_dev_awlen),
  .pc_axi_awlock   (m_axi_init_dev_awlock),
  .pc_axi_awqos    (4'd0),
  .pc_axi_awregion (4'd0),
  // - Write Data Channel Signals
  .pc_axi_wdata    (m_axi_init_dev_wdata),
  .pc_axi_wstrb    (m_axi_init_dev_wstrb),
  .pc_axi_wvalid   (m_axi_init_dev_wvalid),
  .pc_axi_wready   (m_axi_init_dev_wready),
  .pc_axi_wlast    (m_axi_init_dev_wlast),
  // - Write Response Channel Signals
  .pc_axi_bresp    (m_axi_init_dev_bresp),
  .pc_axi_bvalid   (m_axi_init_dev_bvalid),
  .pc_axi_bready   (m_axi_init_dev_bready),

  // - Read address channel signals
  .pc_axi_araddr   (m_axi_veri_dev_araddr),
  .pc_axi_arprot   (m_axi_veri_dev_arprot),
  .pc_axi_arvalid  (m_axi_veri_dev_arvalid),
  .pc_axi_arready  (m_axi_veri_dev_arready),
  .pc_axi_arsize   (m_axi_veri_dev_arsize),
  .pc_axi_arburst  (m_axi_veri_dev_arburst),
  .pc_axi_arcache  (m_axi_veri_dev_arcache),
  .pc_axi_arlock   (m_axi_veri_dev_arlock),
  .pc_axi_arlen    (m_axi_veri_dev_arlen),
  .pc_axi_arqos    (4'd0),
  .pc_axi_arregion (4'd0),
  // - Read data channel signals
  .pc_axi_rdata    (m_axi_veri_dev_rdata),
  .pc_axi_rresp    (m_axi_veri_dev_rresp),
  .pc_axi_rvalid   (m_axi_veri_dev_rvalid),
  .pc_axi_rready   (m_axi_veri_dev_rready),
  .pc_axi_rlast    (m_axi_veri_dev_rlast),

  // - System Signals
  .aclk            (axis_clk),
  .aresetn         (axis_rstn),
  .pc_status       (dev_pc_status),
  .pc_asserted     (dev_pc_asserted)
);


// instantiate AXI4 protocol write checker for system memory
axi_protocol_checker axi4_sys_mem_checker (
  // - Write Address Channel Signals
  .pc_axi_awaddr   (m_axi_init_sys_awaddr),
  .pc_axi_awprot   (m_axi_init_sys_awprot),
  .pc_axi_awvalid  (m_axi_init_sys_awvalid),
  .pc_axi_awready  (m_axi_init_sys_awready),
  .pc_axi_awsize   (m_axi_init_sys_awsize),
  .pc_axi_awburst  (m_axi_init_sys_awburst),
  .pc_axi_awcache  (m_axi_init_sys_awcache),
  .pc_axi_awlen    (m_axi_init_sys_awlen),
  .pc_axi_awlock   (m_axi_init_sys_awlock),
  .pc_axi_awqos    (4'd0),
  .pc_axi_awregion (4'd0),
  // - Write Data Channel Signals
  .pc_axi_wdata    (m_axi_init_sys_wdata),
  .pc_axi_wstrb    (m_axi_init_sys_wstrb),
  .pc_axi_wvalid   (m_axi_init_sys_wvalid),
  .pc_axi_wready   (m_axi_init_sys_wready),
  .pc_axi_wlast    (m_axi_init_sys_wlast),
  // - Write Response Channel Signals
  .pc_axi_bresp    (m_axi_init_sys_bresp),
  .pc_axi_bvalid   (m_axi_init_sys_bvalid),
  .pc_axi_bready   (m_axi_init_sys_bready),

  // - Read address channel signals
  .pc_axi_araddr   (m_axi_veri_sys_araddr),
  .pc_axi_arprot   (m_axi_veri_sys_arprot),
  .pc_axi_arvalid  (m_axi_veri_sys_arvalid),
  .pc_axi_arready  (m_axi_veri_sys_arready),
  .pc_axi_arsize   (m_axi_veri_sys_arsize),
  .pc_axi_arburst  (m_axi_veri_sys_arburst),
  .pc_axi_arcache  (m_axi_veri_sys_arcache),
  .pc_axi_arlock   (m_axi_veri_sys_arlock),
  .pc_axi_arlen    (m_axi_veri_sys_arlen),
  .pc_axi_arqos    (4'd0),
  .pc_axi_arregion (4'd0),
  // - Read data channel signals
  .pc_axi_rdata    (m_axi_veri_sys_rdata),
  .pc_axi_rresp    (m_axi_veri_sys_rresp),
  .pc_axi_rvalid   (m_axi_veri_sys_rvalid),
  .pc_axi_rready   (m_axi_veri_sys_rready),
  .pc_axi_rlast    (m_axi_veri_sys_rlast),

  // - System Signals
  .aclk            (axis_clk),
  .aresetn         (axis_rstn),
  .pc_status       (sys_pc_status),
  .pc_asserted     (sys_pc_asserted)
);

rn_tb_checker result_checker(
  .golden_resp_filename  (""),
  .axi_dev_read_filename (axi_dev_mem_filename),
  .axi_sys_read_filename (axi_sys_mem_filename),
  // golden input data
  .golden_axis_tvalid (s_axis_cmac_rx_tvalid & s_axis_cmac_rx_tready),
  .golden_axis_tdata  (s_axis_cmac_rx_tdata),
  .golden_axis_tkeep  (s_axis_cmac_rx_tkeep),
  .golden_axis_tlast  (s_axis_cmac_rx_tlast),
  .golden_num_pkt     (num_pkts),

  // non-roce result from rn_dut
  .s_axis_tdata (m_axis_qdma_c2h_tdata),
  .s_axis_tkeep (m_axis_qdma_c2h_tkeep),
  .s_axis_tvalid(m_axis_qdma_c2h_tvalid),
  .s_axis_tready(m_axis_qdma_c2h_tready),
  .s_axis_tlast (m_axis_qdma_c2h_tlast),

  // roce result from rn_dut
  .s_axis_roce_tdata (m_axis_cmac_rx_roce_tdata),
  .s_axis_roce_tkeep (m_axis_cmac_rx_roce_tkeep),
  .s_axis_roce_tvalid(m_axis_cmac_rx_roce_tvalid),
  .s_axis_roce_tlast (m_axis_cmac_rx_roce_tlast),

  // Verify device memory
  // - AXI read address channel
  .m_axi_veri_dev_arid      (m_axi_veri_dev_arid),
  .m_axi_veri_dev_araddr    (m_axi_veri_dev_araddr),
  .m_axi_veri_dev_arlen     (m_axi_veri_dev_arlen),
  .m_axi_veri_dev_arsize    (m_axi_veri_dev_arsize),
  .m_axi_veri_dev_arburst   (m_axi_veri_dev_arburst),
  .m_axi_veri_dev_arlock    (m_axi_veri_dev_arlock),
  .m_axi_veri_dev_arcache   (m_axi_veri_dev_arcache),
  .m_axi_veri_dev_arprot    (m_axi_veri_dev_arprot),
  .m_axi_veri_dev_arvalid   (m_axi_veri_dev_arvalid),
  .m_axi_veri_dev_arready   (m_axi_veri_dev_arready),
  // - AXI read data channel
  .m_axi_veri_dev_rid       (m_axi_veri_dev_rid),
  .m_axi_veri_dev_rdata     (m_axi_veri_dev_rdata),
  .m_axi_veri_dev_rresp     (m_axi_veri_dev_rresp),
  .m_axi_veri_dev_rlast     (m_axi_veri_dev_rlast),
  .m_axi_veri_dev_rvalid    (m_axi_veri_dev_rvalid),
  .m_axi_veri_dev_rready    (m_axi_veri_dev_rready),

  // Verify system memory
  // - AXI read address channel
  .m_axi_veri_sys_arid      (m_axi_veri_sys_arid),
  .m_axi_veri_sys_araddr    (m_axi_veri_sys_araddr),
  .m_axi_veri_sys_arlen     (m_axi_veri_sys_arlen),
  .m_axi_veri_sys_arsize    (m_axi_veri_sys_arsize),
  .m_axi_veri_sys_arburst   (m_axi_veri_sys_arburst),
  .m_axi_veri_sys_arlock    (m_axi_veri_sys_arlock),
  .m_axi_veri_sys_arcache   (m_axi_veri_sys_arcache),
  .m_axi_veri_sys_arprot    (m_axi_veri_sys_arprot),
  .m_axi_veri_sys_arvalid   (m_axi_veri_sys_arvalid),
  .m_axi_veri_sys_arready   (m_axi_veri_sys_arready),
  // - AXI read data channel
  .m_axi_veri_sys_rid       (m_axi_veri_sys_rid),
  .m_axi_veri_sys_rdata     (m_axi_veri_sys_rdata),
  .m_axi_veri_sys_rresp     (m_axi_veri_sys_rresp),
  .m_axi_veri_sys_rlast     (m_axi_veri_sys_rlast),
  .m_axi_veri_sys_rvalid    (m_axi_veri_sys_rvalid),
  .m_axi_veri_sys_rready    (m_axi_veri_sys_rready),

  .sys_pc_status     (sys_pc_status),
  .sys_pc_asserted   (sys_pc_asserted),
  .sys_mem_init_done (init_sys_mem_done),

  .dev_pc_status     (dev_pc_status),
  .dev_pc_asserted   (dev_pc_asserted),
  .dev_mem_init_done (init_dev_mem_done),

  .golden_data_loaded(golden_data_loaded),

  .axis_clk(axis_clk),
  .axis_rstn(axis_rstn) 
);

initial begin
  gen_pkt_mbox = new();

  fork
    generator.run();
  join_none
end

always_comb
begin
  if(sys_pc_asserted) begin
    $display("[ERROR] %t: sys_pc_asserted, axi4 write is wrong!", $time);
  end
end

always_comb
begin
  if(dev_pc_asserted) begin
    $display("[ERROR] %t: dev_pc_asserted, axi4 write is wrong!", $time);
  end
end

// Memory initialization for device and system
init_mem init_sys_mem (
  .tag_string        ("sys"),
  .axi_mem_filename  (axi_sys_mem_filename),

  .m_axi_init_awid   (m_axi_init_sys_awid),
  .m_axi_init_awaddr (m_axi_init_sys_awaddr),
  .m_axi_init_awqos  (m_axi_init_sys_awqos),
  .m_axi_init_awlen  (m_axi_init_sys_awlen),
  .m_axi_init_awsize (m_axi_init_sys_awsize),
  .m_axi_init_awburst(m_axi_init_sys_awburst),
  .m_axi_init_awcache(m_axi_init_sys_awcache),
  .m_axi_init_awprot (m_axi_init_sys_awprot),
  .m_axi_init_awvalid(m_axi_init_sys_awvalid),
  .m_axi_init_awready(m_axi_init_sys_awready),
  .m_axi_init_wdata  (m_axi_init_sys_wdata),
  .m_axi_init_wstrb  (m_axi_init_sys_wstrb),
  .m_axi_init_wlast  (m_axi_init_sys_wlast),
  .m_axi_init_wvalid (m_axi_init_sys_wvalid),
  .m_axi_init_wready (m_axi_init_sys_wready),
  .m_axi_init_awlock (m_axi_init_sys_awlock),
  .m_axi_init_bid    (m_axi_init_sys_bid),
  .m_axi_init_bresp  (m_axi_init_sys_bresp),
  .m_axi_init_bvalid (m_axi_init_sys_bvalid),
  .m_axi_init_bready (m_axi_init_sys_bready),

  .init_mem_done (init_sys_mem_done),

  .axis_clk (axis_clk),
  .axis_rstn(axis_rstn)
);

init_mem init_dev_mem (
  .tag_string        ("dev"),
  .axi_mem_filename  (axi_dev_mem_filename),

  .m_axi_init_awid   (m_axi_init_dev_awid),
  .m_axi_init_awaddr (m_axi_init_dev_awaddr),
  .m_axi_init_awqos  (m_axi_init_dev_awqos),
  .m_axi_init_awlen  (m_axi_init_dev_awlen),
  .m_axi_init_awsize (m_axi_init_dev_awsize),
  .m_axi_init_awburst(m_axi_init_dev_awburst),
  .m_axi_init_awcache(m_axi_init_dev_awcache),
  .m_axi_init_awprot (m_axi_init_dev_awprot),
  .m_axi_init_awvalid(m_axi_init_dev_awvalid),
  .m_axi_init_awready(m_axi_init_dev_awready),
  .m_axi_init_wdata  (m_axi_init_dev_wdata),
  .m_axi_init_wstrb  (m_axi_init_dev_wstrb),
  .m_axi_init_wlast  (m_axi_init_dev_wlast),
  .m_axi_init_wvalid (m_axi_init_dev_wvalid),
  .m_axi_init_wready (m_axi_init_dev_wready),
  .m_axi_init_awlock (m_axi_init_dev_awlock),
  .m_axi_init_bid    (m_axi_init_dev_bid),
  .m_axi_init_bresp  (m_axi_init_dev_bresp),
  .m_axi_init_bvalid (m_axi_init_dev_bvalid),
  .m_axi_init_bready (m_axi_init_dev_bready),

  .init_mem_done (init_dev_mem_done),

  .axis_clk (axis_clk),
  .axis_rstn(axis_rstn)
);

// Initialize unused ports
assign axi_qdma_mm_awid     = 0;
assign axi_qdma_mm_awaddr   = 0;
assign axi_qdma_mm_awqos    = 0;
assign axi_qdma_mm_awlen    = 0;
assign axi_qdma_mm_awsize   = 0;
assign axi_qdma_mm_awburst  = 0;
assign axi_qdma_mm_awcache  = 0;
assign axi_qdma_mm_awprot   = 0;
assign axi_qdma_mm_awvalid  = 0;
assign axi_qdma_mm_wdata    = 0;
assign axi_qdma_mm_wstrb    = 0;
assign axi_qdma_mm_wlast    = 0;
assign axi_qdma_mm_wvalid   = 0;
assign axi_qdma_mm_awlock   = 0;
assign axi_qdma_mm_bready   = 0;
assign axi_qdma_mm_arid     = 0;
assign axi_qdma_mm_araddr   = 0;
assign axi_qdma_mm_arlen    = 0;
assign axi_qdma_mm_arsize   = 0;
assign axi_qdma_mm_arburst  = 0;
assign axi_qdma_mm_arcache  = 0;
assign axi_qdma_mm_arprot   = 0;
assign axi_qdma_mm_arvalid  = 0;
assign axi_qdma_mm_rready   = 0;
assign axi_qdma_mm_arlock   = 0;
assign axi_qdma_mm_arqos    = 0;

// For analysis
always_comb begin
  if (m_axis_cmac_tx_tvalid && m_axis_cmac_tx_tready) begin
    $display("INFO: [rn_tb_top] packet_data=%x %x %x", m_axis_cmac_tx_tdata, m_axis_cmac_tx_tkeep, m_axis_cmac_tx_tlast);
  end
end

endmodule: rn_tb_top
