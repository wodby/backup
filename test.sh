#!/usr/bin/env bash

set -e

if [[ -n "${DEBUG}" ]]; then
    set -x
fi

aws_s3_bucket=wodby-mirroring-testing
aws_s3_region=us-east-1
archive_path=/mnt/backup-$RANDOM.tar
archive_path_zip=/mnt/backup-$RANDOM.tar.gz

docker run --rm -v /tmp:/mnt -e DEBUG "${IMAGE}" make backup-dir \
    exclude="./engines/libcswift.so;./engines/libgmp.so" dir=/usr/lib filepath="${archive_path}" mark=".wodby"

docker run --rm -v /tmp:/mnt -e DEBUG "${IMAGE}" make mirror-s3 \
    filepath="${archive_path}" key_id="${AWS_ACCESS_KEY_ID}" access_key="${AWS_ACCESS_KEY}" \
    bucket="${aws_s3_bucket}" region="${aws_s3_region}" storage_class="STANDARD_IA"

docker run --rm -v /tmp:/mnt "${IMAGE}" make backup-dir dir=/usr/lib filepath="${archive_path_zip}"
docker run --rm -v /tmp:/mnt "${IMAGE}" make delete filepath="${archive_path_zip}"
docker run --rm -v /tmp:/mnt "${IMAGE}" mkdir -p /mnt/files
docker run --rm -v /tmp:/mnt "${IMAGE}" touch -d 201512180130.09 /mnt/files/oldfile
docker run --rm -v /tmp:/mnt "${IMAGE}" touch /mnt/files/newfile
docker run --rm -v /tmp:/mnt "${IMAGE}" make rotate dir=/mnt/files
docker run --rm -v /tmp:/mnt "${IMAGE}" test ! -e /mnt/files/oldfile
docker run --rm -v /tmp:/mnt "${IMAGE}" test -e /mnt/files/newfile
