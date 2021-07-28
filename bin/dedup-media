#!/bin/bash

if [[ -z "$1" ]]
then
  echo "Use the 1st & nly arg to specify whether or not you actually want to make changes"
  echo "  -n  No I don't want to make changes, but show me what the changes would be"
  echo "  -y  Yes I want to make changes"
  exit
fi

echo "Gathering a list of unique timestamps.."
# get unique timestamps minus the unknown zero-timestamp
timestamps=$(find media/camera/ -type f -exec basename {} \; | cut -d "-" -f 1-2 | sort -u | sed '/00000000-000000/d')

echo "Done"
echo "Scanning each timestamp for high-res/low-res dups to remove.."

# for each timestamp, if two different mp4s exist, delete the smaller one
for ts in $timestamps
do
  files=$(find media/camera/ -type f -name "$ts-*.mp4")
  if [[ "$(echo "$files" | wc -l)" == "2" ]]
  then
    if [[
      "$(for f in $files; do exiftool -duration "$f"; done | sort -u | wc -l)" == "1" &&
      "$(for f in $files; do exiftool -avgbitrate "$f"; done | sort -u | wc -l)" == "2"
    ]]
    then
      echo
      echo "There are 2 vids w the same timestamp and duration.."

      f1="$(echo "$files" | head -n 1)"
      du "$f1"
      f2="$(echo "$files" | tail -n 1)"
      du "$f2"
      if [[ "$(du "$f1" | cut -d "	" -f 1)" -lt "$(du "$f2" | cut -d "	" -f 1)" ]]
      then
        echo "f1 is smaller, deleting.."
        if [[ "$1" == "-y" ]]
        then echo bash ops/remove.sh "$f1"
        else bash ops/remove.sh "$f1"
        fi
      elif [[ "$(du "$f1" | cut -d "	" -f 1)" -gt "$(du "$f2" | cut -d "	" -f 1)" ]]
      then
        echo "f2 is smaller, deleting"
        if [[ "$1" == "-y" ]]
        then echo bash ops/remove.sh "$f2"
        else bash ops/remove.sh "$f2"
        fi
      else echo "They're the same size, doing nothing"
      fi

    fi
  fi
done
