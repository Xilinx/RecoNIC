#==============================================================================
# Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
# SPDX-License-Identifier: MIT
#
#==============================================================================
VIVADO_DATA_DIR=$VIVADO_DIR/data
XVIP_PATH=$VIVADO_DATA_DIR/xilinx_vip
XPM_PATH=$VIVADO_DATA_DIR/ip/xpm
USER_LIB=${build_dir}/questa_lib

vlib $USER_LIB/reco
vlib $USER_LIB/axi_bram_ctrl_v4_1_6

vlib $USER_LIB/xilinx_vip
vlib $USER_LIB/xpm
vlib $USER_LIB/lib_bmg_v1_0_14
vlib $USER_LIB/lib_fifo_v1_0_15
vlib $USER_LIB/ernic_v3_1_1

vmap axi_bram_ctrl_v4_1_6 $USER_LIB/axi_bram_ctrl_v4_1_6
vmap xilinx_vip $USER_LIB/xilinx_vip
vmap xpm $USER_LIB/xpm
vmap lib_bmg_v1_0_14 $USER_LIB/lib_bmg_v1_0_14
vmap lib_fifo_v1_0_15 $USER_LIB/lib_fifo_v1_0_15
vmap ernic_v3_1_1 $USER_LIB/ernic_v3_1_1
vmap reco $USER_LIB/reco

vlog -work xilinx_vip -64 -incr -mfcu -sv -L ernic_v3_1_1 "+incdir+$XVIP_PATH/include" \
"$XVIP_PATH/hdl/axi4stream_vip_axi4streampc.sv" \
"$XVIP_PATH/hdl/axi_vip_axi4pc.sv" \
"$XVIP_PATH/hdl/xil_common_vip_pkg.sv" \
"$XVIP_PATH/hdl/axi4stream_vip_pkg.sv" \
"$XVIP_PATH/hdl/axi_vip_pkg.sv" \
"$XVIP_PATH/hdl/axi4stream_vip_if.sv" \
"$XVIP_PATH/hdl/axi_vip_if.sv" \
"$XVIP_PATH/hdl/clk_vip_if.sv" \
"$XVIP_PATH/hdl/rst_vip_if.sv" \

vlog -work xpm -64 -incr -mfcu -sv -L ernic_v3_1_1 "+incdir+$XVIP_PATH/include" \
"$XPM_PATH/xpm_cdc/hdl/xpm_cdc.sv" \
"$XPM_PATH/xpm_fifo/hdl/xpm_fifo.sv" \
"$XPM_PATH/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm -64 -93 \
"$VIVADO_DATA_DIR/ip/xpm/xpm_VCOMP.vhd" \

vcom -work lib_bmg_v1_0_14 -64 -93 \
"../build/ip/rdma_core/hdl/lib_bmg_v1_0_rfs.vhd" \

vcom -work lib_fifo_v1_0_15 -64 -93 \
"../build/ip/rdma_core/hdl/lib_fifo_v1_0_rfs.vhd" \

vlog -work ernic_v3_1_1 -64 -incr -mfcu -sv -L ernic_v3_1_1 "+incdir+../build/ip/rdma_core/hdl/common" "+incdir+$XVIP_PATH/include" \
"../build/ip/rdma_core/hdl/ernic_v3_1_rfs.sv" \

vlog -work reco -64 -incr -mfcu -sv -L ernic_v3_1_1 "+incdir+../build/ip/rdma_core/hdl/common" "+incdir+$XVIP_PATH/include" \
"../build/ip/rdma_core/synth/rdma_core.sv" \

