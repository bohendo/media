#!/bin/bash

fail="❌"
good="✅"

media=${MEDIA_DIR:-$HOME/Media} 
mkdir -p "$media"

index=$media/.index
if [[ ! -f "$index" ]]
then touch "$index"
fi

target=$(basename "$1")
if ! [[ "$target" =~ ^[0-9]{8}-[0-9]{6}-[0-9a-f]{8}\.[0-9a-z]{2,5}$ ]]
then echo "$fail Invalid target provided: $target" && exit 1
fi

entry=$(grep -m 1 "$target$" "$index" || true)

path="${entry#*:}"
if ! [[ -f "$path" ]]
then echo "$fail Can't find a target at $path" && exit 1
fi

if [[ -n "$entry" && "$entry" == *:* ]]
then
  mv "$index" "$index.backup"
  sed "s/$entry/${entry%:*}:/" < "$index.backup" > "$index"
  rm "$index.backup"
else
  echo "$fail File is not in the index: $target" && exit 1
fi

rm -f "$path"
find "$media/albums" -name "$target" -exec rm -f {} \;
echo "$good Removed $path"
