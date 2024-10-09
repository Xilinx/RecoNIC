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
initial begin
  if (USE_PHYS_FUNC == 0) begin
    $fatal("No implementation for USE_PHYS_FUNC = %d", 0);
  end
  if (NUM_PHYS_FUNC != NUM_CMAC_PORT) begin
    $fatal("No implementation for NUM_PHYS_FUNC (%d) != NUM_CMAC_PORT (%d)",
      NUM_PHYS_FUNC, NUM_CMAC_PORT);
  end
end

localparam C_NUM_USER_BLOCK = 1;

// Make sure for all the unused reset pair, corresponding bits in
// "mod_rst_done" are tied to 0
assign mod_rst_done[15:C_NUM_USER_BLOCK] = {(16-C_NUM_USER_BLOCK){1'b1}};

p2p_250mhz #(
  .NUM_INTF (NUM_PHYS_FUNC)
) p2p_250mhz_inst (
  .s_axil_awvalid                   (axil_p2p_awvalid),
  .s_axil_awaddr                    (axil_p2p_awaddr),
  .s_axil_awready                   (axil_p2p_awready),
  .s_axil_wvalid                    (axil_p2p_wvalid),
  .s_axil_wdata                     (axil_p2p_wdata),
  .s_axil_wready                    (axil_p2p_wready),
  .s_axil_bvalid                    (axil_p2p_bvalid),
  .s_axil_bresp                     (axil_p2p_bresp),
  .s_axil_bready                    (axil_p2p_bready),
  .s_axil_arvalid                   (axil_p2p_arvalid),
  .s_axil_araddr                    (axil_p2p_araddr),
  .s_axil_arready                   (axil_p2p_arready),
  .s_axil_rvalid                    (axil_p2p_rvalid),
  .s_axil_rdata                     (axil_p2p_rdata),
  .s_axil_rresp                     (axil_p2p_rresp),
  .s_axil_rready                    (axil_p2p_rready),

  .s_axis_qdma_h2c_tvalid           (s_axis_qdma_h2c_tvalid),
  .s_axis_qdma_h2c_tdata            (s_axis_qdma_h2c_tdata),
  .s_axis_qdma_h2c_tkeep            (s_axis_qdma_h2c_tkeep),
  .s_axis_qdma_h2c_tlast            (s_axis_qdma_h2c_tlast),
  .s_axis_qdma_h2c_tuser_size       (s_axis_qdma_h2c_tuser_size),
  .s_axis_qdma_h2c_tuser_src        (s_axis_qdma_h2c_tuser_src),
  .s_axis_qdma_h2c_tuser_dst        (s_axis_qdma_h2c_tuser_dst),
  .s_axis_qdma_h2c_tready           (s_axis_qdma_h2c_tready),

  .m_axis_qdma_c2h_tvalid           (m_axis_qdma_c2h_tvalid),
  .m_axis_qdma_c2h_tdata            (m_axis_qdma_c2h_tdata),
  .m_axis_qdma_c2h_tkeep            (m_axis_qdma_c2h_tkeep),
  .m_axis_qdma_c2h_tlast            (m_axis_qdma_c2h_tlast),
  .m_axis_qdma_c2h_tuser_size       (m_axis_qdma_c2h_tuser_size),
  .m_axis_qdma_c2h_tuser_src        (m_axis_qdma_c2h_tuser_src),
  .m_axis_qdma_c2h_tuser_dst        (m_axis_qdma_c2h_tuser_dst),
  .m_axis_qdma_c2h_tready           (m_axis_qdma_c2h_tready),

  .m_axis_adap_tx_250mhz_tvalid     (m_axis_adap_tx_250mhz_tvalid),
  .m_axis_adap_tx_250mhz_tdata      (m_axis_adap_tx_250mhz_tdata),
  .m_axis_adap_tx_250mhz_tkeep      (m_axis_adap_tx_250mhz_tkeep),
  .m_axis_adap_tx_250mhz_tlast      (m_axis_adap_tx_250mhz_tlast),
  .m_axis_adap_tx_250mhz_tuser_size (m_axis_adap_tx_250mhz_tuser_size),
  .m_axis_adap_tx_250mhz_tuser_src  (m_axis_adap_tx_250mhz_tuser_src),
  .m_axis_adap_tx_250mhz_tuser_dst  (m_axis_adap_tx_250mhz_tuser_dst),
  .m_axis_adap_tx_250mhz_tready     (m_axis_adap_tx_250mhz_tready),

  .s_axis_adap_rx_250mhz_tvalid     (s_axis_adap_rx_250mhz_tvalid),
  .s_axis_adap_rx_250mhz_tdata      (s_axis_adap_rx_250mhz_tdata),
  .s_axis_adap_rx_250mhz_tkeep      (s_axis_adap_rx_250mhz_tkeep),
  .s_axis_adap_rx_250mhz_tlast      (s_axis_adap_rx_250mhz_tlast),
  .s_axis_adap_rx_250mhz_tuser_size (s_axis_adap_rx_250mhz_tuser_size),
  .s_axis_adap_rx_250mhz_tuser_src  (s_axis_adap_rx_250mhz_tuser_src),
  .s_axis_adap_rx_250mhz_tuser_dst  (s_axis_adap_rx_250mhz_tuser_dst),
  .s_axis_adap_rx_250mhz_tready     (s_axis_adap_rx_250mhz_tready),

  .mod_rstn                         (mod_rstn[0]),
  .mod_rst_done                     (mod_rst_done[0]),

// For AU55N, AU55C, AU50, and AU280, we generate 100MHz reference clock which is needed when HBM IP is instantiated
// in user-defined logic.
// Temperature related outputs can be added to route to CMS

`ifdef __au55n__
  .ref_clk_100mhz                   (ref_clk_100mhz),
`elsif __au55c__
  .ref_clk_100mhz                   (ref_clk_100mhz),
`elsif __au50__
  .ref_clk_100mhz                   (ref_clk_100mhz),
`elsif __au280__
  .ref_clk_100mhz                   (ref_clk_100mhz),    
`endif

  .axil_aclk                        (axil_aclk),
  .axis_aclk                        (axis_aclk)
);
