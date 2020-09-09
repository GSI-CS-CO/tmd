#!/bin/bash

# Common functions used by the push scripts.

# Convert WR sync status to numeric value
# expected WR sync status: TRACKING, NO SYNC
get_sync_numeric()
{
	local num_val=0

	case $1 in
		"TRACKING") num_val=100;;
		"NO SYNC")  num_val=20;;
		*)  num_val=0;;
	esac

	echo $num_val
}
