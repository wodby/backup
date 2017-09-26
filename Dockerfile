FROM alpine:3.6

ENV GO_AWS_S3_URL "https://github.com/wodby/go-aws-s3/releases/download/1.0.0/go-aws-s3.tar.gz"

RUN apk add --no-cache \
        bash \
        ca-certificates \
        make \
        tar \
        tzdata \
        wget && \

    wget -qO- "${GO_AWS_S3_URL}" | tar xz -C /usr/local/bin

COPY actions/ /usr/local/bin/
COPY docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]
