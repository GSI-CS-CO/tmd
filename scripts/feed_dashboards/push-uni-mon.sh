#!/bin/bash

# This is an optional script used to present the UNILAC statistics in graphs.
# It sends monitoring data evaluated by scuxl0183 and nwt0285m66 to a Graphite
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

# device name
LM_NAME="" # get the name of the localmaster WRS from 'wrs' file
PZ="" # get the name of the Pulszentrale node from 'unipz' file

# directory with monitoring data
MONDATA=/common/usr/timing/htdocs/cgi-bin/admin/data
UNIPZDATA=unipz    # pulsezentral
UNINWDATA=uninw    # WRS

# files with pulsezentrale statistics
MESSRATE=messrate
WARNCNT=warncnt
MAINSF=mainsf
WRSYNC=wrsync
PZ_FILES=($MESSRATE $WARNCNT $MAINSF $WRSYNC)

# files with WRS port names
PORTD0=dmport
PORTD1=d1port
PORTD2=d2port
PORTD3=d3port

# subdirectories for WRS ports
D0TXDATA=dmtx
D0RXDATA=dmrx
D1TXDATA=d1tx
D1RXDATA=d1rx
D2TXDATA=d2tx
D2RXDATA=d2rx
D3TXDATA=d3tx
D3RXDATA=d3rx

# files with WRS port statistics
RATE10S=rate10s
RATE1M=rate1m
RATE1H=rate1h
RATES=($RATE10S)

# polling interval
INTERVAL=30

# arrays with port statistics files
IDX=0
MONDATA_FILES=()

# get files with pulsezentrale monitoring data
MONDATA_DIR=$MONDATA/$UNIPZDATA

# get the name of the Pulszentrale node
FILE_PATH=$MONDATA_DIR/unipz
if [ -f $FILE_PATH ]; then
    full_name=$(cat $FILE_PATH) # scuxl0183.acc.gsi.de
    PZ=${full_name%%.*}    # scuxl0183
else
    echo "Could not get the name of the Pulszentrale node from file: $FILE_PATH"
    exit 1
fi

for file in "${PZ_FILES[@]}"; do

		FILE_PATH=$MONDATA_DIR/$file
		if [ -f $FILE_PATH ]; then
			MONDATA_FILES[IDX]=$FILE_PATH
		else
			echo "File not found: $FILE_PATH"
		fi

		IDX=`expr $IDX + 1`
done

# get files with network monitoring data
MONDATA_DIR=$MONDATA/$UNINWDATA

# get the name of the localmaster WRS
FILE_PATH=$MONDATA_DIR/wrs
if [ -f $FILE_PATH ]; then
    full_name=$(cat $FILE_PATH) # nwt0285m66.timing.acc.gsi.de
    LM_NAME=${full_name%%.*}    # nwt0285m66
else
    echo "Could not get the name of the localmaster WRS from file: $FILE_PATH"
    exit 1
fi

for port in 0 1 2 3; do

	TX_SUBDIR=D${port}TXDATA
	RX_SUBDIR=D${port}RXDATA

	for subdir in ${!TX_SUBDIR} ${!RX_SUBDIR}; do
		for rate in "${RATES[@]}"; do
			FILE_PATH=$MONDATA_DIR/$subdir/$rate
			if [ -f $FILE_PATH ]; then
				MONDATA_FILES[IDX]=$FILE_PATH
			else
				echo "File not found: $FILE_PATH"
			fi

			IDX=`expr $IDX + 1`
		done
	done
done

# exit here if no file with monitoring data is found
if [ ${#MONDATA_FILES[*]} -eq 0 ]; then
	echo "No files with monitoring data found in $MONDATA. Exit!"
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
			REL_PATH=${MONDATA_FILE#${MONDATA}/}  # part of the file path starting with a facility name (uni*)

			if [ "${REL_PATH:0:${#UNINWDATA}}" == "$UNINWDATA" ]; then # head with $UNINWDATA directory

				MONDATA_DIR=$MONDATA/$UNINWDATA

				DL_TX_RX_RATE=${MONDATA_FILE#${MONDATA_DIR}/}   # get 'd??x/rate*' from directory path
				DL_TX_RX=${DL_TX_RX_RATE%%/rate*}               # get 'd??x' from 'd??x/rate*
				DL_NAME=${DL_TX_RX%?x}                          # get 'd?' from 'd??x'
				TX_RX=${DL_TX_RX#d?}                            # get '?x' from 'd??x'
				METRIC_NAME=${DL_TX_RX_RATE##*/}                # get 'rate*'

				FILE_PATH=$MONDATA_DIR/${DL_NAME}port           # $MONDATA/d?port
				if [ -f $FILE_PATH ]; then
					PORT_NAME=$(tail -1 $FILE_PATH)
				fi

				# send metric key, metric value and timestamp to the Graphite host
				METRIC_KEY=uni.nw.${LM_NAME}.${DL_NAME}.${PORT_NAME}.${TX_RX}.${METRIC_NAME}  # uni.nw.nwt0122m66.dm.port1.tx.rate10s
				echo "$METRIC_KEY $METRIC_VAL $TIMESTAMP" | nc $SERVERIP -u $SERVERPORT

			elif [ "${REL_PATH:0:${#UNIPZDATA}}" == "$UNIPZDATA" ]; then # head with $UNIPZDATA directory

				MONDATA_DIR=$MONDATA/$UNIPZDATA
				METRIC_NAME=${MONDATA_FILE#${MONDATA_DIR}/}     # get 'messrate' from directory path

				# convert WR sync status to numeric value
				if [ "$METRIC_NAME" == "$WRSYNC" ]; then
					METRIC_VAL=$(get_sync_numeric "$METRIC_VAL")
				fi

				# send metric key, metric value and timestamp to the Graphite host
				METRIC_KEY=uni.pz.${PZ}.$METRIC_NAME            # uni.pz.scux0183.messrate
				echo "$METRIC_KEY $METRIC_VAL $TIMESTAMP" | nc $SERVERIP -u $SERVERPORT
			fi
		fi
	done

	sleep $INTERVAL
done
