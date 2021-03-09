#!/bin/bash

# This is an optional script used to present the diagnostic data in graphs.
# The diagnostic data is obtained from several SCUs, which are located at the
# different layers/levels of the timing network.
# The UDP protocol is used to send diagnostic data to a Graphite host.

# Check argument
if [ $# -ne 1 ]; then
	echo "Usage: $0 Graphite_host (host.domain or IP address)"
        echo "e.g., nohup /full/path/to/script tslxxx.domain &"
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
LAYERSCU1="PRO.1.scuxl0338"
LAYERSCU2="PRO.2.scuxl0302"
LAYERSCU3="PRO.3.scuxl0316"
LAYERSCU4="INT.2.scuxl0404"
LAYERSCU5="INT.3.scuxl0363"
LAYERSCU6="DEV.2.scuxl0390"
LAYERSCU7="DEV.3.scuxl0382"
LAYERSCU8="UNI.2.scuxl0187"
LAYERSCU9="UNI.3.scuxl0257"
LAYERSCU10="UNI.4.scuxl0359"

# directories with monitoring data
MONDATA=/common/usr/timing/htdocs/cgi-bin/admin/data
DIAGDATA=diag

# files with statistics
DTMAX=dtmax   # maximum dt, difference between deadline and actual time
DTMIN=dtmin   # minimum dt
DTAVE=dtave   # average dt
NMESS=nmess   # message rate count
NLATE=nlate   # late action count
SYNC=synch    # WR sync status
OFFST=offst   # diff between TAI and UTC

DIAGS=($DTMAX $DTMIN $DTAVE $NMESS $NLATE $SYNC $OFFST)
LAYERS=(l1 l2 l3 l4 l5 l6 l7 l8 l9 l10)
SCUS=($LAYERSCU1 $LAYERSCU2 $LAYERSCU3 $LAYERSCU4 \
	$LAYERSCU5 $LAYERSCU6 $LAYERSCU7 $LAYERSCU8 \
	$LAYERSCU9 $LAYERSCU10)

# polling interval
INTERVAL=30

# arrays with port statistics files
IDX=0
MONDATA_DIR=$MONDATA/$DIAGDATA
MONDATA_FILES=()

# check if files ($MONDATA_DIR/l?diagnostics) with diagnostic data exist
for layer in "${LAYERS[@]}"; do

	for stat in "${DIAGS[@]}"; do
		FILE_PATH=$MONDATA_DIR/${layer}$stat
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
	echo "$(date): Started sending monitoring data to $SERVERIP:$SERVERPORT every $INTERVAL seconds."
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

			LAYER_DIAG=${MONDATA_FILE#${MONDATA_DIR}/}   # get 'l1dtmax' from full path
			LAYER_NUM=${LAYER_DIAG//[!0-9]/}             # get '1' from 'l1dtmax'
			METRIC_NAME=${LAYER_DIAG#*$LAYER_NUM}        # get 'dtmax' from 'l1dtmax'

			# check layer number
			if [ "$LAYER_NUM" != "" ]; then
				LAYER_NUM=`expr $LAYER_NUM - 1`

				# check layer number and metric name
				if [ $LAYER_NUM -lt ${#SCUS[*]} ] && [ "$METRIC_NAME" != "" ]; then

					# convert WR sync status to numeric value
					if [ "$METRIC_NAME" == "$SYNC" ]; then
						METRIC_VAL=$(get_sync_numeric "$METRIC_VAL")
					fi

					SCU=${SCUS[$LAYER_NUM]}                  # get 'PRO.1.scuxl0338'

					if [ "$SCU" != "" ]; then
						METRIC_KEY=${DIAGDATA}.${SCU}.$METRIC_NAME # build metric key: diag.PRO.1.scuxlXYZ.dtmax

						# send metric key, metric value and timestamp to the Graphite host
						if [ "$METRIC_KEY" != "" ]; then
							echo "$METRIC_KEY $METRIC_VAL $TIMESTAMP" | nc $SERVERIP -u $SERVERPORT
						fi
					fi

				fi
			fi
		fi
	done

	sleep $INTERVAL
done
