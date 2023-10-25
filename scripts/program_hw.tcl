#==============================================================================
# Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
# SPDX-License-Identifier: MIT
#
#==============================================================================
#
#  Usage:
#    vivado -mode tcl -source program_hw.tcl -tclargs [-prog_file /your/path/to/program/file] 
#           [-remote_host hostname_or_ip] [-target_id target_name]
#
#==============================================================================

# Directory variables
set root_dir [file normalize ..]
set script_dir ${root_dir}/script
set nic_dir ${root_dir}/base_nics/open-nic-shell
set default_bitstream ${nic_dir}/build/au250/open_nic_shell/open_nic_shell.runs/impl_1/open_nic_shell.bit
set default_config_file ${nic_dir}/build/au250/open_nic_shell/open_nic_shell.runs/impl_1/open_nic_shell.ltx

puts "root_dir   : $root_dir"
puts "script_dir : $script_dir"
puts "nic_dir    : $nic_dir"

set hw_device_id "xcu250_0"

proc getFileSuffix {filename} {
  set suffix [file extension $filename]
  return [string range $suffix 1 end]
}

# Programming options
#   prog_file  : A file in *.bit or *.mcs used to program FPGA
#   config_file : A file in *.ltx used to configure DDR
#   remote_host: hostname or IP address for a remote hw_server
#   target_id  : Hardware target name ID. User can get it when 
#                "Open New Target" under "Open Hardware Manager"
#                in Vivado
array set prog_options {
    -prog_file   ""
    -config_file ""
    -remote_host ""
    -target_id   ""
}

# Expect arguments in the form of `-argument value`
for {set i 0} {$i < $argc} {incr i 2} {
    set arg [lindex $argv $i]
    set val [lindex $argv [expr $i+1]]
    if {[info exists prog_options($arg)]} {
        set prog_options($arg) $val
        puts "Set programming option $arg to $val"
    } else {
        puts "Skip unknown argument $arg and its value $val"
    }
}

foreach {key value} [array get prog_options] {
    set [string range $key 1 end] $value
}

if {[string equal $target_id ""]} {
    puts "Error: Please provide a hardware target ID for FPGA programming"
    quit
}

if {[string equal $prog_file ""]} {
    set prog_file $default_bitstream
}

if {[string equal $config_file ""]} {
    set config_file $default_config_file
}

set file_type [getFileSuffix $prog_file]

puts "Programming file: $prog_file"
puts "Configuration file: $config_file"
puts "Hardware target name ID: $target_id"

puts "Open hardware manager and connect to hardware server"
open_hw_manager
if {[string equal $remote_host ""]} {
    connect_hw_server -allow_non_jtag
} else {
    puts "Connecting remote hw_server"
    connect_hw_server -url $remote_host:3121 -allow_non_jtag
}
current_hw_target [get_hw_targets */xilinx_tcf/Xilinx/$target_id]
set_property PARAM.FREQUENCY 15000000 [get_hw_targets */xilinx_tcf/Xilinx/$target_id]
puts "Open hardware target device"
open_hw_target
current_hw_device [get_hw_devices $hw_device_id]

if {[string equal $file_type "bit"]} {
    puts "Program FPGA with bitstream..."
    set_property PROGRAM.FILE ${prog_file} [get_hw_devices $hw_device_id]
    set_property PROBES.FILE ${config_file} [get_hw_devices $hw_device_id]
    set_property FULL_PROBES.FILE ${config_file} [get_hw_devices $hw_device_id]
    puts "Start programming FPGA..."
    program_hw_devices [get_hw_devices $hw_device_id]
    refresh_hw_device [lindex [get_hw_devices $hw_device_id] 0]
    puts "Success: Programming is done"
} elseif {[string equal $file_type "mcs"]} {
    puts "Program FPGA with configuration memory devices..."
    set_property PROBES.FILE ${config_file} [get_hw_devices $hw_device_id]
    set_property FULL_PROBES.FILE ${config_file} [get_hw_devices $hw_device_id]
    create_hw_cfgmem -hw_device [get_hw_devices $hw_device_id] -mem_dev [lindex [get_cfgmem_parts {mt25qu01g-spi-x1_x2_x4}] 0]
    set_property PROGRAM.ADDRESS_RANGE  {use_file} [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices $hw_device_id] 0]]
    set_property PROGRAM.FILES [list "$prog_file" ] [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices $hw_device_id] 0]]
    set_property PROGRAM.PRM_FILE {} [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices $hw_device_id] 0]]
    set_property PROGRAM.UNUSED_PIN_TERMINATION {pull-up} [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices $hw_device_id] 0]]
    set_property PROGRAM.BLANK_CHECK  0 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices $hw_device_id] 0]]
    set_property PROGRAM.ERASE  1 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices $hw_device_id] 0]]
    set_property PROGRAM.CFG_PROGRAM  1 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices $hw_device_id] 0]]
    set_property PROGRAM.VERIFY  1 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices $hw_device_id] 0]]
    set_property PROGRAM.CHECKSUM  0 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices $hw_device_id] 0]]
    startgroup 
    create_hw_bitstream -hw_device [lindex [get_hw_devices $hw_device_id] 0] [get_property PROGRAM.HW_CFGMEM_BITFILE [ lindex [get_hw_devices $hw_device_id] 0]]; program_hw_devices [lindex [get_hw_devices $hw_device_id] 0]; refresh_hw_device [lindex [get_hw_devices $hw_device_id] 0];
    puts "Start programming FPGA's configuration memory..."
    program_hw_cfgmem -hw_cfgmem [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices $hw_device_id] 0]]
    endgroup
    puts "Success: Configuration memory programming is done"
    boot_hw_device  [lindex [get_hw_devices $hw_device_id] 0]
    refresh_hw_device [lindex [get_hw_devices $hw_device_id] 0]
} else {
    puts "Error: Unsupported file type for FPGA programming"
    quit
}

quit