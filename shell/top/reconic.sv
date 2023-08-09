//==============================================================================
// Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
// SPDX-License-Identifier: MIT
//
//==============================================================================
`timescale 1ns/1ps

module reconic # (
  parameter AXIL_REG_ADDR_WIDTH  = 12,
  parameter AXIL_CTRL_ADDR_WIDTH = 13,
  parameter AXIL_DATA_WIDTH      = 32,
  parameter AXIS_DATA_WIDTH      = 512,
  parameter AXIS_KEEP_WIDTH      = 64,
  parameter AXIS_USER_WIDTH      = 16
) (
  // Table control interface
  input         s_axil_ctrl_awvalid,
  input  [31:0] s_axil_ctrl_awaddr,
  output        s_axil_ctrl_awready,
  input         s_axil_ctrl_wvalid,
  input  [31:0] s_axil_ctrl_wdata,
  output        s_axil_ctrl_wready,
  output        s_axil_ctrl_bvalid,
  output  [1:0] s_axil_ctrl_bresp,
  input         s_axil_ctrl_bready,
  input         s_axil_ctrl_arvalid,
  input  [31:0] s_axil_ctrl_araddr,
  output        s_axil_ctrl_arready,
  output        s_axil_ctrl_rvalid,
  output [31:0] s_axil_ctrl_rdata,
  output  [1:0] s_axil_ctrl_rresp,
  input         s_axil_ctrl_rready,

  // Register control interface
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

  // Compute Logic Register control interface
  input         s_axil_cl_reg_awvalid,
  input  [31:0] s_axil_cl_reg_awaddr,
  output        s_axil_cl_reg_awready,
  input         s_axil_cl_reg_wvalid,
  input  [31:0] s_axil_cl_reg_wdata,
  output        s_axil_cl_reg_wready,
  output        s_axil_cl_reg_bvalid,
  output  [1:0] s_axil_cl_reg_bresp,
  input         s_axil_cl_reg_bready,
  input         s_axil_cl_reg_arvalid,
  input  [31:0] s_axil_cl_reg_araddr,
  output        s_axil_cl_reg_arready,
  output        s_axil_cl_reg_rvalid,
  output [31:0] s_axil_cl_reg_rdata,
  output  [1:0] s_axil_cl_reg_rresp,
  input         s_axil_cl_reg_rready,

  // Receive packets from CMAC RX path
  input            s_axis_cmac_rx_tvalid,
  input    [511:0] s_axis_cmac_rx_tdata,
  input     [63:0] s_axis_cmac_rx_tkeep,
  input            s_axis_cmac_rx_tlast,
  input     [15:0] s_axis_cmac_rx_tuser_size,
`ifdef DEBUG
  input     [31:0] s_axis_cmac_rx_tuser_idx,
