#!/bin/bash

# This is an optional script used to present the monitoring data in graphs.
# If monitoring data prepared by timing receivers is available it sends the data
# to a Graphite host using the UDP protocol.

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

# Graphite host IP address and port
SERVERIP=$1
SERVERPORT=2003

# snooper name (used as metric path)
TR1=ZT00ZM01
TR2=ZT00ZM02

# directory with monitoring data
MONDATA=/common/usr/timing/htdocs/cgi-bin/admin/data
TRDATA=tr

# data files
LATEN=laten
EARLYN=earlyn
OVERFLOWN=overflown
ACTIONN=actionn

# collect interval
INTERVAL=30

# arrays with monitoring data files and metric key
IDX=0
MONDATA_FILES=()
METRIC_KEYS=($LATEN $EARLYN $OVERFLOWN $ACTIONN)
MONDATA_DIR=$MONDATA/$TRDATA

# check if file with monitoring data exists
for i in 1 2; do
	for key in "${METRIC_KEYS[@]}"; do

		# check if file with monitoring data exists
		FILE_PATH=$MONDATA_DIR/$i/$key
		if [ -f $FILE_PATH ]; then
			# add file path to a corresponding array
			MONDATA_FILES[IDX]=$FILE_PATH
		else
			echo "File not found: $FILE_PATH"
		fi

		IDX=`expr $IDX + 1`

	done
done

# exit if no file with monitoring data is found
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

	# for each timing receiver check if monitoring data is available and send it to Graphite host
	for MONDATA_FILE in "${MONDATA_FILES[@]}"; do
		METRIC_VAL=$(tail -1 $MONDATA_FILE)            # read monitoring data

		if [ "$METRIC_VAL" != "" ]; then
			# build metric key
			TR_AND_FILE=${MONDATA_FILE#${MONDATA_DIR}/}    # get '1/actionn' from full path
			TR_NUM=TR${TR_AND_FILE%%/*}                    # get '1' from '1/actionn' and build 'TR1'
			FILE_NAME=${TR_AND_FILE##*/}                   # get 'actionn' from '1/actionn'
			METRIC_KEY=${TRDATA}.${!TR_NUM}.${FILE_NAME%n} # build 'tr.ZT00ZM01.action'

			# send metric (metric key, metric value and timestamp) to Graphite
			echo "$METRIC_KEY $METRIC_VAL $TIMESTAMP" | nc $SERVERIP -u $SERVERPORT
		fi
	done

	sleep $INTERVAL
done
