#!/bin/bash

# Databases
DATABASES=("db1" "db2" "db3")

# Backup dir
BACKUP_DIR="/mnt/backup/database_backup"
mkdir -p ${BACKUP_DIR}

# Nextcloud Talk
Url="https://nextcloud/ocs/v2.php/apps/spreed/api/v1/chat/kubi5p4r"
User="MrBot"
AccessToken="aa-bb-cc"

curl_post() {
    local BODY="$1"
    JSON_PAYLOAD=$(jq -n --arg msg "$BODY" '{"message": $msg}')
    curl  -u "${User}:${AccessToken}" -o /dev/null \
    -H 'accept: application/json, text/plain, _/_' \
    -H 'cache-control: no-cache' \
    -H 'content-type: application/json' \
    -H "OCS-APIRequest: true" \
    --data "${JSON_PAYLOAD}" \
    -X POST "${Url}"
}
DATE=$(date +"%Y-%m-%d_%H-%M-%S")

for DB in "${DATABASES[@]}"; do
    BACKUP_FILE="${BACKUP_DIR}/${DB}_${DATE}.sql"
    echo "Backing up database $DB to $BACKUP_FILE..."
    mysqldump $DB > $BACKUP_FILE
    if [ $? -eq 0 ]; then
        echo "Backup of $DB completed successfully!"
        curl_post "Backup of __${DB}__ completed successfully!"
    else
        echo "Backup of $DB failed!"
        curl_post "Backup of __${DB}__ failed!"
    fi
done

find $BACKUP_DIR -type f -name "*.sql" -mtime +30 -exec rm -f {} \;

