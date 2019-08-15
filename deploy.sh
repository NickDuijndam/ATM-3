#!/bin/bash
userAgent="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Ubuntu Chromium/53.0.2785.143 Chrome/53.0.2785.143 Safari/537.36";
manifest=$(cat manifest.json)
cd overrides/mods

python3 dl_overrides.py

jq -c '.files[]' ../../manifest.json | while read i
do
  url=$(curl "https://minecraft.curseforge.com/projects/$(jq '.projectID' <<< $i)" -si | awk '/location: (.*)/ {print $2}' | tr -d "\r")/download/$(jq '.fileID' <<< $i)/file
  echo "Downloading: $url"
  wget --content-disposition --user-agent="$userAgent" $url 2>/dev/null
done

name="$(jq -r '.name' <<< $manifest)__$(jq -r '.version' <<< $manifest).zip"
name=${name// /_}
cd ../
zip -q -x '*override_mods.txt*' -x '*dl_overrides.py*' -r "../$name" .
cd ../

curl -X POST https://api.dropboxapi.com/2/files/delete_v2 \
    --header "Authorization: Bearer $DROPBOX_TOKEN" \
    --header "Content-Type: application/json" \
    --data "{\"path\": \"/ATM3\"}"

split -b 131072000 -a 3 "$name" "$name."
files=(./$name.*)
total=${#files[@]}
counter=1
uploaded=0

for filename in ./$name.*; do
	if [ $counter = 1 ]; then
	   	result=$(wget -qO- \
			--header="Authorization: Bearer $DROPBOX_TOKEN" \
			--header="Dropbox-API-Arg: {\"close\": false}" \
			--header="Content-Type: application/octet-stream" \
			--post-file $filename https://content.dropboxapi.com/2/files/upload_session/start)

		sessionId="$(jq -r '.session_id' <<< $result)"
	elif [ $counter = $total ]; then
	   	wget \
			--header="Authorization: Bearer $DROPBOX_TOKEN" \
			--header "Dropbox-API-Arg: {\"cursor\": {\"session_id\": \"$sessionId\",\"offset\": $uploaded},\"commit\": {\"path\": \"/ATM3/$name\",\"mode\": \"add\",\"autorename\": true,\"mute\": false,\"strict_conflict\": false}}" \
			--header="Content-Type: application/octet-stream" \
			--post-file $filename https://content.dropboxapi.com/2/files/upload_session/finish

	else
		echo $uploaded
		wget \
			--header="Authorization: Bearer $DROPBOX_TOKEN" \
			--header "Dropbox-API-Arg: {\"cursor\": {\"session_id\": \"$sessionId\",\"offset\": $uploaded},\"close\": false}" \
			--header="Content-Type: application/octet-stream" \
			--post-file $filename https://content.dropboxapi.com/2/files/upload_session/append_v2
	fi

	uploaded=$(expr $uploaded + $(wc -c < $filename))
	counter=$(expr $counter + 1)
done
