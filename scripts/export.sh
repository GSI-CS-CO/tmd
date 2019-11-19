#!/bin/bash
#
# Export existing dashboards from the Grafana installation (v6.4.2+)
#
# Match the destination directory, Grafana host and API key in config.sh
# according to your need.
#
# Sources:
# https://gist.github.com/crisidev/bd52bdcc7f029be2f295
# https://github.com/hagen1778/grafana-import-exporti

. "$(dirname "S0")/config.sh"

counter=0

for entry in "${ORGS[@]}"; do
   # get API key
   ORG=${entry%%:*}
   KEY=${entry##*:}

   # get uid of existing dashboards (use -v if curl returns error)
   for db_uid in $(curl -v -sS -k -H "Authorization: Bearer ${KEY}" \
      ${HOST}/api/search\?query\=\& \
      | jq -r '.[] | select( .type | contains("dash-db")) | .uid'); do

      # get dashboard (in JSON) and its title, version and folder
      db_json="$(curl -sS -k -H "Authorization: Bearer $KEY" $HOST/api/dashboards/uid/$db_uid)"
      db_title="$(echo $db_json | jq -r '.dashboard | .title' | sed -r 's/[ \/]+/_/g' )"
      db_version="$(echo $db_json | jq -r '.dashboard | .version')"
      folder="$(echo $db_json | jq -r '.meta | .folderTitle')"

      # save dashboards in $DB_DIR/dashboards/$ORG/$folder/title_version.json
      FILE_NAME="${db_title}_v${db_version}.json"
      DEST_DIR=$DB_DIR/dashboards/$ORG/$folder
      mkdir -p "$DEST_DIR"

      # Save only 'dashboard' object as JSON file, because it allows re-import
      # of dashboards using GUI. Otherwise a blank dashboard is imported!
      echo $db_json | jq '.dashboard' > "$DEST_DIR/$FILE_NAME"
      result=$?

      if [ $result -eq 0 ]; then
         counter=$((counter + 1))
         log_success "Success: title=${db_title}, uid=${db_uid}, path=${DEST_DIR}/$FILE_NAME"
      else
         log_failure "Failure: title=${db_title}, uid=${db_uid}, path=${DEST_DIR}/$FILE_NAME"
      fi
   done
done

log_title "Total of ${counter} dashboards were exported";
