//==============================================================================
// Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
// SPDX-License-Identifier: MIT
//
//==============================================================================
`timescale 1ns/1ps

module compute_logic_wrapper # (
  parameter AXIL_ADDR_WIDTH  = 12,
  parameter AXIL_DATA_WIDTH  = 32,
  parameter AXIS_DATA_WIDTH  = 512,
  parameter AXIS_KEEP_WIDTH  = 64
) (
  // register control interface
  input         s_axil_awvalid,
  input  [31:0] s_axil_awaddr,
  output        s_axil_awready,
  input         s_axil_wvalid,
  input  [31:0] s_axil_wdata,
  output        s_axil_wready,
  output        s_axil_bvalid,
  output  [1:0] s_axil_bresp,
  input         s_axil_bready,
  input         s_axil_arvalid,
  input  [31:0] s_axil_araddr,
  output        s_axil_arready,
  output        s_axil_rvalid,
  output [31:0] s_axil_rdata,
  output  [1:0] s_axil_rresp,
  input         s_axil_rready,
  
  // master AXI interface for device memory access
  output            m_axi_awid,
  output   [63 : 0] m_axi_awaddr,
  output    [3 : 0] m_axi_awqos,
  output    [7 : 0] m_axi_awlen,
  output    [2 : 0] m_axi_awsize,
  output    [1 : 0] m_axi_awburst,
  output    [3 : 0] m_axi_awcache,
  output    [2 : 0] m_axi_awprot,
  output            m_axi_awvalid,
  input             m_axi_awready,
  output  [511 : 0] m_axi_wdata,
  output   [63 : 0] m_axi_wstrb,
  output            m_axi_wlast,
  output            m_axi_wvalid,
  input             m_axi_wready,
  output            m_axi_awlock,
  input             m_axi_bid,
  input     [1 : 0] m_axi_bresp,
  input             m_axi_bvalid,
  output            m_axi_bready,
  output            m_axi_arid,
  output   [63 : 0] m_axi_araddr,
  output    [7 : 0] m_axi_arlen,
  output    [2 : 0] m_axi_arsize,
  output    [1 : 0] m_axi_arburst,
  output    [3 : 0] m_axi_arcache,
  output    [2 : 0] m_axi_arprot,
  output            m_axi_arvalid,
  input             m_axi_arready,
  input             m_axi_rid,
  input   [511 : 0] m_axi_rdata,
  input     [1 : 0] m_axi_rresp,
  input             m_axi_rlast,
  input             m_axi_rvalid,
  output            m_axi_rready,
  output            m_axi_arlock,
  output     [3:0]  m_axi_arqos,

  input          axil_aclk,
  input          axil_rstn,
  input          axis_aclk,
  input          axis_rstn
);

logic [1:0] m_axi_awlock_tmp;
logic [1:0] m_axi_arlock_tmp;

logic [31:0] ctl_cmd_fifo_dout;
logic        ctl_cmd_fifo_empty_n;
logic        ctl_cmd_fifo_rd_en;

logic [31:0] ker_status_fifo_din;
logic        ker_status_fifo_full_n;
logic        ker_status_fifo_wr_en;

logic cl_box_start;
logic cl_box_done;
logic cl_box_idle;
logic cl_box_ready;

logic [31:0] a_baseaddr;
logic        a_baseaddr_ap_vld;
logic [31:0] b_baseaddr;
logic        b_baseaddr_ap_vld;
logic [31:0] c_baseaddr;
logic        c_baseaddr_ap_vld;
logic [31:0] a_row;
logic        a_row_ap_vld;
logic [31:0] a_col;
logic        a_col_ap_vld;
logic [31:0] b_col;
logic        b_col_ap_vld;
logic [31:0] work_id;
logic        work_id_ap_vld;

logic ap_start;
logic ap_done;
logic ap_idle;
logic ap_ready;

logic [63:0] a_baseaddr_reg;
logic [63:0] b_baseaddr_reg;
logic [63:0] c_baseaddr_reg;
logic [31:0] a_row_reg;
logic [31:0] a_col_reg;
logic [31:0] b_col_reg;
logic [31:0] work_id_reg;

localparam COMPUTE_IDLE = 1'b0;
localparam COMPUTE_BUSY = 1'b1;

logic comp_state;
logic new_req;
logic new_req_reg;

// control command processor
control_command_processor #(
  .AXIL_ADDR_WIDTH (AXIL_ADDR_WIDTH),
  .AXIL_DATA_WIDTH (AXIL_DATA_WIDTH)
) ctl_cmd_proc (
  .s_axil_awvalid(s_axil_awvalid),
  .s_axil_awaddr (s_axil_awaddr[AXIL_ADDR_WIDTH-1:0]),
  .s_axil_awready(s_axil_awready),
  .s_axil_wvalid (s_axil_wvalid ),
  .s_axil_wdata  (s_axil_wdata  ),
  .s_axil_wready (s_axil_wready ),
  .s_axil_bvalid (s_axil_bvalid ),
  .s_axil_bresp  (s_axil_bresp  ),
  .s_axil_bready (s_axil_bready ),
  .s_axil_arvalid(s_axil_arvalid),
  .s_axil_araddr (s_axil_araddr[AXIL_ADDR_WIDTH-1:0]),
  .s_axil_arready(s_axil_arready),
  .s_axil_rvalid (s_axil_rvalid ),
  .s_axil_rdata  (s_axil_rdata  ),
  .s_axil_rresp  (s_axil_rresp  ),
  .s_axil_rready (s_axil_rready ),

  .cl_box_idle         (cl_box_idle),
  .cl_box_start        (cl_box_start),
  .cl_box_done         (cl_box_done),
  .cl_kernel_idle      (ap_idle),
  .cl_kernel_done      (ap_done),
  .ctl_cmd_fifo_dout   (ctl_cmd_fifo_dout),
  .ctl_cmd_fifo_empty_n(ctl_cmd_fifo_empty_n),
  .ctl_cmd_fifo_rd_en  (ctl_cmd_fifo_rd_en),

  .ker_status_fifo_din   (ker_status_fifo_din),
  .ker_status_fifo_full_n(ker_status_fifo_full_n),
  .ker_status_fifo_wr_en (ker_status_fifo_wr_en),

  .axil_aclk (axil_aclk),
  .axil_arstn(axil_rstn),
  .axis_aclk (axis_aclk),
  .axis_arstn(axis_rstn)
);

// Compute_Logic box
cl_box cl_box_wrapper (
  .ap_local_block              (),
  .ap_local_deadlock           (),
  .ap_clk                      (axis_aclk),
  .ap_rst                      (~axis_rstn),
  .ap_start                    (cl_box_start),
  .ap_done                     (cl_box_done),
  .ap_idle                     (cl_box_idle),
  .ap_ready                    (cl_box_ready),
  .ctl_cmd_stream_dout         (ctl_cmd_fifo_dout),
  .ctl_cmd_stream_empty_n      (ctl_cmd_fifo_empty_n),
  .ctl_cmd_stream_read         (ctl_cmd_fifo_rd_en),
  .a_baseaddr                  (a_baseaddr),
  .a_baseaddr_ap_vld           (a_baseaddr_ap_vld),
  .b_baseaddr                  (b_baseaddr),
  .b_baseaddr_ap_vld           (b_baseaddr_ap_vld),
  .c_baseaddr                  (c_baseaddr),
  .c_baseaddr_ap_vld           (c_baseaddr_ap_vld),
  .a_row                       (a_row),
  .a_row_ap_vld                (a_row_ap_vld),
  .a_col                       (a_col),
  .a_col_ap_vld                (a_col_ap_vld),
  .b_col                       (b_col),
  .b_col_ap_vld                (b_col_ap_vld),
  .work_id                     (work_id),
  .work_id_ap_vld              (work_id_ap_vld)
);

mmult kernel_mmult (
  .ap_local_block   (),
  .ap_local_deadlock(),
  .ap_clk           (axis_aclk),
  .ap_rst_n         (axis_rstn),
  .ap_start         (ap_start),
  .ap_done          (ap_done),
  .ap_idle          (ap_idle),
  .ap_ready         (ap_ready),
  .m_axi_systolic_AWVALID (m_axi_awvalid),
  .m_axi_systolic_AWREADY (m_axi_awready),
  .m_axi_systolic_AWADDR  (m_axi_awaddr),
  .m_axi_systolic_AWID    (m_axi_awid),
  .m_axi_systolic_AWLEN   (m_axi_awlen),
  .m_axi_systolic_AWSIZE  (m_axi_awsize),
  .m_axi_systolic_AWBURST (m_axi_awburst),
  .m_axi_systolic_AWLOCK  (m_axi_awlock_tmp),
  .m_axi_systolic_AWCACHE (m_axi_awcache),
  .m_axi_systolic_AWPROT  (m_axi_awprot),
  .m_axi_systolic_AWQOS   (m_axi_awqos),
  .m_axi_systolic_AWREGION(),
  .m_axi_systolic_AWUSER  (),
  .m_axi_systolic_WVALID  (m_axi_wvalid),
  .m_axi_systolic_WREADY  (m_axi_wready),
  .m_axi_systolic_WDATA   (m_axi_wdata),
  .m_axi_systolic_WSTRB   (m_axi_wstrb),
  .m_axi_systolic_WLAST   (m_axi_wlast),
  .m_axi_systolic_WID     (),
  .m_axi_systolic_WUSER   (),
  .m_axi_systolic_ARVALID (m_axi_arvalid),
  .m_axi_systolic_ARREADY (m_axi_arready),
  .m_axi_systolic_ARADDR  (m_axi_araddr),
  .m_axi_systolic_ARID    (m_axi_arid),
  .m_axi_systolic_ARLEN   (m_axi_arlen),
  .m_axi_systolic_ARSIZE  (m_axi_arsize),
  .m_axi_systolic_ARBURST (m_axi_arburst),
  .m_axi_systolic_ARLOCK  (m_axi_arlock_tmp),
  .m_axi_systolic_ARCACHE (m_axi_arcache),
  .m_axi_systolic_ARPROT  (m_axi_arprot),
  .m_axi_systolic_ARQOS   (m_axi_arqos),
  .m_axi_systolic_ARREGION(),
  .m_axi_systolic_ARUSER  (),
  .m_axi_systolic_RVALID  (m_axi_rvalid),
  .m_axi_systolic_RREADY  (m_axi_rready),
  .m_axi_systolic_RDATA   (m_axi_rdata),
  .m_axi_systolic_RLAST   (m_axi_rlast),
  .m_axi_systolic_RID     (m_axi_rid),
  .m_axi_systolic_RUSER   (),
  .m_axi_systolic_RRESP   (m_axi_rresp),
  .m_axi_systolic_BVALID  (m_axi_bvalid),
  .m_axi_systolic_BREADY  (m_axi_bready),
  .m_axi_systolic_BRESP   (m_axi_bresp),
  .m_axi_systolic_BID     (m_axi_bid),
  .m_axi_systolic_BUSER   (),
  .work_id_out_stream_din   (ker_status_fifo_din),
  .work_id_out_stream_full_n(ker_status_fifo_full_n),
  .work_id_out_stream_write (ker_status_fifo_wr_en),
  .a             (a_baseaddr_reg),
  .b             (b_baseaddr_reg),
  .c             (c_baseaddr_reg),
  .a_row         (a_row_reg),
  .a_row_ap_vld  (new_req_reg),
  .a_col         (a_col_reg),
  .a_col_ap_vld  (new_req_reg),
  .b_col         (b_col_reg),
  .b_col_ap_vld  (new_req_reg),
  .work_id       (work_id_reg),
  .work_id_ap_vld(new_req_reg)
);

assign new_req = cl_box_done;

always_ff @(posedge axis_aclk) begin
  if(!axis_rstn) begin
    a_baseaddr_reg <= 64'd0;
    b_baseaddr_reg <= 64'd0;
    c_baseaddr_reg <= 64'd0;
    a_row_reg      <= 32'd0;
    a_col_reg      <= 32'd0;
    b_col_reg      <= 32'd0;
    work_id_reg    <= 32'd0;

    ap_start    <= 1'b0;
    new_req_reg <= 1'b0;
    comp_state  <= COMPUTE_IDLE;
  end
  else begin
    ap_start <= 1'b0;
    a_baseaddr_reg <= a_baseaddr_ap_vld ? {32'd0, a_baseaddr} : a_baseaddr_reg;
    b_baseaddr_reg <= b_baseaddr_ap_vld ? {32'd0, b_baseaddr} : b_baseaddr_reg;
    c_baseaddr_reg <= c_baseaddr_ap_vld ? {32'd0, c_baseaddr} : c_baseaddr_reg;

    a_row_reg     <= a_row_ap_vld ? a_row : a_row_reg;
    a_col_reg     <= a_col_ap_vld ? a_col : a_col_reg;
    b_col_reg     <= b_col_ap_vld ? b_col : b_col_reg;

    work_id_reg   <= work_id_ap_vld ? work_id : work_id_reg;

    new_req_reg <= new_req;

    case(comp_state)
    COMPUTE_IDLE: begin
      if(ap_idle) begin
        if(new_req) begin
          ap_start <= 1'b1;
          comp_state <= COMPUTE_BUSY;
        end
        else begin
          comp_state <= COMPUTE_IDLE;
        end
      end
    end
    COMPUTE_BUSY: begin
      ap_start   <= ap_ready ? 1'b0 : 1'b1;
      comp_state <= ap_done ? COMPUTE_IDLE : COMPUTE_BUSY;
    end
    endcase
  end
end

assign m_axi_awlock = m_axi_awlock_tmp[0];
assign m_axi_arlock = m_axi_arlock_tmp[0];

endmodule: compute_logic_wrapper
