//==============================================================================
// Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
// SPDX-License-Identifier: MIT
//
//==============================================================================
`timescale 1ns/1ps

import rn_tb_pkg::*;

module rn_tb_generator (
  input string traffic_filename,
  output longint num_pkts,
  ref mbox_pkt_str_t mbox_pkt_str
);

strArray pkts_str;

task run;
  if(traffic_filename != "") begin
    pkts_str = parse_data_file(traffic_filename, num_pkts);
    for(int i=0; i<pkts_str.size(); i++) begin
      mbox_pkt_str.put(pkts_str[i]);
    end
  end
  else begin
    $display("INFO: [rn_tb_generator] packets.txt file is not found");
  end
endtask // generator run

endmodule: rn_tb_generator