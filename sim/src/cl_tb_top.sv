//==============================================================================
// Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
// SPDX-License-Identifier: MIT
//
//==============================================================================
`timescale 1ns/1ps

import rn_tb_pkg::*;

module cl_tb_top;

string traffic_filename          = "";
string table_filename            = "";
string rsp_table_filename        = "";
string golden_resp_filename      = "";
string get_req_feedback_filename = "";
string axi_read_info_filename    = "";
string axi_dev_mem_filename      = "matrix_dev_mem";
string axi_sys_mem_filename      = "";
string rdma_combined_cfg_filename= "";
/*
string table_filename            = "table";
string rsp_table_filename        = "rsp_table";
string golden_resp_filename      = "responses_golden";
string get_req_feedback_filename = "get_req_feedback_golden";
string axi_read_info_filename    = "axi_read_info";
*/
// Files used for Compute Logic simulation
string cl_ctl_cmd_filename     = "cl_ctl_cmd";
string cl_golden_data_filename = "cl_golden_data";
string cl_init_mem_filename    = "cl_init_mem";

localparam CLK_PERIOD     = 10ns;
localparam CLK_PERIOD_75  = 12048ps;
localparam CLK_PERIOD_300 = 3012ps;
localparam CLK_PERIOD_400 = 2500ps;
localparam CLK_PERIOD_200 = 5000ps;

logic axil_clk;
logic axil_rstn;
logic axis_clk;
logic axis_rstn;

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


// Singals used to indicate completion of memory initialization
logic init_dev_mem_done;

// AXI4 protocol write checker
logic [160-1:0] sys_pc_status;
logic           sys_pc_asserted;
logic [160-1:0] dev_pc_status;
logic           dev_pc_asserted;

logic start_config_ctl_cmd;

localparam AXIL_IDLE    = 2'b00;
localparam AXIL_START   = 2'b01;
localparam AXIL_GET_CMD = 2'b11;

logic [1:0] state;
logic [1:0] nextstate;
logic        ctl_cmd_size_vld;
logic [31:0] ctl_cmd_size;
logic [31:0] num_ctl_cmd;
logic        new_req;

logic [31:0] timeout_cnt;
logic [31:0] threshold;
logic start_verification;
logic stop_counting;

localparam TIMEOUT_THRESHOLD = 10000;
logic [31:0] verification_timeout_cnt;

logic dev_axi_read_passed;

// Initialize data in the device memory

assign start_config_ctl_cmd = init_dev_mem_done;

// Logic to generate s_axil_rn_* signals
axil_reg_control config_reg (
  .rdma_cfg_filename (cl_ctl_cmd_filename),
  .start_config_rdma (start_config_ctl_cmd),
  .finish_config_rdma(finish_config_ctl_cmd),
  .m_axil_reg_awvalid(s_axil_rn_awvalid),
  .m_axil_reg_awaddr (s_axil_rn_awaddr),
  .m_axil_reg_awready(s_axil_rn_awready),
  .m_axil_reg_wvalid (s_axil_rn_wvalid),
  .m_axil_reg_wdata  (s_axil_rn_wdata),
  .m_axil_reg_wready (s_axil_rn_wready),
  .m_axil_reg_bvalid (s_axil_rn_bvalid),
  .m_axil_reg_bresp  (s_axil_rn_bresp),
  .m_axil_reg_bready (s_axil_rn_bready),
  .m_axil_reg_arvalid(s_axil_rn_arvalid),
  .m_axil_reg_araddr (s_axil_rn_araddr),
  .m_axil_reg_arready(s_axil_rn_arready),
  .m_axil_reg_rvalid (s_axil_rn_rvalid),
  .m_axil_reg_rdata  (s_axil_rn_rdata),
  .m_axil_reg_rresp  (s_axil_rn_rresp),
  .m_axil_reg_rready (s_axil_rn_rready),
  .axil_clk          (axil_clk),
  .axil_rstn         (axil_rstn)
);

// Instantiate rdma_onic_plugin
rdma_onic_plugin dut (
  .s_axil_awvalid            (s_axil_rn_awvalid),
  .s_axil_awaddr             (s_axil_rn_awaddr),
  .s_axil_awready            (s_axil_rn_awready),
  .s_axil_wvalid             (s_axil_rn_wvalid),
  .s_axil_wdata              (s_axil_rn_wdata),
  .s_axil_wready             (s_axil_rn_wready),
  .s_axil_bvalid             (s_axil_rn_bvalid),
  .s_axil_bresp              (s_axil_rn_bresp),
  .s_axil_bready             (s_axil_rn_bready),
  .s_axil_arvalid            (s_axil_rn_arvalid),
  .s_axil_araddr             (s_axil_rn_araddr),
  .s_axil_arready            (s_axil_rn_arready),
  .s_axil_rvalid             (s_axil_rn_rvalid),
  .s_axil_rdata              (s_axil_rn_rdata),
  .s_axil_rresp              (s_axil_rn_rresp),
  .s_axil_rready             (s_axil_rn_rready),

  // Receive packets from CMAC RX path
  .s_axis_cmac_rx_tvalid     (1'b0),
  .s_axis_cmac_rx_tdata      (0),
  .s_axis_cmac_rx_tkeep      (0),
  .s_axis_cmac_rx_tlast      (0),
  .s_axis_cmac_rx_tuser_size (0),
  .s_axis_cmac_rx_tready     (),

  .m_axis_user2rdma_roce_from_cmac_rx_tvalid (),
  .m_axis_user2rdma_roce_from_cmac_rx_tdata  (),
  .m_axis_user2rdma_roce_from_cmac_rx_tkeep  (),
  .m_axis_user2rdma_roce_from_cmac_rx_tlast  (),
  .m_axis_user2rdma_roce_from_cmac_rx_tready (1'b1),

  // Send packets to QDMA RX path
  .m_axis_qdma_c2h_tvalid                    (),
  .m_axis_qdma_c2h_tdata                     (),
  .m_axis_qdma_c2h_tkeep                     (),
  .m_axis_qdma_c2h_tlast                     (),
  .m_axis_qdma_c2h_tuser_size                (),
  .m_axis_qdma_c2h_tready                    (1'b1),

  // Get packets from QDMA TX path
  .s_axis_qdma_h2c_tvalid                    (0),
  .s_axis_qdma_h2c_tdata                     (0),
  .s_axis_qdma_h2c_tkeep                     (0),
  .s_axis_qdma_h2c_tlast                     (0),
  .s_axis_qdma_h2c_tuser_size                (0),
  .s_axis_qdma_h2c_tready                    (),

  .m_axis_user2rdma_from_qdma_tx_tvalid      (),
  .m_axis_user2rdma_from_qdma_tx_tdata       (),
  .m_axis_user2rdma_from_qdma_tx_tkeep       (),
  .m_axis_user2rdma_from_qdma_tx_tlast       (),
  .m_axis_user2rdma_from_qdma_tx_tready      (1'b1),

  // Send packets to CMAC TX path
  .m_axis_cmac_tx_tvalid                     (),
  .m_axis_cmac_tx_tdata                      (),
  .m_axis_cmac_tx_tkeep                      (),
  .m_axis_cmac_tx_tlast                      (),
  .m_axis_cmac_tx_tuser_size                 (),
  .m_axis_cmac_tx_tready                     (1'b1),

  .s_axis_rdma2user_to_cmac_tx_tvalid        (0),
  .s_axis_rdma2user_to_cmac_tx_tdata         (0),
  .s_axis_rdma2user_to_cmac_tx_tkeep         (0),
  .s_axis_rdma2user_to_cmac_tx_tlast         (0),
  .s_axis_rdma2user_to_cmac_tx_tready        (),

  .m_axi_compute_logic_awid                  (axi_compute_logic_awid),
  .m_axi_compute_logic_awaddr                (axi_compute_logic_awaddr),
  .m_axi_compute_logic_awqos                 (axi_compute_logic_awqos),
  .m_axi_compute_logic_awlen                 (axi_compute_logic_awlen),
  .m_axi_compute_logic_awsize                (axi_compute_logic_awsize),
  .m_axi_compute_logic_awburst               (axi_compute_logic_awburst),
  .m_axi_compute_logic_awcache               (axi_compute_logic_awcache),
  .m_axi_compute_logic_awprot                (axi_compute_logic_awprot),
  .m_axi_compute_logic_awvalid               (axi_compute_logic_awvalid),
  .m_axi_compute_logic_awready               (axi_compute_logic_awready),
  .m_axi_compute_logic_wdata                 (axi_compute_logic_wdata),
  .m_axi_compute_logic_wstrb                 (axi_compute_logic_wstrb),
  .m_axi_compute_logic_wlast                 (axi_compute_logic_wlast),
  .m_axi_compute_logic_wvalid                (axi_compute_logic_wvalid),
  .m_axi_compute_logic_wready                (axi_compute_logic_wready),
  .m_axi_compute_logic_awlock                (axi_compute_logic_awlock),
  .m_axi_compute_logic_bid                   (axi_compute_logic_bid),
  .m_axi_compute_logic_bresp                 (axi_compute_logic_bresp),
  .m_axi_compute_logic_bvalid                (axi_compute_logic_bvalid),
  .m_axi_compute_logic_bready                (axi_compute_logic_bready),
  .m_axi_compute_logic_arid                  (axi_compute_logic_arid),
  .m_axi_compute_logic_araddr                (axi_compute_logic_araddr),
  .m_axi_compute_logic_arlen                 (axi_compute_logic_arlen),
  .m_axi_compute_logic_arsize                (axi_compute_logic_arsize),
  .m_axi_compute_logic_arburst               (axi_compute_logic_arburst),
  .m_axi_compute_logic_arcache               (axi_compute_logic_arcache),
  .m_axi_compute_logic_arprot                (axi_compute_logic_arprot),
  .m_axi_compute_logic_arvalid               (axi_compute_logic_arvalid),
  .m_axi_compute_logic_arready               (axi_compute_logic_arready),
  .m_axi_compute_logic_rid                   (axi_compute_logic_rid),
  .m_axi_compute_logic_rdata                 (axi_compute_logic_rdata),
  .m_axi_compute_logic_rresp                 (axi_compute_logic_rresp),
  .m_axi_compute_logic_rlast                 (axi_compute_logic_rlast),
  .m_axi_compute_logic_rvalid                (axi_compute_logic_rvalid),
  .m_axi_compute_logic_rready                (axi_compute_logic_rready),
  .m_axi_compute_logic_arlock                (axi_compute_logic_arlock),
  .m_axi_compute_logic_arqos                 (axi_compute_logic_arqos),

  .axil_aclk  (axil_clk),
  .axil_rstn  (axil_rstn),
  .axis_aclk  (axis_clk),
  .axis_rstn  (axis_rstn)
);

// AXI crossbar used to access device memory
axi_interconnect_to_dev_mem axi_interconnect_to_dev_mem_inst(
  .s_axi_rdma_send_write_payload_awid    (0),
  .s_axi_rdma_send_write_payload_awaddr  (64'd0),
  .s_axi_rdma_send_write_payload_awqos   (0),
  .s_axi_rdma_send_write_payload_awlen   (0),
  .s_axi_rdma_send_write_payload_awsize  (0),
  .s_axi_rdma_send_write_payload_awburst (0),
  .s_axi_rdma_send_write_payload_awcache (0),
  .s_axi_rdma_send_write_payload_awprot  (0),
  .s_axi_rdma_send_write_payload_awvalid (0),
  .s_axi_rdma_send_write_payload_awready (),
  .s_axi_rdma_send_write_payload_wdata   (512'd0),
  .s_axi_rdma_send_write_payload_wstrb   (64'd0),
  .s_axi_rdma_send_write_payload_wlast   (0),
  .s_axi_rdma_send_write_payload_wvalid  (0),
  .s_axi_rdma_send_write_payload_wready  (),
  .s_axi_rdma_send_write_payload_awlock  (0),
  .s_axi_rdma_send_write_payload_bid     (),
  .s_axi_rdma_send_write_payload_bresp   (),
  .s_axi_rdma_send_write_payload_bvalid  (),
  .s_axi_rdma_send_write_payload_bready  (1'b1),
  .s_axi_rdma_send_write_payload_arid    (0),
  .s_axi_rdma_send_write_payload_araddr  (64'd0),
  .s_axi_rdma_send_write_payload_arlen   (0),
  .s_axi_rdma_send_write_payload_arsize  (0),
  .s_axi_rdma_send_write_payload_arburst (0),
  .s_axi_rdma_send_write_payload_arcache (0),
  .s_axi_rdma_send_write_payload_arprot  (0),
  .s_axi_rdma_send_write_payload_arvalid (0),
  .s_axi_rdma_send_write_payload_arready (),
  .s_axi_rdma_send_write_payload_rid     (),
  .s_axi_rdma_send_write_payload_rdata   (),
  .s_axi_rdma_send_write_payload_rresp   (),
  .s_axi_rdma_send_write_payload_rlast   (),
  .s_axi_rdma_send_write_payload_rvalid  (),
  .s_axi_rdma_send_write_payload_rready  (0),
  .s_axi_rdma_send_write_payload_arlock  (0),
  .s_axi_rdma_send_write_payload_arqos   (0),

  .s_axi_rdma_rsp_payload_awid           (0),
  .s_axi_rdma_rsp_payload_awaddr         (64'd0),
  .s_axi_rdma_rsp_payload_awqos          (0),
  .s_axi_rdma_rsp_payload_awlen          (0),
  .s_axi_rdma_rsp_payload_awsize         (0),
  .s_axi_rdma_rsp_payload_awburst        (0),
  .s_axi_rdma_rsp_payload_awcache        (0),
  .s_axi_rdma_rsp_payload_awprot         (0),
  .s_axi_rdma_rsp_payload_awvalid        (0),
  .s_axi_rdma_rsp_payload_awready        (),
  .s_axi_rdma_rsp_payload_wdata          (512'd0),
  .s_axi_rdma_rsp_payload_wstrb          (64'd0),
  .s_axi_rdma_rsp_payload_wlast          (0),
  .s_axi_rdma_rsp_payload_wvalid         (0),
  .s_axi_rdma_rsp_payload_wready         (),
  .s_axi_rdma_rsp_payload_awlock         (0),
  .s_axi_rdma_rsp_payload_bid            (),
  .s_axi_rdma_rsp_payload_bresp          (),
  .s_axi_rdma_rsp_payload_bvalid         (),
  .s_axi_rdma_rsp_payload_bready         (1'b1),
  .s_axi_rdma_rsp_payload_arid           (0),
  .s_axi_rdma_rsp_payload_araddr         (64'd0),
  .s_axi_rdma_rsp_payload_arlen          (0),
  .s_axi_rdma_rsp_payload_arsize         (0),
  .s_axi_rdma_rsp_payload_arburst        (0),
  .s_axi_rdma_rsp_payload_arcache        (0),
  .s_axi_rdma_rsp_payload_arprot         (0),
  .s_axi_rdma_rsp_payload_arvalid        (0),
  .s_axi_rdma_rsp_payload_arready        (),
  .s_axi_rdma_rsp_payload_rid            (),
  .s_axi_rdma_rsp_payload_rdata          (),
  .s_axi_rdma_rsp_payload_rresp          (),
  .s_axi_rdma_rsp_payload_rlast          (),
  .s_axi_rdma_rsp_payload_rvalid         (),
  .s_axi_rdma_rsp_payload_rready         (0),
  .s_axi_rdma_rsp_payload_arlock         (0),
  .s_axi_rdma_rsp_payload_arqos          (0),

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

assign m_axi_veri_dev_arqos = 4'd0;

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

always_comb
begin
  if(dev_pc_asserted) begin
    $display("[ERROR] %t: dev_pc_asserted, axi4 write is wrong!", $time);
  end
end

init_mem init_dev_mem (
  .tag_string        ("cl"),
  .axi_mem_filename  (cl_init_mem_filename),

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

axi_read_verify axi_read_verify_dev_mem (
  .tag_string        ("cl"),
  .axi_read_filename (cl_golden_data_filename),

  // AXI MM read interface to verify device memory
  .m_axi_arid        (m_axi_veri_dev_arid),
  .m_axi_araddr      (m_axi_veri_dev_araddr),
  .m_axi_arlen       (m_axi_veri_dev_arlen),
  .m_axi_arsize      (m_axi_veri_dev_arsize),
  .m_axi_arburst     (m_axi_veri_dev_arburst),
  .m_axi_arlock      (m_axi_veri_dev_arlock),
  .m_axi_arcache     (m_axi_veri_dev_arcache),
  .m_axi_arprot      (m_axi_veri_dev_arprot),
  .m_axi_arvalid     (m_axi_veri_dev_arvalid),
  .m_axi_arready     (m_axi_veri_dev_arready),
  .m_axi_rid         (m_axi_veri_dev_rid),
  .m_axi_rdata       (m_axi_veri_dev_rdata),
  .m_axi_rresp       (m_axi_veri_dev_rresp),
  .m_axi_rlast       (m_axi_veri_dev_rlast),
  .m_axi_rvalid      (m_axi_veri_dev_rvalid),
  .m_axi_rready      (m_axi_veri_dev_rready),

  .start_axi_read    (start_axi_veri_dev_read),
  .axi_read_passed   (dev_axi_read_passed),
  
  .axis_clk          (axis_clk),
  .axis_rstn         (axis_rstn)
);

initial begin
  axil_rstn = 1'b0;
  axis_rstn = 1'b0;

  #500ns;
  axil_rstn = 1'b1;
  axis_rstn = 1'b1;
end

initial begin
  axis_clk  = 1'b0;
  forever #(CLK_PERIOD_200/2) axis_clk = ~axis_clk;
end

initial begin
  axil_clk  = 1'b0;
  forever #(CLK_PERIOD/2) axil_clk = ~axil_clk;
end

always_comb
begin
  ctl_cmd_size_vld = 1'b0;
  case(state)
  AXIL_IDLE: begin
    nextstate = start_config_ctl_cmd ? AXIL_START : AXIL_IDLE;
  end
  AXIL_START: begin
    if(s_axil_rn_wvalid && s_axil_rn_wready) begin
      ctl_cmd_size_vld = 1'b1;
      nextstate = AXIL_GET_CMD;
    end
  end
  AXIL_GET_CMD: begin
    nextstate = finish_config_ctl_cmd ? AXIL_IDLE : AXIL_GET_CMD;;
  end
  default: nextstate = AXIL_IDLE;
  endcase
end

always_ff @(posedge axil_clk)
begin
  if(!axil_rstn) begin
    ctl_cmd_size <= 32'd0;
    num_ctl_cmd  <= 32'd0;
    state <= AXIL_START;
  end
  else begin
    state <= nextstate;

    if(ctl_cmd_size_vld) begin
      ctl_cmd_size <= s_axil_rn_wdata;
    end

    if(s_axil_rn_wvalid && s_axil_rn_wready) begin
      num_ctl_cmd <= num_ctl_cmd + 1;
    end
  end
end

always_ff @(posedge axis_clk)
begin
  if(!axis_rstn) begin
    timeout_cnt <= 32'd0;
    verification_timeout_cnt <= 32'd0;
    start_verification <= 1'b0;
    stop_counting <= 1'b0;
    threshold <= 32'hffffffff;
  end
  else begin
    if(timeout_cnt >= threshold) begin
      start_verification <= 1'b1;
    end

    if(finish_config_ctl_cmd) begin
      timeout_cnt <= timeout_cnt + 32'd1;
      threshold <= num_ctl_cmd*2000;
    end

    if(start_verification && !stop_counting) begin
      verification_timeout_cnt <= verification_timeout_cnt + 1;
    end

    if(verification_timeout_cnt >= TIMEOUT_THRESHOLD) begin
      stop_counting <= 1'b1;
      if(dev_axi_read_passed) begin
        $display("Compute Logic test passed!\n");
      end
      else begin
        $display("Compute Logic test failed!\n");
      end
      $finish;
    end
  end
end

assign start_axi_veri_dev_read = start_verification;

endmodule: cl_tb_top
