// *************************************************************************
//
// Copyright 2023 Xilinx, Inc.
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
module open_nic_shell #(
  parameter [31:0] BUILD_TIMESTAMP = 32'h01010000,
  parameter int    MIN_PKT_LEN     = 64,
  parameter int    MAX_PKT_LEN     = 1518,
  parameter int    USE_PHYS_FUNC   = 1,
  parameter int    NUM_PHYS_FUNC   = 1,
  parameter int    NUM_QUEUE       = 512,
  parameter int    NUM_CMAC_PORT   = 1
) (
`ifdef __synthesis__

  // Fix the CATTRIP issue for AU280, AU50, AU55C, and AU55N custom flow
`ifdef __au280__
  output                         hbm_cattrip,
  input                    [3:0] satellite_gpio,
`elsif __au50__
  output                         hbm_cattrip,
  input                    [1:0] satellite_gpio,
`elsif __au55n__
  output                         hbm_cattrip,
  input                    [3:0] satellite_gpio,
`elsif __au55c__
  output                         hbm_cattrip,
  input                    [3:0] satellite_gpio,
`elsif __au200__
  output                   [1:0] qsfp_resetl, 
  input                    [1:0] qsfp_modprsl,
  input                    [1:0] qsfp_intl,   
  output                   [1:0] qsfp_lpmode,
  output                   [1:0] qsfp_modsell,
  input                    [3:0] satellite_gpio,
`elsif __au250__
  output                   [1:0] qsfp_resetl, 
  input                    [1:0] qsfp_modprsl,
  input                    [1:0] qsfp_intl,   
  output                   [1:0] qsfp_lpmode,
  output                   [1:0] qsfp_modsell,
  input                    [3:0] satellite_gpio,  
`endif

  input                          satellite_uart_0_rxd,
  output                         satellite_uart_0_txd,

  input                   [15:0] pcie_rxp,
  input                   [15:0] pcie_rxn,
  output                  [15:0] pcie_txp,
  output                  [15:0] pcie_txn,
  input                          pcie_refclk_p,
  input                          pcie_refclk_n,
  input                          pcie_rstn,

  output                  [16:0] c0_ddr4_adr,
  output                   [1:0] c0_ddr4_ba,
  output                   [0:0] c0_ddr4_cke,
  output                   [0:0] c0_ddr4_cs_n,
  inout                   [71:0] c0_ddr4_dq,
  output                         c0_ddr4_parity,
  output                   [1:0] c0_ddr4_bg,
  inout                   [17:0] c0_ddr4_dqs_c,
  inout                   [17:0] c0_ddr4_dqs_t,
  output                   [0:0] c0_ddr4_odt,
  output                         c0_ddr4_act_n,
  output                   [0:0] c0_ddr4_ck_c,
  output                   [0:0] c0_ddr4_ck_t,
  input                          c0_sys_clk_p,
  input                          c0_sys_clk_n,
  output                         c0_ddr4_reset_n,

  input    [4*NUM_CMAC_PORT-1:0] qsfp_rxp,
  input    [4*NUM_CMAC_PORT-1:0] qsfp_rxn,
  output   [4*NUM_CMAC_PORT-1:0] qsfp_txp,
  output   [4*NUM_CMAC_PORT-1:0] qsfp_txn,
  input      [NUM_CMAC_PORT-1:0] qsfp_refclk_p,
  input      [NUM_CMAC_PORT-1:0] qsfp_refclk_n
`else // !`ifdef __synthesis__
  input                          s_axil_sim_awvalid,
  input                   [31:0] s_axil_sim_awaddr,
  output                         s_axil_sim_awready,
  input                          s_axil_sim_wvalid,
  input                   [31:0] s_axil_sim_wdata,
  output                         s_axil_sim_wready,
  output                         s_axil_sim_bvalid,
  output                   [1:0] s_axil_sim_bresp,
  input                          s_axil_sim_bready,
  input                          s_axil_sim_arvalid,
  input                   [31:0] s_axil_sim_araddr,
  output                         s_axil_sim_arready,
  output                         s_axil_sim_rvalid,
  output                  [31:0] s_axil_sim_rdata,
  output                   [1:0] s_axil_sim_rresp,
  input                          s_axil_sim_rready,

  input                          s_axis_qdma_h2c_sim_tvalid,
  input                  [511:0] s_axis_qdma_h2c_sim_tdata,
  input                   [31:0] s_axis_qdma_h2c_sim_tcrc,
  input                          s_axis_qdma_h2c_sim_tlast,
  input                   [10:0] s_axis_qdma_h2c_sim_tuser_qid,
  input                    [2:0] s_axis_qdma_h2c_sim_tuser_port_id,
  input                          s_axis_qdma_h2c_sim_tuser_err,
  input                   [31:0] s_axis_qdma_h2c_sim_tuser_mdata,
  input                    [5:0] s_axis_qdma_h2c_sim_tuser_mty,
  input                          s_axis_qdma_h2c_sim_tuser_zero_byte,
  output                         s_axis_qdma_h2c_sim_tready,

  output                         m_axis_qdma_c2h_sim_tvalid,
  output                 [511:0] m_axis_qdma_c2h_sim_tdata,
  output                  [31:0] m_axis_qdma_c2h_sim_tcrc,
  output                         m_axis_qdma_c2h_sim_tlast,
  output                         m_axis_qdma_c2h_sim_ctrl_marker,
  output                   [2:0] m_axis_qdma_c2h_sim_ctrl_port_id,
  output                   [6:0] m_axis_qdma_c2h_sim_ctrl_ecc,
  output                  [15:0] m_axis_qdma_c2h_sim_ctrl_len,
  output                  [10:0] m_axis_qdma_c2h_sim_ctrl_qid,
  output                         m_axis_qdma_c2h_sim_ctrl_has_cmpt,
  output                   [5:0] m_axis_qdma_c2h_sim_mty,
  input                          m_axis_qdma_c2h_sim_tready,

  output                         m_axis_qdma_cpl_sim_tvalid,
  output                 [511:0] m_axis_qdma_cpl_sim_tdata,
  output                   [1:0] m_axis_qdma_cpl_sim_size,
  output                  [15:0] m_axis_qdma_cpl_sim_dpar,
  output                  [10:0] m_axis_qdma_cpl_sim_ctrl_qid,
  output                   [1:0] m_axis_qdma_cpl_sim_ctrl_cmpt_type,
  output                  [15:0] m_axis_qdma_cpl_sim_ctrl_wait_pld_pkt_id,
  output                   [2:0] m_axis_qdma_cpl_sim_ctrl_port_id,
  output                         m_axis_qdma_cpl_sim_ctrl_marker,
  output                         m_axis_qdma_cpl_sim_ctrl_user_trig,
  output                   [2:0] m_axis_qdma_cpl_sim_ctrl_col_idx,
  output                   [2:0] m_axis_qdma_cpl_sim_ctrl_err_idx,
  output                         m_axis_qdma_cpl_sim_ctrl_no_wrb_marker,
  input                          m_axis_qdma_cpl_sim_tready,

  output     [NUM_CMAC_PORT-1:0] m_axis_cmac_tx_sim_tvalid,
  output [512*NUM_CMAC_PORT-1:0] m_axis_cmac_tx_sim_tdata,
  output  [64*NUM_CMAC_PORT-1:0] m_axis_cmac_tx_sim_tkeep,
  output     [NUM_CMAC_PORT-1:0] m_axis_cmac_tx_sim_tlast,
  output     [NUM_CMAC_PORT-1:0] m_axis_cmac_tx_sim_tuser_err,
  input      [NUM_CMAC_PORT-1:0] m_axis_cmac_tx_sim_tready,

  input      [NUM_CMAC_PORT-1:0] s_axis_cmac_rx_sim_tvalid,
  input  [512*NUM_CMAC_PORT-1:0] s_axis_cmac_rx_sim_tdata,
  input   [64*NUM_CMAC_PORT-1:0] s_axis_cmac_rx_sim_tkeep,
  input      [NUM_CMAC_PORT-1:0] s_axis_cmac_rx_sim_tlast,
  input      [NUM_CMAC_PORT-1:0] s_axis_cmac_rx_sim_tuser_err,

  input                          powerup_rstn
`endif
);

  // Parameter DRC
  initial begin
    if (MIN_PKT_LEN > 256 || MIN_PKT_LEN < 64) begin
      $fatal("[%m] Minimum packet length should be within the range [64, 256]");
    end
    if (MAX_PKT_LEN > 9600 || MAX_PKT_LEN < 256) begin
      $fatal("[%m] Maximum packet length should be within the range [256, 9600]");
    end
    if (USE_PHYS_FUNC) begin
      if (NUM_QUEUE > 2048 || NUM_QUEUE < 1) begin
        $fatal("[%m] Number of queues should be within the range [1, 2048]");
      end
      if ((NUM_QUEUE & (NUM_QUEUE - 1)) != 0) begin
        $fatal("[%m] Number of queues should be 2^n");
      end
      if (NUM_PHYS_FUNC > 4 || NUM_PHYS_FUNC < 1) begin
        $fatal("[%m] Number of physical functions should be within the range [1, 4]");
      end
    end
    if (NUM_CMAC_PORT > 2 || NUM_CMAC_PORT < 1) begin
      $fatal("[%m] Number of CMACs should be within the range [1, 2]");
    end
  end

`ifdef __synthesis__
  logic         powerup_rstn;
  logic         pcie_user_lnk_up;
  logic         pcie_phy_ready;

  // BAR2-mapped master AXI-Lite feeding into system configuration block
  logic         axil_pcie_awvalid;
  logic  [31:0] axil_pcie_awaddr;
  logic         axil_pcie_awready;
  logic         axil_pcie_wvalid;
  logic  [31:0] axil_pcie_wdata;
  logic         axil_pcie_wready;
  logic         axil_pcie_bvalid;
  logic   [1:0] axil_pcie_bresp;
  logic         axil_pcie_bready;
  logic         axil_pcie_arvalid;
  logic  [31:0] axil_pcie_araddr;
  logic         axil_pcie_arready;
  logic         axil_pcie_rvalid;
  logic  [31:0] axil_pcie_rdata;
  logic   [1:0] axil_pcie_rresp;
  logic         axil_pcie_rready;

  IBUF pcie_rstn_ibuf_inst (.I(pcie_rstn), .O(pcie_rstn_int));

`ifdef __au280__
  // Fix the CATTRIP issue for AU280 custom flow
  //
  // This pin must be tied to 0; otherwise the board might be unrecoverable
  // after programming
  OBUF hbm_cattrip_obuf_inst (.I(1'b0), .O(hbm_cattrip));
`elsif __au50__
  // Same for AU50
  OBUF hbm_cattrip_obuf_inst (.I(1'b0), .O(hbm_cattrip));
`endif

`ifdef __zynq_family__
  zynq_usplus_ps zynq_usplus_ps_inst ();
`endif
`endif

  logic                         axil_qdma_awvalid;
  logic                  [31:0] axil_qdma_awaddr;
  logic                         axil_qdma_awready;
  logic                         axil_qdma_wvalid;
  logic                  [31:0] axil_qdma_wdata;
  logic                         axil_qdma_wready;
  logic                         axil_qdma_bvalid;
  logic                   [1:0] axil_qdma_bresp;
  logic                         axil_qdma_bready;
  logic                         axil_qdma_arvalid;
  logic                  [31:0] axil_qdma_araddr;
  logic                         axil_qdma_arready;
  logic                         axil_qdma_rvalid;
  logic                  [31:0] axil_qdma_rdata;
  logic                   [1:0] axil_qdma_rresp;
  logic                         axil_qdma_rready;

  logic                         axi_qdma_mm_awready;
  logic                         axi_qdma_mm_wready;
  logic                   [3:0] axi_qdma_mm_bid;
  logic                   [1:0] axi_qdma_mm_bresp;
  logic                         axi_qdma_mm_bvalid;
  logic                         axi_qdma_mm_arready;
  logic                   [3:0] axi_qdma_mm_rid;
  logic                 [511:0] axi_qdma_mm_rdata;
  logic                   [1:0] axi_qdma_mm_rresp;
  logic                         axi_qdma_mm_rlast;
  logic                         axi_qdma_mm_rvalid;
  logic                   [3:0] axi_qdma_mm_awid;
  logic                  [63:0] axi_qdma_mm_awaddr;
  logic                  [31:0] axi_qdma_mm_awuser;
  logic                   [7:0] axi_qdma_mm_awlen;
  logic                   [2:0] axi_qdma_mm_awsize;
  logic                   [1:0] axi_qdma_mm_awburst;
  logic                   [2:0] axi_qdma_mm_awprot;
  logic                         axi_qdma_mm_awvalid;
  logic                         axi_qdma_mm_awlock;
  logic                   [3:0] axi_qdma_mm_awcache;
  logic                 [511:0] axi_qdma_mm_wdata;
  logic                  [63:0] axi_qdma_mm_wuser;
  logic                  [63:0] axi_qdma_mm_wstrb;
  logic                         axi_qdma_mm_wlast;
  logic                         axi_qdma_mm_wvalid;
  logic                         axi_qdma_mm_bready;
  logic                   [3:0] axi_qdma_mm_arid;
  logic                  [63:0] axi_qdma_mm_araddr;
  logic                  [31:0] axi_qdma_mm_aruser;
  logic                   [7:0] axi_qdma_mm_arlen;
  logic                   [2:0] axi_qdma_mm_arsize;
  logic                   [1:0] axi_qdma_mm_arburst;
  logic                   [2:0] axi_qdma_mm_arprot;
  logic                         axi_qdma_mm_arvalid;
  logic                         axi_qdma_mm_arlock;
  logic                   [3:0] axi_qdma_mm_arcache;
  logic                         axi_qdma_mm_rready;

  // QDMA control/status register interface
  logic                         qdma_csr_prog_done;
  logic                  [31:0] axil_qdma_csr_awaddr;
  logic                         axil_qdma_csr_awvalid;
  logic                         axil_qdma_csr_awready;
  logic                  [31:0] axil_qdma_csr_wdata;
  logic                         axil_qdma_csr_wvalid;
  logic                         axil_qdma_csr_wready;
  logic                         axil_qdma_csr_bvalid;
  logic                   [1:0] axil_qdma_csr_bresp;
  logic                         axil_qdma_csr_bready;
  logic                  [31:0] axil_qdma_csr_araddr;
  logic                         axil_qdma_csr_arvalid;
  logic                         axil_qdma_csr_arready;
  logic                  [31:0] axil_qdma_csr_rdata;
  logic                   [1:0] axil_qdma_csr_rresp;
  logic                         axil_qdma_csr_rvalid;
  logic                         axil_qdma_csr_rready;

  logic     [NUM_CMAC_PORT-1:0] axil_adap_awvalid;
  logic  [32*NUM_CMAC_PORT-1:0] axil_adap_awaddr;
  logic     [NUM_CMAC_PORT-1:0] axil_adap_awready;
  logic     [NUM_CMAC_PORT-1:0] axil_adap_wvalid;
  logic  [32*NUM_CMAC_PORT-1:0] axil_adap_wdata;
  logic     [NUM_CMAC_PORT-1:0] axil_adap_wready;
  logic     [NUM_CMAC_PORT-1:0] axil_adap_bvalid;
  logic   [2*NUM_CMAC_PORT-1:0] axil_adap_bresp;
  logic     [NUM_CMAC_PORT-1:0] axil_adap_bready;
  logic     [NUM_CMAC_PORT-1:0] axil_adap_arvalid;
  logic  [32*NUM_CMAC_PORT-1:0] axil_adap_araddr;
  logic     [NUM_CMAC_PORT-1:0] axil_adap_arready;
  logic     [NUM_CMAC_PORT-1:0] axil_adap_rvalid;
  logic  [32*NUM_CMAC_PORT-1:0] axil_adap_rdata;
  logic   [2*NUM_CMAC_PORT-1:0] axil_adap_rresp;
  logic     [NUM_CMAC_PORT-1:0] axil_adap_rready;

  logic     [NUM_CMAC_PORT-1:0] axil_cmac_awvalid;
  logic  [32*NUM_CMAC_PORT-1:0] axil_cmac_awaddr;
  logic     [NUM_CMAC_PORT-1:0] axil_cmac_awready;
  logic     [NUM_CMAC_PORT-1:0] axil_cmac_wvalid;
  logic  [32*NUM_CMAC_PORT-1:0] axil_cmac_wdata;
  logic     [NUM_CMAC_PORT-1:0] axil_cmac_wready;
  logic     [NUM_CMAC_PORT-1:0] axil_cmac_bvalid;
  logic   [2*NUM_CMAC_PORT-1:0] axil_cmac_bresp;
  logic     [NUM_CMAC_PORT-1:0] axil_cmac_bready;
  logic     [NUM_CMAC_PORT-1:0] axil_cmac_arvalid;
  logic  [32*NUM_CMAC_PORT-1:0] axil_cmac_araddr;
  logic     [NUM_CMAC_PORT-1:0] axil_cmac_arready;
  logic     [NUM_CMAC_PORT-1:0] axil_cmac_rvalid;
  logic  [32*NUM_CMAC_PORT-1:0] axil_cmac_rdata;
  logic   [2*NUM_CMAC_PORT-1:0] axil_cmac_rresp;
  logic     [NUM_CMAC_PORT-1:0] axil_cmac_rready;

  // AXIL interface to the RDMA engine
  logic                         axil_rdma_awvalid;
  logic                  [31:0] axil_rdma_awaddr;
  logic                         axil_rdma_awready;
  logic                         axil_rdma_wvalid;
  logic                  [31:0] axil_rdma_wdata;
  logic                         axil_rdma_wready;
  logic                         axil_rdma_bvalid;
  logic                   [1:0] axil_rdma_bresp;
  logic                         axil_rdma_bready;
  logic                         axil_rdma_arvalid;
  logic                  [31:0] axil_rdma_araddr;
  logic                         axil_rdma_arready;
  logic                         axil_rdma_rvalid;
  logic                  [31:0] axil_rdma_rdata;
  logic                   [1:0] axil_rdma_rresp;
  logic                         axil_rdma_rready;

  logic                         axil_box0_awvalid;
  logic                  [31:0] axil_box0_awaddr;
  logic                         axil_box0_awready;
  logic                         axil_box0_wvalid;
  logic                  [31:0] axil_box0_wdata;
  logic                         axil_box0_wready;
  logic                         axil_box0_bvalid;
  logic                   [1:0] axil_box0_bresp;
  logic                         axil_box0_bready;
  logic                         axil_box0_arvalid;
  logic                  [31:0] axil_box0_araddr;
  logic                         axil_box0_arready;
  logic                         axil_box0_rvalid;
  logic                  [31:0] axil_box0_rdata;
  logic                   [1:0] axil_box0_rresp;
  logic                         axil_box0_rready;

  logic                         axil_box1_awvalid;
  logic                  [31:0] axil_box1_awaddr;
  logic                         axil_box1_awready;
  logic                         axil_box1_wvalid;
  logic                  [31:0] axil_box1_wdata;
  logic                         axil_box1_wready;
  logic                         axil_box1_bvalid;
  logic                   [1:0] axil_box1_bresp;
  logic                         axil_box1_bready;
  logic                         axil_box1_arvalid;
  logic                  [31:0] axil_box1_araddr;
  logic                         axil_box1_arready;
  logic                         axil_box1_rvalid;
  logic                  [31:0] axil_box1_rdata;
  logic                   [1:0] axil_box1_rresp;
  logic                         axil_box1_rready;

  // QDMA subsystem interfaces to the box running at 250MHz
  logic     [NUM_PHYS_FUNC-1:0] axis_qdma_h2c_tvalid;
  logic [512*NUM_PHYS_FUNC-1:0] axis_qdma_h2c_tdata;
  logic  [64*NUM_PHYS_FUNC-1:0] axis_qdma_h2c_tkeep;
  logic     [NUM_PHYS_FUNC-1:0] axis_qdma_h2c_tlast;
  logic  [16*NUM_PHYS_FUNC-1:0] axis_qdma_h2c_tuser_size;
  logic  [16*NUM_PHYS_FUNC-1:0] axis_qdma_h2c_tuser_src;
  logic  [16*NUM_PHYS_FUNC-1:0] axis_qdma_h2c_tuser_dst;
  logic     [NUM_PHYS_FUNC-1:0] axis_qdma_h2c_tready;
  logic     [NUM_PHYS_FUNC-1:0] axis_qdma_c2h_tvalid;
  logic [512*NUM_PHYS_FUNC-1:0] axis_qdma_c2h_tdata;
  logic  [64*NUM_PHYS_FUNC-1:0] axis_qdma_c2h_tkeep;
  logic     [NUM_PHYS_FUNC-1:0] axis_qdma_c2h_tlast;
  logic  [16*NUM_PHYS_FUNC-1:0] axis_qdma_c2h_tuser_size;
  logic  [16*NUM_PHYS_FUNC-1:0] axis_qdma_c2h_tuser_src;
  logic  [16*NUM_PHYS_FUNC-1:0] axis_qdma_c2h_tuser_dst;
  logic     [NUM_PHYS_FUNC-1:0] axis_qdma_c2h_tready;

  // Packet adapter interfaces to the box running at 250MHz
  logic     [NUM_CMAC_PORT-1:0] axis_adap_tx_250mhz_tvalid;
  logic [512*NUM_CMAC_PORT-1:0] axis_adap_tx_250mhz_tdata;
  logic  [64*NUM_CMAC_PORT-1:0] axis_adap_tx_250mhz_tkeep;
  logic     [NUM_CMAC_PORT-1:0] axis_adap_tx_250mhz_tlast;
  logic  [16*NUM_CMAC_PORT-1:0] axis_adap_tx_250mhz_tuser_size;
  logic  [16*NUM_CMAC_PORT-1:0] axis_adap_tx_250mhz_tuser_src;
  logic  [16*NUM_CMAC_PORT-1:0] axis_adap_tx_250mhz_tuser_dst;
  logic     [NUM_CMAC_PORT-1:0] axis_adap_tx_250mhz_tready;

  logic     [NUM_CMAC_PORT-1:0] axis_adap_rx_250mhz_tvalid;
  logic [512*NUM_CMAC_PORT-1:0] axis_adap_rx_250mhz_tdata;
  logic  [64*NUM_CMAC_PORT-1:0] axis_adap_rx_250mhz_tkeep;
  logic     [NUM_CMAC_PORT-1:0] axis_adap_rx_250mhz_tlast;
  logic  [16*NUM_CMAC_PORT-1:0] axis_adap_rx_250mhz_tuser_size;
  logic  [16*NUM_CMAC_PORT-1:0] axis_adap_rx_250mhz_tuser_src;
  logic  [16*NUM_CMAC_PORT-1:0] axis_adap_rx_250mhz_tuser_dst;
  logic     [NUM_CMAC_PORT-1:0] axis_adap_rx_250mhz_tready;

  // Packet adapter interfaces to the box running at 322MHz
  logic     [NUM_CMAC_PORT-1:0] axis_adap_tx_322mhz_tvalid;
  logic [512*NUM_CMAC_PORT-1:0] axis_adap_tx_322mhz_tdata;
  logic  [64*NUM_CMAC_PORT-1:0] axis_adap_tx_322mhz_tkeep;
  logic     [NUM_CMAC_PORT-1:0] axis_adap_tx_322mhz_tlast;
  logic     [NUM_CMAC_PORT-1:0] axis_adap_tx_322mhz_tuser_err;
  logic     [NUM_CMAC_PORT-1:0] axis_adap_tx_322mhz_tready;

  logic     [NUM_CMAC_PORT-1:0] axis_adap_rx_322mhz_tvalid;
  logic [512*NUM_CMAC_PORT-1:0] axis_adap_rx_322mhz_tdata;
  logic  [64*NUM_CMAC_PORT-1:0] axis_adap_rx_322mhz_tkeep;
  logic     [NUM_CMAC_PORT-1:0] axis_adap_rx_322mhz_tlast;
  logic     [NUM_CMAC_PORT-1:0] axis_adap_rx_322mhz_tuser_err;

  // CMAC subsystem interfaces to the box running at 322MHz
  logic     [NUM_CMAC_PORT-1:0] axis_cmac_tx_tvalid;
  logic [512*NUM_CMAC_PORT-1:0] axis_cmac_tx_tdata;
  logic  [64*NUM_CMAC_PORT-1:0] axis_cmac_tx_tkeep;
  logic     [NUM_CMAC_PORT-1:0] axis_cmac_tx_tlast;
  logic     [NUM_CMAC_PORT-1:0] axis_cmac_tx_tuser_err;
  logic     [NUM_CMAC_PORT-1:0] axis_cmac_tx_tready;

  logic     [NUM_CMAC_PORT-1:0] axis_cmac_rx_tvalid;
  logic [512*NUM_CMAC_PORT-1:0] axis_cmac_rx_tdata;
  logic  [64*NUM_CMAC_PORT-1:0] axis_cmac_rx_tkeep;
  logic     [NUM_CMAC_PORT-1:0] axis_cmac_rx_tlast;
  logic     [NUM_CMAC_PORT-1:0] axis_cmac_rx_tuser_err;

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

  // RDMA RX interface from CMAC RX, no rx backpressure
  logic [511:0] cmac2rdma_roce_axis_tdata;
  logic  [63:0] cmac2rdma_roce_axis_tkeep;
  logic         cmac2rdma_roce_axis_tvalid;
  logic         cmac2rdma_roce_axis_tlast;
  logic         cmac2rdma_roce_axis_tuser;
  logic         cmac2rdma_roce_axis_tready;

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

  logic         rdma_intr;

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

  // AXI MM interface used to access the device memory
  logic   [4 : 0] axi_dev_mem_awid;
  logic  [63 : 0] axi_dev_mem_awaddr;
  logic   [7 : 0] axi_dev_mem_awlen;
  logic   [2 : 0] axi_dev_mem_awsize;
  logic   [1 : 0] axi_dev_mem_awburst;
  logic           axi_dev_mem_awlock;
  logic   [3 : 0] axi_dev_mem_awqos;
  logic   [3 : 0] axi_dev_mem_awregion;
  logic   [3 : 0] axi_dev_mem_awcache;
  logic   [2 : 0] axi_dev_mem_awprot;
  logic           axi_dev_mem_awvalid;
  logic           axi_dev_mem_awready;
  logic [511 : 0] axi_dev_mem_wdata;
  logic  [63 : 0] axi_dev_mem_wstrb;
  logic           axi_dev_mem_wlast;
  logic           axi_dev_mem_wvalid;
  logic           axi_dev_mem_wready;
  logic   [4 : 0] axi_dev_mem_bid;
  logic   [1 : 0] axi_dev_mem_bresp;
  logic           axi_dev_mem_bvalid;
  logic           axi_dev_mem_bready;
  logic   [4 : 0] axi_dev_mem_arid;
  logic  [63 : 0] axi_dev_mem_araddr;
  logic   [7 : 0] axi_dev_mem_arlen;
  logic   [2 : 0] axi_dev_mem_arsize;
  logic   [1 : 0] axi_dev_mem_arburst;
  logic           axi_dev_mem_arlock;
  logic   [3 : 0] axi_dev_mem_arqos;
  logic   [3 : 0] axi_dev_mem_arregion;
  logic   [3 : 0] axi_dev_mem_arcache;
  logic   [2 : 0] axi_dev_mem_arprot;
  logic           axi_dev_mem_arvalid;
  logic           axi_dev_mem_arready;
  logic   [4 : 0] axi_dev_mem_rid;
  logic [511 : 0] axi_dev_mem_rdata;
  logic   [1 : 0] axi_dev_mem_rresp;
  logic           axi_dev_mem_rlast;
  logic           axi_dev_mem_rvalid;
  logic           axi_dev_mem_rready;

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

  // AXI MM interface used to access the system memory (s_axib_* of the QDMA IP)
  logic   [2 : 0] axi_sys_mem_awid;
  logic  [63 : 0] axi_sys_mem_awaddr;
  logic   [7 : 0] axi_sys_mem_awlen;
  logic   [2 : 0] axi_sys_mem_awsize;
  logic   [1 : 0] axi_sys_mem_awburst;
  logic           axi_sys_mem_awlock;
  logic   [3 : 0] axi_sys_mem_awqos;
  logic   [3 : 0] axi_sys_mem_awregion;
  logic   [3 : 0] axi_sys_mem_awcache;
  logic   [2 : 0] axi_sys_mem_awprot;
  logic           axi_sys_mem_awvalid;
  logic           axi_sys_mem_awready;
  logic [511 : 0] axi_sys_mem_wdata;
  logic  [63 : 0] axi_sys_mem_wstrb;
  logic           axi_sys_mem_wlast;
  logic           axi_sys_mem_wvalid;
  logic           axi_sys_mem_wready;
  logic   [3 : 0] axi_sys_mem_bid;
  logic   [1 : 0] axi_sys_mem_bresp;
  logic           axi_sys_mem_bvalid;
  logic           axi_sys_mem_bready;
  logic   [2 : 0] axi_sys_mem_arid;
  logic  [63 : 0] axi_sys_mem_araddr;
  logic   [7 : 0] axi_sys_mem_arlen;
  logic   [2 : 0] axi_sys_mem_arsize;
  logic   [1 : 0] axi_sys_mem_arburst;
  logic           axi_sys_mem_arlock;
  logic   [3 : 0] axi_sys_mem_arqos;
  logic   [3 : 0] axi_sys_mem_arregion;
  logic   [3 : 0] axi_sys_mem_arcache;
  logic   [2 : 0] axi_sys_mem_arprot;
  logic           axi_sys_mem_arvalid;
  logic           axi_sys_mem_arready;
  logic   [3 : 0] axi_sys_mem_rid;
  logic [511 : 0] axi_sys_mem_rdata;
  logic   [1 : 0] axi_sys_mem_rresp;
  logic           axi_sys_mem_rlast;
  logic           axi_sys_mem_rvalid;
  logic           axi_sys_mem_rready;
  logic  [63 : 0] axi_sys_mem_wuser;
  logic  [63 : 0] axi_sys_mem_ruser;
  logic  [11 : 0] axi_sys_mem_awuser;
  logic  [11 : 0] axi_sys_mem_aruser;

  //AXI interface between system mem crossbar and device mem crossbar
  logic   [2 : 0] axi_from_sys_to_dev_crossbar_awid;
  logic  [63 : 0] axi_from_sys_to_dev_crossbar_awaddr;
  //logic  [31 : 0] axi_from_sys_to_dev_crossbar_awuser;
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
  logic   [4 : 0] axi_from_sys_to_dev_crossbar_bid;
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
  logic   [4 : 0] axi_from_sys_to_dev_crossbar_rid;
  logic [511 : 0] axi_from_sys_to_dev_crossbar_rdata;
  logic   [1 : 0] axi_from_sys_to_dev_crossbar_rresp;
  logic           axi_from_sys_to_dev_crossbar_rlast;
  logic           axi_from_sys_to_dev_crossbar_rvalid;
  logic           axi_from_sys_to_dev_crossbar_rready;
  logic           axi_from_sys_to_dev_crossbar_arlock;
  logic   [3 : 0] axi_from_sys_to_dev_crossbar_arqos;

  wire   [63 : 0] axi_from_clk_converter_to_ddr4_awaddr;
  wire    [7 : 0] axi_from_clk_converter_to_ddr4_awlen;
  wire    [2 : 0] axi_from_clk_converter_to_ddr4_awsize;
  wire    [1 : 0] axi_from_clk_converter_to_ddr4_awburst;
  wire    [0 : 0] axi_from_clk_converter_to_ddr4_awlock;
  wire    [3 : 0] axi_from_clk_converter_to_ddr4_awcache;
  wire    [2 : 0] axi_from_clk_converter_to_ddr4_awprot;
  wire    [3 : 0] axi_from_clk_converter_to_ddr4_awregion;
  wire    [3 : 0] axi_from_clk_converter_to_ddr4_awqos;
  wire            axi_from_clk_converter_to_ddr4_awvalid;
  wire            axi_from_clk_converter_to_ddr4_awready;
  wire  [511 : 0] axi_from_clk_converter_to_ddr4_wdata;
  wire   [63 : 0] axi_from_clk_converter_to_ddr4_wstrb;
  wire            axi_from_clk_converter_to_ddr4_wlast;
  wire            axi_from_clk_converter_to_ddr4_wvalid;
  wire            axi_from_clk_converter_to_ddr4_wready;
  wire    [1 : 0] axi_from_clk_converter_to_ddr4_bresp;
  wire            axi_from_clk_converter_to_ddr4_bvalid;
  wire            axi_from_clk_converter_to_ddr4_bready;
  wire   [63 : 0] axi_from_clk_converter_to_ddr4_araddr;
  wire    [7 : 0] axi_from_clk_converter_to_ddr4_arlen;
  wire    [2 : 0] axi_from_clk_converter_to_ddr4_arsize;
  wire    [1 : 0] axi_from_clk_converter_to_ddr4_arburst;
  wire    [0 : 0] axi_from_clk_converter_to_ddr4_arlock;
  wire    [3 : 0] axi_from_clk_converter_to_ddr4_arcache;
  wire    [2 : 0] axi_from_clk_converter_to_ddr4_arprot;
  wire    [3 : 0] axi_from_clk_converter_to_ddr4_arregion;
  wire    [3 : 0] axi_from_clk_converter_to_ddr4_arqos;
  wire            axi_from_clk_converter_to_ddr4_arvalid;
  wire            axi_from_clk_converter_to_ddr4_arready;
  wire  [511 : 0] axi_from_clk_converter_to_ddr4_rdata;
  wire    [1 : 0] axi_from_clk_converter_to_ddr4_rresp;
  wire            axi_from_clk_converter_to_ddr4_rlast;
  wire            axi_from_clk_converter_to_ddr4_rvalid;
  wire            axi_from_clk_converter_to_ddr4_rready;
  wire    [4 : 0] axi_from_clk_converter_to_ddr4_awid;
  wire    [4 : 0] axi_from_clk_converter_to_ddr4_rid;
  wire    [4 : 0] axi_from_clk_converter_to_ddr4_arid;
  wire    [4 : 0] axi_from_clk_converter_to_ddr4_bid;

  wire            c0_ddr4_ui_clk;
  wire            c0_ddr4_ui_clk_sync_rst;

  wire            c0_init_calib_complete;


  logic                  [31:0] shell_rstn;
  logic                  [31:0] shell_rst_done;
  logic                         qdma_rstn;
  logic                         qdma_rst_done;
  logic     [NUM_CMAC_PORT-1:0] adap_rstn;
  logic     [NUM_CMAC_PORT-1:0] adap_rst_done;
  logic     [NUM_CMAC_PORT-1:0] cmac_rstn;
  logic     [NUM_CMAC_PORT-1:0] cmac_rst_done;
  logic                         rdma_rstn;
  logic                         rdma_rst_done;

  logic                  [31:0] user_rstn;
  logic                  [31:0] user_rst_done;
  logic                  [15:0] user_250mhz_rstn;
  logic                  [15:0] user_250mhz_rst_done;
  logic                   [7:0] user_322mhz_rstn;
  logic                   [7:0] user_322mhz_rst_done;
  logic                         box_250mhz_rstn;
  logic                         box_250mhz_rst_done;
  logic                         box_322mhz_rstn;
  logic                         box_322mhz_rst_done;

  logic                         axil_aclk;
  logic                         axis_aclk;

`ifdef __au55n__
  logic                         ref_clk_100mhz;
`elsif __au55c__
  logic                         ref_clk_100mhz;
`elsif __au50__
  logic                         ref_clk_100mhz;
`elsif __au280__
  logic                         ref_clk_100mhz;    
`endif

  logic     [NUM_CMAC_PORT-1:0] cmac_clk;

  // Unused reset pairs must have their "reset_done" tied to 1

  // First 4-bit for QDMA subsystem
  assign qdma_rstn           = shell_rstn[0];
  assign shell_rst_done[0]   = qdma_rst_done;
  assign rdma_rstn           = shell_rstn[1];
  assign shell_rst_done[1]   = rdma_rst_done;
  assign shell_rst_done[2]   = qdma_csr_prog_done;
  assign shell_rst_done[3]   = 1'b1;
  //assign shell_rst_done[3:2] = 2'b11;

  // For each CMAC port, use the subsequent 4-bit: bit 0 for CMAC subsystem and
  // bit 1 for the corresponding adapter
  generate for (genvar i = 0; i < NUM_CMAC_PORT; i++) begin: cmac_rst
    assign {adap_rstn[i], cmac_rstn[i]} = {shell_rstn[(i+1)*4+1], shell_rstn[(i+1)*4]};
    assign shell_rst_done[(i+1)*4 +: 4] = {2'b11, adap_rst_done[i], cmac_rst_done[i]};
  end: cmac_rst
  endgenerate

  generate for (genvar i = (NUM_CMAC_PORT+1)*4; i < 32; i++) begin: unused_rst
    assign shell_rst_done[i] = 1'b1;
  end: unused_rst
  endgenerate

  // The box running at 250MHz takes 16+1 user reset pairs, with the extra one
  // used by the box itself.  Similarly, the box running at 322MHz takes 8+1
  // pairs.  The mapping is as follows.
  //
  // | 31    | 30    | 29 ... 24 | 23 ... 16 | 15 ... 0 |
  // ----------------------------------------------------
  // | b@250 | b@322 | Reserved  | user@322  | user@250 |
  assign user_250mhz_rstn     = user_rstn[15:0];
  assign user_rst_done[15:0]  = user_250mhz_rst_done;
  assign user_322mhz_rstn     = user_rstn[23:16];
  assign user_rst_done[23:16] = user_322mhz_rst_done;

  assign box_250mhz_rstn      = user_rstn[31];
  assign user_rst_done[31]    = box_250mhz_rst_done;
  assign box_322mhz_rstn      = user_rstn[30];
  assign user_rst_done[30]    = box_322mhz_rst_done;

  // Unused pairs must have their rst_done signals tied to 1
  assign user_rst_done[29:24] = {6{1'b1}};

  system_config #(
    .BUILD_TIMESTAMP (BUILD_TIMESTAMP),
    .NUM_CMAC_PORT   (NUM_CMAC_PORT)
  ) system_config_inst (
`ifdef __synthesis__
    .s_axil_awvalid      (axil_pcie_awvalid),
    .s_axil_awaddr       (axil_pcie_awaddr),
    .s_axil_awready      (axil_pcie_awready),
    .s_axil_wvalid       (axil_pcie_wvalid),
    .s_axil_wdata        (axil_pcie_wdata),
    .s_axil_wready       (axil_pcie_wready),
    .s_axil_bvalid       (axil_pcie_bvalid),
    .s_axil_bresp        (axil_pcie_bresp),
    .s_axil_bready       (axil_pcie_bready),
    .s_axil_arvalid      (axil_pcie_arvalid),
    .s_axil_araddr       (axil_pcie_araddr),
    .s_axil_arready      (axil_pcie_arready),
    .s_axil_rvalid       (axil_pcie_rvalid),
    .s_axil_rdata        (axil_pcie_rdata),
    .s_axil_rresp        (axil_pcie_rresp),
    .s_axil_rready       (axil_pcie_rready),
`else // !`ifdef __synthesis__
    .s_axil_awvalid      (s_axil_sim_awvalid),
    .s_axil_awaddr       (s_axil_sim_awaddr),
    .s_axil_awready      (s_axil_sim_awready),
    .s_axil_wvalid       (s_axil_sim_wvalid),
    .s_axil_wdata        (s_axil_sim_wdata),
    .s_axil_wready       (s_axil_sim_wready),
    .s_axil_bvalid       (s_axil_sim_bvalid),
    .s_axil_bresp        (s_axil_sim_bresp),
    .s_axil_bready       (s_axil_sim_bready),
    .s_axil_arvalid      (s_axil_sim_arvalid),
    .s_axil_araddr       (s_axil_sim_araddr),
    .s_axil_arready      (s_axil_sim_arready),
    .s_axil_rvalid       (s_axil_sim_rvalid),
    .s_axil_rdata        (s_axil_sim_rdata),
    .s_axil_rresp        (s_axil_sim_rresp),
    .s_axil_rready       (s_axil_sim_rready),
`endif

    .m_axil_qdma_awvalid (axil_qdma_awvalid),
    .m_axil_qdma_awaddr  (axil_qdma_awaddr),
    .m_axil_qdma_awready (axil_qdma_awready),
    .m_axil_qdma_wvalid  (axil_qdma_wvalid),
    .m_axil_qdma_wdata   (axil_qdma_wdata),
    .m_axil_qdma_wready  (axil_qdma_wready),
    .m_axil_qdma_bvalid  (axil_qdma_bvalid),
    .m_axil_qdma_bresp   (axil_qdma_bresp),
    .m_axil_qdma_bready  (axil_qdma_bready),
    .m_axil_qdma_arvalid (axil_qdma_arvalid),
    .m_axil_qdma_araddr  (axil_qdma_araddr),
    .m_axil_qdma_arready (axil_qdma_arready),
    .m_axil_qdma_rvalid  (axil_qdma_rvalid),
    .m_axil_qdma_rdata   (axil_qdma_rdata),
    .m_axil_qdma_rresp   (axil_qdma_rresp),
    .m_axil_qdma_rready  (axil_qdma_rready),

    .m_axil_qdma_csr_awaddr (axil_qdma_csr_awaddr),
    .m_axil_qdma_csr_awvalid(axil_qdma_csr_awvalid),
    // Only allowed to program axil csr interface when qdma_csr_prog_done is 1'b1
    .m_axil_qdma_csr_awready(axil_qdma_csr_awready && qdma_csr_prog_done),
    .m_axil_qdma_csr_wdata  (axil_qdma_csr_wdata),
    .m_axil_qdma_csr_wvalid (axil_qdma_csr_wvalid),
    .m_axil_qdma_csr_wready (axil_qdma_csr_wready),
    .m_axil_qdma_csr_bvalid (axil_qdma_csr_bvalid),
    .m_axil_qdma_csr_bresp  (axil_qdma_csr_bresp),
    .m_axil_qdma_csr_bready (axil_qdma_csr_bready),
    .m_axil_qdma_csr_araddr (axil_qdma_csr_araddr),
    .m_axil_qdma_csr_arvalid(axil_qdma_csr_arvalid),
    .m_axil_qdma_csr_arready(axil_qdma_csr_arready),
    .m_axil_qdma_csr_rdata  (axil_qdma_csr_rdata),
    .m_axil_qdma_csr_rresp  (axil_qdma_csr_rresp),
    .m_axil_qdma_csr_rvalid (axil_qdma_csr_rvalid),
    .m_axil_qdma_csr_rready (axil_qdma_csr_rready),

    .m_axil_adap_awvalid (axil_adap_awvalid),
    .m_axil_adap_awaddr  (axil_adap_awaddr),
    .m_axil_adap_awready (axil_adap_awready),
    .m_axil_adap_wvalid  (axil_adap_wvalid),
    .m_axil_adap_wdata   (axil_adap_wdata),
    .m_axil_adap_wready  (axil_adap_wready),
    .m_axil_adap_bvalid  (axil_adap_bvalid),
    .m_axil_adap_bresp   (axil_adap_bresp),
    .m_axil_adap_bready  (axil_adap_bready),
    .m_axil_adap_arvalid (axil_adap_arvalid),
    .m_axil_adap_araddr  (axil_adap_araddr),
    .m_axil_adap_arready (axil_adap_arready),
    .m_axil_adap_rvalid  (axil_adap_rvalid),
    .m_axil_adap_rdata   (axil_adap_rdata),
    .m_axil_adap_rresp   (axil_adap_rresp),
    .m_axil_adap_rready  (axil_adap_rready),

    .m_axil_cmac_awvalid (axil_cmac_awvalid),
    .m_axil_cmac_awaddr  (axil_cmac_awaddr),
    .m_axil_cmac_awready (axil_cmac_awready),
    .m_axil_cmac_wvalid  (axil_cmac_wvalid),
    .m_axil_cmac_wdata   (axil_cmac_wdata),
    .m_axil_cmac_wready  (axil_cmac_wready),
    .m_axil_cmac_bvalid  (axil_cmac_bvalid),
    .m_axil_cmac_bresp   (axil_cmac_bresp),
    .m_axil_cmac_bready  (axil_cmac_bready),
    .m_axil_cmac_arvalid (axil_cmac_arvalid),
    .m_axil_cmac_araddr  (axil_cmac_araddr),
    .m_axil_cmac_arready (axil_cmac_arready),
    .m_axil_cmac_rvalid  (axil_cmac_rvalid),
    .m_axil_cmac_rdata   (axil_cmac_rdata),
    .m_axil_cmac_rresp   (axil_cmac_rresp),
    .m_axil_cmac_rready  (axil_cmac_rready),

    .m_axil_rdma_awvalid (axil_rdma_awvalid),
    .m_axil_rdma_awaddr  (axil_rdma_awaddr),
    .m_axil_rdma_awready (axil_rdma_awready),
    .m_axil_rdma_wvalid  (axil_rdma_wvalid),
    .m_axil_rdma_wdata   (axil_rdma_wdata),
    .m_axil_rdma_wready  (axil_rdma_wready),
    .m_axil_rdma_bvalid  (axil_rdma_bvalid),
    .m_axil_rdma_bresp   (axil_rdma_bresp),
    .m_axil_rdma_bready  (axil_rdma_bready),
    .m_axil_rdma_arvalid (axil_rdma_arvalid),
    .m_axil_rdma_araddr  (axil_rdma_araddr),
    .m_axil_rdma_arready (axil_rdma_arready),
    .m_axil_rdma_rvalid  (axil_rdma_rvalid),
    .m_axil_rdma_rdata   (axil_rdma_rdata),
    .m_axil_rdma_rresp   (axil_rdma_rresp),
    .m_axil_rdma_rready  (axil_rdma_rready),

    .m_axil_box0_awvalid (axil_box0_awvalid),
    .m_axil_box0_awaddr  (axil_box0_awaddr),
    .m_axil_box0_awready (axil_box0_awready),
    .m_axil_box0_wvalid  (axil_box0_wvalid),
    .m_axil_box0_wdata   (axil_box0_wdata),
    .m_axil_box0_wready  (axil_box0_wready),
    .m_axil_box0_bvalid  (axil_box0_bvalid),
    .m_axil_box0_bresp   (axil_box0_bresp),
    .m_axil_box0_bready  (axil_box0_bready),
    .m_axil_box0_arvalid (axil_box0_arvalid),
    .m_axil_box0_araddr  (axil_box0_araddr),
    .m_axil_box0_arready (axil_box0_arready),
    .m_axil_box0_rvalid  (axil_box0_rvalid),
    .m_axil_box0_rdata   (axil_box0_rdata),
    .m_axil_box0_rresp   (axil_box0_rresp),
    .m_axil_box0_rready  (axil_box0_rready),

    .m_axil_box1_awvalid (axil_box1_awvalid),
    .m_axil_box1_awaddr  (axil_box1_awaddr),
    .m_axil_box1_awready (axil_box1_awready),
    .m_axil_box1_wvalid  (axil_box1_wvalid),
    .m_axil_box1_wdata   (axil_box1_wdata),
    .m_axil_box1_wready  (axil_box1_wready),
    .m_axil_box1_bvalid  (axil_box1_bvalid),
    .m_axil_box1_bresp   (axil_box1_bresp),
    .m_axil_box1_bready  (axil_box1_bready),
    .m_axil_box1_arvalid (axil_box1_arvalid),
    .m_axil_box1_araddr  (axil_box1_araddr),
    .m_axil_box1_arready (axil_box1_arready),
    .m_axil_box1_rvalid  (axil_box1_rvalid),
    .m_axil_box1_rdata   (axil_box1_rdata),
    .m_axil_box1_rresp   (axil_box1_rresp),
    .m_axil_box1_rready  (axil_box1_rready),

    .shell_rstn          (shell_rstn),
    .shell_rst_done      (shell_rst_done),
    .user_rstn           (user_rstn),
    .user_rst_done       (user_rst_done),

    .satellite_uart_0_rxd (satellite_uart_0_rxd),
    .satellite_uart_0_txd (satellite_uart_0_txd),
    .satellite_gpio_0     (satellite_gpio),

  `ifdef __au280__
    .hbm_temp_1_0            (7'd0),
    .hbm_temp_2_0            (7'd0),
    .interrupt_hbm_cattrip_0 (1'b0),
  `elsif __au55n__
    .hbm_temp_1_0            (7'd0),
    .hbm_temp_2_0            (7'd0),
    .interrupt_hbm_cattrip_0 (1'b0),  
  `elsif __au55c__
    .hbm_temp_1_0            (7'd0),
    .hbm_temp_2_0            (7'd0),
    .interrupt_hbm_cattrip_0 (1'b0), 
  `elsif __au50__ 
    .hbm_temp_1_0            (7'd0),
    .hbm_temp_2_0            (7'd0),
    .interrupt_hbm_cattrip_0 (1'b0),
  `elsif __au200__
    .qsfp_resetl             (qsfp_resetl),
    .qsfp_modprsl            (qsfp_modprsl),
    .qsfp_intl               (qsfp_intl),  
    .qsfp_lpmode             (qsfp_lpmode),
    .qsfp_modsell            (qsfp_modsell),    
  `elsif __au250__           
    .qsfp_resetl             (qsfp_resetl),
    .qsfp_modprsl            (qsfp_modprsl),
    .qsfp_intl               (qsfp_intl),  
    .qsfp_lpmode             (qsfp_lpmode),
    .qsfp_modsell            (qsfp_modsell), 
  `endif

    .aclk                (axil_aclk),
    .aresetn             (powerup_rstn)
  );

  qdma_subsystem #(
    .MIN_PKT_LEN   (MIN_PKT_LEN),
    .MAX_PKT_LEN   (MAX_PKT_LEN),
    .USE_PHYS_FUNC (USE_PHYS_FUNC),
    .NUM_PHYS_FUNC (NUM_PHYS_FUNC),
    .NUM_QUEUE     (NUM_QUEUE)
  ) qdma_subsystem_inst (
    .s_axil_awvalid                       (axil_qdma_awvalid),
    .s_axil_awaddr                        (axil_qdma_awaddr),
    .s_axil_awready                       (axil_qdma_awready),
    .s_axil_wvalid                        (axil_qdma_wvalid),
    .s_axil_wdata                         (axil_qdma_wdata),
    .s_axil_wready                        (axil_qdma_wready),
    .s_axil_bvalid                        (axil_qdma_bvalid),
    .s_axil_bresp                         (axil_qdma_bresp),
    .s_axil_bready                        (axil_qdma_bready),
    .s_axil_arvalid                       (axil_qdma_arvalid),
    .s_axil_araddr                        (axil_qdma_araddr),
    .s_axil_arready                       (axil_qdma_arready),
    .s_axil_rvalid                        (axil_qdma_rvalid),
    .s_axil_rdata                         (axil_qdma_rdata),
    .s_axil_rresp                         (axil_qdma_rresp),
    .s_axil_rready                        (axil_qdma_rready),

    .m_axis_h2c_tvalid                    (axis_qdma_h2c_tvalid),
    .m_axis_h2c_tdata                     (axis_qdma_h2c_tdata),
    .m_axis_h2c_tkeep                     (axis_qdma_h2c_tkeep),
    .m_axis_h2c_tlast                     (axis_qdma_h2c_tlast),
    .m_axis_h2c_tuser_size                (axis_qdma_h2c_tuser_size),
    .m_axis_h2c_tuser_src                 (axis_qdma_h2c_tuser_src),
    .m_axis_h2c_tuser_dst                 (axis_qdma_h2c_tuser_dst),
    .m_axis_h2c_tready                    (axis_qdma_h2c_tready),

    .s_axis_c2h_tvalid                    (axis_qdma_c2h_tvalid),
    .s_axis_c2h_tdata                     (axis_qdma_c2h_tdata),
    .s_axis_c2h_tkeep                     (axis_qdma_c2h_tkeep),
    .s_axis_c2h_tlast                     (axis_qdma_c2h_tlast),
    .s_axis_c2h_tuser_size                (axis_qdma_c2h_tuser_size),
    .s_axis_c2h_tuser_src                 (axis_qdma_c2h_tuser_src),
    .s_axis_c2h_tuser_dst                 (axis_qdma_c2h_tuser_dst),
    .s_axis_c2h_tready                    (axis_qdma_c2h_tready),

    // QDMA DMA Engine - AXI MM interface
    .m_axi_awready                        (axi_qdma_mm_awready),
    .m_axi_wready                         (axi_qdma_mm_wready),
    .m_axi_bid                            (axi_qdma_mm_bid),
    .m_axi_bresp                          (axi_qdma_mm_bresp),
    .m_axi_bvalid                         (axi_qdma_mm_bvalid),
    .m_axi_arready                        (axi_qdma_mm_arready),
    .m_axi_rid                            (axi_qdma_mm_rid),
    .m_axi_rdata                          (axi_qdma_mm_rdata),
    .m_axi_rresp                          (axi_qdma_mm_rresp),
    .m_axi_rlast                          (axi_qdma_mm_rlast),
    .m_axi_rvalid                         (axi_qdma_mm_rvalid),
    .m_axi_awid                           (axi_qdma_mm_awid),
    .m_axi_awaddr                         (axi_qdma_mm_awaddr),
    .m_axi_awuser                         (axi_qdma_mm_awuser),
    .m_axi_awlen                          (axi_qdma_mm_awlen),
    .m_axi_awsize                         (axi_qdma_mm_awsize),
    .m_axi_awburst                        (axi_qdma_mm_awburst),
    .m_axi_awprot                         (axi_qdma_mm_awprot),
    .m_axi_awvalid                        (axi_qdma_mm_awvalid),
    .m_axi_awlock                         (axi_qdma_mm_awlock),
    .m_axi_awcache                        (axi_qdma_mm_awcache),
    .m_axi_wdata                          (axi_qdma_mm_wdata),
    .m_axi_wuser                          (axi_qdma_mm_wuser),
    .m_axi_wstrb                          (axi_qdma_mm_wstrb),
    .m_axi_wlast                          (axi_qdma_mm_wlast),
    .m_axi_wvalid                         (axi_qdma_mm_wvalid),
    .m_axi_bready                         (axi_qdma_mm_bready),
    .m_axi_arid                           (axi_qdma_mm_arid),
    .m_axi_araddr                         (axi_qdma_mm_araddr),
    .m_axi_aruser                         (axi_qdma_mm_aruser),
    .m_axi_arlen                          (axi_qdma_mm_arlen),
    .m_axi_arsize                         (axi_qdma_mm_arsize),
    .m_axi_arburst                        (axi_qdma_mm_arburst),
    .m_axi_arprot                         (axi_qdma_mm_arprot),
    .m_axi_arvalid                        (axi_qdma_mm_arvalid),
    .m_axi_arlock                         (axi_qdma_mm_arlock),
    .m_axi_arcache                        (axi_qdma_mm_arcache),
    .m_axi_rready                         (axi_qdma_mm_rready),

`ifdef __synthesis__
    .pcie_rxp                             (pcie_rxp),
    .pcie_rxn                             (pcie_rxn),
    .pcie_txp                             (pcie_txp),
    .pcie_txn                             (pcie_txn),

    .m_axil_pcie_awvalid                  (axil_pcie_awvalid),
    .m_axil_pcie_awaddr                   (axil_pcie_awaddr),
    .m_axil_pcie_awready                  (axil_pcie_awready),
    .m_axil_pcie_wvalid                   (axil_pcie_wvalid),
    .m_axil_pcie_wdata                    (axil_pcie_wdata),
    .m_axil_pcie_wready                   (axil_pcie_wready),
    .m_axil_pcie_bvalid                   (axil_pcie_bvalid),
    .m_axil_pcie_bresp                    (axil_pcie_bresp),
    .m_axil_pcie_bready                   (axil_pcie_bready),
    .m_axil_pcie_arvalid                  (axil_pcie_arvalid),
    .m_axil_pcie_araddr                   (axil_pcie_araddr),
    .m_axil_pcie_arready                  (axil_pcie_arready),
    .m_axil_pcie_rvalid                   (axil_pcie_rvalid),
    .m_axil_pcie_rdata                    (axil_pcie_rdata),
    .m_axil_pcie_rresp                    (axil_pcie_rresp),
    .m_axil_pcie_rready                   (axil_pcie_rready),

    .pcie_refclk_p                        (pcie_refclk_p),
    .pcie_refclk_n                        (pcie_refclk_n),
    .pcie_rstn                            (pcie_rstn_int),
    .user_lnk_up                          (pcie_user_lnk_up),
    .phy_ready                            (pcie_phy_ready),
    .powerup_rstn                         (powerup_rstn),
`else // !`ifdef __synthesis__
    .s_axis_qdma_h2c_tvalid               (s_axis_qdma_h2c_sim_tvalid),
    .s_axis_qdma_h2c_tdata                (s_axis_qdma_h2c_sim_tdata),
    .s_axis_qdma_h2c_tcrc                 (s_axis_qdma_h2c_sim_tcrc),
    .s_axis_qdma_h2c_tlast                (s_axis_qdma_h2c_sim_tlast),
    .s_axis_qdma_h2c_tuser_qid            (s_axis_qdma_h2c_sim_tuser_qid),
    .s_axis_qdma_h2c_tuser_port_id        (s_axis_qdma_h2c_sim_tuser_port_id),
    .s_axis_qdma_h2c_tuser_err            (s_axis_qdma_h2c_sim_tuser_err),
    .s_axis_qdma_h2c_tuser_mdata          (s_axis_qdma_h2c_sim_tuser_mdata),
    .s_axis_qdma_h2c_tuser_mty            (s_axis_qdma_h2c_sim_tuser_mty),
    .s_axis_qdma_h2c_tuser_zero_byte      (s_axis_qdma_h2c_sim_tuser_zero_byte),
    .s_axis_qdma_h2c_tready               (s_axis_qdma_h2c_sim_tready),

    .m_axis_qdma_c2h_tvalid               (m_axis_qdma_c2h_sim_tvalid),
    .m_axis_qdma_c2h_tdata                (m_axis_qdma_c2h_sim_tdata),
    .m_axis_qdma_c2h_tcrc                 (m_axis_qdma_c2h_sim_tcrc),
    .m_axis_qdma_c2h_tlast                (m_axis_qdma_c2h_sim_tlast),
    .m_axis_qdma_c2h_ctrl_marker          (m_axis_qdma_c2h_sim_ctrl_marker),
    .m_axis_qdma_c2h_ctrl_port_id         (m_axis_qdma_c2h_sim_ctrl_port_id),
    .m_axis_qdma_c2h_ctrl_ecc             (m_axis_qdma_c2h_sim_ctrl_ecc),
    .m_axis_qdma_c2h_ctrl_len             (m_axis_qdma_c2h_sim_ctrl_len),
    .m_axis_qdma_c2h_ctrl_qid             (m_axis_qdma_c2h_sim_ctrl_qid),
    .m_axis_qdma_c2h_ctrl_has_cmpt        (m_axis_qdma_c2h_sim_ctrl_has_cmpt),
    .m_axis_qdma_c2h_mty                  (m_axis_qdma_c2h_sim_mty),
    .m_axis_qdma_c2h_tready               (m_axis_qdma_c2h_sim_tready),

    .m_axis_qdma_cpl_tvalid               (m_axis_qdma_cpl_sim_tvalid),
    .m_axis_qdma_cpl_tdata                (m_axis_qdma_cpl_sim_tdata),
    .m_axis_qdma_cpl_size                 (m_axis_qdma_cpl_sim_size),
    .m_axis_qdma_cpl_dpar                 (m_axis_qdma_cpl_sim_dpar),
    .m_axis_qdma_cpl_ctrl_qid             (m_axis_qdma_cpl_sim_ctrl_qid),
    .m_axis_qdma_cpl_ctrl_cmpt_type       (m_axis_qdma_cpl_sim_ctrl_cmpt_type),
    .m_axis_qdma_cpl_ctrl_wait_pld_pkt_id (m_axis_qdma_cpl_sim_ctrl_wait_pld_pkt_id),
    .m_axis_qdma_cpl_ctrl_port_id         (m_axis_qdma_cpl_sim_ctrl_port_id),
    .m_axis_qdma_cpl_ctrl_marker          (m_axis_qdma_cpl_sim_ctrl_marker),
    .m_axis_qdma_cpl_ctrl_user_trig       (m_axis_qdma_cpl_sim_ctrl_user_trig),
    .m_axis_qdma_cpl_ctrl_col_idx         (m_axis_qdma_cpl_sim_ctrl_col_idx),
    .m_axis_qdma_cpl_ctrl_err_idx         (m_axis_qdma_cpl_sim_ctrl_err_idx),
    .m_axis_qdma_cpl_ctrl_no_wrb_marker   (m_axis_qdma_cpl_sim_ctrl_no_wrb_marker),
    .m_axis_qdma_cpl_tready               (m_axis_qdma_cpl_sim_tready),
`endif

    .s_csr_prog_done                      (qdma_csr_prog_done),
    .s_axil_csr_awaddr                    (axil_qdma_csr_awaddr),
    .s_axil_csr_awprot                    (3'd0),
    .s_axil_csr_awvalid                   (axil_qdma_csr_awvalid),
    .s_axil_csr_awready                   (axil_qdma_csr_awready),
    .s_axil_csr_wdata                     (axil_qdma_csr_wdata),
    .s_axil_csr_wstrb                     (4'hf),
    .s_axil_csr_wvalid                    (axil_qdma_csr_wvalid),
    .s_axil_csr_wready                    (axil_qdma_csr_wready),
    .s_axil_csr_bvalid                    (axil_qdma_csr_bvalid),
    .s_axil_csr_bresp                     (axil_qdma_csr_bresp),
    .s_axil_csr_bready                    (axil_qdma_csr_bready),
    .s_axil_csr_araddr                    (axil_qdma_csr_araddr),
    .s_axil_csr_arprot                    (3'd0),
    .s_axil_csr_arvalid                   (axil_qdma_csr_arvalid),
    .s_axil_csr_arready                   (axil_qdma_csr_arready),
    .s_axil_csr_rdata                     (axil_qdma_csr_rdata),
    .s_axil_csr_rresp                     (axil_qdma_csr_rresp),
    .s_axil_csr_rvalid                    (axil_qdma_csr_rvalid),
    .s_axil_csr_rready                    (axil_qdma_csr_rready),

    .s_axib_awid                          ({1'd0,axi_sys_mem_awid}),
    .s_axib_awaddr                        (axi_sys_mem_awaddr),
    .s_axib_awregion                      (axi_sys_mem_awregion),
    .s_axib_awlen                         (axi_sys_mem_awlen),
    .s_axib_awsize                        (axi_sys_mem_awsize),
    .s_axib_awburst                       (axi_sys_mem_awburst),
    .s_axib_awvalid                       (axi_sys_mem_awvalid),
    .s_axib_wdata                         (axi_sys_mem_wdata),
    .s_axib_wstrb                         (axi_sys_mem_wstrb),
    .s_axib_wlast                         (axi_sys_mem_wlast),
    .s_axib_wvalid                        (axi_sys_mem_wvalid),
    .s_axib_wuser                         (axi_sys_mem_wuser),
    .s_axib_ruser                         (axi_sys_mem_ruser),
    .s_axib_bready                        (axi_sys_mem_bready),
    .s_axib_arid                          ({1'd0,axi_sys_mem_arid}),
    .s_axib_araddr                        (axi_sys_mem_araddr),
    .s_axib_aruser                        (axi_sys_mem_aruser),
    .s_axib_awuser                        (axi_sys_mem_awuser),
    .s_axib_arregion                      (axi_sys_mem_arregion),
    .s_axib_arlen                         (axi_sys_mem_arlen),
    .s_axib_arsize                        (axi_sys_mem_arsize),
    .s_axib_arburst                       (axi_sys_mem_arburst),
    .s_axib_arvalid                       (axi_sys_mem_arvalid),
    .s_axib_rready                        (axi_sys_mem_rready),
    .s_axib_awready                       (axi_sys_mem_awready),
    .s_axib_wready                        (axi_sys_mem_wready),
    .s_axib_bid                           (axi_sys_mem_bid),
    .s_axib_bresp                         (axi_sys_mem_bresp),
    .s_axib_bvalid                        (axi_sys_mem_bvalid),
    .s_axib_arready                       (axi_sys_mem_arready),
    .s_axib_rid                           (axi_sys_mem_rid),
    .s_axib_rdata                         (axi_sys_mem_rdata),
    .s_axib_rresp                         (axi_sys_mem_rresp),
    .s_axib_rlast                         (axi_sys_mem_rlast),
    .s_axib_rvalid                        (axi_sys_mem_rvalid),

    .mod_rstn                             (qdma_rstn),
    .mod_rst_done                         (qdma_rst_done),

    .axil_aclk                            (axil_aclk),

    `ifdef __au55n__
      .ref_clk_100mhz                       (ref_clk_100mhz),
    `elsif __au55c__
      .ref_clk_100mhz                       (ref_clk_100mhz),
    `elsif __au50__
      .ref_clk_100mhz                       (ref_clk_100mhz),
    `elsif __au280__
      .ref_clk_100mhz                       (ref_clk_100mhz),            
    `endif

    .axis_aclk                            (axis_aclk)
  );

  generate for (genvar i = 0; i < NUM_CMAC_PORT; i++) begin: cmac_port
    packet_adapter #(
      .CMAC_ID     (i),
      .MIN_PKT_LEN (MIN_PKT_LEN),
      .MAX_PKT_LEN (MAX_PKT_LEN)
    ) packet_adapter_inst (
      .s_axil_awvalid       (axil_adap_awvalid[i]),
      .s_axil_awaddr        (axil_adap_awaddr[`getvec(32, i)]),
      .s_axil_awready       (axil_adap_awready[i]),
      .s_axil_wvalid        (axil_adap_wvalid[i]),
      .s_axil_wdata         (axil_adap_wdata[`getvec(32, i)]),
      .s_axil_wready        (axil_adap_wready[i]),
      .s_axil_bvalid        (axil_adap_bvalid[i]),
      .s_axil_bresp         (axil_adap_bresp[`getvec(2, i)]),
      .s_axil_bready        (axil_adap_bready[i]),
      .s_axil_arvalid       (axil_adap_arvalid[i]),
      .s_axil_araddr        (axil_adap_araddr[`getvec(32, i)]),
      .s_axil_arready       (axil_adap_arready[i]),
      .s_axil_rvalid        (axil_adap_rvalid[i]),
      .s_axil_rdata         (axil_adap_rdata[`getvec(32, i)]),
      .s_axil_rresp         (axil_adap_rresp[`getvec(2, i)]),
      .s_axil_rready        (axil_adap_rready[i]),

      .s_axis_tx_tvalid     (axis_adap_tx_250mhz_tvalid[i]),
      .s_axis_tx_tdata      (axis_adap_tx_250mhz_tdata[`getvec(512, i)]),
      .s_axis_tx_tkeep      (axis_adap_tx_250mhz_tkeep[`getvec(64, i)]),
      .s_axis_tx_tlast      (axis_adap_tx_250mhz_tlast[i]),
      .s_axis_tx_tuser_size (axis_adap_tx_250mhz_tuser_size[`getvec(16, i)]),
      .s_axis_tx_tuser_src  (axis_adap_tx_250mhz_tuser_src[`getvec(16, i)]),
      .s_axis_tx_tuser_dst  (axis_adap_tx_250mhz_tuser_dst[`getvec(16, i)]),
      .s_axis_tx_tready     (axis_adap_tx_250mhz_tready[i]),

      .m_axis_rx_tvalid     (axis_adap_rx_250mhz_tvalid[i]),
      .m_axis_rx_tdata      (axis_adap_rx_250mhz_tdata[`getvec(512, i)]),
      .m_axis_rx_tkeep      (axis_adap_rx_250mhz_tkeep[`getvec(64, i)]),
      .m_axis_rx_tlast      (axis_adap_rx_250mhz_tlast[i]),
      .m_axis_rx_tuser_size (axis_adap_rx_250mhz_tuser_size[`getvec(16, i)]),
      .m_axis_rx_tuser_src  (axis_adap_rx_250mhz_tuser_src[`getvec(16, i)]),
      .m_axis_rx_tuser_dst  (axis_adap_rx_250mhz_tuser_dst[`getvec(16, i)]),
      .m_axis_rx_tready     (axis_adap_rx_250mhz_tready[i]),

      .m_axis_tx_tvalid     (axis_adap_tx_322mhz_tvalid[i]),
      .m_axis_tx_tdata      (axis_adap_tx_322mhz_tdata[`getvec(512, i)]),
      .m_axis_tx_tkeep      (axis_adap_tx_322mhz_tkeep[`getvec(64, i)]),
      .m_axis_tx_tlast      (axis_adap_tx_322mhz_tlast[i]),
      .m_axis_tx_tuser_err  (axis_adap_tx_322mhz_tuser_err[i]),
      .m_axis_tx_tready     (axis_adap_tx_322mhz_tready[i]),

      .s_axis_rx_tvalid     (axis_adap_rx_322mhz_tvalid[i]),
      .s_axis_rx_tdata      (axis_adap_rx_322mhz_tdata[`getvec(512, i)]),
      .s_axis_rx_tkeep      (axis_adap_rx_322mhz_tkeep[`getvec(64, i)]),
      .s_axis_rx_tlast      (axis_adap_rx_322mhz_tlast[i]),
      .s_axis_rx_tuser_err  (axis_adap_rx_322mhz_tuser_err[i]),

      .mod_rstn             (adap_rstn[i]),
      .mod_rst_done         (adap_rst_done[i]),

      .axil_aclk            (axil_aclk),
      .axis_aclk            (axis_aclk),
      .cmac_clk             (cmac_clk[i])
    );

    cmac_subsystem #(
      .CMAC_ID     (i),
      .MIN_PKT_LEN (MIN_PKT_LEN),
      .MAX_PKT_LEN (MAX_PKT_LEN)
    ) cmac_subsystem_inst (
      .s_axil_awvalid               (axil_cmac_awvalid[i]),
      .s_axil_awaddr                (axil_cmac_awaddr[`getvec(32, i)]),
      .s_axil_awready               (axil_cmac_awready[i]),
      .s_axil_wvalid                (axil_cmac_wvalid[i]),
      .s_axil_wdata                 (axil_cmac_wdata[`getvec(32, i)]),
      .s_axil_wready                (axil_cmac_wready[i]),
      .s_axil_bvalid                (axil_cmac_bvalid[i]),
      .s_axil_bresp                 (axil_cmac_bresp[`getvec(2, i)]),
      .s_axil_bready                (axil_cmac_bready[i]),
      .s_axil_arvalid               (axil_cmac_arvalid[i]),
      .s_axil_araddr                (axil_cmac_araddr[`getvec(32, i)]),
      .s_axil_arready               (axil_cmac_arready[i]),
      .s_axil_rvalid                (axil_cmac_rvalid[i]),
      .s_axil_rdata                 (axil_cmac_rdata[`getvec(32, i)]),
      .s_axil_rresp                 (axil_cmac_rresp[`getvec(2, i)]),
      .s_axil_rready                (axil_cmac_rready[i]),

      .s_axis_cmac_tx_tvalid        (axis_cmac_tx_tvalid[i]),
      .s_axis_cmac_tx_tdata         (axis_cmac_tx_tdata[`getvec(512, i)]),
      .s_axis_cmac_tx_tkeep         (axis_cmac_tx_tkeep[`getvec(64, i)]),
      .s_axis_cmac_tx_tlast         (axis_cmac_tx_tlast[i]),
      .s_axis_cmac_tx_tuser_err     (axis_cmac_tx_tuser_err[i]),
      .s_axis_cmac_tx_tready        (axis_cmac_tx_tready[i]),

      .m_axis_cmac_rx_tvalid        (axis_cmac_rx_tvalid[i]),
      .m_axis_cmac_rx_tdata         (axis_cmac_rx_tdata[`getvec(512, i)]),
      .m_axis_cmac_rx_tkeep         (axis_cmac_rx_tkeep[`getvec(64, i)]),
      .m_axis_cmac_rx_tlast         (axis_cmac_rx_tlast[i]),
      .m_axis_cmac_rx_tuser_err     (axis_cmac_rx_tuser_err[i]),

`ifdef __synthesis__
      .gt_rxp                       (qsfp_rxp[`getvec(4, i)]),
      .gt_rxn                       (qsfp_rxn[`getvec(4, i)]),
      .gt_txp                       (qsfp_txp[`getvec(4, i)]),
      .gt_txn                       (qsfp_txn[`getvec(4, i)]),
      .gt_refclk_p                  (qsfp_refclk_p[i]),
      .gt_refclk_n                  (qsfp_refclk_n[i]),

      .cmac_clk                     (cmac_clk[i]),
`else
      .m_axis_cmac_tx_sim_tvalid    (m_axis_cmac_tx_sim_tvalid[i]),
      .m_axis_cmac_tx_sim_tdata     (m_axis_cmac_tx_sim_tdata[`getvec(512, i)]),
      .m_axis_cmac_tx_sim_tkeep     (m_axis_cmac_tx_sim_tkeep[`getvec(64, i)]),
      .m_axis_cmac_tx_sim_tlast     (m_axis_cmac_tx_sim_tlast[i]),
      .m_axis_cmac_tx_sim_tuser_err (m_axis_cmac_tx_sim_tuser_err[i]),
      .m_axis_cmac_tx_sim_tready    (m_axis_cmac_tx_sim_tready[i]),

      .s_axis_cmac_rx_sim_tvalid    (s_axis_cmac_rx_sim_tvalid[i]),
      .s_axis_cmac_rx_sim_tdata     (s_axis_cmac_rx_sim_tdata[`getvec(512, i)]),
      .s_axis_cmac_rx_sim_tkeep     (s_axis_cmac_rx_sim_tkeep[`getvec(64, i)]),
      .s_axis_cmac_rx_sim_tlast     (s_axis_cmac_rx_sim_tlast[i]),
      .s_axis_cmac_rx_sim_tuser_err (s_axis_cmac_rx_sim_tuser_err[i]),

      .cmac_clk                     (cmac_clk[i]),
`endif

      .mod_rstn                     (cmac_rstn[i]),
      .mod_rst_done                 (cmac_rst_done[i]),
      .axil_aclk                    (axil_aclk)
    );
  end: cmac_port
  endgenerate

  // RDMA subsystem
  // TODO: retry buffer and hardware handshaking are not supported at the moment
  rdma_subsystem_wrapper rdma_subsystem_inst (
    // AXIL interface for RDMA control register
    .s_axil_awaddr    (axil_rdma_awaddr),
    .s_axil_awvalid   (axil_rdma_awvalid),
    .s_axil_awready   (axil_rdma_awready),
    .s_axil_wdata     (axil_rdma_wdata),
    .s_axil_wstrb     (4'hf),
    .s_axil_wvalid    (axil_rdma_wvalid),
    .s_axil_wready    (axil_rdma_wready),
    .s_axil_araddr    (axil_rdma_araddr),
    .s_axil_arvalid   (axil_rdma_arvalid),
    .s_axil_arready   (axil_rdma_arready),
    .s_axil_rdata     (axil_rdma_rdata),
    .s_axil_rvalid    (axil_rdma_rvalid),
    .s_axil_rresp     (axil_rdma_rresp),
    .s_axil_rready    (axil_rdma_rready),
    .s_axil_bresp     (axil_rdma_bresp),
    .s_axil_bvalid    (axil_rdma_bvalid),
    .s_axil_bready    (axil_rdma_bready),

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
    .m_axi_rdma_send_write_payload_store_awid    (axi_rdma_send_write_payload_awid),
    .m_axi_rdma_send_write_payload_store_awaddr  (axi_rdma_send_write_payload_awaddr),
    .m_axi_rdma_send_write_payload_store_awuser  (axi_rdma_send_write_payload_awuser),
    .m_axi_rdma_send_write_payload_store_awlen   (axi_rdma_send_write_payload_awlen),
    .m_axi_rdma_send_write_payload_store_awsize  (axi_rdma_send_write_payload_awsize),
    .m_axi_rdma_send_write_payload_store_awburst (axi_rdma_send_write_payload_awburst),
    .m_axi_rdma_send_write_payload_store_awcache (axi_rdma_send_write_payload_awcache),
    .m_axi_rdma_send_write_payload_store_awprot  (axi_rdma_send_write_payload_awprot),
    .m_axi_rdma_send_write_payload_store_awvalid (axi_rdma_send_write_payload_awvalid),
    .m_axi_rdma_send_write_payload_store_awready (axi_rdma_send_write_payload_awready),
    .m_axi_rdma_send_write_payload_store_wdata   (axi_rdma_send_write_payload_wdata),
    .m_axi_rdma_send_write_payload_store_wstrb   (axi_rdma_send_write_payload_wstrb),
    .m_axi_rdma_send_write_payload_store_wlast   (axi_rdma_send_write_payload_wlast),
    .m_axi_rdma_send_write_payload_store_wvalid  (axi_rdma_send_write_payload_wvalid),
    .m_axi_rdma_send_write_payload_store_wready  (axi_rdma_send_write_payload_wready),
    .m_axi_rdma_send_write_payload_store_awlock  (axi_rdma_send_write_payload_awlock),
    .m_axi_rdma_send_write_payload_store_bid     (axi_rdma_send_write_payload_bid),
    .m_axi_rdma_send_write_payload_store_bresp   (axi_rdma_send_write_payload_bresp),
    .m_axi_rdma_send_write_payload_store_bvalid  (axi_rdma_send_write_payload_bvalid),
    .m_axi_rdma_send_write_payload_store_bready  (axi_rdma_send_write_payload_bready),
    .m_axi_rdma_send_write_payload_store_arid    (axi_rdma_send_write_payload_arid),
    .m_axi_rdma_send_write_payload_store_araddr  (axi_rdma_send_write_payload_araddr),
    .m_axi_rdma_send_write_payload_store_arlen   (axi_rdma_send_write_payload_arlen),
    .m_axi_rdma_send_write_payload_store_arsize  (axi_rdma_send_write_payload_arsize),
    .m_axi_rdma_send_write_payload_store_arburst (axi_rdma_send_write_payload_arburst),
    .m_axi_rdma_send_write_payload_store_arcache (axi_rdma_send_write_payload_arcache),
    .m_axi_rdma_send_write_payload_store_arprot  (axi_rdma_send_write_payload_arprot),
    .m_axi_rdma_send_write_payload_store_arvalid (axi_rdma_send_write_payload_arvalid),
    .m_axi_rdma_send_write_payload_store_arready (axi_rdma_send_write_payload_arready),
    .m_axi_rdma_send_write_payload_store_rid     (axi_rdma_send_write_payload_rid),
    .m_axi_rdma_send_write_payload_store_rdata   (axi_rdma_send_write_payload_rdata),
    .m_axi_rdma_send_write_payload_store_rresp   (axi_rdma_send_write_payload_rresp),
    .m_axi_rdma_send_write_payload_store_rlast   (axi_rdma_send_write_payload_rlast),
    .m_axi_rdma_send_write_payload_store_rvalid  (axi_rdma_send_write_payload_rvalid),
    .m_axi_rdma_send_write_payload_store_rready  (axi_rdma_send_write_payload_rready),
    .m_axi_rdma_send_write_payload_store_arlock  (axi_rdma_send_write_payload_arlock),

    // RDMA AXI MM interface used to store payload from RDMA Read response operation
    .m_axi_rdma_rsp_payload_awid          (axi_rdma_rsp_payload_awid),
    .m_axi_rdma_rsp_payload_awaddr        (axi_rdma_rsp_payload_awaddr),
    .m_axi_rdma_rsp_payload_awlen         (axi_rdma_rsp_payload_awlen),
    .m_axi_rdma_rsp_payload_awsize        (axi_rdma_rsp_payload_awsize),
    .m_axi_rdma_rsp_payload_awburst       (axi_rdma_rsp_payload_awburst),
    .m_axi_rdma_rsp_payload_awcache       (axi_rdma_rsp_payload_awcache),
    .m_axi_rdma_rsp_payload_awprot        (axi_rdma_rsp_payload_awprot),
    .m_axi_rdma_rsp_payload_awvalid       (axi_rdma_rsp_payload_awvalid),
    .m_axi_rdma_rsp_payload_awready       (axi_rdma_rsp_payload_awready),
    .m_axi_rdma_rsp_payload_wdata         (axi_rdma_rsp_payload_wdata),
    .m_axi_rdma_rsp_payload_wstrb         (axi_rdma_rsp_payload_wstrb),
    .m_axi_rdma_rsp_payload_wlast         (axi_rdma_rsp_payload_wlast),
    .m_axi_rdma_rsp_payload_wvalid        (axi_rdma_rsp_payload_wvalid),
    .m_axi_rdma_rsp_payload_wready        (axi_rdma_rsp_payload_wready),
    .m_axi_rdma_rsp_payload_awlock        (axi_rdma_rsp_payload_awlock),
    .m_axi_rdma_rsp_payload_bid           (axi_rdma_rsp_payload_bid),
    .m_axi_rdma_rsp_payload_bresp         (axi_rdma_rsp_payload_bresp),
    .m_axi_rdma_rsp_payload_bvalid        (axi_rdma_rsp_payload_bvalid),
    .m_axi_rdma_rsp_payload_bready        (axi_rdma_rsp_payload_bready),
    .m_axi_rdma_rsp_payload_arid          (axi_rdma_rsp_payload_arid),
    .m_axi_rdma_rsp_payload_araddr        (axi_rdma_rsp_payload_araddr),
    .m_axi_rdma_rsp_payload_arlen         (axi_rdma_rsp_payload_arlen),
    .m_axi_rdma_rsp_payload_arsize        (axi_rdma_rsp_payload_arsize),
    .m_axi_rdma_rsp_payload_arburst       (axi_rdma_rsp_payload_arburst),
    .m_axi_rdma_rsp_payload_arcache       (axi_rdma_rsp_payload_arcache),
    .m_axi_rdma_rsp_payload_arprot        (axi_rdma_rsp_payload_arprot),
    .m_axi_rdma_rsp_payload_arvalid       (axi_rdma_rsp_payload_arvalid),
    .m_axi_rdma_rsp_payload_arready       (axi_rdma_rsp_payload_arready),
    .m_axi_rdma_rsp_payload_rid           (axi_rdma_rsp_payload_rid),
    .m_axi_rdma_rsp_payload_rdata         (axi_rdma_rsp_payload_rdata),
    .m_axi_rdma_rsp_payload_rresp         (axi_rdma_rsp_payload_rresp),
    .m_axi_rdma_rsp_payload_rlast         (axi_rdma_rsp_payload_rlast),
    .m_axi_rdma_rsp_payload_rvalid        (axi_rdma_rsp_payload_rvalid),
    .m_axi_rdma_rsp_payload_rready        (axi_rdma_rsp_payload_rready),
    .m_axi_rdma_rsp_payload_arlock        (axi_rdma_rsp_payload_arlock),

    // RDMA AXI MM interface used to fetch WQE entries in the senq queue from DDR by the QP manager
    .m_axi_qp_get_wqe_awid                (axi_rdma_get_wqe_awid),
    .m_axi_qp_get_wqe_awaddr              (axi_rdma_get_wqe_awaddr),
    .m_axi_qp_get_wqe_awlen               (axi_rdma_get_wqe_awlen),
    .m_axi_qp_get_wqe_awsize              (axi_rdma_get_wqe_awsize),
    .m_axi_qp_get_wqe_awburst             (axi_rdma_get_wqe_awburst),
    .m_axi_qp_get_wqe_awcache             (axi_rdma_get_wqe_awcache),
    .m_axi_qp_get_wqe_awprot              (axi_rdma_get_wqe_awprot),
    .m_axi_qp_get_wqe_awvalid             (axi_rdma_get_wqe_awvalid),
    .m_axi_qp_get_wqe_awready             (axi_rdma_get_wqe_awready),
    .m_axi_qp_get_wqe_wdata               (axi_rdma_get_wqe_wdata),
    .m_axi_qp_get_wqe_wstrb               (axi_rdma_get_wqe_wstrb),
    .m_axi_qp_get_wqe_wlast               (axi_rdma_get_wqe_wlast),
    .m_axi_qp_get_wqe_wvalid              (axi_rdma_get_wqe_wvalid),
    .m_axi_qp_get_wqe_wready              (axi_rdma_get_wqe_wready),
    .m_axi_qp_get_wqe_awlock              (axi_rdma_get_wqe_awlock),
    .m_axi_qp_get_wqe_bid                 (axi_rdma_get_wqe_bid),
    .m_axi_qp_get_wqe_bresp               (axi_rdma_get_wqe_bresp),
    .m_axi_qp_get_wqe_bvalid              (axi_rdma_get_wqe_bvalid),
    .m_axi_qp_get_wqe_bready              (axi_rdma_get_wqe_bready),
    .m_axi_qp_get_wqe_arid                (axi_rdma_get_wqe_arid),
    .m_axi_qp_get_wqe_araddr              (axi_rdma_get_wqe_araddr),
    .m_axi_qp_get_wqe_arlen               (axi_rdma_get_wqe_arlen),
    .m_axi_qp_get_wqe_arsize              (axi_rdma_get_wqe_arsize),
    .m_axi_qp_get_wqe_arburst             (axi_rdma_get_wqe_arburst),
    .m_axi_qp_get_wqe_arcache             (axi_rdma_get_wqe_arcache),
    .m_axi_qp_get_wqe_arprot              (axi_rdma_get_wqe_arprot),
    .m_axi_qp_get_wqe_arvalid             (axi_rdma_get_wqe_arvalid),
    .m_axi_qp_get_wqe_arready             (axi_rdma_get_wqe_arready),
    .m_axi_qp_get_wqe_rid                 (axi_rdma_get_wqe_rid),
    .m_axi_qp_get_wqe_rdata               (axi_rdma_get_wqe_rdata),
    .m_axi_qp_get_wqe_rresp               (axi_rdma_get_wqe_rresp),
    .m_axi_qp_get_wqe_rlast               (axi_rdma_get_wqe_rlast),
    .m_axi_qp_get_wqe_rvalid              (axi_rdma_get_wqe_rvalid),
    .m_axi_qp_get_wqe_rready              (axi_rdma_get_wqe_rready),
    .m_axi_qp_get_wqe_arlock              (axi_rdma_get_wqe_arlock),

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
    .m_axi_pktgen_get_payload_awid       (axi_rdma_get_payload_awid),
    .m_axi_pktgen_get_payload_awaddr     (axi_rdma_get_payload_awaddr),
    .m_axi_pktgen_get_payload_awlen      (axi_rdma_get_payload_awlen),
    .m_axi_pktgen_get_payload_awsize     (axi_rdma_get_payload_awsize),
    .m_axi_pktgen_get_payload_awburst    (axi_rdma_get_payload_awburst),
    .m_axi_pktgen_get_payload_awcache    (axi_rdma_get_payload_awcache),
    .m_axi_pktgen_get_payload_awprot     (axi_rdma_get_payload_awprot),
    .m_axi_pktgen_get_payload_awvalid    (axi_rdma_get_payload_awvalid),
    .m_axi_pktgen_get_payload_awready    (axi_rdma_get_payload_awready),
    .m_axi_pktgen_get_payload_wdata      (axi_rdma_get_payload_wdata),
    .m_axi_pktgen_get_payload_wstrb      (axi_rdma_get_payload_wstrb),
    .m_axi_pktgen_get_payload_wlast      (axi_rdma_get_payload_wlast),
    .m_axi_pktgen_get_payload_wvalid     (axi_rdma_get_payload_wvalid),
    .m_axi_pktgen_get_payload_wready     (axi_rdma_get_payload_wready),
    .m_axi_pktgen_get_payload_awlock     (axi_rdma_get_payload_awlock),
    .m_axi_pktgen_get_payload_bid        (axi_rdma_get_payload_bid),
    .m_axi_pktgen_get_payload_bresp      (axi_rdma_get_payload_bresp),
    .m_axi_pktgen_get_payload_bvalid     (axi_rdma_get_payload_bvalid),
    .m_axi_pktgen_get_payload_bready     (axi_rdma_get_payload_bready),
    .m_axi_pktgen_get_payload_arid       (axi_rdma_get_payload_arid),
    .m_axi_pktgen_get_payload_araddr     (axi_rdma_get_payload_araddr),
    .m_axi_pktgen_get_payload_arlen      (axi_rdma_get_payload_arlen),
    .m_axi_pktgen_get_payload_arsize     (axi_rdma_get_payload_arsize),
    .m_axi_pktgen_get_payload_arburst    (axi_rdma_get_payload_arburst),
    .m_axi_pktgen_get_payload_arcache    (axi_rdma_get_payload_arcache),
    .m_axi_pktgen_get_payload_arprot     (axi_rdma_get_payload_arprot),
    .m_axi_pktgen_get_payload_arvalid    (axi_rdma_get_payload_arvalid),
    .m_axi_pktgen_get_payload_arready    (axi_rdma_get_payload_arready),
    .m_axi_pktgen_get_payload_rid        (axi_rdma_get_payload_rid),
    .m_axi_pktgen_get_payload_rdata      (axi_rdma_get_payload_rdata),
    .m_axi_pktgen_get_payload_rresp      (axi_rdma_get_payload_rresp),
    .m_axi_pktgen_get_payload_rlast      (axi_rdma_get_payload_rlast),
    .m_axi_pktgen_get_payload_rvalid     (axi_rdma_get_payload_rvalid),
    .m_axi_pktgen_get_payload_rready     (axi_rdma_get_payload_rready),
    .m_axi_pktgen_get_payload_arlock     (axi_rdma_get_payload_arlock),

    // RDMA AXI MM interface used to write completion entries to a completion queue in the DDR
    .m_axi_write_completion_awid         (axi_rdma_completion_awid),
    .m_axi_write_completion_awaddr       (axi_rdma_completion_awaddr),
    .m_axi_write_completion_awlen        (axi_rdma_completion_awlen),
    .m_axi_write_completion_awsize       (axi_rdma_completion_awsize),
    .m_axi_write_completion_awburst      (axi_rdma_completion_awburst),
    .m_axi_write_completion_awcache      (axi_rdma_completion_awcache),
    .m_axi_write_completion_awprot       (axi_rdma_completion_awprot),
    .m_axi_write_completion_awvalid      (axi_rdma_completion_awvalid),
    .m_axi_write_completion_awready      (axi_rdma_completion_awready),
    .m_axi_write_completion_wdata        (axi_rdma_completion_wdata),
    .m_axi_write_completion_wstrb        (axi_rdma_completion_wstrb),
    .m_axi_write_completion_wlast        (axi_rdma_completion_wlast),
    .m_axi_write_completion_wvalid       (axi_rdma_completion_wvalid),
    .m_axi_write_completion_wready       (axi_rdma_completion_wready),
    .m_axi_write_completion_awlock       (axi_rdma_completion_awlock),
    .m_axi_write_completion_bid          (axi_rdma_completion_bid),
    .m_axi_write_completion_bresp        (axi_rdma_completion_bresp),
    .m_axi_write_completion_bvalid       (axi_rdma_completion_bvalid),
    .m_axi_write_completion_bready       (axi_rdma_completion_bready),
    .m_axi_write_completion_arid         (axi_rdma_completion_arid),
    .m_axi_write_completion_araddr       (axi_rdma_completion_araddr),
    .m_axi_write_completion_arlen        (axi_rdma_completion_arlen),
    .m_axi_write_completion_arsize       (axi_rdma_completion_arsize),
    .m_axi_write_completion_arburst      (axi_rdma_completion_arburst),
    .m_axi_write_completion_arcache      (axi_rdma_completion_arcache),
    .m_axi_write_completion_arprot       (axi_rdma_completion_arprot),
    .m_axi_write_completion_arvalid      (axi_rdma_completion_arvalid),
    .m_axi_write_completion_arready      (axi_rdma_completion_arready),
    .m_axi_write_completion_rid          (axi_rdma_completion_rid),
    .m_axi_write_completion_rdata        (axi_rdma_completion_rdata),
    .m_axi_write_completion_rresp        (axi_rdma_completion_rresp),
    .m_axi_write_completion_rlast        (axi_rdma_completion_rlast),
    .m_axi_write_completion_rvalid       (axi_rdma_completion_rvalid),
    .m_axi_write_completion_rready       (axi_rdma_completion_rready),
    .m_axi_write_completion_arlock       (axi_rdma_completion_arlock),

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

    .mod_rstn     (rdma_rstn),
    .mod_rst_done (rdma_rst_done),
    //.rdma_resetn_done (rdma_resetn_done),
    .axil_clk     (axil_aclk),
    .axis_clk     (axis_aclk)
  );

  axi_3to1_interconnect_to_dev_mem axi_interconnect_to_dev_mem_inst(
    .s_axi_qdma_mm_awid                    ({1'd0,axi_qdma_mm_awid}),
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
    .s_axi_qdma_mm_arid                    ({1'd0,axi_qdma_mm_arid}),
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

    .s_axi_from_sys_crossbar_awid          ({2'd0,axi_from_sys_to_dev_crossbar_awid}),
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
    .s_axi_from_sys_crossbar_arid          ({2'd0,axi_from_sys_to_dev_crossbar_arid}),
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

    .axis_aclk                             (axis_aclk),
    .axis_arestn                           (qdma_rstn)
);

axi_5to2_interconnect_to_sys_mem axi_interconnect_to_sys_mem_inst(
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
    .axis_arestn                           (qdma_rstn)
);

  axi_clock_converter_for_mem  axi_clock_converter_for_ddr_inst (
    .s_axi_aclk      (axis_aclk),
    .s_axi_aresetn   (qdma_rstn),
    .s_axi_awid      (axi_dev_mem_awid),
    .s_axi_awaddr    (axi_dev_mem_awaddr),
    .s_axi_awlen     (axi_dev_mem_awlen),
    .s_axi_awsize    (axi_dev_mem_awsize),
    .s_axi_awburst   (axi_dev_mem_awburst),
    .s_axi_awlock    (1'b0),
    .s_axi_awcache   (4'b0),
    .s_axi_awprot    (3'b0),
    .s_axi_awregion  (4'b0),
    .s_axi_awqos     (4'b0),
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
    .s_axi_araddr    (axi_dev_mem_araddr),
    .s_axi_arlen     (axi_dev_mem_arlen),
    .s_axi_arsize    (axi_dev_mem_arsize),
    .s_axi_arburst   (axi_dev_mem_arburst),
    .s_axi_arlock    (1'b0),
    .s_axi_arcache   (4'b0),
    .s_axi_arprot    (3'b0),
    .s_axi_arregion  (4'b0),
    .s_axi_arqos     (4'b0),
    .s_axi_arvalid   (axi_dev_mem_arvalid),
    .s_axi_arready   (axi_dev_mem_arready),
    .s_axi_rid       (axi_dev_mem_rid),
    .s_axi_rdata     (axi_dev_mem_rdata),
    .s_axi_rresp     (axi_dev_mem_rresp),
    .s_axi_rlast     (axi_dev_mem_rlast),
    .s_axi_rvalid    (axi_dev_mem_rvalid),
    .s_axi_rready    (axi_dev_mem_rready),

    .m_axi_aclk      (c0_ddr4_ui_clk),
    .m_axi_aresetn   (~c0_ddr4_ui_clk_sync_rst),
    .m_axi_awid      (axi_from_clk_converter_to_ddr4_awid),
    .m_axi_awaddr    (axi_from_clk_converter_to_ddr4_awaddr),
    .m_axi_awlen     (axi_from_clk_converter_to_ddr4_awlen),
    .m_axi_awsize    (axi_from_clk_converter_to_ddr4_awsize),
    .m_axi_awburst   (axi_from_clk_converter_to_ddr4_awburst),
    .m_axi_awlock    (axi_from_clk_converter_to_ddr4_awlock),
    .m_axi_awcache   (axi_from_clk_converter_to_ddr4_awcache),
    .m_axi_awprot    (axi_from_clk_converter_to_ddr4_awprot),
    .m_axi_awregion  (axi_from_clk_converter_to_ddr4_awregion),
    .m_axi_awqos     (axi_from_clk_converter_to_ddr4_awqos),
    .m_axi_awvalid   (axi_from_clk_converter_to_ddr4_awvalid),
    .m_axi_awready   (axi_from_clk_converter_to_ddr4_awready),
    .m_axi_wdata     (axi_from_clk_converter_to_ddr4_wdata),
    .m_axi_wstrb     (axi_from_clk_converter_to_ddr4_wstrb),
    .m_axi_wlast     (axi_from_clk_converter_to_ddr4_wlast),
    .m_axi_wvalid    (axi_from_clk_converter_to_ddr4_wvalid),
    .m_axi_wready    (axi_from_clk_converter_to_ddr4_wready),
    .m_axi_bid       (axi_from_clk_converter_to_ddr4_bid),
    .m_axi_bresp     (axi_from_clk_converter_to_ddr4_bresp),
    .m_axi_bvalid    (axi_from_clk_converter_to_ddr4_bvalid),
    .m_axi_bready    (axi_from_clk_converter_to_ddr4_bready),
    .m_axi_arid      (axi_from_clk_converter_to_ddr4_arid),
    .m_axi_araddr    (axi_from_clk_converter_to_ddr4_araddr),
    .m_axi_arlen     (axi_from_clk_converter_to_ddr4_arlen),
    .m_axi_arsize    (axi_from_clk_converter_to_ddr4_arsize),
    .m_axi_arburst   (axi_from_clk_converter_to_ddr4_arburst),
    .m_axi_arlock    (axi_from_clk_converter_to_ddr4_arlock),
    .m_axi_arcache   (axi_from_clk_converter_to_ddr4_arcache),
    .m_axi_arprot    (axi_from_clk_converter_to_ddr4_arprot),
    .m_axi_arregion  (axi_from_clk_converter_to_ddr4_arregion),
    .m_axi_arqos     (axi_from_clk_converter_to_ddr4_arqos),
    .m_axi_arvalid   (axi_from_clk_converter_to_ddr4_arvalid),
    .m_axi_arready   (axi_from_clk_converter_to_ddr4_arready),
    .m_axi_rid       (axi_from_clk_converter_to_ddr4_rid),
    .m_axi_rdata     (axi_from_clk_converter_to_ddr4_rdata),
    .m_axi_rresp     (axi_from_clk_converter_to_ddr4_rresp),
    .m_axi_rlast     (axi_from_clk_converter_to_ddr4_rlast),
    .m_axi_rvalid    (axi_from_clk_converter_to_ddr4_rvalid),
    .m_axi_rready    (axi_from_clk_converter_to_ddr4_rready)
  );

  dev_mem_ddr4_controller  ddr4_inst (
    .dbg_clk(),
    .dbg_bus(),

    .sys_rst(~pcie_rstn_int),
    .c0_sys_clk_p(c0_sys_clk_p),
    .c0_sys_clk_n(c0_sys_clk_n),

    .c0_init_calib_complete(c0_init_calib_complete),

    .c0_ddr4_ui_clk(c0_ddr4_ui_clk),
    .c0_ddr4_ui_clk_sync_rst(c0_ddr4_ui_clk_sync_rst),

    .c0_ddr4_aresetn(pcie_rstn_int),
    .c0_ddr4_adr(c0_ddr4_adr),
    .c0_ddr4_ba(c0_ddr4_ba),
    .c0_ddr4_cke(c0_ddr4_cke),
    .c0_ddr4_cs_n(c0_ddr4_cs_n),
    .c0_ddr4_dq(c0_ddr4_dq),
    .c0_ddr4_dqs_c(c0_ddr4_dqs_c),
    .c0_ddr4_dqs_t(c0_ddr4_dqs_t),
    .c0_ddr4_bg(c0_ddr4_bg),
    .c0_ddr4_parity(c0_ddr4_parity),
    .c0_ddr4_odt(c0_ddr4_odt),
    .c0_ddr4_reset_n(c0_ddr4_reset_n),
    .c0_ddr4_act_n(c0_ddr4_act_n),
    .c0_ddr4_ck_c(c0_ddr4_ck_c),
    .c0_ddr4_ck_t(c0_ddr4_ck_t),

    .c0_ddr4_s_axi_ctrl_wdata(32'b0),
    .c0_ddr4_s_axi_ctrl_bready(1'b0),
    .c0_ddr4_s_axi_ctrl_arvalid(1'b0),
    .c0_ddr4_s_axi_ctrl_araddr(32'b0),
    .c0_ddr4_s_axi_ctrl_rready(1'b0),
    .c0_ddr4_s_axi_ctrl_wvalid(1'b0),
    .c0_ddr4_s_axi_ctrl_awvalid(1'b0),
    .c0_ddr4_s_axi_ctrl_awaddr(32'b0),

    .c0_ddr4_s_axi_awid(axi_from_clk_converter_to_ddr4_awid),
    .c0_ddr4_s_axi_awaddr(axi_from_clk_converter_to_ddr4_awaddr),
    .c0_ddr4_s_axi_awlen(axi_from_clk_converter_to_ddr4_awlen),
    .c0_ddr4_s_axi_awsize(axi_from_clk_converter_to_ddr4_awsize),
    .c0_ddr4_s_axi_awburst(axi_from_clk_converter_to_ddr4_awburst),
    .c0_ddr4_s_axi_awlock(1'b0),
    .c0_ddr4_s_axi_awcache(4'b0),
    .c0_ddr4_s_axi_awprot(3'b0),
    .c0_ddr4_s_axi_awqos(4'b0),
    .c0_ddr4_s_axi_awvalid(axi_from_clk_converter_to_ddr4_awvalid),
    .c0_ddr4_s_axi_awready(axi_from_clk_converter_to_ddr4_awready),
    .c0_ddr4_s_axi_wdata(axi_from_clk_converter_to_ddr4_wdata),
    .c0_ddr4_s_axi_wstrb(axi_from_clk_converter_to_ddr4_wstrb),
    .c0_ddr4_s_axi_wlast(axi_from_clk_converter_to_ddr4_wlast),
    .c0_ddr4_s_axi_wvalid(axi_from_clk_converter_to_ddr4_wvalid),
    .c0_ddr4_s_axi_wready(axi_from_clk_converter_to_ddr4_wready),
    .c0_ddr4_s_axi_bready(axi_from_clk_converter_to_ddr4_bready),
    .c0_ddr4_s_axi_bid(axi_from_clk_converter_to_ddr4_bid),
    .c0_ddr4_s_axi_bresp(axi_from_clk_converter_to_ddr4_bresp),
    .c0_ddr4_s_axi_bvalid(axi_from_clk_converter_to_ddr4_bvalid),
    .c0_ddr4_s_axi_arid(axi_from_clk_converter_to_ddr4_arid),
    .c0_ddr4_s_axi_araddr(axi_from_clk_converter_to_ddr4_araddr),
    .c0_ddr4_s_axi_arlen(axi_from_clk_converter_to_ddr4_arlen),
    .c0_ddr4_s_axi_arsize(axi_from_clk_converter_to_ddr4_arsize),
    .c0_ddr4_s_axi_arburst(axi_from_clk_converter_to_ddr4_arburst),
    .c0_ddr4_s_axi_arlock(1'b0),
    .c0_ddr4_s_axi_arcache(4'b0),
    .c0_ddr4_s_axi_arprot(3'b0),
    .c0_ddr4_s_axi_arqos(4'b0),
    .c0_ddr4_s_axi_arvalid(axi_from_clk_converter_to_ddr4_arvalid),
    .c0_ddr4_s_axi_arready(axi_from_clk_converter_to_ddr4_arready),
    .c0_ddr4_s_axi_rready(axi_from_clk_converter_to_ddr4_rready),
    .c0_ddr4_s_axi_rlast(axi_from_clk_converter_to_ddr4_rlast),
    .c0_ddr4_s_axi_rvalid(axi_from_clk_converter_to_ddr4_rvalid),
    .c0_ddr4_s_axi_rresp(axi_from_clk_converter_to_ddr4_rresp),
    .c0_ddr4_s_axi_rid(axi_from_clk_converter_to_ddr4_rid),
    .c0_ddr4_s_axi_rdata(axi_from_clk_converter_to_ddr4_rdata)
  );

  // User logic boxes
  box_250mhz #(
    .MIN_PKT_LEN   (MIN_PKT_LEN),
    .MAX_PKT_LEN   (MAX_PKT_LEN),
    .USE_PHYS_FUNC (USE_PHYS_FUNC),
    .NUM_PHYS_FUNC (NUM_PHYS_FUNC),
    .NUM_CMAC_PORT (NUM_CMAC_PORT)
  ) box_250mhz_inst (
    .s_axil_awvalid                   (axil_box0_awvalid),
    .s_axil_awaddr                    (axil_box0_awaddr),
    .s_axil_awready                   (axil_box0_awready),
    .s_axil_wvalid                    (axil_box0_wvalid),
    .s_axil_wdata                     (axil_box0_wdata),
    .s_axil_wready                    (axil_box0_wready),
    .s_axil_bvalid                    (axil_box0_bvalid),
    .s_axil_bresp                     (axil_box0_bresp),
    .s_axil_bready                    (axil_box0_bready),
    .s_axil_arvalid                   (axil_box0_arvalid),
    .s_axil_araddr                    (axil_box0_araddr),
    .s_axil_arready                   (axil_box0_arready),
    .s_axil_rvalid                    (axil_box0_rvalid),
    .s_axil_rdata                     (axil_box0_rdata),
    .s_axil_rresp                     (axil_box0_rresp),
    .s_axil_rready                    (axil_box0_rready),

    .s_axis_qdma_h2c_tvalid           (axis_qdma_h2c_tvalid),
    .s_axis_qdma_h2c_tdata            (axis_qdma_h2c_tdata),
    .s_axis_qdma_h2c_tkeep            (axis_qdma_h2c_tkeep),
    .s_axis_qdma_h2c_tlast            (axis_qdma_h2c_tlast),
    .s_axis_qdma_h2c_tuser_size       (axis_qdma_h2c_tuser_size),
    .s_axis_qdma_h2c_tuser_src        (axis_qdma_h2c_tuser_src),
    .s_axis_qdma_h2c_tuser_dst        (axis_qdma_h2c_tuser_dst),
    .s_axis_qdma_h2c_tready           (axis_qdma_h2c_tready),

    .m_axis_qdma_c2h_tvalid           (axis_qdma_c2h_tvalid),
    .m_axis_qdma_c2h_tdata            (axis_qdma_c2h_tdata),
    .m_axis_qdma_c2h_tkeep            (axis_qdma_c2h_tkeep),
    .m_axis_qdma_c2h_tlast            (axis_qdma_c2h_tlast),
    .m_axis_qdma_c2h_tuser_size       (axis_qdma_c2h_tuser_size),
    .m_axis_qdma_c2h_tuser_src        (axis_qdma_c2h_tuser_src),
    .m_axis_qdma_c2h_tuser_dst        (axis_qdma_c2h_tuser_dst),
    .m_axis_qdma_c2h_tready           (axis_qdma_c2h_tready),

    .m_axis_adap_tx_250mhz_tvalid     (axis_adap_tx_250mhz_tvalid),
    .m_axis_adap_tx_250mhz_tdata      (axis_adap_tx_250mhz_tdata),
    .m_axis_adap_tx_250mhz_tkeep      (axis_adap_tx_250mhz_tkeep),
    .m_axis_adap_tx_250mhz_tlast      (axis_adap_tx_250mhz_tlast),
    .m_axis_adap_tx_250mhz_tuser_size (axis_adap_tx_250mhz_tuser_size),
    .m_axis_adap_tx_250mhz_tuser_src  (axis_adap_tx_250mhz_tuser_src),
    .m_axis_adap_tx_250mhz_tuser_dst  (axis_adap_tx_250mhz_tuser_dst),
    .m_axis_adap_tx_250mhz_tready     (axis_adap_tx_250mhz_tready),

    .s_axis_adap_rx_250mhz_tvalid     (axis_adap_rx_250mhz_tvalid),
    .s_axis_adap_rx_250mhz_tdata      (axis_adap_rx_250mhz_tdata),
    .s_axis_adap_rx_250mhz_tkeep      (axis_adap_rx_250mhz_tkeep),
    .s_axis_adap_rx_250mhz_tlast      (axis_adap_rx_250mhz_tlast),
    .s_axis_adap_rx_250mhz_tuser_size (axis_adap_rx_250mhz_tuser_size),
    .s_axis_adap_rx_250mhz_tuser_src  (axis_adap_rx_250mhz_tuser_src),
    .s_axis_adap_rx_250mhz_tuser_dst  (axis_adap_rx_250mhz_tuser_dst),
    .s_axis_adap_rx_250mhz_tready     (axis_adap_rx_250mhz_tready),

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
    .m_axi_compute_logic_awid            (axi_compute_logic_awid),
    .m_axi_compute_logic_awaddr          (axi_compute_logic_awaddr),
    .m_axi_compute_logic_awqos           (axi_compute_logic_awqos),
    .m_axi_compute_logic_awlen           (axi_compute_logic_awlen),
    .m_axi_compute_logic_awsize          (axi_compute_logic_awsize),
    .m_axi_compute_logic_awburst         (axi_compute_logic_awburst),
    .m_axi_compute_logic_awcache         (axi_compute_logic_awcache),
    .m_axi_compute_logic_awprot          (axi_compute_logic_awprot),
    .m_axi_compute_logic_awvalid         (axi_compute_logic_awvalid),
    .m_axi_compute_logic_awready         (axi_compute_logic_awready),
    .m_axi_compute_logic_wdata           (axi_compute_logic_wdata),
    .m_axi_compute_logic_wstrb           (axi_compute_logic_wstrb),
    .m_axi_compute_logic_wlast           (axi_compute_logic_wlast),
    .m_axi_compute_logic_wvalid          (axi_compute_logic_wvalid),
    .m_axi_compute_logic_wready          (axi_compute_logic_wready),
    .m_axi_compute_logic_awlock          (axi_compute_logic_awlock),
    .m_axi_compute_logic_bid             (axi_compute_logic_bid),
    .m_axi_compute_logic_bresp           (axi_compute_logic_bresp),
    .m_axi_compute_logic_bvalid          (axi_compute_logic_bvalid),
    .m_axi_compute_logic_bready          (axi_compute_logic_bready),
    .m_axi_compute_logic_arid            (axi_compute_logic_arid),
    .m_axi_compute_logic_araddr          (axi_compute_logic_araddr),
    .m_axi_compute_logic_arlen           (axi_compute_logic_arlen),
    .m_axi_compute_logic_arsize          (axi_compute_logic_arsize),
    .m_axi_compute_logic_arburst         (axi_compute_logic_arburst),
    .m_axi_compute_logic_arcache         (axi_compute_logic_arcache),
    .m_axi_compute_logic_arprot          (axi_compute_logic_arprot),
    .m_axi_compute_logic_arvalid         (axi_compute_logic_arvalid),
    .m_axi_compute_logic_arready         (axi_compute_logic_arready),
    .m_axi_compute_logic_rid             (axi_compute_logic_rid),
    .m_axi_compute_logic_rdata           (axi_compute_logic_rdata),
    .m_axi_compute_logic_rresp           (axi_compute_logic_rresp),
    .m_axi_compute_logic_rlast           (axi_compute_logic_rlast),
    .m_axi_compute_logic_rvalid          (axi_compute_logic_rvalid),
    .m_axi_compute_logic_rready          (axi_compute_logic_rready),
    .m_axi_compute_logic_arlock          (axi_compute_logic_arlock),
    .m_axi_compute_logic_arqos           (axi_compute_logic_arqos),

    .mod_rstn     (user_250mhz_rstn),
    .mod_rst_done (user_250mhz_rst_done),

    .box_rstn     (box_250mhz_rstn),
    .box_rst_done (box_250mhz_rst_done),

    .axil_aclk    (axil_aclk),
    .axis_aclk    (axis_aclk)
  );

  box_322mhz #(
    .MIN_PKT_LEN   (MIN_PKT_LEN),
    .MAX_PKT_LEN   (MAX_PKT_LEN),
    .NUM_CMAC_PORT (NUM_CMAC_PORT)
  ) box_322mhz_inst (
    .s_axil_awvalid                  (axil_box1_awvalid),
    .s_axil_awaddr                   (axil_box1_awaddr),
    .s_axil_awready                  (axil_box1_awready),
    .s_axil_wvalid                   (axil_box1_wvalid),
    .s_axil_wdata                    (axil_box1_wdata),
    .s_axil_wready                   (axil_box1_wready),
    .s_axil_bvalid                   (axil_box1_bvalid),
    .s_axil_bresp                    (axil_box1_bresp),
    .s_axil_bready                   (axil_box1_bready),
    .s_axil_arvalid                  (axil_box1_arvalid),
    .s_axil_araddr                   (axil_box1_araddr),
    .s_axil_arready                  (axil_box1_arready),
    .s_axil_rvalid                   (axil_box1_rvalid),
    .s_axil_rdata                    (axil_box1_rdata),
    .s_axil_rresp                    (axil_box1_rresp),
    .s_axil_rready                   (axil_box1_rready),

    .s_axis_adap_tx_322mhz_tvalid    (axis_adap_tx_322mhz_tvalid),
    .s_axis_adap_tx_322mhz_tdata     (axis_adap_tx_322mhz_tdata),
    .s_axis_adap_tx_322mhz_tkeep     (axis_adap_tx_322mhz_tkeep),
    .s_axis_adap_tx_322mhz_tlast     (axis_adap_tx_322mhz_tlast),
    .s_axis_adap_tx_322mhz_tuser_err (axis_adap_tx_322mhz_tuser_err),
    .s_axis_adap_tx_322mhz_tready    (axis_adap_tx_322mhz_tready),

    .m_axis_adap_rx_322mhz_tvalid    (axis_adap_rx_322mhz_tvalid),
    .m_axis_adap_rx_322mhz_tdata     (axis_adap_rx_322mhz_tdata),
    .m_axis_adap_rx_322mhz_tkeep     (axis_adap_rx_322mhz_tkeep),
    .m_axis_adap_rx_322mhz_tlast     (axis_adap_rx_322mhz_tlast),
    .m_axis_adap_rx_322mhz_tuser_err (axis_adap_rx_322mhz_tuser_err),

    .m_axis_cmac_tx_tvalid           (axis_cmac_tx_tvalid),
    .m_axis_cmac_tx_tdata            (axis_cmac_tx_tdata),
    .m_axis_cmac_tx_tkeep            (axis_cmac_tx_tkeep),
    .m_axis_cmac_tx_tlast            (axis_cmac_tx_tlast),
    .m_axis_cmac_tx_tuser_err        (axis_cmac_tx_tuser_err),
    .m_axis_cmac_tx_tready           (axis_cmac_tx_tready),

    .s_axis_cmac_rx_tvalid           (axis_cmac_rx_tvalid),
    .s_axis_cmac_rx_tdata            (axis_cmac_rx_tdata),
    .s_axis_cmac_rx_tkeep            (axis_cmac_rx_tkeep),
    .s_axis_cmac_rx_tlast            (axis_cmac_rx_tlast),
    .s_axis_cmac_rx_tuser_err        (axis_cmac_rx_tuser_err),

    .mod_rstn                        (user_322mhz_rstn),
    .mod_rst_done                    (user_322mhz_rst_done),

    .box_rstn                        (box_322mhz_rstn),
    .box_rst_done                    (box_322mhz_rst_done),

    .axil_aclk                       (axil_aclk),
    .cmac_clk                        (cmac_clk)
  );

  assign axi_rdma_send_write_payload_awqos = 16'd0;
  assign axi_rdma_send_write_payload_arqos = 16'd0;
  assign axi_rdma_rsp_payload_awqos = 4'd0;
  assign axi_rdma_rsp_payload_arqos = 4'd0;
  assign axi_qdma_mm_awqos  = 4'd0;
  assign axi_qdma_mm_arqos  = 4'd0;

  assign axi_rdma_get_wqe_awqos     = 4'd0;
  assign axi_rdma_get_wqe_arqos     = 4'd0;
  assign axi_rdma_get_payload_awqos = 4'd0;
  assign axi_rdma_get_payload_arqos = 4'd0;
  assign axi_rdma_completion_awqos  = 4'd0;
  assign axi_rdma_completion_arqos  = 4'd0;

  assign cmac2rdma_roce_axis_tready = 1'b1;
  assign cmac2rdma_roce_axis_tuser  = 1'b1;

  assign axi_sys_mem_wuser  = 64'd0;
  assign axi_sys_mem_aruser = 12'd0;
  assign axi_sys_mem_awuser = 12'd0;

endmodule: open_nic_shell
