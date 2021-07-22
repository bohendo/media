#!/usr/bin/env bash
set -e

root=$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." >/dev/null 2>&1 && pwd )
project=$(grep -m 1 '"name":' "$root/package.json" | cut -d '"' -f 4)

# Format string describing how each line looks
function format {
 awk '{printf("| %-32s|%8s  ->  %-8s|\n", $1, $3, $4)}'
}

echo "===== Package: $project/package.json"
npm outdated -D | tail -n +2 | awk '$3 != $4' | format
echo

for package in modules/*/package.json
do
  cd "$(dirname "$package")" || exit 1
  echo "===== Package: $project/$(dirname "$package")/package.json"
  mv package.json package.json.backup
  sed "/@$project/d" < package.json.backup > package.json
  npm outdated | tail -n +2 | awk '$3 != $4' | format
  echo "-----"
  npm outdated -D | tail -n +2 | awk '$3 != $4' | format
  rm package.json
  mv package.json.backup package.json
  cd "$root" || exit 1
  echo
done
