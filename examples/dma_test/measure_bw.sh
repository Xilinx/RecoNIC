#!/bin/bash
#==============================================================================
# Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
# SPDX-License-Identifier: MIT
#
#==============================================================================
#
# How to use: (mode could be [write | read], default value is write)
# $ ./stress_test_bash.sh /dev/reconic-mm 2 mode
#==============================================================================

device=$1
no_threads=$2
counter=0

mode='write'
mode_arg=''

file="nohup.out"
sum=0

# Array to store the background process IDs
pids=()

if [ $# -gt 2 ]; then
	mode="$3"
fi

sudo chmod 666 /dev/reconic-mm

if [ -e "nohup.out" ]; then
	rm nohup.out
fi

if [ "$mode" = 'read' ]; then
	mode_arg="-r"
fi

echo -e "\nNumber of dma_test ($mode) threads: $no_threads"
for ((counter = 0 ; counter < no_threads ; counter++)); do
	nohup ./dma_test -d $device -s 65536000 -c 500 $mode_arg &
	pids+=($!)
done

# Wait for all background dma_test to finish
for pid in "${pids[@]}"; do
    wait "$pid"
done

echo "Calculate total $mode bandwidth achieved:"
while IFS= read -r line; do
    if [[ "$line" == *"Average BW ="* ]]; then
        number="${line#*= }"
        number="${number% GB/sec}"
        sum=$(bc -l <<< "$sum + $number")
    fi
done < "$file"

echo -e "-- The total $mode bandwidth is: $sum GB/sec\n"

