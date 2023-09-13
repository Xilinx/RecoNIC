//==============================================================================
// Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
// SPDX-License-Identifier: MIT
//
//==============================================================================
`timescale 1ns/1ps

module axi_3to1_interconnect_to_dev_mem #(
  parameter C_AXI_DATA_WIDTH = 512,
  parameter C_AXI_ADDR_WIDTH = 64
) (
  
  input     [4 : 0] s_axi_qdma_mm_awid,
  input    [63 : 0] s_axi_qdma_mm_awaddr,
  input     [3 : 0] s_axi_qdma_mm_awqos,
  input     [7 : 0] s_axi_qdma_mm_awlen,
  input     [2 : 0] s_axi_qdma_mm_awsize,
  input     [1 : 0] s_axi_qdma_mm_awburst,
  input     [3 : 0] s_axi_qdma_mm_awcache,
  input     [2 : 0] s_axi_qdma_mm_awprot,
  input             s_axi_qdma_mm_awvalid,
  output            s_axi_qdma_mm_awready,
  input   [511 : 0] s_axi_qdma_mm_wdata,
  input    [63 : 0] s_axi_qdma_mm_wstrb,
  input             s_axi_qdma_mm_wlast,
  input             s_axi_qdma_mm_wvalid,
  output            s_axi_qdma_mm_wready,
  input             s_axi_qdma_mm_awlock,
  output    [4 : 0] s_axi_qdma_mm_bid,
  output    [1 : 0] s_axi_qdma_mm_bresp,
  output            s_axi_qdma_mm_bvalid,
  input             s_axi_qdma_mm_bready,
  input     [4 : 0] s_axi_qdma_mm_arid,
  input    [63 : 0] s_axi_qdma_mm_araddr,
  input     [7 : 0] s_axi_qdma_mm_arlen,
  input     [2 : 0] s_axi_qdma_mm_arsize,
  input     [1 : 0] s_axi_qdma_mm_arburst,
  input     [3 : 0] s_axi_qdma_mm_arcache,
  input     [2 : 0] s_axi_qdma_mm_arprot,
  input             s_axi_qdma_mm_arvalid,
  output            s_axi_qdma_mm_arready,
  output    [4 : 0] s_axi_qdma_mm_rid,
  output  [511 : 0] s_axi_qdma_mm_rdata,
  output    [1 : 0] s_axi_qdma_mm_rresp,
  output            s_axi_qdma_mm_rlast,
  output            s_axi_qdma_mm_rvalid,
  input             s_axi_qdma_mm_rready,
  input             s_axi_qdma_mm_arlock,
  input     [3 : 0] s_axi_qdma_mm_arqos,

  input     [4 : 0] s_axi_compute_logic_awid,
  input    [63 : 0] s_axi_compute_logic_awaddr,
  input     [3 : 0] s_axi_compute_logic_awqos,
  input     [7 : 0] s_axi_compute_logic_awlen,
  input     [2 : 0] s_axi_compute_logic_awsize,
  input     [1 : 0] s_axi_compute_logic_awburst,
  input     [3 : 0] s_axi_compute_logic_awcache,
  input     [2 : 0] s_axi_compute_logic_awprot,
  input             s_axi_compute_logic_awvalid,
  output            s_axi_compute_logic_awready,
  input   [511 : 0] s_axi_compute_logic_wdata,
  input    [63 : 0] s_axi_compute_logic_wstrb,
  input             s_axi_compute_logic_wlast,
  input             s_axi_compute_logic_wvalid,
  output            s_axi_compute_logic_wready,
  input             s_axi_compute_logic_awlock,
  output    [4 : 0] s_axi_compute_logic_bid,
  output    [1 : 0] s_axi_compute_logic_bresp,
  output            s_axi_compute_logic_bvalid,
  input             s_axi_compute_logic_bready,
  input     [4 : 0] s_axi_compute_logic_arid,
  input    [63 : 0] s_axi_compute_logic_araddr,
  input     [7 : 0] s_axi_compute_logic_arlen,
  input     [2 : 0] s_axi_compute_logic_arsize,
  input     [1 : 0] s_axi_compute_logic_arburst,
  input     [3 : 0] s_axi_compute_logic_arcache,
  input     [2 : 0] s_axi_compute_logic_arprot,
  input             s_axi_compute_logic_arvalid,
  output            s_axi_compute_logic_arready,
  output    [4 : 0] s_axi_compute_logic_rid,
  output  [511 : 0] s_axi_compute_logic_rdata,
  output    [1 : 0] s_axi_compute_logic_rresp,
  output            s_axi_compute_logic_rlast,
  output            s_axi_compute_logic_rvalid,
  input             s_axi_compute_logic_rready,
  input             s_axi_compute_logic_arlock,
  input     [3 : 0] s_axi_compute_logic_arqos,

  input     [4 : 0] s_axi_from_sys_crossbar_awid,
  input    [63 : 0] s_axi_from_sys_crossbar_awaddr,
  input     [3 : 0] s_axi_from_sys_crossbar_awqos,
  input     [7 : 0] s_axi_from_sys_crossbar_awlen,
  input     [2 : 0] s_axi_from_sys_crossbar_awsize,
  input     [1 : 0] s_axi_from_sys_crossbar_awburst,
  input     [3 : 0] s_axi_from_sys_crossbar_awcache,
  input     [2 : 0] s_axi_from_sys_crossbar_awprot,
  input             s_axi_from_sys_crossbar_awvalid,
  output            s_axi_from_sys_crossbar_awready,
  input   [511 : 0] s_axi_from_sys_crossbar_wdata,
  input    [63 : 0] s_axi_from_sys_crossbar_wstrb,
  input             s_axi_from_sys_crossbar_wlast,
  input             s_axi_from_sys_crossbar_wvalid,
  output            s_axi_from_sys_crossbar_wready,
  input             s_axi_from_sys_crossbar_awlock,
  output    [4 : 0] s_axi_from_sys_crossbar_bid,
  output    [1 : 0] s_axi_from_sys_crossbar_bresp,
  output            s_axi_from_sys_crossbar_bvalid,
  input             s_axi_from_sys_crossbar_bready,
  input     [4 : 0] s_axi_from_sys_crossbar_arid,
  input    [63 : 0] s_axi_from_sys_crossbar_araddr,
  input     [7 : 0] s_axi_from_sys_crossbar_arlen,
  input     [2 : 0] s_axi_from_sys_crossbar_arsize,
  input     [1 : 0] s_axi_from_sys_crossbar_arburst,
  input     [3 : 0] s_axi_from_sys_crossbar_arcache,
  input     [2 : 0] s_axi_from_sys_crossbar_arprot,
  input             s_axi_from_sys_crossbar_arvalid,
  output            s_axi_from_sys_crossbar_arready,
  output    [4 : 0] s_axi_from_sys_crossbar_rid,
  output  [511 : 0] s_axi_from_sys_crossbar_rdata,
  output    [1 : 0] s_axi_from_sys_crossbar_rresp,
  output            s_axi_from_sys_crossbar_rlast,
  output            s_axi_from_sys_crossbar_rvalid,
  input             s_axi_from_sys_crossbar_rready,
  input             s_axi_from_sys_crossbar_arlock,
  input     [3 : 0] s_axi_from_sys_crossbar_arqos,

  output    [4 : 0] m_axi_dev_mem_awid,
  output   [63 : 0] m_axi_dev_mem_awaddr,
  output    [7 : 0] m_axi_dev_mem_awlen,
  output    [2 : 0] m_axi_dev_mem_awsize,
  output    [1 : 0] m_axi_dev_mem_awburst,
  output            m_axi_dev_mem_awlock,
  output    [3 : 0] m_axi_dev_mem_awqos,
  output    [3 : 0] m_axi_dev_mem_awregion,
  output    [3 : 0] m_axi_dev_mem_awcache,
  output    [2 : 0] m_axi_dev_mem_awprot,
  output            m_axi_dev_mem_awvalid,
  input             m_axi_dev_mem_awready,
  output  [511 : 0] m_axi_dev_mem_wdata,
  output   [63 : 0] m_axi_dev_mem_wstrb,
  output            m_axi_dev_mem_wlast,
  output            m_axi_dev_mem_wvalid,
  input             m_axi_dev_mem_wready,
  input     [4 : 0] m_axi_dev_mem_bid,
  input     [1 : 0] m_axi_dev_mem_bresp,
  input             m_axi_dev_mem_bvalid,
  output            m_axi_dev_mem_bready,
  output    [4 : 0] m_axi_dev_mem_arid,
  output   [63 : 0] m_axi_dev_mem_araddr,
  output    [7 : 0] m_axi_dev_mem_arlen,
  output    [2 : 0] m_axi_dev_mem_arsize,
  output    [1 : 0] m_axi_dev_mem_arburst,
  output            m_axi_dev_mem_arlock,
  output    [3 : 0] m_axi_dev_mem_arqos,
  output    [3 : 0] m_axi_dev_mem_arregion,
  output    [3 : 0] m_axi_dev_mem_arcache,
  output    [2 : 0] m_axi_dev_mem_arprot,
  output            m_axi_dev_mem_arvalid,
  input             m_axi_dev_mem_arready,
  input     [4 : 0] m_axi_dev_mem_rid,
  input   [511 : 0] m_axi_dev_mem_rdata,
  input     [1 : 0] m_axi_dev_mem_rresp,
  input             m_axi_dev_mem_rlast,
  input             m_axi_dev_mem_rvalid,
  output            m_axi_dev_mem_rready,

  input             axis_aclk,
  input             axis_arestn
);

localparam C_NUM_MASTERS = 3;

localparam C_QDMA_MM_IDX          = 0;
localparam C_COMPUTE_LOGIC_IDX    = 1;
localparam C_FROM_SYS_CROSSBAR_IDX  = 2;

logic   [C_NUM_MASTERS*5-1 : 0] axi_awid;
logic  [C_NUM_MASTERS*64-1 : 0] axi_awaddr;
logic   [C_NUM_MASTERS*8-1 : 0] axi_awlen;
logic   [C_NUM_MASTERS*3-1 : 0] axi_awsize;
logic   [C_NUM_MASTERS*2-1 : 0] axi_awburst;
logic     [C_NUM_MASTERS-1 : 0] axi_awlock;
logic   [C_NUM_MASTERS*4-1 : 0] axi_awcache;
logic   [C_NUM_MASTERS*3-1 : 0] axi_awprot;
logic   [C_NUM_MASTERS*4-1 : 0] axi_awqos;
logic     [C_NUM_MASTERS-1 : 0] axi_awvalid;
logic     [C_NUM_MASTERS-1 : 0] axi_awready;
logic [C_NUM_MASTERS*512-1 : 0] axi_wdata;
logic  [C_NUM_MASTERS*64-1 : 0] axi_wstrb;
logic     [C_NUM_MASTERS-1 : 0] axi_wlast;
logic     [C_NUM_MASTERS-1 : 0] axi_wvalid;
logic     [C_NUM_MASTERS-1 : 0] axi_wready;
logic   [C_NUM_MASTERS*5-1 : 0] axi_bid;
logic   [C_NUM_MASTERS*2-1 : 0] axi_bresp;
logic     [C_NUM_MASTERS-1 : 0] axi_bvalid;
logic     [C_NUM_MASTERS-1 : 0] axi_bready;
logic   [C_NUM_MASTERS*5-1 : 0] axi_arid;
logic  [C_NUM_MASTERS*64-1 : 0] axi_araddr;
logic   [C_NUM_MASTERS*8-1 : 0] axi_arlen;
logic   [C_NUM_MASTERS*3-1 : 0] axi_arsize;
logic   [C_NUM_MASTERS*2-1 : 0] axi_arburst;
logic     [C_NUM_MASTERS-1 : 0] axi_arlock;
logic   [C_NUM_MASTERS*4-1 : 0] axi_arcache;
logic   [C_NUM_MASTERS*3-1 : 0] axi_arprot;
logic   [C_NUM_MASTERS*4-1 : 0] axi_arqos;
logic     [C_NUM_MASTERS-1 : 0] axi_arvalid;
logic     [C_NUM_MASTERS-1 : 0] axi_arready;
logic   [C_NUM_MASTERS*5-1 : 0] axi_rid;
logic [C_NUM_MASTERS*512-1 : 0] axi_rdata;
logic   [C_NUM_MASTERS*2-1 : 0] axi_rresp;
logic     [C_NUM_MASTERS-1 : 0] axi_rlast;
logic     [C_NUM_MASTERS-1 : 0] axi_rvalid;
logic     [C_NUM_MASTERS-1 : 0] axi_rready;


// AXI slave signals for data access from qdma mm channel
//assign axi_awid   [C_QDMA_MM_IDX*2 +: 2]                = s_axi_qdma_mm_awid[1:0];
assign axi_awid   [C_QDMA_MM_IDX*5 +: 5]                = s_axi_qdma_mm_awvalid ? 5'd0 : 5'd0;
assign axi_awaddr [C_QDMA_MM_IDX *64 +: 64]             = s_axi_qdma_mm_awaddr;
assign axi_awqos  [C_QDMA_MM_IDX *4 +: 4]               = s_axi_qdma_mm_awqos;
assign axi_awlen  [C_QDMA_MM_IDX *8 +: 8]               = s_axi_qdma_mm_awlen;
assign axi_awsize [C_QDMA_MM_IDX *3 +: 3]               = s_axi_qdma_mm_awsize;
assign axi_awburst[C_QDMA_MM_IDX *2 +: 2]               = s_axi_qdma_mm_awburst;
assign axi_awcache[C_QDMA_MM_IDX *4 +: 4]               = s_axi_qdma_mm_awcache;
assign axi_awprot [C_QDMA_MM_IDX *3 +: 3]               = s_axi_qdma_mm_awprot;
assign axi_awvalid[C_QDMA_MM_IDX *1 +: 1]               = s_axi_qdma_mm_awvalid;
assign s_axi_qdma_mm_awready                            = axi_awready[C_QDMA_MM_IDX *1 +: 1];
assign axi_wdata  [C_QDMA_MM_IDX *512 +: 512]           = s_axi_qdma_mm_wdata;
assign axi_wstrb  [C_QDMA_MM_IDX *64 +: 64]             = s_axi_qdma_mm_wstrb;
assign axi_wlast  [C_QDMA_MM_IDX *1 +: 1]               = s_axi_qdma_mm_wlast;
assign axi_wvalid [C_QDMA_MM_IDX *1 +: 1]               = s_axi_qdma_mm_wvalid;
assign s_axi_qdma_mm_wready                             = axi_wready[C_QDMA_MM_IDX *1 +: 1];
assign axi_awlock [C_QDMA_MM_IDX *1 +: 1]               = s_axi_qdma_mm_awlock;
assign s_axi_qdma_mm_bid                                = axi_bid[C_QDMA_MM_IDX *5 +: 5];
assign s_axi_qdma_mm_bresp                              = axi_bresp[C_QDMA_MM_IDX *2 +: 2];
assign s_axi_qdma_mm_bvalid                             = axi_bvalid[C_QDMA_MM_IDX *1 +: 1];
assign axi_bready [C_QDMA_MM_IDX *1 +: 1]               = s_axi_qdma_mm_bready;
//assign axi_arid   [C_QDMA_MM_IDX *2 +: 2]               = s_axi_qdma_mm_arid[1:0];
assign axi_arid   [C_QDMA_MM_IDX *5 +: 5]               = s_axi_qdma_mm_arvalid ? 5'd0 : 5'd0;
assign axi_araddr [C_QDMA_MM_IDX *64 +: 64]             = s_axi_qdma_mm_araddr;
assign axi_arlen  [C_QDMA_MM_IDX *8  +: 8]              = s_axi_qdma_mm_arlen;
assign axi_arsize [C_QDMA_MM_IDX *3  +: 3]              = s_axi_qdma_mm_arsize;
assign axi_arburst[C_QDMA_MM_IDX *2  +: 2]              = s_axi_qdma_mm_arburst;
assign axi_arcache[C_QDMA_MM_IDX *4  +: 4]              = s_axi_qdma_mm_arcache;
assign axi_arprot [C_QDMA_MM_IDX *3  +: 3]              = s_axi_qdma_mm_arprot;
assign axi_arvalid[C_QDMA_MM_IDX *1  +: 1]              = s_axi_qdma_mm_arvalid;
assign s_axi_qdma_mm_arready                            = axi_arready[C_QDMA_MM_IDX *1 +: 1];
assign s_axi_qdma_mm_rid                                = axi_rid[C_QDMA_MM_IDX *5 +: 5];
assign s_axi_qdma_mm_rdata                              = axi_rdata[C_QDMA_MM_IDX *512 +: 512];
assign s_axi_qdma_mm_rresp                              = axi_rresp[C_QDMA_MM_IDX *2 +: 2];
assign s_axi_qdma_mm_rlast                              = axi_rlast[C_QDMA_MM_IDX *1 +: 1];
assign s_axi_qdma_mm_rvalid                             = axi_rvalid[C_QDMA_MM_IDX *1 +: 1];
assign axi_rready [C_QDMA_MM_IDX *1 +: 1]               = s_axi_qdma_mm_rready;
assign axi_arlock [C_QDMA_MM_IDX *1 +: 1]               = s_axi_qdma_mm_arlock;
assign axi_arqos  [C_QDMA_MM_IDX *4 +: 4]               = s_axi_qdma_mm_arqos;

// AXI slave signals for data access from compute logic
//assign axi_awid   [C_COMPUTE_LOGIC_IDX *2 +: 2]      = {1'b0, s_axi_compute_logic_awid};
assign axi_awid   [C_COMPUTE_LOGIC_IDX *5 +: 5]      = s_axi_compute_logic_awvalid ? 5'd4 : 5'd0;
assign axi_awaddr [C_COMPUTE_LOGIC_IDX *64 +: 64]    = s_axi_compute_logic_awaddr;
assign axi_awqos  [C_COMPUTE_LOGIC_IDX *4 +: 4]      = s_axi_compute_logic_awqos;
assign axi_awlen  [C_COMPUTE_LOGIC_IDX *8 +: 8]      = s_axi_compute_logic_awlen;
assign axi_awsize [C_COMPUTE_LOGIC_IDX *3 +: 3]      = s_axi_compute_logic_awsize;
assign axi_awburst[C_COMPUTE_LOGIC_IDX *2 +: 2]      = s_axi_compute_logic_awburst;
assign axi_awcache[C_COMPUTE_LOGIC_IDX *4 +: 4]      = s_axi_compute_logic_awcache;
assign axi_awprot [C_COMPUTE_LOGIC_IDX *3 +: 3]      = s_axi_compute_logic_awprot;
assign axi_awvalid[C_COMPUTE_LOGIC_IDX *1 +: 1]      = s_axi_compute_logic_awvalid;
assign s_axi_compute_logic_awready                   = axi_awready[C_COMPUTE_LOGIC_IDX *1 +: 1];
assign axi_wdata  [C_COMPUTE_LOGIC_IDX *512 +: 512]  = s_axi_compute_logic_wdata;
assign axi_wstrb  [C_COMPUTE_LOGIC_IDX *64 +: 64]    = s_axi_compute_logic_wstrb;
assign axi_wlast  [C_COMPUTE_LOGIC_IDX *1 +: 1]      = s_axi_compute_logic_wlast;
assign axi_wvalid [C_COMPUTE_LOGIC_IDX *1 +: 1]      = s_axi_compute_logic_wvalid;
assign s_axi_compute_logic_wready                    = axi_wready[C_COMPUTE_LOGIC_IDX *1 +: 1];
assign axi_awlock [C_COMPUTE_LOGIC_IDX *1 +: 1]      = s_axi_compute_logic_awlock;
assign s_axi_compute_logic_bid                       = axi_bid[C_COMPUTE_LOGIC_IDX *5 +: 5];
assign s_axi_compute_logic_bresp                     = axi_bresp[C_COMPUTE_LOGIC_IDX *2 +: 2];
assign s_axi_compute_logic_bvalid                    = axi_bvalid[C_COMPUTE_LOGIC_IDX *1 +: 1];
assign axi_bready [C_COMPUTE_LOGIC_IDX *1 +: 1]      = s_axi_compute_logic_bready;
//assign axi_arid   [C_COMPUTE_LOGIC_IDX *2 +: 2]      = {1'b0, s_axi_compute_logic_arid};
assign axi_arid   [C_COMPUTE_LOGIC_IDX *5 +: 5]      = s_axi_compute_logic_arvalid ? 5'd4 : 5'd4;
assign axi_araddr [C_COMPUTE_LOGIC_IDX *64 +: 64]    = s_axi_compute_logic_araddr;
assign axi_arlen  [C_COMPUTE_LOGIC_IDX *8  +: 8]     = s_axi_compute_logic_arlen;
assign axi_arsize [C_COMPUTE_LOGIC_IDX *3  +: 3]     = s_axi_compute_logic_arsize;
assign axi_arburst[C_COMPUTE_LOGIC_IDX *2  +: 2]     = s_axi_compute_logic_arburst;
assign axi_arcache[C_COMPUTE_LOGIC_IDX *4  +: 4]     = s_axi_compute_logic_arcache;
assign axi_arprot [C_COMPUTE_LOGIC_IDX *3  +: 3]     = s_axi_compute_logic_arprot;
assign axi_arvalid[C_COMPUTE_LOGIC_IDX *1  +: 1]     = s_axi_compute_logic_arvalid;
assign s_axi_compute_logic_arready                   = axi_arready[C_COMPUTE_LOGIC_IDX *1 +: 1];
assign s_axi_compute_logic_rid                       = axi_rid[C_COMPUTE_LOGIC_IDX *5 +: 5];
assign s_axi_compute_logic_rdata                     = axi_rdata[C_COMPUTE_LOGIC_IDX *512 +: 512];
assign s_axi_compute_logic_rresp                     = axi_rresp[C_COMPUTE_LOGIC_IDX *2 +: 2];
assign s_axi_compute_logic_rlast                     = axi_rlast[C_COMPUTE_LOGIC_IDX *1 +: 1];
assign s_axi_compute_logic_rvalid                    = axi_rvalid[C_COMPUTE_LOGIC_IDX *1 +: 1];
assign axi_rready [C_COMPUTE_LOGIC_IDX *1 +: 1]      = s_axi_compute_logic_rready;
assign axi_arlock [C_COMPUTE_LOGIC_IDX *1 +: 1]      = s_axi_compute_logic_arlock;
assign axi_arqos  [C_COMPUTE_LOGIC_IDX *4 +: 4]      = s_axi_compute_logic_arqos;

//s_axi_from_sys_crossbar_awid
assign axi_awid   [C_FROM_SYS_CROSSBAR_IDX *5 +: 5]      = s_axi_from_sys_crossbar_awvalid ? s_axi_from_sys_crossbar_awid : 5'd0;
assign axi_awaddr [C_FROM_SYS_CROSSBAR_IDX *64 +: 64]    = s_axi_from_sys_crossbar_awaddr;
assign axi_awqos  [C_FROM_SYS_CROSSBAR_IDX *4 +: 4]      = s_axi_from_sys_crossbar_awqos;
assign axi_awlen  [C_FROM_SYS_CROSSBAR_IDX *8 +: 8]      = s_axi_from_sys_crossbar_awlen;
assign axi_awsize [C_FROM_SYS_CROSSBAR_IDX *3 +: 3]      = s_axi_from_sys_crossbar_awsize;
assign axi_awburst[C_FROM_SYS_CROSSBAR_IDX *2 +: 2]      = s_axi_from_sys_crossbar_awburst;
assign axi_awcache[C_FROM_SYS_CROSSBAR_IDX *4 +: 4]      = s_axi_from_sys_crossbar_awcache;
assign axi_awprot [C_FROM_SYS_CROSSBAR_IDX *3 +: 3]      = s_axi_from_sys_crossbar_awprot;
assign axi_awvalid[C_FROM_SYS_CROSSBAR_IDX *1 +: 1]      = s_axi_from_sys_crossbar_awvalid;
assign s_axi_from_sys_crossbar_awready                   = axi_awready[C_FROM_SYS_CROSSBAR_IDX *1 +: 1];
assign axi_wdata  [C_FROM_SYS_CROSSBAR_IDX *512 +: 512]  = s_axi_from_sys_crossbar_wdata;
assign axi_wstrb  [C_FROM_SYS_CROSSBAR_IDX *64 +: 64]    = s_axi_from_sys_crossbar_wstrb;
assign axi_wlast  [C_FROM_SYS_CROSSBAR_IDX *1 +: 1]      = s_axi_from_sys_crossbar_wlast;
assign axi_wvalid [C_FROM_SYS_CROSSBAR_IDX *1 +: 1]      = s_axi_from_sys_crossbar_wvalid;
assign s_axi_from_sys_crossbar_wready                    = axi_wready[C_FROM_SYS_CROSSBAR_IDX *1 +: 1];
assign axi_awlock [C_FROM_SYS_CROSSBAR_IDX *1 +: 1]      = s_axi_from_sys_crossbar_awlock;
assign s_axi_from_sys_crossbar_bid                       = axi_bid[C_FROM_SYS_CROSSBAR_IDX *5 +: 5];
assign s_axi_from_sys_crossbar_bresp                     = axi_bresp[C_FROM_SYS_CROSSBAR_IDX *2 +: 2];
assign s_axi_from_sys_crossbar_bvalid                    = axi_bvalid[C_FROM_SYS_CROSSBAR_IDX *1 +: 1];
assign axi_bready [C_FROM_SYS_CROSSBAR_IDX *1 +: 1]      = s_axi_from_sys_crossbar_bready;
//assign axi_arid   [C_FROM_SYS_CROSSBAR_IDX *2 +: 2]      = {1'b0, s_axi_from_sys_crossbar_arid};
assign axi_arid   [C_FROM_SYS_CROSSBAR_IDX *5 +: 5]      = s_axi_from_sys_crossbar_arvalid ? s_axi_from_sys_crossbar_arid : 5'd0;
//assign axi_arid   [C_FROM_SYS_CROSSBAR_IDX *3 +: 3]      = 3'd3;
assign axi_araddr [C_FROM_SYS_CROSSBAR_IDX *64 +: 64]    = s_axi_from_sys_crossbar_araddr;
assign axi_arlen  [C_FROM_SYS_CROSSBAR_IDX *8  +: 8]     = s_axi_from_sys_crossbar_arlen;
assign axi_arsize [C_FROM_SYS_CROSSBAR_IDX *3  +: 3]     = s_axi_from_sys_crossbar_arsize;
assign axi_arburst[C_FROM_SYS_CROSSBAR_IDX *2  +: 2]     = s_axi_from_sys_crossbar_arburst;
assign axi_arcache[C_FROM_SYS_CROSSBAR_IDX *4  +: 4]     = s_axi_from_sys_crossbar_arcache;
assign axi_arprot [C_FROM_SYS_CROSSBAR_IDX *3  +: 3]     = s_axi_from_sys_crossbar_arprot;
assign axi_arvalid[C_FROM_SYS_CROSSBAR_IDX *1  +: 1]     = s_axi_from_sys_crossbar_arvalid;
assign s_axi_from_sys_crossbar_arready                   = axi_arready[C_FROM_SYS_CROSSBAR_IDX *1 +: 1];
assign s_axi_from_sys_crossbar_rid                       = axi_rid[C_FROM_SYS_CROSSBAR_IDX *5 +: 5];
assign s_axi_from_sys_crossbar_rdata                     = axi_rdata[C_FROM_SYS_CROSSBAR_IDX *512 +: 512];
assign s_axi_from_sys_crossbar_rresp                     = axi_rresp[C_FROM_SYS_CROSSBAR_IDX *2 +: 2];
assign s_axi_from_sys_crossbar_rlast                     = axi_rlast[C_FROM_SYS_CROSSBAR_IDX *1 +: 1];
assign s_axi_from_sys_crossbar_rvalid                    = axi_rvalid[C_FROM_SYS_CROSSBAR_IDX *1 +: 1];
assign axi_rready [C_FROM_SYS_CROSSBAR_IDX *1 +: 1]      = s_axi_from_sys_crossbar_rready;
assign axi_arlock [C_FROM_SYS_CROSSBAR_IDX *1 +: 1]      = s_axi_from_sys_crossbar_arlock;
assign axi_arqos  [C_FROM_SYS_CROSSBAR_IDX *4 +: 4]      = s_axi_from_sys_crossbar_arqos;

dev_mem_3to1_axi_crossbar dev_mem_3to1_axi_crossbar_inst (
  // Master interface only has 4-bit ID width
  .m_axi_awaddr    (m_axi_dev_mem_awaddr),
  .m_axi_awprot    (m_axi_dev_mem_awprot),
  .m_axi_awvalid   (m_axi_dev_mem_awvalid),
  .m_axi_awready   (m_axi_dev_mem_awready),
  .m_axi_awsize    (m_axi_dev_mem_awsize),
  .m_axi_awburst   (m_axi_dev_mem_awburst),
  .m_axi_awcache   (m_axi_dev_mem_awcache),
  .m_axi_awlen     (m_axi_dev_mem_awlen),
  .m_axi_awlock    (m_axi_dev_mem_awlock),
  .m_axi_awqos     (m_axi_dev_mem_awqos),
  .m_axi_awregion  (m_axi_dev_mem_awregion),
  .m_axi_awid      (m_axi_dev_mem_awid),
  .m_axi_wdata     (m_axi_dev_mem_wdata),
  .m_axi_wstrb     (m_axi_dev_mem_wstrb),
  .m_axi_wvalid    (m_axi_dev_mem_wvalid),
  .m_axi_wready    (m_axi_dev_mem_wready),
  .m_axi_wlast     (m_axi_dev_mem_wlast),
  .m_axi_bresp     (m_axi_dev_mem_bresp),
  .m_axi_bvalid    (m_axi_dev_mem_bvalid),
  .m_axi_bready    (m_axi_dev_mem_bready),
  .m_axi_bid       (m_axi_dev_mem_bid),
  .m_axi_araddr    (m_axi_dev_mem_araddr),
  .m_axi_arprot    (m_axi_dev_mem_arprot),
  .m_axi_arvalid   (m_axi_dev_mem_arvalid),
  .m_axi_arready   (m_axi_dev_mem_arready),
  .m_axi_arsize    (m_axi_dev_mem_arsize),
  .m_axi_arburst   (m_axi_dev_mem_arburst),
  .m_axi_arcache   (m_axi_dev_mem_arcache),
  .m_axi_arlock    (m_axi_dev_mem_arlock),
  .m_axi_arlen     (m_axi_dev_mem_arlen),
  .m_axi_arqos     (m_axi_dev_mem_arqos),
  .m_axi_arregion  (m_axi_dev_mem_arregion),
  .m_axi_arid      (m_axi_dev_mem_arid),
  .m_axi_rdata     (m_axi_dev_mem_rdata),
  .m_axi_rresp     (m_axi_dev_mem_rresp),
  .m_axi_rvalid    (m_axi_dev_mem_rvalid),
  .m_axi_rready    (m_axi_dev_mem_rready),
  .m_axi_rlast     (m_axi_dev_mem_rlast),
  .m_axi_rid       (m_axi_dev_mem_rid),

  // Slave interface has 12-bit ID width
  .s_axi_awid      (axi_awid),
  .s_axi_awaddr    (axi_awaddr),
  .s_axi_awqos     (axi_awqos),
  .s_axi_awlen     (axi_awlen),
  .s_axi_awsize    (axi_awsize),
  .s_axi_awburst   (axi_awburst),
  .s_axi_awcache   (axi_awcache),
  .s_axi_awprot    (axi_awprot),
  .s_axi_awvalid   (axi_awvalid),
  .s_axi_awready   (axi_awready),
  .s_axi_wdata     (axi_wdata),
  .s_axi_wstrb     (axi_wstrb),
  .s_axi_wlast     (axi_wlast),
  .s_axi_wvalid    (axi_wvalid),
  .s_axi_wready    (axi_wready),
  .s_axi_awlock    (axi_awlock),
  .s_axi_bid       (axi_bid),
  .s_axi_bresp     (axi_bresp),
  .s_axi_bvalid    (axi_bvalid),
  .s_axi_bready    (axi_bready),
  .s_axi_arid      (axi_arid),
  .s_axi_araddr    (axi_araddr),
  .s_axi_arlen     (axi_arlen),
  .s_axi_arsize    (axi_arsize),
  .s_axi_arburst   (axi_arburst),
  .s_axi_arcache   (axi_arcache),
  .s_axi_arprot    (axi_arprot),
  .s_axi_arvalid   (axi_arvalid),
  .s_axi_arready   (axi_arready),
  .s_axi_rid       (axi_rid),
  .s_axi_rdata     (axi_rdata),
  .s_axi_rresp     (axi_rresp),
  .s_axi_rlast     (axi_rlast),
  .s_axi_rvalid    (axi_rvalid),
  .s_axi_rready    (axi_rready),
  .s_axi_arlock    (axi_arlock),
  .s_axi_arqos     (axi_arqos),

  .aclk   (axis_aclk),
  .aresetn(axis_arestn)
);

endmodule: axi_3to1_interconnect_to_dev_mem