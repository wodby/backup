#!/usr/bin/env bash
set -euo pipefail

tag="${GITHUB_REF_NAME:?Missing release tag}"
if [[ "${GITHUB_REF:-}" != "refs/tags/${tag}" || ! "${tag}" =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]]; then
    echo >&2 "GitHub Releases require a semantic product tag"
    exit 1
fi
if [[ "$(git cat-file -t "refs/tags/${tag}")" != tag ]]; then
    echo >&2 "GitHub Releases require an annotated product tag"
    exit 1
fi

# Use the annotated tag's release description, excluding any signing material.
notes=$(mktemp)
trap 'rm -f "${notes}"' EXIT
git for-each-ref --format='%(contents:subject)%0a%0a%(contents:body)' "refs/tags/${tag}" > "${notes}"
if ! grep -q '[^[:space:]]' "${notes}"; then
    echo >&2 "The product tag has no release description"
    exit 1
fi

# Successful reruns preserve the release already published for this tag.
if gh release view "${tag}" >/dev/null 2>&1; then
    echo "GitHub Release ${tag} already exists"
    exit 0
fi
gh release create "${tag}" --verify-tag --title "${tag}" --notes-file "${notes}"
