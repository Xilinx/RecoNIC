#==============================================================================
# Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
# SPDX-License-Identifier: MIT
#
#==============================================================================
#  Program local FPGA board without rebooting the server
# 
#  Usage ./program_fpga.sh -b|--bdf pcie_bdf_num -t|--target_id target_name
#                         [-p|--prog_file *.bit|*.mcs]
#                         [-c|--config_file *.ltx]
#                         [-r|--remote_host hostname|IP_address]
#                         
#
#  [NOTE] 1. This script should be executed on a host server with the target
#            FPGA board, as it will remove and rescan the corresponding PCIe 
#            slot.
#         2. Target ID or target name can be obtained from "Open New Target" 
#            under "Open Hardware Manager" of "PROGRAM AND DEBUG" in Vivado 
#            GUI.
#
#==============================================================================
#!/bin/bash

# Define usage
usage_func() {
  echo -e  "Usage:"
  echo -e  "  ./program_fpga.sh -b pcie_bdf_num -t target_name [option]
  Options and arguments:
  -b, --bdf          PCIe BDF (Bus, Device, Function) number
  -t, --target_id    FPGA target device name or ID
  -p, --prog_file    FPGA programming file in \"bit\" or \"mcs\" format
  -c, --config_file  DDR Configuration file in \"ltx\" format
  -r, --remote_host  Remote hostname or IP address used to program FPGA board\n"                   
  echo "Info: This script should be executed locally on a host server with the target FPGA board."
  echo "Info: For mcs programming, user has to provide /your/path/to/your_file.mcs."
  echo -e "Info: Target ID or target name can be obtained from \"Open New Target\" under \"Open Hardware 
      Manager\" of \"PROGRAM AND DEBUG\" in Vivado GUI\n"
}

pcie_bdf=""
prog_file=""
config_file=""
target_id=""
remote_host=""

if [ $# -lt 4 ]; then
  usage_func
  exit 1
fi

# Process command-line options and arguments
OPTIONS="b:p:c:t:r:"
LONGOPTS="bdf:,prog_file:,config_file:,target_id:,remote_host:"

# Parsing command-line options
PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTS --name "$0" -- "$@")

# Resetting command-line arguments
eval set -- "$PARSED"

# Extracting options and arguments
while true; do
  case "$1" in
    -b|--bdf)
      pcie_bdf="$2"
      shift 2
      ;;
    -p|--prog_file)
      prog_file=$(realpath $2)
      shift 2
      ;;
    -c|--config_file)
      config_file=$(realpath $2)
      shift 2
      ;;
    -t|--target_id)
      target_id="$2"
      shift 2
      ;;
    -r|--remote_host)
      remote_host="$2"
      shift 2
      ;;
    --)
      shift
      break
      ;;
    *)
      echo "Error: Invalid option"
      usage_func
      exit 1
      ;;
  esac
done

pcie_bdf_num="0000:$pcie_bdf"

if [ "$pcie_bdf" == "" -o "$target_id" == "" ]; then
  echo "Error: Please provide correct arguments"
  usage_func
  exit 1
fi

echo "bdf_num: $pcie_bdf_num"
echo "prog_file: $prog_file"
echo "config_file: $config_file"
echo "target_id: $target_id"
echo "remote_host: $remote_host"

# Check device existence
if [ ! -e "/sys/bus/pci/devices/$pcie_bdf_num" ]; then
  echo "Error: PCIe device $pcie_bdf_num not found"
  exit 1
fi

# unbind driver if already binded
if [ -e "/sys/bus/pci/devices/${pcie_bdf_num}/driver" ]; then
  drv_name=$(basename $(readlink "/sys/bus/pci/devices/${pcie_bdf_num}/driver"))
  echo "Unbind driver: ${drv_name}"
  sudo bash -c "echo '${pcie_bdf_num}' >> /sys/bus/pci/devices/${pcie_bdf_num}/driver/unbind"
fi

slot_num=$(basename $(dirname $(readlink "/sys/bus/pci/devices/$pcie_bdf_num")))

# Prevent the host machine from rebooting when FPGA board falls off the bus.
echo "Disable PCIe fatal error report"

## clear SERR in command reg
echo "clear SERR"
cmd_reg=$(sudo setpci -s $slot_num COMMAND)
sudo setpci -s $slot_num COMMAND=$(printf "%04x" $(("0x$cmd_reg" & ~0x0100)))

## clear error reporting enable in CONTROL reg
echo "clear error reporting"
ctrl_reg=$(sudo setpci -s $slot_num CAP_EXP+8.w)
sudo setpci -s $slot_num CAP_EXP+8.w=$(printf "%04x" $(("0x$ctrl_reg" & ~0x0004)))

# program fpga
if [[ ${prog_file} == *.mcs ]]; then
  echo "vivado -mode tcl -source program_hw.tcl -tclargs -prog_file $prog_file -target_id $target_id -remote_host $remote_host"
  vivado -mode tcl -source program_hw.tcl -tclargs -prog_file $prog_file -config_file $config_file -target_id $target_id -remote_host $remote_host
else
  if [ "$prog_file" == "" ]; then
    echo "vivado -mode tcl -source program_hw.tcl -tclargs -target_id $target_id -remote_host $remote_host"
    vivado -mode tcl -source program_hw.tcl -tclargs -target_id $target_id -remote_host $remote_host
  else
    echo "vivado -mode tcl -source program_hw.tcl -tclargs -target_id $target_id -prog_file $prog_file -remote_host $remote_host"
    vivado -mode tcl -source program_hw.tcl -tclargs -target_id $target_id -prog_file $prog_file -config_file $config_file -remote_host $remote_host
  fi
fi

# Enable device after reprogram
echo "Renable FPGA card"
sudo bash -c "echo 1 >> /sys/bus/pci/devices/$slot_num/$pcie_bdf_num/remove"
sudo bash -c "echo 1 >> /sys/bus/pci/devices/$slot_num/rescan"
sudo setpci -s $pcie_bdf_num COMMAND=0x02

echo "Success: FPGA is up and ready"

if [[ ${prog_file} == *.mcs ]]; then
  echo "Info: Please reboot the machine when mcs programming is done"
fi