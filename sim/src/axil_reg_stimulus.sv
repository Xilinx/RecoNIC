//==============================================================================
// Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
// SPDX-License-Identifier: MIT
//
//==============================================================================
`timescale 1ns/1ps

module axil_reg_stimulus #(
  parameter AXIL_ADDR_WIDTH = 12,
  parameter AXIL_DATA_WIDTH = 32
) (
  input string      table_config_filename,
  output reg        m_axil_reg_awvalid,
  output reg [31:0] m_axil_reg_awaddr,
  input             m_axil_reg_awready,
  output reg        m_axil_reg_wvalid,
  output reg [31:0] m_axil_reg_wdata,
  input             m_axil_reg_wready,
  input             m_axil_reg_bvalid,
  input       [1:0] m_axil_reg_bresp,
  output reg        m_axil_reg_bready,
  output            m_axil_reg_arvalid,
  output     [31:0] m_axil_reg_araddr,
  input             m_axil_reg_arready,
  input             m_axil_reg_rvalid,
  input      [31:0] m_axil_reg_rdata,
  input       [1:0] m_axil_reg_rresp,
  output            m_axil_reg_rready,

  input         axil_clk,
  input         axil_rstn
);

localparam USER_RESET            = 14'h2100;
localparam CONFIG_SFA            = 14'h2104;
localparam CONFIG_OP_PKT_IDX_EXT = 14'h2108;
localparam CONFIG_START_ADDR     = 14'h210c;

localparam AXIL_WRITE_IDLE                  = 4'b0000;
localparam AXIL_WRITE_SFA                   = 4'b0001;
localparam AXIL_WRITE_SFA_WREADY            = 4'b0011;
localparam AXIL_WRITE_SFA_RESP              = 4'b0010;
localparam AXIL_WRITE_OP_PKT_IDX_EXT        = 4'b0110;
localparam AXIL_WRITE_OP_PKT_IDX_EXT_WREADY = 4'b0111;
localparam AXIL_WRITE_OP_PKT_IDX_EXT_RESP   = 4'b0101;
localparam AXIL_WRITE_START_ADDR            = 4'b0100;
localparam AXIL_WRITE_START_ADDR_WREADY     = 4'b1100;
localparam AXIL_WRITE_START_ADDR_RESP       = 4'b1101;

logic [3:0] wr_state, wr_nextstate;

// Configure the table in Packet Classification
logic [31:0] rn_table_conf;

logic eof_table_config;
logic [31:0] sfa;
logic [1 :0] pktid_ext;
logic [4 :0] idx_ext;
logic [31:0] start_addr;
logic [7 :0] config_op;
logic        config_vld;
logic [31:0] op_pkt_idx_ext;

logic show_msg;

always_ff @(posedge axil_rstn)
begin
  rn_table_conf <= $fopen($sformatf("%s.txt", table_config_filename), "r");
end

always_ff @(posedge axil_clk)
begin
  if (!axil_rstn) begin
    sfa        <= 0;
    pktid_ext  <= 0;
    idx_ext    <= 0;
    start_addr <= 0;
    config_op  <= 0;
    config_vld <= 1'b0;

    eof_table_config <= 1'b0;

    show_msg <= 1'b1;
  end
  else begin
    if(rn_table_conf) begin
      if(!eof_table_config) begin
        if (!config_vld) begin
          if (32'h5 != $fscanf(rn_table_conf, "%x %x %x %x %x", sfa, pktid_ext, idx_ext, start_addr, config_op)) begin
            $display("INFO: [axil_reg_stimulus] time=%t, Finished reading %s file", $time, $sformatf("%s.txt", table_config_filename));
            sfa        <= 0;
            pktid_ext  <= 0;
            idx_ext    <= 0;
            start_addr <= 0;
            config_op  <= 0;
            config_vld <= 1'b0;

            eof_table_config <= 1'b1;
          end
          else begin
            config_vld <= 1'b1;
          end
        end
      end
      if((wr_state == AXIL_WRITE_START_ADDR_RESP) && m_axil_reg_bvalid) begin
        config_vld <= 1'b0;
      end      
    end
    else begin
      if(show_msg) begin
        $display("INFO: [axil_reg_stimulus], time=%t, no %s file to configure table", $time, $sformatf("%s.txt", table_config_filename));
        show_msg <= 1'b0;
      end
    end
  end
end

assign m_axil_reg_arvalid = 1'b0;
assign m_axil_reg_araddr  = 0;
assign m_axil_reg_rready  = 1'b0;

assign op_pkt_idx_ext = config_vld ? {17'd0, config_op, pktid_ext, idx_ext} : 0;

always_comb
begin
  m_axil_reg_awvalid = 1'b0;
  m_axil_reg_awaddr  = 0;
  m_axil_reg_wvalid  = 1'b0;
  m_axil_reg_wdata   = 0;
  m_axil_reg_bready  = 1'b0;

  wr_nextstate = wr_state;
  case(wr_state)
  AXIL_WRITE_IDLE: begin
    if(config_vld) begin
      wr_nextstate = AXIL_WRITE_SFA;
    end
    else begin
      wr_nextstate = AXIL_WRITE_IDLE;
    end
  end
  AXIL_WRITE_SFA: begin
    wr_nextstate = AXIL_WRITE_SFA;
    m_axil_reg_awvalid = 1'b1;
    m_axil_reg_awaddr  = {18'd0, CONFIG_SFA};
    if (m_axil_reg_awready && !m_axil_reg_wready) begin
      wr_nextstate = AXIL_WRITE_SFA_WREADY;
    end

    if (m_axil_reg_awready && m_axil_reg_wready) begin
      m_axil_reg_wvalid = 1'b1;
      m_axil_reg_wdata  = sfa;
      wr_nextstate = AXIL_WRITE_SFA_RESP;
    end
  end
  AXIL_WRITE_SFA_WREADY: begin
    if (m_axil_reg_wready) begin
      m_axil_reg_wvalid = 1'b1;
      m_axil_reg_wdata  = sfa;
      wr_nextstate = AXIL_WRITE_SFA_RESP;
    end
  end
  AXIL_WRITE_SFA_RESP: begin
    if (m_axil_reg_bvalid) begin
      m_axil_reg_bready = 1'b1;
      wr_nextstate = AXIL_WRITE_OP_PKT_IDX_EXT;
    end
    else begin
      wr_nextstate = AXIL_WRITE_SFA_RESP;
    end
  end
  AXIL_WRITE_OP_PKT_IDX_EXT: begin
    wr_nextstate = AXIL_WRITE_OP_PKT_IDX_EXT;
    m_axil_reg_awvalid = 1'b1;
    m_axil_reg_awaddr  = {18'd0, CONFIG_OP_PKT_IDX_EXT};
    
    if (m_axil_reg_awready && !m_axil_reg_wready) begin
      wr_nextstate = AXIL_WRITE_OP_PKT_IDX_EXT_WREADY;
    end

    if (m_axil_reg_awready && m_axil_reg_wready) begin
      m_axil_reg_wvalid = 1'b1;
      m_axil_reg_wdata  = op_pkt_idx_ext;
      wr_nextstate = AXIL_WRITE_OP_PKT_IDX_EXT_RESP;
    end
  end
  AXIL_WRITE_OP_PKT_IDX_EXT_WREADY: begin
    if (m_axil_reg_wready) begin
      m_axil_reg_wvalid = 1'b1;
      m_axil_reg_wdata  = op_pkt_idx_ext;
      wr_nextstate = AXIL_WRITE_OP_PKT_IDX_EXT_RESP;
    end
  end
  AXIL_WRITE_OP_PKT_IDX_EXT_RESP: begin
    if (m_axil_reg_bvalid) begin
      m_axil_reg_bready = 1'b1;
      wr_nextstate = AXIL_WRITE_START_ADDR;
    end
    else begin
      wr_nextstate = AXIL_WRITE_OP_PKT_IDX_EXT_RESP;
    end
  end
  AXIL_WRITE_START_ADDR: begin
    wr_nextstate = AXIL_WRITE_START_ADDR;
    m_axil_reg_awvalid = 1'b1;
    m_axil_reg_awaddr  = {18'd0, CONFIG_START_ADDR};
    
    if (m_axil_reg_awready && !m_axil_reg_wready) begin
      wr_nextstate = AXIL_WRITE_START_ADDR_WREADY;
    end

    if (m_axil_reg_awready && m_axil_reg_wready) begin
      m_axil_reg_wvalid = 1'b1;
      m_axil_reg_wdata  = start_addr;
      wr_nextstate = AXIL_WRITE_START_ADDR_RESP;
    end
  end
  AXIL_WRITE_START_ADDR_WREADY: begin
    if (m_axil_reg_wready) begin
      m_axil_reg_wvalid = 1'b1;
      m_axil_reg_wdata  = start_addr;
      wr_nextstate = AXIL_WRITE_START_ADDR_RESP;
    end
  end
  AXIL_WRITE_START_ADDR_RESP: begin
    if (m_axil_reg_bvalid) begin
      m_axil_reg_bready = 1'b1;
      wr_nextstate = AXIL_WRITE_IDLE;
    end
    else begin
      wr_nextstate = AXIL_WRITE_START_ADDR_RESP;
    end
  end
  default: wr_nextstate = AXIL_WRITE_IDLE;
  endcase
end

always_ff @(posedge axil_clk)
begin
  if (!axil_rstn) begin
    wr_state <= AXIL_WRITE_IDLE;
  end
  else begin
    wr_state <= wr_nextstate;
  end
end

endmodule: axil_reg_stimulus