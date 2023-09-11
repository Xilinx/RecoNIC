//==============================================================================
// Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
// SPDX-License-Identifier: MIT
//
//==============================================================================
`timescale 1ns/1ps

module init_mem (
  input string tag_string,
  input string axi_mem_filename,

  output logic     [4:0] m_axi_init_awid,
  output logic  [63 : 0] m_axi_init_awaddr,
  output logic   [3 : 0] m_axi_init_awqos,
  output logic   [7 : 0] m_axi_init_awlen,
  output logic   [2 : 0] m_axi_init_awsize,
  output logic   [1 : 0] m_axi_init_awburst,
  output logic   [3 : 0] m_axi_init_awcache,
  output logic   [2 : 0] m_axi_init_awprot,
  output logic           m_axi_init_awvalid,
  input                  m_axi_init_awready,
  output logic [511 : 0] m_axi_init_wdata,
  output logic  [63 : 0] m_axi_init_wstrb,
  output logic           m_axi_init_wlast,
  output logic           m_axi_init_wvalid,
  input                  m_axi_init_wready,
  output logic           m_axi_init_awlock,
  input          [4 : 0] m_axi_init_bid,
  input          [1 : 0] m_axi_init_bresp,
  input                  m_axi_init_bvalid,
  output logic           m_axi_init_bready,

  output logic init_mem_done,

  input axis_clk,
  input axis_rstn
);

// Memory initialization for device or system memory
logic [31:0]  rn_axi_write_init;
logic         axi_write_init_end_of_file;
logic [63:0]  init_addr;
logic [511:0] init_payload;
logic [15:0]  init_payload_len;
logic         init_axi_write_vld;

// Buffer init_axi_bram_write command
logic [63:0] fifo_out_init_addr;
logic [511:0] fifo_out_init_payload;
logic [15:0] fifo_out_init_payload_len;
logic init_bram_wr_en;
logic init_bram_rd_en;
logic init_empty;
logic init_full;

// Generate AXI Write request
localparam AXI_IDLE         = 2'b00;
localparam AXI_WRITE_RSP    = 2'b01;
localparam AXI_WRITE_WREADY = 2'b11;
localparam AXI_INIT_DONE    = 2'b10;
localparam AXIS_KEEP_WIDTH  = 64;

logic [1:0] write_state;
logic [1:0] write_nextstate;

logic [63:0] aligned_write_addr;
logic [15:0] payload_len;
logic [31:0] start_idx;
logic [31:0] end_idx;

logic wr_rst_busy;

always_ff @(posedge axis_rstn) begin
  rn_axi_write_init <= $fopen($sformatf("%s.txt", axi_mem_filename), "r");
end

always_comb begin
  if(!rn_axi_write_init && !wr_rst_busy) begin
    //$fatal("INFO: [init_mem_%s] time=%t, no %s found. Please provide the required file", tag_string, $time, $sformatf("%s.txt", rn_axi_write_init));
    $display("INFO: [init_mem_%s] time=%t, no %s found. Please provide the required file", tag_string, $time, $sformatf("%s.txt", rn_axi_write_init));
  end
end

logic [31:0] timeout_cnt;
// run for 5ms
localparam TIMEOUT_NUM = 1000000;

always_ff @(posedge axis_clk) begin
  if(!axis_rstn) begin
    init_addr    <= 64'd0;
    init_payload <= 512'd0;
    init_payload_len <= 16'd0;
    init_axi_write_vld <= 1'b0;
    axi_write_init_end_of_file <= 1'b0;
    timeout_cnt <= 0;
  end
  else begin
    if(!wr_rst_busy) begin
      if (rn_axi_write_init) begin
        if(!axi_write_init_end_of_file) begin
          // file format: (address, payload, payload len in byte)
          if(32'd3 != $fscanf(rn_axi_write_init, "%x %x %x", init_addr, init_payload, init_payload_len)) begin
            init_addr <= 0;
            init_payload <= 0;
            init_payload_len <= 0;
            init_axi_write_vld <= 1'b0;
            axi_write_init_end_of_file <= 1'b1;
          end
          else begin
            init_axi_write_vld <= 1'b1;
          end
        end
        else begin
          init_addr <= 0;
          init_payload <= 0;
          init_payload_len <= 0;
          init_axi_write_vld <= 1'b0;
        end

        if (axi_write_init_end_of_file == 1'b1) begin
          if (timeout_cnt >= TIMEOUT_NUM) begin
            timeout_cnt <= 0;
            $finish;
          end

          timeout_cnt <= timeout_cnt + 1; 
        end
       end  
    end
    else begin
      init_addr    <= 64'd0;
      init_payload <= 512'd0;
      init_axi_write_vld <= 1'b0;
    end
  end
end

// Buffer init_axi_bram_write command
xpm_fifo_sync #(
  .DOUT_RESET_VALUE    ("0"),
  .ECC_MODE            ("no_ecc"),
  .FIFO_MEMORY_TYPE    ("auto"),
  .FIFO_READ_LATENCY   (1),
  .FIFO_WRITE_DEPTH    (8192),
  .PROG_FULL_THRESH    (),
  .READ_DATA_WIDTH     (64+512+16),
  .READ_MODE           ("fwft"),
  .WRITE_DATA_WIDTH    (64+512+16)
) init_axi_bram_fifo (
  .wr_en         (init_bram_wr_en),
  .din           ({init_addr, init_payload, init_payload_len}),
  .wr_ack        (),
  .rd_en         (init_bram_rd_en),
  .data_valid    (),
  .dout          ({fifo_out_init_addr, fifo_out_init_payload, fifo_out_init_payload_len}),

  .wr_data_count (),
  .rd_data_count (),

  .empty         (init_empty),
  .full          (init_full),
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

  .wr_clk        (axis_clk),
  .rst           (~axis_rstn),
  .rd_rst_busy   (),
  .wr_rst_busy   (wr_rst_busy)
);

assign init_bram_wr_en = init_axi_write_vld && !init_full;

// Generate AXI Write request
assign aligned_write_addr = {fifo_out_init_addr[63:6], 6'd0};
assign payload_len = fifo_out_init_payload_len;
assign start_idx = fifo_out_init_addr - aligned_write_addr;
assign end_idx   = fifo_out_init_addr + fifo_out_init_payload_len - aligned_write_addr;

always_comb begin
  m_axi_init_awaddr  = 0;
  m_axi_init_awlen   = 0;
  m_axi_init_awvalid = 0;

  m_axi_init_wdata   = 0;
  m_axi_init_wstrb   = 0;
  m_axi_init_wlast   = 1'b0;
  m_axi_init_wvalid  = 1'b0;

  m_axi_init_bready  = 1'b1;

  init_bram_rd_en = 1'b0;
  init_mem_done = 1'b0;
  write_nextstate = write_state;
  case(write_state)
  AXI_IDLE: begin
    if(!init_empty) begin
      m_axi_init_awaddr  = aligned_write_addr;
      m_axi_init_awlen   = payload_len[13:6] - 1;
      m_axi_init_awvalid = 1'b1;

      if (m_axi_init_awready) begin
        if (m_axi_init_wready) begin
          init_bram_rd_en = 1'b1;
          m_axi_init_wlast  = 1'b1;
          m_axi_init_wvalid = !init_empty;

          for(int i=0; i<AXIS_KEEP_WIDTH; i++) begin
            if((i>=start_idx) && (i<end_idx)) begin
              m_axi_init_wstrb[i] = 1'b1;
              m_axi_init_wdata[8*i +: 8] = fifo_out_init_payload[(i-start_idx)*8 +: 8];
            end
            else begin
              m_axi_init_wstrb[i] = 1'b0;
              m_axi_init_wdata[8*i +: 8] = 0;
            end
          end
          write_nextstate = AXI_WRITE_RSP;
        end
        else begin
          write_nextstate = AXI_WRITE_WREADY;
        end
      end
      else begin
        write_nextstate = AXI_IDLE;
      end
    end
    else begin
      if(axi_write_init_end_of_file == 1'b1) begin
        init_mem_done = 1'b1;
        write_nextstate = AXI_INIT_DONE;
      end
    end
  end
  AXI_WRITE_WREADY: begin
    // Wait for wready
    if (m_axi_init_wready) begin
      init_bram_rd_en = 1'b1;
      m_axi_init_wlast  = 1'b1;
      m_axi_init_wvalid = !init_empty;

      for(int i=0; i<AXIS_KEEP_WIDTH; i++) begin
        if((i>=start_idx) && (i<end_idx)) begin
          m_axi_init_wstrb[i] = 1'b1;
          m_axi_init_wdata[8*i +: 8] = fifo_out_init_payload[(i-start_idx)*8 +: 8];
        end
        else begin
          m_axi_init_wstrb[i] = 1'b0;
          m_axi_init_wdata[8*i +: 8] = 0;
        end
      end

      write_nextstate = AXI_WRITE_RSP;
    end
  end
  AXI_WRITE_RSP: begin
    if (m_axi_init_bvalid) begin
      // Start a new write request
      write_nextstate = AXI_IDLE;
    end
    else begin
      write_nextstate = AXI_WRITE_RSP;
    end

    if((axi_write_init_end_of_file == 1'b1) && init_empty) begin
      init_mem_done = 1'b1;
      write_nextstate = AXI_INIT_DONE;
    end
  end
  AXI_INIT_DONE: begin
    write_nextstate = AXI_INIT_DONE;
    init_mem_done = 1'b1;
    $display("INFO: [init_mem_%s] time=%t, Memory is initialized", tag_string, $time);
  end
  default: write_nextstate = AXI_IDLE;
  endcase
end

// Set default values to specific signals
assign m_axi_init_awid    = 5'd0;
assign m_axi_init_awsize  = 3'b110;
assign m_axi_init_awburst = 2'b01; // INCR mode
assign m_axi_init_awlock  = 1'b0;
assign m_axi_init_awcache = 4'd0;
assign m_axi_init_awprot  = 3'd0;
assign m_axi_init_awqos   = 4'd0;

always_ff @(posedge axis_clk) begin
  if(!axis_rstn) begin
    write_state <= AXI_IDLE;
  end
  else begin
    write_state <= write_nextstate;
  end
end

endmodule: init_mem