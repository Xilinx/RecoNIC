//==============================================================================
// Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
// SPDX-License-Identifier: MIT
//
//==============================================================================

package rn_tb_pkg;
  
  localparam AXIS_DATA_WIDTH = 512;
  localparam AXIS_KEEP_WIDTH = 64;
  localparam USER_META_DATA_WIDTH = 263;
  localparam PKTLEN_WIDTH    = 16;

  typedef struct {
    logic [AXIS_DATA_WIDTH-1:0] tdata;
    logic [AXIS_KEEP_WIDTH-1:0] tkeep;
    logic                       tlast;
    logic    [PKTLEN_WIDTH-1:0] pkt_len;
  } AXIS_T;

  typedef string strArray[$];
  typedef bit [1023:0] bitArray;
  typedef AXIS_T axis_pkt_queue_t[$];

  typedef mailbox #(string) mbox_pkt_str_t;
  typedef mailbox #(AXIS_T) mbox_data_axis_t;
  typedef mailbox #(logic[31:0]) mbox_ctrl_t;

  // split string using delimiter
  function automatic strArray split (
    input string str_in,      // input string 
    input byte   delim = " "  // delimited character. Default ' ' (white space)
  );
  
    int str_idx = 0;  
    string str_tmp = "";
    strArray str_out;

    for (int i = 0; i <= str_in.len(); i++) begin
      if (str_in[i] == delim || i == str_in.len()) begin
        if (str_tmp.len() > 0) begin
          str_out[str_idx] = str_tmp;
          str_tmp = "";
          str_idx++;
        end
      end else begin
        str_tmp = {str_tmp, str_in[i]};
      end
    end

    return str_out;
  endfunction

  // parser a packet file
  function automatic strArray parse_data_file (
    input string filename,
    output longint num_pkts
  );

    int fd;
    string line;
    string lines;
    strArray pkts_str;

    num_pkts = 0;
    // Open file to get data / metadata
    fd = $fopen($sformatf("%s.txt", filename), "r");
    if(!fd) begin
      //$fatal(1, "[ERROR]: Packet data file not found %s.txt", filename);
      $display("[INFO]: Packet data file not found %s.txt", filename);
      pkts_str[0] = "";
      return pkts_str;
    end

    // read lines
    while(!$feof(fd)) begin
      if($fgets(line, fd)) begin
        if(line.getc(0) == "%" || ((line.getc(0) == "/") && (line.getc(1) == "/"))) begin
          // Ignore comments
          continue;
        end

        if(!(line.getc(0) == "d" && line.getc(1) == "d")) begin
          // Do not print dummy packet
          $display("[INFO]: time=%0t, %d-th Packet: %s", $time, num_pkts, line);
        end
        else begin
          $display("[INFO]: time=%0t, %d-th dummy Packet: %s", $time, num_pkts, line);
        end
        lines = {lines, " ", line.substr(0, line.len()-2)};
        num_pkts++;
      end
    end

    pkts_str = split(lines, ";");
    $display("[INFO]: Number of packets is %d", num_pkts);
    $fclose(fd);
    return pkts_str;
  endfunction // parse_data_file

endpackage: rn_tb_pkg