vlog -64 -work reco -sv -L cam_v2_2_2 -L vitis_net_p4_v1_0_2 -Ldir \
"+incdir+../build/ip/packet_parser/hdl" "+incdir+../build/ip/packet_parser/src/hw/include" "+incdir+$XVIP_PATH/include" \
"../build/ip/packet_parser/src/verilog/packet_parser_top_pkg.sv" \
"../build/ip/packet_parser/src/verilog/packet_parser_pkg.sv" \
"../build/ip/packet_parser/src/verilog/packet_parser_sync_fifos.sv" \
"../build/ip/packet_parser/src/verilog/packet_parser_header_sequence_identifier.sv" \
"../build/ip/packet_parser/src/verilog/packet_parser_header_field_extractor.sv" \
"../build/ip/packet_parser/src/verilog/packet_parser_error_check_module.sv" \
"../build/ip/packet_parser/src/verilog/packet_parser_parser_engine.sv" \
"../build/ip/packet_parser/src/verilog/packet_parser_deparser_engine.sv" \
"../build/ip/packet_parser/src/verilog/packet_parser_action_engine.sv" \
"../build/ip/packet_parser/src/verilog/packet_parser_lookup_engine.sv" \
"../build/ip/packet_parser/src/verilog/packet_parser_axi4lite_interconnect.sv" \
"../build/ip/packet_parser/src/verilog/packet_parser_statistics_registers.sv" \
"../build/ip/packet_parser/src/verilog/packet_parser_match_action_engine.sv" \
"../build/ip/packet_parser/src/verilog/packet_parser_top.sv" \
"../build/ip/packet_parser/src/verilog/packet_parser.sv" \

vcom -work axi_bram_ctrl_v4_1_6 -64 -93 \
"../build/ip/axi_mm_bram/hdl/axi_bram_ctrl_v4_1_rfs.vhd" \

vcom -work reco -64 -93 \
"../build/ip/axi_mm_bram/sim/axi_mm_bram.vhd" \

vcom -work reco -64 -93 \
"../build/ip/axi_sys_mm/sim/axi_sys_mm.vhd" \

vlog -64 -work reco -L axi_crossbar_v2_1_26 "+incdir+../build/ip/reconic_axil_crossbar/hdl" \
"../build/ip/reconic_axil_crossbar/sim/reconic_axil_crossbar.v" \

#vlog -64 -work reco -L axi_crossbar_v2_1_26 "+incdir+../build/ip/axil_2to1_crossbar/hdl" \
#"../build/ip/axil_2to1_crossbar/sim/axil_2to1_crossbar.v" \

vlog -64 -work reco -L axi_crossbar_v2_1_26 "+incdir+../build/ip/axil_3to1_crossbar/hdl" \
"../build/ip/axil_3to1_crossbar/sim/axil_3to1_crossbar.v" \

vlog -64 -work reco -L fifo_generator_v13_2_6 "+incdir+../build/ip/dev_mem_axi_crossbar/hdl" \
"../build/ip/dev_mem_axi_crossbar/hdl/axi_crossbar_v2_1_vl_rfs.v" \
"../build/ip/dev_mem_axi_crossbar/hdl/axi_data_fifo_v2_1_vl_rfs.v" \
"../build/ip/dev_mem_axi_crossbar/hdl/axi_infrastructure_v1_1_vl_rfs.v" \
"../build/ip/dev_mem_axi_crossbar/hdl/axi_register_slice_v2_1_vl_rfs.v" \
"../build/ip/dev_mem_axi_crossbar/hdl/generic_baseblocks_v2_1_vl_rfs.v" \
"../build/ip/dev_mem_axi_crossbar/synth/dev_mem_axi_crossbar.v" \

vlog -work reco -64 -incr -mfcu -sv \
"../../base_nics/open-nic-shell/src/utility/generic_reset.sv" \
"../../base_nics/open-nic-shell/src/rdma_subsystem/rdma_subsystem.sv" \
"../../base_nics/open-nic-shell/src/rdma_subsystem/rdma_subsystem_wrapper.sv" \

vlog -64 -sv -work reco -L blk_mem_gen_v8_4_5 -L fifo_generator_v13_2_6 "+incdir+../build/ip/axi_protocol_checker/hdl/verilog" \
"../build/ip/axi_protocol_checker/hdl/sc_util_v1_0_vl_rfs.sv" \
"../build/ip/axi_protocol_checker/hdl/axi_protocol_checker_v2_0_vl_rfs.sv" \
"../build/ip/axi_protocol_checker/sim/axi_protocol_checker.sv" \

