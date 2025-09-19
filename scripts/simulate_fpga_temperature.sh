#!/bin/bash

# Simulate the temperature value (between min and max degrees) and
# send it to a Grafana server (using host and port) in given interval (interval).

# simulated temperature range
min=50
max=85

# temperature metric name
metric="test.nwt0297m66.Temperature.perfdata.sensor.fpga.value"

# Graphite server: host=localhost, port=2003
host="localhost"
port=2003

# interval (seconds)
interval=1800

while :
do
    data=$(($RANDOM%($max-$min+1)+$min))
    timestamp=$(date +%s)
    echo "$(date -d @$timestamp +"%F %T") $data"
    echo "$metric $data $timestamp" | nc -u $host $port
    sleep $interval
done

# Setting for testing the Grafana alert (on WRS FPGA temperature increase)

# A. Query
# interval = 15m
# functions = derivative() + keepLastValue()

# B. Reduce
# input = A, function = last, mode = strict

# C. Threshold
# input = B, is above = 10 (10 = simulated value, 1 = real value, 3 = production)
