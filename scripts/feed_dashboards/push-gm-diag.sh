#!/bin/bash

# This is an optional script used to present the error statistics of Grandmaster in graphs.
# It sends the value of several SNMP objects exported from Grandmaster (WR switch) to a Graphite
# host using the UDP protocol.

# wrsSpllDelCnt Counter32 "Del counter at Soft PLL"
# wrsPtpServoStateErrCnt Counter32 "Number of servo updates with wrong servo state"
# wrsPtpClockOffsetErrCnt Counter32 "Number of servo updates with wrong clock offset"
# wrsPtpRTTErrCnt Counter32 "Number of servo updates with wrong RTT"

# Check argument
if [ $# -ne 1 ]; then
	echo "Usage: $0 Graphite_host (host.domain or IP address)"
	exit 1
fi

# Graphite host and port
SERVERIP=$1
SERVERPORT=2003

# Grandmaster device (used in metric path)
GM=nwt0013m66
WRS_DEVICE=${GM}.timing

# polling interval, seconds
INTERVAL=300

# SNMP application, objects
SNMP_APP=snmpwalk
SNMP_OPT="-c public -v 2c -Ovq -m ALL"
WRS_OIDS=("SpllDelCnt:.1.3.6.1.4.1.96.100.7.3.2.9"   # Del counter at Soft PLL
"PtpServoStateErrCnt:.1.3.6.1.4.1.96.100.7.5.1.20"   # Number of servo updates with wrong servo state
"PtpClockOffsetErrCnt:.1.3.6.1.4.1.96.100.7.5.1.21"  # Number of servo updates with wrong clock offset
#"PtpRTTErrCnt:.1.3.6.1.4.1.96.100.7.5.1.22"          # Number of servo updates with wrong RTT
)   # pseudo hash array

# abort if required SNMP app is not installed
if ! command -v $SNMP_APP >/dev/null 2>&1; then
	echo 1>&2 "FAIL: Missing $SNMP_APP. Aborting!"
	exit 1
fi

echo "Sending monitoring data to $SERVERIP:$SERVERPORT every $INTERVAL seconds."
# /common/graphite/whisper/nw/nwt0123m66

# main stuff
while true; do

	# update timestamp
	TIMESTAMP=`date +%s`

	# obtain SNMP objects and send their values to Graphite host
	for element in "${WRS_OIDS[@]}"; do

		# split SNMP object name and numeric ID
		METRIC_NAME="${element%%:*}"
		OID_IN_NUM="${element##*:}"

		# get SNMP object
		METRIC_VAL=$($SNMP_APP $SNMP_OPT $WRS_DEVICE $OID_IN_NUM)

		# if metric value is available then send it
		if [ "$METRIC_VAL" != "" ]; then

			# send metric key, metric value and timestamp to the Graphite host
			METRIC_KEY=nw.${GM}.diag.${METRIC_NAME}  # nw.nwt0123m66.diag.SpllDelCnt
			echo "$METRIC_KEY $METRIC_VAL $TIMESTAMP" | nc $SERVERIP -u $SERVERPORT
		fi
	done

	sleep $INTERVAL
done
