// *************************************************************************
//
// Copyright 2020 Xilinx, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// *************************************************************************
// This module wraps up the QDMA IP.  It creates two clock domains: one for the
// data path running at 250MHz, and the other for the AXI-Lite register
// interface running at 125MHz.
`timescale 1ns/1ps
module qdma_subsystem_qdma_wrapper (
  input   [15:0] pcie_rxp,
  input   [15:0] pcie_rxn,
  output  [15:0] pcie_txp,
  output  [15:0] pcie_txn,

  output         m_axil_awvalid,
  output  [31:0] m_axil_awaddr,
  input          m_axil_awready,
  output         m_axil_wvalid,
  output  [31:0] m_axil_wdata,
  input          m_axil_wready,
  input          m_axil_bvalid,
  input    [1:0] m_axil_bresp,
  output         m_axil_bready,
  output         m_axil_arvalid,
  output  [31:0] m_axil_araddr,
  input          m_axil_arready,
  input          m_axil_rvalid,
  input   [31:0] m_axil_rdata,
  input    [1:0] m_axil_rresp,
  output         m_axil_rready,

  input          m_axi_awready,
  input          m_axi_wready,
  input  [3:0]   m_axi_bid,
  input  [1:0]   m_axi_bresp,
  input          m_axi_bvalid,
  input          m_axi_arready,
  input  [3:0]   m_axi_rid,
  input  [511:0] m_axi_rdata,
  input  [1:0]   m_axi_rresp,
  input          m_axi_rlast,
  input          m_axi_rvalid,
  output [3:0]   m_axi_awid,
  output [63:0]  m_axi_awaddr,
  output [31:0]  m_axi_awuser,
  output [7:0]   m_axi_awlen,
  output [2:0]   m_axi_awsize,
  output [1:0]   m_axi_awburst,
  output [2:0]   m_axi_awprot,
  output         m_axi_awvalid,
  output         m_axi_awlock,
  output [3:0]   m_axi_awcache,
  output [511:0] m_axi_wdata,
  output [63:0]  m_axi_wuser,
  output [63:0]  m_axi_wstrb,
  output         m_axi_wlast,
  output         m_axi_wvalid,
  output         m_axi_bready,
  output [3:0]   m_axi_arid,
  output [63:0]  m_axi_araddr,
  output [31:0]  m_axi_aruser,
  output [7:0]   m_axi_arlen,
  output [2:0]   m_axi_arsize,
  output [1:0]   m_axi_arburst,
  output [2:0]   m_axi_arprot,
  output         m_axi_arvalid,
  output         m_axi_arlock,
  output [3:0]   m_axi_arcache,
  output         m_axi_rready,

  output         m_axis_h2c_tvalid,
  output [511:0] m_axis_h2c_tdata,
  output  [31:0] m_axis_h2c_tcrc,
  output         m_axis_h2c_tlast,
  output  [10:0] m_axis_h2c_tuser_qid,
  output   [2:0] m_axis_h2c_tuser_port_id,
  output         m_axis_h2c_tuser_err,
  output  [31:0] m_axis_h2c_tuser_mdata,
  output   [5:0] m_axis_h2c_tuser_mty,
  output         m_axis_h2c_tuser_zero_byte,
  input          m_axis_h2c_tready,

  input          s_axis_c2h_tvalid,
  input  [511:0] s_axis_c2h_tdata,
  input   [31:0] s_axis_c2h_tcrc,
  input          s_axis_c2h_tlast,
  input          s_axis_c2h_ctrl_marker,
  input    [2:0] s_axis_c2h_ctrl_port_id,
  input    [6:0] s_axis_c2h_ctrl_ecc,
  input   [15:0] s_axis_c2h_ctrl_len,
  input   [10:0] s_axis_c2h_ctrl_qid,
  input          s_axis_c2h_ctrl_has_cmpt,
  input    [5:0] s_axis_c2h_mty,
  output         s_axis_c2h_tready,

  input          s_axis_cpl_tvalid,
  input  [511:0] s_axis_cpl_tdata,
  input    [1:0] s_axis_cpl_size,
  input   [15:0] s_axis_cpl_dpar,
  input   [10:0] s_axis_cpl_ctrl_qid,
  input    [1:0] s_axis_cpl_ctrl_cmpt_type,
  input   [15:0] s_axis_cpl_ctrl_wait_pld_pkt_id,
  input    [2:0] s_axis_cpl_ctrl_port_id,
  input          s_axis_cpl_ctrl_marker,
  input          s_axis_cpl_ctrl_user_trig,
  input    [2:0] s_axis_cpl_ctrl_col_idx,
  input    [2:0] s_axis_cpl_ctrl_err_idx,
  input          s_axis_cpl_ctrl_no_wrb_marker,
  output         s_axis_cpl_tready,

  output         h2c_byp_out_vld,
  output [255:0] h2c_byp_out_dsc,
  output         h2c_byp_out_st_mm,
  output   [1:0] h2c_byp_out_dsc_sz,
  output  [10:0] h2c_byp_out_qid,
  output         h2c_byp_out_error,
  output   [7:0] h2c_byp_out_func,
  output  [15:0] h2c_byp_out_cidx,
  output   [2:0] h2c_byp_out_port_id,
  output   [3:0] h2c_byp_out_fmt,
  input          h2c_byp_out_rdy,

  input          h2c_byp_in_st_vld,
  input   [63:0] h2c_byp_in_st_addr,
  input   [15:0] h2c_byp_in_st_len,
  input          h2c_byp_in_st_eop,
  input          h2c_byp_in_st_sop,
  input          h2c_byp_in_st_mrkr_req,
  input    [2:0] h2c_byp_in_st_port_id,
  input          h2c_byp_in_st_sdi,
  input   [10:0] h2c_byp_in_st_qid,
  input          h2c_byp_in_st_error,
  input    [7:0] h2c_byp_in_st_func,
  input   [15:0] h2c_byp_in_st_cidx,
  input          h2c_byp_in_st_no_dma,
  output         h2c_byp_in_st_rdy,

  input  [63:0]  h2c_byp_in_mm_radr,
  input  [63:0]  h2c_byp_in_mm_wadr,
  input  [15:0]  h2c_byp_in_mm_len,
  input          h2c_byp_in_mm_mrkr_req,
  input  [2:0]   h2c_byp_in_mm_port_id,
  input          h2c_byp_in_mm_sdi,
  input  [10:0]  h2c_byp_in_mm_qid,
  input          h2c_byp_in_mm_error,
  input  [7:0]   h2c_byp_in_mm_func,
  input  [15:0]  h2c_byp_in_mm_cidx,
  input          h2c_byp_in_mm_no_dma,
  input          h2c_byp_in_mm_vld,
  output         h2c_byp_in_mm_rdy,

  output         c2h_byp_out_vld,
  output [255:0] c2h_byp_out_dsc,
  output         c2h_byp_out_st_mm,
  output  [10:0] c2h_byp_out_qid,
  output   [1:0] c2h_byp_out_dsc_sz,
  output         c2h_byp_out_error,
  output   [7:0] c2h_byp_out_func,
  output  [15:0] c2h_byp_out_cidx,
  output   [2:0] c2h_byp_out_port_id,
  output   [3:0] c2h_byp_out_fmt,
  output   [6:0] c2h_byp_out_pfch_tag,
  input          c2h_byp_out_rdy,

  input          c2h_byp_in_st_csh_vld,
  input   [63:0] c2h_byp_in_st_csh_addr,
  input    [2:0] c2h_byp_in_st_csh_port_id,
  input   [10:0] c2h_byp_in_st_csh_qid,
  input          c2h_byp_in_st_csh_error,
  input    [7:0] c2h_byp_in_st_csh_func,
  input    [6:0] c2h_byp_in_st_csh_pfch_tag,
  output         c2h_byp_in_st_csh_rdy,

  input   [63:0] c2h_byp_in_mm_radr,
  input   [63:0] c2h_byp_in_mm_wadr,
  input   [15:0] c2h_byp_in_mm_len,
  input          c2h_byp_in_mm_mrkr_req,
  input   [2:0]  c2h_byp_in_mm_port_id,
  input          c2h_byp_in_mm_sdi,
  input   [10:0] c2h_byp_in_mm_qid,
  input          c2h_byp_in_mm_error,
  input   [7:0]  c2h_byp_in_mm_func,
  input   [15:0] c2h_byp_in_mm_cidx,
  input          c2h_byp_in_mm_vld,
  input          c2h_byp_in_mm_no_dma,
  output         c2h_byp_in_mm_rdy,

  // QDMA control/status register interface
  output         s_csr_prog_done,
  input   [31:0] s_axil_csr_awaddr,
  input    [2:0] s_axil_csr_awprot,
  input          s_axil_csr_awvalid,
  output         s_axil_csr_awready,
  input   [31:0] s_axil_csr_wdata,
  input   [3:0]  s_axil_csr_wstrb,
  input          s_axil_csr_wvalid,
  output         s_axil_csr_wready,
  output         s_axil_csr_bvalid,
  output   [1:0] s_axil_csr_bresp,
  input          s_axil_csr_bready,
  input   [31:0] s_axil_csr_araddr,
  input    [2:0] s_axil_csr_arprot,
  input          s_axil_csr_arvalid,
  output         s_axil_csr_arready,
  output  [31:0] s_axil_csr_rdata,
  output   [1:0] s_axil_csr_rresp,
  output         s_axil_csr_rvalid,
  input          s_axil_csr_rready,

  // QDMA bridge slave interface
  (* mark_debug = "true" *) input    [3:0] s_axib_awid,
  (* mark_debug = "true" *) input   [63:0] s_axib_awaddr,
  (* mark_debug = "true" *) input    [3:0] s_axib_awregion,
  (* mark_debug = "true" *) input    [7:0] s_axib_awlen,
  (* mark_debug = "true" *) input    [2:0] s_axib_awsize,
  (* mark_debug = "true" *) input    [1:0] s_axib_awburst,
  (* mark_debug = "true" *) input          s_axib_awvalid,
  (* mark_debug = "true" *) input  [511:0] s_axib_wdata,
  (* mark_debug = "true" *) input   [63:0] s_axib_wstrb,
  (* mark_debug = "true" *) input          s_axib_wlast,
  (* mark_debug = "true" *) input          s_axib_wvalid,
  (* mark_debug = "true" *) input   [63:0] s_axib_wuser,
  (* mark_debug = "true" *) output  [63:0] s_axib_ruser,
  (* mark_debug = "true" *) input          s_axib_bready,
  (* mark_debug = "true" *) input    [3:0] s_axib_arid,
  (* mark_debug = "true" *) input   [63:0] s_axib_araddr,
  (* mark_debug = "true" *) input   [11:0] s_axib_aruser,
  (* mark_debug = "true" *) input   [11:0] s_axib_awuser,
  (* mark_debug = "true" *) input    [3:0] s_axib_arregion,
  (* mark_debug = "true" *) input    [7:0] s_axib_arlen,
  (* mark_debug = "true" *) input    [2:0] s_axib_arsize,
  (* mark_debug = "true" *) input    [1:0] s_axib_arburst,
  (* mark_debug = "true" *) input          s_axib_arvalid,
  (* mark_debug = "true" *) input          s_axib_rready,
  (* mark_debug = "true" *) output         s_axib_awready,
  (* mark_debug = "true" *) output         s_axib_wready,
  (* mark_debug = "true" *) output   [3:0] s_axib_bid,
  (* mark_debug = "true" *) output   [1:0] s_axib_bresp,
  (* mark_debug = "true" *) output         s_axib_bvalid,
  (* mark_debug = "true" *) output         s_axib_arready,
  (* mark_debug = "true" *) output   [3:0] s_axib_rid,
  (* mark_debug = "true" *) output [511:0] s_axib_rdata,
  (* mark_debug = "true" *) output   [1:0] s_axib_rresp,
  (* mark_debug = "true" *) output         s_axib_rlast,
  (* mark_debug = "true" *) output         s_axib_rvalid,

  input          pcie_refclk,
  input          pcie_refclk_gt,
  input          pcie_rstn,

  output         user_lnk_up,
  output         phy_ready,
  input          soft_reset_n,

  output         axis_aclk,
  output         axil_aclk,

// For AU55N, AU55C, AU50, and AU280, we generate 100MHz reference clock which is needed when HBM IP is instantiated 
// in user-defined logic.

`ifdef __au55n__
  output         ref_clk_100mhz,
