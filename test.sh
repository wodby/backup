#!/usr/bin/env bash

set -e

aws_bucket=wodby-mirroring-testing
gcp_bucket=wodby-backup-tests
azure_container=${AZURE_BLOB_CONTAINER:-}
archive_path=/mnt/backup-$RANDOM.tar
archive_path_zip=/mnt/backup-$RANDOM.tar.gz
destination=test/test.tar
tmp_dir=${BACKUP_TEST_TMP_DIR:-/tmp/backup-tests-$RANDOM}

docker run --rm -v "${tmp_dir}":/mnt -e DEBUG "${IMAGE}" make backup-dir \
  exclude="./gnumake.h;./python3.11" dir=/usr/include filepath="${archive_path}" mark=".wodby"

docker run --rm -v "${tmp_dir}":/mnt -e DEBUG -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -e AWS_SESSION_TOKEN -e AWS_REGION "${IMAGE}" make upload \
  provider="aws" gzip=1 \
  filepath="${archive_path}" bucket="${aws_bucket}" storage_class="STANDARD_IA" content_disposition="attachment; filename=test.tar" region="${AWS_REGION}"

docker run --rm -v "${tmp_dir}":/mnt -e DEBUG -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -e AWS_SESSION_TOKEN -e AWS_REGION "${IMAGE}" make upload \
  provider="aws" \
  filepath="${archive_path}" bucket="${aws_bucket}" destination="destination-$RANDOM.tar" region="${AWS_REGION}"

docker run --rm -v "${tmp_dir}":/mnt -e DEBUG -e GCP_SA "${IMAGE}" make upload \
  provider="gcp" \
  filepath="${archive_path}" bucket="${gcp_bucket}" destination="destination-$RANDOM.tar" storage_class="NEARLINE" content_disposition="attachment; filename=test.tar"

if [[ -n "${AZURE_STORAGE_ACCOUNT:-}" && -n "${AZURE_STORAGE_KEY:-}" && -n "${azure_container}" ]]; then
  docker run --rm -v "${tmp_dir}":/mnt -e DEBUG -e AZURE_STORAGE_ACCOUNT -e AZURE_STORAGE_KEY -e AZURE_STORAGE_ENDPOINT "${IMAGE}" make upload \
    provider="azure" \
    filepath="${archive_path}" bucket="${azure_container}" destination="destination-$RANDOM.tar" \
    storage_class="Cool" content_disposition="attachment; filename=test.tar"
else
  echo "Skipping Azure upload test because AZURE_STORAGE_ACCOUNT, AZURE_STORAGE_KEY, or AZURE_BLOB_CONTAINER is not set"
fi

docker run --rm -v "${tmp_dir}":/mnt "${IMAGE}" make backup-dir dir=/usr/include filepath="${archive_path_zip}"
docker run --rm -v "${tmp_dir}":/mnt "${IMAGE}" make delete filepath="${archive_path_zip}"
docker run --rm -v "${tmp_dir}":/mnt "${IMAGE}" mkdir -p /mnt/files
docker run --rm -v "${tmp_dir}":/mnt "${IMAGE}" touch -d 201512180130.09 /mnt/files/oldfile
docker run --rm -v "${tmp_dir}":/mnt "${IMAGE}" touch /mnt/files/newfile
docker run --rm -v "${tmp_dir}":/mnt "${IMAGE}" make rotate dir=/mnt/files
docker run --rm -v "${tmp_dir}":/mnt "${IMAGE}" test ! -e /mnt/files/oldfile
docker run --rm -v "${tmp_dir}":/mnt "${IMAGE}" test -e /mnt/files/newfile

docker run --rm -v "${tmp_dir}":/mnt "${IMAGE}" make import source="https://s3.amazonaws.com/wodby-sample-files/archives/export.tar.gz" destination="/mnt"
docker run --rm -v "${tmp_dir}":/mnt "${IMAGE}" make import source="https://s3.amazonaws.com/wodby-sample-files/archives/export.tar" destination="/mnt" owner=10 group=10
docker run --rm -v "${tmp_dir}":/mnt "${IMAGE}" make import source="https://s3.amazonaws.com/wodby-sample-files/archives/export.zip" destination="/mnt" owner=11 group=11

docker run --rm -v "${tmp_dir}":/mnt -e DEBUG -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -e AWS_SESSION_TOKEN -e AWS_REGION "${IMAGE}" make backup-and-upload dir=/usr/include \
  provider="aws" \
  bucket="${aws_bucket}" destination="${destination}" storage_class="STANDARD_IA" region="${AWS_REGION}"

docker run --rm -v "${tmp_dir}":/mnt -e DEBUG -e GCP_SA "${IMAGE}" make backup-and-upload dir=/usr/include \
  provider="gcp" \
  bucket="${gcp_bucket}" destination="${destination}" storage_class="NEARLINE"

if [[ -n "${AZURE_STORAGE_ACCOUNT:-}" && -n "${AZURE_STORAGE_KEY:-}" && -n "${azure_container}" ]]; then
  docker run --rm -v "${tmp_dir}":/mnt -e DEBUG -e AZURE_STORAGE_ACCOUNT -e AZURE_STORAGE_KEY -e AZURE_STORAGE_ENDPOINT "${IMAGE}" make backup-and-upload dir=/usr/include \
    provider="azure" \
    bucket="${azure_container}" destination="${destination}" storage_class="Cool"
else
  echo "Skipping Azure backup-and-upload test because AZURE_STORAGE_ACCOUNT, AZURE_STORAGE_KEY, or AZURE_BLOB_CONTAINER is not set"
fi

docker run --rm -v "${tmp_dir}":/mnt -e DEBUG "${IMAGE}" sh -c 'rm -rf /mnt/*'
