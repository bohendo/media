#!/bin/bash

fail="❌"
good="✅"

media=${MEDIA_DIR:-$HOME/Media} 
trash=$media/.trash

if [[ ! -f "$trash" ]]
then touch "$trash"
fi

target=$(basename "$1")
if ! [[ "$target" =~ ^[0-9]{8}-[0-9]{6}-[0-9a-f]{8}\.[0-9a-z]{2,5}$ ]]
then echo "$fail Invalid target provided: $target" && exit 1
fi

path="$media/$target"
if ! [[ -f "$path" ]]
then echo "$fail Can't find a target at $path" && exit 1
fi

full_digest=$(sha256sum "$path" | cut -d " " -f 1)

if ! grep -qs "$full_digest" < "$trash"
then echo "$full_digest" >> "$trash"
fi

rm -rf "$path"
echo "$good Removed $path"
