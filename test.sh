#!/usr/bin/env bash

set -e

if [[ -n "${DEBUG}" ]]; then
  set -x
fi

aws_bucket=wodby-mirroring-testing
gcp_bucket=wodby-backup-tests
azure_container=${AZURE_BLOB_CONTAINER:-}
azure_account=${AZURE_STORAGE_ACCOUNT:-}
azure_key=${AZURE_STORAGE_KEY:-}
azure_endpoint=${AZURE_STORAGE_ENDPOINT:-}
archive_path=/mnt/backup-$RANDOM.tar
archive_path_zip=/mnt/backup-$RANDOM.tar.gz
destination=test/test.tar
tmp_dir=/tmp/backup-tests-$RANDOM

docker run --rm -v "${tmp_dir}":/mnt -e DEBUG "${IMAGE}" make backup-dir \
  exclude="./gnumake.h;./python3.11" dir=/usr/include filepath="${archive_path}" mark=".wodby"

docker run --rm -v "${tmp_dir}":/mnt -e DEBUG "${IMAGE}" make upload \
  provider="aws" key="${AWS_ACCESS_KEY_ID}" gzip=1 secret="${AWS_SECRET_ACCESS_KEY}" \
  filepath="${archive_path}" bucket="${aws_bucket}" storage_class="STANDARD_IA" content_disposition="'attachment; filename=test.tar'" region="${AWS_REGION}"

docker run --rm -v "${tmp_dir}":/mnt -e DEBUG "${IMAGE}" make upload \
  provider="aws" key="${AWS_ACCESS_KEY_ID}" secret="${AWS_SECRET_ACCESS_KEY}" \
  filepath="${archive_path}" bucket="${aws_bucket}" destination="destination-$RANDOM.tar" region="${AWS_REGION}"

docker run --rm -v "${tmp_dir}":/mnt -e DEBUG "${IMAGE}" make upload \
  provider="gcp" key="${GCP_SA}" \
  filepath="${archive_path}" bucket="${gcp_bucket}" destination="destination-$RANDOM.tar" storage_class="NEARLINE" content_disposition="'attachment; filename=test.tar'"

if [[ -n "${azure_account}" && -n "${azure_key}" && -n "${azure_container}" ]]; then
  docker run --rm -v "${tmp_dir}":/mnt -e DEBUG "${IMAGE}" make upload \
    provider="azure" key="${azure_account}" secret="${azure_key}" \
    filepath="${archive_path}" bucket="${azure_container}" destination="destination-$RANDOM.tar" \
    storage_class="Cool" content_disposition="'attachment; filename=test.tar'" endpoint_url="${azure_endpoint}"
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

docker run --rm -v "${tmp_dir}":/mnt -e DEBUG "${IMAGE}" make backup-and-upload dir=/usr/include \
  provider="aws" key="${AWS_ACCESS_KEY_ID}" secret="${AWS_SECRET_ACCESS_KEY}" \
  bucket="${aws_bucket}" destination="${destination}" storage_class="STANDARD_IA" region="${AWS_REGION}"

docker run --rm -v "${tmp_dir}":/mnt -e DEBUG "${IMAGE}" make backup-and-upload dir=/usr/include \
  provider="gcp" key="${GCP_SA}" \
  bucket="${gcp_bucket}" destination="${destination}" storage_class="NEARLINE"

if [[ -n "${azure_account}" && -n "${azure_key}" && -n "${azure_container}" ]]; then
  docker run --rm -v "${tmp_dir}":/mnt -e DEBUG "${IMAGE}" make backup-and-upload dir=/usr/include \
    provider="azure" key="${azure_account}" secret="${azure_key}" \
    bucket="${azure_container}" destination="${destination}" storage_class="Cool" endpoint_url="${azure_endpoint}"
else
  echo "Skipping Azure backup-and-upload test because AZURE_STORAGE_ACCOUNT, AZURE_STORAGE_KEY, or AZURE_BLOB_CONTAINER is not set"
fi

docker run --rm -v "${tmp_dir}":/mnt -e DEBUG "${IMAGE}" sh -c 'rm -rf /mnt/*'
