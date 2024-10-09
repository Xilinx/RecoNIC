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
set system_management_wiz system_management_wiz
create_ip -name system_management_wiz -vendor xilinx.com -library ip -module_name $system_management_wiz -dir ${ip_build_dir}
set_property -dict {
    CONFIG.INTERFACE_SELECTION {Enable_AXI}
    CONFIG.ENABLE_RESET {false}
    CONFIG.OT_ALARM {false}
    CONFIG.USER_TEMP_ALARM {false}
    CONFIG.VCCINT_ALARM {false}
    CONFIG.VCCAUX_ALARM {false}
    CONFIG.ENABLE_VBRAM_ALARM {false}
    CONFIG.CHANNEL_ENABLE_VP_VN {true}
    CONFIG.AVERAGE_ENABLE_VBRAM {true}
    CONFIG.AVERAGE_ENABLE_TEMPERATURE {true}
    CONFIG.AVERAGE_ENABLE_VCCINT {true}
    CONFIG.AVERAGE_ENABLE_VCCAUX {true}
    CONFIG.AVERAGE_ENABLE_TEMPERATURE_SLAVE0_SSIT {true}
    CONFIG.AVERAGE_ENABLE_TEMPERATURE_SLAVE1_SSIT {true}
    CONFIG.CHANNEL_ENABLE_VUSER0_SLAVE0_SSIT {true}
    CONFIG.AVERAGE_ENABLE_VUSER0_SLAVE0_SSIT {true}
    CONFIG.CHANNEL_ENABLE_VUSER0_SLAVE1_SSIT {true}
    CONFIG.AVERAGE_ENABLE_VUSER0_SLAVE1_SSIT {true}
    CONFIG.Enable_Slave0 {true}
    CONFIG.Enable_Slave1 {true}
} [get_ips $system_management_wiz]
