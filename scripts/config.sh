# ORGS contains pairs of organization name and HTTP API key.
# HOST specifies Grafana host URL.
# DB_DIR is a directory where dashboard files exist or to be saved.

SCRIPT_TEST=1

if [ $SCRIPT_TEST -ne 0 ]; then
   ORGS=("TOS:eyJrIjoiN0lwVndYNkFmWXhQeklobUczZTlVdERYcm1pSGFNaDUiLCJuIjoidG9zX2FkbWluIiwiaWQiOjF9")
   HOST=http://localhost:3000
   DB_DIR=/tmp/grafana_test
else
   ORGS=("org:12345")
   HOST=https://grafana.host.domain:port
   DB_DIR=/tmd
fi

# set some colors for status OK, FAIL and titles
SETCOLOR_SUCCESS="echo -en \\033[0;32m"
SETCOLOR_FAILURE="echo -en \\033[1;31m"
SETCOLOR_NORMAL="echo -en \\033[0;39m"
SETCOLOR_TITLE_PURPLE="echo -en \\033[0;35m" # purple

# usage log "string to log" "color option"
log_success() {
   if [ $# -lt 1 ]; then
      ${SETCOLOR_FAILURE}
      echo "Not enough arguments for log function! Expecting 1 argument got $#"
      exit 1
   fi

   timestamp=$(date "+%Y-%m-%d %H:%M:%S %Z")

   ${SETCOLOR_SUCCESS}
   printf "[${timestamp}] $1\n"
   ${SETCOLOR_NORMAL}
}

log_failure() {
   if [ $# -lt 1 ]; then
      ${SETCOLOR_FAILURE}
      echo "Not enough arguments for log function! Expecting 1 argument got $#"
      exit 1
   fi

   timestamp=$(date "+%Y-%m-%d %H:%M:%S %Z")

   ${SETCOLOR_FAILURE}
   printf "[${timestamp}] $1\n"
   ${SETCOLOR_NORMAL}
}

log_title() {
   if [ $# -lt 1 ]; then
      ${SETCOLOR_FAILURE}
      log_failure "Not enough arguments for log function! Expecting 1 argument got $#"
      exit 1
   fi

   ${SETCOLOR_TITLE_PURPLE}
   printf "$1\n"
   ${SETCOLOR_NORMAL}
}
