#!/bin/bash
#==============================================================================
# Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
# SPDX-License-Identifier: MIT
#
#==============================================================================
set -Eeuo pipefail

echo -e "gen_nic_driver.sh -- Generate the NIC driver for RecoNIC"

cur_dir=$(pwd)
root_dir=$(dirname $cur_dir)
drv_dir=${root_dir}/drivers/onic-driver
drv_patch=${root_dir}/patches/open-nic-driver/onic.patch

cd ${drv_dir}
git apply --whitespace=fix ${drv_patch}

echo -e "gen_nic_driver.sh done!"

cd ${cur_dir}

$SHELL