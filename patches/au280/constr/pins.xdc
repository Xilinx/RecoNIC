# *************************************************************************
#
# Copyright 2020 Xilinx, Inc.
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

set_property -dict {PACKAGE_PIN BH26 IOSTANDARD LVCMOS18} [get_ports pcie_rstn]

# This file should be read in as unmanaged Tcl constraints to enable the usage
# of if statement
set_property PACKAGE_PIN AR14 [get_ports pcie_refclk_n]
set_property PACKAGE_PIN AR15 [get_ports pcie_refclk_p]

set num_ports [llength [get_ports qsfp_refclk_p]]
if {$num_ports >= 1} {
    set_property PACKAGE_PIN T43 [get_ports qsfp_refclk_n[0]]
    set_property PACKAGE_PIN T42 [get_ports qsfp_refclk_p[0]]
}
if {$num_ports >= 2} {
    set_property PACKAGE_PIN P43 [get_ports qsfp_refclk_n[1]]
    set_property PACKAGE_PIN P42 [get_ports qsfp_refclk_p[1]]
}

# Fix the CATTRIP issue for custom flow
set_property -dict {PACKAGE_PIN D32 IOSTANDARD LVCMOS18 PULLDOWN TRUE} [get_ports hbm_cattrip]

set_property -dict {PACKAGE_PIN D29 IOSTANDARD LVCMOS18} [get_ports satellite_uart_0_txd]
set_property -dict {PACKAGE_PIN E28 IOSTANDARD LVCMOS18} [get_ports satellite_uart_0_rxd]
set_property -dict {PACKAGE_PIN K28 IOSTANDARD LVCMOS18} [get_ports satellite_gpio[0]]
set_property -dict {PACKAGE_PIN J29 IOSTANDARD LVCMOS18} [get_ports satellite_gpio[1]]
set_property -dict {PACKAGE_PIN K29 IOSTANDARD LVCMOS18} [get_ports satellite_gpio[2]]
set_property -dict {PACKAGE_PIN J31 IOSTANDARD LVCMOS18} [get_ports satellite_gpio[3]]
