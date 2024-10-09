# *************************************************************************
#
# Copyright 2023 Xilinx, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# *************************************************************************
set ddr4_controller dev_mem_ddr4_controller

create_ip -name ddr4 -vendor xilinx.com -library ip -version 2.2 -module_name $ddr4_controller -dir ${ip_build_dir}

set_property -dict {
    CONFIG.C0.ControllerType {DDR4_SDRAM}
    CONFIG.IOPowerReduction {OFF}
    CONFIG.Enable_SysPorts {true}
    CONFIG.Phy_Only {Complete_Memory_Controller}
    CONFIG.RESET_BOARD_INTERFACE {pcie_perstn}
    CONFIG.C0_CLOCK_BOARD_INTERFACE {sysclk0}
    CONFIG.IS_FROM_PHY {1}
    CONFIG.RECONFIG_XSDB_SAVE_RESTORE {false}
    CONFIG.AL_SEL {0}
    CONFIG.Example_TG {SIMPLE_TG}
    CONFIG.C0.DDR4_Clamshell {false}
    CONFIG.C0.MIGRATION {false}
    CONFIG.TIMING_OP1 {false}
    CONFIG.TIMING_OP2 {false}
    CONFIG.TIMING_3DS {false}
    CONFIG.SET_DW_TO_40 {false}
    CONFIG.DIFF_TERM_SYSCLK {false}
    CONFIG.C0_DDR4_BOARD_INTERFACE {ddr4_sdram_c0}
    CONFIG.C0.DDR4_TimePeriod {833}
    CONFIG.C0.DDR4_InputClockPeriod {3332}
    CONFIG.C0.DDR4_Specify_MandD {false}
    CONFIG.C0.DDR4_CLKFBOUT_MULT {5}
    CONFIG.C0.DDR4_DIVCLK_DIVIDE {1}
    CONFIG.C0.DDR4_CLKOUT0_DIVIDE {5}
    CONFIG.C0.DDR4_PhyClockRatio {4:1}
    CONFIG.C0.DDR4_MemoryType {RDIMMs}
    CONFIG.C0.DDR4_MemoryPart {MTA18ASF2G72PZ-2G3}
    CONFIG.C0.DDR4_Slot {Single}
    CONFIG.C0.DDR4_MemoryVoltage {1.2V}
    CONFIG.C0.DDR4_DataWidth {72}
    CONFIG.C0.DDR4_DataMask {NONE}
    CONFIG.C0.DDR4_Ecc {true}
    CONFIG.C0.DDR4_AxiSelection {true}
    CONFIG.C0.DDR4_AUTO_AP_COL_A3 {true}
    CONFIG.C0.DDR4_Ordering {Normal}
    CONFIG.C0.DDR4_BurstLength {8}
    CONFIG.C0.DDR4_BurstType {Sequential}
    CONFIG.C0.DDR4_OutputDriverImpedenceControl {RZQ/7}
    CONFIG.C0.DDR4_OnDieTermination {RZQ/6}
    CONFIG.C0.DDR4_CasLatency {17}
    CONFIG.C0.DDR4_CasWriteLatency {12}
    CONFIG.C0.DDR4_ChipSelect {true}
    CONFIG.C0.DDR4_isCKEShared {false}
    CONFIG.C0.DDR4_AxiDataWidth {512}
    CONFIG.C0.DDR4_AxiArbitrationScheme {RD_PRI_REG}
    CONFIG.C0.DDR4_AxiNarrowBurst {false}
    CONFIG.C0.DDR4_AxiAddressWidth {34}
    CONFIG.C0.DDR4_AxiIDWidth {8}
    CONFIG.C0.DDR4_Capacity {512}
    CONFIG.C0.DDR4_Mem_Add_Map {ROW_COLUMN_BANK_INTLV}
    CONFIG.C0.DDR4_MemoryName {MainMemory}
    CONFIG.C0.DDR4_AutoPrecharge {false}
    CONFIG.C0.DDR4_UserRefresh_ZQCS {false}
    CONFIG.C0.DDR4_CustomParts {no_file_loaded}
    CONFIG.C0.DDR4_isCustom {false}
    CONFIG.C0.DDR4_SELF_REFRESH {false}
    CONFIG.C0.DDR4_SAVE_RESTORE {false}
    CONFIG.C0.DDR4_RESTORE_CRC {false}
    CONFIG.ADDN_UI_CLKOUT1_FREQ_HZ {250}
    CONFIG.ADDN_UI_CLKOUT2_FREQ_HZ {None}
    CONFIG.ADDN_UI_CLKOUT3_FREQ_HZ {None}
    CONFIG.ADDN_UI_CLKOUT4_FREQ_HZ {None}
    CONFIG.CLKOUT6 {false}
    CONFIG.No_Controller {1}
    CONFIG.System_Clock {Differential}
    CONFIG.Reference_Clock {Differential}
    CONFIG.Debug_Signal {Disable}
    CONFIG.IO_Power_Reduction {false}
    CONFIG.DCI_Cascade {false}
    CONFIG.Default_Bank_Selections {false}
    CONFIG.Simulation_Mode {BFM}
    CONFIG.PARTIAL_RECONFIG_FLOW_MIG {false}
    CONFIG.MCS_DBG_EN {false}
    CONFIG.C0.DDR4_CK_SKEW_0 {0}
    CONFIG.C0.DDR4_CK_SKEW_1 {0}
    CONFIG.C0.DDR4_CK_SKEW_2 {0}
    CONFIG.C0.DDR4_CK_SKEW_3 {0}
    CONFIG.C0.DDR4_ADDR_SKEW_0 {0}
    CONFIG.C0.DDR4_ADDR_SKEW_1 {0}
    CONFIG.C0.DDR4_ADDR_SKEW_2 {0}
    CONFIG.C0.DDR4_ADDR_SKEW_3 {0}
    CONFIG.C0.DDR4_ADDR_SKEW_4 {0}
    CONFIG.C0.DDR4_ADDR_SKEW_5 {0}
    CONFIG.C0.DDR4_ADDR_SKEW_6 {0}
    CONFIG.C0.DDR4_ADDR_SKEW_7 {0}
    CONFIG.C0.DDR4_ADDR_SKEW_8 {0}
    CONFIG.C0.DDR4_ADDR_SKEW_9 {0}
    CONFIG.C0.DDR4_ADDR_SKEW_10 {0}
    CONFIG.C0.DDR4_ADDR_SKEW_11 {0}
    CONFIG.C0.DDR4_ADDR_SKEW_12 {0}
    CONFIG.C0.DDR4_ADDR_SKEW_13 {0}
    CONFIG.C0.DDR4_ADDR_SKEW_14 {0}
    CONFIG.C0.DDR4_ADDR_SKEW_15 {0}
    CONFIG.C0.DDR4_ADDR_SKEW_16 {0}
    CONFIG.C0.DDR4_ADDR_SKEW_17 {0}
    CONFIG.C0.DDR4_BA_SKEW_0 {0}
    CONFIG.C0.DDR4_BA_SKEW_1 {0}
    CONFIG.C0.DDR4_BG_SKEW_0 {0}
    CONFIG.C0.DDR4_BG_SKEW_1 {0}
    CONFIG.C0.DDR4_CS_SKEW_0 {0}
    CONFIG.C0.DDR4_CS_SKEW_1 {0}
    CONFIG.C0.DDR4_CS_SKEW_2 {0}
    CONFIG.C0.DDR4_CS_SKEW_3 {0}
    CONFIG.C0.DDR4_CKE_SKEW_0 {0}
    CONFIG.C0.DDR4_CKE_SKEW_1 {0}
    CONFIG.C0.DDR4_CKE_SKEW_2 {0}
    CONFIG.C0.DDR4_CKE_SKEW_3 {0}
    CONFIG.C0.DDR4_ACT_SKEW {0}
    CONFIG.C0.DDR4_PAR_SKEW {0}
    CONFIG.C0.DDR4_ODT_SKEW_0 {0}
    CONFIG.C0.DDR4_ODT_SKEW_1 {0}
    CONFIG.C0.DDR4_ODT_SKEW_2 {0}
    CONFIG.C0.DDR4_ODT_SKEW_3 {0}
    CONFIG.C0.DDR4_LR_SKEW_0 {0}
    CONFIG.C0.DDR4_LR_SKEW_1 {0}
    CONFIG.C0.DDR4_TREFI {0}
    CONFIG.C0.DDR4_TRFC {0}
    CONFIG.C0.DDR4_TRFC_DLR {0}
    CONFIG.C0.DDR4_TXPR {0}
    CONFIG.C0.DDR4_nCK_TREFI {0}
    CONFIG.C0.DDR4_nCK_TRFC {0}
    CONFIG.C0.DDR4_nCK_TRFC_DLR {0}
    CONFIG.C0.DDR4_nCK_TXPR {0}
    CONFIG.C0.ADDR_WIDTH {17}
    CONFIG.C0.BANK_GROUP_WIDTH {2}
    CONFIG.C0.LR_WIDTH {1}
    CONFIG.C0.CK_WIDTH {1}
    CONFIG.C0.CKE_WIDTH {1}
    CONFIG.C0.CS_WIDTH {1}
    CONFIG.C0.ODT_WIDTH {1}
    CONFIG.C0.StackHeight {1}
    CONFIG.PING_PONG_PHY {1}
    CONFIG.C0.DDR4_Enable_LVAUX {false}
    CONFIG.C0.DDR4_EN_PARITY {true}
    CONFIG.EN_PP_4R_MIR {false}
    CONFIG.MCS_WO_DSP {false}
    CONFIG.C0_SYS_CLK_I.INSERT_VIP {0}
    CONFIG.C0_DDR4_S_AXI_CTRL.INSERT_VIP {0}
    CONFIG.C0_DDR4_S_AXI.INSERT_VIP {0}
    CONFIG.C0_DDR4_ARESETN.INSERT_VIP {0}
    CONFIG.C0_DDR4_RESET.INSERT_VIP {0}
    CONFIG.C0_DDR4_CLOCK.INSERT_VIP {0}
    CONFIG.ADDN_UI_CLKOUT1.INSERT_VIP {0}
    CONFIG.ADDN_UI_CLKOUT2.INSERT_VIP {0}
    CONFIG.ADDN_UI_CLKOUT3.INSERT_VIP {0}
    CONFIG.ADDN_UI_CLKOUT4.INSERT_VIP {0}
    CONFIG.SYSTEM_RESET.INSERT_VIP {0}
} [get_ips $ddr4_controller]
