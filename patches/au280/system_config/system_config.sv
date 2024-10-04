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
`timescale 1ns/1ps
module system_config #(
  parameter [31:0] BUILD_TIMESTAMP = 32'h01010000,
  parameter int    NUM_CMAC_PORT   = 1
) (
  input                         s_axil_awvalid,
  input                  [31:0] s_axil_awaddr,
  output                        s_axil_awready,
  input                         s_axil_wvalid,
  input                  [31:0] s_axil_wdata,
  output                        s_axil_wready,
  output                        s_axil_bvalid,
  output                  [1:0] s_axil_bresp,
  input                         s_axil_bready,
  input                         s_axil_arvalid,
  input                  [31:0] s_axil_araddr,
  output                        s_axil_arready,
  output                        s_axil_rvalid,
  output                 [31:0] s_axil_rdata,
  output                  [1:0] s_axil_rresp,
  input                         s_axil_rready,

  output                        m_axil_qdma_awvalid,
  output                 [31:0] m_axil_qdma_awaddr,
  input                         m_axil_qdma_awready,
  output                        m_axil_qdma_wvalid,
  output                 [31:0] m_axil_qdma_wdata,
  input                         m_axil_qdma_wready,
  input                         m_axil_qdma_bvalid,
  input                   [1:0] m_axil_qdma_bresp,
  output                        m_axil_qdma_bready,
  output                        m_axil_qdma_arvalid,
  output                 [31:0] m_axil_qdma_araddr,
  input                         m_axil_qdma_arready,
  input                         m_axil_qdma_rvalid,
  input                  [31:0] m_axil_qdma_rdata,
  input                   [1:0] m_axil_qdma_rresp,
  output                        m_axil_qdma_rready,

  output                        m_axil_qdma_csr_awvalid,
  output                 [31:0] m_axil_qdma_csr_awaddr,
  input                         m_axil_qdma_csr_awready,
  output                        m_axil_qdma_csr_wvalid,
  output                 [31:0] m_axil_qdma_csr_wdata,
  input                         m_axil_qdma_csr_wready,
  input                         m_axil_qdma_csr_bvalid,
  input                   [1:0] m_axil_qdma_csr_bresp,
  output                        m_axil_qdma_csr_bready,
  output                        m_axil_qdma_csr_arvalid,
  output                 [31:0] m_axil_qdma_csr_araddr,
  input                         m_axil_qdma_csr_arready,
  input                         m_axil_qdma_csr_rvalid,
  input                  [31:0] m_axil_qdma_csr_rdata,
  input                   [1:0] m_axil_qdma_csr_rresp,
  output                        m_axil_qdma_csr_rready,

  output    [NUM_CMAC_PORT-1:0] m_axil_adap_awvalid,
  output [32*NUM_CMAC_PORT-1:0] m_axil_adap_awaddr,
  input     [NUM_CMAC_PORT-1:0] m_axil_adap_awready,
  output    [NUM_CMAC_PORT-1:0] m_axil_adap_wvalid,
  output [32*NUM_CMAC_PORT-1:0] m_axil_adap_wdata,
  input     [NUM_CMAC_PORT-1:0] m_axil_adap_wready,
  input     [NUM_CMAC_PORT-1:0] m_axil_adap_bvalid,
  input   [2*NUM_CMAC_PORT-1:0] m_axil_adap_bresp,
  output    [NUM_CMAC_PORT-1:0] m_axil_adap_bready,
  output    [NUM_CMAC_PORT-1:0] m_axil_adap_arvalid,
  output [32*NUM_CMAC_PORT-1:0] m_axil_adap_araddr,
  input     [NUM_CMAC_PORT-1:0] m_axil_adap_arready,
  input     [NUM_CMAC_PORT-1:0] m_axil_adap_rvalid,
  input  [32*NUM_CMAC_PORT-1:0] m_axil_adap_rdata,
  input   [2*NUM_CMAC_PORT-1:0] m_axil_adap_rresp,
  output    [NUM_CMAC_PORT-1:0] m_axil_adap_rready,

  output    [NUM_CMAC_PORT-1:0] m_axil_cmac_awvalid,
  output [32*NUM_CMAC_PORT-1:0] m_axil_cmac_awaddr,
  input     [NUM_CMAC_PORT-1:0] m_axil_cmac_awready,
  output    [NUM_CMAC_PORT-1:0] m_axil_cmac_wvalid,
  output [32*NUM_CMAC_PORT-1:0] m_axil_cmac_wdata,
  input     [NUM_CMAC_PORT-1:0] m_axil_cmac_wready,
  input     [NUM_CMAC_PORT-1:0] m_axil_cmac_bvalid,
  input   [2*NUM_CMAC_PORT-1:0] m_axil_cmac_bresp,
  output    [NUM_CMAC_PORT-1:0] m_axil_cmac_bready,
  output    [NUM_CMAC_PORT-1:0] m_axil_cmac_arvalid,
  output [32*NUM_CMAC_PORT-1:0] m_axil_cmac_araddr,
  input     [NUM_CMAC_PORT-1:0] m_axil_cmac_arready,
  input     [NUM_CMAC_PORT-1:0] m_axil_cmac_rvalid,
  input  [32*NUM_CMAC_PORT-1:0] m_axil_cmac_rdata,
  input   [2*NUM_CMAC_PORT-1:0] m_axil_cmac_rresp,
  output    [NUM_CMAC_PORT-1:0] m_axil_cmac_rready,

  output                        m_axil_rdma_awvalid,
  output                 [31:0] m_axil_rdma_awaddr,
  input                         m_axil_rdma_awready,
  output                        m_axil_rdma_wvalid,
  output                 [31:0] m_axil_rdma_wdata,
  input                         m_axil_rdma_wready,
  input                         m_axil_rdma_bvalid,
  input                   [1:0] m_axil_rdma_bresp,
  output                        m_axil_rdma_bready,
  output                        m_axil_rdma_arvalid,
  output                 [31:0] m_axil_rdma_araddr,
  input                         m_axil_rdma_arready,
  input                         m_axil_rdma_rvalid,
  input                  [31:0] m_axil_rdma_rdata,
  input                   [1:0] m_axil_rdma_rresp,
  output                        m_axil_rdma_rready,

  output                        m_axil_box0_awvalid,
  output                 [31:0] m_axil_box0_awaddr,
  input                         m_axil_box0_awready,
  output                        m_axil_box0_wvalid,
  output                 [31:0] m_axil_box0_wdata,
  input                         m_axil_box0_wready,
  input                         m_axil_box0_bvalid,
  input                   [1:0] m_axil_box0_bresp,
  output                        m_axil_box0_bready,
  output                        m_axil_box0_arvalid,
  output                 [31:0] m_axil_box0_araddr,
  input                         m_axil_box0_arready,
  input                         m_axil_box0_rvalid,
  input                  [31:0] m_axil_box0_rdata,
  input                   [1:0] m_axil_box0_rresp,
  output                        m_axil_box0_rready,

  output                        m_axil_box1_awvalid,
  output                 [31:0] m_axil_box1_awaddr,
  input                         m_axil_box1_awready,
  output                        m_axil_box1_wvalid,
  output                 [31:0] m_axil_box1_wdata,
  input                         m_axil_box1_wready,
  input                         m_axil_box1_bvalid,
  input                   [1:0] m_axil_box1_bresp,
  output                        m_axil_box1_bready,
  output                        m_axil_box1_arvalid,
  output                 [31:0] m_axil_box1_araddr,
  input                         m_axil_box1_arready,
  input                         m_axil_box1_rvalid,
  input                  [31:0] m_axil_box1_rdata,
  input                   [1:0] m_axil_box1_rresp,
  output                        m_axil_box1_rready,

  output                 [31:0] shell_rstn,
  input                  [31:0] shell_rst_done,
  output                 [31:0] user_rstn,
  input                  [31:0] user_rst_done,

  input                         satellite_uart_0_rxd,
  output                        satellite_uart_0_txd,

`ifdef __au280__
  input                   [3:0] satellite_gpio_0,
  input                   [6:0] hbm_temp_1_0,
  input                   [6:0] hbm_temp_2_0,
  input                         interrupt_hbm_cattrip_0,
