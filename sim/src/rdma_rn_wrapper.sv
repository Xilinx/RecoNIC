//==============================================================================
// Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
// SPDX-License-Identifier: MIT
//
//==============================================================================
`timescale 1ns/1ps

module rdma_rn_wrapper (
// AXIL interface to the RDMA engine
  input         s_axil_rdma_awvalid,
  input  [31:0] s_axil_rdma_awaddr,
  output        s_axil_rdma_awready,
  input         s_axil_rdma_wvalid,
  input  [31:0] s_axil_rdma_wdata,
  output        s_axil_rdma_wready,
  output        s_axil_rdma_bvalid,
  output  [1:0] s_axil_rdma_bresp,
  input         s_axil_rdma_bready,
  input         s_axil_rdma_arvalid,
  input  [31:0] s_axil_rdma_araddr,
  output        s_axil_rdma_arready,
  output        s_axil_rdma_rvalid,
  output [31:0] s_axil_rdma_rdata,
  output  [1:0] s_axil_rdma_rresp,
  input         s_axil_rdma_rready,

// RecoNIC AXI4-Lite register channel
  input         s_axil_rn_awvalid,
  input  [31:0] s_axil_rn_awaddr,
  output        s_axil_rn_awready,
  input         s_axil_rn_wvalid,
  input  [31:0] s_axil_rn_wdata,
  output        s_axil_rn_wready,
  output        s_axil_rn_bvalid,
  output  [1:0] s_axil_rn_bresp,
  input         s_axil_rn_bready,
  input         s_axil_rn_arvalid,
  input  [31:0] s_axil_rn_araddr,
  output        s_axil_rn_arready,
  output        s_axil_rn_rvalid,
  output [31:0] s_axil_rn_rdata,
  output  [1:0] s_axil_rn_rresp,
  input         s_axil_rn_rready,

  // Receive packets from CMAC RX path
  input         s_axis_cmac_rx_tvalid,
  input [511:0] s_axis_cmac_rx_tdata,
  input  [63:0] s_axis_cmac_rx_tkeep,
  input         s_axis_cmac_rx_tlast,
  input  [15:0] s_axis_cmac_rx_tuser_size,
  output        s_axis_cmac_rx_tready,

  // Expose roce packets from CMAC RX path after packet classification, 
  // for debug only
  output [511:0] m_axis_cmac2rdma_roce_tdata,
  output  [63:0] m_axis_cmac2rdma_roce_tkeep,
  output         m_axis_cmac2rdma_roce_tvalid,
  output         m_axis_cmac2rdma_roce_tlast,

  // AXIS data to CMAC TX path
  output [511:0] m_axis_cmac_tx_tdata,
  output  [63:0] m_axis_cmac_tx_tkeep,
  output         m_axis_cmac_tx_tvalid,
  output  [15:0] m_axis_cmac_tx_tuser_size,
  output         m_axis_cmac_tx_tlast,
  input          m_axis_cmac_tx_tready,

  // Get non-roce packets from QDMA tx path
  input         s_axis_qdma_h2c_tvalid,
  input [511:0] s_axis_qdma_h2c_tdata,
  input  [63:0] s_axis_qdma_h2c_tkeep,
  input         s_axis_qdma_h2c_tlast,
  input  [15:0] s_axis_qdma_h2c_tuser_size,
  output        s_axis_qdma_h2c_tready,

  // Send non-roce packets from QDMA rx path
  output         m_axis_qdma_c2h_tvalid,
  output [511:0] m_axis_qdma_c2h_tdata,
  output  [63:0] m_axis_qdma_c2h_tkeep,
  output         m_axis_qdma_c2h_tlast,
  output  [15:0] m_axis_qdma_c2h_tuser_size,
  input          m_axis_qdma_c2h_tready,

  // RDMA AXI MM interface used to store payload from RDMA MAD, Send or Write operation
  output           m_axi_rdma_send_write_payload_awid,
  output  [63 : 0] m_axi_rdma_send_write_payload_awaddr,
  output  [31 : 0] m_axi_rdma_send_write_payload_awuser,
  output   [7 : 0] m_axi_rdma_send_write_payload_awlen,
  output   [2 : 0] m_axi_rdma_send_write_payload_awsize,
  output   [1 : 0] m_axi_rdma_send_write_payload_awburst,
  output   [3 : 0] m_axi_rdma_send_write_payload_awcache,
  output   [2 : 0] m_axi_rdma_send_write_payload_awprot,
  output           m_axi_rdma_send_write_payload_awvalid,
  input            m_axi_rdma_send_write_payload_awready,
  output [511 : 0] m_axi_rdma_send_write_payload_wdata,
  output  [63 : 0] m_axi_rdma_send_write_payload_wstrb,
  output           m_axi_rdma_send_write_payload_wlast,
  output           m_axi_rdma_send_write_payload_wvalid,
  input            m_axi_rdma_send_write_payload_wready,
  output           m_axi_rdma_send_write_payload_awlock,
  input            m_axi_rdma_send_write_payload_bid,
  input    [1 : 0] m_axi_rdma_send_write_payload_bresp,
  input            m_axi_rdma_send_write_payload_bvalid,
  output           m_axi_rdma_send_write_payload_bready,
  output           m_axi_rdma_send_write_payload_arid,
  output  [63 : 0] m_axi_rdma_send_write_payload_araddr,
  output   [7 : 0] m_axi_rdma_send_write_payload_arlen,
  output   [2 : 0] m_axi_rdma_send_write_payload_arsize,
  output   [1 : 0] m_axi_rdma_send_write_payload_arburst,
  output   [3 : 0] m_axi_rdma_send_write_payload_arcache,
  output   [2 : 0] m_axi_rdma_send_write_payload_arprot,
  output           m_axi_rdma_send_write_payload_arvalid,
  input            m_axi_rdma_send_write_payload_arready,
  input            m_axi_rdma_send_write_payload_rid,
  input  [511 : 0] m_axi_rdma_send_write_payload_rdata,
  input    [1 : 0] m_axi_rdma_send_write_payload_rresp,
  input            m_axi_rdma_send_write_payload_rlast,
  input            m_axi_rdma_send_write_payload_rvalid,
  output           m_axi_rdma_send_write_payload_rready,
  output           m_axi_rdma_send_write_payload_arlock,

  // RDMA AXI MM interface used to store payload from RDMA Read response operation
  output           m_axi_rdma_rsp_payload_awid,
  output  [63 : 0] m_axi_rdma_rsp_payload_awaddr,
  output   [7 : 0] m_axi_rdma_rsp_payload_awlen,
  output   [2 : 0] m_axi_rdma_rsp_payload_awsize,
  output   [1 : 0] m_axi_rdma_rsp_payload_awburst,
  output   [3 : 0] m_axi_rdma_rsp_payload_awcache,
  output   [2 : 0] m_axi_rdma_rsp_payload_awprot,
  output           m_axi_rdma_rsp_payload_awvalid,
  input            m_axi_rdma_rsp_payload_awready,
  output [511 : 0] m_axi_rdma_rsp_payload_wdata,
  output  [63 : 0] m_axi_rdma_rsp_payload_wstrb,
  output           m_axi_rdma_rsp_payload_wlast,
  output           m_axi_rdma_rsp_payload_wvalid,
  input            m_axi_rdma_rsp_payload_wready,
  output           m_axi_rdma_rsp_payload_awlock,
  input            m_axi_rdma_rsp_payload_bid,
  input    [1 : 0] m_axi_rdma_rsp_payload_bresp,
  input            m_axi_rdma_rsp_payload_bvalid,
  output           m_axi_rdma_rsp_payload_bready,
  output           m_axi_rdma_rsp_payload_arid,
  output  [63 : 0] m_axi_rdma_rsp_payload_araddr,
  output   [7 : 0] m_axi_rdma_rsp_payload_arlen,
  output   [2 : 0] m_axi_rdma_rsp_payload_arsize,
  output   [1 : 0] m_axi_rdma_rsp_payload_arburst,
  output   [3 : 0] m_axi_rdma_rsp_payload_arcache,
  output   [2 : 0] m_axi_rdma_rsp_payload_arprot,
  output           m_axi_rdma_rsp_payload_arvalid,
  input            m_axi_rdma_rsp_payload_arready,
  input            m_axi_rdma_rsp_payload_rid,
  input  [511 : 0] m_axi_rdma_rsp_payload_rdata,
  input    [1 : 0] m_axi_rdma_rsp_payload_rresp,
  input            m_axi_rdma_rsp_payload_rlast,
  input            m_axi_rdma_rsp_payload_rvalid,
  output           m_axi_rdma_rsp_payload_rready,
  output           m_axi_rdma_rsp_payload_arlock,

  // RDMA AXI MM interface used to fetch WQE entries in the senq queue from DDR by the QP manager
  output           m_axi_rdma_get_wqe_awid,
  output  [63 : 0] m_axi_rdma_get_wqe_awaddr,
  output   [7 : 0] m_axi_rdma_get_wqe_awlen,
  output   [2 : 0] m_axi_rdma_get_wqe_awsize,
  output   [1 : 0] m_axi_rdma_get_wqe_awburst,
  output   [3 : 0] m_axi_rdma_get_wqe_awcache,
  output   [2 : 0] m_axi_rdma_get_wqe_awprot,
  output           m_axi_rdma_get_wqe_awvalid,
  input            m_axi_rdma_get_wqe_awready,
  output [511 : 0] m_axi_rdma_get_wqe_wdata,
  output  [63 : 0] m_axi_rdma_get_wqe_wstrb,
  output           m_axi_rdma_get_wqe_wlast,
  output           m_axi_rdma_get_wqe_wvalid,
  input            m_axi_rdma_get_wqe_wready,
  output           m_axi_rdma_get_wqe_awlock,
  input            m_axi_rdma_get_wqe_bid,
  input    [1 : 0] m_axi_rdma_get_wqe_bresp,
  input            m_axi_rdma_get_wqe_bvalid,
  output           m_axi_rdma_get_wqe_bready,
  output           m_axi_rdma_get_wqe_arid,
  output  [63 : 0] m_axi_rdma_get_wqe_araddr,
  output   [7 : 0] m_axi_rdma_get_wqe_arlen,
  output   [2 : 0] m_axi_rdma_get_wqe_arsize,
  output   [1 : 0] m_axi_rdma_get_wqe_arburst,
  output   [3 : 0] m_axi_rdma_get_wqe_arcache,
  output   [2 : 0] m_axi_rdma_get_wqe_arprot,
  output           m_axi_rdma_get_wqe_arvalid,
  input            m_axi_rdma_get_wqe_arready,
  input            m_axi_rdma_get_wqe_rid,
  input  [511 : 0] m_axi_rdma_get_wqe_rdata,
  input    [1 : 0] m_axi_rdma_get_wqe_rresp,
  input            m_axi_rdma_get_wqe_rlast,
  input            m_axi_rdma_get_wqe_rvalid,
  output           m_axi_rdma_get_wqe_rready,
  output           m_axi_rdma_get_wqe_arlock,

  // RDMA AXI MM interface used to get payload of an outgoing RDMA send/write and read response packets
  output           m_axi_rdma_get_payload_awid,
  output  [63 : 0] m_axi_rdma_get_payload_awaddr,
  output   [7 : 0] m_axi_rdma_get_payload_awlen,
  output   [2 : 0] m_axi_rdma_get_payload_awsize,
  output   [1 : 0] m_axi_rdma_get_payload_awburst,
  output   [3 : 0] m_axi_rdma_get_payload_awcache,
  output   [2 : 0] m_axi_rdma_get_payload_awprot,
  output           m_axi_rdma_get_payload_awvalid,
  input            m_axi_rdma_get_payload_awready,
  output [511 : 0] m_axi_rdma_get_payload_wdata,
  output  [63 : 0] m_axi_rdma_get_payload_wstrb,
  output           m_axi_rdma_get_payload_wlast,
  output           m_axi_rdma_get_payload_wvalid,
  input            m_axi_rdma_get_payload_wready,
  output           m_axi_rdma_get_payload_awlock,
  input            m_axi_rdma_get_payload_bid,
  input    [1 : 0] m_axi_rdma_get_payload_bresp,
  input            m_axi_rdma_get_payload_bvalid,
  output           m_axi_rdma_get_payload_bready,
  output           m_axi_rdma_get_payload_arid,
  output  [63 : 0] m_axi_rdma_get_payload_araddr,
  output   [7 : 0] m_axi_rdma_get_payload_arlen,
  output   [2 : 0] m_axi_rdma_get_payload_arsize,
  output   [1 : 0] m_axi_rdma_get_payload_arburst,
  output   [3 : 0] m_axi_rdma_get_payload_arcache,
  output   [2 : 0] m_axi_rdma_get_payload_arprot,
  output           m_axi_rdma_get_payload_arvalid,
  input            m_axi_rdma_get_payload_arready,
  input            m_axi_rdma_get_payload_rid,
  input  [511 : 0] m_axi_rdma_get_payload_rdata,
  input    [1 : 0] m_axi_rdma_get_payload_rresp,
  input            m_axi_rdma_get_payload_rlast,
  input            m_axi_rdma_get_payload_rvalid,
  output           m_axi_rdma_get_payload_rready,
  output           m_axi_rdma_get_payload_arlock,

  // RDMA AXI MM interface used to write completion entries to a completion queue in the DDR
  output           m_axi_rdma_completion_awid,
  output  [63 : 0] m_axi_rdma_completion_awaddr,
  output   [7 : 0] m_axi_rdma_completion_awlen,
  output   [2 : 0] m_axi_rdma_completion_awsize,
  output   [1 : 0] m_axi_rdma_completion_awburst,
  output   [3 : 0] m_axi_rdma_completion_awcache,
  output   [2 : 0] m_axi_rdma_completion_awprot,
  output           m_axi_rdma_completion_awvalid,
  input            m_axi_rdma_completion_awready,
  output [511 : 0] m_axi_rdma_completion_wdata,
  output  [63 : 0] m_axi_rdma_completion_wstrb,
  output           m_axi_rdma_completion_wlast,
  output           m_axi_rdma_completion_wvalid,
  input            m_axi_rdma_completion_wready,
  output           m_axi_rdma_completion_awlock,
  input            m_axi_rdma_completion_bid,
  input    [1 : 0] m_axi_rdma_completion_bresp,
  input            m_axi_rdma_completion_bvalid,
  output           m_axi_rdma_completion_bready,
  output           m_axi_rdma_completion_arid,
  output  [63 : 0] m_axi_rdma_completion_araddr,
  output   [7 : 0] m_axi_rdma_completion_arlen,
  output   [2 : 0] m_axi_rdma_completion_arsize,
  output   [1 : 0] m_axi_rdma_completion_arburst,
  output   [3 : 0] m_axi_rdma_completion_arcache,
  output   [2 : 0] m_axi_rdma_completion_arprot,
  output           m_axi_rdma_completion_arvalid,
  input            m_axi_rdma_completion_arready,
  input            m_axi_rdma_completion_rid,
  input  [511 : 0] m_axi_rdma_completion_rdata,
  input    [1 : 0] m_axi_rdma_completion_rresp,
  input            m_axi_rdma_completion_rlast,
  input            m_axi_rdma_completion_rvalid,
  output           m_axi_rdma_completion_rready,
  output           m_axi_rdma_completion_arlock,

  output           m_axi_compute_logic_awid,
  output  [63 : 0] m_axi_compute_logic_awaddr,
  output   [3 : 0] m_axi_compute_logic_awqos,
  output   [7 : 0] m_axi_compute_logic_awlen,
  output   [2 : 0] m_axi_compute_logic_awsize,
  output   [1 : 0] m_axi_compute_logic_awburst,
  output   [3 : 0] m_axi_compute_logic_awcache,
  output   [2 : 0] m_axi_compute_logic_awprot,
  output           m_axi_compute_logic_awvalid,
  input            m_axi_compute_logic_awready,
  output [511 : 0] m_axi_compute_logic_wdata,
  output  [63 : 0] m_axi_compute_logic_wstrb,
  output           m_axi_compute_logic_wlast,
  output           m_axi_compute_logic_wvalid,
  input            m_axi_compute_logic_wready,
  output           m_axi_compute_logic_awlock,
  input            m_axi_compute_logic_bid,
  input    [1 : 0] m_axi_compute_logic_bresp,
  input            m_axi_compute_logic_bvalid,
  output           m_axi_compute_logic_bready,
  output           m_axi_compute_logic_arid,
  output  [63 : 0] m_axi_compute_logic_araddr,
  output   [7 : 0] m_axi_compute_logic_arlen,
  output   [2 : 0] m_axi_compute_logic_arsize,
  output   [1 : 0] m_axi_compute_logic_arburst,
  output   [3 : 0] m_axi_compute_logic_arcache,
  output   [2 : 0] m_axi_compute_logic_arprot,
  output           m_axi_compute_logic_arvalid,
  input            m_axi_compute_logic_arready,
  input            m_axi_compute_logic_rid,
  input  [511 : 0] m_axi_compute_logic_rdata,
  input    [1 : 0] m_axi_compute_logic_rresp,
  input            m_axi_compute_logic_rlast,
  input            m_axi_compute_logic_rvalid,
  output           m_axi_compute_logic_rready,
  output           m_axi_compute_logic_arlock,
  output    [3:0]  m_axi_compute_logic_arqos,

  output rdma_intr,
  input  axil_aclk,
  input  axil_rstn,
  input  axis_aclk,
  input  axis_rstn
);

// Send roce packets from reconic to rdma rx path
logic [511:0] cmac2rdma_roce_axis_tdata;
logic  [63:0] cmac2rdma_roce_axis_tkeep;
logic         cmac2rdma_roce_axis_tvalid;
logic         cmac2rdma_roce_axis_tlast;
logic         cmac2rdma_roce_axis_tuser;
logic         cmac2rdma_roce_axis_tready;

// RDMA TX interface (including roce and non-roce packets) to CMAC TX path
logic [511:0] rdma2cmac_axis_tdata;
logic  [63:0] rdma2cmac_axis_tkeep;
logic         rdma2cmac_axis_tvalid;
logic         rdma2cmac_axis_tlast;
logic         rdma2cmac_axis_tready;

// Non-RDMA packets from QDMA TX bypassing RDMA TX
logic [511:0] qdma2rdma_non_roce_axis_tdata;
logic  [63:0] qdma2rdma_non_roce_axis_tkeep;
logic         qdma2rdma_non_roce_axis_tvalid;
logic         qdma2rdma_non_roce_axis_tlast;
logic         qdma2rdma_non_roce_axis_tready;

// invalidate or immediate data from roce IETH/IMMDT header
logic  [63:0] rdma2user_ieth_immdt_axis_tdata;
logic         rdma2user_ieth_immdt_axis_tlast;
logic         rdma2user_ieth_immdt_axis_tvalid;
logic         rdma2user_ieth_immdt_axis_trdy;

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

logic  [15:0] user_rst_done;
logic         box_rst_done;

logic         rdma_rstn;
logic         rdma_rst_done;

// RDMA subsystem
// TODO: retry buffer and hardware handshaking are not supported at the moment
rdma_subsystem_wrapper rdma_subsystem_inst (
  // AXIL interface for RDMA control register
  .s_axil_awaddr    (s_axil_rdma_awaddr),
  .s_axil_awvalid   (s_axil_rdma_awvalid),
  .s_axil_awready   (s_axil_rdma_awready),
  .s_axil_wdata     (s_axil_rdma_wdata),
  .s_axil_wstrb     (4'hf),
  .s_axil_wvalid    (s_axil_rdma_wvalid),
  .s_axil_wready    (s_axil_rdma_wready),
  .s_axil_araddr    (s_axil_rdma_araddr),
  .s_axil_arvalid   (s_axil_rdma_arvalid),
  .s_axil_arready   (s_axil_rdma_arready),
  .s_axil_rdata     (s_axil_rdma_rdata),
  .s_axil_rvalid    (s_axil_rdma_rvalid),
  .s_axil_rresp     (s_axil_rdma_rresp),
  .s_axil_rready    (s_axil_rdma_rready),
  .s_axil_bresp     (s_axil_rdma_bresp),
  .s_axil_bvalid    (s_axil_rdma_bvalid),
  .s_axil_bready    (s_axil_rdma_bready),

  // RDMA TX interface (including roce and non-roce packets) to CMAC TX path
  .m_rdma2cmac_axis_tdata  (rdma2cmac_axis_tdata),
  .m_rdma2cmac_axis_tkeep  (rdma2cmac_axis_tkeep),
  .m_rdma2cmac_axis_tvalid (rdma2cmac_axis_tvalid),
  .m_rdma2cmac_axis_tlast  (rdma2cmac_axis_tlast),
  .m_rdma2cmac_axis_tready (rdma2cmac_axis_tready),

  // Non-RDMA packets from QDMA TX bypassing RDMA TX
  .s_qdma2rdma_non_roce_axis_tdata    (qdma2rdma_non_roce_axis_tdata),
  .s_qdma2rdma_non_roce_axis_tkeep    (qdma2rdma_non_roce_axis_tkeep),
  .s_qdma2rdma_non_roce_axis_tvalid   (qdma2rdma_non_roce_axis_tvalid),
  .s_qdma2rdma_non_roce_axis_tlast    (qdma2rdma_non_roce_axis_tlast),
  .s_qdma2rdma_non_roce_axis_tready   (qdma2rdma_non_roce_axis_tready),

  // RDMA RX interface from CMAC RX, no rx backpressure
  .s_cmac2rdma_roce_axis_tdata        (cmac2rdma_roce_axis_tdata),
  .s_cmac2rdma_roce_axis_tkeep        (cmac2rdma_roce_axis_tkeep),
  .s_cmac2rdma_roce_axis_tvalid       (cmac2rdma_roce_axis_tvalid),
  .s_cmac2rdma_roce_axis_tlast        (cmac2rdma_roce_axis_tlast),
  .s_cmac2rdma_roce_axis_tuser        (cmac2rdma_roce_axis_tuser),

  // Non-RDMA packets from CMAC RX bypassing RDMA, no rx backpressure
  .s_cmac2rdma_non_roce_axis_tdata    (512'd0),
  .s_cmac2rdma_non_roce_axis_tkeep    (64'd0),
  .s_cmac2rdma_non_roce_axis_tvalid   (1'b0),
  .s_cmac2rdma_non_roce_axis_tlast    (1'b0),
  .s_cmac2rdma_non_roce_axis_tuser    (1'b0),

  // Non-RDMA packets bypassing RDMA to QDMA RX
  .m_rdma2qdma_non_roce_axis_tdata    (),
  .m_rdma2qdma_non_roce_axis_tkeep    (),
  .m_rdma2qdma_non_roce_axis_tvalid   (),
  .m_rdma2qdma_non_roce_axis_tlast    (),
  .m_rdma2qdma_non_roce_axis_tready   (1'b1),

  // invalidate or immediate data from roce IETH/IMMDT header
  .m_rdma2user_ieth_immdt_axis_tdata  (rdma2user_ieth_immdt_axis_tdata),
  .m_rdma2user_ieth_immdt_axis_tlast  (rdma2user_ieth_immdt_axis_tlast),
  .m_rdma2user_ieth_immdt_axis_tvalid (rdma2user_ieth_immdt_axis_tvalid),
  .m_rdma2user_ieth_immdt_axis_trdy   (rdma2user_ieth_immdt_axis_trdy),

  // RDMA AXI MM interface used to store payload from RDMA MAD, Send or Write operation
  .m_axi_rdma_send_write_payload_store_awid    (m_axi_rdma_send_write_payload_awid),
  .m_axi_rdma_send_write_payload_store_awaddr  (m_axi_rdma_send_write_payload_awaddr),
  .m_axi_rdma_send_write_payload_store_awuser  (m_axi_rdma_send_write_payload_awuser),
  .m_axi_rdma_send_write_payload_store_awlen   (m_axi_rdma_send_write_payload_awlen),
  .m_axi_rdma_send_write_payload_store_awsize  (m_axi_rdma_send_write_payload_awsize),
  .m_axi_rdma_send_write_payload_store_awburst (m_axi_rdma_send_write_payload_awburst),
  .m_axi_rdma_send_write_payload_store_awcache (m_axi_rdma_send_write_payload_awcache),
  .m_axi_rdma_send_write_payload_store_awprot  (m_axi_rdma_send_write_payload_awprot),
  .m_axi_rdma_send_write_payload_store_awvalid (m_axi_rdma_send_write_payload_awvalid),
  .m_axi_rdma_send_write_payload_store_awready (m_axi_rdma_send_write_payload_awready),
  .m_axi_rdma_send_write_payload_store_wdata   (m_axi_rdma_send_write_payload_wdata),
  .m_axi_rdma_send_write_payload_store_wstrb   (m_axi_rdma_send_write_payload_wstrb),
  .m_axi_rdma_send_write_payload_store_wlast   (m_axi_rdma_send_write_payload_wlast),
  .m_axi_rdma_send_write_payload_store_wvalid  (m_axi_rdma_send_write_payload_wvalid),
  .m_axi_rdma_send_write_payload_store_wready  (m_axi_rdma_send_write_payload_wready),
  .m_axi_rdma_send_write_payload_store_awlock  (m_axi_rdma_send_write_payload_awlock),
  .m_axi_rdma_send_write_payload_store_bid     (m_axi_rdma_send_write_payload_bid),
  .m_axi_rdma_send_write_payload_store_bresp   (m_axi_rdma_send_write_payload_bresp),
  .m_axi_rdma_send_write_payload_store_bvalid  (m_axi_rdma_send_write_payload_bvalid),
  .m_axi_rdma_send_write_payload_store_bready  (m_axi_rdma_send_write_payload_bready),
  .m_axi_rdma_send_write_payload_store_arid    (m_axi_rdma_send_write_payload_arid),
  .m_axi_rdma_send_write_payload_store_araddr  (m_axi_rdma_send_write_payload_araddr),
  .m_axi_rdma_send_write_payload_store_arlen   (m_axi_rdma_send_write_payload_arlen),
  .m_axi_rdma_send_write_payload_store_arsize  (m_axi_rdma_send_write_payload_arsize),
  .m_axi_rdma_send_write_payload_store_arburst (m_axi_rdma_send_write_payload_arburst),
  .m_axi_rdma_send_write_payload_store_arcache (m_axi_rdma_send_write_payload_arcache),
  .m_axi_rdma_send_write_payload_store_arprot  (m_axi_rdma_send_write_payload_arprot),
  .m_axi_rdma_send_write_payload_store_arvalid (m_axi_rdma_send_write_payload_arvalid),
  .m_axi_rdma_send_write_payload_store_arready (m_axi_rdma_send_write_payload_arready),
  .m_axi_rdma_send_write_payload_store_rid     (m_axi_rdma_send_write_payload_rid),
  .m_axi_rdma_send_write_payload_store_rdata   (m_axi_rdma_send_write_payload_rdata),
  .m_axi_rdma_send_write_payload_store_rresp   (m_axi_rdma_send_write_payload_rresp),
  .m_axi_rdma_send_write_payload_store_rlast   (m_axi_rdma_send_write_payload_rlast),
  .m_axi_rdma_send_write_payload_store_rvalid  (m_axi_rdma_send_write_payload_rvalid),
  .m_axi_rdma_send_write_payload_store_rready  (m_axi_rdma_send_write_payload_rready),
  .m_axi_rdma_send_write_payload_store_arlock  (m_axi_rdma_send_write_payload_arlock),

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
  .m_axi_pktgen_get_payload_awid       (m_axi_rdma_get_payload_awid),
  .m_axi_pktgen_get_payload_awaddr     (m_axi_rdma_get_payload_awaddr),
  .m_axi_pktgen_get_payload_awlen      (m_axi_rdma_get_payload_awlen),
  .m_axi_pktgen_get_payload_awsize     (m_axi_rdma_get_payload_awsize),
  .m_axi_pktgen_get_payload_awburst    (m_axi_rdma_get_payload_awburst),
  .m_axi_pktgen_get_payload_awcache    (m_axi_rdma_get_payload_awcache),
  .m_axi_pktgen_get_payload_awprot     (m_axi_rdma_get_payload_awprot),
  .m_axi_pktgen_get_payload_awvalid    (m_axi_rdma_get_payload_awvalid),
  .m_axi_pktgen_get_payload_awready    (m_axi_rdma_get_payload_awready),
  .m_axi_pktgen_get_payload_wdata      (m_axi_rdma_get_payload_wdata),
  .m_axi_pktgen_get_payload_wstrb      (m_axi_rdma_get_payload_wstrb),
  .m_axi_pktgen_get_payload_wlast      (m_axi_rdma_get_payload_wlast),
  .m_axi_pktgen_get_payload_wvalid     (m_axi_rdma_get_payload_wvalid),
  .m_axi_pktgen_get_payload_wready     (m_axi_rdma_get_payload_wready),
  .m_axi_pktgen_get_payload_awlock     (m_axi_rdma_get_payload_awlock),
  .m_axi_pktgen_get_payload_bid        (m_axi_rdma_get_payload_bid),
  .m_axi_pktgen_get_payload_bresp      (m_axi_rdma_get_payload_bresp),
  .m_axi_pktgen_get_payload_bvalid     (m_axi_rdma_get_payload_bvalid),
  .m_axi_pktgen_get_payload_bready     (m_axi_rdma_get_payload_bready),
  .m_axi_pktgen_get_payload_arid       (m_axi_rdma_get_payload_arid),
  .m_axi_pktgen_get_payload_araddr     (m_axi_rdma_get_payload_araddr),
  .m_axi_pktgen_get_payload_arlen      (m_axi_rdma_get_payload_arlen),
  .m_axi_pktgen_get_payload_arsize     (m_axi_rdma_get_payload_arsize),
  .m_axi_pktgen_get_payload_arburst    (m_axi_rdma_get_payload_arburst),
  .m_axi_pktgen_get_payload_arcache    (m_axi_rdma_get_payload_arcache),
  .m_axi_pktgen_get_payload_arprot     (m_axi_rdma_get_payload_arprot),
  .m_axi_pktgen_get_payload_arvalid    (m_axi_rdma_get_payload_arvalid),
  .m_axi_pktgen_get_payload_arready    (m_axi_rdma_get_payload_arready),
  .m_axi_pktgen_get_payload_rid        (m_axi_rdma_get_payload_rid),
  .m_axi_pktgen_get_payload_rdata      (m_axi_rdma_get_payload_rdata),
  .m_axi_pktgen_get_payload_rresp      (m_axi_rdma_get_payload_rresp),
  .m_axi_pktgen_get_payload_rlast      (m_axi_rdma_get_payload_rlast),
  .m_axi_pktgen_get_payload_rvalid     (m_axi_rdma_get_payload_rvalid),
  .m_axi_pktgen_get_payload_rready     (m_axi_rdma_get_payload_rready),
  .m_axi_pktgen_get_payload_arlock     (m_axi_rdma_get_payload_arlock),

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

  .rnic_intr    (rdma_intr),

  .mod_rstn     (axil_rstn),
  .mod_rst_done (rdma_rst_done),
  //.rdma_resetn_done (rdma_resetn_done),
  .axil_clk     (axil_aclk),
  .axis_clk     (axis_aclk)
);

// reconic wrapper
box_250mhz rn_dut (
  // AXI4-Lite register channel
  .s_axil_awvalid(s_axil_rn_awvalid),
  .s_axil_awaddr (s_axil_rn_awaddr),
  .s_axil_awready(s_axil_rn_awready),
  .s_axil_wvalid (s_axil_rn_wvalid),
  .s_axil_wdata  (s_axil_rn_wdata),
  .s_axil_wready (s_axil_rn_wready),
  .s_axil_bvalid (s_axil_rn_bvalid),
  .s_axil_bresp  (s_axil_rn_bresp),
  .s_axil_bready (s_axil_rn_bready),
  .s_axil_arvalid(s_axil_rn_arvalid),
  .s_axil_araddr (s_axil_rn_araddr),
  .s_axil_arready(s_axil_rn_arready),
  .s_axil_rvalid (s_axil_rn_rvalid),
  .s_axil_rdata  (s_axil_rn_rdata),
  .s_axil_rresp  (s_axil_rn_rresp),
  .s_axil_rready (s_axil_rn_rready),

  .s_axis_qdma_h2c_tvalid           (s_axis_qdma_h2c_tvalid),
  .s_axis_qdma_h2c_tdata            (s_axis_qdma_h2c_tdata),
  .s_axis_qdma_h2c_tkeep            (s_axis_qdma_h2c_tkeep),
  .s_axis_qdma_h2c_tlast            (s_axis_qdma_h2c_tlast),
  .s_axis_qdma_h2c_tuser_size       (s_axis_qdma_h2c_tuser_size),
  .s_axis_qdma_h2c_tuser_src        (16'hffff),
  .s_axis_qdma_h2c_tuser_dst        (16'hffff),
  .s_axis_qdma_h2c_tready           (s_axis_qdma_h2c_tready),

  .m_axis_qdma_c2h_tvalid           (m_axis_qdma_c2h_tvalid),
  .m_axis_qdma_c2h_tdata            (m_axis_qdma_c2h_tdata),
  .m_axis_qdma_c2h_tkeep            (m_axis_qdma_c2h_tkeep),
  .m_axis_qdma_c2h_tlast            (m_axis_qdma_c2h_tlast),
  .m_axis_qdma_c2h_tuser_size       (m_axis_qdma_c2h_tuser_size),
  .m_axis_qdma_c2h_tuser_src        (),
  .m_axis_qdma_c2h_tuser_dst        (),
  .m_axis_qdma_c2h_tready           (m_axis_qdma_c2h_tready),

  // Send packets to CMAC TX path
  .m_axis_adap_tx_250mhz_tvalid     (m_axis_cmac_tx_tvalid),
  .m_axis_adap_tx_250mhz_tdata      (m_axis_cmac_tx_tdata),
  .m_axis_adap_tx_250mhz_tkeep      (m_axis_cmac_tx_tkeep),
  .m_axis_adap_tx_250mhz_tlast      (m_axis_cmac_tx_tlast),
  .m_axis_adap_tx_250mhz_tuser_size (m_axis_cmac_tx_tuser_size),
  .m_axis_adap_tx_250mhz_tuser_src  (),
  .m_axis_adap_tx_250mhz_tuser_dst  (),
  .m_axis_adap_tx_250mhz_tready     (m_axis_cmac_tx_tready),

  // Receive packets from CMAC RX path
  .s_axis_adap_rx_250mhz_tvalid     (s_axis_cmac_rx_tvalid),
  .s_axis_adap_rx_250mhz_tdata      (s_axis_cmac_rx_tdata),
  .s_axis_adap_rx_250mhz_tkeep      (s_axis_cmac_rx_tkeep),
  .s_axis_adap_rx_250mhz_tlast      (s_axis_cmac_rx_tlast),
  .s_axis_adap_rx_250mhz_tuser_size (s_axis_cmac_rx_tuser_size),
  .s_axis_adap_rx_250mhz_tuser_src  (16'hffff),
  .s_axis_adap_rx_250mhz_tuser_dst  (16'hffff),
  .s_axis_adap_rx_250mhz_tready     (s_axis_cmac_rx_tready),

  // RoCEv2 packets from user logic box to rdma
  .m_axis_user2rdma_roce_from_cmac_rx_tvalid (cmac2rdma_roce_axis_tvalid),
  .m_axis_user2rdma_roce_from_cmac_rx_tdata  (cmac2rdma_roce_axis_tdata),
  .m_axis_user2rdma_roce_from_cmac_rx_tkeep  (cmac2rdma_roce_axis_tkeep),
  .m_axis_user2rdma_roce_from_cmac_rx_tlast  (cmac2rdma_roce_axis_tlast),
  .m_axis_user2rdma_roce_from_cmac_rx_tready (cmac2rdma_roce_axis_tready),

  // packets from rdma to user logic
  .s_axis_rdma2user_to_cmac_tx_tvalid        (rdma2cmac_axis_tvalid),
  .s_axis_rdma2user_to_cmac_tx_tdata         (rdma2cmac_axis_tdata),
  .s_axis_rdma2user_to_cmac_tx_tkeep         (rdma2cmac_axis_tkeep),
  .s_axis_rdma2user_to_cmac_tx_tlast         (rdma2cmac_axis_tlast),
  .s_axis_rdma2user_to_cmac_tx_tready        (rdma2cmac_axis_tready),

  // packets from user logic to rdma
  .m_axis_user2rdma_from_qdma_tx_tvalid      (qdma2rdma_non_roce_axis_tvalid),
  .m_axis_user2rdma_from_qdma_tx_tdata       (qdma2rdma_non_roce_axis_tdata),
  .m_axis_user2rdma_from_qdma_tx_tkeep       (qdma2rdma_non_roce_axis_tkeep),
  .m_axis_user2rdma_from_qdma_tx_tlast       (qdma2rdma_non_roce_axis_tlast),
  .m_axis_user2rdma_from_qdma_tx_tready      (qdma2rdma_non_roce_axis_tready),

  // ieth or immdt data from rdma packets
  .s_axis_rdma2user_ieth_immdt_tdata         (rdma2user_ieth_immdt_axis_tdata),
  .s_axis_rdma2user_ieth_immdt_tlast         (rdma2user_ieth_immdt_axis_tlast),
  .s_axis_rdma2user_ieth_immdt_tvalid        (rdma2user_ieth_immdt_axis_tvalid),
  .s_axis_rdma2user_ieth_immdt_trdy          (rdma2user_ieth_immdt_axis_trdy),

  // HW handshaking from user logic: Send WQE completion queue doorbell
  .s_resp_hndler_i_send_cq_db_cnt_valid(resp_hndler_o_send_cq_db_cnt_valid),
  .s_resp_hndler_i_send_cq_db_addr     (resp_hndler_o_send_cq_db_addr),
  .s_resp_hndler_i_send_cq_db_cnt      (resp_hndler_o_send_cq_db_cnt),
  .s_resp_hndler_o_send_cq_db_rdy      (resp_hndler_i_send_cq_db_rdy),

  // HW handshaking from user logic: Send WQE producer index doorbell
  .m_o_qp_sq_pidb_hndshk               (i_qp_sq_pidb_hndshk),
  .m_o_qp_sq_pidb_wr_addr_hndshk       (i_qp_sq_pidb_wr_addr_hndshk),
  .m_o_qp_sq_pidb_wr_valid_hndshk      (i_qp_sq_pidb_wr_valid_hndshk),
  .m_i_qp_sq_pidb_wr_rdy               (o_qp_sq_pidb_wr_rdy),

  // HW handshaking from user logic: RDMA-Send consumer index doorbell
  .m_o_qp_rq_cidb_hndshk               (i_qp_rq_cidb_hndshk),
  .m_o_qp_rq_cidb_wr_addr_hndshk       (i_qp_rq_cidb_wr_addr_hndshk),
  .m_o_qp_rq_cidb_wr_valid_hndshk      (i_qp_rq_cidb_wr_valid_hndshk),
  .m_i_qp_rq_cidb_wr_rdy               (o_qp_rq_cidb_wr_rdy),

  // HW handshaking from user logic: RDMA-Send producer index doorbell
  .s_rx_pkt_hndler_i_rq_db_data        (rx_pkt_hndler_o_rq_db_data),
  .s_rx_pkt_hndler_i_rq_db_addr        (rx_pkt_hndler_o_rq_db_addr),
  .s_rx_pkt_hndler_i_rq_db_data_valid  (rx_pkt_hndler_o_rq_db_data_valid),
  .s_rx_pkt_hndler_o_rq_db_rdy         (rx_pkt_hndler_i_rq_db_rdy),

  // AXI interface from the Compute Logic
  .m_axi_compute_logic_awid            (m_axi_compute_logic_awid),
  .m_axi_compute_logic_awaddr          (m_axi_compute_logic_awaddr),
  .m_axi_compute_logic_awqos           (m_axi_compute_logic_awqos),
  .m_axi_compute_logic_awlen           (m_axi_compute_logic_awlen),
  .m_axi_compute_logic_awsize          (m_axi_compute_logic_awsize),
  .m_axi_compute_logic_awburst         (m_axi_compute_logic_awburst),
  .m_axi_compute_logic_awcache         (m_axi_compute_logic_awcache),
  .m_axi_compute_logic_awprot          (m_axi_compute_logic_awprot),
  .m_axi_compute_logic_awvalid         (m_axi_compute_logic_awvalid),
  .m_axi_compute_logic_awready         (m_axi_compute_logic_awready),
  .m_axi_compute_logic_wdata           (m_axi_compute_logic_wdata),
  .m_axi_compute_logic_wstrb           (m_axi_compute_logic_wstrb),
  .m_axi_compute_logic_wlast           (m_axi_compute_logic_wlast),
  .m_axi_compute_logic_wvalid          (m_axi_compute_logic_wvalid),
  .m_axi_compute_logic_wready          (m_axi_compute_logic_wready),
  .m_axi_compute_logic_awlock          (m_axi_compute_logic_awlock),
  .m_axi_compute_logic_bid             (m_axi_compute_logic_bid),
  .m_axi_compute_logic_bresp           (m_axi_compute_logic_bresp),
  .m_axi_compute_logic_bvalid          (m_axi_compute_logic_bvalid),
  .m_axi_compute_logic_bready          (m_axi_compute_logic_bready),
  .m_axi_compute_logic_arid            (m_axi_compute_logic_arid),
  .m_axi_compute_logic_araddr          (m_axi_compute_logic_araddr),
  .m_axi_compute_logic_arlen           (m_axi_compute_logic_arlen),
  .m_axi_compute_logic_arsize          (m_axi_compute_logic_arsize),
  .m_axi_compute_logic_arburst         (m_axi_compute_logic_arburst),
  .m_axi_compute_logic_arcache         (m_axi_compute_logic_arcache),
  .m_axi_compute_logic_arprot          (m_axi_compute_logic_arprot),
  .m_axi_compute_logic_arvalid         (m_axi_compute_logic_arvalid),
  .m_axi_compute_logic_arready         (m_axi_compute_logic_arready),
  .m_axi_compute_logic_rid             (m_axi_compute_logic_rid),
  .m_axi_compute_logic_rdata           (m_axi_compute_logic_rdata),
  .m_axi_compute_logic_rresp           (m_axi_compute_logic_rresp),
  .m_axi_compute_logic_rlast           (m_axi_compute_logic_rlast),
  .m_axi_compute_logic_rvalid          (m_axi_compute_logic_rvalid),
  .m_axi_compute_logic_rready          (m_axi_compute_logic_rready),
  .m_axi_compute_logic_arlock          (m_axi_compute_logic_arlock),
  .m_axi_compute_logic_arqos           (m_axi_compute_logic_arqos),

  .mod_rstn     ({15'd0, axil_rstn}),
  .mod_rst_done (user_rst_done),

  .box_rstn     (axil_rstn),
  .box_rst_done (box_rst_done),

  .axil_aclk    (axil_aclk),
  .axis_aclk    (axis_aclk)
);

assign cmac2rdma_roce_axis_tuser  = 1'b1;
assign cmac2rdma_roce_axis_tready = 1'b1;

assign m_axis_cmac2rdma_roce_tdata  = cmac2rdma_roce_axis_tdata;
assign m_axis_cmac2rdma_roce_tkeep  = cmac2rdma_roce_axis_tkeep;
assign m_axis_cmac2rdma_roce_tvalid = cmac2rdma_roce_axis_tvalid;
assign m_axis_cmac2rdma_roce_tlast  = cmac2rdma_roce_axis_tlast;

endmodule: rdma_rn_wrapper