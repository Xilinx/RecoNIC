//==============================================================================
// Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
// SPDX-License-Identifier: MIT
//
//==============================================================================
//
//
// Self-checking items:
//   1. For data written into system and device memory: to compare data read from memory
//                       - issue axi read to system and device memory and compare output
//                         data with golden data from files provided by python
//   2. For rdma/non-rdma packets: to compare packets with golden data from files
//                       - in progress
//
//
//==============================================================================
`timescale 1ns/1ps

module rn_tb_checker #(
  parameter AXIS_DATA_WIDTH = 512,
  parameter AXIS_KEEP_WIDTH = 64
)(
  input string golden_resp_filename,
  input string axi_dev_read_filename,
  input string axi_sys_read_filename,
  // golden input data
  input [AXIS_DATA_WIDTH-1:0] golden_axis_tdata,
  input [AXIS_KEEP_WIDTH-1:0] golden_axis_tkeep,
  input                       golden_axis_tvalid,
  input                       golden_axis_tlast,
  input [31:0]                golden_num_pkt,

  // non-roce result from rn_dut
  input [AXIS_DATA_WIDTH-1:0] s_axis_tdata,
  input [AXIS_KEEP_WIDTH-1:0] s_axis_tkeep,
  input                       s_axis_tvalid,
  input                       s_axis_tlast,
  output                      s_axis_tready,

  // roce result from rn_dut
  input [AXIS_DATA_WIDTH-1:0] s_axis_roce_tdata,
  input [AXIS_KEEP_WIDTH-1:0] s_axis_roce_tkeep,
  input                       s_axis_roce_tvalid,
  input                       s_axis_roce_tlast,

  // AXI MM read interface to verify device memory
  output       [4 :0] m_axi_veri_dev_arid,
  output logic [63:0] m_axi_veri_dev_araddr,
  output logic [7 :0] m_axi_veri_dev_arlen,
  output       [2 :0] m_axi_veri_dev_arsize,
  output       [1 :0] m_axi_veri_dev_arburst,
  output              m_axi_veri_dev_arlock,
  output       [3 :0] m_axi_veri_dev_arcache,
  output       [2 :0] m_axi_veri_dev_arprot,
  output logic        m_axi_veri_dev_arvalid,
  input               m_axi_veri_dev_arready,
  input        [4 :0] m_axi_veri_dev_rid,
  input       [511:0] m_axi_veri_dev_rdata,
  input        [1 :0] m_axi_veri_dev_rresp,
  input               m_axi_veri_dev_rlast,
  input               m_axi_veri_dev_rvalid,
  output logic        m_axi_veri_dev_rready,

  // AXI MM read interface to verify system memory
  output       [2 :0] m_axi_veri_sys_arid,
  output logic [63:0] m_axi_veri_sys_araddr,
  output logic [7 :0] m_axi_veri_sys_arlen,
  output       [2 :0] m_axi_veri_sys_arsize,
  output       [1 :0] m_axi_veri_sys_arburst,
  output              m_axi_veri_sys_arlock,
  output       [3 :0] m_axi_veri_sys_arcache,
  output       [2 :0] m_axi_veri_sys_arprot,
  output logic        m_axi_veri_sys_arvalid,
  input               m_axi_veri_sys_arready,
  input        [2 :0] m_axi_veri_sys_rid,
  input       [511:0] m_axi_veri_sys_rdata,
  input        [1 :0] m_axi_veri_sys_rresp,
  input               m_axi_veri_sys_rlast,
  input               m_axi_veri_sys_rvalid,
  output logic        m_axi_veri_sys_rready,

  input     [160-1:0] sys_pc_status,
  input               sys_pc_asserted,
  input               sys_mem_init_done,

  input     [160-1:0] dev_pc_status,
  input               dev_pc_asserted,
  input               dev_mem_init_done,

  output              golden_data_loaded,

  input axis_clk,
  input axis_rstn
);

function integer log2;
  input integer number;
  begin
    log2 = 0;
    while(2**log2 < number)
    begin
      log2 = log2 + 1;
    end
  end
endfunction

localparam MAGIC_NUM = 10;

logic [63:0] pkt_cnt;
logic [63:0] noise_pkt_cnt;
logic [63:0] pkt_cnt_golden;
logic [63:0] golden_pkt_cnt_feedback;
logic        packet_mismatch;
logic        is_get_pkt;
logic [63:0] wait_cnt;
logic        wait_to_be_finished;
logic        packet_mismatch_delay;
logic [AXIS_DATA_WIDTH-1:0]  expected_axis_tdata_reg;
logic [AXIS_KEEP_WIDTH-1 :0] expected_axis_tkeep_reg;
logic                        expected_axis_tlast_reg;
logic  [AXIS_DATA_WIDTH-1:0] captured_axis_tdata_reg;
logic [AXIS_KEEP_WIDTH-1 :0] captured_axis_tkeep_reg;
logic                        captured_axis_tlast_reg;
logic  [AXIS_DATA_WIDTH-1:0] captured_axis_roce_tdata_reg;
logic [AXIS_KEEP_WIDTH-1 :0] captured_axis_roce_tkeep_reg;
logic                        captured_axis_roce_tlast_reg;
logic [63 :0] idx_mismatch;

logic [31:0] reset_cnt;
logic        reset_done;

logic start_read;

// Maximum size of xpm_fifo_sync
localparam FIFO_WRITE_DEPTH = 1<<17;
//localparam RD_DATA_COUNT_WIDTH = log2(FIFO_WRITE_DEPTH)+1;

wire wr_en_golden_get_req;
wire rd_en_golden_get_req;
wire wr_rst_busy;
wire rd_rst_busy;

logic [AXIS_DATA_WIDTH-1:0] golden_axis_non_roce_tvalid;
logic [AXIS_DATA_WIDTH-1:0] golden_axis_non_roce_tdata;
logic [AXIS_KEEP_WIDTH-1:0] golden_axis_non_roce_tkeep;
logic                       golden_axis_non_roce_tlast;

logic [AXIS_DATA_WIDTH-1:0] golden_axis_tdata_fifo_out;
logic [AXIS_KEEP_WIDTH-1:0] golden_axis_tkeep_fifo_out;
logic                       golden_axis_tlast_fifo_out;

localparam IDLE   = 2'b00;
localparam WRITE  = 2'b01;
localparam BYPASS = 2'b10;
logic [1:0] state, nextstate;
logic noise_pkt;

logic wr_golden_axis_pkt;
logic rd_golden_axis_pkt;
logic golden_pkt_full;
logic golden_pkt_empty;

logic [511:0] axi_captured_data;
logic         start_comparison;
logic         axi_data_mismatch;
logic  [31:0] axi_read_cnt;

// Signals used for verifying system memory
logic start_axi_veri_sys_read;
logic sys_axi_read_passed;

// Signals used for verifying device memory
logic start_axi_veri_dev_read;
logic dev_axi_read_passed;

logic [1:0] two_unused_bits0;


initial begin
  start_read = 1'b0;
  #10;
  start_read = 1'b1;
end

// Buffer golden non-roce input data
// noise roce packet has "cdabefbeadde" as its destination mac address.
// Accordingly, the filter_pattern will be "deadbeefabcd"
localparam [47:0] filter_pattern = 48'hdeadbeefabcd;
always_comb begin
  noise_pkt = 1'b0;
  golden_axis_non_roce_tvalid = 1'b0;
  golden_axis_non_roce_tdata  = 0;
  golden_axis_non_roce_tkeep  = 0;
  golden_axis_non_roce_tlast  = 1'b0;
  nextstate = state;
  case(state)
  IDLE: begin
    if(golden_axis_tvalid) begin
      if (golden_axis_tdata[47:0] == filter_pattern) begin
        if(!golden_axis_tlast) begin
          nextstate = BYPASS;
        end
        else begin
          nextstate = IDLE;
        end
        noise_pkt = 1'b1;
        golden_axis_non_roce_tvalid = 1'b0;
      end
      else begin
        golden_axis_non_roce_tvalid = 1'b1;
        golden_axis_non_roce_tdata  = golden_axis_tdata;
        golden_axis_non_roce_tkeep  = golden_axis_tkeep;
        golden_axis_non_roce_tlast  = golden_axis_tlast;
        if(golden_axis_tlast) begin
          nextstate = IDLE;
        end
        else begin
          nextstate = WRITE;
        end
      end
    end
  end
  WRITE: begin
    if(golden_axis_tvalid) begin
      golden_axis_non_roce_tvalid = 1'b1;
      golden_axis_non_roce_tdata  = golden_axis_tdata;
      golden_axis_non_roce_tkeep  = golden_axis_tkeep;
      golden_axis_non_roce_tlast  = golden_axis_tlast;
      if(golden_axis_tlast) begin
        nextstate = IDLE;
      end
    end
  end
  BYPASS: begin
    if(golden_axis_tvalid && golden_axis_tlast) begin
      nextstate = IDLE;
    end
    else begin
      nextstate = BYPASS;
    end
  end
  default: begin
    nextstate = IDLE;
  end
  endcase
end

always_ff @(posedge axis_clk)
begin
  if (!axis_rstn) begin
    state <= IDLE;
  end
  else begin
    state <= nextstate;
  end
end

xpm_fifo_sync #(
  .DOUT_RESET_VALUE    ("0"),
  .ECC_MODE            ("no_ecc"),
  .FIFO_MEMORY_TYPE    ("auto"),
  .FIFO_READ_LATENCY   (1),
  .FIFO_WRITE_DEPTH    (FIFO_WRITE_DEPTH),
  .PROG_FULL_THRESH    (),
  .READ_DATA_WIDTH     (577),
  .READ_MODE           ("fwft"),
  .WRITE_DATA_WIDTH    (577)
) golden_axis_non_roce_pkt_fifo (
  .wr_en         (wr_golden_axis_pkt),
  .din           ({golden_axis_non_roce_tdata, golden_axis_non_roce_tkeep, golden_axis_non_roce_tlast}),
  .wr_ack        (),
  .rd_en         (rd_golden_axis_pkt),
  .data_valid    (),
  .dout          ({golden_axis_tdata_fifo_out, golden_axis_tkeep_fifo_out, golden_axis_tlast_fifo_out}),

  .wr_data_count (),
  .rd_data_count (),

  .empty         (golden_pkt_empty),
  .full          (golden_pkt_full),
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
  .wr_rst_busy   ()
);

always_ff @(posedge golden_pkt_full) begin
  $fatal("ERROR: [rn_tb_checker] size of golden_axis_pkt_fifo is too small for input stimulus. Please increase its size");  
end

assign wr_golden_axis_pkt = golden_axis_non_roce_tvalid && !golden_pkt_full;
assign rd_golden_axis_pkt = s_axis_tready && s_axis_tvalid && !golden_pkt_empty;

always_comb begin
  packet_mismatch = 1'b0;
  if(s_axis_tvalid && s_axis_tready) begin
    packet_mismatch = !((golden_axis_tdata_fifo_out==s_axis_tdata) && (golden_axis_tkeep_fifo_out==s_axis_tkeep) && (golden_axis_tlast_fifo_out==s_axis_tlast));
  end
end

always_ff @(posedge axis_clk) begin
  if(!axis_rstn) begin
    idx_mismatch <= 0;
    packet_mismatch_delay <= 1'b0;
    expected_axis_tdata_reg <= 0;
    expected_axis_tkeep_reg <= 0;
    expected_axis_tlast_reg <= 0;
    captured_axis_tdata_reg <= 0;
    captured_axis_tkeep_reg <= 0;
    captured_axis_tlast_reg <= 0;
    captured_axis_roce_tdata_reg <= 0;
    captured_axis_roce_tkeep_reg <= 0;
    captured_axis_roce_tlast_reg <= 0;
  end
  else begin
    if(packet_mismatch) begin
      idx_mismatch          <= pkt_cnt;
      packet_mismatch_delay <= 1'b1;
      expected_axis_tdata_reg <= golden_axis_tdata_fifo_out;
      expected_axis_tkeep_reg <= golden_axis_tkeep_fifo_out;
      expected_axis_tlast_reg <= golden_axis_tlast_fifo_out;

      captured_axis_tdata_reg <= s_axis_tdata;
      captured_axis_tkeep_reg <= s_axis_tkeep;
      captured_axis_tlast_reg <= s_axis_tlast;

      captured_axis_roce_tdata_reg <= s_axis_roce_tdata;
      captured_axis_roce_tkeep_reg <= s_axis_roce_tkeep;
      captured_axis_roce_tlast_reg <= s_axis_roce_tlast;      
    end

    if(packet_mismatch_delay) begin
      $fatal("ERROR: [rn_tb_checker] time=%0t, the %d-th packet is mismatched. \n - Expected           (tlast, tkeep, tdata) = (%x, %x, %x)\n - Captured non-RoCEv2(tlast, tkeep, tdata) = (%x, %x, %x)\n", $time, idx_mismatch, expected_axis_tlast_reg, expected_axis_tkeep_reg, expected_axis_tdata_reg, captured_axis_tlast_reg, captured_axis_tkeep_reg, captured_axis_tdata_reg);
    end
  end
end

always_ff @(posedge axis_clk) begin
  if (!axis_rstn) begin
    wait_cnt                <= 0;
    wait_to_be_finished     <= 1'b0;
    //start_axi_veri_sys_read <= 1'b0;
    //start_axi_veri_dev_read <= 1'b0;
  end
  else begin
    if(!wait_to_be_finished && ((pkt_cnt == (pkt_cnt_golden-noise_pkt_cnt)) && (pkt_cnt_golden != 0)) && !packet_mismatch && sys_axi_read_passed && dev_axi_read_passed) begin
      $display("INFO: [rn_tb_checker] time=%0t, Number of packets received = %d", $time, pkt_cnt);
      $display("INFO: [rn_tb_checker] time=%0t, SUCCESS - Simulation is passed!", $time);

      wait_to_be_finished <= 1'b1;
    end

    // Add delay to allow data_mover to send all axi-mm transactions
    if(wait_to_be_finished) begin
      wait_cnt <= wait_cnt + 1;
      if(wait_cnt > MAGIC_NUM*pkt_cnt) begin
        //start_axi_veri_dev_read <= 1'b1;
        //start_axi_veri_sys_read <= 1'b1;
        $finish;
      end
    end
  end
end

// TODO: termination condition will be updated based on what we try to verify.
// Terminate the simulation when sys_mem and dev_mem verification are done
/*
always_comb begin
  if (sys_axi_read_passed && dev_axi_read_passed) begin
    $display("INFO: [rn_tb_checker] time=%0t, SUCCESS - Simulation is passed!", $time);
    $finish;
  end
end
*/

always_ff @(posedge axis_clk) begin
  if (!axis_rstn) begin
    start_axi_veri_sys_read <= 1'b0;
    start_axi_veri_dev_read <= 1'b0;
  end
  else begin
    if (sys_mem_init_done) begin
      start_axi_veri_sys_read <= 1'b1;
    end

    if (dev_mem_init_done) begin
      start_axi_veri_dev_read <= 1'b1;
    end
  end
end

always_ff @(posedge axis_clk) begin
  if(!axis_rstn) begin
    pkt_cnt <= 0;
    pkt_cnt_golden <= 0;
    noise_pkt_cnt  <= 0;
  end
  else begin
    if(s_axis_tvalid && s_axis_tlast) begin
      pkt_cnt <= pkt_cnt + 1;
    end
    if(golden_axis_tvalid && golden_axis_tlast) begin
      pkt_cnt_golden <= pkt_cnt_golden + 1;
    end

    if(noise_pkt) begin
      noise_pkt_cnt <= noise_pkt_cnt + 1;
    end
  end
end

always_ff @(posedge axis_clk) begin
  if(!axis_rstn) begin
    reset_cnt  <= 0;
    reset_done <= 1'b0;
  end
  else begin
    if(!reset_done) begin
      reset_cnt <= reset_cnt + 1;
    end
    if(reset_cnt > 10) begin
      reset_done <= 1'b1;
    end
  end
end

assign s_axis_tready = 1'b1;

axi_read_verify axi_read_verify_sys_mem (
  .tag_string        ("sys"),
  .axi_read_filename (axi_sys_read_filename),

  // AXI MM read interface to verify system memory
  .m_axi_arid        ({two_unused_bits0,m_axi_veri_sys_arid}),
  .m_axi_araddr      (m_axi_veri_sys_araddr),
  .m_axi_arlen       (m_axi_veri_sys_arlen),
  .m_axi_arsize      (m_axi_veri_sys_arsize),
  .m_axi_arburst     (m_axi_veri_sys_arburst),
  .m_axi_arlock      (m_axi_veri_sys_arlock),
  .m_axi_arcache     (m_axi_veri_sys_arcache),
  .m_axi_arprot      (m_axi_veri_sys_arprot),
  .m_axi_arvalid     (m_axi_veri_sys_arvalid),
  .m_axi_arready     (m_axi_veri_sys_arready),
  .m_axi_rid         ({2'd0,m_axi_veri_sys_rid}),
  .m_axi_rdata       (m_axi_veri_sys_rdata),
  .m_axi_rresp       (m_axi_veri_sys_rresp),
  .m_axi_rlast       (m_axi_veri_sys_rlast),
  .m_axi_rvalid      (m_axi_veri_sys_rvalid),
  .m_axi_rready      (m_axi_veri_sys_rready),

  .start_axi_read    (start_axi_veri_sys_read),
  .axi_read_passed   (sys_axi_read_passed),

  .axis_clk          (axis_clk),
  .axis_rstn         (axis_rstn)
);

axi_read_verify axi_read_verify_dev_mem (
  .tag_string        ("dev"),
  .axi_read_filename (axi_dev_read_filename),

  // AXI MM read interface to verify device memory
  .m_axi_arid        (m_axi_veri_dev_arid),
  .m_axi_araddr      (m_axi_veri_dev_araddr),
  .m_axi_arlen       (m_axi_veri_dev_arlen),
  .m_axi_arsize      (m_axi_veri_dev_arsize),
  .m_axi_arburst     (m_axi_veri_dev_arburst),
  .m_axi_arlock      (m_axi_veri_dev_arlock),
  .m_axi_arcache     (m_axi_veri_dev_arcache),
  .m_axi_arprot      (m_axi_veri_dev_arprot),
  .m_axi_arvalid     (m_axi_veri_dev_arvalid),
  .m_axi_arready     (m_axi_veri_dev_arready),
  .m_axi_rid         (m_axi_veri_dev_rid),
  .m_axi_rdata       (m_axi_veri_dev_rdata),
  .m_axi_rresp       (m_axi_veri_dev_rresp),
  .m_axi_rlast       (m_axi_veri_dev_rlast),
  .m_axi_rvalid      (m_axi_veri_dev_rvalid),
  .m_axi_rready      (m_axi_veri_dev_rready),

  .start_axi_read    (start_axi_veri_dev_read),
  .axi_read_passed   (dev_axi_read_passed),
  
  .axis_clk          (axis_clk),
  .axis_rstn         (axis_rstn)
);

logic [160-1:0] sys_pc_status_reg;
logic           sys_pc_asserted_reg;
always_ff @(posedge axis_clk)
begin
  if(!axis_rstn) begin
    sys_pc_status_reg   <= 160'd0;
    sys_pc_asserted_reg <= 1'b0;
  end
  else begin
    if(sys_pc_asserted_reg==1'b0 && sys_pc_asserted==1'b1) begin
      sys_pc_asserted_reg <= 1'b1;
      sys_pc_status_reg   <= sys_pc_status;
    end
  end
end

always_comb begin
  if(sys_pc_asserted_reg) begin
    $fatal("INFO: [rn_tb_checker] time=%0t, warning or error is detected with sys_pc_status = %h", $time, sys_pc_status_reg);
  end
end

logic [160-1:0] dev_pc_status_reg;
logic           dev_pc_asserted_reg;
always_ff @(posedge axis_clk)
begin
  if(!axis_rstn) begin
    dev_pc_status_reg   <= 160'd0;
    dev_pc_asserted_reg <= 1'b0;
  end
  else begin
    if(dev_pc_asserted_reg==1'b0 && dev_pc_asserted==1'b1) begin
      dev_pc_asserted_reg <= 1'b1;
      dev_pc_status_reg   <= dev_pc_status;
    end
  end
end

always_comb begin
  if(dev_pc_asserted_reg) begin
    $fatal("INFO: [rn_tb_checker] time=%0t, warning or error is detected with dev_pc_status = %h", $time, dev_pc_status_reg);
  end
end

endmodule: rn_tb_checker