`elsif __au50__
  input                   [1:0] satellite_gpio_0,
  input                   [6:0] hbm_temp_1_0,
  input                   [6:0] hbm_temp_2_0,
  input                         interrupt_hbm_cattrip_0,
`elsif __au55n__
  input                   [3:0] satellite_gpio_0,
  input                   [6:0] hbm_temp_1_0,
  input                   [6:0] hbm_temp_2_0,
  input                         interrupt_hbm_cattrip_0,
`elsif __au55c__
  input                   [3:0] satellite_gpio_0,
  input                   [6:0] hbm_temp_1_0,
  input                   [6:0] hbm_temp_2_0,
  input                         interrupt_hbm_cattrip_0,  
`elsif __au200__
  input                   [3:0] satellite_gpio_0,
  output                  [1:0] qsfp_resetl, 
  input                   [1:0] qsfp_modprsl,
  input                   [1:0] qsfp_intl,   
  output                  [1:0] qsfp_lpmode,
  output                  [1:0] qsfp_modsell,
`elsif __au250__
  input                   [3:0] satellite_gpio_0,
  output                  [1:0] qsfp_resetl, 
  input                   [1:0] qsfp_modprsl,
  input                   [1:0] qsfp_intl,   
  output                  [1:0] qsfp_lpmode,
  output                  [1:0] qsfp_modsell,  
`endif

  input                         aclk,
  input                         aresetn
);

  // Parameter DRC
  initial begin
    if (NUM_CMAC_PORT > 2 || NUM_CMAC_PORT < 1) begin
      $fatal("[%m] Number of CMACs should be within the range [1, 2]");
    end
  end

  wire        axil_scfg_awvalid;
  wire [31:0] axil_scfg_awaddr;
  wire        axil_scfg_awready;
  wire        axil_scfg_wvalid;
  wire [31:0] axil_scfg_wdata;
  wire        axil_scfg_wready;
  wire        axil_scfg_bvalid;
  wire  [1:0] axil_scfg_bresp;
  wire        axil_scfg_bready;
  wire        axil_scfg_arvalid;
  wire [31:0] axil_scfg_araddr;
  wire        axil_scfg_arready;
  wire        axil_scfg_rvalid;
  wire [31:0] axil_scfg_rdata;
  wire  [1:0] axil_scfg_rresp;
  wire        axil_scfg_rready;

  wire        axil_smon_awvalid;
  wire [31:0] axil_smon_awaddr;
  wire        axil_smon_awready;
  wire        axil_smon_wvalid;
  wire [31:0] axil_smon_wdata;
  wire        axil_smon_wready;
  wire        axil_smon_bvalid;
  wire  [1:0] axil_smon_bresp;
  wire        axil_smon_bready;
  wire        axil_smon_arvalid;
  wire [31:0] axil_smon_araddr;
  wire        axil_smon_arready;
  wire        axil_smon_rvalid;
  wire [31:0] axil_smon_rdata;
  wire  [1:0] axil_smon_rresp;
  wire        axil_smon_rready;

  wire        axil_cms_awvalid;
  wire [31:0] axil_cms_awaddr;
  wire        axil_cms_awready;
  wire        axil_cms_wvalid;
  wire [31:0] axil_cms_wdata;
  wire        axil_cms_wready;
  wire        axil_cms_bvalid;
  wire  [1:0] axil_cms_bresp;
  wire        axil_cms_bready;
  wire        axil_cms_arvalid;
  wire [31:0] axil_cms_araddr;
  wire        axil_cms_arready;
  wire        axil_cms_rvalid;
  wire [31:0] axil_cms_rdata;
  wire  [1:0] axil_cms_rresp;
  wire        axil_cms_rready;
  wire  [2:0] axil_cms_awprot;
  wire  [2:0] axil_cms_arprot;
  wire  [3:0] axil_cms_wstrb;
  
  wire        axil_cms_int_awvalid;
  wire [31:0] axil_cms_int_awaddr;
  wire        axil_cms_int_awready;
  wire        axil_cms_int_wvalid;
  wire [31:0] axil_cms_int_wdata;
  wire        axil_cms_int_wready;
  wire        axil_cms_int_bvalid;
  wire  [1:0] axil_cms_int_bresp;
  wire        axil_cms_int_bready;
  wire        axil_cms_int_arvalid;
  wire [31:0] axil_cms_int_araddr;
  wire        axil_cms_int_arready;
  wire        axil_cms_int_rvalid;
  wire [31:0] axil_cms_int_rdata;
  wire  [1:0] axil_cms_int_rresp;
  wire        axil_cms_int_rready;
  wire  [2:0] axil_cms_int_awprot;
  wire  [2:0] axil_cms_int_arprot;
  wire  [3:0] axil_cms_int_wstrb;

  wire        axil_qspi_awvalid;
  wire [31:0] axil_qspi_awaddr;
  wire        axil_qspi_awready;
  wire        axil_qspi_wvalid;
  wire [31:0] axil_qspi_wdata;
  wire        axil_qspi_wready;
  wire        axil_qspi_bvalid;
  wire  [1:0] axil_qspi_bresp;
  wire        axil_qspi_bready;
  wire        axil_qspi_arvalid;
  wire [31:0] axil_qspi_araddr;
  wire        axil_qspi_arready;
  wire        axil_qspi_rvalid;
  wire [31:0] axil_qspi_rdata;
  wire  [1:0] axil_qspi_rresp;
  wire        axil_qspi_rready;
  wire  [2:0] axil_qspi_awprot;
  wire  [2:0] axil_qspi_arprot;
  wire  [3:0] axil_qspi_wstrb;
  
  wire        axil_qspi_int_awvalid;
  wire [31:0] axil_qspi_int_awaddr;
  wire        axil_qspi_int_awready;
  wire        axil_qspi_int_wvalid;
  wire [31:0] axil_qspi_int_wdata;
  wire        axil_qspi_int_wready;
  wire        axil_qspi_int_bvalid;
  wire  [1:0] axil_qspi_int_bresp;
  wire        axil_qspi_int_bready;
  wire        axil_qspi_int_arvalid;
  wire [31:0] axil_qspi_int_araddr;
  wire        axil_qspi_int_arready;
  wire        axil_qspi_int_rvalid;
  wire [31:0] axil_qspi_int_rdata;
  wire  [1:0] axil_qspi_int_rresp;
  wire        axil_qspi_int_rready;
  wire  [2:0] axil_qspi_int_awprot;
  wire  [2:0] axil_qspi_int_arprot;
  wire  [3:0] axil_qspi_int_wstrb;
   
  system_config_address_map #(
    .NUM_CMAC_PORT (NUM_CMAC_PORT)
  ) scfg_address_map_inst (
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

    .m_axil_scfg_awvalid (axil_scfg_awvalid),
    .m_axil_scfg_awaddr  (axil_scfg_awaddr),
    .m_axil_scfg_awready (axil_scfg_awready),
    .m_axil_scfg_wvalid  (axil_scfg_wvalid),
    .m_axil_scfg_wdata   (axil_scfg_wdata),
    .m_axil_scfg_wready  (axil_scfg_wready),
    .m_axil_scfg_bvalid  (axil_scfg_bvalid),
    .m_axil_scfg_bresp   (axil_scfg_bresp),
    .m_axil_scfg_bready  (axil_scfg_bready),
    .m_axil_scfg_arvalid (axil_scfg_arvalid),
    .m_axil_scfg_araddr  (axil_scfg_araddr),
    .m_axil_scfg_arready (axil_scfg_arready),
    .m_axil_scfg_rvalid  (axil_scfg_rvalid),
    .m_axil_scfg_rdata   (axil_scfg_rdata),
    .m_axil_scfg_rresp   (axil_scfg_rresp),
    .m_axil_scfg_rready  (axil_scfg_rready),

    .m_axil_qdma_awvalid (m_axil_qdma_awvalid),
    .m_axil_qdma_awaddr  (m_axil_qdma_awaddr),
    .m_axil_qdma_awready (m_axil_qdma_awready),
    .m_axil_qdma_wvalid  (m_axil_qdma_wvalid),
    .m_axil_qdma_wdata   (m_axil_qdma_wdata),
    .m_axil_qdma_wready  (m_axil_qdma_wready),
    .m_axil_qdma_bvalid  (m_axil_qdma_bvalid),
    .m_axil_qdma_bresp   (m_axil_qdma_bresp),
    .m_axil_qdma_bready  (m_axil_qdma_bready),
    .m_axil_qdma_arvalid (m_axil_qdma_arvalid),
    .m_axil_qdma_araddr  (m_axil_qdma_araddr),
    .m_axil_qdma_arready (m_axil_qdma_arready),
    .m_axil_qdma_rvalid  (m_axil_qdma_rvalid),
    .m_axil_qdma_rdata   (m_axil_qdma_rdata),
    .m_axil_qdma_rresp   (m_axil_qdma_rresp),
    .m_axil_qdma_rready  (m_axil_qdma_rready),

    .m_axil_qdma_csr_awvalid (m_axil_qdma_csr_awvalid),
    .m_axil_qdma_csr_awaddr  (m_axil_qdma_csr_awaddr),
    .m_axil_qdma_csr_awready (m_axil_qdma_csr_awready),
    .m_axil_qdma_csr_wvalid  (m_axil_qdma_csr_wvalid),
    .m_axil_qdma_csr_wdata   (m_axil_qdma_csr_wdata),
    .m_axil_qdma_csr_wready  (m_axil_qdma_csr_wready),
    .m_axil_qdma_csr_bvalid  (m_axil_qdma_csr_bvalid),
    .m_axil_qdma_csr_bresp   (m_axil_qdma_csr_bresp),
    .m_axil_qdma_csr_bready  (m_axil_qdma_csr_bready),
    .m_axil_qdma_csr_arvalid (m_axil_qdma_csr_arvalid),
    .m_axil_qdma_csr_araddr  (m_axil_qdma_csr_araddr),
    .m_axil_qdma_csr_arready (m_axil_qdma_csr_arready),
    .m_axil_qdma_csr_rvalid  (m_axil_qdma_csr_rvalid),
    .m_axil_qdma_csr_rdata   (m_axil_qdma_csr_rdata),
    .m_axil_qdma_csr_rresp   (m_axil_qdma_csr_rresp),
    .m_axil_qdma_csr_rready  (m_axil_qdma_csr_rready),

    .m_axil_adap_awvalid (m_axil_adap_awvalid),
    .m_axil_adap_awaddr  (m_axil_adap_awaddr),
    .m_axil_adap_awready (m_axil_adap_awready),
    .m_axil_adap_wvalid  (m_axil_adap_wvalid),
    .m_axil_adap_wdata   (m_axil_adap_wdata),
    .m_axil_adap_wready  (m_axil_adap_wready),
    .m_axil_adap_bvalid  (m_axil_adap_bvalid),
    .m_axil_adap_bresp   (m_axil_adap_bresp),
    .m_axil_adap_bready  (m_axil_adap_bready),
    .m_axil_adap_arvalid (m_axil_adap_arvalid),
    .m_axil_adap_araddr  (m_axil_adap_araddr),
    .m_axil_adap_arready (m_axil_adap_arready),
    .m_axil_adap_rvalid  (m_axil_adap_rvalid),
    .m_axil_adap_rdata   (m_axil_adap_rdata),
    .m_axil_adap_rresp   (m_axil_adap_rresp),
    .m_axil_adap_rready  (m_axil_adap_rready),

    .m_axil_cmac_awvalid (m_axil_cmac_awvalid),
    .m_axil_cmac_awaddr  (m_axil_cmac_awaddr),
    .m_axil_cmac_awready (m_axil_cmac_awready),
    .m_axil_cmac_wvalid  (m_axil_cmac_wvalid),
    .m_axil_cmac_wdata   (m_axil_cmac_wdata),
    .m_axil_cmac_wready  (m_axil_cmac_wready),
    .m_axil_cmac_bvalid  (m_axil_cmac_bvalid),
    .m_axil_cmac_bresp   (m_axil_cmac_bresp),
    .m_axil_cmac_bready  (m_axil_cmac_bready),
    .m_axil_cmac_arvalid (m_axil_cmac_arvalid),
    .m_axil_cmac_araddr  (m_axil_cmac_araddr),
    .m_axil_cmac_arready (m_axil_cmac_arready),
    .m_axil_cmac_rvalid  (m_axil_cmac_rvalid),
    .m_axil_cmac_rdata   (m_axil_cmac_rdata),
    .m_axil_cmac_rresp   (m_axil_cmac_rresp),
    .m_axil_cmac_rready  (m_axil_cmac_rready),
    
    .m_axil_smon_awvalid (axil_smon_awvalid),
    .m_axil_smon_awaddr  (axil_smon_awaddr),
    .m_axil_smon_awready (axil_smon_awready),
    .m_axil_smon_wvalid  (axil_smon_wvalid),
    .m_axil_smon_wdata   (axil_smon_wdata),
    .m_axil_smon_wready  (axil_smon_wready),
    .m_axil_smon_bvalid  (axil_smon_bvalid),
    .m_axil_smon_bresp   (axil_smon_bresp),
    .m_axil_smon_bready  (axil_smon_bready),
    .m_axil_smon_arvalid (axil_smon_arvalid),
    .m_axil_smon_araddr  (axil_smon_araddr),
    .m_axil_smon_arready (axil_smon_arready),
    .m_axil_smon_rvalid  (axil_smon_rvalid),
    .m_axil_smon_rdata   (axil_smon_rdata),
    .m_axil_smon_rresp   (axil_smon_rresp),
    .m_axil_smon_rready  (axil_smon_rready),

    .m_axil_rdma_awvalid (m_axil_rdma_awvalid),
    .m_axil_rdma_awaddr  (m_axil_rdma_awaddr),
    .m_axil_rdma_awready (m_axil_rdma_awready),
    .m_axil_rdma_wvalid  (m_axil_rdma_wvalid),
    .m_axil_rdma_wdata   (m_axil_rdma_wdata),
    .m_axil_rdma_wready  (m_axil_rdma_wready),
    .m_axil_rdma_bvalid  (m_axil_rdma_bvalid),
    .m_axil_rdma_bresp   (m_axil_rdma_bresp),
    .m_axil_rdma_bready  (m_axil_rdma_bready),
    .m_axil_rdma_arvalid (m_axil_rdma_arvalid),
    .m_axil_rdma_araddr  (m_axil_rdma_araddr),
    .m_axil_rdma_arready (m_axil_rdma_arready),
    .m_axil_rdma_rvalid  (m_axil_rdma_rvalid),
    .m_axil_rdma_rdata   (m_axil_rdma_rdata),
    .m_axil_rdma_rresp   (m_axil_rdma_rresp),
    .m_axil_rdma_rready  (m_axil_rdma_rready),

    .m_axil_box0_awvalid (m_axil_box0_awvalid),
    .m_axil_box0_awaddr  (m_axil_box0_awaddr),
    .m_axil_box0_awready (m_axil_box0_awready),
    .m_axil_box0_wvalid  (m_axil_box0_wvalid),
    .m_axil_box0_wdata   (m_axil_box0_wdata),
    .m_axil_box0_wready  (m_axil_box0_wready),
    .m_axil_box0_bvalid  (m_axil_box0_bvalid),
    .m_axil_box0_bresp   (m_axil_box0_bresp),
    .m_axil_box0_bready  (m_axil_box0_bready),
    .m_axil_box0_arvalid (m_axil_box0_arvalid),
    .m_axil_box0_araddr  (m_axil_box0_araddr),
    .m_axil_box0_arready (m_axil_box0_arready),
    .m_axil_box0_rvalid  (m_axil_box0_rvalid),
    .m_axil_box0_rdata   (m_axil_box0_rdata),
    .m_axil_box0_rresp   (m_axil_box0_rresp),
    .m_axil_box0_rready  (m_axil_box0_rready),

    .m_axil_box1_awvalid (m_axil_box1_awvalid),
    .m_axil_box1_awaddr  (m_axil_box1_awaddr),
    .m_axil_box1_awready (m_axil_box1_awready),
    .m_axil_box1_wvalid  (m_axil_box1_wvalid),
    .m_axil_box1_wdata   (m_axil_box1_wdata),
    .m_axil_box1_wready  (m_axil_box1_wready),
    .m_axil_box1_bvalid  (m_axil_box1_bvalid),
    .m_axil_box1_bresp   (m_axil_box1_bresp),
    .m_axil_box1_bready  (m_axil_box1_bready),
    .m_axil_box1_arvalid (m_axil_box1_arvalid),
    .m_axil_box1_araddr  (m_axil_box1_araddr),
    .m_axil_box1_arready (m_axil_box1_arready),
    .m_axil_box1_rvalid  (m_axil_box1_rvalid),
    .m_axil_box1_rdata   (m_axil_box1_rdata),
    .m_axil_box1_rresp   (m_axil_box1_rresp),
    .m_axil_box1_rready  (m_axil_box1_rready),

    .m_axil_cms_awvalid (axil_cms_awvalid),
    .m_axil_cms_awaddr  (axil_cms_awaddr),
    .m_axil_cms_awready (axil_cms_awready),
    .m_axil_cms_wvalid  (axil_cms_wvalid),
    .m_axil_cms_wdata   (axil_cms_wdata),
    .m_axil_cms_wready  (axil_cms_wready),
    .m_axil_cms_bvalid  (axil_cms_bvalid),
    .m_axil_cms_bresp   (axil_cms_bresp),
    .m_axil_cms_bready  (axil_cms_bready),
    .m_axil_cms_arvalid (axil_cms_arvalid),
    .m_axil_cms_araddr  (axil_cms_araddr),
    .m_axil_cms_arready (axil_cms_arready),
    .m_axil_cms_rvalid  (axil_cms_rvalid),
    .m_axil_cms_rdata   (axil_cms_rdata),
    .m_axil_cms_rresp   (axil_cms_rresp),
    .m_axil_cms_rready  (axil_cms_rready),
    .m_axil_cms_arprot  (axil_cms_arprot),
    .m_axil_cms_awprot  (axil_cms_awprot),
    .m_axil_cms_wstrb   (axil_cms_wstrb),

    .m_axil_qspi_awvalid (axil_qspi_awvalid),
    .m_axil_qspi_awaddr  (axil_qspi_awaddr),
    .m_axil_qspi_awready (axil_qspi_awready),
    .m_axil_qspi_wvalid  (axil_qspi_wvalid),
    .m_axil_qspi_wdata   (axil_qspi_wdata),
    .m_axil_qspi_wready  (axil_qspi_wready),
    .m_axil_qspi_bvalid  (axil_qspi_bvalid),
    .m_axil_qspi_bresp   (axil_qspi_bresp),
    .m_axil_qspi_bready  (axil_qspi_bready),
    .m_axil_qspi_arvalid (axil_qspi_arvalid),
    .m_axil_qspi_araddr  (axil_qspi_araddr),
    .m_axil_qspi_arready (axil_qspi_arready),
    .m_axil_qspi_rvalid  (axil_qspi_rvalid),
    .m_axil_qspi_rdata   (axil_qspi_rdata),
    .m_axil_qspi_rresp   (axil_qspi_rresp),
    .m_axil_qspi_rready  (axil_qspi_rready),
    .m_axil_qspi_arprot  (axil_qspi_arprot),
    .m_axil_qspi_awprot  (axil_qspi_awprot),
    .m_axil_qspi_wstrb   (axil_qspi_wstrb),

    .aclk                (aclk),
    .aresetn             (aresetn)
  );

  system_config_register #(
    .BUILD_TIMESTAMP (BUILD_TIMESTAMP)
  ) scfg_reg_inst (
    .s_axil_awvalid (axil_scfg_awvalid),
    .s_axil_awaddr  (axil_scfg_awaddr),
    .s_axil_awready (axil_scfg_awready),
    .s_axil_wvalid  (axil_scfg_wvalid),
    .s_axil_wdata   (axil_scfg_wdata),
    .s_axil_wready  (axil_scfg_wready),
    .s_axil_bvalid  (axil_scfg_bvalid),
    .s_axil_bresp   (axil_scfg_bresp),
    .s_axil_bready  (axil_scfg_bready),
    .s_axil_arvalid (axil_scfg_arvalid),
    .s_axil_araddr  (axil_scfg_araddr),
    .s_axil_arready (axil_scfg_arready),
    .s_axil_rvalid  (axil_scfg_rvalid),
    .s_axil_rdata   (axil_scfg_rdata),
    .s_axil_rresp   (axil_scfg_rresp),
    .s_axil_rready  (axil_scfg_rready),

    .shell_rstn     (shell_rstn),
    .shell_rst_done (shell_rst_done),
    .user_rstn      (user_rstn),
    .user_rst_done  (user_rst_done),

    .aclk           (aclk),
    .aresetn        (aresetn)
  );

   system_management_wiz
   system_management_wiz_inst (
     .s_axi_aclk      (aclk),
     .s_axi_aresetn   (aresetn),

     .s_axi_awaddr    (axil_smon_awaddr),
     .s_axi_awvalid   (axil_smon_awvalid),
     .s_axi_awready   (axil_smon_awready),
     .s_axi_wdata     (axil_smon_wdata),
     .s_axi_wstrb     (4'hF),
     .s_axi_wvalid    (axil_smon_wvalid),
     .s_axi_wready    (axil_smon_wready),
     .s_axi_bresp     (axil_smon_bresp),
     .s_axi_bvalid    (axil_smon_bvalid),
     .s_axi_bready    (axil_smon_bready),
     .s_axi_araddr    (axil_smon_araddr),
     .s_axi_arvalid   (axil_smon_arvalid),
     .s_axi_arready   (axil_smon_arready),
     .s_axi_rdata     (axil_smon_rdata),
     .s_axi_rresp     (axil_smon_rresp),
     .s_axi_rvalid    (axil_smon_rvalid),
     .s_axi_rready    (axil_smon_rready),

     .vp              (1'b0),
     .vn              (1'b0)
  );

  wire        cms_clk;
  wire        cms_aresetn;
  wire        cms_locked;
  
  wire        clk_50mhz_wiz_out;

  // Generate 50MHz 'cms_clk'
clk_wiz_50Mhz clk_wiz_cms_inst (
    .clk_in1  (aclk),
    .resetn   (aresetn),
    .clk_out1 (clk_50mhz_wiz_out),
    .locked   (cms_locked)
  );

BUFG
clk_50mhz_bufg_inst (
    .I(clk_50mhz_wiz_out),
    .O(cms_clk)
);

  // generate synchronous reset to 50MHz with asynchronous assertion  
localparam sync_stages = 2;
reg [sync_stages-1:0] cms_aresetn_sync = {sync_stages{1'b0}};
assign cms_aresetn = cms_locked && cms_aresetn_sync[sync_stages-1];
  
always @(posedge cms_clk) begin
    if (cms_locked == 1'b0) begin
        cms_aresetn_sync <= {sync_stages{1'b0}};
    end
    else begin
        cms_aresetn_sync <= {cms_aresetn_sync[sync_stages-2:0], 1'b1};
    end
end    

  axi_lite_clock_converter axi_clock_conv_qspi_inst (
      .s_axi_awaddr  (axil_qspi_awaddr),
      .s_axi_awprot  (axil_qspi_awprot),
      .s_axi_awvalid (axil_qspi_awvalid),
      .s_axi_awready (axil_qspi_awready),
      .s_axi_wdata   (axil_qspi_wdata),
      .s_axi_wstrb   (axil_qspi_wstrb),
      .s_axi_wvalid  (axil_qspi_wvalid),
      .s_axi_wready  (axil_qspi_wready),
      .s_axi_bvalid  (axil_qspi_bvalid),
      .s_axi_bresp   (axil_qspi_bresp),
      .s_axi_bready  (axil_qspi_bready),
      .s_axi_araddr  (axil_qspi_araddr),
      .s_axi_arprot  (axil_qspi_arprot),
      .s_axi_arvalid (axil_qspi_arvalid),
      .s_axi_arready (axil_qspi_arready),
      .s_axi_rdata   (axil_qspi_rdata),
      .s_axi_rresp   (axil_qspi_rresp),
      .s_axi_rvalid  (axil_qspi_rvalid),
      .s_axi_rready  (axil_qspi_rready),

      .m_axi_awaddr  (axil_qspi_int_awaddr),
      .m_axi_awprot  (axil_qspi_int_awprot),
      .m_axi_awvalid (axil_qspi_int_awvalid),
      .m_axi_awready (axil_qspi_int_awready),
      .m_axi_wdata   (axil_qspi_int_wdata),
      .m_axi_wstrb   (axil_qspi_int_wstrb),
      .m_axi_wvalid  (axil_qspi_int_wvalid),
      .m_axi_wready  (axil_qspi_int_wready),
      .m_axi_bvalid  (axil_qspi_int_bvalid),
      .m_axi_bresp   (axil_qspi_int_bresp),
      .m_axi_bready  (axil_qspi_int_bready),
      .m_axi_araddr  (axil_qspi_int_araddr),
      .m_axi_arprot  (axil_qspi_int_arprot),
      .m_axi_arvalid (axil_qspi_int_arvalid),
      .m_axi_arready (axil_qspi_int_arready),
      .m_axi_rdata   (axil_qspi_int_rdata),
      .m_axi_rresp   (axil_qspi_int_rresp),
      .m_axi_rvalid  (axil_qspi_int_rvalid),
      .m_axi_rready  (axil_qspi_int_rready),

      .s_axi_aclk    (aclk),
      .s_axi_aresetn (aresetn),
      .m_axi_aclk    (cms_clk),
      .m_axi_aresetn (cms_aresetn)
    );

  axi_quad_spi_0 quad_spi_inst (
    .s_axi_awvalid (axil_qspi_int_awvalid),
    .s_axi_awaddr  (axil_qspi_int_awaddr[6:0]),
    .s_axi_awready (axil_qspi_int_awready),
    .s_axi_wvalid  (axil_qspi_int_wvalid),
    .s_axi_wdata   (axil_qspi_int_wdata),
    .s_axi_wready  (axil_qspi_int_wready),
    .s_axi_bvalid  (axil_qspi_int_bvalid),
    .s_axi_bresp   (axil_qspi_int_bresp),
    .s_axi_bready  (axil_qspi_int_bready),
    .s_axi_arvalid (axil_qspi_int_arvalid),
    .s_axi_araddr  (axil_qspi_int_araddr[6:0]),
    .s_axi_arready (axil_qspi_int_arready),
    .s_axi_rvalid  (axil_qspi_int_rvalid),
    .s_axi_rdata   (axil_qspi_int_rdata),
    .s_axi_rresp   (axil_qspi_int_rresp),
    .s_axi_rready  (axil_qspi_int_rready),
    .s_axi_wstrb   (4'b1111),
    .s_axi_aclk    (cms_clk),
    .s_axi_aresetn (cms_aresetn),
    .gsr           (1'b0),
    .gts           (1'b0),
    .usrcclkts     (1'b0),
    .keyclearb     (1'b1),
    .usrdoneo      (1'b0),
    .usrdonets     (1'b1),
    .ext_spi_clk   (cms_clk)
  );

  axi_lite_clock_converter axi_clock_conv_cms_inst (
      .s_axi_awaddr  (axil_cms_awaddr),
      .s_axi_awprot  (axil_cms_awprot),
      .s_axi_awvalid (axil_cms_awvalid),
      .s_axi_awready (axil_cms_awready),
      .s_axi_wdata   (axil_cms_wdata),
      .s_axi_wstrb   (axil_cms_wstrb),
      .s_axi_wvalid  (axil_cms_wvalid),
      .s_axi_wready  (axil_cms_wready),
      .s_axi_bvalid  (axil_cms_bvalid),
      .s_axi_bresp   (axil_cms_bresp),
      .s_axi_bready  (axil_cms_bready),
      .s_axi_araddr  (axil_cms_araddr),
      .s_axi_arprot  (axil_cms_arprot),
      .s_axi_arvalid (axil_cms_arvalid),
      .s_axi_arready (axil_cms_arready),
      .s_axi_rdata   (axil_cms_rdata),
      .s_axi_rresp   (axil_cms_rresp),
      .s_axi_rvalid  (axil_cms_rvalid),
      .s_axi_rready  (axil_cms_rready),

      .m_axi_awaddr  (axil_cms_int_awaddr),
      .m_axi_awprot  (axil_cms_int_awprot),
      .m_axi_awvalid (axil_cms_int_awvalid),
      .m_axi_awready (axil_cms_int_awready),
      .m_axi_wdata   (axil_cms_int_wdata),
      .m_axi_wstrb   (axil_cms_int_wstrb),
      .m_axi_wvalid  (axil_cms_int_wvalid),
      .m_axi_wready  (axil_cms_int_wready),
      .m_axi_bvalid  (axil_cms_int_bvalid),
      .m_axi_bresp   (axil_cms_int_bresp),
      .m_axi_bready  (axil_cms_int_bready),
      .m_axi_araddr  (axil_cms_int_araddr),
      .m_axi_arprot  (axil_cms_int_arprot),
      .m_axi_arvalid (axil_cms_int_arvalid),
      .m_axi_arready (axil_cms_int_arready),
      .m_axi_rdata   (axil_cms_int_rdata),
      .m_axi_rresp   (axil_cms_int_rresp),
      .m_axi_rvalid  (axil_cms_int_rvalid),
      .m_axi_rready  (axil_cms_int_rready),

      .s_axi_aclk    (aclk),
      .s_axi_aresetn (aresetn),
      .m_axi_aclk    (cms_clk),
      .m_axi_aresetn (cms_aresetn)
    );


  cms_subsystem_wrapper
  cms_subsystem_wrapper_inst (
    .aclk_ctrl_0             (cms_clk),
    .aresetn_ctrl_0          (cms_aresetn),

    .interrupt_host_0        (),
    .s_axi_ctrl_0_araddr     (axil_cms_int_araddr[17:0]),     
    .s_axi_ctrl_0_arprot     (axil_cms_int_arprot),
    .s_axi_ctrl_0_arready    (axil_cms_int_arready),
    .s_axi_ctrl_0_arvalid    (axil_cms_int_arvalid),
    .s_axi_ctrl_0_awaddr     (axil_cms_int_awaddr[17:0]),
    .s_axi_ctrl_0_awprot     (axil_cms_int_awprot),
    .s_axi_ctrl_0_awready    (axil_cms_int_awready),
    .s_axi_ctrl_0_awvalid    (axil_cms_int_awvalid),
    .s_axi_ctrl_0_bready     (axil_cms_int_bready),
    .s_axi_ctrl_0_bresp      (axil_cms_int_bresp),
    .s_axi_ctrl_0_bvalid     (axil_cms_int_bvalid),
    .s_axi_ctrl_0_rdata      (axil_cms_int_rdata),
    .s_axi_ctrl_0_rready     (axil_cms_int_rready),
    .s_axi_ctrl_0_rresp      (axil_cms_int_rresp),
    .s_axi_ctrl_0_rvalid     (axil_cms_int_rvalid),
    .s_axi_ctrl_0_wdata      (axil_cms_int_wdata),
    .s_axi_ctrl_0_wready     (axil_cms_int_wready),
    .s_axi_ctrl_0_wstrb      (axil_cms_int_wstrb),
    .s_axi_ctrl_0_wvalid     (axil_cms_int_wvalid),
  
  `ifdef __au280__
    .hbm_temp_1_0            (hbm_temp_1_0),
    .hbm_temp_2_0            (hbm_temp_2_0),
    .interrupt_hbm_cattrip_0 (interrupt_hbm_cattrip_0),
  `elsif __au55n__
    .hbm_temp_1_0            (hbm_temp_1_0),
    .hbm_temp_2_0            (hbm_temp_2_0),
    .interrupt_hbm_cattrip_0 (interrupt_hbm_cattrip_0),
  `elsif __au55c__
    .hbm_temp_1_0            (hbm_temp_1_0),
    .hbm_temp_2_0            (hbm_temp_2_0),
    .interrupt_hbm_cattrip_0 (interrupt_hbm_cattrip_0), 
  `elsif __au50__ 
    .hbm_temp_1_0            (hbm_temp_1_0),
    .hbm_temp_2_0            (hbm_temp_2_0),
    .interrupt_hbm_cattrip_0 (interrupt_hbm_cattrip_0),
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
      
    .satellite_gpio_0        (satellite_gpio_0),
    .satellite_uart_0_rxd    (satellite_uart_0_rxd),
    .satellite_uart_0_txd    (satellite_uart_0_txd)
  );


endmodule: system_config