`endif
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

  // Compute Logic AXI interface for memory access
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

  input          axil_aclk,
  input          axil_rstn,
  input          axis_aclk,
  input          axis_rstn
);

localparam METADATA_WIDTH = 263;
localparam FIFO_WRITE_DEPTH = 512;

/* 
 * Metadata contains debug information and control data
 * Total size   : 263 bits
 * @index       : 32-bit, index of an incoming packet, used for debug purpose
 * @ip_src      : 32-bit, IP source address
 * @ip_dst      : 32-bit, IP destination address
 * @udp_sport   : 16-bit, UDP source port
 * @udp_dport   : 16-bit, UDP destination port
 * @opcode      : 5-bit, opcode
 * @pktlen      : 16-bit, packet length
 * @dma_length  : 32-bit, length in bytes of the DMA operation
 * @r_key       : 32-bit, remote key
 * @se          : 1-bit, solicited event
 * @psn         : 24-bit, packet sequence number
 * @msn         : 24-bit, message sequence number
 * @is_rdma     : 1-bit, indicates that this packet is a rdma packet
 */
logic [METADATA_WIDTH-1:0] pc_in_metadata;
logic                      pc_in_metadata_valid;
logic                      set_pc_in_metadata_valid_low;
logic [METADATA_WIDTH-1:0] pc_out_metadata;
logic                      pc_out_metadata_valid;

// Metadata input
logic [31:0] pc_in_index;
logic [31:0] pc_in_ip_src;
logic [31:0] pc_in_ip_dst;
logic [15:0] pc_in_udp_sport;
logic [15:0] pc_in_udp_dport;
logic [4:0]  pc_in_opcode;
logic [15:0] pc_in_pktlen;
logic [31:0] pc_in_dma_length;
logic [31:0] pc_in_r_key;
logic        pc_in_se;
logic [23:0] pc_in_psn;
logic [23:0] pc_in_msn;
logic        pc_in_is_rdma;

// Metadata output
logic [31:0] pc_out_index;
(* mark_debug = "true" *) logic [31:0] pc_out_ip_src;
(* mark_debug = "true" *) logic [31:0] pc_out_ip_dst;
(* mark_debug = "true" *) logic [15:0] pc_out_udp_sport;
(* mark_debug = "true" *) logic [15:0] pc_out_udp_dport;
(* mark_debug = "true" *) logic [4:0]  pc_out_opcode;
(* mark_debug = "true" *) logic [15:0] pc_out_pktlen;
(* mark_debug = "true" *) logic [31:0] pc_out_dma_length;
(* mark_debug = "true" *) logic [31:0] pc_out_r_key;
(* mark_debug = "true" *) logic        pc_out_se;
(* mark_debug = "true" *) logic [23:0] pc_out_psn;
(* mark_debug = "true" *) logic [23:0] pc_out_msn;
(* mark_debug = "true" *) logic        pc_out_is_rdma;

logic roce_pkt_recved;
logic non_roce_pkt_recved;
logic packet_filter_err;
logic roce_pkt_recved_at_axis_clk;
logic non_roce_pkt_recved_at_axis_clk;
logic [31:0] fatal_err;

// Declaration for buffer_mac_rx_data
logic wr_en;
logic rd_en;
logic buffer_full;
logic buff_empty;
logic buffer_vld;
logic [511:0] buffer_out_tdata;
logic  [63:0] buffer_out_tkeep;
logic  [15:0] buffer_out_tuser_size;
logic         buffer_out_tlast;
`ifdef DEBUG
logic  [31:0] buffer_out_tuser_idx;
`endif

logic         pc_in_tvalid;
logic [511:0] pc_in_tdata;
logic [63:0]  pc_in_tkeep;
logic         pc_in_tlast;
logic         pc_in_tready;

logic         pc_non_roce_out_tvalid;
logic [511:0] pc_non_roce_out_tdata;
logic [63:0]  pc_non_roce_out_tkeep;
logic [15:0]  pc_non_roce_out_tuser_size;
logic         pc_non_roce_out_tlast;
logic         pc_non_roce_out_tready;

logic         pc_roce_out_tvalid;
logic [511:0] pc_roce_out_tdata;
logic [63:0]  pc_roce_out_tkeep;
logic [15:0]  pc_roce_out_tuser_size;
logic         pc_roce_out_tlast;
logic         pc_roce_out_tready;

logic   [1:0] pkt_filter_err;

// rn_reg_control only uses fatal_err[5:0]. When changing fatal_err, 
// please make sure that you also change fatal_err in rn_reg_control
// fatal_err[1]: RDMA FIFO in packet_filter is overflowed
// fatal_err[0]: non-RDMA FIFO in packet_filter is overflowed
assign fatal_err = {27'd0, 3'd0, packet_filter_err};

// Register control
rn_reg_control #(
  .AXIL_ADDR_WIDTH(AXIL_REG_ADDR_WIDTH),
  .AXIL_DATA_WIDTH(AXIL_DATA_WIDTH)
) rn_reg_control_inst (
  .s_axil_reg_awvalid(s_axil_reg_awvalid),
  .s_axil_reg_awaddr (s_axil_reg_awaddr[AXIL_REG_ADDR_WIDTH-1:0]),
  .s_axil_reg_awready(s_axil_reg_awready),
  .s_axil_reg_wvalid (s_axil_reg_wvalid ),
  .s_axil_reg_wdata  (s_axil_reg_wdata  ),
  .s_axil_reg_wready (s_axil_reg_wready ),
  .s_axil_reg_bvalid (s_axil_reg_bvalid ),
  .s_axil_reg_bresp  (s_axil_reg_bresp  ),
  .s_axil_reg_bready (s_axil_reg_bready ),
  .s_axil_reg_arvalid(s_axil_reg_arvalid),
  .s_axil_reg_araddr (s_axil_reg_araddr[AXIL_REG_ADDR_WIDTH-1:0]),
  .s_axil_reg_arready(s_axil_reg_arready),
  .s_axil_reg_rvalid (s_axil_reg_rvalid ),
  .s_axil_reg_rdata  (s_axil_reg_rdata  ),
  .s_axil_reg_rresp  (s_axil_reg_rresp  ),
  .s_axil_reg_rready (s_axil_reg_rready ),

  // input
  .roce_pkt_recved    (roce_pkt_recved),
  .non_roce_pkt_recved(non_roce_pkt_recved),
  .fatal_err          (fatal_err),

  .axil_aclk (axil_aclk),
  .axil_arstn(axil_rstn)
);

// Buffer data coming from the MAC rx path
`ifdef DEBUG
xpm_fifo_sync #(
  .DOUT_RESET_VALUE    ("0"),
  .ECC_MODE            ("no_ecc"),
  .FIFO_MEMORY_TYPE    ("auto"),
  .FIFO_READ_LATENCY   (1),
  .FIFO_WRITE_DEPTH    (FIFO_WRITE_DEPTH),
  .READ_DATA_WIDTH     (AXIS_DATA_WIDTH + AXIS_KEEP_WIDTH + AXIS_USER_WIDTH + 32 + 1),
  .READ_MODE           ("fwft"),
  .WRITE_DATA_WIDTH    (AXIS_DATA_WIDTH + AXIS_KEEP_WIDTH + AXIS_USER_WIDTH + 32 + 1)
) buffer_mac_rx_data (
  .wr_en         (wr_en),
  .din           ({s_axis_cmac_rx_tdata, s_axis_cmac_rx_tkeep, s_axis_cmac_rx_tuser_size, s_axis_cmac_rx_tuser_idx, s_axis_cmac_rx_tlast}),
  .wr_ack        (),
  .rd_en         (rd_en),
  .data_valid    (buffer_vld),
  .dout          ({buffer_out_tdata, buffer_out_tkeep, buffer_out_tuser_size, buffer_out_tuser_idx, buffer_out_tlast}),

  .wr_data_count (),
  .rd_data_count (),

  .empty         (buff_empty),
  .full          (buffer_full),
  .almost_empty  (),
  .almost_full   (),
  .overflow      (),
  .underflow     (),
  .prog_empty    (),
  .prog_full     (),
  .sleep         (1'b0),

  .sbiterr       (),
  .dbiterr       (),
  .injectsbiterr (1'b0),
  .injectdbiterr (1'b0),

  .wr_clk        (axis_aclk),
  .rst           (~axis_rstn),
  .rd_rst_busy   (),
  .wr_rst_busy   ()
);
`else
xpm_fifo_sync #(
  .DOUT_RESET_VALUE    ("0"),
  .ECC_MODE            ("no_ecc"),
  .FIFO_MEMORY_TYPE    ("auto"),
  .FIFO_READ_LATENCY   (1),
  .FIFO_WRITE_DEPTH    (FIFO_WRITE_DEPTH),
  .READ_DATA_WIDTH     (AXIS_DATA_WIDTH + AXIS_KEEP_WIDTH + AXIS_USER_WIDTH + 1),
  .READ_MODE           ("fwft"),
  .WRITE_DATA_WIDTH    (AXIS_DATA_WIDTH + AXIS_KEEP_WIDTH + AXIS_USER_WIDTH + 1)
) buffer_mac_rx_data (
  .wr_en         (wr_en),
  .din           ({s_axis_cmac_rx_tdata, s_axis_cmac_rx_tkeep, s_axis_cmac_rx_tuser_size, s_axis_cmac_rx_tlast}),
  .wr_ack        (),
  .rd_en         (rd_en),
  .data_valid    (buffer_vld),
  .dout          ({buffer_out_tdata, buffer_out_tkeep, buffer_out_tuser_size, buffer_out_tlast}),

  .wr_data_count (),
  .rd_data_count (),

  .empty         (buff_empty),
  .full          (buffer_full),
  .almost_empty  (),
  .almost_full   (),
  .overflow      (),
  .underflow     (),
  .prog_empty    (),
  .prog_full     (),
  .sleep         (1'b0),

  .sbiterr       (),
  .dbiterr       (),
  .injectsbiterr (1'b0),
  .injectdbiterr (1'b0),

  .wr_clk        (axis_aclk),
  .rst           (~axis_rstn),
  .rd_rst_busy   (),
  .wr_rst_busy   ()
);
`endif

assign s_axis_cmac_rx_tready = !buffer_full;
assign wr_en                 = s_axis_cmac_rx_tready && s_axis_cmac_rx_tvalid;
assign rd_en                 = pc_in_tready && !buff_empty;
assign pc_in_tvalid          = rd_en;
assign pc_in_tdata           = rd_en ? buffer_out_tdata : 512'd0;
assign pc_in_tkeep           = rd_en ? buffer_out_tkeep :  64'd0;
assign pc_in_tlast           = rd_en ? buffer_out_tlast :   1'b0;

// Metadata input
`ifdef DEBUG
assign pc_in_index      = buffer_out_tuser_idx;
`else
assign pc_in_index      = 32'd0;
`endif
assign pc_in_ip_src     = 32'd0;
assign pc_in_ip_dst     = 32'd0;
assign pc_in_udp_sport  = 2'd0;
assign pc_in_udp_dport  = 5'd0;
assign pc_in_opcode     = 8'd0;
assign pc_in_pktlen     = buffer_out_tuser_size;
assign pc_in_dma_length = 56'd0;
assign pc_in_r_key      = 6'd0;
assign pc_in_se         = 2'd0;
assign pc_in_psn        = 12'd0;
assign pc_in_msn        = 24'd0;
assign pc_in_is_rdma    = 1'b0;
assign pc_in_metadata   = {pc_in_index, pc_in_ip_src, pc_in_ip_dst, pc_in_udp_sport, pc_in_udp_dport, pc_in_opcode, pc_in_pktlen, pc_in_dma_length, pc_in_r_key, pc_in_se, pc_in_psn, pc_in_msn, pc_in_is_rdma};
assign pc_in_metadata_valid = pc_in_tvalid && pc_in_tready && set_pc_in_metadata_valid_low;

// Metadata output, valid signal is pc_out_metadata_valid
assign pc_out_index      = pc_out_metadata_valid ? pc_out_metadata[262:231] : 0;
assign pc_out_ip_src     = pc_out_metadata_valid ? pc_out_metadata[230:199] : 0;
assign pc_out_ip_dst     = pc_out_metadata_valid ? pc_out_metadata[198:167] : 0;
assign pc_out_udp_sport  = pc_out_metadata_valid ? pc_out_metadata[166:151] : 0;
assign pc_out_udp_dport  = pc_out_metadata_valid ? pc_out_metadata[150:135] : 0;
assign pc_out_opcode     = pc_out_metadata_valid ? pc_out_metadata[134:130] : 0;
assign pc_out_pktlen     = pc_out_metadata_valid ? pc_out_metadata[129:114] : 0;
assign pc_out_dma_length = pc_out_metadata_valid ? pc_out_metadata[113: 82] : 0;
assign pc_out_r_key      = pc_out_metadata_valid ? pc_out_metadata[81 : 50] : 0;
assign pc_out_se         = pc_out_metadata_valid ? pc_out_metadata[49 : 49] : 0;
assign pc_out_psn        = pc_out_metadata_valid ? pc_out_metadata[48 : 25] : 0;
assign pc_out_msn        = pc_out_metadata_valid ? pc_out_metadata[24 :  1] : 0;
assign pc_out_is_rdma    = pc_out_metadata_valid ? pc_out_metadata[0  :  0] : 0;

always @(posedge axis_aclk) 
begin
  if(~axis_rstn)
  begin
    set_pc_in_metadata_valid_low <= 1'b1;
  end
  else begin
    if(pc_in_tvalid && pc_in_tready && !pc_in_tlast) 
    begin
      set_pc_in_metadata_valid_low <= 1'b0;  
    end

    if(pc_in_tvalid && pc_in_tready && pc_in_tlast)
    begin
      set_pc_in_metadata_valid_low <= 1'b1;
    end
  end
end

// Packet Classification module
packet_classification #(
  .METADATA_WIDTH(METADATA_WIDTH)
)pacekt_classification_inst(
  // Metadata
  .user_metadata_in       (pc_in_metadata),
  .user_metadata_in_valid (pc_in_metadata_valid),
  .user_metadata_out      (pc_out_metadata),
  .user_metadata_out_valid(pc_out_metadata_valid),

  // Packet input in axi-streaming format
  .s_axis_tdata           (pc_in_tdata),
  .s_axis_tkeep           (pc_in_tkeep),
  .s_axis_tvalid          (pc_in_tvalid),
  .s_axis_tlast           (pc_in_tlast),
  .s_axis_tready          (pc_in_tready),

  // RoCEv2 packet output in axi-streaming format
  .m_axis_roce_tdata          (pc_roce_out_tdata),
  .m_axis_roce_tkeep          (pc_roce_out_tkeep),
  .m_axis_roce_tuser_size     (pc_roce_out_tuser_size),
  .m_axis_roce_tvalid         (pc_roce_out_tvalid),
  .m_axis_roce_tready         (pc_roce_out_tready),
  .m_axis_roce_tlast          (pc_roce_out_tlast),

  // non-RoCEv2 packet output in axi-streaming format
  .m_axis_non_roce_tdata      (pc_non_roce_out_tdata),
  .m_axis_non_roce_tkeep      (pc_non_roce_out_tkeep),
  .m_axis_non_roce_tuser_size (pc_non_roce_out_tuser_size),
  .m_axis_non_roce_tvalid     (pc_non_roce_out_tvalid),
  .m_axis_non_roce_tready     (pc_non_roce_out_tready),
  .m_axis_non_roce_tlast      (pc_non_roce_out_tlast),

  // Slave AXI-lite interface
  .s_axil_ctrl_awaddr     (s_axil_ctrl_awaddr[AXIL_CTRL_ADDR_WIDTH-1:0]),
  .s_axil_ctrl_awvalid    (s_axil_ctrl_awvalid),
  .s_axil_ctrl_awready    (s_axil_ctrl_awready),
  .s_axil_ctrl_wdata      (s_axil_ctrl_wdata),
  .s_axil_ctrl_wvalid     (s_axil_ctrl_wvalid),
  .s_axil_ctrl_wready     (s_axil_ctrl_wready),
  .s_axil_ctrl_bresp      (s_axil_ctrl_bresp),
  .s_axil_ctrl_bvalid     (s_axil_ctrl_bvalid),
  .s_axil_ctrl_bready     (s_axil_ctrl_bready),
  .s_axil_ctrl_araddr     (s_axil_ctrl_araddr[AXIL_CTRL_ADDR_WIDTH-1:0]),
  .s_axil_ctrl_arvalid    (s_axil_ctrl_arvalid),
  .s_axil_ctrl_arready    (s_axil_ctrl_arready),
  .s_axil_ctrl_rdata      (s_axil_ctrl_rdata),
  .s_axil_ctrl_rvalid     (s_axil_ctrl_rvalid),
  .s_axil_ctrl_rready     (s_axil_ctrl_rready),
  .s_axil_ctrl_rresp      (s_axil_ctrl_rresp),

  .pkt_filter_err         (pkt_filter_err),

  .axis_aclk (axis_aclk),
  .axis_rstn (axis_rstn),
  .axil_aclk (axil_aclk),
  .axil_rstn (axil_rstn)
);

// TODO: Message status monitor

// Compute Logic box
compute_logic_wrapper #(
  .AXIL_ADDR_WIDTH(AXIL_REG_ADDR_WIDTH),
  .AXIL_DATA_WIDTH(AXIL_DATA_WIDTH),
  .AXIS_DATA_WIDTH(AXIS_DATA_WIDTH),
  .AXIS_KEEP_WIDTH(AXIS_KEEP_WIDTH)
) compute_logic_inst (
  .s_axil_awvalid(s_axil_cl_reg_awvalid),
  .s_axil_awaddr (s_axil_cl_reg_awaddr),
  .s_axil_awready(s_axil_cl_reg_awready),
  .s_axil_wvalid (s_axil_cl_reg_wvalid),
  .s_axil_wdata  (s_axil_cl_reg_wdata),
  .s_axil_wready (s_axil_cl_reg_wready),
  .s_axil_bvalid (s_axil_cl_reg_bvalid),
  .s_axil_bresp  (s_axil_cl_reg_bresp),
  .s_axil_bready (s_axil_cl_reg_bready),
  .s_axil_arvalid(s_axil_cl_reg_arvalid),
  .s_axil_araddr (s_axil_cl_reg_araddr),
  .s_axil_arready(s_axil_cl_reg_arready),
  .s_axil_rvalid (s_axil_cl_reg_rvalid),
  .s_axil_rdata  (s_axil_cl_reg_rdata),
  .s_axil_rresp  (s_axil_cl_reg_rresp),
  .s_axil_rready (s_axil_cl_reg_rready),

  .m_axi_awid    (m_axi_compute_logic_awid),
  .m_axi_awaddr  (m_axi_compute_logic_awaddr),
  .m_axi_awqos   (m_axi_compute_logic_awqos),
  .m_axi_awlen   (m_axi_compute_logic_awlen),
  .m_axi_awsize  (m_axi_compute_logic_awsize),
  .m_axi_awburst (m_axi_compute_logic_awburst),
  .m_axi_awcache (m_axi_compute_logic_awcache),
  .m_axi_awprot  (m_axi_compute_logic_awprot),
  .m_axi_awvalid (m_axi_compute_logic_awvalid),
  .m_axi_awready (m_axi_compute_logic_awready),
  .m_axi_wdata   (m_axi_compute_logic_wdata),
  .m_axi_wstrb   (m_axi_compute_logic_wstrb),
  .m_axi_wlast   (m_axi_compute_logic_wlast),
  .m_axi_wvalid  (m_axi_compute_logic_wvalid),
  .m_axi_wready  (m_axi_compute_logic_wready),
  .m_axi_awlock  (m_axi_compute_logic_awlock),
  .m_axi_bid     (m_axi_compute_logic_bid),
  .m_axi_bresp   (m_axi_compute_logic_bresp),
  .m_axi_bvalid  (m_axi_compute_logic_bvalid),
  .m_axi_bready  (m_axi_compute_logic_bready),
  .m_axi_arid    (m_axi_compute_logic_arid),
  .m_axi_araddr  (m_axi_compute_logic_araddr),
  .m_axi_arlen   (m_axi_compute_logic_arlen),
  .m_axi_arsize  (m_axi_compute_logic_arsize),
  .m_axi_arburst (m_axi_compute_logic_arburst),
  .m_axi_arcache (m_axi_compute_logic_arcache),
  .m_axi_arprot  (m_axi_compute_logic_arprot),
  .m_axi_arvalid (m_axi_compute_logic_arvalid),
  .m_axi_arready (m_axi_compute_logic_arready),
  .m_axi_rid     (m_axi_compute_logic_rid),
  .m_axi_rdata   (m_axi_compute_logic_rdata),
  .m_axi_rresp   (m_axi_compute_logic_rresp),
  .m_axi_rlast   (m_axi_compute_logic_rlast),
  .m_axi_rvalid  (m_axi_compute_logic_rvalid),
  .m_axi_rready  (m_axi_compute_logic_rready),
  .m_axi_arlock  (m_axi_compute_logic_arlock),
  .m_axi_arqos   (m_axi_compute_logic_arqos),

  .axil_aclk (axil_aclk),
  .axil_rstn (axil_rstn),
  .axis_aclk (axis_aclk),
  .axis_rstn (axis_rstn)
);

assign m_axis_user2rdma_roce_from_cmac_rx_tvalid = pc_roce_out_tvalid;
assign m_axis_user2rdma_roce_from_cmac_rx_tdata  = pc_roce_out_tdata;
assign m_axis_user2rdma_roce_from_cmac_rx_tkeep  = pc_roce_out_tkeep;
assign m_axis_user2rdma_roce_from_cmac_rx_tlast  = pc_roce_out_tlast;
assign pc_roce_out_tready                        = m_axis_user2rdma_roce_from_cmac_rx_tready;

assign m_axis_qdma_c2h_tvalid     = pc_non_roce_out_tvalid;
assign m_axis_qdma_c2h_tdata      = pc_non_roce_out_tdata;
assign m_axis_qdma_c2h_tkeep      = pc_non_roce_out_tkeep;
assign m_axis_qdma_c2h_tlast      = pc_non_roce_out_tlast;
assign m_axis_qdma_c2h_tuser_size = pc_non_roce_out_tuser_size;
assign pc_non_roce_out_tready     = m_axis_qdma_c2h_tready;

assign m_axis_cmac_tx_tvalid     = s_axis_rdma2user_to_cmac_tx_tvalid;
assign m_axis_cmac_tx_tdata      = s_axis_rdma2user_to_cmac_tx_tdata;
assign m_axis_cmac_tx_tkeep      = s_axis_rdma2user_to_cmac_tx_tkeep;
assign m_axis_cmac_tx_tlast      = s_axis_rdma2user_to_cmac_tx_tlast;
assign m_axis_cmac_tx_tuser_size = 16'd0;
assign s_axis_rdma2user_to_cmac_tx_tready = m_axis_cmac_tx_tready;

assign m_axis_user2rdma_from_qdma_tx_tvalid = s_axis_qdma_h2c_tvalid;
assign m_axis_user2rdma_from_qdma_tx_tdata  = s_axis_qdma_h2c_tdata;
assign m_axis_user2rdma_from_qdma_tx_tkeep  = s_axis_qdma_h2c_tkeep;
assign m_axis_user2rdma_from_qdma_tx_tlast  = s_axis_qdma_h2c_tlast;
assign s_axis_qdma_h2c_tready               = m_axis_user2rdma_from_qdma_tx_tready;

// Get number of roce and non-roce packets received
assign roce_pkt_recved_at_axis_clk     = pc_out_metadata_valid;
assign non_roce_pkt_recved_at_axis_clk = pc_non_roce_out_tready && pc_non_roce_out_tvalid && pc_non_roce_out_tlast;

// Convert signals @ axis_aclk to axil_aclk
xpm_cdc_single #(
  .DEST_SYNC_FF(4), // DECIMAL; range: 2-10
  .INIT_SYNC_FF(0), // DECIMAL; 0=disable simulation init values, 1=enable simulation init values
  .SIM_ASSERT_CHK(1), // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
  .SRC_INPUT_REG(1) // DECIMAL; 0=do not register input, 1=register input
) roce_pkt_recved_cdc (
  .dest_out(roce_pkt_recved), 
  .dest_clk(axil_aclk), 
  .src_clk(axis_aclk), 
  .src_in(roce_pkt_recved_at_axis_clk)
);

xpm_cdc_single #(
  .DEST_SYNC_FF(4), // DECIMAL; range: 2-10
  .INIT_SYNC_FF(0), // DECIMAL; 0=disable simulation init values, 1=enable simulation init values
  .SIM_ASSERT_CHK(1), // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
  .SRC_INPUT_REG(1) // DECIMAL; 0=do not register input, 1=register input
) non_roce_pkt_recved_cdc (
  .dest_out(non_roce_pkt_recved), 
  .dest_clk(axil_aclk), 
  .src_clk(axis_aclk), 
  .src_in(non_roce_pkt_recved_at_axis_clk)
);

xpm_cdc_array_single #(
   .DEST_SYNC_FF(4),   // DECIMAL; range: 2-10
   .INIT_SYNC_FF(0),   // DECIMAL; 0=disable simulation init values, 1=enable simulation init values
   .SIM_ASSERT_CHK(1), // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
   .SRC_INPUT_REG(1),  // DECIMAL; 0=do not register input, 1=register input
   .WIDTH(2)           // DECIMAL; range: 1-1024
) pkt_filter_err_cdc (
   .dest_out(packet_filter_err), // WIDTH-bit output: src_in synchronized to the destination clock 
                                 // domain. This output is registered.

   .dest_clk(axil_aclk),   // 1-bit input: Clock signal for the destination clock domain.
   .src_clk(axis_aclk),    // 1-bit input: optional; required when SRC_INPUT_REG = 1
   .src_in(pkt_filter_err) // WIDTH-bit input: Input single-bit array to be synchronized to destination 
                           //  clock domain. It is assumed that each bit of the array is unrelated to 
                           //  the others. This is reflected in the constraints applied to this macro. 
                           //  To transfer a binary value losslessly across the two clock domains, use 
                           //  the XPM_CDC_GRAY macro instead.
);

(* mark_debug = "true" *) logic [63:0] axis_clk_latency_timer;
(* mark_debug = "true" *) logic [63:0] axil_clk_latency_timer;
always_ff @(posedge axis_aclk)
begin
  if(!axis_rstn) begin
    axis_clk_latency_timer <= 64'd0;
  end
  else begin
    axis_clk_latency_timer <= axis_clk_latency_timer + 64'd1;
  end
end

always_ff @(posedge axil_aclk)
begin
  if(!axil_rstn) begin
    axil_clk_latency_timer <= 64'd0;
  end
  else begin
    axil_clk_latency_timer <= axil_clk_latency_timer + 64'd1;
  end
end

endmodule: reconic
