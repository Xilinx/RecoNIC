#!/bin/bash
#==============================================================================
# Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
# SPDX-License-Identifier: MIT
#
#==============================================================================
set -Eeuo pipefail

echo -e "gen_base_nic.sh -- Generate the basic NIC with an RDMA offloading engine"

cur_dir=$(pwd)
root_dir=$(dirname $cur_dir)
nic_dir=${root_dir}/base_nics/open-nic-shell
nic_patch=${root_dir}/patches/open-nic-shell/rdma_onic.patch

cd ${nic_dir}
git apply --whitespace=fix ${nic_patch}

echo -e "gen_base_nic.sh done!"

cd ${cur_dir}

$SHELL