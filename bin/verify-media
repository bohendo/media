#!/bin/bash

fail="❌"
warn="⚠️ "
good="✅"

if [[ -z "$(command -v exiftool)" ]]
then echo "$fail Install exiftool first" && exit 1
fi

function getCreateDate {
  exiftool -CreateDate "$1" 2> /dev/null \
    | sed 's/.*  ://' \
    | sed 's/: /:0/g' \
    | sed 's/://g' \
    | sed 's/\+.*//g' \
    | sed 's/ /-/g' \
    | sed 's/-$//' \
    | sed 's/^-//'
}

for target in media/camera/*
do

  if [[ ! -f "$target" ]]
  then echo "$fail File does not exist at $target" && exit 1
  fi

  created=$(getCreateDate "$target")

  if [[ -z "$created" ]]
  then
    echo "$fail $target does not have a create date"

    if [[ "$(basename "$target")" == "00000000-000000"* ]]
    then
      echo "$warn re-importing $target"
      import-media "$target" -y
      bash ops/remove.sh "$target"
      continue;
    fi

    echo "Idk what to do with this"
    exit 1
  fi

  if [[ "$(basename "$target")" != "$created"* ]]
  then echo "$fail $target does not match create date $created" && exit 1
  fi

  full_digest=$(sha256sum "$target" | cut -d " " -f 1)
  digest=$(echo "$full_digest" | head -c 8)

  if [[ "$(basename "$target")" != "$created-$digest."* ]]
  then echo "$fail $target does not match digest $digest" && exit 1
  fi

  echo "$good $target looks good"
done
