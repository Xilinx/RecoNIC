//==============================================================================
// Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
// SPDX-License-Identifier: MIT
//
//==============================================================================
`timescale 1ns/1ps

import rn_tb_pkg::*;

module rn_tb_driver #(
  parameter AXIS_DATA_WIDTH = 512,
  parameter AXIS_KEEP_WIDTH = 64,
  parameter USER_SIZE_WIDTH = 16,
  parameter USER_IDX_WIDTH  = 32
)(
  input  longint          num_pkts,
  input  string           table_filename,
  input  string           rsp_table_filename,
  input  string           rdma_cfg_filename,
  input  string           rdma_stat_filename,
  ref    mbox_pkt_str_t   mbox_pkt_str,
  // Output stimulus
  output [AXIS_DATA_WIDTH-1:0] m_axis_tdata,
  output [AXIS_KEEP_WIDTH-1:0] m_axis_tkeep,
  output                       m_axis_tvalid,
  output                       m_axis_tlast,
  output [USER_SIZE_WIDTH-1:0] m_axis_tuser_size,
  input                        m_axis_tready,

  output reg        m_axil_rn_awvalid,
  output reg [31:0] m_axil_rn_awaddr,
  input             m_axil_rn_awready,
  output reg        m_axil_rn_wvalid,
  output reg [31:0] m_axil_rn_wdata,
  input             m_axil_rn_wready,
  input             m_axil_rn_bvalid,
  input       [1:0] m_axil_rn_bresp,
  output reg        m_axil_rn_bready,
  output            m_axil_rn_arvalid,
  output     [31:0] m_axil_rn_araddr,
  input             m_axil_rn_arready,
  input             m_axil_rn_rvalid,
  input      [31:0] m_axil_rn_rdata,
  input       [1:0] m_axil_rn_rresp,
  output            m_axil_rn_rready,

  output reg        m_axil_rdma_awvalid,
  output reg [31:0] m_axil_rdma_awaddr,
  input             m_axil_rdma_awready,
  output reg        m_axil_rdma_wvalid,
  output reg [31:0] m_axil_rdma_wdata,
  input             m_axil_rdma_wready,
  input             m_axil_rdma_bvalid,
  input       [1:0] m_axil_rdma_bresp,
  output reg        m_axil_rdma_bready,
  output            m_axil_rdma_arvalid,
  output     [31:0] m_axil_rdma_araddr,
  input             m_axil_rdma_arready,
  input             m_axil_rdma_rvalid,
  input      [31:0] m_axil_rdma_rdata,
  input       [1:0] m_axil_rdma_rresp,
  output            m_axil_rdma_rready,

  input             start_sim,
  input             start_config_rdma,
  input             start_stat_rdma,
  output            stimulus_all_sent,

  output reg axil_clk,
  output reg axil_rstn,
  output reg axis_clk,
  output reg axis_rstn
);

localparam SENDING_DELAY = 100;
logic [31:0] delay_cnt;
logic        start_send;

axis_pkt_queue_t packets;

logic start_reading;
logic reading_done;
logic [63:0] pkt_idx;
logic [63:0] axis_beat_idx;

logic [AXIS_DATA_WIDTH-1:0] m_axis_tdata_reg;
logic [AXIS_KEEP_WIDTH-1:0] m_axis_tkeep_reg;
logic                       m_axis_tvalid_reg;
logic [USER_SIZE_WIDTH-1:0] m_axis_tuser_size_reg;
logic                       m_axis_tlast_reg;

localparam CLK_PERIOD = 10ns;
localparam CLK_PERIOD_75  = 12048ps;
localparam CLK_PERIOD_300 = 3012ps;
localparam CLK_PERIOD_400 = 2500ps;
localparam CLK_PERIOD_200 = 5000ps;

initial begin
  axil_rstn = 1'b0;
  axis_rstn = 1'b0;
  #500ns;
  packets = get_pkt_in_axis(num_pkts, mbox_pkt_str);

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

always_ff @(posedge axis_clk) begin
  if(!axis_rstn) begin
    start_reading <= 1'b0;
  end
  else begin
    start_reading <= reading_done ? 1'b0 : 1'b1;
  end
end

always_ff @(posedge axis_clk) begin
  if(!axis_rstn) begin
    reading_done <= 1'b0;
    pkt_idx       <= 0;
    axis_beat_idx <= 0;
  end
  else begin
    if(m_axis_tready && start_sim && start_send && !reading_done)
    begin
      axis_beat_idx <= axis_beat_idx + 1;
    end

    if(m_axis_tready && packets[axis_beat_idx].tlast && start_sim && start_send && !reading_done) begin
      pkt_idx <= pkt_idx + 1;

      if((pkt_idx == num_pkts-1) && (axis_beat_idx == (packets.size()-1))) begin
        reading_done <= 1'b1;
        $display("INFO: [rn_tb_driver] Got all the input stimululs");
      end
    end

    if(pkt_idx == 32'hffff_ffff) begin
      $fatal(1, "ERROR: [rn_tb_driver] pkt_idx overflow at time %0t, too many packets", $time);
    end
  end
end

assign stimulus_all_sent = reading_done;

// Reading packets in axi-streaming mode
always_ff @(posedge axis_clk) begin
  if(!axis_rstn) begin
    m_axis_tdata_reg      <= 0;
    m_axis_tkeep_reg      <= 0;
    m_axis_tvalid_reg     <= 0;
    m_axis_tuser_size_reg <= 0;
    m_axis_tlast_reg      <= 0;
    delay_cnt             <= 0;
    start_send            <= 1'b0;
  end
  else begin
    if((packets.size()!=0) && start_sim && start_send && start_reading && !reading_done && m_axis_tready) begin
      m_axis_tdata_reg      <= packets[axis_beat_idx].tdata;
      m_axis_tkeep_reg      <= packets[axis_beat_idx].tkeep;
      m_axis_tuser_size_reg <= packets[axis_beat_idx].pkt_len;
      m_axis_tlast_reg      <= packets[axis_beat_idx].tlast;
      m_axis_tvalid_reg     <= (packets[axis_beat_idx].tdata[63:0] != 64'hdddddddddddddddd) ? 1'b1 : 1'b0;
      $display("INFO: [rn_tb_driver] time=%0t Reading %d-th packet = %x", $time, pkt_idx, packets[axis_beat_idx].tdata);
    end
    else begin
      m_axis_tvalid_reg     <= 1'b0;
    end

    if(!start_send) begin
      delay_cnt <= delay_cnt + 1;
      if(delay_cnt > SENDING_DELAY) begin
        start_send <= 1'b1;
      end
    end

  end
end

assign m_axis_tdata      = m_axis_tdata_reg;
assign m_axis_tkeep      = m_axis_tkeep_reg;
assign m_axis_tvalid     = m_axis_tvalid_reg;
assign m_axis_tuser_size = m_axis_tuser_size_reg;
assign m_axis_tlast      = m_axis_tlast_reg;

// TODO: Update register configuration for RecoNIC and RDMA
/* Configure RecoNIC */
axil_reg_stimulus config_rn (
  .table_config_filename(""),
  .m_axil_reg_awvalid(m_axil_rn_awvalid),
  .m_axil_reg_awaddr (m_axil_rn_awaddr),
  .m_axil_reg_awready(m_axil_rn_awready),
  .m_axil_reg_wvalid (m_axil_rn_wvalid),
  .m_axil_reg_wdata  (m_axil_rn_wdata),
  .m_axil_reg_wready (m_axil_rn_wready),
  .m_axil_reg_bvalid (m_axil_rn_bvalid),
  .m_axil_reg_bresp  (m_axil_rn_bresp),
  .m_axil_reg_bready (m_axil_rn_bready),
  .m_axil_reg_arvalid(m_axil_rn_arvalid),
  .m_axil_reg_araddr (m_axil_rn_araddr),
  .m_axil_reg_arready(m_axil_rn_arready),
  .m_axil_reg_rvalid (m_axil_rn_rvalid),
  .m_axil_reg_rdata  (m_axil_rn_rdata),
  .m_axil_reg_rresp  (m_axil_rn_rresp),
  .m_axil_reg_rready (m_axil_rn_rready),
  .axil_clk          (axil_clk),
  .axil_rstn         (axil_rstn)
);

/* Configure RDMA */
axil_reg_control config_rdma (
  .which_rdma        ("rdma1"),
  .rdma_cfg_filename (rdma_cfg_filename),
  .rdma_stat_filename(rdma_stat_filename),
  .start_config_rdma (start_config_rdma),
  .finish_config_rdma(),
  .start_rdma_stat   (start_stat_rdma),
  .m_axil_reg_awvalid(m_axil_rdma_awvalid),
  .m_axil_reg_awaddr (m_axil_rdma_awaddr),
  .m_axil_reg_awready(m_axil_rdma_awready),
  .m_axil_reg_wvalid (m_axil_rdma_wvalid),
  .m_axil_reg_wdata  (m_axil_rdma_wdata),
  .m_axil_reg_wready (m_axil_rdma_wready),
  .m_axil_reg_bvalid (m_axil_rdma_bvalid),
  .m_axil_reg_bresp  (m_axil_rdma_bresp),
  .m_axil_reg_bready (m_axil_rdma_bready),
  .m_axil_reg_arvalid(m_axil_rdma_arvalid),
  .m_axil_reg_araddr (m_axil_rdma_araddr),
  .m_axil_reg_arready(m_axil_rdma_arready),
  .m_axil_reg_rvalid (m_axil_rdma_rvalid),
  .m_axil_reg_rdata  (m_axil_rdma_rdata),
  .m_axil_reg_rresp  (m_axil_rdma_rresp),
  .m_axil_reg_rready (m_axil_rdma_rready),
  .axil_clk          (axil_clk),
  .axil_rstn         (axil_rstn)
);

function automatic axis_pkt_queue_t get_pkt_in_axis (
  longint num_pkts,
  ref mbox_pkt_str_t mbox_pkt_str
);

  //longint pkts_read = 0;
  longint pkt_processed = 0;
  longint glb_beat_cnt = 0;
  longint local_beat_cnt = 0;
  int byte_read = 0;
  string pkt_str;
  string pkt_byte;
  strArray pkt_bytes;
  axis_pkt_queue_t axis_pkts;

  $display("INFO: [rn_tb_driver] time=%0t Getting packets in axi-streaming mode", $time);

  while(pkt_processed < num_pkts) begin
    if(mbox_pkt_str.try_get(pkt_str)) begin
      pkt_bytes = split(pkt_str, " ");
      for(int i=0; i<pkt_bytes.size(); i++) begin
        pkt_byte = pkt_bytes[i];
        axis_pkts[glb_beat_cnt+local_beat_cnt].tdata = pkt_byte.atohex() << (8* byte_read) | (byte_read > 0 ? axis_pkts[glb_beat_cnt+local_beat_cnt].tdata : 0);
        axis_pkts[glb_beat_cnt+local_beat_cnt].tkeep = (1'b1 << byte_read) | (byte_read > 0 ? axis_pkts[glb_beat_cnt+local_beat_cnt].tkeep : 0);
        axis_pkts[glb_beat_cnt+local_beat_cnt].tlast = (i == pkt_bytes.size()-1) ? 1'b1 : 1'b0;
        byte_read++;
        pkt_processed = (i == pkt_bytes.size()-1) ? (pkt_processed + 1) : pkt_processed;
        axis_pkts[glb_beat_cnt+local_beat_cnt].pkt_len = pkt_bytes.size();

        if((byte_read == AXIS_KEEP_WIDTH) || (i == pkt_bytes.size()-1)) begin
          byte_read = 0;
          local_beat_cnt++;
        end
        glb_beat_cnt = (i == pkt_bytes.size()-1) ? (glb_beat_cnt + local_beat_cnt) : glb_beat_cnt;
      end
      $display("INFO: [rn_tb_driver] the %d-th packet: local_beat_cnt=%d, pkt_bytes=%d, global_beat_cnt=%d", pkt_processed, local_beat_cnt, pkt_bytes.size(), glb_beat_cnt);
      local_beat_cnt = 0;
    end
  end
  return axis_pkts;
endfunction // get_pkts from mbox_pkt_str

endmodule: rn_tb_driver