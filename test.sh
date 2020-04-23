#!/usr/bin/env bash

set -e

if [[ -n "${DEBUG}" ]]; then
  set -x
fi

aws_bucket=wodby-mirroring-testing
aws_region=us-east-1
gcp_bucket=wodby-backup-tests
gcp_project_id=wodby-tests
archive_path=/mnt/backup-$RANDOM.tar
archive_path_zip=/mnt/backup-$RANDOM.tar.gz
destination=test/test.tar

docker run --rm -v /tmp:/mnt -e DEBUG "${IMAGE}" make backup-dir \
  exclude="./engines/libcswift.so;./engines/libgmp.so" dir=/usr/include filepath="${archive_path}" mark=".wodby"

docker run --rm -v /tmp:/mnt -e DEBUG "${IMAGE}" make upload \
  provider="aws" scope="${aws_region}" key="${AWS_ACCESS_KEY_ID}" secret="${AWS_ACCESS_KEY}" \
  filepath="${archive_path}" bucket="${aws_bucket}" storage_class="STANDARD_IA"

docker run --rm -v /tmp:/mnt -e DEBUG "${IMAGE}" make upload \
  provider="gcp" scope="${gcp_project_id}" key="${GCP_SA}" \
  filepath="${archive_path}" bucket="${gcp_bucket}" storage_class="NEARLINE"

docker run --rm -v /tmp:/mnt "${IMAGE}" make backup-dir dir=/usr/include filepath="${archive_path_zip}"
docker run --rm -v /tmp:/mnt "${IMAGE}" make delete filepath="${archive_path_zip}"
docker run --rm -v /tmp:/mnt "${IMAGE}" mkdir -p /mnt/files
docker run --rm -v /tmp:/mnt "${IMAGE}" touch -d 201512180130.09 /mnt/files/oldfile
docker run --rm -v /tmp:/mnt "${IMAGE}" touch /mnt/files/newfile
docker run --rm -v /tmp:/mnt "${IMAGE}" make rotate dir=/mnt/files
docker run --rm -v /tmp:/mnt "${IMAGE}" test ! -e /mnt/files/oldfile
docker run --rm -v /tmp:/mnt "${IMAGE}" test -e /mnt/files/newfile

docker run --rm -v /tmp:/mnt -e DEBUG "${IMAGE}" make backup-and-upload dir=/usr/include \
  provider="aws" scope="${aws_region}" key="${AWS_ACCESS_KEY_ID}" secret="${AWS_ACCESS_KEY}" \
  bucket="${aws_bucket}" destination="${destination}" storage_class="STANDARD_IA"

docker run --rm -v /tmp:/mnt -e DEBUG "${IMAGE}" make backup-and-upload dir=/usr/include \
  provider="gcp" scope="${gcp_project_id}" key="${GCP_SA}" \
  bucket="${gcp_bucket}" destination="${destination}" storage_class="NEARLINE"
