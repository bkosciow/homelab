#!/bin/bash

set -euo pipefail  # Exit on error, no silent failures

BACKUP_DIR="/mnt/backup/config_backups"
CONFIG="/root/services/backup/cfg_config.conf"
MAX_BACKUPS=10
DATE_ADDON=$(date +%Y-%m-%dT%H:%M:%S)

mkdir -p ${BACKUP_DIR}
mkdir -p /root/cron_backup

# dump crons 
crontab -l -u root > /root/cron_backup/cron_root.txt
crontab -l -u kosci > /root/cron_backup/cron_kosci.txt

# nextcloud
Url="https://nextcloud/ocs/v2.php/apps/spreed/api/v1/chat/kubi5p4r"
User="MrBot"
AccessToken="aa-bb-cc"
CurlArgs=""

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

  # Build rsync command with dynamic excludes
  rsync_cmd=(rsync -aHAX)

  # Add exclude patterns (skip first two parts which are source/dest)
  for ((i=2; i<${#parts[@]}; i++)); do
    rsync_cmd+=(--exclude="${parts[i]}")
  done

  # Add remaining arguments
  rsync_cmd+=("$source" "${BACKUP_DIR}/${DATE_ADDON}${dest}" --log-file="/var/log/cfg_backup.log")

  mkdir -p "${BACKUP_DIR}/${DATE_ADDON}${dest}"
  "${rsync_cmd[@]}"
done < "$CONFIG"

#find $BACKUP_DIR -type f -name "*.sql" -mtime +10 -exec rm -f {} \;
cd "$BACKUP_DIR"
if [[ $(ls -1d * 2>/dev/null | wc -l) -gt $MAX_BACKUPS ]]; then
  ls -1td * | tail -n +$((MAX_BACKUPS + 1)) | xargs rm -rf
fi

curl_post "✅ Backup of config files completed successfully at $(date +%Y-%m-%dT%H:%M:%S)"

