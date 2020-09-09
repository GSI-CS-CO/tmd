#!/bin/bash

# This script is used to launch the push scripts that
# send GMT monitoring data to Grafana running on the tsl019 host.

# TOS_GRAFANA_HOST (domain name or IP address)
if [ -z "$TOS_GRAFANA_HOST" ]; then
    echo "Need to set TOS_GRAFANA_HOST. Exit!"
    exit 1
fi

# Terminate running scripts
killall push-dm-mon.sh
killall push-prod-lm-mon.sh
killall push-gw-mon.sh
killall push-tr-mon.sh
killall push-diag-mon.sh
killall push-uni-mon.sh

# Start scripts
push-dm-mon.sh $TOS_GRAFANA_HOST &
push-prod-lm-mon.sh $TOS_GRAFANA_HOST &
push-gw-mon.sh $TOS_GRAFANA_HOST &
push-tr-mon.sh $TOS_GRAFANA_HOST &
push-diag-mon.sh $TOS_GRAFANA_HOST &
push-uni-mon.sh $TOS_GRAFANA_HOST &
