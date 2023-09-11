//==============================================================================
// Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
// SPDX-License-Identifier: MIT
//
//==============================================================================
`timescale 1ns/1ps

module axi_read_verify (
  input string tag_string,
  input string axi_read_filename,

  // AXI MM read interface to verify memory
  output       [4 :0] m_axi_arid,
  output logic [63:0] m_axi_araddr,
  output logic [7 :0] m_axi_arlen,
  output       [2 :0] m_axi_arsize,
  output       [1 :0] m_axi_arburst,
  output              m_axi_arlock,
  output       [3 :0] m_axi_arcache,
  output       [2 :0] m_axi_arprot,
  output logic        m_axi_arvalid,
  input               m_axi_arready,
  input        [4 :0] m_axi_rid,
  input       [511:0] m_axi_rdata,
  input        [1 :0] m_axi_rresp,
  input               m_axi_rlast,
  input               m_axi_rvalid,
  output logic        m_axi_rready,

  input               start_axi_read,
  output logic        axi_read_passed,

  input axis_clk,
  input axis_rstn
);

logic   [31:0] rn_axi_read;
logic          axi_read_end_of_file;
logic   [63:0] read_address;
logic  [511:0] read_golden_data;
logic   [15:0] read_length;
logic          read_vld;
logic          read_next_item;
logic          axi_data_mismatch;

localparam    READ_IDLE = 2'b00;
localparam    READ_DATA = 2'b01;
localparam    WAIT_NEXT = 2'b11;
logic  [1 :0] rd_state, rd_nextstate;
logic  [63:0] aligned_read_addr;
logic  [31:0] start_idx;
logic  [31:0] end_idx;

logic [511:0] axi_captured_data_reg;
logic         start_comparison;
logic         start_first_read;
logic         start_axi_read_delay;
logic  [31:0] axi_read_cnt;

// Read data from AXI BRAM via AXI-MM
always_ff @(posedge axis_rstn) begin
  rn_axi_read <= $fopen($sformatf("%s.txt", axi_read_filename), "r");
end

always_ff @(posedge axis_clk) begin
  if(!axis_rstn) begin
    axi_read_end_of_file <= 1'b0;
    read_address     <= 0;
    read_golden_data <= 0;
    read_length      <= 0;
    read_vld    <= 1'b0;
  end
  else begin
    if(start_axi_read) begin
      if(rn_axi_read) begin
        if(!axi_read_end_of_file && (start_first_read || read_next_item)) begin
          if(32'd3 != $fscanf(rn_axi_read, "%x %x %x", read_address, read_golden_data, read_length)) begin
            read_address     <= 0;
            read_golden_data <= 0;
            read_length      <= 0;
            read_vld         <= 1'b0;
            axi_read_end_of_file <= 1'b1;  
          end
          else begin
            // Valid data
            read_vld <= 1'b1;
          end
        end
      end
      else begin
        $display("INFO: [rn_tb_checker] time=%t, no %s.txt - No need to check AXI-MM read/write", $time, $sformatf("%s.txt", axi_read_filename));
        $finish;
      end
    end
    else begin
      // Set default value to read information
      read_address     <= 0;
      read_golden_data <= 0;
      read_length      <= 0;
      read_vld    <= 1'b0;
    end
  end
end

// AXI-MM Read operations
assign aligned_read_addr = {read_address[63:6], 6'd0};
assign start_idx         = read_address - aligned_read_addr;
assign end_idx           = read_address+read_length-aligned_read_addr;

always_comb
begin
  m_axi_araddr  = 0;
  m_axi_arlen   = 0;
  m_axi_arvalid = 1'b0;
  m_axi_rready  = 1'b0;

  rd_nextstate = rd_state;
  case(rd_state)
    READ_IDLE: begin
      if (start_axi_read && read_vld) begin
        m_axi_araddr  = aligned_read_addr;
        m_axi_arlen   = read_length[13:6] - 1;
        m_axi_arvalid = 1'b1;
        if (m_axi_arready) begin
          rd_nextstate = READ_DATA;
        end
      end
      else begin
        rd_nextstate = READ_IDLE;
      end
    end
    READ_DATA: begin
      if (m_axi_rvalid && m_axi_rlast) begin
        m_axi_rready = 1'b1;
        if (read_next_item) begin
          rd_nextstate = READ_IDLE;
        end
        else begin
          rd_nextstate = WAIT_NEXT;
        end
      end
    end
    WAIT_NEXT: begin
      if(read_next_item) begin
        rd_nextstate = READ_IDLE;
      end
    end
    default: begin
      rd_nextstate = READ_IDLE;
    end
  endcase
end

always_ff @(posedge axis_clk)
begin
  if (!axis_rstn) begin
    start_comparison     <= 1'b0;
    axi_data_mismatch    <= 1'b0;
    start_axi_read_delay <= 1'b0;
    read_next_item       <= 1'b0;
    axi_read_cnt         <= 0;
    rd_state <= READ_IDLE;
  end 
  else begin
    start_comparison  <= 1'b0;
    read_next_item    <= 1'b0;
    start_axi_read_delay <= start_axi_read;

    if((rd_state==READ_DATA) && m_axi_rvalid) begin
      start_comparison  <= 1'b1;
      axi_captured_data_reg <= m_axi_rdata;
    end

    if(start_comparison) begin
      axi_data_mismatch <= !(axi_captured_data_reg == read_golden_data);
      read_next_item    <= 1'b1;
    end

    rd_state <= rd_nextstate;

    axi_read_cnt <= read_next_item ? axi_read_cnt + 1 : axi_read_cnt;
  end
end

always_comb begin
  if(start_axi_read && axi_data_mismatch) begin
    $fatal("ERROR: [rn_tb_checker] time=%t, axi read (the %d-th data) for %s_mem is mismatched - expected = %x, captured =%x", $time, axi_read_cnt, tag_string, read_golden_data, axi_captured_data_reg);
  end

  if(axi_read_end_of_file && !axi_data_mismatch) begin
    $display("INFO: [rn_tb_checker] time=%0t, SUCCESS - Simulation for axi-mm read for %s_mem is passed!", $time, tag_string);
  end
end

// Set default values to specific signals
assign m_axi_arid    = 5'd0;
assign m_axi_arsize  = 3'b110; // 64 bytes per beat
assign m_axi_arburst = 2'b01;  // INCR mode
assign m_axi_arlock  = 1'b0;
assign m_axi_arcache = 4'd0;
assign m_axi_arprot  = 3'd0;

assign start_first_read = start_axi_read^start_axi_read_delay;

assign axi_read_passed = axi_read_end_of_file && !axi_data_mismatch;

endmodule: axi_read_verify