#!/bin/bash
#==============================================================================
# Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
# SPDX-License-Identifier: MIT
#
#==============================================================================
#
# How to use: (mode could be [write | read])
# $ ./measure_dma.sh /dev/reconic-mm num_thread mode size
#   e.g., ./measure_dma.sh /dev/reconic-mm 4 read 16384
#==============================================================================

device=$1
no_threads=$2
counter=0

mode='write'
mode_arg=''

file="nohup.out"
sum_bw=0
sum_lat=0
ave_bw=0
ave_lat=0
bw_unit="GB/s"

size=4096

# Array to store the background process IDs
pids=()

if [ $# -gt 3 ]; then
	mode="$3"
  size=$4
fi

size_in_B=$((size * no_threads / 1024))

sudo chmod 666 /dev/reconic-mm

if [ -e "nohup.out" ]; then
	rm nohup.out
fi

if [ "$mode" = 'read' ]; then
	mode_arg="-r"
fi

echo -e "\nNumber of dma_test ($mode) threads: $no_threads; Transfer size= $size_in_B KB"
for ((counter = 0 ; counter < no_threads ; counter++)); do
	nohup ./dma_test -d $device -s $size -c 500 $mode_arg &
	pids+=($!)
done

# Wait for all background dma_test to finish
for pid in "${pids[@]}"; do
    wait "$pid"
done

echo "Calculate total $mode bandwidth achieved:"
while IFS= read -r line; do
    if [[ "$line" == *"Average BW ="* ]]; then
        number_string="${line#*= }"
        #echo -e "number_string = $number_string"
        #bw_string=($(echo "$number_string" | grep -oE '[0-9.]+ [A-Za-z]+/sec'))
        latency_string=$(echo "$number_string" | grep -oE '[0-9.]+ us')
        bw_string=$(echo "$number_string" | grep -oE '[0-9.]+ [A-Za-z]+/sec' | head -n 1)
        #echo "bw_string = $bw_string"
        bw=$(echo "$bw_string" | awk '{print $1}')
        bw_unit=$(echo "$bw_string" | awk '{print $2}')
        echo "Bandwidth: $bw, Unit: $bw_unit"
        
        lat=$(echo "$latency_string" | awk '{print $1}')
        lat_unit=$(echo "$latency_string" | awk '{print $2}')
        #echo "Latency: $lat, lat_unit: $lat_unit"

        sum_bw=$(bc -l <<< "$sum_bw + $bw")
        sum_lat=$(bc -l <<< "$sum_lat + $lat")
    fi
done < "$file"

ave_lat=$(bc -l <<< "$sum_lat / $counter")

echo -e "-- The total $mode bandwidth for $size_in_B KB data is: $sum_bw $bw_unit; Its average latency is: $ave_lat us\n"

