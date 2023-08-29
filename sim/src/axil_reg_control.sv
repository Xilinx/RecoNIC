//==============================================================================
// Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
// SPDX-License-Identifier: MIT
//
//==============================================================================
`timescale 1ns/1ps

module axil_reg_control (
  input string        which_rdma,
  input string        rdma_cfg_filename,
  input string        rdma_recv_cfg_filename,
  input string        rdma_stat_filename,
  input               start_config_rdma,
  output              finish_config_rdma,
  input               start_checking_recv,
  input               start_rdma_stat,
  output              finish_rdma_stat,
  output logic        m_axil_reg_awvalid,
  output logic [31:0] m_axil_reg_awaddr,
  input               m_axil_reg_awready,
  output logic        m_axil_reg_wvalid,
  output logic [31:0] m_axil_reg_wdata,
  input               m_axil_reg_wready,
  input               m_axil_reg_bvalid,
  input         [1:0] m_axil_reg_bresp,
  output logic        m_axil_reg_bready,
  output logic        m_axil_reg_arvalid,
  output logic [31:0] m_axil_reg_araddr,
  input               m_axil_reg_arready,
  input               m_axil_reg_rvalid,
  input        [31:0] m_axil_reg_rdata,
  input         [1:0] m_axil_reg_rresp,
  output logic        m_axil_reg_rready,

  input axil_clk,
  input axil_rstn
);

localparam AXIL_WRITE_IDLE   = 2'b00;
localparam AXIL_WRITE        = 2'b01;
localparam AXIL_WRITE_WREADY = 2'b10;
localparam AXIL_WRITE_RESP   = 2'b11;

logic [1:0] wr_state, wr_nextstate;

logic [31:0] rn_rdma_conf;
logic        eof_rdma_conf;

logic        config_vld;
logic [31:0] config_addr;
logic [31:0] config_data;

logic [31:0] rn_rdma_recv_conf;
logic        eof_rdma_recv_conf;
logic        config_rq_vld;
logic [31:0] rq_addr;
logic [31:0] rq_golden_value;
logic        rq_pidb_vld;
logic [31:0] rq_pidb_addr;
logic [31:0] rq_pidb_golden_value;
logic [31:0] rq_pidb_value;
logic        rq_cidb_vld;
logic [31:0] rq_cidb_addr;
logic        poll_rq_pidb_vld;
logic [31:0] poll_rq_pidb_addr;
logic [31:0] poll_rq_pidb_golden_value;

/* AXI-Lite read interface */
localparam AXIL_READ_IDLE = 2'b01;
localparam AXIL_READ_RESP = 2'b10;
localparam AXIL_WAIT_NEXT_READ = 2'b11;
logic [1:0] axil_read_state;
logic [1:0] axil_read_nextstate;

logic        rdma_stat_vld;
logic [31:0] rdma_stat_value;

logic [31:0] rn_rdma_stat_read;
logic        eof_rdma_stat_read;

logic        stat_reg_vld;
logic [31:0] stat_reg_addr;
logic        next_read;

// AXI-Lite write operation
always_ff @(posedge axil_rstn)
begin
  rn_rdma_conf <= $fopen($sformatf("%s.txt", rdma_cfg_filename), "r");
end

always_ff @(posedge axil_rstn)
begin
  rn_rdma_recv_conf <= $fopen($sformatf("%s.txt", rdma_recv_cfg_filename), "r");
end

always_ff @(posedge axil_clk)
begin
  if (!axil_rstn) begin
    config_addr <= 32'd0;
    config_data <= 32'd0;
    config_vld  <= 1'b0;
    eof_rdma_conf <= 1'b0;

    config_rq_vld   <= 1'b0;
    rq_addr         <= 32'd0;
    rq_golden_value <= 32'd0;
    eof_rdma_recv_conf <= 1'b0;
  end
  else begin
    if (start_config_rdma) begin
      if (rn_rdma_conf) begin
        if (!eof_rdma_conf) begin
          if(!config_vld) begin
            if (32'h2 != $fscanf(rn_rdma_conf, "%x %x", config_addr, config_data)) begin
              $display("INFO: [axil_reg_control] time=%t, Finished reading %s file", $time, $sformatf("%s.txt", rdma_cfg_filename));
              config_data <= 32'd0;
              config_addr <= 32'd0;
              config_vld  <= 1'b0;

              eof_rdma_conf <= 1'b1;
            end
            else begin
              config_vld <= 1'b1;
            end
          end          
        end

        if((wr_state == AXIL_WRITE_RESP) && m_axil_reg_bvalid && config_vld) begin
          config_vld <= 1'b0;
        end
      end
      else begin
        $fatal("INFO: [axil_reg_control], time=%t, no %s file to configure the RDMA IP", $time, $sformatf("%s.txt", rdma_cfg_filename));
      end
    end
    else begin
      config_vld  <= 1'b0;
      config_data <= 32'd0;
      config_addr <= 32'd0;
    end

    // Checking RQ completion for send/receive operations
    if (start_checking_recv) begin
      if (rn_rdma_recv_conf) begin
        if (!eof_rdma_recv_conf) begin
          if(!config_rq_vld && !poll_rq_pidb_vld) begin
            if (32'h2 != $fscanf(rn_rdma_recv_conf, "%x %x", rq_addr, rq_golden_value)) begin
              $display("INFO: [axil_reg_control] time=%t, Finished reading %s file", $time, $sformatf("%s.txt", rdma_recv_cfg_filename));
              rq_golden_value <= 32'd0;
              rq_addr         <= 32'd0;
              config_rq_vld   <= 1'b0;

              eof_rdma_recv_conf <= 1'b1;
            end
            else begin
              config_rq_vld <= 1'b1;
            end
          end

          // Logic used to de-assert config_rq_vld
          // Set config_rq_vld to 1'b0 when rq_pidb_vld read is done
          if (m_axil_reg_rvalid && (m_axil_reg_rresp == 2'd0) && rq_pidb_vld) begin
            config_rq_vld <= 1'b0;
          end
          else begin
            // Set config_rq_vld to 1'b0 when rq_cidb write is done
            if((wr_state == AXIL_WRITE_RESP) && m_axil_reg_bvalid && rq_cidb_vld) begin
              config_rq_vld <= 1'b0;
            end
          end
        end

      end
      else begin
        $fatal("INFO: [axil_reg_control], time=%t, no %s file to check RQ completion status for a receive operation", $time, $sformatf("%s.txt", rdma_recv_cfg_filename));
      end      
    end
    else begin
      config_rq_vld   <= 1'b0;
      rq_addr         <= 32'd0;
      rq_golden_value <= 32'd0;
    end
  end
end

assign finish_config_rdma = eof_rdma_conf;

assign rq_pidb_vld  = (config_rq_vld && (rq_golden_value != 32'hffffffff)) ? config_rq_vld : 1'b0;
assign rq_pidb_addr = config_rq_vld ? ((rq_golden_value != 32'hffffffff) ? rq_addr : 32'd0) : 32'd0;
assign rq_pidb_golden_value = config_rq_vld ? ((rq_golden_value != 32'hffffffff) ? rq_golden_value : 32'd0) : 32'd0;
assign rq_cidb_vld  = (config_rq_vld && (rq_golden_value == 32'hffffffff)) ? config_rq_vld : 1'b0;
assign rq_cidb_addr = config_rq_vld ? ((rq_golden_value == 32'hffffffff) ? rq_addr : 32'd0) : 32'd0;

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
    if(config_vld || rq_cidb_vld) begin
      wr_nextstate = AXIL_WRITE;
    end
    else begin
      wr_nextstate = AXIL_WRITE_IDLE;
    end
  end
  AXIL_WRITE: begin
    wr_nextstate = AXIL_WRITE;
    m_axil_reg_awvalid = 1'b1;
    m_axil_reg_awaddr  = config_vld ? config_addr : rq_cidb_addr;
    if (m_axil_reg_awready) begin
      wr_nextstate = AXIL_WRITE_WREADY;
    end
  end
  AXIL_WRITE_WREADY: begin
    if (m_axil_reg_wready) begin
      m_axil_reg_wvalid = 1'b1;
      // If rq_cidb_vld is asserted, then write rq_pidb_value to rq_cidb to complete the 
      // receive operation
      m_axil_reg_wdata  = config_vld ? config_data : rq_pidb_value;
      wr_nextstate = AXIL_WRITE_RESP;
    end
  end
  AXIL_WRITE_RESP: begin
    if (m_axil_reg_bvalid) begin
      m_axil_reg_bready = 1'b1;
      wr_nextstate = AXIL_WRITE_IDLE;
    end
    else begin
      wr_nextstate = AXIL_WRITE_RESP;
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

localparam ERRBUFWPTR      = 32'h0002006c;
localparam IPKTERRQWPTR    = 32'h00020094;
localparam INSRRPKTCNT     = 32'h00020100;
localparam INAMPKTCNT      = 32'h00020104;
localparam OUTIOPKTCNT     = 32'h00020108;
localparam OUTAMPKTCNT     = 32'h0002010c;
localparam LSTINPKT        = 32'h00020110;
localparam LSTOUTPKT       = 32'h00020114;
localparam ININVDUPCNT     = 32'h00020118;
localparam INNCKPKTSTS     = 32'h0002011c;
localparam OUTRNRPKTSTS    = 32'h00020120;
localparam WQEPROCSTS      = 32'h00020124;
localparam QPMSTS          = 32'h0002012c;
localparam INALLDRPPKTCNT  = 32'h00020130;
localparam INNAKPKTCNT     = 32'h00020134;
localparam OUTNAKPKTCNT    = 32'h00020138;
localparam RESPHNDSTS      = 32'h0002013c;
localparam RETRYCNTSTS     = 32'h00020140;
localparam INCNPPKTCNT     = 32'h00020174;
localparam OUTCNPPKTCNT    = 32'h00020178;
localparam OUTRDRSPPKTCNT  = 32'h0002017c;
localparam INTSTS          = 32'h00020184;
localparam RQINTSTS1       = 32'h00020190;
localparam RQINTSTS2       = 32'h00020194;
localparam RQINTSTS3       = 32'h00020198;
localparam RQINTSTS4       = 32'h0002019c;
localparam RQINTSTS5       = 32'h000201a0;
localparam RQINTSTS6       = 32'h000201a4;
localparam RQINTSTS7       = 32'h000201a8;
localparam RQINTSTS8       = 32'h000201ac;
localparam CQINTSTS1       = 32'h000201b0;
localparam CQINTSTS2       = 32'h000201b4;
localparam CQINTSTS3       = 32'h000201b8;
localparam CQINTSTS4       = 32'h000201bc;
localparam CQINTSTS5       = 32'h000201c0;
localparam CQINTSTS6       = 32'h000201c4;
localparam CQINTSTS7       = 32'h000201c8;
localparam CQINTSTS8       = 32'h000201cc;
localparam CQHEADi         = 32'h00020330;
localparam STATSSNi        = 32'h00020380;
localparam STATMSNi        = 32'h00020384;
localparam STATQPi         = 32'h00020388;
localparam STATCURSQPTRi   = 32'h0002038c;
localparam STATRESPSNi     = 32'h00020390;
localparam STATRQBUFCAi    = 32'h00020394;
localparam STATRQBUFCAMSBi = 32'h000203d8;
localparam STATWQEi        = 32'h00020398;
localparam STATRQPIDBi     = 32'h0002039c;
localparam SQPIi           = 32'h00020338;

// AXI-Lite read operation
always_ff @(posedge axil_rstn)
begin
  rn_rdma_stat_read <= $fopen($sformatf("%s.txt", rdma_stat_filename), "r");
end

always_ff @(posedge axil_clk)
begin
  if (!axil_rstn) begin
    stat_reg_addr <= 32'd0;
    stat_reg_vld  <= 1'b0;

    eof_rdma_stat_read <= 1'b0;
  end
  else begin
    if (start_rdma_stat) begin
      if (rn_rdma_stat_read) begin
        if (!eof_rdma_stat_read) begin
          if(!stat_reg_vld) begin
            if (32'h1 != $fscanf(rn_rdma_stat_read, "%x", stat_reg_addr)) begin
              $display("INFO: [axil_reg_control] time=%t, Finished reading %s file\n", $time, $sformatf("%s.txt", rdma_stat_filename));
              stat_reg_addr <= 32'd0;
              stat_reg_vld  <= 1'b0;

              eof_rdma_stat_read <= 1'b1;
            end
            else begin
              stat_reg_vld <= 1'b1;
            end
          end
        end

        if(next_read) begin
          stat_reg_vld <= 1'b0;
        end
      end
      else begin
        $fatal("INFO: [axil_reg_control], time=%t, no %s file to read statistics the RDMA IP", $time, $sformatf("%s.txt", stat_reg_addr));
      end
    end
    else begin
      stat_reg_vld  <= 1'b0;
      stat_reg_addr <= 32'd0;
    end
  end
end

assign finish_rdma_stat = eof_rdma_stat_read;

always_comb 
begin
  m_axil_reg_arvalid  = 1'b0;
  m_axil_reg_araddr   = 32'd0;
  m_axil_reg_rready   = 1'b0;
  axil_read_nextstate = axil_read_state;
  case(axil_read_state)
  AXIL_READ_IDLE: begin
    if(stat_reg_vld || rq_pidb_vld || poll_rq_pidb_vld) begin
      m_axil_reg_arvalid = 1'b1;
      m_axil_reg_araddr  = stat_reg_vld ? stat_reg_addr : (rq_pidb_vld ? rq_pidb_addr : poll_rq_pidb_addr);
      if(m_axil_reg_arready) begin
        axil_read_nextstate = AXIL_READ_RESP;
      end
      else begin
        axil_read_nextstate = AXIL_READ_IDLE;
      end
    end
    else begin
      axil_read_nextstate = AXIL_READ_IDLE;
    end
  end
  AXIL_READ_RESP: begin
    m_axil_reg_rready = 1'b1;
    if(m_axil_reg_rvalid && (m_axil_reg_rresp == 2'd0)) begin
      axil_read_nextstate = next_read ? AXIL_READ_IDLE : AXIL_WAIT_NEXT_READ;
    end
    else begin
      if(m_axil_reg_rvalid && (m_axil_reg_rresp != 2'd0)) begin
        $fatal("INFO: [axil_reg_control], time=%t, m_axil_reg_rresp is not 0", $time);
      end
      else begin
        axil_read_nextstate = AXIL_READ_RESP;
      end
    end
  end
  AXIL_WAIT_NEXT_READ: begin
    if(next_read || poll_rq_pidb_vld) begin
      axil_read_nextstate = AXIL_READ_IDLE;
    end
  end
  default: begin
    axil_read_nextstate = AXIL_READ_IDLE;
  end
  endcase
end

always_ff @(posedge axil_clk)
begin
  if(!axil_rstn) begin
    rdma_stat_vld   <= 1'b0;
    rdma_stat_value <= 32'd0;
    next_read       <= 1'b0;

    rq_pidb_value   <= 32'd0;
    axil_read_state <= AXIL_READ_IDLE;
  end
  else begin
    next_read <= 1'b0;
    if(m_axil_reg_rvalid && (m_axil_reg_rresp == 2'd0)) begin
      if (rq_pidb_vld || poll_rq_pidb_vld) begin
        rq_pidb_value <= m_axil_reg_rdata;
      end
      else begin
        rdma_stat_vld   <= 1'b1;
        rdma_stat_value <= m_axil_reg_rdata;
      end
    end
    else begin
      next_read     <= rdma_stat_vld ? 1'b1 : 1'b0;
      rdma_stat_vld <= 1'b0;
    end

    axil_read_state <= axil_read_nextstate;
  end
end

localparam POLLING = 1'b0;
localparam TIMEOUT = 1'b1;
localparam TIMEOUT_THRESHOLD = 32'h00000400;
logic poll_state;
logic [31:0] timeout_cnt;

always_ff @(posedge axil_clk)
begin
  if(!axil_rstn) begin
    poll_rq_pidb_vld  <= 1'b0;
    poll_rq_pidb_addr <= 32'd0;
    poll_rq_pidb_golden_value <= 32'd0;

    timeout_cnt <= 32'd0;
    poll_state <= POLLING;
  end
  else begin
    if (rq_pidb_vld && m_axil_reg_rvalid && (m_axil_reg_rresp == 2'd0) && (!poll_rq_pidb_vld)) begin
      if (rq_pidb_golden_value != m_axil_reg_rdata) begin
        // Polling rq_pidb
        poll_rq_pidb_vld  <= 1'b1;
        poll_rq_pidb_addr <= rq_pidb_addr;
        poll_rq_pidb_golden_value <= rq_pidb_golden_value;
        //$fatal("ERROR: [axil_reg_control], time=%t, %s, rq_pidb_gloden_value (%d) and rq_pidb_value (%d) are mismatched", $time, rq_pidb_golden_value, m_axil_reg_rdata);
      end
    end

    if (poll_rq_pidb_vld && m_axil_reg_rvalid && (m_axil_reg_rresp == 2'd0)) begin
      case(poll_state)
      POLLING: begin
        if (poll_rq_pidb_golden_value == m_axil_reg_rdata) begin
          // Polling rq_pidb
          poll_rq_pidb_vld  <= 1'b0;
          poll_rq_pidb_addr <= 32'd0;
          poll_rq_pidb_golden_value <= 32'd0;
          //$fatal("ERROR: [axil_reg_control], time=%t, %s, rq_pidb_gloden_value (%d) and rq_pidb_value (%d) are mismatched", $time, rq_pidb_golden_value, m_axil_reg_rdata);
        end

        timeout_cnt <= timeout_cnt + 1;
        if (timeout_cnt == TIMEOUT_THRESHOLD) begin
          timeout_cnt <= 32'd0;
          poll_state <= TIMEOUT;
        end
      end
      TIMEOUT: begin
        $fatal("ERROR: [axil_reg_control], time=%t, rq_pidb timeout", $time);
      end
      default: poll_state <= POLLING;
      endcase
    end
  end
end

always_comb
begin
  if(rdma_stat_vld) begin
    case(stat_reg_addr)
    ERRBUFWPTR     : $display("INFO: [axil_reg_control], time=%t, %s, ERRBUFWPTR      (addr=0x%x)= 0x%x", $time, which_rdma, stat_reg_addr, rdma_stat_value);
    IPKTERRQWPTR   : $display("INFO: [axil_reg_control], time=%t, %s, IPKTERRQWPTR    (addr=0x%x)= 0x%x", $time, which_rdma, stat_reg_addr, rdma_stat_value);
    INSRRPKTCNT    : $display("INFO: [axil_reg_control], time=%t, %s, INSRRPKTCNT     (addr=0x%x)= 0x%x", $time, which_rdma, stat_reg_addr, rdma_stat_value);
    INAMPKTCNT     : $display("INFO: [axil_reg_control], time=%t, %s, INAMPKTCNT      (addr=0x%x)= 0x%x", $time, which_rdma, stat_reg_addr, rdma_stat_value);
    OUTIOPKTCNT    : $display("INFO: [axil_reg_control], time=%t, %s, OUTIOPKTCNT     (addr=0x%x)= 0x%x", $time, which_rdma, stat_reg_addr, rdma_stat_value);
    OUTAMPKTCNT    : $display("INFO: [axil_reg_control], time=%t, %s, OUTAMPKTCNT     (addr=0x%x)= 0x%x", $time, which_rdma, stat_reg_addr, rdma_stat_value);
    LSTINPKT       : $display("INFO: [axil_reg_control], time=%t, %s, LSTINPKT        (addr=0x%x)= 0x%x", $time, which_rdma, stat_reg_addr, rdma_stat_value);
    LSTOUTPKT      : $display("INFO: [axil_reg_control], time=%t, %s, LSTOUTPKT       (addr=0x%x)= 0x%x", $time, which_rdma, stat_reg_addr, rdma_stat_value);
    ININVDUPCNT    : $display("INFO: [axil_reg_control], time=%t, %s, ININVDUPCNT     (addr=0x%x)= 0x%x", $time, which_rdma, stat_reg_addr, rdma_stat_value);
    INNCKPKTSTS    : $display("INFO: [axil_reg_control], time=%t, %s, INNCKPKTSTS     (addr=0x%x)= 0x%x", $time, which_rdma, stat_reg_addr, rdma_stat_value);
    OUTRNRPKTSTS   : $display("INFO: [axil_reg_control], time=%t, %s, OUTRNRPKTSTS    (addr=0x%x)= 0x%x", $time, which_rdma, stat_reg_addr, rdma_stat_value);
    WQEPROCSTS     : $display("INFO: [axil_reg_control], time=%t, %s, WQEPROCSTS      (addr=0x%x)= 0x%x", $time, which_rdma, stat_reg_addr, rdma_stat_value);
    QPMSTS         : $display("INFO: [axil_reg_control], time=%t, %s, QPMSTS          (addr=0x%x)= 0x%x", $time, which_rdma, stat_reg_addr, rdma_stat_value);
    INALLDRPPKTCNT : $display("INFO: [axil_reg_control], time=%t, %s, INALLDRPPKTCNT  (addr=0x%x)= 0x%x", $time, which_rdma, stat_reg_addr, rdma_stat_value);
    INNAKPKTCNT    : $display("INFO: [axil_reg_control], time=%t, %s, INNAKPKTCNT     (addr=0x%x)= 0x%x", $time, which_rdma, stat_reg_addr, rdma_stat_value);
    OUTNAKPKTCNT   : $display("INFO: [axil_reg_control], time=%t, %s, OUTNAKPKTCNT    (addr=0x%x)= 0x%x", $time, which_rdma, stat_reg_addr, rdma_stat_value);
    RESPHNDSTS     : $display("INFO: [axil_reg_control], time=%t, %s, RESPHNDSTS      (addr=0x%x)= 0x%x", $time, which_rdma, stat_reg_addr, rdma_stat_value);
    RETRYCNTSTS    : $display("INFO: [axil_reg_control], time=%t, %s, RETRYCNTSTS     (addr=0x%x)= 0x%x", $time, which_rdma, stat_reg_addr, rdma_stat_value);
    INCNPPKTCNT    : $display("INFO: [axil_reg_control], time=%t, %s, INCNPPKTCNT     (addr=0x%x)= 0x%x", $time, which_rdma, stat_reg_addr, rdma_stat_value);
    OUTCNPPKTCNT   : $display("INFO: [axil_reg_control], time=%t, %s, OUTCNPPKTCNT    (addr=0x%x)= 0x%x", $time, which_rdma, stat_reg_addr, rdma_stat_value);
    OUTRDRSPPKTCNT : $display("INFO: [axil_reg_control], time=%t, %s, OUTRDRSPPKTCNT  (addr=0x%x)= 0x%x", $time, which_rdma, stat_reg_addr, rdma_stat_value);
    INTSTS         : $display("INFO: [axil_reg_control], time=%t, %s, INTSTS          (addr=0x%x)= 0x%x", $time, which_rdma, stat_reg_addr, rdma_stat_value);
    RQINTSTS1      : $display("INFO: [axil_reg_control], time=%t, %s, RQINTSTS1       (addr=0x%x)= 0x%x", $time, which_rdma, stat_reg_addr, rdma_stat_value);
    RQINTSTS2      : $display("INFO: [axil_reg_control], time=%t, %s, RQINTSTS2       (addr=0x%x)= 0x%x", $time, which_rdma, stat_reg_addr, rdma_stat_value);
    RQINTSTS3      : $display("INFO: [axil_reg_control], time=%t, %s, RQINTSTS3       (addr=0x%x)= 0x%x", $time, which_rdma, stat_reg_addr, rdma_stat_value);
    RQINTSTS4      : $display("INFO: [axil_reg_control], time=%t, %s, RQINTSTS4       (addr=0x%x)= 0x%x", $time, which_rdma, stat_reg_addr, rdma_stat_value);
    RQINTSTS5      : $display("INFO: [axil_reg_control], time=%t, %s, RQINTSTS5       (addr=0x%x)= 0x%x", $time, which_rdma, stat_reg_addr, rdma_stat_value);
    RQINTSTS6      : $display("INFO: [axil_reg_control], time=%t, %s, RQINTSTS6       (addr=0x%x)= 0x%x", $time, which_rdma, stat_reg_addr, rdma_stat_value);
    RQINTSTS7      : $display("INFO: [axil_reg_control], time=%t, %s, RQINTSTS7       (addr=0x%x)= 0x%x", $time, which_rdma, stat_reg_addr, rdma_stat_value);
    RQINTSTS8      : $display("INFO: [axil_reg_control], time=%t, %s, RQINTSTS8       (addr=0x%x)= 0x%x", $time, which_rdma, stat_reg_addr, rdma_stat_value);
    CQINTSTS1      : $display("INFO: [axil_reg_control], time=%t, %s, CQINTSTS1       (addr=0x%x)= 0x%x", $time, which_rdma, stat_reg_addr, rdma_stat_value);
    CQINTSTS2      : $display("INFO: [axil_reg_control], time=%t, %s, CQINTSTS2       (addr=0x%x)= 0x%x", $time, which_rdma, stat_reg_addr, rdma_stat_value);
    CQINTSTS3      : $display("INFO: [axil_reg_control], time=%t, %s, CQINTSTS3       (addr=0x%x)= 0x%x", $time, which_rdma, stat_reg_addr, rdma_stat_value);
    CQINTSTS4      : $display("INFO: [axil_reg_control], time=%t, %s, CQINTSTS4       (addr=0x%x)= 0x%x", $time, which_rdma, stat_reg_addr, rdma_stat_value);
    CQINTSTS5      : $display("INFO: [axil_reg_control], time=%t, %s, CQINTSTS5       (addr=0x%x)= 0x%x", $time, which_rdma, stat_reg_addr, rdma_stat_value);
    CQINTSTS6      : $display("INFO: [axil_reg_control], time=%t, %s, CQINTSTS6       (addr=0x%x)= 0x%x", $time, which_rdma, stat_reg_addr, rdma_stat_value);
    CQINTSTS7      : $display("INFO: [axil_reg_control], time=%t, %s, CQINTSTS7       (addr=0x%x)= 0x%x", $time, which_rdma, stat_reg_addr, rdma_stat_value);
    CQINTSTS8      : $display("INFO: [axil_reg_control], time=%t, %s, CQINTSTS8       (addr=0x%x)= 0x%x", $time, which_rdma, stat_reg_addr, rdma_stat_value);
    CQHEADi        : $display("INFO: [axil_reg_control], time=%t, %s, CQHEADi         (addr=0x%x)= 0x%x", $time, which_rdma, stat_reg_addr, rdma_stat_value);
    STATSSNi       : $display("INFO: [axil_reg_control], time=%t, %s, STATSSNi        (addr=0x%x)= 0x%x", $time, which_rdma, stat_reg_addr, rdma_stat_value);
    STATMSNi       : $display("INFO: [axil_reg_control], time=%t, %s, STATMSNi        (addr=0x%x)= 0x%x", $time, which_rdma, stat_reg_addr, rdma_stat_value);
    STATQPi        : $display("INFO: [axil_reg_control], time=%t, %s, STATQPi         (addr=0x%x)= 0x%x", $time, which_rdma, stat_reg_addr, rdma_stat_value);
    STATCURSQPTRi  : $display("INFO: [axil_reg_control], time=%t, %s, STATCURSQPTRi   (addr=0x%x)= 0x%x", $time, which_rdma, stat_reg_addr, rdma_stat_value);
    STATRESPSNi    : $display("INFO: [axil_reg_control], time=%t, %s, STATRESPSNi     (addr=0x%x)= 0x%x", $time, which_rdma, stat_reg_addr, rdma_stat_value);
    STATRQBUFCAi   : $display("INFO: [axil_reg_control], time=%t, %s, STATRQBUFCAi    (addr=0x%x)= 0x%x", $time, which_rdma, stat_reg_addr, rdma_stat_value);
    STATRQBUFCAMSBi: $display("INFO: [axil_reg_control], time=%t, %s, STATRQBUFCAMSBi (addr=0x%x)= 0x%x", $time, which_rdma, stat_reg_addr, rdma_stat_value);
    STATWQEi       : $display("INFO: [axil_reg_control], time=%t, %s, STATWQEi        (addr=0x%x)= 0x%x", $time, which_rdma, stat_reg_addr, rdma_stat_value);
    STATRQPIDBi    : $display("INFO: [axil_reg_control], time=%t, %s, STATRQPIDBi     (addr=0x%x)= 0x%x", $time, which_rdma, stat_reg_addr, rdma_stat_value);
    SQPIi          : $display("INFO: [axil_reg_control], time=%t, %s, SQPIi           (addr=0x%x)= 0x%x", $time, which_rdma, stat_reg_addr, rdma_stat_value);
    default: begin
      $display("INFO: [axil_reg_control], time=%t, stat_reg_addr(0x%x) is not supported", $time, stat_reg_addr);
    end
    endcase
  end
end

endmodule: axil_reg_control