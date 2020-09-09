#!/bin/bash

# This is an optional script used to present the data master statistics in graphs.
# The UDP protocol is used to send statistics data to a Graphite host.

# Check argument
if [ $# -ne 1 ]; then
	echo "Usage: $0 Graphite_host (host.domain or IP address)"
	exit 1
fi

# load common functions
COMMON_SCRIPT="push-common.sh"
if [ -f $COMMON_SCRIPT ]; then
	source $COMMON_SCRIPT
else
	echo "Missing $COMMON_SCRIPT. Exit!"
	exit 1
fi

# Graphite host and port
SERVERIP=$1
SERVERPORT=2003

# device name (used in metric path)
DM=ZT00ZZ1

# directories with monitoring data
MONDATA=/common/usr/timing/htdocs/cgi-bin/admin/data
DMDATA=dm
CPU0DATA=cpu0
CPU1DATA=cpu1
CPU2DATA=cpu2
CPU3DATA=cpu3
CPUXDATA=total
WRDATA=wr

CPUS=($CPU0DATA $CPU1DATA $CPU2DATA $CPU3DATA $CPUXDATA)

# files with statistics
RATE10S=rate10s
RATE1M=rate1m
RATE1H=rate1h

WRATE10S=wrate10s
WRATE1M=wrate1m
WRATE1H=wrate1h

STATUS=status    # WR sync status

RATES=($RATE10S)

# polling interval
INTERVAL=30

# arrays with port statistics files
IDX=0
MONDATA_DIR=$MONDATA/$DMDATA
MONDATA_FILES=()

# check if files ($MONDATA_DIR/cpu0/rate10s) with CPU statistics exist
for cpu in "${CPUS[@]}"; do

	for rate in "${RATES[@]}"; do
		FILE_PATH=$MONDATA_DIR/$cpu/$rate
		if [ -f $FILE_PATH ]; then
			MONDATA_FILES[IDX]=$FILE_PATH
		else
			echo "File not found: $FILE_PATH"
		fi

		IDX=`expr $IDX + 1`
	done

done

# check if files ($MONDATA_DIR/wr/status) with WR sync status exist
FILE_PATH=$MONDATA_DIR/$WRDATA/$STATUS
if [ -f $FILE_PATH ]; then
	MONDATA_FILES[IDX]=$FILE_PATH
else
	echo "File not found: $FILE_PATH"
fi

IDX=`expr $IDX + 1`

# exit here if no file with monitoring data is found
if [ ${#MONDATA_FILES[*]} -eq 0 ]; then
	echo "No files with monitoring data found in $MONDATA_DIR. Exit!"
	exit 1
else
	echo "List of files with monitoring data:"
	for file in "${MONDATA_FILES[@]}"; do
		echo $file
	done
	echo "Sending monitoring data to $SERVERIP:$SERVERPORT every $INTERVAL seconds."
fi

# main stuff
while true; do

	# update timestamp
	TIMESTAMP=`date +%s`

	# read each file with monitoring data and send it to Graphite host
	for MONDATA_FILE in "${MONDATA_FILES[@]}"; do

		# read monitoring data
		METRIC_VAL=$(tail -1 $MONDATA_FILE)

		# if metric value is available then send it
		if [ "$METRIC_VAL" != "" ]; then

			METRIC_ALL=${MONDATA_FILE#${MONDATA_DIR}/}        # get 'cpu?/rate*', 'wr/status' from full path
			METRIC_ALL_GRAPH=${METRIC_ALL////.}               # replace all matching '/' with '.' (Graphite compatible)
			METRIC_NAME=${METRIC_ALL_GRAPH##*.}               # get 'rate*', or 'status'

			# convert WR sync status to numeric value
			if [ "$METRIC_NAME" == "$STATUS" ]; then
				METRIC_VAL=$(get_sync_numeric "$METRIC_VAL")
			fi

			METRIC_KEY=${DMDATA}.${DM}.$METRIC_ALL_GRAPH      # build metric key: dm.ZT00ZZ1.cpu*|total.rate*

			# send metric key, metric value and timestamp to the Graphite host
			if [ "$METRIC_KEY" != "" ]; then
				echo "$METRIC_KEY $METRIC_VAL $TIMESTAMP" | nc $SERVERIP -u $SERVERPORT
			fi
		fi
	done

	sleep $INTERVAL
done
