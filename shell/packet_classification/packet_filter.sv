//==============================================================================
// Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
// SPDX-License-Identifier: MIT
//
//==============================================================================
//
//  packet_filter
//    - classifies different packet types into roce and non-roce packets, 
//      which will be later redirected to either RDMA engine or SmartNIC QDMA
//      subsystem
//==============================================================================
`timescale 1ns/1ps

module packet_filter #(
  parameter METADATA_WIDTH  = 263,
  parameter AXIS_DATA_WIDTH = 512,
  parameter AXIS_KEEP_WIDTH = 64,
  parameter AXIS_USER_WIDTH = 16
) (
  input   [METADATA_WIDTH-1:0] metadata_in,
  input                        metadata_in_valid,

  // Packet input in axi-streaming format
  input                        s_axis_tvalid,
  input  [AXIS_DATA_WIDTH-1:0] s_axis_tdata,
  input  [AXIS_KEEP_WIDTH-1:0] s_axis_tkeep,
  input  [AXIS_USER_WIDTH-1:0] s_axis_tuser_size,
  input                        s_axis_tlast,
  output                       s_axis_tready,
  
  // RoCEv2 packet output in axi-streaming format
  output                       m_axis_roce_tvalid,
  output [AXIS_DATA_WIDTH-1:0] m_axis_roce_tdata,
  output [AXIS_KEEP_WIDTH-1:0] m_axis_roce_tkeep,
  output [AXIS_USER_WIDTH-1:0] m_axis_roce_tuser_size,
  output                       m_axis_roce_tlast,
  input                        m_axis_roce_tready,

  // non-RoCEv2 packet output in axi-streaming format
  output                       m_axis_non_roce_tvalid,
  output [AXIS_DATA_WIDTH-1:0] m_axis_non_roce_tdata,
  output [AXIS_KEEP_WIDTH-1:0] m_axis_non_roce_tkeep,
  output [AXIS_USER_WIDTH-1:0] m_axis_non_roce_tuser_size,
  output                       m_axis_non_roce_tlast,
  input                        m_axis_non_roce_tready,

  // Metadata out is only valid when a packet is a RoCEv2 packet
  output  [METADATA_WIDTH-1:0] metadata_out,
  output                       metadata_out_valid,

  // pkt_filter_err[0] - non-RDMA FIFO overflow
  // pkt_filter_err[1] - RDMA FIFO overflow
  output logic [1:0]           pkt_filter_err,

  input axis_aclk,
  input axis_rstn
);


// Parameter declaration
localparam FIFO_WRITE_DEPTH = 512;

localparam FILTER_IDLE       = 2'b00;
localparam FILTER_WR_ROCE    = 2'b01;
localparam FILTER_WR_NONROCE = 2'b11;

logic [1:0] filter_state;
logic [1:0] filter_nextstate;

// Signals for metadata FIFO
logic meta_wr_en;
logic meta_rd_en;
logic meta_empty;

logic [METADATA_WIDTH-1:0] meta_out;
logic                      meta_out_valid;

// metadata structure
logic [31:0] meta_index;
logic [31:0] meta_ip_src;
logic [31:0] meta_ip_dst;
logic [15:0] meta_udp_sport;
logic [15:0] meta_udp_dport;
logic [4:0]  meta_opcode;
logic [15:0] meta_pktlen;
logic [31:0] meta_dma_length;
logic [31:0] meta_r_key;
logic        meta_se;
logic [23:0] meta_psn;
logic [23:0] meta_msn;
logic        meta_is_rdma;

// Signals for RDMA packet FIFO
logic rdma_pkt_wr_en;
logic rdma_pkt_rd_en;
logic rdma_pkt_empty;
logic rdma_pkt_almost_full;
logic rdma_pkt_prog_full;
logic [AXIS_DATA_WIDTH-1:0] rdma_pkt_fifo_out_tdata;
logic [AXIS_KEEP_WIDTH-1:0] rdma_pkt_fifo_out_tkeep;
logic [AXIS_USER_WIDTH-1:0] rdma_pkt_fifo_out_tuser_size;
logic                       rdma_pkt_fifo_out_tlast;

// Signals used to read RDMA packets out of FIFO
localparam READ_RDMA_IDLE = 1'b0;
localparam READ_RDMA      = 1'b1;

logic filter_rd_rdma_state;
logic filter_rd_rdma_nextstate;

// Signals for non-RDMA packet FIFO
logic non_rdma_pkt_wr_en;
logic non_rdma_pkt_rd_en;
logic non_rdma_pkt_empty;
logic non_rdma_pkt_almost_full;
logic non_rdma_pkt_prog_full;
logic [AXIS_DATA_WIDTH-1:0] non_rdma_pkt_fifo_out_tdata;
logic [AXIS_KEEP_WIDTH-1:0] non_rdma_pkt_fifo_out_tkeep;
logic [AXIS_USER_WIDTH-1:0] non_rdma_pkt_fifo_out_tuser_size;
logic                       non_rdma_pkt_fifo_out_tlast;

// Signals used to read non-RDMA packets out of FIFOs
localparam READ_NONRDMA_IDLE = 1'b0;
localparam READ_NONRDMA      = 1'b1;

logic filter_rd_nonrdma_state;
logic filter_rd_nonrdma_nextstate;

// Accept all packets from the network, as we can process it in line rate.
//assign s_axis_tready = !data_prog_full;
assign s_axis_tready   = 1'b1;

always_comb
begin
  meta_wr_en                  = 1'b0;
  rdma_pkt_wr_en              = 1'b0;
  non_rdma_pkt_wr_en          = 1'b0;
  filter_nextstate = filter_state;
  case(filter_state)
  FILTER_IDLE: begin
    if(s_axis_tvalid) begin
      // metadata_in[0] is metadata_is_rdma
      if(metadata_in[0] == 1'b1) begin
        // RDMA packet
        meta_wr_en = 1'b1;
        rdma_pkt_wr_en = 1'b1;
        if(s_axis_tlast) begin
          filter_nextstate = FILTER_IDLE;
        end
        else begin
          filter_nextstate = FILTER_WR_ROCE;
        end
      end
      else begin
        // Non-RDMA packet
        non_rdma_pkt_wr_en = 1'b1;
        if(s_axis_tlast) begin
          filter_nextstate = FILTER_IDLE;
        end
        else begin
          filter_nextstate = FILTER_WR_NONROCE;
        end
      end
    end
  end
  FILTER_WR_ROCE: begin
    if(s_axis_tvalid) begin
      rdma_pkt_wr_en = 1'b1;
      if(s_axis_tlast) begin
        filter_nextstate = FILTER_IDLE;
      end
      else begin
        filter_nextstate = FILTER_WR_ROCE;
      end
    end
    else begin
      filter_nextstate = FILTER_WR_ROCE;
    end
  end
  FILTER_WR_NONROCE: begin
    if(s_axis_tvalid) begin
      non_rdma_pkt_wr_en = 1'b1;
      if(s_axis_tlast) begin
        filter_nextstate = FILTER_IDLE;
      end
      else begin
        filter_nextstate = FILTER_WR_NONROCE;
      end
    end
    else begin
      filter_nextstate = FILTER_WR_NONROCE;
    end
  end
  default: filter_nextstate = FILTER_IDLE;
  endcase
end

always_ff @(posedge axis_aclk)
begin
  if(~axis_rstn) begin
    filter_state <= FILTER_IDLE;
  end
  else begin
    filter_state <= filter_nextstate;
  end
end

// Read rdma packets from rdma_pkt FIFO
always_comb
begin
  meta_rd_en     = 1'b0;
  rdma_pkt_rd_en = 1'b0;
  filter_rd_rdma_nextstate = filter_rd_rdma_state;
  case(filter_rd_rdma_state)
  READ_RDMA_IDLE: begin
    if(m_axis_roce_tready && !meta_empty && !rdma_pkt_empty) begin
      rdma_pkt_rd_en = 1'b1;
      meta_rd_en     = 1'b1;
      if(rdma_pkt_fifo_out_tlast != 1'b1) begin
        filter_rd_rdma_nextstate = READ_RDMA;
      end
      else begin
        filter_rd_rdma_nextstate = READ_RDMA_IDLE;
      end
    end
  end
  READ_RDMA: begin
    if(m_axis_roce_tready && !rdma_pkt_empty) begin
      rdma_pkt_rd_en = 1'b1;
      if(rdma_pkt_fifo_out_tlast != 1'b1) begin
        filter_rd_rdma_nextstate = READ_RDMA;
      end
      else begin
        filter_rd_rdma_nextstate = READ_RDMA_IDLE;
      end
    end
    else begin
      filter_rd_rdma_nextstate = READ_RDMA;
    end
  end
  endcase
end

always_ff @(posedge axis_aclk)
begin
  if(~axis_rstn) begin
    filter_rd_rdma_state <= READ_RDMA_IDLE;
  end
  else begin
    filter_rd_rdma_state <= filter_rd_rdma_nextstate;
  end
end

assign m_axis_roce_tvalid     = rdma_pkt_rd_en;
assign m_axis_roce_tdata      = rdma_pkt_rd_en ? rdma_pkt_fifo_out_tdata : {AXIS_DATA_WIDTH{1'b0}};
assign m_axis_roce_tkeep      = rdma_pkt_rd_en ? rdma_pkt_fifo_out_tkeep : {AXIS_KEEP_WIDTH{1'b0}};
assign m_axis_roce_tuser_size = rdma_pkt_rd_en ? rdma_pkt_fifo_out_tuser_size : {AXIS_USER_WIDTH{1'b0}};
assign m_axis_roce_tlast      = rdma_pkt_rd_en ? rdma_pkt_fifo_out_tlast : 1'd0;

assign metadata_out_valid     = meta_rd_en;
assign metadata_out           = meta_rd_en ? meta_out : {METADATA_WIDTH{1'b0}};

// Read non_rdma packets from non_rdma_pkt FIFO
always_comb
begin
  non_rdma_pkt_rd_en = 1'b0;
  filter_rd_nonrdma_nextstate = filter_rd_nonrdma_state;
  case(filter_rd_nonrdma_state)
  READ_NONRDMA_IDLE: begin
    if(m_axis_non_roce_tready && !non_rdma_pkt_empty) begin
      non_rdma_pkt_rd_en = 1'b1;
      if(non_rdma_pkt_fifo_out_tlast != 1'b1) begin
        filter_rd_nonrdma_nextstate = READ_NONRDMA;
      end
      else begin
        filter_rd_nonrdma_nextstate = READ_NONRDMA_IDLE;
      end
    end
  end
  READ_NONRDMA: begin
    if(m_axis_non_roce_tready && !non_rdma_pkt_empty) begin
      non_rdma_pkt_rd_en = 1'b1;
      if(non_rdma_pkt_fifo_out_tlast != 1'b1) begin
        filter_rd_nonrdma_nextstate = READ_NONRDMA;
      end
      else begin
        filter_rd_nonrdma_nextstate = READ_NONRDMA_IDLE;
      end
    end
    else begin
      filter_rd_nonrdma_nextstate = READ_NONRDMA;
    end
  end
  endcase
end

always_ff @(posedge axis_aclk)
begin
  if(~axis_rstn) begin
    filter_rd_nonrdma_state <= READ_NONRDMA_IDLE;
  end
  else begin
    filter_rd_nonrdma_state <= filter_rd_nonrdma_nextstate;
  end
end

assign m_axis_non_roce_tvalid     = non_rdma_pkt_rd_en;
assign m_axis_non_roce_tdata      = non_rdma_pkt_rd_en ? non_rdma_pkt_fifo_out_tdata : {AXIS_DATA_WIDTH{1'b0}};
assign m_axis_non_roce_tkeep      = non_rdma_pkt_rd_en ? non_rdma_pkt_fifo_out_tkeep : {AXIS_KEEP_WIDTH{1'b0}};
assign m_axis_non_roce_tuser_size = non_rdma_pkt_rd_en ? non_rdma_pkt_fifo_out_tuser_size : {AXIS_USER_WIDTH{1'b0}};
assign m_axis_non_roce_tlast      = non_rdma_pkt_rd_en ? non_rdma_pkt_fifo_out_tlast : 1'd0;

/* Write rdma_pkt and metadata into FIFOs */
xpm_fifo_sync #(
  .DOUT_RESET_VALUE    ("0"),
  .ECC_MODE            ("no_ecc"),
  .FIFO_MEMORY_TYPE    ("auto"),
  .FIFO_READ_LATENCY   (1),
  .FIFO_WRITE_DEPTH    (FIFO_WRITE_DEPTH),
  .PROG_FULL_THRESH    (FIFO_WRITE_DEPTH-5),
  .READ_DATA_WIDTH     (AXIS_DATA_WIDTH + AXIS_KEEP_WIDTH + AXIS_USER_WIDTH + 1),
  .READ_MODE           ("fwft"),
  .WRITE_DATA_WIDTH    (AXIS_DATA_WIDTH + AXIS_KEEP_WIDTH + AXIS_USER_WIDTH + 1)
) filter_rdma_pkt_fifo (
  .wr_en         (rdma_pkt_wr_en),
  .din           ({s_axis_tdata, s_axis_tkeep, s_axis_tuser_size, s_axis_tlast}),
  .wr_ack        (),
  .rd_en         (rdma_pkt_rd_en),
  .data_valid    (),
  .dout          ({rdma_pkt_fifo_out_tdata, rdma_pkt_fifo_out_tkeep, rdma_pkt_fifo_out_tuser_size, rdma_pkt_fifo_out_tlast}),

  .wr_data_count (),
  .rd_data_count (),

  .empty         (rdma_pkt_empty),
  .full          (),
  .almost_empty  (),
  .almost_full   (rdma_pkt_almost_full),
  .overflow      (),
  .underflow     (),
  .prog_empty    (),
  .prog_full     (rdma_pkt_prog_full),
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

// FIFO to store input metadata for RDMA packets
xpm_fifo_sync #(
  .DOUT_RESET_VALUE    ("0"),
  .ECC_MODE            ("no_ecc"),
  .FIFO_MEMORY_TYPE    ("auto"),
  .FIFO_READ_LATENCY   (1),
  .FIFO_WRITE_DEPTH    (FIFO_WRITE_DEPTH),
  .PROG_FULL_THRESH    (FIFO_WRITE_DEPTH-5),
  .READ_DATA_WIDTH     (METADATA_WIDTH),
  .READ_MODE           ("fwft"),
  .WRITE_DATA_WIDTH    (METADATA_WIDTH)
) filter_metadata_fifo (
  .wr_en         (meta_wr_en),
  .din           (metadata_in),
  .wr_ack        (),
  .rd_en         (meta_rd_en),
  .data_valid    (),
  .dout          (meta_out),

  .wr_data_count (),
  .rd_data_count (),

  .empty         (meta_empty),
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

/* Write non_rdma_pkt into a FIFO */
xpm_fifo_sync #(
  .DOUT_RESET_VALUE    ("0"),
  .ECC_MODE            ("no_ecc"),
  .FIFO_MEMORY_TYPE    ("auto"),
  .FIFO_READ_LATENCY   (1),
  .FIFO_WRITE_DEPTH    (FIFO_WRITE_DEPTH),
  .PROG_FULL_THRESH    (FIFO_WRITE_DEPTH-5),
  .READ_DATA_WIDTH     (AXIS_DATA_WIDTH + AXIS_KEEP_WIDTH + AXIS_USER_WIDTH + 1),
  .READ_MODE           ("fwft"),
  .WRITE_DATA_WIDTH    (AXIS_DATA_WIDTH + AXIS_KEEP_WIDTH + AXIS_USER_WIDTH + 1)
) filter_non_rdma_pkt_fifo (
  .wr_en         (non_rdma_pkt_wr_en),
  .din           ({s_axis_tdata, s_axis_tkeep, s_axis_tuser_size, s_axis_tlast}),
  .wr_ack        (),
  .rd_en         (non_rdma_pkt_rd_en),
  .data_valid    (),
  .dout          ({non_rdma_pkt_fifo_out_tdata, non_rdma_pkt_fifo_out_tkeep, non_rdma_pkt_fifo_out_tuser_size, non_rdma_pkt_fifo_out_tlast}),

  .wr_data_count (),
  .rd_data_count (),

  .empty         (non_rdma_pkt_empty),
  .full          (),
  .almost_empty  (),
  .almost_full   (non_rdma_pkt_almost_full),
  .overflow      (),
  .underflow     (),
  .prog_empty    (),
  .prog_full     (non_rdma_pkt_prog_full),
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
    pkt_filter_err <= 2'b0;
  end
  else begin
    if(non_rdma_pkt_prog_full) begin
      // Indicates that the modules connected can not process packets in line rate
      // Used for debug purpose
      pkt_filter_err[0] <= 1'b1;
    end

    if(rdma_pkt_prog_full) begin
      // Indicates that the modules connected can not process packets in line rate
      // Used for debug purpose
      pkt_filter_err[1] <= 1'b1;
    end
  end
end

assign meta_index      = !meta_empty ? meta_out[262:231] : 0;
assign meta_ip_src     = !meta_empty ? meta_out[230:199] : 0;
assign meta_ip_dst     = !meta_empty ? meta_out[198:167] : 0;
assign meta_udp_sport  = !meta_empty ? meta_out[166:151] : 0;
assign meta_udp_dport  = !meta_empty ? meta_out[150:135] : 0;
assign meta_opcode     = !meta_empty ? meta_out[134:130] : 0;
assign meta_pktlen     = !meta_empty ? meta_out[129:114] : 0;
assign meta_dma_length = !meta_empty ? meta_out[113: 82] : 0;
assign meta_r_key      = !meta_empty ? meta_out[81 : 50] : 0;
assign meta_se         = !meta_empty ? meta_out[49 : 49] : 0;
assign meta_psn        = !meta_empty ? meta_out[48 : 25] : 0;
assign meta_msn        = !meta_empty ? meta_out[24 :  1] : 0;
assign meta_is_rdma    = !meta_empty ? meta_out[0  :  0] : 0;

endmodule
