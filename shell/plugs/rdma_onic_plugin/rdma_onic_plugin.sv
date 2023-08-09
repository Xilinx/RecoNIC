//==============================================================================
// Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
// SPDX-License-Identifier: MIT
//
//==============================================================================
`timescale 1ns/1ps

module rdma_onic_plugin (
  input            s_axil_awvalid,
  input     [31:0] s_axil_awaddr,
  output           s_axil_awready,
  input            s_axil_wvalid,
  input     [31:0] s_axil_wdata,
  output           s_axil_wready,
  output           s_axil_bvalid,
  output     [1:0] s_axil_bresp,
  input            s_axil_bready,
  input            s_axil_arvalid,
  input     [31:0] s_axil_araddr,
  output           s_axil_arready,
  output           s_axil_rvalid,
  output    [31:0] s_axil_rdata,
  output     [1:0] s_axil_rresp,
  input            s_axil_rready,

  // Receive packets from CMAC RX path
  input            s_axis_cmac_rx_tvalid,
  input    [511:0] s_axis_cmac_rx_tdata,
  input     [63:0] s_axis_cmac_rx_tkeep,
  input            s_axis_cmac_rx_tlast,
  input     [15:0] s_axis_cmac_rx_tuser_size,
  output           s_axis_cmac_rx_tready,

  // Send roce packets to rdma rx path
  output           m_axis_user2rdma_roce_from_cmac_rx_tvalid,
  output   [511:0] m_axis_user2rdma_roce_from_cmac_rx_tdata,
  output    [63:0] m_axis_user2rdma_roce_from_cmac_rx_tkeep,
  output           m_axis_user2rdma_roce_from_cmac_rx_tlast,
  input            m_axis_user2rdma_roce_from_cmac_rx_tready,

  // Send non-roce packets to QDMA rx path
  output           m_axis_qdma_c2h_tvalid,
  output   [511:0] m_axis_qdma_c2h_tdata,
  output    [63:0] m_axis_qdma_c2h_tkeep,
  output           m_axis_qdma_c2h_tlast,
  output    [15:0] m_axis_qdma_c2h_tuser_size,
  input            m_axis_qdma_c2h_tready,

  // Get non-roce packets from QDMA tx path
  input            s_axis_qdma_h2c_tvalid,
  input    [511:0] s_axis_qdma_h2c_tdata,
  input     [63:0] s_axis_qdma_h2c_tkeep,
  input            s_axis_qdma_h2c_tlast,
  input     [15:0] s_axis_qdma_h2c_tuser_size,
  output           s_axis_qdma_h2c_tready,

  // Send non-roce packets to rdma tx path
  output           m_axis_user2rdma_from_qdma_tx_tvalid,
  output   [511:0] m_axis_user2rdma_from_qdma_tx_tdata,
  output    [63:0] m_axis_user2rdma_from_qdma_tx_tkeep,
  output           m_axis_user2rdma_from_qdma_tx_tlast,
  input            m_axis_user2rdma_from_qdma_tx_tready,

  // Get roce packets from rdma tx path
  input            s_axis_rdma2user_to_cmac_tx_tvalid,
  input    [511:0] s_axis_rdma2user_to_cmac_tx_tdata,
  input     [63:0] s_axis_rdma2user_to_cmac_tx_tkeep,
  input            s_axis_rdma2user_to_cmac_tx_tlast,
  output           s_axis_rdma2user_to_cmac_tx_tready,

  // Send packets to CMAC tx path
  output           m_axis_cmac_tx_tvalid,
  output   [511:0] m_axis_cmac_tx_tdata,
  output    [63:0] m_axis_cmac_tx_tkeep,
  output           m_axis_cmac_tx_tlast,
  output    [15:0] m_axis_cmac_tx_tuser_size,
  input            m_axis_cmac_tx_tready,

  output            m_axi_compute_logic_awid,
  output   [63 : 0] m_axi_compute_logic_awaddr,
  output    [3 : 0] m_axi_compute_logic_awqos,
  output    [7 : 0] m_axi_compute_logic_awlen,
  output    [2 : 0] m_axi_compute_logic_awsize,
  output    [1 : 0] m_axi_compute_logic_awburst,
  output    [3 : 0] m_axi_compute_logic_awcache,
  output    [2 : 0] m_axi_compute_logic_awprot,
  output            m_axi_compute_logic_awvalid,
  input             m_axi_compute_logic_awready,
  output  [511 : 0] m_axi_compute_logic_wdata,
  output   [63 : 0] m_axi_compute_logic_wstrb,
  output            m_axi_compute_logic_wlast,
  output            m_axi_compute_logic_wvalid,
  input             m_axi_compute_logic_wready,
  output            m_axi_compute_logic_awlock,
  input             m_axi_compute_logic_bid,
  input     [1 : 0] m_axi_compute_logic_bresp,
  input             m_axi_compute_logic_bvalid,
  output            m_axi_compute_logic_bready,
  output            m_axi_compute_logic_arid,
  output   [63 : 0] m_axi_compute_logic_araddr,
  output    [7 : 0] m_axi_compute_logic_arlen,
  output    [2 : 0] m_axi_compute_logic_arsize,
  output    [1 : 0] m_axi_compute_logic_arburst,
  output    [3 : 0] m_axi_compute_logic_arcache,
  output    [2 : 0] m_axi_compute_logic_arprot,
  output            m_axi_compute_logic_arvalid,
  input             m_axi_compute_logic_arready,
  input             m_axi_compute_logic_rid,
  input   [511 : 0] m_axi_compute_logic_rdata,
  input     [1 : 0] m_axi_compute_logic_rresp,
  input             m_axi_compute_logic_rlast,
  input             m_axi_compute_logic_rvalid,
  output            m_axi_compute_logic_rready,
  output            m_axi_compute_logic_arlock,
  output     [3:0]  m_axi_compute_logic_arqos,

  input             axil_aclk,
  input             axil_rstn,
  input             axis_aclk,
  input             axis_rstn
);

localparam C_AXIS_DATA_WIDTH = 512;
localparam C_AXIS_KEEP_WIDTH = 64;
localparam C_AXIS_USER_WIDTH = 16;
localparam C_AXIL_DATA_WIDTH = 32;
localparam C_AXIL_ADDR_WIDTH = 32;
localparam C_AXIL_REG_ADDR_WIDTH  = 12;
localparam C_AXIL_CTRL_ADDR_WIDTH = 13;

logic                         axil_ctrl_awvalid;
logic [C_AXIL_ADDR_WIDTH-1:0] axil_ctrl_awaddr;
logic                         axil_ctrl_awready;
logic                         axil_ctrl_wvalid;
logic [C_AXIL_DATA_WIDTH-1:0] axil_ctrl_wdata;
logic                         axil_ctrl_wready;
logic                         axil_ctrl_bvalid;
logic                   [1:0] axil_ctrl_bresp;
logic                         axil_ctrl_bready;
logic                         axil_ctrl_arvalid;
logic [C_AXIL_ADDR_WIDTH-1:0] axil_ctrl_araddr;
logic                         axil_ctrl_arready;
logic                         axil_ctrl_rvalid;
logic [C_AXIL_DATA_WIDTH-1:0] axil_ctrl_rdata;
logic                   [1:0] axil_ctrl_rresp;
logic                         axil_ctrl_rready;

logic                         axil_reg_awvalid;
logic [C_AXIL_ADDR_WIDTH-1:0] axil_reg_awaddr;
logic                         axil_reg_awready;
logic                         axil_reg_wvalid;
logic [C_AXIL_DATA_WIDTH-1:0] axil_reg_wdata;
logic                         axil_reg_wready;
logic                         axil_reg_bvalid;
logic                   [1:0] axil_reg_bresp;
logic                         axil_reg_bready;
logic                         axil_reg_arvalid;
logic [C_AXIL_ADDR_WIDTH-1:0] axil_reg_araddr;
logic                         axil_reg_arready;
logic                         axil_reg_rvalid;
logic [C_AXIL_DATA_WIDTH-1:0] axil_reg_rdata;
logic                   [1:0] axil_reg_rresp;
logic                         axil_reg_rready;

  // Compute Logic Register control interface
logic                         axil_cl_reg_awvalid;
logic [C_AXIL_ADDR_WIDTH-1:0] axil_cl_reg_awaddr;
logic                         axil_cl_reg_awready;
logic                         axil_cl_reg_wvalid;
logic [C_AXIL_DATA_WIDTH-1:0] axil_cl_reg_wdata;
logic                         axil_cl_reg_wready;
logic                         axil_cl_reg_bvalid;
logic                   [1:0] axil_cl_reg_bresp;
logic                         axil_cl_reg_bready;
logic                         axil_cl_reg_arvalid;
logic [C_AXIL_ADDR_WIDTH-1:0] axil_cl_reg_araddr;
logic                         axil_cl_reg_arready;
logic                         axil_cl_reg_rvalid;
logic [C_AXIL_DATA_WIDTH-1:0] axil_cl_reg_rdata;
logic                   [1:0] axil_cl_reg_rresp;
logic                         axil_cl_reg_rready;

`ifdef DEBUG
logic [31:0] s_axis_cmac_rx_tuser_idx;
`endif

// register address map
reconic_address_map reconic_address_map_inst (
  .s_axil_awvalid(s_axil_awvalid),
  .s_axil_awaddr (s_axil_awaddr ),
  .s_axil_awready(s_axil_awready),
  .s_axil_wvalid (s_axil_wvalid ),
  .s_axil_wdata  (s_axil_wdata  ),
  .s_axil_wready (s_axil_wready ),
  .s_axil_bvalid (s_axil_bvalid ),
  .s_axil_bresp  (s_axil_bresp  ),
  .s_axil_bready (s_axil_bready ),
  .s_axil_arvalid(s_axil_arvalid),
  .s_axil_araddr (s_axil_araddr ),
  .s_axil_arready(s_axil_arready),
  .s_axil_rvalid (s_axil_rvalid ),
  .s_axil_rdata  (s_axil_rdata  ),
  .s_axil_rresp  (s_axil_rresp  ),
  .s_axil_rready (s_axil_rready ),

  .m_axil_ctrl_awvalid(axil_ctrl_awvalid),
  .m_axil_ctrl_awaddr (axil_ctrl_awaddr ),
  .m_axil_ctrl_awready(axil_ctrl_awready),
  .m_axil_ctrl_wvalid (axil_ctrl_wvalid ),
  .m_axil_ctrl_wdata  (axil_ctrl_wdata  ),
  .m_axil_ctrl_wready (axil_ctrl_wready ),
  .m_axil_ctrl_bvalid (axil_ctrl_bvalid ),
  .m_axil_ctrl_bresp  (axil_ctrl_bresp  ),
  .m_axil_ctrl_bready (axil_ctrl_bready ),
  .m_axil_ctrl_arvalid(axil_ctrl_arvalid),
  .m_axil_ctrl_araddr (axil_ctrl_araddr ),
  .m_axil_ctrl_arready(axil_ctrl_arready),
  .m_axil_ctrl_rvalid (axil_ctrl_rvalid ),
  .m_axil_ctrl_rdata  (axil_ctrl_rdata  ),
  .m_axil_ctrl_rresp  (axil_ctrl_rresp  ),
  .m_axil_ctrl_rready (axil_ctrl_rready ),  

  .m_axil_reg_awvalid(axil_reg_awvalid),
  .m_axil_reg_awaddr (axil_reg_awaddr ),
  .m_axil_reg_awready(axil_reg_awready),
  .m_axil_reg_wvalid (axil_reg_wvalid ),
  .m_axil_reg_wdata  (axil_reg_wdata  ),
  .m_axil_reg_wready (axil_reg_wready ),
  .m_axil_reg_bvalid (axil_reg_bvalid ),
  .m_axil_reg_bresp  (axil_reg_bresp  ),
  .m_axil_reg_bready (axil_reg_bready ),
  .m_axil_reg_arvalid(axil_reg_arvalid),
  .m_axil_reg_araddr (axil_reg_araddr ),
  .m_axil_reg_arready(axil_reg_arready),
  .m_axil_reg_rvalid (axil_reg_rvalid ),
  .m_axil_reg_rdata  (axil_reg_rdata  ),
  .m_axil_reg_rresp  (axil_reg_rresp  ),
  .m_axil_reg_rready (axil_reg_rready ),

  // Compute Logic register interface
  .m_axil_cl_reg_awvalid (axil_cl_reg_awvalid),
  .m_axil_cl_reg_awaddr  (axil_cl_reg_awaddr),
  .m_axil_cl_reg_awready (axil_cl_reg_awready),
  .m_axil_cl_reg_wvalid  (axil_cl_reg_wvalid),
  .m_axil_cl_reg_wdata   (axil_cl_reg_wdata),
  .m_axil_cl_reg_wready  (axil_cl_reg_wready),
  .m_axil_cl_reg_bvalid  (axil_cl_reg_bvalid),
  .m_axil_cl_reg_bresp   (axil_cl_reg_bresp),
  .m_axil_cl_reg_bready  (axil_cl_reg_bready),
  .m_axil_cl_reg_arvalid (axil_cl_reg_arvalid),
  .m_axil_cl_reg_araddr  (axil_cl_reg_araddr),
  .m_axil_cl_reg_arready (axil_cl_reg_arready),
  .m_axil_cl_reg_rvalid  (axil_cl_reg_rvalid),
  .m_axil_cl_reg_rdata   (axil_cl_reg_rdata),
  .m_axil_cl_reg_rresp   (axil_cl_reg_rresp),
  .m_axil_cl_reg_rready  (axil_cl_reg_rready),

  .aclk   (axil_aclk),
  .aresetn(axil_rstn)
);

// RecoNIC instantiation
reconic #(
  .AXIL_REG_ADDR_WIDTH  (C_AXIL_REG_ADDR_WIDTH),
  .AXIL_CTRL_ADDR_WIDTH (C_AXIL_CTRL_ADDR_WIDTH),
  .AXIL_DATA_WIDTH      (C_AXIL_DATA_WIDTH),
  .AXIS_DATA_WIDTH      (C_AXIS_DATA_WIDTH),
  .AXIS_KEEP_WIDTH      (C_AXIS_KEEP_WIDTH),
  .AXIS_USER_WIDTH      (C_AXIS_USER_WIDTH)
) reconic_inst (
  // AXIL control interface used to configure tables in packet classification
  .s_axil_ctrl_awvalid(axil_ctrl_awvalid),
  .s_axil_ctrl_awaddr (axil_ctrl_awaddr ),
  .s_axil_ctrl_awready(axil_ctrl_awready),
  .s_axil_ctrl_wvalid (axil_ctrl_wvalid ),
  .s_axil_ctrl_wdata  (axil_ctrl_wdata  ),
  .s_axil_ctrl_wready (axil_ctrl_wready ),
  .s_axil_ctrl_bvalid (axil_ctrl_bvalid ),
  .s_axil_ctrl_bresp  (axil_ctrl_bresp  ),
  .s_axil_ctrl_bready (axil_ctrl_bready ),
  .s_axil_ctrl_arvalid(axil_ctrl_arvalid),
  .s_axil_ctrl_araddr (axil_ctrl_araddr ),
  .s_axil_ctrl_arready(axil_ctrl_arready),
  .s_axil_ctrl_rvalid (axil_ctrl_rvalid ),
  .s_axil_ctrl_rdata  (axil_ctrl_rdata  ),
  .s_axil_ctrl_rresp  (axil_ctrl_rresp  ),
  .s_axil_ctrl_rready (axil_ctrl_rready ),

  // AXIL register control interface used to access registers in RecoNIC
  .s_axil_reg_awvalid (axil_reg_awvalid),
  .s_axil_reg_awaddr  (axil_reg_awaddr ),
  .s_axil_reg_awready (axil_reg_awready),
  .s_axil_reg_wvalid  (axil_reg_wvalid ),
  .s_axil_reg_wdata   (axil_reg_wdata  ),
  .s_axil_reg_wready  (axil_reg_wready ),
  .s_axil_reg_bvalid  (axil_reg_bvalid ),
  .s_axil_reg_bresp   (axil_reg_bresp  ),
  .s_axil_reg_bready  (axil_reg_bready ),
  .s_axil_reg_arvalid (axil_reg_arvalid),
  .s_axil_reg_araddr  (axil_reg_araddr ),
  .s_axil_reg_arready (axil_reg_arready),
  .s_axil_reg_rvalid  (axil_reg_rvalid ),
  .s_axil_reg_rdata   (axil_reg_rdata  ),
  .s_axil_reg_rresp   (axil_reg_rresp  ),
  .s_axil_reg_rready  (axil_reg_rready ),

  // AXIL compute logic register control interface
  .s_axil_cl_reg_awvalid (axil_cl_reg_awvalid),
  .s_axil_cl_reg_awaddr  (axil_cl_reg_awaddr),
  .s_axil_cl_reg_awready (axil_cl_reg_awready),
  .s_axil_cl_reg_wvalid  (axil_cl_reg_wvalid),
  .s_axil_cl_reg_wdata   (axil_cl_reg_wdata),
  .s_axil_cl_reg_wready  (axil_cl_reg_wready),
  .s_axil_cl_reg_bvalid  (axil_cl_reg_bvalid),
  .s_axil_cl_reg_bresp   (axil_cl_reg_bresp),
  .s_axil_cl_reg_bready  (axil_cl_reg_bready),
  .s_axil_cl_reg_arvalid (axil_cl_reg_arvalid),
  .s_axil_cl_reg_araddr  (axil_cl_reg_araddr),
  .s_axil_cl_reg_arready (axil_cl_reg_arready),
  .s_axil_cl_reg_rvalid  (axil_cl_reg_rvalid),
  .s_axil_cl_reg_rdata   (axil_cl_reg_rdata),
  .s_axil_cl_reg_rresp   (axil_cl_reg_rresp),
  .s_axil_cl_reg_rready  (axil_cl_reg_rready),

  // Receive packets from CMAC RX path
  .s_axis_cmac_rx_tvalid                     (s_axis_cmac_rx_tvalid),
  .s_axis_cmac_rx_tdata                      (s_axis_cmac_rx_tdata),
  .s_axis_cmac_rx_tkeep                      (s_axis_cmac_rx_tkeep),
  .s_axis_cmac_rx_tlast                      (s_axis_cmac_rx_tlast),
  .s_axis_cmac_rx_tuser_size                 (s_axis_cmac_rx_tuser_size),
`ifdef DEBUG
  .s_axis_cmac_rx_tuser_idx                  (s_axis_cmac_rx_tuser_idx),
