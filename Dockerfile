FROM alpine:3.5

ENV GO_AWS_S3_VER 1.0.0

RUN apk add --no-cache \
        bash \
        ca-certificates \
        make \
        tar \
        tzdata \
        wget && \

    # Install go-aws-s3
    wget -qO- https://github.com/wodby/go-aws-s3/releases/download/${GO_AWS_S3_VER}/go-aws-s3.tar.gz \
        | tar xz -C /usr/local/bin

COPY actions/ /usr/local/bin/
COPY docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]