vlog -64 +define+DEBUG -work reco +incdir+../../shell/compute/lookside/interface -f ./interface.f
vlog -64 +define+DEBUG -work reco +incdir+../../shell/compute/lookside/kernel -f ./kernel.f

vlog -64 -sv -L xpm +define+DEBUG -work reco \
"../../shell/utilities/rn_reg_control.sv" \
"../../shell/packet_classification/packet_classification.sv" \
"../../shell/packet_classification/packet_filter.sv" \
"../../shell/compute/lookside/compute_logic_wrapper.sv" \
"../../shell/compute/lookside/control_command_processor.sv" \
"../../base_nics/open-nic-shell/src/utility/axi_interconnect_to_dev_mem.sv" \
"../../base_nics/open-nic-shell/src/utility/axi_interconnect_to_sys_mem.sv" \
"../../shell/plugs/rdma_onic_plugin/reconic_address_map.sv" \
"../../shell/top/reconic.sv" \
"../../shell/plugs/rdma_onic_plugin/box_250mhz.sv" \
"../../shell/plugs/rdma_onic_plugin/rdma_onic_plugin.sv" \

vlog -64 -sv +define+DEBUG -L xpm -work reco \
"../src/axi_read_verify.sv" \
"../src/axil_reg_stimulus.sv" \
"../src/axil_reg_control.sv" \
"../src/axil_3to1_crossbar_wrapper.sv" \
"../src/init_mem.sv" \
"../src/rdma_rn_wrapper.sv" \
"../src/rn_tb_pkg.sv" \
"../src/rn_tb_generator.sv" \
"../src/rn_tb_driver.sv" \
"../src/rn_tb_checker.sv" \
"../src/rn_tb_top.sv" \
"../src/cl_tb_top.sv" \
"../src/rn_tb_2rdma_top.sv" \
"../src/axi_3to1_interconnect_to_dev_mem.sv" \
"../src/axi_5to2_interconnect_to_sys_mem.sv" \


vlog -64 -work reco -L fifo_generator_v13_2_6 "+incdir+../build/ip/dev_mem_3to1_axi_crossbar/hdl" \
"../build/ip/dev_mem_3to1_axi_crossbar/hdl/axi_crossbar_v2_1_vl_rfs.v" \
"../build/ip/dev_mem_3to1_axi_crossbar/hdl/axi_data_fifo_v2_1_vl_rfs.v" \
"../build/ip/dev_mem_3to1_axi_crossbar/hdl/axi_infrastructure_v1_1_vl_rfs.v" \
"../build/ip/dev_mem_3to1_axi_crossbar/hdl/axi_register_slice_v2_1_vl_rfs.v" \
"../build/ip/dev_mem_3to1_axi_crossbar/hdl/generic_baseblocks_v2_1_vl_rfs.v" \
"../build/ip/dev_mem_3to1_axi_crossbar/synth/dev_mem_3to1_axi_crossbar.v" \

vlog -64 -work reco -L fifo_generator_v13_2_6 "+incdir+../build/ip/sys_mem_5to2_axi_crossbar/hdl" \
"../build/ip/sys_mem_5to2_axi_crossbar/hdl/axi_crossbar_v2_1_vl_rfs.v" \
"../build/ip/sys_mem_5to2_axi_crossbar/hdl/axi_data_fifo_v2_1_vl_rfs.v" \
"../build/ip/sys_mem_5to2_axi_crossbar/hdl/axi_infrastructure_v1_1_vl_rfs.v" \
"../build/ip/sys_mem_5to2_axi_crossbar/hdl/axi_register_slice_v2_1_vl_rfs.v" \
"../build/ip/sys_mem_5to2_axi_crossbar/hdl/generic_baseblocks_v2_1_vl_rfs.v" \
"../build/ip/sys_mem_5to2_axi_crossbar/synth/sys_mem_5to2_axi_crossbar.v" \

vlog -64 -work reco \
"$VIVADO_DATA_DIR/verilog/src/glbl.v"