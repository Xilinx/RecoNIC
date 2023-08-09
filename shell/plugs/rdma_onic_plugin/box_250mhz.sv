//==============================================================================
// Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
// Copyright (C) 2022, Xilinx, Inc. All rights reserved.
// SPDX-License-Identifier: MIT
//
//==============================================================================
`timescale 1ns/1ps

module box_250mhz #(
  parameter int MIN_PKT_LEN   = 64,
  parameter int MAX_PKT_LEN   = 1518,
  parameter int USE_PHYS_FUNC = 1,
  parameter int NUM_PHYS_FUNC = 1,
  parameter int NUM_CMAC_PORT = 1
) (
  input                          s_axil_awvalid,
  input                   [31:0] s_axil_awaddr,
  output                         s_axil_awready,
  input                          s_axil_wvalid,
  input                   [31:0] s_axil_wdata,
  output                         s_axil_wready,
  output                         s_axil_bvalid,
  output                   [1:0] s_axil_bresp,
  input                          s_axil_bready,
  input                          s_axil_arvalid,
  input                   [31:0] s_axil_araddr,
  output                         s_axil_arready,
  output                         s_axil_rvalid,
  output                  [31:0] s_axil_rdata,
  output                   [1:0] s_axil_rresp,
  input                          s_axil_rready,

  input      [NUM_PHYS_FUNC-1:0] s_axis_qdma_h2c_tvalid,
  input  [512*NUM_PHYS_FUNC-1:0] s_axis_qdma_h2c_tdata,
  input   [64*NUM_PHYS_FUNC-1:0] s_axis_qdma_h2c_tkeep,
  input      [NUM_PHYS_FUNC-1:0] s_axis_qdma_h2c_tlast,
  input   [16*NUM_PHYS_FUNC-1:0] s_axis_qdma_h2c_tuser_size,
  input   [16*NUM_PHYS_FUNC-1:0] s_axis_qdma_h2c_tuser_src,
  input   [16*NUM_PHYS_FUNC-1:0] s_axis_qdma_h2c_tuser_dst,
  output     [NUM_PHYS_FUNC-1:0] s_axis_qdma_h2c_tready,

  output     [NUM_PHYS_FUNC-1:0] m_axis_qdma_c2h_tvalid,
  output [512*NUM_PHYS_FUNC-1:0] m_axis_qdma_c2h_tdata,
  output  [64*NUM_PHYS_FUNC-1:0] m_axis_qdma_c2h_tkeep,
  output     [NUM_PHYS_FUNC-1:0] m_axis_qdma_c2h_tlast,
  output  [16*NUM_PHYS_FUNC-1:0] m_axis_qdma_c2h_tuser_size,
  output  [16*NUM_PHYS_FUNC-1:0] m_axis_qdma_c2h_tuser_src,
  output  [16*NUM_PHYS_FUNC-1:0] m_axis_qdma_c2h_tuser_dst,
  input      [NUM_PHYS_FUNC-1:0] m_axis_qdma_c2h_tready,

  output     [NUM_CMAC_PORT-1:0] m_axis_adap_tx_250mhz_tvalid,
  output [512*NUM_CMAC_PORT-1:0] m_axis_adap_tx_250mhz_tdata,
  output  [64*NUM_CMAC_PORT-1:0] m_axis_adap_tx_250mhz_tkeep,
  output     [NUM_CMAC_PORT-1:0] m_axis_adap_tx_250mhz_tlast,
  output  [16*NUM_CMAC_PORT-1:0] m_axis_adap_tx_250mhz_tuser_size,
  output  [16*NUM_CMAC_PORT-1:0] m_axis_adap_tx_250mhz_tuser_src,
  output  [16*NUM_CMAC_PORT-1:0] m_axis_adap_tx_250mhz_tuser_dst,
  input      [NUM_CMAC_PORT-1:0] m_axis_adap_tx_250mhz_tready,

  input      [NUM_CMAC_PORT-1:0] s_axis_adap_rx_250mhz_tvalid,
  input  [512*NUM_CMAC_PORT-1:0] s_axis_adap_rx_250mhz_tdata,
  input   [64*NUM_CMAC_PORT-1:0] s_axis_adap_rx_250mhz_tkeep,
  input      [NUM_CMAC_PORT-1:0] s_axis_adap_rx_250mhz_tlast,
  input   [16*NUM_CMAC_PORT-1:0] s_axis_adap_rx_250mhz_tuser_size,
  input   [16*NUM_CMAC_PORT-1:0] s_axis_adap_rx_250mhz_tuser_src,
  input   [16*NUM_CMAC_PORT-1:0] s_axis_adap_rx_250mhz_tuser_dst,
  output     [NUM_CMAC_PORT-1:0] s_axis_adap_rx_250mhz_tready,

  output                         m_axis_user2rdma_roce_from_cmac_rx_tvalid,
  output                 [511:0] m_axis_user2rdma_roce_from_cmac_rx_tdata,
  output                  [63:0] m_axis_user2rdma_roce_from_cmac_rx_tkeep,
  output                         m_axis_user2rdma_roce_from_cmac_rx_tlast,
  input                          m_axis_user2rdma_roce_from_cmac_rx_tready,

  input                          s_axis_rdma2user_to_cmac_tx_tvalid,
  input                  [511:0] s_axis_rdma2user_to_cmac_tx_tdata,
  input                   [63:0] s_axis_rdma2user_to_cmac_tx_tkeep,
  input                          s_axis_rdma2user_to_cmac_tx_tlast,
  output                         s_axis_rdma2user_to_cmac_tx_tready,

  output                         m_axis_user2rdma_from_qdma_tx_tvalid,
  output                 [511:0] m_axis_user2rdma_from_qdma_tx_tdata,
  output                  [63:0] m_axis_user2rdma_from_qdma_tx_tkeep,
  output                         m_axis_user2rdma_from_qdma_tx_tlast,
  input                          m_axis_user2rdma_from_qdma_tx_tready,

  input                   [63:0] s_axis_rdma2user_ieth_immdt_tdata,
  input                          s_axis_rdma2user_ieth_immdt_tlast,
  input                          s_axis_rdma2user_ieth_immdt_tvalid,
  output                         s_axis_rdma2user_ieth_immdt_trdy,

  input                          s_resp_hndler_i_send_cq_db_cnt_valid,
  input                   [9 :0] s_resp_hndler_i_send_cq_db_addr,
  input                   [31:0] s_resp_hndler_i_send_cq_db_cnt,
  output                         s_resp_hndler_o_send_cq_db_rdy,

  output                  [15:0] m_o_qp_sq_pidb_hndshk,
  output                  [31:0] m_o_qp_sq_pidb_wr_addr_hndshk,
  output                         m_o_qp_sq_pidb_wr_valid_hndshk,
  input                          m_i_qp_sq_pidb_wr_rdy,

  output                  [15:0] m_o_qp_rq_cidb_hndshk,
  output                  [31:0] m_o_qp_rq_cidb_wr_addr_hndshk,
  output                         m_o_qp_rq_cidb_wr_valid_hndshk,
  input                          m_i_qp_rq_cidb_wr_rdy,

  input                          s_rx_pkt_hndler_i_rq_db_data_valid,
  input                   [9 :0] s_rx_pkt_hndler_i_rq_db_addr,
  input                   [31:0] s_rx_pkt_hndler_i_rq_db_data,
  output                         s_rx_pkt_hndler_o_rq_db_rdy,

  output                         m_axi_compute_logic_awid,
  output                [63 : 0] m_axi_compute_logic_awaddr,
  output                 [3 : 0] m_axi_compute_logic_awqos,
  output                 [7 : 0] m_axi_compute_logic_awlen,
  output                 [2 : 0] m_axi_compute_logic_awsize,
  output                 [1 : 0] m_axi_compute_logic_awburst,
  output                 [3 : 0] m_axi_compute_logic_awcache,
  output                 [2 : 0] m_axi_compute_logic_awprot,
  output                         m_axi_compute_logic_awvalid,
  input                          m_axi_compute_logic_awready,
  output               [511 : 0] m_axi_compute_logic_wdata,
  output                [63 : 0] m_axi_compute_logic_wstrb,
  output                         m_axi_compute_logic_wlast,
  output                         m_axi_compute_logic_wvalid,
  input                          m_axi_compute_logic_wready,
  output                         m_axi_compute_logic_awlock,
  input                          m_axi_compute_logic_bid,
  input                  [1 : 0] m_axi_compute_logic_bresp,
  input                          m_axi_compute_logic_bvalid,
  output                         m_axi_compute_logic_bready,
  output                         m_axi_compute_logic_arid,
  output                [63 : 0] m_axi_compute_logic_araddr,
  output                 [7 : 0] m_axi_compute_logic_arlen,
  output                 [2 : 0] m_axi_compute_logic_arsize,
  output                 [1 : 0] m_axi_compute_logic_arburst,
  output                 [3 : 0] m_axi_compute_logic_arcache,
  output                 [2 : 0] m_axi_compute_logic_arprot,
  output                         m_axi_compute_logic_arvalid,
  input                          m_axi_compute_logic_arready,
  input                          m_axi_compute_logic_rid,
  input                [511 : 0] m_axi_compute_logic_rdata,
  input                  [1 : 0] m_axi_compute_logic_rresp,
  input                          m_axi_compute_logic_rlast,
  input                          m_axi_compute_logic_rvalid,
  output                         m_axi_compute_logic_rready,
  output                         m_axi_compute_logic_arlock,
  output                  [3:0]  m_axi_compute_logic_arqos,

  input                   [15:0] mod_rstn,
  output                  [15:0] mod_rst_done,

  input                          box_rstn,
  output                         box_rst_done,

  input                          axil_aclk,
  input                          axis_aclk
);

localparam C_NUM_USER_BLOCK = 1;

logic axil_rstn;
logic axis_rstn;

generic_reset #(
  .NUM_INPUT_CLK  (2),
  .RESET_DURATION (100)
) reset_inst (
  .mod_rstn     (box_rstn),
  .mod_rst_done (box_rst_done),
  .clk          ({axis_aclk, axil_aclk}),
  .rstn         ({axis_rstn, axil_rstn})
);

// Make sure for all the unused reset pair, corresponding bits in
// "mod_rst_done" are tied to 0
assign mod_rst_done[15:C_NUM_USER_BLOCK] = {(16-C_NUM_USER_BLOCK){1'b1}};
assign mod_rst_done[0]                   = box_rst_done;

rdma_onic_plugin rdma_onic_plugin_inst (
  .s_axil_awvalid            (s_axil_awvalid),
  .s_axil_awaddr             (s_axil_awaddr),
  .s_axil_awready            (s_axil_awready),
  .s_axil_wvalid             (s_axil_wvalid),
  .s_axil_wdata              (s_axil_wdata),
  .s_axil_wready             (s_axil_wready),
  .s_axil_bvalid             (s_axil_bvalid),
  .s_axil_bresp              (s_axil_bresp),
  .s_axil_bready             (s_axil_bready),
  .s_axil_arvalid            (s_axil_arvalid),
  .s_axil_araddr             (s_axil_araddr),
  .s_axil_arready            (s_axil_arready),
  .s_axil_rvalid             (s_axil_rvalid),
  .s_axil_rdata              (s_axil_rdata),
  .s_axil_rresp              (s_axil_rresp),
  .s_axil_rready             (s_axil_rready),

  // Receive packets from CMAC RX path
  .s_axis_cmac_rx_tvalid     (s_axis_adap_rx_250mhz_tvalid),
  .s_axis_cmac_rx_tdata      (s_axis_adap_rx_250mhz_tdata),
  .s_axis_cmac_rx_tkeep      (s_axis_adap_rx_250mhz_tkeep),
  .s_axis_cmac_rx_tlast      (s_axis_adap_rx_250mhz_tlast),
  .s_axis_cmac_rx_tuser_size (s_axis_adap_rx_250mhz_tuser_size),
  .s_axis_cmac_rx_tready     (s_axis_adap_rx_250mhz_tready),

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
  .m_axis_cmac_tx_tvalid                     (m_axis_adap_tx_250mhz_tvalid),
  .m_axis_cmac_tx_tdata                      (m_axis_adap_tx_250mhz_tdata),
  .m_axis_cmac_tx_tkeep                      (m_axis_adap_tx_250mhz_tkeep),
  .m_axis_cmac_tx_tlast                      (m_axis_adap_tx_250mhz_tlast),
  .m_axis_cmac_tx_tuser_size                 (m_axis_adap_tx_250mhz_tuser_size),
  .m_axis_cmac_tx_tready                     (m_axis_adap_tx_250mhz_tready),

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

  .axil_aclk  (axil_aclk),
  .axil_rstn  (axil_rstn),
  .axis_aclk  (axis_aclk),
  .axis_rstn  (axis_rstn)
);

assign m_axis_qdma_c2h_tuser_src = 16'd0;
assign m_axis_qdma_c2h_tuser_dst = 16'h1 << 0;
assign m_axis_adap_tx_250mhz_tuser_src = 16'd0;
assign m_axis_adap_tx_250mhz_tuser_dst = 16'h1 << 6;

// TODO: Disable hardware handshaking for doorbell ringing in the current implementation
assign s_resp_hndler_o_send_cq_db_rdy = 1'b0;
assign s_rx_pkt_hndler_o_rq_db_rdy    = 1'b0;

assign m_o_qp_sq_pidb_hndshk          = 0;
assign m_o_qp_sq_pidb_wr_addr_hndshk  = 0;
assign m_o_qp_sq_pidb_wr_valid_hndshk = 0;

assign m_o_qp_rq_cidb_hndshk          = 0;
assign m_o_qp_rq_cidb_wr_addr_hndshk  = 0;
assign m_o_qp_rq_cidb_wr_valid_hndshk = 0;

// TODO: Disable ieth and immdt data
assign s_axis_rdma2user_ieth_immdt_trdy = 1'b1;

endmodule: box_250mhz
