#!/usr/bin/env bash

set -e

if [[ -n "${DEBUG}" ]]; then
  set -x
fi

dir=$1
filepath=$2
zip=$3
exclude_paths=$4

cd "${dir}"

exclude=""
options="-cf"

if [[ -n "${zip}" ]]; then
    options="${options}z"
fi

excludes=()

IFS=';' read -ra ADDR <<< "${exclude_paths}"
for path in "${ADDR[@]}"; do
    excludes+=("--exclude=\"${path}\"")
done

tar "${excludes[@]}" "${options}" "${filepath}" .

stat -c "RESULT=%s" "${filepath}"