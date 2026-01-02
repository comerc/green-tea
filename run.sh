#!/bin/bash

set -e

echo "Building Docker image..."
# Build the Docker image quietly
docker build -f Dockerfile -t go-gc-benchmark . > /dev/null 2>&1

echo "Running 10 tests with Standard GC and 10 tests with Green Tea GC..."
echo ""

# Run the container and capture output
output=$(docker run --rm --memory=256m go-gc-benchmark)

# Extract results using grep and awk
# Result format: RESULT: time_ms,pause_ms,cycles,alloc_mb

# Parse Standard GC results
std_times=$(echo "$output" | sed -n '/STD_GC_START/,/STD_GC_END/p' | grep "RESULT:" | awk -F'[:,]' '{print $2}')
std_pauses=$(echo "$output" | sed -n '/STD_GC_START/,/STD_GC_END/p' | grep "RESULT:" | awk -F'[:,]' '{print $3}')

# Parse GreenTea GC results
gt_times=$(echo "$output" | sed -n '/GREENTEA_GC_START/,/GREENTEA_GC_END/p' | grep "RESULT:" | awk -F'[:,]' '{print $2}')
gt_pauses=$(echo "$output" | sed -n '/GREENTEA_GC_START/,/GREENTEA_GC_END/p' | grep "RESULT:" | awk -F'[:,]' '{print $3}')

# Calculate averages using awk
avg_std_time=$(echo "$std_times" | awk '{s+=$1} END {printf "%.2f", s/NR}')
avg_std_pause=$(echo "$std_pauses" | awk '{s+=$1} END {printf "%.2f", s/NR}')

avg_gt_time=$(echo "$gt_times" | awk '{s+=$1} END {printf "%.2f", s/NR}')
avg_gt_pause=$(echo "$gt_pauses" | awk '{s+=$1} END {printf "%.2f", s/NR}')

# Calculate improvement
time_diff=$(echo "$avg_std_time - $avg_gt_time" | bc -l)
percent_diff=$(echo "$time_diff / $avg_std_time * 100" | bc -l)

echo "╔══════════════════════════════════════════════════════════╗"
echo "║                   BENCHMARK REPORT                       ║"
echo "╠══════════════════════════════════════════════════════════╣"
printf "║ %-26s │ %-12s │ %-12s ║\n" "Metric" "Standard GC" "Green Tea GC"
echo "╟────────────────────────────┼──────────────┼──────────────╢"
printf "║ %-26s │ %9s ms │ %9s ms ║\n" "Avg Total Time (20 cycles)" "$avg_std_time" "$avg_gt_time"
printf "║ %-26s │ %9s ms │ %9s ms ║\n" "Avg GC Pause (per cycle)" "$avg_std_pause" "$avg_gt_pause"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

if (( $(echo "$percent_diff > 0" | bc -l) )); then
    printf "🚀 RESULT: Green Tea GC is FASTER by %.2f%%\n" "$percent_diff"
else
    printf "🐌 RESULT: Standard GC is faster by %.2f%%\n" "$(echo "$percent_diff * -1" | bc -l)"
fi
echo ""
echo "Raw Data - Total Time (ms):"
echo "Standard:"
echo $std_times
echo "GreenTea:"
echo $gt_times
echo ""
echo "Raw Data - Avg GC Pause (ms):"
echo "Standard:"
echo $std_pauses
echo "GreenTea:"
echo $gt_pauses
