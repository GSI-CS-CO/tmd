#!/bin/bash

# This script is used to launch the push scripts that
# send GMT monitoring data to Grafana running on the tsl019 host.

# TOS_GRAFANA_HOST (domain name or IP address)
if [ -z "$TOS_GRAFANA_HOST" ]; then
    echo "Need to set TOS_GRAFANA_HOST. Exit!"
    exit 1
fi

# list of push scripts
LIST_PUSH_SCRIPTS=(push-dm-mon.sh
push-prod-lm-mon.sh
push-gw-mon.sh
push-tr-mon.sh
push-diag-mon.sh
push-uni-mon.sh
)

# Terminate running scripts
for item in ${LIST_PUSH_SCRIPTS[@]}; do
    killall $item
done

# Start scripts
for item in ${LIST_PUSH_SCRIPTS[@]}; do
    if [ -f $item ]; then
        eval "./$item $TOS_GRAFANA_HOST &"
    fi
done
