#!/usr/bin/env bash

set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
test_dir=$(mktemp -d)

cleanup() {
  rm -rf "${test_dir}"
}
trap cleanup EXIT

mkdir -p "${test_dir}/bin" "${test_dir}/remote"

cat > "${test_dir}/bin/rclone" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

command=$1
shift
printf '%s %s\n' "${command}" "$*" >> "${FAKE_RCLONE_LOG}"
printf 'type=%s provider=%s\n' "${RCLONE_CONFIG_STREAM_TYPE:-}" "${RCLONE_CONFIG_STREAM_PROVIDER:-}" >> "${FAKE_RCLONE_LOG}"
printf 'access=%s secret=%s\n' "${RCLONE_CONFIG_STREAM_ACCESS_KEY_ID:-}" "${RCLONE_CONFIG_STREAM_SECRET_ACCESS_KEY:-}" >> "${FAKE_RCLONE_LOG}"

remote_path() {
  printf '%s/%s' "${FAKE_RCLONE_ROOT}" "${1#*:}"
}

case "${command}" in
rcat)
  target=$(remote_path "$1")
  mkdir -p "$(dirname "${target}")"
  cat > "${target}"
  ;;
moveto)
  source_path=$(remote_path "$1")
  destination_path=$(remote_path "$2")
  mkdir -p "$(dirname "${destination_path}")"
  mv "${source_path}" "${destination_path}"
  ;;
deletefile)
  target=$(remote_path "$1")
  rm -f "${target}"
  ;;
*)
  echo >&2 "Unexpected rclone command ${command}"
  exit 1
  ;;
esac
SCRIPT
chmod +x "${test_dir}/bin/rclone"

export PATH="${test_dir}/bin:${repo_dir}/bin:${PATH}"
export FAKE_RCLONE_ROOT="${test_dir}/remote"
export FAKE_RCLONE_LOG="${test_dir}/rclone.log"
export AWS_ACCESS_KEY_ID=expanded-access-key
export AWS_SECRET_ACCESS_KEY=expanded-secret-key

run_upload() {
  local status=$1
  local destination=$2
  local stream_dir="${test_dir}/${destination}"

  mkdir -p "${stream_dir}"
  stream_init "${stream_dir}"
  (
    printf 'database dump' > "${stream_dir}/data"
    status_tmp="${stream_dir}/status.tmp"
    printf '%s\n' "${status}" > "${status_tmp}"
    mv "${status_tmp}" "${stream_dir}/status"
  ) &

  make -f "${repo_dir}/bin/actions.mk" stream-upload \
    provider=aws 'key=${AWS_ACCESS_KEY_ID}' 'secret=${AWS_SECRET_ACCESS_KEY}' \
    "stream_path=${stream_dir}/data" "status_path=${stream_dir}/status" \
    bucket=backups "destination=${destination}/dump.sql.gz" \
    "temporary_destination=${destination}/dump.sql.gz.partial" \
    max_concurrent_requests=2 storage_class=STANDARD \
    'content_disposition=attachment; filename=dump.sql.gz' region=us-east-1
}

run_upload 0 success
test "$(cat "${test_dir}/remote/backups/success/dump.sql.gz")" = 'database dump'
test ! -e "${test_dir}/remote/backups/success/dump.sql.gz.partial"
grep -q 'type=s3 provider=AWS' "${FAKE_RCLONE_LOG}"
grep -q 'access=expanded-access-key secret=expanded-secret-key' "${FAKE_RCLONE_LOG}"
grep -q -- '--s3-upload-concurrency 2' "${FAKE_RCLONE_LOG}"
grep -q -- '--s3-storage-class STANDARD' "${FAKE_RCLONE_LOG}"

if run_upload 7 failure; then
  echo >&2 'Failed producer unexpectedly published an object'
  exit 1
fi
test ! -e "${test_dir}/remote/backups/failure/dump.sql.gz"
test ! -e "${test_dir}/remote/backups/failure/dump.sql.gz.partial"

run_provider_upload() {
  local provider=$1
  local destination=$2
  local key=$3
  local secret=$4
  local endpoint=$5
  local stream_dir="${test_dir}/${destination}"

  mkdir -p "${stream_dir}"
  stream_init "${stream_dir}"
  (
    printf '%s stream' "${provider}" > "${stream_dir}/data"
    printf '0\n' > "${stream_dir}/status"
  ) &

  make -f "${repo_dir}/bin/actions.mk" stream-upload \
    "provider=${provider}" "key=${key}" "secret=${secret}" \
    "stream_path=${stream_dir}/data" "status_path=${stream_dir}/status" \
    bucket=backups "destination=${destination}/dump" \
    "temporary_destination=${destination}/dump.partial" "endpoint_url=${endpoint}"
  test "$(cat "${test_dir}/remote/backups/${destination}/dump")" = "${provider} stream"
}

printf '{}\n' > "${test_dir}/gcp-service-account.json"
run_provider_upload digitalocean digitalocean access-key secret-key https://fra1.digitaloceanspaces.com
run_provider_upload cloudflare cloudflare access-key secret-key https://account.r2.cloudflarestorage.com
run_provider_upload backblaze backblaze application-key-id application-key https://s3.us-west-004.backblazeb2.com
run_provider_upload azure azure storage-account storage-key https://storage-account.blob.core.windows.net
run_provider_upload gcp gcp "${test_dir}/gcp-service-account.json" '' https://storage.googleapis.com
grep -q 'type=s3 provider=DigitalOcean' "${FAKE_RCLONE_LOG}"
grep -q 'type=s3 provider=Cloudflare' "${FAKE_RCLONE_LOG}"
grep -q 'type=s3 provider=Other' "${FAKE_RCLONE_LOG}"
grep -q 'type=azureblob provider=' "${FAKE_RCLONE_LOG}"
grep -q 'type=google cloud storage provider=' "${FAKE_RCLONE_LOG}"

mkdir -p "${test_dir}/source"
printf 'file backup\n' > "${test_dir}/source/example.txt"
backup_and_upload_stream aws access-key secret-key \
  "${test_dir}/source" 1 '' '' backups files/archive.tar.gz files/archive.tar.gz.partial \
  2 '' STANDARD 'attachment; filename="archive.tar.gz"' us-east-1 ''
tar -xOzf "${test_dir}/remote/backups/files/archive.tar.gz" ./example.txt | grep -q '^file backup$'
test ! -e "${test_dir}/remote/backups/files/archive.tar.gz.partial"

printf 'stream upload unit tests passed\n'
