#!/bin/sh

# Internal script running inside Docker

echo "Running 10 iterations..."

echo "STD_GC_START"
for i in $(seq 1 10); do
    ./benchmark_std | grep "RESULT:"
done
echo "STD_GC_END"

echo "GREENTEA_GC_START"
for i in $(seq 1 10); do
    ./benchmark_greentea | grep "RESULT:"
done
echo "GREENTEA_GC_END"
