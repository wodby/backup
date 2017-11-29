#!/usr/bin/env bash

set -e

if [[ -n "${DEBUG}" ]]; then
    set -x
fi

dir=$1
filepath=$2
zip=$3
exclude_paths=$4
nice=$5
ionice=$6

cd "${dir}"

exclude=""
options="-cf"

if [[ -n "${mark}" ]]; then
    touch "${mark}"
    chmod 777 "${mark}"
    ownership=$(stat -c '%U:%G' .)
    chown "${ownership}" "${mark}"
fi

if [[ -n "${zip}" ]]; then
    options="${options}z"
fi

excludes=()

IFS=';' read -ra ADDR <<< "${exclude_paths}"
for path in "${ADDR[@]}"; do
    excludes+=("--exclude=\"${path}\"")
done

nice -n "${nice}" ionice -c2 -n "${ionice}" \
    tar "${excludes[@]}" --warning=no-file-changed "${options}" "${filepath}" .

stat -c "RESULT=%s" "${filepath}"