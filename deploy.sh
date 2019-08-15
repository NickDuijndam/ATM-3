#!/bin/bash
userAgent="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Ubuntu Chromium/53.0.2785.143 Chrome/53.0.2785.143 Safari/537.36";
manifest=$(cat manifest.json)
cd overrides/mods

for line in $(cat override_mods.txt);
do
    wget --content-disposition --user-agent="$userAgent" $line 2>/dev/null
done

jq -c '.files[]' ../../manifest.json | while read i
do
  url=$(curl "https://minecraft.curseforge.com/projects/$(jq '.projectID' <<< $i)" -si | awk '/location: (.*)/ {print $2}' | tr -d "\r")/download/$(jq '.fileID' <<< $i)/file
  echo "Downloading: $url"
  wget --content-disposition --user-agent="$userAgent" $url 2>/dev/null
done

name="$(jq -r '.name' <<< $manifest)__$(jq -r '.version' <<< $manifest).zip"
name=${name// /_}
cd ../
tar --exclude='override_mods.txt' --exclude='dl_overrides.py' -cf  ../$name *

curl -X POST https://api.dropboxapi.com/2/files/delete_v2 \
    --header "Authorization: Bearer $DROPBOX_TOKEN" \
    --header "Content-Type: application/json" \
    --data "{\"path\": \"/ATM3\"}"

curl -X POST https://content.dropboxapi.com/2/files/upload \
    --header "Authorization: Bearer $DROPBOX_TOKEN" \
    --header "Dropbox-API-Arg: {\"path\": \"/ATM3/${name}\",\"mode\": \"add\",\"autorename\": true,\"mute\": false,\"strict_conflict\": false}" \
    --header "Content-Type: application/octet-stream" \
    --data-binary "$name"

