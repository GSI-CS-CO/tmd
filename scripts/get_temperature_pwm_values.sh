#!/bin/bash

# Get the temperature group values (FPGA & PLL temperature, PWM) using SNMP and
# send them to a Grafana server (using host and port) in given interval (interval).

# SNMP
snmp_opts="-c public -v 2c -O q -m ALL -M +$HOME"  # -O q: quick print with easier parsing
snmp_oid="wrsTemperatureGroup"

# carbon server: host=localhost, port=2003
host="localhost"
port=2003

# metric structure: test.<wrs_name>.<metric>
group="test"
metrics=("FPGA" "PLL" "FanPwmVal")

# interval (seconds)
interval=600

# target WRSs
switches=("nwt0105m66" "nwt0296m66" "nwt0297m66")

while :
do
    for switch in ${switches[@]}; do
        timestamp=$(date +%s)
        #echo "$snmp_opts $switch.timing $snmp_oid"
        snmp_response="$(snmpwalk $snmp_opts $switch.timing $snmp_oid)"
        #echo "$snmp_response" # WR-SWITCH-MIB::wrsTempFanPwmVal.0 40

        for m in ${metrics[@]}; do
            # parse a metric in 'snmp_response'
            while IFS= read -r line
            do
                # get a value by trimming the leading part (WR-SWITCH-MIB::wrsTempFanPwmVal.0 )
                value=${line#*${m}.0[[:space:]]}

                if [ "${value:0:2}" != "WR" ]; then
                    break                        # break if metric's value is obtained
                fi
            done <<<"$snmp_response"

            metric=${m,,}                        # convert metric name to lowercase

            #echo "$(date -d @$timestamp +"%F %T") $switch $metric $value"
            echo "$group.$switch.$metric $value $timestamp"
            echo "$group.$switch.$metric $value $timestamp" | nc -u $host $port
        done
    done
    sleep $interval
done
