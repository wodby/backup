#!/usr/bin/env bash

set -e

if [[ -n "${DEBUG}" ]]; then
    set -x
fi

if [[ "${1}" == 'make' ]]; then
    exec "$@" -f /usr/local/bin/actions.mk
else
    exec "$@"
fi
