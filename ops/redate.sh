#!/bin/bash

root=$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." >/dev/null 2>&1 && pwd )
media=${MEDIA_DIR:-$HOME/Media} 

fail="❌"
good="✅"

if [[ -z "$(command -v exiftool)" ]]
then echo "$fail Install exiftool first" && exit 1
fi

target="$1"
if ! [[ "$target" =~ ^[0-9]{8}-[0-9]{6}-[0-9a-f]{8}\.[0-9a-z]{2,5}$ ]]
then echo "$fail Invalid target provided: $target" && exit 1
fi
path="$media/$target"

if [[ ! -f "$path" ]]
then echo "$fail Target doesn't exist at $path" && exit 1
fi

date="$2"
if [[ -z "$date" ]]
then echo "$fail No new date provided" && exit 1
elif ! [[ "$date" =~ ^[0-9]{8}-[0-9]{6}$ ]]
then echo "$fail Invalid date provided. Expected YYMMDD-hhmmss" && exit 1
fi

echo "$good redating $path to $date"
exiftool -CreateDate="${date::4}:${date:4:2}:${date:6:2} ${date:9:2}:${date:11:2}:${date:13:2}" "$path"
exiftool -CreateDate "$path"
import-media "$path" -y
bash "$root/ops/remove-media.sh" "$target"
rm "${path}_original"
