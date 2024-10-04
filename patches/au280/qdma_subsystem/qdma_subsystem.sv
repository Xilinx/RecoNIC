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
`include "open_nic_shell_macros.vh"
`timescale 1ns/1ps
module qdma_subsystem #(
  parameter int MIN_PKT_LEN   = 64,
  parameter int MAX_PKT_LEN   = 1518,
  parameter int USE_PHYS_FUNC = 1,
  parameter int NUM_PHYS_FUNC = 1,
  parameter int NUM_QUEUE     = 512
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

  output     [NUM_PHYS_FUNC-1:0] m_axis_h2c_tvalid,
  output [512*NUM_PHYS_FUNC-1:0] m_axis_h2c_tdata,
  output  [64*NUM_PHYS_FUNC-1:0] m_axis_h2c_tkeep,
  output     [NUM_PHYS_FUNC-1:0] m_axis_h2c_tlast,
  output  [16*NUM_PHYS_FUNC-1:0] m_axis_h2c_tuser_size,
  output  [16*NUM_PHYS_FUNC-1:0] m_axis_h2c_tuser_src,
  output  [16*NUM_PHYS_FUNC-1:0] m_axis_h2c_tuser_dst,
  input      [NUM_PHYS_FUNC-1:0] m_axis_h2c_tready,

  input      [NUM_PHYS_FUNC-1:0] s_axis_c2h_tvalid,
  input  [512*NUM_PHYS_FUNC-1:0] s_axis_c2h_tdata,
  input   [64*NUM_PHYS_FUNC-1:0] s_axis_c2h_tkeep,
  input      [NUM_PHYS_FUNC-1:0] s_axis_c2h_tlast,
  input   [16*NUM_PHYS_FUNC-1:0] s_axis_c2h_tuser_size,
  input   [16*NUM_PHYS_FUNC-1:0] s_axis_c2h_tuser_src,
  input   [16*NUM_PHYS_FUNC-1:0] s_axis_c2h_tuser_dst,
  output     [NUM_PHYS_FUNC-1:0] s_axis_c2h_tready,

  // QDMA DMA Engine - AXI MM interface
  input                          m_axi_awready,
  input                          m_axi_wready,
  input                  [3:0]   m_axi_bid,
  input                  [1:0]   m_axi_bresp,
  input                          m_axi_bvalid,
  input                          m_axi_arready,
  input                  [3:0]   m_axi_rid,
  input                  [511:0] m_axi_rdata,
  input                  [1:0]   m_axi_rresp,
  input                          m_axi_rlast,
  input                          m_axi_rvalid,
  output                 [3:0]   m_axi_awid,
  output                 [63:0]  m_axi_awaddr,
  output                 [31:0]  m_axi_awuser,
  output                 [7:0]   m_axi_awlen,
  output                 [2:0]   m_axi_awsize,
  output                 [1:0]   m_axi_awburst,
  output                 [2:0]   m_axi_awprot,
  output                         m_axi_awvalid,
  output                         m_axi_awlock,
  output                 [3:0]   m_axi_awcache,
  output                 [511:0] m_axi_wdata,
  output                 [63:0]  m_axi_wuser,
  output                 [63:0]  m_axi_wstrb,
  output                         m_axi_wlast,
  output                         m_axi_wvalid,
  output                         m_axi_bready,
  output                 [3:0]   m_axi_arid,
  output                 [63:0]  m_axi_araddr,
  output                 [31:0]  m_axi_aruser,
  output                 [7:0]   m_axi_arlen,
  output                 [2:0]   m_axi_arsize,
  output                 [1:0]   m_axi_arburst,
  output                 [2:0]   m_axi_arprot,
  output                         m_axi_arvalid,
  output                         m_axi_arlock,
  output                 [3:0]   m_axi_arcache,
  output                         m_axi_rready,

`ifdef __synthesis__
  input                   [15:0] pcie_rxp,
  input                   [15:0] pcie_rxn,
  output                  [15:0] pcie_txp,
  output                  [15:0] pcie_txn,

  // BAR2-mapped master AXI-Lite feeding into system configuration block
  output                         m_axil_pcie_awvalid,
  output                  [31:0] m_axil_pcie_awaddr,
  input                          m_axil_pcie_awready,
  output                         m_axil_pcie_wvalid,
  output                  [31:0] m_axil_pcie_wdata,
  input                          m_axil_pcie_wready,
  input                          m_axil_pcie_bvalid,
  input                    [1:0] m_axil_pcie_bresp,
  output                         m_axil_pcie_bready,
  output                         m_axil_pcie_arvalid,
  output                  [31:0] m_axil_pcie_araddr,
  input                          m_axil_pcie_arready,
  input                          m_axil_pcie_rvalid,
  input                   [31:0] m_axil_pcie_rdata,
  input                    [1:0] m_axil_pcie_rresp,
  output                         m_axil_pcie_rready,

  input                          pcie_refclk_p,
  input                          pcie_refclk_n,
  input                          pcie_rstn,
  output                         user_lnk_up,
  output                         phy_ready,

  // This reset signal serves as a power-up reset for the entire system.  It is
  // routed into the `system_config` submodule to generate proper reset signals
  // for each submodule.
  output                         powerup_rstn,
`else // !`ifdef __synthesis__
  input                          s_axis_qdma_h2c_tvalid,
  input                  [511:0] s_axis_qdma_h2c_tdata,
  input                   [31:0] s_axis_qdma_h2c_tcrc,
  input                          s_axis_qdma_h2c_tlast,
  input                   [10:0] s_axis_qdma_h2c_tuser_qid,
  input                    [2:0] s_axis_qdma_h2c_tuser_port_id,
  input                          s_axis_qdma_h2c_tuser_err,
  input                   [31:0] s_axis_qdma_h2c_tuser_mdata,
  input                    [5:0] s_axis_qdma_h2c_tuser_mty,
  input                          s_axis_qdma_h2c_tuser_zero_byte,
  output                         s_axis_qdma_h2c_tready,

  output                         m_axis_qdma_c2h_tvalid,
  output                 [511:0] m_axis_qdma_c2h_tdata,
  output                  [31:0] m_axis_qdma_c2h_tcrc,
  output                         m_axis_qdma_c2h_tlast,
  output                         m_axis_qdma_c2h_ctrl_marker,
  output                   [2:0] m_axis_qdma_c2h_ctrl_port_id,
  output                   [6:0] m_axis_qdma_c2h_ctrl_ecc,
  output                  [15:0] m_axis_qdma_c2h_ctrl_len,
  output                  [10:0] m_axis_qdma_c2h_ctrl_qid,
  output                         m_axis_qdma_c2h_ctrl_has_cmpt,
  output                   [5:0] m_axis_qdma_c2h_mty,
  input                          m_axis_qdma_c2h_tready,

  output                         m_axis_qdma_cpl_tvalid,
  output                 [511:0] m_axis_qdma_cpl_tdata,
  output                   [1:0] m_axis_qdma_cpl_size,
  output                  [15:0] m_axis_qdma_cpl_dpar,
  output                  [10:0] m_axis_qdma_cpl_ctrl_qid,
  output                   [1:0] m_axis_qdma_cpl_ctrl_cmpt_type,
  output                  [15:0] m_axis_qdma_cpl_ctrl_wait_pld_pkt_id,
  output                   [2:0] m_axis_qdma_cpl_ctrl_port_id,
  output                         m_axis_qdma_cpl_ctrl_marker,
  output                         m_axis_qdma_cpl_ctrl_user_trig,
  output                   [2:0] m_axis_qdma_cpl_ctrl_col_idx,
  output                   [2:0] m_axis_qdma_cpl_ctrl_err_idx,
  output                         m_axis_qdma_cpl_ctrl_no_wrb_marker,
  input                          m_axis_qdma_cpl_tready,
