#==============================================================================
# Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
# SPDX-License-Identifier: MIT
#
#==============================================================================
VIVADO_DATA_DIR=$VIVADO_DIR/data
XVIP_PATH=$VIVADO_DATA_DIR/xilinx_vip
XVIP_INCLUDE=$XVIP_PATH/include

xvlog_opts="--relax --incr"
xvhdl_opts="--relax --incr"

xvlog $xvlog_opts -work reco -L cam_v2_2_2 -sv -L vitis_net_p4_v1_0_2 \
--include "../build/ip/packet_parser/hdl" --include "../build/ip/packet_parser/src/hw/include" \
--include "$XVIP_INCLUDE" \
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
"../build/ip/packet_parser/src/verilog/packet_parser.sv"

xvhdl $xvhdl_opts -work reco \
"../build/ip/axi_mm_bram/sim/axi_mm_bram.vhd"

xvhdl $xvhdl_opts -work reco \
"../build/ip/axi_sys_mm/sim/axi_sys_mm.vhd"

xvlog $xvlog_opts -work reco --include "../build/ip/reconic_axil_crossbar/hdl" \
"../build/ip/reconic_axil_crossbar/hdl/axi_crossbar_v2_1_vl_rfs.v" \
"../build/ip/reconic_axil_crossbar/hdl/axi_data_fifo_v2_1_vl_rfs.v" \
"../build/ip/reconic_axil_crossbar/hdl/axi_infrastructure_v1_1_vl_rfs.v" \
"../build/ip/reconic_axil_crossbar/hdl/axi_register_slice_v2_1_vl_rfs.v" \
"../build/ip/reconic_axil_crossbar/hdl/fifo_generator_v13_2_rfs.v" \
"../build/ip/reconic_axil_crossbar/hdl/generic_baseblocks_v2_1_vl_rfs.v" \
"../build/ip/reconic_axil_crossbar/sim/reconic_axil_crossbar.v"

xvlog $xvlog_opts -work reco -L axi_crossbar_v2_1_26 --include "../build/ip/axil_3to1_crossbar/hdl" \
"../build/ip/axil_3to1_crossbar/sim/axil_3to1_crossbar.v" \

xvlog $xvlog_opts -work reco -sv \
"../../base_nics/open-nic-shell/src/utility/generic_reset.sv" \
"../../base_nics/open-nic-shell/src/rdma_subsystem/rdma_subsystem.sv" \
"../../base_nics/open-nic-shell/src/rdma_subsystem/rdma_subsystem_wrapper.sv" \

xvlog $xvlog_opts -work reco -sv -L blk_mem_gen_v8_4_5 -L fifo_generator_v13_2_6 \
-i ../build/ip/axi_protocol_checker/hdl/verilog \
"../build/ip/axi_protocol_checker/hdl/sc_util_v1_0_vl_rfs.sv" \
"../build/ip/axi_protocol_checker/hdl/axi_protocol_checker_v2_0_vl_rfs.sv" \
"../build/ip/axi_protocol_checker/sim/axi_protocol_checker.sv"

xvlog $xvlog_opts -work reco -sv -L fifo_generator_v13_2_6 \
"../build/ip/dev_mem_axi_crossbar/synth/dev_mem_axi_crossbar.v" 

xvlog $xvlog_opts -d DEBUG -work reco -i ../../shell/compute/lookside/interface -f ./interface.f
xvlog $xvlog_opts -d DEBUG -work reco -i ../../shell/compute/lookside/kernel -f ./kernel.f

xvhdl $xvhdl_opts -work reco -L ernic_v3_1_1 \
"../build/ip/rdma_core/hdl/fifo_generator_v13_2_rfs.vhd" \
"../build/ip/rdma_core/hdl/lib_bmg_v1_0_rfs.vhd" \
"../build/ip/rdma_core/hdl/lib_fifo_v1_0_rfs.vhd"

xvlog $xvlog_opts -work reco -sv -L ernic_v3_1_1 -i ../build/ip/rdma_core/hdl/common \
"../build/ip/rdma_core/synth/rdma_core.sv"

xvlog $xvlog_opts -sv -L xpm -L ernic_v3_1_1 -L axi_bram_ctrl_v4_1_6 -d DEBUG -work reco \
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

xvlog $xvlog_opts -sv -d DEBUG -L axi_bram_ctrl_v4_1_6 -L xpm -work reco \
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

xvlog $xvlog_opts -work reco -sv -L fifo_generator_v13_2_6 \
"../build/ip/dev_mem_3to1_axi_crossbar/synth/dev_mem_3to1_axi_crossbar.v"

xvlog $xvlog_opts -work reco -sv -L fifo_generator_v13_2_6 \
"../build/ip/sys_mem_5to2_axi_crossbar/synth/sys_mem_5to2_axi_crossbar.v"

xvlog $xvlog_opts -work reco \
"$VIVADO_DATA_DIR/verilog/src/glbl.v"