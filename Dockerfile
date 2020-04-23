FROM wodby/alpine

ENV PATH="${PATH}:/usr/local/google-cloud-sdk/bin"

RUN set -ex; \
    \
    apk add --update --no-cache -t .backup-rundeps \
        make \
        py2-pip \
        tzdata; \
    \
    curl https://sdk.cloud.google.com > install.sh; \
    bash install.sh --disable-prompts --install-dir=/usr/local; \
    \
    # @todo upgrade to v2 https://github.com/wodby/backup/issues/2
    pip install -U awscli

COPY bin /usr/local/bin/
COPY docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]