`endif

  // QDMA control/status register interface
  output                         s_csr_prog_done,
  input                   [31:0] s_axil_csr_awaddr,
  input                    [2:0] s_axil_csr_awprot,
  input                          s_axil_csr_awvalid,
  output                         s_axil_csr_awready,
  input                   [31:0] s_axil_csr_wdata,
  input                   [3:0]  s_axil_csr_wstrb,
  input                          s_axil_csr_wvalid,
  output                         s_axil_csr_wready,
  output                         s_axil_csr_bvalid,
  output                   [1:0] s_axil_csr_bresp,
  input                          s_axil_csr_bready,
  input                   [31:0] s_axil_csr_araddr,
  input                    [2:0] s_axil_csr_arprot,
  input                          s_axil_csr_arvalid,
  output                         s_axil_csr_arready,
  output                  [31:0] s_axil_csr_rdata,
  output                   [1:0] s_axil_csr_rresp,
  output                         s_axil_csr_rvalid,
  input                          s_axil_csr_rready,

  // QDMA bridge slave interface
  input                    [3:0] s_axib_awid,
  input                   [63:0] s_axib_awaddr,
  input                    [3:0] s_axib_awregion,
  input                    [7:0] s_axib_awlen,
  input                    [2:0] s_axib_awsize,
  input                    [1:0] s_axib_awburst,
  input                          s_axib_awvalid,
  input                  [511:0] s_axib_wdata,
  input                   [63:0] s_axib_wstrb,
  input                          s_axib_wlast,
  input                          s_axib_wvalid,
  input                   [63:0] s_axib_wuser,
  output                  [63:0] s_axib_ruser,
  input                          s_axib_bready,
  input                    [3:0] s_axib_arid,
  input                   [63:0] s_axib_araddr,
  input                   [11:0] s_axib_aruser,
  input                   [11:0] s_axib_awuser,
  input                    [3:0] s_axib_arregion,
  input                    [7:0] s_axib_arlen,
  input                    [2:0] s_axib_arsize,
  input                    [1:0] s_axib_arburst,
  input                          s_axib_arvalid,
  input                          s_axib_rready,
  output                         s_axib_awready,
  output                         s_axib_wready,
  output                   [3:0] s_axib_bid,
  output                   [1:0] s_axib_bresp,
  output                         s_axib_bvalid,
  output                         s_axib_arready,
  output                   [3:0] s_axib_rid,
  output                 [511:0] s_axib_rdata,
  output                   [1:0] s_axib_rresp,
  output                         s_axib_rlast,
  output                         s_axib_rvalid,

  input                          mod_rstn,
  output                         mod_rst_done,

`ifdef __synthesis__
  output                         axil_aclk,

  `ifdef __au55n__
    output                         ref_clk_100mhz,
  `elsif __au55c__
    output                         ref_clk_100mhz,
  `elsif __au50__
    output                         ref_clk_100mhz,
  `elsif __au280__
    output                         ref_clk_100mhz,        
  `endif
  output                         axis_aclk


`else
  output reg                     axil_aclk,

  `ifdef __au55n__
    output reg                        ref_clk_100mhz,
  `elsif __au55c__
    output reg                        ref_clk_100mhz,
  `elsif __au50__
    output reg                        ref_clk_100mhz,
  `elsif __au280__
    output reg                        ref_clk_100mhz,        
  `endif
  output reg                     axis_aclk
`endif
);

  wire         axis_qdma_h2c_tvalid;
  wire [511:0] axis_qdma_h2c_tdata;
  wire  [31:0] axis_qdma_h2c_tcrc;
  wire         axis_qdma_h2c_tlast;
  wire  [10:0] axis_qdma_h2c_tuser_qid;
  wire   [2:0] axis_qdma_h2c_tuser_port_id;
  wire         axis_qdma_h2c_tuser_err;
  wire  [31:0] axis_qdma_h2c_tuser_mdata;
  wire   [5:0] axis_qdma_h2c_tuser_mty;
  wire         axis_qdma_h2c_tuser_zero_byte;
  wire         axis_qdma_h2c_tready;

  wire         axis_qdma_c2h_tvalid;
  wire [511:0] axis_qdma_c2h_tdata;
  wire  [31:0] axis_qdma_c2h_tcrc;
  wire         axis_qdma_c2h_tlast;
  wire         axis_qdma_c2h_ctrl_marker;
  wire   [2:0] axis_qdma_c2h_ctrl_port_id;
  wire   [6:0] axis_qdma_c2h_ctrl_ecc;
  wire  [15:0] axis_qdma_c2h_ctrl_len;
  wire  [10:0] axis_qdma_c2h_ctrl_qid;
  wire         axis_qdma_c2h_ctrl_has_cmpt;
  wire   [5:0] axis_qdma_c2h_mty;
  wire         axis_qdma_c2h_tready;

  /*
  wire         axi_qdma_mm_awready;
  wire         axi_qdma_mm_wready;
  wire [3:0]   axi_qdma_mm_bid;
  wire [1:0]   axi_qdma_mm_bresp;
  wire         axi_qdma_mm_bvalid;
  wire         axi_qdma_mm_arready;
  wire [3:0]   axi_qdma_mm_rid;
  wire [511:0] axi_qdma_mm_rdata;
  wire [1:0]   axi_qdma_mm_rresp;
  wire         axi_qdma_mm_rlast;
  wire         axi_qdma_mm_rvalid;
  wire [3:0]   axi_qdma_mm_awid;
  wire [63:0]  axi_qdma_mm_awaddr;
  wire [31:0]  axi_qdma_mm_awuser;
  wire [7:0]   axi_qdma_mm_awlen;
  wire [2:0]   axi_qdma_mm_awsize;
  wire [1:0]   axi_qdma_mm_awburst;
  wire [2:0]   axi_qdma_mm_awprot;
  wire         axi_qdma_mm_awvalid;
  wire         axi_qdma_mm_awlock;
  wire [3:0]   axi_qdma_mm_awcache;
  wire [511:0] axi_qdma_mm_wdata;
  wire [63:0]  axi_qdma_mm_wuser;
  wire [63:0]  axi_qdma_mm_wstrb;
  wire         axi_qdma_mm_wlast;
  wire         axi_qdma_mm_wvalid;
  wire         axi_qdma_mm_bready;
  wire [3:0]   axi_qdma_mm_arid;
  wire [63:0]  axi_qdma_mm_araddr;
  wire [31:0]  axi_qdma_mm_aruser;
  wire [7:0]   axi_qdma_mm_arlen;
  wire [2:0]   axi_qdma_mm_arsize;
  wire [1:0]   axi_qdma_mm_arburst;
  wire [2:0]   axi_qdma_mm_arprot;
  wire         axi_qdma_mm_arvalid;
  wire         axi_qdma_mm_arlock;
  wire [3:0]   axi_qdma_mm_arcache;
  wire         axi_qdma_mm_rready;
  */

  wire         axis_qdma_cpl_tvalid;
  wire [511:0] axis_qdma_cpl_tdata;
  wire   [1:0] axis_qdma_cpl_size;
  wire  [15:0] axis_qdma_cpl_dpar;
  wire  [10:0] axis_qdma_cpl_ctrl_qid;
  wire   [1:0] axis_qdma_cpl_ctrl_cmpt_type;
  wire  [15:0] axis_qdma_cpl_ctrl_wait_pld_pkt_id;
  wire   [2:0] axis_qdma_cpl_ctrl_port_id;
  wire         axis_qdma_cpl_ctrl_marker;
  wire         axis_qdma_cpl_ctrl_user_trig;
  wire   [2:0] axis_qdma_cpl_ctrl_col_idx;
  wire   [2:0] axis_qdma_cpl_ctrl_err_idx;
  wire         axis_qdma_cpl_ctrl_no_wrb_marker;
  wire         axis_qdma_cpl_tready;

  wire         h2c_byp_out_vld;
  wire [255:0] h2c_byp_out_dsc;
  wire         h2c_byp_out_st_mm;
  wire   [1:0] h2c_byp_out_dsc_sz;
  wire  [10:0] h2c_byp_out_qid;
  wire         h2c_byp_out_error;
  wire   [7:0] h2c_byp_out_func;
  wire  [15:0] h2c_byp_out_cidx;
  wire   [2:0] h2c_byp_out_port_id;
  wire   [3:0] h2c_byp_out_fmt;
  wire         h2c_byp_out_rdy;

  wire         h2c_byp_in_st_vld;
  wire  [63:0] h2c_byp_in_st_addr;
  wire  [15:0] h2c_byp_in_st_len;
  wire         h2c_byp_in_st_eop;
  wire         h2c_byp_in_st_sop;
  wire         h2c_byp_in_st_mrkr_req;
  wire   [2:0] h2c_byp_in_st_port_id;
  wire         h2c_byp_in_st_sdi;
  wire  [10:0] h2c_byp_in_st_qid;
  wire         h2c_byp_in_st_error;
  wire   [7:0] h2c_byp_in_st_func;
  wire  [15:0] h2c_byp_in_st_cidx;
  wire         h2c_byp_in_st_no_dma;
  wire         h2c_byp_in_st_rdy;

  wire  [63:0] h2c_byp_in_mm_radr;
  wire  [63:0] h2c_byp_in_mm_wadr;
  wire  [15:0] h2c_byp_in_mm_len;
  wire         h2c_byp_in_mm_mrkr_req;
  wire  [2:0]  h2c_byp_in_mm_port_id;
  wire         h2c_byp_in_mm_sdi;
  wire  [10:0] h2c_byp_in_mm_qid;
  wire         h2c_byp_in_mm_error;
  wire  [7:0]  h2c_byp_in_mm_func;
  wire  [15:0] h2c_byp_in_mm_cidx;
  wire         h2c_byp_in_mm_no_dma;
  wire         h2c_byp_in_mm_vld;
  wire         h2c_byp_in_mm_rdy;

  wire         c2h_byp_out_vld;
  wire [255:0] c2h_byp_out_dsc;
  wire         c2h_byp_out_st_mm;
  wire  [10:0] c2h_byp_out_qid;
  wire   [1:0] c2h_byp_out_dsc_sz;
  wire         c2h_byp_out_error;
  wire   [7:0] c2h_byp_out_func;
  wire  [15:0] c2h_byp_out_cidx;
  wire   [2:0] c2h_byp_out_port_id;
  wire   [3:0] c2h_byp_out_fmt;
  wire   [6:0] c2h_byp_out_pfch_tag;
  wire         c2h_byp_out_rdy;

  wire         c2h_byp_in_st_csh_vld;
  wire  [63:0] c2h_byp_in_st_csh_addr;
  wire   [2:0] c2h_byp_in_st_csh_port_id;
  wire  [10:0] c2h_byp_in_st_csh_qid;
  wire         c2h_byp_in_st_csh_error;
  wire   [7:0] c2h_byp_in_st_csh_func;
  wire   [6:0] c2h_byp_in_st_csh_pfch_tag;
  wire         c2h_byp_in_st_csh_rdy;

  wire  [63:0] c2h_byp_in_mm_radr;
  wire  [63:0] c2h_byp_in_mm_wadr;
  wire  [15:0] c2h_byp_in_mm_len;
  wire         c2h_byp_in_mm_mrkr_req;
  wire  [2:0]  c2h_byp_in_mm_port_id;
  wire         c2h_byp_in_mm_sdi;
  wire  [10:0] c2h_byp_in_mm_qid;
  wire         c2h_byp_in_mm_error;
  wire  [7:0]  c2h_byp_in_mm_func;
  wire  [15:0] c2h_byp_in_mm_cidx;
  wire         c2h_byp_in_mm_vld;
  wire         c2h_byp_in_mm_no_dma;
  wire         c2h_byp_in_mm_rdy;

  wire         axil_aresetn;

  // Reset is clocked by the 125MHz AXI-Lite clock
  generic_reset #(
    .NUM_INPUT_CLK  (1),
    .RESET_DURATION (100)
  ) reset_inst (
    .mod_rstn     (mod_rstn),
    .mod_rst_done (mod_rst_done),
    .clk          (axil_aclk),
    .rstn         (axil_aresetn)
  );

