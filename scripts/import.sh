#!/bin/bash
#
# Import dashboards into Grafana (v6.4.2+)
#
# Match the dashboard location, Grafana host and API key in config.sh
# according to your need.
#
# Sources: https://github.com/grafana/grafana/issues/2816

. "$(dirname "$0")/config.sh"

# Create map with organization name and API key
declare -aa ORGMAP
for row in "${ORGS[@]}"; do
    IFS=':' read -r -a values <<< "$row"
    ORGMAP[${values[0]}]=${values[1]}
done

# Request to create/update dashboard
request_to_update() {
    # $1 - dashboard path: $DB_DIR/dashboards/$ORG/$folder/title_version.json
    # $2 - API key
    local FILE=$1
    local KEY=$2
    HTTP_REQUEST=POST

    # URL for Grafana dashboards
    URL=${HOST}/api/dashboards/db

    # Folder information is specified in the .meta object, but Grafana
    # does not support importing dashboard with the .meta object.
    # Therefore dashboards are imported only into the General folder.
    #get_folder_id $FILE $KEY

    # The id is only unique per Grafana install and the null value is used to
    # create a new dashboard.
    json=$(cat $FILE | jq '.id = null')

    # Create/update dashboard with POST HTTP API request.
    # The line with -d option allows updating existing dashboard and
    # assigns the whole JSON content to a 'dashboard' object.
    curl -sS --fail -k -X$HTTP_REQUEST \
        -H "Content-Type: application/json" \
        -H "Accept: application/json" \
        -H "Authorization: Bearer $KEY" \
        -d "{\"dashboard\":${json}, \"overwrite\":true}" \
        $URL > /dev/null
}

# Import dashboard files
import_file() {
    # $1 - dashboard path
    # $2 - API key
    local FILE="$1"
    local KEY="$2"

    if ! [ -f "$FILE" ]; then
        echo "$FILE not found. Exit!"
        return 1
    fi

    request_to_update "$FILE" "$KEY"
}

# Check valid API keys and dashboards
initial_check() {
    # $1 - amount of available dashboards
    # $2 - amount of API keys
    local N_DASHBOARDS=$1
    local N_KEYS=$2

    if [ $N_DASHBOARDS -eq 0 ]; then
        echo "Bad configuration or command line argument. Exit!"
        exit 1
    fi

    if [ $N_KEYS -eq 0 ]; then
        echo "API key is not set. Exit!"
        exit 1
    fi
}

# Get an ID of the given folder
get_folder_id() {
    # $1 - dashboard path: $DB_DIR/dashboards/$ORG/$folder/title_version.json
    # $2 - API key
    local FILE=$1
    local KEY=$2

    # Grafana URL for folders
    local URL=${HOST}/api/folders

    # get folder title
    rel_path=${FILE##*${DB_DIR}/dashboards/${ORG_NAME}/}
    folder_title=${rel_path%/*}

    # request folder list and get an ID of the given folder
    folder_id=$(curl -sS --fail -k -H "Authorization: Bearer $KEY" $URL \
        | jq ".[] | select(.title | test(\"${folder_title}\")) | .id")
    echo "ID: $folder_id ($folder_title)"
}

# Import available dashboards in the $DB_DIR directory, when script is called
# without argument (not specifying files), otherwise import the given files.
if [ $# -eq 0 ]; then
    DB_PATHS=($(find $DB_DIR -name "*.json"))
    echo ${DB_PATHS[@]}
else
    DB_PATHS=("$@")
fi

# Check if valid API key and dashboards are found
initial_check ${#ORGMAP[@]} ${#DB_PATHS[@]}

counter=0

for db_path in "${DB_PATHS[@]}"; do

    # dashboard path: $DB_DIR/dashboards/$ORG/$folder_title/dashboard.json

    # get dashboard title and uid
    db_title="$(cat $db_path | jq -r '.title' | sed -r 's/[ \/]+/_/g' )"
    db_uid="$(cat $db_path | jq -r '.uid')"

    # get API key
    rel_path=${db_path##*${DB_DIR}/dashboards/}
    ORG_NAME=${rel_path%%/*}
    key=${ORGMAP[${ORG_NAME}]}

    # import dashboard using the HTTP API request
    import_file $db_path "$key"
    result=$?

    if [ $result -eq 0 ]; then
        counter=$((counter + 1))
        log_success "Success: path=${db_path}, title=${db_title}, uid=${db_uid}"
    else
        log_failure "Failure: path=${db_path}, title=${db_title}, uid=${db_uid}"
    fi
done

log_title "Total of $counter dashboards were imported."
