#!/bin/bash


set -Eeuo pipefail

echo -e "add_au280_support.sh -- apply changes to support AU280"

cur_dir=$(pwd)
root_dir=$(dirname $cur_dir)
patch_dir=${root_dir}/patches/au280
nic_dir=${root_dir}/base_nics/open-nic-shell
nic_src_dir=${root_dir}/base_nics/open-nic-shell/src

cd ${nic_src_dir}
mkdir -p ${nic_src_dir}/mem_ctrl/au280/vivado_ip
cp ${patch_dir}/mem_ctrl/au280/* ${nic_src_dir}/mem_ctrl/au280/vivado_ip

cp ${patch_dir}/constr/* ${nic_dir}/constr/au280

cp ${patch_dir}/open_nic_shell.sv ${nic_src_dir}/open_nic_shell.sv

cp ${patch_dir}/plugin/p2p/p2p_250mhz.sv ${nic_dir}/plugin/p2p/p2p_250mhz.sv

cp ${patch_dir}/plugin/p2p/box_250mhz/user_plugin_250mhz_inst.vh ${nic_dir}/plugin/p2p/box_250mhz/user_plugin_250mhz_inst.vh

cp ${patch_dir}/qdma_subsystem/qdma_subsystem.sv ${nic_src_dir}/qdma_subsystem/qdma_subsystem.sv

cp ${patch_dir}/qdma_subsystem/qdma_subsystem_qdma_wrapper.v ${nic_src_dir}/qdma_subsystem/qdma_subsystem_qdma_wrapper.v

cp ${patch_dir}/qdma_subsystem/vivado_ip/qdma_no_sriov_au280.tcl ${nic_src_dir}/qdma_subsystem/vivado_ip/qdma_no_sriov_au280.tcl

cp -r ${patch_dir}/system_config/* ${nic_src_dir}/system_config

cp ${patch_dir}/utility/vivado_ip/axi_clock_converter_for_mem_au280.tcl ${nic_src_dir}/utility/vivado_ip/axi_clock_converter_for_mem_au280.tcl


echo -e "add_au280_support.sh done!"


cd ${cur_dir}

$SHELL