`ifdef __synthesis__
  wire         pcie_refclk_gt;
  wire         pcie_refclk;

  IBUFDS_GTE4 pcie_refclk_buf (
    .CEB   (1'b0),
    .I     (pcie_refclk_p),
    .IB    (pcie_refclk_n),
    .O     (pcie_refclk_gt),
    .ODIV2 (pcie_refclk)
  );

  assign h2c_byp_out_rdy            = 1'b1;
  assign h2c_byp_in_st_vld          = 1'b0;
  assign h2c_byp_in_st_addr         = 0;
  assign h2c_byp_in_st_len          = 0;
  assign h2c_byp_in_st_eop          = 1'b0;
  assign h2c_byp_in_st_sop          = 1'b0;
  assign h2c_byp_in_st_mrkr_req     = 1'b0;
  assign h2c_byp_in_st_port_id      = 0;
  assign h2c_byp_in_st_sdi          = 1'b0;
  assign h2c_byp_in_st_qid          = 0;
  assign h2c_byp_in_st_error        = 1'b0;
  assign h2c_byp_in_st_func         = 0;
  assign h2c_byp_in_st_cidx         = 0;
  assign h2c_byp_in_st_no_dma       = 1'b0;

  assign h2c_byp_in_mm_radr         = 0;
  assign h2c_byp_in_mm_wadr         = 0;
  assign h2c_byp_in_mm_len          = 0;
  assign h2c_byp_in_mm_mrkr_req     = 1'b0;
  assign h2c_byp_in_mm_port_id      = 0;
  assign h2c_byp_in_mm_sdi          = 1'b0;
  assign h2c_byp_in_mm_qid          = 0;
  assign h2c_byp_in_mm_error        = 1'b0;
  assign h2c_byp_in_mm_func         = 0;
  assign h2c_byp_in_mm_cidx         = 0;
  assign h2c_byp_in_mm_no_dma       = 1'b0;
  assign h2c_byp_in_mm_vld          = 1'b0;

  assign c2h_byp_out_rdy            = 1'b1;
  assign c2h_byp_in_st_csh_vld      = 1'b0;
  assign c2h_byp_in_st_csh_addr     = 0;
  assign c2h_byp_in_st_csh_port_id  = 0;
  assign c2h_byp_in_st_csh_qid      = 0;
  assign c2h_byp_in_st_csh_error    = 1'b0;
  assign c2h_byp_in_st_csh_func     = 0;
  assign c2h_byp_in_st_csh_pfch_tag = 0;

  assign c2h_byp_in_mm_radr         = 0;
  assign c2h_byp_in_mm_wadr         = 0;
  assign c2h_byp_in_mm_len          = 0;
  assign c2h_byp_in_mm_mrkr_req     = 1'b0;
  assign c2h_byp_in_mm_port_id      = 0;
  assign c2h_byp_in_mm_sdi          = 1'b0;
  assign c2h_byp_in_mm_qid          = 0;
  assign c2h_byp_in_mm_error        = 1'b0;
  assign c2h_byp_in_mm_func         = 0;
  assign c2h_byp_in_mm_cidx         = 0;
  assign c2h_byp_in_mm_vld          = 1'b0;
  assign c2h_byp_in_mm_no_dma       = 1'b0;

  qdma_subsystem_qdma_wrapper qdma_wrapper_inst (
    .pcie_rxp                        (pcie_rxp),
    .pcie_rxn                        (pcie_rxn),
    .pcie_txp                        (pcie_txp),
    .pcie_txn                        (pcie_txn),

    .m_axil_awvalid                  (m_axil_pcie_awvalid),
    .m_axil_awaddr                   (m_axil_pcie_awaddr),
    .m_axil_awready                  (m_axil_pcie_awready),
    .m_axil_wvalid                   (m_axil_pcie_wvalid),
    .m_axil_wdata                    (m_axil_pcie_wdata),
    .m_axil_wready                   (m_axil_pcie_wready),
    .m_axil_bvalid                   (m_axil_pcie_bvalid),
    .m_axil_bresp                    (m_axil_pcie_bresp),
    .m_axil_bready                   (m_axil_pcie_bready),
    .m_axil_arvalid                  (m_axil_pcie_arvalid),
    .m_axil_araddr                   (m_axil_pcie_araddr),
    .m_axil_arready                  (m_axil_pcie_arready),
    .m_axil_rvalid                   (m_axil_pcie_rvalid),
    .m_axil_rdata                    (m_axil_pcie_rdata),
    .m_axil_rresp                    (m_axil_pcie_rresp),
    .m_axil_rready                   (m_axil_pcie_rready),

    .m_axi_awready                   (m_axi_awready),
    .m_axi_wready                    (m_axi_wready),
    .m_axi_bid                       (m_axi_bid),
    .m_axi_bresp                     (m_axi_bresp),
    .m_axi_bvalid                    (m_axi_bvalid),
    .m_axi_arready                   (m_axi_arready),
    .m_axi_rid                       (m_axi_rid),
    .m_axi_rdata                     (m_axi_rdata),
    .m_axi_rresp                     (m_axi_rresp),
    .m_axi_rlast                     (m_axi_rlast),
    .m_axi_rvalid                    (m_axi_rvalid),
    .m_axi_awid                      (m_axi_awid),
    .m_axi_awaddr                    (m_axi_awaddr),
    .m_axi_awuser                    (m_axi_awuser),
    .m_axi_awlen                     (m_axi_awlen),
    .m_axi_awsize                    (m_axi_awsize),
    .m_axi_awburst                   (m_axi_awburst),
    .m_axi_awprot                    (m_axi_awprot),
    .m_axi_awvalid                   (m_axi_awvalid),
    .m_axi_awlock                    (m_axi_awlock),
    .m_axi_awcache                   (m_axi_awcache),
    .m_axi_wdata                     (m_axi_wdata),
    .m_axi_wuser                     (m_axi_wuser),
    .m_axi_wstrb                     (m_axi_wstrb),
    .m_axi_wlast                     (m_axi_wlast),
    .m_axi_wvalid                    (m_axi_wvalid),
    .m_axi_bready                    (m_axi_bready),
    .m_axi_arid                      (m_axi_arid),
    .m_axi_araddr                    (m_axi_araddr),
    .m_axi_aruser                    (m_axi_aruser),
    .m_axi_arlen                     (m_axi_arlen),
    .m_axi_arsize                    (m_axi_arsize),
    .m_axi_arburst                   (m_axi_arburst),
    .m_axi_arprot                    (m_axi_arprot),
    .m_axi_arvalid                   (m_axi_arvalid),
    .m_axi_arlock                    (m_axi_arlock),
    .m_axi_arcache                   (m_axi_arcache),
    .m_axi_rready                    (m_axi_rready),

    .m_axis_h2c_tvalid               (axis_qdma_h2c_tvalid),
    .m_axis_h2c_tdata                (axis_qdma_h2c_tdata),
    .m_axis_h2c_tcrc                 (axis_qdma_h2c_tcrc),
    .m_axis_h2c_tlast                (axis_qdma_h2c_tlast),
    .m_axis_h2c_tuser_qid            (axis_qdma_h2c_tuser_qid),
    .m_axis_h2c_tuser_port_id        (axis_qdma_h2c_tuser_port_id),
    .m_axis_h2c_tuser_err            (axis_qdma_h2c_tuser_err),
    .m_axis_h2c_tuser_mdata          (axis_qdma_h2c_tuser_mdata),
    .m_axis_h2c_tuser_mty            (axis_qdma_h2c_tuser_mty),
    .m_axis_h2c_tuser_zero_byte      (axis_qdma_h2c_tuser_zero_byte),
    .m_axis_h2c_tready               (axis_qdma_h2c_tready),

    .s_axis_c2h_tvalid               (axis_qdma_c2h_tvalid),
    .s_axis_c2h_tdata                (axis_qdma_c2h_tdata),
    .s_axis_c2h_tcrc                 (axis_qdma_c2h_tcrc),
    .s_axis_c2h_tlast                (axis_qdma_c2h_tlast),
    .s_axis_c2h_ctrl_marker          (axis_qdma_c2h_ctrl_marker),
    .s_axis_c2h_ctrl_port_id         (axis_qdma_c2h_ctrl_port_id),
    .s_axis_c2h_ctrl_ecc             (axis_qdma_c2h_ctrl_ecc),
    .s_axis_c2h_ctrl_len             (axis_qdma_c2h_ctrl_len),
    .s_axis_c2h_ctrl_qid             (axis_qdma_c2h_ctrl_qid),
    .s_axis_c2h_ctrl_has_cmpt        (axis_qdma_c2h_ctrl_has_cmpt),
    .s_axis_c2h_mty                  (axis_qdma_c2h_mty),
    .s_axis_c2h_tready               (axis_qdma_c2h_tready),

    .s_axis_cpl_tvalid               (axis_qdma_cpl_tvalid),
    .s_axis_cpl_tdata                (axis_qdma_cpl_tdata),
    .s_axis_cpl_size                 (axis_qdma_cpl_size),
    .s_axis_cpl_dpar                 (axis_qdma_cpl_dpar),
    .s_axis_cpl_ctrl_qid             (axis_qdma_cpl_ctrl_qid),
    .s_axis_cpl_ctrl_cmpt_type       (axis_qdma_cpl_ctrl_cmpt_type),
    .s_axis_cpl_ctrl_wait_pld_pkt_id (axis_qdma_cpl_ctrl_wait_pld_pkt_id),
    .s_axis_cpl_ctrl_port_id         (axis_qdma_cpl_ctrl_port_id),
    .s_axis_cpl_ctrl_marker          (axis_qdma_cpl_ctrl_marker),
    .s_axis_cpl_ctrl_user_trig       (axis_qdma_cpl_ctrl_user_trig),
    .s_axis_cpl_ctrl_col_idx         (axis_qdma_cpl_ctrl_col_idx),
    .s_axis_cpl_ctrl_err_idx         (axis_qdma_cpl_ctrl_err_idx),
    .s_axis_cpl_ctrl_no_wrb_marker   (axis_qdma_cpl_ctrl_no_wrb_marker),
    .s_axis_cpl_tready               (axis_qdma_cpl_tready),

    .h2c_byp_out_vld                 (h2c_byp_out_vld),
    .h2c_byp_out_dsc                 (h2c_byp_out_dsc),
    .h2c_byp_out_st_mm               (h2c_byp_out_st_mm),
    .h2c_byp_out_dsc_sz              (h2c_byp_out_dsc_sz),
    .h2c_byp_out_qid                 (h2c_byp_out_qid),
    .h2c_byp_out_error               (h2c_byp_out_error),
    .h2c_byp_out_func                (h2c_byp_out_func),
    .h2c_byp_out_cidx                (h2c_byp_out_cidx),
    .h2c_byp_out_port_id             (h2c_byp_out_port_id),
    .h2c_byp_out_fmt                 (h2c_byp_out_fmt),
    .h2c_byp_out_rdy                 (h2c_byp_out_rdy),

    .h2c_byp_in_st_vld               (h2c_byp_in_st_vld),
    .h2c_byp_in_st_addr              (h2c_byp_in_st_addr),
    .h2c_byp_in_st_len               (h2c_byp_in_st_len),
    .h2c_byp_in_st_eop               (h2c_byp_in_st_eop),
    .h2c_byp_in_st_sop               (h2c_byp_in_st_sop),
    .h2c_byp_in_st_mrkr_req          (h2c_byp_in_st_mrkr_req),
    .h2c_byp_in_st_port_id           (h2c_byp_in_st_port_id),
    .h2c_byp_in_st_sdi               (h2c_byp_in_st_sdi),
    .h2c_byp_in_st_qid               (h2c_byp_in_st_qid),
    .h2c_byp_in_st_error             (h2c_byp_in_st_error),
    .h2c_byp_in_st_func              (h2c_byp_in_st_func),
    .h2c_byp_in_st_cidx              (h2c_byp_in_st_cidx),
    .h2c_byp_in_st_no_dma            (h2c_byp_in_st_no_dma),
    .h2c_byp_in_st_rdy               (h2c_byp_in_st_rdy),

    .h2c_byp_in_mm_radr              (h2c_byp_in_mm_radr),
    .h2c_byp_in_mm_wadr              (h2c_byp_in_mm_wadr),
    .h2c_byp_in_mm_len               (h2c_byp_in_mm_len),
    .h2c_byp_in_mm_mrkr_req          (h2c_byp_in_mm_mrkr_req),
    .h2c_byp_in_mm_port_id           (h2c_byp_in_mm_port_id),
    .h2c_byp_in_mm_sdi               (h2c_byp_in_mm_sdi),
    .h2c_byp_in_mm_qid               (h2c_byp_in_mm_qid),
    .h2c_byp_in_mm_error             (h2c_byp_in_mm_error),
    .h2c_byp_in_mm_func              (h2c_byp_in_mm_func),
    .h2c_byp_in_mm_cidx              (h2c_byp_in_mm_cidx),
    .h2c_byp_in_mm_no_dma            (h2c_byp_in_mm_no_dma),
    .h2c_byp_in_mm_vld               (h2c_byp_in_mm_vld),
    .h2c_byp_in_mm_rdy               (h2c_byp_in_mm_rdy),

    .c2h_byp_out_vld                 (c2h_byp_out_vld),
    .c2h_byp_out_dsc                 (c2h_byp_out_dsc),
    .c2h_byp_out_st_mm               (c2h_byp_out_st_mm),
    .c2h_byp_out_qid                 (c2h_byp_out_qid),
    .c2h_byp_out_dsc_sz              (c2h_byp_out_dsc_sz),
    .c2h_byp_out_error               (c2h_byp_out_error),
    .c2h_byp_out_func                (c2h_byp_out_func),
    .c2h_byp_out_cidx                (c2h_byp_out_cidx),
    .c2h_byp_out_port_id             (c2h_byp_out_port_id),
    .c2h_byp_out_fmt                 (c2h_byp_out_fmt),
    .c2h_byp_out_pfch_tag            (c2h_byp_out_pfch_tag),
    .c2h_byp_out_rdy                 (c2h_byp_out_rdy),

    .c2h_byp_in_st_csh_vld           (c2h_byp_in_st_csh_vld),
    .c2h_byp_in_st_csh_addr          (c2h_byp_in_st_csh_addr),
    .c2h_byp_in_st_csh_port_id       (c2h_byp_in_st_csh_port_id),
    .c2h_byp_in_st_csh_qid           (c2h_byp_in_st_csh_qid),
    .c2h_byp_in_st_csh_error         (c2h_byp_in_st_csh_error),
    .c2h_byp_in_st_csh_func          (c2h_byp_in_st_csh_func),
    .c2h_byp_in_st_csh_pfch_tag      (c2h_byp_in_st_csh_pfch_tag),
    .c2h_byp_in_st_csh_rdy           (c2h_byp_in_st_csh_rdy),

    .c2h_byp_in_mm_radr              (c2h_byp_in_mm_radr),
    .c2h_byp_in_mm_wadr              (c2h_byp_in_mm_wadr),
    .c2h_byp_in_mm_len               (c2h_byp_in_mm_len),
    .c2h_byp_in_mm_mrkr_req          (c2h_byp_in_mm_mrkr_req),
    .c2h_byp_in_mm_port_id           (c2h_byp_in_mm_port_id),
    .c2h_byp_in_mm_sdi               (c2h_byp_in_mm_sdi),
    .c2h_byp_in_mm_qid               (c2h_byp_in_mm_qid),
    .c2h_byp_in_mm_error             (c2h_byp_in_mm_error),
    .c2h_byp_in_mm_func              (c2h_byp_in_mm_func),
    .c2h_byp_in_mm_cidx              (c2h_byp_in_mm_cidx),
    .c2h_byp_in_mm_vld               (c2h_byp_in_mm_vld),
    .c2h_byp_in_mm_no_dma            (c2h_byp_in_mm_no_dma),
    .c2h_byp_in_mm_rdy               (c2h_byp_in_mm_rdy),

    .s_csr_prog_done                 (s_csr_prog_done),
    .s_axil_csr_awaddr               (s_axil_csr_awaddr),
    .s_axil_csr_awprot               (s_axil_csr_awprot),
    .s_axil_csr_awvalid              (s_axil_csr_awvalid),
    .s_axil_csr_awready              (s_axil_csr_awready),
    .s_axil_csr_wdata                (s_axil_csr_wdata),
    .s_axil_csr_wstrb                (s_axil_csr_wstrb),
    .s_axil_csr_wvalid               (s_axil_csr_wvalid),
    .s_axil_csr_wready               (s_axil_csr_wready),
    .s_axil_csr_bvalid               (s_axil_csr_bvalid),
    .s_axil_csr_bresp                (s_axil_csr_bresp),
    .s_axil_csr_bready               (s_axil_csr_bready),
    .s_axil_csr_araddr               (s_axil_csr_araddr),
    .s_axil_csr_arprot               (s_axil_csr_arprot),
    .s_axil_csr_arvalid              (s_axil_csr_arvalid),
    .s_axil_csr_arready              (s_axil_csr_arready),
    .s_axil_csr_rdata                (s_axil_csr_rdata),
    .s_axil_csr_rresp                (s_axil_csr_rresp),
    .s_axil_csr_rvalid               (s_axil_csr_rvalid),
    .s_axil_csr_rready               (s_axil_csr_rready),

    .s_axib_awid                     (s_axib_awid),
    .s_axib_awaddr                   (s_axib_awaddr),
    .s_axib_awregion                 (s_axib_awregion),
    .s_axib_awlen                    (s_axib_awlen),
    .s_axib_awsize                   (s_axib_awsize),
    .s_axib_awburst                  (s_axib_awburst),
    .s_axib_awvalid                  (s_axib_awvalid),
    .s_axib_wdata                    (s_axib_wdata),
    .s_axib_wstrb                    (s_axib_wstrb),
    .s_axib_wlast                    (s_axib_wlast),
    .s_axib_wvalid                   (s_axib_wvalid),
    .s_axib_wuser                    (s_axib_wuser),
    .s_axib_ruser                    (s_axib_ruser),
    .s_axib_bready                   (s_axib_bready),
    .s_axib_arid                     (s_axib_arid),
    .s_axib_araddr                   (s_axib_araddr),
    .s_axib_aruser                   (s_axib_aruser),
    .s_axib_awuser                   (s_axib_awuser),
    .s_axib_arregion                 (s_axib_arregion),
    .s_axib_arlen                    (s_axib_arlen),
    .s_axib_arsize                   (s_axib_arsize),
    .s_axib_arburst                  (s_axib_arburst),
    .s_axib_arvalid                  (s_axib_arvalid),
    .s_axib_rready                   (s_axib_rready),
    .s_axib_awready                  (s_axib_awready),
    .s_axib_wready                   (s_axib_wready),
    .s_axib_bid                      (s_axib_bid),
    .s_axib_bresp                    (s_axib_bresp),
    .s_axib_bvalid                   (s_axib_bvalid),
    .s_axib_arready                  (s_axib_arready),
    .s_axib_rid                      (s_axib_rid),
    .s_axib_rdata                    (s_axib_rdata),
    .s_axib_rresp                    (s_axib_rresp),
    .s_axib_rlast                    (s_axib_rlast),
    .s_axib_rvalid                   (s_axib_rvalid),

    .pcie_refclk                     (pcie_refclk),
    .pcie_refclk_gt                  (pcie_refclk_gt),
    .pcie_rstn                       (pcie_rstn),
    .user_lnk_up                     (user_lnk_up),
    .phy_ready                       (phy_ready),

    .soft_reset_n                    (axil_aresetn),

    .axil_aclk                       (axil_aclk),
    .axis_aclk                       (axis_aclk),
  `ifdef __au55n__
    .ref_clk_100mhz                  (ref_clk_100mhz),
  `elsif __au55c__
    .ref_clk_100mhz                  (ref_clk_100mhz),
  `elsif __au50__
    .ref_clk_100mhz                  (ref_clk_100mhz),
  `elsif __au280__
    .ref_clk_100mhz                  (ref_clk_100mhz),        
  `endif

    .aresetn                         (powerup_rstn)
  );
