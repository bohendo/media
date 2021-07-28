#!/bin/bash

fail="❌"
good="✅"

media=${MEDIA_DIR:-$HOME/Media}
mkdir -p "$media"

tmp="/tmp/media"
mkdir -p "$tmp"

index=$media/.index
if [[ ! -f "$index" ]]
then touch "$index"
fi

if [[ -z "$(command -v exiftool)" ]]
then echo "$fail Install exiftool first" && exit 1
fi

target="$1" # should include category
if ! [[ "$target" =~ [a-z]+/[0-9]{8}-[0-9]{6}-[0-9a-f]{8}\.[0-9a-z]{2,5}$ ]]
then echo "$fail Invalid target provided: $target" && exit 1
fi
name=${target#*/}
category=${target%/*}
path="$media/$category/$name"

if [[ ! -f "$path" ]]
then echo "$fail No file exists at $path" && exit 1;
fi

date="$2"
if [[ -z "$date" ]]
then echo "$fail No new date provided" && exit 1
elif ! [[ "$date" =~ ^[0-9]{8}-[0-9]{6}$ ]]
then echo "$fail Invalid date provided. Expected YYMMDD-hhmmss" && exit 1
fi

echo "Redating $path to $date"

tmp_target="$tmp/$name"
rm -rf "$tmp_target*"
cp "$path" "$tmp_target"
chmod 644 "$tmp_target"

exiftool -CreateDate="${date::4}:${date:4:2}:${date:6:2} ${date:9:2}:${date:11:2}:${date:13:2}" "$tmp_target"

ext=$(exiftool -FileTypeExtension "$tmp_target" 2> /dev/null | sed 's/^.*: //')
new_hash=$(sha256sum "$tmp_target" | cut -d " " -f 1)
suffix=$(echo "$new_hash" | head -c 8)
new_name="$date-$suffix.$ext"
new_path="$media/$category/$new_name"

# Add the new file
cp "$tmp_target" "$new_path"

# Remove the old file
rm "$path"

# Update the path in the index
mv "$index" "$index.backup"
sed "s/$path$/$new_path/" < "$index.backup" > "$index"
rm "$index.backup"

echo "$good Re-dated $path to $new_path"
