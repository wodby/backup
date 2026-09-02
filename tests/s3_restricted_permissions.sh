#!/usr/bin/env bash

set -euo pipefail

image=${IMAGE:?IMAGE must name the backup image under test}
test_dir=$(mktemp -d)
suffix="${RANDOM}-$$"
network="wodby-backup-s3-${suffix}"
server="wodby-backup-minio-${suffix}"
proxy="wodby-backup-s3-proxy-${suffix}"
minio_image=quay.io/minio/minio:RELEASE.2025-04-22T22-12-26Z
mc_image=quay.io/minio/mc:RELEASE.2025-04-16T18-13-26Z
nginx_image=nginx:1.28-alpine
root_user=minio-root
root_password=minio-root-password
backup_user=backup-object-user
backup_password=backup-object-password

cleanup() {
  docker rm -f "${proxy}" >/dev/null 2>&1 || true
  docker rm -f "${server}" >/dev/null 2>&1 || true
  docker network rm "${network}" >/dev/null 2>&1 || true
  rm -rf "${test_dir}"
}
trap cleanup EXIT

cat > "${test_dir}/policy.json" <<'JSON'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:GetBucketLocation",
      "Resource": "arn:aws:s3:::backups"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:AbortMultipartUpload"
      ],
      "Resource": "arn:aws:s3:::backups/*"
    }
  ]
}
JSON

# AWS returns 403 for a HEAD of a missing object when the caller lacks
# s3:ListBucket. MinIO returns 404, so this proxy translates only that missing
# response and lets the test exercise AWS's permission-sensitive behavior.
cat > "${test_dir}/nginx.conf" <<'NGINX'
events {}
http {
  server {
    listen 9000;
    client_max_body_size 0;
    location / {
      proxy_pass http://minio:9000;
      proxy_set_header Host $http_host;
      proxy_intercept_errors on;
      error_page 404 = @missing_object;
    }
    location @missing_object {
      return 403;
    }
  }
}
NGINX

mkdir -p "${test_dir}/source"
# Stay above rclone's streaming cutoff so this exercises the multipart path
# used by real database and files backups rather than its small-object PUT.
dd if=/dev/urandom of="${test_dir}/source/example.bin" bs=1M count=1 status=none

docker network create "${network}" >/dev/null
docker run --detach --rm \
  --name "${server}" \
  --network "${network}" \
  --network-alias minio \
  --network-alias "backups.${server}" \
  --env "MINIO_ROOT_USER=${root_user}" \
  --env "MINIO_ROOT_PASSWORD=${root_password}" \
  "${minio_image}" server /data >/dev/null

ready=false
for _ in $(seq 1 30); do
  if docker run --rm --network "${network}" "${mc_image}" \
    alias set local "http://${server}:9000" "${root_user}" "${root_password}" >/dev/null 2>&1; then
    ready=true
    break
  fi
  sleep 1
done
if [[ "${ready}" != "true" ]]; then
  echo >&2 'MinIO did not become ready'
  exit 1
fi

docker run --rm \
  --network "${network}" \
  --volume "${test_dir}/policy.json:/policy.json:ro" \
  --entrypoint /bin/sh \
  "${mc_image}" -eu -c \
  "mc alias set local http://${server}:9000 ${root_user} ${root_password} >/dev/null
   mc mb local/backups >/dev/null
   mc admin user add local ${backup_user} ${backup_password} >/dev/null
   mc admin policy create local backup-object-access /policy.json >/dev/null
   mc admin policy attach local backup-object-access --user ${backup_user} >/dev/null"

# This user deliberately has no s3:ListBucket permission. It models manually
# selected buckets whose credentials can operate only on exact object keys.
if docker run --rm --network "${network}" --entrypoint /bin/sh "${mc_image}" -eu -c \
  "mc alias set restricted http://${server}:9000 ${backup_user} ${backup_password} >/dev/null
   mc ls restricted/backups" >/dev/null 2>&1; then
  echo >&2 'Restricted backup user unexpectedly listed the bucket'
  exit 1
fi

docker run --detach --rm \
  --name "${proxy}" \
  --network "${network}" \
  --network-alias s3-proxy \
  --volume "${test_dir}/nginx.conf:/etc/nginx/nginx.conf:ro" \
  "${nginx_image}" >/dev/null

docker run --rm \
  --network "${network}" \
  --volume "${test_dir}/source:/source:ro" \
  "${image}" make backup-and-upload-stream \
  provider=backblaze \
  "key=${backup_user}" \
  "secret=${backup_password}" \
  dir=/source \
  gzip=1 \
  bucket=backups \
  destination=tests/final.tar.gz \
  temporary_destination=tests/final.tar.gz.partial \
  region=us-east-1 \
  endpoint_url=http://s3-proxy:9000

docker run --rm --network "${network}" --entrypoint /bin/sh "${mc_image}" -eu -c \
  "mc alias set local http://${server}:9000 ${root_user} ${root_password} >/dev/null
   mc stat local/backups/tests/final.tar.gz >/dev/null
   if mc stat local/backups/tests/final.tar.gz.partial >/dev/null 2>&1; then
     echo >&2 'Temporary backup object still exists after publish'
     exit 1
   fi"

printf 'restricted S3 permission test passed\n'
