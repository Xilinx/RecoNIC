//==============================================================================
// Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
// SPDX-License-Identifier: MIT
//
//==============================================================================
//
// packet_matcher
//   - provides lookup and match operations for each incoming packets
//   - format of a matching table entry: 
//       <32-bit sfa, 2-bit pktid_ext, 5-bit idx_ext> -> 32-bit start address
//
//==============================================================================
`timescale 1ns/1ps

module packet_matcher #(
  parameter METADATA_WIDTH_IN  = 203,
  parameter METADATA_WIDTH_OUT = 235,
  parameter AXIS_DATA_WIDTH    = 512,
  parameter AXIS_KEEP_WIDTH    = 64
) (
  // interface to configure the table
  input                    [31:0] sfa_in,
  input                     [1:0] pktid_ext_in,
  input                     [4:0] idx_ext_in,
  input                    [31:0] start_addr_in,
  input                     [7:0] config_op_in,
  input                           config_in_vld,

  input    [METADATA_WIDTH_IN-1:0] metadata_in,
  input                            metadata_in_valid,
  output  [METADATA_WIDTH_OUT-1:0] metadata_out,
  output                           metadata_out_valid,

   // AXI Slave port
  input                        s_axis_tvalid,
  input  [AXIS_DATA_WIDTH-1:0] s_axis_tdata,
  input  [AXIS_KEEP_WIDTH-1:0] s_axis_tkeep,
  input                        s_axis_tlast,
  output                       s_axis_tready,
  // AXI Master port
  output                       m_axis_tvalid,
  output [AXIS_DATA_WIDTH-1:0] m_axis_tdata,
  output [AXIS_KEEP_WIDTH-1:0] m_axis_tkeep,
  output                       m_axis_tlast,
  input                        m_axis_tready,

  input                        axis_aclk,
  input                        axis_rstn
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

localparam FIFO_WRITE_DEPTH = 64;

// Table configuration cdc signals
logic [31:0] sfa_cdc       [1:0];
logic  [1:0] pktid_ext_cdc [1:0];
logic  [4:0] idx_ext_cdc   [1:0];
logic [31:0] start_addr_cdc[1:0];
logic  [7:0] config_op_cdc [1:0];
logic  [1:0] config_vld_cdc;

logic [31:0] sfa_200mhz;
logic  [1:0] pktid_ext_200mhz;
logic  [4:0] idx_ext_200mhz;
logic [31:0] start_addr_200mhz;
logic  [7:0] config_op_200mhz;
logic  [1:0] config_vld_200mhz;

logic [31:0] fifo_out_sfa;
logic  [1:0] fifo_out_pktid_ext;
logic  [4:0] fifo_out_idx_ext;
logic [31:0] fifo_out_start_addr;
logic  [7:0] fifo_out_config_op;
logic  [1:0] fifo_out_config_vld;

// Buffer table configuration request in a FIFO
(* mark_debug = "true" *) logic req_wr_en;
(* mark_debug = "true" *) logic req_rd_en;
(* mark_debug = "true" *) logic req_empty;
(* mark_debug = "true" *) logic req_full;

// metadata input/output
logic [31:0] meta_in_index;
logic [31:0] meta_in_sfa;
logic [31:0] meta_in_dfa;
logic [1:0]  meta_in_pktid_ext;
logic [4:0]  meta_in_idx_ext;
logic [7:0]  meta_in_pkt_type;
logic [15:0] meta_in_pktlen;
logic [55:0] meta_in_remote_offs;
logic [5:0]  meta_in_return_code;
logic [1:0]  meta_in_ptl_list;
logic [11:0] meta_in_response_len;

logic  [31:0] meta_out_index;
logic  [31:0] meta_out_sfa;
logic  [31:0] meta_out_dfa;
logic  [1:0]  meta_out_pktid_ext;
logic  [4:0]  meta_out_idx_ext;
logic  [7:0]  meta_out_pkt_type;
logic  [15:0] meta_out_pktlen;
logic  [31:0] meta_out_start_addr;
logic  [55:0] meta_out_remote_offs;
logic  [5:0]  meta_out_return_code;
logic  [1:0]  meta_out_ptl_list;
logic  [11:0] meta_out_response_len;

assign req_wr_en = config_vld_200mhz;

xpm_fifo_sync #(
  .DOUT_RESET_VALUE    ("0"),
  .ECC_MODE            ("no_ecc"),
  .FIFO_MEMORY_TYPE    ("auto"),
  .FIFO_READ_LATENCY   (1),
  .FIFO_WRITE_DEPTH    (FIFO_WRITE_DEPTH),
  //.PROG_FULL_THRESH    (0),
  .READ_DATA_WIDTH     (79),
  .READ_MODE           ("fwft"),
  .WRITE_DATA_WIDTH    (79)
) table_config_req_fifo (
  .wr_en         (req_wr_en),
  .din           ({sfa_200mhz, pktid_ext_200mhz, idx_ext_200mhz, start_addr_200mhz, config_op_200mhz}),
  .wr_ack        (),
  .rd_en         (req_rd_en),
  .data_valid    (),
  .dout          ({fifo_out_sfa, fifo_out_pktid_ext, fifo_out_idx_ext, fifo_out_start_addr, fifo_out_config_op}),

  .wr_data_count (),
  .rd_data_count (),

  .empty         (req_empty),
  .full          (req_full),
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

assign fifo_out_config_vld = req_rd_en;

// Table signals
localparam NUM_TABLE_ENTRY = 32;
localparam TABLE_IDX_WIDTH = log2(NUM_TABLE_ENTRY);

localparam TABLE_OP_READ   = 8'd1;
localparam TABLE_OP_WRITE  = 8'd2;
localparam TABLE_OP_DELETE = 8'd3;

logic [NUM_TABLE_ENTRY-1:0] table_lookup_from_pkt;
logic [NUM_TABLE_ENTRY-1:0] table_lookup_from_config;

logic [31:0] table_sfa      [NUM_TABLE_ENTRY-1:0];
logic [1 :0] table_pktid_ext[NUM_TABLE_ENTRY-1:0];
logic [4 :0] table_idx_ext  [NUM_TABLE_ENTRY-1:0];
logic [31:0] table_value    [NUM_TABLE_ENTRY-1:0];

logic [TABLE_IDX_WIDTH-1:0] table_idx;
logic [TABLE_IDX_WIDTH-1:0] table_ptr;

// Buffer AXIS packet, delay for one cycle
logic [METADATA_WIDTH_IN-1:0] m_metadata;
logic                         m_metadata_vld;

axis_packet_reg_buffer #(
  .METADATA_WIDTH(METADATA_WIDTH_IN),
  .BUFFER_MODE  ("BUFFERING_DATA")
) axis_packet_reg_buf_inst (
  .s_metadata    ({METADATA_WIDTH_IN{1'b0}}),
  .s_metadata_vld(1'b0),

  .s_axis_tvalid (s_axis_tvalid),
  .s_axis_tdata  (s_axis_tdata),
  .s_axis_tkeep  (s_axis_tkeep),
  .s_axis_tlast  (s_axis_tlast),
  .s_axis_tready (s_axis_tready),

  .m_axis_tvalid (m_axis_tvalid),
  .m_axis_tdata  (m_axis_tdata),
  .m_axis_tkeep  (m_axis_tkeep),
  .m_axis_tlast  (m_axis_tlast),
  .m_axis_tready (m_axis_tready),

  .m_metadata    (m_metadata),
  .m_metadata_vld(m_metadata_vld),

  .aclk    (axis_aclk),
  .aresetn (axis_rstn)
);

// Get data from the metadata_in
assign meta_in_index        = metadata_in[202:171];
assign meta_in_sfa          = metadata_in[170:139];
assign meta_in_dfa          = metadata_in[138:107];
assign meta_in_pktid_ext    = metadata_in[106:105];
assign meta_in_idx_ext      = metadata_in[104:100];
assign meta_in_pkt_type     = metadata_in[99 : 92];
assign meta_in_pktlen       = metadata_in[91 : 76];
assign meta_in_remote_offs  = metadata_in[75 : 20];
assign meta_in_return_code  = metadata_in[19 : 14];
assign meta_in_ptl_list     = metadata_in[13 : 12];
assign meta_in_response_len = metadata_in[11 :  0];

// Table lookup operations
generate genvar i;
  for (i=0; i<NUM_TABLE_ENTRY; i=i+1) begin
    assign table_lookup_from_pkt[i]    = metadata_in_valid ? ((meta_in_sfa==table_sfa[i]) && (meta_in_pktid_ext==table_pktid_ext[i]) && (meta_in_idx_ext==table_idx_ext[i])) : 1'b0;
    assign table_lookup_from_config[i] = !req_empty ? ((fifo_out_sfa==table_sfa[i]) && (fifo_out_pktid_ext==table_pktid_ext[i]) && (fifo_out_idx_ext==table_idx_ext[i])) : 1'b0;
  end
endgenerate

localparam TABLE_LOOKUP = 1'b0;
localparam WAIT_TLAST   = 1'b1;

logic lookup_state;

assign metadata_out = {meta_out_index, meta_out_sfa, meta_out_dfa, meta_out_pktid_ext, meta_out_idx_ext, meta_out_pkt_type, meta_out_pktlen, meta_out_start_addr, meta_out_remote_offs, meta_out_return_code, meta_out_ptl_list, meta_out_response_len};
assign metadata_out_valid = m_metadata_vld;

localparam RD_CONFIG_IDLE = 1'b0;
localparam RD_CONFIG_READ = 1'b1;
logic rd_config_state;
logic rd_config_nextstate;

always_comb begin
  req_rd_en = 1'b0;
  rd_config_nextstate = rd_config_state;
  case(rd_config_state)
  RD_CONFIG_IDLE: begin
    if(!req_empty) begin
      req_rd_en = 1'b1;
      rd_config_nextstate = RD_CONFIG_READ;
    end
  end
  RD_CONFIG_READ: begin
    if(!req_empty) begin
      req_rd_en = 1'b1;
      rd_config_nextstate = RD_CONFIG_IDLE;
    end
  end
  endcase
end

always_ff @(posedge axis_aclk) begin
  if(!axis_rstn) begin
    rd_config_state <= RD_CONFIG_IDLE;    
  end
  else begin
    rd_config_state <= rd_config_nextstate;
  end
end

// [TODO:] table_ptr will be recycled if a table entry is deleted. 
//         The current implementation doesn't consider recycled table_ptr.
//         Need to address this issue in the new version.
always_ff @(posedge axis_aclk)
begin
  if (!axis_rstn) begin
    for (int j=0; j<NUM_TABLE_ENTRY; j=j+1) begin
      table_sfa[j]        <= 32'hffff_ffff;
      table_pktid_ext[j]  <= 2'b11;
      table_idx_ext[j]    <= 5'b11111;
      table_value[j]      <= 32'hffff_ffff;
    end
    table_idx    <= 0;
    table_ptr    <= 0;

    meta_out_index       <= 0;
    meta_out_sfa         <= 0;
    meta_out_dfa         <= 0;
    meta_out_pktid_ext   <= 0;
    meta_out_idx_ext     <= 0;
    meta_out_pkt_type    <= 0;
    meta_out_pktlen      <= 0;
    meta_out_start_addr  <= 0;
    meta_out_remote_offs <= 0;
    meta_out_return_code <= 0;
    meta_out_ptl_list    <= 0;
    meta_out_response_len<= 0;
    lookup_state         <= TABLE_LOOKUP;
  end
  else begin
    if (s_axis_tready && s_axis_tvalid) begin
      meta_out_index       <= meta_in_index;
      meta_out_sfa         <= meta_in_sfa;
      meta_out_dfa         <= meta_in_dfa;
      meta_out_pktid_ext   <= meta_in_pktid_ext;
      meta_out_idx_ext     <= meta_in_idx_ext;
      meta_out_pkt_type    <= meta_in_pkt_type;
      meta_out_pktlen      <= meta_in_pktlen;
      meta_out_start_addr  <= 0;
      meta_out_remote_offs <= meta_in_remote_offs;
      meta_out_return_code <= meta_in_return_code;
      meta_out_ptl_list    <= meta_in_ptl_list;
      meta_out_response_len<= meta_in_response_len;

      lookup_state <= s_axis_tlast ? TABLE_LOOKUP : WAIT_TLAST;
      case (lookup_state)
      TABLE_LOOKUP: begin
        case(table_lookup_from_pkt)
        32'h00000000: begin
          if (req_empty) begin
            // No table configuration request
            // Remove metadata if table lookup is missed
            meta_out_index       <= 0;
            meta_out_sfa         <= 0;
            meta_out_dfa         <= 0;
            meta_out_pktid_ext   <= 0;
            meta_out_idx_ext     <= 0;
            meta_out_pkt_type    <= 0;
            meta_out_pktlen      <= 0;
            meta_out_start_addr  <= 0;
            meta_out_remote_offs <= 0;
            meta_out_return_code <= 0;
            meta_out_ptl_list    <= 0;
            meta_out_response_len<= 0;            
          end
          else begin
            // There exists table configuration requests.

            // Check whether the current packet is matched with the
            // top table config request. If matched, update the table; otherwise,
            // reset metadata to 0 to indicate there is no match in the table
            // and process the table config request
            if (!(metadata_in_valid && (meta_in_sfa==fifo_out_sfa) && (meta_in_pktid_ext==fifo_out_pktid_ext) && (meta_in_idx_ext==fifo_out_idx_ext))) begin
              // The current packet is not matched with the top table config request
              // Remove metadata if table lookup is missed
              meta_out_index       <= 0;
              meta_out_sfa         <= 0;
              meta_out_dfa         <= 0;
              meta_out_pktid_ext   <= 0;
              meta_out_idx_ext     <= 0;
              meta_out_pkt_type    <= 0;
              meta_out_pktlen      <= 0;
              meta_out_start_addr  <= 0;
              meta_out_remote_offs <= 0;
              meta_out_return_code <= 0;
              meta_out_ptl_list    <= 0;
              meta_out_response_len<= 0;

              // [Note] do not read out the table configuration request and hold it in WAIT_TLAST state or ((s_axis_tready && s_axis_tvalid)==1'b0) to make the code simpler. It'll introduce one-cycle delay for the table config write/update operation
            end
            else begin
              // The current packet is matched with the top table config request
              // Write the table with the table config request              
              if (fifo_out_config_op == TABLE_OP_WRITE) begin
                table_sfa[table_ptr]       <= fifo_out_sfa;
                table_pktid_ext[table_ptr] <= fifo_out_pktid_ext;
                table_idx_ext[table_ptr]   <= fifo_out_idx_ext;
                table_value[table_ptr]     <= fifo_out_start_addr;
                table_idx                  <= table_ptr;
                table_ptr                  <= table_ptr + 1;
                meta_out_start_addr        <= fifo_out_start_addr;
              end
            end
          end
        end
        32'h00000001: begin
          // Table lookup is hit. The index of the matched entry is 5'd0
          meta_out_start_addr <= table_value[0];
          table_idx <=5'd0;
        end
        32'h00000002: begin
          // Table lookup is hit. The index of the matched entry is 5'd1
          meta_out_start_addr <= table_value[1];
          table_idx <=5'd1;
        end
        32'h00000004: begin
          // Table lookup is hit. The index of the matched entry is 5'd2
          meta_out_start_addr <= table_value[2];
          table_idx <=5'd2;
        end
        32'h00000008: begin
          // Table lookup is hit. The index of the matched entry is 5'd3
          meta_out_start_addr <= table_value[3];
          table_idx <=5'd3;
        end
        32'h00000010: begin
          // Table lookup is hit. The index of the matched entry is 5'd4
          meta_out_start_addr <= table_value[4];
          table_idx <=5'd4;
        end
        32'h00000020: begin
          // Table lookup is hit. The index of the matched entry is 5'd5
          meta_out_start_addr <= table_value[5];
          table_idx <=5'd5;
        end
        32'h00000040: begin
          // Table lookup is hit. The index of the matched entry is 5'd6
          meta_out_start_addr <= table_value[6];
          table_idx <=5'd6;
        end
        32'h00000080: begin
          // Table lookup is hit. The index of the matched entry is 5'd7
          meta_out_start_addr <= table_value[7];
          table_idx <=5'd7;
        end
        32'h00000100: begin
          // Table lookup is hit. The index of the matched entry is 5'd8
          meta_out_start_addr <= table_value[8];
          table_idx <=5'd8;
        end
        32'h00000200: begin
          // Table lookup is hit. The index of the matched entry is 5'd9
          meta_out_start_addr <= table_value[9];
          table_idx <=5'd9;
        end
        32'h00000400: begin
          // Table lookup is hit. The index of the matched entry is 5'd10
          meta_out_start_addr <= table_value[10];
          table_idx <=5'd10;
        end
        32'h00000800: begin
          // Table lookup is hit. The index of the matched entry is 5'd11
          meta_out_start_addr <= table_value[11];
          table_idx <=5'd11;
        end
        32'h00001000: begin
          // Table lookup is hit. The index of the matched entry is 5'd12
          meta_out_start_addr <= table_value[12];
          table_idx <=5'd12;
        end
        32'h00002000: begin
          // Table lookup is hit. The index of the matched entry is 5'd13
          meta_out_start_addr <= table_value[13];
          table_idx <=5'd13;
        end
        32'h00004000: begin
          // Table lookup is hit. The index of the matched entry is 5'd14
          meta_out_start_addr <= table_value[14];
          table_idx <=5'd14;
        end
        32'h00008000: begin
          // Table lookup is hit. The index of the matched entry is 5'd15
          meta_out_start_addr <= table_value[15];
          table_idx <=5'd15;
        end
        32'h00010000: begin
          // Table lookup is hit. The index of the matched entry is 5'd16
          meta_out_start_addr <= table_value[16];
          table_idx <=5'd16;
        end
        32'h00020000: begin
          // Table lookup is hit. The index of the matched entry is 5'd17
          meta_out_start_addr <= table_value[17];
          table_idx <=5'd17;
        end
        32'h00040000: begin
          // Table lookup is hit. The index of the matched entry is 5'd18
          meta_out_start_addr <= table_value[18];
          table_idx <=5'd18;
        end
        32'h00080000: begin
          // Table lookup is hit. The index of the matched entry is 5'd19
          meta_out_start_addr <= table_value[19];
          table_idx <=5'd19;
        end
        32'h00100000: begin
          // Table lookup is hit. The index of the matched entry is 5'd20
          meta_out_start_addr <= table_value[20];
          table_idx <=5'd20;
        end
        32'h00200000: begin
          // Table lookup is hit. The index of the matched entry is 5'd21
          meta_out_start_addr <= table_value[21];
          table_idx <=5'd21;
        end
        32'h00400000: begin
          // Table lookup is hit. The index of the matched entry is 5'd22
          meta_out_start_addr <= table_value[22];
          table_idx <=5'd22;
        end
        32'h00800000: begin
          // Table lookup is hit. The index of the matched entry is 5'd23
          meta_out_start_addr <= table_value[23];
          table_idx <=5'd23;
        end
        32'h01000000: begin
          // Table lookup is hit. The index of the matched entry is 5'd24
          meta_out_start_addr <= table_value[24];
          table_idx <=5'd24;
        end
        32'h02000000: begin
          // Table lookup is hit. The index of the matched entry is 5'd25
          meta_out_start_addr <= table_value[25];
          table_idx <=5'd25;
        end
        32'h04000000: begin
          // Table lookup is hit. The index of the matched entry is 5'd26
          meta_out_start_addr <= table_value[26];
          table_idx <=5'd26;
        end
        32'h08000000: begin
          // Table lookup is hit. The index of the matched entry is 5'd27
          meta_out_start_addr <= table_value[27];
          table_idx <=5'd27;
        end
        32'h10000000: begin
          // Table lookup is hit. The index of the matched entry is 5'd28
          meta_out_start_addr <= table_value[28];
          table_idx <=5'd28;
        end
        32'h20000000: begin
          // Table lookup is hit. The index of the matched entry is 5'd29
          meta_out_start_addr <= table_value[29];
          table_idx <=5'd29;
        end
        32'h40000000: begin
          // Table lookup is hit. The index of the matched entry is 5'd30
          meta_out_start_addr <= table_value[30];
          table_idx <=5'd30;
        end
        32'h80000000: begin
          // Table lookup is hit. The index of the matched entry is 5'd31
          meta_out_start_addr <= table_value[31];
          table_idx <=5'd31;
        end
        default: begin
          table_idx <= 5'd0;
        end
        endcase
      end
      WAIT_TLAST: begin
        if(s_axis_tready && s_axis_tvalid && s_axis_tlast) begin
          lookup_state <= TABLE_LOOKUP;
        end
      end
      default: begin
        table_idx    <= 0;

        meta_out_index       <= 0;
        meta_out_sfa         <= 0;
        meta_out_dfa         <= 0;
        meta_out_pktid_ext   <= 0;
        meta_out_idx_ext     <= 0;
        meta_out_pkt_type    <= 0;
        meta_out_pktlen      <= 0;
        meta_out_start_addr  <= 0;
        meta_out_remote_offs <= 0;
        meta_out_return_code <= 0;
        meta_out_ptl_list    <= 0;
        meta_out_response_len<= 0;
        lookup_state         <= TABLE_LOOKUP;
      end
      endcase
    end
    else begin
      // When no packet comes, but we have table configuration requests
      if (!req_empty) begin
        case(table_lookup_from_config)
        32'h00000000: begin
          // No matching found, write the new entry
          if (fifo_out_config_op == TABLE_OP_WRITE) begin
            table_sfa[table_ptr]       <= fifo_out_sfa;
            table_pktid_ext[table_ptr] <= fifo_out_pktid_ext;
            table_idx_ext[table_ptr]   <= fifo_out_idx_ext;
            table_value[table_ptr]     <= fifo_out_start_addr;
            table_idx                  <= table_ptr;
            table_ptr                  <= table_ptr + 1;            
          end
        end
        32'h00000001: begin
          table_idx <=5'd0;
          if (fifo_out_config_op == TABLE_OP_WRITE) begin
            table_value[0] <= fifo_out_start_addr;
          end

          if (fifo_out_config_op == TABLE_OP_DELETE) begin
            table_sfa[0]       <= 32'hffff_ffff;
            table_pktid_ext[0] <= 2'b11;
            table_idx_ext[0]   <= 5'b11111;
            table_value[0]     <= 32'hffff_ffff;
          end
        end
        32'h00000002: begin
          table_idx <=5'd1;
          if (fifo_out_config_op == TABLE_OP_WRITE) begin
            table_value[1] <= fifo_out_start_addr;
          end

          if (fifo_out_config_op == TABLE_OP_DELETE) begin
            table_sfa[1]       <= 32'hffff_ffff;
            table_pktid_ext[1] <= 2'b11;
            table_idx_ext[1]   <= 5'b11111;
            table_value[1]     <= 32'hffff_ffff;
          end
        end
        32'h00000004: begin
          table_idx <=5'd2;
          if (fifo_out_config_op == TABLE_OP_WRITE) begin
            table_value[2] <= fifo_out_start_addr;
          end

          if (fifo_out_config_op == TABLE_OP_DELETE) begin
            table_sfa[2]       <= 32'hffff_ffff;
            table_pktid_ext[2] <= 2'b11;
            table_idx_ext[2]   <= 5'b11111;
            table_value[2]     <= 32'hffff_ffff;
          end
        end
        32'h00000008: begin
          table_idx <=5'd3;
          if (fifo_out_config_op == TABLE_OP_WRITE) begin
            table_value[3] <= fifo_out_start_addr;
          end

          if (fifo_out_config_op == TABLE_OP_DELETE) begin
            table_sfa[3]       <= 32'hffff_ffff;
            table_pktid_ext[3] <= 2'b11;
            table_idx_ext[3]   <= 5'b11111;
            table_value[3]     <= 32'hffff_ffff;
          end
        end
        32'h00000010: begin
          table_idx <=5'd4;
          if (fifo_out_config_op == TABLE_OP_WRITE) begin
            table_value[4] <= fifo_out_start_addr;
          end

          if (fifo_out_config_op == TABLE_OP_DELETE) begin
            table_sfa[4]       <= 32'hffff_ffff;
            table_pktid_ext[4] <= 2'b11;
            table_idx_ext[4]   <= 5'b11111;
            table_value[4]     <= 32'hffff_ffff;
          end
        end
        32'h00000020: begin
          table_idx <=5'd5;
          if (fifo_out_config_op == TABLE_OP_WRITE) begin
            table_value[5] <= fifo_out_start_addr;
          end

          if (fifo_out_config_op == TABLE_OP_DELETE) begin
            table_sfa[5]       <= 32'hffff_ffff;
            table_pktid_ext[5] <= 2'b11;
            table_idx_ext[5]   <= 5'b11111;
            table_value[5]     <= 32'hffff_ffff;
          end
        end
        32'h00000040: begin
          table_idx <=5'd6;
          if (fifo_out_config_op == TABLE_OP_WRITE) begin
            table_value[6] <= fifo_out_start_addr;
          end

          if (fifo_out_config_op == TABLE_OP_DELETE) begin
            table_sfa[6]       <= 32'hffff_ffff;
            table_pktid_ext[6] <= 2'b11;
            table_idx_ext[6]   <= 5'b11111;
            table_value[6]     <= 32'hffff_ffff;
          end
        end
        32'h00000080: begin
          table_idx <=5'd7;
          if (fifo_out_config_op == TABLE_OP_WRITE) begin
            table_value[7] <= fifo_out_start_addr;
          end

          if (fifo_out_config_op == TABLE_OP_DELETE) begin
            table_sfa[7]       <= 32'hffff_ffff;
            table_pktid_ext[7] <= 2'b11;
            table_idx_ext[7]   <= 5'b11111;
            table_value[7]     <= 32'hffff_ffff;
          end
        end
        32'h00000100: begin
          table_idx <=5'd8;
          if (fifo_out_config_op == TABLE_OP_WRITE) begin
            table_value[8] <= fifo_out_start_addr;
          end

          if (fifo_out_config_op == TABLE_OP_DELETE) begin
            table_sfa[8]       <= 32'hffff_ffff;
            table_pktid_ext[8] <= 2'b11;
            table_idx_ext[8]   <= 5'b11111;
            table_value[8]     <= 32'hffff_ffff;
          end
        end
        32'h00000200: begin
          table_idx <=5'd9;
          if (fifo_out_config_op == TABLE_OP_WRITE) begin
            table_value[9] <= fifo_out_start_addr;
          end

          if (fifo_out_config_op == TABLE_OP_DELETE) begin
            table_sfa[9]       <= 32'hffff_ffff;
            table_pktid_ext[9] <= 2'b11;
            table_idx_ext[9]   <= 5'b11111;
            table_value[9]     <= 32'hffff_ffff;
          end
        end
        32'h00000400: begin
          table_idx <=5'd10;
          if (fifo_out_config_op == TABLE_OP_WRITE) begin
            table_value[10] <= fifo_out_start_addr;
          end

          if (fifo_out_config_op == TABLE_OP_DELETE) begin
            table_sfa[10]       <= 32'hffff_ffff;
            table_pktid_ext[10] <= 2'b11;
            table_idx_ext[10]   <= 5'b11111;
            table_value[10]     <= 32'hffff_ffff;
          end
        end
        32'h00000800: begin
          table_idx <=5'd11;
          if (fifo_out_config_op == TABLE_OP_WRITE) begin
            table_value[11] <= fifo_out_start_addr;
          end

          if (fifo_out_config_op == TABLE_OP_DELETE) begin
            table_sfa[11]       <= 32'hffff_ffff;
            table_pktid_ext[11] <= 2'b11;
            table_idx_ext[11]   <= 5'b11111;
            table_value[11]     <= 32'hffff_ffff;
          end
        end
        32'h00001000: begin
          table_idx <=5'd12;
          if (fifo_out_config_op == TABLE_OP_WRITE) begin
            table_value[12] <= fifo_out_start_addr;
          end

          if (fifo_out_config_op == TABLE_OP_DELETE) begin
            table_sfa[12]       <= 32'hffff_ffff;
            table_pktid_ext[12] <= 2'b11;
            table_idx_ext[12]   <= 5'b11111;
            table_value[12]     <= 32'hffff_ffff;
          end
        end
        32'h00002000: begin
          table_idx <=5'd13;
          if (fifo_out_config_op == TABLE_OP_WRITE) begin
            table_value[13] <= fifo_out_start_addr;
          end

          if (fifo_out_config_op == TABLE_OP_DELETE) begin
            table_sfa[13]       <= 32'hffff_ffff;
            table_pktid_ext[13] <= 2'b11;
            table_idx_ext[13]   <= 5'b11111;
            table_value[13]     <= 32'hffff_ffff;
          end
        end
        32'h00004000: begin
          table_idx <=5'd14;
          if (fifo_out_config_op == TABLE_OP_WRITE) begin
            table_value[14] <= fifo_out_start_addr;
          end

          if (fifo_out_config_op == TABLE_OP_DELETE) begin
            table_sfa[14]       <= 32'hffff_ffff;
            table_pktid_ext[14] <= 2'b11;
            table_idx_ext[14]   <= 5'b11111;
            table_value[14]     <= 32'hffff_ffff;
          end
        end
        32'h00008000: begin
          table_idx <=5'd15;
          if (fifo_out_config_op == TABLE_OP_WRITE) begin
            table_value[15] <= fifo_out_start_addr;
          end

          if (fifo_out_config_op == TABLE_OP_DELETE) begin
            table_sfa[15]       <= 32'hffff_ffff;
            table_pktid_ext[15] <= 2'b11;
            table_idx_ext[15]   <= 5'b11111;
            table_value[15]     <= 32'hffff_ffff;
          end
        end
        32'h00010000: begin
          table_idx <=5'd16;
          if (fifo_out_config_op == TABLE_OP_WRITE) begin
            table_value[16] <= fifo_out_start_addr;
          end

          if (fifo_out_config_op == TABLE_OP_DELETE) begin
            table_sfa[16]       <= 32'hffff_ffff;
            table_pktid_ext[16] <= 2'b11;
            table_idx_ext[16]   <= 5'b11111;
            table_value[16]     <= 32'hffff_ffff;
          end
        end
        32'h00020000: begin
          table_idx <=5'd17;
          if (fifo_out_config_op == TABLE_OP_WRITE) begin
            table_value[17] <= fifo_out_start_addr;
          end

          if (fifo_out_config_op == TABLE_OP_DELETE) begin
            table_sfa[17]       <= 32'hffff_ffff;
            table_pktid_ext[17] <= 2'b11;
            table_idx_ext[17]   <= 5'b11111;
            table_value[17]     <= 32'hffff_ffff;
          end
        end
        32'h00040000: begin
          table_idx <=5'd18;
          if (fifo_out_config_op == TABLE_OP_WRITE) begin
            table_value[18] <= fifo_out_start_addr;
          end

          if (fifo_out_config_op == TABLE_OP_DELETE) begin
            table_sfa[18]       <= 32'hffff_ffff;
            table_pktid_ext[18] <= 2'b11;
            table_idx_ext[18]   <= 5'b11111;
            table_value[18]     <= 32'hffff_ffff;
          end
        end
        32'h00080000: begin
          table_idx <=5'd19;
          if (fifo_out_config_op == TABLE_OP_WRITE) begin
            table_value[19] <= fifo_out_start_addr;
          end

          if (fifo_out_config_op == TABLE_OP_DELETE) begin
            table_sfa[19]       <= 32'hffff_ffff;
            table_pktid_ext[19] <= 2'b11;
            table_idx_ext[19]   <= 5'b11111;
            table_value[19]     <= 32'hffff_ffff;
          end
        end
        32'h00100000: begin
          table_idx <=5'd20;
          if (fifo_out_config_op == TABLE_OP_WRITE) begin
            table_value[20] <= fifo_out_start_addr;
          end

          if (fifo_out_config_op == TABLE_OP_DELETE) begin
            table_sfa[20]       <= 32'hffff_ffff;
            table_pktid_ext[20] <= 2'b11;
            table_idx_ext[20]   <= 5'b11111;
            table_value[20]     <= 32'hffff_ffff;
          end
        end
        32'h00200000: begin
          table_idx <=5'd21;
          if (fifo_out_config_op == TABLE_OP_WRITE) begin
            table_value[21] <= fifo_out_start_addr;
          end

          if (fifo_out_config_op == TABLE_OP_DELETE) begin
            table_sfa[21]       <= 32'hffff_ffff;
            table_pktid_ext[21] <= 2'b11;
            table_idx_ext[21]   <= 5'b11111;
            table_value[21]     <= 32'hffff_ffff;
          end
        end
        32'h00400000: begin
          table_idx <=5'd22;
          if (fifo_out_config_op == TABLE_OP_WRITE) begin
            table_value[22] <= fifo_out_start_addr;
          end

          if (fifo_out_config_op == TABLE_OP_DELETE) begin
            table_sfa[22]       <= 32'hffff_ffff;
            table_pktid_ext[22] <= 2'b11;
            table_idx_ext[22]   <= 5'b11111;
            table_value[22]     <= 32'hffff_ffff;
          end
        end
        32'h00800000: begin
          table_idx <=5'd23;
          if (fifo_out_config_op == TABLE_OP_WRITE) begin
            table_value[23] <= fifo_out_start_addr;
          end

          if (fifo_out_config_op == TABLE_OP_DELETE) begin
            table_sfa[23]       <= 32'hffff_ffff;
            table_pktid_ext[23] <= 2'b11;
            table_idx_ext[23]   <= 5'b11111;
            table_value[23]     <= 32'hffff_ffff;
          end
        end
        32'h01000000: begin
          table_idx <=5'd24;
          if (fifo_out_config_op == TABLE_OP_WRITE) begin
            table_value[24] <= fifo_out_start_addr;
          end

          if (fifo_out_config_op == TABLE_OP_DELETE) begin
            table_sfa[24]       <= 32'hffff_ffff;
            table_pktid_ext[24] <= 2'b11;
            table_idx_ext[24]   <= 5'b11111;
            table_value[24]     <= 32'hffff_ffff;
          end
        end
        32'h02000000: begin
          table_idx <=5'd25;
          if (fifo_out_config_op == TABLE_OP_WRITE) begin
            table_value[25] <= fifo_out_start_addr;
          end

          if (fifo_out_config_op == TABLE_OP_DELETE) begin
            table_sfa[25]       <= 32'hffff_ffff;
            table_pktid_ext[25] <= 2'b11;
            table_idx_ext[25]   <= 5'b11111;
            table_value[25]     <= 32'hffff_ffff;
          end
        end
        32'h04000000: begin
          table_idx <=5'd26;
          if (fifo_out_config_op == TABLE_OP_WRITE) begin
            table_value[26] <= fifo_out_start_addr;
          end

          if (fifo_out_config_op == TABLE_OP_DELETE) begin
            table_sfa[26]       <= 32'hffff_ffff;
            table_pktid_ext[26] <= 2'b11;
            table_idx_ext[26]   <= 5'b11111;
            table_value[26]     <= 32'hffff_ffff;
          end
        end
        32'h08000000: begin
          table_idx <=5'd27;
          if (fifo_out_config_op == TABLE_OP_WRITE) begin
            table_value[27] <= fifo_out_start_addr;
          end

          if (fifo_out_config_op == TABLE_OP_DELETE) begin
            table_sfa[27]       <= 32'hffff_ffff;
            table_pktid_ext[27] <= 2'b11;
            table_idx_ext[27]   <= 5'b11111;
            table_value[27]     <= 32'hffff_ffff;
          end
        end
        32'h10000000: begin
          table_idx <=5'd28;
          if (fifo_out_config_op == TABLE_OP_WRITE) begin
            table_value[28] <= fifo_out_start_addr;
          end

          if (fifo_out_config_op == TABLE_OP_DELETE) begin
            table_sfa[28]       <= 32'hffff_ffff;
            table_pktid_ext[28] <= 2'b11;
            table_idx_ext[28]   <= 5'b11111;
            table_value[28]     <= 32'hffff_ffff;
          end
        end
        32'h20000000: begin
          table_idx <=5'd29;
          if (fifo_out_config_op == TABLE_OP_WRITE) begin
            table_value[29] <= fifo_out_start_addr;
          end

          if (fifo_out_config_op == TABLE_OP_DELETE) begin
            table_sfa[29]       <= 32'hffff_ffff;
            table_pktid_ext[29] <= 2'b11;
            table_idx_ext[29]   <= 5'b11111;
            table_value[29]     <= 32'hffff_ffff;
          end
        end
        32'h40000000: begin
          table_idx <=5'd30;
          if (fifo_out_config_op == TABLE_OP_WRITE) begin
            table_value[30] <= fifo_out_start_addr;
          end

          if (fifo_out_config_op == TABLE_OP_DELETE) begin
            table_sfa[30]       <= 32'hffff_ffff;
            table_pktid_ext[30] <= 2'b11;
            table_idx_ext[30]   <= 5'b11111;
            table_value[30]     <= 32'hffff_ffff;
          end
        end
        32'h80000000: begin
          table_idx <=5'd31;
          if (fifo_out_config_op == TABLE_OP_WRITE) begin
            table_value[31] <= fifo_out_start_addr;
          end

          if (fifo_out_config_op == TABLE_OP_DELETE) begin
            table_sfa[31]       <= 32'hffff_ffff;
            table_pktid_ext[31] <= 2'b11;
            table_idx_ext[31]   <= 5'b11111;
            table_value[31]     <= 32'hffff_ffff;
          end
        end
        default: begin
          table_idx <= 0;
          table_ptr <= table_ptr;
        end
        endcase
      end
    end
  end
end

// Convert table configuration request from axil_aclk domain to axis_aclk domain
reg single_cycle;
always_ff @(posedge axis_aclk)
begin
  if (!axis_rstn) begin
    for (int k=0; k<2; k=k+1) begin
      sfa_cdc[k]        <= 0;
      pktid_ext_cdc[k]  <= 0;
      idx_ext_cdc[k]    <= 0;
      start_addr_cdc[k] <= 0;
      config_op_cdc[k]  <= 0;
    end
    config_vld_cdc <= 2'd0;
    single_cycle   <= 1'b1;
  end
  else begin
    sfa_cdc[0]        <= sfa_in;
    sfa_cdc[1]        <= sfa_cdc[0];
    pktid_ext_cdc[0]  <= pktid_ext_in;
    pktid_ext_cdc[1]  <= pktid_ext_cdc[0];
    idx_ext_cdc[0]    <= idx_ext_in;
    idx_ext_cdc[1]    <= idx_ext_cdc[0];
    start_addr_cdc[0] <= start_addr_in;
    start_addr_cdc[1] <= start_addr_cdc[0];
    config_op_cdc[0]  <= config_op_in;
    config_op_cdc[1]  <= config_op_cdc[0];
    config_vld_cdc    <= {config_vld_cdc[0], config_in_vld};
    
    single_cycle <= config_vld_cdc[1] ? 1'b0 : 1'b1;
  end
end

assign sfa_200mhz        = sfa_cdc[1];
assign pktid_ext_200mhz  = pktid_ext_cdc[1];
assign idx_ext_200mhz    = idx_ext_cdc[1];
assign start_addr_200mhz = start_addr_cdc[1];
assign config_op_200mhz  = config_op_cdc[1];
assign config_vld_200mhz = config_vld_cdc[1] && single_cycle;

endmodule: packet_matcher