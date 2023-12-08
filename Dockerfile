FROM wodby/alpine:3.18-2.14.0

ENV PATH="${PATH}:/usr/local/google-cloud-sdk/bin"

RUN set -ex; \
    \
    apk add --update --no-cache -t .backup-rundeps \
        make \
        aws-cli \
        rsync \
        doctl; \
    \
    curl https://sdk.cloud.google.com > install.sh; \
    bash install.sh --disable-prompts --install-dir=/usr/local

COPY bin /usr/local/bin/
COPY docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]
