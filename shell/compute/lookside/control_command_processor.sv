//==============================================================================
// Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
// SPDX-License-Identifier: MIT
//
//==============================================================================
`timescale 1ns/1ps

module control_command_processor #(
  parameter AXIL_ADDR_WIDTH  = 12,
  parameter AXIL_DATA_WIDTH  = 32
) (
  // register control interface
  input                              s_axil_awvalid,
  input        [AXIL_ADDR_WIDTH-1:0] s_axil_awaddr,
  output logic                       s_axil_awready,
  input                              s_axil_wvalid,
  input        [AXIL_DATA_WIDTH-1:0] s_axil_wdata,
  output logic                       s_axil_wready,
  output logic                       s_axil_bvalid,
  output logic                 [1:0] s_axil_bresp,
  input                              s_axil_bready,
  input                              s_axil_arvalid,
  input        [AXIL_ADDR_WIDTH-1:0] s_axil_araddr,
  output logic                       s_axil_arready,
  output logic                       s_axil_rvalid,
  output logic [AXIL_DATA_WIDTH-1:0] s_axil_rdata,
  output logic                 [1:0] s_axil_rresp,
  input                              s_axil_rready,

  input         cl_box_idle,
  output logic  cl_box_start,
  input         cl_box_done,
  input         cl_kernel_idle,
  input         cl_kernel_done,
  output [31:0] ctl_cmd_fifo_dout,
  output        ctl_cmd_fifo_empty_n,
  input         ctl_cmd_fifo_rd_en,

  input  [31:0] ker_status_fifo_din,
  input         ker_status_fifo_wr_en,
  output        ker_status_fifo_full_n,

  input axil_aclk,
  input axil_arstn,
  input axis_aclk,
  input axis_arstn
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

localparam DEFAULT_VALUE = 32'hdeadbeef;

// For testing purpose
localparam TEMPLATE_REG = 12'd512;
logic [AXIL_DATA_WIDTH-1:0] template_reg;

localparam CTL_CMD                = 12'h000;
localparam KER_STS                = 12'h004;
localparam JOB_SUBMITTED          = 12'h008;
localparam JOB_COMPLETED_NOT_READ = 12'h00C;

logic [31:0] job_submitted_cnt;
logic [31:0] job_completed_not_read_cnt;

/* AXI-Lite write interface */
localparam AXIL_WRITE_IDLE   = 2'b00;
localparam AXIL_WRITE_WREADY = 2'b01;
localparam AXIL_WRITE_RESP   = 2'b11;
localparam AXIL_WRITE_WAIT   = 2'b10;
logic [1:0] axil_write_state;
logic [AXIL_ADDR_WIDTH-1:0] awaddr;

/* AXI-Lite read interface */
localparam AXIL_READ_IDLE = 2'b01;
localparam AXIL_READ_RESP = 2'b10;
logic [1:0] axil_read_state;
logic [AXIL_ADDR_WIDTH-1:0] araddr;

/* Async FIFO to buffer control commands */
localparam ASYNC_FIFO_DEPTH = 2048;
localparam WR_DATA_COUNT_WIDTH = log2(ASYNC_FIFO_DEPTH) + 1;

logic ctl_cmd_wr_en;
logic ctl_cmd_afifo_full;
logic [31:0] ctl_cmd_data;

logic ctl_cmd_rd_en;
logic ctl_cmd_afifo_empty;
logic [31:0] ctl_cmd_afifo_data_out;

logic [WR_DATA_COUNT_WIDTH-1:0] ctl_cmd_afifo_wr_data_count;

logic ctl_cmd_wr_rst_busy;

/* Async FIFO to buffer kernel status */
localparam RD_DATA_COUNT_WIDTH = log2(ASYNC_FIFO_DEPTH) + 1;
logic ker_status_wr_en;
logic ker_status_afifo_full;
logic [31:0] ker_status_data;

logic ker_status_rd_en;
logic ker_status_afifo_empty;
logic [31:0] ker_status_afifo_data_out;

logic [RD_DATA_COUNT_WIDTH-1:0] ker_status_afifo_rd_data_count;

logic ker_status_wr_rst_busy;

localparam CL_IDLE          = 2'b00;
localparam CL_BOX_ACTIVE    = 2'b01;
localparam CL_KERNEL_ACTIVE = 2'b11;

logic [1:0] kernel_state;
logic [1:0] kernel_nextstate;

// AXI-Lite write transaction
always_ff @(posedge axil_aclk)
begin
  if(~axil_arstn)
  begin
    s_axil_awready <= 1'b1;
    s_axil_wready  <= 1'b0;
    s_axil_bvalid  <= 1'b0;
    s_axil_bresp   <= 2'd0;
    awaddr         <= 0;

    template_reg   <= 0;

    ctl_cmd_data   <= 0;
    ctl_cmd_wr_en  <= 0;

    axil_write_state <= AXIL_WRITE_IDLE;
  end
  else begin
    ctl_cmd_wr_en  <= 0;
    case(axil_write_state)
      AXIL_WRITE_IDLE: begin
        s_axil_bvalid  <= 1'b0;
        if(s_axil_awvalid && s_axil_awready)
        begin
          s_axil_wready  <= 1'b1;
          s_axil_awready <= 1'b0;
          awaddr         <= s_axil_awaddr;
          if(s_axil_wvalid)
          begin
            axil_write_state <= AXIL_WRITE_RESP;
            case(s_axil_awaddr)
              CTL_CMD     : begin
                ctl_cmd_data <= s_axil_wdata;
                if(ctl_cmd_afifo_full || ctl_cmd_wr_rst_busy) begin
                  ctl_cmd_wr_en  <= 1'b0;
                  axil_write_state <= AXIL_WRITE_WAIT;
                end
                else begin
                  ctl_cmd_wr_en <= 1'b1;
                end
                if(s_axil_wready)
                begin
                  s_axil_wready <= 1'b0;
                end
              end
              TEMPLATE_REG: begin
                template_reg <= s_axil_wdata;
              end
              default: begin
                template_reg <= template_reg;
              end
            endcase
          end
          else begin
            axil_write_state <= AXIL_WRITE_WREADY;
          end
        end
        else begin
          s_axil_wready <= s_axil_wready;
        end
      end
      AXIL_WRITE_WREADY: begin
        if(s_axil_wvalid)
        begin
          axil_write_state <= AXIL_WRITE_RESP;
          if(s_axil_wready)
          begin
            s_axil_wready <= 1'b0;
          end
          case(awaddr)
            CTL_CMD     : begin
              ctl_cmd_data <= s_axil_wdata;
              if(ctl_cmd_afifo_full) begin
                ctl_cmd_wr_en  <= 1'b0;
                axil_write_state <= AXIL_WRITE_WAIT;
              end
              else begin
                ctl_cmd_wr_en <= 1'b1;
              end
            end
            TEMPLATE_REG   : template_reg <= s_axil_wdata;
            default: begin
              template_reg <= template_reg;
            end
          endcase    
        end
      end
      AXIL_WRITE_WAIT: begin
        if(!ctl_cmd_afifo_full && !ctl_cmd_wr_rst_busy) begin
          s_axil_bresp  <= 0;
          ctl_cmd_wr_en <= 1'b1;
          s_axil_bvalid <= 1'b1;
          axil_write_state <= AXIL_WRITE_RESP;
        end
      end
      AXIL_WRITE_RESP: begin
        s_axil_bresp   <= 0;
        s_axil_bvalid  <= 1'b1;
        awaddr         <= 0;
        s_axil_awready <= 1'b1;
        s_axil_wready  <= 1'b0;
        ctl_cmd_wr_en  <= 1'b0;
        axil_write_state <= s_axil_bready ? AXIL_WRITE_IDLE : AXIL_WRITE_RESP;
      end
      default: begin
        s_axil_awready <= 1'b1;
        s_axil_wready  <= 1'b0;
        s_axil_bvalid  <= 1'b0;
        s_axil_bresp   <= 2'd0;
        awaddr         <= 0;     
        axil_write_state <= AXIL_WRITE_IDLE;
      end
    endcase
  end
end

// Async FIFO to buffer control commands
xpm_fifo_async #(
  .DOUT_RESET_VALUE    ("0"),
  .ECC_MODE            ("no_ecc"),
  .FIFO_MEMORY_TYPE    ("auto"),
  .FIFO_READ_LATENCY   (0),
  .FIFO_WRITE_DEPTH    (ASYNC_FIFO_DEPTH),
  .READ_DATA_WIDTH     (32),
  .RD_DATA_COUNT_WIDTH (),
  .WR_DATA_COUNT_WIDTH (WR_DATA_COUNT_WIDTH),
  .READ_MODE           ("fwft"),
  .WRITE_DATA_WIDTH    (32),
  .CDC_SYNC_STAGES     (2)
) ctl_cmd_afifo (
  .wr_en         (ctl_cmd_wr_en),
  .din           (ctl_cmd_data),
  .wr_ack        (),
  .rd_en         (ctl_cmd_rd_en),
  .data_valid    (),
  .dout          (ctl_cmd_afifo_data_out),

  .wr_data_count (ctl_cmd_afifo_wr_data_count),
  .rd_data_count (),

  .empty         (ctl_cmd_afifo_empty),
  .full          (ctl_cmd_afifo_full),
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

  .wr_clk        (axil_aclk),
  .rd_clk        (axis_aclk),
  .rst           (~axis_arstn),
  .rd_rst_busy   (),
  .wr_rst_busy   (ctl_cmd_wr_rst_busy)
);

assign ctl_cmd_rd_en        = ctl_cmd_fifo_rd_en;
assign ctl_cmd_fifo_dout    = ctl_cmd_afifo_data_out;
assign ctl_cmd_fifo_empty_n = ~ctl_cmd_afifo_empty;

// AXI-Lite read transaction
always_ff @(posedge axil_aclk)
begin
  if(~axil_arstn)
  begin
    s_axil_arready   <= 1'b1;
    s_axil_rvalid    <= 1'b0;
    s_axil_rdata     <= 0;
    s_axil_rresp     <= 0;
    araddr           <= 0;
    ker_status_rd_en <= 1'b0;
    axil_read_state <= AXIL_READ_IDLE;
  end
  else begin
    ker_status_rd_en <= 1'b0;
    case(axil_read_state)
      AXIL_READ_IDLE: begin
        if(s_axil_arready && s_axil_arvalid)
        begin
          s_axil_arready <= 1'b0;
          s_axil_rvalid  <= 1'b1;
          s_axil_rresp   <= 0;
          araddr             <= s_axil_araddr;
          case(s_axil_araddr)
            KER_STS               : begin
              s_axil_rdata <= !ker_status_afifo_empty ? ker_status_afifo_data_out : DEFAULT_VALUE;
              ker_status_rd_en <= !ker_status_afifo_empty ? 1'b1 : 1'b0;
            end
            JOB_SUBMITTED         : s_axil_rdata <= job_submitted_cnt;
            JOB_COMPLETED_NOT_READ: s_axil_rdata <= job_completed_not_read_cnt;
            TEMPLATE_REG          : s_axil_rdata <= template_reg;
            default               : s_axil_rdata <= DEFAULT_VALUE;
          endcase
          axil_read_state <= AXIL_READ_RESP;
        end
      end
      AXIL_READ_RESP: begin
        if(s_axil_rready && s_axil_rvalid)
        begin
          s_axil_rvalid  <= 1'b0;
          s_axil_arready <= 1'b1;
          axil_read_state    <= AXIL_READ_IDLE;
        end
      end
      default: begin
        s_axil_arready <= 1'b1;
        s_axil_rvalid  <= 1'b0;
        s_axil_rdata   <= 0;
        s_axil_rresp   <= 0;
        axil_read_state <= AXIL_READ_IDLE;        
      end
    endcase
  end
end

assign job_submitted_cnt          = ctl_cmd_afifo_wr_data_count;
assign job_completed_not_read_cnt = ker_status_afifo_rd_data_count;

// Async FIFO to buffer kernel status
xpm_fifo_async #(
  .DOUT_RESET_VALUE    ("0"),
  .ECC_MODE            ("no_ecc"),
  .FIFO_MEMORY_TYPE    ("auto"),
  .FIFO_READ_LATENCY   (0),
  .FIFO_WRITE_DEPTH    (ASYNC_FIFO_DEPTH),
  .READ_DATA_WIDTH     (32),
  .RD_DATA_COUNT_WIDTH (RD_DATA_COUNT_WIDTH),
  .READ_MODE           ("fwft"),
  .WRITE_DATA_WIDTH    (32),
  .CDC_SYNC_STAGES     (2)
) ker_status_afifo (
  .wr_en         (ker_status_wr_en),
  .din           (ker_status_data),
  .wr_ack        (),
  .rd_en         (ker_status_rd_en),
  .data_valid    (),
  .dout          (ker_status_afifo_data_out),

  .wr_data_count (),
  .rd_data_count (ker_status_afifo_rd_data_count),

  .empty         (ker_status_afifo_empty),
  .full          (ker_status_afifo_full),
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
  .rd_clk        (axil_aclk),
  .rst           (~axil_arstn),
  .rd_rst_busy   (),
  .wr_rst_busy   (ker_status_wr_rst_busy)
);

assign ker_status_fifo_full_n = (!ker_status_afifo_full) && (!ker_status_wr_rst_busy);
assign ker_status_data        = ker_status_fifo_din;
assign ker_status_wr_en       = ker_status_fifo_wr_en;

always_ff @(posedge axis_aclk)
begin
  if(!axis_arstn) begin
    kernel_state <= CL_IDLE;

    cl_box_start <= 1'b0;
  end
  else begin
    cl_box_start <= 1'b0;
    case(kernel_state)
      CL_IDLE: begin
        if(cl_box_idle && cl_kernel_idle && !ctl_cmd_afifo_empty) begin
          cl_box_start <= 1'b1;
          kernel_state <= CL_BOX_ACTIVE;
        end
      end
      CL_BOX_ACTIVE: begin
        cl_box_start <= 1'b1;
        if(cl_box_done && !cl_kernel_done) begin
          cl_box_start <= 1'b0;
          kernel_state <= CL_KERNEL_ACTIVE;
        end

        if(cl_box_done && cl_kernel_done) begin
          cl_box_start <= 1'b0;
          kernel_state <= CL_IDLE;
        end
      end
      CL_KERNEL_ACTIVE: begin
        if(cl_kernel_done) begin
          kernel_state <= CL_IDLE;
        end
      end
      default: kernel_state <= CL_IDLE;
    endcase
  end
end

endmodule: control_command_processor