//==============================================================================
// Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
// SPDX-License-Identifier: MIT
//
//==============================================================================
`timescale 1ns/1ps

import rn_tb_pkg::*;

module rn_tb_2rdma_top;

string traffic_filename            = "";
string table_filename              = "";
string rsp_table_filename          = "";
string golden_resp_filename        = "";
string get_req_feedback_filename   = "";
string axi_read_info_filename      = "";
string axi_dev_mem_filename        = "rdma_dev_mem";
string axi_sys_mem_filename        = "rdma_sys_mem";
string rdma_combined_cfg_filename  = "rdma_combined_config";
string rdma1_stat_filename         = "rdma1_stat_reg_config";
string rdma2_combined_cfg_filename = "rdma2_combined_config";
string rdma2_stat_reg_cfg_filename = "rdma2_stat_reg_config";
string rdma2_recv_cfg_filename     = "rdma2_per_q_recv_config";
string rdma_wqe_init_filename      = "rdma_hw_hndshk_wqe_init";
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

// RDMA AXI4-Lite register channel for the remote RDMA peer
logic        axil_rdma2_awvalid;
logic [31:0] axil_rdma2_awaddr;
logic        axil_rdma2_awready;
logic        axil_rdma2_wvalid;
logic [31:0] axil_rdma2_wdata;
logic        axil_rdma2_wready;
logic        axil_rdma2_bvalid;
logic  [1:0] axil_rdma2_bresp;
logic        axil_rdma2_bready;
logic        axil_rdma2_arvalid;
logic [31:0] axil_rdma2_araddr;
logic        axil_rdma2_arready;
logic        axil_rdma2_rvalid;
logic [31:0] axil_rdma2_rdata;
logic  [1:0] axil_rdma2_rresp;
logic        axil_rdma2_rready;

// RDMA AXI4-Lite register configuration channel for the remote RDMA peer
logic        s_axil_rdma2_reg_awvalid;
logic [31:0] s_axil_rdma2_reg_awaddr;
logic        s_axil_rdma2_reg_awready;
logic        s_axil_rdma2_reg_wvalid;
logic [31:0] s_axil_rdma2_reg_wdata;
logic        s_axil_rdma2_reg_wready;
logic        s_axil_rdma2_reg_bvalid;
logic  [1:0] s_axil_rdma2_reg_bresp;
logic        s_axil_rdma2_reg_bready;
logic        s_axil_rdma2_reg_arvalid;
logic [31:0] s_axil_rdma2_reg_araddr;
logic        s_axil_rdma2_reg_arready;
logic        s_axil_rdma2_reg_rvalid;
logic [31:0] s_axil_rdma2_reg_rdata;
logic  [1:0] s_axil_rdma2_reg_rresp;
logic        s_axil_rdma2_reg_rready;

// RDMA AXI4-Lite status register channel for the remote RDMA peer
logic        s_axil_rdma2_stat_awvalid;
logic [31:0] s_axil_rdma2_stat_awaddr;
logic        s_axil_rdma2_stat_awready;
logic        s_axil_rdma2_stat_wvalid;
logic [31:0] s_axil_rdma2_stat_wdata;
logic        s_axil_rdma2_stat_wready;
logic        s_axil_rdma2_stat_bvalid;
logic  [1:0] s_axil_rdma2_stat_bresp;
logic        s_axil_rdma2_stat_bready;
logic        s_axil_rdma2_stat_arvalid;
logic [31:0] s_axil_rdma2_stat_araddr;
logic        s_axil_rdma2_stat_arready;
logic        s_axil_rdma2_stat_rvalid;
logic [31:0] s_axil_rdma2_stat_rdata;
logic  [1:0] s_axil_rdma2_stat_rresp;
logic        s_axil_rdma2_stat_rready;

// RDMA AXI4-Lite polling register channel for receive operations of the remote RDMA peer
logic        s_axil_rdma2_recv_awvalid;
logic [31:0] s_axil_rdma2_recv_awaddr;
logic        s_axil_rdma2_recv_awready;
logic        s_axil_rdma2_recv_wvalid;
logic [31:0] s_axil_rdma2_recv_wdata;
logic        s_axil_rdma2_recv_wready;
logic        s_axil_rdma2_recv_bvalid;
logic  [1:0] s_axil_rdma2_recv_bresp;
logic        s_axil_rdma2_recv_bready;
logic        s_axil_rdma2_recv_arvalid;
logic [31:0] s_axil_rdma2_recv_araddr;
logic        s_axil_rdma2_recv_arready;
logic        s_axil_rdma2_recv_rvalid;
logic [31:0] s_axil_rdma2_recv_rdata;
logic  [1:0] s_axil_rdma2_recv_rresp;
logic        s_axil_rdma2_recv_rready;

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

logic           axi_rdma1_send_write_payload_awid;
logic  [63 : 0] axi_rdma1_send_write_payload_awaddr;
logic  [31 : 0] axi_rdma1_send_write_payload_awuser;
logic   [3 : 0] axi_rdma1_send_write_payload_awqos;
logic   [7 : 0] axi_rdma1_send_write_payload_awlen;
logic   [2 : 0] axi_rdma1_send_write_payload_awsize;
logic   [1 : 0] axi_rdma1_send_write_payload_awburst;
logic   [3 : 0] axi_rdma1_send_write_payload_awcache;
logic   [2 : 0] axi_rdma1_send_write_payload_awprot;
logic           axi_rdma1_send_write_payload_awvalid;
logic           axi_rdma1_send_write_payload_awready;
logic [511 : 0] axi_rdma1_send_write_payload_wdata;
logic  [63 : 0] axi_rdma1_send_write_payload_wstrb;
logic           axi_rdma1_send_write_payload_wlast;
logic           axi_rdma1_send_write_payload_wvalid;
logic           axi_rdma1_send_write_payload_wready;
logic           axi_rdma1_send_write_payload_awlock;
logic           axi_rdma1_send_write_payload_bid;
logic   [1 : 0] axi_rdma1_send_write_payload_bresp;
logic           axi_rdma1_send_write_payload_bvalid;
logic           axi_rdma1_send_write_payload_bready;
logic           axi_rdma1_send_write_payload_arid;
logic  [63 : 0] axi_rdma1_send_write_payload_araddr;
logic   [7 : 0] axi_rdma1_send_write_payload_arlen;
logic   [2 : 0] axi_rdma1_send_write_payload_arsize;
logic   [1 : 0] axi_rdma1_send_write_payload_arburst;
logic   [3 : 0] axi_rdma1_send_write_payload_arcache;
logic   [2 : 0] axi_rdma1_send_write_payload_arprot;
logic           axi_rdma1_send_write_payload_arvalid;
logic           axi_rdma1_send_write_payload_arready;
logic           axi_rdma1_send_write_payload_rid;
logic [511 : 0] axi_rdma1_send_write_payload_rdata;
logic   [1 : 0] axi_rdma1_send_write_payload_rresp;
logic           axi_rdma1_send_write_payload_rlast;
logic           axi_rdma1_send_write_payload_rvalid;
logic           axi_rdma1_send_write_payload_rready;
logic           axi_rdma1_send_write_payload_arlock;
logic     [3:0] axi_rdma1_send_write_payload_arqos;

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
logic   [1 : 0] axi_rdma_get_payload_awid;
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
logic   [1 : 0] axi_rdma_get_payload_bid;
logic   [1 : 0] axi_rdma_get_payload_bresp;
logic           axi_rdma_get_payload_bvalid;
logic           axi_rdma_get_payload_bready;
logic   [1 : 0] axi_rdma_get_payload_arid;
logic  [63 : 0] axi_rdma_get_payload_araddr;
logic   [7 : 0] axi_rdma_get_payload_arlen;
logic   [2 : 0] axi_rdma_get_payload_arsize;
logic   [1 : 0] axi_rdma_get_payload_arburst;
logic   [3 : 0] axi_rdma_get_payload_arcache;
logic   [2 : 0] axi_rdma_get_payload_arprot;
logic           axi_rdma_get_payload_arvalid;
logic           axi_rdma_get_payload_arready;
logic   [1 : 0] axi_rdma_get_payload_rid;
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

logic           axi_rdma_completion_or_init_sys_awid;
logic  [63 : 0] axi_rdma_completion_or_init_sys_awaddr;
logic   [3 : 0] axi_rdma_completion_or_init_sys_awqos;
logic   [7 : 0] axi_rdma_completion_or_init_sys_awlen;
logic   [2 : 0] axi_rdma_completion_or_init_sys_awsize;
logic   [1 : 0] axi_rdma_completion_or_init_sys_awburst;
logic   [3 : 0] axi_rdma_completion_or_init_sys_awcache;
logic   [2 : 0] axi_rdma_completion_or_init_sys_awprot;
logic           axi_rdma_completion_or_init_sys_awvalid;
logic           axi_rdma_completion_or_init_sys_awready;
logic [511 : 0] axi_rdma_completion_or_init_sys_wdata;
logic  [63 : 0] axi_rdma_completion_or_init_sys_wstrb;
logic           axi_rdma_completion_or_init_sys_wlast;
logic           axi_rdma_completion_or_init_sys_wvalid;
logic           axi_rdma_completion_or_init_sys_wready;
logic           axi_rdma_completion_or_init_sys_awlock;
logic           axi_rdma_completion_or_init_sys_bid;
logic   [1 : 0] axi_rdma_completion_or_init_sys_bresp;
logic           axi_rdma_completion_or_init_sys_bvalid;
logic           axi_rdma_completion_or_init_sys_bready;
logic           axi_rdma_completion_or_init_sys_arid;
logic  [63 : 0] axi_rdma_completion_or_init_sys_araddr;
logic   [7 : 0] axi_rdma_completion_or_init_sys_arlen;
logic   [2 : 0] axi_rdma_completion_or_init_sys_arsize;
logic   [1 : 0] axi_rdma_completion_or_init_sys_arburst;
logic   [3 : 0] axi_rdma_completion_or_init_sys_arcache;
logic   [2 : 0] axi_rdma_completion_or_init_sys_arprot;
logic           axi_rdma_completion_or_init_sys_arvalid;
logic           axi_rdma_completion_or_init_sys_arready;
logic           axi_rdma_completion_or_init_sys_rid;
logic [511 : 0] axi_rdma_completion_or_init_sys_rdata;
logic   [1 : 0] axi_rdma_completion_or_init_sys_rresp;
logic           axi_rdma_completion_or_init_sys_rlast;
logic           axi_rdma_completion_or_init_sys_rvalid;
logic           axi_rdma_completion_or_init_sys_rready;
logic           axi_rdma_completion_or_init_sys_arlock;
logic   [3 : 0] axi_rdma_completion_or_init_sys_arqos;

logic           axi_rdma_rsp_or_hw_hndshk_sys_awid;
logic  [63 : 0] axi_rdma_rsp_or_hw_hndshk_sys_awaddr;
logic   [3 : 0] axi_rdma_rsp_or_hw_hndshk_sys_awqos;
logic   [7 : 0] axi_rdma_rsp_or_hw_hndshk_sys_awlen;
logic   [2 : 0] axi_rdma_rsp_or_hw_hndshk_sys_awsize;
logic   [1 : 0] axi_rdma_rsp_or_hw_hndshk_sys_awburst;
logic   [3 : 0] axi_rdma_rsp_or_hw_hndshk_sys_awcache;
logic   [2 : 0] axi_rdma_rsp_or_hw_hndshk_sys_awprot;
logic           axi_rdma_rsp_or_hw_hndshk_sys_awvalid;
logic           axi_rdma_rsp_or_hw_hndshk_sys_awready;
logic [511 : 0] axi_rdma_rsp_or_hw_hndshk_sys_wdata;
logic  [63 : 0] axi_rdma_rsp_or_hw_hndshk_sys_wstrb;
logic           axi_rdma_rsp_or_hw_hndshk_sys_wlast;
logic           axi_rdma_rsp_or_hw_hndshk_sys_wvalid;
logic           axi_rdma_rsp_or_hw_hndshk_sys_wready;
logic           axi_rdma_rsp_or_hw_hndshk_sys_awlock;
logic           axi_rdma_rsp_or_hw_hndshk_sys_bid;
logic   [1 : 0] axi_rdma_rsp_or_hw_hndshk_sys_bresp;
logic           axi_rdma_rsp_or_hw_hndshk_sys_bvalid;
logic           axi_rdma_rsp_or_hw_hndshk_sys_bready;
logic           axi_rdma_rsp_or_hw_hndshk_sys_arid;
logic  [63 : 0] axi_rdma_rsp_or_hw_hndshk_sys_araddr;
logic   [7 : 0] axi_rdma_rsp_or_hw_hndshk_sys_arlen;
logic   [2 : 0] axi_rdma_rsp_or_hw_hndshk_sys_arsize;
logic   [1 : 0] axi_rdma_rsp_or_hw_hndshk_sys_arburst;
logic   [3 : 0] axi_rdma_rsp_or_hw_hndshk_sys_arcache;
logic   [2 : 0] axi_rdma_rsp_or_hw_hndshk_sys_arprot;
logic           axi_rdma_rsp_or_hw_hndshk_sys_arvalid;
logic           axi_rdma_rsp_or_hw_hndshk_sys_arready;
logic           axi_rdma_rsp_or_hw_hndshk_sys_rid;
logic [511 : 0] axi_rdma_rsp_or_hw_hndshk_sys_rdata;
logic   [1 : 0] axi_rdma_rsp_or_hw_hndshk_sys_rresp;
logic           axi_rdma_rsp_or_hw_hndshk_sys_rlast;
logic           axi_rdma_rsp_or_hw_hndshk_sys_rvalid;
logic           axi_rdma_rsp_or_hw_hndshk_sys_rready;
logic           axi_rdma_rsp_or_hw_hndshk_sys_arlock;
logic   [3 : 0] axi_rdma_rsp_or_hw_hndshk_sys_arqos;

// AXI MM interface used to access the device memory
logic   [3:0] axi_dev_mem_awid;
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
logic   [3:0] axi_dev_mem_bid;
logic   [1:0] axi_dev_mem_bresp;
logic         axi_dev_mem_bvalid;
logic         axi_dev_mem_bready;
logic   [3:0] axi_dev_mem_arid;
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
logic   [3:0] axi_dev_mem_rid;
logic [511:0] axi_dev_mem_rdata;
logic   [1:0] axi_dev_mem_rresp;
logic         axi_dev_mem_rlast;
logic         axi_dev_mem_rvalid;
logic         axi_dev_mem_rready;

logic           axi_hw_hndshk_to_sys_mem_awid;
logic  [63 : 0] axi_hw_hndshk_to_sys_mem_awaddr;
logic   [3 : 0] axi_hw_hndshk_to_sys_mem_awqos;
logic   [7 : 0] axi_hw_hndshk_to_sys_mem_awlen;
logic   [2 : 0] axi_hw_hndshk_to_sys_mem_awsize;
logic   [1 : 0] axi_hw_hndshk_to_sys_mem_awburst;
logic   [3 : 0] axi_hw_hndshk_to_sys_mem_awcache;
logic   [2 : 0] axi_hw_hndshk_to_sys_mem_awprot;
logic           axi_hw_hndshk_to_sys_mem_awvalid;
logic           axi_hw_hndshk_to_sys_mem_awready;
logic [511 : 0] axi_hw_hndshk_to_sys_mem_wdata;
logic  [63 : 0] axi_hw_hndshk_to_sys_mem_wstrb;
logic           axi_hw_hndshk_to_sys_mem_wlast;
logic           axi_hw_hndshk_to_sys_mem_wvalid;
logic           axi_hw_hndshk_to_sys_mem_wready;
logic           axi_hw_hndshk_to_sys_mem_awlock;
logic           axi_hw_hndshk_to_sys_mem_bid;
logic   [1 : 0] axi_hw_hndshk_to_sys_mem_bresp;
logic           axi_hw_hndshk_to_sys_mem_bvalid;
logic           axi_hw_hndshk_to_sys_mem_bready;
logic           axi_hw_hndshk_to_sys_mem_arid;
logic  [63 : 0] axi_hw_hndshk_to_sys_mem_araddr;
logic   [7 : 0] axi_hw_hndshk_to_sys_mem_arlen;
logic   [2 : 0] axi_hw_hndshk_to_sys_mem_arsize;
logic   [1 : 0] axi_hw_hndshk_to_sys_mem_arburst;
logic   [3 : 0] axi_hw_hndshk_to_sys_mem_arcache;
logic   [2 : 0] axi_hw_hndshk_to_sys_mem_arprot;
logic           axi_hw_hndshk_to_sys_mem_arvalid;
logic           axi_hw_hndshk_to_sys_mem_arready;
logic           axi_hw_hndshk_to_sys_mem_rid;
logic [511 : 0] axi_hw_hndshk_to_sys_mem_rdata;
logic   [1 : 0] axi_hw_hndshk_to_sys_mem_rresp;
logic           axi_hw_hndshk_to_sys_mem_rlast;
logic           axi_hw_hndshk_to_sys_mem_rvalid;
logic           axi_hw_hndshk_to_sys_mem_rready;
logic           axi_hw_hndshk_to_sys_mem_arlock;
logic   [3 : 0] axi_hw_hndshk_to_sys_mem_arqos;

// AXI MM interface used to access the system memory (s_axib_* of the QDMA IP)
logic     [2:0] axi_sys_mem_awid;
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
logic     [2:0] axi_sys_mem_bid;
logic     [1:0] axi_sys_mem_bresp;
logic           axi_sys_mem_bvalid;
logic           axi_sys_mem_bready;
logic     [2:0] axi_sys_mem_arid;
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
logic     [2:0] axi_sys_mem_rid;
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

logic sys_axi_read_passed;
logic dev_axi_read_passed;

// AXI4 protocol write checker
logic [160-1:0] sys_pc_status;
logic           sys_pc_asserted;
logic [160-1:0] dev_pc_status;
logic           dev_pc_asserted;

logic start_config_rdma;
logic start_rdma1_stat;

logic start_init_hw_hndshk;
logic finish_init_hw_hndshk;
logic trg_hw_hndshk;


/* Declaration of remote RDMA peer */
logic start_config_rdma2;
logic finish_config_rdma2;
logic start_rdma2_stat;
logic finish_rdma2_stat;
logic start_checking_recv_rdma2;
logic checking_recv_rdma2;
logic [1:0] start_checking_recv_rdma2_cdc;

// remote peer rdma to local peer rdma
logic [511:0] rp_rdma2lp_rdma_axis_tdata;
logic  [63:0] rp_rdma2lp_rdma_axis_tkeep;
logic         rp_rdma2lp_rdma_axis_tvalid;
logic         rp_rdma2lp_rdma_axis_tlast;
logic         rp_rdma2lp_rdma_axis_tready;

// invalidate or immediate data from roce IETH/IMMDT header
logic  [63:0] rp_rdma2user_ieth_immdt_axis_tdata;
logic         rp_rdma2user_ieth_immdt_axis_tlast;
logic         rp_rdma2user_ieth_immdt_axis_tvalid;
logic         rp_rdma2user_ieth_immdt_axis_trdy;

// RDMA AXI MM interface used to store payload from RDMA MAD, Send or Write operation
logic           axi_rdma2_send_write_payload_awid;
logic  [63 : 0] axi_rdma2_send_write_payload_awaddr;
logic  [31 : 0] axi_rdma2_send_write_payload_awuser;
logic   [3 : 0] axi_rdma2_send_write_payload_awqos;
logic   [7 : 0] axi_rdma2_send_write_payload_awlen;
logic   [2 : 0] axi_rdma2_send_write_payload_awsize;
logic   [1 : 0] axi_rdma2_send_write_payload_awburst;
logic   [3 : 0] axi_rdma2_send_write_payload_awcache;
logic   [2 : 0] axi_rdma2_send_write_payload_awprot;
logic           axi_rdma2_send_write_payload_awvalid;
logic           axi_rdma2_send_write_payload_awready;
logic [511 : 0] axi_rdma2_send_write_payload_wdata;
logic  [63 : 0] axi_rdma2_send_write_payload_wstrb;
logic           axi_rdma2_send_write_payload_wlast;
logic           axi_rdma2_send_write_payload_wvalid;
logic           axi_rdma2_send_write_payload_wready;
logic           axi_rdma2_send_write_payload_awlock;
logic           axi_rdma2_send_write_payload_bid;
logic   [1 : 0] axi_rdma2_send_write_payload_bresp;
logic           axi_rdma2_send_write_payload_bvalid;
logic           axi_rdma2_send_write_payload_bready;
logic           axi_rdma2_send_write_payload_arid;
logic  [63 : 0] axi_rdma2_send_write_payload_araddr;
logic   [7 : 0] axi_rdma2_send_write_payload_arlen;
logic   [2 : 0] axi_rdma2_send_write_payload_arsize;
logic   [1 : 0] axi_rdma2_send_write_payload_arburst;
logic   [3 : 0] axi_rdma2_send_write_payload_arcache;
logic   [2 : 0] axi_rdma2_send_write_payload_arprot;
logic           axi_rdma2_send_write_payload_arvalid;
logic           axi_rdma2_send_write_payload_arready;
logic           axi_rdma2_send_write_payload_rid;
logic [511 : 0] axi_rdma2_send_write_payload_rdata;
logic   [1 : 0] axi_rdma2_send_write_payload_rresp;
logic           axi_rdma2_send_write_payload_rlast;
logic           axi_rdma2_send_write_payload_rvalid;
logic           axi_rdma2_send_write_payload_rready;
logic           axi_rdma2_send_write_payload_arlock;
logic     [3:0] axi_rdma2_send_write_payload_arqos;

// RDMA AXI MM interface used to store payload from RDMA Read response operation
logic           m_axi_rdma_rsp_payload_awid;
logic  [63 : 0] m_axi_rdma_rsp_payload_awaddr;
logic   [7 : 0] m_axi_rdma_rsp_payload_awlen;
logic   [2 : 0] m_axi_rdma_rsp_payload_awsize;
logic   [1 : 0] m_axi_rdma_rsp_payload_awburst;
logic   [3 : 0] m_axi_rdma_rsp_payload_awcache;
logic   [2 : 0] m_axi_rdma_rsp_payload_awprot;
logic           m_axi_rdma_rsp_payload_awvalid;
logic           m_axi_rdma_rsp_payload_awready;
logic [511 : 0] m_axi_rdma_rsp_payload_wdata;
logic  [63 : 0] m_axi_rdma_rsp_payload_wstrb;
logic           m_axi_rdma_rsp_payload_wlast;
logic           m_axi_rdma_rsp_payload_wvalid;
logic           m_axi_rdma_rsp_payload_wready;
logic           m_axi_rdma_rsp_payload_awlock;
logic           m_axi_rdma_rsp_payload_bid;
logic   [1 : 0] m_axi_rdma_rsp_payload_bresp;
logic           m_axi_rdma_rsp_payload_bvalid;
logic           m_axi_rdma_rsp_payload_bready;
logic           m_axi_rdma_rsp_payload_arid;
logic  [63 : 0] m_axi_rdma_rsp_payload_araddr;
logic   [7 : 0] m_axi_rdma_rsp_payload_arlen;
logic   [2 : 0] m_axi_rdma_rsp_payload_arsize;
logic   [1 : 0] m_axi_rdma_rsp_payload_arburst;
logic   [3 : 0] m_axi_rdma_rsp_payload_arcache;
logic   [2 : 0] m_axi_rdma_rsp_payload_arprot;
logic           m_axi_rdma_rsp_payload_arvalid;
logic           m_axi_rdma_rsp_payload_arready;
logic           m_axi_rdma_rsp_payload_rid;
logic [511 : 0] m_axi_rdma_rsp_payload_rdata;
logic   [1 : 0] m_axi_rdma_rsp_payload_rresp;
logic           m_axi_rdma_rsp_payload_rlast;
logic           m_axi_rdma_rsp_payload_rvalid;
logic           m_axi_rdma_rsp_payload_rready;
logic           m_axi_rdma_rsp_payload_arlock;

// RDMA AXI MM interface used to fetch WQE entries in the senq queue from DDR by the QP manager
logic           m_axi_rdma_get_wqe_awid;
logic  [63 : 0] m_axi_rdma_get_wqe_awaddr;
logic   [7 : 0] m_axi_rdma_get_wqe_awlen;
logic   [2 : 0] m_axi_rdma_get_wqe_awsize;
logic   [1 : 0] m_axi_rdma_get_wqe_awburst;
logic   [3 : 0] m_axi_rdma_get_wqe_awcache;
logic   [2 : 0] m_axi_rdma_get_wqe_awprot;
logic           m_axi_rdma_get_wqe_awvalid;
logic           m_axi_rdma_get_wqe_awready;
logic [511 : 0] m_axi_rdma_get_wqe_wdata;
logic  [63 : 0] m_axi_rdma_get_wqe_wstrb;
logic           m_axi_rdma_get_wqe_wlast;
logic           m_axi_rdma_get_wqe_wvalid;
logic           m_axi_rdma_get_wqe_wready;
logic           m_axi_rdma_get_wqe_awlock;
logic           m_axi_rdma_get_wqe_bid;
logic   [1 : 0] m_axi_rdma_get_wqe_bresp;
logic           m_axi_rdma_get_wqe_bvalid;
logic           m_axi_rdma_get_wqe_bready;
logic           m_axi_rdma_get_wqe_arid;
logic  [63 : 0] m_axi_rdma_get_wqe_araddr;
logic   [7 : 0] m_axi_rdma_get_wqe_arlen;
logic   [2 : 0] m_axi_rdma_get_wqe_arsize;
logic   [1 : 0] m_axi_rdma_get_wqe_arburst;
logic   [3 : 0] m_axi_rdma_get_wqe_arcache;
logic   [2 : 0] m_axi_rdma_get_wqe_arprot;
logic           m_axi_rdma_get_wqe_arvalid;
logic           m_axi_rdma_get_wqe_arready;
logic           m_axi_rdma_get_wqe_rid;
logic [511 : 0] m_axi_rdma_get_wqe_rdata;
logic   [1 : 0] m_axi_rdma_get_wqe_rresp;
logic           m_axi_rdma_get_wqe_rlast;
logic           m_axi_rdma_get_wqe_rvalid;
logic           m_axi_rdma_get_wqe_rready;
logic           m_axi_rdma_get_wqe_arlock;

// RDMA AXI MM interface used to get payload of an outgoing RDMA send/write and read response packets
logic           m_axi_rdma1_get_payload_awid;
logic  [63 : 0] m_axi_rdma1_get_payload_awaddr;
logic   [3 : 0] m_axi_rdma1_get_payload_awqos;
logic   [7 : 0] m_axi_rdma1_get_payload_awlen;
logic   [2 : 0] m_axi_rdma1_get_payload_awsize;
logic   [1 : 0] m_axi_rdma1_get_payload_awburst;
logic   [3 : 0] m_axi_rdma1_get_payload_awcache;
logic   [2 : 0] m_axi_rdma1_get_payload_awprot;
logic           m_axi_rdma1_get_payload_awvalid;
logic           m_axi_rdma1_get_payload_awready;
logic [511 : 0] m_axi_rdma1_get_payload_wdata;
logic  [63 : 0] m_axi_rdma1_get_payload_wstrb;
logic           m_axi_rdma1_get_payload_wlast;
logic           m_axi_rdma1_get_payload_wvalid;
logic           m_axi_rdma1_get_payload_wready;
logic           m_axi_rdma1_get_payload_awlock;
logic           m_axi_rdma1_get_payload_bid;
logic   [1 : 0] m_axi_rdma1_get_payload_bresp;
logic           m_axi_rdma1_get_payload_bvalid;
logic           m_axi_rdma1_get_payload_bready;
logic           m_axi_rdma1_get_payload_arid;
logic  [63 : 0] m_axi_rdma1_get_payload_araddr;
logic   [7 : 0] m_axi_rdma1_get_payload_arlen;
logic   [2 : 0] m_axi_rdma1_get_payload_arsize;
logic   [1 : 0] m_axi_rdma1_get_payload_arburst;
logic   [3 : 0] m_axi_rdma1_get_payload_arcache;
logic   [2 : 0] m_axi_rdma1_get_payload_arprot;
logic           m_axi_rdma1_get_payload_arvalid;
logic           m_axi_rdma1_get_payload_arready;
logic           m_axi_rdma1_get_payload_rid;
logic [511 : 0] m_axi_rdma1_get_payload_rdata;
logic   [1 : 0] m_axi_rdma1_get_payload_rresp;
logic           m_axi_rdma1_get_payload_rlast;
logic           m_axi_rdma1_get_payload_rvalid;
logic           m_axi_rdma1_get_payload_rready;
logic           m_axi_rdma1_get_payload_arlock;
logic   [3 : 0] m_axi_rdma1_get_payload_arqos;

logic           m_axi_rdma2_get_payload_awid;
logic  [63 : 0] m_axi_rdma2_get_payload_awaddr;
logic   [3 : 0] m_axi_rdma2_get_payload_awqos;
logic   [7 : 0] m_axi_rdma2_get_payload_awlen;
logic   [2 : 0] m_axi_rdma2_get_payload_awsize;
logic   [1 : 0] m_axi_rdma2_get_payload_awburst;
logic   [3 : 0] m_axi_rdma2_get_payload_awcache;
logic   [2 : 0] m_axi_rdma2_get_payload_awprot;
logic           m_axi_rdma2_get_payload_awvalid;
logic           m_axi_rdma2_get_payload_awready;
logic [511 : 0] m_axi_rdma2_get_payload_wdata;
logic  [63 : 0] m_axi_rdma2_get_payload_wstrb;
logic           m_axi_rdma2_get_payload_wlast;
logic           m_axi_rdma2_get_payload_wvalid;
logic           m_axi_rdma2_get_payload_wready;
logic           m_axi_rdma2_get_payload_awlock;
logic           m_axi_rdma2_get_payload_bid;
logic   [1 : 0] m_axi_rdma2_get_payload_bresp;
logic           m_axi_rdma2_get_payload_bvalid;
logic           m_axi_rdma2_get_payload_bready;
logic           m_axi_rdma2_get_payload_arid;
logic  [63 : 0] m_axi_rdma2_get_payload_araddr;
logic   [7 : 0] m_axi_rdma2_get_payload_arlen;
logic   [2 : 0] m_axi_rdma2_get_payload_arsize;
logic   [1 : 0] m_axi_rdma2_get_payload_arburst;
logic   [3 : 0] m_axi_rdma2_get_payload_arcache;
logic   [2 : 0] m_axi_rdma2_get_payload_arprot;
logic           m_axi_rdma2_get_payload_arvalid;
logic           m_axi_rdma2_get_payload_arready;
logic           m_axi_rdma2_get_payload_rid;
logic [511 : 0] m_axi_rdma2_get_payload_rdata;
logic   [1 : 0] m_axi_rdma2_get_payload_rresp;
logic           m_axi_rdma2_get_payload_rlast;
logic           m_axi_rdma2_get_payload_rvalid;
logic           m_axi_rdma2_get_payload_rready;
logic           m_axi_rdma2_get_payload_arlock;
logic   [3 : 0] m_axi_rdma2_get_payload_arqos;

// RDMA AXI MM interface used to write completion entries to a completion queue in the DDR
logic           m_axi_rdma_completion_awid;
logic  [63 : 0] m_axi_rdma_completion_awaddr;
logic   [7 : 0] m_axi_rdma_completion_awlen;
logic   [2 : 0] m_axi_rdma_completion_awsize;
logic   [1 : 0] m_axi_rdma_completion_awburst;
logic   [3 : 0] m_axi_rdma_completion_awcache;
logic   [2 : 0] m_axi_rdma_completion_awprot;
logic           m_axi_rdma_completion_awvalid;
logic           m_axi_rdma_completion_awready;
logic [511 : 0] m_axi_rdma_completion_wdata;
logic  [63 : 0] m_axi_rdma_completion_wstrb;
logic           m_axi_rdma_completion_wlast;
logic           m_axi_rdma_completion_wvalid;
logic           m_axi_rdma_completion_wready;
logic           m_axi_rdma_completion_awlock;
logic           m_axi_rdma_completion_bid;
logic   [1 : 0] m_axi_rdma_completion_bresp;
logic           m_axi_rdma_completion_bvalid;
logic           m_axi_rdma_completion_bready;
logic           m_axi_rdma_completion_arid;
logic  [63 : 0] m_axi_rdma_completion_araddr;
logic   [7 : 0] m_axi_rdma_completion_arlen;
logic   [2 : 0] m_axi_rdma_completion_arsize;
logic   [1 : 0] m_axi_rdma_completion_arburst;
logic   [3 : 0] m_axi_rdma_completion_arcache;
logic   [2 : 0] m_axi_rdma_completion_arprot;
logic           m_axi_rdma_completion_arvalid;
logic           m_axi_rdma_completion_arready;
logic           m_axi_rdma_completion_rid;
logic [511 : 0] m_axi_rdma_completion_rdata;
logic   [1 : 0] m_axi_rdma_completion_rresp;
logic           m_axi_rdma_completion_rlast;
logic           m_axi_rdma_completion_rvalid;
logic           m_axi_rdma_completion_rready;
logic           m_axi_rdma_completion_arlock;

//AXI interface between system mem crossbar and device mem crossbar
logic   [2 : 0] axi_from_sys_to_dev_crossbar_awid;
logic  [63 : 0] axi_from_sys_to_dev_crossbar_awaddr;
logic  [31 : 0] axi_from_sys_to_dev_crossbar_awuser;
logic   [3 : 0] axi_from_sys_to_dev_crossbar_awqos;
logic   [7 : 0] axi_from_sys_to_dev_crossbar_awlen;
logic   [2 : 0] axi_from_sys_to_dev_crossbar_awsize;
logic   [1 : 0] axi_from_sys_to_dev_crossbar_awburst;
logic   [3 : 0] axi_from_sys_to_dev_crossbar_awcache;
logic   [2 : 0] axi_from_sys_to_dev_crossbar_awprot;
logic           axi_from_sys_to_dev_crossbar_awvalid;
logic           axi_from_sys_to_dev_crossbar_awready;
logic [511 : 0] axi_from_sys_to_dev_crossbar_wdata;
logic  [63 : 0] axi_from_sys_to_dev_crossbar_wstrb;
logic           axi_from_sys_to_dev_crossbar_wlast;
logic           axi_from_sys_to_dev_crossbar_wvalid;
logic           axi_from_sys_to_dev_crossbar_wready;
logic           axi_from_sys_to_dev_crossbar_awlock;
logic   [3 : 0] axi_from_sys_to_dev_crossbar_bid;
logic   [1 : 0] axi_from_sys_to_dev_crossbar_bresp;
logic           axi_from_sys_to_dev_crossbar_bvalid;
logic           axi_from_sys_to_dev_crossbar_bready;
logic   [2 : 0] axi_from_sys_to_dev_crossbar_arid;
logic  [63 : 0] axi_from_sys_to_dev_crossbar_araddr;
logic   [7 : 0] axi_from_sys_to_dev_crossbar_arlen;
logic   [2 : 0] axi_from_sys_to_dev_crossbar_arsize;
logic   [1 : 0] axi_from_sys_to_dev_crossbar_arburst;
logic   [3 : 0] axi_from_sys_to_dev_crossbar_arcache;
logic   [2 : 0] axi_from_sys_to_dev_crossbar_arprot;
logic           axi_from_sys_to_dev_crossbar_arvalid;
logic           axi_from_sys_to_dev_crossbar_arready;
logic   [3 : 0] axi_from_sys_to_dev_crossbar_rid;
logic [511 : 0] axi_from_sys_to_dev_crossbar_rdata;
logic   [1 : 0] axi_from_sys_to_dev_crossbar_rresp;
logic           axi_from_sys_to_dev_crossbar_rlast;
logic           axi_from_sys_to_dev_crossbar_rvalid;
logic           axi_from_sys_to_dev_crossbar_rready;
logic           axi_from_sys_to_dev_crossbar_arlock;
logic   [3 : 0] axi_from_sys_to_dev_crossbar_arqos;


// Send WQE completion queue doorbell
logic         resp_hndler_o_send_cq_db_cnt_valid;
logic   [9:0] resp_hndler_o_send_cq_db_addr;
logic  [31:0] resp_hndler_o_send_cq_db_cnt;
logic         resp_hndler_i_send_cq_db_rdy;

// Send WQE producer index doorbell
logic  [15:0] i_qp_sq_pidb_hndshk;
logic  [31:0] i_qp_sq_pidb_wr_addr_hndshk;
logic         i_qp_sq_pidb_wr_valid_hndshk;
logic         o_qp_sq_pidb_wr_rdy;

// RDMA-Send consumer index doorbell
logic  [15:0] i_qp_rq_cidb_hndshk;
logic  [31:0] i_qp_rq_cidb_wr_addr_hndshk;
logic         i_qp_rq_cidb_wr_valid_hndshk;
logic         o_qp_rq_cidb_wr_rdy;

// RDMA-Send producer index doorbell
logic  [31:0] rx_pkt_hndler_o_rq_db_data;
logic   [9:0] rx_pkt_hndler_o_rq_db_addr;
logic         rx_pkt_hndler_o_rq_db_data_valid;
logic         rx_pkt_hndler_i_rq_db_rdy;


logic rdma2_intr;
logic rdma2_rst_done;

// Check RDMA packets generated by the local peer
logic [47:0] mac_dst;
logic [47:0] mac_src;
logic [3:0]  ip_ihl;
logic [15:0] ip_total_length;
logic [31:0] ip_src;
logic [31:0] ip_dst;
logic [15:0] udp_sport;
logic [15:0] udp_dport;
logic [15:0] udp_length;
logic [7:0]  bth_opcode;
logic [15:0] bth_partition_key;
logic [23:0] bth_dst_qp;
logic [23:0] bth_psn;
logic [31:0] reth_vir_addr_lsb;
logic [31:0] reth_vir_addr_msb;
logic [31:0] reth_rkey;
logic [31:0] reth_length; 

logic [511:0] m_axis_cmac_tx_tdata_delay;
logic [63:0]  m_axis_cmac_tx_tkeep_delay;
logic         m_axis_cmac_tx_tvalid_delay;
logic         m_axis_cmac_tx_tlast_delay;

logic           one_unused_bit0;
logic           one_unused_bit1;

logic   [1 : 0] two_unused_bit0;
logic   [1 : 0] two_unused_bit1;
logic   [1 : 0] two_unused_bit2;
logic   [1 : 0] two_unused_bit3;
logic   [1 : 0] two_unused_bit4;
logic   [1 : 0] two_unused_bit5;
logic   [1 : 0] two_unused_bit6;
logic   [1 : 0] two_unused_bit7;
logic   [1 : 0] two_unused_bit8;
logic   [1 : 0] two_unused_bit9;
logic   [1 : 0] two_unused_bit10;

logic           trg_rdma_ops_flag;

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
  .rdma_stat_filename(rdma1_stat_filename),
  .rdma_wqe_init_filename(rdma_wqe_init_filename),

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

  .start_sim     (axis_rstn),
  .start_config_rdma (start_config_rdma),
  .start_stat_rdma   (start_rdma1_stat),
  //.start_stat_rdma   (start_init_hw_hndshk),
  .stimulus_all_sent(),
  .finish_config_rdma (trg_hw_hndshk),
  //.start_init_hw_hndshk (start_init_hw_hndshk),
  .finish_init_hw_hndshk (finish_init_hw_hndshk),

  .axil_clk (axil_clk), 
  .axil_rstn(axil_rstn),
  .axis_clk (axis_clk), 
  .axis_rstn(axis_rstn)
);

assign start_config_rdma  = finish_config_rdma2;

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

  // Receive acknowledge packets from remote rdma peer
  .s_axis_cmac_rx_tvalid       (rp_rdma2lp_rdma_axis_tvalid),
  .s_axis_cmac_rx_tdata        (rp_rdma2lp_rdma_axis_tdata),
  .s_axis_cmac_rx_tkeep        (rp_rdma2lp_rdma_axis_tkeep),
  .s_axis_cmac_rx_tlast        (rp_rdma2lp_rdma_axis_tlast),
  .s_axis_cmac_rx_tuser_size   (16'd0),
  .s_axis_cmac_rx_tready       (rp_rdma2lp_rdma_axis_tready),

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
  .m_axi_rdma_send_write_payload_awid       (axi_rdma1_send_write_payload_awid),
  .m_axi_rdma_send_write_payload_awaddr     (axi_rdma1_send_write_payload_awaddr),
  .m_axi_rdma_send_write_payload_awuser     (axi_rdma1_send_write_payload_awuser),
  .m_axi_rdma_send_write_payload_awlen      (axi_rdma1_send_write_payload_awlen),
  .m_axi_rdma_send_write_payload_awsize     (axi_rdma1_send_write_payload_awsize),
  .m_axi_rdma_send_write_payload_awburst    (axi_rdma1_send_write_payload_awburst),
  .m_axi_rdma_send_write_payload_awcache    (axi_rdma1_send_write_payload_awcache),
  .m_axi_rdma_send_write_payload_awprot     (axi_rdma1_send_write_payload_awprot),
  .m_axi_rdma_send_write_payload_awvalid    (axi_rdma1_send_write_payload_awvalid),
  .m_axi_rdma_send_write_payload_awready    (axi_rdma1_send_write_payload_awready),
  .m_axi_rdma_send_write_payload_wdata      (axi_rdma1_send_write_payload_wdata),
  .m_axi_rdma_send_write_payload_wstrb      (axi_rdma1_send_write_payload_wstrb),
  .m_axi_rdma_send_write_payload_wlast      (axi_rdma1_send_write_payload_wlast),
  .m_axi_rdma_send_write_payload_wvalid     (axi_rdma1_send_write_payload_wvalid),
  .m_axi_rdma_send_write_payload_wready     (axi_rdma1_send_write_payload_wready),
  .m_axi_rdma_send_write_payload_awlock     (axi_rdma1_send_write_payload_awlock),
  .m_axi_rdma_send_write_payload_bid        (axi_rdma1_send_write_payload_bid),
  .m_axi_rdma_send_write_payload_bresp      (axi_rdma1_send_write_payload_bresp),
  .m_axi_rdma_send_write_payload_bvalid     (axi_rdma1_send_write_payload_bvalid),
  .m_axi_rdma_send_write_payload_bready     (axi_rdma1_send_write_payload_bready),
  .m_axi_rdma_send_write_payload_arid       (axi_rdma1_send_write_payload_arid),
  .m_axi_rdma_send_write_payload_araddr     (axi_rdma1_send_write_payload_araddr),
  .m_axi_rdma_send_write_payload_arlen      (axi_rdma1_send_write_payload_arlen),
  .m_axi_rdma_send_write_payload_arsize     (axi_rdma1_send_write_payload_arsize),
  .m_axi_rdma_send_write_payload_arburst    (axi_rdma1_send_write_payload_arburst),
  .m_axi_rdma_send_write_payload_arcache    (axi_rdma1_send_write_payload_arcache),
  .m_axi_rdma_send_write_payload_arprot     (axi_rdma1_send_write_payload_arprot),
  .m_axi_rdma_send_write_payload_arvalid    (axi_rdma1_send_write_payload_arvalid),
  .m_axi_rdma_send_write_payload_arready    (axi_rdma1_send_write_payload_arready),
  .m_axi_rdma_send_write_payload_rid        (axi_rdma1_send_write_payload_rid),
  .m_axi_rdma_send_write_payload_rdata      (axi_rdma1_send_write_payload_rdata),
  .m_axi_rdma_send_write_payload_rresp      (axi_rdma1_send_write_payload_rresp),
  .m_axi_rdma_send_write_payload_rlast      (axi_rdma1_send_write_payload_rlast),
  .m_axi_rdma_send_write_payload_rvalid     (axi_rdma1_send_write_payload_rvalid),
  .m_axi_rdma_send_write_payload_rready     (axi_rdma1_send_write_payload_rready),
  .m_axi_rdma_send_write_payload_arlock     (axi_rdma1_send_write_payload_arlock),

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

  // RDMA AXI MM interface used to fetch WQE entries in the send queue from DDR by the QP manager
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
  .m_axi_rdma_get_payload_awid          (m_axi_rdma1_get_payload_awid),
  .m_axi_rdma_get_payload_awaddr        (m_axi_rdma1_get_payload_awaddr),
  .m_axi_rdma_get_payload_awlen         (m_axi_rdma1_get_payload_awlen),
  .m_axi_rdma_get_payload_awsize        (m_axi_rdma1_get_payload_awsize),
  .m_axi_rdma_get_payload_awburst       (m_axi_rdma1_get_payload_awburst),
  .m_axi_rdma_get_payload_awcache       (m_axi_rdma1_get_payload_awcache),
  .m_axi_rdma_get_payload_awprot        (m_axi_rdma1_get_payload_awprot),
  .m_axi_rdma_get_payload_awvalid       (m_axi_rdma1_get_payload_awvalid),
  .m_axi_rdma_get_payload_awready       (m_axi_rdma1_get_payload_awready),
  .m_axi_rdma_get_payload_wdata         (m_axi_rdma1_get_payload_wdata),
  .m_axi_rdma_get_payload_wstrb         (m_axi_rdma1_get_payload_wstrb),
  .m_axi_rdma_get_payload_wlast         (m_axi_rdma1_get_payload_wlast),
  .m_axi_rdma_get_payload_wvalid        (m_axi_rdma1_get_payload_wvalid),
  .m_axi_rdma_get_payload_wready        (m_axi_rdma1_get_payload_wready),
  .m_axi_rdma_get_payload_awlock        (m_axi_rdma1_get_payload_awlock),
  .m_axi_rdma_get_payload_bid           (m_axi_rdma1_get_payload_bid),
  .m_axi_rdma_get_payload_bresp         (m_axi_rdma1_get_payload_bresp),
  .m_axi_rdma_get_payload_bvalid        (m_axi_rdma1_get_payload_bvalid),
  .m_axi_rdma_get_payload_bready        (m_axi_rdma1_get_payload_bready),
  .m_axi_rdma_get_payload_arid          (m_axi_rdma1_get_payload_arid),
  .m_axi_rdma_get_payload_araddr        (m_axi_rdma1_get_payload_araddr),
  .m_axi_rdma_get_payload_arlen         (m_axi_rdma1_get_payload_arlen),
  .m_axi_rdma_get_payload_arsize        (m_axi_rdma1_get_payload_arsize),
  .m_axi_rdma_get_payload_arburst       (m_axi_rdma1_get_payload_arburst),
  .m_axi_rdma_get_payload_arcache       (m_axi_rdma1_get_payload_arcache),
  .m_axi_rdma_get_payload_arprot        (m_axi_rdma1_get_payload_arprot),
  .m_axi_rdma_get_payload_arvalid       (m_axi_rdma1_get_payload_arvalid),
  .m_axi_rdma_get_payload_arready       (m_axi_rdma1_get_payload_arready),
  .m_axi_rdma_get_payload_rid           (m_axi_rdma1_get_payload_rid),
  .m_axi_rdma_get_payload_rdata         (m_axi_rdma1_get_payload_rdata),
  .m_axi_rdma_get_payload_rresp         (m_axi_rdma1_get_payload_rresp),
  .m_axi_rdma_get_payload_rlast         (m_axi_rdma1_get_payload_rlast),
  .m_axi_rdma_get_payload_rvalid        (m_axi_rdma1_get_payload_rvalid),
  .m_axi_rdma_get_payload_rready        (m_axi_rdma1_get_payload_rready),
  .m_axi_rdma_get_payload_arlock        (m_axi_rdma1_get_payload_arlock),

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

  .m_axi_hw_hndshk_to_sys_mem_awid    (axi_hw_hndshk_to_sys_mem_awid),
  .m_axi_hw_hndshk_to_sys_mem_awaddr  (axi_hw_hndshk_to_sys_mem_awaddr),
  .m_axi_hw_hndshk_to_sys_mem_awqos   (axi_hw_hndshk_to_sys_mem_awqos),
  .m_axi_hw_hndshk_to_sys_mem_awlen   (axi_hw_hndshk_to_sys_mem_awlen),
  .m_axi_hw_hndshk_to_sys_mem_awsize  (axi_hw_hndshk_to_sys_mem_awsize),
  .m_axi_hw_hndshk_to_sys_mem_awburst (axi_hw_hndshk_to_sys_mem_awburst),
  .m_axi_hw_hndshk_to_sys_mem_awcache (axi_hw_hndshk_to_sys_mem_awcache),
  .m_axi_hw_hndshk_to_sys_mem_awprot  (axi_hw_hndshk_to_sys_mem_awprot),
  .m_axi_hw_hndshk_to_sys_mem_awvalid (axi_hw_hndshk_to_sys_mem_awvalid),
  .m_axi_hw_hndshk_to_sys_mem_awready (axi_hw_hndshk_to_sys_mem_awready),
  .m_axi_hw_hndshk_to_sys_mem_wdata   (axi_hw_hndshk_to_sys_mem_wdata),
  .m_axi_hw_hndshk_to_sys_mem_wstrb   (axi_hw_hndshk_to_sys_mem_wstrb),
  .m_axi_hw_hndshk_to_sys_mem_wlast   (axi_hw_hndshk_to_sys_mem_wlast),
  .m_axi_hw_hndshk_to_sys_mem_wvalid  (axi_hw_hndshk_to_sys_mem_wvalid),
  .m_axi_hw_hndshk_to_sys_mem_wready  (axi_hw_hndshk_to_sys_mem_wready),
  .m_axi_hw_hndshk_to_sys_mem_awlock  (axi_hw_hndshk_to_sys_mem_awlock),
  .m_axi_hw_hndshk_to_sys_mem_bid     (axi_hw_hndshk_to_sys_mem_bid),
  .m_axi_hw_hndshk_to_sys_mem_bresp   (axi_hw_hndshk_to_sys_mem_bresp),
  .m_axi_hw_hndshk_to_sys_mem_bvalid  (axi_hw_hndshk_to_sys_mem_bvalid),
  .m_axi_hw_hndshk_to_sys_mem_bready  (axi_hw_hndshk_to_sys_mem_bready),
  .m_axi_hw_hndshk_to_sys_mem_arid    (axi_hw_hndshk_to_sys_mem_arid),
  .m_axi_hw_hndshk_to_sys_mem_araddr  (axi_hw_hndshk_to_sys_mem_araddr),
  .m_axi_hw_hndshk_to_sys_mem_arlen   (axi_hw_hndshk_to_sys_mem_arlen),
  .m_axi_hw_hndshk_to_sys_mem_arsize  (axi_hw_hndshk_to_sys_mem_arsize),
  .m_axi_hw_hndshk_to_sys_mem_arburst (axi_hw_hndshk_to_sys_mem_arburst),
  .m_axi_hw_hndshk_to_sys_mem_arcache (axi_hw_hndshk_to_sys_mem_arcache),
  .m_axi_hw_hndshk_to_sys_mem_arprot  (axi_hw_hndshk_to_sys_mem_arprot),
  .m_axi_hw_hndshk_to_sys_mem_arvalid (axi_hw_hndshk_to_sys_mem_arvalid),
  .m_axi_hw_hndshk_to_sys_mem_arready (axi_hw_hndshk_to_sys_mem_arready),
  .m_axi_hw_hndshk_to_sys_mem_rid     (axi_hw_hndshk_to_sys_mem_rid),
  .m_axi_hw_hndshk_to_sys_mem_rdata   (axi_hw_hndshk_to_sys_mem_rdata),
  .m_axi_hw_hndshk_to_sys_mem_rresp   (axi_hw_hndshk_to_sys_mem_rresp),
  .m_axi_hw_hndshk_to_sys_mem_rlast   (axi_hw_hndshk_to_sys_mem_rlast),
  .m_axi_hw_hndshk_to_sys_mem_rvalid  (axi_hw_hndshk_to_sys_mem_rvalid),
  .m_axi_hw_hndshk_to_sys_mem_rready  (axi_hw_hndshk_to_sys_mem_rready),
  .m_axi_hw_hndshk_to_sys_mem_arlock  (axi_hw_hndshk_to_sys_mem_arlock),
  .m_axi_hw_hndshk_to_sys_mem_arqos   (axi_hw_hndshk_to_sys_mem_arqos),

  .rdma_intr(rdma_intr),
  .axil_aclk(axil_clk),
  .axil_rstn(axil_rstn),
  .axis_aclk(axis_clk),
  .axis_rstn(axis_rstn)
);

// Always receive packets sent to CMAC tx path
assign m_axis_cmac_tx_tready =1'b1;

// AXI crossbar used to access device memory
/*
axi_3to1_interconnect_to_dev_mem axi_interconnect_to_dev_mem_inst(
  
  .s_axi_qdma_mm_awid                    (m_axi_init_dev_awid),
  .s_axi_qdma_mm_awaddr                  (m_axi_init_dev_awaddr),
  .s_axi_qdma_mm_awqos                   (m_axi_init_dev_awqos),
  .s_axi_qdma_mm_awlen                   (m_axi_init_dev_awlen),
  .s_axi_qdma_mm_awsize                  (m_axi_init_dev_awsize),
  .s_axi_qdma_mm_awburst                 (m_axi_init_dev_awburst),
  .s_axi_qdma_mm_awcache                 (m_axi_init_dev_awcache),
  .s_axi_qdma_mm_awprot                  (m_axi_init_dev_awprot),
  .s_axi_qdma_mm_awvalid                 (m_axi_init_dev_awvalid),
  .s_axi_qdma_mm_awready                 (m_axi_init_dev_awready),
  .s_axi_qdma_mm_wdata                   (m_axi_init_dev_wdata),
  .s_axi_qdma_mm_wstrb                   (m_axi_init_dev_wstrb),
  .s_axi_qdma_mm_wlast                   (m_axi_init_dev_wlast),
  .s_axi_qdma_mm_wvalid                  (m_axi_init_dev_wvalid),
  .s_axi_qdma_mm_wready                  (m_axi_init_dev_wready),
  .s_axi_qdma_mm_awlock                  (m_axi_init_dev_awlock),
  .s_axi_qdma_mm_bid                     (m_axi_init_dev_bid),
  .s_axi_qdma_mm_bresp                   (m_axi_init_dev_bresp),
  .s_axi_qdma_mm_bvalid                  (m_axi_init_dev_bvalid),
  .s_axi_qdma_mm_bready                  (m_axi_init_dev_bready),
  .s_axi_qdma_mm_arid                    (m_axi_veri_dev_arid),
  .s_axi_qdma_mm_araddr                  (m_axi_veri_dev_araddr),
  .s_axi_qdma_mm_arlen                   (m_axi_veri_dev_arlen),
  .s_axi_qdma_mm_arsize                  (m_axi_veri_dev_arsize),
  .s_axi_qdma_mm_arburst                 (m_axi_veri_dev_arburst),
  .s_axi_qdma_mm_arcache                 (m_axi_veri_dev_arcache),
  .s_axi_qdma_mm_arprot                  (m_axi_veri_dev_arprot),
  .s_axi_qdma_mm_arvalid                 (m_axi_veri_dev_arvalid),
  .s_axi_qdma_mm_arready                 (m_axi_veri_dev_arready),
  .s_axi_qdma_mm_rid                     (m_axi_veri_dev_rid),
  .s_axi_qdma_mm_rdata                   (m_axi_veri_dev_rdata),
  .s_axi_qdma_mm_rresp                   (m_axi_veri_dev_rresp),
  .s_axi_qdma_mm_rlast                   (m_axi_veri_dev_rlast),
  .s_axi_qdma_mm_rvalid                  (m_axi_veri_dev_rvalid),
  .s_axi_qdma_mm_rready                  (m_axi_veri_dev_rready),
  .s_axi_qdma_mm_arlock                  (m_axi_veri_dev_arlock),
  .s_axi_qdma_mm_arqos                   (m_axi_veri_dev_arqos),

  .s_axi_compute_logic_awid              (4'd0),
  .s_axi_compute_logic_awaddr            (64'd0),
  .s_axi_compute_logic_awqos             (4'd0),
  .s_axi_compute_logic_awlen             (8'd0),
  .s_axi_compute_logic_awsize            (3'd0),
  .s_axi_compute_logic_awburst           (2'd0),
  .s_axi_compute_logic_awcache           (4'd0),
  .s_axi_compute_logic_awprot            (3'd0),
  .s_axi_compute_logic_awvalid           (1'b0),
  .s_axi_compute_logic_awready           (),
  .s_axi_compute_logic_wdata             (512'd0),
  .s_axi_compute_logic_wstrb             (64'd0),
  .s_axi_compute_logic_wlast             (1'b0),
  .s_axi_compute_logic_wvalid            (1'b0),
  .s_axi_compute_logic_wready            (),
  .s_axi_compute_logic_awlock            (1'b0),
  .s_axi_compute_logic_bid               (),
  .s_axi_compute_logic_bresp             (),
  .s_axi_compute_logic_bvalid            (),
  .s_axi_compute_logic_bready            (1'b1),
  .s_axi_compute_logic_arid              (4'd0),
  .s_axi_compute_logic_araddr            (64'd0),
  .s_axi_compute_logic_arlen             (8'd0),
  .s_axi_compute_logic_arsize            (3'd0),
  .s_axi_compute_logic_arburst           (2'd0),
  .s_axi_compute_logic_arcache           (4'd0),
  .s_axi_compute_logic_arprot            (3'd0),
  .s_axi_compute_logic_arvalid           (1'b0),
  .s_axi_compute_logic_arready           (),
  .s_axi_compute_logic_rid               (),
  .s_axi_compute_logic_rdata             (),
  .s_axi_compute_logic_rresp             (),
  .s_axi_compute_logic_rlast             (),
  .s_axi_compute_logic_rvalid            (),
  .s_axi_compute_logic_rready            (1'b1),
  .s_axi_compute_logic_arlock            (1'b0),
  .s_axi_compute_logic_arqos             (4'd0),

  .s_axi_from_sys_crossbar_awid          (axi_from_sys_to_dev_crossbar_awid),
  .s_axi_from_sys_crossbar_awaddr        (axi_from_sys_to_dev_crossbar_awaddr),
  .s_axi_from_sys_crossbar_awqos         (axi_from_sys_to_dev_crossbar_awqos),
  .s_axi_from_sys_crossbar_awlen         (axi_from_sys_to_dev_crossbar_awlen),
  .s_axi_from_sys_crossbar_awsize        (axi_from_sys_to_dev_crossbar_awsize),
  .s_axi_from_sys_crossbar_awburst       (axi_from_sys_to_dev_crossbar_awburst),
  .s_axi_from_sys_crossbar_awcache       (axi_from_sys_to_dev_crossbar_awcache),
  .s_axi_from_sys_crossbar_awprot        (axi_from_sys_to_dev_crossbar_awprot),
  .s_axi_from_sys_crossbar_awvalid       (axi_from_sys_to_dev_crossbar_awvalid),
  .s_axi_from_sys_crossbar_awready       (axi_from_sys_to_dev_crossbar_awready),
  .s_axi_from_sys_crossbar_wdata         (axi_from_sys_to_dev_crossbar_wdata),
  .s_axi_from_sys_crossbar_wstrb         (axi_from_sys_to_dev_crossbar_wstrb),
  .s_axi_from_sys_crossbar_wlast         (axi_from_sys_to_dev_crossbar_wlast),
  .s_axi_from_sys_crossbar_wvalid        (axi_from_sys_to_dev_crossbar_wvalid),
  .s_axi_from_sys_crossbar_wready        (axi_from_sys_to_dev_crossbar_wready),
  .s_axi_from_sys_crossbar_awlock        (axi_from_sys_to_dev_crossbar_awlock),
  .s_axi_from_sys_crossbar_bid           (axi_from_sys_to_dev_crossbar_bid),
  .s_axi_from_sys_crossbar_bresp         (axi_from_sys_to_dev_crossbar_bresp),
  .s_axi_from_sys_crossbar_bvalid        (axi_from_sys_to_dev_crossbar_bvalid),
  .s_axi_from_sys_crossbar_bready        (axi_from_sys_to_dev_crossbar_bready),
  .s_axi_from_sys_crossbar_arid          (axi_from_sys_to_dev_crossbar_arid),
  .s_axi_from_sys_crossbar_araddr        (axi_from_sys_to_dev_crossbar_araddr),
  .s_axi_from_sys_crossbar_arlen         (axi_from_sys_to_dev_crossbar_arlen),
  .s_axi_from_sys_crossbar_arsize        (axi_from_sys_to_dev_crossbar_arsize),
  .s_axi_from_sys_crossbar_arburst       (axi_from_sys_to_dev_crossbar_arburst),
  .s_axi_from_sys_crossbar_arcache       (axi_from_sys_to_dev_crossbar_arcache),
  .s_axi_from_sys_crossbar_arprot        (axi_from_sys_to_dev_crossbar_arprot),
  .s_axi_from_sys_crossbar_arvalid       (axi_from_sys_to_dev_crossbar_arvalid),
  .s_axi_from_sys_crossbar_arready       (axi_from_sys_to_dev_crossbar_arready),
  .s_axi_from_sys_crossbar_rid           (axi_from_sys_to_dev_crossbar_rid),
  .s_axi_from_sys_crossbar_rdata         (axi_from_sys_to_dev_crossbar_rdata),
  .s_axi_from_sys_crossbar_rresp         (axi_from_sys_to_dev_crossbar_rresp),
  .s_axi_from_sys_crossbar_rlast         (axi_from_sys_to_dev_crossbar_rlast),
  .s_axi_from_sys_crossbar_rvalid        (axi_from_sys_to_dev_crossbar_rvalid),
  .s_axi_from_sys_crossbar_rready        (axi_from_sys_to_dev_crossbar_rready),
  .s_axi_from_sys_crossbar_arlock        (axi_from_sys_to_dev_crossbar_arlock),
  .s_axi_from_sys_crossbar_arqos         (axi_from_sys_to_dev_crossbar_arqos),

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

  .axis_aclk                             (axis_clk),
  .axis_arestn                           (axis_rstn)   
);*/

axi_2to1_interconnect_to_dev_mem axi_interconnect_to_dev_mem_inst(
  .s_axi_qdma_mm_awid                    (m_axi_init_dev_awid),
  .s_axi_qdma_mm_awaddr                  (m_axi_init_dev_awaddr),
  .s_axi_qdma_mm_awqos                   (m_axi_init_dev_awqos),
  .s_axi_qdma_mm_awlen                   (m_axi_init_dev_awlen),
  .s_axi_qdma_mm_awsize                  (m_axi_init_dev_awsize),
  .s_axi_qdma_mm_awburst                 (m_axi_init_dev_awburst),
  .s_axi_qdma_mm_awcache                 (m_axi_init_dev_awcache),
  .s_axi_qdma_mm_awprot                  (m_axi_init_dev_awprot),
  .s_axi_qdma_mm_awvalid                 (m_axi_init_dev_awvalid),
  .s_axi_qdma_mm_awready                 (m_axi_init_dev_awready),
  .s_axi_qdma_mm_wdata                   (m_axi_init_dev_wdata),
  .s_axi_qdma_mm_wstrb                   (m_axi_init_dev_wstrb),
  .s_axi_qdma_mm_wlast                   (m_axi_init_dev_wlast),
  .s_axi_qdma_mm_wvalid                  (m_axi_init_dev_wvalid),
  .s_axi_qdma_mm_wready                  (m_axi_init_dev_wready),
  .s_axi_qdma_mm_awlock                  (m_axi_init_dev_awlock),
  .s_axi_qdma_mm_bid                     (m_axi_init_dev_bid),
  .s_axi_qdma_mm_bresp                   (m_axi_init_dev_bresp),
  .s_axi_qdma_mm_bvalid                  (m_axi_init_dev_bvalid),
  .s_axi_qdma_mm_bready                  (m_axi_init_dev_bready),
  .s_axi_qdma_mm_arid                    (m_axi_veri_dev_arid),
  .s_axi_qdma_mm_araddr                  (m_axi_veri_dev_araddr),
  .s_axi_qdma_mm_arlen                   (m_axi_veri_dev_arlen),
  .s_axi_qdma_mm_arsize                  (m_axi_veri_dev_arsize),
  .s_axi_qdma_mm_arburst                 (m_axi_veri_dev_arburst),
  .s_axi_qdma_mm_arcache                 (m_axi_veri_dev_arcache),
  .s_axi_qdma_mm_arprot                  (m_axi_veri_dev_arprot),
  .s_axi_qdma_mm_arvalid                 (m_axi_veri_dev_arvalid),
  .s_axi_qdma_mm_arready                 (m_axi_veri_dev_arready),
  .s_axi_qdma_mm_rid                     (m_axi_veri_dev_rid),
  .s_axi_qdma_mm_rdata                   (m_axi_veri_dev_rdata),
  .s_axi_qdma_mm_rresp                   (m_axi_veri_dev_rresp),
  .s_axi_qdma_mm_rlast                   (m_axi_veri_dev_rlast),
  .s_axi_qdma_mm_rvalid                  (m_axi_veri_dev_rvalid),
  .s_axi_qdma_mm_rready                  (m_axi_veri_dev_rready),
  .s_axi_qdma_mm_arlock                  (m_axi_veri_dev_arlock),
  .s_axi_qdma_mm_arqos                   (m_axi_veri_dev_arqos),

    .s_axi_from_sys_crossbar_awid          ({1'b0,axi_from_sys_to_dev_crossbar_awid}),
    .s_axi_from_sys_crossbar_awaddr        (axi_from_sys_to_dev_crossbar_awaddr),
    .s_axi_from_sys_crossbar_awqos         (axi_from_sys_to_dev_crossbar_awqos),
    .s_axi_from_sys_crossbar_awlen         (axi_from_sys_to_dev_crossbar_awlen),
    .s_axi_from_sys_crossbar_awsize        (axi_from_sys_to_dev_crossbar_awsize),
    .s_axi_from_sys_crossbar_awburst       (axi_from_sys_to_dev_crossbar_awburst),
    .s_axi_from_sys_crossbar_awcache       (axi_from_sys_to_dev_crossbar_awcache),
    .s_axi_from_sys_crossbar_awprot        (axi_from_sys_to_dev_crossbar_awprot),
    .s_axi_from_sys_crossbar_awvalid       (axi_from_sys_to_dev_crossbar_awvalid),
    .s_axi_from_sys_crossbar_awready       (axi_from_sys_to_dev_crossbar_awready),
    .s_axi_from_sys_crossbar_wdata         (axi_from_sys_to_dev_crossbar_wdata),
    .s_axi_from_sys_crossbar_wstrb         (axi_from_sys_to_dev_crossbar_wstrb),
    .s_axi_from_sys_crossbar_wlast         (axi_from_sys_to_dev_crossbar_wlast),
    .s_axi_from_sys_crossbar_wvalid        (axi_from_sys_to_dev_crossbar_wvalid),
    .s_axi_from_sys_crossbar_wready        (axi_from_sys_to_dev_crossbar_wready),
    .s_axi_from_sys_crossbar_awlock        (axi_from_sys_to_dev_crossbar_awlock),
    .s_axi_from_sys_crossbar_bid           (axi_from_sys_to_dev_crossbar_bid),
    .s_axi_from_sys_crossbar_bresp         (axi_from_sys_to_dev_crossbar_bresp),
    .s_axi_from_sys_crossbar_bvalid        (axi_from_sys_to_dev_crossbar_bvalid),
    .s_axi_from_sys_crossbar_bready        (axi_from_sys_to_dev_crossbar_bready),
    .s_axi_from_sys_crossbar_arid          ({1'b0,axi_from_sys_to_dev_crossbar_arid}),
    .s_axi_from_sys_crossbar_araddr        (axi_from_sys_to_dev_crossbar_araddr),
    .s_axi_from_sys_crossbar_arlen         (axi_from_sys_to_dev_crossbar_arlen),
    .s_axi_from_sys_crossbar_arsize        (axi_from_sys_to_dev_crossbar_arsize),
    .s_axi_from_sys_crossbar_arburst       (axi_from_sys_to_dev_crossbar_arburst),
    .s_axi_from_sys_crossbar_arcache       (axi_from_sys_to_dev_crossbar_arcache),
    .s_axi_from_sys_crossbar_arprot        (axi_from_sys_to_dev_crossbar_arprot),
    .s_axi_from_sys_crossbar_arvalid       (axi_from_sys_to_dev_crossbar_arvalid),
    .s_axi_from_sys_crossbar_arready       (axi_from_sys_to_dev_crossbar_arready),
    .s_axi_from_sys_crossbar_rid           (axi_from_sys_to_dev_crossbar_rid),
    .s_axi_from_sys_crossbar_rdata         (axi_from_sys_to_dev_crossbar_rdata),
    .s_axi_from_sys_crossbar_rresp         (axi_from_sys_to_dev_crossbar_rresp),
    .s_axi_from_sys_crossbar_rlast         (axi_from_sys_to_dev_crossbar_rlast),
    .s_axi_from_sys_crossbar_rvalid        (axi_from_sys_to_dev_crossbar_rvalid),
    .s_axi_from_sys_crossbar_rready        (axi_from_sys_to_dev_crossbar_rready),
    .s_axi_from_sys_crossbar_arlock        (axi_from_sys_to_dev_crossbar_arlock),
    .s_axi_from_sys_crossbar_arqos         (axi_from_sys_to_dev_crossbar_arqos),

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

    .axis_aclk                             (axis_clk),
    .axis_arestn                           (axis_rstn)
);

axi_interconnect_to_dev_mem axi_2to1_for_send_write_payload_to_dev_mem(
  .s_axi_rdma_send_write_payload_awid    (axi_rdma1_send_write_payload_awid),
  .s_axi_rdma_send_write_payload_awaddr  (axi_rdma1_send_write_payload_awaddr),
  .s_axi_rdma_send_write_payload_awqos   (axi_rdma1_send_write_payload_awqos),
  .s_axi_rdma_send_write_payload_awlen   (axi_rdma1_send_write_payload_awlen),
  .s_axi_rdma_send_write_payload_awsize  (axi_rdma1_send_write_payload_awsize),
  .s_axi_rdma_send_write_payload_awburst (axi_rdma1_send_write_payload_awburst),
  .s_axi_rdma_send_write_payload_awcache (axi_rdma1_send_write_payload_awcache),
  .s_axi_rdma_send_write_payload_awprot  (axi_rdma1_send_write_payload_awprot),
  .s_axi_rdma_send_write_payload_awvalid (axi_rdma1_send_write_payload_awvalid),
  .s_axi_rdma_send_write_payload_awready (axi_rdma1_send_write_payload_awready),
  .s_axi_rdma_send_write_payload_wdata   (axi_rdma1_send_write_payload_wdata),
  .s_axi_rdma_send_write_payload_wstrb   (axi_rdma1_send_write_payload_wstrb),
  .s_axi_rdma_send_write_payload_wlast   (axi_rdma1_send_write_payload_wlast),
  .s_axi_rdma_send_write_payload_wvalid  (axi_rdma1_send_write_payload_wvalid),
  .s_axi_rdma_send_write_payload_wready  (axi_rdma1_send_write_payload_wready),
  .s_axi_rdma_send_write_payload_awlock  (axi_rdma1_send_write_payload_awlock),
  .s_axi_rdma_send_write_payload_bid     (axi_rdma1_send_write_payload_bid),
  .s_axi_rdma_send_write_payload_bresp   (axi_rdma1_send_write_payload_bresp),
  .s_axi_rdma_send_write_payload_bvalid  (axi_rdma1_send_write_payload_bvalid),
  .s_axi_rdma_send_write_payload_bready  (axi_rdma1_send_write_payload_bready),
  .s_axi_rdma_send_write_payload_arid    (axi_rdma1_send_write_payload_arid),
  .s_axi_rdma_send_write_payload_araddr  (axi_rdma1_send_write_payload_araddr),
  .s_axi_rdma_send_write_payload_arlen   (axi_rdma1_send_write_payload_arlen),
  .s_axi_rdma_send_write_payload_arsize  (axi_rdma1_send_write_payload_arsize),
  .s_axi_rdma_send_write_payload_arburst (axi_rdma1_send_write_payload_arburst),
  .s_axi_rdma_send_write_payload_arcache (axi_rdma1_send_write_payload_arcache),
  .s_axi_rdma_send_write_payload_arprot  (axi_rdma1_send_write_payload_arprot),
  .s_axi_rdma_send_write_payload_arvalid (axi_rdma1_send_write_payload_arvalid),
  .s_axi_rdma_send_write_payload_arready (axi_rdma1_send_write_payload_arready),
  .s_axi_rdma_send_write_payload_rid     (axi_rdma1_send_write_payload_rid),
  .s_axi_rdma_send_write_payload_rdata   (axi_rdma1_send_write_payload_rdata),
  .s_axi_rdma_send_write_payload_rresp   (axi_rdma1_send_write_payload_rresp),
  .s_axi_rdma_send_write_payload_rlast   (axi_rdma1_send_write_payload_rlast),
  .s_axi_rdma_send_write_payload_rvalid  (axi_rdma1_send_write_payload_rvalid),
  .s_axi_rdma_send_write_payload_rready  (axi_rdma1_send_write_payload_rready),
  .s_axi_rdma_send_write_payload_arlock  (axi_rdma1_send_write_payload_arlock),
  .s_axi_rdma_send_write_payload_arqos   (axi_rdma1_send_write_payload_arqos),

  .s_axi_rdma_rsp_payload_awid           (axi_rdma2_send_write_payload_awid),
  .s_axi_rdma_rsp_payload_awaddr         (axi_rdma2_send_write_payload_awaddr),
  .s_axi_rdma_rsp_payload_awqos          (axi_rdma2_send_write_payload_awqos),
  .s_axi_rdma_rsp_payload_awlen          (axi_rdma2_send_write_payload_awlen),
  .s_axi_rdma_rsp_payload_awsize         (axi_rdma2_send_write_payload_awsize),
  .s_axi_rdma_rsp_payload_awburst        (axi_rdma2_send_write_payload_awburst),
  .s_axi_rdma_rsp_payload_awcache        (axi_rdma2_send_write_payload_awcache),
  .s_axi_rdma_rsp_payload_awprot         (axi_rdma2_send_write_payload_awprot),
  .s_axi_rdma_rsp_payload_awvalid        (axi_rdma2_send_write_payload_awvalid),
  .s_axi_rdma_rsp_payload_awready        (axi_rdma2_send_write_payload_awready),
  .s_axi_rdma_rsp_payload_wdata          (axi_rdma2_send_write_payload_wdata),
  .s_axi_rdma_rsp_payload_wstrb          (axi_rdma2_send_write_payload_wstrb),
  .s_axi_rdma_rsp_payload_wlast          (axi_rdma2_send_write_payload_wlast),
  .s_axi_rdma_rsp_payload_wvalid         (axi_rdma2_send_write_payload_wvalid),
  .s_axi_rdma_rsp_payload_wready         (axi_rdma2_send_write_payload_wready),
  .s_axi_rdma_rsp_payload_awlock         (axi_rdma2_send_write_payload_awlock),
  .s_axi_rdma_rsp_payload_bid            (axi_rdma2_send_write_payload_bid),
  .s_axi_rdma_rsp_payload_bresp          (axi_rdma2_send_write_payload_bresp),
  .s_axi_rdma_rsp_payload_bvalid         (axi_rdma2_send_write_payload_bvalid),
  .s_axi_rdma_rsp_payload_bready         (axi_rdma2_send_write_payload_bready),
  .s_axi_rdma_rsp_payload_arid           (axi_rdma2_send_write_payload_arid),
  .s_axi_rdma_rsp_payload_araddr         (axi_rdma2_send_write_payload_araddr),
  .s_axi_rdma_rsp_payload_arlen          (axi_rdma2_send_write_payload_arlen),
  .s_axi_rdma_rsp_payload_arsize         (axi_rdma2_send_write_payload_arsize),
  .s_axi_rdma_rsp_payload_arburst        (axi_rdma2_send_write_payload_arburst),
  .s_axi_rdma_rsp_payload_arcache        (axi_rdma2_send_write_payload_arcache),
  .s_axi_rdma_rsp_payload_arprot         (axi_rdma2_send_write_payload_arprot),
  .s_axi_rdma_rsp_payload_arvalid        (axi_rdma2_send_write_payload_arvalid),
  .s_axi_rdma_rsp_payload_arready        (axi_rdma2_send_write_payload_arready),
  .s_axi_rdma_rsp_payload_rid            (axi_rdma2_send_write_payload_rid),
  .s_axi_rdma_rsp_payload_rdata          (axi_rdma2_send_write_payload_rdata),
  .s_axi_rdma_rsp_payload_rresp          (axi_rdma2_send_write_payload_rresp),
  .s_axi_rdma_rsp_payload_rlast          (axi_rdma2_send_write_payload_rlast),
  .s_axi_rdma_rsp_payload_rvalid         (axi_rdma2_send_write_payload_rvalid),
  .s_axi_rdma_rsp_payload_rready         (axi_rdma2_send_write_payload_rready),
  .s_axi_rdma_rsp_payload_arlock         (axi_rdma2_send_write_payload_arlock),
  .s_axi_rdma_rsp_payload_arqos          (axi_rdma2_send_write_payload_arqos),

  .s_axi_qdma_mm_awid                    (4'd0),
  .s_axi_qdma_mm_awaddr                  (64'd0),
  .s_axi_qdma_mm_awqos                   (4'd0),
  .s_axi_qdma_mm_awlen                   (8'd0),
  .s_axi_qdma_mm_awsize                  (3'd0),
  .s_axi_qdma_mm_awburst                 (2'd0),
  .s_axi_qdma_mm_awcache                 (4'd0),
  .s_axi_qdma_mm_awprot                  (3'd0),
  .s_axi_qdma_mm_awvalid                 (1'b0),
  .s_axi_qdma_mm_awready                 (),
  .s_axi_qdma_mm_wdata                   (512'd0),
  .s_axi_qdma_mm_wstrb                   (64'd0),
  .s_axi_qdma_mm_wlast                   (1'b0),
  .s_axi_qdma_mm_wvalid                  (1'b0),
  .s_axi_qdma_mm_wready                  (),
  .s_axi_qdma_mm_awlock                  (1'b0),
  .s_axi_qdma_mm_bid                     (),
  .s_axi_qdma_mm_bresp                   (),
  .s_axi_qdma_mm_bvalid                  (),
  .s_axi_qdma_mm_bready                  (1'b1),
  .s_axi_qdma_mm_arid                    (4'd0),
  .s_axi_qdma_mm_araddr                  (64'd0),
  .s_axi_qdma_mm_arlen                   (8'd0),
  .s_axi_qdma_mm_arsize                  (3'd0),
  .s_axi_qdma_mm_arburst                 (2'd0),
  .s_axi_qdma_mm_arcache                 (4'd0),
  .s_axi_qdma_mm_arprot                  (3'd0),
  .s_axi_qdma_mm_arvalid                 (1'b0),
  .s_axi_qdma_mm_arready                 (),
  .s_axi_qdma_mm_rid                     (),
  .s_axi_qdma_mm_rdata                   (),
  .s_axi_qdma_mm_rresp                   (),
  .s_axi_qdma_mm_rlast                   (),
  .s_axi_qdma_mm_rvalid                  (),
  .s_axi_qdma_mm_rready                  (1'b1),
  .s_axi_qdma_mm_arlock                  (1'b0),
  .s_axi_qdma_mm_arqos                   (4'd0),

  .s_axi_compute_logic_awid              (4'd0),
  .s_axi_compute_logic_awaddr            (64'd0),
  .s_axi_compute_logic_awqos             (4'd0),
  .s_axi_compute_logic_awlen             (8'd0),
  .s_axi_compute_logic_awsize            (3'd0),
  .s_axi_compute_logic_awburst           (2'd0),
  .s_axi_compute_logic_awcache           (4'd0),
  .s_axi_compute_logic_awprot            (3'd0),
  .s_axi_compute_logic_awvalid           (1'b0),
  .s_axi_compute_logic_awready           (),
  .s_axi_compute_logic_wdata             (512'd0),
  .s_axi_compute_logic_wstrb             (64'd0),
  .s_axi_compute_logic_wlast             (1'b0),
  .s_axi_compute_logic_wvalid            (1'b0),
  .s_axi_compute_logic_wready            (),
  .s_axi_compute_logic_awlock            (1'b0),
  .s_axi_compute_logic_bid               (),
  .s_axi_compute_logic_bresp             (),
  .s_axi_compute_logic_bvalid            (),
  .s_axi_compute_logic_bready            (1'b1),
  .s_axi_compute_logic_arid              (4'd0),
  .s_axi_compute_logic_araddr            (64'd0),
  .s_axi_compute_logic_arlen             (8'd0),
  .s_axi_compute_logic_arsize            (3'd0),
  .s_axi_compute_logic_arburst           (2'd0),
  .s_axi_compute_logic_arcache           (4'd0),
  .s_axi_compute_logic_arprot            (3'd0),
  .s_axi_compute_logic_arvalid           (1'b0),
  .s_axi_compute_logic_arready           (),
  .s_axi_compute_logic_rid               (),
  .s_axi_compute_logic_rdata             (),
  .s_axi_compute_logic_rresp             (),
  .s_axi_compute_logic_rlast             (),
  .s_axi_compute_logic_rvalid            (),
  .s_axi_compute_logic_rready            (1'b1),
  .s_axi_compute_logic_arlock            (1'b0),
  .s_axi_compute_logic_arqos             (4'd0),

  .m_axi_dev_mem_awaddr                  (axi_rdma_send_write_payload_awaddr),
  .m_axi_dev_mem_awprot                  (axi_rdma_send_write_payload_awprot),
  .m_axi_dev_mem_awvalid                 (axi_rdma_send_write_payload_awvalid),
  .m_axi_dev_mem_awready                 (axi_rdma_send_write_payload_awready),
  .m_axi_dev_mem_awsize                  (axi_rdma_send_write_payload_awsize),
  .m_axi_dev_mem_awburst                 (axi_rdma_send_write_payload_awburst),
  .m_axi_dev_mem_awcache                 (axi_rdma_send_write_payload_awcache),
  .m_axi_dev_mem_awlen                   (axi_rdma_send_write_payload_awlen),
  .m_axi_dev_mem_awlock                  (axi_rdma_send_write_payload_awlock),
  .m_axi_dev_mem_awqos                   (axi_rdma_send_write_payload_awqos),
  .m_axi_dev_mem_awregion                (),
  .m_axi_dev_mem_awid                    (axi_rdma_send_write_payload_awid),
  .m_axi_dev_mem_wdata                   (axi_rdma_send_write_payload_wdata),
  .m_axi_dev_mem_wstrb                   (axi_rdma_send_write_payload_wstrb),
  .m_axi_dev_mem_wvalid                  (axi_rdma_send_write_payload_wvalid),
  .m_axi_dev_mem_wready                  (axi_rdma_send_write_payload_wready),
  .m_axi_dev_mem_wlast                   (axi_rdma_send_write_payload_wlast),
  .m_axi_dev_mem_bresp                   (axi_rdma_send_write_payload_bresp),
  .m_axi_dev_mem_bvalid                  (axi_rdma_send_write_payload_bvalid),
  .m_axi_dev_mem_bready                  (axi_rdma_send_write_payload_bready),
  .m_axi_dev_mem_bid                     ({1'b0, axi_rdma_send_write_payload_bid}),
  .m_axi_dev_mem_araddr                  (axi_rdma_send_write_payload_araddr),
  .m_axi_dev_mem_arprot                  (axi_rdma_send_write_payload_arprot),
  .m_axi_dev_mem_arvalid                 (axi_rdma_send_write_payload_arvalid),
  .m_axi_dev_mem_arready                 (axi_rdma_send_write_payload_arready),
  .m_axi_dev_mem_arsize                  (axi_rdma_send_write_payload_arsize),
  .m_axi_dev_mem_arburst                 (axi_rdma_send_write_payload_arburst),
  .m_axi_dev_mem_arcache                 (axi_rdma_send_write_payload_arcache),
  .m_axi_dev_mem_arlock                  (axi_rdma_send_write_payload_arlock),
  .m_axi_dev_mem_arlen                   (axi_rdma_send_write_payload_arlen),
  .m_axi_dev_mem_arqos                   (axi_rdma_send_write_payload_arqos),
  .m_axi_dev_mem_arregion                (),
  .m_axi_dev_mem_arid                    (axi_rdma_send_write_payload_arid),
  .m_axi_dev_mem_rdata                   (axi_rdma_send_write_payload_rdata),
  .m_axi_dev_mem_rresp                   (axi_rdma_send_write_payload_rresp),
  .m_axi_dev_mem_rvalid                  (axi_rdma_send_write_payload_rvalid),
  .m_axi_dev_mem_rready                  (axi_rdma_send_write_payload_rready),
  .m_axi_dev_mem_rlast                   (axi_rdma_send_write_payload_rlast),
  .m_axi_dev_mem_rid                     ({1'b0, axi_rdma_send_write_payload_rid}), 

  .axis_aclk   (axis_clk),
  .axis_arestn (axis_rstn)   
);

xpm_fifo_sync #(
  .DOUT_RESET_VALUE    ("0"),
  .ECC_MODE            ("no_ecc"),
  .FIFO_MEMORY_TYPE    ("auto"),
  .FIFO_READ_LATENCY   (0),
  .FIFO_WRITE_DEPTH    (1024),
  .PROG_FULL_THRESH    (1024-5),
  .READ_DATA_WIDTH     (1),
  .READ_MODE           ("std"),
  .WRITE_DATA_WIDTH    (1)
) rdma_send_write_awid_fifo (
  .wr_en         (axi_rdma_send_write_payload_awready && axi_rdma_send_write_payload_awvalid),
  .din           (axi_rdma_send_write_payload_awid),
  .wr_ack        (),
  .rd_en         (axi_rdma_send_write_payload_bvalid),//axi_rdma_completion_or_init_sys_wready && axi_rdma_completion_or_init_sys_wvalid && axi_rdma_completion_or_init_sys_wlast
  .data_valid    (),
  .dout          (axi_rdma_send_write_payload_bid),

  .wr_data_count (),
  .rd_data_count (),

  .empty         (),
  .full          (),
  .almost_empty  (),
  .almost_full   (),
  .overflow      (),
  .underflow     (),
  .prog_empty    (),
  .prog_full     (),
  .sleep         (1'b0),

  .sbiterr       (),
  .dbiterr       (),
  .injectsbiterr (1'b0),
  .injectdbiterr (1'b0),

  .wr_clk        (axis_clk),
  .rst           (~axis_rstn),
  .rd_rst_busy   (),
  .wr_rst_busy   ()
);

assign axi_rdma1_send_write_payload_awqos = 4'd0;
assign axi_rdma1_send_write_payload_arqos = 4'd0;
assign axi_rdma2_send_write_payload_awqos = 4'd0;
assign axi_rdma2_send_write_payload_arqos = 4'd0;

axi_5to2_interconnect_to_sys_mem axi_interconnect_to_sys_mem_inst(
  .s_axi_rdma_get_wqe_awid              (axi_rdma_get_wqe_awid),//{2'd0,axi_rdma_get_wqe_awid}
  .s_axi_rdma_get_wqe_awaddr            (axi_rdma_get_wqe_awaddr),
  .s_axi_rdma_get_wqe_awqos             (axi_rdma_get_wqe_awqos),
  .s_axi_rdma_get_wqe_awlen             (axi_rdma_get_wqe_awlen),
  .s_axi_rdma_get_wqe_awsize            (axi_rdma_get_wqe_awsize),
  .s_axi_rdma_get_wqe_awburst           (axi_rdma_get_wqe_awburst),
  .s_axi_rdma_get_wqe_awcache           (axi_rdma_get_wqe_awcache),
  .s_axi_rdma_get_wqe_awprot            (axi_rdma_get_wqe_awprot),
  .s_axi_rdma_get_wqe_awvalid           (axi_rdma_get_wqe_awvalid),
  .s_axi_rdma_get_wqe_awready           (axi_rdma_get_wqe_awready),
  .s_axi_rdma_get_wqe_wdata             (axi_rdma_get_wqe_wdata),
  .s_axi_rdma_get_wqe_wstrb             (axi_rdma_get_wqe_wstrb),
  .s_axi_rdma_get_wqe_wlast             (axi_rdma_get_wqe_wlast),
  .s_axi_rdma_get_wqe_wvalid            (axi_rdma_get_wqe_wvalid),
  .s_axi_rdma_get_wqe_wready            (axi_rdma_get_wqe_wready),    
  .s_axi_rdma_get_wqe_awlock            (axi_rdma_get_wqe_awlock),
  .s_axi_rdma_get_wqe_bid               (axi_rdma_get_wqe_bid),//{two_unused_bit8,axi_rdma_get_wqe_bid}
  .s_axi_rdma_get_wqe_bresp             (axi_rdma_get_wqe_bresp),
  .s_axi_rdma_get_wqe_bvalid            (axi_rdma_get_wqe_bvalid),
  .s_axi_rdma_get_wqe_bready            (axi_rdma_get_wqe_bready),
  .s_axi_rdma_get_wqe_arid              (axi_rdma_get_wqe_arid),//{2'd0,axi_rdma_get_wqe_arid}
  .s_axi_rdma_get_wqe_araddr            (axi_rdma_get_wqe_araddr),
  .s_axi_rdma_get_wqe_arlen             (axi_rdma_get_wqe_arlen),
  .s_axi_rdma_get_wqe_arsize            (axi_rdma_get_wqe_arsize),
  .s_axi_rdma_get_wqe_arburst           (axi_rdma_get_wqe_arburst),
  .s_axi_rdma_get_wqe_arcache           (axi_rdma_get_wqe_arcache),
  .s_axi_rdma_get_wqe_arprot            (axi_rdma_get_wqe_arprot),
  .s_axi_rdma_get_wqe_arvalid           (axi_rdma_get_wqe_arvalid),
  .s_axi_rdma_get_wqe_arready           (axi_rdma_get_wqe_arready),
  .s_axi_rdma_get_wqe_rid               (axi_rdma_get_wqe_rid),//{two_unused_bit7,axi_rdma_get_wqe_rid}
  .s_axi_rdma_get_wqe_rdata             (axi_rdma_get_wqe_rdata),
  .s_axi_rdma_get_wqe_rresp             (axi_rdma_get_wqe_rresp),
  .s_axi_rdma_get_wqe_rlast             (axi_rdma_get_wqe_rlast),
  .s_axi_rdma_get_wqe_rvalid            (axi_rdma_get_wqe_rvalid),
  .s_axi_rdma_get_wqe_rready            (axi_rdma_get_wqe_rready),
  .s_axi_rdma_get_wqe_arlock            (axi_rdma_get_wqe_arlock),
  .s_axi_rdma_get_wqe_arqos             (axi_rdma_get_wqe_arqos),

  .s_axi_rdma_get_payload_awid          (axi_rdma_get_payload_awid),//{1'b0,axi_rdma_get_payload_awid}
  .s_axi_rdma_get_payload_awaddr        (axi_rdma_get_payload_awaddr),
  .s_axi_rdma_get_payload_awqos         (axi_rdma_get_payload_awqos),
  .s_axi_rdma_get_payload_awlen         (axi_rdma_get_payload_awlen),
  .s_axi_rdma_get_payload_awsize        (axi_rdma_get_payload_awsize),
  .s_axi_rdma_get_payload_awburst       (axi_rdma_get_payload_awburst),
  .s_axi_rdma_get_payload_awcache       (axi_rdma_get_payload_awcache),
  .s_axi_rdma_get_payload_awprot        (axi_rdma_get_payload_awprot),
  .s_axi_rdma_get_payload_awvalid       (axi_rdma_get_payload_awvalid),
  .s_axi_rdma_get_payload_awready       (axi_rdma_get_payload_awready),
  .s_axi_rdma_get_payload_wdata         (axi_rdma_get_payload_wdata),
  .s_axi_rdma_get_payload_wstrb         (axi_rdma_get_payload_wstrb),
  .s_axi_rdma_get_payload_wlast         (axi_rdma_get_payload_wlast),
  .s_axi_rdma_get_payload_wvalid        (axi_rdma_get_payload_wvalid),
  .s_axi_rdma_get_payload_wready        (axi_rdma_get_payload_wready),
  .s_axi_rdma_get_payload_awlock        (axi_rdma_get_payload_awlock),
  .s_axi_rdma_get_payload_bid           (),//{one_unused_bit0,axi_rdma_get_payload_bid}
  .s_axi_rdma_get_payload_bresp         (axi_rdma_get_payload_bresp),
  .s_axi_rdma_get_payload_bvalid        (axi_rdma_get_payload_bvalid),
  .s_axi_rdma_get_payload_bready        (axi_rdma_get_payload_bready),
  .s_axi_rdma_get_payload_arid          (axi_rdma_get_payload_arid),//{1'b0,axi_rdma_get_payload_arid}
  .s_axi_rdma_get_payload_araddr        (axi_rdma_get_payload_araddr),
  .s_axi_rdma_get_payload_arlen         (axi_rdma_get_payload_arlen),
  .s_axi_rdma_get_payload_arsize        (axi_rdma_get_payload_arsize),
  .s_axi_rdma_get_payload_arburst       (axi_rdma_get_payload_arburst),
  .s_axi_rdma_get_payload_arcache       (axi_rdma_get_payload_arcache),
  .s_axi_rdma_get_payload_arprot        (axi_rdma_get_payload_arprot),
  .s_axi_rdma_get_payload_arvalid       (axi_rdma_get_payload_arvalid),
  .s_axi_rdma_get_payload_arready       (axi_rdma_get_payload_arready),
  //.s_axi_rdma_get_payload_rid           ({one_unused_bit1,axi_rdma_get_payload_rid}),
  .s_axi_rdma_get_payload_rid           (),
  .s_axi_rdma_get_payload_rdata         (axi_rdma_get_payload_rdata),
  .s_axi_rdma_get_payload_rresp         (axi_rdma_get_payload_rresp),
  .s_axi_rdma_get_payload_rlast         (axi_rdma_get_payload_rlast),
  .s_axi_rdma_get_payload_rvalid        (axi_rdma_get_payload_rvalid),
  .s_axi_rdma_get_payload_rready        (axi_rdma_get_payload_rready),
  .s_axi_rdma_get_payload_arlock        (axi_rdma_get_payload_arlock),
  .s_axi_rdma_get_payload_arqos         (axi_rdma_get_payload_arqos),

  .s_axi_rdma_completion_awid           (0),//{2'd0,axi_rdma_completion_awid}
  .s_axi_rdma_completion_awaddr         (axi_rdma_completion_or_init_sys_awaddr),
  .s_axi_rdma_completion_awqos          (axi_rdma_completion_or_init_sys_awqos),
  .s_axi_rdma_completion_awlen          (axi_rdma_completion_or_init_sys_awlen),
  .s_axi_rdma_completion_awsize         (axi_rdma_completion_or_init_sys_awsize),
  .s_axi_rdma_completion_awburst        (axi_rdma_completion_or_init_sys_awburst),
  .s_axi_rdma_completion_awcache        (axi_rdma_completion_or_init_sys_awcache),
  .s_axi_rdma_completion_awprot         (axi_rdma_completion_or_init_sys_awprot),
  .s_axi_rdma_completion_awvalid        (axi_rdma_completion_or_init_sys_awvalid),
  .s_axi_rdma_completion_awready        (axi_rdma_completion_or_init_sys_awready),
  .s_axi_rdma_completion_wdata          (axi_rdma_completion_or_init_sys_wdata),
  .s_axi_rdma_completion_wstrb          (axi_rdma_completion_or_init_sys_wstrb),
  .s_axi_rdma_completion_wlast          (axi_rdma_completion_or_init_sys_wlast),
  .s_axi_rdma_completion_wvalid         (axi_rdma_completion_or_init_sys_wvalid),
  .s_axi_rdma_completion_wready         (axi_rdma_completion_or_init_sys_wready),
  .s_axi_rdma_completion_awlock         (axi_rdma_completion_or_init_sys_awlock),
  .s_axi_rdma_completion_bid            (),//{two_unused_bit6,axi_rdma_completion_bid}
  .s_axi_rdma_completion_bresp          (axi_rdma_completion_or_init_sys_bresp),
  .s_axi_rdma_completion_bvalid         (axi_rdma_completion_or_init_sys_bvalid),
  .s_axi_rdma_completion_bready         (axi_rdma_completion_or_init_sys_bready),
  .s_axi_rdma_completion_arid           (axi_rdma_completion_or_init_sys_arid),//{2'd0,axi_rdma_completion_arid}
  .s_axi_rdma_completion_araddr         (axi_rdma_completion_or_init_sys_araddr),
  .s_axi_rdma_completion_arlen          (axi_rdma_completion_or_init_sys_arlen),
  .s_axi_rdma_completion_arsize         (axi_rdma_completion_or_init_sys_arsize),
  .s_axi_rdma_completion_arburst        (axi_rdma_completion_or_init_sys_arburst),
  .s_axi_rdma_completion_arcache        (axi_rdma_completion_or_init_sys_arcache),
  .s_axi_rdma_completion_arprot         (axi_rdma_completion_or_init_sys_arprot),
  .s_axi_rdma_completion_arvalid        (axi_rdma_completion_or_init_sys_arvalid),
  .s_axi_rdma_completion_arready        (axi_rdma_completion_or_init_sys_arready),
  .s_axi_rdma_completion_rid            (),//{two_unused_bit5,axi_rdma_completion_rid}
  .s_axi_rdma_completion_rdata          (axi_rdma_completion_or_init_sys_rdata),
  .s_axi_rdma_completion_rresp          (axi_rdma_completion_or_init_sys_rresp),
  .s_axi_rdma_completion_rlast          (axi_rdma_completion_or_init_sys_rlast),
  .s_axi_rdma_completion_rvalid         (axi_rdma_completion_or_init_sys_rvalid),
  .s_axi_rdma_completion_rready         (axi_rdma_completion_or_init_sys_rready),
  .s_axi_rdma_completion_arlock         (axi_rdma_completion_or_init_sys_arlock),
  .s_axi_rdma_completion_arqos          (axi_rdma_completion_or_init_sys_arqos),

  .s_axi_rdma_send_write_payload_awid                    (axi_rdma_send_write_payload_awid),
  .s_axi_rdma_send_write_payload_awaddr                  (axi_rdma_send_write_payload_awaddr),
  .s_axi_rdma_send_write_payload_awqos                   (axi_rdma_send_write_payload_awqos),
  .s_axi_rdma_send_write_payload_awlen                   (axi_rdma_send_write_payload_awlen),
  .s_axi_rdma_send_write_payload_awsize                  (axi_rdma_send_write_payload_awsize),
  .s_axi_rdma_send_write_payload_awburst                 (axi_rdma_send_write_payload_awburst),
  .s_axi_rdma_send_write_payload_awcache                 (axi_rdma_send_write_payload_awcache),
  .s_axi_rdma_send_write_payload_awprot                  (axi_rdma_send_write_payload_awprot),
  .s_axi_rdma_send_write_payload_awvalid                 (axi_rdma_send_write_payload_awvalid),
  .s_axi_rdma_send_write_payload_awready                 (axi_rdma_send_write_payload_awready),
  .s_axi_rdma_send_write_payload_wdata                   (axi_rdma_send_write_payload_wdata),
  .s_axi_rdma_send_write_payload_wstrb                   (axi_rdma_send_write_payload_wstrb),
  .s_axi_rdma_send_write_payload_wlast                   (axi_rdma_send_write_payload_wlast),
  .s_axi_rdma_send_write_payload_wvalid                  (axi_rdma_send_write_payload_wvalid),
  .s_axi_rdma_send_write_payload_wready                  (axi_rdma_send_write_payload_wready),
  .s_axi_rdma_send_write_payload_awlock                  (axi_rdma_send_write_payload_awlock),
  .s_axi_rdma_send_write_payload_bid                     (),
  .s_axi_rdma_send_write_payload_bresp                   (axi_rdma_send_write_payload_bresp),
  .s_axi_rdma_send_write_payload_bvalid                  (axi_rdma_send_write_payload_bvalid),
  .s_axi_rdma_send_write_payload_bready                  (axi_rdma_send_write_payload_bready),
  .s_axi_rdma_send_write_payload_arid                    (axi_rdma_send_write_payload_arid),
  .s_axi_rdma_send_write_payload_araddr                  (axi_rdma_send_write_payload_araddr),
  .s_axi_rdma_send_write_payload_arlen                   (axi_rdma_send_write_payload_arlen),
  .s_axi_rdma_send_write_payload_arsize                  (axi_rdma_send_write_payload_arsize),
  .s_axi_rdma_send_write_payload_arburst                 (axi_rdma_send_write_payload_arburst),
  .s_axi_rdma_send_write_payload_arcache                 (axi_rdma_send_write_payload_arcache),
  .s_axi_rdma_send_write_payload_arprot                  (axi_rdma_send_write_payload_arprot),
  .s_axi_rdma_send_write_payload_arvalid                 (axi_rdma_send_write_payload_arvalid),
  .s_axi_rdma_send_write_payload_arready                 (axi_rdma_send_write_payload_arready),
  .s_axi_rdma_send_write_payload_rid                     (axi_rdma_send_write_payload_rid),
  .s_axi_rdma_send_write_payload_rdata                   (axi_rdma_send_write_payload_rdata),
  .s_axi_rdma_send_write_payload_rresp                   (axi_rdma_send_write_payload_rresp),
  .s_axi_rdma_send_write_payload_rlast                   (axi_rdma_send_write_payload_rlast),
  .s_axi_rdma_send_write_payload_rvalid                  (axi_rdma_send_write_payload_rvalid),
  .s_axi_rdma_send_write_payload_rready                  (axi_rdma_send_write_payload_rready),
  .s_axi_rdma_send_write_payload_arlock                  (axi_rdma_send_write_payload_arlock),
  .s_axi_rdma_send_write_payload_arqos                   (axi_rdma_send_write_payload_arqos),

  .s_axi_rdma_rsp_payload_awid           (axi_rdma_rsp_or_hw_hndshk_sys_awid),//{2'd0,axi_rdma_rsp_payload_awid}
  .s_axi_rdma_rsp_payload_awaddr         (axi_rdma_rsp_or_hw_hndshk_sys_awaddr),
  .s_axi_rdma_rsp_payload_awqos          (axi_rdma_rsp_or_hw_hndshk_sys_awqos),
  .s_axi_rdma_rsp_payload_awlen          (axi_rdma_rsp_or_hw_hndshk_sys_awlen),
  .s_axi_rdma_rsp_payload_awsize         (axi_rdma_rsp_or_hw_hndshk_sys_awsize),
  .s_axi_rdma_rsp_payload_awburst        (axi_rdma_rsp_or_hw_hndshk_sys_awburst),
  .s_axi_rdma_rsp_payload_awcache        (axi_rdma_rsp_or_hw_hndshk_sys_awcache),
  .s_axi_rdma_rsp_payload_awprot         (axi_rdma_rsp_or_hw_hndshk_sys_awprot),
  .s_axi_rdma_rsp_payload_awvalid        (axi_rdma_rsp_or_hw_hndshk_sys_awvalid),
  .s_axi_rdma_rsp_payload_awready        (axi_rdma_rsp_or_hw_hndshk_sys_awready),
  .s_axi_rdma_rsp_payload_wdata          (axi_rdma_rsp_or_hw_hndshk_sys_wdata),
  .s_axi_rdma_rsp_payload_wstrb          (axi_rdma_rsp_or_hw_hndshk_sys_wstrb),
  .s_axi_rdma_rsp_payload_wlast          (axi_rdma_rsp_or_hw_hndshk_sys_wlast),
  .s_axi_rdma_rsp_payload_wvalid         (axi_rdma_rsp_or_hw_hndshk_sys_wvalid),
  .s_axi_rdma_rsp_payload_wready         (axi_rdma_rsp_or_hw_hndshk_sys_wready),
  .s_axi_rdma_rsp_payload_awlock         (axi_rdma_rsp_or_hw_hndshk_sys_awlock),
  .s_axi_rdma_rsp_payload_bid            (),//{two_unused_bit3,axi_rdma_rsp_payload_bid}
  .s_axi_rdma_rsp_payload_bresp          (axi_rdma_rsp_or_hw_hndshk_sys_bresp),
  .s_axi_rdma_rsp_payload_bvalid         (axi_rdma_rsp_or_hw_hndshk_sys_bvalid),
  .s_axi_rdma_rsp_payload_bready         (axi_rdma_rsp_or_hw_hndshk_sys_bready),
  .s_axi_rdma_rsp_payload_arid           (axi_rdma_rsp_or_hw_hndshk_sys_arid),//{2'd0,axi_rdma_rsp_payload_arid}
  .s_axi_rdma_rsp_payload_araddr         (axi_rdma_rsp_or_hw_hndshk_sys_araddr),
  .s_axi_rdma_rsp_payload_arlen          (axi_rdma_rsp_or_hw_hndshk_sys_arlen),
  .s_axi_rdma_rsp_payload_arsize         (axi_rdma_rsp_or_hw_hndshk_sys_arsize),
  .s_axi_rdma_rsp_payload_arburst        (axi_rdma_rsp_or_hw_hndshk_sys_arburst),
  .s_axi_rdma_rsp_payload_arcache        (axi_rdma_rsp_or_hw_hndshk_sys_arcache),
  .s_axi_rdma_rsp_payload_arprot         (axi_rdma_rsp_or_hw_hndshk_sys_arprot),
  .s_axi_rdma_rsp_payload_arvalid        (axi_rdma_rsp_or_hw_hndshk_sys_arvalid),
  .s_axi_rdma_rsp_payload_arready        (axi_rdma_rsp_or_hw_hndshk_sys_arready),
  .s_axi_rdma_rsp_payload_rid            (axi_rdma_rsp_or_hw_hndshk_sys_rid),//{two_unused_bit4,axi_rdma_rsp_payload_rid}
  .s_axi_rdma_rsp_payload_rdata          (axi_rdma_rsp_or_hw_hndshk_sys_rdata),
  .s_axi_rdma_rsp_payload_rresp          (axi_rdma_rsp_or_hw_hndshk_sys_rresp),
  .s_axi_rdma_rsp_payload_rlast          (axi_rdma_rsp_or_hw_hndshk_sys_rlast),
  .s_axi_rdma_rsp_payload_rvalid         (axi_rdma_rsp_or_hw_hndshk_sys_rvalid),
  .s_axi_rdma_rsp_payload_rready         (axi_rdma_rsp_or_hw_hndshk_sys_rready),
  .s_axi_rdma_rsp_payload_arlock         (axi_rdma_rsp_or_hw_hndshk_sys_arlock),
  .s_axi_rdma_rsp_payload_arqos          (axi_rdma_rsp_or_hw_hndshk_sys_arqos),

  .m_axi_sys_mem_awaddr                  (axi_sys_mem_awaddr),
  .m_axi_sys_mem_awprot                  (axi_sys_mem_awprot),
  .m_axi_sys_mem_awvalid                 (axi_sys_mem_awvalid),
  .m_axi_sys_mem_awready                 (axi_sys_mem_awready),
  .m_axi_sys_mem_awsize                  (axi_sys_mem_awsize),
  .m_axi_sys_mem_awburst                 (axi_sys_mem_awburst),
  .m_axi_sys_mem_awcache                 (axi_sys_mem_awcache),
  .m_axi_sys_mem_awlen                   (axi_sys_mem_awlen),
  .m_axi_sys_mem_awlock                  (axi_sys_mem_awlock),
  .m_axi_sys_mem_awqos                   (axi_sys_mem_awqos),
  .m_axi_sys_mem_awregion                (axi_sys_mem_awregion),
  .m_axi_sys_mem_awid                    (axi_sys_mem_awid),
  .m_axi_sys_mem_wdata                   (axi_sys_mem_wdata),
  .m_axi_sys_mem_wstrb                   (axi_sys_mem_wstrb),
  .m_axi_sys_mem_wvalid                  (axi_sys_mem_wvalid),
  .m_axi_sys_mem_wready                  (axi_sys_mem_wready),
  .m_axi_sys_mem_wlast                   (axi_sys_mem_wlast),
  .m_axi_sys_mem_bresp                   (axi_sys_mem_bresp),
  .m_axi_sys_mem_bvalid                  (axi_sys_mem_bvalid),
  .m_axi_sys_mem_bready                  (axi_sys_mem_bready),
  .m_axi_sys_mem_bid                     (axi_sys_mem_bid),
  .m_axi_sys_mem_araddr                  (axi_sys_mem_araddr),
  .m_axi_sys_mem_arprot                  (axi_sys_mem_arprot),
  .m_axi_sys_mem_arvalid                 (axi_sys_mem_arvalid),
  .m_axi_sys_mem_arready                 (axi_sys_mem_arready),
  .m_axi_sys_mem_arsize                  (axi_sys_mem_arsize),
  .m_axi_sys_mem_arburst                 (axi_sys_mem_arburst),
  .m_axi_sys_mem_arcache                 (axi_sys_mem_arcache),
  .m_axi_sys_mem_arlock                  (axi_sys_mem_arlock),
  .m_axi_sys_mem_arlen                   (axi_sys_mem_arlen),
  .m_axi_sys_mem_arqos                   (axi_sys_mem_arqos),
  .m_axi_sys_mem_arregion                (axi_sys_mem_arregion),
  .m_axi_sys_mem_arid                    (axi_sys_mem_arid),
  .m_axi_sys_mem_rdata                   (axi_sys_mem_rdata),
  .m_axi_sys_mem_rresp                   (axi_sys_mem_rresp),
  .m_axi_sys_mem_rvalid                  (axi_sys_mem_rvalid),
  .m_axi_sys_mem_rready                  (axi_sys_mem_rready),
  .m_axi_sys_mem_rlast                   (axi_sys_mem_rlast),
  .m_axi_sys_mem_rid                     (axi_sys_mem_rid), 

  .m_axi_sys_to_dev_crossbar_awaddr      (axi_from_sys_to_dev_crossbar_awaddr),
  .m_axi_sys_to_dev_crossbar_awprot      (axi_from_sys_to_dev_crossbar_awprot),
  .m_axi_sys_to_dev_crossbar_awvalid     (axi_from_sys_to_dev_crossbar_awvalid),
  .m_axi_sys_to_dev_crossbar_awready     (axi_from_sys_to_dev_crossbar_awready),
  .m_axi_sys_to_dev_crossbar_awsize      (axi_from_sys_to_dev_crossbar_awsize),
  .m_axi_sys_to_dev_crossbar_awburst     (axi_from_sys_to_dev_crossbar_awburst),
  .m_axi_sys_to_dev_crossbar_awcache     (axi_from_sys_to_dev_crossbar_awcache),
  .m_axi_sys_to_dev_crossbar_awlen       (axi_from_sys_to_dev_crossbar_awlen),
  .m_axi_sys_to_dev_crossbar_awlock      (axi_from_sys_to_dev_crossbar_awlock),
  .m_axi_sys_to_dev_crossbar_awqos       (axi_from_sys_to_dev_crossbar_awqos),
  .m_axi_sys_to_dev_crossbar_awregion    (axi_from_sys_to_dev_crossbar_awregion),
  .m_axi_sys_to_dev_crossbar_awid        (axi_from_sys_to_dev_crossbar_awid),
  .m_axi_sys_to_dev_crossbar_wdata       (axi_from_sys_to_dev_crossbar_wdata),
  .m_axi_sys_to_dev_crossbar_wstrb       (axi_from_sys_to_dev_crossbar_wstrb),
  .m_axi_sys_to_dev_crossbar_wvalid      (axi_from_sys_to_dev_crossbar_wvalid),
  .m_axi_sys_to_dev_crossbar_wready      (axi_from_sys_to_dev_crossbar_wready),
  .m_axi_sys_to_dev_crossbar_wlast       (axi_from_sys_to_dev_crossbar_wlast),
  .m_axi_sys_to_dev_crossbar_bresp       (axi_from_sys_to_dev_crossbar_bresp),
  .m_axi_sys_to_dev_crossbar_bvalid      (axi_from_sys_to_dev_crossbar_bvalid),
  .m_axi_sys_to_dev_crossbar_bready      (axi_from_sys_to_dev_crossbar_bready),
  .m_axi_sys_to_dev_crossbar_bid         (axi_from_sys_to_dev_crossbar_bid),
  .m_axi_sys_to_dev_crossbar_araddr      (axi_from_sys_to_dev_crossbar_araddr),
  .m_axi_sys_to_dev_crossbar_arprot      (axi_from_sys_to_dev_crossbar_arprot),
  .m_axi_sys_to_dev_crossbar_arvalid     (axi_from_sys_to_dev_crossbar_arvalid),
  .m_axi_sys_to_dev_crossbar_arready     (axi_from_sys_to_dev_crossbar_arready),
  .m_axi_sys_to_dev_crossbar_arsize      (axi_from_sys_to_dev_crossbar_arsize),
  .m_axi_sys_to_dev_crossbar_arburst     (axi_from_sys_to_dev_crossbar_arburst),
  .m_axi_sys_to_dev_crossbar_arcache     (axi_from_sys_to_dev_crossbar_arcache),
  .m_axi_sys_to_dev_crossbar_arlock      (axi_from_sys_to_dev_crossbar_arlock),
  .m_axi_sys_to_dev_crossbar_arlen       (axi_from_sys_to_dev_crossbar_arlen),
  .m_axi_sys_to_dev_crossbar_arqos       (axi_from_sys_to_dev_crossbar_arqos),
  .m_axi_sys_to_dev_crossbar_arregion    (axi_from_sys_to_dev_crossbar_arregion),
  .m_axi_sys_to_dev_crossbar_arid        (axi_from_sys_to_dev_crossbar_arid),
  .m_axi_sys_to_dev_crossbar_rdata       (axi_from_sys_to_dev_crossbar_rdata),
  .m_axi_sys_to_dev_crossbar_rresp       (axi_from_sys_to_dev_crossbar_rresp),
  .m_axi_sys_to_dev_crossbar_rvalid      (axi_from_sys_to_dev_crossbar_rvalid),
  .m_axi_sys_to_dev_crossbar_rready      (axi_from_sys_to_dev_crossbar_rready),
  .m_axi_sys_to_dev_crossbar_rlast       (axi_from_sys_to_dev_crossbar_rlast),
  .m_axi_sys_to_dev_crossbar_rid         (axi_from_sys_to_dev_crossbar_rid),

  .axis_aclk                             (axis_clk),
  .axis_arestn                           (axis_rstn)   
);
/*
axi_7to2_interconnect_to_sys_mem axi_interconnect_to_sys_mem_inst(
    .s_axi_rdma_get_wqe_awid               (axi_rdma_get_wqe_awid),
    .s_axi_rdma_get_wqe_awaddr             (axi_rdma_get_wqe_awaddr),
    .s_axi_rdma_get_wqe_awqos              (axi_rdma_get_wqe_awqos),
    .s_axi_rdma_get_wqe_awlen              (axi_rdma_get_wqe_awlen),
    .s_axi_rdma_get_wqe_awsize             (axi_rdma_get_wqe_awsize),
    .s_axi_rdma_get_wqe_awburst            (axi_rdma_get_wqe_awburst),
    .s_axi_rdma_get_wqe_awcache            (axi_rdma_get_wqe_awcache),
    .s_axi_rdma_get_wqe_awprot             (axi_rdma_get_wqe_awprot),
    .s_axi_rdma_get_wqe_awvalid            (axi_rdma_get_wqe_awvalid),
    .s_axi_rdma_get_wqe_awready            (axi_rdma_get_wqe_awready),
    .s_axi_rdma_get_wqe_wdata              (axi_rdma_get_wqe_wdata),
    .s_axi_rdma_get_wqe_wstrb              (axi_rdma_get_wqe_wstrb),
    .s_axi_rdma_get_wqe_wlast              (axi_rdma_get_wqe_wlast),
    .s_axi_rdma_get_wqe_wvalid             (axi_rdma_get_wqe_wvalid),
    .s_axi_rdma_get_wqe_wready             (axi_rdma_get_wqe_wready),
    .s_axi_rdma_get_wqe_awlock             (axi_rdma_get_wqe_awlock),
    .s_axi_rdma_get_wqe_bid                (axi_rdma_get_wqe_bid),
    .s_axi_rdma_get_wqe_bresp              (axi_rdma_get_wqe_bresp),
    .s_axi_rdma_get_wqe_bvalid             (axi_rdma_get_wqe_bvalid),
    .s_axi_rdma_get_wqe_bready             (axi_rdma_get_wqe_bready),
    .s_axi_rdma_get_wqe_arid               (axi_rdma_get_wqe_arid),
    .s_axi_rdma_get_wqe_araddr             (axi_rdma_get_wqe_araddr),
    .s_axi_rdma_get_wqe_arlen              (axi_rdma_get_wqe_arlen),
    .s_axi_rdma_get_wqe_arsize             (axi_rdma_get_wqe_arsize),
    .s_axi_rdma_get_wqe_arburst            (axi_rdma_get_wqe_arburst),
    .s_axi_rdma_get_wqe_arcache            (axi_rdma_get_wqe_arcache),
    .s_axi_rdma_get_wqe_arprot             (axi_rdma_get_wqe_arprot),
    .s_axi_rdma_get_wqe_arvalid            (axi_rdma_get_wqe_arvalid),
    .s_axi_rdma_get_wqe_arready            (axi_rdma_get_wqe_arready),
    .s_axi_rdma_get_wqe_rid                (axi_rdma_get_wqe_rid),
    .s_axi_rdma_get_wqe_rdata              (axi_rdma_get_wqe_rdata),
    .s_axi_rdma_get_wqe_rresp              (axi_rdma_get_wqe_rresp),
    .s_axi_rdma_get_wqe_rlast              (axi_rdma_get_wqe_rlast),
    .s_axi_rdma_get_wqe_rvalid             (axi_rdma_get_wqe_rvalid),
    .s_axi_rdma_get_wqe_rready             (axi_rdma_get_wqe_rready),
    .s_axi_rdma_get_wqe_arlock             (axi_rdma_get_wqe_arlock),
    .s_axi_rdma_get_wqe_arqos              (axi_rdma_get_wqe_arqos),

    .s_axi_rdma_get_payload_awid           (axi_rdma_get_payload_awid),
    .s_axi_rdma_get_payload_awaddr         (axi_rdma_get_payload_awaddr),
    .s_axi_rdma_get_payload_awqos          (axi_rdma_get_payload_awqos),
    .s_axi_rdma_get_payload_awlen          (axi_rdma_get_payload_awlen),
    .s_axi_rdma_get_payload_awsize         (axi_rdma_get_payload_awsize),
    .s_axi_rdma_get_payload_awburst        (axi_rdma_get_payload_awburst),
    .s_axi_rdma_get_payload_awcache        (axi_rdma_get_payload_awcache),
    .s_axi_rdma_get_payload_awprot         (axi_rdma_get_payload_awprot),
    .s_axi_rdma_get_payload_awvalid        (axi_rdma_get_payload_awvalid),
    .s_axi_rdma_get_payload_awready        (axi_rdma_get_payload_awready),
    .s_axi_rdma_get_payload_wdata          (axi_rdma_get_payload_wdata),
    .s_axi_rdma_get_payload_wstrb          (axi_rdma_get_payload_wstrb),
    .s_axi_rdma_get_payload_wlast          (axi_rdma_get_payload_wlast),
    .s_axi_rdma_get_payload_wvalid         (axi_rdma_get_payload_wvalid),
    .s_axi_rdma_get_payload_wready         (axi_rdma_get_payload_wready),
    .s_axi_rdma_get_payload_awlock         (axi_rdma_get_payload_awlock),
    .s_axi_rdma_get_payload_bid            (axi_rdma_get_payload_bid),
    .s_axi_rdma_get_payload_bresp          (axi_rdma_get_payload_bresp),
    .s_axi_rdma_get_payload_bvalid         (axi_rdma_get_payload_bvalid),
    .s_axi_rdma_get_payload_bready         (axi_rdma_get_payload_bready),
    .s_axi_rdma_get_payload_arid           (axi_rdma_get_payload_arid),
    .s_axi_rdma_get_payload_araddr         (axi_rdma_get_payload_araddr),
    .s_axi_rdma_get_payload_arlen          (axi_rdma_get_payload_arlen),
    .s_axi_rdma_get_payload_arsize         (axi_rdma_get_payload_arsize),
    .s_axi_rdma_get_payload_arburst        (axi_rdma_get_payload_arburst),
    .s_axi_rdma_get_payload_arcache        (axi_rdma_get_payload_arcache),
    .s_axi_rdma_get_payload_arprot         (axi_rdma_get_payload_arprot),
    .s_axi_rdma_get_payload_arvalid        (axi_rdma_get_payload_arvalid),
    .s_axi_rdma_get_payload_arready        (axi_rdma_get_payload_arready),
    .s_axi_rdma_get_payload_rid            (axi_rdma_get_payload_rid),
    .s_axi_rdma_get_payload_rdata          (axi_rdma_get_payload_rdata),
    .s_axi_rdma_get_payload_rresp          (axi_rdma_get_payload_rresp),
    .s_axi_rdma_get_payload_rlast          (axi_rdma_get_payload_rlast),
    .s_axi_rdma_get_payload_rvalid         (axi_rdma_get_payload_rvalid),
    .s_axi_rdma_get_payload_rready         (axi_rdma_get_payload_rready),
    .s_axi_rdma_get_payload_arlock         (axi_rdma_get_payload_arlock),
    .s_axi_rdma_get_payload_arqos          (axi_rdma_get_payload_arqos),

    .s_axi_rdma_completion_awid            (axi_rdma_completion_awid),
    .s_axi_rdma_completion_awaddr          (axi_rdma_completion_awaddr),
    .s_axi_rdma_completion_awqos           (axi_rdma_completion_awqos),
    .s_axi_rdma_completion_awlen           (axi_rdma_completion_awlen),
    .s_axi_rdma_completion_awsize          (axi_rdma_completion_awsize),
    .s_axi_rdma_completion_awburst         (axi_rdma_completion_awburst),
    .s_axi_rdma_completion_awcache         (axi_rdma_completion_awcache),
    .s_axi_rdma_completion_awprot          (axi_rdma_completion_awprot),
    .s_axi_rdma_completion_awvalid         (axi_rdma_completion_awvalid),
    .s_axi_rdma_completion_awready         (axi_rdma_completion_awready),
    .s_axi_rdma_completion_wdata           (axi_rdma_completion_wdata),
    .s_axi_rdma_completion_wstrb           (axi_rdma_completion_wstrb),
    .s_axi_rdma_completion_wlast           (axi_rdma_completion_wlast),
    .s_axi_rdma_completion_wvalid          (axi_rdma_completion_wvalid),
    .s_axi_rdma_completion_wready          (axi_rdma_completion_wready),
    .s_axi_rdma_completion_awlock          (axi_rdma_completion_awlock),
    .s_axi_rdma_completion_bid             (axi_rdma_completion_bid),
    .s_axi_rdma_completion_bresp           (axi_rdma_completion_bresp),
    .s_axi_rdma_completion_bvalid          (axi_rdma_completion_bvalid),
    .s_axi_rdma_completion_bready          (axi_rdma_completion_bready),
    .s_axi_rdma_completion_arid            (axi_rdma_completion_arid),
    .s_axi_rdma_completion_araddr          (axi_rdma_completion_araddr),
    .s_axi_rdma_completion_arlen           (axi_rdma_completion_arlen),
    .s_axi_rdma_completion_arsize          (axi_rdma_completion_arsize),
    .s_axi_rdma_completion_arburst         (axi_rdma_completion_arburst),
    .s_axi_rdma_completion_arcache         (axi_rdma_completion_arcache),
    .s_axi_rdma_completion_arprot          (axi_rdma_completion_arprot),
    .s_axi_rdma_completion_arvalid         (axi_rdma_completion_arvalid),
    .s_axi_rdma_completion_arready         (axi_rdma_completion_arready),
    .s_axi_rdma_completion_rid             (axi_rdma_completion_rid),
    .s_axi_rdma_completion_rdata           (axi_rdma_completion_rdata),
    .s_axi_rdma_completion_rresp           (axi_rdma_completion_rresp),
    .s_axi_rdma_completion_rlast           (axi_rdma_completion_rlast),
    .s_axi_rdma_completion_rvalid          (axi_rdma_completion_rvalid),
    .s_axi_rdma_completion_rready          (axi_rdma_completion_rready),
    .s_axi_rdma_completion_arlock          (axi_rdma_completion_arlock),
    .s_axi_rdma_completion_arqos           (axi_rdma_completion_arqos),

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

    .s_axi_hw_hndshk_awid              (axi_hw_hndshk_awid),
    .s_axi_hw_hndshk_awaddr            (axi_hw_hndshk_awaddr),
    .s_axi_hw_hndshk_awqos             (axi_hw_hndshk_awqos),
    .s_axi_hw_hndshk_awlen             (axi_hw_hndshk_awlen),
    .s_axi_hw_hndshk_awsize            (axi_hw_hndshk_awsize),
    .s_axi_hw_hndshk_awburst           (axi_hw_hndshk_awburst),
    .s_axi_hw_hndshk_awcache           (axi_hw_hndshk_awcache),
    .s_axi_hw_hndshk_awprot            (axi_hw_hndshk_awprot),
    .s_axi_hw_hndshk_awvalid           (axi_hw_hndshk_awvalid),
    .s_axi_hw_hndshk_awready           (axi_hw_hndshk_awready),
    .s_axi_hw_hndshk_wdata             (axi_hw_hndshk_wdata),
    .s_axi_hw_hndshk_wstrb             (axi_hw_hndshk_wstrb),
    .s_axi_hw_hndshk_wlast             (axi_hw_hndshk_wlast),
    .s_axi_hw_hndshk_wvalid            (axi_hw_hndshk_wvalid),
    .s_axi_hw_hndshk_wready            (axi_hw_hndshk_wready),
    .s_axi_hw_hndshk_awlock            (axi_hw_hndshk_awlock),
    .s_axi_hw_hndshk_bid               (axi_hw_hndshk_bid),
    .s_axi_hw_hndshk_bresp             (axi_hw_hndshk_bresp),
    .s_axi_hw_hndshk_bvalid            (axi_hw_hndshk_bvalid),
    .s_axi_hw_hndshk_bready            (axi_hw_hndshk_bready),
    .s_axi_hw_hndshk_arid              (axi_hw_hndshk_arid),
    .s_axi_hw_hndshk_araddr            (axi_hw_hndshk_araddr),
    .s_axi_hw_hndshk_arlen             (axi_hw_hndshk_arlen),
    .s_axi_hw_hndshk_arsize            (axi_hw_hndshk_arsize),
    .s_axi_hw_hndshk_arburst           (axi_hw_hndshk_arburst),
    .s_axi_hw_hndshk_arcache           (axi_hw_hndshk_arcache),
    .s_axi_hw_hndshk_arprot            (axi_hw_hndshk_arprot),
    .s_axi_hw_hndshk_arvalid           (axi_hw_hndshk_arvalid),
    .s_axi_hw_hndshk_arready           (axi_hw_hndshk_arready),
    .s_axi_hw_hndshk_rid               (axi_hw_hndshk_rid),
    .s_axi_hw_hndshk_rdata             (axi_hw_hndshk_rdata),
    .s_axi_hw_hndshk_rresp             (axi_hw_hndshk_rresp),
    .s_axi_hw_hndshk_rlast             (axi_hw_hndshk_rlast),
    .s_axi_hw_hndshk_rvalid            (axi_hw_hndshk_rvalid),
    .s_axi_hw_hndshk_rready            (axi_hw_hndshk_rready),
    .s_axi_hw_hndshk_arlock            (axi_hw_hndshk_arlock),
    .s_axi_hw_hndshk_arqos             (axi_hw_hndshk_arqos),

    .s_axi_payload_to_retry_buf_awid       (axi_payload_to_retry_buf_awid),
    .s_axi_payload_to_retry_buf_awaddr     (axi_payload_to_retry_buf_awaddr),
    .s_axi_payload_to_retry_buf_awlen      (axi_payload_to_retry_buf_awlen),
    .s_axi_payload_to_retry_buf_awsize     (axi_payload_to_retry_buf_awsize),
    .s_axi_payload_to_retry_buf_awburst    (axi_payload_to_retry_buf_awburst),
    .s_axi_payload_to_retry_buf_awcache    (axi_payload_to_retry_buf_awcache),
    .s_axi_payload_to_retry_buf_awprot     (axi_payload_to_retry_buf_awprot),
    .s_axi_payload_to_retry_buf_awvalid    (axi_payload_to_retry_buf_awvalid),
    .s_axi_payload_to_retry_buf_awready    (axi_payload_to_retry_buf_awready),
    .s_axi_payload_to_retry_buf_wdata      (axi_payload_to_retry_buf_wdata),
    .s_axi_payload_to_retry_buf_wstrb      (axi_payload_to_retry_buf_wstrb),
    .s_axi_payload_to_retry_buf_wlast      (axi_payload_to_retry_buf_wlast),
    .s_axi_payload_to_retry_buf_wvalid     (axi_payload_to_retry_buf_wvalid),
    .s_axi_payload_to_retry_buf_wready     (axi_payload_to_retry_buf_wready),
    .s_axi_payload_to_retry_buf_awlock     (axi_payload_to_retry_buf_awlock),
    .s_axi_payload_to_retry_buf_bid        (axi_payload_to_retry_buf_bid),
    .s_axi_payload_to_retry_buf_bresp      (axi_payload_to_retry_buf_bresp),
    .s_axi_payload_to_retry_buf_bvalid     (axi_payload_to_retry_buf_bvalid),
    .s_axi_payload_to_retry_buf_bready     (axi_payload_to_retry_buf_bready),
    .s_axi_payload_to_retry_buf_arid       (axi_payload_to_retry_buf_arid),
    .s_axi_payload_to_retry_buf_araddr     (axi_payload_to_retry_buf_araddr),
    .s_axi_payload_to_retry_buf_arlen      (axi_payload_to_retry_buf_arlen),
    .s_axi_payload_to_retry_buf_arsize     (axi_payload_to_retry_buf_arsize),
    .s_axi_payload_to_retry_buf_arburst    (axi_payload_to_retry_buf_arburst),
    .s_axi_payload_to_retry_buf_arcache    (axi_payload_to_retry_buf_arcache),
    .s_axi_payload_to_retry_buf_arprot     (axi_payload_to_retry_buf_arprot),
    .s_axi_payload_to_retry_buf_arvalid    (axi_payload_to_retry_buf_arvalid),
    .s_axi_payload_to_retry_buf_arready    (axi_payload_to_retry_buf_arready),
    .s_axi_payload_to_retry_buf_rid        (axi_payload_to_retry_buf_rid),
    .s_axi_payload_to_retry_buf_rdata      (axi_payload_to_retry_buf_rdata),
    .s_axi_payload_to_retry_buf_rresp      (axi_payload_to_retry_buf_rresp),
    .s_axi_payload_to_retry_buf_rlast      (axi_payload_to_retry_buf_rlast),
    .s_axi_payload_to_retry_buf_rvalid     (axi_payload_to_retry_buf_rvalid),
    .s_axi_payload_to_retry_buf_rready     (axi_payload_to_retry_buf_rready),
    .s_axi_payload_to_retry_buf_arlock     (axi_payload_to_retry_buf_arlock),

    .m_axi_sys_mem_awaddr                  (axi_sys_mem_awaddr),
    .m_axi_sys_mem_awprot                  (axi_sys_mem_awprot),
    .m_axi_sys_mem_awvalid                 (axi_sys_mem_awvalid),
    .m_axi_sys_mem_awready                 (axi_sys_mem_awready),
    .m_axi_sys_mem_awsize                  (axi_sys_mem_awsize),
    .m_axi_sys_mem_awburst                 (axi_sys_mem_awburst),
    .m_axi_sys_mem_awcache                 (axi_sys_mem_awcache),
    .m_axi_sys_mem_awlen                   (axi_sys_mem_awlen),
    .m_axi_sys_mem_awlock                  (axi_sys_mem_awlock),
    .m_axi_sys_mem_awqos                   (axi_sys_mem_awqos),
    .m_axi_sys_mem_awregion                (axi_sys_mem_awregion),
    .m_axi_sys_mem_awid                    (axi_sys_mem_awid),
    .m_axi_sys_mem_wdata                   (axi_sys_mem_wdata),
    .m_axi_sys_mem_wstrb                   (axi_sys_mem_wstrb),
    .m_axi_sys_mem_wvalid                  (axi_sys_mem_wvalid),
    .m_axi_sys_mem_wready                  (axi_sys_mem_wready),
    .m_axi_sys_mem_wlast                   (axi_sys_mem_wlast),
    .m_axi_sys_mem_bresp                   (axi_sys_mem_bresp),
    .m_axi_sys_mem_bvalid                  (axi_sys_mem_bvalid),
    .m_axi_sys_mem_bready                  (axi_sys_mem_bready),
    .m_axi_sys_mem_bid                     (axi_sys_mem_bid[2:0]),
    .m_axi_sys_mem_araddr                  (axi_sys_mem_araddr),
    .m_axi_sys_mem_arprot                  (axi_sys_mem_arprot),
    .m_axi_sys_mem_arvalid                 (axi_sys_mem_arvalid),
    .m_axi_sys_mem_arready                 (axi_sys_mem_arready),
    .m_axi_sys_mem_arsize                  (axi_sys_mem_arsize),
    .m_axi_sys_mem_arburst                 (axi_sys_mem_arburst),
    .m_axi_sys_mem_arcache                 (axi_sys_mem_arcache),
    .m_axi_sys_mem_arlock                  (axi_sys_mem_arlock),
    .m_axi_sys_mem_arlen                   (axi_sys_mem_arlen),
    .m_axi_sys_mem_arqos                   (axi_sys_mem_arqos),
    .m_axi_sys_mem_arregion                (axi_sys_mem_arregion),
    .m_axi_sys_mem_arid                    (axi_sys_mem_arid),
    .m_axi_sys_mem_rdata                   (axi_sys_mem_rdata),
    .m_axi_sys_mem_rresp                   (axi_sys_mem_rresp),
    .m_axi_sys_mem_rvalid                  (axi_sys_mem_rvalid),
    .m_axi_sys_mem_rready                  (axi_sys_mem_rready),
    .m_axi_sys_mem_rlast                   (axi_sys_mem_rlast),
    .m_axi_sys_mem_rid                     (axi_sys_mem_rid[2:0]),

    .m_axi_sys_to_dev_crossbar_awaddr      (axi_from_sys_to_dev_crossbar_awaddr),
    .m_axi_sys_to_dev_crossbar_awprot      (axi_from_sys_to_dev_crossbar_awprot),
    .m_axi_sys_to_dev_crossbar_awvalid     (axi_from_sys_to_dev_crossbar_awvalid),
    .m_axi_sys_to_dev_crossbar_awready     (axi_from_sys_to_dev_crossbar_awready),
    .m_axi_sys_to_dev_crossbar_awsize      (axi_from_sys_to_dev_crossbar_awsize),
    .m_axi_sys_to_dev_crossbar_awburst     (axi_from_sys_to_dev_crossbar_awburst),
    .m_axi_sys_to_dev_crossbar_awcache     (axi_from_sys_to_dev_crossbar_awcache),
    .m_axi_sys_to_dev_crossbar_awlen       (axi_from_sys_to_dev_crossbar_awlen),
    .m_axi_sys_to_dev_crossbar_awlock      (axi_from_sys_to_dev_crossbar_awlock),
    .m_axi_sys_to_dev_crossbar_awqos       (axi_from_sys_to_dev_crossbar_awqos),
    .m_axi_sys_to_dev_crossbar_awregion    (axi_from_sys_to_dev_crossbar_awregion),
    .m_axi_sys_to_dev_crossbar_awid        (axi_from_sys_to_dev_crossbar_awid),
    .m_axi_sys_to_dev_crossbar_wdata       (axi_from_sys_to_dev_crossbar_wdata),
    .m_axi_sys_to_dev_crossbar_wstrb       (axi_from_sys_to_dev_crossbar_wstrb),
    .m_axi_sys_to_dev_crossbar_wvalid      (axi_from_sys_to_dev_crossbar_wvalid),
    .m_axi_sys_to_dev_crossbar_wready      (axi_from_sys_to_dev_crossbar_wready),
    .m_axi_sys_to_dev_crossbar_wlast       (axi_from_sys_to_dev_crossbar_wlast),
    .m_axi_sys_to_dev_crossbar_bresp       (axi_from_sys_to_dev_crossbar_bresp),
    .m_axi_sys_to_dev_crossbar_bvalid      (axi_from_sys_to_dev_crossbar_bvalid),
    .m_axi_sys_to_dev_crossbar_bready      (axi_from_sys_to_dev_crossbar_bready),
    .m_axi_sys_to_dev_crossbar_bid         (axi_from_sys_to_dev_crossbar_bid[2:0]),
    .m_axi_sys_to_dev_crossbar_araddr      (axi_from_sys_to_dev_crossbar_araddr),
    .m_axi_sys_to_dev_crossbar_arprot      (axi_from_sys_to_dev_crossbar_arprot),
    .m_axi_sys_to_dev_crossbar_arvalid     (axi_from_sys_to_dev_crossbar_arvalid),
    .m_axi_sys_to_dev_crossbar_arready     (axi_from_sys_to_dev_crossbar_arready),
    .m_axi_sys_to_dev_crossbar_arsize      (axi_from_sys_to_dev_crossbar_arsize),
    .m_axi_sys_to_dev_crossbar_arburst     (axi_from_sys_to_dev_crossbar_arburst),
    .m_axi_sys_to_dev_crossbar_arcache     (axi_from_sys_to_dev_crossbar_arcache),
    .m_axi_sys_to_dev_crossbar_arlock      (axi_from_sys_to_dev_crossbar_arlock),
    .m_axi_sys_to_dev_crossbar_arlen       (axi_from_sys_to_dev_crossbar_arlen),
    .m_axi_sys_to_dev_crossbar_arqos       (axi_from_sys_to_dev_crossbar_arqos),
    .m_axi_sys_to_dev_crossbar_arregion    (axi_from_sys_to_dev_crossbar_arregion),
    .m_axi_sys_to_dev_crossbar_arid        (axi_from_sys_to_dev_crossbar_arid),
    .m_axi_sys_to_dev_crossbar_rdata       (axi_from_sys_to_dev_crossbar_rdata),
    .m_axi_sys_to_dev_crossbar_rresp       (axi_from_sys_to_dev_crossbar_rresp),
    .m_axi_sys_to_dev_crossbar_rvalid      (axi_from_sys_to_dev_crossbar_rvalid),
    .m_axi_sys_to_dev_crossbar_rready      (axi_from_sys_to_dev_crossbar_rready),
    .m_axi_sys_to_dev_crossbar_rlast       (axi_from_sys_to_dev_crossbar_rlast),
    .m_axi_sys_to_dev_crossbar_rid         (axi_from_sys_to_dev_crossbar_rid[2:0]),

    .axis_aclk                             (axis_aclk),
    .axis_arestn                           (axis_rstn)
);*/


axi_interconnect_to_dev_mem axi_2to1_for_completion_or_init_sys(
  .s_axi_rdma_send_write_payload_awid    (axi_rdma_completion_awid),
  .s_axi_rdma_send_write_payload_awaddr  (axi_rdma_completion_awaddr),
  .s_axi_rdma_send_write_payload_awqos   (axi_rdma_completion_awqos),
  .s_axi_rdma_send_write_payload_awlen   (axi_rdma_completion_awlen),
  .s_axi_rdma_send_write_payload_awsize  (axi_rdma_completion_awsize),
  .s_axi_rdma_send_write_payload_awburst (axi_rdma_completion_awburst),
  .s_axi_rdma_send_write_payload_awcache (axi_rdma_completion_awcache),
  .s_axi_rdma_send_write_payload_awprot  (axi_rdma_completion_awprot),
  .s_axi_rdma_send_write_payload_awvalid (axi_rdma_completion_awvalid),
  .s_axi_rdma_send_write_payload_awready (axi_rdma_completion_awready),
  .s_axi_rdma_send_write_payload_wdata   (axi_rdma_completion_wdata),
  .s_axi_rdma_send_write_payload_wstrb   (axi_rdma_completion_wstrb),
  .s_axi_rdma_send_write_payload_wlast   (axi_rdma_completion_wlast),
  .s_axi_rdma_send_write_payload_wvalid  (axi_rdma_completion_wvalid),
  .s_axi_rdma_send_write_payload_wready  (axi_rdma_completion_wready),
  .s_axi_rdma_send_write_payload_awlock  (axi_rdma_completion_awlock),
  .s_axi_rdma_send_write_payload_bid     (axi_rdma_completion_bid),
  .s_axi_rdma_send_write_payload_bresp   (axi_rdma_completion_bresp),
  .s_axi_rdma_send_write_payload_bvalid  (axi_rdma_completion_bvalid),
  .s_axi_rdma_send_write_payload_bready  (axi_rdma_completion_bready),
  .s_axi_rdma_send_write_payload_arid    (axi_rdma_completion_arid),
  .s_axi_rdma_send_write_payload_araddr  (axi_rdma_completion_araddr),
  .s_axi_rdma_send_write_payload_arlen   (axi_rdma_completion_arlen),
  .s_axi_rdma_send_write_payload_arsize  (axi_rdma_completion_arsize),
  .s_axi_rdma_send_write_payload_arburst (axi_rdma_completion_arburst),
  .s_axi_rdma_send_write_payload_arcache (axi_rdma_completion_arcache),
  .s_axi_rdma_send_write_payload_arprot  (axi_rdma_completion_arprot),
  .s_axi_rdma_send_write_payload_arvalid (axi_rdma_completion_arvalid),
  .s_axi_rdma_send_write_payload_arready (axi_rdma_completion_arready),
  .s_axi_rdma_send_write_payload_rid     (axi_rdma_completion_rid),
  .s_axi_rdma_send_write_payload_rdata   (axi_rdma_completion_rdata),
  .s_axi_rdma_send_write_payload_rresp   (axi_rdma_completion_rresp),
  .s_axi_rdma_send_write_payload_rlast   (axi_rdma_completion_rlast),
  .s_axi_rdma_send_write_payload_rvalid  (axi_rdma_completion_rvalid),
  .s_axi_rdma_send_write_payload_rready  (axi_rdma_completion_rready),
  .s_axi_rdma_send_write_payload_arlock  (axi_rdma_completion_arlock),
  .s_axi_rdma_send_write_payload_arqos   (axi_rdma_completion_arqos),

  .s_axi_rdma_rsp_payload_awid           (m_axi_init_sys_awid),
  .s_axi_rdma_rsp_payload_awaddr         (m_axi_init_sys_awaddr),
  .s_axi_rdma_rsp_payload_awqos          (m_axi_init_sys_awqos),
  .s_axi_rdma_rsp_payload_awlen          (m_axi_init_sys_awlen),
  .s_axi_rdma_rsp_payload_awsize         (m_axi_init_sys_awsize),
  .s_axi_rdma_rsp_payload_awburst        (m_axi_init_sys_awburst),
  .s_axi_rdma_rsp_payload_awcache        (m_axi_init_sys_awcache),
  .s_axi_rdma_rsp_payload_awprot         (m_axi_init_sys_awprot),
  .s_axi_rdma_rsp_payload_awvalid        (m_axi_init_sys_awvalid),
  .s_axi_rdma_rsp_payload_awready        (m_axi_init_sys_awready),
  .s_axi_rdma_rsp_payload_wdata          (m_axi_init_sys_wdata),
  .s_axi_rdma_rsp_payload_wstrb          (m_axi_init_sys_wstrb),
  .s_axi_rdma_rsp_payload_wlast          (m_axi_init_sys_wlast),
  .s_axi_rdma_rsp_payload_wvalid         (m_axi_init_sys_wvalid),
  .s_axi_rdma_rsp_payload_wready         (m_axi_init_sys_wready),
  .s_axi_rdma_rsp_payload_awlock         (m_axi_init_sys_awlock),
  .s_axi_rdma_rsp_payload_bid            (m_axi_init_sys_bid),
  .s_axi_rdma_rsp_payload_bresp          (m_axi_init_sys_bresp),
  .s_axi_rdma_rsp_payload_bvalid         (m_axi_init_sys_bvalid),
  .s_axi_rdma_rsp_payload_bready         (m_axi_init_sys_bready),
  .s_axi_rdma_rsp_payload_arid           (m_axi_veri_sys_arid),
  .s_axi_rdma_rsp_payload_araddr         (m_axi_veri_sys_araddr),
  .s_axi_rdma_rsp_payload_arlen          (m_axi_veri_sys_arlen),
  .s_axi_rdma_rsp_payload_arsize         (m_axi_veri_sys_arsize),
  .s_axi_rdma_rsp_payload_arburst        (m_axi_veri_sys_arburst),
  .s_axi_rdma_rsp_payload_arcache        (m_axi_veri_sys_arcache),
  .s_axi_rdma_rsp_payload_arprot         (m_axi_veri_sys_arprot),
  .s_axi_rdma_rsp_payload_arvalid        (m_axi_veri_sys_arvalid),
  .s_axi_rdma_rsp_payload_arready        (m_axi_veri_sys_arready),
  .s_axi_rdma_rsp_payload_rid            (m_axi_veri_sys_rid),
  .s_axi_rdma_rsp_payload_rdata          (m_axi_veri_sys_rdata),
  .s_axi_rdma_rsp_payload_rresp          (m_axi_veri_sys_rresp),
  .s_axi_rdma_rsp_payload_rlast          (m_axi_veri_sys_rlast),
  .s_axi_rdma_rsp_payload_rvalid         (m_axi_veri_sys_rvalid),
  .s_axi_rdma_rsp_payload_rready         (m_axi_veri_sys_rready),
  .s_axi_rdma_rsp_payload_arlock         (m_axi_veri_sys_arlock),
  .s_axi_rdma_rsp_payload_arqos          (m_axi_veri_sys_arqos),

  .s_axi_qdma_mm_awid                    (4'd0),
  .s_axi_qdma_mm_awaddr                  (64'd0),
  .s_axi_qdma_mm_awqos                   (4'd0),
  .s_axi_qdma_mm_awlen                   (8'd0),
  .s_axi_qdma_mm_awsize                  (3'd0),
  .s_axi_qdma_mm_awburst                 (2'd0),
  .s_axi_qdma_mm_awcache                 (4'd0),
  .s_axi_qdma_mm_awprot                  (3'd0),
  .s_axi_qdma_mm_awvalid                 (1'b0),
  .s_axi_qdma_mm_awready                 (),
  .s_axi_qdma_mm_wdata                   (512'd0),
  .s_axi_qdma_mm_wstrb                   (64'd0),
  .s_axi_qdma_mm_wlast                   (1'b0),
  .s_axi_qdma_mm_wvalid                  (1'b0),
  .s_axi_qdma_mm_wready                  (),
  .s_axi_qdma_mm_awlock                  (1'b0),
  .s_axi_qdma_mm_bid                     (),
  .s_axi_qdma_mm_bresp                   (),
  .s_axi_qdma_mm_bvalid                  (),
  .s_axi_qdma_mm_bready                  (1'b1),
  .s_axi_qdma_mm_arid                    (4'd0),
  .s_axi_qdma_mm_araddr                  (64'd0),
  .s_axi_qdma_mm_arlen                   (8'd0),
  .s_axi_qdma_mm_arsize                  (3'd0),
  .s_axi_qdma_mm_arburst                 (2'd0),
  .s_axi_qdma_mm_arcache                 (4'd0),
  .s_axi_qdma_mm_arprot                  (3'd0),
  .s_axi_qdma_mm_arvalid                 (1'b0),
  .s_axi_qdma_mm_arready                 (),
  .s_axi_qdma_mm_rid                     (),
  .s_axi_qdma_mm_rdata                   (),
  .s_axi_qdma_mm_rresp                   (),
  .s_axi_qdma_mm_rlast                   (),
  .s_axi_qdma_mm_rvalid                  (),
  .s_axi_qdma_mm_rready                  (1'b1),
  .s_axi_qdma_mm_arlock                  (1'b0),
  .s_axi_qdma_mm_arqos                   (4'd0),

  .s_axi_compute_logic_awid              (4'd0),
  .s_axi_compute_logic_awaddr            (64'd0),
  .s_axi_compute_logic_awqos             (4'd0),
  .s_axi_compute_logic_awlen             (8'd0),
  .s_axi_compute_logic_awsize            (3'd0),
  .s_axi_compute_logic_awburst           (2'd0),
  .s_axi_compute_logic_awcache           (4'd0),
  .s_axi_compute_logic_awprot            (3'd0),
  .s_axi_compute_logic_awvalid           (1'b0),
  .s_axi_compute_logic_awready           (),
  .s_axi_compute_logic_wdata             (512'd0),
  .s_axi_compute_logic_wstrb             (64'd0),
  .s_axi_compute_logic_wlast             (1'b0),
  .s_axi_compute_logic_wvalid            (1'b0),
  .s_axi_compute_logic_wready            (),
  .s_axi_compute_logic_awlock            (1'b0),
  .s_axi_compute_logic_bid               (),
  .s_axi_compute_logic_bresp             (),
  .s_axi_compute_logic_bvalid            (),
  .s_axi_compute_logic_bready            (1'b1),
  .s_axi_compute_logic_arid              (4'd0),
  .s_axi_compute_logic_araddr            (64'd0),
  .s_axi_compute_logic_arlen             (8'd0),
  .s_axi_compute_logic_arsize            (3'd0),
  .s_axi_compute_logic_arburst           (2'd0),
  .s_axi_compute_logic_arcache           (4'd0),
  .s_axi_compute_logic_arprot            (3'd0),
  .s_axi_compute_logic_arvalid           (1'b0),
  .s_axi_compute_logic_arready           (),
  .s_axi_compute_logic_rid               (),
  .s_axi_compute_logic_rdata             (),
  .s_axi_compute_logic_rresp             (),
  .s_axi_compute_logic_rlast             (),
  .s_axi_compute_logic_rvalid            (),
  .s_axi_compute_logic_rready            (1'b1),
  .s_axi_compute_logic_arlock            (1'b0),
  .s_axi_compute_logic_arqos             (4'd0),

  .m_axi_dev_mem_awaddr                  (axi_rdma_completion_or_init_sys_awaddr),
  .m_axi_dev_mem_awprot                  (axi_rdma_completion_or_init_sys_awprot),
  .m_axi_dev_mem_awvalid                 (axi_rdma_completion_or_init_sys_awvalid),
  .m_axi_dev_mem_awready                 (axi_rdma_completion_or_init_sys_awready),
  .m_axi_dev_mem_awsize                  (axi_rdma_completion_or_init_sys_awsize),
  .m_axi_dev_mem_awburst                 (axi_rdma_completion_or_init_sys_awburst),
  .m_axi_dev_mem_awcache                 (axi_rdma_completion_or_init_sys_awcache),
  .m_axi_dev_mem_awlen                   (axi_rdma_completion_or_init_sys_awlen),
  .m_axi_dev_mem_awlock                  (axi_rdma_completion_or_init_sys_awlock),
  .m_axi_dev_mem_awqos                   (axi_rdma_completion_or_init_sys_awqos),
  .m_axi_dev_mem_awregion                (),
  .m_axi_dev_mem_awid                    (axi_rdma_completion_or_init_sys_awid),
  .m_axi_dev_mem_wdata                   (axi_rdma_completion_or_init_sys_wdata),
  .m_axi_dev_mem_wstrb                   (axi_rdma_completion_or_init_sys_wstrb),
  .m_axi_dev_mem_wvalid                  (axi_rdma_completion_or_init_sys_wvalid),
  .m_axi_dev_mem_wready                  (axi_rdma_completion_or_init_sys_wready),
  .m_axi_dev_mem_wlast                   (axi_rdma_completion_or_init_sys_wlast),
  .m_axi_dev_mem_bresp                   (axi_rdma_completion_or_init_sys_bresp),
  .m_axi_dev_mem_bvalid                  (axi_rdma_completion_or_init_sys_bvalid),
  .m_axi_dev_mem_bready                  (axi_rdma_completion_or_init_sys_bready),
  .m_axi_dev_mem_bid                     ({1'b0,axi_rdma_completion_or_init_sys_bid}),
  .m_axi_dev_mem_araddr                  (axi_rdma_completion_or_init_sys_araddr),
  .m_axi_dev_mem_arprot                  (axi_rdma_completion_or_init_sys_arprot),
  .m_axi_dev_mem_arvalid                 (axi_rdma_completion_or_init_sys_arvalid),
  .m_axi_dev_mem_arready                 (axi_rdma_completion_or_init_sys_arready),
  .m_axi_dev_mem_arsize                  (axi_rdma_completion_or_init_sys_arsize),
  .m_axi_dev_mem_arburst                 (axi_rdma_completion_or_init_sys_arburst),
  .m_axi_dev_mem_arcache                 (axi_rdma_completion_or_init_sys_arcache),
  .m_axi_dev_mem_arlock                  (axi_rdma_completion_or_init_sys_arlock),
  .m_axi_dev_mem_arlen                   (axi_rdma_completion_or_init_sys_arlen),
  .m_axi_dev_mem_arqos                   (axi_rdma_completion_or_init_sys_arqos),
  .m_axi_dev_mem_arregion                (),
  .m_axi_dev_mem_arid                    (axi_rdma_completion_or_init_sys_arid),
  .m_axi_dev_mem_rdata                   (axi_rdma_completion_or_init_sys_rdata),
  .m_axi_dev_mem_rresp                   (axi_rdma_completion_or_init_sys_rresp),
  .m_axi_dev_mem_rvalid                  (axi_rdma_completion_or_init_sys_rvalid),
  .m_axi_dev_mem_rready                  (axi_rdma_completion_or_init_sys_rready),
  .m_axi_dev_mem_rlast                   (axi_rdma_completion_or_init_sys_rlast),
  .m_axi_dev_mem_rid                     ({1'b0,axi_rdma_completion_or_init_sys_rid}), 

  .axis_aclk   (axis_clk),
  .axis_arestn (axis_rstn)   
);

axi_interconnect_to_dev_mem axi_2to1_for_rsp_or_hw_hndshk(
  .s_axi_rdma_send_write_payload_awid    (axi_rdma_rsp_payload_awid),
  .s_axi_rdma_send_write_payload_awaddr  (axi_rdma_rsp_payload_awaddr),
  .s_axi_rdma_send_write_payload_awqos   (axi_rdma_rsp_payload_awqos),
  .s_axi_rdma_send_write_payload_awlen   (axi_rdma_rsp_payload_awlen),
  .s_axi_rdma_send_write_payload_awsize  (axi_rdma_rsp_payload_awsize),
  .s_axi_rdma_send_write_payload_awburst (axi_rdma_rsp_payload_awburst),
  .s_axi_rdma_send_write_payload_awcache (axi_rdma_rsp_payload_awcache),
  .s_axi_rdma_send_write_payload_awprot  (axi_rdma_rsp_payload_awprot),
  .s_axi_rdma_send_write_payload_awvalid (axi_rdma_rsp_payload_awvalid),
  .s_axi_rdma_send_write_payload_awready (axi_rdma_rsp_payload_awready),
  .s_axi_rdma_send_write_payload_wdata   (axi_rdma_rsp_payload_wdata),
  .s_axi_rdma_send_write_payload_wstrb   (axi_rdma_rsp_payload_wstrb),
  .s_axi_rdma_send_write_payload_wlast   (axi_rdma_rsp_payload_wlast),
  .s_axi_rdma_send_write_payload_wvalid  (axi_rdma_rsp_payload_wvalid),
  .s_axi_rdma_send_write_payload_wready  (axi_rdma_rsp_payload_wready),
  .s_axi_rdma_send_write_payload_awlock  (axi_rdma_rsp_payload_awlock),
  .s_axi_rdma_send_write_payload_bid     (axi_rdma_rsp_payload_bid),
  .s_axi_rdma_send_write_payload_bresp   (axi_rdma_rsp_payload_bresp),
  .s_axi_rdma_send_write_payload_bvalid  (axi_rdma_rsp_payload_bvalid),
  .s_axi_rdma_send_write_payload_bready  (axi_rdma_rsp_payload_bready),
  .s_axi_rdma_send_write_payload_arid    (axi_rdma_rsp_payload_arid),
  .s_axi_rdma_send_write_payload_araddr  (axi_rdma_rsp_payload_araddr),
  .s_axi_rdma_send_write_payload_arlen   (axi_rdma_rsp_payload_arlen),
  .s_axi_rdma_send_write_payload_arsize  (axi_rdma_rsp_payload_arsize),
  .s_axi_rdma_send_write_payload_arburst (axi_rdma_rsp_payload_arburst),
  .s_axi_rdma_send_write_payload_arcache (axi_rdma_rsp_payload_arcache),
  .s_axi_rdma_send_write_payload_arprot  (axi_rdma_rsp_payload_arprot),
  .s_axi_rdma_send_write_payload_arvalid (axi_rdma_rsp_payload_arvalid),
  .s_axi_rdma_send_write_payload_arready (axi_rdma_rsp_payload_arready),
  .s_axi_rdma_send_write_payload_rid     (axi_rdma_rsp_payload_rid),
  .s_axi_rdma_send_write_payload_rdata   (axi_rdma_rsp_payload_rdata),
  .s_axi_rdma_send_write_payload_rresp   (axi_rdma_rsp_payload_rresp),
  .s_axi_rdma_send_write_payload_rlast   (axi_rdma_rsp_payload_rlast),
  .s_axi_rdma_send_write_payload_rvalid  (axi_rdma_rsp_payload_rvalid),
  .s_axi_rdma_send_write_payload_rready  (axi_rdma_rsp_payload_rready),
  .s_axi_rdma_send_write_payload_arlock  (axi_rdma_rsp_payload_arlock),
  .s_axi_rdma_send_write_payload_arqos   (axi_rdma_rsp_payload_arqos),

  .s_axi_rdma_rsp_payload_awid           (axi_hw_hndshk_to_sys_mem_awid),
  .s_axi_rdma_rsp_payload_awaddr         (axi_hw_hndshk_to_sys_mem_awaddr),
  .s_axi_rdma_rsp_payload_awqos          (axi_hw_hndshk_to_sys_mem_awqos),
  .s_axi_rdma_rsp_payload_awlen          (axi_hw_hndshk_to_sys_mem_awlen),
  .s_axi_rdma_rsp_payload_awsize         (axi_hw_hndshk_to_sys_mem_awsize),
  .s_axi_rdma_rsp_payload_awburst        (axi_hw_hndshk_to_sys_mem_awburst),
  .s_axi_rdma_rsp_payload_awcache        (axi_hw_hndshk_to_sys_mem_awcache),
  .s_axi_rdma_rsp_payload_awprot         (axi_hw_hndshk_to_sys_mem_awprot),
  .s_axi_rdma_rsp_payload_awvalid        (axi_hw_hndshk_to_sys_mem_awvalid),
  .s_axi_rdma_rsp_payload_awready        (axi_hw_hndshk_to_sys_mem_awready),
  .s_axi_rdma_rsp_payload_wdata          (axi_hw_hndshk_to_sys_mem_wdata),
  .s_axi_rdma_rsp_payload_wstrb          (axi_hw_hndshk_to_sys_mem_wstrb),
  .s_axi_rdma_rsp_payload_wlast          (axi_hw_hndshk_to_sys_mem_wlast),
  .s_axi_rdma_rsp_payload_wvalid         (axi_hw_hndshk_to_sys_mem_wvalid),
  .s_axi_rdma_rsp_payload_wready         (axi_hw_hndshk_to_sys_mem_wready),
  .s_axi_rdma_rsp_payload_awlock         (axi_hw_hndshk_to_sys_mem_awlock),
  .s_axi_rdma_rsp_payload_bid            (axi_hw_hndshk_to_sys_mem_bid),
  .s_axi_rdma_rsp_payload_bresp          (axi_hw_hndshk_to_sys_mem_bresp),
  .s_axi_rdma_rsp_payload_bvalid         (axi_hw_hndshk_to_sys_mem_bvalid),
  .s_axi_rdma_rsp_payload_bready         (axi_hw_hndshk_to_sys_mem_bready),
  .s_axi_rdma_rsp_payload_arid           (axi_hw_hndshk_to_sys_mem_arid),
  .s_axi_rdma_rsp_payload_araddr         (axi_hw_hndshk_to_sys_mem_araddr),
  .s_axi_rdma_rsp_payload_arlen          (axi_hw_hndshk_to_sys_mem_arlen),
  .s_axi_rdma_rsp_payload_arsize         (axi_hw_hndshk_to_sys_mem_arsize),
  .s_axi_rdma_rsp_payload_arburst        (axi_hw_hndshk_to_sys_mem_arburst),
  .s_axi_rdma_rsp_payload_arcache        (axi_hw_hndshk_to_sys_mem_arcache),
  .s_axi_rdma_rsp_payload_arprot         (axi_hw_hndshk_to_sys_mem_arprot),
  .s_axi_rdma_rsp_payload_arvalid        (axi_hw_hndshk_to_sys_mem_arvalid),
  .s_axi_rdma_rsp_payload_arready        (axi_hw_hndshk_to_sys_mem_arready),
  .s_axi_rdma_rsp_payload_rid            (axi_hw_hndshk_to_sys_mem_rid),
  .s_axi_rdma_rsp_payload_rdata          (axi_hw_hndshk_to_sys_mem_rdata),
  .s_axi_rdma_rsp_payload_rresp          (axi_hw_hndshk_to_sys_mem_rresp),
  .s_axi_rdma_rsp_payload_rlast          (axi_hw_hndshk_to_sys_mem_rlast),
  .s_axi_rdma_rsp_payload_rvalid         (axi_hw_hndshk_to_sys_mem_rvalid),
  .s_axi_rdma_rsp_payload_rready         (axi_hw_hndshk_to_sys_mem_rready),
  .s_axi_rdma_rsp_payload_arlock         (axi_hw_hndshk_to_sys_mem_arlock),
  .s_axi_rdma_rsp_payload_arqos          (axi_hw_hndshk_to_sys_mem_arqos),

  .s_axi_qdma_mm_awid                    (4'd0),
  .s_axi_qdma_mm_awaddr                  (64'd0),
  .s_axi_qdma_mm_awqos                   (4'd0),
  .s_axi_qdma_mm_awlen                   (8'd0),
  .s_axi_qdma_mm_awsize                  (3'd0),
  .s_axi_qdma_mm_awburst                 (2'd0),
  .s_axi_qdma_mm_awcache                 (4'd0),
  .s_axi_qdma_mm_awprot                  (3'd0),
  .s_axi_qdma_mm_awvalid                 (1'b0),
  .s_axi_qdma_mm_awready                 (),
  .s_axi_qdma_mm_wdata                   (512'd0),
  .s_axi_qdma_mm_wstrb                   (64'd0),
  .s_axi_qdma_mm_wlast                   (1'b0),
  .s_axi_qdma_mm_wvalid                  (1'b0),
  .s_axi_qdma_mm_wready                  (),
  .s_axi_qdma_mm_awlock                  (1'b0),
  .s_axi_qdma_mm_bid                     (),
  .s_axi_qdma_mm_bresp                   (),
  .s_axi_qdma_mm_bvalid                  (),
  .s_axi_qdma_mm_bready                  (1'b1),
  .s_axi_qdma_mm_arid                    (4'd0),
  .s_axi_qdma_mm_araddr                  (64'd0),
  .s_axi_qdma_mm_arlen                   (8'd0),
  .s_axi_qdma_mm_arsize                  (3'd0),
  .s_axi_qdma_mm_arburst                 (2'd0),
  .s_axi_qdma_mm_arcache                 (4'd0),
  .s_axi_qdma_mm_arprot                  (3'd0),
  .s_axi_qdma_mm_arvalid                 (1'b0),
  .s_axi_qdma_mm_arready                 (),
  .s_axi_qdma_mm_rid                     (),
  .s_axi_qdma_mm_rdata                   (),
  .s_axi_qdma_mm_rresp                   (),
  .s_axi_qdma_mm_rlast                   (),
  .s_axi_qdma_mm_rvalid                  (),
  .s_axi_qdma_mm_rready                  (1'b1),
  .s_axi_qdma_mm_arlock                  (1'b0),
  .s_axi_qdma_mm_arqos                   (4'd0),

  .s_axi_compute_logic_awid              (4'd0),
  .s_axi_compute_logic_awaddr            (64'd0),
  .s_axi_compute_logic_awqos             (4'd0),
  .s_axi_compute_logic_awlen             (8'd0),
  .s_axi_compute_logic_awsize            (3'd0),
  .s_axi_compute_logic_awburst           (2'd0),
  .s_axi_compute_logic_awcache           (4'd0),
  .s_axi_compute_logic_awprot            (3'd0),
  .s_axi_compute_logic_awvalid           (1'b0),
  .s_axi_compute_logic_awready           (),
  .s_axi_compute_logic_wdata             (512'd0),
  .s_axi_compute_logic_wstrb             (64'd0),
  .s_axi_compute_logic_wlast             (1'b0),
  .s_axi_compute_logic_wvalid            (1'b0),
  .s_axi_compute_logic_wready            (),
  .s_axi_compute_logic_awlock            (1'b0),
  .s_axi_compute_logic_bid               (),
  .s_axi_compute_logic_bresp             (),
  .s_axi_compute_logic_bvalid            (),
  .s_axi_compute_logic_bready            (1'b1),
  .s_axi_compute_logic_arid              (4'd0),
  .s_axi_compute_logic_araddr            (64'd0),
  .s_axi_compute_logic_arlen             (8'd0),
  .s_axi_compute_logic_arsize            (3'd0),
  .s_axi_compute_logic_arburst           (2'd0),
  .s_axi_compute_logic_arcache           (4'd0),
  .s_axi_compute_logic_arprot            (3'd0),
  .s_axi_compute_logic_arvalid           (1'b0),
  .s_axi_compute_logic_arready           (),
  .s_axi_compute_logic_rid               (),
  .s_axi_compute_logic_rdata             (),
  .s_axi_compute_logic_rresp             (),
  .s_axi_compute_logic_rlast             (),
  .s_axi_compute_logic_rvalid            (),
  .s_axi_compute_logic_rready            (1'b1),
  .s_axi_compute_logic_arlock            (1'b0),
  .s_axi_compute_logic_arqos             (4'd0),

  .m_axi_dev_mem_awaddr                  (axi_rdma_rsp_or_hw_hndshk_sys_awaddr),
  .m_axi_dev_mem_awprot                  (axi_rdma_rsp_or_hw_hndshk_sys_awprot),
  .m_axi_dev_mem_awvalid                 (axi_rdma_rsp_or_hw_hndshk_sys_awvalid),
  .m_axi_dev_mem_awready                 (axi_rdma_rsp_or_hw_hndshk_sys_awready),
  .m_axi_dev_mem_awsize                  (axi_rdma_rsp_or_hw_hndshk_sys_awsize),
  .m_axi_dev_mem_awburst                 (axi_rdma_rsp_or_hw_hndshk_sys_awburst),
  .m_axi_dev_mem_awcache                 (axi_rdma_rsp_or_hw_hndshk_sys_awcache),
  .m_axi_dev_mem_awlen                   (axi_rdma_rsp_or_hw_hndshk_sys_awlen),
  .m_axi_dev_mem_awlock                  (axi_rdma_rsp_or_hw_hndshk_sys_awlock),
  .m_axi_dev_mem_awqos                   (axi_rdma_rsp_or_hw_hndshk_sys_awqos),
  .m_axi_dev_mem_awregion                (),
  .m_axi_dev_mem_awid                    (axi_rdma_rsp_or_hw_hndshk_sys_awid),
  .m_axi_dev_mem_wdata                   (axi_rdma_rsp_or_hw_hndshk_sys_wdata),
  .m_axi_dev_mem_wstrb                   (axi_rdma_rsp_or_hw_hndshk_sys_wstrb),
  .m_axi_dev_mem_wvalid                  (axi_rdma_rsp_or_hw_hndshk_sys_wvalid),
  .m_axi_dev_mem_wready                  (axi_rdma_rsp_or_hw_hndshk_sys_wready),
  .m_axi_dev_mem_wlast                   (axi_rdma_rsp_or_hw_hndshk_sys_wlast),
  .m_axi_dev_mem_bresp                   (axi_rdma_rsp_or_hw_hndshk_sys_bresp),
  .m_axi_dev_mem_bvalid                  (axi_rdma_rsp_or_hw_hndshk_sys_bvalid),
  .m_axi_dev_mem_bready                  (axi_rdma_rsp_or_hw_hndshk_sys_bready),
  .m_axi_dev_mem_bid                     ({1'b0,axi_rdma_rsp_or_hw_hndshk_sys_bid}),
  .m_axi_dev_mem_araddr                  (axi_rdma_rsp_or_hw_hndshk_sys_araddr),
  .m_axi_dev_mem_arprot                  (axi_rdma_rsp_or_hw_hndshk_sys_arprot),
  .m_axi_dev_mem_arvalid                 (axi_rdma_rsp_or_hw_hndshk_sys_arvalid),
  .m_axi_dev_mem_arready                 (axi_rdma_rsp_or_hw_hndshk_sys_arready),
  .m_axi_dev_mem_arsize                  (axi_rdma_rsp_or_hw_hndshk_sys_arsize),
  .m_axi_dev_mem_arburst                 (axi_rdma_rsp_or_hw_hndshk_sys_arburst),
  .m_axi_dev_mem_arcache                 (axi_rdma_rsp_or_hw_hndshk_sys_arcache),
  .m_axi_dev_mem_arlock                  (axi_rdma_rsp_or_hw_hndshk_sys_arlock),
  .m_axi_dev_mem_arlen                   (axi_rdma_rsp_or_hw_hndshk_sys_arlen),
  .m_axi_dev_mem_arqos                   (axi_rdma_rsp_or_hw_hndshk_sys_arqos),
  .m_axi_dev_mem_arregion                (),
  .m_axi_dev_mem_arid                    (axi_rdma_rsp_or_hw_hndshk_sys_arid),
  .m_axi_dev_mem_rdata                   (axi_rdma_rsp_or_hw_hndshk_sys_rdata),
  .m_axi_dev_mem_rresp                   (axi_rdma_rsp_or_hw_hndshk_sys_rresp),
  .m_axi_dev_mem_rvalid                  (axi_rdma_rsp_or_hw_hndshk_sys_rvalid),
  .m_axi_dev_mem_rready                  (axi_rdma_rsp_or_hw_hndshk_sys_rready),
  .m_axi_dev_mem_rlast                   (axi_rdma_rsp_or_hw_hndshk_sys_rlast),
  .m_axi_dev_mem_rid                     ({1'b0,axi_rdma_rsp_or_hw_hndshk_sys_rid}), 

  .axis_aclk   (axis_clk),
  .axis_arestn (axis_rstn)   
);

axi_interconnect_to_dev_mem axi_2to1_for_get_rdma_payload_from_sys_mem(
  .s_axi_rdma_send_write_payload_awid    (m_axi_rdma1_get_payload_awid),
  .s_axi_rdma_send_write_payload_awaddr  (m_axi_rdma1_get_payload_awaddr),
  .s_axi_rdma_send_write_payload_awqos   (m_axi_rdma1_get_payload_awqos),
  .s_axi_rdma_send_write_payload_awlen   (m_axi_rdma1_get_payload_awlen),
  .s_axi_rdma_send_write_payload_awsize  (m_axi_rdma1_get_payload_awsize),
  .s_axi_rdma_send_write_payload_awburst (m_axi_rdma1_get_payload_awburst),
  .s_axi_rdma_send_write_payload_awcache (m_axi_rdma1_get_payload_awcache),
  .s_axi_rdma_send_write_payload_awprot  (m_axi_rdma1_get_payload_awprot),
  .s_axi_rdma_send_write_payload_awvalid (m_axi_rdma1_get_payload_awvalid),
  .s_axi_rdma_send_write_payload_awready (m_axi_rdma1_get_payload_awready),
  .s_axi_rdma_send_write_payload_wdata   (m_axi_rdma1_get_payload_wdata),
  .s_axi_rdma_send_write_payload_wstrb   (m_axi_rdma1_get_payload_wstrb),
  .s_axi_rdma_send_write_payload_wlast   (m_axi_rdma1_get_payload_wlast),
  .s_axi_rdma_send_write_payload_wvalid  (m_axi_rdma1_get_payload_wvalid),
  .s_axi_rdma_send_write_payload_wready  (m_axi_rdma1_get_payload_wready),
  .s_axi_rdma_send_write_payload_awlock  (m_axi_rdma1_get_payload_awlock),
  .s_axi_rdma_send_write_payload_bid     (m_axi_rdma1_get_payload_bid),
  .s_axi_rdma_send_write_payload_bresp   (m_axi_rdma1_get_payload_bresp),
  .s_axi_rdma_send_write_payload_bvalid  (m_axi_rdma1_get_payload_bvalid),
  .s_axi_rdma_send_write_payload_bready  (m_axi_rdma1_get_payload_bready),
  .s_axi_rdma_send_write_payload_arid    (m_axi_rdma1_get_payload_arid),
  .s_axi_rdma_send_write_payload_araddr  (m_axi_rdma1_get_payload_araddr),
  .s_axi_rdma_send_write_payload_arlen   (m_axi_rdma1_get_payload_arlen),
  .s_axi_rdma_send_write_payload_arsize  (m_axi_rdma1_get_payload_arsize),
  .s_axi_rdma_send_write_payload_arburst (m_axi_rdma1_get_payload_arburst),
  .s_axi_rdma_send_write_payload_arcache (m_axi_rdma1_get_payload_arcache),
  .s_axi_rdma_send_write_payload_arprot  (m_axi_rdma1_get_payload_arprot),
  .s_axi_rdma_send_write_payload_arvalid (m_axi_rdma1_get_payload_arvalid),
  .s_axi_rdma_send_write_payload_arready (m_axi_rdma1_get_payload_arready),
  .s_axi_rdma_send_write_payload_rid     (m_axi_rdma1_get_payload_rid),
  .s_axi_rdma_send_write_payload_rdata   (m_axi_rdma1_get_payload_rdata),
  .s_axi_rdma_send_write_payload_rresp   (m_axi_rdma1_get_payload_rresp),
  .s_axi_rdma_send_write_payload_rlast   (m_axi_rdma1_get_payload_rlast),
  .s_axi_rdma_send_write_payload_rvalid  (m_axi_rdma1_get_payload_rvalid),
  .s_axi_rdma_send_write_payload_rready  (m_axi_rdma1_get_payload_rready),
  .s_axi_rdma_send_write_payload_arlock  (m_axi_rdma1_get_payload_arlock),
  .s_axi_rdma_send_write_payload_arqos   (m_axi_rdma1_get_payload_arqos),

  .s_axi_rdma_rsp_payload_awid           (m_axi_rdma2_get_payload_awid),
  .s_axi_rdma_rsp_payload_awaddr         (m_axi_rdma2_get_payload_awaddr),
  .s_axi_rdma_rsp_payload_awqos          (m_axi_rdma2_get_payload_awqos),
  .s_axi_rdma_rsp_payload_awlen          (m_axi_rdma2_get_payload_awlen),
  .s_axi_rdma_rsp_payload_awsize         (m_axi_rdma2_get_payload_awsize),
  .s_axi_rdma_rsp_payload_awburst        (m_axi_rdma2_get_payload_awburst),
  .s_axi_rdma_rsp_payload_awcache        (m_axi_rdma2_get_payload_awcache),
  .s_axi_rdma_rsp_payload_awprot         (m_axi_rdma2_get_payload_awprot),
  .s_axi_rdma_rsp_payload_awvalid        (m_axi_rdma2_get_payload_awvalid),
  .s_axi_rdma_rsp_payload_awready        (m_axi_rdma2_get_payload_awready),
  .s_axi_rdma_rsp_payload_wdata          (m_axi_rdma2_get_payload_wdata),
  .s_axi_rdma_rsp_payload_wstrb          (m_axi_rdma2_get_payload_wstrb),
  .s_axi_rdma_rsp_payload_wlast          (m_axi_rdma2_get_payload_wlast),
  .s_axi_rdma_rsp_payload_wvalid         (m_axi_rdma2_get_payload_wvalid),
  .s_axi_rdma_rsp_payload_wready         (m_axi_rdma2_get_payload_wready),
  .s_axi_rdma_rsp_payload_awlock         (m_axi_rdma2_get_payload_awlock),
  .s_axi_rdma_rsp_payload_bid            (m_axi_rdma2_get_payload_bid),
  .s_axi_rdma_rsp_payload_bresp          (m_axi_rdma2_get_payload_bresp),
  .s_axi_rdma_rsp_payload_bvalid         (m_axi_rdma2_get_payload_bvalid),
  .s_axi_rdma_rsp_payload_bready         (m_axi_rdma2_get_payload_bready),
  .s_axi_rdma_rsp_payload_arid           (m_axi_rdma2_get_payload_arid),
  .s_axi_rdma_rsp_payload_araddr         (m_axi_rdma2_get_payload_araddr),
  .s_axi_rdma_rsp_payload_arlen          (m_axi_rdma2_get_payload_arlen),
  .s_axi_rdma_rsp_payload_arsize         (m_axi_rdma2_get_payload_arsize),
  .s_axi_rdma_rsp_payload_arburst        (m_axi_rdma2_get_payload_arburst),
  .s_axi_rdma_rsp_payload_arcache        (m_axi_rdma2_get_payload_arcache),
  .s_axi_rdma_rsp_payload_arprot         (m_axi_rdma2_get_payload_arprot),
  .s_axi_rdma_rsp_payload_arvalid        (m_axi_rdma2_get_payload_arvalid),
  .s_axi_rdma_rsp_payload_arready        (m_axi_rdma2_get_payload_arready),
  .s_axi_rdma_rsp_payload_rid            (m_axi_rdma2_get_payload_rid),
  .s_axi_rdma_rsp_payload_rdata          (m_axi_rdma2_get_payload_rdata),
  .s_axi_rdma_rsp_payload_rresp          (m_axi_rdma2_get_payload_rresp),
  .s_axi_rdma_rsp_payload_rlast          (m_axi_rdma2_get_payload_rlast),
  .s_axi_rdma_rsp_payload_rvalid         (m_axi_rdma2_get_payload_rvalid),
  .s_axi_rdma_rsp_payload_rready         (m_axi_rdma2_get_payload_rready),
  .s_axi_rdma_rsp_payload_arlock         (m_axi_rdma2_get_payload_arlock),
  .s_axi_rdma_rsp_payload_arqos          (m_axi_rdma2_get_payload_arqos),

  .s_axi_qdma_mm_awid                    (4'd0),
  .s_axi_qdma_mm_awaddr                  (64'd0),
  .s_axi_qdma_mm_awqos                   (4'd0),
  .s_axi_qdma_mm_awlen                   (8'd0),
  .s_axi_qdma_mm_awsize                  (3'd0),
  .s_axi_qdma_mm_awburst                 (2'd0),
  .s_axi_qdma_mm_awcache                 (4'd0),
  .s_axi_qdma_mm_awprot                  (3'd0),
  .s_axi_qdma_mm_awvalid                 (1'b0),
  .s_axi_qdma_mm_awready                 (),
  .s_axi_qdma_mm_wdata                   (512'd0),
  .s_axi_qdma_mm_wstrb                   (64'd0),
  .s_axi_qdma_mm_wlast                   (1'b0),
  .s_axi_qdma_mm_wvalid                  (1'b0),
  .s_axi_qdma_mm_wready                  (),
  .s_axi_qdma_mm_awlock                  (1'b0),
  .s_axi_qdma_mm_bid                     (),
  .s_axi_qdma_mm_bresp                   (),
  .s_axi_qdma_mm_bvalid                  (),
  .s_axi_qdma_mm_bready                  (1'b1),
  .s_axi_qdma_mm_arid                    (4'd0),
  .s_axi_qdma_mm_araddr                  (64'd0),
  .s_axi_qdma_mm_arlen                   (8'd0),
  .s_axi_qdma_mm_arsize                  (3'd0),
  .s_axi_qdma_mm_arburst                 (2'd0),
  .s_axi_qdma_mm_arcache                 (4'd0),
  .s_axi_qdma_mm_arprot                  (3'd0),
  .s_axi_qdma_mm_arvalid                 (1'b0),
  .s_axi_qdma_mm_arready                 (),
  .s_axi_qdma_mm_rid                     (),
  .s_axi_qdma_mm_rdata                   (),
  .s_axi_qdma_mm_rresp                   (),
  .s_axi_qdma_mm_rlast                   (),
  .s_axi_qdma_mm_rvalid                  (),
  .s_axi_qdma_mm_rready                  (1'b1),
  .s_axi_qdma_mm_arlock                  (1'b0),
  .s_axi_qdma_mm_arqos                   (4'd0),

  .s_axi_compute_logic_awid           (0),
  .s_axi_compute_logic_awaddr         (64'd0),
  .s_axi_compute_logic_awqos          (0),
  .s_axi_compute_logic_awlen          (0),
  .s_axi_compute_logic_awsize         (0),
  .s_axi_compute_logic_awburst        (0),
  .s_axi_compute_logic_awcache        (0),
  .s_axi_compute_logic_awprot         (0),
  .s_axi_compute_logic_awvalid        (0),
  .s_axi_compute_logic_awready        (),
  .s_axi_compute_logic_wdata          (512'd0),
  .s_axi_compute_logic_wstrb          (64'd0),
  .s_axi_compute_logic_wlast          (0),
  .s_axi_compute_logic_wvalid         (0),
  .s_axi_compute_logic_wready         (),
  .s_axi_compute_logic_awlock         (0),
  .s_axi_compute_logic_bid            (),
  .s_axi_compute_logic_bresp          (),
  .s_axi_compute_logic_bvalid         (),
  .s_axi_compute_logic_bready         (1'b1),
  .s_axi_compute_logic_arid           (0),
  .s_axi_compute_logic_araddr         (64'd0),
  .s_axi_compute_logic_arlen          (0),
  .s_axi_compute_logic_arsize         (0),
  .s_axi_compute_logic_arburst        (0),
  .s_axi_compute_logic_arcache        (0),
  .s_axi_compute_logic_arprot         (0),
  .s_axi_compute_logic_arvalid        (0),
  .s_axi_compute_logic_arready        (),
  .s_axi_compute_logic_rid            (),
  .s_axi_compute_logic_rdata          (),
  .s_axi_compute_logic_rresp          (),
  .s_axi_compute_logic_rlast          (),
  .s_axi_compute_logic_rvalid         (),
  .s_axi_compute_logic_rready         (0),
  .s_axi_compute_logic_arlock         (0),
  .s_axi_compute_logic_arqos          (0),

  .m_axi_dev_mem_awaddr                  (axi_rdma_get_payload_awaddr),
  .m_axi_dev_mem_awprot                  (axi_rdma_get_payload_awprot),
  .m_axi_dev_mem_awvalid                 (axi_rdma_get_payload_awvalid),
  .m_axi_dev_mem_awready                 (axi_rdma_get_payload_awready),
  .m_axi_dev_mem_awsize                  (axi_rdma_get_payload_awsize),
  .m_axi_dev_mem_awburst                 (axi_rdma_get_payload_awburst),
  .m_axi_dev_mem_awcache                 (axi_rdma_get_payload_awcache),
  .m_axi_dev_mem_awlen                   (axi_rdma_get_payload_awlen),
  .m_axi_dev_mem_awlock                  (axi_rdma_get_payload_awlock),
  .m_axi_dev_mem_awqos                   (axi_rdma_get_payload_awqos),
  .m_axi_dev_mem_awregion                (),
  .m_axi_dev_mem_awid                    (axi_rdma_get_payload_awid),
  .m_axi_dev_mem_wdata                   (axi_rdma_get_payload_wdata),
  .m_axi_dev_mem_wstrb                   (axi_rdma_get_payload_wstrb),
  .m_axi_dev_mem_wvalid                  (axi_rdma_get_payload_wvalid),
  .m_axi_dev_mem_wready                  (axi_rdma_get_payload_wready),
  .m_axi_dev_mem_wlast                   (axi_rdma_get_payload_wlast),
  .m_axi_dev_mem_bresp                   (axi_rdma_get_payload_bresp),
  .m_axi_dev_mem_bvalid                  (axi_rdma_get_payload_bvalid),
  .m_axi_dev_mem_bready                  (axi_rdma_get_payload_bready),
  .m_axi_dev_mem_bid                     (axi_rdma_get_payload_bid),
  .m_axi_dev_mem_araddr                  (axi_rdma_get_payload_araddr),
  .m_axi_dev_mem_arprot                  (axi_rdma_get_payload_arprot),
  .m_axi_dev_mem_arvalid                 (axi_rdma_get_payload_arvalid),
  .m_axi_dev_mem_arready                 (axi_rdma_get_payload_arready),
  .m_axi_dev_mem_arsize                  (axi_rdma_get_payload_arsize),
  .m_axi_dev_mem_arburst                 (axi_rdma_get_payload_arburst),
  .m_axi_dev_mem_arcache                 (axi_rdma_get_payload_arcache),
  .m_axi_dev_mem_arlock                  (axi_rdma_get_payload_arlock),
  .m_axi_dev_mem_arlen                   (axi_rdma_get_payload_arlen),
  .m_axi_dev_mem_arqos                   (axi_rdma_get_payload_arqos),
  .m_axi_dev_mem_arregion                (),
  .m_axi_dev_mem_arid                    (axi_rdma_get_payload_arid),
  .m_axi_dev_mem_rdata                   (axi_rdma_get_payload_rdata),
  .m_axi_dev_mem_rresp                   (axi_rdma_get_payload_rresp),
  .m_axi_dev_mem_rvalid                  (axi_rdma_get_payload_rvalid),
  .m_axi_dev_mem_rready                  (axi_rdma_get_payload_rready),
  .m_axi_dev_mem_rlast                   (axi_rdma_get_payload_rlast),
  .m_axi_dev_mem_rid                     (axi_rdma_get_payload_rid), 

  .axis_aclk   (axis_clk),
  .axis_arestn (axis_rstn)   
);


// Add FIFO to store m_axi_arid/m_axi_wrid and output m_axi_rid/m_axi_bid
xpm_fifo_sync #(
  .DOUT_RESET_VALUE    ("0"),
  .ECC_MODE            ("no_ecc"),
  .FIFO_MEMORY_TYPE    ("auto"),
  .FIFO_READ_LATENCY   (0),
  .FIFO_WRITE_DEPTH    (1024),
  .PROG_FULL_THRESH    (1024-5),
  .READ_DATA_WIDTH     (2),
  .READ_MODE           ("std"),
  .WRITE_DATA_WIDTH    (2)
) rdma_arid_fifo (
  .wr_en         (axi_rdma_get_payload_arready && axi_rdma_get_payload_arvalid),
  .din           (axi_rdma_get_payload_arid),
  .wr_ack        (),
  .rd_en         (axi_rdma_get_payload_rready && axi_rdma_get_payload_rvalid && axi_rdma_get_payload_rlast),
  .data_valid    (),
  .dout          (axi_rdma_get_payload_rid),

  .wr_data_count (),
  .rd_data_count (),

  .empty         (),
  .full          (),
  .almost_empty  (),
  .almost_full   (),
  .overflow      (),
  .underflow     (),
  .prog_empty    (),
  .prog_full     (),
  .sleep         (1'b0),

  .sbiterr       (),
  .dbiterr       (),
  .injectsbiterr (1'b0),
  .injectdbiterr (1'b0),

  .wr_clk        (axis_clk),
  .rst           (~axis_rstn),
  .rd_rst_busy   (),
  .wr_rst_busy   ()
);

xpm_fifo_sync #(
  .DOUT_RESET_VALUE    ("0"),
  .ECC_MODE            ("no_ecc"),
  .FIFO_MEMORY_TYPE    ("auto"),
  .FIFO_READ_LATENCY   (0),
  .FIFO_WRITE_DEPTH    (1024),
  .PROG_FULL_THRESH    (1024-5),
  .READ_DATA_WIDTH     (1),
  .READ_MODE           ("std"),
  .WRITE_DATA_WIDTH    (1)
) rdma_hw_hndshk_awid_fifo (
  .wr_en         (axi_rdma_rsp_or_hw_hndshk_sys_awready && axi_rdma_rsp_or_hw_hndshk_sys_awvalid),
  .din           (axi_rdma_rsp_or_hw_hndshk_sys_awid),
  .wr_ack        (),
  .rd_en         (axi_rdma_rsp_or_hw_hndshk_sys_bvalid),//axi_rdma_completion_or_init_sys_wready && axi_rdma_completion_or_init_sys_wvalid && axi_rdma_completion_or_init_sys_wlast
  .data_valid    (),
  .dout          (axi_rdma_rsp_or_hw_hndshk_sys_bid),

  .wr_data_count (),
  .rd_data_count (),

  .empty         (),
  .full          (),
  .almost_empty  (),
  .almost_full   (),
  .overflow      (),
  .underflow     (),
  .prog_empty    (),
  .prog_full     (),
  .sleep         (1'b0),

  .sbiterr       (),
  .dbiterr       (),
  .injectsbiterr (1'b0),
  .injectdbiterr (1'b0),

  .wr_clk        (axis_clk),
  .rst           (~axis_rstn),
  .rd_rst_busy   (),
  .wr_rst_busy   ()
);

xpm_fifo_sync #(
  .DOUT_RESET_VALUE    ("0"),
  .ECC_MODE            ("no_ecc"),
  .FIFO_MEMORY_TYPE    ("auto"),
  .FIFO_READ_LATENCY   (0),
  .FIFO_WRITE_DEPTH    (1024),
  .PROG_FULL_THRESH    (1024-5),
  .READ_DATA_WIDTH     (1),
  .READ_MODE           ("std"),
  .WRITE_DATA_WIDTH    (1)
) rdma_init_sys_awid_fifo (
  .wr_en         (axi_rdma_completion_or_init_sys_awready && axi_rdma_completion_or_init_sys_awvalid),
  .din           (axi_rdma_completion_or_init_sys_awid),
  .wr_ack        (),
  .rd_en         (axi_rdma_completion_or_init_sys_bvalid),//axi_rdma_completion_or_init_sys_wready && axi_rdma_completion_or_init_sys_wvalid && axi_rdma_completion_or_init_sys_wlast
  .data_valid    (),
  .dout          (axi_rdma_completion_or_init_sys_bid),

  .wr_data_count (),
  .rd_data_count (),

  .empty         (),
  .full          (),
  .almost_empty  (),
  .almost_full   (),
  .overflow      (),
  .underflow     (),
  .prog_empty    (),
  .prog_full     (),
  .sleep         (1'b0),

  .sbiterr       (),
  .dbiterr       (),
  .injectsbiterr (1'b0),
  .injectdbiterr (1'b0),

  .wr_clk        (axis_clk),
  .rst           (~axis_rstn),
  .rd_rst_busy   (),
  .wr_rst_busy   ()
);

xpm_fifo_sync #(
  .DOUT_RESET_VALUE    ("0"),
  .ECC_MODE            ("no_ecc"),
  .FIFO_MEMORY_TYPE    ("auto"),
  .FIFO_READ_LATENCY   (0),
  .FIFO_WRITE_DEPTH    (1024),
  .PROG_FULL_THRESH    (1024-5),
  .READ_DATA_WIDTH     (1),
  .READ_MODE           ("std"),
  .WRITE_DATA_WIDTH    (1)
) rdma_init_sys_arid_fifo (
  .wr_en         (axi_rdma_completion_or_init_sys_arready && axi_rdma_completion_or_init_sys_arvalid),
  .din           (axi_rdma_completion_or_init_sys_arid),
  .wr_ack        (),
  .rd_en         (axi_rdma_completion_or_init_sys_rready && axi_rdma_completion_or_init_sys_rvalid && axi_rdma_completion_or_init_sys_rlast),
  .data_valid    (),
  .dout          (axi_rdma_completion_or_init_sys_rid),

  .wr_data_count (),
  .rd_data_count (),

  .empty         (),
  .full          (),
  .almost_empty  (),
  .almost_full   (),
  .overflow      (),
  .underflow     (),
  .prog_empty    (),
  .prog_full     (),
  .sleep         (1'b0),

  .sbiterr       (),
  .dbiterr       (),
  .injectsbiterr (1'b0),
  .injectdbiterr (1'b0),

  .wr_clk        (axis_clk),
  .rst           (~axis_rstn),
  .rd_rst_busy   (),
  .wr_rst_busy   ()
);

assign m_axi_rdma1_get_payload_awqos = 4'd0;
assign m_axi_rdma1_get_payload_arqos = 4'd0;
assign m_axi_rdma2_get_payload_awqos = 4'd0;
assign m_axi_rdma2_get_payload_arqos = 4'd0;

// Memory subsytem
// -- used AXI-MM BRAM to replace device DDR at the moment
// -- 512KB for system memory
axi_mm_bram axi_dev_mem_inst (
  .s_axi_aclk      (axis_clk),
  .s_axi_aresetn   (axis_rstn),
  .s_axi_awid      (axi_dev_mem_awid),
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
  .s_axi_bid       (axi_dev_mem_bid),
  .s_axi_bresp     (axi_dev_mem_bresp),
  .s_axi_bvalid    (axi_dev_mem_bvalid),
  .s_axi_bready    (axi_dev_mem_bready),
  .s_axi_arid      (axi_dev_mem_arid),
  .s_axi_araddr    (axi_dev_mem_araddr[18:0]),
  .s_axi_arlen     (axi_dev_mem_arlen),
  .s_axi_arsize    (axi_dev_mem_arsize),
  .s_axi_arburst   (axi_dev_mem_arburst),
  .s_axi_arlock    (axi_dev_mem_arlock),
  .s_axi_arcache   (axi_dev_mem_arcache),
  .s_axi_arprot    (axi_dev_mem_arprot),
  .s_axi_arvalid   (axi_dev_mem_arvalid),
  .s_axi_arready   (axi_dev_mem_arready),
  .s_axi_rid       (axi_dev_mem_rid),
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
  .s_axi_awid      ({2'd0,axi_sys_mem_awid}),//{2'd0,axi_sys_mem_awid}
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
  .s_axi_bid       ({two_unused_bit0,axi_sys_mem_bid}),
  .s_axi_bresp     (axi_sys_mem_bresp),
  .s_axi_bvalid    (axi_sys_mem_bvalid),
  .s_axi_bready    (axi_sys_mem_bready),
  .s_axi_arid      ({2'd0,axi_sys_mem_arid}),
  .s_axi_araddr    (axi_sys_mem_araddr[19:0]),
  .s_axi_arlen     (axi_sys_mem_arlen),
  .s_axi_arsize    (axi_sys_mem_arsize),
  .s_axi_arburst   (axi_sys_mem_arburst),
  .s_axi_arlock    (axi_sys_mem_arlock),
  .s_axi_arcache   (axi_sys_mem_arcache),
  .s_axi_arprot    (axi_sys_mem_arprot),
  .s_axi_arvalid   (axi_sys_mem_arvalid),
  .s_axi_arready   (axi_sys_mem_arready),
  .s_axi_rid       ({two_unused_bit1,axi_sys_mem_rid}),
  .s_axi_rdata     (axi_sys_mem_rdata),
  .s_axi_rresp     (axi_sys_mem_rresp),
  .s_axi_rlast     (axi_sys_mem_rlast),
  .s_axi_rvalid    (axi_sys_mem_rvalid),
  .s_axi_rready    (axi_sys_mem_rready)
);

assign axi_rdma_rsp_payload_awqos = 4'd0;
assign axi_rdma_rsp_payload_arqos = 4'd0;
assign axi_qdma_mm_awqos  = 4'd0;
assign axi_qdma_mm_arqos  = 4'd0;

assign m_axi_veri_sys_arqos = 4'd0;
assign m_axi_veri_dev_arqos = 4'd0;

assign axi_rdma_get_wqe_awqos     = 4'd0;
assign axi_rdma_get_wqe_arqos     = 4'd0;
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

  .sys_axi_read_passed  (sys_axi_read_passed),
  .dev_axi_read_passed  (dev_axi_read_passed),

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

// For analysis
always_comb begin
  if (m_axis_cmac_tx_tvalid && m_axis_cmac_tx_tready) begin
    $display("INFO: [rn_tb_2rdma_top] packet_data=%x %x %x", m_axis_cmac_tx_tdata, m_axis_cmac_tx_tkeep, m_axis_cmac_tx_tlast);
  end
end

assign m_axi_rdma_rsp_payload_awready = 1'b0;
assign m_axi_rdma_rsp_payload_wready  = 1'b0;
assign m_axi_rdma_rsp_payload_bid     = 1'b0;
assign m_axi_rdma_rsp_payload_bresp   = 2'd0;
assign m_axi_rdma_rsp_payload_bvalid  = 1'b0;
assign m_axi_rdma_rsp_payload_arready = 1'b0;
assign m_axi_rdma_rsp_payload_rid     = 1'b0;
assign m_axi_rdma_rsp_payload_rdata   = 512'd0;
assign m_axi_rdma_rsp_payload_rresp   = 2'd0;
assign m_axi_rdma_rsp_payload_rlast   = 1'b0;
assign m_axi_rdma_rsp_payload_rvalid  = 1'b0;

assign m_axi_rdma_get_wqe_awready = 1'b0;
assign m_axi_rdma_get_wqe_wready  = 1'b0;
assign m_axi_rdma_get_wqe_bid     = 1'b0;
assign m_axi_rdma_get_wqe_bresp   = 2'd0;
assign m_axi_rdma_get_wqe_bvalid  = 1'b0;
assign m_axi_rdma_get_wqe_arready = 1'b0;
assign m_axi_rdma_get_wqe_rid     = 1'b0;
assign m_axi_rdma_get_wqe_rdata   = 512'd0;
assign m_axi_rdma_get_wqe_rresp   = 2'd0;
assign m_axi_rdma_get_wqe_rlast   = 1'b0;
assign m_axi_rdma_get_wqe_rvalid  = 1'b0;

assign m_axi_rdma_completion_awready = 1'b0;
assign m_axi_rdma_completion_wready  = 1'b0;
assign m_axi_rdma_completion_bid     = 1'b0;
assign m_axi_rdma_completion_bresp   = 2'd0;
assign m_axi_rdma_completion_bvalid  = 1'b0;
assign m_axi_rdma_completion_arready = 1'b0;
assign m_axi_rdma_completion_rid     = 1'b0;
assign m_axi_rdma_completion_rdata   = 512'd0;
assign m_axi_rdma_completion_rresp   = 2'd0;
assign m_axi_rdma_completion_rlast   = 1'b0;
assign m_axi_rdma_completion_rvalid  = 1'b0;

assign rp_rdma2user_ieth_immdt_axis_trdy = 1'b1;

assign resp_hndler_i_send_cq_db_rdy = 1'b1;
assign i_qp_sq_pidb_hndshk = 16'd0;
assign i_qp_sq_pidb_wr_addr_hndshk = 32'd0;
assign i_qp_sq_pidb_wr_valid_hndshk = 1'b0;

assign i_qp_rq_cidb_hndshk = 16'd0;
assign i_qp_rq_cidb_wr_addr_hndshk = 32'd0;
assign i_qp_rq_cidb_wr_valid_hndshk = 1'b0;

assign s_rx_pkt_hndler_o_rq_db_rdy = 1'b1;

rdma_subsystem_wrapper remote_peer_rdma_inst (
  // AXIL interface for RDMA control register
  .s_axil_awaddr    (axil_rdma2_awaddr),
  .s_axil_awvalid   (axil_rdma2_awvalid),
  .s_axil_awready   (axil_rdma2_awready),
  .s_axil_wdata     (axil_rdma2_wdata),
  .s_axil_wstrb     (4'hf),
  .s_axil_wvalid    (axil_rdma2_wvalid),
  .s_axil_wready    (axil_rdma2_wready),
  .s_axil_araddr    (axil_rdma2_araddr),
  .s_axil_arvalid   (axil_rdma2_arvalid),
  .s_axil_arready   (axil_rdma2_arready),
  .s_axil_rdata     (axil_rdma2_rdata),
  .s_axil_rvalid    (axil_rdma2_rvalid),
  .s_axil_rresp     (axil_rdma2_rresp),
  .s_axil_rready    (axil_rdma2_rready),
  .s_axil_bresp     (axil_rdma2_bresp),
  .s_axil_bvalid    (axil_rdma2_bvalid),
  .s_axil_bready    (axil_rdma2_bready),

  // Issue RDMA acknowledge packets back to the RDMA-1
  .m_rdma2cmac_axis_tdata  (rp_rdma2lp_rdma_axis_tdata),
  .m_rdma2cmac_axis_tkeep  (rp_rdma2lp_rdma_axis_tkeep),
  .m_rdma2cmac_axis_tvalid (rp_rdma2lp_rdma_axis_tvalid),
  .m_rdma2cmac_axis_tlast  (rp_rdma2lp_rdma_axis_tlast),
  .m_rdma2cmac_axis_tready (rp_rdma2lp_rdma_axis_tready),

  // Do not receive any non-roce packets
  .s_qdma2rdma_non_roce_axis_tdata    (512'd0),
  .s_qdma2rdma_non_roce_axis_tkeep    (64'd0),
  .s_qdma2rdma_non_roce_axis_tvalid   (1'b0),
  .s_qdma2rdma_non_roce_axis_tlast    (1'b0),
  .s_qdma2rdma_non_roce_axis_tready   (),

  // Receive RoCEv2 packets from the local RDMA peer
  .s_cmac2rdma_roce_axis_tdata        (m_axis_cmac_tx_tdata),
  .s_cmac2rdma_roce_axis_tkeep        (m_axis_cmac_tx_tkeep),
  .s_cmac2rdma_roce_axis_tvalid       (m_axis_cmac_tx_tvalid),
  .s_cmac2rdma_roce_axis_tlast        (m_axis_cmac_tx_tlast),
  .s_cmac2rdma_roce_axis_tuser        (m_axis_cmac_tx_tvalid && m_axis_cmac_tx_tlast),

  // No non-RDMA packets from CMAC RX bypassing RDMA from the remote RDMA peer
  .s_cmac2rdma_non_roce_axis_tdata    (512'd0),
  .s_cmac2rdma_non_roce_axis_tkeep    (64'd0),
  .s_cmac2rdma_non_roce_axis_tvalid   (1'b0),
  .s_cmac2rdma_non_roce_axis_tlast    (1'b0),
  .s_cmac2rdma_non_roce_axis_tuser    (1'b0),

  // No non-RDMA packets bypassing RDMA to QDMA RX from the remote RDMA peer
  .m_rdma2qdma_non_roce_axis_tdata    (),
  .m_rdma2qdma_non_roce_axis_tkeep    (),
  .m_rdma2qdma_non_roce_axis_tvalid   (),
  .m_rdma2qdma_non_roce_axis_tlast    (),
  .m_rdma2qdma_non_roce_axis_tready   (1'b1),

  // invalidate or immediate data from roce IETH/IMMDT header
  .m_rdma2user_ieth_immdt_axis_tdata  (rp_rdma2user_ieth_immdt_axis_tdata),
  .m_rdma2user_ieth_immdt_axis_tlast  (rp_rdma2user_ieth_immdt_axis_tlast),
  .m_rdma2user_ieth_immdt_axis_tvalid (rp_rdma2user_ieth_immdt_axis_tvalid),
  .m_rdma2user_ieth_immdt_axis_trdy   (rp_rdma2user_ieth_immdt_axis_trdy),

  // RDMA AXI MM interface used to store payload from RDMA MAD, Send or Write operation
  .m_axi_rdma_send_write_payload_store_awid    (axi_rdma2_send_write_payload_awid),
  .m_axi_rdma_send_write_payload_store_awaddr  (axi_rdma2_send_write_payload_awaddr),
  .m_axi_rdma_send_write_payload_store_awuser  (axi_rdma2_send_write_payload_awuser),
  .m_axi_rdma_send_write_payload_store_awlen   (axi_rdma2_send_write_payload_awlen),
  .m_axi_rdma_send_write_payload_store_awsize  (axi_rdma2_send_write_payload_awsize),
  .m_axi_rdma_send_write_payload_store_awburst (axi_rdma2_send_write_payload_awburst),
  .m_axi_rdma_send_write_payload_store_awcache (axi_rdma2_send_write_payload_awcache),
  .m_axi_rdma_send_write_payload_store_awprot  (axi_rdma2_send_write_payload_awprot),
  .m_axi_rdma_send_write_payload_store_awvalid (axi_rdma2_send_write_payload_awvalid),
  .m_axi_rdma_send_write_payload_store_awready (axi_rdma2_send_write_payload_awready),
  .m_axi_rdma_send_write_payload_store_wdata   (axi_rdma2_send_write_payload_wdata),
  .m_axi_rdma_send_write_payload_store_wstrb   (axi_rdma2_send_write_payload_wstrb),
  .m_axi_rdma_send_write_payload_store_wlast   (axi_rdma2_send_write_payload_wlast),
  .m_axi_rdma_send_write_payload_store_wvalid  (axi_rdma2_send_write_payload_wvalid),
  .m_axi_rdma_send_write_payload_store_wready  (axi_rdma2_send_write_payload_wready),
  .m_axi_rdma_send_write_payload_store_awlock  (axi_rdma2_send_write_payload_awlock),
  .m_axi_rdma_send_write_payload_store_bid     (axi_rdma2_send_write_payload_bid),
  .m_axi_rdma_send_write_payload_store_bresp   (axi_rdma2_send_write_payload_bresp),
  .m_axi_rdma_send_write_payload_store_bvalid  (axi_rdma2_send_write_payload_bvalid),
  .m_axi_rdma_send_write_payload_store_bready  (axi_rdma2_send_write_payload_bready),
  .m_axi_rdma_send_write_payload_store_arid    (axi_rdma2_send_write_payload_arid),
  .m_axi_rdma_send_write_payload_store_araddr  (axi_rdma2_send_write_payload_araddr),
  .m_axi_rdma_send_write_payload_store_arlen   (axi_rdma2_send_write_payload_arlen),
  .m_axi_rdma_send_write_payload_store_arsize  (axi_rdma2_send_write_payload_arsize),
  .m_axi_rdma_send_write_payload_store_arburst (axi_rdma2_send_write_payload_arburst),
  .m_axi_rdma_send_write_payload_store_arcache (axi_rdma2_send_write_payload_arcache),
  .m_axi_rdma_send_write_payload_store_arprot  (axi_rdma2_send_write_payload_arprot),
  .m_axi_rdma_send_write_payload_store_arvalid (axi_rdma2_send_write_payload_arvalid),
  .m_axi_rdma_send_write_payload_store_arready (axi_rdma2_send_write_payload_arready),
  .m_axi_rdma_send_write_payload_store_rid     (axi_rdma2_send_write_payload_rid),
  .m_axi_rdma_send_write_payload_store_rdata   (axi_rdma2_send_write_payload_rdata),
  .m_axi_rdma_send_write_payload_store_rresp   (axi_rdma2_send_write_payload_rresp),
  .m_axi_rdma_send_write_payload_store_rlast   (axi_rdma2_send_write_payload_rlast),
  .m_axi_rdma_send_write_payload_store_rvalid  (axi_rdma2_send_write_payload_rvalid),
  .m_axi_rdma_send_write_payload_store_rready  (axi_rdma2_send_write_payload_rready),
  .m_axi_rdma_send_write_payload_store_arlock  (axi_rdma2_send_write_payload_arlock),

  // RDMA AXI MM interface used to store payload from RDMA Read response operation
  .m_axi_rdma_rsp_payload_awid          (m_axi_rdma_rsp_payload_awid),
  .m_axi_rdma_rsp_payload_awaddr        (m_axi_rdma_rsp_payload_awaddr),
  .m_axi_rdma_rsp_payload_awlen         (m_axi_rdma_rsp_payload_awlen),
  .m_axi_rdma_rsp_payload_awsize        (m_axi_rdma_rsp_payload_awsize),
  .m_axi_rdma_rsp_payload_awburst       (m_axi_rdma_rsp_payload_awburst),
  .m_axi_rdma_rsp_payload_awcache       (m_axi_rdma_rsp_payload_awcache),
  .m_axi_rdma_rsp_payload_awprot        (m_axi_rdma_rsp_payload_awprot),
  .m_axi_rdma_rsp_payload_awvalid       (m_axi_rdma_rsp_payload_awvalid),
  .m_axi_rdma_rsp_payload_awready       (m_axi_rdma_rsp_payload_awready),
  .m_axi_rdma_rsp_payload_wdata         (m_axi_rdma_rsp_payload_wdata),
  .m_axi_rdma_rsp_payload_wstrb         (m_axi_rdma_rsp_payload_wstrb),
  .m_axi_rdma_rsp_payload_wlast         (m_axi_rdma_rsp_payload_wlast),
  .m_axi_rdma_rsp_payload_wvalid        (m_axi_rdma_rsp_payload_wvalid),
  .m_axi_rdma_rsp_payload_wready        (m_axi_rdma_rsp_payload_wready),
  .m_axi_rdma_rsp_payload_awlock        (m_axi_rdma_rsp_payload_awlock),
  .m_axi_rdma_rsp_payload_bid           (m_axi_rdma_rsp_payload_bid),
  .m_axi_rdma_rsp_payload_bresp         (m_axi_rdma_rsp_payload_bresp),
  .m_axi_rdma_rsp_payload_bvalid        (m_axi_rdma_rsp_payload_bvalid),
  .m_axi_rdma_rsp_payload_bready        (m_axi_rdma_rsp_payload_bready),
  .m_axi_rdma_rsp_payload_arid          (m_axi_rdma_rsp_payload_arid),
  .m_axi_rdma_rsp_payload_araddr        (m_axi_rdma_rsp_payload_araddr),
  .m_axi_rdma_rsp_payload_arlen         (m_axi_rdma_rsp_payload_arlen),
  .m_axi_rdma_rsp_payload_arsize        (m_axi_rdma_rsp_payload_arsize),
  .m_axi_rdma_rsp_payload_arburst       (m_axi_rdma_rsp_payload_arburst),
  .m_axi_rdma_rsp_payload_arcache       (m_axi_rdma_rsp_payload_arcache),
  .m_axi_rdma_rsp_payload_arprot        (m_axi_rdma_rsp_payload_arprot),
  .m_axi_rdma_rsp_payload_arvalid       (m_axi_rdma_rsp_payload_arvalid),
  .m_axi_rdma_rsp_payload_arready       (m_axi_rdma_rsp_payload_arready),
  .m_axi_rdma_rsp_payload_rid           (m_axi_rdma_rsp_payload_rid),
  .m_axi_rdma_rsp_payload_rdata         (m_axi_rdma_rsp_payload_rdata),
  .m_axi_rdma_rsp_payload_rresp         (m_axi_rdma_rsp_payload_rresp),
  .m_axi_rdma_rsp_payload_rlast         (m_axi_rdma_rsp_payload_rlast),
  .m_axi_rdma_rsp_payload_rvalid        (m_axi_rdma_rsp_payload_rvalid),
  .m_axi_rdma_rsp_payload_rready        (m_axi_rdma_rsp_payload_rready),
  .m_axi_rdma_rsp_payload_arlock        (m_axi_rdma_rsp_payload_arlock),

  // RDMA AXI MM interface used to fetch WQE entries in the senq queue from DDR by the QP manager
  .m_axi_qp_get_wqe_awid                (m_axi_rdma_get_wqe_awid),
  .m_axi_qp_get_wqe_awaddr              (m_axi_rdma_get_wqe_awaddr),
  .m_axi_qp_get_wqe_awlen               (m_axi_rdma_get_wqe_awlen),
  .m_axi_qp_get_wqe_awsize              (m_axi_rdma_get_wqe_awsize),
  .m_axi_qp_get_wqe_awburst             (m_axi_rdma_get_wqe_awburst),
  .m_axi_qp_get_wqe_awcache             (m_axi_rdma_get_wqe_awcache),
  .m_axi_qp_get_wqe_awprot              (m_axi_rdma_get_wqe_awprot),
  .m_axi_qp_get_wqe_awvalid             (m_axi_rdma_get_wqe_awvalid),
  .m_axi_qp_get_wqe_awready             (m_axi_rdma_get_wqe_awready),
  .m_axi_qp_get_wqe_wdata               (m_axi_rdma_get_wqe_wdata),
  .m_axi_qp_get_wqe_wstrb               (m_axi_rdma_get_wqe_wstrb),
  .m_axi_qp_get_wqe_wlast               (m_axi_rdma_get_wqe_wlast),
  .m_axi_qp_get_wqe_wvalid              (m_axi_rdma_get_wqe_wvalid),
  .m_axi_qp_get_wqe_wready              (m_axi_rdma_get_wqe_wready),
  .m_axi_qp_get_wqe_awlock              (m_axi_rdma_get_wqe_awlock),
  .m_axi_qp_get_wqe_bid                 (m_axi_rdma_get_wqe_bid),
  .m_axi_qp_get_wqe_bresp               (m_axi_rdma_get_wqe_bresp),
  .m_axi_qp_get_wqe_bvalid              (m_axi_rdma_get_wqe_bvalid),
  .m_axi_qp_get_wqe_bready              (m_axi_rdma_get_wqe_bready),
  .m_axi_qp_get_wqe_arid                (m_axi_rdma_get_wqe_arid),
  .m_axi_qp_get_wqe_araddr              (m_axi_rdma_get_wqe_araddr),
  .m_axi_qp_get_wqe_arlen               (m_axi_rdma_get_wqe_arlen),
  .m_axi_qp_get_wqe_arsize              (m_axi_rdma_get_wqe_arsize),
  .m_axi_qp_get_wqe_arburst             (m_axi_rdma_get_wqe_arburst),
  .m_axi_qp_get_wqe_arcache             (m_axi_rdma_get_wqe_arcache),
  .m_axi_qp_get_wqe_arprot              (m_axi_rdma_get_wqe_arprot),
  .m_axi_qp_get_wqe_arvalid             (m_axi_rdma_get_wqe_arvalid),
  .m_axi_qp_get_wqe_arready             (m_axi_rdma_get_wqe_arready),
  .m_axi_qp_get_wqe_rid                 (m_axi_rdma_get_wqe_rid),
  .m_axi_qp_get_wqe_rdata               (m_axi_rdma_get_wqe_rdata),
  .m_axi_qp_get_wqe_rresp               (m_axi_rdma_get_wqe_rresp),
  .m_axi_qp_get_wqe_rlast               (m_axi_rdma_get_wqe_rlast),
  .m_axi_qp_get_wqe_rvalid              (m_axi_rdma_get_wqe_rvalid),
  .m_axi_qp_get_wqe_rready              (m_axi_rdma_get_wqe_rready),
  .m_axi_qp_get_wqe_arlock              (m_axi_rdma_get_wqe_arlock),

  // TODO: In the current implementation, we do not consider retry buffer
  // RDMA AXI MM interface used to store payload of an outgoing RDMA write packet to a retry buffer
  .m_axi_payload_to_retry_buf_awid     (),
  .m_axi_payload_to_retry_buf_awaddr   (),
  .m_axi_payload_to_retry_buf_awlen    (),
  .m_axi_payload_to_retry_buf_awsize   (),
  .m_axi_payload_to_retry_buf_awburst  (),
  .m_axi_payload_to_retry_buf_awcache  (),
  .m_axi_payload_to_retry_buf_awprot   (),
  .m_axi_payload_to_retry_buf_awvalid  (),
  .m_axi_payload_to_retry_buf_awready  (1'b1),
  .m_axi_payload_to_retry_buf_wdata    (),
  .m_axi_payload_to_retry_buf_wstrb    (),
  .m_axi_payload_to_retry_buf_wlast    (),
  .m_axi_payload_to_retry_buf_wvalid   (),
  .m_axi_payload_to_retry_buf_wready   (1'b1),
  .m_axi_payload_to_retry_buf_awlock   (),
  .m_axi_payload_to_retry_buf_bid      (1'b0),
  .m_axi_payload_to_retry_buf_bresp    (2'd0),
  .m_axi_payload_to_retry_buf_bvalid   (1'b0),
  .m_axi_payload_to_retry_buf_bready   (),
  .m_axi_payload_to_retry_buf_arid     (),
  .m_axi_payload_to_retry_buf_araddr   (),
  .m_axi_payload_to_retry_buf_arlen    (),
  .m_axi_payload_to_retry_buf_arsize   (),
  .m_axi_payload_to_retry_buf_arburst  (),
  .m_axi_payload_to_retry_buf_arcache  (),
  .m_axi_payload_to_retry_buf_arprot   (),
  .m_axi_payload_to_retry_buf_arvalid  (),
  .m_axi_payload_to_retry_buf_arready  (1'b1),
  .m_axi_payload_to_retry_buf_rid      (1'b0),
  .m_axi_payload_to_retry_buf_rdata    (512'd0),
  .m_axi_payload_to_retry_buf_rresp    (2'd0),
  .m_axi_payload_to_retry_buf_rlast    (1'b0),
  .m_axi_payload_to_retry_buf_rvalid   (1'b0),
  .m_axi_payload_to_retry_buf_rready   (),
  .m_axi_payload_to_retry_buf_arlock   (),

  // RDMA AXI MM interface used to get payload of an outgoing RDMA send/write and read response packets
  .m_axi_pktgen_get_payload_awid       (m_axi_rdma2_get_payload_awid),
  .m_axi_pktgen_get_payload_awaddr     (m_axi_rdma2_get_payload_awaddr),
  .m_axi_pktgen_get_payload_awlen      (m_axi_rdma2_get_payload_awlen),
  .m_axi_pktgen_get_payload_awsize     (m_axi_rdma2_get_payload_awsize),
  .m_axi_pktgen_get_payload_awburst    (m_axi_rdma2_get_payload_awburst),
  .m_axi_pktgen_get_payload_awcache    (m_axi_rdma2_get_payload_awcache),
  .m_axi_pktgen_get_payload_awprot     (m_axi_rdma2_get_payload_awprot),
  .m_axi_pktgen_get_payload_awvalid    (m_axi_rdma2_get_payload_awvalid),
  .m_axi_pktgen_get_payload_awready    (m_axi_rdma2_get_payload_awready),
  .m_axi_pktgen_get_payload_wdata      (m_axi_rdma2_get_payload_wdata),
  .m_axi_pktgen_get_payload_wstrb      (m_axi_rdma2_get_payload_wstrb),
  .m_axi_pktgen_get_payload_wlast      (m_axi_rdma2_get_payload_wlast),
  .m_axi_pktgen_get_payload_wvalid     (m_axi_rdma2_get_payload_wvalid),
  .m_axi_pktgen_get_payload_wready     (m_axi_rdma2_get_payload_wready),
  .m_axi_pktgen_get_payload_awlock     (m_axi_rdma2_get_payload_awlock),
  .m_axi_pktgen_get_payload_bid        (m_axi_rdma2_get_payload_bid),
  .m_axi_pktgen_get_payload_bresp      (m_axi_rdma2_get_payload_bresp),
  .m_axi_pktgen_get_payload_bvalid     (m_axi_rdma2_get_payload_bvalid),
  .m_axi_pktgen_get_payload_bready     (m_axi_rdma2_get_payload_bready),
  .m_axi_pktgen_get_payload_arid       (m_axi_rdma2_get_payload_arid),
  .m_axi_pktgen_get_payload_araddr     (m_axi_rdma2_get_payload_araddr),
  .m_axi_pktgen_get_payload_arlen      (m_axi_rdma2_get_payload_arlen),
  .m_axi_pktgen_get_payload_arsize     (m_axi_rdma2_get_payload_arsize),
  .m_axi_pktgen_get_payload_arburst    (m_axi_rdma2_get_payload_arburst),
  .m_axi_pktgen_get_payload_arcache    (m_axi_rdma2_get_payload_arcache),
  .m_axi_pktgen_get_payload_arprot     (m_axi_rdma2_get_payload_arprot),
  .m_axi_pktgen_get_payload_arvalid    (m_axi_rdma2_get_payload_arvalid),
  .m_axi_pktgen_get_payload_arready    (m_axi_rdma2_get_payload_arready),
  .m_axi_pktgen_get_payload_rid        (m_axi_rdma2_get_payload_rid),
  .m_axi_pktgen_get_payload_rdata      (m_axi_rdma2_get_payload_rdata),
  .m_axi_pktgen_get_payload_rresp      (m_axi_rdma2_get_payload_rresp),
  .m_axi_pktgen_get_payload_rlast      (m_axi_rdma2_get_payload_rlast),
  .m_axi_pktgen_get_payload_rvalid     (m_axi_rdma2_get_payload_rvalid),
  .m_axi_pktgen_get_payload_rready     (m_axi_rdma2_get_payload_rready),
  .m_axi_pktgen_get_payload_arlock     (m_axi_rdma2_get_payload_arlock),

  // RDMA AXI MM interface used to write completion entries to a completion queue in the DDR
  .m_axi_write_completion_awid         (m_axi_rdma_completion_awid),
  .m_axi_write_completion_awaddr       (m_axi_rdma_completion_awaddr),
  .m_axi_write_completion_awlen        (m_axi_rdma_completion_awlen),
  .m_axi_write_completion_awsize       (m_axi_rdma_completion_awsize),
  .m_axi_write_completion_awburst      (m_axi_rdma_completion_awburst),
  .m_axi_write_completion_awcache      (m_axi_rdma_completion_awcache),
  .m_axi_write_completion_awprot       (m_axi_rdma_completion_awprot),
  .m_axi_write_completion_awvalid      (m_axi_rdma_completion_awvalid),
  .m_axi_write_completion_awready      (m_axi_rdma_completion_awready),
  .m_axi_write_completion_wdata        (m_axi_rdma_completion_wdata),
  .m_axi_write_completion_wstrb        (m_axi_rdma_completion_wstrb),
  .m_axi_write_completion_wlast        (m_axi_rdma_completion_wlast),
  .m_axi_write_completion_wvalid       (m_axi_rdma_completion_wvalid),
  .m_axi_write_completion_wready       (m_axi_rdma_completion_wready),
  .m_axi_write_completion_awlock       (m_axi_rdma_completion_awlock),
  .m_axi_write_completion_bid          (m_axi_rdma_completion_bid),
  .m_axi_write_completion_bresp        (m_axi_rdma_completion_bresp),
  .m_axi_write_completion_bvalid       (m_axi_rdma_completion_bvalid),
  .m_axi_write_completion_bready       (m_axi_rdma_completion_bready),
  .m_axi_write_completion_arid         (m_axi_rdma_completion_arid),
  .m_axi_write_completion_araddr       (m_axi_rdma_completion_araddr),
  .m_axi_write_completion_arlen        (m_axi_rdma_completion_arlen),
  .m_axi_write_completion_arsize       (m_axi_rdma_completion_arsize),
  .m_axi_write_completion_arburst      (m_axi_rdma_completion_arburst),
  .m_axi_write_completion_arcache      (m_axi_rdma_completion_arcache),
  .m_axi_write_completion_arprot       (m_axi_rdma_completion_arprot),
  .m_axi_write_completion_arvalid      (m_axi_rdma_completion_arvalid),
  .m_axi_write_completion_arready      (m_axi_rdma_completion_arready),
  .m_axi_write_completion_rid          (m_axi_rdma_completion_rid),
  .m_axi_write_completion_rdata        (m_axi_rdma_completion_rdata),
  .m_axi_write_completion_rresp        (m_axi_rdma_completion_rresp),
  .m_axi_write_completion_rlast        (m_axi_rdma_completion_rlast),
  .m_axi_write_completion_rvalid       (m_axi_rdma_completion_rvalid),
  .m_axi_write_completion_rready       (m_axi_rdma_completion_rready),
  .m_axi_write_completion_arlock       (m_axi_rdma_completion_arlock),

  // TODO: In the current implementation, we do not consider hardware handshaking from user logic
  // HW handshaking from user logic: Send WQE completion queue doorbell
  .resp_hndler_o_send_cq_db_cnt_valid(resp_hndler_o_send_cq_db_cnt_valid),
  .resp_hndler_o_send_cq_db_addr     (resp_hndler_o_send_cq_db_addr),
  .resp_hndler_o_send_cq_db_cnt      (resp_hndler_o_send_cq_db_cnt),
  .resp_hndler_i_send_cq_db_rdy      (resp_hndler_i_send_cq_db_rdy),

  // HW handshaking from user logic: Send WQE producer index doorbell
  .i_qp_sq_pidb_hndshk               (i_qp_sq_pidb_hndshk),
  .i_qp_sq_pidb_wr_addr_hndshk       (i_qp_sq_pidb_wr_addr_hndshk),
  .i_qp_sq_pidb_wr_valid_hndshk      (i_qp_sq_pidb_wr_valid_hndshk),
  .o_qp_sq_pidb_wr_rdy               (o_qp_sq_pidb_wr_rdy),

  // HW handshaking from user logic: RDMA-Send consumer index doorbell
  .i_qp_rq_cidb_hndshk               (i_qp_rq_cidb_hndshk),
  .i_qp_rq_cidb_wr_addr_hndshk       (i_qp_rq_cidb_wr_addr_hndshk),
  .i_qp_rq_cidb_wr_valid_hndshk      (i_qp_rq_cidb_wr_valid_hndshk),
  .o_qp_rq_cidb_wr_rdy               (o_qp_rq_cidb_wr_rdy),

  // HW handshaking from user logic: RDMA-Send producer index doorbell
  .rx_pkt_hndler_o_rq_db_data        (rx_pkt_hndler_o_rq_db_data),
  .rx_pkt_hndler_o_rq_db_addr        (rx_pkt_hndler_o_rq_db_addr),
  .rx_pkt_hndler_o_rq_db_data_valid  (rx_pkt_hndler_o_rq_db_data_valid),
  .rx_pkt_hndler_i_rq_db_rdy         (rx_pkt_hndler_i_rq_db_rdy),

  .rnic_intr    (rdma2_intr),

  .mod_rstn     (axil_rstn),
  .mod_rst_done (rdma2_rst_done),
  //.rdma_resetn_done (rdma_resetn_done),
  .axil_clk     (axil_clk),
  .axis_clk     (axis_clk)
);

//assign start_rdma1_stat = finish_init_hw_hndshk;
/*
axil_reg_control config_init_hw_hndshk (
  .rdma_cfg_filename ("init_hw_hndshk_cmd"),
  .start_config_rdma (start_init_hw_hndshk),
  .finish_config_rdma(finish_init_hw_hndshk),
  .m_axil_reg_awvalid(s_axil_hw_hndshk_cmd_awvalid),
  .m_axil_reg_awaddr (s_axil_hw_hndshk_cmd_awaddr),
  .m_axil_reg_awready(s_axil_hw_hndshk_cmd_awready),
  .m_axil_reg_wvalid (s_axil_hw_hndshk_cmd_wvalid),
  .m_axil_reg_wdata  (s_axil_hw_hndshk_cmd_wdata),
  .m_axil_reg_wready (s_axil_hw_hndshk_cmd_wready),
  .m_axil_reg_bvalid (s_axil_hw_hndshk_cmd_bvalid),
  .m_axil_reg_bresp  (s_axil_hw_hndshk_cmd_bresp),
  .m_axil_reg_bready (s_axil_hw_hndshk_cmd_bready),
  .m_axil_reg_arvalid(s_axil_hw_hndshk_cmd_arvalid),
  .m_axil_reg_araddr (s_axil_hw_hndshk_cmd_araddr),
  .m_axil_reg_arready(s_axil_hw_hndshk_cmd_arready),
  .m_axil_reg_rvalid (s_axil_hw_hndshk_cmd_rvalid),
  .m_axil_reg_rdata  (s_axil_hw_hndshk_cmd_rdata),
  .m_axil_reg_rresp  (s_axil_hw_hndshk_cmd_rresp),
  .m_axil_reg_rready (s_axil_hw_hndshk_cmd_rready),
  .axil_clk          (axil_clk),
  .axil_rstn         (axil_rstn)
);*/

// Configure the remote RDMA
axil_reg_control config_reg_config_rdma2 (
  .which_rdma        ("rdma2"),
  .rdma_cfg_filename (rdma2_combined_cfg_filename),
  .rdma_recv_cfg_filename(""),
  .rdma_stat_filename(""),
  .start_config_rdma (start_config_rdma2),
  .finish_config_rdma(finish_config_rdma2),
  .start_checking_recv(1'b0),
  .start_rdma_stat   (1'b0),
  .finish_rdma_stat  (),
  .m_axil_reg_awvalid(s_axil_rdma2_reg_awvalid),
  .m_axil_reg_awaddr (s_axil_rdma2_reg_awaddr),
  .m_axil_reg_awready(s_axil_rdma2_reg_awready),
  .m_axil_reg_wvalid (s_axil_rdma2_reg_wvalid),
  .m_axil_reg_wdata  (s_axil_rdma2_reg_wdata),
  .m_axil_reg_wready (s_axil_rdma2_reg_wready),
  .m_axil_reg_bvalid (s_axil_rdma2_reg_bvalid),
  .m_axil_reg_bresp  (s_axil_rdma2_reg_bresp),
  .m_axil_reg_bready (s_axil_rdma2_reg_bready),
  .m_axil_reg_arvalid(s_axil_rdma2_reg_arvalid),
  .m_axil_reg_araddr (s_axil_rdma2_reg_araddr),
  .m_axil_reg_arready(s_axil_rdma2_reg_arready),
  .m_axil_reg_rvalid (s_axil_rdma2_reg_rvalid),
  .m_axil_reg_rdata  (s_axil_rdma2_reg_rdata),
  .m_axil_reg_rresp  (s_axil_rdma2_reg_rresp),
  .m_axil_reg_rready (s_axil_rdma2_reg_rready),
  .axil_clk          (axil_clk),
  .axil_rstn         (axil_rstn)
);

assign start_config_rdma2 = init_sys_mem_done && init_dev_mem_done;
//assign start_init_hw_hndshk = finish_config_rdma2;
assign start_init_hw_hndshk = trg_hw_hndshk;

// Polling for receive operations
axil_reg_control read_rdma2_recv_reg (
  .which_rdma        ("rdma2"),
  .rdma_cfg_filename (""),
  .rdma_recv_cfg_filename(rdma2_recv_cfg_filename),
  .rdma_stat_filename(""),
  .start_config_rdma (1'b0),
  .finish_config_rdma(),
  .start_checking_recv(start_checking_recv_rdma2),
  .start_rdma_stat   (1'b0),
  .finish_rdma_stat  (),
  .m_axil_reg_awvalid(s_axil_rdma2_recv_awvalid),
  .m_axil_reg_awaddr (s_axil_rdma2_recv_awaddr),
  .m_axil_reg_awready(s_axil_rdma2_recv_awready),
  .m_axil_reg_wvalid (s_axil_rdma2_recv_wvalid),
  .m_axil_reg_wdata  (s_axil_rdma2_recv_wdata),
  .m_axil_reg_wready (s_axil_rdma2_recv_wready),
  .m_axil_reg_bvalid (s_axil_rdma2_recv_bvalid),
  .m_axil_reg_bresp  (s_axil_rdma2_recv_bresp),
  .m_axil_reg_bready (s_axil_rdma2_recv_bready),
  .m_axil_reg_arvalid(s_axil_rdma2_recv_arvalid),
  .m_axil_reg_araddr (s_axil_rdma2_recv_araddr),
  .m_axil_reg_arready(s_axil_rdma2_recv_arready),
  .m_axil_reg_rvalid (s_axil_rdma2_recv_rvalid),
  .m_axil_reg_rdata  (s_axil_rdma2_recv_rdata),
  .m_axil_reg_rresp  (s_axil_rdma2_recv_rresp),
  .m_axil_reg_rready (s_axil_rdma2_recv_rready),
  .axil_clk          (axil_clk),
  .axil_rstn         (axil_rstn)
);
/*
always_ff @(posedge axil_clk)
begin
  if(!axil_rstn) begin
    s_axil_hw_hndshk_trg_wvalid <= 0;
    s_axil_hw_hndshk_trg_wdata <= 32'd0;
    trg_rdma_ops_flag <= 0;
  end
  else if (trg_hw_hndshk && !trg_rdma_ops_flag)
  begin
    s_axil_hw_hndshk_trg_wvalid <= 1;
    s_axil_hw_hndshk_trg_wdata <= 32'h00020001;
    trg_rdma_ops_flag <= 1;
    //start_init_hw_hndshk <= 1;
  end
  else
  begin
    s_axil_hw_hndshk_trg_wvalid <= 0;
    s_axil_hw_hndshk_trg_wdata <= 32'h00000000;
  end
end*/

always_ff @(posedge axis_clk)
begin
  if(!axis_rstn) begin
    checking_recv_rdma2 <= 1'b0;
  end
  else begin
    if (m_axis_cmac_tx_tvalid && m_axis_cmac_tx_tready) begin
      // Detect whether it's a send operation
      if ((bth_opcode==8'h00) || (bth_opcode==8'h01) || (bth_opcode==8'h02) || (bth_opcode==8'h03) || (bth_opcode==8'h04) || (bth_opcode==8'h05)) begin
        checking_recv_rdma2 <= 1'b1;
      end
    end
  end
end

always_ff @(posedge axil_clk)
begin
  if(!axil_rstn) begin
    start_checking_recv_rdma2_cdc <= 2'd0;
  end
  else begin
    start_checking_recv_rdma2_cdc <= {start_checking_recv_rdma2_cdc[0], checking_recv_rdma2};
  end
end

assign start_checking_recv_rdma2 = start_checking_recv_rdma2_cdc[1];

// Configure the remote RDMA
axil_reg_control read_rdma2_stat_reg (
  .which_rdma        ("rdma2"),
  .rdma_cfg_filename (""),
  .rdma_recv_cfg_filename(""),
  .rdma_stat_filename(rdma2_stat_reg_cfg_filename),
  .start_config_rdma (1'b0),
  .finish_config_rdma(),
  .start_checking_recv(1'b0),
  .start_rdma_stat   (start_rdma2_stat),
  .finish_rdma_stat  (finish_rdma2_stat),
  .m_axil_reg_awvalid(s_axil_rdma2_stat_awvalid),
  .m_axil_reg_awaddr (s_axil_rdma2_stat_awaddr),
  .m_axil_reg_awready(s_axil_rdma2_stat_awready),
  .m_axil_reg_wvalid (s_axil_rdma2_stat_wvalid),
  .m_axil_reg_wdata  (s_axil_rdma2_stat_wdata),
  .m_axil_reg_wready (s_axil_rdma2_stat_wready),
  .m_axil_reg_bvalid (s_axil_rdma2_stat_bvalid),
  .m_axil_reg_bresp  (s_axil_rdma2_stat_bresp),
  .m_axil_reg_bready (s_axil_rdma2_stat_bready),
  .m_axil_reg_arvalid(s_axil_rdma2_stat_arvalid),
  .m_axil_reg_araddr (s_axil_rdma2_stat_araddr),
  .m_axil_reg_arready(s_axil_rdma2_stat_arready),
  .m_axil_reg_rvalid (s_axil_rdma2_stat_rvalid),
  .m_axil_reg_rdata  (s_axil_rdma2_stat_rdata),
  .m_axil_reg_rresp  (s_axil_rdma2_stat_rresp),
  .m_axil_reg_rready (s_axil_rdma2_stat_rready),
  .axil_clk          (axil_clk),
  .axil_rstn         (axil_rstn)
);

axil_3to1_crossbar_wrapper axil_3to1_wrapper (
  // RDMA2 register interface for configuration
  .s_axil_reg_awvalid  (s_axil_rdma2_reg_awvalid),
  .s_axil_reg_awaddr   (s_axil_rdma2_reg_awaddr ),
  .s_axil_reg_awready  (s_axil_rdma2_reg_awready),
  .s_axil_reg_wvalid   (s_axil_rdma2_reg_wvalid ),
  .s_axil_reg_wdata    (s_axil_rdma2_reg_wdata  ),
  .s_axil_reg_wready   (s_axil_rdma2_reg_wready ),
  .s_axil_reg_bvalid   (s_axil_rdma2_reg_bvalid ),
  .s_axil_reg_bresp    (s_axil_rdma2_reg_bresp  ),
  .s_axil_reg_bready   (s_axil_rdma2_reg_bready ),
  .s_axil_reg_arvalid  (s_axil_rdma2_reg_arvalid),
  .s_axil_reg_araddr   (s_axil_rdma2_reg_araddr ),
  .s_axil_reg_arready  (s_axil_rdma2_reg_arready),
  .s_axil_reg_rvalid   (s_axil_rdma2_reg_rvalid ),
  .s_axil_reg_rdata    (s_axil_rdma2_reg_rdata  ),
  .s_axil_reg_rresp    (s_axil_rdma2_reg_rresp  ),
  .s_axil_reg_rready   (s_axil_rdma2_reg_rready ),

  // RDMA2 stat register interface for debug purpose
  .s_axil_stat_awvalid  (s_axil_rdma2_stat_awvalid),
  .s_axil_stat_awaddr   (s_axil_rdma2_stat_awaddr ),
  .s_axil_stat_awready  (s_axil_rdma2_stat_awready),
  .s_axil_stat_wvalid   (s_axil_rdma2_stat_wvalid ),
  .s_axil_stat_wdata    (s_axil_rdma2_stat_wdata  ),
  .s_axil_stat_wready   (s_axil_rdma2_stat_wready ),
  .s_axil_stat_bvalid   (s_axil_rdma2_stat_bvalid ),
  .s_axil_stat_bresp    (s_axil_rdma2_stat_bresp  ),
  .s_axil_stat_bready   (s_axil_rdma2_stat_bready ),
  .s_axil_stat_arvalid  (s_axil_rdma2_stat_arvalid),
  .s_axil_stat_araddr   (s_axil_rdma2_stat_araddr ),
  .s_axil_stat_arready  (s_axil_rdma2_stat_arready),
  .s_axil_stat_rvalid   (s_axil_rdma2_stat_rvalid ),
  .s_axil_stat_rdata    (s_axil_rdma2_stat_rdata  ),
  .s_axil_stat_rresp    (s_axil_rdma2_stat_rresp  ),
  .s_axil_stat_rready   (s_axil_rdma2_stat_rready ),

  // RDMA2 polling interface for receive operations
  .s_axil_recv_awvalid  (s_axil_rdma2_recv_awvalid),
  .s_axil_recv_awaddr   (s_axil_rdma2_recv_awaddr ),
  .s_axil_recv_awready  (s_axil_rdma2_recv_awready),
  .s_axil_recv_wvalid   (s_axil_rdma2_recv_wvalid ),
  .s_axil_recv_wdata    (s_axil_rdma2_recv_wdata  ),
  .s_axil_recv_wready   (s_axil_rdma2_recv_wready ),
  .s_axil_recv_bvalid   (s_axil_rdma2_recv_bvalid ),
  .s_axil_recv_bresp    (s_axil_rdma2_recv_bresp  ),
  .s_axil_recv_bready   (s_axil_rdma2_recv_bready ),
  .s_axil_recv_arvalid  (s_axil_rdma2_recv_arvalid),
  .s_axil_recv_araddr   (s_axil_rdma2_recv_araddr ),
  .s_axil_recv_arready  (s_axil_rdma2_recv_arready),
  .s_axil_recv_rvalid   (s_axil_rdma2_recv_rvalid ),
  .s_axil_recv_rdata    (s_axil_rdma2_recv_rdata  ),
  .s_axil_recv_rresp    (s_axil_rdma2_recv_rresp  ),
  .s_axil_recv_rready   (s_axil_rdma2_recv_rready ),

  .m_axil_awvalid  (axil_rdma2_awvalid),
  .m_axil_awaddr   (axil_rdma2_awaddr ),
  .m_axil_awready  (axil_rdma2_awready),
  .m_axil_wvalid   (axil_rdma2_wvalid ),
  .m_axil_wdata    (axil_rdma2_wdata  ),
  .m_axil_wready   (axil_rdma2_wready ),
  .m_axil_bvalid   (axil_rdma2_bvalid ),
  .m_axil_bresp    (axil_rdma2_bresp  ),
  .m_axil_bready   (axil_rdma2_bready ),
  .m_axil_arvalid  (axil_rdma2_arvalid),
  .m_axil_araddr   (axil_rdma2_araddr ),
  .m_axil_arready  (axil_rdma2_arready),
  .m_axil_rvalid   (axil_rdma2_rvalid ),
  .m_axil_rdata    (axil_rdma2_rdata  ),
  .m_axil_rresp    (axil_rdma2_rresp  ),
  .m_axil_rready   (axil_rdma2_rready ),  

  .axil_clk (axil_clk),
  .axil_rstn(axil_rstn)
);

always_ff @(posedge axis_clk)
begin
  if(!axis_rstn) begin
    m_axis_cmac_tx_tdata_delay  <= 512'd0;
    m_axis_cmac_tx_tkeep_delay  <= 64'd0;
    m_axis_cmac_tx_tvalid_delay <= 1'b0;
    m_axis_cmac_tx_tlast_delay  <= 1'b0;
  end
  else begin
    m_axis_cmac_tx_tdata_delay  <= m_axis_cmac_tx_tdata;
    m_axis_cmac_tx_tkeep_delay  <= m_axis_cmac_tx_tkeep;
    m_axis_cmac_tx_tvalid_delay <= m_axis_cmac_tx_tvalid;
    m_axis_cmac_tx_tlast_delay  <= m_axis_cmac_tx_tlast;
  end
end

assign mac_dst = m_axis_cmac_tx_tvalid ? {m_axis_cmac_tx_tdata[7:0], m_axis_cmac_tx_tdata[15:8], m_axis_cmac_tx_tdata[23:16], m_axis_cmac_tx_tdata[31:24], m_axis_cmac_tx_tdata[39:32], m_axis_cmac_tx_tdata[47:40]} : 48'd0;
assign mac_src = m_axis_cmac_tx_tvalid ? {m_axis_cmac_tx_tdata[55:48], m_axis_cmac_tx_tdata[63:56], m_axis_cmac_tx_tdata[71:64], m_axis_cmac_tx_tdata[79:72], m_axis_cmac_tx_tdata[87:80], m_axis_cmac_tx_tdata[95:88]} : 48'd0;
assign ip_ihl = m_axis_cmac_tx_tvalid ? m_axis_cmac_tx_tdata[28*4+: 4] : 4'd0;
assign ip_total_length = m_axis_cmac_tx_tvalid ? {m_axis_cmac_tx_tdata[16*8+: 8], m_axis_cmac_tx_tdata[17*8+: 8]} : 16'd0;
assign ip_src = m_axis_cmac_tx_tvalid ? {m_axis_cmac_tx_tdata[26*8+: 8], m_axis_cmac_tx_tdata[27*8+: 8], m_axis_cmac_tx_tdata[28*8+: 8], m_axis_cmac_tx_tdata[29*8+: 8]} : 32'd0;
assign ip_dst = m_axis_cmac_tx_tvalid ? {m_axis_cmac_tx_tdata[30*8+: 8], m_axis_cmac_tx_tdata[31*8+: 8], m_axis_cmac_tx_tdata[32*8+: 8], m_axis_cmac_tx_tdata[33*8+: 8]} : 32'd0;
assign udp_sport = m_axis_cmac_tx_tvalid ? {m_axis_cmac_tx_tdata[34*8+: 8], m_axis_cmac_tx_tdata[35*8+: 16]} : 16'd0;
assign udp_dport = m_axis_cmac_tx_tvalid ? {m_axis_cmac_tx_tdata[36*8+: 8], m_axis_cmac_tx_tdata[37*8+: 8]} : 16'd0;
assign udp_length = m_axis_cmac_tx_tvalid ? {m_axis_cmac_tx_tdata[38*8+: 8], m_axis_cmac_tx_tdata[39*8+: 8]} : 16'd0;
assign bth_opcode = m_axis_cmac_tx_tvalid ? m_axis_cmac_tx_tdata[42*8+: 8] : 8'd0;
assign bth_partition_key = m_axis_cmac_tx_tvalid ? {m_axis_cmac_tx_tdata[44*8+: 8], m_axis_cmac_tx_tdata[45*8+: 8]} : 16'd0;
assign bth_dst_qp = m_axis_cmac_tx_tvalid ? {m_axis_cmac_tx_tdata[47*8+: 8], m_axis_cmac_tx_tdata[48*8+: 8], m_axis_cmac_tx_tdata[49*8+: 8]} : 24'd0;
assign bth_psn = m_axis_cmac_tx_tvalid ? {m_axis_cmac_tx_tdata[51*8+: 8], m_axis_cmac_tx_tdata[52*8+: 8], m_axis_cmac_tx_tdata[53*8+: 8]} : 24'd0;
assign reth_vir_addr_msb = m_axis_cmac_tx_tvalid ? {m_axis_cmac_tx_tdata[54*8+: 8], m_axis_cmac_tx_tdata[55*8+: 8], m_axis_cmac_tx_tdata[56*8+: 8], m_axis_cmac_tx_tdata[57*8+: 8]} : 32'd0;
assign reth_vir_addr_lsb = m_axis_cmac_tx_tvalid ? {m_axis_cmac_tx_tdata[58*8+: 8], m_axis_cmac_tx_tdata[59*8+: 8], m_axis_cmac_tx_tdata[60*8+: 8], m_axis_cmac_tx_tdata[61*8+: 8]} : 32'd0;;
assign reth_rkey = m_axis_cmac_tx_tvalid ? {m_axis_cmac_tx_tdata_delay[62*8+: 8], m_axis_cmac_tx_tdata_delay[63*8+: 8], m_axis_cmac_tx_tdata[0*8+: 8], m_axis_cmac_tx_tdata[1*8+: 8]} : 32'd0;
assign reth_length = m_axis_cmac_tx_tvalid ? {m_axis_cmac_tx_tdata[2*8+: 8], m_axis_cmac_tx_tdata[3*8+: 8], m_axis_cmac_tx_tdata[4*8+: 8], m_axis_cmac_tx_tdata[5*8+: 8]} : 32'd0;

logic [31:0] delay_cnt1;
logic        start_counting1;
logic        start_stat1;
logic [1:0]  start_stat1_cdc;

logic [31:0] delay_cnt2;
logic        start_counting2;
logic        start_stat2;
logic [1:0]  start_stat2_cdc;
localparam WAIT_CYCLE = 32'd5000;

always_ff @(posedge axis_clk)
begin
  if(!axis_rstn) begin
    delay_cnt1 <= 32'd0;
    start_counting1 <= 1'b0;    
    start_stat1 <= 1'b0;
  end
  else begin
    if(m_axis_cmac_tx_tvalid && m_axis_cmac_tx_tlast && !start_counting1) begin
      start_counting1 <= 1'b1;
    end

    delay_cnt1 <= start_counting1 ? (delay_cnt1 + 32'd1) : delay_cnt1;

    if(delay_cnt1 >= (WAIT_CYCLE>>1)) begin
      start_counting1   <= 1'b0;
      start_stat1       <= 1'b1;
    end
  end
end

always_ff @(posedge axil_clk)
begin
  if(!axil_rstn) begin
    start_stat1_cdc <= 2'd0;
  end
  else begin
    start_stat1_cdc <= {start_stat1_cdc[0], start_stat1};
  end
end

assign start_rdma1_stat = start_stat1_cdc[1];

always_ff @(posedge axis_clk)
begin
  if(!axis_rstn) begin
    delay_cnt2 <= 32'd0;
    start_counting2 <= 1'b0;
    start_stat2 <= 1'b0;
  end
  else begin
    if(m_axis_cmac_tx_tvalid && m_axis_cmac_tx_tlast && !start_counting2) begin
      start_counting2 <= 1'b1;
    end

    delay_cnt2 <= start_counting2 ? (delay_cnt2 + 32'd1) : delay_cnt2;

    if(delay_cnt2 >= WAIT_CYCLE) begin
      start_counting2   <= 1'b0;
      start_stat2       <= 1'b1;
    end
  end
end

always_ff @(posedge axil_clk)
begin
  if(!axil_rstn) begin
    start_stat2_cdc <= 2'd0;
  end
  else begin
    start_stat2_cdc <= {start_stat2_cdc[0], start_stat2};
  end
end

assign start_rdma2_stat = start_stat2_cdc[1];

always_comb
begin
  if(finish_rdma2_stat) begin
    $display("INFO: [rn_tb_2rdma_top], time=%t, Simulation completed", $time);
    $finish;
  end
end

endmodule: rn_tb_2rdma_top
