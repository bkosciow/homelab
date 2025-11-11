#!/bin/bash

set -euo pipefail  # Exit on error, no silent failures

BACKUP_DIR="/mnt/backup/data_backups"
CONFIG="/root/services/backup/data_config.conf"

# nextcloud
Url="https://nextcloud/ocs/v2.php/apps/spreed/api/v1/chat/kubi5p4r"
User="MrBot"
AccessToken="aa-bb-cc"
CurlArgs=""

mkdir -p ${BACKUP_DIR}

curl_post() {
    local BODY="$1"
    echo ${BODY}
    JSON_PAYLOAD=$(jq -n --arg msg "$BODY" '{"message": $msg}')
    curl  -u "${User}:${AccessToken}" -o /dev/null \
    -H 'accept: application/json, text/plain, _/_' \
    -H 'cache-control: no-cache' \
    -H 'content-type: application/json' \
    -H "OCS-APIRequest: true" \
    --data "${JSON_PAYLOAD}" \
    -X POST "${Url}"
}


while IFS= read -r line; do
  [[ "$line" =~ ^# ]] || [[ -z "$line" ]] && continue

  # Split line into parts
  read -ra parts <<< "$line"
  source="${parts[0]}"
  dest="${parts[1]}"

  rsync_cmd=(rsync -aHAX)

  # Add exclude patterns (skip first two parts which are source/dest)
  for ((i=2; i<${#parts[@]}; i++)); do
    rsync_cmd+=(--exclude="${parts[i]}")
  done

  # Add remaining arguments
  rsync_cmd+=("$source" "${BACKUP_DIR}${dest}" --log-file="/var/log/data_backup.log")

  curl_post "Backup of data __${dest}__ started at $(date +%Y-%m-%dT%H:%M:%S)"
  mkdir -p "${BACKUP_DIR}${dest}"
  "${rsync_cmd[@]}"
  curl_post "✅ Backup of data __${dest}__ completed at $(date +%Y-%m-%dT%H:%M:%S)"
done < "$CONFIG"

curl_post "✅ Backup of data completed successfully at $(date +%Y-%m-%dT%H:%M:%S)"

