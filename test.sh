#!/usr/bin/env bash

set -e

if [[ -n ${DEBUG} ]]; then
  set -x
fi

AWS_KEY_ID=AKIAJQ73RDKGCOGMX7KQ
AWS_ACCESS_KEY=Rhp7c4WZtm1bLXVoHCBRudwVDEF/7RNr/CQ3xbJD
AWS_S3_BUCKET=wodby-mirroring-testing
AWS_S3_REGION=us-east-1
FILEPATH=/mnt/backup-$RANDOM.tar.gz

docker run --rm -v /tmp:/mnt ${IMAGE} make backup-dir dir=/usr/lib filepath=${FILEPATH}
docker run --rm -v /tmp:/mnt ${IMAGE} make mirror-s3 filepath=${FILEPATH} key_id=${AWS_KEY_ID} access_key=${AWS_ACCESS_KEY} bucket=${AWS_S3_BUCKET} region=${AWS_S3_REGION}