`else // !`ifdef __synthesis__
  initial begin
    axil_aclk = 1'b1;
    axis_aclk = 1'b1;

  `ifdef __au55n__
    ref_clk_100mhz = 1'b1;
  `elsif __au55c__
    ref_clk_100mhz = 1'b1;
  `elsif __au50__
    ref_clk_100mhz = 1'b1;
  `elsif __au280__
    ref_clk_100mhz = 1'b1;        
  `endif
  end

  always #4000ps axil_aclk = ~axil_aclk;
  always #2000ps axis_aclk = ~axis_aclk;

`ifdef __au55n__
  always #5000ps ref_clk_100mhz = ~ref_clk_100mhz;
`elsif __au55c__
  always #5000ps ref_clk_100mhz = ~ref_clk_100mhz;
`elsif __au50__
  always #5000ps ref_clk_100mhz = ~ref_clk_100mhz;
`elsif __au280__
  always #5000ps ref_clk_100mhz = ~ref_clk_100mhz;    
`endif

  assign axis_qdma_h2c_tvalid                 = s_axis_qdma_h2c_tvalid;
  assign axis_qdma_h2c_tdata                  = s_axis_qdma_h2c_tdata;
  assign axis_qdma_h2c_tcrc                   = s_axis_qdma_h2c_tcrc;
  assign axis_qdma_h2c_tlast                  = s_axis_qdma_h2c_tlast;
  assign axis_qdma_h2c_tuser_qid              = s_axis_qdma_h2c_tuser_qid;
  assign axis_qdma_h2c_tuser_port_id          = s_axis_qdma_h2c_tuser_port_id;
  assign axis_qdma_h2c_tuser_err              = s_axis_qdma_h2c_tuser_err;
  assign axis_qdma_h2c_tuser_mdata            = s_axis_qdma_h2c_tuser_mdata;
  assign axis_qdma_h2c_tuser_mty              = s_axis_qdma_h2c_tuser_mty;
  assign axis_qdma_h2c_tuser_zero_byte        = s_axis_qdma_h2c_tuser_zero_byte;
  assign s_axis_qdma_h2c_tready               = axis_qdma_h2c_tready;

  assign m_axis_qdma_c2h_tvalid               = axis_qdma_c2h_tvalid;
  assign m_axis_qdma_c2h_tdata                = axis_qdma_c2h_tdata;
  assign m_axis_qdma_c2h_tcrc                 = axis_qdma_c2h_tcrc;
  assign m_axis_qdma_c2h_tlast                = axis_qdma_c2h_tlast;
  assign m_axis_qdma_c2h_ctrl_marker          = axis_qdma_c2h_ctrl_marker;
  assign m_axis_qdma_c2h_ctrl_port_id         = axis_qdma_c2h_ctrl_port_id;
  assign m_axis_qdma_c2h_ctrl_ecc             = axis_qdma_c2h_ctrl_ecc;
  assign m_axis_qdma_c2h_ctrl_len             = axis_qdma_c2h_ctrl_len;
  assign m_axis_qdma_c2h_ctrl_qid             = axis_qdma_c2h_ctrl_qid;
  assign m_axis_qdma_c2h_ctrl_has_cmpt        = axis_qdma_c2h_ctrl_has_cmpt;
  assign m_axis_qdma_c2h_mty                  = axis_qdma_c2h_mty;
  assign axis_qdma_c2h_tready                 = m_axis_qdma_c2h_tready;

  assign m_axis_qdma_cpl_tvalid               = axis_qdma_cpl_tvalid;
  assign m_axis_qdma_cpl_tdata                = axis_qdma_cpl_tdata;
  assign m_axis_qdma_cpl_size                 = axis_qdma_cpl_size;
  assign m_axis_qdma_cpl_dpar                 = axis_qdma_cpl_dpar;
  assign m_axis_qdma_cpl_ctrl_qid             = axis_qdma_cpl_ctrl_qid;
  assign m_axis_qdma_cpl_ctrl_cmpt_type       = axis_qdma_cpl_ctrl_cmpt_type;
  assign m_axis_qdma_cpl_ctrl_wait_pld_pkt_id = axis_qdma_cpl_ctrl_wait_pld_pkt_id;
  assign m_axis_qdma_cpl_ctrl_port_id         = axis_qdma_cpl_ctrl_port_id;
  assign m_axis_qdma_cpl_ctrl_marker          = axis_qdma_cpl_ctrl_marker;
  assign m_axis_qdma_cpl_ctrl_user_trig       = axis_qdma_cpl_ctrl_user_trig;
  assign m_axis_qdma_cpl_ctrl_col_idx         = axis_qdma_cpl_ctrl_col_idx;
  assign m_axis_qdma_cpl_ctrl_err_idx         = axis_qdma_cpl_ctrl_err_idx;
  assign m_axis_qdma_cpl_ctrl_no_wrb_marker   = axis_qdma_cpl_ctrl_no_wrb_marker;
  assign axis_qdma_cpl_tready                 = m_axis_qdma_cpl_tready;
