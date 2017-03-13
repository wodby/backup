#!/usr/bin/env bash

set -e

if [[ -n ${DEBUG} ]]; then
  set -x
fi

AWS_KEY_ID=AKIAJ72G4XDNC7NMAOCA
AWS_S3_BUCKET=wodby-mirroring-testing
AWS_S3_REGION=us-east-1
FILEPATH=/mnt/backup-$RANDOM.tar.gz

docker run --rm -v /tmp:/mnt ${IMAGE} make backup-dir dir=/usr/lib filepath=${FILEPATH}
docker run --rm -v /tmp:/mnt ${IMAGE} make mirror-s3 filepath=${FILEPATH} key_id=${AWS_KEY_ID} access_key=${AWS_ACCESS_KEY} bucket=${AWS_S3_BUCKET} region=${AWS_S3_REGION}
docker run --rm -v /tmp:/mnt ${IMAGE} mkdir -p /mnt/files
docker run --rm -v /tmp:/mnt ${IMAGE} touch -d 201512180130.09 /mnt/files/oldfile
docker run --rm -v /tmp:/mnt ${IMAGE} touch /mnt/files/newfile
docker run --rm -v /tmp:/mnt ${IMAGE} make rotate dir=/mnt/files
docker run --rm -v /tmp:/mnt ${IMAGE} test ! -e /mnt/files/oldfile
docker run --rm -v /tmp:/mnt ${IMAGE} test -e /mnt/files/newfile