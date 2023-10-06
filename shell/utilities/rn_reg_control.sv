//==============================================================================
// Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
// SPDX-License-Identifier: MIT
//
//==============================================================================
//
//  rn_reg_control
//  -- RecoNIC's register control interface
//     Register           Offset   Type  Usage
//     RN_VERSION         12'd0     RO   RecoNIC version in DD/MM/YY format
//     FATAL_ERR          12'd4     RO   fatal error used for debug purpose
//     TRROCE_HIGH_REG    12'd8     RO   total received RoCEv2 packets (high reg)
//     TRROCE_LOW_REG     12'd12    RO   total received RoCEv2 packets (low  reg)
//     TRNONROCE_HIGH_REG 12'd16    RO   total received non-RoCEv2 packets (high reg)
//     TRNONROCE_LOW_REG  12'd20    RO   total received non-RoCEv2 packets (low  reg)
//     TEMPLATE_REG       12'd512   R/W  template register used for read/write
//
//==============================================================================
`timescale 1ns/1ps

module rn_reg_control #(
  parameter AXIL_ADDR_WIDTH = 12,
  parameter AXIL_DATA_WIDTH = 32,
  parameter OP_WIDTH        = 8,
  parameter DEFAULT_VALUE   = 32'hDEEDBEEF
)(
  input                              s_axil_reg_awvalid,
  input  [AXIL_ADDR_WIDTH-1:0]       s_axil_reg_awaddr ,
  output logic                       s_axil_reg_awready,
  input                              s_axil_reg_wvalid ,
  input  [AXIL_DATA_WIDTH-1:0]       s_axil_reg_wdata  ,
  output logic                       s_axil_reg_wready ,
  output logic                       s_axil_reg_bvalid ,
  output logic [1:0]                 s_axil_reg_bresp  ,
  input                              s_axil_reg_bready ,
  input                              s_axil_reg_arvalid,
  input  [AXIL_ADDR_WIDTH-1:0]       s_axil_reg_araddr ,
  output logic                       s_axil_reg_arready,
  output logic                       s_axil_reg_rvalid ,
  output logic [AXIL_DATA_WIDTH-1:0] s_axil_reg_rdata  ,
  output logic [1:0]                 s_axil_reg_rresp  ,
  input                              s_axil_reg_rready ,

  // Packet statistics registers
  input                              roce_pkt_recved,
  input                              non_roce_pkt_recved,
  input        [AXIL_DATA_WIDTH-1:0] fatal_err,

  input axil_aclk,
  input axil_arstn
);

function integer log2;
  input integer val;
  begin
    log2 = 0;
    while (2**log2 < val) begin
      log2 = log2 + 1;
    end
  end
endfunction

/* Statistics Registers */
// Read only
localparam RN_VERSION                  = 12'h000;
localparam FATAL_ERR                   = 12'h004;
localparam TRROCE_HIGH_REG             = 12'h008;
localparam TRROCE_LOW_REG              = 12'h00C;
localparam TRROCE_NO_RESET_HIGH_REG    = 12'h010;
localparam TRROCE_NO_RESET_LOW_REG     = 12'h014;
localparam TRNONROCE_HIGH_REG          = 12'h018;
localparam TRNONROCE_LOW_REG           = 12'h01C;
localparam TRNONROCE_NO_RESET_HIGH_REG = 12'h020;
localparam TRNONROCE_NO_RESET_LOW_REG  = 12'h024;
localparam RN_TIMER_HIGH_REG           = 12'h028;
localparam RN_TIMER_LOW_REG            = 12'h02C;

logic [AXIL_DATA_WIDTH-1:0] rn_version_reg;
logic [AXIL_DATA_WIDTH-1:0] fatal_err_reg;
// trroce: total number of roce packets received
(* mark_debug = "true" *) logic [AXIL_DATA_WIDTH-1:0] trroce_high_reg;
(* mark_debug = "true" *) logic [AXIL_DATA_WIDTH-1:0] trroce_low_reg;
(* mark_debug = "true" *) logic [AXIL_DATA_WIDTH-1:0] trroce_no_reset_high_reg;
(* mark_debug = "true" *) logic [AXIL_DATA_WIDTH-1:0] trroce_no_reset_low_reg;
// trroce: total number of non-roce packets received
(* mark_debug = "true" *) logic [AXIL_DATA_WIDTH-1:0] trnonroce_high_reg;
(* mark_debug = "true" *) logic [AXIL_DATA_WIDTH-1:0] trnonroce_low_reg;
(* mark_debug = "true" *) logic [AXIL_DATA_WIDTH-1:0] trnonroce_no_reset_high_reg;
(* mark_debug = "true" *) logic [AXIL_DATA_WIDTH-1:0] trnonroce_no_reset_low_reg;

logic [63:0] rn_reg_ctl_timer;

// Read/Write
localparam TEMPLATE_REG = 12'd512;
logic [AXIL_DATA_WIDTH-1:0] template_reg;

logic trroce_carry_bit;
logic trroce_overflow_bit;
logic msb_trroce_low;

logic trroce_no_reset_carry_bit;
logic trroce_no_reset_overflow_bit;
logic msb_trroce_no_reset_low;

logic trnonroce_carry_bit;
logic trnonroce_overflow_bit;
logic msb_trnonroce_low;

logic trnonroce_no_reset_carry_bit;
logic trnonroce_no_reset_overflow_bit;
logic msb_trnonroce_no_reset_low;

/* AXI-Lite write interface */
localparam AXIL_WRITE_IDLE   = 2'd0;
localparam AXIL_WRITE_WREADY = 2'd1;
localparam AXIL_WRITE_RESP   = 2'd2;

logic [AXIL_ADDR_WIDTH-1:0] awaddr;
logic [1:0] axil_write_state;

/* AXI-Lite read interface */
localparam AXIL_READ_IDLE = 2'b01;
localparam AXIL_READ_RESP = 2'b10;
logic [1:0] axil_read_state;

logic [AXIL_ADDR_WIDTH-1:0] araddr;

// AXI-Lite write operation
always_ff @(posedge axil_aclk)
begin
  if(~axil_arstn)
  begin
    s_axil_reg_awready <= 1'b1;
    s_axil_reg_wready  <= 1'b0;
    s_axil_reg_bvalid  <= 1'b0;
    s_axil_reg_bresp   <= 2'd0;
    awaddr             <= 0;

    template_reg       <= 0;

    axil_write_state <= AXIL_WRITE_IDLE;
  end
  else begin
    case(axil_write_state)
      AXIL_WRITE_IDLE: begin
        if(s_axil_reg_awvalid && s_axil_reg_awready)
        begin
          s_axil_reg_wready  <= 1'b1;
          s_axil_reg_awready <= 1'b0;
          awaddr            <= s_axil_reg_awaddr;
          if(s_axil_reg_wvalid)
          begin
            case(s_axil_reg_awaddr)
              TEMPLATE_REG: begin
                template_reg <= s_axil_reg_wdata;
              end
              default: begin
                template_reg         <= template_reg;
              end
            endcase
            axil_write_state <= AXIL_WRITE_RESP;    
          end
          else begin
            axil_write_state <= AXIL_WRITE_WREADY;
          end
        end
        else begin
          s_axil_reg_wready <= s_axil_reg_wready;
        end
      end
      AXIL_WRITE_WREADY: begin
        if(s_axil_reg_wvalid)
        begin
          case(awaddr)
            TEMPLATE_REG   : template_reg   <= s_axil_reg_wdata;

            default: begin
              template_reg         <= template_reg;
            end
          endcase
          if(s_axil_reg_wready)
          begin
            s_axil_reg_wready <= 1'b0;
            s_axil_reg_bvalid <= 1'b1;            
          end
          axil_write_state <= AXIL_WRITE_RESP;    
        end
      end
      AXIL_WRITE_RESP: begin
        if(s_axil_reg_wready && s_axil_reg_wvalid)
        begin
          s_axil_reg_wready <= 1'b0;
          s_axil_reg_bvalid <= 1'b1;
        end
        
        if(s_axil_reg_bready && s_axil_reg_bvalid)
        begin
          s_axil_reg_bresp   <= 0;
          s_axil_reg_bvalid  <= 1'b0;
          s_axil_reg_awready <= 1'b1;
          awaddr             <= 0;  
          axil_write_state <= AXIL_WRITE_IDLE;
        end
      end
      default: begin
        s_axil_reg_awready <= 1'b1;
        s_axil_reg_wready  <= 1'b0;
        s_axil_reg_bvalid  <= 1'b0;
        s_axil_reg_bresp   <= 2'd0;
        awaddr             <= 0;     
        axil_write_state <= AXIL_WRITE_IDLE;
      end
    endcase
  end
end

// AXI-Lite read operation
always_ff @(posedge axil_aclk)
begin
  if(~axil_arstn)
  begin
    s_axil_reg_arready <= 1'b1;
    s_axil_reg_rvalid  <= 1'b0;
    s_axil_reg_rdata   <= 0;
    s_axil_reg_rresp   <= 0;
    araddr             <= 0;
    axil_read_state <= AXIL_READ_IDLE;
  end
  else begin
    case(axil_read_state)
      AXIL_READ_IDLE: begin
        if(s_axil_reg_arready && s_axil_reg_arvalid)
        begin
          s_axil_reg_arready <= 1'b0;
          s_axil_reg_rvalid  <= 1'b1;
          s_axil_reg_rresp   <= 0;
          araddr             <= s_axil_reg_araddr;
          case(s_axil_reg_araddr)
            RN_VERSION                 : s_axil_reg_rdata <= rn_version_reg;
            FATAL_ERR                  : s_axil_reg_rdata <= fatal_err_reg;
            TRROCE_HIGH_REG            : s_axil_reg_rdata <= trroce_high_reg;
            TRROCE_LOW_REG             : s_axil_reg_rdata <= trroce_low_reg;
            TRROCE_NO_RESET_HIGH_REG   : s_axil_reg_rdata <= trroce_no_reset_high_reg;
            TRROCE_NO_RESET_LOW_REG    : s_axil_reg_rdata <= trroce_no_reset_low_reg;
            TRNONROCE_HIGH_REG         : s_axil_reg_rdata <= trnonroce_high_reg;
            TRNONROCE_LOW_REG          : s_axil_reg_rdata <= trnonroce_low_reg;
            TRNONROCE_NO_RESET_HIGH_REG: s_axil_reg_rdata <= trnonroce_no_reset_high_reg;
            TRNONROCE_NO_RESET_LOW_REG : s_axil_reg_rdata <= trnonroce_no_reset_low_reg;
            RN_TIMER_HIGH_REG          : s_axil_reg_rdata <= rn_reg_ctl_timer[63:32];
            RN_TIMER_LOW_REG           : s_axil_reg_rdata <= rn_reg_ctl_timer[31:0];
            TEMPLATE_REG               : s_axil_reg_rdata <= template_reg;
            default                    : s_axil_reg_rdata <= DEFAULT_VALUE;
          endcase
          axil_read_state    <= AXIL_READ_RESP;
        end
      end
      AXIL_READ_RESP: begin
        if(s_axil_reg_rready && s_axil_reg_rvalid)
        begin
          s_axil_reg_rvalid  <= 1'b0;
          s_axil_reg_arready <= 1'b1;
          axil_read_state    <= AXIL_READ_IDLE;
        end
      end
      default: begin
        s_axil_reg_arready <= 1'b1;
        s_axil_reg_rvalid  <= 1'b0;
        s_axil_reg_rdata   <= 0;
        s_axil_reg_rresp   <= 0;
        axil_read_state <= AXIL_READ_IDLE;        
      end
    endcase
  end
end

/* Statistics Registers */
/*
 * RecoNIC version
 */
always_ff @(posedge axil_aclk)
begin
  if(~axil_arstn)
  begin
    rn_version_reg <= 32'h11082022;
  end
  else begin
    rn_version_reg <= rn_version_reg;
  end
end

/*
 * fatal_err: Fatal Error Register
 * -- [9:9] : TRNONROCE_NO_RESET_HIGH_REG register overflow
 * -- [8:8] : TRROCE_NO_RESET_HIGH_REG register overflow
 * -- [7:7] : TRNONROCE_HIGH_REG register overflow
 * -- [6:6] : TRROCE_HIGH_REG register overflow
 * -- [5:4] : Reserved
 * -- [3:2] : Reserved
 * -- [1:1] : Reserved
 * -- [0:0] : FIFO full in packet filter or backpressure given to packet filter from RDMA module
 * -- Offset: FATAL_ERR = 12'd4
 */
always_ff @(posedge axil_aclk)
begin
  if(~axil_arstn)
  begin
    fatal_err_reg <= 0;
  end
  else begin
    fatal_err_reg <= {22'd0, trnonroce_no_reset_overflow_bit, trroce_no_reset_overflow_bit, trnonroce_overflow_bit, trroce_overflow_bit, fatal_err[5:0]};
  end
end

/*
 * TRROCE_HIGH_REG and TRROCE_LOW_REG: Total Received RoCEv2 Packet Registers
 * TRRMHR and TRRMLR: Total Received non-RoCEv2 Packet Registers
 *
 * -- TRROCE_HIGH_REG: Total Received RoCEv2 Packet High Register, will be reset after read
 *           [31]   : Read only; Overflow bit
 *           [30:0] : Read only; Upper counter
 *           Offset : TRROCE_HIGH_REG = 12'd8
 * -- TRROCE_LOW_REG: Total Received RoCEv2 Packet Low Register, will be reset after read
 *           [31:0] : Read only; Lower counter
 *           Offset : TRROCE_LOW_REG = 12'd12
 *
 * -- TRROCE_NO_RESET_HIGH_REG and TRROCE_NO_RESET_LOW_REG: the same with the above TRROCE 
 *                    registers, but it won't be reset after read
 *
 * -- TRNONROCE_HIGH_REG: Total Received non-RoCEv2 Packet High Register, will be reset 
 *                        after read
 *            [31]   : Read only; Overflow bit
 *            [30:0] : Read only; Upper counter
 *            Offset : TRNONROCE_HIGH_REG = 12'd16
 * -- TRNONROCE_LOW_REG: Total Received non-RoCEv2 Packet Low Register, will be reset 
 *                       after read
 *            [31:0] : Read only; Lower counter
 *            Offset : TRNONROCE_LOW_REG = 12'd20
 *
 * -- TRNONROCE_NO_RESET_HIGH_REG and TRNONROCE_NO_RESET_LOW_REG: the same with the above 
 *                     TRNONROCE registers, but it won't be reset after read
 *
 * [NOTE]: TRROCE_HIGH_REG register will be read immediately after
 *         reading TRROCE_LOW_REG register. The same for TRNONROCE_HIGH_REG and
 *         TRNONROCE_LOW_REG registers
 */
always_ff @(posedge axil_aclk)
begin
  if(~axil_arstn)
  begin
    trroce_low_reg <= 0;
    msb_trroce_low <= 1'b0;
    trroce_carry_bit <= 1'b0;

    trroce_no_reset_low_reg <= 0;
    msb_trroce_no_reset_low <= 1'b0;
    trroce_no_reset_carry_bit <= 1'b0;

    trnonroce_low_reg <= 0;
    msb_trnonroce_low <= 1'b0;
    trnonroce_carry_bit <= 1'b0;

    trnonroce_no_reset_low_reg <= 0;
    msb_trnonroce_no_reset_low <= 1'b0;
    trnonroce_no_reset_carry_bit <= 1'b0;    
  end
  else begin
    // trroce_low_reg
    if(!trroce_overflow_bit)
    begin
      if(s_axil_reg_rvalid && araddr==TRROCE_LOW_REG)
      begin
        // Clear trroce_low_reg when the register has been read
        trroce_low_reg <= roce_pkt_recved ? 32'd1 : 32'd0;
        trroce_carry_bit <= 1'b0;
        msb_trroce_low <= 1'b0;
      end
      else begin
        trroce_carry_bit <= 1'b0;
        if(roce_pkt_recved)
        begin
          if(msb_trroce_low && ~trroce_low_reg[AXIL_DATA_WIDTH-1])
          begin
            trroce_carry_bit <= 1'b1;
          end

          trroce_low_reg <= trroce_low_reg + 32'd1;
          msb_trroce_low <= trroce_low_reg[AXIL_DATA_WIDTH-1];
        end
      end
    end
    else begin
      // Stop counting number of packet sent when overflow
      trroce_low_reg <= 0;
      trroce_carry_bit <= 1'b0;      
    end

    // trroce_no_reset_low_reg
    if(!trroce_no_reset_overflow_bit)
    begin
      trroce_no_reset_carry_bit <= 1'b0;
      if(roce_pkt_recved)
      begin
        if(msb_trroce_no_reset_low && ~trroce_no_reset_low_reg[AXIL_DATA_WIDTH-1])
        begin
          trroce_no_reset_carry_bit <= 1'b1;
        end

        trroce_no_reset_low_reg <= trroce_no_reset_low_reg + 32'd1;
        msb_trroce_no_reset_low <= trroce_no_reset_low_reg[AXIL_DATA_WIDTH-1];
      end
    end
    else begin
      // Stop counting number of packet sent when overflow
      trroce_no_reset_low_reg <= 0;
      trroce_no_reset_carry_bit <= 1'b0;      
    end

    // trnonroce_low_reg
    if(!trnonroce_overflow_bit)
    begin
      if(s_axil_reg_rvalid && araddr==TRNONROCE_LOW_REG)
      begin
        // Clear trnonroce_low_reg when the register has been read
        trnonroce_low_reg <= non_roce_pkt_recved ? 32'd1 : 32'd0;
        trnonroce_carry_bit <= 1'b0;
        msb_trnonroce_low <= 1'b0;
      end
      else begin
        trnonroce_carry_bit <= 1'b0;
        if(non_roce_pkt_recved)
        begin
          if(msb_trnonroce_low && ~trnonroce_low_reg[AXIL_DATA_WIDTH-1])
          begin
            trnonroce_carry_bit <= 1'b1;
          end

          trnonroce_low_reg <= trnonroce_low_reg + 32'd1;
          msb_trnonroce_low <= trnonroce_low_reg[AXIL_DATA_WIDTH-1];
        end
      end
    end
    else begin
      // Stop counting number of packet sent when overflow
      trnonroce_low_reg <= 0;
      trnonroce_carry_bit <= 1'b0;
    end

    // trnonroce_no_reset_low_reg
    if(!trnonroce_no_reset_overflow_bit)
    begin
      trnonroce_no_reset_carry_bit <= 1'b0;
      if(non_roce_pkt_recved)
      begin
        if(msb_trnonroce_no_reset_low && ~trnonroce_no_reset_low_reg[AXIL_DATA_WIDTH-1])
        begin
          trnonroce_no_reset_carry_bit <= 1'b1;
        end

        trnonroce_no_reset_low_reg <= trnonroce_no_reset_low_reg + 32'd1;
        msb_trnonroce_no_reset_low <= trnonroce_no_reset_low_reg[AXIL_DATA_WIDTH-1];
      end
    end
    else begin
      // Stop counting number of packet sent when overflow
      trnonroce_no_reset_low_reg <= 0;
      trnonroce_no_reset_carry_bit <= 1'b0;
    end 
  end
end

always_ff @(posedge axil_aclk)
begin
  if(~axil_arstn)
  begin
    trroce_high_reg     <= 0;
    trroce_overflow_bit <= 1'b0;

    trroce_no_reset_high_reg     <= 0;
    trroce_no_reset_overflow_bit <= 1'b0;

    trnonroce_high_reg     <= 0;
    trnonroce_overflow_bit <= 1'b0;

    trnonroce_no_reset_high_reg     <= 0;
    trnonroce_no_reset_overflow_bit <= 1'b0;
  end
  else begin
    // trroce_high_reg
    if(!trroce_overflow_bit)
    begin
      if(s_axil_reg_rvalid && araddr==TRROCE_HIGH_REG)
      begin
        // Clear trroce_high_reg when the register has been read.
        trroce_high_reg    <= 32'd0;
      end
      else begin
        if(trroce_carry_bit)
        begin
          trroce_high_reg <= trroce_high_reg + 32'd1;
        end
        trroce_overflow_bit <= trroce_high_reg[AXIL_DATA_WIDTH-1];
      end
    end
    else begin
      // Stop counting number of packet sent when overflow
      trroce_high_reg <= trroce_high_reg;
    end

    // trroce_no_reset_high_reg
    if(!trroce_no_reset_overflow_bit)
    begin
      if(trroce_no_reset_carry_bit)
      begin
        trroce_no_reset_high_reg <= trroce_no_reset_high_reg + 32'd1;
      end
      trroce_no_reset_overflow_bit <= trroce_no_reset_high_reg[AXIL_DATA_WIDTH-1];
    end
    else begin
      // Stop counting number of packet sent when overflow
      trroce_no_reset_high_reg <= trroce_no_reset_high_reg;
    end

    // trnonroce_high_reg
    if(!trnonroce_overflow_bit)
    begin
      if(s_axil_reg_rvalid && araddr==TRNONROCE_HIGH_REG)
      begin
        // Clear trnonroce_high_reg when the register has been read.
        trnonroce_high_reg    <= 32'd0;
      end
      else begin
        if(trnonroce_carry_bit)
        begin
          trnonroce_high_reg <= trnonroce_high_reg + 32'd1;
        end
        trnonroce_overflow_bit <= trnonroce_high_reg[AXIL_DATA_WIDTH-1];
      end
    end
    else begin
      // Stop counting number of packet sent when overflow
      trnonroce_high_reg <= trnonroce_high_reg;
    end

    // trnonroce_no_reset_high_reg
    if(!trnonroce_no_reset_overflow_bit)
    begin
      if(trnonroce_no_reset_carry_bit)
      begin
        trnonroce_no_reset_high_reg <= trnonroce_no_reset_high_reg + 32'd1;
      end
      trnonroce_no_reset_overflow_bit <= trnonroce_no_reset_high_reg[AXIL_DATA_WIDTH-1];
    end
    else begin
      // Stop counting number of packet sent when overflow
      trnonroce_no_reset_high_reg <= trnonroce_no_reset_high_reg;
    end    
  end
end

always_ff @(posedge axil_aclk)
begin
  if(!axil_arstn) begin
    rn_reg_ctl_timer <= 64'd0;
  end
  else begin
    rn_reg_ctl_timer <= rn_reg_ctl_timer + 64'd1;
  end
end

endmodule: rn_reg_control