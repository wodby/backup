#!/usr/bin/env bash

set -e

if [[ "${1}" == 'make' ]]; then
    exec "$@" -f /usr/local/bin/actions.mk
else
    exec "$@"
fi
