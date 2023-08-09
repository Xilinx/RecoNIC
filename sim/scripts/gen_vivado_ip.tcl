#==============================================================================
# Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
# SPDX-License-Identifier: MIT
#
#==============================================================================
array set build_options {
  -board_repo ""
}

# Expect arguments in the form of `-argument value`
for {set i 0} {$i < $argc} {incr i 2} {
    set arg [lindex $argv $i]
    set val [lindex $argv [expr $i+1]]
    if {[info exists build_options($arg)]} {
        set build_options($arg) $val
        puts "Set build option $arg to $val"
    } elseif {[info exists design_params($arg)]} {
        set design_params($arg) $val
        puts "Set design parameter $arg to $val"
    } else {
        puts "Skip unknown argument $arg and its value $val"
    }
}

# Settings based on defaults or passed in values
foreach {key value} [array get build_options] {
    set [string range $key 1 end] $value
}

if {[string equal $board_repo ""]} {
  puts "INFO: if showing board_part definition error, please provide \"board_repo\" in the command line to indicate Xilinx board repo path"
} else {
  set_param board.repoPaths $board_repo
}

set vivado_version 2021.2
set board au250
set part xcu250-figd2104-2l-e
set board_part xilinx.com:au250:part0:1.3

set root_dir [file normalize ../..]
set ip_src_dir $root_dir/shell/plugs/rdma_onic_plugin
set sim_dir $root_dir/sim
set build_dir $sim_dir/build
set ip_build_dir $build_dir/ip
set build_managed_ip_dir $build_dir/managed_ip
set ip_src $root_dir/shell/plugs/rdma_onic_plugin
set p4_dir $root_dir/shell/packet_classification

file mkdir $ip_build_dir
file mkdir $build_managed_ip_dir

puts "INFO: Building required IPs"
create_project -force managed_ip_project $build_managed_ip_dir -part $part
set_property BOARD_PART $board_part [current_project]

set ip_dict [dict create]
source ${ip_src_dir}/vivado_ip/sim_vivado_ip.tcl
foreach ip $ips {
  set xci_file ${ip_build_dir}/$ip/$ip.xci
  source ${ip_src_dir}/vivado_ip/${ip}.tcl

  generate_target all [get_files  $xci_file]
  create_ip_run [get_files -of_objects [get_fileset sources_1] $xci_file]
  launch_runs ${ip}_synth_1 -jobs 8
  wait_on_run ${ip}_synth_1
  puts "INFO: $ip is generated"
}

puts "INFO: All IPs required for simulation are generated"

