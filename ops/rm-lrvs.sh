#!/bin/bash

# get unique timestamps minus the unknown zero-timestamp
timestamps=$(find media/public/ -type f -exec basename {} \; | cut -d "-" -f 1-2 | sort -u | sed '/00000000-000000/d')

# for each timestamp, if two different mp4s exist, delete the smaller one
for ts in $timestamps
do
  files=$(find media/public/ -type f -name "$ts-*.mp4")
  if [[ "$(echo "$files" | wc -l)" == "2" ]]
  then
    if [[
      "$(for f in $files; do exiftool -duration "$f"; done | sort -u | wc -l)" == "1" &&
      "$(for f in $files; do exiftool -avgbitrate "$f"; done | sort -u | wc -l)" == "2"
    ]]
    then
      echo
      echo "There are 2 vids w timestamp $ts & same durations but different bitrates.."

      f1="$(echo "$files" | head -n 1)"
      du "$f1"
      f2="$(echo "$files" | tail -n 1)"
      du "$f2"
      if [[ "$(du "$f1" | cut -d "	" -f 1)" -lt "$(du "$f2" | cut -d "	" -f 1)" ]]
      then
        echo "f1 is smaller, deleting.."
        bash ops/remove-media.sh "$f1"
      elif [[ "$(du "$f1" | cut -d "	" -f 1)" -gt "$(du "$f2" | cut -d "	" -f 1)" ]]
      then
        echo "f2 is smaller, deleting"
        bash ops/remove-media.sh "$f2"
      else echo "They're the same, doing nothing"
      fi

    fi
  fi
done
