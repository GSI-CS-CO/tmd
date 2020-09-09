#!/bin/bash

# This is an optional script used to present the clock master statistics in graphs.
# It sends packet rate evaluated by clock master (WR switch) to a Graphite
# host using the UDP protocol.

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
CM=nwt0013m66

# directory with monitoring data
MONDATA=/common/usr/timing/htdocs/cgi-bin/admin/data
NWDATA=nw

# files with port names
PORTD0=dmport
PORTD1=d1port
PORTD2=d2port
PORTD3=d3port

# folders with data files
D0TXDATA=dmtx
D0RXDATA=dmrx
D1TXDATA=d1tx
D1RXDATA=d1rx
D2TXDATA=d2tx
D2RXDATA=d2rx
D3TXDATA=d3tx
D3RXDATA=d3rx

# files with port statistics
RATE10S=rate10s
RATE1M=rate1m
RATE1H=rate1h
RATES=($RATE10S)

# polling interval
INTERVAL=30

# arrays with port statistics files
IDX=0
MONDATA_DIR=$MONDATA/$NWDATA
MONDATA_FILES=()

# check if files with monitoring data exist
for i in 0 1 2 3; do

	TX_DIR=D${i}TXDATA

	for rate in "${RATES[@]}"; do
		FILE_PATH=$MONDATA_DIR/${!TX_DIR}/$rate
		if [ -f $FILE_PATH ]; then
			MONDATA_FILES[IDX]=$FILE_PATH
		else
			echo "File not found: $FILE_PATH"
		fi

		IDX=`expr $IDX + 1`
	done

	RX_DIR=D${i}RXDATA

	for rate in "${RATES[@]}"; do
		FILE_PATH=$MONDATA_DIR/${!RX_DIR}/$rate
		if [ -f $FILE_PATH ]; then
			MONDATA_FILES[IDX]=$FILE_PATH
		else
			echo "File not found: $FILE_PATH"
		fi

		IDX=`expr $IDX + 1`
	done
done

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

			DL_TX_RX_RATE=${MONDATA_FILE#${MONDATA_DIR}/}   # get 'd??x/rate*' from full path
			DL_TX_RX=${DL_TX_RX_RATE%%/rate*}               # get 'd??x' from 'd??x/rate*
			DL_NAME=${DL_TX_RX%?x}                          # get 'd?' from 'd??x'
			TX_RX=${DL_TX_RX#d?}                            # get '?x' from 'd??x'
			METRIC_NAME=${DL_TX_RX_RATE##*/}                # get 'rate*'

			FILE_PATH=$MONDATA_DIR/${DL_NAME}port        # $MONDATA/d?port
			if [ -f $FILE_PATH ]; then
				PORT_NAME=$(tail -1 $FILE_PATH)
			fi

			# send metric key, metric value and timestamp to the Graphite host
			METRIC_KEY=${NWDATA}.${CM}.${DL_NAME}.${PORT_NAME}.${TX_RX}.${METRIC_NAME}  # nw.nwt0013m66.dm.port1.tx.rate10s
			echo "$METRIC_KEY $METRIC_VAL $TIMESTAMP" | nc $SERVERIP -u $SERVERPORT
		fi
	done

	sleep $INTERVAL
done
