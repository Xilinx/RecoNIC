#!/bin/bash
#==============================================================================
# Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
# SPDX-License-Identifier: MIT
#
#==============================================================================
sizes=( 4096 8192 16384 32768 65536 131072 262144 524288 1048576 2097152 4194304 8388608 16777216 33554432 67108864 134217728 )
count=500
sudo chmod 666 /dev/reconic-mm
for size in "${sizes[@]}"
do
	./dma_test -d /dev/reconic-mm -s $size -c $count -r >> results.txt
done