`endif

  generate if (USE_PHYS_FUNC == 0) begin
    // Terminate the AXI-lite interface for QDMA subsystem registers
    axi_lite_slave #(
      .REG_ADDR_W (15),
      .REG_PREFIX (16'h0D0A) // for "QDMA"
    ) qdma_reg_inst (
      .s_axil_awvalid (s_axil_awvalid),
      .s_axil_awaddr  (s_axil_awaddr),
      .s_axil_awready (s_axil_awready),
      .s_axil_wvalid  (s_axil_wvalid),
      .s_axil_wdata   (s_axil_wdata),
      .s_axil_wready  (s_axil_wready),
      .s_axil_bvalid  (s_axil_bvalid),
      .s_axil_bresp   (s_axil_bresp),
      .s_axil_bready  (s_axil_bready),
      .s_axil_arvalid (s_axil_arvalid),
      .s_axil_araddr  (s_axil_araddr),
      .s_axil_arready (s_axil_arready),
      .s_axil_rvalid  (s_axil_rvalid),
      .s_axil_rdata   (s_axil_rdata),
      .s_axil_rresp   (s_axil_rresp),
      .s_axil_rready  (s_axil_rready),

      .aresetn        (axil_aresetn),
      .aclk           (axil_aclk)
    );

    // Terminate H2C and C2H interfaces to QDMA IP
    assign axis_qdma_h2c_tready               = 1'b1;

    assign axis_qdma_c2h_tvalid               = 1'b0;
    assign axis_qdma_c2h_tdata                = 0;
    assign axis_qdma_c2h_tcrc                 = 0;
    assign axis_qdma_c2h_tlast                = 1'b0;
    assign axis_qdma_c2h_ctrl_marker          = 1'b0;
    assign axis_qdma_c2h_ctrl_port_id         = 0;
    assign axis_qdma_c2h_ctrl_ecc             = 0;
    assign axis_qdma_c2h_ctrl_len             = 0;
    assign axis_qdma_c2h_ctrl_qid             = 0;
    assign axis_qdma_c2h_ctrl_has_cmpt        = 1'b0;
    assign axis_qdma_c2h_mty                  = 0;

    assign axis_qdma_cpl_tvalid               = 1'b0;
    assign axis_qdma_cpl_tdata                = 0;
    assign axis_qdma_cpl_size                 = 0;
    assign axis_qdma_cpl_dpar                 = 0;
    assign axis_qdma_cpl_ctrl_qid             = 0;
    assign axis_qdma_cpl_ctrl_cmpt_type       = 0;
    assign axis_qdma_cpl_ctrl_wait_pld_pkt_id = 0;
    assign axis_qdma_cpl_ctrl_port_id         = 0;
    assign axis_qdma_cpl_ctrl_marker          = 1'b0;
    assign axis_qdma_cpl_ctrl_user_trig       = 1'b0;
    assign axis_qdma_cpl_ctrl_col_idx         = 0;
    assign axis_qdma_cpl_ctrl_err_idx         = 0;
    assign axis_qdma_cpl_ctrl_no_wrb_marker   = 1'b0;

    // Terminate H2C and C2H interfaces of the shell
    assign m_axis_h2c_tvalid     = 1'b0;
    assign m_axis_h2c_tdata      = 0;
    assign m_axis_h2c_tkeep      = 0;
    assign m_axis_h2c_tlast      = 1'b0;
    assign m_axis_h2c_tuser_size = 0;
    assign m_axis_h2c_tuser_src  = 0;
    assign m_axis_h2c_tuser_dst  = 0;
    assign m_axis_h2c_tuser_user = 0;

    assign s_axis_c2h_tready     = 1'b1;
  end
  else begin
    wire                         axil_awvalid;
    wire                  [31:0] axil_awaddr;
    wire                         axil_awready;
    wire                         axil_wvalid;
    wire                  [31:0] axil_wdata;
    wire                         axil_wready;
    wire                         axil_bvalid;
    wire                   [1:0] axil_bresp;
    wire                         axil_bready;
    wire                         axil_arvalid;
    wire                  [31:0] axil_araddr;
    wire                         axil_arready;
    wire                         axil_rvalid;
    wire                  [31:0] axil_rdata;
    wire                   [1:0] axil_rresp;
    wire                         axil_rready;

    wire   [1*NUM_PHYS_FUNC-1:0] axil_func_awvalid;
    wire  [32*NUM_PHYS_FUNC-1:0] axil_func_awaddr;
    wire   [1*NUM_PHYS_FUNC-1:0] axil_func_awready;
    wire   [1*NUM_PHYS_FUNC-1:0] axil_func_wvalid;
    wire  [32*NUM_PHYS_FUNC-1:0] axil_func_wdata;
    wire   [1*NUM_PHYS_FUNC-1:0] axil_func_wready;
    wire   [1*NUM_PHYS_FUNC-1:0] axil_func_bvalid;
    wire   [2*NUM_PHYS_FUNC-1:0] axil_func_bresp;
    wire   [1*NUM_PHYS_FUNC-1:0] axil_func_bready;
    wire   [1*NUM_PHYS_FUNC-1:0] axil_func_arvalid;
    wire  [32*NUM_PHYS_FUNC-1:0] axil_func_araddr;
    wire   [1*NUM_PHYS_FUNC-1:0] axil_func_arready;
    wire   [1*NUM_PHYS_FUNC-1:0] axil_func_rvalid;
    wire  [32*NUM_PHYS_FUNC-1:0] axil_func_rdata;
    wire   [2*NUM_PHYS_FUNC-1:0] axil_func_rresp;
    wire   [1*NUM_PHYS_FUNC-1:0] axil_func_rready;

    wire     [NUM_PHYS_FUNC-1:0] axis_h2c_tvalid;
    wire [512*NUM_PHYS_FUNC-1:0] axis_h2c_tdata;
    wire     [NUM_PHYS_FUNC-1:0] axis_h2c_tlast;
    wire  [16*NUM_PHYS_FUNC-1:0] axis_h2c_tuser_size;
    wire  [11*NUM_PHYS_FUNC-1:0] axis_h2c_tuser_qid;
    wire     [NUM_PHYS_FUNC-1:0] axis_h2c_tready;

    wire                         h2c_status_valid;
    wire                  [15:0] h2c_status_bytes;
    wire                   [1:0] h2c_status_func_id;

    wire     [NUM_PHYS_FUNC-1:0] axis_c2h_tvalid;
    wire [512*NUM_PHYS_FUNC-1:0] axis_c2h_tdata;
    wire     [NUM_PHYS_FUNC-1:0] axis_c2h_tlast;
    wire  [16*NUM_PHYS_FUNC-1:0] axis_c2h_tuser_size;
    wire  [11*NUM_PHYS_FUNC-1:0] axis_c2h_tuser_qid;
    wire     [NUM_PHYS_FUNC-1:0] axis_c2h_tready;

    wire                         c2h_status_valid;
    wire                  [15:0] c2h_status_bytes;
    wire                   [1:0] c2h_status_func_id;

    qdma_subsystem_address_map #(
      .NUM_PHYS_FUNC (NUM_PHYS_FUNC)
    ) address_map_inst (
      .s_axil_awvalid      (s_axil_awvalid),
      .s_axil_awaddr       (s_axil_awaddr),
      .s_axil_awready      (s_axil_awready),
      .s_axil_wvalid       (s_axil_wvalid),
      .s_axil_wdata        (s_axil_wdata),
      .s_axil_wready       (s_axil_wready),
      .s_axil_bvalid       (s_axil_bvalid),
      .s_axil_bresp        (s_axil_bresp),
      .s_axil_bready       (s_axil_bready),
      .s_axil_arvalid      (s_axil_arvalid),
      .s_axil_araddr       (s_axil_araddr),
      .s_axil_arready      (s_axil_arready),
      .s_axil_rvalid       (s_axil_rvalid),
      .s_axil_rdata        (s_axil_rdata),
      .s_axil_rresp        (s_axil_rresp),
      .s_axil_rready       (s_axil_rready),

      .m_axil_awvalid      (axil_awvalid),
      .m_axil_awaddr       (axil_awaddr),
      .m_axil_awready      (axil_awready),
      .m_axil_wvalid       (axil_wvalid),
      .m_axil_wdata        (axil_wdata),
      .m_axil_wready       (axil_wready),
      .m_axil_bvalid       (axil_bvalid),
      .m_axil_bresp        (axil_bresp),
      .m_axil_bready       (axil_bready),
      .m_axil_arvalid      (axil_arvalid),
      .m_axil_araddr       (axil_araddr),
      .m_axil_arready      (axil_arready),
      .m_axil_rvalid       (axil_rvalid),
      .m_axil_rdata        (axil_rdata),
      .m_axil_rresp        (axil_rresp),
      .m_axil_rready       (axil_rready),

      .m_axil_func_awvalid (axil_func_awvalid),
      .m_axil_func_awaddr  (axil_func_awaddr),
      .m_axil_func_awready (axil_func_awready),
      .m_axil_func_wvalid  (axil_func_wvalid),
      .m_axil_func_wdata   (axil_func_wdata),
      .m_axil_func_wready  (axil_func_wready),
      .m_axil_func_bvalid  (axil_func_bvalid),
      .m_axil_func_bresp   (axil_func_bresp),
      .m_axil_func_bready  (axil_func_bready),
      .m_axil_func_arvalid (axil_func_arvalid),
      .m_axil_func_araddr  (axil_func_araddr),
      .m_axil_func_arready (axil_func_arready),
      .m_axil_func_rvalid  (axil_func_rvalid),
      .m_axil_func_rdata   (axil_func_rdata),
      .m_axil_func_rresp   (axil_func_rresp),
      .m_axil_func_rready  (axil_func_rready),

      .aclk                (axil_aclk),
      .aresetn             (axil_aresetn)
    );

    qdma_subsystem_register reg_inst (
      .s_axil_awvalid (axil_awvalid),
      .s_axil_awaddr  (axil_awaddr),
      .s_axil_awready (axil_awready),
      .s_axil_wvalid  (axil_wvalid),
      .s_axil_wdata   (axil_wdata),
      .s_axil_wready  (axil_wready),
      .s_axil_bvalid  (axil_bvalid),
      .s_axil_bresp   (axil_bresp),
      .s_axil_bready  (axil_bready),
      .s_axil_arvalid (axil_arvalid),
      .s_axil_araddr  (axil_araddr),
      .s_axil_arready (axil_arready),
      .s_axil_rvalid  (axil_rvalid),
      .s_axil_rdata   (axil_rdata),
      .s_axil_rresp   (axil_rresp),
      .s_axil_rready  (axil_rready),

      .axil_aclk      (axil_aclk),
      .axis_aclk      (axis_aclk),
      .axil_aresetn   (axil_aresetn)
    );

    qdma_subsystem_h2c #(
      .NUM_PHYS_FUNC (NUM_PHYS_FUNC)
    ) h2c_inst (
      .s_axis_qdma_h2c_tvalid          (axis_qdma_h2c_tvalid),
      .s_axis_qdma_h2c_tdata           (axis_qdma_h2c_tdata),
      .s_axis_qdma_h2c_tcrc            (axis_qdma_h2c_tcrc),
      .s_axis_qdma_h2c_tlast           (axis_qdma_h2c_tlast),
      .s_axis_qdma_h2c_tuser_qid       (axis_qdma_h2c_tuser_qid),
      .s_axis_qdma_h2c_tuser_port_id   (axis_qdma_h2c_tuser_port_id),
      .s_axis_qdma_h2c_tuser_err       (axis_qdma_h2c_tuser_err),
      .s_axis_qdma_h2c_tuser_mdata     (axis_qdma_h2c_tuser_mdata),
      .s_axis_qdma_h2c_tuser_mty       (axis_qdma_h2c_tuser_mty),
      .s_axis_qdma_h2c_tuser_zero_byte (axis_qdma_h2c_tuser_zero_byte),
      .s_axis_qdma_h2c_tready          (axis_qdma_h2c_tready),

      .m_axis_h2c_tvalid               (axis_h2c_tvalid),
      .m_axis_h2c_tdata                (axis_h2c_tdata),
      .m_axis_h2c_tlast                (axis_h2c_tlast),
      .m_axis_h2c_tuser_size           (axis_h2c_tuser_size),
      .m_axis_h2c_tuser_qid            (axis_h2c_tuser_qid),
      .m_axis_h2c_tready               (axis_h2c_tready),

      .h2c_status_valid                (h2c_status_valid),
      .h2c_status_bytes                (h2c_status_bytes),
      .h2c_status_func_id              (h2c_status_func_id),

      .axis_aclk                       (axis_aclk),
      .axil_aresetn                    (axil_aresetn)
    );

    qdma_subsystem_c2h #(
      .NUM_PHYS_FUNC (NUM_PHYS_FUNC)
    ) c2h_inst (
      .s_axis_c2h_tvalid                    (axis_c2h_tvalid),
      .s_axis_c2h_tdata                     (axis_c2h_tdata),
      .s_axis_c2h_tlast                     (axis_c2h_tlast),
      .s_axis_c2h_tuser_size                (axis_c2h_tuser_size),
      .s_axis_c2h_tuser_qid                 (axis_c2h_tuser_qid),
      .s_axis_c2h_tready                    (axis_c2h_tready),

      .m_axis_qdma_c2h_tvalid               (axis_qdma_c2h_tvalid),
      .m_axis_qdma_c2h_tdata                (axis_qdma_c2h_tdata),
      .m_axis_qdma_c2h_tcrc                 (axis_qdma_c2h_tcrc),
      .m_axis_qdma_c2h_tlast                (axis_qdma_c2h_tlast),
      .m_axis_qdma_c2h_ctrl_marker          (axis_qdma_c2h_ctrl_marker),
      .m_axis_qdma_c2h_ctrl_port_id         (axis_qdma_c2h_ctrl_port_id),
      .m_axis_qdma_c2h_ctrl_ecc             (axis_qdma_c2h_ctrl_ecc),
      .m_axis_qdma_c2h_ctrl_len             (axis_qdma_c2h_ctrl_len),
      .m_axis_qdma_c2h_ctrl_qid             (axis_qdma_c2h_ctrl_qid),
      .m_axis_qdma_c2h_ctrl_has_cmpt        (axis_qdma_c2h_ctrl_has_cmpt),
      .m_axis_qdma_c2h_mty                  (axis_qdma_c2h_mty),
      .m_axis_qdma_c2h_tready               (axis_qdma_c2h_tready),

      .m_axis_qdma_cpl_tvalid               (axis_qdma_cpl_tvalid),
      .m_axis_qdma_cpl_tdata                (axis_qdma_cpl_tdata),
      .m_axis_qdma_cpl_size                 (axis_qdma_cpl_size),
      .m_axis_qdma_cpl_dpar                 (axis_qdma_cpl_dpar),
      .m_axis_qdma_cpl_ctrl_qid             (axis_qdma_cpl_ctrl_qid),
      .m_axis_qdma_cpl_ctrl_cmpt_type       (axis_qdma_cpl_ctrl_cmpt_type),
      .m_axis_qdma_cpl_ctrl_wait_pld_pkt_id (axis_qdma_cpl_ctrl_wait_pld_pkt_id),
      .m_axis_qdma_cpl_ctrl_port_id         (axis_qdma_cpl_ctrl_port_id),
      .m_axis_qdma_cpl_ctrl_marker          (axis_qdma_cpl_ctrl_marker),
      .m_axis_qdma_cpl_ctrl_user_trig       (axis_qdma_cpl_ctrl_user_trig),
      .m_axis_qdma_cpl_ctrl_col_idx         (axis_qdma_cpl_ctrl_col_idx),
      .m_axis_qdma_cpl_ctrl_err_idx         (axis_qdma_cpl_ctrl_err_idx),
      .m_axis_qdma_cpl_ctrl_no_wrb_marker   (axis_qdma_cpl_ctrl_no_wrb_marker),
      .m_axis_qdma_cpl_tready               (axis_qdma_cpl_tready),

      .c2h_status_valid                     (c2h_status_valid),
      .c2h_status_bytes                     (c2h_status_bytes),
      .c2h_status_func_id                   (c2h_status_func_id),

      .axis_aclk                            (axis_aclk),
      .axil_aresetn                         (axil_aresetn)
    );

    for (genvar i = 0; i < NUM_PHYS_FUNC; i++) begin
      qdma_subsystem_function #(
        .FUNC_ID     (i),
        .MAX_PKT_LEN (MAX_PKT_LEN),
        .MIN_PKT_LEN (MIN_PKT_LEN)
      ) func_inst (
        .s_axil_awvalid        (axil_func_awvalid[i]),
        .s_axil_awaddr         (axil_func_awaddr[`getvec(32, i)]),
        .s_axil_awready        (axil_func_awready[i]),
        .s_axil_wvalid         (axil_func_wvalid[i]),
        .s_axil_wdata          (axil_func_wdata[`getvec(32, i)]),
        .s_axil_wready         (axil_func_wready[i]),
        .s_axil_bvalid         (axil_func_bvalid[i]),
        .s_axil_bresp          (axil_func_bresp[`getvec(2, i)]),
        .s_axil_bready         (axil_func_bready[i]),
        .s_axil_arvalid        (axil_func_arvalid[i]),
        .s_axil_araddr         (axil_func_araddr[`getvec(32, i)]),
        .s_axil_arready        (axil_func_arready[i]),
        .s_axil_rvalid         (axil_func_rvalid[i]),
        .s_axil_rdata          (axil_func_rdata[`getvec(32, i)]),
        .s_axil_rresp          (axil_func_rresp[`getvec(2, i)]),
        .s_axil_rready         (axil_func_rready[i]),

        .s_axis_h2c_tvalid     (axis_h2c_tvalid[i]),
        .s_axis_h2c_tdata      (axis_h2c_tdata[`getvec(512, i)]),
        .s_axis_h2c_tlast      (axis_h2c_tlast[i]),
        .s_axis_h2c_tuser_size (axis_h2c_tuser_size[`getvec(16, i)]),
        .s_axis_h2c_tuser_qid  (axis_h2c_tuser_qid[`getvec(11, i)]),
        .s_axis_h2c_tready     (axis_h2c_tready[i]),

        .m_axis_h2c_tvalid     (m_axis_h2c_tvalid[i]),
        .m_axis_h2c_tdata      (m_axis_h2c_tdata[`getvec(512, i)]),
        .m_axis_h2c_tkeep      (m_axis_h2c_tkeep[`getvec(64, i)]),
        .m_axis_h2c_tlast      (m_axis_h2c_tlast[i]),
        .m_axis_h2c_tuser_size (m_axis_h2c_tuser_size[`getvec(16, i)]),
        .m_axis_h2c_tuser_src  (m_axis_h2c_tuser_src[`getvec(16, i)]),
        .m_axis_h2c_tuser_dst  (m_axis_h2c_tuser_dst[`getvec(16, i)]),
        .m_axis_h2c_tready     (m_axis_h2c_tready[i]),

        .s_axis_c2h_tvalid     (s_axis_c2h_tvalid[i]),
        .s_axis_c2h_tdata      (s_axis_c2h_tdata[`getvec(512, i)]),
        .s_axis_c2h_tkeep      (s_axis_c2h_tkeep[`getvec(64, i)]),
        .s_axis_c2h_tlast      (s_axis_c2h_tlast[i]),
        .s_axis_c2h_tuser_size (s_axis_c2h_tuser_size[`getvec(16, i)]),
        .s_axis_c2h_tuser_src  (s_axis_c2h_tuser_src[`getvec(16, i)]),
        .s_axis_c2h_tuser_dst  (s_axis_c2h_tuser_dst[`getvec(16, i)]),
        .s_axis_c2h_tready     (s_axis_c2h_tready[i]),

        .m_axis_c2h_tvalid     (axis_c2h_tvalid[i]),
        .m_axis_c2h_tdata      (axis_c2h_tdata[`getvec(512, i)]),
        .m_axis_c2h_tlast      (axis_c2h_tlast[i]),
        .m_axis_c2h_tuser_size (axis_c2h_tuser_size[`getvec(16, i)]),
        .m_axis_c2h_tuser_qid  (axis_c2h_tuser_qid[`getvec(11, i)]),
        .m_axis_c2h_tready     (axis_c2h_tready[i]),

        .axil_aclk             (axil_aclk),
        .axis_aclk             (axis_aclk),
        .axil_aresetn          (axil_aresetn)
      );
    end

    (* mark_debug = "true" *) logic [47:0] qdma_h2c_pkt_cnt;
    (* mark_debug = "true" *) logic [47:0] qdma_c2h_pkt_cnt;

    always_ff @(posedge axis_aclk)
      if(!axil_aresetn) begin
        qdma_h2c_pkt_cnt <= 0;
        qdma_c2h_pkt_cnt <= 0;
      end
      else begin
        if ((m_axis_h2c_tvalid != 0) && (m_axis_h2c_tready != 0) && (m_axis_h2c_tlast != 0)) begin
          qdma_h2c_pkt_cnt <= qdma_h2c_pkt_cnt + 1;
        end

        if ((s_axis_c2h_tvalid != 0) && (s_axis_c2h_tready != 0) && (axis_c2h_tlast !=0)) begin
          qdma_c2h_pkt_cnt <= qdma_c2h_pkt_cnt + 1;
        end
      end
    end

  endgenerate

endmodule: qdma_subsystem
