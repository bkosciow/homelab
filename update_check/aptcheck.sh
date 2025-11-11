#!/bin/bash

# Requires package "recode" for proper output of flatpak list
# Capture the list of upgraded packages and flatpaks
apt_upgrades=$(apt-get -s upgrade | grep '^Inst' | awk '{print $2}' | tr '[:upper:]' '[:lower:]' | sort | uniq)

Url="https://nextcloud/ocs/v2.php/apps/spreed/api/v1/chat/kubi5p4r"
User="MrBot"
AccessToken="aa-bb-cc"


if [[ -n "$apt_upgrades" ]]; then
    body="The following apt packages have upgrades:"
    body+=$'\n\n'
    body+="$apt_upgrades"
    body+=$'\n\n'

    echo "$body"

JSON_PAYLOAD=$(jq -n --arg msg "$body" '{"message": $msg}')

echo $JSON_PAYLOAD

  curl -u ${User}:${AccessToken} -o /dev/null ${CurlArgs} \
  -H 'accept: application/json, text/plain, */*' \
  -H 'cache-control: no-cache' \
  -H 'content-type: application/json' \
  -H "OCS-APIRequest: true" \
  --data "${JSON_PAYLOAD}" \
  -X POST ${Url} 
  
fi

