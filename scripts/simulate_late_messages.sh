#!/bin/bash

# Simulate the late messages (up to 10) and
# send it to a Grafana server (using host and port) in given interval (interval).

# simulate late messages
rmin=1
rmax=20
threshold=5
nlate=0

# temperature metric name
metric="test.nlate"

# Graphite server: host=localhost, port=2003
host="localhost"
port=2003

# interval (seconds)
interval=60

while :
do
    data=$nlate
    timestamp=$(date +%s)
    echo "$(date -d @$timestamp +"%F %T") $data"
    echo "$metric $data $timestamp" | nc -u $host $port

    sleep $interval
    random=$(( $RANDOM%($rmax-$rmin+1)+$rmin ))
    echo "random: $random"
    #if [ $random -le $threshold ]; then
    #    nlate=$(( nlate + random ))
    #fi
done

# Setting for testing the Grafana alert

# A. Query
# range = 5m, interval = 1m
# functions = derivative() + keepLastValue()

# B. Classic condition
# conditions: when = last() of = A, is above = 0

