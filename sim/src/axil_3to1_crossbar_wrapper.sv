//==============================================================================
// Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
// SPDX-License-Identifier: MIT
//
//==============================================================================
`timescale 1ns/1ps

module axil_3to1_crossbar_wrapper (
  // RDMA2 register interface for configuration
  input         s_axil_reg_awvalid,
  input  [31:0] s_axil_reg_awaddr,
  output        s_axil_reg_awready,
  input         s_axil_reg_wvalid,
  input  [31:0] s_axil_reg_wdata,
  output        s_axil_reg_wready,
  output        s_axil_reg_bvalid,
  output  [1:0] s_axil_reg_bresp,
  input         s_axil_reg_bready,
  input         s_axil_reg_arvalid,
  input  [31:0] s_axil_reg_araddr,
  output        s_axil_reg_arready,
  output        s_axil_reg_rvalid,
  output [31:0] s_axil_reg_rdata,
  output  [1:0] s_axil_reg_rresp,
  input         s_axil_reg_rready,

  // RDMA2 stat register interface for debug purpose
  input         s_axil_stat_awvalid,
  input  [31:0] s_axil_stat_awaddr,
  output        s_axil_stat_awready,
  input         s_axil_stat_wvalid,
  input  [31:0] s_axil_stat_wdata,
  output        s_axil_stat_wready,
  output        s_axil_stat_bvalid,
  output  [1:0] s_axil_stat_bresp,
  input         s_axil_stat_bready,
  input         s_axil_stat_arvalid,
  input  [31:0] s_axil_stat_araddr,
  output        s_axil_stat_arready,
  output        s_axil_stat_rvalid,
  output [31:0] s_axil_stat_rdata,
  output  [1:0] s_axil_stat_rresp,
  input         s_axil_stat_rready,

  // RDMA2 receive register interface for dealing with incoming send RDMA packets
  input         s_axil_recv_awvalid,
  input  [31:0] s_axil_recv_awaddr,
  output        s_axil_recv_awready,
  input         s_axil_recv_wvalid,
  input  [31:0] s_axil_recv_wdata,
  output        s_axil_recv_wready,
  output        s_axil_recv_bvalid,
  output  [1:0] s_axil_recv_bresp,
  input         s_axil_recv_bready,
  input         s_axil_recv_arvalid,
  input  [31:0] s_axil_recv_araddr,
  output        s_axil_recv_arready,
  output        s_axil_recv_rvalid,
  output [31:0] s_axil_recv_rdata,
  output  [1:0] s_axil_recv_rresp,
  input         s_axil_recv_rready,

  // RDMA2 AXIL interface
  output        m_axil_awvalid,
  output [31:0] m_axil_awaddr,
  input         m_axil_awready,
  output        m_axil_wvalid,
  output [31:0] m_axil_wdata,
  input         m_axil_wready,
  input         m_axil_bvalid,
  input   [1:0] m_axil_bresp,
  output        m_axil_bready,
  output        m_axil_arvalid,
  output [31:0] m_axil_araddr,
  input         m_axil_arready,
  input         m_axil_rvalid,
  input  [31:0] m_axil_rdata,
  input   [1:0] m_axil_rresp,
  output        m_axil_rready,

  input axil_clk,
  input axil_rstn
);

localparam C_NUM_MASTERS = 3;
localparam C_REG_INDEX   = 0;
localparam C_STAT_INDEX  = 1;
localparam C_RECV_INDEX  = 2;

logic  [(1*C_NUM_MASTERS)-1:0] axil_awvalid;
logic [(32*C_NUM_MASTERS)-1:0] axil_awaddr;
logic  [(1*C_NUM_MASTERS)-1:0] axil_awready;
logic  [(1*C_NUM_MASTERS)-1:0] axil_wvalid;
logic [(32*C_NUM_MASTERS)-1:0] axil_wdata;
logic  [(1*C_NUM_MASTERS)-1:0] axil_wready;
logic  [(1*C_NUM_MASTERS)-1:0] axil_bvalid;
logic  [(2*C_NUM_MASTERS)-1:0] axil_bresp;
logic  [(1*C_NUM_MASTERS)-1:0] axil_bready;
logic  [(1*C_NUM_MASTERS)-1:0] axil_arvalid;
logic [(32*C_NUM_MASTERS)-1:0] axil_araddr;
logic  [(1*C_NUM_MASTERS)-1:0] axil_arready;
logic  [(1*C_NUM_MASTERS)-1:0] axil_rvalid;
logic [(32*C_NUM_MASTERS)-1:0] axil_rdata;
logic  [(2*C_NUM_MASTERS)-1:0] axil_rresp;
logic  [(1*C_NUM_MASTERS)-1:0] axil_rready;

assign axil_awvalid = {s_axil_recv_awvalid, s_axil_stat_awvalid, s_axil_reg_awvalid};
assign axil_awaddr  = {s_axil_recv_awaddr , s_axil_stat_awaddr, s_axil_reg_awaddr};
assign axil_wvalid  = {s_axil_recv_wvalid , s_axil_stat_wvalid, s_axil_reg_wvalid};
assign axil_wdata   = {s_axil_recv_wdata  , s_axil_stat_wdata, s_axil_reg_wdata};
assign axil_bready  = {s_axil_recv_bready , s_axil_stat_bready, s_axil_reg_bready};
assign axil_arvalid = {s_axil_recv_arvalid, s_axil_stat_arvalid, s_axil_reg_arvalid};
assign axil_araddr  = {s_axil_recv_araddr , s_axil_stat_araddr, s_axil_reg_araddr};
assign axil_rready  = {s_axil_recv_rready , s_axil_stat_rready, s_axil_reg_rready};

assign s_axil_reg_awready = axil_awready[C_REG_INDEX];
assign s_axil_reg_wready  = axil_wready[C_REG_INDEX];
assign s_axil_reg_bvalid  = axil_bvalid[C_REG_INDEX];
assign s_axil_reg_bresp   = axil_bresp[C_REG_INDEX*2+: 2];
assign s_axil_reg_arready = axil_arready[C_REG_INDEX];
assign s_axil_reg_rvalid  = axil_rvalid[C_REG_INDEX];
assign s_axil_reg_rdata   = axil_rdata[C_REG_INDEX*32+: 32];
assign s_axil_reg_rresp   = axil_rresp[C_REG_INDEX*2+: 2];

assign s_axil_stat_awready = axil_awready[C_STAT_INDEX];
assign s_axil_stat_wready  = axil_wready[C_STAT_INDEX];
assign s_axil_stat_bvalid  = axil_bvalid[C_STAT_INDEX];
assign s_axil_stat_bresp   = axil_bresp[C_STAT_INDEX*2+: 2];
assign s_axil_stat_arready = axil_arready[C_STAT_INDEX];
assign s_axil_stat_rvalid  = axil_rvalid[C_STAT_INDEX];;
assign s_axil_stat_rdata   = axil_rdata[C_STAT_INDEX*32+: 32];
assign s_axil_stat_rresp   = axil_rresp[C_STAT_INDEX*2+: 2];

assign s_axil_recv_awready = axil_awready[C_RECV_INDEX];
assign s_axil_recv_wready  = axil_wready [C_RECV_INDEX];
assign s_axil_recv_bvalid  = axil_bvalid [C_RECV_INDEX];
assign s_axil_recv_bresp   = axil_bresp  [C_RECV_INDEX*2+: 2];
assign s_axil_recv_arready = axil_arready[C_RECV_INDEX];
assign s_axil_recv_rvalid  = axil_rvalid [C_RECV_INDEX];
assign s_axil_recv_rdata   = axil_rdata  [C_RECV_INDEX*32+: 32];
assign s_axil_recv_rresp   = axil_rresp  [C_RECV_INDEX*2+: 2];

axil_3to1_crossbar axil_3to1_crossbar_inst (
  .s_axi_awaddr  (axil_awaddr),
  .s_axi_awprot  (0),
  .s_axi_awvalid (axil_awvalid),
  .s_axi_awready (axil_awready),
  .s_axi_wdata   (axil_wdata),
  .s_axi_wstrb   (8'hFF),
  .s_axi_wvalid  (axil_wvalid),
  .s_axi_wready  (axil_wready),
  .s_axi_bresp   (axil_bresp),
  .s_axi_bvalid  (axil_bvalid),
  .s_axi_bready  (axil_bready),
  .s_axi_araddr  (axil_araddr),
  .s_axi_arprot  (0),
  .s_axi_arvalid (axil_arvalid),
  .s_axi_arready (axil_arready),
  .s_axi_rdata   (axil_rdata),
  .s_axi_rresp   (axil_rresp),
  .s_axi_rvalid  (axil_rvalid),
  .s_axi_rready  (axil_rready),

  .m_axi_awaddr  (m_axil_awaddr),
  .m_axi_awprot  (),
  .m_axi_awvalid (m_axil_awvalid),
  .m_axi_awready (m_axil_awready),
  .m_axi_wdata   (m_axil_wdata),
  .m_axi_wstrb   (),
  .m_axi_wvalid  (m_axil_wvalid),
  .m_axi_wready  (m_axil_wready),
  .m_axi_bresp   (m_axil_bresp),
  .m_axi_bvalid  (m_axil_bvalid),
  .m_axi_bready  (m_axil_bready),
  .m_axi_araddr  (m_axil_araddr),
  .m_axi_arprot  (),
  .m_axi_arvalid (m_axil_arvalid),
  .m_axi_arready (m_axil_arready),
  .m_axi_rdata   (m_axil_rdata),
  .m_axi_rresp   (m_axil_rresp),
  .m_axi_rvalid  (m_axil_rvalid),
  .m_axi_rready  (m_axil_rready),

  .aclk          (axil_clk),
  .aresetn       (axil_rstn)
);

endmodule: axil_3to1_crossbar_wrapper