`elsif __au55c__
  output         ref_clk_100mhz,
`elsif __au50__
  output         ref_clk_100mhz,
`elsif __au280__
  output         ref_clk_100mhz,    
`endif

  output         aresetn
);

  // 250MHz clock generated by QDMA IP
  wire        aclk_250mhz;
  wire        aresetn_250mhz;

  reg   [1:0] aresetn_sync = 2'b11;

  (* mark_debug = "true" *) wire         qdma_csr_prog_done;
  (* mark_debug = "true" *) wire  [31:0] qdma_axil_csr_awaddr;
  (* mark_debug = "true" *) wire   [2:0] qdma_axil_csr_awprot;
  (* mark_debug = "true" *) wire         qdma_axil_csr_awvalid;
  (* mark_debug = "true" *) wire         qdma_axil_csr_awready;
  (* mark_debug = "true" *) wire  [31:0] qdma_axil_csr_wdata;
  (* mark_debug = "true" *) wire  [3:0]  qdma_axil_csr_wstrb;
  (* mark_debug = "true" *) wire         qdma_axil_csr_wvalid;
  (* mark_debug = "true" *) wire         qdma_axil_csr_wready;
  (* mark_debug = "true" *) wire         qdma_axil_csr_bvalid;
  (* mark_debug = "true" *) wire   [1:0] qdma_axil_csr_bresp;
  (* mark_debug = "true" *) wire         qdma_axil_csr_bready;
  (* mark_debug = "true" *) wire  [31:0] qdma_axil_csr_araddr;
  (* mark_debug = "true" *) wire   [2:0] qdma_axil_csr_arprot;
  (* mark_debug = "true" *) wire         qdma_axil_csr_arvalid;
  (* mark_debug = "true" *) wire         qdma_axil_csr_arready;
  (* mark_debug = "true" *) wire  [31:0] qdma_axil_csr_rdata;
  (* mark_debug = "true" *) wire   [1:0] qdma_axil_csr_rresp;
  (* mark_debug = "true" *) wire         qdma_axil_csr_rvalid;
  (* mark_debug = "true" *) wire         qdma_axil_csr_rready;

  wire        qdma_axil_awvalid;
  wire [31:0] qdma_axil_awaddr;
  wire  [2:0] qdma_axil_awprot;
  wire        qdma_axil_awready;
  wire        qdma_axil_wvalid;
  wire [31:0] qdma_axil_wdata;
  wire        qdma_axil_wready;
  wire        qdma_axil_bvalid;
  wire  [1:0] qdma_axil_bresp;
  wire        qdma_axil_bready;
  wire        qdma_axil_arvalid;
  wire [31:0] qdma_axil_araddr;
  wire  [2:0] qdma_axil_arprot;
  wire        qdma_axil_arready;
  wire        qdma_axil_rvalid;
  wire [31:0] qdma_axil_rdata;
  wire  [1:0] qdma_axil_rresp;
  wire        qdma_axil_rready;

  wire        usr_irq_in_vld;
  wire  [4:0] usr_irq_in_vec;
  wire  [7:0] usr_irq_in_fnc;
  wire        usr_irq_out_ack;
  wire        usr_irq_out_fail;

  wire        tm_dsc_sts_vld;
  wire  [2:0] tm_dsc_sts_port_id;
  wire        tm_dsc_sts_qen;
  wire        tm_dsc_sts_byp;
  wire        tm_dsc_sts_dir;
  wire        tm_dsc_sts_mm;
  wire        tm_dsc_sts_error;
  wire [10:0] tm_dsc_sts_qid;
  wire [15:0] tm_dsc_sts_avl;
  wire        tm_dsc_sts_qinv;
  wire        tm_dsc_sts_irq_arm;
  wire [15:0] tm_dsc_sts_pidx;
  wire        tm_dsc_sts_rdy;

  wire        dsc_crdt_in_vld;
  wire [15:0] dsc_crdt_in_crdt;
  wire [10:0] dsc_crdt_in_qid;
  wire        dsc_crdt_in_dir;
  wire        dsc_crdt_in_fence;
  wire        dsc_crdt_in_rdy;

  assign axis_aclk = aclk_250mhz;

  // Generate 125MHz 'axil_aclk'
  qdma_subsystem_clk_div clk_div_inst (
    .clk_in1  (axis_aclk),
    .clk_out1 (axil_aclk),
    .locked   ()
  );

  // Generate reset w.r.t. the 125MHz clock
  assign aresetn = aresetn_sync[1];
  always @(posedge axil_aclk) begin
    aresetn_sync[0] <= aresetn_250mhz;
    aresetn_sync[1] <= aresetn_sync[0];
  end

  // Convert the 250MHz QDMA output AXI-Lite interface to a 125MHz one
  qdma_subsystem_axi_cdc axi_cdc_inst (
    .s_axi_awvalid (qdma_axil_awvalid),
    .s_axi_awaddr  (qdma_axil_awaddr),
    .s_axi_awprot  (0),
    .s_axi_awready (qdma_axil_awready),
    .s_axi_wvalid  (qdma_axil_wvalid),
    .s_axi_wdata   (qdma_axil_wdata),
    .s_axi_wstrb   (4'hF),
    .s_axi_wready  (qdma_axil_wready),
    .s_axi_bvalid  (qdma_axil_bvalid),
    .s_axi_bresp   (qdma_axil_bresp),
    .s_axi_bready  (qdma_axil_bready),
    .s_axi_arvalid (qdma_axil_arvalid),
    .s_axi_araddr  (qdma_axil_araddr),
    .s_axi_arprot  (0),
    .s_axi_arready (qdma_axil_arready),
    .s_axi_rvalid  (qdma_axil_rvalid),
    .s_axi_rdata   (qdma_axil_rdata),
    .s_axi_rresp   (qdma_axil_rresp),
    .s_axi_rready  (qdma_axil_rready),

    .m_axi_awvalid (m_axil_awvalid),
    .m_axi_awaddr  (m_axil_awaddr),
    .m_axi_awprot  (),
    .m_axi_awready (m_axil_awready),
    .m_axi_wvalid  (m_axil_wvalid),
    .m_axi_wdata   (m_axil_wdata),
    .m_axi_wstrb   (),
    .m_axi_wready  (m_axil_wready),
    .m_axi_bvalid  (m_axil_bvalid),
    .m_axi_bresp   (m_axil_bresp),
    .m_axi_bready  (m_axil_bready),
    .m_axi_arvalid (m_axil_arvalid),
    .m_axi_araddr  (m_axil_araddr),
    .m_axi_arprot  (),
    .m_axi_arready (m_axil_arready),
    .m_axi_rvalid  (m_axil_rvalid),
    .m_axi_rdata   (m_axil_rdata),
    .m_axi_rresp   (m_axil_rresp),
    .m_axi_rready  (m_axil_rready),

    .s_axi_aclk    (axis_aclk),
    .s_axi_aresetn (aresetn_250mhz),
    .m_axi_aclk    (axil_aclk),
    .m_axi_aresetn (aresetn)
  );

  qdma_subsystem_axi_csr_cdc axi_csr_cdc_inst (
    .s_axi_awvalid (s_axil_csr_awvalid),
    .s_axi_awaddr  (s_axil_csr_awaddr),
    .s_axi_awprot  (s_axil_csr_awprot),
    .s_axi_awready (s_axil_csr_awready),
    .s_axi_wvalid  (s_axil_csr_wvalid),
    .s_axi_wdata   (s_axil_csr_wdata),
    .s_axi_wstrb   (s_axil_csr_wstrb),
    .s_axi_wready  (s_axil_csr_wready),
    .s_axi_bvalid  (s_axil_csr_bvalid),
    .s_axi_bresp   (s_axil_csr_bresp),
    .s_axi_bready  (s_axil_csr_bready),
    .s_axi_arvalid (s_axil_csr_arvalid),
    .s_axi_araddr  (s_axil_csr_araddr),
    .s_axi_arprot  (s_axil_csr_arprot),
    .s_axi_arready (s_axil_csr_arready),
    .s_axi_rvalid  (s_axil_csr_rvalid),
    .s_axi_rdata   (s_axil_csr_rdata),
    .s_axi_rresp   (s_axil_csr_rresp),
    .s_axi_rready  (s_axil_csr_rready),

    .m_axi_awvalid (qdma_axil_csr_awvalid),
    .m_axi_awaddr  (qdma_axil_csr_awaddr),
    .m_axi_awprot  (qdma_axil_csr_awprot),
    .m_axi_awready (qdma_axil_csr_awready),
    .m_axi_wvalid  (qdma_axil_csr_wvalid),
    .m_axi_wdata   (qdma_axil_csr_wdata),
    .m_axi_wstrb   (qdma_axil_csr_wstrb),
    .m_axi_wready  (qdma_axil_csr_wready),
    .m_axi_bvalid  (qdma_axil_csr_bvalid),
    .m_axi_bresp   (qdma_axil_csr_bresp),
    .m_axi_bready  (qdma_axil_csr_bready),
    .m_axi_arvalid (qdma_axil_csr_arvalid),
    .m_axi_araddr  (qdma_axil_csr_araddr),
    .m_axi_arprot  (qdma_axil_csr_arprot),
    .m_axi_arready (qdma_axil_csr_arready),
    .m_axi_rvalid  (qdma_axil_csr_rvalid),
    .m_axi_rdata   (qdma_axil_csr_rdata),
    .m_axi_rresp   (qdma_axil_csr_rresp),
    .m_axi_rready  (qdma_axil_csr_rready),

    .s_axi_aclk    (axil_aclk),
    .s_axi_aresetn (aresetn),
    .m_axi_aclk    (axis_aclk),
    .m_axi_aresetn (aresetn_250mhz)
  );

  // Convert signals @ axis_aclk to axil_aclk
  xpm_cdc_single #(
    .DEST_SYNC_FF(4), // DECIMAL; range: 2-10
    .INIT_SYNC_FF(0), // DECIMAL; 0=disable simulation init values, 1=enable simulation init values
    .SIM_ASSERT_CHK(1), // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
    .SRC_INPUT_REG(1) // DECIMAL; 0=do not register input, 1=register input
  ) roce_pkt_recved_cdc (
    .dest_out(s_csr_prog_done),
    .dest_clk(axil_aclk),
    .src_clk(axis_aclk),
    .src_in(qdma_csr_prog_done)
  );

  assign usr_irq_in_vld    = 1'b0;
  assign usr_irq_in_vec    = 0;
  assign usr_irq_in_fnc    = 0;

  assign tm_dsc_sts_rdy    = 1'b1;

  assign dsc_crdt_in_vld   = 1'b0;
  assign dsc_crdt_in_crdt  = 0;
  assign dsc_crdt_in_qid   = 0;
  assign dsc_crdt_in_dir   = 1'b0;
  assign dsc_crdt_in_fence = 1'b0;

  qdma_no_sriov qdma_inst (
    .pci_exp_rxp                          (pcie_rxp),
    .pci_exp_rxn                          (pcie_rxn),
    .pci_exp_txp                          (pcie_txp),
    .pci_exp_txn                          (pcie_txn),

    .sys_clk                              (pcie_refclk),
    .sys_clk_gt                           (pcie_refclk_gt),
    .sys_rst_n                            (pcie_rstn),
    .user_lnk_up                          (user_lnk_up),

    .axi_aclk                             (aclk_250mhz),
    .axi_aresetn                          (aresetn_250mhz),

    .m_axil_awvalid                       (qdma_axil_awvalid),
    .m_axil_awaddr                        (qdma_axil_awaddr),
    .m_axil_awuser                        (),
    .m_axil_awprot                        (),
    .m_axil_awready                       (qdma_axil_awready),
    .m_axil_wvalid                        (qdma_axil_wvalid),
    .m_axil_wdata                         (qdma_axil_wdata),
    .m_axil_wstrb                         (),
    .m_axil_wready                        (qdma_axil_wready),
    .m_axil_bvalid                        (qdma_axil_bvalid),
    .m_axil_bresp                         (qdma_axil_bresp),
    .m_axil_bready                        (qdma_axil_bready),
    .m_axil_arvalid                       (qdma_axil_arvalid),
    .m_axil_araddr                        (qdma_axil_araddr),
    .m_axil_aruser                        (),
    .m_axil_arprot                        (),
    .m_axil_arready                       (qdma_axil_arready),
    .m_axil_rvalid                        (qdma_axil_rvalid),
    .m_axil_rdata                         (qdma_axil_rdata),
    .m_axil_rresp                         (qdma_axil_rresp),
    .m_axil_rready                        (qdma_axil_rready),

    .h2c_byp_out_vld                      (h2c_byp_out_vld),
    .h2c_byp_out_dsc                      (h2c_byp_out_dsc),
    .h2c_byp_out_st_mm                    (h2c_byp_out_st_mm),
    .h2c_byp_out_dsc_sz                   (h2c_byp_out_dsc_sz),
    .h2c_byp_out_qid                      (h2c_byp_out_qid),
    .h2c_byp_out_error                    (h2c_byp_out_error),
    .h2c_byp_out_func                     (h2c_byp_out_func),
    .h2c_byp_out_cidx                     (h2c_byp_out_cidx),
    .h2c_byp_out_port_id                  (h2c_byp_out_port_id),
    .h2c_byp_out_fmt                      (h2c_byp_out_fmt),
    .h2c_byp_out_rdy                      (h2c_byp_out_rdy),

    .h2c_byp_in_st_vld                    (h2c_byp_in_st_vld),
    .h2c_byp_in_st_addr                   (h2c_byp_in_st_addr),
    .h2c_byp_in_st_len                    (h2c_byp_in_st_len),
    .h2c_byp_in_st_eop                    (h2c_byp_in_st_eop),
    .h2c_byp_in_st_sop                    (h2c_byp_in_st_sop),
    .h2c_byp_in_st_mrkr_req               (h2c_byp_in_st_mrkr_req),
    .h2c_byp_in_st_port_id                (h2c_byp_in_st_port_id),
    .h2c_byp_in_st_sdi                    (h2c_byp_in_st_sdi),
    .h2c_byp_in_st_qid                    (h2c_byp_in_st_qid),
    .h2c_byp_in_st_error                  (h2c_byp_in_st_error),
    .h2c_byp_in_st_func                   (h2c_byp_in_st_func),
    .h2c_byp_in_st_cidx                   (h2c_byp_in_st_cidx),
    .h2c_byp_in_st_no_dma                 (h2c_byp_in_st_no_dma),
    .h2c_byp_in_st_rdy                    (h2c_byp_in_st_rdy),

    .h2c_byp_in_mm_radr                   (h2c_byp_in_mm_radr),
    .h2c_byp_in_mm_wadr                   (h2c_byp_in_mm_wadr),
    .h2c_byp_in_mm_len                    (h2c_byp_in_mm_len),
    .h2c_byp_in_mm_mrkr_req               (h2c_byp_in_mm_mrkr_req),
    .h2c_byp_in_mm_port_id                (h2c_byp_in_mm_port_id),
    .h2c_byp_in_mm_sdi                    (h2c_byp_in_mm_sdi),
    .h2c_byp_in_mm_qid                    (h2c_byp_in_mm_qid),
    .h2c_byp_in_mm_error                  (h2c_byp_in_mm_error),
    .h2c_byp_in_mm_func                   (h2c_byp_in_mm_func),
    .h2c_byp_in_mm_cidx                   (h2c_byp_in_mm_cidx),
    .h2c_byp_in_mm_no_dma                 (h2c_byp_in_mm_no_dma),
    .h2c_byp_in_mm_vld                    (h2c_byp_in_mm_vld),
    .h2c_byp_in_mm_rdy                    (h2c_byp_in_mm_rdy),

    .c2h_byp_out_vld                      (c2h_byp_out_vld),
    .c2h_byp_out_dsc                      (c2h_byp_out_dsc),
    .c2h_byp_out_st_mm                    (c2h_byp_out_st_mm),
    .c2h_byp_out_qid                      (c2h_byp_out_qid),
    .c2h_byp_out_dsc_sz                   (c2h_byp_out_dsc_sz),
    .c2h_byp_out_error                    (c2h_byp_out_error),
    .c2h_byp_out_func                     (c2h_byp_out_func),
    .c2h_byp_out_cidx                     (c2h_byp_out_cidx),
    .c2h_byp_out_port_id                  (c2h_byp_out_port_id),
    .c2h_byp_out_fmt                      (c2h_byp_out_fmt),
    .c2h_byp_out_pfch_tag                 (c2h_byp_out_pfch_tag),
    .c2h_byp_out_rdy                      (c2h_byp_out_rdy),

    .c2h_byp_in_st_csh_vld                (c2h_byp_in_st_csh_vld),
    .c2h_byp_in_st_csh_addr               (c2h_byp_in_st_csh_addr),
    .c2h_byp_in_st_csh_port_id            (c2h_byp_in_st_csh_port_id),
    .c2h_byp_in_st_csh_qid                (c2h_byp_in_st_csh_qid),
    .c2h_byp_in_st_csh_error              (c2h_byp_in_st_csh_error),
    .c2h_byp_in_st_csh_func               (c2h_byp_in_st_csh_func),
    .c2h_byp_in_st_csh_pfch_tag           (c2h_byp_in_st_csh_pfch_tag),
    .c2h_byp_in_st_csh_rdy                (c2h_byp_in_st_csh_rdy),

    .c2h_byp_in_mm_radr                   (c2h_byp_in_mm_radr),
    .c2h_byp_in_mm_wadr                   (c2h_byp_in_mm_wadr),
    .c2h_byp_in_mm_len                    (c2h_byp_in_mm_len),
    .c2h_byp_in_mm_mrkr_req               (c2h_byp_in_mm_mrkr_req),
    .c2h_byp_in_mm_port_id                (c2h_byp_in_mm_port_id),
    .c2h_byp_in_mm_sdi                    (c2h_byp_in_mm_sdi),
    .c2h_byp_in_mm_qid                    (c2h_byp_in_mm_qid),
    .c2h_byp_in_mm_error                  (c2h_byp_in_mm_error),
    .c2h_byp_in_mm_func                   (c2h_byp_in_mm_func),
    .c2h_byp_in_mm_cidx                   (c2h_byp_in_mm_cidx),
    .c2h_byp_in_mm_vld                    (c2h_byp_in_mm_vld),
    .c2h_byp_in_mm_no_dma                 (c2h_byp_in_mm_no_dma),
    .c2h_byp_in_mm_rdy                    (c2h_byp_in_mm_rdy),

    .usr_irq_in_vld                       (usr_irq_in_vld),
    .usr_irq_in_vec                       (usr_irq_in_vec),
    .usr_irq_in_fnc                       (usr_irq_in_fnc),
    .usr_irq_out_ack                      (usr_irq_out_ack),
    .usr_irq_out_fail                     (usr_irq_out_fail),

    .st_rx_msg_rdy                        (1'b1),
    .st_rx_msg_valid                      (),
    .st_rx_msg_last                       (),
    .st_rx_msg_data                       (),

    .tm_dsc_sts_vld                       (tm_dsc_sts_vld),
    .tm_dsc_sts_port_id                   (tm_dsc_sts_port_id),
    .tm_dsc_sts_qen                       (tm_dsc_sts_qen),
    .tm_dsc_sts_byp                       (tm_dsc_sts_byp),
    .tm_dsc_sts_dir                       (tm_dsc_sts_dir),
    .tm_dsc_sts_mm                        (tm_dsc_sts_mm),
    .tm_dsc_sts_error                     (tm_dsc_sts_error),
    .tm_dsc_sts_qid                       (tm_dsc_sts_qid),
    .tm_dsc_sts_avl                       (tm_dsc_sts_avl),
    .tm_dsc_sts_qinv                      (tm_dsc_sts_qinv),
    .tm_dsc_sts_irq_arm                   (tm_dsc_sts_irq_arm),
    .tm_dsc_sts_pidx                      (tm_dsc_sts_pidx),
    .tm_dsc_sts_rdy                       (tm_dsc_sts_rdy),

    .dsc_crdt_in_vld                      (dsc_crdt_in_vld),
    .dsc_crdt_in_crdt                     (dsc_crdt_in_crdt),
    .dsc_crdt_in_qid                      (dsc_crdt_in_qid),
    .dsc_crdt_in_dir                      (dsc_crdt_in_dir),
    .dsc_crdt_in_fence                    (dsc_crdt_in_fence),
    .dsc_crdt_in_rdy                      (dsc_crdt_in_rdy),

    .m_axi_awready                        (m_axi_awready),
    .m_axi_wready                         (m_axi_wready),
    .m_axi_bid                            (m_axi_bid),
    .m_axi_bresp                          (m_axi_bresp),
    .m_axi_bvalid                         (m_axi_bvalid),
    .m_axi_arready                        (m_axi_arready),
    .m_axi_rid                            (m_axi_rid),
    .m_axi_rdata                          (m_axi_rdata),
    .m_axi_rresp                          (m_axi_rresp),
    .m_axi_rlast                          (m_axi_rlast),
    .m_axi_rvalid                         (m_axi_rvalid),
    .m_axi_awid                           (m_axi_awid),
    .m_axi_awaddr                         (m_axi_awaddr),
    .m_axi_awuser                         (m_axi_awuser),
    .m_axi_awlen                          (m_axi_awlen),
    .m_axi_awsize                         (m_axi_awsize),
    .m_axi_awburst                        (m_axi_awburst),
    .m_axi_awprot                         (m_axi_awprot),
    .m_axi_awvalid                        (m_axi_awvalid),
    .m_axi_awlock                         (m_axi_awlock),
    .m_axi_awcache                        (m_axi_awcache),
    .m_axi_wdata                          (m_axi_wdata),
    .m_axi_wuser                          (m_axi_wuser),
    .m_axi_wstrb                          (m_axi_wstrb),
    .m_axi_wlast                          (m_axi_wlast),
    .m_axi_wvalid                         (m_axi_wvalid),
    .m_axi_bready                         (m_axi_bready),
    .m_axi_arid                           (m_axi_arid),
    .m_axi_araddr                         (m_axi_araddr),
    .m_axi_aruser                         (m_axi_aruser),
    .m_axi_arlen                          (m_axi_arlen),
    .m_axi_arsize                         (m_axi_arsize),
    .m_axi_arburst                        (m_axi_arburst),
    .m_axi_arprot                         (m_axi_arprot),
    .m_axi_arvalid                        (m_axi_arvalid),
    .m_axi_arlock                         (m_axi_arlock),
    .m_axi_arcache                        (m_axi_arcache),
    .m_axi_rready                         (m_axi_rready),

    /*
    // No need to connect Master AXI Bridge signals
    .m_axib_awid                          (),
    .m_axib_awaddr                        (),
    .m_axib_awlen                         (),
    .m_axib_awuser                        (),
    .m_axib_awsize                        (),
    .m_axib_awburst                       (),
    .m_axib_awprot                        (),
    .m_axib_awvalid                       (),
    .m_axib_awready                       (1'b0),
    .m_axib_awlock                        (),
    .m_axib_awcache                       (),
    .m_axib_wdata                         (),
    .m_axib_wstrb                         (),
    .m_axib_wlast                         (),
    .m_axib_wvalid                        (),
    .m_axib_wready                        (1'b0),
    .m_axib_bid                           (4'd0),
    .m_axib_bresp                         (2'd0),
    .m_axib_bvalid                        (1'b0),
    .m_axib_bready                        (),
    .m_axib_arid                          (),
    .m_axib_araddr                        (),
    .m_axib_arlen                         (),
    .m_axib_aruser                        (),
    .m_axib_arsize                        (),
    .m_axib_arburst                       (),
    .m_axib_arprot                        (),
    .m_axib_arvalid                       (),
    .m_axib_arready                       (1'b0),
    .m_axib_arlock                        (),
    .m_axib_arcache                       (),
    .m_axib_rid                           (4'd0),
    .m_axib_rdata                         (512'd0),
    .m_axib_rresp                         (2'd0),
    .m_axib_rlast                         (1'b0),
    .m_axib_rvalid                        (1'b0),
    .m_axib_rready                        (),
    */

    .m_axis_h2c_tvalid                    (m_axis_h2c_tvalid),
    .m_axis_h2c_tdata                     (m_axis_h2c_tdata),
    .m_axis_h2c_tcrc                      (m_axis_h2c_tcrc),
    .m_axis_h2c_tlast                     (m_axis_h2c_tlast),
    .m_axis_h2c_tuser_qid                 (m_axis_h2c_tuser_qid),
    .m_axis_h2c_tuser_port_id             (m_axis_h2c_tuser_port_id),
    .m_axis_h2c_tuser_err                 (m_axis_h2c_tuser_err),
    .m_axis_h2c_tuser_mdata               (m_axis_h2c_tuser_mdata),
    .m_axis_h2c_tuser_mty                 (m_axis_h2c_tuser_mty),
    .m_axis_h2c_tuser_zero_byte           (m_axis_h2c_tuser_zero_byte),
    .m_axis_h2c_tready                    (m_axis_h2c_tready),

    .s_axis_c2h_tvalid                    (s_axis_c2h_tvalid),
    .s_axis_c2h_tdata                     (s_axis_c2h_tdata),
    .s_axis_c2h_tcrc                      (s_axis_c2h_tcrc),
    .s_axis_c2h_tlast                     (s_axis_c2h_tlast),
    .s_axis_c2h_ctrl_marker               (s_axis_c2h_ctrl_marker),
    .s_axis_c2h_ctrl_port_id              (s_axis_c2h_ctrl_port_id),
    .s_axis_c2h_ctrl_ecc                  (s_axis_c2h_ctrl_ecc),
    .s_axis_c2h_ctrl_len                  (s_axis_c2h_ctrl_len),
    .s_axis_c2h_ctrl_qid                  (s_axis_c2h_ctrl_qid),
    .s_axis_c2h_ctrl_has_cmpt             (s_axis_c2h_ctrl_has_cmpt),
    .s_axis_c2h_mty                       (s_axis_c2h_mty),
    .s_axis_c2h_tready                    (s_axis_c2h_tready),

    .s_axis_c2h_cmpt_tvalid               (s_axis_cpl_tvalid),
    .s_axis_c2h_cmpt_tdata                (s_axis_cpl_tdata),
    .s_axis_c2h_cmpt_size                 (s_axis_cpl_size),
    .s_axis_c2h_cmpt_dpar                 (s_axis_cpl_dpar),
    .s_axis_c2h_cmpt_ctrl_qid             (s_axis_cpl_ctrl_qid),
    .s_axis_c2h_cmpt_ctrl_cmpt_type       (s_axis_cpl_ctrl_cmpt_type),
    .s_axis_c2h_cmpt_ctrl_wait_pld_pkt_id (s_axis_cpl_ctrl_wait_pld_pkt_id),
    .s_axis_c2h_cmpt_ctrl_port_id         (s_axis_cpl_ctrl_port_id),
    .s_axis_c2h_cmpt_ctrl_marker          (s_axis_cpl_ctrl_marker),
    .s_axis_c2h_cmpt_ctrl_user_trig       (s_axis_cpl_ctrl_user_trig),
    .s_axis_c2h_cmpt_ctrl_col_idx         (s_axis_cpl_ctrl_col_idx),
    .s_axis_c2h_cmpt_ctrl_err_idx         (s_axis_cpl_ctrl_err_idx),
    .s_axis_c2h_cmpt_ctrl_no_wrb_marker   (s_axis_cpl_ctrl_no_wrb_marker),
    .s_axis_c2h_cmpt_tready               (s_axis_cpl_tready),

    // Control status register interface
    .csr_prog_done                        (qdma_csr_prog_done),
    .s_axil_csr_awaddr                    (qdma_axil_csr_awaddr),
    .s_axil_csr_awprot                    (qdma_axil_csr_awprot),
    .s_axil_csr_awvalid                   (qdma_axil_csr_awvalid),
    .s_axil_csr_awready                   (qdma_axil_csr_awready),
    .s_axil_csr_wdata                     (qdma_axil_csr_wdata),
    .s_axil_csr_wstrb                     (qdma_axil_csr_wstrb),
    .s_axil_csr_wvalid                    (qdma_axil_csr_wvalid),
    .s_axil_csr_wready                    (qdma_axil_csr_wready),
    .s_axil_csr_bvalid                    (qdma_axil_csr_bvalid),
    .s_axil_csr_bresp                     (qdma_axil_csr_bresp),
    .s_axil_csr_bready                    (qdma_axil_csr_bready),
    .s_axil_csr_araddr                    (qdma_axil_csr_araddr),
    .s_axil_csr_arprot                    (qdma_axil_csr_arprot),
    .s_axil_csr_arvalid                   (qdma_axil_csr_arvalid),
    .s_axil_csr_arready                   (qdma_axil_csr_arready),
    .s_axil_csr_rdata                     (qdma_axil_csr_rdata),
    .s_axil_csr_rresp                     (qdma_axil_csr_rresp),
    .s_axil_csr_rvalid                    (qdma_axil_csr_rvalid),
    .s_axil_csr_rready                    (qdma_axil_csr_rready),

    // AXI bridge interface used to access host memory
    .s_axib_awid                          (s_axib_awid),
    .s_axib_awaddr                        (s_axib_awaddr),
    .s_axib_awregion                      (s_axib_awregion),
    .s_axib_awlen                         (s_axib_awlen),
    .s_axib_awsize                        (s_axib_awsize),
    .s_axib_awburst                       (s_axib_awburst),
    .s_axib_awvalid                       (s_axib_awvalid),
    .s_axib_wdata                         (s_axib_wdata),
    .s_axib_wstrb                         (s_axib_wstrb),
    .s_axib_wlast                         (s_axib_wlast),
    .s_axib_wvalid                        (s_axib_wvalid),
    .s_axib_wuser                         (s_axib_wuser),
    .s_axib_ruser                         (s_axib_ruser),
    .s_axib_bready                        (s_axib_bready),
    .s_axib_arid                          (s_axib_arid),
    .s_axib_araddr                        (s_axib_araddr),
    .s_axib_aruser                        (s_axib_aruser),
    .s_axib_awuser                        (s_axib_awuser),
    .s_axib_arregion                      (s_axib_arregion),
    .s_axib_arlen                         (s_axib_arlen),
    .s_axib_arsize                        (s_axib_arsize),
    .s_axib_arburst                       (s_axib_arburst),
    .s_axib_arvalid                       (s_axib_arvalid),
    .s_axib_rready                        (s_axib_rready),
    .s_axib_awready                       (s_axib_awready),
    .s_axib_wready                        (s_axib_wready),
    .s_axib_bid                           (s_axib_bid),
    .s_axib_bresp                         (s_axib_bresp),
    .s_axib_bvalid                        (s_axib_bvalid),
    .s_axib_arready                       (s_axib_arready),
    .s_axib_rid                           (s_axib_rid),
    .s_axib_rdata                         (s_axib_rdata),
    .s_axib_rresp                         (s_axib_rresp),
    .s_axib_rlast                         (s_axib_rlast),
    .s_axib_rvalid                        (s_axib_rvalid),

    .axis_c2h_status_drop                 (),     // output wire axis_c2h_status_drop
    .axis_c2h_status_valid                (),     // output wire axis_c2h_status_valid
    .axis_c2h_status_cmp                  (),     // output wire axis_c2h_status_cmp
    .axis_c2h_status_error                (),     // output wire axis_c2h_status_error
    .axis_c2h_status_last                 (),     // output wire axis_c2h_status_last
    .axis_c2h_status_qid                  (),     // output wire [10 : 0] axis_c2h_status_qid
    .axis_c2h_dmawr_cmp                   (),     // output wire axis_c2h_dmawr_cmp

    .qsts_out_op                          (),     // output wire [7 : 0] qsts_out_op
    .qsts_out_data                        (),     // output wire [63 : 0] qsts_out_data
    .qsts_out_port_id                     (),     // output wire [2 : 0] qsts_out_port_id
    .qsts_out_qid                         (),     // output wire [12 : 0] qsts_out_qid
    .qsts_out_vld                         (),     // output wire qsts_out_vld
    .qsts_out_rdy                         (1'b1), // input wire qsts_out_rdy

    .soft_reset_n                         (soft_reset_n),
    .phy_ready                            (phy_ready)
  );

endmodule: qdma_subsystem_qdma_wrapper
