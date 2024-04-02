//==============================================================================
// Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
// SPDX-License-Identifier: MIT
//
//==============================================================================
`timescale 1ns/1ps

module hw_hndshk_wrapper # (
  parameter AXIL_ADDR_WIDTH  = 12,
  parameter AXIL_DATA_WIDTH  = 32,
  parameter AXIS_DATA_WIDTH  = 512,
  parameter AXIS_KEEP_WIDTH  = 64
) (
  // register control interface
  input             s_axil_hw_hndshk_cmd_awvalid,
  input  [31:0]     s_axil_hw_hndshk_cmd_awaddr,
  output            s_axil_hw_hndshk_cmd_awready,
  input             s_axil_hw_hndshk_cmd_wvalid,
  input  [31:0]     s_axil_hw_hndshk_cmd_wdata,
  output            s_axil_hw_hndshk_cmd_wready,
  output            s_axil_hw_hndshk_cmd_bvalid,
  output  [1:0]     s_axil_hw_hndshk_cmd_bresp,
  input             s_axil_hw_hndshk_cmd_bready,
  input             s_axil_hw_hndshk_cmd_arvalid,
  input  [31:0]     s_axil_hw_hndshk_cmd_araddr,
  output            s_axil_hw_hndshk_cmd_arready,
  output            s_axil_hw_hndshk_cmd_rvalid,
  output [31:0]     s_axil_hw_hndshk_cmd_rdata,
  output  [1:0]     s_axil_hw_hndshk_cmd_rresp,
  input             s_axil_hw_hndshk_cmd_rready,

  output            m_axi_to_sys_mem_awid,
  output   [63 : 0] m_axi_to_sys_mem_awaddr,
  output    [3 : 0] m_axi_to_sys_mem_awqos,
  output    [7 : 0] m_axi_to_sys_mem_awlen,
  output    [2 : 0] m_axi_to_sys_mem_awsize,
  output    [1 : 0] m_axi_to_sys_mem_awburst,
  output    [3 : 0] m_axi_to_sys_mem_awcache,
  output    [2 : 0] m_axi_to_sys_mem_awprot,
  output            m_axi_to_sys_mem_awvalid,
  input             m_axi_to_sys_mem_awready,
  output  [511 : 0] m_axi_to_sys_mem_wdata,
  output   [63 : 0] m_axi_to_sys_mem_wstrb,
  output            m_axi_to_sys_mem_wlast,
  output            m_axi_to_sys_mem_wvalid,
  input             m_axi_to_sys_mem_wready,
  output            m_axi_to_sys_mem_awlock,
  input             m_axi_to_sys_mem_bid,
  input     [1 : 0] m_axi_to_sys_mem_bresp,
  input             m_axi_to_sys_mem_bvalid,
  output            m_axi_to_sys_mem_bready,
  output            m_axi_to_sys_mem_arid,
  output   [63 : 0] m_axi_to_sys_mem_araddr,
  output    [7 : 0] m_axi_to_sys_mem_arlen,
  output    [2 : 0] m_axi_to_sys_mem_arsize,
  output    [1 : 0] m_axi_to_sys_mem_arburst,
  output    [3 : 0] m_axi_to_sys_mem_arcache,
  output    [2 : 0] m_axi_to_sys_mem_arprot,
  output            m_axi_to_sys_mem_arvalid,
  input             m_axi_to_sys_mem_arready,
  input             m_axi_to_sys_mem_rid,
  input   [511 : 0] m_axi_to_sys_mem_rdata,
  input     [1 : 0] m_axi_to_sys_mem_rresp,
  input             m_axi_to_sys_mem_rlast,
  input             m_axi_to_sys_mem_rvalid,
  output            m_axi_to_sys_mem_rready,
  output            m_axi_to_sys_mem_arlock,
  output     [3:0]  m_axi_to_sys_mem_arqos,

  input             s_resp_hndler_i_send_cq_db_cnt_valid,
  input  [9 :0]     s_resp_hndler_i_send_cq_db_addr,
  input  [31:0]     s_resp_hndler_i_send_cq_db_cnt,
  output logic      s_resp_hndler_o_send_cq_db_rdy,

  output logic [15:0] m_o_qp_sq_pidb_hndshk,
  output logic [31:0] m_o_qp_sq_pidb_wr_addr_hndshk,
  output logic        m_o_qp_sq_pidb_wr_valid_hndshk,
  input               m_i_qp_sq_pidb_wr_rdy,

  input [63:0]       global_hw_timer,

  input          axil_aclk,
  input          axil_rstn,
  input          axis_aclk,
  input          axis_rstn
);

logic [31:0] ctl_cmd_fifo_dout;
logic        ctl_cmd_fifo_empty_n;
logic        ctl_cmd_fifo_rd_en;

logic hw_hndshk_start;
logic hw_hndshk_done;
logic hw_hndshk_idle;
logic hw_hndshk_ready;

logic kernel_wait_on_cqdb_start;
logic kernel_wait_on_cqdb_done;
logic kernel_wait_on_cqdb_idle;
logic kernel_wait_on_cqdb_ready;

logic kernel_write_wqe_start;
logic kernel_write_wqe_done;
logic kernel_write_wqe_idle;
logic kernel_write_wqe_ready;

logic kernel_write_sqpidb_start;
logic kernel_write_sqpidb_done;
logic kernel_write_sqpidb_idle;
logic kernel_write_sqpidb_ready;

logic [31:0] qpid_wqecount_dout;
logic        qpid_wqecount_empty_n;
logic        qpid_wqecount_read;
logic [63:0] addr_cqdbcount_dout;
logic        addr_cqdbcount_empty_n;
logic        addr_cqdbcount_read;
logic [63:0] addr_sqpidbcount_din;
logic        addr_sqpidbcount_full_n;
logic        addr_sqpidbcount_write;
logic [31:0] hw_timer_din;
logic        hw_timer_write;
logic        hw_timer_full_n;
logic [31:0] sq_pidb_cnt;
logic        sq_pidb_cnt_ap_vld;
logic [31:0] cq_db_cnt;
logic        cq_db_cnt_ap_vld;
logic [31:0] sq_pidb_addr;
logic        sq_pidb_addr_ap_vld;
logic [31:0] wqe_count;
logic        wqe_count_ap_vld;
logic [63:0] hw_start_timer;
logic        hw_start_timer_ap_vld;
logic [15:0] qpid;
logic        qpid_ap_vld;
logic [31:0] wrid;
logic        wrid_ap_vld;
logic [31:0] laddr_msb;
logic        laddr_msb_ap_vld;
logic [31:0] laddr_lsb;
logic        laddr_lsb_ap_vld;
logic [31:0] payload_len;
logic        payload_len_ap_vld;
logic [31:0] opcode;
logic        opcode_ap_vld;
logic [31:0] remote_offset_msb;
logic        remote_offset_msb_ap_vld;
logic [31:0] remote_offset_lsb;
logic        remote_offset_lsb_ap_vld;
logic [31:0] r_key;
logic        r_key_ap_vld;
logic [31:0] send_small_payload0;
logic        send_small_payload0_ap_vld;
logic [31:0] send_small_payload1;
logic        send_small_payload1_ap_vld;
logic [31:0] send_small_payload2;
logic        send_small_payload2_ap_vld;
logic [31:0] send_small_payload3;
logic        send_small_payload3_ap_vld;
logic [31:0] immdt_data;
logic        immdt_data_ap_vld;
logic [31:0] sq_addr_lsb;
logic        sq_addr_lsb_ap_vld;
logic [31:0] sq_addr_msb;
logic        sq_addr_msb_ap_vld;

logic [31:0] sq_pidb_cnt_reg;
logic [31:0] cq_db_cnt_reg;
logic [31:0] sq_pidb_addr_reg;
logic [31:0] wqe_count_reg;
logic [63:0] hw_start_timer_reg;
logic [15:0] qpid_reg;
logic [31:0] wrid_reg;
logic [31:0] laddr_msb_reg;
logic [31:0] laddr_lsb_reg;
logic [31:0] payload_len_reg;
logic [31:0] opcode_reg;
logic [31:0] remote_offset_msb_reg;
logic [31:0] remote_offset_lsb_reg;
logic [31:0] r_key_reg;
logic [31:0] send_small_payload0_reg;
logic [31:0] send_small_payload1_reg;
logic [31:0] send_small_payload2_reg;
logic [31:0] send_small_payload3_reg;
logic [31:0] immdt_data_reg;
logic [31:0] sq_addr_lsb_reg;
logic [31:0] sq_addr_msb_reg;

logic [1:0]  m_axi_to_sys_mem_awlock_tmp;
logic [1:0]  m_axi_to_sys_mem_arlock_tmp;

logic        addr_sqpidbcount_rd_en;
logic [63:0] addr_sqpidbcount_fifo_out;

logic        addr_sqpidbcount_fifo_empty;

logic [2:0]  hndshk_state;
//logic [1:0]  hndshk_next_state;

logic        kernel_idle;
logic        kernel_done;

localparam   IDLE=3'd0;
localparam   CREATE_WQE=3'd1;
localparam   WAIT_FOR_SQPIDB=3'd2;
localparam   WRITE_SQPIDB=3'd3;
localparam   WAIT_CQDB=3'd4;
localparam   WRITE_HW_TIMER = 3'd5;

logic [31:0] local_hw_timer;

control_command_processor #(
  .AXIL_ADDR_WIDTH (AXIL_ADDR_WIDTH),
  .AXIL_DATA_WIDTH (AXIL_DATA_WIDTH)
) ctl_cmd_proc (
  .s_axil_awvalid             (s_axil_hw_hndshk_cmd_awvalid),
  .s_axil_awaddr              (s_axil_hw_hndshk_cmd_awaddr[AXIL_ADDR_WIDTH-1:0]),
  .s_axil_awready             (s_axil_hw_hndshk_cmd_awready),
  .s_axil_wvalid              (s_axil_hw_hndshk_cmd_wvalid ),
  .s_axil_wdata               (s_axil_hw_hndshk_cmd_wdata  ),
  .s_axil_wready              (s_axil_hw_hndshk_cmd_wready ),
  .s_axil_bvalid              (s_axil_hw_hndshk_cmd_bvalid ),
  .s_axil_bresp               (s_axil_hw_hndshk_cmd_bresp  ),
  .s_axil_bready              (s_axil_hw_hndshk_cmd_bready ),
  .s_axil_arvalid             (s_axil_hw_hndshk_cmd_arvalid),
  .s_axil_araddr              (s_axil_hw_hndshk_cmd_araddr[AXIL_ADDR_WIDTH-1:0]),
  .s_axil_arready             (s_axil_hw_hndshk_cmd_arready),
  .s_axil_rvalid              (s_axil_hw_hndshk_cmd_rvalid ),
  .s_axil_rdata               (s_axil_hw_hndshk_cmd_rdata  ),
  .s_axil_rresp               (s_axil_hw_hndshk_cmd_rresp  ),
  .s_axil_rready              (s_axil_hw_hndshk_cmd_rready ),

  .cl_box_idle                (hw_hndshk_idle),
  .cl_box_start               (hw_hndshk_start),
  .cl_box_done                (hw_hndshk_done),
  .cl_kernel_idle             (kernel_idle),
  .cl_kernel_done             (kernel_done),
  .ctl_cmd_fifo_dout          (ctl_cmd_fifo_dout),
  .ctl_cmd_fifo_empty_n       (ctl_cmd_fifo_empty_n),
  .ctl_cmd_fifo_rd_en         (ctl_cmd_fifo_rd_en),
  .rdma_trg_fifo_dout         (qpid_wqecount_dout),
  .rdma_trg_fifo_empty_n      (qpid_wqecount_empty_n),
  .rdma_trg_fifo_rd_en        (qpid_wqecount_read),

  .ker_status_fifo_din        (hw_timer_din),
  .ker_status_fifo_full_n     (hw_timer_full_n),
  .ker_status_fifo_wr_en      (hw_timer_write),

  .axil_aclk                  (axil_aclk),
  .axil_arstn                 (axil_rstn),
  .axis_aclk                  (axis_aclk),
  .axis_arstn                 (axis_rstn)
);

hw_hndshk hw_hndshk_inst (
  .ap_local_block              (),
  .ap_local_deadlock           (),
  .ap_clk                      (axis_aclk),
  .ap_rst                      (~axis_rstn),
  .ap_start                    (hw_hndshk_start),
  .ap_done                     (hw_hndshk_done),
  .ap_idle                     (hw_hndshk_idle),
  .ap_ready                    (hw_hndshk_ready),
  .ctl_cmd_stream_dout         (ctl_cmd_fifo_dout),
  .ctl_cmd_stream_empty_n      (ctl_cmd_fifo_empty_n),
  .ctl_cmd_stream_read         (ctl_cmd_fifo_rd_en),
  .sq_pidb_cnt                 (sq_pidb_cnt),
  .sq_pidb_cnt_ap_vld          (sq_pidb_cnt_ap_vld),
  .cq_db_cnt                   (cq_db_cnt),
  .cq_db_cnt_ap_vld            (cq_db_cnt_ap_vld),
  .sq_pidb_addr                (sq_pidb_addr),
  .sq_pidb_addr_ap_vld         (sq_pidb_addr_ap_vld),
  .wrid                        (wrid),
  .wrid_ap_vld                 (wrid_ap_vld),
  .wqe_count                   (wqe_count),
  .wqe_count_ap_vld            (wqe_count_ap_vld),
  .laddr_msb                   (laddr_msb),
  .laddr_msb_ap_vld            (laddr_msb_ap_vld),
  .laddr_lsb                   (laddr_lsb),
  .laddr_lsb_ap_vld            (laddr_lsb_ap_vld),
  .payload_len                 (payload_len),
  .payload_len_ap_vld          (payload_len_ap_vld),
  .opcode                      (opcode),
  .opcode_ap_vld               (opcode_ap_vld),
  .remote_offset_msb           (remote_offset_msb),
  .remote_offset_msb_ap_vld    (remote_offset_msb_ap_vld),
  .remote_offset_lsb           (remote_offset_lsb),
  .remote_offset_lsb_ap_vld    (remote_offset_lsb_ap_vld),
  .r_key                       (r_key),
  .r_key_ap_vld                (r_key_ap_vld),
  .send_small_payload0         (send_small_payload0),
  .send_small_payload0_ap_vld  (send_small_payload0_ap_vld),
  .send_small_payload1         (send_small_payload1),
  .send_small_payload1_ap_vld  (send_small_payload1_ap_vld),
  .send_small_payload2         (send_small_payload2),
  .send_small_payload2_ap_vld  (send_small_payload2_ap_vld),
  .send_small_payload3         (send_small_payload3),
  .send_small_payload3_ap_vld  (send_small_payload3_ap_vld),
  .immdt_data                  (immdt_data),
  .immdt_data_ap_vld           (immdt_data_ap_vld),
  .sq_addr_lsb                 (sq_addr_lsb),
  .sq_addr_lsb_ap_vld          (sq_addr_lsb_ap_vld),
  .sq_addr_msb                 (sq_addr_msb),
  .sq_addr_msb_ap_vld          (sq_addr_msb_ap_vld)
);

ker_write_wqe ker_write_wqe_inst (
  .ap_local_block                  (),
  .ap_local_deadlock               (),
  .ap_clk                          (axis_aclk),
  .ap_rst_n                        (axis_rstn),
  .ap_start                        (kernel_write_wqe_start),
  .ap_done                         (kernel_write_wqe_done),
  .ap_idle                         (kernel_write_wqe_idle),
  .ap_ready                        (kernel_write_wqe_ready),

  .m_axi_hw_hndshk_sys_mem_AWVALID (m_axi_to_sys_mem_awvalid),
  .m_axi_hw_hndshk_sys_mem_AWREADY (m_axi_to_sys_mem_awready),
  .m_axi_hw_hndshk_sys_mem_AWADDR  (m_axi_to_sys_mem_awaddr),
  .m_axi_hw_hndshk_sys_mem_AWID    (m_axi_to_sys_mem_awid),
  .m_axi_hw_hndshk_sys_mem_AWLEN   (m_axi_to_sys_mem_awlen),
  .m_axi_hw_hndshk_sys_mem_AWSIZE  (m_axi_to_sys_mem_awsize),
  .m_axi_hw_hndshk_sys_mem_AWBURST (m_axi_to_sys_mem_awburst),
  .m_axi_hw_hndshk_sys_mem_AWLOCK  (m_axi_to_sys_mem_awlock_tmp),
  .m_axi_hw_hndshk_sys_mem_AWCACHE (m_axi_to_sys_mem_awcache),
  .m_axi_hw_hndshk_sys_mem_AWPROT  (m_axi_to_sys_mem_awprot),
  .m_axi_hw_hndshk_sys_mem_AWQOS   (m_axi_to_sys_mem_awqos),
  .m_axi_hw_hndshk_sys_mem_AWREGION(),
  .m_axi_hw_hndshk_sys_mem_AWUSER  (),
  .m_axi_hw_hndshk_sys_mem_WVALID  (m_axi_to_sys_mem_wvalid),
  .m_axi_hw_hndshk_sys_mem_WREADY  (m_axi_to_sys_mem_wready),
  .m_axi_hw_hndshk_sys_mem_WDATA   (m_axi_to_sys_mem_wdata),
  .m_axi_hw_hndshk_sys_mem_WSTRB   (m_axi_to_sys_mem_wstrb),
  .m_axi_hw_hndshk_sys_mem_WLAST   (m_axi_to_sys_mem_wlast),
  .m_axi_hw_hndshk_sys_mem_WID     (),
  .m_axi_hw_hndshk_sys_mem_WUSER   (),
  .m_axi_hw_hndshk_sys_mem_ARVALID (m_axi_to_sys_mem_arvalid),
  .m_axi_hw_hndshk_sys_mem_ARREADY (m_axi_to_sys_mem_arready),
  .m_axi_hw_hndshk_sys_mem_ARADDR  (m_axi_to_sys_mem_araddr),
  .m_axi_hw_hndshk_sys_mem_ARID    (m_axi_to_sys_mem_arid),
  .m_axi_hw_hndshk_sys_mem_ARLEN   (m_axi_to_sys_mem_arlen),
  .m_axi_hw_hndshk_sys_mem_ARSIZE  (m_axi_to_sys_mem_arsize),
  .m_axi_hw_hndshk_sys_mem_ARBURST (m_axi_to_sys_mem_arburst),
  .m_axi_hw_hndshk_sys_mem_ARLOCK  (m_axi_to_sys_mem_arlock_tmp),
  .m_axi_hw_hndshk_sys_mem_ARCACHE (m_axi_to_sys_mem_arcache),
  .m_axi_hw_hndshk_sys_mem_ARPROT  (m_axi_to_sys_mem_arprot),
  .m_axi_hw_hndshk_sys_mem_ARQOS   (m_axi_to_sys_mem_arqos),
  .m_axi_hw_hndshk_sys_mem_ARREGION(),
  .m_axi_hw_hndshk_sys_mem_ARUSER  (),
  .m_axi_hw_hndshk_sys_mem_RVALID  (m_axi_to_sys_mem_rvalid),
  .m_axi_hw_hndshk_sys_mem_RREADY  (m_axi_to_sys_mem_rready),
  .m_axi_hw_hndshk_sys_mem_RDATA   (m_axi_to_sys_mem_rdata),
  .m_axi_hw_hndshk_sys_mem_RLAST   (m_axi_to_sys_mem_rlast),
  .m_axi_hw_hndshk_sys_mem_RID     (m_axi_to_sys_mem_rid),
  .m_axi_hw_hndshk_sys_mem_RUSER   (),
  .m_axi_hw_hndshk_sys_mem_RRESP   (m_axi_to_sys_mem_rresp),
  .m_axi_hw_hndshk_sys_mem_BVALID  (m_axi_to_sys_mem_bvalid),
  .m_axi_hw_hndshk_sys_mem_BREADY  (m_axi_to_sys_mem_bready),
  .m_axi_hw_hndshk_sys_mem_BRESP   (m_axi_to_sys_mem_bresp),
  .m_axi_hw_hndshk_sys_mem_BID     (m_axi_to_sys_mem_bid),
  .m_axi_hw_hndshk_sys_mem_BUSER   (),

  .wrid                            (wrid_reg),
  .wqe_count                       (wqe_count_reg),
  .laddr_msb                       (laddr_msb_reg),
  .laddr_lsb                       (laddr_lsb_reg),
  .payload_len                     (payload_len_reg),
  .opcode                          (opcode_reg),
  .remote_offset_msb               (remote_offset_msb_reg),
  .remote_offset_lsb               (remote_offset_lsb_reg),
  .r_key                           (r_key_reg),
  .send_small_payload0             (send_small_payload0_reg),
  .send_small_payload1             (send_small_payload1_reg),
  .send_small_payload2             (send_small_payload2_reg),
  .send_small_payload3             (send_small_payload3_reg),
  .immdt_data                      (immdt_data_reg),
  .sq_addr_sys_mem                 ({sq_addr_msb_reg,sq_addr_lsb_reg})
);

ker_write_sqpidb ker_write_sqpidb_inst (
  .ap_local_block             (),
  .ap_local_deadlock          (),
  .ap_clk                     (axis_aclk),
  .ap_rst                     (~axis_rstn),
  .ap_start                   (kernel_write_sqpidb_start),
  .ap_done                    (kernel_write_sqpidb_done),
  .ap_idle                    (kernel_write_sqpidb_idle),
  .ap_ready                   (kernel_write_sqpidb_ready),

  .qpid_wqecount_dout         (qpid_wqecount_dout),
  .qpid_wqecount_empty_n      (qpid_wqecount_empty_n),
  .qpid_wqecount_read         (qpid_wqecount_read),

  .addr_sqpidbcount_din       (addr_sqpidbcount_din),
  .addr_sqpidbcount_full_n    (~addr_sqpidbcount_full_n),
  .addr_sqpidbcount_write     (addr_sqpidbcount_write),
  .sq_pidb_cnt                (sq_pidb_cnt_reg),
  .sq_pidb_addr               (sq_pidb_addr_reg),
  .wqe_count                  (wqe_count_reg),
  .global_hw_timer            (global_hw_timer),
  .hw_start_timer             (hw_start_timer),
  .hw_start_timer_ap_vld      (hw_start_timer_ap_vld),
  .qpid                       (qpid),
  .qpid_ap_vld                (qpid_ap_vld)
);

ker_wait_on_cqdb ker_wait_on_cqdb_inst (
  .ap_local_block             (),
  .ap_local_deadlock          (),
  .ap_clk                     (axis_aclk),
  .ap_rst                     (~axis_rstn),
  .ap_start                   (kernel_wait_on_cqdb_start),
  .ap_done                    (kernel_wait_on_cqdb_done),
  .ap_idle                    (kernel_wait_on_cqdb_idle),
  .ap_ready                   (kernel_wait_on_cqdb_ready),
  .cq_db_cnt                  (cq_db_cnt_reg),
  .addr_cqdbcount_dout        (addr_cqdbcount_dout),
  .addr_cqdbcount_empty_n     (~addr_cqdbcount_empty_n),
  .addr_cqdbcount_read        (addr_cqdbcount_read),
  .wqecount                   (wqe_count_reg)
);

xpm_fifo_sync #(
  .DOUT_RESET_VALUE    ("0"),
  .ECC_MODE            ("no_ecc"),
  .FIFO_MEMORY_TYPE    ("auto"),
  .FIFO_READ_LATENCY   (0),
  .FIFO_WRITE_DEPTH    (32),
  .PROG_FULL_THRESH    (32-5),
  .READ_DATA_WIDTH     (64),
  .READ_MODE           ("std"),
  .WRITE_DATA_WIDTH    (64)
) addr_sqpidbcount_fifo (
  .wr_en         (addr_sqpidbcount_write),
  .din           (addr_sqpidbcount_din),
  .wr_ack        (),
  .rd_en         (addr_sqpidbcount_rd_en),
  .data_valid    (),
  .dout          (addr_sqpidbcount_fifo_out),

  .wr_data_count (),
  .rd_data_count (),

  .empty         (addr_sqpidbcount_fifo_empty),
  .full          (addr_sqpidbcount_full_n),
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

xpm_fifo_sync #(
  .DOUT_RESET_VALUE    ("0"),
  .ECC_MODE            ("no_ecc"),
  .FIFO_MEMORY_TYPE    ("auto"),
  .FIFO_READ_LATENCY   (0),
  .FIFO_WRITE_DEPTH    (32),
  .PROG_FULL_THRESH    (32-5),
  .READ_DATA_WIDTH     (64),
  .READ_MODE           ("std"),
  .WRITE_DATA_WIDTH    (64)
) addr_cqdbcount_fifo (
  .wr_en         (s_resp_hndler_i_send_cq_db_cnt_valid),
  .din           ({22'd0,s_resp_hndler_i_send_cq_db_addr,s_resp_hndler_i_send_cq_db_cnt}),
  .wr_ack        (),
  .rd_en         (addr_cqdbcount_read),
  .data_valid    (),
  .dout          (addr_cqdbcount_dout),

  .wr_data_count (),
  .rd_data_count (),

  .empty         (addr_cqdbcount_empty_n),
  .full          (),
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

always_ff @(posedge axis_aclk) begin
  if(!axis_rstn) begin
    sq_pidb_cnt_reg <= 32'd0;
    cq_db_cnt_reg <= 32'd0;
    sq_pidb_addr_reg <= 32'd0;
  end
  else begin

    sq_pidb_cnt_reg     <= sq_pidb_cnt_ap_vld ? sq_pidb_cnt : sq_pidb_cnt_reg;
    cq_db_cnt_reg     <= cq_db_cnt_ap_vld ? cq_db_cnt : cq_db_cnt_reg;
    sq_pidb_addr_reg     <= sq_pidb_addr_ap_vld ? sq_pidb_addr : sq_pidb_addr_reg;
    wqe_count_reg     <= wqe_count_ap_vld ? wqe_count : wqe_count_reg;
    hw_start_timer_reg <= hw_start_timer_ap_vld ? hw_start_timer : hw_start_timer_reg;
    qpid_reg <= qpid_ap_vld ? qpid : qpid_reg;
    wrid_reg <= wrid_ap_vld ? wrid : wrid_reg;
    laddr_msb_reg <= laddr_msb_ap_vld ? laddr_msb : laddr_msb_reg;
    laddr_lsb_reg <= laddr_lsb_ap_vld ? laddr_lsb : laddr_lsb_reg;
    payload_len_reg <= payload_len_ap_vld ? payload_len : payload_len_reg;
    opcode_reg <= opcode_ap_vld ? opcode : opcode_reg;
    remote_offset_msb_reg <= remote_offset_msb_ap_vld ? remote_offset_msb : remote_offset_msb_reg;
    remote_offset_lsb_reg <= remote_offset_lsb_ap_vld ? remote_offset_lsb : remote_offset_lsb_reg;
    r_key_reg <= r_key_ap_vld ? r_key : r_key_reg;
    send_small_payload0_reg <= send_small_payload0_ap_vld ? send_small_payload0 : send_small_payload0_reg;
    send_small_payload1_reg <= send_small_payload1_ap_vld ? send_small_payload1 : send_small_payload1_reg;
    send_small_payload2_reg <= send_small_payload2_ap_vld ? send_small_payload2 : send_small_payload2_reg;
    send_small_payload3_reg <= send_small_payload3_ap_vld ? send_small_payload3 : send_small_payload3_reg;
    immdt_data_reg <= immdt_data_ap_vld ? immdt_data : immdt_data_reg;
    sq_addr_lsb_reg <= sq_addr_lsb_ap_vld ? sq_addr_lsb : sq_addr_lsb_reg;
    sq_addr_msb_reg <= sq_addr_msb_ap_vld ? sq_addr_msb : sq_addr_msb_reg;

  end
end

assign kernel_idle = kernel_wait_on_cqdb_idle & kernel_write_wqe_idle & kernel_write_sqpidb_idle;
assign kernel_done = kernel_wait_on_cqdb_done;

assign s_resp_hndler_o_send_cq_db_rdy = (s_resp_hndler_i_send_cq_db_cnt_valid && (s_resp_hndler_i_send_cq_db_cnt <= wqe_count_reg)) ? 1'b1 : 1'b0;
always_ff @(posedge axis_aclk)
begin
  if(!axis_rstn) begin
    m_o_qp_sq_pidb_hndshk <= 16'd0;
    m_o_qp_sq_pidb_wr_addr_hndshk <= 32'd0;
    m_o_qp_sq_pidb_wr_valid_hndshk <= 0;
    addr_sqpidbcount_rd_en <= 0;
    kernel_wait_on_cqdb_start <= 0;
    kernel_write_wqe_start <= 0;
    kernel_write_sqpidb_start <= 0;
    hndshk_state <= IDLE;
  end
  else
  begin   
    case(hndshk_state)
        IDLE: begin
          hw_timer_write <= 0;
          if(hw_hndshk_done)
            hndshk_state <= CREATE_WQE;
          else
            hndshk_state <= IDLE;
        end

        CREATE_WQE: begin
          kernel_write_wqe_start <= 1;
          if(kernel_write_wqe_done)
          begin
              hndshk_state <= WAIT_FOR_SQPIDB;
              kernel_write_wqe_start <= 0;
              kernel_write_sqpidb_start <= 1;
          end
            else
              hndshk_state <= CREATE_WQE;
        end

        WAIT_FOR_SQPIDB:begin
          if(!addr_sqpidbcount_fifo_empty)
          begin
              addr_sqpidbcount_rd_en <= 1;
              hndshk_state <= WRITE_SQPIDB;
          end
          else
          begin
              addr_sqpidbcount_rd_en <= 0;
              hndshk_state <= WAIT_FOR_SQPIDB;
          end
        end

        WRITE_SQPIDB:begin
          m_o_qp_sq_pidb_hndshk <= addr_sqpidbcount_fifo_out & 64'h000000000000ffff;
          m_o_qp_sq_pidb_wr_addr_hndshk <= (addr_sqpidbcount_fifo_out >> 16) & 64'h00000000ffffffff;
          m_o_qp_sq_pidb_wr_valid_hndshk <= 1;
          if(kernel_write_sqpidb_done)
            kernel_write_sqpidb_start <= 0;
          if(m_i_qp_sq_pidb_wr_rdy)
          begin
            m_o_qp_sq_pidb_wr_valid_hndshk <= 0;
            kernel_write_sqpidb_start <= 0;
            hndshk_state <= WAIT_CQDB;
          end
          else
            hndshk_state <= WRITE_SQPIDB;
        end

        WAIT_CQDB:begin
          kernel_wait_on_cqdb_start <= 1;
          addr_sqpidbcount_rd_en <= 0;
          if(kernel_wait_on_cqdb_done)
          begin
            kernel_wait_on_cqdb_start <= 0;
            local_hw_timer <= global_hw_timer - hw_start_timer_reg;
            hw_timer_din <= qpid_reg;
            hndshk_state <= WRITE_HW_TIMER;
            end
          else
            hndshk_state <= WAIT_CQDB;
        end

        WRITE_HW_TIMER: begin
          if(hw_timer_full_n)
            begin
              hw_timer_din <= (hw_timer_din << 24) | (local_hw_timer & 32'h00ffffff);
              hw_timer_write <= 1;
              $display("INFO: [hw_hndshk_wrapper] Number of clock cycles required to perform RDMA operation are %d", local_hw_timer);
              hndshk_state <= IDLE;
            end
          else
            hndshk_state <= WRITE_HW_TIMER;
        end
    endcase
  end
end

assign m_axi_to_sys_mem_awlock = m_axi_to_sys_mem_awlock_tmp[0];
assign m_axi_to_sys_mem_arlock = m_axi_to_sys_mem_arlock_tmp[0];

endmodule: hw_hndshk_wrapper