`endif
  .s_axis_cmac_rx_tready                     (s_axis_cmac_rx_tready),

  .m_axis_user2rdma_roce_from_cmac_rx_tvalid (m_axis_user2rdma_roce_from_cmac_rx_tvalid),
  .m_axis_user2rdma_roce_from_cmac_rx_tdata  (m_axis_user2rdma_roce_from_cmac_rx_tdata),
  .m_axis_user2rdma_roce_from_cmac_rx_tkeep  (m_axis_user2rdma_roce_from_cmac_rx_tkeep),
  .m_axis_user2rdma_roce_from_cmac_rx_tlast  (m_axis_user2rdma_roce_from_cmac_rx_tlast),
  .m_axis_user2rdma_roce_from_cmac_rx_tready (m_axis_user2rdma_roce_from_cmac_rx_tready),

  // Send packets to QDMA RX path
  .m_axis_qdma_c2h_tvalid                    (m_axis_qdma_c2h_tvalid),
  .m_axis_qdma_c2h_tdata                     (m_axis_qdma_c2h_tdata),
  .m_axis_qdma_c2h_tkeep                     (m_axis_qdma_c2h_tkeep),
  .m_axis_qdma_c2h_tlast                     (m_axis_qdma_c2h_tlast),
  .m_axis_qdma_c2h_tuser_size                (m_axis_qdma_c2h_tuser_size),
  .m_axis_qdma_c2h_tready                    (m_axis_qdma_c2h_tready),

  // Get packets from QDMA TX path
  .s_axis_qdma_h2c_tvalid                    (s_axis_qdma_h2c_tvalid),
  .s_axis_qdma_h2c_tdata                     (s_axis_qdma_h2c_tdata),
  .s_axis_qdma_h2c_tkeep                     (s_axis_qdma_h2c_tkeep),
  .s_axis_qdma_h2c_tlast                     (s_axis_qdma_h2c_tlast),
  .s_axis_qdma_h2c_tuser_size                (s_axis_qdma_h2c_tuser_size),
  .s_axis_qdma_h2c_tready                    (s_axis_qdma_h2c_tready),

  .m_axis_user2rdma_from_qdma_tx_tvalid      (m_axis_user2rdma_from_qdma_tx_tvalid),
  .m_axis_user2rdma_from_qdma_tx_tdata       (m_axis_user2rdma_from_qdma_tx_tdata),
  .m_axis_user2rdma_from_qdma_tx_tkeep       (m_axis_user2rdma_from_qdma_tx_tkeep),
  .m_axis_user2rdma_from_qdma_tx_tlast       (m_axis_user2rdma_from_qdma_tx_tlast),
  .m_axis_user2rdma_from_qdma_tx_tready      (m_axis_user2rdma_from_qdma_tx_tready),

  // Send packets to CMAC TX path
  .m_axis_cmac_tx_tvalid                     (m_axis_cmac_tx_tvalid),
  .m_axis_cmac_tx_tdata                      (m_axis_cmac_tx_tdata),
  .m_axis_cmac_tx_tkeep                      (m_axis_cmac_tx_tkeep),
  .m_axis_cmac_tx_tlast                      (m_axis_cmac_tx_tlast),
  .m_axis_cmac_tx_tuser_size                 (m_axis_cmac_tx_tuser_size),
  .m_axis_cmac_tx_tready                     (m_axis_cmac_tx_tready),

  .s_axis_rdma2user_to_cmac_tx_tvalid        (s_axis_rdma2user_to_cmac_tx_tvalid),
  .s_axis_rdma2user_to_cmac_tx_tdata         (s_axis_rdma2user_to_cmac_tx_tdata),
  .s_axis_rdma2user_to_cmac_tx_tkeep         (s_axis_rdma2user_to_cmac_tx_tkeep),
  .s_axis_rdma2user_to_cmac_tx_tlast         (s_axis_rdma2user_to_cmac_tx_tlast),
  .s_axis_rdma2user_to_cmac_tx_tready        (s_axis_rdma2user_to_cmac_tx_tready),

  .m_axi_compute_logic_awid                  (m_axi_compute_logic_awid),
  .m_axi_compute_logic_awaddr                (m_axi_compute_logic_awaddr),
  .m_axi_compute_logic_awqos                 (m_axi_compute_logic_awqos),
  .m_axi_compute_logic_awlen                 (m_axi_compute_logic_awlen),
  .m_axi_compute_logic_awsize                (m_axi_compute_logic_awsize),
  .m_axi_compute_logic_awburst               (m_axi_compute_logic_awburst),
  .m_axi_compute_logic_awcache               (m_axi_compute_logic_awcache),
  .m_axi_compute_logic_awprot                (m_axi_compute_logic_awprot),
  .m_axi_compute_logic_awvalid               (m_axi_compute_logic_awvalid),
  .m_axi_compute_logic_awready               (m_axi_compute_logic_awready),
  .m_axi_compute_logic_wdata                 (m_axi_compute_logic_wdata),
  .m_axi_compute_logic_wstrb                 (m_axi_compute_logic_wstrb),
  .m_axi_compute_logic_wlast                 (m_axi_compute_logic_wlast),
  .m_axi_compute_logic_wvalid                (m_axi_compute_logic_wvalid),
  .m_axi_compute_logic_wready                (m_axi_compute_logic_wready),
  .m_axi_compute_logic_awlock                (m_axi_compute_logic_awlock),
  .m_axi_compute_logic_bid                   (m_axi_compute_logic_bid),
  .m_axi_compute_logic_bresp                 (m_axi_compute_logic_bresp),
  .m_axi_compute_logic_bvalid                (m_axi_compute_logic_bvalid),
  .m_axi_compute_logic_bready                (m_axi_compute_logic_bready),
  .m_axi_compute_logic_arid                  (m_axi_compute_logic_arid),
  .m_axi_compute_logic_araddr                (m_axi_compute_logic_araddr),
  .m_axi_compute_logic_arlen                 (m_axi_compute_logic_arlen),
  .m_axi_compute_logic_arsize                (m_axi_compute_logic_arsize),
  .m_axi_compute_logic_arburst               (m_axi_compute_logic_arburst),
  .m_axi_compute_logic_arcache               (m_axi_compute_logic_arcache),
  .m_axi_compute_logic_arprot                (m_axi_compute_logic_arprot),
  .m_axi_compute_logic_arvalid               (m_axi_compute_logic_arvalid),
  .m_axi_compute_logic_arready               (m_axi_compute_logic_arready),
  .m_axi_compute_logic_rid                   (m_axi_compute_logic_rid),
  .m_axi_compute_logic_rdata                 (m_axi_compute_logic_rdata),
  .m_axi_compute_logic_rresp                 (m_axi_compute_logic_rresp),
  .m_axi_compute_logic_rlast                 (m_axi_compute_logic_rlast),
  .m_axi_compute_logic_rvalid                (m_axi_compute_logic_rvalid),
  .m_axi_compute_logic_rready                (m_axi_compute_logic_rready),
  .m_axi_compute_logic_arlock                (m_axi_compute_logic_arlock),
  .m_axi_compute_logic_arqos                 (m_axi_compute_logic_arqos),

  .axil_aclk(axil_aclk),
  .axil_rstn(axil_rstn),
  .axis_aclk(axis_aclk),
  .axis_rstn(axis_rstn) 
);

`ifdef DEBUG
always_ff @(posedge axis_aclk)
begin
  if(!axis_rstn) begin
    s_axis_cmac_rx_tuser_idx <= 32'd0;
  end
  else begin
    s_axis_cmac_rx_tuser_idx <= (s_axis_cmac_rx_tvalid && s_axis_cmac_rx_tlast && s_axis_cmac_rx_tready) ? (s_axis_cmac_rx_tuser_idx + 32'd1) : s_axis_cmac_rx_tuser_idx;
  end
end
`endif

endmodule: rdma_onic_plugin